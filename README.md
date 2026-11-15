# README

## Heroku database configuration

Production uses Heroku's `DATABASE_URL` for the primary database and, by default,
Solid Queue, Solid Cache, and Solid Cable. To use separate databases, set
`QUEUE_DATABASE_URL`, `CACHE_DATABASE_URL`, or `CABLE_DATABASE_URL` respectively.

After deploying, run the application migrations:

```sh
heroku run bin/rails db:migrate --app YOUR_APP
```

The Solid tables must also exist. For an existing application database that has
never had these tables installed, load each Solid schema once:

```sh
heroku run 'bin/rails runner "ActiveRecord::Base.establish_connection(:queue); load Rails.root.join(\"db/queue_schema.rb\")"' --app YOUR_APP
heroku run 'bin/rails runner "ActiveRecord::Base.establish_connection(:cache); load Rails.root.join(\"db/cache_schema.rb\")"' --app YOUR_APP
heroku run 'bin/rails runner "ActiveRecord::Base.establish_connection(:cable); load Rails.root.join(\"db/cable_schema.rb\")"' --app YOUR_APP
```

These schema loads recreate their respective Solid tables, so do not run them
against existing queue, cache, or cable data that you need to retain.

Rails 8.0.2's named `db:schema:load` tasks first purge the corresponding test
database. Since this application only defines these named connections in
production, those tasks fail with a nil configuration. The runner commands above
load each schema directly using its configured connection.

To process jobs inside the web dyno using the existing Puma configuration:

```sh
heroku config:set SOLID_QUEUE_IN_PUMA=true --app YOUR_APP
```

Alternatively, run `bin/jobs` in a dedicated worker dyno.

## Heroku email configuration

Production sends email through `smtp.resend.com:465` using TLS, including
Devise password reset instructions. Set `RESEND_API_KEY` in the Heroku dashboard
under Settings → Config Vars to a Resend API key with permission to send email.
The SMTP username is `resend`.

Verify the sender domain `eric-coulthard.com` in Resend. If `NOTIFIER_EMAIL` is
set for application notifications, its domain must also be verified in Resend.

If delivery fails with `Socket::ResolutionError`, check that the SMTP address is
the hostname `smtp.resend.com`, without a URL scheme or path. Authentication
errors indicate a separate issue with the API key. After deploying configuration
changes or correcting credentials, request a new password reset.

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...
