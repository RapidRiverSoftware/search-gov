class NewsSearch < Search
  DEFAULT_PER_PAGE = 10
  DEFAULT_VIDEO_PER_PAGE = 20
  attr_reader :rss_feed,
              :hits,
              :since

  def initialize(options = {})
    super(options)
    @query = (@query || '').squish
    @channel = options[:channel]
    @tbs = options[:tbs]
    @since = since_when(@tbs)
    assign_rss_feed(options[:channel])
    if @rss_feed
      @rss_feeds = [@rss_feed]
    else
      @rss_feeds = navigable_feeds
      @rss_feed = @rss_feeds.first if @rss_feeds.count == 1
    end
    @hits, @total = [] , 0
    assign_per_page
  end

  def search
    NewsItem.search_for(@query, @rss_feeds, @since, @page, @per_page)
  end

  def cache_key
    [@affiliate.id, @query, @channel, @tbs, @page, @per_page].join(':')
  end

  protected

  def handle_response(response)
    if response
      @total = response.total
      @results = paginate(process_results(response))
      @hits = response.hits(:verify => true)
      @startrecord = ((@page - 1) * 10) + 1
      @endrecord = @startrecord + @results.size - 1
    end
  end

  def assign_rss_feed(channel_id)
    @rss_feed = @affiliate.rss_feeds.find_by_id(channel_id.to_i) if channel_id.present?
  end

  def navigable_feeds
    @affiliate.rss_feeds.navigable_only
  end

  def assign_per_page
    @per_page = @rss_feed && @rss_feed.is_video? ? DEFAULT_VIDEO_PER_PAGE : DEFAULT_PER_PAGE
  end

  def process_results(response)
    processed = response.hits(:verify => true).collect do |hit|
      {
        'title' => highlight_solr_hit_like_bing(hit, :title),
        'link' => hit.instance.link,
        'publishedAt' => hit.instance.published_at,
        'content' => highlight_solr_hit_like_bing(hit, :description)
      }
    end
    processed.compact
  end

  def since_when(tbs)
    if tbs && (extent = NewsItem::TIME_BASED_SEARCH_OPTIONS[tbs])
      1.send(extent).ago
    end
  end

  def log_serp_impressions
    modules = []
    modules << "NEWS" unless @total.zero?
    modules << "SREL" unless @related_search.nil? or @related_search.empty?
    QueryImpression.log(:news, @affiliate.name, @query, modules)
  end

  def allow_blank_query?
    true
  end
end