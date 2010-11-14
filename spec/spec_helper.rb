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
    module Matchers
      # Matcher for checking if #match? returns trues
      class Warns
        def initialize(input, *args)
          @input, @args = input, args
        end

        def matches?(actual)
          @class = actual
          @class.new('(stdin)', @input, *@args).match?
        end

        def failure_message
          "expected '#{@actual}' to match #{@input.inspect}"
        end

        def negative_failure_message
          "expected '#{@actual}' to not match #{@input.inspect}"
        end
      end
    end
    
    module Macros
      def is_fixed(parser = nil)
        describe '#fixed_size?' do
          it 'returns true' do
            (parser || @parser).fixed_size?.should be_true
          end
        end
      end
      
      def is_not_fixed(parser = nil)
        describe '#fixed_size?' do
          it 'returns false' do
            (parser || @parser).fixed_size?.should be_false
          end
        end
      end
      
      def static_size(bytes, parser = nil)
        describe '#static_size' do
          it 'returns the correct size' do
            (parser || @parser).static_size.should == bytes
          end
        end
      end
      
      def no_static_size(parser = nil)
        describe '#static_size' do
          it "raises, since #{subject} doesn't have static sizes" do
            lambda {
              (parser || @parser).static_size
            }.should raise_error(ByteParser::DynamicParserError)
          end
        end
      end
      
      def reads(input, output, desc = "Expects #{input.inspect} to be parsed to #{output.inspect}",
                parser = nil)
        it desc do
          parser ||= @parser
          input_stream = StringIO.new(input)
          parser.read(input_stream).should == output
        end
      end
      
      def writes(value, output, desc = "Expects #{input.inspect} to be parsed to #{output.inspect}",
                 parser = nil)
        it desc do
          parser ||= @parser
          output_stream = StringIO.new
          parser.write(value, output_stream)
          output_stream.string.should == output
        end
      end
    end
  end
end

Spec::Runner.configure do |config|
  config.include(ByteParsers::RSpec::Matchers)
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