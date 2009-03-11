#!/usr/local/bin/ruby
#
# An example of using HTTP POST to retrieve sunrise/set data
#
# Author : Brian Adkins
# Site   : http://lojic.com
# License: Just leave copyright notice :)
# Copyright 2009 Brian Adkins, all rights reserved
#
# Reference: http://aa.usno.navy.mil/data/docs/RS_OneDay.php
#
# "If you plan to write your own form to access the cgi script for
# sunrise/sunset calculations (not recommended), please use the above
# line in your form but substitute in the value field an identifier of
# your own choosing, up to 8 characters.  For example, <input
# type="hidden" name="ID", value="UCLA"> .  If you are setting this up
# for an institution, please e-mail us (at ) and let us know what
# identifier you are using and who you are.  Thanks... this allows us to
# keep track of all our users, even those who bypass our normal web
# usage log, and helps us justify our work on the web.  (Nothing in this
# note should be construed as encouragement to set up your own form, as
# we do not guarantee that either our form or the program called by the
# cgi script will not change.)"

# Here's a simple Emacs function to invoke this Ruby script if it's
# executable and available in the path
# (defun bja-sunrise ()
#   "Display sunrise/sunset information."
#   (interactive)
#   (shell-command "sunrise_http_post.rb"))

require 'net/http'

YOUR_ID    = ''    # A unique ID per comment above
YOUR_CITY  = ''    # The name of your city
YOUR_STATE = ''    # Two letter state abbreviation

now   = Time.now
month = now.month
day   = now.day + 1 # Tomorrow
year  = now.year

Net::HTTP.start('aa.usno.navy.mil') do |query|
  response = query.post('/cgi-bin/aa_pap.pl', "FFX=1&ID=#{YOUR_ID}&xxy=#{year}&xxm=#{month}&xxd=#{day}&st=#{YOUR_STATE}&place=#{YOUR_CITY}&ZZZ=END")
  if response.body =~ /Begin civil twilight[^0-9]*(\d+:\d{2} [ap].m.).*Sunrise[^0-9]*(\d+:\d{2} [ap].m.).*Sunset[^0-9]*(\d+:\d{2} [ap].m.).*End civil twilight[^0-9]*(\d+:\d{2} [ap].m.)/m
    puts "#{month}/#{day}/#{year}"
    puts "Begin Twilight: #{$1}"
    puts "Sunrise       : #{$2}"
    puts "Sunset        : #{$3}"
    puts "End Twilight  : #{$4}"
  end
end
