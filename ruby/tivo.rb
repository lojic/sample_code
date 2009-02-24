# TiVo Statistics
#
# Input:
#   HTML source from TiVo "nowplaying" page
#
# Output:
#   Report in the following format:
#
# TiVo Nowplaying Statistics
# --------------------------
# 1.5 GB 177 Min Show Title 1
# 0.8 GB  30 MIN Show Title 2
# ...
#
# 25 items, total hours = 28, total disk = 53.0 GB
#
# 1) Open https://<ipaddr>/nowplaying/index.html?Recurse=Yes
#    You'll be prompted for a userid and password.
#    Userid: tivo
#    Password: MAK (media access key)
# 2) Save HTML source to DATA_FILE in the current directory
require 'cgi'

DATA_FILE = "tivo.html"
GB_PER_HR_HIGH = 1.6
# Regular expression pattern with groups as follows:
# title, hours, minutes, seconds, size, unit
PATTERN = /<b>([^<]+)<\/b>.*?(\d+):(\d+):(\d+)<br>([0-9.]+)\s*(MB|GB)/m
SUGGEST_PATTERN = /images\/suggestion-recording\.png" width="16" height="16">.*?<b>([^<]+)<\/b>.*?(\d+):(\d+):(\d+)<br>([0-9.]+)\s*(MB|GB)/m
TOTAL_DISK = 57.2

data = File.new(DATA_FILE).read

# Ensure the file contains a string indicating the number of items
raise 'data error' unless data =~ /(\d+) items/
num_items = $1.to_i

# Parse the file and create a list of elements containing:
# :title, :minutes & :size
entries = []
data.scan(PATTERN) do |title, hours, minutes, seconds, num, unit|
  gb = unit == 'MB' ? num.to_f / 1024 : num.to_f
  entries << { 
    :title => title, 
    :minutes => hours.to_i * 60 + minutes.to_i + seconds.to_i / 60.0, 
    :size => gb }
end

# Print the report
puts
puts "TiVo Nowplaying Statistics"
puts "--------------------------"
total_gb = 0
total_minutes = 0
entries.each do |x| 
  printf "%4.1f GB %3.0d %s\n", x[:size], x[:minutes], CGI::unescapeHTML(x[:title])
  total_gb += x[:size] 
  total_minutes += x[:minutes]
end

unless entries.length == num_items
  puts "entries.length=#{entries.length}, num_items=#{num_items}"
  raise 'parse error'
end

printf "\n%d items, total hours = %.1f, total disk = %.1f GB\n", 
  entries.length, total_minutes / 60.0, total_gb

# Process TiVo suggestions
entries = []
data.scan(SUGGEST_PATTERN) do |title, hours, minutes, seconds, num, unit|
  gb = unit == 'MB' ? num.to_f / 1024 : num.to_f
  entries << { 
    :title => title, 
    :minutes => hours.to_i * 60 + minutes.to_i + seconds.to_i / 60.0, 
    :size => gb }
end

suggest_gb = 0
suggest_minutes = 0
entries.each do |x| 
  suggest_gb += x[:size] 
  suggest_minutes += x[:minutes]
end

printf "%d suggestions, hours = %.1f, disk = %.1f GB\n",
  entries.length, suggest_minutes / 60.0, suggest_gb

free_space = TOTAL_DISK - total_gb + suggest_gb
printf "Free space = %.1f GB or %.1f hours at high quality\n\n",
  free_space, free_space / GB_PER_HR_HIGH
