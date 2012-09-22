# encoding: utf-8
import sys
import re
import httplib
from urlparse import urlparse
from pyquery import PyQuery as pq
import urllib
import urllib2
import os


class Mp3Location:
	def __init__(self,song_url,music_dir):
		self.song_url = song_url
		self.music_dir = music_dir
		r = re.search("song\/([0-9]+)",url)
		self.song_id = r.group(1)
		self.parse_info()

	def parse_info(self):
		info_src = "http://www.xiami.com/widget/xml-single/uid/0/sid/%s" % self.song_id
		body = get_body(info_src)
		xml = pq(body)
		self.song_name = xml("song_name").text()
		self.album_name = xml("album_name").text()
		self.artist_name = xml("artist_name").text()
		self.location = xml("location").text()
		self.mp3_url = self.sospa(self.location)

	def download(self):
		file_name = "%s\\%s--%s(%s).mp3" % (self.music_dir,self.song_name,self.album_name,self.artist_name)
		for i in range(0,10):
			try:
				req = urllib2.Request(url=self.mp3_url)
				f = urllib2.urlopen(req,timeout=10)
				fp = open(file_name, 'wb')
				mp3_data = f.read()
				fp.write(mp3_data)
				fp.close()			
			except:
				print sys.exc_info()[0],sys.exc_info()[1]
				print("retry %s" % file_name)
				continue

	

	def sospa(self,location):
		totle = int(location[0:1])
		new_str = location[1:]
		chu = len(new_str)/int(totle)
		yu = len(new_str) % totle
		stor = {}

		i = 0
		while i<yu:
			index = (chu+1)*i
			length = chu+1
			stor[i] = new_str[index:index+length]
			i+=1

		i = yu
		while i<totle:
			index = chu*(i-yu)+(chu+1)*yu
			length = chu
			stor[i] = new_str[index:index+length]
			i+=1

		pin_str = ""
		for ii in range(0,len(stor[0])):
			for jj in range(0,len(stor)):
				pin_str += stor[jj][ii:ii+1]

		pin_str = self.rtan(pin_str)
		return_str = ""

		for iii in range(0,len(pin_str)):
			if pin_str[iii:iii+1] == "^":
				return_str+="0"
			else:
				return_str+=pin_str[iii:iii+1]

		return return_str

	def rtan(self,str):
		return urllib.unquote_plus(str)


def get_body(url):
	for i in range(0,100):
		try:
			o = urlparse(url)
			conn = httplib.HTTPConnection(o.netloc,timeout=5)
			#conn.set_debuglevel(4)
			conn.request('GET', o.path)  
			res = conn.getresponse()
			return res.read()
		except:
			print("retry %s" % url)
			continue 



print u"下载 url"
base_dir = "g:\\xiami_music\\"
url = sys.stdin.readline()[:-1]

print url


html = get_body(url)
body = pq(unicode(html, "utf-8"))
urls = []
dir_name = ""

if re.search("album",url):
  def find_url(i,e):
 		u = pq(e)("td.song_name a").attr("href")
 		urls.append(u)
  body("div[id='track'] table.track_list tr").map(find_url)
  album_name = body("#title h1").text()
  artist = body("#album_info table tr:first-child td:last-child a").text()
  dir_name = artist + "_" + album_name
elif re.search("showcollect",url):
	def find_url(i,e):
		u = pq(e)("a").attr("href")
		urls.append(u)
	body("div[id='list_collect'] div.quote_song_list li .song_name").map(find_url)
	dir_name = body("#info_collect .info_collect_main h2").text()
elif re.search("artist",url):
	def find_url(i,e):
		u = pq(e)("a").attr("href")
		urls.append(u)
	body("table.track_list td.song_name").map(find_url)
	dir_name = body("#title").text() + "_top"
else:
	print("Invalid Url")

print(urls)
music_dir = base_dir + dir_name
print(music_dir)
os.makedirs(music_dir)

total = len(urls)
index = 1
for url in urls:
	print(u"下载 %s / %s" % (index,total))
	m3l = Mp3Location(url,music_dir)
	m3l.download()
	index+=1







