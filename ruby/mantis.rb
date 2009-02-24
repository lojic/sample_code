#!/usr/local/bin/ruby

# This script reads a Mantis csv export via standard input.
# It looks for a pattern such as (7.5 h*) in the summary
# and extracts the number portion.
# It prints the mantis id, assignee, hours, summary

require 'csv'
column_id, column_assignee, column_priority, column_summary = 0, 3, 4, 17
sum = 0.0
first = true

CSV::Reader.parse(STDIN) do |row|
    if row[column_summary] =~ /\(([\d.]+) h.*\)/
        hours = Float($1)
    else
        hours = 0.0
    end

    sum += hours

    if first
        printf("%s,%s,%s,%s,%s\n", row[column_id], row[column_assignee], row[column_priority], "Est. hours", row[column_summary])
        first = false
    else
        printf("%s,%s,%s,%s,%s\n", row[column_id], row[column_assignee], row[column_priority], hours, row[column_summary])
    end
end

printf("sum=%s\n", sum)
