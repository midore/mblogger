module Mblogger

  class Xblog

    def initialize(req, path)
      @req = req
      return @year_month = path if req == '-blg-get'
      @t_head, @t_xdoc, @t_body = Xdoc.new(path).base
      return err_msg(4) if @t_head.nil? 
      @t_id = @t_head[:edit_id]
      @t_body = nil unless req == '-blg-post'
    end

    def base
      print_t_head if @t_head 
      begin
        case @req
        when '-blg-doc' then g_doc
        when '-blg-get' then g_get
        when '-blg-post' then g_post
        when '-blg-up' then g_up
        when '-blg-del' then g_del
        end
      rescue
      end
    end

    private
    def err_msg(n)
      case n
      when 1 then print "Error1: posted, already.\n"
      when 2 then print "Error2: need to post, before update.\n"
      when 3 then print "Error3: edit_id is empty.\n"
      when 4 then print "Error4: text file format.\n"
      end
    end

    def g_doc
      print @t_xdoc, "\n"
    end

    def g_get
      Start.new().xget(@year_month)
    end

    def g_post
      return err_msg(1) unless @t_id.nil?
      return nil unless @t_xdoc
      rh = Start.new().xpost(@t_xdoc)
      return nil unless rh
      h = @t_head.merge(rh)
      h[:content] = @t_body
      SaveText.new(h).base
    end

    def g_up
      return err_msg(2) if @t_id.nil?
      return nil if @t_xdoc.nil?
      Start.new(@t_id).xup(@t_xdoc)
    end

    def g_del
      return err_msg(3) if @t_id.nil?
      Start.new(@t_id).xdel
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
        return nil unless n == 201
        success_msg(str)
        return res_to_h(r)
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
      ary = IO.readlines(path)
      @mark = ary.find_index("--content\n")
      return check(nil) unless @mark
      content_h = ary[@mark+1..ary.size]
      content_s = content_h.join().strip
      return check(nil) if content_s.empty?
      @meta, @content = to_meta(ary), content_s
      @xdoc = to_xml(@meta, content_h) if @meta 
    end

    def base
      return nil if (@meta.nil? or @xdoc.nil?)
      return [@meta, @xdoc, @content]
    end

    private
    def to_xml(h, arr)
      Mbxml.new().to_xml(h, arr) 
    end

    def to_meta(ary)
      h, k = need_key, nil
      ary.each_with_index{|x,y|
        break if @mark == y
        next if x.strip.empty?
        m = /^--(.*?)\n$/.match(x)
        m ? k = m[1].to_sym : ( h[k] = x.strip if h.key?(k) )
      }
      return nil unless check(h)
      return h
    end

    def check(h)
      return print "Error: content.\n" unless h
      return print "Error: category\n" unless h[:category]
      return print "Error: title\n" unless h[:title]
      return print "Error: control\n" unless h[:control]
      return true
    end

    def need_key
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
        return print "\nError: Same name file is exist.\nFile: #{path}\n" 
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
      subd = File.join(@dir, Time.parse(@pubd).strftime("%Y-%m"))
      Dir.mkdir(subd) unless File.exist?(subd)
      f = Time.parse(@pubd).strftime("%Y-%m-%dT%H-%M-%S") + "-" + @h[:edit_id] + ".txt"
      File.join(subd, f)
    end

  end

  # end of module
end

# test
#rh = {:edit_id=>'1234567890', :published=>'2010-01-01T00:00:00.001+09:00'}

