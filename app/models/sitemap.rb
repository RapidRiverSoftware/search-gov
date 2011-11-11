class Sitemap < ActiveRecord::Base
  validates_presence_of :url
  validates_uniqueness_of :url, :scope => :affiliate_id
  validates_format_of :url, :with => /(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?([\/].*)?$)/ix
  validate :is_valid_sitemap?
  belongs_to :affiliate
  
  def fetch
    begin
      file = open(url)
      parse(file)
    rescue Exception => e
      Rails.logger.error "Trouble fetching #{url} to index: #{e}"
    ensure
      update_attributes!(:last_crawled_at => Time.now)
      File.delete(file) unless file.nil?
    end
  end
  
  def parse(file)
    sitemap_doc = Nokogiri::XML(file)
    sitemap_doc.xpath("//xmlns:url").each do |url|
      IndexedDocument.create(:url => url.xpath("xmlns:loc").inner_text, :affiliate => self.affiliate)
    end
  end
  
  private
  
  def is_valid_sitemap?
    begin
      sitemap_doc = Nokogiri::XML(Kernel.open(url))
      errors.add(:url, "The Sitemap URL specified does not appear to be a valid Sitemap.") unless sitemap_doc.root.name == "urlset"
    rescue Exception => e
      errors.add(:url, "The Sitemap URL specified does not appear to be a valid Sitemap.  Additional information: " + e.message)
    end
  end
end