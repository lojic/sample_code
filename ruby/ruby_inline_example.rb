# sudo gem install rubyinline
# Generated C code goes to ~/.ruby_inline
require 'rubygems'
require 'inline'

class MyTest
  inline do |builder|
    builder.c "
      long factorial(int max) {
        long result = 1;
        while (max >= 2) {
          result *= max--;
        }
        return result;
      }"
  end
end
t = MyTest.new
puts t.factorial(10)
