#!/usr/bin/env ruby

# == Name
# replace_strings.rb
#
# == Synopsis
# Perform a set of string substitutions in parallel taking dependencies
# between substitutions into account. Input text is read from standard
# input and written to standard output.
#
# == Usage
#   ruby replace_strings.rb 
#     [-h | --help] 
#     [ -v | --verbose ] 
#     [ -d | --debug ] 
#     [ -e | --explicit ] 
#     [ -t | --test ] 
#     [ -f | --file inputfile ]
#     -s | --strings stringsfile 
#
# == Help
# help::
#   Print this information.
#
# verbose::
#   Print extra information
#
# debug::
#   Print debug information (more verbose than verbose)
#
# explicit::
#   Don't reorder the replacement strings. By default, the program will reorder
#   the replacements so that 1) replacements involving source supersets are performed
#   before replacements involving source subsets e.g. 'abc' -> 'foo' is replaced before
#   'ab' -> 'foo' and 2) replacements involving s as a source string are performed
#   before replacements involving s as a destination string e.g. 'cd' -> 'ef' is 
#   performed before 'ab' -> 'cd' to avoid having the latter's action overwritten
#   by the former i.e. 'ab' converted to 'cd', then subsequently converted to 'ef'.
#
# test::
#   Don't actually replace anything, just print the order of actions. Implies verbose.
#
# stringsfile::
#   A csv file with each line containing a pair of strings. If you desire to use a
#   comma in the old or new strings, use double quotes. For example:
#   old,new 
#   before,after
#   "never,never","always,always"
#
#   You may also use a regular expression for old. For example:
#   /(Perl|Python)/,Ruby
#
#   If a regular expression is used for the old, you may use \1, \2, etc. to refer
#   to groups in the match. For example, if the input file contained the 
#   following line:
#   hello
#   And a replacement pair was specified as follows:
#   /([aeiou])/,<\1>
#   Then the output line would be:
#   h<e>ll<o>
#
# Example invocation:
# ruby replace_strings.rb -s replacements.txt < oldfile.txt > newfile.txt
#
# == Author
# Brian Adkins
#
# == Date
# 03/16/06

# Load libraries
require 'optparse'
require 'rdoc/usage'
require 'csv'

# Handle command line arguments
debug       = false
explicit    = false
file_name   = nil
test        = false
verbose     = false
input_name  = nil

opts = OptionParser.new

opts.on("-h", "--help")         { RDoc::usage }
opts.on("-s", "--strings FOO")  { |f| file_name = f }
opts.on("-v", "--verbose")      { verbose = true }
opts.on("-e", "--explicit")     { explicit = true }
opts.on("-t", "--test")         { test = true }
opts.on("-d", "--debug")        { debug = true }
opts.on("-f", "--file FOO")     { |f| input_name = f }

opts.parse(ARGV) rescue RDoc::usage('usage')
RDoc::usage('Usage') unless file_name

verbose = true if test || debug

# The ReplaceAction class is the core of this program. It encapsulates
# the source string (or regex), destination string, actions which must
# precede this action, and actions for which this action must precede.
 
class ReplaceAction
  # Constants
  INDENT_LEVEL = '  '

  # Read only attributes
  attr_reader :source, :destination, :predecessors

  # The constructor.
  def initialize(source,destination)
    # If the source begins and ends with a '/', create a regex instead
    # of a string
    @source = source =~ %r{/(.*)/} ? Regexp.new($1) : source
    @destination = destination
    @predecessors = []
    @successors = []
    @visited = false
  end

  # Add a predecessor to this action by adding it to our list
  # of predecessors and adding ourself to the predecessor's list
  # of successors.
  def add_predecessor predecessor
    predecessor.successors << self
    @predecessors << predecessor
  end

  # Recursively print this action and its successors indenting
  # each successive level.
  def print_with_successors(indent='')
    raise "Error: loop detected while printing #{self}" if @visited
    puts "#{indent}[#{@source}->#{@destination}]"
    @visited = true
    for action in @successors
      action.print_with_successors(indent + INDENT_LEVEL)
    end
    @visited = false
  end

  # Perform the string substitution. Each ReplaceAction object will first ensure
  # each predecessor has been executed by recursively calling their exec method, 
  # then it will perform its own substitution, and finally will recursively call 
  # exec on its successors.
  #
  # Loops are detected by having the first action to call a predecessor's exec
  # method pass in self so that if the recursive call to predecessors loops back
  # around to self, it can be detected.
  def exec(line, originating_successor=nil)
    raise "Error: loop detected while processing #{self}" if equal? originating_successor
    unless @visited
      @visited = true
      @predecessors.each { |action| action.exec(line, originating_successor || self) }
      line.gsub!(@source, @destination)
      unless originating_successor 
        @successors.each { |action| action.exec(line) }
      end
    end
  end

  # Reset visited and return self if the action had not been visited
  # which indicates an error condition due to orphaned actions.
  def reset
    if @visited
      @visited = false
      return nil
    else
      return self
    end  
  end

  def to_s
    "[#{@source}->#{@destination}, predecessors: #{@predecessors.length}, successors: #{@successors.length}]"
  end

  protected

  def successors
    @successors
  end  

end

# Read the lines containing strings with mixed case
replacement_actions = []
CSV.open(file_name, "r") do |row|
  replacement_actions << ReplaceAction.new(row[0], row[1])
end

# Now we need to order the replacements properly:
# 1) Supersets should be replaced before subsets. For example, if 
#    'ab' and 'abc' are both to be replaced, 'abc' should be replaced
#    before 'ab'. Consider the replacements 'Camel' -> 'Donkey' and
#    'CamelCase' -> 'PascalCase'. If we replace 'Camel' first, we end up with
#    'Donkey' and 'DonkeyCase', not the desired 'Donkey' and 'PascalCase'
#    If we only wanted to handle this requirement, we could simply sort
#    the pairs by source string in descending order.
#      replacement_pairs.sort! { |a,b| b[0] <=> a[0] } # use a block to reverse the sort order
# 2) Consider a string s. If s is a source string (i.e. in the set of strings
#    to be replaced) and a destination string (i.e. in the set of replacement
#    strings), the replacement in which s is a source string should be 
#    performed before the replacement in which s is a destination string.

unless explicit
  replacement_actions.each do |action|
    replacement_actions.each do |other|
      unless action.equal? other
        action.add_predecessor(other) if other.source == action.destination  
        # Don't attempt to handle dependencies for regular expressions
        unless other.source.kind_of?(Regexp) || (action.source.kind_of?(Regexp))
          action.add_predecessor(other) if other.source.include?(action.source)
        end  
      end
    end
  end
end

# Create a collection of actions that don't have predecessors
roots = replacement_actions.find_all { |action| action.predecessors.empty? }

begin
  if verbose 
    puts "\nThe following replacements will occur. Actions indented less will be performed before those indented more." 
    roots.each { |action| action.print_with_successors }
  end

  unless test
    # Read the lines of the file to fix from stdin and perform all of the
    # substitutions on each line.
    while line = STDIN.gets
        roots.each { |action| action.exec(line) }
        action = replacement_actions.find { |action| action.reset }
        raise "Error: action orphaned: #{action}" if action
        puts line
    end
  end
rescue => msg
  puts msg
end
