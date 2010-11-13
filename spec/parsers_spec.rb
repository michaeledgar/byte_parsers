require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe ByteParser::UInt32 do
  before do
    @parser = ByteParser::UInt32.new(:endian => :little)
  end

  it 'has a fixed size' do
    @parser.fixed_size?.should be_true
  end
  
  it 'has a static size of 4 bytes' do
    @parser.static_size.should == 4
  end
  
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

describe ByteParser::CString do
  before do
    @parser = ByteParser::CString.new
  end

  it 'has a non-fixed size' do
    @parser.fixed_size?.should be_false
  end
  
  it 'raises on #static_size' do
    lambda {
      @parser.static_size
    }.should raise_error(ByteParser::DynamicParserError)
  end
  
  it 'reads a simple C string' do
    input = StringIO.new("hi there\0what is up")
    @parser.read(input).should == "hi there"
  end
  
  it 'stops reading if it does not hit a null byte' do
    input = StringIO.new("hi there")
    @parser.read(input).should == "hi there"
  end
end