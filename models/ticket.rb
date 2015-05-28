require "active_record"

class Ticket < ActiveRecord::Base
	belongs_to :account
	belongs_to :user

	scope :zendesk, -> { where("source = ?", "Zendesk") }
	scope :unsolved, -> {  where("status = ? or status = ? or status = ?", "open", "pending", "new") }

	def self.unsolved_zendesk_tickets account, phone_number
		# 
		Ticket.zendesk.unsolved.where("account_id = ? and phone_number = ?", account.id, phone_number)
	end
end