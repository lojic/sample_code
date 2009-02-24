#!/usr/local/bin/python

# This script reads a Mantis csv export via standard input.
# It looks for a pattern such as (7.5 h*) in the summary
# and extracts the number portion.
# It prints the mantis id, assignee, hours, summary
import csv
import re
import sys

column_id = 0 # index of Mantis id
column_assignee = 3 # index of Mantis assignee
column_priority = 4 # index of Mantis priority
column_summary = 17 # index of Mantis summary

reader = csv.reader(sys.stdin)
sum = 0.0
first = True

for row in reader:
	pattern = re.compile(r'\(([\d.]+) h.*\)')
	result = pattern.search(row[column_summary])

	if (result):
		hours = float(result.groups()[0])
	else:
		hours = 0.0

	sum += hours
	if (first):
		print '"%s","%s","%s","%s","%s"' % (row[column_id], row[column_assignee], row[column_priority], "Est. hours", row[column_summary])
		first = False
	else:
		print '"%s","%s","%s","%s","%s"' % (row[column_id], row[column_assignee], row[column_priority], hours, row[column_summary])

print 'sum =',sum


	
