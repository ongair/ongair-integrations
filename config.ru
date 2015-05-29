require_relative 'ongair.rb'
require 'rollbar'

Rollbar.configure do |config|
  config.access_token = Ongair.config.rollbar_access_token
end

use Rack::Reloader, 0
run Ongair::API