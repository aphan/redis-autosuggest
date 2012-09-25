class Redis
  module Autosuggest

    class << self

      # Add an item to the pool of items to autosuggest from
      def add_item(item, score=0)
        item = item.downcase
        unless Config.db.hgetall(Config.items).has_value?(item)
          id = Config.db.hlen(Config.items)
          Config.db.hset(Config.items, id, item)
          add_substrings(item, score, id)
          Config.db.zadd(Config.leaderboard, score, id) if Config.use_leaderboard
        end
      end

      # Remove an item from the pool of items to autosuggest from
      def remove_item(item)
        item = item.downcase
        id = get_id(item)
        return if id.nil?
        Config.db.hdel(Config.items, id)
        remove_substrings(item, id)
        Config.redis.zrem(Config.leaderboard, id) if Config.use_leaderboard
      end
      
      # Increment the score (by 1 by default) of an item.  Pass in a negative value
      # to decrement the score
      def increment(item, inc=1)
        item = item.downcase
        id = get_id(item)
        each_substring(item) { |sub| Config.substrings.zincrby(sub, inc, id) }
        Config.db.zincrby(Config.leaderboard, inc, id) if Config.use_leaderboard
      end

      private
      # Yield each substring of a complete string 
      def each_substring(str)
        str.each_char.each_with_object("") do |char, total|
          yield total << char
        end
      end

      # Add all substrings of a string to redis
      def add_substrings(str, score, id)
        each_substring(str) do |sub|
          Config.substrings.zadd(sub, score, id)
        end
      end

      # Remove all substrings of a string from the db
      def remove_substrings(str, id)
        each_substring(str) do |sub|
          Config.substrings.zrem(sub, id)
        end
      end

      # Get the id associated with an item in the db 
      def get_id(item)
        kv_pair = Config.db.hgetall(Config.items).find { |_, v| v == item}
        kv_pair.first unless kv_pair.nil?
      end
    end
  end
end
