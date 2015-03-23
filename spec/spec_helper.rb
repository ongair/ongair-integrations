require 'airborne'
require 'webmock/rspec'
require_relative '../ongair.rb'

Airborne.configure do |config|
  config.rack_app = Ongair::API
end

# disable web connect
WebMock.disable_net_connect!

# fixture_path = "fixtures/"
# use_transactional_fixtures = true
# global_fixtures = :all