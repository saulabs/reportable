Reportable
==========

Reportable allows for the easy creation of reports based on `ActiveRecord` models.


Usage
-----

Usage is pretty easy. To declare a report on a model, simply define that the model provides a report:

    class User < ActiveRecord::Base

      reportable :registrations, :aggregation => :count

    end

The `reportable` method takes a bunch more options which are described in the [API docs](http://rdoc.info/projects/saulabs/reportable). For example you could generate a report on
the number of updated users records per second or the number of registrations of users that have a last name that starts with `'A'` per month:

    class User < ActiveRecord::Base

      reportable :last_name_starting_with_a_registrations, :aggregation => :count, :grouping => :month, :conditions => ["last_name LIKE 'A%'"]

      reportable :updated_per_second, :aggregation => :count, :grouping => :hour, :date_column => :updated_at

    end

For every declared report a method is generated on the model that returns the date:

    User.registrations_report

    User.last_name_starting_with_a_registrations_report

    User.updated_per_second_report


Working with the data
---------------------

The data is returned as an `Array` of `Array`s of `DateTime`s and `Float`s, e.g.:

    [
      [DateTime.now,          1.0],
      [DateTime.now - 1.day,  2.0],
      [DateTime.now - 2.days, 3.0]
    ]

Reportable provides a helper method to generate a sparkline image from this data that you can use in your views:

    <%= report_tag(User.registrations_report) %>


Installation
------------

To install the Reportable gem, simply run

    [sudo] gem install reportable

### Rails 2.x

To install Reportable for Rails 2.x, add it to your application's dependencies in your `environment.rb`:

    config.gem 'reportable', :lib => 'saulabs/reportable'

and generate the migration that creates Reportable's cache table:

    ./script/generate reportable_migration create_reportable_cache

Run the generated migration as the last step:

    rake db:migrate

### Rails 3.0

To install Reportable for Rails 3.0, add it to your application's Gemfile:

    gem 'reportable', :require => 'saulabs/reportable'

and generate the migration that creates Reportable's cache table:

    ./script/generate reportable_migration

Run the generated migration as the last step:

    rake db:migrate


Plans
-----

* add support for Oracle and MSSQL
* add support for DataMapper
* add more options to generate graphs from the data
* add the option to generate textual reports on the command line


Authors
-------

© 2008-2010 Marco Otte-Witte (<http://simplabs.com>), Martin Kavalar (<http://www.sauspiel.de>)

Released under the MIT license