require "active_record"
class Location < ActiveRecord::Base
	belongs_to :account
	geocoded_by :address
	after_validation :geocode, :if => :address_changed?

	def self.find_nearest lat, long
		 Location.near([lat, long], 20, :units => :km).first
	end
end