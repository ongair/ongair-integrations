require_relative 'ongair.rb'
require 'airborne'

Airborne.configure do |config|
  config.rack_app = Ongair::API
end
use Rack::Reloader, 0
run Ongair::API