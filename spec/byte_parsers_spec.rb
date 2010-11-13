require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "ByteParsers" do
  before do
    SimpleParser = ByteParser.new do
      add :fourcc, BP::UInt32, :endian => :big
      add :version, BP::UInt16, :endian => :big
      add :name, BP::CString
      add :tag, BP::FixedString, :size => 7
      add :weird_string, BP::String, :terminator => "4"
      add :number_terminated_string, BP::String, :terminator => proc {|x| x =~ /\d/}
    end
  end

  it "allows declarative class creation" do
    SimpleParser.should be_a(Class)
  end
end
