require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_string = params.keys.map { |key| "#{key} = ?"}
    where_string = where_string.join(' AND ')
    data = DBConnection.execute(<<-SQL,*params.values)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{where_string}
      SQL

    self.parse_all(data)
  end
end

class SQLObject
  extend Searchable
end
