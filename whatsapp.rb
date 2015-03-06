class WhatsApp
	def self.send_message account, phone_number, message
	  HTTParty.post("#{account.ongair_url}/api/v1/base/send?token=#{account.ongair_token}", body: {phone_number: phone_number, text: message, thread: true})
	end
end