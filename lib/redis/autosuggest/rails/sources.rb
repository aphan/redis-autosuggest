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

        # Hook onto rails callbacks to update autosuggest db if a source is modified
        class_eval <<-HERE
          after_create :add_to_autosuggest
          def add_to_autosuggest
            Redis::Autosuggest::SuggestRails.add_to_autosuggest(self)
          end

          after_update :check_if_changed
          def check_if_changed
            Redis::Autosuggest::SuggestRails.check_if_changed(self)
          end

          before_destroy :remove_from_autosuggest
          def remove_from_autosuggest
            Redis::Autosuggest::SuggestRails.remove_from_autosuggest(self)
          end
          HERE
        end
      end

      module SuggestRails
        class << self

          def init_rails_sources
            ::Rails.application.eager_load!
            # Redis::Autosuggest.db.flushdb
            Redis::Autosuggest.rails_sources.each do |model, attrs|
              attrs.each do |column, options|
                order = options[:init_order] || ""
                model.order(order).find_each do |record|
                  puts "Adding #{record.send(column)}"
                  size = self.add_source_attr(record, column, options)
                  break if size >= options[:limit]
                end
              end
            end
          end

          def add_to_autosuggest(record)
            Redis::Autosuggest.rails_sources[record.class].each do |column, options|
              self.add_source_attr(record, column, options)
            end
          end

          def add_source_attr(record, column, options)
            item = record.send(column)
            size = self.get_size(record.class, column).to_i
            if size < options[:limit]
              score = record.send(options[:rank_by]) unless options[:rank_by].nil?
              score ||= 0
              is_new_item = Redis::Autosuggest.add_with_score(item, score)
              size = self.incr_size(record.class, column) if is_new_item
            end
            return size
          end

          def check_if_changed(record)
            Redis::Autosuggest.rails_sources[record.class].each_key do |column|
              next unless record.send("#{column}_changed?")
              old_item = record.send("#{column}_was")
              score = Redis::Autosuggest.get_score(old_item)
              Redis::Autosuggest.remove(old_item)
              Redis::Autosuggest.add_with_score(record.send(column), score)
            end
          end

          def remove_from_autosuggest(record)
            Redis::Autosuggest.rails_sources[record.class].each_key do |column|
              item = record.send(column)
              item_was_in_db = Redis::Autosuggest.remove(item)
              self.incr_size(record.class, column, -1) if item_was_in_db
            end
          end

          # Get the size (how many items) of a model/attribute pair
          def get_size(model, attr)
            Redis::Autosuggest.rails_source_sizes.get("#{model}:#{attr}")
          end

          # Increment the key storing the size of a model/attribute pair
          def incr_size(model, attr, incr=1)
            return Redis::Autosuggest.rails_source_sizes.incrby("#{model}:#{attr}", incr)
          end
        end
      end
    end
  end
