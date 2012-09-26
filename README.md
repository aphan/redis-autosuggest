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

    r = Redis.new(:host => "my_host", :port => my_port)

    Redis::Autosuggest.redis = r

To add an item to be use for autocompletions:

    Redis::Autosuggest.add("North By Northwest", "Northern Exposure")

To check for autocompletions for this item:

    Redis::Autosuggest.suggest("nor")

    # => ["north by northwest", "northern exposure"]

To remove an item:

    Redis::Autosuggest.remove("Northern Exposure")

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
