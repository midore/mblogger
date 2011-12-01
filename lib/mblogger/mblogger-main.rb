module Mblogger
  class Xblog
    def initialize(h)
      @req, @opt = h.keys[0].to_s, h.values[0]
    end

    def base
      begin
        blogger_api
      rescue GData::Client::AuthorizationError
        print "ERROR: Blogger Login Error. LOOK! /path/to/xblogger-config\n"
        exit
      rescue GData::Client::UnknownError
        print "ERROR: Entry not found\n"
        exit
      rescue => err
        print "ERROR: #{err.class}\n"
        exit
      end
    end

    private
    def blogger_api
      # {:getinfo=>"--getinfo"} {:get=>"--get"} {:getentry=>"123"}
      case @req
      when /get/
        GetRequest.new(@req, @opt)
      when /^doc$/
        ReadText.new(@opt).to_str
      when /^post$/
        x = get_obj_text
        exit unless gets_msg("\nPost Entry\n")
        rh = PostRequest.new(x).base
      when /^update$/
        x = get_obj_text
        exit unless gets_msg("\nUpdate Entry\n")
        UpdateRequest.new(x).base
      when /^del$/
        GetRequest.new("getentry", @opt)
        exit unless gets_msg("\nDelete Entry\n")
        DeleteRequest.new(@opt).base
      end
    end

    def get_obj_text
      x = ReadText.new(@opt)
      x.to_s
      return x
    end

    def gets_msg(str)
      print "#{str}", "OK? [y/n]\n"
      ans = $stdin.gets.chomp
      exit if /^n$/.match(ans)
      exit if ans.empty?
      return true if ans == 'y'
    end
  end

  class RequestBase
    include $MBLOGGER
    def initialize
      exit unless check
      exit unless dir_check
    end

    def posturl
      "https://www.blogger.com/feeds/#{xid}/posts/default"
    end

    def loginauth
      a = GData::Client::Blogger.new
      a.source = xname
      token = a.clientlogin(ac, pw)
      a.headers = {
        "Authorization" => "GoogleLogin auth=#{token}",
        'Content-Type' => 'application/atom+xml'
      }
      return a
    end

    def print_status_code(res, no)
      print "Status Code: ", res.status_code, "\n"
      exit unless res.status_code == no
    end

    def check
      str = "Error: Not Found data directory.\n"
      return print str unless dir_check
      return nil unless pw
      return nil unless ac
      return true
    end

    def dir_check
      d = data_dir
      return false unless File.exist?(d)
      return false unless File.directory?(d)
      return d
    end

    def err_msg(n)
      case n
      when 1 then print "Error 1: this entry was posted, already.\n"
      when 2 then print "Error 2: need to post entry, before update.\n"
      when 3 then print "Error 3: edit_id is empty.\n"
      when 4 then print "Error 4: some error in text file.\n"
      end
    end
  end

  class PostRequest < RequestBase
    def initialize(x)
      @xml, @eid = x.to_xml, x.h[:edit_id]
      @h, @cont = x.h, x.content
      @view = ResultView.new
    end

    def base
      return err_msg(1) if @eid
      print "-"*5, " POST REQUEST \n"
      res = loginauth.post(posturl, @xml)
      print_status_code(res, 201)
      rh = @view.base(res, "postentry")
      return nil unless rh
      save_file(rh)
    end

    def save_file(rh)
      h = @h.merge(rh)
      h[:content] = @cont
      h[:dir] = data_dir
      SaveText.new(h).base
    end
  end

  class UpdateRequest < RequestBase
    def initialize(x)
      @xml = x.to_xml
      @eid = x.h[:edit_id]
      @url = posturl + "/" +  @eid if @eid
    end

    def base
      return err_msg(2) unless @eid
      print "-"*5, " PUT REQUEST \n"
      res = loginauth.put(@url, @xml)
      print_status_code(res, 200)
    end
  end

  class DeleteRequest < RequestBase
    def initialize(eid)
      @eid = eid
      @url = posturl + "/" + @eid if @eid
    end

    def base
      return err_msg(3) unless @eid
      print "-"*5, " Delete REQUEST \n"
      res = loginauth.delete(@url)
      print_status_code(res, 200)
    end
  end

  class ReadText
    attr_reader :content, :h
    def initialize(filepath)
      exit unless File.exist?(filepath)
      @ary = IO.readlines(filepath)
      @h = to_hash
    end

    def to_xml
      Mbxml.new().to_xml(@h, @con)
    end
    def to_s
      print "Title: #{@h[:title]}\n"
      print "Category: #{@h[:category]}\nControl: #{@h[:control]}\n"
    end

    def to_str
      to_s
      print "\n", to_xml, "\n"
    end

    private
    def to_hash
      mark = @ary.find_index("--content\n")
      h, k = need_key, nil
      @ary.each_with_index{|x,y|
        break if mark == y
        next if x.strip.empty?
        m = /^--(.*?)\n$/.match(x)
        m ? k = m[1].to_sym : (h[k] = x.strip if h.key?(k))
      }
      @con = @ary[mark+1..@ary.size]
      @content = @ary[mark+1..@ary.size].join().strip
      return nil unless check(h)
      return h
    end

    def need_key
      {
        :edit_id=>nil, :published=>nil, :updated=>nil,
        :date=>nil, :control=>nil, :category=>nil, :title=>nil
      }
    end

    def check(h)
      return print "Error: content.\n" unless h
      return print "Error: category\n" unless h[:category]
      return print "Error: title\n" unless h[:title]
      return print "Error: control\n" unless h[:control]
      return true
    end
  end

  class GetRequest < RequestBase
    def initialize(req, opt)
      @req = req
      @opt = @eid = opt
      @baseurl = "https://www.blogger.com/feeds/default/blogs"
      @feedurl = "https://www.blogger.com/feeds/#{xid}/posts/summary"
      @view = ResultView.new
      base
    end

    private
    def base
      print "-"*5, " #{@req.upcase} REQUEST \n"
      case @req
      when "getinfo"
        res = loginauth.get(@baseurl)
      when "get"
        res = loginauth.get(set_url)
      when "getentry"
        return nil if @eid.match(/\D/)
        url = posturl + "/" +  @eid
        res = loginauth.get(url)
      else
        exit
      end
      print_status_code(res, 200)
      @view.base(res, @req)
    end

    def set_url
      @opt = Time.now.strftime("%Y-%m") if @opt == "--get"
      @opt.match(/^\d{4}.\d{2}$/) ? opt = set_time : opt = set_category
      return @feedurl + opt
    end

    def set_time
      t = Time.parse(@opt.gsub("-","/"))
      min = t.strftime("%Y-%m-%dT%H:%M:%S")
      t.month == 12 ? x = [t.year+1, 1] : x = [t.year, t.month+1]
      max = Time.local(x[0], x[1], 1).strftime("%Y-%m-%dT%H:%M:%S")
      return "?published-min=#{min}&published-max=#{max}"
    end

    def set_category
      return "?category=#{@opt.gsub(",","&amp;")}"
    end
  end

  class SaveText
    def initialize(h)
      return nil unless h[:dir]
      @h = h
      @dir, @pubd = h[:dir], h[:published]
      @h.delete(:dir)
    end

    def base
      path, data = getpath, getdata
      if File.exist?(path)
        return print "\nError: Same file exist.\nFile: #{path}\n"
      end
      File.open(path, 'w:utf-8'){|f| f.print data}
      print "Saved: #{path}\n"
    end

    private
    def getdata
      str = String.new
      @h[:date] ||= Time.parse(@pubd).strftime("%Y/%m/%d %a %p %H:%M:%S")
      a = [:edit_id, :published, :updated, :date, :control, :category, :title, :url]
      a.each{|k|
        next if @h[k].nil?
        str << "--#{k}\n#{@h[k]}\n"
      }
      str << "--content\n#{@h[:content]}\n"
      return str
    end

    def getpath
      return nil unless @dir
      subd = File.join(@dir, Time.parse(@pubd).strftime("%Y-%m"))
      Dir.mkdir(subd) unless File.exist?(subd)
      f = Time.parse(@pubd).strftime("%Y-%m-%dT%H-%M-%S") + "-" + @h[:edit_id] + ".txt"
      File.join(subd, f)
    end
  end
  # end of module
end
