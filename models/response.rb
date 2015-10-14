require "active_record"
class Response < ActiveRecord::Base
	belongs_to :account
end