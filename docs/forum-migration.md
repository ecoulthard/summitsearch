# Forem to Thredded migration assessment

Assessed on October 17, 2026 against this application's Rails 8.0.2,
Ruby 3.4.4, PostgreSQL, Devise, Propshaft, and Turbo configuration.

## Recommendation and compatibility

Thredded is a viable replacement. Version 1.2.1 is the latest published GitHub
release checked during this assessment. Its source includes a Rails 8.0 test
Gemfile. Resolving `thredded ~> 1.2.1` against a temporary copy of this project's
Gemfile and lockfile succeeded without changing the existing Rails version or
the project's files. This verifies dependency resolution, not application boot,
browser behavior, or a data import.

The frontend needs explicit integration: Thredded 1.2 uses Sprockets, Sass,
transpiled JavaScript, and Rails UJS. This app uses Propshaft and Turbo. Adding
the gem alone will not produce working forum assets. Choose and test either
an isolated build that feeds compiled forum assets into Propshaft, or a move
to Sprockets with a Sass compiler. The latter affects the whole application.
Keep the forum on full page navigation initially so Turbo and Rails UJS do not
both handle forum forms and links.

The upstream main-branch README describes Thredded 2.0 with Turbo support, but
the latest GitHub release returned by the API is 1.2.1. Do not assume an
unreleased frontend is available in the published gem.

Sources:

- https://github.com/thredded/thredded/releases/tag/v1.2.1
- https://github.com/thredded/thredded/blob/v1.2.1/spec/gemfiles/rails_8.0.gemfile
- https://github.com/thredded/thredded/blob/v1.2.1/thredded.gemspec
- https://github.com/thredded/thredded/blob/v1.2.1/lib/thredded/engine.rb
- https://github.com/thredded/thredded/blob/main/README.md#rails-compatibility

## Step 1 implementation

Step 1 is implemented with Thredded 1.2.1 locked in `Gemfile.lock`. Propshaft
remains the application asset pipeline. `ForumAssets` uses a standalone
Sprockets environment for the gem's JavaScript (including Rails UJS and its
dependencies), and SassC plus Autoprefixer for its styles. The generated
bundles and images go into ignored `app/assets/builds/`, which Propshaft
serves and fingerprints. Raw Thredded asset directories are excluded from
Propshaft. The build also handles the upstream stylesheet's missing 48px
calendar icon using the shipped 128px image at the intended display size.

Development automatically rebuilds these gem assets on application startup.
Restart after changing the asset builder or upgrading Thredded. To explicitly
rebuild, run:

```sh
bundle exec rails thredded:assets:build
```

Node.js must be installed locally for JavaScript compilation and Autoprefixer.
The Docker build stage installs Node.js. The existing production build command
now runs the forum build before Propshaft precompiles:

```sh
RAILS_ENV=production SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile
```

`app/views/layouts/thredded/application.html.erb` loads only the forum bundles.
It requests full page navigation from Turbo and disables Turbo within the
forum body, leaving Rails UJS in charge of forum forms and links. It will be
used when the engine is mounted in step 6; no forum routes, user configuration,
schema, or data import are included in step 1.

The database-independent browser smoke test renders this real layout through
a temporary Rack app. It checks CSS, JavaScript initialization, textarea
autosizing, a spoiler interaction, all stylesheet image URLs, and browser
console errors. It does not mount the engine or exercise forum CRUD, which
needs later migration steps.

```sh
RAILS_ENV=development bundle exec ruby test/assets/forum_assets_test.rb
```

To test production compilation without writing a manifest into `public/assets`
(which would affect subsequent local development), use an isolated output:

```sh
RAILS_ENV=production SECRET_KEY_BASE_DUMMY=1 bundle exec ruby -e 'require "rake"; require_relative "config/application"; Rails.application.config.assets.output_path = Rails.root.join("tmp/forum-production-assets"); Rails.application.load_tasks; Rake::Task["assets:precompile"].invoke'
RAILS_ENV=production SECRET_KEY_BASE_DUMMY=1 FORUM_ASSETS_OUTPUT_PATH="$PWD/tmp/forum-production-assets" bundle exec ruby test/assets/forum_assets_test.rb
```

Verified locally: development boot and browser smoke test, production
precompilation with no unresolved asset warnings, and the browser smoke test
against those precompiled assets under production boot. Both browser runs
passed 49 assertions. No database migrations or imports were run. The complete
Docker image build has not been tested.

## Step 2 implementation

`config/initializers/thredded.rb` uses the existing Devise `User` and
`current_user`, the `username` column for mentions/autocomplete, and
`display_name` for presentation. Profile links use the application's existing
user route, including FriendlyId slugs. The sender uses `NOTIFIER_EMAIL`, with
the same `notifier@summitsearch.org` fallback as Devise. Pending content is
explicitly hidden from ordinary readers.

Forum administration continues to use `users.forem_admin`. A site Admin or
Editor does not automatically become a forum administrator. The `ForumUser`
module is prepended so its permissions take precedence over Thredded's default
user extension, including after development reloads. The host authentication,
editor, and admin callbacks are skipped specifically on Thredded controllers;
Thredded's own login requirements and Pundit policies govern forum actions.
The host application's callbacks remain intact elsewhere.

Board moderators are resolved through the existing `forem_memberships` and
`forem_moderator_groups` tables, using read-only models. **Step 3 must add a
nullable, unique indexed `forem_forum_id` column to `thredded_messageboards`
and populate it during import.** Permissions use that explicit mapping rather
than coincidentally equal primary keys, names, or slugs. Until the mapping
exists, non-admin moderation grants are empty. Unmapped/new boards receive no
legacy group permissions. Retain the legacy membership tables until grants
are deliberately moved to a new store.

The read-only username audit is repeatable in any environment:

```sh
bundle exec rails thredded:users:audit
```

The local development audit found 374 users: 32 null usernames, one empty
username, four usernames with surrounding whitespace, and zero duplicate
case-insensitive groups (including after trimming). The local legacy tables
had no moderator group grants or memberships; synthetic grants were tested
against PostgreSQL temporary tables.

After that audit, a guarded migration added a unique `lower(username)` index
to match Thredded's case-insensitive lookup; the model validation now also
ignores case. The migration stops with an audit instruction if conflicts
exist in another environment. It was applied to local development and test
databases and can be reversed. Run `bundle exec rails db:migrate` on other
environments before deploying this change.

No users were renamed, deleted, or assigned new privileges. Null usernames
remain allowed, and display names still fall back to real names. Accounts
without usable usernames cannot be reliably selected by username-based
autocomplete/mentions; resolve blank and whitespace names with their owners
before forum cutover. No presence constraint or automatic renaming was added.
The functional index enforces uniqueness of the actual stored names, not
trimmed names; the audit also reports potential conflicts after trimming.

Verification:

```sh
bundle exec ruby test/models/forum_user_test.rb
```

This suite uses rolled-back transactions and temporary PostgreSQL tables,
without requiring the Thredded schema. It covers configuration, profile links,
display-name fallback, forum administrators, board-scoped moderators,
unmapped boards, guest/member posting, host callback isolation, username
auditing, and index enforcement/preflight. Forum routes and content import
remain deferred to later steps.

Deployment dependency: configuring `Thredded.user_class` enables the gem's
user associations, including dependent cleanup when deleting users. Those
cleanup callbacks require the Thredded tables from step 3. Do not deploy this
intermediate stage with user deletion enabled before installing that schema.
Step 3 now installs those tables: the existing User model suite passes all
eight tests (18 assertions), including last-admin deletion. The step 2 suite
also passes all 11 tests and 58 assertions with the installed schema.

## Step 3 implementation

The upstream Thredded 1.2.1 schema migration and `AddLegacyForumLinks` have
been applied to local development and test databases. Run the following in
other environments before using the importer:

```sh
bundle exec rails db:migrate
bundle exec rails thredded:forem:preflight
```

The application migration adds nullable unique legacy mappings for forums,
categories, topics, and posts, plus indexed article/place association columns
on topics. `ForumTopicLinks` supplies the album, photo, trip report, place,
and uploaded-photo associations on Thredded topics. Existing article and place
consumers still use their old associations until the later integration steps.
All Forem tables remain intact.

`ForemImport` reads the legacy tables directly without loading the Forem gem.
Preflight makes no writes and reports source counts, moderation states,
missing authors/timestamps, and invalid or duplicate subscriptions. Missing
tables, unknown moderation states, broken category/forum/topic references,
nonempty Thredded tables, or an existing import ledger entry stop the import.
The local preflight passed with 3 categories, 15 forums, 109 topics, 221 posts,
161 subscriptions, and 374 users. Four subscriptions point to deleted topics;
these are reported and skipped. Valid subscriptions become distinct follows;
notification preferences and auto-follow behavior are not inferred from
Forem's settings.

The separate write command is:

```sh
bundle exec rails thredded:forem:import
```

Run this only during the rehearsed cutover described below, with forum/comment
writes stopped. It requires empty Thredded tables, locks source and destination
tables, repeats preflight under those locks, and imports in one PostgreSQL
transaction. Lock acquisition times out after five seconds. Bulk inserts
bypass callbacks, jobs, and mailers. Verification checks record counts, exact
post bodies, and valid subscription counts before committing. The durable
`forum_import_runs` ledger and destination-emptiness checks refuse reruns,
including after new Thredded content exists. Sequence restarts are transactional
so failures roll back imported rows and sequence changes together.

Primary keys, existing authors, timestamps, article/place IDs, ordering, and
locked/pinned flags are retained. Missing authors become Thredded deleted-user
references, with original IDs retained as metadata. Missing timestamps fall
back to the other timestamp or the Unix epoch; legacy forums have no timestamps
and use the epoch. Counters and last activity are rebuilt from imported posts.
Pending content stays pending, spam/rejected content becomes blocked, and
hidden topics and their posts become blocked. A pending or blocked parent
never promotes a reply into public visibility.

Original subjects, slugs, reply IDs, states, and view counts are retained as
legacy metadata. Safe deterministic Thredded slugs avoid reserved-name and
duplicate-slug problems; step 6 must resolve original URLs using that metadata.
Post HTML and `[[photo=...]]` tokens are copied verbatim with `source: "forem"`.
Step 4 must supply their legacy rendering before exposing imported content.
Historical visits, signatures, and read state remain in the Forem tables;
they are not converted into Thredded tracking records.

Verification:

```sh
bundle exec ruby test/models/forem_import_test.rb
bundle exec ruby test/models/forum_user_test.rb
bundle exec rails test test/models/user_test.rb
```

The importer suite passes 7 tests and 61 assertions in disposable PostgreSQL
schemas with independent sequences. It covers read-only preflight, preserved
content and links, moderation, no notification events, counters, rerun guards,
structural errors, and rollback after sequence restart. Both user suites pass
as described above. **No content has been imported into the application's
Thredded tables.** The engine remains unmounted; rendering, redirects, and
article/comment cutover are still later steps.

## Step 4 implementation

Albums, photos, and trip reports now associate their discussions and comments
with Thredded. Article board selection resolves existing area `forum_id`
values through `thredded_messageboards.forem_forum_id`; it does not load Forem
classes. Articles without a regional assignment use the `Other Regions`
messageboard. An assigned area without an imported board mapping fails closed.
Place and route forum consumers outside article comments remain for step 7.

`ArticleComment` locks the article and reloads its discussion before writing,
so simultaneous first comments share one topic. The topic, first comment,
read state, and initial owner follow are written in one transaction. Validation
or permission failures roll back the write. Both the topic and post belong to
the commenter; the topic retains its article association and a plain-text
title. The article owner follows an initially readable discussion, with
Thredded's usual notification jobs and preferences replacing the old separate
first-comment email. No historical notification jobs run during import.
The forum topic title hook renders a separate link back to the associated
article, including for imported discussions whose original titles held HTML.

The article endpoint applies Thredded's board, topic, and post policies. A
shared `PostPolicy` extension rejects anonymous replies, unreadable topics,
locked topics (including replies by administrators), and blocked topics on
both article and engine posting paths. Other Thredded write permissions still
apply. Article display checks board/topic read permission before applying the
post policy scope, so guests cannot read pending or blocked content. Authors
and board moderators retain Thredded's visibility of their permitted content.

New comments use Markdown and the existing application paginator, avoiding
the `.page(...).per(...)` collision with will_paginate. Article partials handle
deleted authors, quoting, and moderation labels without Forem helpers. Imported
posts marked `source: "forem"` use a sanitized HTML renderer that expands
`[[photo=ID]]` tokens and tolerates missing photos. The renderer extends the
Thredded post model, so article pages and Thredded's post views share it. Photo
upload/selection and attachment ownership changes remain step 5.

Model callbacks refresh `total_comments` and `last_comment_at` inside the
write transaction for post creation, editing, moderation, deletion, and topic
moderation/deletion or reassignment. Only approved posts in approved topics
count toward public totals and homepage summaries. Last-comment time comes
from the remaining visible comments, and clears when there are none. After
commit, a shared cache version invalidates the homepage comment fragment for
changes from either interface. The old queued totals job now recomputes from
current data instead of applying an obsolete job timestamp.

At cutover, after the import and before enabling comments, rebuild existing
article totals:

```sh
bundle exec rails thredded:articles:recount
```

This command refuses to run without a recorded import and preserves article
update timestamps. It has not been run on local application content because
the real import has not run. No new migration is required for step 4.

Verification:

```sh
bundle exec ruby test/models/article_comment_test.rb
bundle exec ruby test/models/forem_import_test.rb
bundle exec ruby test/models/forum_user_test.rb
bundle exec rails test test/models/user_test.rb
RAILS_ENV=test bundle exec rails zeitwerk:check
```

The article suite passes 14 tests and 110 assertions using disposable
PostgreSQL schemas and real Thredded models,
callbacks, controller actions, views, and moderation commands. It covers atomic
failure, simultaneous first comments, all three article types, board mapping,
policy denials, public/private visibility, Markdown, legacy HTML/photo embeds,
deleted authors, counter updates, recounting, and cache invalidation. The
importer and both user suites also pass, as does Rails eager loading. The
engine is still unmounted until step 6; a mounted-engine browser CRUD test
remains part of cutover verification. No application forum content was imported
or recounted while implementing step 4.

## Step 5 implementation

`Photo#parent_topic` now points to `Thredded::Topic` through the existing
`photos.topic_id` column. Imported topic IDs and photo links stay intact;
deleting a Thredded topic clears the photo links without deleting the photos.
No new migration or attachment remapping is needed.

Thredded topic/post forms and article comment forms have an **Add photos**
picker. It searches the signed-in user's available photos, supports paging,
and uploads multiple JPEG, PNG, or GIF files using Active Storage and the
existing Photo model's 50 MB validation. Uploads require a nearby reference
place, selected through a database-backed place search. The picker works
without the old jQuery UI, TinyMCE, or Fine Uploader code. It inserts
`[[photo=ID]]` tokens and sends the selected IDs with the post. New Markdown
posts render these tokens as photos while retaining Markdown around them;
legacy HTML posts keep their existing sanitized renderer.

`ForumPhotosController` exposes authenticated, policy-checked listing, place
search, and multipart upload endpoints under `/forum_photos`. Eligibility
requires ownership, an image attachment or legacy image filename, and either
no topic assignment or an assignment to the current topic. Another topic's
photos cannot be moved. Existing discussion access follows the shared reply
policy, including locked/blocked/read restrictions. New-discussion access
checks board read and posting permissions.

Uploads always belong to the current user and initially remain unattached;
submitted owner/topic fields are ignored. `ForumPhotoAttachments` validates
all selected IDs and rechecks eligibility under row locks before attaching.
The operation is additive: omitted photos, including other participants'
photos, are not detached. Topic creation, replies, and post edits wrap content
and attachment updates in one transaction. Invalid selections return HTTP 422
and roll back the content changes; article comments use the same attachment
service inside their existing transaction. A cancelled upload remains a photo
in its owner's account and can be selected later.

Generic photo create/update parameters no longer accept `topic_id`, so they
cannot bypass this service. The legacy topic editable-list branch now resolves
Thredded topics and checks access and ownership. Thumbnail updates are scoped
to the signed-in user's photos. The old GET `set_place_id` route has been
removed. Its place-assignment action is not retained: selecting an upload's
reference place does not modify the discussion's place association.

Verification:

```sh
bundle exec ruby test/models/forum_photo_test.rb
bundle exec ruby test/assets/forum_photos_test.rb
bundle exec ruby test/models/article_comment_test.rb
RAILS_ENV=test bundle exec rails zeitwerk:check
```

The photo integration suite passes 12 tests and 72 assertions using disposable
PostgreSQL schemas and real Photo,
Active Storage, and Thredded controller actions. It covers ownership, image
eligibility, malformed IDs, locked/blocked/read policies, concurrent claims,
transactional rollback, uploads, generic endpoint restrictions, and topic
deletion. Engine actions stub only their final redirect destination because
the mount is still step 6. The headless browser test uses the real picker
partial and JavaScript with local mock API responses; it verifies selection,
multipart upload, inserted tokens/IDs, CSRF headers, and browser console
errors (1 test, 14 assertions). The article comment suite remains green
(14 tests, 110 assertions). Rails eager loading, targeted lint, and isolated
production asset compilation also pass; the new `forum_photos.js` is present
in the fingerprinted output under `tmp/forum-step5-assets`. No development
forum content was imported or changed by this implementation.

## Step 6 implementation

Thredded is mounted at `/fanaticsforum`, ahead of the low-priority place
shortcuts. GET/HEAD redirects for Forem's `/forums` index, `/forums/:forum_id`, nested
`/forums/:forum_id/topics/:topic_id`, nested post URLs, and
`/categories/:category_id` are registered before the engine mount.
These return permanent redirects using explicit legacy mappings, imported
slugs, or retained `friendly_id_slugs` history. History lookup does not load
Forem classes. Nested lookups enforce board/topic/post membership; unknown,
unmapped, ambiguous historical, or mismatched references return 404.
Incoming query parameters are discarded rather than copied into destinations.
Legacy write and administration endpoints are not redirected.

Post redirects go to Thredded's `/posts/:id` permalink. That endpoint applies
current read permissions and calculates the viewer's page and `post_ID`
anchor. Page calculation now includes the ID tie-breaker for posts sharing a
timestamp, matching display order. Topic bookmarks with an off-page
`#post_ID` fragment also follow the permalink in the browser; fragments never
reach the server. This uses the post primary keys preserved by the import.
Already-visible anchors retain normal browser scrolling.

Kaminari uses `forum_page`, configured before models load, to coexist with
the application's will_paginate. Thredded topic `on_page` scopes use that
method too. Article pagination continues to use will_paginate.
The photo controller tests now use real engine redirect helpers.

Verification uses disposable PostgreSQL schemas for mounted HTTP requests,
including numeric/current/historical slug redirects, category redirects,
missing mappings, nested membership, mounted index/board/topic rendering,
moderation visibility, and post pagination with identical timestamps.
The layout browser smoke test also checks off-page legacy fragment navigation
and existing anchors. Run:

```sh
bundle exec ruby test/controllers/forum_routes_test.rb
bundle exec ruby test/models/forum_photo_test.rb
bundle exec ruby test/models/article_comment_test.rb
bundle exec ruby test/assets/forum_assets_test.rb
RAILS_ENV=test bundle exec rails zeitwerk:check
```

Verified: routing (3 tests, 52 assertions), photo integration (12 tests,
72 assertions), article comments (14 tests, 110 assertions), and browser
assets/fragments (2 tests, 53 assertions). Eager loading and targeted lint pass.

No application content was imported or recounted. Navigation/search and the
remaining Forem consumers are still step 7. Rehearsing authenticated forum
CRUD, uploads, and moderation in the mounted UI remains part of staging
cutover verification. Earlier sections describe the state at each step;
the engine is now mounted, superseding their unmounted-stage notes.

## Step 7 implementation

Site menus, the listing page, suggestions links, and article comment links
now use Thredded routes. Forum navigation groups readable messageboards by
messageboard group, including ungrouped boards. Suggestions resolve through
the imported `suggestions` slug or legacy forum 21; if unavailable, the link
opens the forum index. The forum layout provides links to all forums, active
and unanswered topics, and a search form. Article comments expose stable post
permalinks and a link to the corresponding forum discussion.

Active Topics and Unanswered Topics are retained as custom, paginated lists:

- `/fanaticsforum/active_topics`: activity in the last seven days.
- `/fanaticsforum/unanswered`: activity in the last 120 days and exactly one
  post readable by the current viewer.

Both lists apply messageboard and topic policies before pagination, use a
fixed activity ordering, and request no indexing. Counting readable posts
avoids revealing hidden replies through the unanswered filter. User-provided
board parameters cannot bypass board permissions.

Search uses Thredded's native database-backed search, independently of
Thinking Sphinx. `/fanaticsforum/search?search=...` redirects to native `q=`
search. Old blank searches with `unanswered` open the unanswered list; other
blank searches open active topics. Old `hours` and sorting parameters are
not retained. `/fanaticsforum/list_topics?forum_id=...` opens that imported
board using the existing legacy resolver; without a board it opens the forum
index. The site's general search offers a separate forum-search link, and
its Sphinx queries explicitly restrict results to the remaining site models.
The guarded, inactive Forem Sphinx definition remains for step 8 cleanup;
do not deploy or reuse its old index for Thredded.

`Place#forum` resolves existing `forum_id` values through the unique
`forem_forum_id` mapping. Route geography uses this same association, with
Other Regions as the fallback only when no area is assigned. An assigned but
unmapped area returns no board. Stored geographic IDs are unchanged.
`User#topics` and `User#posts` now reference Thredded. Historical `forem_views`
remain accessible through a read-only legacy model without loading Forem.
Thredded continues to own current read state and user-deletion callbacks.

The retained first-comment mail template now links to the Thredded topic and
its authenticated unfollow endpoint. New comments continue using the Thredded
follow/notification flow implemented in step 4; no second notification sender
was enabled. Old queued template callers can render without Forem helpers.

Verification:

```sh
bundle exec ruby test/controllers/forum_integration_test.rb
bundle exec ruby test/controllers/forum_routes_test.rb
bundle exec ruby test/models/article_comment_test.rb
bundle exec rails test test/models/user_test.rb test/mailers/user_mailer_test.rb
bundle exec ruby test/assets/forum_assets_test.rb
RAILS_ENV=test bundle exec rails zeitwerk:check
```

The new integration suite uses disposable PostgreSQL schemas and covers list
filters, pagination, moderation, unreadable boards (including crafted board
parameters), native and legacy search, geographic mappings, user associations,
site navigation, and rendered notification links. Article-comment, user/mailer,
legacy routing, browser layout/fragment, eager-loading, and targeted lint
checks also pass. No application forum data was imported, recounted, or
remapped. Retiring inactive Forem decorators, views, assets, and permission
shims remains step 8; old tables are retained.

## Step 8 implementation

Retired the Forem controller/model/helper decorators, their loader and
Zeitwerk exclusions, all Forem views and layout, the commented initializer,
and the obsolete topic Sphinx definition. Removed the Forem permission shims
from ApplicationController and User and the conditional fixture-class setup.
The old conditional controller test is superseded by the mounted routing and
integration suites. Historical fixtures and database migrations remain.

Removed Forem styles, palette variables, JavaScript, jMenu, duplicated scripts
inside the application bundle, and unused forum images. The shared background
image still used by the site's main/menu styles was moved to
`app/assets/images/menu-background.gif`, with those references updated.
Thredded's assets and the article photo picker remain in use.

`LogForemVisitJob` is intentionally retained as a no-op compatibility class
for previously queued/retrying jobs. It no longer writes legacy visit fields
or resolves retired classes. Keep it until old queues and retries have drained.
The unused legacy tracking methods were removed from LogVisitHelper; regular
site visit logging remains active. The inactive `config/routes_old.rb` file is
a historical route snapshot, not part of the application's loaded routes.

All legacy tables, columns, FriendlyId history, moderator mappings, the import
ledger, read-only legacy models, import/audit tasks, sanitized legacy content
renderer, and redirect resolver remain. No schema/data migration, import,
recount, or legacy table deletion was performed for step 8.

A full local **development database** custom-format PostgreSQL backup was
created on October 18, 2026:

```text
storage/forum-backups/before-forem-retirement-20261018T150921Z.dump
```

The archive is 26,891,745 bytes, mode 0600, inside a mode 0700 directory
excluded from Git by the existing storage ignore rule. PostgreSQL 17 tools
were used to match server 17.5. `pg_restore --list` succeeded and confirmed
legacy topic/post table data in its catalog. A restore rehearsal has not been
performed, and this is not a production or uploaded-file backup. Preserve
this archive and the legacy tables through staging/cutover verification;
do not run storage cleanup against `storage/forum-backups`. Take a fresh
backup in each deployment environment before its cutover and retain it
outside ephemeral application storage. For an environment whose libpq
connection variables are already configured, use matching-version tools:

```sh
umask 077
pg_dump --format=custom --file=/secure/persistent/path/before-forum-cutover.dump
pg_restore --list /secure/persistent/path/before-forum-cutover.dump
```

Verification covers the mounted UI, search and notifications, historic
redirects, importer invariants, user lifecycle and mailers, queued-job
compatibility, JavaScript syntax, eager loading, browser assets/fragments,
and isolated production asset compilation under `tmp/forum-step8-assets`.
The retained import suite uses disposable schemas and does not import into
application content tables. Staging cutover/restore rehearsal and verification
with real migrated content are still required before retiring the old tables
or the backup.

## Local development content import

On October 18, 2026 (local time), the empty forum was diagnosed as an
unexecuted content import. The implementation steps above describe their
historical state; local development content has now been imported.

A fresh full development database backup was created before import:
`storage/forum-backups/before-forem-retirement-20261019T004602Z.dump`
(26,891,744 bytes, mode 0600). Its PostgreSQL archive catalog was verified.
Preflight passed, and the guarded transactional import recorded one ledger
entry with 3 messageboard groups, 15 messageboards, 109 topics, 221 posts,
374 user details, and 157 valid follows. Four subscriptions referencing
deleted topics were skipped. Legacy tables remain intact, and historical
notification jobs were not generated. The guarded article recount also
completed, rebuilding comment totals and last-comment timestamps and
invalidating the homepage comment summary cache.

Verified against the development application: the forum index returns HTTP
200 with all 15 board names, a board and topic each return HTTP 200, and a
post permalink redirects to HTTP 200 with its post anchor present. This
operation applies to the local development database only; staging/production
cutover and restore rehearsal remain separate deployment work. The importer
now refuses reruns because destination content and the ledger entry exist.

## Forum appearance

The forum now uses the original Rocky Mountain Fanatics banner, the site's
blue palette and Verdana/Arial typography, a wider content area, compact board
rows, alternating row backgrounds, blue group headers, and site navigation
and footer links. The original `fanatics_forum_logo.png` was deliberately
restored from the repository after the initial step 8 cleanup. This does not
restore Forem views, scripts, or dependencies.

`lib/assets/forum_settings.scss` configures Thredded's supported Sass variables
before compilation, including disabling its board-card grid.
`app/assets/stylesheets/forum_theme.css` styles the forum chrome separately
from the site's global stylesheet. The layout continues loading only Thredded
and forum JavaScript; Rails UJS and full page navigation remain in charge.
The theme's general link color excludes Thredded button links, preserving
contrasting button text before hover as well as on hover and keyboard focus.
Both board/group creation buttons were checked at desktop and phone widths.
Sign-in/sign-up links open the existing Devise pages, avoiding dependency on
the site's old modal JavaScript. Follow/unfollow forms stay in normal flow
so Thredded's desktop absolute positioning cannot collapse their container
and overflow the link text; verified on a real topic at desktop and 390px
mobile widths. At Thredded's tablet breakpoint (48rem) and below, moderation,
settings, private-message, and unread-topic controls use wrapping navigation
rows in normal flow instead of absolute positioning over the breadcrumbs.
Verified with all four icons visible as an administrator on the board index
and a topic at 320px, 390px, and 768px, plus desktop at 1400px.
Forum theme settings are build inputs and
are not published as raw Sass. Rebuild after changing the Sass settings:

```sh
bundle exec rails thredded:assets:build
```

Verified with real imported boards in desktop and exact 390px mobile browser
views, including all 15 boards and no horizontal overflow. The browser asset
suite passes 2 tests and 60 assertions, including branding, fonts, colors,
responsive layout, legacy fragments, and interactive components. The forum
integration suite passes 6 tests and 68 assertions. Targeted lint and isolated
production asset compilation also pass under `tmp/forum-theme-assets`.
Screenshots are available locally at `tmp/forum-theme-desktop.png` and
`tmp/forum-theme-mobile.png`.

## Original integration (before migration)

At the start of this assessment, Forem was absent from the Gemfile, its
initializer was commented out, its routes were conditional, and its decorators
were excluded from Zeitwerk. Legacy tables remained in `db/schema.rb`, while
several live model associations and controllers still referred to Forem. The
implementation sections above describe their replacement and retirement.

The migration includes more than the standalone forum:

- `ArticlesController` creates forum topics and posts for article comments.
- Albums, photos, and trip reports expose comments through forum topics.
- Places and regional areas select a forum; routes and articles fall back to
  the "Other Regions" forum.
- Photos can belong to a forum topic independently of having their own
  discussion topic.
- Topic decorators hold article and place associations. Post controller
  decorators update article comment totals when people reply from the forum.
- Legacy post content includes sanitized HTML and `[[photo=...]]` embeds,
  rendered through `app/views/all/_text_with_photos.html.erb`.
- Subscriptions, moderation groups, visits, signatures, search, notification
  emails, and old URL helpers all have Forem-specific implementations.

## Data mapping

| Existing data | Destination / treatment |
| --- | --- |
| `forem_categories` | `thredded_messageboard_groups`; these group forums, unlike Thredded topic categories |
| `forem_forums` | `thredded_messageboards`; preserve ordering and group membership |
| `forem_topics` | `thredded_topics`; `subject` becomes a plain-text `title`, `forum_id` becomes `messageboard_id`, `pinned` becomes `sticky` |
| `forem_posts` | `thredded_posts`; `text` becomes `content`, `topic_id` becomes `postable_id`; populate `messageboard_id` from the topic |
| `forem_subscriptions` | `thredded_user_topic_follows`; configure notification preferences separately |
| Topic `album_id`, `photo_id`, `trip_report_id`, `place_id` | Additional indexed columns and application associations on Thredded topics |
| `photos.topic_id` | Preserve topic attachment ownership and identifiers, or explicitly remap |
| Place/area `forum_id` | Point associations at messageboards; preserve identifiers or explicitly remap |
| `users.forem_admin` | Use as Thredded's admin flag, or deliberately combine with site administrator privileges |
| Forem moderator group memberships | Implement board-specific moderation; do not silently grant all-board moderation |
| Forem `reply_to_id`, signatures, view counts | Preserve as legacy metadata and add rendering where needed; no automatic equivalent is assumed |
| Historical visits and read state | Keep legacy tables; optionally transform into Thredded tracking after defining equivalent semantics |

Retaining forum, topic, and post primary keys simplifies existing references
and redirects. Import into empty destination tables with a guard against
collisions; reset PostgreSQL sequences afterward. Retain original timestamps
and authors, including a deliberate treatment of deleted/missing users.

Map approved content to approved, pending content to pending moderation, and
spam/rejected content to blocked. Treat hidden topics conservatively: they
must not become public simply because they were approved. Profile the actual
state values and nulls before finalizing the mapping. Thredded can show pending
content publicly by default, so explicitly configure visibility.

Preserve post bodies verbatim in the import. Use a legacy renderer for imported
content, or a separately tested conversion. Thredded's Markdown rendering is
not an automatic replacement for HTML and photo embeds. Topic subjects may
contain article links, so strip markup for titles and retain the article
association to render a dedicated link.

## Implementation sequence

1. Add and lock Thredded; prove development and production asset compilation
   and a browser smoke test with the chosen asset integration.
2. Configure existing Devise users, unique username lookup, `display_name`,
   profile links, sender address, admin rights, and board-specific moderation.
   Audit blank/duplicate usernames before introducing stricter constraints.
3. Install Thredded's schema and add the application association columns,
   including the unique `thredded_messageboards.forem_forum_id` legacy mapping
   required by the step 2 moderator permissions.
   Keep the Forem schema intact. Build a separate import command with a
   read-only preflight and transactional writes. Avoid callback-driven imports
   that send historical notification emails. Refuse an unsafe rerun or provide
   a durable import ledger; do not overwrite new Thredded content.
4. Move article comment creation and display to Thredded. Enforce policy checks
   and locked/blocked topic restrictions on this path as well as forum pages.
   Create the first topic and comment atomically; update cached comment totals
   after creates, edits, moderation changes, and deletions from either UI.
5. Port topic photo attachments and the photo-selection/upload UI. Restrict
   attachment updates to the signed-in user's eligible photos. Replace the
   legacy place-assignment action with an authorized update if retained.
6. Mount at `/fanaticsforum`. Register redirects for old forum/topic/post URLs
   before the engine mount and resolve both IDs and historical slugs. A mount
   at the same prefix alone does not preserve Forem's nested routes. Redirect
   post links through Thredded permalinks so pagination and anchors resolve.
7. Replace navigation, article notification links, search, comment partials,
   and Forem-dependent associations. Choose whether to retain the old active
   and unanswered topic pages as custom queries. Thredded supplies its own
   search; the existing Forem Sphinx index cannot be reused unchanged.
8. Retire decorators and views only after all active references are replaced.
   Retain old tables and a backup through the verification period.

Thredded inherits the host `ApplicationController`. This application's editor
and admin callbacks would restrict ordinary members on some forum actions.
Skip those host role gates specifically within the forum controller and rely
on tested Thredded policies. Keep the site's existing gates for other pages.

## Verification and cutover

Rehearse on a restored database in staging. No production or development data
was imported during this assessment.

- Compare source/destination record counts, association IDs, states, author
  IDs, timestamps, subscriptions, and representative full post bodies.
- Test a guest, ordinary confirmed member, forum admin, and board moderator.
  Verify that pending/hidden/spam content is not exposed to guests.
- Exercise the first article comment, subsequent comments from both UIs,
  locked topics, deleted authors, and comment totals after deletion/moderation.
- Test embedded and attached photos, upload ownership, follow/unfollow,
  notification links, search, legacy numeric/slug URLs, and post permalinks.
- Run relevant Rails tests, eager loading, production asset compilation,
  and browser tests for posting/editing/deleting and pagination.

For cutover, back up the database, temporarily stop forum/comment writes,
drain or pause relevant jobs, run the rehearsed import and verification, then
enable Thredded and resume writes. A rollback after new Thredded posts exist
requires preserving or exporting those writes; retaining Forem tables alone
does not synchronize them back.
