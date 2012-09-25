class Redis
  module Autosuggest

    class Config
      # Default Redis server at localhost:6379
      @redis = Redis.new
      # Key for hash that maps ids to words we want to use for autosuggest responses
      @words = "autosuggest:words"
      # If we want to autosuggest for partial matchings of the word: 'ruby', we would
      # have four sorted sets: 'autosuggest:partials:r', 'autosuggest:partials:ru',
      # 'autosuggest:partials:rub', and 'autosuggest:partials:ruby'.
      # Each sorted set would the id to the word 'ruby'
      @partials = "autosuggest:partials:"
      # max number of ids to store per partial word.  No limit by default
      @max_per_partial = FLOAT::INFINITY
      # max number of results to return for an autosuggest query
      @max_results = 5 
      # Key to a sorted set holding all ids words in the autosuggest database sorted 
      # by their score
      @leaderboard = "autosuggest:leaderboard"
      # Leaderboard off by default
      @use_leaderboard = false

      class << self
        attr_accessor :redis, :words, :partials, :max_per_partial, :max_results,
          :leaderboard, :use_leaderboard
      end
    end
  end
end

