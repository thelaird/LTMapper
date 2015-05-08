require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    columns = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
      SQL

    columns.first.map { |var| var.to_sym }
  end

  def self.finalize!
    columns.each do |var|
      define_method("#{var}") do
        attributes[var]
      end
      define_method("#{var}=") do |val|
        attributes[var] = val
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name.nil? ? self.to_s.tableize : @table_name
  end

  def self.all
    data = DBConnection.execute(<<-SQL)
    SELECT
      *
    FROM
      #{table_name}
    SQL

    parse_all(data)
  end

  def self.parse_all(results)
    objects = []
    results.each { |result| objects << self.new(result) }

    objects
  end

  def self.find(id)
    data = DBConnection.execute(<<-SQL, id)
    SELECT
      *
    FROM
      #{table_name}
    WHERE
      id = ? LIMIT 1
    SQL

    return nil if data.empty?
    self.new(data.first)
  end

  def initialize(params = {})
    params.keys.each do |attr_name|
      unless self.class.columns.include?(attr_name.to_sym)
        raise "unknown attribute '#{attr_name}'"
      else
        attributes[attr_name.to_sym] = params[attr_name]
      end
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    @attributes.values
  end

  def insert
    col_names = self.class.columns.drop(1).join(',')
    question_marks = (["?"] * attribute_values.length).join(',')
    DBConnection.execute(<<-SQL,*attribute_values)
    INSERT INTO
      #{self.class.table_name} (#{col_names})
    VALUES
      (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    set_string = self.class.columns.map { |column| "#{column} = ?" }
    set_string = set_string.join(',')
    DBConnection.execute(<<-SQL, *attribute_values,self.id)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_string}
      WHERE
        id = ?
      SQL

  end

  def save
    self.id.nil? ? insert : update
  end
end
