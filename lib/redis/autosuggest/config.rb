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
    @substrings =  Redis::Namespace.new("#{@namespace}:su", :redis => @redis)

    # max number of ids to store per substring.
    @max_per_substring = Float::INFINITY

    # max number of results to return for an autosuggest query
    @max_results = 5

    # max string size for an item
    @max_str_size = Float::INFINITY

    # Key to a sorted set holding all id of items in the autosuggest database sorted 
    # by their score
    @leaderboard = "lead"

    # Leaderboard on by default
    @use_leaderboard = false

    # Sources to be used for Autocomplete in rails.
    # Example: { Movie => :movie_title }
    @rails_sources = {}

    # Stores the number of items the db has for each rails source
    @rails_source_sizes = Redis::Namespace.new("#{@namespace}:size", :redis => @redis)

    # Fuzzy matching
    @ngrams = Redis::Namespace.new("#{@namespace}:ng", :redis => @redis)

    # Whether or not to use fuzzy matching for autocompletions
    @fuzzy_match = false

    # The size of n-grams stored (fuzzy matching)
    @ngram_size = 3

    # Maximum number of items to be indexed per n-gram (fuzzy matching)
    @ngram_item_limit = 200
    
    # If this is set to true, returned suggestions for fuzzy matching will only
    # return suggestions that it has a very high confidence of in being correct.
    @strict_fuzzy_matching = false

    class << self
      attr_reader :redis, :namespace
      attr_accessor :db, :items, :itemids, :substrings, :max_per_substring,
        :max_results, :max_str_size, :leaderboard, :use_leaderboard, :rails_sources,
        :rails_source_sizes, :ngrams, :fuzzy_match, :ngram_size, :ngram_item_limit,
        :strict_fuzzy_matching

      def redis=(redis)
        @redis = redis
        set_namespaces()
      end

      def namespace=(namespace)
        @namespace = namespace
        set_namespaces()
      end

      private

      def set_namespaces
        @db = Redis::Namespace.new(@namespace, :redis => @redis)
        @substrings =  Redis::Namespace.new("#{@namespace}:sub", :redis => @redis)
        @rails_source_sizes = Redis::Namespace.new("#{@namespace}:size", :redis => @redis)
        @ngrams = Redis::Namespace.new("#{@namespace}:ng", :redis => @redis)
      end
    end
  end
end
