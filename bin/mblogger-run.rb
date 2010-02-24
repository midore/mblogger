#!/usr/bin/local/ruby19
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
err, arg_h = Mblogger::CheckStart.new(arg).base

# help
exit if err == 'help'

# error
(print "#{err}\n"; exit) if err

# start
conf = File.join(bin, 'mblogger-config')
load conf, wrap=true

# you need to edit require path
# require 'gdata-1.1.1/lib/gdata.rb' # Edit this line, your gdata path. 

=begin
if see this error, 
  ... gdata-1.1.1/lib/gdata.rb:21:in `require': no such file to load -- jcode (LoadError)

 You need to edit line 21 and line 22 of file 'gdata-1.1.1/lib/gdata.rb'.
 Because, ruby 1.9.1 not support jcode and $KCODE.
 ...like this...
 # require 'jcode' 
 # $KCODE = 'UTF8'
=end

# mblogger lib
require 'mblogger'
Mblogger::Xblog.new(arg_h).base

