require 'httparty'
class Freshdesk
	def self.post body, url, account
		auth = {
			username: account.freshdesk_token,
			password: "password"
		}

		response = HTTParty.post(url, {
			body: body,
			basic_auth: auth,
			headers: { "Content-type" => "application/x-www-form-urlencoded" },
			debug_output: $stdout
		})		
	end

	def self.post_multiparty body, url, account
		auth = {
			username: account.freshdesk_token,
			password: "password"
		}

		response = HTTMultiParty.post(url, {
			body: body,
			basic_auth: auth,
			headers: { "Content-type" => "application/x-www-form-urlencoded" },
			debug_output: $stdout
		})
	end

	def self.get url, account
		auth = {
			username: account.freshdesk_token,
			password: "password"
		}
		HTTParty.get(url, {basic_auth: auth})
	end

	def self.create_survey ticket_id, account, rating="", feedback=""
		post({feedback: feedback}, "#{account.freshdesk_url}/helpdesk/tickets/#{ticket_id}/surveys/rate.json?rating=#{rating}", account)
	end

	def self.random_string
	  cs = [*'0'..'9', *'a'..'z']
	  5.times.map { cs.sample }.join.downcase
	end

	def self.strip_html(str)
	  document = Nokogiri::HTML.parse(str)
	  document.css("br").each { |node| node.replace("\n") }
	  document.text
	end

	def self.create_freshdesk_ticket description, subject, email, account, user, tags=[]
		body = {
		  helpdesk_ticket: {
	      description: description,
	      subject: subject,
	      email: email,
	      priority: 1,
	      status: 1
		  }
		}
		tags_query = tags.blank? ? "" : "?helpdesk[tags]=#{tags.join(",")}"
		ticket = post(body, "#{account.freshdesk_url}/helpdesk/tickets.json#{tags_query}", account)
		ticket_id = ticket['helpdesk_ticket']['display_id']
		Ticket.create! phone_number: user.phone_number, user: user, ticket_id: ticket_id, status: ticket['helpdesk_ticket']['status'], account: account, source: "Freshdesk"
		WhatsApp.send_message(account, user.phone_number, "Hi #{user.name},\nThanks for getting in touch with us. Your reference ID is ##{ticket_id}. We will get back to you shortly.")
		{ message: "New ticket created", ticket: ticket }
	end

	def self.find_ticket id, account
		get("#{account.freshdesk_url}/helpdesk/tickets/#{id}.json", account)
	end
	

	def self.add_note ticket_id, note, user_id, account, attachment=""
		body = {
		  helpdesk_note: {
		    body: note,
		    "private" => false,
		    incoming: true,
		    user_id: user_id
		  }
		}

		if !attachment.blank?
			site = RestClient::Resource.new("#{account.freshdesk_url}/helpdesk/tickets/#{ticket_id}/conversations/note.json", account.freshdesk_token, "test")
			temp = {body: note, 'private'=>false, incoming: true, user_id: user_id, attachments: {''=>[{resource: File.new(attachment, 'rb')}]}}
			site.post({helpdesk_note: temp}, content_type: "application/json")
		else
			post(body, "#{account.freshdesk_url}/helpdesk/tickets/#{ticket_id}/conversations/note.json", account)
		end
	end

	def self.tickets account
		get("#{account.freshdesk_url}/helpdesk/tickets.json", account)
	end

	def self.find_user_by_phone_number phone_number, account
		get("#{account.freshdesk_url}/helpdesk/contacts.json?query=#{phone_number}", account)
	end

	def self.create_user name, email="", description, phone_number, account
		body = {
			user: {
			  name: name,
			  email: email,
			  mobile: phone_number,
			  description: description
			}
		}
		post(body, "#{account.freshdesk_url}/contacts.json", account)
	end

	def self.find_or_create_user name, email="", description, phone_number, account
		user = find_user_by_phone_number phone_number, account
		if user.blank?
			user = create_user name, email, description, phone_number, account
		end
		user
	end

	def self.create_ticket account, user, text, notification_type="MessageReceived", image_url=""
		tickets = Ticket.unsolved_freshdesk_tickets account, user
		user.update email: "#{self.random_string}@#{self.random_string}.com" if user.email.blank?

		s = user.surveys.where(account: account).last

		if !s.nil? && !s.completed
			if s.rating.blank?
				if ['1', '2', '3'].include?(text)
					s.update rating: text.to_i
					WhatsApp.send_message(account, user.phone_number, "Thanks for the rating. Can you add a quick comment on the quality of our service?")
				else
					WhatsApp.send_message(account, user.phone_number, "Please reply with 1, 2 or 3. 1 being Excellent, 2 being Good and 3 being Bad. Thanks.")
				end
			else
				s.update comment: text
				self.create_survey s.ticket.ticket_id, account, s.rating, s.comment
				s.update completed: true
				WhatsApp.send_message(account, user.phone_number, "Thanks for the feedback. We will act on it.")
			end
		else
			if tickets.blank?
				puts "\n\n>>>>>> No tickets found\n\n"
				response = create_freshdesk_ticket text, "#{user.phone_number}##{tickets.size + 1}", user.email, account, user, ['ongair', user.phone_number]
			else
				puts "\n\n>>>>>> Found a ticket\n\n"
				ticket_id = tickets.last.ticket_id
				ticket = self.find_ticket ticket_id, account
				user_id = ticket['helpdesk_ticket']['requester_id']
				if !ticket.blank?
					if notification_type == "MessageReceived"
						t = self.add_note ticket_id, text, user_id, account
					elsif notification_type == "ImageReceived"
						t = self.add_note ticket_id, "Image Received", user_id, account, image_url
					end
					response = { message: "Comment added", ticket: t }
				else
					response = create_freshdesk_ticket text, "#{user.phone_number}##{tickets.size + 1}", user.email, account, user, ['ongair', user.phone_number]
				end
			end
		end
		response
	end
end