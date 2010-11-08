xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title "Search.USA.gov Superfresh Feed"
    xml.description "Recently updated URLs from around the US Government"
    xml.link 'http://search.usa.gov'
    
    @superfresh_urls.each do |superfresh_url|
      xml.item do
        xml.title superfresh_url.url
        xml.link superfresh_url.url
        xml.pubDate Time.now.to_s(:rfc822)
      end
    end
  end
end
