#!/usr/local/bin/ruby
# An example of using HTTP POST to retrieve sunrise/set data

require 'date'
require 'net/http'

YOUR_ID    = ''    # A unique ID per comment above
YOUR_CITY  = ''    # The name of your city
YOUR_STATE = ''    # Two letter state abbreviation

date = DateTime.now + 1 # tomorrow

Net::HTTP.start('aa.usno.navy.mil') do |query|
  response = query.get("/rstt/onedaytable?form=1&ID=AA&year=#{date.year}&month=#{date.month}&day=#{date.day}&state=NC&place=Cary")
  if response.body =~ /<td>Begin civil twilight<\/td><td>([^<]+)<\/td>.*<td>Sunrise<\/td><td>([^<]+)<\/td>.*<td>Sunset<\/td><td>([^<]+)<\/td>.*<td>End civil twilight<\/td><td>([^<]+)<\/td>/mi
    puts "#{date.month}/#{date.day}/#{date.year}"
    puts "Begin Twilight: #{$1}"
    puts "Sunrise       : #{$2}"
    puts "Sunset        : #{$3}"
    puts "End Twilight  : #{$4}"
  end
end
