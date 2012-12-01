require 'time'

require 'rest-core'
require 'eventmachine'
require 'nokogiri'
require 'hashie/mash'

require_relative 'xml_middleware'


class Nokogiri::XML::Node
  def content_node(css)
    nodes = css(css)
    if nodes.size == 0
      nil
    elsif nodes.size == 1
      nodes[0].content
    else
      raise "more then one node for #{css}: #{nodes.size}"
    end
  end
end

module EM
  
  class TvDB
    Client = RestCore::Builder.client do
      s = RestCore
      use s::DefaultSite , 'http://www.thetvdb.com/api'
      use s::XmlDecode
      use s::CommonLogger, method(:puts)
      use s::Cache       , nil, 3600
      run s::EmHttpRequest
    end
  
    def initialize(api_key)
      @api_key = api_key
      @client = Client.new
    end
  
    # <?xml version="1.0"?>
    # <Data>
    #   <Series>
    #     <seriesid>158661</seriesid>
    #     <language>en</language>
    #     <SeriesName>Haven</SeriesName>
    #     <banner>graphical/158661-g2.jpg</banner>
    #     <Overview>...</Overview>
    #     <FirstAired>2010-07-09</FirstAired>
    #     <IMDB_ID>tt1519931</IMDB_ID>
    #     <zap2it_id>SH01281487</zap2it_id>
    #     <id>158661</id>
    #   </Series>
    #   <Series>
    #     <seriesid>70971</seriesid>
    #     <language>en</language>
    #     <SeriesName>Castle Haven</SeriesName>
    #     <FirstAired>1969-04-01</FirstAired>
    #     <id>70971</id>
    #   </Series>
    # </Data>
    def search_serie(name, &block)
      @client.get("/GetSeries.php", :seriesname => name) do |xml|
        series = xml.css('Series').map do |serie|
          Hashie::Mash.new(
            :id       => serie.content_node('seriesid'),
            :name     => serie.content_node('SeriesName'),
            :overview => serie.content_node('Overview')
          )
        end
      
        block.call(series)
      end
    end
    
    # <Episode>
    #   <id>4158103</id>
    #   <Combined_episodenumber>13</Combined_episodenumber>
    #   <Combined_season>2</Combined_season>
    #   <DVD_chapter></DVD_chapter>
    #   <DVD_discid></DVD_discid>
    #   <DVD_episodenumber></DVD_episodenumber>
    #   <DVD_season></DVD_season>
    #   <Director>Shawn Piller</Director>
    #   <EpImgFlag>2</EpImgFlag>
    #   <EpisodeName>Silent Night</EpisodeName>
    #   <EpisodeNumber>13</EpisodeNumber>
    #   <FirstAired>2011-12-06</FirstAired>
    #   <GuestStars>Niamh Wilson|Craig Eldridge</GuestStars>
    #   <IMDB_ID></IMDB_ID>
    #   <Language>en</Language>
    #   <Overview>...</Overview>
    #   <ProductionCode></ProductionCode>
    #   <Rating>7.9</Rating>
    #   <RatingCount>14</RatingCount>
    #   <SeasonNumber>2</SeasonNumber>
    #   <Writer>Brian Millikin</Writer>
    #   <absolute_number></absolute_number>
    #   <filename>episodes/158661/4158103.jpg</filename>
    #   <lastupdated>1327959365</lastupdated>
    #   <seasonid>463844</seasonid>
    #   <seriesid>158661</seriesid>
    # </Episode>
    def episodes(serie_id, &block)
      @client.get("/#{@api_key}/series/#{serie_id}/all/en.xml") do |xml|
        episodes = xml.css('Episode').map do |ep|
          aired_date = ep.content_node('FirstAired')
          
          if aired_date.empty?
            aired_date = nil
          else
            aired_date = Time.parse(aired_date)
          end
          
          
          Hashie::Mash.new(
            :id               => ep.content_node('id'),
            :name             => ep.content_node('EpisodeName'),
            :episode_number   => ep.content_node('EpisodeNumber').to_i,
            :season_number    => ep.content_node('SeasonNumber').to_i,
            :aired_date       => aired_date,
            :overview         => ep.content_node('Overview')
          )
        end
        
        episodes.select{|ep| ep.season_number > 0 }.sort_by(&:episode_number)
        
        block.call(episodes)
      end
    end

  private
    def xml_node(root, css)
      nodes = root.css(css)
      if nodes.size == 0
        nil
      elsif nodes.size == 1
        nodes[0].content
      else
        raise "more then one node for #{css}: #{nodes.size}"
      end
    end
  
  end
end
