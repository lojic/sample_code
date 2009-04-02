#!/usr/local/bin/ruby
# Author: Brian J. Adkins
# Date:   2009/04/02
#
# Upload a set of OSX screen captures to a web host (after converting
# to .jpg) with simple wrapper html files for easier viewing. It
# assumes a set of screen capture images exist in ~/Desktop of the
# form:
#   Picture N.png
# For each screen capture image, the program will create two remote files:
#   screenshotN.html
#   screenshotN.jpg
# The .html file will contain links to all the .html files plus a
# screen shot image.
#
# Usage:
# 1) Fill in values for USERNAME, HOSTNAME & REMOTE_DIR
# 2) Create a bunch of OSX screen captures via command-shift-4 (then either drag a rect
#    or press the space bar to capture a window)
# 3) Invoke this program to create & upload the images with wrapper html files
#
# Emacs macro to reset user modified values (highlight, then: M-x eval-region )
# ((lambda (&optional arg) "Keyboard macro." (interactive "p") (kmacro-exec-ring-item (quote ("USERNAME\"\372\"HOSTNAME\"\372\"REMOTE_DIR\"\372\"URL_BASE\"\372\"" 0 "%d")) arg)))

# --- MODIFY THESE -- #
USERNAME   = ""  # Username for remote host
HOSTNAME   = ""  # Remote host name e.g. foo.com
REMOTE_DIR = ""  # Remote directory e.g. /var/www/bar
URL_BASE   = ""  # URL prefix e.g. http://foo.com/screenshots
# --- MODIFY THESE -- #

def header
  return <<HEADER
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
  <head>
    <title>Screen Captures</title>
    <meta http-equiv="content-type" content="text/html; charset=iso-8859-1">
    <style type="text/css">
    li {
      background-color: #ffe;
      border:           solid 2px #ccc;
      display:          block;
      float:            left;
      margin-right:     7px;
      padding:          5px;
    }
    li a {
      color: #0000a8;
    }
    ol {
      margin-left:  0;
    }
    </style>
  </head>
  <body>
    <ol>
HEADER
end

def footer image_file_name
  return <<FOOTER
    </ol>
    <p>
      <br style=\"clear: left;\">
      <br>
      <img alt="a screenshot" src="#{image_file_name}">
    </p>
  </body>
</html>
FOOTER
end

# If an argument is supplied, it's used as a filename prefix to allow
# multiple sets of screenshots to be stored concurrently.
PREFIX = ARGV[0] || ''

# Create a list of tuples [src, dest_base] where:
#   src is the local file path e.g. /Users/brian/Picture 1.png
#   dest is the base filename (w/o ext) for the remote image & html files
#
# We need to create the list of tuples first to allow creating a complete
# list of links in each html wrapper file.
file_list = Dir[File.expand_path("~/Desktop") +
                "/Picture {[0-9],[0-9][0-9]}.png"].map do |path|
  [ path.sub(/ /, '\ '),  # escape space for command line invocation
    PREFIX + File.basename(path).sub(/Picture /, 'pic').sub(/\.png/, '') ]
end

file_list.each do |src, dest_base|
  # Create wrapper html
  temp_path = '/tmp/' + dest_base + '.html'

  File.open(temp_path, 'w') do |tf|
    tf.puts header
    file_list.each do |src2, dest_base2|
      tf.puts "      <li><a href=\"#{dest_base2}.html\">#{dest_base2.sub(/#{PREFIX}/,'')}</a></li>"
    end
    tf.puts footer(dest_base + '.jpg')
  end

  # Copy html wrapper and image to server
  puts "Copying #{URL_BASE}/#{dest_base}.html"
  `scp #{temp_path} #{USERNAME}@#{HOSTNAME}:#{REMOTE_DIR}`
  File.delete(temp_path)
  puts "Copying #{dest_base}.jpg"
  temp_file = "/tmp/#{dest_base}.jpg"
  `convert -background white -flatten #{src} #{temp_file}`
  `scp #{temp_file} #{USERNAME}@#{HOSTNAME}:#{REMOTE_DIR}/#{dest_base}.jpg`
end


