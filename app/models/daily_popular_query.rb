class DailyPopularQuery < ActiveRecord::Base
  @queue = :usasearch

  belongs_to :affiliate
  validates_presence_of :day, :query, :times, :time_frame
  validates_uniqueness_of :query, :scope => [:day, :affiliate_id, :is_grouped, :time_frame]

  class << self

    def most_recent_populated_date(affiliate = nil, locale = I18n.default_locale.to_s)
      conditions = affiliate.nil? ? ["ISNULL(affiliate_id) AND locale=?", locale] : ["affiliate_id=? AND locale=?", affiliate.id, locale]
      maximum(:day, :conditions => conditions)
    end

    def calculate(day, time_frame, method, is_grouped)
      Resque.enqueue(DailyPopularQuery, day, time_frame, method, is_grouped)
    end

    def perform(day_string, time_frame, method, is_grouped)
      day = Date.parse(day_string)
      delete_all(["day = ? and time_frame = ? and is_grouped = ?", day, time_frame, is_grouped])
      query_counts = DailyQueryStat.send(method, day, time_frame, 1000)
      query_counts.each do |query_count|
        create!(:day => day, :affiliate_id => nil, :locale => 'en', :query => query_count.query,
                :is_grouped => is_grouped, :time_frame => time_frame, :times => query_count.times)
      end unless query_counts.is_a?(String)
    end
  end
end