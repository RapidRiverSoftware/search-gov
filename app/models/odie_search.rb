class OdieSearch < Search
              
  def initialize(options = {})
    super(options)
    @query = (@query || '').squish
    @query.downcase! if @query.ends_with? " OR"
    @hits, @total = [], 0
  end

  def search
    IndexedDocument.search_for(@query, @affiliate, @page, 10)
  end
  
  def handle_response(response)
    if response 
      @total = response.total
      @startrecord = ((@page - 1) * 10) + 1
      @results = paginate(process_results(response))
      @endrecord = @startrecord + @results.size - 1
    end
  end
    
  def cache_key
    [@query, @affiliate.name, @page].join(':')
  end

  
  def as_json(options = {})
    if @error_message
      {:error => @error_message}
    else
      {
        :total => @total,
        :startrecord => @startrecord,
        :endrecord => @endrecord,
        :results => @results
      }
    end
  end

  def to_xml(options = {:indent => 0, :root => :search})
    if @error_message
      {:error => @error_message}.to_xml(options)
    else
      { :total => @total, :startrecord => @startrecord, :endrecord => @endrecord, :results => @results }.to_xml(options)
    end
  end

  protected

  def process_results(results)
    processed = results.hits(:verify => true).collect do |hit|
      {
        'title' => highlight_solr_hit_like_bing(hit, :title),
        'unescapedUrl' => hit.instance.url,
        'content' => highlight_solr_hit_like_bing(hit, :description),
        'cacheUrl' => nil,
        'deepLinks' => nil
      }
    end
    processed.compact
  end

  def log_serp_impressions
    modules = []
    modules << "ODIE" unless @total.zero?
    QueryImpression.log(:odie, @affiliate.name, @query, modules)
  end  
end