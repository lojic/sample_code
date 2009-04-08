#!/usr/local/bin/ruby
# Author: Brian Adkins
# Date:   2009/04/08
# Copyright 2009 Brian Adkins - All Rights Reserved
#
# Ruby program to retrieve and parse GPS information (via NMEA sentences)
# from a Sprint Sierra Wireless 598U device.
#
# ruby gps-nmea.rb                # prints latititude/longitude info
# ruby gps-nmea.rb update-remote  # scp a file of location info to a remote server
#
# This program depends on the ruby-serialport gem:
# sudo gem install ruby-serialport
#
# From: http://www.gpsinformation.org/dale/nmea.htm#GGA
#  $GPGGA,123519,4807.038,N,01131.000,E,1,08,0.9,545.4,M,46.9,M,,*47
# Where:
#      GGA          Global Positioning System Fix Data
#      123519       Fix taken at 12:35:19 UTC
#      4807.038,N   Latitude 48 deg 07.038' N
#      01131.000,E  Longitude 11 deg 31.000' E
#      1            Fix quality: 0 = invalid
#                                1 = GPS fix (SPS)
#                                2 = DGPS fix
#                                3 = PPS fix
#              4 = Real Time Kinematic
#              5 = Float RTK
#                                6 = estimated (dead reckoning) (2.3 feature)
#              7 = Manual input mode
#              8 = Simulation mode
#      08           Number of satellites being tracked
#      0.9          Horizontal dilution of position
#      545.4,M      Altitude, Meters, above mean sea level
#      46.9,M       Height of geoid (mean sea level) above WGS84
#                       ellipsoid
#      (empty field) time in seconds since last DGPS update
#      (empty field) DGPS station ID number
#      *47          the checksum data, always begins with *

require 'rubygems'
require 'serialport'

# Emacs macro to reset user modified values (highlight, then: M-x eval-region )
# ((lambda (&optional arg) "Keyboard macro." (interactive "p") (kmacro-exec-ring-item (quote ("USERNAME\"\372\"HOSTNAME\"\372\"REMOTE_DIR\"\372\"" 0 "%d")) arg)))

# --- MODIFY THESE -- #
USERNAME   = ""  # Username for remote host
HOSTNAME   = ""  # Remote host name e.g. foo.com
REMOTE_DIR = ""  # Remote directory e.g. /var/www/bar
# --- MODIFY THESE -- #

port_str  = '/dev/cu.sierra05'
baud_rate = 9600
data_bits = 8
stop_bits = 1
parity    = SerialPort::NONE

sp = SerialPort.new(port_str, baud_rate, data_bits, stop_bits, parity)

# lat is of the form 4807.038 where the first 2 digits are degrees and
#   the remainder is minutes.
# dir is either 'N' or 'S'
def convert_lat lat, dir
  degrees = lat[0,2].to_f + (lat[2,lat.length-2].to_f / 60.0)
  dir == 'N' ? degrees : -degrees
end

# lon is of the form 01131.000 where the first 3 digits are degrees and
#   the remainder is minutes.
# dir is either 'E', or 'W'
def convert_lon lon, dir
  degrees = lon[0,3].to_f + (lon[3,lon.length-2].to_f / 60.0)
  dir == 'E' ? degrees : -degrees
end

TEMP_PATH = '/tmp'
TEMP_FILE = 'location.txt'

def update_remote_info lat, lon
  File.open("#{TEMP_PATH}/#{TEMP_FILE}", 'w') do |tf|
    tf.puts Time.now.to_s
    tf.puts "#{lat},#{lon}"
  end
  puts 'Updating remote location info'
  `scp #{TEMP_PATH}/#{TEMP_FILE} #{USERNAME}@#{HOSTNAME}:#{REMOTE_DIR}/#{TEMP_FILE}`
  File.delete("#{TEMP_PATH}/#{TEMP_FILE}")
end

# 99 requests should be sufficient to find a $GPGGA sentence
99.times do
  if (str = sp.gets) =~ /^\$GPGGA/
    fix = str.split(',')
    if fix[6] == '1'
      lat = convert_lat(fix[2], fix[3])
      lon = convert_lon(fix[4], fix[5])
      if ARGV[0] == 'update-remote'
        update_remote_info(lat,lon)
      elsif
        puts "#{lat}, #{lon}"
      end
      exit 0
    end
  end
end

puts "Invalid data - GPS coordinates not found"
