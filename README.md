# Redis::Autosuggest

Provides autocompletions through Redis, with the ability to rank
  results and integrate with Rails

## Installation

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
Redis::Autosuggest.add_with_score("North By Northwest", 9, Northern Exposure, 3)
# Increment an item's score
Redis::Autosuggest.increment("North By Northwest", 1)
```

## Rails support

Autosuggest can also be integrated with Rails.  Include it in a model:
```ruby
class Movie < ActiveRecord::Base
  include Redis::Autosuggest
  
  attr_accessible :movie_title
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
  autosuggest :movie_title, :rank_by => imdb_rating
```

## Front-end portion
Jquery plugin for dropdown autocompletions for a from can be found [here](https://github.com/aphan/jquery-rtsuggest)
