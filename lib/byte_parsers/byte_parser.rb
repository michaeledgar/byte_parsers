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
    end
  end
end