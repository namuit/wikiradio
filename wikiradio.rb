#!/usr/bin/ruby

# ARCHIVIO WIKIRADIO 2011-2015, 2016 e 2017
PODCAST_URLS = [
    'http://www.radio.rai.it/radio3/podcast/rssradio3.jsp?id=6079',
    'http://www.radio.rai.it/rss/podcast/rssradio.jsp?channel=RF3&id=17348',
    'http://www.radio.rai.it/rss/podcast/rssradio.jsp?channel=RF3&id=19810'
]

require 'net/http'
require 'rubygems'
require 'xmlsimple'
require 'date'
require "fileutils"
require 'zaru'

def http_download_uri(uri, filename)
  http_object = Net::HTTP.new(uri.host, uri.port)
  http_object.use_ssl = true if uri.scheme == 'https'
  begin
    http_object.start do |http|
      request = Net::HTTP::Get.new uri.request_uri
      http.read_timeout = 500
      http.request request do |response|
        open filename, 'w' do |io|
          response.read_body do |chunk|
            io.write chunk
          end
        end
      end
    end
  rescue Exception => e
    puts "=> Exception: '#{e}'. Skipping download."
    return
  end
end

def download_podcast(podcast_url)

    xml_data = Net::HTTP.get_response(URI.parse(podcast_url)).body
    data = XmlSimple.xml_in(xml_data)

    data['channel'][0]['item'].each do |item|

        podcast = item['enclosure'][0]['url']
        title = item['title'][0]
        description = item['description'][0]

        if not title.include? " - "
            title = "#{title} - #{description}"
        end

        file_name = "#{Zaru.sanitize! title.gsub("/",'-')}.mp3"

        regex='.*?((?:(?:[0-2]?\\d{1})|(?:[3][01]{1}))[-:\\/.](?:[0]?[1-9]|[1][012])[-:\\/.](?:(?:[1]{1}\\d{1}\\d{1}\\d{1})|(?:[2]{1}\\d{3})))(?![\\d])' # DDMMYYYY

        m = Regexp.new(regex,Regexp::IGNORECASE)
        date_episode = Date.strptime(m.match(title)[1],"%d/%m/%Y")
        download_folder_episode = "wikiradio/#{date_episode.year.to_s}/#{date_episode.month.to_s}/"
        FileUtils::mkdir_p download_folder_episode
        puts "Checking for file '#{file_name}'"
        file_path = "#{download_folder_episode}/#{file_name}"
        if File::exists?(file_path) then
            puts "Skipping existing file '#{file_name}'"
        else
            puts "Downloading non-existent file '#{file_name}'to #{download_folder_episode}..."
            http_download_uri URI.parse(podcast), file_path
        end
    end
end

PODCAST_URLS.each do |podcast_url|
    download_podcast(podcast_url)
end