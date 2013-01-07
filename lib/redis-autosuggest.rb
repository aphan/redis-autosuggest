require 'redis'
require 'redis-namespace'
require 'levenshtein'
require 'text'
require 'redis/autosuggest'
require 'redis/autosuggest/config'
require 'redis/autosuggest/file'
require 'redis/autosuggest/version'
require 'redis/autosuggest/fuzzy'

if defined?(Rails)
  require 'redis/autosuggest/rails/sources'
  require 'redis/autosuggest/rails/railtie'
end
