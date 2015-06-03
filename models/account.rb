require "active_record"
class Account < ActiveRecord::Base
	has_many :tickets
end