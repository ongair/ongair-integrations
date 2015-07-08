require 'airborne'
require 'webmock/rspec'
require 'simplecov'
require 'pry'

# coverage start
SimpleCov.start do
  add_filter '/spec'
end

require_relative '../ongair.rb'

Airborne.configure do |config|
  config.rack_app = Ongair::API
end

# disable web connect
WebMock.disable_net_connect!