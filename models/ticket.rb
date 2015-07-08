require "active_record"

class Ticket < ActiveRecord::Base
	belongs_to :account
	belongs_to :user

	scope :zendesk, -> { where("source = ?", "Zendesk") }
	scope :unsolved, -> {  where("status = ? or status = ? or status = ?", "open", "pending", "new") }

	def self.unsolved_zendesk_tickets account, phone_number
		Ticket.zendesk.unsolved.where("account_id = ? and phone_number = ?", account.id, phone_number)
	end

	def self.status_map
		status_new = {1 => ["new", "nuevo", "novo"]}
		status_open = {2 => ["open", "abierto", "aberto", "offen"]}
		status_pending = {3 => ["pending", "pendiente"]}
		status_solved = {4 => ["solved", "resuelto"]}
		status_dictionary = {status_new: status_new, status_open: status_open, status_pending: status_pending, status_solved: status_solved}
	end

	def self.get_status status
		status = status.downcase
		statuses = self.status_map
		statuses.values.each do |s|
			status = s.keys.first if s.values.first.include?(status)
		end
		status
	end
end