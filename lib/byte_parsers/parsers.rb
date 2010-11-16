class ByteParser
  class ParsingGroup
    
  end
  
  # If #static_size is called on a class with none, this exception is
  # raised.
  class DynamicParserError < Exception; end
  
  # A generic parser class. Its definitions of fixed_size?, static_size,
  # read, and write all make up this parser. Each must be implemented.
  #
  # fixed_size? and static_size exist for one purpose: some parsers take
  # up a static amount of space (a unsigned, 32-bit, big-endian integer
  # is one example). By knowing this information, we can perform optimizations
  # when reading in the parsed data. For example, if a given ByteParser is
  # made up of 8, 32-bit integers, we can read 256 bytes at once, which
  # would be more performant than reading 32 bits 8 times.
  class Parser
    attr_reader :opts
    def initialize(opts={})
      @opts = opts
    end
    
    if RUBY_VERSION >= "1.9"
      # Gets the ascii value of the first byte of the string.
      #
      # @param [String] char the character to read.
      # @return [Integer] the first byte of the string, as an integer.
      def ord(char)
        char.ord
      end
    else
      # Gets the ascii value of the first byte of the string.
      #
      # @param [String] char the character to read.
      # @return [Integer] the first byte of the string, as an integer.
      def ord(char)
        char[0]
      end
    end
    
    # Sets the class's static size. Helper for defining the
    # fixed_size? and static_size methods.
    #
    # @param [Integer] bytes the number of bytes this field uses.
    def self.static_size(bytes)
      if !(Integer === bytes)
        raise ArgumentError.new('number of bytes must be an Integer')
      end
      class_eval(<<-EOF)
        def fixed_size?; true; end
        def static_size; #{bytes}; end
      EOF
    end
    
    # Sets the class to be a dynamic class, which never has a static size.
    #
    # @param [Integer] bytes the number of bytes this field uses.
    def self.dynamic_size
      class_eval(<<-EOF)
        def fixed_size?; false; end
        def static_size; raise DynamicParserError.new; end
      EOF
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
    
    # This is run once - at load time - to determine endianness.
    
    # Figures up the system is running on a little or big endian processor
    # architecture, and upates the SYSTEM[] hash in the Support module.
    def self.determine_endianness
      num = 0x12345678
      native = [num].pack('l')
      netunpack = native.unpack('N')[0]
      if num == netunpack
        @endian = :big
      else
        @endian = :little
      end
    end
    determine_endianness
    
    # For later lookup: the native endian format.
    #
    # @return [Symbol] either :big or :little
    def self.native_endian
      @endian
    end
    
    # For later lookup: the native endian format.
    #
    # @return [Symbol] either :big or :little
    def native_endian
      Parser.native_endian
    end
    
    # Returns the endian to use: :little or :big. The issue
    # arises when users provide :native, which means we now need to compare
    # versus our native endian.
    #
    # @return [Symbol] either :big or :little, whichever should be used based
    #   on opts[:endian]
    def endian
      case opts[:endian]
      when :big then :big
      when :little then :little
      when :native then native_endian
      end
    end
  end
  
  # This parser has two blocks: a read block, and a write block.
  #
  # The read block receives an input stream, and must return a value,
  # presumably based on some data read from the input stream.
  #
  # The write block receives a value and an output stream, and should
  # write that value with some encoding to the output stream.
  class BlockParser < Parser
    # Initializes the block parser. This override simply verifies the
    # input options, namely that both :read_block and :write_block are
    # present.
    #
    # @raise ArgumentError if :read_block and :write_block are not present,
    #   this parser fails verification.
    def initialize(opts={})
      if !(opts[:read_block] && opts[:write_block])
        raise ArgumentError.new("Must provide :read_block and :write_block for BlockParser")
      end
      super
    end
    
    # Always a dynamic size, since we can't introspect the blocks. However,
    # subclasses could override this if the blocks happen to use a fixed
    # amount of space on all invocations.
    dynamic_size
    
    # Runs the read block to read a value from the input stream.
    #
    # @param [IO, #read] input the input stream to read through.
    # @return [Object] the value read from the stream
    def read(input)
      opts[:read_block].call(input)
    end
    
    # Runs the write block to write the value to the output stream.
    #
    # @param [Object] value the value to write.
    # @return [IO, #write] output the output stream to write to.
    def write(value, output)
      opts[:write_block].call(value, output)
    end
  end
  
  # This creates 2 classes for each input array, for unsigned and
  # signed integers of 1, 2, and 4 bytes. It usees String#unpack
  # and Array#pack to do its magic.
  #
  # The following arrays are in the form:
  # [size, big-endian-pack-char, little-endian-pack-char,]
  [[4, 'N', 'V'], [2, 'n', 'v'],
   [1, 'C', 'C']].each do |size, big, little|
     # defs are faster than define_method. Though worse.
    preamble =
    <<-EOF
      static_size #{size}
      def packing_char
        char = case endian
               when :big then '#{big}'
               when :little then '#{little}'
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

  # This is a parser for a non-uniform length, Base 128
  # integer. The MSB of each byte indicates whether to read
  # an additional byte.
  class Base128 < Parser
    dynamic_size
    
    # Reads the Base128 from the input stream. How we handle this
    # is quite different based on the endianness of the stream.
    # The conditional is hoisted so the loops can go quicker.
    #
    # @param [IO, #read] input the input stream to read
    # @return [Integer] an integer of any size
    def read(input)
      result = 0
      if endian == :little
        shift = 0
        begin
          byte = ord input.read(1)
          result |= (byte & 0x7f) << shift
          shift += 7
        end while (byte & 0x80) > 0
      else
        begin
          byte = ord input.read(1)
          result = (result << 7) | (byte & 0x7f)
        end while (byte & 0x80) > 0
      end
      result
    end
    
    # Writes the Base128 to the input stream. How we handle this
    # is quite different based on the endianness of the stream.
    # The conditional is hoisted so the loops can go quicker.
    #
    # @param [Integer] an integer of any size
    # @param [IO, #read] output the output stream to write to
    def write(value, output)
      if endian == :little
        begin
          byte, value = (value & 0x7f), (value >> 7)
          byte = 0x80 | byte if value > 0
          output.write(byte.chr)
        end while value > 0
      else
        result_bytes = []
        begin
          byte, value = (value & 0x7f), (value >> 7)
          byte = 0x80 | byte if !result_bytes.empty?
          result_bytes << byte.chr
        end while value > 0
        result_bytes.reverse.each {|x| output.write x}
      end
    end
  end

  # This is a parser for generic String behavior. It handles both fixed-size
  # strings and strings with terminators. In order to use it, only ONE of
  # :size or :terminator may be provided, to specialize the String's behavior.
  #
  # This class is public because complex behavior may be necessary. However,
  # you should use one of the simpler subclasses (CString and FixedSize) if
  # your needs fall under their capabilities.
  #
  # When used with an Integer :size option, the parser always reads that many
  # bytes from input. It always writes that many bytes, padded with its :padding
  # option (defaults to the null byte).
  #
  # When reading with a :terminator option, a few behaviors are possible:
  #   * If :terminator is a String, reading stops after the terminator is read.
  #     it is not appended to the result, but it is consumed from the input.
  #   * If :terminator is a Proc, then the proc is called with each consumed 
  #     character as an argument. When the Proc returns true, reading stops.
  #     The character that causes the proc to be true is *not* appended to the
  #     resulting string.
  # When writing with a :terminator option, two behaviors are again possible:
  #   * If :terminator is a String, the value is written and then the terminator
  #     is written to the output.
  #   * If :terminator is a Proc, then :write_block *must* be provided, and it
  #     to must be a proc. It is called with the given value (string) being
  #     written as well as an output stream.
  class String < Parser
    # Initializes the parser and verifies that its options are consistent.
    #
    # @raise ArgumentError if neither :size nor :terminator are provided
    # @raise ArgumentError if :size is provided but is not an integer
    # @raise ArgumentError if :terminator is neither a String nor a Proc
    # @raise ArgumentError if :terminator is a Proc but :write_block is not
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
        if Proc === opts[:terminator] && !(Proc === opts[:write_block])
          raise ArgumentError.new('cannot have a proc :terminator and :write_block is not a Proc')
        end
      end
    end
    
    # Returns if the size is fixed or not.
    #
    # @return is the size fixed?
    def fixed_size?
      opts[:size]
    end
    
    # Returns the static size of the String parser, or raises if there is
    # none.
    #
    # @return [Integer] the static size of the parser's input/output representation
    # @raise DynamicParserError if the parser is not of a fixed size
    def static_size
      if opts[:size]
      then return opts[:size]
      else raise DynamicParserError.new
      end
    end
    
    # Reads the string in from the input stream and returns it. See the
    # description of the class for more details on this algorithm.
    #
    # @see ByteParser::String
    # @param [IO, #read] input the input stream to read from
    # @return [String] a string from the input
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
    
    # Writes a given string to the output stream. See the description of
    # the class for more details on this algorithm.
    #
    # @see ByteParser::String
    # @param [String] value a string to write
    # @param [IO, #write] output the output stream to write from
    def write(value, output)
      if opts[:write_block]
        opts[:write_block].call(value, output)
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
  
  # This is a simple parser for a null-terminated string.
  class CString < String
    def initialize(opts={})
      super({:terminator => "\0"}.merge(opts))
    end
  end

  # A simple parser for a fixed-size string. Provides a more specialized
  # error warning during creation if improperly declared.
  class FixedString < String
    def initialize(opts={})
      raise ArgumentError.new('FixedString requires :size') unless opts[:size]
      super
    end
  end
end