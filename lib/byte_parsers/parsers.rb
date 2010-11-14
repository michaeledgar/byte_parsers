class ByteParser
  class ParsingGroup
    
  end
  
  class DynamicParserError < Exception; end
  
  class Parser
    attr_reader :opts
    def initialize(opts={})
      @opts = opts
    end
    
    # Implement all these methods.
    
    # Is this parser of a fixed size?
    #
    # @return [Boolean] is the parser a fixed size?
    def fixed_size?
      raise NotImplementedError.new('subclasses must implement #fixed_size?')
    end
    
    # Returns the static size of the field (if static). Should raise
    # a DynamicParserError if the field is not of a static size.
    #
    # @return [Integer] static size of the field.
    def static_size
      raise NotImplementedError.new('subclasses must implement #static_size')
    end
    
    # Reads the field in from the input stream
    #
    # @param [IO, #read] input the input stream
    # @return [Object] some object. Could be anything!
    def read(input)
      raise NotImplementedError.new('subclasses must implement #read')
    end
    
    # Writes the field out to the output stream
    #
    # @param [IO, #write] output the output stream
    # @return [Object] some object. Could be anything!
    def write(output)
      raise NotImplementedError.new('subclasses must implement #write')
    end
  end
  
  class BlockParser < Parser
    def initialize(opts={})
      if !(opts[:read_block] && opts[:write_block])
        raise ArgumentError.new("Must provide :read_block and :write_block for BlockParser")
      end
      super
    end
    
    def fixed_size?
      false
    end
    
    def static_size
      raise DynamicParserError.new
    end
    
    def read(input)
      opts[:read_block].call(input)
    end
    
    def write(value, output)
      opts[:write_block].call(value, output)
    end
  end
  
  [[4, 'N', 'V', 'L'], [2, 'n', 'v', 'S'],
   [1, 'C', 'C', 'C']].each do |size, big, little, native|
     # defs are faster than define_method. Though worse.
    preamble =
    <<-EOF
      def fixed_size?; true; end
      def static_size; #{size}; end
      def packing_char
        char = case opts[:endian]
               when :big then '#{big}'
               when :little then '#{little}'
               else '#{native}'
               end
      end
    EOF
    klass = Class.new(Parser)
    const_set("UInt#{size * 8}", klass)
    klass.class_eval(preamble + <<-EOF)
      def read(input)
        input.read(static_size).unpack(packing_char).first
      end
      def write(value, output)
        output.write([value].pack(packing_char))
      end
    EOF
    klass = Class.new(Parser)
    const_set("Int#{size * 8}", klass)
    klass.class_eval(preamble + <<-EOF)
      def read(input)
        result = input.read(static_size).unpack(packing_char).first
        if result >= #{2 ** (size * 8 - 1)}
          result = -1 * (#{2 ** (size * 8)} - result)
        end
        result
      end
      def write(value, output)
        output.write([value].pack(packing_char))
      end
    EOF
  end

  class String < Parser
    def initialize(opts={})
      super
      if !(opts.has_key?(:size) ^ opts.has_key?(:terminator))
        raise ArgumentError.new('Either :size or :terminator must be provided to String parsers')
      end
      if opts[:size]
        raise ArgumentError.new(':size must be an Integer') unless Integer === opts[:size]
      elsif opts[:terminator]
        if !(::String === opts[:terminator] || Proc === opts[:terminator])
          raise ArgumentError.new(':terminator must be a String or a proc.')
        end
      end
    end
    
    def fixed_size?
      opts[:size]
    end
    
    def static_size
      if opts[:size]
      then return opts[:size]
      else raise DynamicParserError.new
      end
    end
    
    def read(input)
      return input.read(opts[:size]) if opts[:size]
      result = ""
      # Extract conditionals to outside of loop
      if ::String === opts[:terminator]
        while (char = input.read(1)) && char != opts[:terminator]
          result << char
        end
      elsif Proc === opts[:terminator]
        while (char = input.read(1)) && !opts[:terminator].call(char)
          result << char
        end
      end
      result
    end
    
    def write(value, output)
      if Proc === opts[:terminator] && !opts[:write_block]
        raise ArgumentError.new('cannot write with a proc :terminator and no :write_block')
      end
      
      if opts[:write_block]
        output.write(value)
        opts[:write_block].call(output)
      elsif opts[:terminator]
        output.write(value)
        output.write(opts[:terminator])
      elsif opts[:size]
        output.write(value[0...opts[:size]])
        padding_size = opts[:size] - value.size
        padding = padding_size <= 0 ? "" : (opts[:padding] || "\0") * padding_size 
        output.write(padding)
      end
    end
  end
  
  class CString < String
    def initialize(opts={})
      super(opts.merge(:terminator => "\0"))
    end
  end

  class FixedString < String
    def initialize(opts={})
      raise ArgumentError.new('FixedString requires :size') unless opts[:size]
      super
    end
  end
end