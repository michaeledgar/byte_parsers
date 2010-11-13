class ByteParser
  Field = Struct.new(:name, :parser, :opts)
  
  def self.new(&blk)
    result = Class.new(ByteParser)
    result.instance_eval(&blk)
    result
  end
  
  def self.fields
    @fields ||= []
  end
  
  def self.add(name, parser, opts={})
    self.fields << Field.new(name, parser, opts)
  end
end