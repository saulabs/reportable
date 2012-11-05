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

Reportable provides helper methods to generate a sparkline image from this data that you can use in your views, e.g.:

    <%= google_report_tag(User.registrations_report) %>

For other options to generate sparklines see the [API docs](http://rdoc.info/projects/saulabs/reportable).


Installation
------------

To install the Reportable gem, simply run

    [sudo] gem install reportable

ORM configuration
-----------------

Currently Reportable still only supports ActiveRecord, but it has now been refactored so it should be easy to add additional ORM adapters. To use Reportable with Active Record in Rails, create an initializer file reportable.rb with the following

    Saulabs::Reportable.orm_adapter :active_record

The _#reportable_ macro should determine which Report to use for a given model, by inspecting the kind of class it is used in (fx if it inherits from ActiveRecord::Base it should use the ActiveRecord::Report)

Generators
----------

To generate the migration that create reportable's cache table (beware that reportable currently only supports ActiveRecord):

    rails generate reportable_migration

If you want to use reportable's JavaScript graph output format, you also have to generate the JavaScript files:

    rails generate reportable_raphael_assets

if you want to use [Raphael](http://raphaeljs.com/) or if you want to use [jQuery](http://jquery.com/) and [flot](http://code.google.com/p/flot/):

    rails generate reportable_jquery_flot_assets


### Rails 3.x

To install Reportable for Rails 3.x, add it to your application's Gemfile:

    gem 'reportable', :require => 'saulabs/reportable'

Generators
----------

To generate the migration that create reportable's cache table (beware that reportable currently only supports ActiveRecord):

    rails generate reportable:migration

Assets
------

If you want to use reportable's JavaScript graph output format, you can copy the JavaScript files to your assets folder:

    rails generate reportable:assets raphael

If you want to use [flot](http://code.google.com/p/flot/):

		rails generate reportable:assets flot

Note: The assets are also included directly in this gem under vendor/assets and will be added to the Rails asset pipeline. 

Plans
-----

* add support for Oracle and MSSQL
* add support for DataMapper
* add more options to generate graphs from the data
* add the option to generate textual reports on the command line


Authors
-------

© 2008-2012 Marco Otte-Witte (<http://simplabs.com>) and Martin Kavalar (<http://www.sauspiel.de>)

Released under the MIT license


Contributors
------------

* Eric Lindvall (<http://github.com/eric>)
* Jan Bromberger (<http://github.com/jan>)
* Jared Dobson (<http://github.com/onesupercoder>)
* Jarod Reid
* Lars Kuhnt (<http://github.com/larskuhnt>)
* Max Schöfmann (<http://github.com/schoefmax>)
* Myron Marston (<http://github.com/myronmarston>)
* Ryan Bates (<http://github.com/ryanb>)
