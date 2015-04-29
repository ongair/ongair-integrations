class WhatsApp
	def self.send_message account, phone_number, message
	  HTTParty.post("#{account.ongair_url}/api/v1/base/send?token=#{account.ongair_token}", body: {phone_number: phone_number, text: message, thread: true})
	end

	def self.send_image account, phone_number, image_url
		HTTParty.post("#{account.ongair_url}/api/v1/base/send_image", body: { token: account.ongair_token,  phone_number: phone_number, image: image_url, thread: true })
	end

	def self.send_location latitude, longitude, phone_number
	  location = Location.find_nearest latitude, longitude
	  HTTParty.post("#{location.account.ongair_url}/api/v1/base/send?token=#{location.account.ongair_token}", body: {phone_number: phone_number, text: location.address, thread: true})
	end

	def self.personalize_message message, ticket_id, name
		message.gsub("{{ticket_id}}", ticket_id.to_s).gsub("{{user_name}}", name)
	end
end