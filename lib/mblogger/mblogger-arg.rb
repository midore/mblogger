module Mblogger

  class CheckStart

    def initialize(arg)
      @err = false
      m, @h = '', Hash.new
      arg.each{|x| m = /^-(.*)/.match(x) if /^-/.match(x); @h[m[1].to_sym] = x if m}
    end

    def base
      return "Error: $LANG must be UTF-8" unless Encoding.default_external.name == 'UTF-8'
      return help if (@h.has_key?(:h) or @h.has_key?(:help))
      return check_arg
    end

    private
    def help
      arg_keys.each{|k,v| print "#{k}: #{v}\n"}
      return 'help'
    end

    def arg_keys
      {
        '-blg-get'=>'Get entry. Example: -blg-get 2010-01',
        '-blg-doc'=>'Print text file to XML doc. Example: -blg-doc draft.txt',
        '-blg-post'=>'Post entry.  Example: -blg-post draft.txt',
        '-blg-up'=>'Update entry.  Example: -blg-up /path/2010-01-01-xxx.txt',
        '-blg-del'=>'Delete entry. Example: -blg-del /path/2010-01-01-xxx.txt',
        '-h'=>'this Help'
      }
    end

    def check_arg
      err_no_str, err_no_file = "No option", "Not exist file"
      @h.keys.each{|k| return @err = err_no_str unless arg_keys["-#{k}"]}
      k = @h.keys[0]
      if k == :"blg-get"
        (@h[:"blg-get"] == "-blg-get") ? @h[:"blg-get"] = Time.now().strftime("%Y-%m") : nil
        return arg_keys['-blg-get'] unless /\d{4}\-\d{2}$/.match(@h[:"blg-get"])
      else
        return err_no_file unless File.exist?(@h[k]) and File.file?(@h[k])
      end
      return [@err, @h]
    end

  end

end
