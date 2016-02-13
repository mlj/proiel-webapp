# The PROIEL web application [![Build Status](https://travis-ci.org/mlj/proiel-webapp.png)](https://travis-ci.org/mlj/proiel-webapp)

The PROIEL web application (`proiel-webapp`) is a tool for collaborative
treebank annotation. It uses a dependency-grammar formalism with multiple
levels of additional annotation, many of which are customisable.

Installation, customisation and upgrade instructions can be found below. A
description of the data format is found in the `doc` directory.

## Installing

`proiel-webapp` is a Ruby on Rails application. This version uses Ruby on Rails
3.2 and requires Ruby 2.1.

The following instructions assume that you have a functional Ruby environment
with RubyGems and bundler installed.

### Step 1: Install dependencies

Install required dependencies:

    $ bundle

If you only intend to run the application in production mode (with or without
customisations), you will not need support for the application's testing and
development modes:

    $ bundle install --without test development

### Step 2: Install external binaries

Install [graphviz](http://www.graphviz.org/) for dependency graph
visualisations. Versions 2.26.3 and 2.30.1 are known to work with this release
of the PROIEL application, but more recent versions may also work. `graphviz`
must be compiled with SVG support. The recommended configuration settings are
the following:

    --with-fontconfig --with-freetype2 --with-pangocairo --with-rsvg

### Step 3: Install optional external binaries

_This step is optional_. If you want to be able to regenerate the finite-state
transducer files, you will also need to install the [SFST
toolkit](http://www.ims.uni-stuttgart.de/projekte/gramotron/SOFTWARE/SFST.html).
This release of `proiel-webapp` is designed to work with version 1.3 of `SFST`.

### Step 4: Configure the database

Copy `config/database.yml.example` to `config/database.yml` and edit it to fit
your setup.

Initialize a new database by running the following command:

    $ bundle exec rake db:setup

Add an administrator account by using Rails' console interface:

    $ ./script/rails c
    Loading development environment (Rails 3.1.3)
    >> User.create_confirmed_administrator! :login => "username", :first_name => "Foo", :last_name => "Bar", :email => "foo@bar", :password => "foo"

### Step 5: Generate an environment file

Generate an environment file by running

    $ bundle exec rake generate_env

This generates a file called `.env` containing run-time settings that are
unique to this instance of the application. Inspect the contents of this file
and edit it if necessary.

The `.env` file contains some information that sould not be made public (e.g.
in a version control system). If you are using a multi-user system and/or
configuring a production instance, you should verify that other users are
unable to read `.env`.

You may also need to modify `config/initializers/mailer.rb` to get registration
e-mails working properly.

### Step 6: Start the server and worker

Start the server and worker processes:

    $ RAILS_ENV=production foreman start

If you prefer not to use `foreman`, you will need to start both processes
manually:

    $ bundle exec unicorn_rails -E $environment -p $PORT
    $ bundle exec rake work_jobs

If you are doing development, a simpler way is to use Rails' default server:

    $ rails s

Do not use this in a production environment!

## Upgrading

Upgrading from one version to another normally involves only the following
steps:

    $ bundle install
    $ RAILS_ENV=production bundle exec rake db:migrate

## Editing locale files

Some key strings used by the application, such as the application's title, can
be modified by editing the files in `config/locales`.

## Documentation

To generate documentation for developers simply run `rdoc` from the top of the
tree.

## License

The PROIEL web application is licensed under the terms of the GNU General Public
License version 2. See the file `COPYING` for details.

The application was written by Marius L. Jøhndal (University of Cambridge), Dag
Haug (University of Oslo) and Anders Nøklestad (University of Oslo).

The icons on the site are taken from the following collections:

* [Sweetie](http://sweetie.sublink.ca/) icons by Joseph North (<a href="http://creativecommons.org/licenses/by-sa/3.0/">Creative Commons Attribution-ShareAlike</a>)
* [Iconize](http://pooliestudios.com/projects/iconize/) by Alexander Kaiser and Mark James (<a href="http://creativecommons.org/licenses/by/2.5/">Creative Commons Attribution License</a>)
