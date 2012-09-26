class Redis
  module Autosuggest
    extend ActiveSupport::Concern

    module ClassMethods

      def autosuggest(column, options={})
        hash = Redis::Autosuggest.rails_sources[self]
        if hash.nil?
          Redis::Autosuggest.rails_sources[self] = { column => options }
        else
          hash[column] = options
        end

        # hook onto rails callbacks to update autosuggest db if a source is modified
        class_eval <<-HERE
          after_create :add_to_autosuggest
          def add_to_autosuggest
            Redis::Autosuggest.rails_sources[self.class].each do |column, options|
              score = self.send(options[:rank_by]) if !options[:rank_by].nil?
              score ||= 0
              Redis::Autosuggest.add_with_score(self.send(column), score)
            end
          end

          after_update :check_if_changed
          def check_if_changed
            Redis::Autosuggest.rails_sources[self.class].each_key do |column|
              next if !self.send("#{column}_changed?")
              old_item = self.send("#{column}_was")
              score = Redis::Autosuggest.get_score(old_item)
              Redis::Autosuggest.remove(old_item)
              Redis::Autosuggest.add_with_score(self.send(column), score)
            end
          end

          before_destroy :remove_from_autosuggest
          def remove_from_autosuggest
            Redis::Autosuggest.rails_sources[self.class].each_key do |column|
              Redis::Autosuggest.remove(self.send(column))
            end
          end
          HERE
        end 
      end
    end
  end


