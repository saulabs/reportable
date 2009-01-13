supported_databases = [
#  'ActiveRecord::ConnectionAdapters::PostgreSQLAdapter',
#  'ActiveRecord::ConnectionAdapters::MysqlAdapter',
#  'ActiveRecord::ConnectionAdapters::SQLite3Adapter'
]

unless supported_databases.include?(ActiveRecord::Base.connection.class.to_s)
  puts <<-EOT
    =====================================
    Your database #{ActiveRecord::Base.connection.class} is not supported by reports_as_sparkline
    =====================================
  EOT
end
