#!/usr/bin/ruby
 
PODCAST_URL = 'http://www.radio.rai.it/radio3/podcast/rssradio3.jsp?id=6079'
 
require 'net/http'
require 'rubygems'
require 'xmlsimple'
require 'Date'
require "fileutils"
 
xml_data = Net::HTTP.get_response(URI.parse(PODCAST_URL)).body
data = XmlSimple.xml_in(xml_data)

data['channel'][0]['item'].each do |item|
    
    podcast = item['enclosure'][0]['url']
    title = item['title'][0]
    description = item['description'][0]
    file = podcast.split("/").last

    if not title.include? " - "
        title += description.camelcase
    end

    file = title.gsub("/",'-')  + ".mp3"

    regex='.*?((?:(?:[0-2]?\\d{1})|(?:[3][01]{1}))[-:\\/.](?:[0]?[1-9]|[1][012])[-:\\/.](?:(?:[1]{1}\\d{1}\\d{1}\\d{1})|(?:[2]{1}\\d{3})))(?![\\d])' # DDMMYYYY

    m = Regexp.new(regex,Regexp::IGNORECASE)
    date_episode = Date.strptime(m.match(title)[1],"%d/%m/%Y")
    download_folder_episode = "wikiradio" + "/" + date_episode.year.to_s + "/" + date_episode.month.to_s + "/"
    FileUtils::mkdir_p download_folder_episode

    puts "Checking for file '" + file + "'"
    if File::exists?(download_folder_episode + '/' + file) then
        puts "Skipping existing file '" + file + "'"
    else
        puts "Downloading non-existent file '" + file + "'..."
        file = download_folder_episode + '/' + file
        Net::HTTP.start(URI.parse(podcast).host) do |http|
            resp = http.get(podcast)
            open(file, "wb") do |file|
                puts "Writing file to disk..."
                file.write(resp.body)
            end
        end
    end
end
