require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'byte_parsers/shorthands'
describe BP do
  it 'includes the constants for each parser in ByteParser' do
    BP::BlockParser.should == ByteParser::BlockParser
    BP::UInt32.should == ByteParser::UInt32
    BP::UInt16.should == ByteParser::UInt16
    BP::UInt8 .should == ByteParser::UInt8
    BP::Int32.should == ByteParser::Int32
    BP::Int16.should == ByteParser::Int16
    BP::Int8 .should == ByteParser::Int8
    BP::CString.should == ByteParser::CString
    BP::FixedString.should == ByteParser::FixedString
    BP::String.should == ByteParser::String
  end
end