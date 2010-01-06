# coding: utf-8

#------------------------------------------
# mblogger-run.rb
# 
# gdata
# http://code.google.com/p/gdata-ruby-util/downloads/list
#------------------------------------------

dir = File.dirname(File.dirname(File.expand_path($PROGRAM_NAME)))
bin = File.join(dir, 'bin')
lib = File.join(dir, 'lib')
$LOAD_PATH.push(bin, lib)
$LOAD_PATH.delete(".")

arg = ARGV
arg.delete("")

# argv check
require 'mblogger/mblogger-arg'
err = Mblogger::Checkconf.new().check_arg(arg)

# help
exit if err == true

# error
(print "#{err}\n"; exit) unless err.nil?

# start
conf = File.join(bin, 'mblogger-config')
load conf, wrap=true

# edit: /path/to/gdata-1.1.1/
require 'gdata-1.1.1/lib/gdata.rb'

# mblogger lib
require 'mblogger'
x, y = arg
Mblogger::Xblog.new().base(x,y)

