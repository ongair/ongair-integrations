require 'airborne'
require_relative '../ongair.rb'

Airborne.configure do |config|
  config.rack_app = Ongair::API
end

# disable web connect
