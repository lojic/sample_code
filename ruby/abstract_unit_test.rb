require "test/unit"

# While experimenting with ways to get Test::Unit to not try and run
# tests in an abstract base class, I came up with a hack to hide
# the class from ObjectSpace :)

class Module
  def hide_class
    Module.cloaked << self 
  end

  def Module.cloaked
    @@cloaked ||= []
  end
end

class << ObjectSpace 
  alias orig_each_object each_object
  def each_object(klass)
    ObjectSpace.orig_each_object(klass) do |obj|
      yield obj if !Module.cloaked.include?(obj)
    end
  end
end

class ParentTest < Test::Unit::TestCase
  hide_class
  # The proper way to prevent Test::Unit from attempting to 
  # run tests in an abstract base class is to undefine
  # the default_test method:
  # undef_method :default_test 

  def setup
    puts 'setup called'
  end

  def teardown
    puts 'teardown called'
  end
end

class ChildTest < ParentTest 
  def test_one
    puts 'test_one called'
    assert true
  end
end

