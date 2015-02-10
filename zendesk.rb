require 'rubygems'

module Zendesk
  def client zendesk_access_token, url
    client = ZendeskAPI::Client.new do |config|
      # Mandatory:

      config.url = url # e.g. https://mydesk.zendesk.com/api/v2

      # Basic / Token Authentication
      # config.username = ENV['ZENDESK_USER']

      # Choose one of the following depending on your authentication choice
      # config.token = "your zendesk token"
      # config.password = ENV['ZENDESK_PASSWORD']

      # OAuth Authentication
      config.access_token = zendesk_access_token

      # Optional:

      # Retry uses middleware to notify the user
      # when hitting the rate limit, sleep automatically,
      # then retry the request.
      config.retry = true

      # Logger prints to STDERR by default, to e.g. print to stdout:
      require 'logger'
      config.logger = Logger.new(STDOUT)

      # Changes Faraday adapter
      # config.adapter = :patron

      # Merged with the default client options hash
      # config.client_options = { :ssl => false }

      # When getting the error 'hostname does not match the server certificate'
      # use the API at https://yoursubdomain.zendesk.com/api/v2
    end
  end

  def self.current_user account
    client(account.zendesk_access_token, account.zendesk_url).current_user
  end

  def self.tickets account
    client(account.zendesk_access_token, account.zendesk_url).tickets
  end

  def self.create_ticket account, subject, comment, submitter_id, requester_id, priority, custom_fields=[]
    ZendeskAPI::Ticket.create(client(account.zendesk_access_token, account.zendesk_url), :subject => subject, :comment => { :value => comment }, :submitter_id => submitter_id,
     :requester_id => requester_id, :priority => priority, :custom_fields => custom_fields)
  end

  def self.find_ticket account, id
    client(account.zendesk_access_token, account.zendesk_url).tickets.find(client(account.zendesk_access_token, account.zendesk_url), :id => id)
  end

  def self.find_tickets_by_phone_number_and_status account, phone_number, status
    tickets = []
    client(account.zendesk_access_token, account.zendesk_url).tickets.all do |ticket|
      if ticket["custom_fields"][0].value == phone_number && ticket.status == status
        tickets << ticket
      end
    end
    tickets
  end

  def create_ticket_field account, type, title
    ZendeskAPI::TicketField.create(client(account.zendesk_access_token, account.zendesk_url), {type: type, title: title})
  end

  def find_ticket_field account, title
    client(account.zendesk_access_token, account.zendesk_url).ticket_fields.all do |ticket_field|
      if ticket_field["title"] == title
        field = ticket_field
      end
    end
    field
  end

  def self.forward_ticket_updates phone_number, message
    HTTParty.post("http://beta.ongair.im/api/v1/base/send?token=#{ENV['ONGAIR_API_KEY']}", body: {phone_number: phone_number, text: message, thread: true})
  end

  def self.find_user_by_phone_number account, phone_number
    client(account.zendesk_access_token, account.zendesk_url).users.all do |user|
      return user if user.phone == phone_number
    end
  end

  def self.create_user account, name, phone_number
    if find_user_by_phone_number(phone_number).nil?
      user = ZendeskAPI::User.create(client(account.zendesk_access_token, account.zendesk_url), { name: name, phone: phone_number })
    else
      user = find_user_by_phone_number(phone_number)
    end
    user
  end

  def self.create_trigger account, title, conditions={}, actions=[]
    ZendeskAPI::Trigger.create(client(account.zendesk_access_token, account.zendesk_url), {title: title, conditions: conditions, actions: actions})
    # actions = [{field: "notification_target", value: ["20092202", "Ticket {{ticket.id}} has been updated."]}] # Use target as action
    # ZendeskAPI::Trigger.create(z.client(account.zendesk_access_token, account.zendesk_url), {title: "Trigger from web API", conditions: {all: [{field: "status", operator: "is", value: "open"}]}, actions: [{field: "status", value: "solved"}]})
  end

  def self.create_target account, title, target_url, attribute, method
    ZendeskAPI::Target.create(client(account.zendesk_access_token, account.zendesk_url), {type: "url_target", title: title, target_url: target_url, attribute: attribute, method: method})   
  end
end