require "active_record"

class Ticket < ActiveRecord::Base
	belongs_to :account
	belongs_to :user

	scope :zendesk, -> { where("source = ?", "Zendesk") }

	scope :unsolved, -> {  where("status = ? or status = ? or status = ? or status = ?", "1", "2", "3", "6") }
	scope :not_closed, -> {  where("status = ? or status = ? or status = ? or status = ? or status = ?", "1", "2", "3", "4", "6") }

	STATUS_NEW = '1'
	STATUS_OPEN = '2'
	STATUS_PENDING = '3'
	STATUS_SOLVED = '4'
	STATUS_CLOSED = '5'
	STATUS_ON_HOLD = '6'

	def can_be_commented?
		status == STATUS_NEW || status == STATUS_OPEN	 || status == STATUS_PENDING
	end

	def self.unsolved_zendesk_tickets account, phone_number
		if account.ticket_end_status == "4"
			Ticket.zendesk.unsolved.where("account_id = ? and phone_number = ?", account.id, phone_number)
		else
			Ticket.zendesk.not_closed.where("account_id = ? and phone_number = ?", account.id, phone_number)
		end
	end

	def self.status_map
		status_new = {STATUS_NEW => ["new", "nuevo", "novo", "nieuw", "neu"]}
		status_open = {STATUS_OPEN => ["open", "abierto", "aberto", "offen"]}
		status_pending = {STATUS_PENDING => ["pending", "pendiente", "in afwachting", "pendente", "wartend"]}
		status_on_hold = {STATUS_ON_HOLD => ["on-hold", "angehalten"]}
		status_solved = {STATUS_SOLVED => ["solved", "resuelto", "resolvido", "opgelost", "gelöst"]}
		status_closed = {STATUS_CLOSED => ["closed", "cerrado", "geschlossen"]}
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