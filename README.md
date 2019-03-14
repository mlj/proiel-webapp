# PROIEL Annotator [![Build Status](https://travis-ci.org/mlj/proiel-webapp.png)](https://travis-ci.org/mlj/proiel-webapp)

PROIEL Annotator is a tool for collaborative treebank annotation using the PROIEL dependency-grammar formalism and multiple levels of additional annotation.

Installation, customisation and upgrade instructions are found below. See the [wiki](https://github.com/mlj/proiel-webapp/wiki) for more technical information, the [PROIEL framework page](http://proiel.github.io/framework/) for an overview of associated tools and the [PROIEL treebanking handbook](http://proiel.github.io/handbook/) for general instructions.

## Installing

PROIEL Annotator is a Ruby on Rails application. This version uses Ruby on Rails 4.2 and works with MySQL and PostgreSQL on Linux and OS X.

The following instructions assume that you have a functional and up-to-date Ruby environment installed, and that you have already configured your database server. You will need Ruby >= 2.4 to run this application

### Step 1: Install dependencies

Make sure that bundler is installed and then install required dependencies:

```shell
$ gem install bundler
$ bundle install
```

If you only intend to run the application in production mode, you can cut down the number of dependencies this way:

```shell
$ gem install bundler
$ bundle install --without test development
```

### Step 2: Install external binaries

Install [graphviz](http://www.graphviz.org/) for dependency graph visualisations. Versions 2.26.3 and 2.30.1 are known to work, but more recent versions may also work.

`graphviz` must be compiled with SVG support. The recommended settings are the following:

    --with-fontconfig --with-freetype2 --with-pangocairo --with-rsvg

If you want to regenerate the finite-state transducer files, you will also need the [SFST toolkit](http://www.ims.uni-stuttgart.de/projekte/gramotron/SOFTWARE/SFST.html). This release of `proiel-webapp` is designed to work with version 1.3 of `SFST`.

### Step 3: Configure the database

Copy `config/database.yml.example` to `config/database.yml` and edit it to fit your setup.

Initialize a new database by running the following command:

```shell
$ bin/rake db:setup
```

Add an administrator account using the Rails console:

```shell
$ bin/rails c
Loading development environment (Rails 3.1.3)
>> User.create_confirmed_administrator! :login => "username", :first_name => "Foo", :last_name => "Bar", :email => "foo@bar", :password => "foo"
```

### Step 4: Generate an environment file

Generate an environment file by running

```shell
$ bin/rake generate_env
```

This generates a file called `.env` with run-time settings that are unique to this instance of the application. Inspect the contents of the file and edit it if necessary.

The `.env` file contains information that should not be made public. Make sure that other users on your system are unable to read `.env`. It is also not a good idea to add the file to a public version control system.

You may also need to modify `config/initializers/mailer.rb` to get registration e-mails working properly.

### Step 5: Precompile assets

For the production environment, assets should be precompiled:

```shell
RAILS_ENV=production rake assets:precompile
```

If you run the application behind nginx or another webserver, you should ensure that the webserver serves the `public` directory. Otherwise, make sure that `RAILS_SERVE_STATIC_ASSETS` in `.env` is set to `true` so that Rails will serve this directory.

### Step 6: Start the server and worker

Start the server and worker processes:

```shell
$ RAILS_ENV=production foreman start
```

If you prefer not to use `foreman`, you must start the server and worker processes manually:

```shell
$ bundle exec unicorn_rails -E $environment -p $PORT
$ bin/rake work_jobs
```

## Upgrading

See the [wiki](https://github.com/mlj/proiel-webapp/wiki/Versioning-and-upgrading) for upgrade instructions.

## Editing locale files

Some key strings used by the application, such as the application's title, can
be modified by editing the files in `config/locales`.

## Development

For development, run the server using

```shell
$ bin/rails s
```

This will run the server with [spring](https://github.com/rails/spring),
[web-console](https://github.com/rails/web-console) and
[rack-mini-profiler](https://github.com/MiniProfiler/rack-mini-profiler)
enabled. *Make sure that you never run the system like this in production
since it is possible to execute arbitrary commands on the server with
web-console.*

Tests are run using

```shell
$ bin/rake test
$ bin/rspec
```

To open a console, run

```shell
$ bin/rails c
```

## License

PROIEL Annotator is licensed under the terms of the GNU General Public License version 2. See the file `COPYING` for details.

PROIEL Annotator was written by Marius L. Jøhndal (University of Cambridge/University of Oslo), Dag Haug (University of Oslo) and Anders Nøklestad (University of Oslo).
