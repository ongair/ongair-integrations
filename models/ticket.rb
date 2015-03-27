require "active_record"

class Ticket < ActiveRecord::Base
	belongs_to :account

	def self.unsolved_zendesk_tickets account, phone_number
		Ticket.where("account_id = ? and phone_number = ? and source = ? and status = ? or status = ? or status = ?", account.id, phone_number, "Zendesk", "open", "pending", "new")
	end
end