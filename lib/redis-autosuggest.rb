require 'redis'
require 'redis-namespace'
require 'redis/autosuggest'
require 'redis/autosuggest/config'
require 'redis/autosuggest/file'
require 'redis/autosuggest/version'

if defined?(Rails)
  require 'redis/autosuggest/rails/sources'
  require 'redis/autosuggest/rails/railtie'
end
