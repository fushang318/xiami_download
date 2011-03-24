require "cgi"
require "json"
module Xiami

  class Mp3Location
    attr_reader :mp3_url,:song_name,:album_name,:artist_name
    def initialize(song_id)
      @song_id = song_id
      parse_info
    end

    def self.create(song_url)
      song_id = song_url.match(/song\/([0-9]+)/)[1]
      self.new(song_id)
    end

    private
    def parse
      p "parse"
      json_src = "http://www.xiami.com/widget/json-single/uid/0/sid/#{@song_id}"
      url_str = URI.parse(json_src)
      site = Net::HTTP.new(url_str.host, url_str.port)
      json_str = site.get2(url_str.path,{'accept'=>'text/html'}).body
      location = JSON(json_str)["location"]
      @mp3_url = sospa(location)
    end

    def parse_info
      p "parse_info"
      info_src = "http://www.xiami.com/widget/xml-single/uid/0/sid/#{@song_id}"
      url_str = URI.parse(info_src)
      site = Net::HTTP.new(url_str.host, url_str.port)
      xml = site.get2(url_str.path,{'accept'=>'text/html'}).body
      doc = Nokogiri::XML(xml)
      @song_name = doc.at_css("song_name").content
      @album_name = doc.at_css("album_name").content
      @artist_name = doc.at_css("artist_name").content
      location = doc.at_css("location").content
      @mp3_url = sospa(location)
    end

    def sospa(location)
      totle = location.to_i
      new_str = location[1..-1]
      chu = (new_str.length.to_f / totle).floor
      yu = new_str.length % totle
      stor = []

      i = 0
      while i<yu do
        index = (chu+1)*i
        length = chu+1
        stor[i] = new_str[index...index+length]

        i+=1
      end


      i = yu
      while i<totle do
        index = chu*(i-yu)+(chu+1)*yu
        length = chu

        stor[i] = new_str[index...index+length]

        i+=1
      end

      pin_str = ""
      0.upto(stor[0].length-1) do |ii|
        0.upto(stor.length-1) do |jj|
          pin_str += stor[jj][ii...ii+1]
        end
      end

      pin_str = rtan(pin_str)
      return_str = ""

      0.upto(pin_str.length-1) do |iii|
        if pin_str[iii...iii+1]=='^'
          return_str<<"0"
        else
          return_str<<pin_str[iii...iii+1]
        end
      end

      return_str
    end

    def rtan(str)
      CGI::unescape(str)
    end
  end
end
