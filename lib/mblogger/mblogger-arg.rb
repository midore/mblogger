module Mblogger

  class Checkconf

    def check_arg(arg)
      err = nil
      return err = 'lang' unless Encoding.default_external.name == 'UTF-8'
      return err = 'err0' if arg.empty?
      x, y = arg
      if x =~ /^-h$|^-help$/
        helpmsg
        return true
      end
      return err if x == '-blg-get' and y.nil?
      return err = 'err1' if y.nil?
      return err = 'err2' unless arg_key[x]
      unless x == '-blg-get'
        return err = 'err4' if File.directory?(y)
        return err = 'err4' unless File.exist?(y)
      else
        return err = 'err3' unless y =~ /\d{4}\-\d{2}$/
      end
      return err
    end

    private
    def arg_key
      a = {
        '-blg-get'=>'get entry',
        '-blg-doc'=>'print xml',
        '-blg-post'=>'post entry',
        '-blg-up'=>'up entry',
        '-blg-del'=>'delete entry',
        '-h|-help'=>'this help'
      }
    end

    def helpmsg
      arg_key.each{|k,v| print " #{k}: #{v}\n"}
    end

    def check_file(f)
      return File.exist?(f)
    end

    def arrtoh(arg)
      ak = arg_key
      h, k = Hash.new, nil
      arg.each{|x| k = x if ak[x]; h[k] = x if k}
      return h
    end

  end

end
