module Mblogger

  class Xblog

    def base(req, x)
      data, eid = setup(req, x)
      begin
        case req
        when '-blg-doc' then g_doc(data)
        when '-blg-get' then g_get(x)
        when '-blg-post' then g_post(data, eid)
        when '-blg-up' then g_up(data, eid)
        when '-blg-del' then g_del(eid)
        end
      rescue
      end
    end

    private
    def setup(req, x)
      unless req == '-blg-get'
        dc = Xdoc.new(x)
        return nil unless h = dc.base
        @t_head = h
        data = dc.data(h)
        eid = h[:edit_id]
        @t_body = dc.str_content unless req == '-blg-del'
        print_t_head
        return [data, eid]
      end
    end

    def err_msg(n)
      case n
      when 1 then print "Error1: posted, already.\n"
      when 2 then print "Error2: need to post request, before update.\n"
      when 3 then print "Error3: edit_id is empty.\n"
      end
    end

    def g_doc(data)
      print data, "\n"
    end

    def g_get(x)
      Start.new().xget(x)
    end

    def g_post(data, eid)
      return err_msg(1) unless eid.nil?
      return nil unless data
      rh = Start.new().xpost(data)
      return nil unless rh
      h = @t_head.merge(rh)
      h[:content] = @t_body
      SaveText.new(h).base
    end

    def g_up(data, eid)
      return nil unless data
      return err_msg(2) unless eid
      Start.new(eid).xup(data)
    end

    def g_del(eid)
      return err_msg(3) unless eid
      Start.new(eid).xdel
    end

    def print_t_head
      print_hash(@t_head)
      print "-"*5, "\n"
    end

    def print_hash(h)
      print "\n"
      h.each{|k,v| print k.upcase, ": ", v, "\n" if v}
    end
 
  end

  class Start

    include $MBLOGGER
    def initialize(eid=nil)
      @eid = eid
      @xurl = "http://www.blogger.com/feeds/#{xid}/posts/default"
    end

    def xget(x)
      return nil unless u = range_t(x)
      request_get(u)
    end

    def xdel
      print "Edit_id: #{@eid}\n"
      u = @xurl + "/" + @eid
      request_del(u)
    end

    def xpost(data)
      str = "Error: path to data directory. edit bin/mblogger-conf\n"
      return print str unless d = dir_check
      rh = request_post(data)
      rh[:dir] = d
      return rh
    end

    def xup(data)
      print "Edit_id: #{@eid}\n"
      u = @xurl + "/" + @eid
      request_up(u, data)
    end

    private
    def dir_check
      d = data_dir
      return false unless File.exist?(d)
      return false unless File.directory?(d)
      return d
    end

    def request_get(u)
      r = clbase.get(u)
      res_to_getreq(r)
      code_msg(r, 'get')
    end

    def request_del(u)
      r = clbase.delete(u)
      code_msg(r, 'delete')
    end

    def request_post(data)
      r = clbase.post(@xurl, data.to_s)
      code_msg(r, 'post')
    end

    def request_up(u, data)
      r = clbase.put(u, data.to_s)
      code_msg(r, 'update')
    end

    def code_msg(r, str)
      n = r.status_code
      print "StatusCode: #{n}\n"
      if str == 'post'
        if n == 201
          success_msg(str)
          return res_to_h(r)
        end
      else
        success_msg(str) if n == 200
      end
    end

    def success_msg(str)
      print "Success: request #{str}.\n\n"
    end

    def clbase
      begin
        a = GData::Client::Blogger.new
        a.source = xname
        token = a.clientlogin(ac, pw)
        a.headers = {
          "Authorization" => "GoogleLogin auth=#{token}",
          'Content-Type' => 'application/atom+xml'
        }
        return a
      rescue SocketError
        print "Error: SocketError\n"
      rescue => err
        print "#{err.class} #{err.message}\n"
      end
    end

    def res_to_h(res)
      return nil unless res.to_xml.root.name == "entry"
      h = Hash.new
      @xr = res.to_xml.root
      h[:edit_id] = res_editid
      h[:published] = get_xstr('published')
      h[:updated] = get_xstr('updated')
      print_hash(h)
      return h unless h.empty?
    end

    def print_hash(h)
      print "\n"
      h.each{|k,v| print k.upcase, ": ", v, "\n" if v}
    end
 
    def res_editid
      edit = @xr.elements["link[@rel='edit']"].attributes['href']
      edit.to_s.gsub(/.*?default\//,'')
    end

    def get_xstr(str)
      return nil unless @xr.elements[str]
      @xr.elements[str].text
    end

    def range_t(t)
      return nil unless t = set_time(t)
      min = t.strftime("%Y-%m-01T00:00:00")
      t.month == 12 ? x = [t.year+1, 1] : x = [t.year, t.month+1]
      max = (Time.local(x[0], x[1], 1) - 1).strftime("%Y-%m-%dT%H:%M:%S")
      print "\nRange: #{min} ~ #{max}\n"
      return @xurl + "?published-min=#{min}" + "&published-max=#{max}"
    end

    def set_time(t)
      unless t.nil?
        m = /(\d{4}).(\d{2})/.match(t)
        t = m[1] + "/" + m[2] if m
      else
        t = Time.now.strftime("%Y/%m")
      end
      begin
        t = Time.parse(t)
      rescue ArgumentError
        return print "Error: Time parse error. example: 2010-01.\n"
      end
    end

    def res_to_getreq(r)
      r.to_xml.elements.each('entry'){|x|
        h, @xr = {}, x
        h[:title] = get_xstr('title')
        h[:edit_id] = res_editid
        h[:published] = get_xstr('published')
        h[:updated] = get_xstr('updated')
        h[:control] = get_xstr('app:control/app:draft')
        print "-"*5, "\n"
        print_hash(h)
      }
    end
  
  end

  class Xdoc

    def initialize(path)
      @ary = IO.readlines(path)
    end

    def base
      return nil unless h = ary_to_h
      return h
    end

    def content
      mark = @ary.find_index("--content\n")
      @ary[mark+1..@ary.size]
    end

    def str_content
      str = content.join().strip
      (str.empty?) ? nil : str
    end

    def data(h)
      Mbxml.new().to_xml(h, content)
    end

    private
    def check(h)
      return print "TextError: parse text.\n" unless h
      return print "TextError: category\n" unless h[:category]
      return print "TextError: title\n" unless h[:title]
      return print "TextError: control\n" unless h[:control]
      return true
    end

    def ary_to_h
      return check(nil) unless mark = @ary.find_index("--content\n")
      h, k = text_h, nil
      @ary.each_with_index{|x,y|
        break if mark == y
        next if x.strip.empty?
        m = /^--(.*?)\n$/.match(x)
        unless m
          h[k] = x.strip if h.key?(k)
        else
          k = m[1].to_sym
        end
      }
      return nil unless check(h)
      return h
    end

    def text_h
      h = Hash.new
      a = [:edit_id, :published, :updated, :date, :control, :category, :title]
      a.each{|s| h[s.to_sym] = nil}
      return h
    end

  end

  class SaveText

    def initialize(h)
      @h = h
      @pubd = h[:published]
      @dir = h[:dir]
      @str = String.new.encode("UTF-8")
    end

    def base
      path, data = getpath, getdata
      if File.exist?(path)
        print "\nError: Same name file is exist.\nFile: #{path}\n" 
        return nil
      end
      File.open(path, 'w:utf-8'){|f| f.print data}
      print "Saved: #{path}\n"
    end

    private
    def getdata
      @h[:date] ||= Time.parse(@pubd).strftime("%Y/%m/%d %a %p %H:%M:%S")
      @h.delete(:dir)
      @h.each{|k,v| @str << "--#{k}\n#{v}\n"}
      return @str
    end

    def getpath
      t = Time.parse(@pubd).strftime("%Y-%m-%dT%H-%M-%S")
      f = t + "-" + @h[:edit_id] + ".txt"
      File.join(@dir, f)
    end

  end

  # end of module
end

# test
#rh = {:edit_id=>'1234567890', :published=>'2010-01-01T00:00:00.001+09:00'}

