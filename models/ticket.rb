require "active_record"

class Ticket < ActiveRecord::Base
	belongs_to :account
	belongs_to :user

	scope :zendesk, -> { where("source = ?", "Zendesk") }
	# scope :unsolved, -> {  where("status = ? or status = ? or status = ?", "open", "pending", "new") }
	scope :unsolved, -> {  where("status = ? or status = ? or status = ?", "1", "2", "3") }

	def self.unsolved_zendesk_tickets account, phone_number
		Ticket.zendesk.unsolved.where("account_id = ? and phone_number = ?", account.id, phone_number)
	end

	def self.status_map
		status_new = {1 => ["new", "nuevo", "novo", "nieuw"]}
		status_open = {2 => ["open", "abierto", "aberto", "offen"]}
		status_pending = {3 => ["pending", "pendiente", "in afwachting"]}
		status_solved = {4 => ["solved", "resuelto", "resolvido"]}
		status_closed = {5 => ["closed", "cerrado"]}
		status_dictionary = {status_new: status_new, status_open: status_open, status_pending: status_pending, status_solved: status_solved, status_closed: status_closed}
	end

	def self.get_status status
		status = status.downcase
		statuses = self.status_map
		statuses.values.each do |s|
			status = s.keys.first if s.values.first.include?(status)
		end
		status
	end

	def self.update_statuses
		tickets = Ticket.where.not('status = ? or status = ? or status = ? or status = ? or status = ?', '1', '2', '3', '4', '5')
		tickets.each do |ticket|
			status = Ticket.get_status(ticket.status) if !ticket.status.blank?
			ticket.update(status: status)
		end
	end
end