require "active_record"
class Survey < ActiveRecord::Base
	belongs_to :user
	belongs_to :ticket
	belongs_to :account
end