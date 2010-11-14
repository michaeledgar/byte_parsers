$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'byte_parsers'
require 'spec'
require 'spec/autorun'
require 'rubygems'
require 'faker'
Spec::Runner.configure do |config|
  
end

module ByteParsers
  module RSpec    
    module Macros
      def is_fixed(parser)
        describe '#fixed_size?' do
          it 'returns true' do
            parser.fixed_size?.should be_true
          end
        end
      end
      
      def is_not_fixed(parser)
        describe '#fixed_size?' do
          it 'returns false' do
            parser.fixed_size?.should be_false
          end
        end
      end
      
      def static_size(bytes, parser)
        is_fixed parser
        describe '#static_size' do
          it 'returns the correct size' do
            parser.static_size.should == bytes
          end
        end
      end
      
      def no_static_size(parser)
        describe '#static_size' do
          it "raises, since #{subject} doesn't have static sizes" do
            lambda {
              parser.static_size
            }.should raise_error(ByteParser::DynamicParserError)
          end
        end
      end
      
      def reads(input, output, desc = "Expects #{input.inspect} to be parsed to #{output.inspect}", parser = nil)
        it desc do
          input_stream = StringIO.new(input)
          parser.read(input_stream).should == output
        end
      end
      
      def writes(value, output, desc = "Expects #{input.inspect} to be parsed to #{output.inspect}",
                 parser = nil)
        it desc do
          output_stream = StringIO.new
          parser.write(value, output_stream)
          output_stream.string.should == output
        end
      end
    end
  end
end

Spec::Runner.configure do |config|
  config.extend(ByteParsers::RSpec::Macros)
end

module RandomStuff
  module_function
  def number(range)
    range.begin + rand(range.end - range.begin)
  end
  
  def bytes(size)
    (0...size).map {(0 + rand(255)).chr}.join
  end
  
  def name
    Faker::Name.name
  end
  
  def string(size)
    (0...size).map{(65 + rand(25)).chr}.join
  end
end