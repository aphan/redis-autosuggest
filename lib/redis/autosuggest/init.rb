class Redis
  module Autosuggest

    class << self

      def init_rails_sources
        self.rails_sources.each_key do |r|
          r.all.each do |record|
            record.add_to_autosuggest
          end
        end
      end
    end
  end
end


