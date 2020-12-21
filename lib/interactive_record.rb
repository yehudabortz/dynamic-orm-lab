require 'pry'
require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord

    def self.table_name
        self.to_s.downcase.pluralize
    end

    def self.column_names
        sql = <<-SQL
        PRAGMA table_info(#{table_name})
        SQL
        table_info = DB[:conn].execute(sql)
        column_names = []
        table_info.each do |column|
            column_names << column["name"]
        end
        column_names
    end

    def initialize(options = {})
        options.each do |property, value|
            self.send("#{property}=", value)
        end
    end

    def table_name_for_insert
        self.class.table_name
    end

    def col_names_for_insert
        self.class.column_names.delete_if {|col| col == "id"}.join(", ")
    end

    def values_for_insert
        values = []
        self.class.column_names[1..-1].each do |col_name|
            values << "'#{send(col_name)}'" unless send(col_name).nil?
        end
        values.join(", ")
        # binding.pry
    end
    
    # def question_marks_for_save
    #     (self.class.column_names[1..-1].count).times.collect{"?"}.join(",")
    # end
    
    def save
            sql = <<-SQL
            INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})
            SQL
            DB[:conn].execute(sql)
            # binding.pry
        @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
    end

    def self.find_by_name(name_to_find)
        sql = <<-SQL
            SELECT *
            FROM #{self.table_name}
            WHERE name = '#{name_to_find}'
        SQL
        DB[:conn].execute(sql)
    end

    def self.find_by(attribute_hash)
        value = attribute_hash.values[0]
        formatted_value = value.class == Fixnum ? value : "'#{value}'"
        sql = <<-SQL
            SELECT *
            FROM #{self.table_name}
            WHERE #{attribute_hash.keys[0]} == #{formatted_value}
        SQL
        DB[:conn].execute(sql)
    end

end