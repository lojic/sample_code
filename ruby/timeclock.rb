#!/usr/bin/env ruby

# Copyright 2007-2013 Brian Adkins all rights reserved
#
# = Name
# timeclock.rb
#
# = Synopsis
# Process an emacs time log file.
#
# = Usage
# ruby timeclock.rb [OPTION] [regex] < emacs_timelog
#   [ -b | --begin-date DATE ]
#   [ -e | --end-date DATE ]
#   [ -g | --group LEVELS ]
#   [ -h | --help ]
#   [ -s | --statistics ]
#   [ -t | --today-only ]
#   [ -v | --invert-match ]
#   [ -w | --week [DATE] ]
#
# = Help
# help::
#   Print this information
# regex::
#   select only records matching the regex
# today-only::
#   Only process records for today
# begin-date::
#   Specify the beginning date, and optionally time, for which earlier entries
#   will be excluded. If the time is omitted, 0:00:00 is assumed.
# end-date::
#   Specify the ending date, and optionally time, for which later entries
#   will be excluded. If the time is omitted, 0:00:00 is assumed.
# statistics::
#   Print daily and total hour amounts
# invert-match::
#   Invert the sense of matching the regex to only select non-matching entries
# group:
#   Specify the number of grouping levels for computing statistics. A group
#   levels > 1 implies --statistics
# week:
#   Report on weekly statistics.
#     Implies:
#       --begin-date
#       --end-date
#       --statistics
#       --group 1
#
# = Author
# Brian Adkins
#
# = Date
# 03/05/08

require 'optparse'
require 'date'
require 'json'
require 'pp'

TimeEntry = Struct.new(:is_start, :time, :description)
TimePair  = Struct.new(:start, :end)
TimeDay   = Struct.new(:mon, :day, :year, :pairs, :group_hours)

#------------------------------------------------------------------------
# Compute a grouping key from the time description based on the
# specified levels. For example, if the description was the following:
# Lojic research Ruby
# Then the group key would be the following based on the specified levels:
# 0: ""
# 1: "Lojic"
# 2: "Lojic research"
# 3: "Lojic research Ruby"
#------------------------------------------------------------------------
def compute_group_key description, levels, sep = ' '
  if levels < 1
    ''
  else
    tokens = description.split(sep)
    if tokens.length > levels
      tokens[0, levels].join(sep)
    else
      description
    end
  end
end

#------------------------------------------------------------------------
# Compute the elapsed time of a TimePair
# (assumes pair is within same day)
#------------------------------------------------------------------------
def elapsed pair
  (pair.end.time - pair.start.time) * 24.0
end

#------------------------------------------------------------------------
# Return a pair [line, lines_read] where line == nil if eof encountered
#------------------------------------------------------------------------
def get_line file
  lines_read = 0
  while line = file.gets
    lines_read += 1
    line.strip!
    break unless line.length < 1
  end
  return [line, lines_read]
end

#------------------------------------------------------------------------
# Return a 2 element list of the TimePair's start/end times converted to hours
# e.g. [ 9.7, 15.4 ]
# (assumes pair within same day)
#------------------------------------------------------------------------
def hours_interval pair
  [pair.start.time, pair.end.time].map {|t| t.hour + t.min / 60.0 + t.sec / 3600.0 }
end

#------------------------------------------------------------------------
# Parse a pair of in/out entries and return a list of pairs or nil.
# This function will split a single pair into two pairs if it
# spans a midnight.
#------------------------------------------------------------------------
def parse_complete_pair i, o, options
  begin_date = options[:begin_date]
  end_date   = options[:end_date]

  case
  # Case 1: out < begin_date => skip
  when o.time < begin_date
    return nil

  # Case 2: in > end_date => skip
  when i.time > end_date
    return nil

  # Case 3: entry intersects [begin_date, end_date]
  else
    pair = TimePair.new(i,o)
    if i.time >= begin_date && o.time < end_date
      # all of pair is within filtered span
      if i.time.day == o.time.day
        return [ pair ]
      else
        return split_time_pair(pair)
      end
    elsif i.time < begin_date
      # split and append second portion
      return [ split_time_pair(pair)[1] ]
    elsif o.time >= end_date
      # split and append first portion
      return [ split_time_pair(pair)[0] ]
    else
      raise 'this should not happen :)'
    end
  end
end

#------------------------------------------------------------------------
# Aggregate a list of TimePair objects into days
#------------------------------------------------------------------------
def parse_days pairs
  current_day = { :mon => 1, :day => 1, :year => 1970 }
  days = []
  pairs.each do |pair|
    t = pair.start.time
    day = { :mon => t.mon, :day => t.day, :year => t.year }

    if day == current_day
      days.last[:pairs] << pair
    else
      days << TimeDay.new(day[:mon], day[:day], day[:year], [pair], 0.0)
      current_day = day
    end
  end
  days
end

#------------------------------------------------------------------------
# Parse an emacs time log file and return a list of TimePair objects
#------------------------------------------------------------------------
def parse_file file, options
  line_no = 0
  pairs = []

  while true
    # Obtain a pair of TimeEntry objects and the current line_no
    result = parse_in_out(file, line_no)
    i, o, line_no = result # in, out, line

    # If i is nil, we've hit EOF - exit loop
    break unless i

    unless o
      # o is nil, active interval, use now for second entry
      raise 'expected in entry' unless i.is_start
      # Manually create a Date to avoid having a time zone issue
      o = TimeEntry.new(false, DateTime.parse(Time.now.strftime("%F %T")), nil)
    end

    # We have a complete in/out pair
    if (pair = parse_complete_pair(i, o, options))
      pairs.concat(pair)
    end

  end

  pairs
rescue Exception => e
  puts "Parse error on line %d: %s" % [line_no, e.message]
  exit 0
end

#------------------------------------------------------------------------
# Parse a pair of lines (in/out) from an emacs time log file and return
# a triplet consisting of two TimeEntry objects and the number of lines
# read. TimeEntry slots will be nil if unable to read or parse a line.
#------------------------------------------------------------------------
def parse_in_out file, line_no
  # Parse in
  line, lines_read = get_line(file)
  line_no += lines_read
  unless line
    return [nil, nil, line_no]
  end
  start_entry = parse_line(line)

  # Parse out
  line, lines_read = get_line(file)
  line_no += lines_read
  unless line
    return [start_entry, nil, line_no]
  end
  end_entry = parse_line(line)

  return [start_entry, end_entry, line_no]
rescue Exception => e
  puts "Parse error on line %d: %s" % [line_no, e.message]
  exit 0
end

#------------------------------------------------------------------------
# Parse a line from an emacs time log file and return a TimeEntry
#------------------------------------------------------------------------
def parse_line line
  raise 'invalid line' unless
    line =~ /^([io]) (\d{4}\/\d\d\/\d\d \d\d:\d\d:\d\d)(?: (\S.*)?)?$/
  TimeEntry.new($1 == 'i',  DateTime.parse($2, true), $3 || '')
end

#------------------------------------------------------------------------
# Print a report and accumulate grouping statistics
#------------------------------------------------------------------------
def print_report days, options
  # Report
  days.each do |day|
    puts "%s/%s/%s" % [day[:mon], day[:day], day[:year]]
    group_hours = { '' => 0.0 } if options[:statistics]
    day.pairs.each do |pair|
      hours = hours_interval(pair)
      puts "%05.2f-%05.2f %s" % (hours + [pair.start.description])
      if options[:statistics]
        group_key = compute_group_key(pair.start.description, options[:group_levels])
        group_hours[group_key] = (group_hours[group_key] || 0.0) + (hours[1] - hours[0])
      end
    end
    if options[:statistics]
      puts '------------------'
      if group_hours.length > 1
        group_hours.delete('')
        daily_sum = 0.0
        group_hours.sort.each do |key, value|
          puts "%5.2f %s" % [value, key]
          daily_sum += value
        end
      else
        daily_sum = group_hours['']
      end
      puts "%5.2f Daily Total" % daily_sum
      day.group_hours = group_hours
    end
    puts
  end
end

#------------------------------------------------------------------------
# Split a TimePair object into two TimePair objects before/after midnight
#------------------------------------------------------------------------
def split_time_pair pair
  first = pair.start.time
  end_of_first = DateTime.civil(first.year, first.mon, first.day, 23, 59, 59)
  second = pair.end.time
  beg_of_second = DateTime.civil(second.year, second.mon, second.day, 0, 0, 0)
  [
   TimePair.new(pair.start, TimeEntry.new(false, end_of_first, nil)),
   TimePair.new(TimeEntry.new(true, beg_of_second, pair.start.description), pair.end)
  ]
end

def beginning_of_week d
  d.monday? ? d : beginning_of_week(d-1)
end

#------------------------------------------------------------------------
# Handle command line arguments
#------------------------------------------------------------------------
options = {
  :begin_date   => DateTime.parse("2000-01-01", true),
  :end_date     => DateTime.parse("2050-01-01", true),
  :statistics   => false,
  :invert_match => false,
  :group_levels => 0,
  :week_date    => beginning_of_week(DateTime.parse(Date.today.to_s)),
}
opts = OptionParser.new
opts.on("-h", "--help")            { puts opts; exit }
opts.on("-b", "--begin-date DATE") {|d| options[:begin_date] = DateTime.parse(d, true) }
opts.on("-e", "--end-date DATE")   {|d| options[:end_date]   = DateTime.parse(d, true) }
opts.on("-s", "--statistics")      { options[:statistics]    = true              }
opts.on("-v", "--invert-match")    { options[:invert_match]  = true              }
opts.on("-t", "--today-only") do
  options[:begin_date] = DateTime.parse(Time.now.strftime("%Y-%m-%d"))
end
opts.on("-g", "--group LEVELS") do |levels|
  options[:group_levels] = levels.to_i
  options[:statistics] = true if options[:group_levels] > 0
end
opts.on("-w", "--week [DATE]") do |d|
  options[:week_date]    = DateTime.parse(d, true) if d
  options[:begin_date]   = options[:week_date]
  options[:end_date]     = options[:week_date] + 7
  options[:week_stats]   = true
  options[:statistics]   = true
  options[:group_levels] = 1
end
rest = opts.parse(ARGV) rescue RDoc::usage('usage')

# Parse the file
entries = parse_file(STDIN, options).select do |e|
  match = e[0][:description] =~ /#{rest[0] || '.*'}/i
  options[:invert_match] ? !match : match
end

# Group into days
days = parse_days(entries)

# Print a report and accumulate group stats
group_stats = print_report(days, options)

if options[:statistics]
  puts 'Daily Hours'
  puts '-----------'
  group_hours = { '' => 0.0 }
  total_sum = 0.0
  days.each do |day|
    daily_sum = 0.0
    day.group_hours.each do |key, value|
      group_hours[key] = (group_hours[key] || 0.0) + value
      daily_sum += value
    end
    puts "%2d/%02.2d/%d: %5.2f" % [day[:mon], day[:day], day[:year], daily_sum]
    total_sum += daily_sum
  end
  puts "Total      %6.2f" % total_sum

  puts
  puts 'Category Totals'
  puts "---------------"
  if group_hours.length > 1
    group_hours.delete('')
    sum = 0.0
    group_hours.sort.each do |key, value|
      puts "%5.2f (%5.1f %%) %s" % [value, (value / total_sum * 100.0), key]
      sum += value
    end
  else
    sum = group_hours['']
  end
  raise 'calculation error' if (sum - total_sum).abs > 0.0001
  puts "%5.2f Total hours" % sum

  if group_hours.length > 1
    puts
    puts 'Most Time Spent'
    puts "---------------"
    sum = 0.0
    group_hours.sort {|a,b| b[1] <=> a[1] }.each do |key, value|
      puts "%5.2f (%5.1f %%) %s" % [value, (value / total_sum * 100.0), key]
      sum += value
    end
  end
  puts "%5.2f Total hours" % sum
end

if options[:week_stats]
  # Config file to specify weekly hours allocation per client is of the form:
  # {
  #   "Client A" : 20.0,
  #   "Client B" : 20.0
  # }
  allocations = JSON.parse(IO.read("/Users/badkins/sync/business/hours_allocation.json"))

  puts ''
  puts 'Week Stats'
  puts '----------'
  sum = {}
  group_hours = {}

  days.each do |day|
    day.group_hours.each do |key,value|
      group_hours[key] = (group_hours[key] || 0.0) + value
    end
  end

  company_hours = []

  group_hours.each do |key,value|
    allocated = allocations[key]
    company_hours << [
                      key,
                      value,
                      allocated ? (value / allocations[key]) * 100.0 : 0.0
                     ]
  end

  company_hours.sort {|a,b| a[2] <=> b[2] }.each do |pair|
    puts "( %6.2f %% ) %5.2f #{pair[0]}" % [ pair[2], pair[1] ]
  end
  puts "Total allocated hours: #{allocations.inject(0.0) {|memo,pair| memo + pair[1]} }"

  puts ''
  group_hours.map {|k,v| k }.select {|k| !allocations[k] }.each do |k|
    puts "WARNING: no allocation found for #{k}"
    puts ''
  end
end
