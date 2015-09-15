require_relative 'ongair.rb'
require 'rollbar'
require 'detect_language'
require 'newrelic_rpm'
require 'new_relic/rack/developer_mode'

Rollbar.configure do |config|
  config.access_token = Ongair.config.rollbar_access_token
  config.enabled = Ongair.config.rollbar_enabled == "YES"
  config.environment = Ongair.config.environment
end

DetectLanguage.configure do |config|
  config.api_key = Ongair.config.language_api_key
end

NewRelic::Agent.manual_start

use NewRelic::Rack::DeveloperMode
use Rack::Reloader, 0
run Ongair::API