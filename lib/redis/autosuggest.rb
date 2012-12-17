class Redis
  module Autosuggest

    class << self

      # Add item(s) to the pool of items to autosuggest from.  Each item's initial
      # rank is 0. Returns true if all items added were new, false otherwise.
      def add(*items)
        all_new_items = true
        items.each do |item|
          item = item.downcase
          item_exists?(item) ? all_new_items = false : add_item(item)
        end
        all_new_items
      end

      # Add item(s) along with their initial scores.
      # Returns true if all items added were new, false otherwise.
      # add_with_score("item1", 4, "item2", 1, "item3", 0)
      def add_with_score(*fields)
        all_new_items = true 
        fields.each_slice(2) do |f|
          f[0] = normalize(f[0])
          item_exists?(f[0]) ? all_new_items = false : add_item(*f)
        end
        all_new_items
      end

      # Remove an item from the pool of items to autosuggest from.
      # Returns true if an item was indeed removed, false otherwise.
      def remove(item)
        item = item.downcase
        id = get_id(item)
        return false if id.nil?
        @db.hdel(@items, id)
        @db.hdel(@itemids, item)
        remove_substrings(item, id)
        @redis.zrem(@leaderboard, id) if @use_leaderboard
        return true
      end

      # Increment the score (by 1 by default) of an item.  
      # Pass in a negative value to decrement the score.
      def increment(item, incr=1)
        item = normalize(item)
        id = get_id(item)
        each_substring(item) { |sub| @substrings.zincrby(sub, incr, id) }
        @db.zincrby(@leaderboard, incr, id) if @use_leaderboard
      end

      # Suggest items from the database that most closely match the queried string.
      # Returns an array of suggestion items (an empty array if nothing found).
      def suggest(str, results=@max_results)
        suggestion_ids = @substrings.zrevrange(normalize(str), 0, results - 1)
        suggestion_ids.empty? ? [] : @db.hmget(@items, suggestion_ids)
      end

      # Gets the items with the highest scores from the autosuggest db
      def get_leaderboard(results=@max_results)
        top_ids = @db.zrevrange(@leaderboard, 0, results - 1)
        top_ids.empty? ? [] : @db.hmget(@items, top_ids)  
      end

      # Get the score of an item
      def get_score(item)
        item = normalize(item)
        @substrings.zscore(item, get_id(item))
      end

      # Returns whether or not an item is already stored in the db
      def item_exists?(item)
        return !get_id(normalize(item)).nil?
      end

      private

      def normalize(item)
        return item.downcase.strip
      end

      def add_item(item, score=0)
        id = @db.hlen(@items)
        @db.hset(@items, id, item)
        @db.hset(@itemids, item, id)
        add_substrings(item, score, id)
        @db.zadd(@leaderboard, score, id) if @use_leaderboard
      end

      # Get the id associated with an item in the db
      def get_id(item)
        return @db.hmget(@itemids, item).first
      end

      # Yield each substring of a complete string 
      def each_substring(str)
        (0..str.length - 1).each { |i| yield str[0..i] }
      end

      # Add all substrings of a string to redis
      def add_substrings(str, score, id)
        each_substring(str) { |sub| @substrings.zadd(sub, score, id) }
      end

      # Remove all substrings of a string from the db
      def remove_substrings(str, id)
        each_substring(str) { |sub| @substrings.zrem(sub, id) }
      end
    end
  end
end
