class Redis
  module Autosuggest

    class << self

      # Add item(s) to the pool of items to autosuggest from.  Each item's initial
      # rank is 0. Returns true if all items added were new, false otherwise.
      def add(*items)
        all_new_items = true
        items.each do |item|
          if item.size > @max_str_size
            all_new_items = false
            next
          end
          item = normalize(item)
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
          if f[0].size > @max_str_size
            all_new_items = false
            next
          end
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
        remove_fuzzy(item) if @fuzzy_match
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
      # Fuzzy matching will only occur when both of these conditions are met:
      #   - Redis::Autosuggest.fuzzy_match == true
      #   - The simple suggestion method (matching substrings) yields no results
      def suggest(str, results=@max_results)
        str = normalize(str)
        suggestion_ids = @substrings.zrevrange(str, 0, results - 1)
        if suggestion_ids.empty? && @fuzzy_match 
          return suggest_fuzzy(str, results)
        end
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

      # Get the id associated with an item in the db
      def get_id(item)
        return @db.hmget(@itemids, normalize(item)).first
      end

      def get_item(id)
        return @db.hmget(@items, id).first
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
        add_fuzzy(item) if @fuzzy_match
      end

      # Yield each substring of a complete string 
      def each_substring(str)
        (0..str.length - 1).each { |i| yield str[0..i] }
      end

      # Add all substrings of a string to redis
      def add_substrings(str, score, id)
        each_substring(str) do |sub| 
          if @max_per_substring == Float::INFINITY
            add_substring(sub, score, id)
          else
            add_substring_limit(sub, score, id)
          end
        end
      end

      # Add the id of an item to a substring
      def add_substring(sub, score, id)
        @substrings.zadd(sub, score, id)
      end

      # Add the id of an item to a substring only when the number of items that
      # substring stores is less then the config value of "max_per_substring".
      # If the substring set is already full, check to see if the item with the
      # lowest score in the substring set has a lower score than the item being added.
      # If yes, remove that item and add this item to the substring set.
      def add_substring_limit(sub, score, id)
        count = @substrings.zcount(sub, "-inf", "+inf")
        if count < @max_per_substring
          add_substring(sub, score, id)
        else
          lowest_item = @substrings.zrevrange(sub, -1, -1, { withscores: true }).last
          if score > lowest_item[1]
            @substrings.zrem(sub, lowest_item[0])
            add_substring(sub, score, id)
          end
        end
      end

      # Remove all substrings of a string from the db
      def remove_substrings(str, id)
        each_substring(str) { |sub| @substrings.zrem(sub, id) }
      end
    end
  end
end
