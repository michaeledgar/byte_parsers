# This class is the base for a parser of a series of binary fields from an input,
# and writes them back. The goal is for ByteParser to be both high-level and very
# fast. For those purposes, speedy code should be written first, not last.
# 
# It generates a new class on ByteParser.new and also defines a "Result Class,"
# which is the class which holds the results of a parse or the fields to write.
# In other words, your use your new parser's .read method and the result class's
# #write method to serialize and deserialize all the fields at once.
class ByteParser
  # We need to hold a (name, parser) tuple, and structs are faster.
  Field = Struct.new(:name, :parser)
  
  class << self
    # This is the class that our results will be wrapped in.
    attr_accessor :result_class
  end
  
  # This creates a new Parser class and a new Parse Result class, based on how
  # the consumer configures the Parser in the given block.
  def self.new(&blk)
    result = Class.new(ByteParser)
    result.result_class = Class.new
    result.instance_eval(&blk)
    result.add_methods
    result
  end
  
  # Returns the fields in the parser.
  #
  # @return [Array<ByteParser::Field>] the fields added to the parser so far.
  def self.fields
    @fields ||= []
  end
  
  # Adds a new field to the parser.
  #
  # @param [String] name the name of the field (used for generated method names)
  # @param [Parser] parser the parser class to instantiate
  # @param [Hash] opts the options for the given parser (passed during
  #    instantiation)
  def self.add(name, parser, opts={})
    self.fields << Field.new(name, parser.new(opts))
  end
  
  # Reads the entire parser from an input stream. Returns a new instance of
  # the designated result class for this parser class, populated with the
  # results of the parse.
  #
  # @param [IO, #read] input the input stream to parse from
  # @return [Object] an instance of the result_class Class populated with
  #    the data parsed off the wire.
  def self.read(input)
    result = self.result_class.new
    self.fields.each do |field|
      value = field.parser.read(input)
      result.__send__(:instance_variable_set, "@#{field.name}".to_sym, value)
    end
    result
  end

  # Adds auto-generated methods to the result class now that we know all
  # the fields we have to manage. We add these methods later because we
  # can perform optimizations at this point.
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
    add_write_method
  end
  
  # Adds the write method to the result class which writes each parser
  # and each field. To do this, we have to use the private class method
  # __#{field.name}__parser to know how to parse each field.
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