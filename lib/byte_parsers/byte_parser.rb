# This class is the base for a parser of a series of binary fields from an input,
# and writes them back. The goal is for ByteParser to be both high-level and very
# fast. For those purposes, speedy code should be written first, not last.
# 
# It generates a new class on ByteParser.new and also defines a "Result Class,"
# which is the class which holds the results of a parse or the fields to write.
# In other words, your use your new parser's .read method and .write method to 
class ByteParser
  Field = Struct.new(:name, :parser)
  
  class << self
    attr_accessor :result_class
  end
  
  def self.new(&blk)
    result = Class.new(ByteParser)
    result.result_class = Class.new
    result.instance_eval(&blk)
    result.add_methods
    result.add_write_method
    result
  end
  
  def self.fields
    @fields ||= []
  end
  
  def self.add(name, parser, opts={})
    self.fields << Field.new(name, parser.new(opts))
  end
  
  def self.read(input)
    result = self.result_class.new
    self.fields.each do |field|
      value = field.parser.read(input)
      result.__send__(:instance_variable_set, "@#{field.name}".to_sym, value)
    end
    result
  end

  def self.add_methods
    self.fields.each do |field|
      self.result_class.send(:attr_reader, field.name.to_sym)
      result_class_meta = (class << self.result_class; self; end)
      result_class_meta.class_eval do
        attr_reader "__#{field.name}__parser".to_sym
      end
      self.result_class.send(
          :instance_variable_set, "@__#{field.name}__parser".to_sym, field.parser)
    end
  end
  
  def self.add_write_method
    field_code = self.fields.map do |field|
      "self.class.__#{field.name}__parser.write(#{field.name}, output)"
    end.join("\n")

    self.result_class.class_eval <<-EOF
      def write(output)
        #{field_code}
      end
    EOF
  end
end