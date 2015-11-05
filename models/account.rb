require "active_record"
require "timezone"
class Account < ActiveRecord::Base
	belongs_to :client
	
	has_many :tickets
	has_many :users
	has_many :responses
	has_many :business_hours

	def set_business_hours days
		# [ {day: "Monday", from: "08", to: "17", work_day: true}, {day: "Tuesday", from: "09", to: "18", work_day: true} ]
		days.each do |day|
			bh = BusinessHour.find_or_create_by! day: day[:day], account_id: id
			bh.update(from: day[:from], to: day[:to])
		end
	end

	def set_responses in_business_message, not_in_business_message
		response = Response.find_or_create_by! account_id: id
		response.update in_business_hours: in_business_message, not_in_business_hours: not_in_business_message
	end

	def time
		if !timezone.blank?
			begin
				tz = Timezone::Zone.new(zone: timezone) 
				time = tz.time(Time.now)
			rescue Timezone::Error::InvalidZone => e
				time = Time.now
			end
		else
			time = Time.now
		end
		time
	end

	def day
		today = time.strftime('%A')
		business_hours.where(day: today).first
	end

	def today_is_work_day?
		if !day.nil?
			is_work_day = day.work_day
		else
			is_work_day = false
		end
		is_work_day
	end

	def in_business?
		business = true
		if today_is_work_day?
			business = time.hour.between?(day.from.to_i, day.to.to_i)
		end
		business
	end

	def response
		msg = zendesk_ticket_auto_responder
		if msg.blank?
			if !responses.blank?
				if in_business?
					msg = responses.first.in_business_hours
				else
					msg = responses.first.not_in_business_hours
				end
			end
		end
		msg
	end

	def is_number?(object)
	  true if Float(object) rescue false
	end

	def get_tickets
		tickets = []
		client = Zendesk.client(self)
		client.tickets.each do |t|
		  tags = t.tags  
		  tags.each do |tag|  
		    if tag.id == 'ongair'    
		      phone_number = tags.select{|tg| is_number?(tg.id)}.first.id
		      tickets << {ticket_id: t.id, phone_number: phone_number, status: Ticket.get_status(t.status), requester: t.requester_id}
		    end  
		  end  
		end  
		tickets
	end

	def import_zendesk_tickets
		tickets = get_tickets
		tickets.each do |ticket|
			user = User.find_or_create_by account: self, phone_number: ticket[:phone_number], zendesk_id: ticket[:requester]
			Ticket.find_or_create_by account: self, phone_number: ticket[:phone_number], ticket_id: ticket[:ticket_id], status: ticket[:status], user: user, source: "Zendesk"
		end
	end

	def update_details options
		# options = { account: {ongair_phone_number: "254722777888", zat: "etwet2t", ot: "dsgg"}, integrations_url: "http://integrations.ongair.im" }
		phone = options[:account][:ongair_phone_number]
		new_url = options[:integrations_url]
		old_url = "http://77f3f2cd.ngrok.io" # "http://41.242.1.46"
		client = Zendesk.client(self)
		targets = client.targets.select{|t| t.title.start_with?("Ongair") and t.active}

		targets.each do |tar|
			url = tar.target_url
			if !phone.blank? && phone != ongair_phone_number
				url = url.gsub!(ongair_phone_number, phone)
				puts ">>>> 1"
			elsif !new_url.blank?
				url = url.gsub!(old_url, new_url)
				puts ">>>> 2"
			end
			puts ">>>>>> URL: #{url}"
			tar.target_url = url
			puts ">>>>>> Target URL: #{tar.target_url}"
			tar.save!
		end
		
		update(options[:account])
	end
end