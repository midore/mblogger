#!/path/to/ruby19
# coding: utf-8
#------------------------------------------
# mblogger-run.rb
# last: 2010-07-01 
# gdata
# http://code.google.com/p/gdata-ruby-util/downloads/list
#------------------------------------------

module Mblogger
  class Start
    def self.run
      dir = File.dirname(File.dirname(File.expand_path($PROGRAM_NAME)))
      bin = File.join(dir, 'bin')
      lib = File.join(dir, 'lib')
      $LOAD_PATH.push(bin, lib)
      $LOAD_PATH.delete(".")

      ARGV.empty? ? exit : ARGV.delete("")
      require 'mblogger/mblogger-arg'
      err, arg_h = CheckStart.new(ARGV).base
      if err
        err == 'help' ? exit : (print "#{err}\n"; exit)
      end
      # start
      # Your Path
      conf = '/path/to/your/mblogger-config'
      load conf, wrap=true
      # Your Path
      require 'path/to/gdata-1.1.1/lib/gdata.rb'
      # mblogger lib
      require 'mblogger'
      Xblog.new(arg_h).base
    end
  end
end
Mblogger::Start.run

=begin
if see this error, 
  ... gdata-1.1.1/lib/gdata.rb:21:in `require': no such file to load -- jcode (LoadError)

 You need to edit line 21 and line 22 of file 'gdata-1.1.1/lib/gdata.rb'.
 Because, ruby 1.9.1 not support jcode and $KCODE.
 ...like this...
 # require 'jcode' 
 # $KCODE = 'UTF8'
=end

