v1.5.0
------
* Upgrade to ruby 2.3.1

v1.4.2
------
* Revert "Make ResultSet enumerable"

v1.4.0
------

* rename model_name to model_class_name for rails 4.2 compatibility

    to update, you must generate and run the migration

    	bundle exec rails generate reportable_model_name_migration
    	bundle exec rake db:migrate
* Make ResultSet enumerable

v1.1.2
------

* pushed a faulty version to Rubygems - need to use a new version number for the fixed version

v1.1.1
------

* not including the whole Saulabs::Reportable namespace into ActiveRecord anymore.

v1.1.0
------

* added configuration options
* added support for Rails 3
* added generator for the packaged RaphaelJs
* added generator for the packaged jQuery flot
* moved tag helper to ReportTagHelper
* added the ResultSet class that allows access to the model name and report name via the resulting data

v1.0.3
------

* Fixed bug in reportable method that broke cumulated reports and reports with options

v1.0.2
------

* Fixed the migration template

v1.0.1
------

* Fixed a bug with PostgreSQL

v1.0.0
------

* Initial release of the new Reportable gem (formerly known as the ReportsAsSparkline plugin)