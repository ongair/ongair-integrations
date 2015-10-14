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
end