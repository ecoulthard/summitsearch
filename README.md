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

Production sends email through `smtp.gmail.com:587` using STARTTLS, including
Devise password reset instructions. Set these Heroku config vars:

* `NOTIFIER_EMAIL`: the full Gmail or Google Workspace account email address.
* `NOTIFIER_EMAIL_PASSWORD`: a Google app password for that account, rather than
  its regular sign-in password. App passwords require two-step verification and
  must be allowed by the account's security policy.

Set the values in the Heroku dashboard under Settings → Config Vars. Google app
passwords can be managed at https://myaccount.google.com/apppasswords.

If password resets fail in `Net::SMTP::AuthLogin#auth`, inspect the exception
message immediately before the backtrace:

```sh
heroku logs --num 300 --app summitsearch-v2
```

A `535` response usually indicates rejected credentials; `534` may indicate an
app password or another Google account security requirement. Use Google's full
response to identify the cause. After correcting the credentials, request a new
password reset from the application.

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
