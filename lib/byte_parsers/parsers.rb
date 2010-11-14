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
  end
  
  [[4, 'N', 'V', 'L'], [2, 'n', 'v', 'S'],
   [1, 'C', 'C', 'C']].each do |size, big, little, native|
    klass = Class.new(Parser)
    # defs are faster than define_method. Though worse.
    klass.class_eval(<<-EOF)
      def fixed_size?; true; end
      def static_size; #{size}; end
      def read(input)
        char = case opts[:endian]
        when :big then '#{big}'
        when :little then '#{little}'
        else '#{native}'
        end
        input.read(static_size).unpack(char).first
      end
    EOF
    const_set("UInt#{size * 8}", klass)
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