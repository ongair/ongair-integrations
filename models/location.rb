require "active_record"
require "geocoder"
class Location < ActiveRecord::Base
	extend ::Geocoder::Model::ActiveRecord
	belongs_to :account
	geocoded_by :address
	after_validation :geocode, :if => :address_changed?

	def self.find_nearest lat, long
		 Location.near([lat, long], 20, :units => :km).first
	end
end