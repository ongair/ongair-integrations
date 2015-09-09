require "active_record"
class Client < ActiveRecord::Base
	has_many :accounts
end