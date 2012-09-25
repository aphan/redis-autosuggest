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
    end
  end
end
