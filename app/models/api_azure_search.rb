class ApiAzureSearch < ApiWebSearch
  def default_module_tag
    is_api_key_bing_v5? ? 'BV5W' : 'AWEB'
  end

  def query_formatting_klass
    AzureFormattedQuery
  end

  def engine_klass
    is_api_key_bing_v5? ? BingV5WebEngine : NoResultsEngine
  end
end
