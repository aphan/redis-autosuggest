class Redis
  module Autosuggest

    class << self

      # Add items to the autosuggest database from a file.
      # Each line be a string representing the item
      def add_from_file(file)
        File.open(file, "r").each do |l| 
          puts "Adding #{l}"
          add(l.strip)
        end
      end
      
      # Add items and their to the autosuggest database from a file.
      # Each line be a string representing the item followed by its score
      # Example:
      # item1 0.4
      # item2 2.1
      # item3 5.2
      def add_with_score_from_file(file)
        add_with_score(*(File.open(file, "r").map { |l| l.split(" ")}.flatten))
      end
    end
  end
end
