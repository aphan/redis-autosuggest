class Redis
  module Autosuggest

    class << self
      
      # Add 
      def add_from_file(file)
        add(*(File.open(file, "r").map { |l| l.strip }))
      end

      def add_with_score_from_file(file)
        add_with_score(*(File.open(file, "r").map { |l| l.split(" ")}.flatten))
      end
    end
  end
end
