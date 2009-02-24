require 'open-uri'

URL = 'http://www.frf.usace.army.mil/'

str = open(URL).read

puts "Time = #{$1}"       if str =~ /Conditions for\s+(\d+\s+[a-zA-Z]{3}\s+2007 \d+) EST/
puts "Water temp = #{$1}" if str =~ /Water Temp.*[ ]+(\d+)&deg;F</
puts "Air temp = #{$1}"   if str =~ /Air Temp.*[ ]+(\d+)&deg;F</
puts "Winds = #{$1}"      if str =~ /Winds<\/td>.*>([0-9.]+\s+kts from \w+) <\/td>/m
