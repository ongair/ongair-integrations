require "active_record"
class BusinessHour < ActiveRecord::Base
	belongs_to :account	
end