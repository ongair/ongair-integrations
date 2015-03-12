class WhatsApp
	def self.send_message account, phone_number, message
	  HTTParty.post("#{account.ongair_url}/api/v1/base/send?token=#{account.ongair_token}", body: {phone_number: phone_number, text: message, thread: true})
	end

	def self.send_location latitude, longitude, phone_number
	  location = Location.find_nearest latitude, longitude
	  HTTParty.post("#{location.account.ongair_url}/api/v1/base/send?token=#{location.account.ongair_token}", body: {phone_number: phone_number, text: location.address, thread: true})
	end
end