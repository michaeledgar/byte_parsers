require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "ByteParsers" do
  before(:all) do
    SimpleParser = ByteParser.new do
      add :fourcc, ByteParser::UInt32, :endian => :big
      add :version, ByteParser::UInt16, :endian => :little
      add :name, ByteParser::CString
      add :tag, ByteParser::FixedString, :size => 7
      add :weird_string, ByteParser::String, :terminator => "4"
      add :number_terminated_string, ByteParser::String, :terminator => proc {|x| x =~ /\d/}
    end
  end

  it "allows declarative class creation" do
    SimpleParser.should be_a(Class)
  end

  it 'has a #read method that reads in an IO' do
    SimpleParser.should respond_to(:read)
  end
  
  describe '#read' do
    before do
      @fourcc = RandomStuff.bytes 4
      @version = RandomStuff.bytes 2
      @name = RandomStuff.name
      @tag = RandomStuff.string(7)
      @weird_string = RandomStuff.string(RandomStuff.number(15..100))
      @number_terminated = RandomStuff.string(RandomStuff.number(15..100))
      @input = @fourcc + @version + @name + "\0" + @tag + @weird_string +
               "4" + @number_terminated + RandomStuff.number(0..9).to_s
    end
      
    it 'returns an object with readers for each field' do
      result = SimpleParser.read(StringIO.new(@input))
      result.should respond_to(:fourcc)
      result.should respond_to(:version)
      result.should respond_to(:name)
      result.should respond_to(:tag)
      result.should respond_to(:weird_string)
      result.should respond_to(:number_terminated_string)
    end
    
    it 'parses basic input' do
      result = SimpleParser.read(StringIO.new(@input))
      result.fourcc.should == @fourcc.unpack('N').first
      result.version.should == @version.unpack('v').first
      result.name.should == @name
      result.tag.should == @tag
      result.weird_string.should == @weird_string
      result.number_terminated_string.should == @number_terminated
    end
  end
end
