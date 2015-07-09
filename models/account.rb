require "active_record"
class Account < ActiveRecord::Base
	has_many :tickets
	has_many :users
end