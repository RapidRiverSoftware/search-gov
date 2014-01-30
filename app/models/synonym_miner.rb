class SynonymMiner
  @queue = :primary_low

  def initialize(affiliate, days_back = 1)
    @affiliate = affiliate
    @affiliate.search_engine = 'Bing'
    @days_back = days_back
    @domains = @affiliate.site_domains.pluck(:domain)
  end

  def mine
    candidates.each { |candidate_group| Synonym.create_entry_for(candidate_group.join(', '), @affiliate) }
  end

  def candidates
    raw_synonym_sets = scrape_synonyms(popular_single_word_terms)
    grouped_synonyms = group_overlapping_sets(raw_synonym_sets)
    probably_acronyms, all_single_words = grouped_synonyms.partition { |synonym_array| synonym_array.any? { |synonym| synonym.split.many? } }
    unstemmed_singles = filter_stemmed(all_single_words)
    (probably_acronyms + unstemmed_singles).sort
  end

  def group_overlapping_sets(raw_synonym_sets)
    grouped_synonyms = []
    while raw_synonym_sets.present?
      candidate = raw_synonym_sets.shift
      partition = raw_synonym_sets.partition { |set| (set & candidate).empty? }
      if partition.last.empty?
        grouped_synonyms << candidate
      else
        raw_synonym_sets = partition.first << (partition.last.flatten + candidate).uniq.sort
      end
    end
    grouped_synonyms.sort
  end

  def popular_single_word_terms
    conditions = ['updated_at >= ? AND affiliate_id = ? and phrase not like "% %" and deleted_at IS NULL', @days_back.days.ago, @affiliate.id]
    SaytSuggestion.where(conditions).order("popularity desc").pluck(:phrase)
  end

  def filter_stemmed(singles)
    singles.select { |synset| tokens_from_analyzer(synset).many? }
  end

  def tokens_from_analyzer(synset)
    options = { text: synset.join(' '), analyzer: "#{@affiliate.locale}_analyzer", index: ElasticIndexedDocument.writer_alias }
    ES::client.indices.analyze(options)['tokens'].collect { |t| t['token'] }.uniq
  end

  def scrape_synonyms(queries)
    queries.collect { |query| extract_equivalents(bing_site_search_results(query)) }.uniq.select { |values| values.many? }
  end

  def bing_site_search_results(query)
    search = SiteSearch.new(query: query, affiliate: @affiliate, per_page: 20)
    search.run
    search.results
  end

  def extract_equivalents(results)
    results.map { |result| extract_highlights(result["title"]) + extract_highlights(result["content"]) }.flatten.uniq.sort
  end

  def extract_highlights(field)
    field.gsub(/(,|['’]s)/i, '').scan(/\uE000([^\uE000]*)\uE001/).flatten.map(&:downcase).reject { |f| f =~ /\A[0-9]+\z/ } - @domains
  end

  def self.perform(affiliate_id, days_back)
    affiliate = Affiliate.find affiliate_id
    synonym_miner = new(affiliate, days_back)
    synonym_miner.mine
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn("Could not find affiliate #{affiliate_id} in SynonymMiner.perform()")
  end

end
