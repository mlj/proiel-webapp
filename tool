#!/usr/bin/env ruby
#
# tool - PROIEL tool runner
#
# Written by Marius L. Jøhndal, 2008.
#
# $Id: $
#
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'lib')
require 'tools'

if ARGV.length < 2 
  STDERR.puts "tool user_name tool_name tool_arguments"
  exit 1
end

user_name = ARGV.shift
tool_name = ARGV.shift
args = ARGV
PROIEL::Tools.execute(tool_name, user_name, *args)

exit 0
