require 'rubygems'
require 'nokogiri'
require 'net/http'
require "xiami/mp3_location"
require 'fileutils'


p "put the xiami url:"
url = gets.sub("\n","")
p url
p "put the save dir:"
path = gets.sub("\n","")
if !File.exist?(path)
  FileUtils.mkdir_p(path)
end


url_str = URI.parse(url)
site = Net::HTTP.new(url_str.host, url_str.port)
xml = site.get2(url_str.path,{'accept'=>'text/html','user-agent'=>'Mozilla/5.0'}).body
doc = Nokogiri::HTML(xml)


list = []
case url
when /album/
  doc.css("div[id='track'] table.track_list tr").each do |tr|
    a = tr.at_css("td.song_name a")
    url = a["href"]
    list << url
  end
when /showcollect/
  doc.css("div[id='list_collect'] div.quote_song_list li .song_name").each do |span|
    as = span.css("a")
    url = as.first["href"]
    list << url
  end
else
  raise "Invalid Url"
end
list_count = list.length
list.each_with_index do |song_url,index|
  m3l = Xiami::Mp3Location.create(song_url)
  mp3_url = m3l.mp3_url
  song_name = m3l.song_name
  album_name = m3l.album_name
  artist_name = m3l.artist_name

  mp3 = "#{path}/#{song_name}--#{album_name}(#{artist_name}).mp3"

  p "download the #{index+1} song, total #{list_count}"
  next if File.exist?(mp3)

  retry_count = 5
  begin
    `wget -O "#{mp3}" "#{mp3_url}"`
  rescue Exception => ex
    if retry_count < 0
      raise "download the #{index+1} song error"
    else
      retry_count -= 1
      retry
    end
  end

  sleep(rand(5))
end
