require "active_record"

class User < ActiveRecord::Base
	has_many :tickets
	belongs_to :account

	def self.create_user_for_each_account
		Ticket.all.each do |ticket|
			account = ticket.account
			zt = Zendesk.find_ticket(account, ticket.ticket_id)
			user = User.find_or_create_by! phone_number: ticket.phone_number, account: account
			user.update zendesk_id: zt.comments.first.author_id if !zt.nil?
			ticket.update user: user
		end
	end
end