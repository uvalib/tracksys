class DropSqlReports < ActiveRecord::Migration
  def up
     drop_table :sql_reports if ActiveRecord::Base.connection.table_exists? 'sql_reports'
  end

  def down
     #not reversable
  end
end
