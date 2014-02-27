# The PROIEL web application [![Build Status](https://travis-ci.org/mlj/proiel-webapp.png)](https://travis-ci.org/mlj/proiel-webapp)

The PROIEL web application (`proiel-webapp`) is a tool for collaborative
treebank annotation. It uses a dependency-grammar formalism with multiple
levels of additional annotation, many of which are customisable.

Installation, customisation and upgrade instructions can be found below. A
description of the data format is found in the `doc` directory.

## Installing

`proiel-webapp` is a Ruby on Rails application. This version uses Rails 3.2 and
Ruby 1.9. Ruby 1.8 will not work. The following instructions assume that you
have a functional Ruby environment with RubyGems and bundler installed.

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

For validation of XML files, `xmllint` from [libxml2](http://www.xmlsoft.org/)
is required.

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

    $ rake generate_env

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

    $ foreman start

If you prefer not to use `foreman`, you will need to start both processes
manually:

    $ bundle exec thin start
    $ bundle exec rake work_jobs

## Upgrading

Upgrading from one version to another normally involves only the following
steps:

    $ bundle install
    $ RAILS_ENV=production bundle exec rake db:migrate

## Customising the application

This section describes some ways of modifying or extending the application.

### Editing locale files

Some key strings used by the application, such as the application's title, can
be modified by editing the files in `config/locales`.

### Adding a dependency graph visualization method

The default plugin for visualization of dependency graphs uses `graphviz`.
As long as you are able to use the `dot` engine from `graphviz`, adding new
visualizations is trivial:

  1. Create a new visualization template in `plugins/graph_visualizers/graphviz`.
     Have a look at the existing ones to see how the templates work.
  2. Add a new visualization choice in
     `app/views/preferences/edit.html.haml`. This will enable users to select
     the visualization method.
  3. Add a new description of the visualization method in `config/locales/en.yml`.

Early testing of new visualisations is probably best done using the Rails
console. To see the `dot` file produced before it is passed to `graphviz`,
you can try the following:

    $ ./script/rails c
    Loading development environment (Rails 3.2.12)
    >> GraphvizVisualization.new(Sentence.first).generate(:format => :dot, :mode => :linearized)

To run it through `graphviz`, change the format to `svg` or `png`:

    >> GraphvizVisualization.new(Sentence.first).generate(:format => :svg, :mode => :linearized)

### Documentation

To generate documentation for developers simply run `rdoc` from the top of the
tree.

## License

The PROIEL web application is licensed under the terms of the GNU General Public
License version 2. See the file `COPYING` for details.

The application was written by Marius L. Jøhndal (University of Cambridge), Dag
Haug (University of Oslo) and Anders Nøklestad (University of Oslo).
