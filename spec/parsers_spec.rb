require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe ByteParser::UInt32 do
  before do
    @parser = ByteParser::UInt32.new(:endian => :little)
  end

  describe '#fixed_size?' do
    it 'returns true' do
      @parser.fixed_size?.should be_true
    end
  end
  
  describe '#static_size' do
    it 'returns 4 bytes (for 32 bits)' do
      @parser.static_size.should == 4
    end
  end
    
  describe '#read' do
    it 'reads a simple little-endian uint32' do
      input = StringIO.new("\x01\x02\x03\x04blahblah")
      @parser.read(input).should == 0x04030201
    end
    
    it 'reads a simple big-endian uint32' do
      parser = ByteParser::UInt32.new(:endian => :big)
      input = StringIO.new("\x01\x02\x03\x04blahblah")
      parser.read(input).should == 0x01020304
    end
  end
end

describe ByteParser::UInt16 do
  before do
    @parser = ByteParser::UInt16.new(:endian => :little)
  end

  describe '#fixed_size?' do
    it 'returns true' do
      @parser.fixed_size?.should be_true
    end
  end
    
  describe '#static_size' do
    it 'returns 2 bytes (for 16 bits)' do
      @parser.static_size.should == 2
    end
  end
    
  describe '#read' do
    it 'reads a simple little-endian uint16' do
      input = StringIO.new("\x01\x02blahblah")
      @parser.read(input).should == 0x0201
    end
    
    it 'reads a simple big-endian uint16' do
      parser = ByteParser::UInt16.new(:endian => :big)
      input = StringIO.new("\x01\x02blahblah")
      parser.read(input).should == 0x0102
    end
  end
end

describe ByteParser::UInt8 do
  before do
    @parser = ByteParser::UInt8.new(:endian => :little)
  end

  describe '#fixed_size?' do
    it 'returns true' do
      @parser.fixed_size?.should be_true
    end
  end
    
  describe '#static_size' do
    it 'returns 1 byte (for 8 bits)' do
      @parser.static_size.should == 1
    end
  end
    
  describe '#read' do
    it 'reads a simple little-endian uint8' do
      input = StringIO.new("\xcbblahblah")
      @parser.read(input).should == 0xcb
    end
    
    it 'should be unaffected by endianness' do
      parser = ByteParser::UInt8.new(:endian => :big)
      input = StringIO.new("\xcbblahblah")
      parser.read(input).should == 0xcb
    end
  end
end

describe ByteParser::String do
  before do
    @size_parser = BP::String.new(:size => 3)
    @term_parser = BP::String.new(:terminator => "7")
    # terminates on 0, 3, 6, or 9
    @term_proc_parser = BP::String.new(:terminator => proc {|x| x.to_i % 3 == 0})
  end
  
  describe '#fixed_size?' do
    it 'returns true for size-based strings' do
      @size_parser.fixed_size?.should be_true
    end
    
    it 'returns false for terminator-based strings' do
      @term_parser.fixed_size?.should be_false
      @term_proc_parser.fixed_size?.should be_false
    end
  end
    
  describe '#static_size' do
    it 'returns the size of size-based strings' do
      @size_parser.static_size.should == 3
    end
    it "raises for terminator-based strings" do
      lambda {
        @term_parser.static_size
      }.should raise_error(ByteParser::DynamicParserError)
      lambda {
        @term_proc_parser.static_size
      }.should raise_error(ByteParser::DynamicParserError)
    end
  end
  
  describe '#read' do
    it 'reads the given number of chars for size-based strings' do
      input = StringIO.new('abcdefg')
      @size_parser.read(input).should == 'abc'
    end
    it 'reads until the terminator for set-terminator strings' do
      input = StringIO.new('abcdef7ajmilc')
      @term_parser.read(input).should == 'abcdef'
    end
    it 'reads until the termination proc succeeds for proc-terminator strings' do
      input = StringIO.new('1524875912452')
      @term_proc_parser.read(input).should == '1524875'
    end
  end
end

describe ByteParser::CString do
  before do
    @parser = ByteParser::CString.new
  end

  describe '#fixed_size?' do
    it 'returns false' do
      @parser.fixed_size?.should be_false
    end
  end
  
  describe '#static_size' do
    it "raises, since C strings don't have static sizes" do
      lambda {
        @parser.static_size
      }.should raise_error(ByteParser::DynamicParserError)
    end
  end
  
  describe '#read' do
    it 'reads a simple C string' do
      input = StringIO.new("hi there\0what is up")
      @parser.read(input).should == "hi there"
    end
    
    it 'stops reading if it does not hit a null byte' do
      input = StringIO.new("hi there")
      @parser.read(input).should == "hi there"
    end
  end
end

describe ByteParser::FixedString do
  before do
    @parser = ByteParser::FixedString.new(:size => 7)
  end

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
  
  describe '#fixed_size?' do
    it 'returns true' do
      @parser.fixed_size?.should be_true
    end
  end
  
  describe '#static_size' do
    it 'returns the correct size' do
      @parser.static_size.should == 7
    end
  end
  
  describe '#read' do
    it 'reads a simple fixed string' do
      input = StringIO.new("hi there\0what is up")
      @parser.read(input).should == "hi ther"
    end
    
    it 'stops reading if it runs out of text' do
      input = StringIO.new("hi!")
      @parser.read(input).should == "hi!"
    end
  end
end