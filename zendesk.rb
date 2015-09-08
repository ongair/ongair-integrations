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

  def self.tickets account
    self.client(account).tickets
  end

  def self.create_zendesk_ticket account, subject, comment, submitter_id, requester_id, priority, custom_fields=[], tags=[]
    ZendeskAPI::Ticket.create(self.client(account), :subject => subject, :comment => { :value => comment }, :submitter_id => submitter_id,
     :requester_id => requester_id, :priority => priority, :custom_fields => custom_fields, :tags => tags)
  end

  def self.find_ticket account, id    
    self.client(account).tickets.find(client(account), :id => id)
  end

  def self.create_ticket_field account, type, title
    ZendeskAPI::TicketField.create(self.client(account), {type: type, title: title})
  end

  def self.find_ticket_field account, title
    field = nil
    self.client(account).ticket_fields.each do |ticket_field|
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
        if f.id == self.find_ticket_field(account, "Phone number")["id"]
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

  def self.find_user_by_phone_number account, phone_number
    client = self.client(account)
    client.users.search(query: phone_number).first
  end

  def self.find_or_create_user account, name, phone_number
    client = self.client(account)
    if self.find_user_by_phone_number(account, phone_number).nil?
      user = ZendeskAPI::User.create(client, { name: name, phone: phone_number })
    else
      user = self.find_user_by_phone_number(account, phone_number)
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

  def self.new_ticket_config account
    conditions = {all: [{field: "update_type", operator: "is", value: "Create"}, {field: "via_id", operator: "is", value: 0}], any: []}
    target_url = "#{Ongair.config.app_url}/api/tickets/new"
    target = Zendesk.create_target(account, "Ongair - New Ticket for WhatsApp end-user", target_url, "payload", "POST")
    
    payload = "{ ticket: { id: '{{ticket.id}}', comment: '{{ticket.latest_comment}}', status: '{{ticket.status}}', requester: { id: '{{ticket.requester.id}}', phone_number: '{{ticket.requester.phone}}', name: '{{ticket.requester.name}}' } }, account: #{account.ongair_phone_number} }"
    actions = [{field: "notification_target", value: [target.id, payload]}]
    Zendesk.create_trigger(account, "Ongair - New Ticket for WhatsApp end-user", conditions, actions)
  end

  def self.setup_ticket notification_type, phone_number, zen_user_id, account, user, text, image, tickets
    ticket = nil
    ticket_field = Zendesk.find_or_create_ticket_field account, "text", "Phone number"
    if notification_type == "MessageReceived"
      ticket = self.create_zendesk_ticket(account, "#{phone_number}##{tickets.size + 1}", text, zen_user_id, zen_user_id, "Urgent", [], ['Ongair', phone_number])
        # , [{"id"=>ticket_field["id"], "value"=>phone_number}])
      Ticket.find_or_create_by(account: account, phone_number: phone_number, user: user, ticket_id: ticket.id, source: "Zendesk", status: Ticket.get_status(ticket.status))
    elsif notification_type == "ImageReceived"
      # Attach image to ticket
      ticket = self.create_zendesk_ticket(account, "#{phone_number}##{tickets.size + 1}", "Image attached", zen_user_id, zen_user_id, "Urgent", [], ['Ongair', phone_number])
        # , [{"id"=>ticket_field["id"], "value"=>phone_number}])
      Ticket.find_or_create_by(account: account, phone_number: phone_number, user: user, ticket_id: ticket.id, source: "Zendesk", status: Ticket.get_status(ticket.status))
      self.download_file image
      ticket.comment.uploads << "image.png"
      ticket.save
      `rm image.png`
    end
    ticket
  end

  def self.create_ticket phone_number, name, text, notification_type, image="", account
    ticket = nil
    tickets = Ticket.unsolved_zendesk_tickets account, phone_number
    zen_user = Zendesk.find_or_create_user(account, name, phone_number)

    user = User.find_or_create_by!(phone_number: phone_number, account: account)
    if !zen_user.nil?
      zen_user_id = zen_user.id
      user.update zendesk_id: zen_user_id
    end

    if tickets.size == 0
      ticket = self.setup_ticket notification_type, phone_number, zen_user_id, account, user, text, image, tickets
      if !ticket.nil? && !account.zendesk_ticket_auto_responder.blank?
        WhatsApp.send_message(account, phone_number, WhatsApp.personalize_message(account.zendesk_ticket_auto_responder, ticket.id, name))
      end
    else
      # If unsolved ticket is found for user, their message is added as a comment
      current_ticket = tickets.last
      ticket = self.find_ticket account, current_ticket.ticket_id
      if !ticket.nil?
        if notification_type == "MessageReceived"
          current_ticket.update(user_id: user.id) if current_ticket.user.nil?
          ticket.comment = { :value => text, :author_id => zen_user_id }
        elsif notification_type == "ImageReceived"
          ticket.comment = { :value => "Image attached", :author_id => zen_user_id }
          self.download_file image
          ticket.comment.uploads << "image.png"
        end
        
        begin
          ticket.save!
        rescue ZendeskAPI::Error::RecordInvalid => e
          ticket = self.setup_ticket notification_type, phone_number, zen_user_id, account, user, text, image, tickets
          if !ticket.nil? && !account.zendesk_ticket_auto_responder.blank?
            WhatsApp.send_message(account, phone_number, WhatsApp.personalize_message(account.zendesk_ticket_auto_responder, ticket.id, name))
          end
        end 
        `rm image.png` if notification_type == "ImageReceived"
      else
        orphan = tickets.last
        ticket_field = Zendesk.find_or_create_ticket_field account, "text", "Phone number"
        puts "#{ticket_field['id']}"
        puts "#{phone_number}"
        ticket = self.create_zendesk_ticket(account, "#{phone_number}##{tickets.size + 1}", text, zen_user_id, zen_user_id, "Urgent",
          [{"id"=>ticket_field["id"], "value"=>phone_number}], ['Ongair', phone_number])

        if !ticket.nil? && !account.zendesk_ticket_auto_responder.blank?
          WhatsApp.send_message(account, phone_number, WhatsApp.personalize_message(account.zendesk_ticket_auto_responder, ticket.id, name))
        end

        Ticket.find_or_create_by(account: account, phone_number: phone_number, user: user, ticket_id: ticket.id, source: "Zendesk", status: Ticket.get_status(ticket.status))
        orphan.destroy
      end
    end
    if ticket.nil?
      response = {error: "Ticket could not be created or found!"}
    else
      response = { success: true }
    end
    response
  end

  def self.setup_account ongair_phone_number, zendesk_url, zendesk_access_token, zendesk_user, ongair_token, ongair_url, zendesk_ticket_auto_responder
    a = Account.find_or_create_by! ongair_phone_number: ongair_phone_number
    a.update(zendesk_url: zendesk_url, zendesk_access_token: zendesk_access_token,
         zendesk_user: zendesk_user, ongair_token: ongair_token, ongair_url: ongair_url, 
          zendesk_ticket_auto_responder: zendesk_ticket_auto_responder)

    # Trigger and action for ticket updates
    if a.setup
      response = { message: "Account has already been setup." }
    else
      conditions = {all: [{field: "update_type", operator: "is", value: "Change"}, {field: "comment_is_public", operator: "is", value: "requester_can_see_comment"}, {field: "comment_is_public", operator: "is", value: "true"}]}
      target_url = "#{Ongair.config.app_url}/api/notifications?ticket={{ticket.id}}&account=#{a.ongair_phone_number}&comment={{ticket.latest_comment}}&author={{ticket.latest_comment.author.id}}"
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

        a.update(setup: true)

        response = { success: true }
      end
    end
    response
  end
end