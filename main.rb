require 'rubygems'
require 'nokogiri'
require 'net/http'
require "xiami/mp3_location"
require 'fileutils'


p "put the url:"
url = gets.sub("\n","")
p url
p "put the path"
path = gets.sub("\n","")
if File.exist?(path)
  raise "path exists"
end
FileUtils.mkdir_p(path)


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
  raise "无效的地址"
end
p list
list.each do |song_url|
  m3l = Xiami::Mp3Location.create(song_url)
  mp3_url = m3l.mp3_url
  song_name = m3l.song_name
  album_name = m3l.album_name
  artist_name = m3l.artist_name
  p mp3_url
  `wget -O "#{path}/#{song_name}--#{album_name}(#{artist_name}).mp3" "#{mp3_url}"`
  sleep(rand(5))
end
