require 'rubygems'
require 'zendesk_api'
require 'httparty'

class Zendesk

  def self.client account
    client = ZendeskAPI::Client.new do |config|
      config.url = account.zendesk_url
      config.username = account.zendesk_user
      config.token = account.zendesk_access_token
      config.retry = true
      if ENV['RACK_ENV'] == 'development'
        require 'logger'
        config.logger = Logger.new(STDOUT)
      end
    end
  end

  def self.current_user account
    self.client(account).current_user
  end

  def self.tickets account
    self.client(account).tickets
  end

  def self.create_zendesk_ticket account, subject, comment, submitter_id, requester_id, priority, custom_fields=[]
    ZendeskAPI::Ticket.create(self.client(account), :subject => subject, :comment => { :value => comment }, :submitter_id => submitter_id,
     :requester_id => requester_id, :priority => priority, :custom_fields => custom_fields)
  end

  def self.find_ticket account, id
    self.client(account).tickets.find(client(account), :id => id)
  end

  def self.find_tickets_by_phone_number_and_status account, phone_number, status
    tickets = []
    self.client(account).tickets.all do |ticket|
      if !ticket["custom_fields"].empty?
        if ticket["custom_fields"][0].value == phone_number && (ticket.status == status || ticket.status == "pending" || ticket.status == "new")
          tickets << ticket
        end
      end
    end
    tickets
  end

  def self.find_unsolved_tickets_for_phone_number account, phone_number
    tickets = []
    self.client(account).tickets.all do |ticket|
      if self.find_phone_number_for_ticket(account, ticket.id) == phone_number && ticket.status == "open" || ticket.status == "pending" || ticket.status == "new"
        tickets << ticket
      end
    end
    tickets
  end

  def self.create_ticket_field account, type, title
    ZendeskAPI::TicketField.create(self.client(account), {type: type, title: title})
  end

  def self.find_ticket_field account, title
    field = nil
    self.client(account).ticket_fields.all do |ticket_field|
      if ticket_field["title"] == title
        field = ticket_field
      end
    end
    field
  end

  def self.find_phone_number_for_ticket account, ticket_id
    ticket = self.find_ticket(account, ticket_id)
    phone_number = nil
    if !ticket.nil?
      ticket["custom_fields"].each do |f|
        if f.id == self.find_ticket_field(account, "Phone number").id
          phone_number = f.value
        end
      end
    end
    phone_number
  end

  def self.find_or_create_ticket_field account, type, title
    field = ""
    if self.find_ticket_field(account, title).nil?
      field = self.create_ticket_field account, type, title
    else
      field = self.find_ticket_field(account, title)
    end
    field
  end

  def self.upload account, file
    ZendeskAPI::Attachment.new(self.client(account), {file: file}).save
  end

  def self.find_user_by_phone_number client, phone_number
    client.users.all do |user|
      return user if user.phone == phone_number
    end
  end

  def self.create_user client, name, phone_number
    if self.find_user_by_phone_number(client, phone_number).nil?
      user = ZendeskAPI::User.create(client, { name: name, phone: phone_number })
    else
      user = self.find_user_by_phone_number(client, phone_number)
    end
    user
  end

  def self.create_trigger account, title, conditions={}, actions=[]
    ZendeskAPI::Trigger.create(self.client(account), {title: title, conditions: conditions, actions: actions})
  end

  def self.create_target account, title, target_url, attribute, method
    ZendeskAPI::Target.create(self.client(account), {type: "url_target", title: title, target_url: target_url, attribute: attribute, method: method})   
  end

  def self.download_file image
    open('image.png', 'wb') do |file|
      file << open(image).read
    end
  end

  def self.create_ticket params, account
    ticket = nil
    tickets = Ticket.unsolved_zendesk_tickets account, params[:phone_number]
    user = Zendesk.create_user(Zendesk.client(account), params[:name], params[:phone_number])
    if tickets.size == 0
      ticket_field = Zendesk.find_or_create_ticket_field account, "text", "Phone number"
      if params[:notification_type] == "MessageReceived"
        ticket = self.create_zendesk_ticket(account, "#{params[:phone_number]}##{tickets.size + 1}", params[:text], user.id, user.id, "Urgent",
          [{"id"=>ticket_field["id"], "value"=>params[:phone_number]}])
        Ticket.find_or_create_by(account: account, phone_number: params[:phone_number], ticket_id: ticket.id, source: "Zendesk", status: ticket.status)
      elsif params[:notification_type] == "ImageReceived"
        # Attach image to ticket
        ticket = self.create_zendesk_ticket(account, "#{params[:phone_number]}##{tickets.size + 1}", "Image attached", user.id, user.id, "Urgent",
          [{"id"=>ticket_field["id"], "value"=>params[:phone_number]}])
        Ticket.find_or_create_by(account: account, phone_number: params[:phone_number], ticket_id: ticket.id, source: "Zendesk", status: ticket.status)
        self.download_file params[:image]
        ticket.comment.uploads << "image.png"
        ticket.save
        `rm image.png`
      end
      if !ticket.nil?
        WhatsApp.send_message(account, params[:phone_number], account.zendesk_ticket_auto_responder)
      end
    else
      # If unsolved ticket is found for user, their message is added as a comment
      ticket = self.find_ticket account, tickets.last.ticket_id
      if params[:notification_type] == "MessageReceived"
        # Ticket comment is set as private because of a trigger condition I set up on Zendesk. This is to avoid the same comment
        # being sent back to user since there is a trigger that sends all ticket comments to user. There was no other way to differentiate
        # a user comment from an agent comment
        ticket.comment = { :value => params[:text], :author_id => user.id, public: false }
      elsif params[:notification_type] == "ImageReceived"
        ticket.comment = { :value => "Image attached", :author_id => user.id, public: false }
        self.download_file params[:image]
        ticket.comment.uploads << "image.png"
      end
      ticket.save!
      `rm image.png`
    end
    if ticket.nil?
      response = {error: "Ticket could not be created or found!"}
    else
      response = { success: true }
    end
    response
  end

  def self.setup_account params
    a = Account.find_or_create_by! ongair_phone_number: params[:ongair_phone_number]
    a.update(zendesk_url: params[:zendesk_url], zendesk_access_token: params[:zendesk_access_token],
         zendesk_user: params[:zendesk_user], ongair_token: params[:ongair_token], ongair_url: params[:ongair_url], 
          zendesk_ticket_auto_responder: params[:zendesk_ticket_auto_responder])

    # Trigger and action for ticket updates
    
    conditions = {all: [{field: "update_type", operator: "is", value: "Change"}, {field: "comment_is_public", operator: "is", value: "requester_can_see_comment"}, {field: "comment_is_public", operator: "is", value: "true"}]}
    target_url = "#{Ongair.config.app_url}/api/notifications?ticket={{ticket.id}}&account=#{a.ongair_phone_number}&comment={{ticket.latest_comment}}"
    target = Zendesk.create_target(a, "Ongair - Ticket commented on", target_url, "comment", "POST")
    if target.nil?
      response = {error: "Could not be authenticated!"}
    else
      actions = [{field: "notification_target", value: [target.id, "{{ticket.latest_comment}}"]}]
      Zendesk.create_trigger(a, "Ongair - Ticket commented on", conditions, actions)

      # Trigger and action for ticket status changes

      conditions = {all: [{field: "status", operator: "changed", value: nil}], any: []}
      target_url = "#{Ongair.config.app_url}/api/tickets/status_change?ticket={{ticket.id}}&account=#{a.ongair_phone_number}&status={{ticket.status}}"
      target = Zendesk.create_target(a, "Ongair - Ticket status changed", target_url, "comment", "POST")
      actions = [{field: "notification_target", value: [target.id, "The status of your ticket has been changed to {{ticket.status}}"]}]
      Zendesk.create_trigger(a, "Ongair - Ticket status changed", conditions, actions)

      response = { success: true }
    end
    response
  end
end