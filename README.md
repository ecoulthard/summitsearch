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
heroku run bin/rails db:schema:load:queue --app YOUR_APP
heroku run bin/rails db:schema:load:cache --app YOUR_APP
heroku run bin/rails db:schema:load:cable --app YOUR_APP
```

These schema loads recreate their respective Solid tables, so do not run them
against existing queue, cache, or cable data that you need to retain.

To process jobs inside the web dyno using the existing Puma configuration:

```sh
heroku config:set SOLID_QUEUE_IN_PUMA=true --app YOUR_APP
```

Alternatively, run `bin/jobs` in a dedicated worker dyno.

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
