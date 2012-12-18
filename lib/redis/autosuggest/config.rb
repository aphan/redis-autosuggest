class Redis
  module Autosuggest

    # Default Redis server at localhost:6379
    @redis = Redis.new
    
    # Main Redis namespace for this module
    @namespace = "suggest"

    @db = Redis::Namespace.new(@namespace, :redis => @redis)

    # Key for a Redis hash mapping ids to items we want to use for autosuggest responses
    @items = "items"

    # Key to a Redis hash mapping items to their respective ids
    @itemids = "itemids"

    # If we want to autosuggest for partial matchings of the word: 'ruby', we would
    # have four sorted sets: 'autosuggest:substring:r', 'autosuggest:substring:ru',
    # 'autosuggest:substring:rub', and 'autosuggest:substring:ruby'.
    # Each sorted set would the id to the word 'ruby'
    @substrings =  Redis::Namespace.new("#{@namespace}:sub", :redis => @redis)

    # max number of ids to store per substring.
    @max_per_substring = Float::INFINITY

    # max number of results to return for an autosuggest query
    @max_results = 5

    # Key to a sorted set holding all id of items in the autosuggest database sorted 
    # by their score
    @leaderboard = "lead"

    # Leaderboard on by default
    @use_leaderboard = true

    # Sources to be used for Autocomplete in rails.
    # Example: { Movie => :movie_title }
    @rails_sources = {}

    # Stores the number of items the db has for each rails source
    @rails_source_sizes = Redis::Namespace.new("#{@namespace}:size", :redis => @redis)

    class << self
      attr_reader :redis
      attr_accessor :namespace, :db, :items, :substrings, :max_per_substring, :max_results,
        :leaderboard, :use_leaderboard, :rails_sources, :rails_source_sizes

      def redis=(redis)
        @redis = redis
        @db = Redis::Namespace.new(@namespace, :redis => redis)
        @substrings =  Redis::Namespace.new("#{@namespace}:sub", :redis => redis)
        @rails_source_sizes = Redis::Namespace.new("#{@namespace}:size", :redis => redis)
      end
    end
  end
end
