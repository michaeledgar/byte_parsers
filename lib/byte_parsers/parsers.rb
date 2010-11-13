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
  
  class UInt32 < Parser
    def fixed_size?
      true
    end
    
    def static_size
      4
    end
    
    def read(input)
      char = opts[:endian] == :big ? 'N' : 'L'
      input.read(static_size).unpack(char).first
    end
  end

  class UInt16 < Parser
    def fixed_size?
      true
    end
    
    def static_size
      1
    end
    
    def read(input)
      char = opts[:endian] == :big ? "n" : "s"
      input.read(static_size).unpack(char).first
    end
  end

  class CString < Parser
    def fixed_size?
      false
    end
    
    def static_size
      raise DynamicParserError.new
    end
    
    def read(input)
      result = ""
      while (char = input.read(1)) && char != "\0"
        result << char
      end
      return result
    end
  end

  class String < Parser
  end

  class FixedString < Parser
    def initialize(*args)
      super
      if !opts[:size]
        raise ArgumentError.new("No :size option provided to FixedString")
      elsif !(Integer === opts[:size])
        raise ArgumentError.new(':size option for FixedString must be an integer.')
      end
    end

    def fixed_size?
      true
    end
    
    def static_size
      opts[:size]
    end
    
    def read(input)
      input.read(static_size)
    end
  end
end