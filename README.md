# Summit Search Mountain Community

This is the source code for [summitsearch.org](http://www.summitsearch.org).

We believe in free and open access to mountain information. Our site summitsearch.org is designed to be a friendly and easy to use place to find information or share experiences and photos. Help us to grow our community by spreading the word or contributing content to the site.

If you are a developer then your help in designing and implementing this site would be greatly appreciated. The site is written using the Ruby on Rails framework. Knowledge of programming in that framework is a necessary pre-requisite to developing the site.


# Installation

## Dependencies

There are a number of things you need to install before you can run summitsearch locally.

* [Git](https://www.google.ca/search?q=git+scm)
* [Ruby 2.2.4p230](https://www.google.ca/search?q=ruby+on+rails)
* [Rails 4.1.16](https://www.google.ca/search?q=ruby+programming)
* [Postgresql 9.5.6] (https://www.google.ca/search?q=postgresql)
    * Create a [pgpass file] (https://www.google.ca/search?q=pgpass+file)
    * The development database is currently named "summitsearch" in the database.yml file. So use that name in your pgpass file.
* [Sphinx search](https://www.google.ca/search?q=install+thinking+sphinx)
    * Make sure you configure sphinx to use postgresql.
* [Redis server](https://www.google.ca/search?q=redis)

## Getting Started


First you'll need to fork and clone this repo

```bash
git clone https://github.com/ecoulthard/summitsearch.git
```

Let's get all our dependencies setup:
```bash
bundle install --without production
```

Now let's create the database:
```bash
bundle exec rake db:migrate
```

Now let's index sphinx search:
```bash
bundle exec rake ts:index
```

You'll need to set a few environment variables used in config/application.rb. You'll need to figure out how to set environment variables on the specific operating system you are using.

* SECRET\_KEY\_BASE
  * This can be anything on dev.
* NOTIFIER\_EMAIL
  * You will need to set this to a gmail address for notifications to work.
* NOTIFIER\_EMAIL\_PASSWORD
  * This will be the password to the gmail account.
* FACEBOOK\_APP\_ID
  * This is only used to get the facebook like buttons working. You can set it to anything for development.
* GOOGLE\_MAPS\_API\_KEY
  *  This is used to get Google maps working. A lot of functionality depends on Google maps so you should probably get your own key from Google. [Google Maps Api Key](https://www.google.ca/search?q=Google+Maps+Api+key)
* MY\_TOPO\_PARTNER\_ID
  *  This is used to get topo maps working on the Google maps. You can set it to anything for dev.
* MY\_TOPO\_HEX\_DIGEST
  *  This is used to get topo maps working on the Google maps. You can set it to anything for dev.
* DEVISE\_PEPPER
  * This is used for user account passwords. It can be anything on dev since the accounts are fake. 
* DEVISE\_SECRET\_KEY
  * This is used for user account passwords. It can be anything on dev since the accounts are fake. 
	

Let's get it running.

Start thinking sphinx search:
```bash
bundle exec rake ts:start
```

Start Sidekiq:
```bash
bundle exec sidekiq 
```

Start Rails
```bash
bundle exec rails server
```

# Contributing

One of the things that I could use help with is upgrading summitsearch to newer versions of ruby and rails. Upgrading usually introduces a lot of bugs and is time consuming.

