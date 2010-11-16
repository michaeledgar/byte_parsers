require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe ByteParser::Parser do
  describe 'ByteParser.static_size' do
    it 'attaches #fixed_size? and #static_size methods to a class' do
      klass = Class.new(ByteParser::Parser) { static_size 17 }
      instance = klass.new
      instance.fixed_size?.should be_true
      instance.static_size.should == 17
    end
    it 'raises if the number of bytes is not an integer' do
      lambda {
        klass = Class.new(ByteParser::Parser) { static_size 3.14 }
      }.should raise_error(ArgumentError)
    end
  end
  
  describe 'a subclass that does not override ' do
    before do
      subclass = Class.new(ByteParser::Parser)
      @instance = subclass.new
    end
    [['#fixed_size?', 0], ['#static_size', 0], ['#read', 1],
     ['#write', 1]].each do |method, arity|
      describe method do
        it 'raises when not overridden' do
          lambda {
            @instance.send(method[1..-1].to_sym, *([nil] * arity))
          }.should raise_error(NotImplementedError)
        end
      end
    end
  end
  
  describe '#native_endian' do
    it 'returns :big or :little' do
      [:big, :little].should include(ByteParser::Parser.new.native_endian)
    end
  end
  
  describe '.native_endian' do
    it 'returns :big or :little' do
      [:big, :little].should include(ByteParser::Parser.new.native_endian)
    end
  end
  
  describe '#endian' do
    it 'returns :little when opts[:endian] is :little' do
      ByteParser::Parser.new(:endian => :little).endian.should == :little
    end
    it 'returns :big when opts[:endian] is :big' do
      ByteParser::Parser.new(:endian => :big).endian.should == :big
    end
    it 'returns the native endian when opts[:endian] is :native' do
      parser = ByteParser::Parser.new(:endian => :native)
      parser.endian.should == parser.native_endian
    end
  end
end

describe ByteParser::BlockParser do
  parser = ByteParser::BlockParser.new(:read_block => proc { |input|
    a, b = input.read(1), input.read(1)
    a > b ? (a + input.read(1)) : b
  }, :write_block => proc { |value, output|
      output.write((value * 3).to_s)
  })
  
  is_not_fixed parser
  no_static_size parser
  
  describe '#initialize' do
    it 'raises if :read_block is not provided' do
      lambda { ByteParser::BlockParser.new(:write_block => 1) }.should raise_error(ArgumentError)
    end
    
    it 'raises if :write_block is not provided' do
      lambda { ByteParser::BlockParser.new(:read_block => 1) }.should raise_error(ArgumentError)
    end
  end
  
  describe '#read' do
    reads 'bac', 'bc', 'reads 3 characters if the first is greater than the second', parser
    reads 'abc', 'b', 'returns the second character if the first is <= the second', parser
  end
  
  describe '#write' do
    writes 5, '15', 'write the value using #write_block', parser
    writes 'hi', 'hihihi', 'write the value using #write_block again', parser
  end
end

describe ByteParser::UInt32 do
  parser = ByteParser::UInt32.new(:endian => :little)
  be_parser = ByteParser::UInt32.new(:endian => :big)

  is_fixed parser
  static_size 4, parser
  
  describe '#read' do
    reads "\x01\x02\x03\x04blahblah", 0x04030201, 'reads a simple little-endian uint32', parser
    reads "\x01\x02\x03\x04blahblah", 0x01020304, 'reads a simple big-endian uint32', be_parser
  end
  
  describe '#write' do
    writes 0x01020304, "\x04\x03\x02\x01", 'writes a simple little-endian uint32', parser
    writes 0x01020304, "\x01\x02\x03\x04", 'writes a simple big-endian uint32', be_parser
  end
end

describe ByteParser::UInt16 do
  parser = ByteParser::UInt16.new(:endian => :little)
  be_parser = ByteParser::UInt16.new(:endian => :big)

  is_fixed parser
  static_size 2, parser
    
  describe '#read' do
    reads "\x01\x02blahblah", 0x0201, 'reads a simple little-endian uint16', parser
    reads "\x01\x02blahblah", 0x0102, 'reads a simple big-endian uint16', be_parser
  end
  
  describe '#write' do
    writes 0x0102, "\x02\x01", 'writes a simple little-endian uint16', parser
    writes 0x0102, "\x01\x02", 'writes a simple big-endian uint16', be_parser
  end
end

describe ByteParser::UInt8 do
  parser = ByteParser::UInt8.new(:endian => :little)
  be_parser = ByteParser::UInt8.new(:endian => :big)

  is_fixed parser
  static_size 1, parser
    
  describe '#read' do
    reads "\xcbblahblah", 0xcb, 'reads a simple little-endian uint8', parser
    reads "\xcbblahblah", 0xcb, 'should be unaffected by endianness', be_parser
  end
  
  describe '#write' do
    writes 0x01, "\x01", 'writes a simple little-endian uint8', parser
    writes 0x01, "\x01", 'should be unaffected by endianness', be_parser
  end
end

describe ByteParser::Int32 do
  parser = ByteParser::Int32.new(:endian => :little)
  be_parser = ByteParser::Int32.new(:endian => :big)

  is_fixed parser
  static_size 4, parser
    
  describe '#read' do
    reads "\x01\x02\x03\x04blahblah", 0x04030201, 'reads a simple little-endian int32', parser
    reads "\x01\x02\x03\x04blahblah", 0x01020304, 'reads a simple big-endian int32', be_parser
    reads 0xfe.chr + 0xf0.chr + 0xff.chr + 0xff.chr, 
          -15 * (2 ** 8) - 2, 'converts overflowed signed values to negatives', parser
    reads 0xfe.chr + 0xf0.chr + 0xff.chr + 0xff.chr, (-1 * (2 ** 24)) - (15 * (2 ** 16)) - 1,
          'is switches endian first when converting overflow', be_parser
  end
  
  describe '#write' do
    writes 0x01020304, "\x04\x03\x02\x01", 'writes a simple little-endian uint32', parser
    writes 0x01020304, "\x01\x02\x03\x04", 'writes a simple big-endian uint32', be_parser
  end
end

describe ByteParser::Int16 do
  parser = ByteParser::Int16.new(:endian => :little)
  be_parser = ByteParser::Int16.new(:endian => :big)

  is_fixed parser
  static_size 2, parser
    
  describe '#read' do
    reads "\x01\x02blahblah", 0x0201, 'reads a simple little-endian uint16', parser
    reads "\x01\x02blahblah", 0x0102, 'reads a simple big-endian int16', be_parser
    reads 0xfe.chr + 0xf0.chr, -15 * 256 - 2, 'converts overflowed signed values to negatives', parser
    reads 0xfe.chr + 0xf0.chr, -256 - 16, 'is switches endian first when converting overflow', be_parser
  end
  
  describe '#write' do
    writes 0x0102, "\x02\x01", 'writes a simple little-endian uint16', parser
    writes 0x0102, "\x01\x02", 'writes a simple big-endian uint16', be_parser
  end
end

describe ByteParser::Int8 do
  parser = ByteParser::Int8.new(:endian => :little)
  be_parser = ByteParser::Int8.new(:endian => :big)

  is_fixed parser
  static_size 1, parser
    
  describe '#read' do
    reads "\x31blahblah", 0x31, 'reads a simple little-endian int8', parser
    reads "\x7bblahblah", 0x7b, 'should be unaffected by endianness', be_parser
    reads "\xfe", -2, 'converts overflowed signed values to negatives', parser
    reads "\xfe", -2, 'is unaffected by endian when converting overflow', be_parser
  end
  
  describe '#write' do
    writes 0x01, "\x01", 'writes a simple little-endian int8', parser
    writes 0x01, "\x01", 'should be unaffected by endianness', be_parser
  end
end


describe ByteParser::Base128 do
  parser = ByteParser::Base128.new(:endian => :little)
  be_parser = ByteParser::Base128.new(:endian => :big)

  is_not_fixed parser
  no_static_size parser

  describe '#read' do
    reads "\x37blahblah", 0x37, 'reads a simple one-byte, little-endian Base128', parser
    reads "\xb7\x02blahblah", 0x137, 'reads a simple two-byte, little-endian Base128', parser
    reads "\xd5\x82\x38blah", 0xe0155, 'reads a three-byte, little-endian Base128', parser
    reads "\x37blahblah", 0x37, 'reads a simple one-byte, big-endian Base128', be_parser
    reads "\xb7\x02blahblah", 0x1b82, 'reads a simple two-byte, big-endian Base128', be_parser
    reads "\xd5\x82\x38blah", 0x154138, 'reads a three-byte, big-endian Base128', be_parser
  end

  describe '#write' do
    writes 0x37, "\x37", 'writes a 1-byte little-endian Base128', parser
    writes 0x137, "\xb7\x02", 'writes a 2-byte little-endian Base128', parser
    writes 0xe0155, "\xd5\x82\x38", 'writes a 3-byte little-endian Base128', parser
    writes 0x37, "\x37", 'writes a 1-byte big-endian Base128', be_parser
    writes 0x1b82, "\xb7\x02", 'writes a 2-byte big-endian Base128', be_parser
    writes 0x154138, "\xd5\x82\x38", 'writes a 3-byte big-endian Base128', be_parser
  end
  
  describe 'randomized testing' do
    10.times do
      x = rand(2 ** 32)
      [parser, be_parser].each do |parser_chosen|    
        title = parser_chosen == parser ? 'little' : 'big'    
        it "reads back the same random #{title}-endian value written: #{x}" do
          output = StringIO.new
          parser_chosen.write(x, output)
          output.rewind
          parser_chosen.read(output).should == x
          p output.string
        end
      end
    end
  end
end

describe ByteParser::String do
  size_parser = ByteParser::String.new(:size => 3)
  term_parser = ByteParser::String.new(:terminator => "7")
  # terminates on 0, 3, 6, or 9
  term_proc_parser = ByteParser::String.new(
      :terminator => proc {|x| x.to_i % 3 == 0},
      :write_block => proc {|v,o| o.write(v.to_s * 3)})
  
  describe '#initialize' do
    it 'raises if no :size or :terminator is provided' do
      lambda { ByteParser::String.new }.should raise_error(ArgumentError)
    end
    it 'raises if :size is a non-Integer' do
      lambda {
        ByteParser::String.new(:size => 3.14)
      }.should raise_error(ArgumentError)
    end
    it 'raises if :terminator is not a String or Proc' do
      lambda {
        ByteParser::String.new(:terminator => 3.14)
      }.should raise_error(ArgumentError)
    end
    it 'raises if :terminator is a Proc and :write_block is a non-Proc' do
      lambda { 
        ByteParser::String.new(:terminator => proc {|x|}, :write_block => 'hai')
      }.should raise_error(ArgumentError)
    end
  end
  
  is_fixed size_parser
  is_not_fixed term_parser
  is_not_fixed term_proc_parser

  static_size 3, size_parser
  no_static_size term_parser
  no_static_size term_proc_parser
  
  describe '#read' do
    reads 'abcdefg', 'abc', 'reads the fixed number of bytes', size_parser
    reads 'abcdef7ajmilc', 'abcdef', 'reads until the terminator for set-terminator strings', term_parser
    reads '1524875912452', '1524875', 'reads until the termination proc succeeds for proc-terminator strings', term_proc_parser
  end
  
  describe '#write' do
    writes 'abcdef', 'abc', 'trims size-based parsers', size_parser
    writes 'ab', "ab\0", 'pads with size-based parsers, too', size_parser
    writes 'ab', 'ab7', 'pads with terminator with terminator-based parsers', term_parser
    writes 'ab', 'ababab', 'runs :write_block for proc-based string parsers', term_proc_parser
  end
end

describe ByteParser::CString do
  parser = ByteParser::CString.new

  is_not_fixed parser
  no_static_size parser
  
  describe '#read' do
    reads "hi there\0what is up", 'hi there', 'reads a simple C string', parser
    reads 'hi there', 'hi there', 'stops reading if it does not hit a null byte', parser
  end
  
  describe '#write' do
    writes 'hello', "hello\0", 'writes a simple C string', parser
  end
end

describe ByteParser::FixedString do
  parser = ByteParser::FixedString.new(:size => 7)
  padding_parser = ByteParser::FixedString.new(:size => 7, :padding => "l")

  describe '#initialize' do
    it 'raises if a non-integer size is given' do
      lambda {
        ByteParser::FixedString.new(:size => 3.14)
      }.should raise_error(ArgumentError)
    end
    
    it 'raises if no size is given' do
      lambda {
        ByteParser::FixedString.new
      }.should raise_error(ArgumentError)
    end
  end
  
  is_fixed parser
  static_size 7, parser
  
  describe '#read' do
    reads "hi there\0what is up", 'hi ther', 'reads a simple fixed string', parser
    reads 'hi!', 'hi!', 'stops reading if it runs out of text', parser
  end
  
  describe '#write' do
    writes 'hello there', 'hello t', 'Clips to the given size', parser
    writes 'lol', 'lolllll', 'Pads with the given padding parameter', padding_parser
    writes 'lol', "lol\0\0\0\0", 'Pads with null bytes by default', parser
  end
end