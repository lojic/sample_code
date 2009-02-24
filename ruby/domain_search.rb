#!/usr/bin/ruby

# Script to search for availability of multiple domain names passed
# as command line arguments.
#
# e.g. ruby domain_search.rb foo.com bar.com baz.com

if ARGV.length < 1
  puts "supply domain names as arguments"
  exit 0 
end

# Just an experiment in abstracting the concept of 
# skipping a block of code the first time through a loop.
class SkipN
  def initialize n
    @n = n
  end

  def run 
    if @n < 1
      yield 
    else
      @n -= 1
    end
  end

  def self.skip_first
    return new(1)
  end
end

def get_create_date whois
  patterns = [
    /creat(?:ion|ed).*?(\d{4}[\/-]\d{2}[\/-]\d{2}|\d{2}[ -]\w{3}[ -]\d{4})/
  ]
  patterns.each do |pat|
    if whois.downcase =~ pat
      return $1
    end
  end
  return "couldn't parse create date"
end

skip_first = SkipN.skip_first
ARGV.each do |domain|
  skip_first.run { sleep 3 }
  if (whois = `whois #{domain}`) =~ /(No match for "#{domain.upcase}"\.|NOT FOUND)/
    puts "#{domain} is available"
  else
    puts "#{domain} is NOT available (#{get_create_date(whois)})"
  end
end
