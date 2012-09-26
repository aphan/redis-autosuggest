class Redis
  module Autosuggest

    # Default Redis server at localhost:6379
    @redis = Redis.new

    @db = Redis::Namespace.new("autosuggest", :redis => @redis)

    # Key for a Redis hash mapping ids to items we want to use for autosuggest responses
    @items = "items"

    # If we want to autosuggest for partial matchings of the word: 'ruby', we would
    # have four sorted sets: 'autosuggest:substring:r', 'autosuggest:substring:ru',
    # 'autosuggest:substring:rub', and 'autosuggest:substring:ruby'.
    # Each sorted set would the id to the word 'ruby'
    @substrings =  Redis::Namespace.new("autosuggest:substring", :redis => @redis)

    # max number of ids to store per substring.
    @max_per_substring = Float::INFINITY

    # max number of results to return for an autosuggest query
    @max_results = 5 

    # Key to a sorted set holding all id of items in the autosuggest database sorted 
    # by their score
    @leaderboard = "leaderboard"

    # Leaderboard off by default
    @use_leaderboard = false

    class << self
      attr_reader :redis
      attr_accessor :db, :items, :substrings, :max_per_substring, :max_results,
        :leaderboard, :use_leaderboard

      def redis=(redis)
        @redis = redis
        @db = Redis::Namespace.new("autosuggest", :redis => redis)
        @substrings =  Redis::Namespace.new("autosuggest:substring", :redis => redis)
      end
    end
  end
end

