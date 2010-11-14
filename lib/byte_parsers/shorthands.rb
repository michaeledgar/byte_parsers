# This module includes all of ByteParser with a smaller name,
# so that pre-defined Parsers can be accessed easily.
module BP
  BlockParser = ByteParser::BlockParser
  UInt32 = ByteParser::UInt32
  UInt16 = ByteParser::UInt16
  UInt8  = ByteParser::UInt8
  Int32 = ByteParser::Int32
  Int16 = ByteParser::Int16
  Int8  = ByteParser::Int8
  CString = ByteParser::CString
  FixedString = ByteParser::FixedString
  String = ByteParser::String
end