class WhatsApp
	def self.send_message account, phone_number, message
	  HTTParty.post("#{account.ongair_url}/api/v1/base/send?token=#{account.ongair_token}", body: {phone_number: phone_number, text: message, thread: true})
	end

	def self.send_location
	  branch = Location.find_nearest params[:latitude], params[:longitude]
	  HTTParty.post("http://app.ongair.im/api/v1/base/send?token=#{ENV['ONGAIR_API_KEY']}", body: {phone_number: params[:phone_number], text: branch.address, thread: true})
	  render json: {success: true}
	end
end