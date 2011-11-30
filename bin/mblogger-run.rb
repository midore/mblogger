# coding: utf-8
#
# ruby 1.9.3p0 (2011-10-30 revision 33570) [x86_64-darwin11.2.0]
# mblogger-run.rb
#------------------------------------------
# gdata =>http://code.google.com/p/gdata-ruby-util/downloads/list
#------------------------------------------

(print "Error: Only Ruby 1.9\n"; exit) if RUBY_VERSION < "1.9"
(print "Error: LANG"; exit) unless Encoding.default_external.name == 'UTF-8'

module Mblogger
  class Start
    def run
      ARGV.empty? ? exit : ARGV.delete("")
      require 'mblogger/mblogger-arg'
      err, arg_h = CheckStart.new(ARGV).base
      if err
        err == 'help' ? exit : (print "#{err}\n"; exit)
      end

      begin
        # Your Path
        conf = '/path/to/your/mblogger-config'
        load(conf)#, wrap=true)
        # Your Path
        require 'path/to/gdata-1.1.1/lib/gdata.rb'
        require 'mblogger'
        Xblog.new(arg_h).base
      rescue LoadError
         print "Error: path to \"mblogger-config\" or \"gdata library\"\n"
         exit
      end
    end
  end
end
Mblogger::Start.new.run

