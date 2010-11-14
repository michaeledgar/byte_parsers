$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'byte_parsers'
require 'spec'
require 'spec/autorun'
require 'rubygems'
require 'faker'
Spec::Runner.configure do |config|
  
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