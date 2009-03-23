#!/usr/bin/env ruby
require 'rubygems'
require 'statement'

Dir.glob("statements/*.pdf").each do |pdf|
  st=Statement.new pdf
  puts "#{pdf}, Date: #{st.statement_end_date}, Start #{st.starting_balance}, End #{st.ending_balance}, #{st.all.size} transactions"
end
