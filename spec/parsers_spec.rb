require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe ByteParser::BlockParser do
  before do
    @parser = ByteParser::BlockParser.new(:read_block => proc { |input|
      a, b = input.read(1), input.read(1)
      a > b ? (a + input.read(1)) : b
    }, :write_block => proc { |value, output|
        output.write((value * 3).to_s)
    })
  end
  
  is_not_fixed
  no_static_size
  
  describe '#read' do
    reads 'bac', 'bc', 'reads 3 characters if the first is greater than the second'
    reads 'abc', 'b', 'returns the second character if the first is <= the second'
  end
  
  describe '#write' do
    it 'writes the value using #write_block' do
      output = StringIO.new
      @parser.write(5, output)
      @parser.write('hi', output)
      output.string.should == '15hihihi'
    end
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

describe ByteParser::String do
  size_parser = ByteParser::String.new(:size => 3)
  term_parser = ByteParser::String.new(:terminator => "7")
  # terminates on 0, 3, 6, or 9
  term_proc_parser = ByteParser::String.new(:terminator => proc {|x| x.to_i % 3 == 0})
  
  is_fixed size_parser
  is_not_fixed term_parser
  is_not_fixed term_proc_parser

  static_size 3, size_parser
  no_static_size term_parser
  no_static_size term_proc_parser
  
  size_parser = ByteParser::String.new(:size => 3)
  term_parser = ByteParser::String.new(:terminator => "7")
  term_proc_parser = ByteParser::String.new(:terminator => proc {|x| x.to_i % 3 == 0})
  
  describe '#read' do
    reads 'abcdefg', 'abc', 'reads the fixed number of bytes', size_parser
    reads 'abcdef7ajmilc', 'abcdef', 'reads until the terminator for set-terminator strings', term_parser
    reads '1524875912452', '1524875', 'reads until the termination proc succeeds for proc-terminator strings', term_proc_parser
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