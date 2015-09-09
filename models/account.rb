require "active_record"
class Account < ActiveRecord::Base
	belongs_to :client
	
	has_many :tickets
	has_many :users
end