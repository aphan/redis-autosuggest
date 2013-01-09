class Redis
  module Autosuggest

    class << self 

      # Add an item's n-grams to the redis db. The n-grams will be used
      # as candidates for autocompletions when Redis::Autosuggest.fuzzy_match
      # is set to true.
      def add_fuzzy(item)
        yield_ngrams(item) do |ngram|
          if @ngrams.scard(ngram).to_i <= @ngram_item_limit
            @ngrams.sadd(ngram, "#{item}:#{compute_soundex_code(item)}")
          end
        end
      end

      # Remove an item's n-grams from the Redis db
      def remove_fuzzy(item)
        yield_ngrams(item) do |ngram| 
          @ngrams.srem(ngram, "#{item}:#{compute_soundex_code(item)}")
        end
      end

      # Compute the soundex code of a string (only works for single words
      # so we have to merge multi-word strings)
      def compute_soundex_code(str)
        return Text::Soundex.soundex(alphabet_only(str))
      end

      # Build a candidate pool for all suitable fuzzy matches for a string
      # by taking the union of all items in the Redis db that share an n-gram
      # with the string. Use levenshtein distance, soundex code similarity,
      # and the number of matching 2-grams to compute a score for each candidate.
      # Then return the highest-scoring candidates.
      def suggest_fuzzy(str, results=@max_results, strict=@strict_fuzzy_matching)
        str_mul = alphabet_only(str).size
        str_soundex_code = compute_soundex_code(str)
        str_2grams = ngram_list(str, 2)
        candidates = []

        @ngrams.sunion(*ngram_list(str)).each do |candidate|
          candidate = candidate.split(":")
          candidate_str = candidate[0]
          candidate_soundex_code = candidate[1]
          candidate_score = 1.0

          # Levenshtein distance
          lev_dist = Levenshtein.distance(str, candidate_str)
          candidate_score *= Math.exp([str_mul - lev_dist, 1].max)

          # Soundex
          if str_soundex_code == candidate_soundex_code
            candidate_score *= str_mul
          elsif str_soundex_code[1..-1] == candidate_soundex_code[1..-1]
            candidate_score *= (str_mul / 2).ceil
          end

          # Compute n-grams of size 2 shared between the two strings
          same_2grams = str_2grams & ngram_list(candidate_str, 2)
          candidate_score *= Math.exp(same_2grams.size)

          if candidate_score > 1
            candidates << {
              str: candidate_str,
              score: candidate_score
            }
          end
        end
        # Sort results by score and return the highest scoring candidates
        candidates = candidates.sort { |a, b| b[:score] <=> a[:score] }
        # puts candidates.take(10).map { |cand| "#{cand[:str]} => #{cand[:score]}" }
        # If strict fuzzy matching is used, only suggestion items with scores
        # above a certain threshold will be returned.
        if strict
          suggestions = []
          candidates.each do |cand|
            # threshold ||= candidates[0][:score] / 10
            threshold = Math.exp(str.size)
            break if suggestions.size > results || cand[:score] < threshold
            suggestions << cand
          end
        else
          suggestions = candidates.take(results)
        end
        return suggestions.map { |cand| cand[:str] }
      end

      # Yield the n-grams of a specified size for a string one at a time
      def yield_ngrams(str, ngram_size=@ngram_size)
        ngram_list = ngram_list(str, ngram_size)
        ngram_list.each { |ngram| yield ngram }
      end

      # Returns a list containing all of the n-grams of a specified size
      # of a string.  The list is ordered by the position of the n-gram
      # in the string (duplicates included).
      def ngram_list(str, ngram_size=@ngram_size)
        str = alphabet_only(str).split("")
        ngram_list = []
        (0..str.size - ngram_size).each do |i|
          ngram = ""
          (0...ngram_size).each { |j| ngram << str[i + j] }
          ngram_list << ngram
        end
        ngram_list
      end

      # Remove all characters not in the range 'a-z' from a string
      def alphabet_only(str)
        return str.gsub(/[^abcdefghijklmnopqrstuvwxyz]/, '')
      end
    end
  end
end
