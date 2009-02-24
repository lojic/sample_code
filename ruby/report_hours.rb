#!/usr/bin/env ruby

# Parses time tracking data from standard input

require 'date'

class TimeParser
  BUILD_TIME = "Mon Feb 25 19:16:42 EST 2008"
  # Overkill because I simply grabbed an existing pattern
  REGEX_FLOAT = /^([0-9]+|[0-9]{1,3}(,[0-9]{3})*)?(\.[0-9]*)?$/

  # Constructor
  def initialize
    @current_day = nil
    @days = []
    @line_no = 0
  end

  # Parse the input file of time data
  def parse_time_data input
    while line = input.gets
      line.chomp!
      @line_no += 1

      if line =~ /^[\#;]/
        # ignore comment lines
      elsif line =~ /^(\d{1,2})\/(\d{1,2})\/(\d{2}|\d{4})$/
        # mm/dd/yy or mm/dd/yyyy
        handle_new_day($1, $2, $3)
      elsif line =~ /^([0-9.:]+)\s*[-]\s*([0-9.]+)\s+(\S+.*)/
        # t1 - t2 description  for example:
        # 7.1-13.6 Mantis issues  OR (for Jordan :)
        # 7:30-10 Mantis issues
        handle_new_entry($1, $2, $3)
      elsif line.strip.empty?
        # ignore blank lines
      else
        raise "parse error - invalid line"
      end
    end
  rescue Exception => e
    puts "line #{@line_no}: #{e.message}"
  end

  # Print a summary report
  def print_report
    sum = 0.0
    puts "\nSummary:"
    puts '-'*8
    @days.each do |day|
      puts "#{day[:day].strftime("%m/%d/%y")}, %.2f hours" % day[:hours]
      sum += day[:hours]
    end
    puts "\nTotal hours = %.2f" % sum
    days = elapsed_days(@days[0][:day])
    puts "Elapsed days = %d" % days
    puts "Average hrs per week = %.2f" % (sum / (days / 7.0))
    puts
  end

  private

  # Create a new @current_day hash and append to @days array
  def handle_new_day month, day, year
    m = month.to_i
    d = day.to_i
    y = year.to_i + (year.length == 2 ? 2000 : 0)
    @current_day = { :day => Time.local(y, m, d), :entries => 0, :hours => 0.0 }
    @days << @current_day
    puts "\nDay: #{@current_day[:day].strftime("%m/%d/%y")}"
    puts '-'*13
  end

  # Process a new time entry and update statistics for the current day
  def handle_new_entry t1, t2, description
    t1, t2 = [t1.strip, t2.strip].map do |t|
      if t =~ REGEX_FLOAT
        # time is in a decimal hour format e.g. 7.5
        t.to_f
      elsif t =~ /^(\d{1,2}):(\d\d)$/
        # time is in a h:mm or hh:mm format
        $1.to_f + $2.to_f / 60.0
      else
        raise 'parse error - invalid hours'
      end
    end
    t2 += 24.0 if t2 < t1 # time period spanning midnight
    task_hours = t2 - t1
    @current_day[:entries] += 1
    @current_day[:hours] += task_hours
    puts "#{format_time_from_hour(t1.to_f)} (%2.2f) #{description}" % task_hours
  end

  # Return the number of days between t1 and the current day inclusive
  # e.g. if t1 is 1/5/08 00:00:00 and now is 1/7/08 15:30:00 => 3
  def elapsed_days t1
    ((Time.now - t1) / 86400).to_i + 1
  end

  # Format a floating point value representing an hour w/ fractional part as:
  # hh:mm
  def format_time_from_hour hour
    hrs = hour.to_i
    min = ((hour - hrs) * 60.0 + 0.5).to_i
    "%2d:%02d" % [hrs, min]
  end
end

# Main program
if ARGV[0] == '--version'
  puts "Build time: #{TimeParser::BUILD_TIME}"
  exit 0
end
parser = TimeParser.new
parser.parse_time_data(STDIN)
parser.print_report


