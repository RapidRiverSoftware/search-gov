namespace :searchgov do
  desc 'Bulk index urls into Search.gov'
  # Usage: rake searchgov:bulk_index[my_urls.csv,10]

  task :bulk_index, [:url_file, :sleep_seconds] => [:environment] do |_t, args|
    CSV.foreach(args.url_file) do |row|
      url = row.first
      sleep(args.sleep_seconds.to_i || 10) #to avoid getting us blacklisted...
      begin
        searchgov_url = SearchgovUrl.create!(url: url)
        searchgov_url.fetch
        puts "Indexed #{searchgov_url.url}"
      rescue => error
        puts "Failed to index #{url}:\n#{error}".red
      end
    end
  end
end
