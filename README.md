# Redis::Autosuggest

Provides autocompletions through Redis, with the ability to rank
  results and integrate with Rails

## Installation

Add this line to your application's Gemfile:

    gem 'redis-autosuggest'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install redis-autosuggest

## Usage

By default Autosuggest creates a new Redis client on db 0 at localhost:6379.

To change the server/port:
```ruby
r = Redis.new(:host => "my_host", :port => my_port)
Redis::Autosuggest.redis = r
```

To add items to be use for autocompletions:
```ruby
Redis::Autosuggest.add("North By Northwest", "Northern Exposure")
```

To check for autocompletions for an item:
```ruby
Redis::Autosuggest.suggest("nor")
# => ["north by northwest", "northern exposure"]
```
Autocompletions will be ordered their score value (descending).

Some other usage examples:
```ruby
# Add items with initial scores 
Redis::Autosuggest.suggest("North By Northwest", 9, Northern Exposure, 3)
# Increment an item's score
Redis::Autosuggest.suggest("North By Northwest", 1)
```

## Rails support

Autosuggest can also be integrated with Rails.  Include it in a model:
```ruby
class Movie < ActiveRecord::Base
  include Redis::Autosuggest
  
  autosuggest     :movie_title
end
```

For first time usage, seed the Redis db with the autosuggest sources:
```ruby
Redis::Autosuggest.init_rails_sources
```

You can optionally specify a numeric field to be used as the initial score for an item
when it is added:
```ruby
  autosuggest     :movie_title, :rank_by => imdb_rating
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
