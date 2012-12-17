require "redis-autosuggest"

namespace :autosuggest do
  
  desc "redis autosuggestions init"
  task :init => :environment do
    Redis::Autosuggest::SuggestRails.init_rails_sources
  end
end
