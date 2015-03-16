require 'grape'
require 'active_record'
require './models/account'
require './models/location'
require 'rubygems'
require 'zendesk_api'
require 'open-uri'

require_relative 'zendesk'
require_relative 'whatsapp'

# conf = YAML.load_file('./config/database.yml')
# ActiveRecord::Base.establish_connection({adapter:  'sqlite3', database: 'db/dev.sqlite3'})

module Ongair
  class API < Grape::API 
    environment = ENV['RACK_ENV'] || 'development'
    dbconfig = YAML.load(File.read('config/database.yml'))
    ActiveRecord::Base.establish_connection dbconfig[environment]

    version 'v1', using: :header, vendor: 'ongair'
    format :json
    prefix :api

    helpers do
      def account
        Account.find_by(ongair_phone_number: params[:account])
      end

      def create_ticket
        tickets = Zendesk.find_unsolved_tickets_for_phone_number account, params[:phone_number]
        user = Zendesk.create_user(Zendesk.client(account), params[:name], params[:phone_number])
        if tickets.size == 0
          ticket_field = Zendesk.find_or_create_ticket_field account, "text", "Phone number"
          if params[:notification_type] == "MessageReceived"
            Zendesk.create_ticket(account, "#{params[:phone_number]}##{tickets.size + 1}", params[:text], user.id, user.id, "Urgent",
              [{"id"=>ticket_field["id"], "value"=>params[:phone_number]}])
          elsif params[:notification_type] == "ImageReceived"
            ticket = Zendesk.create_ticket(account, "#{params[:phone_number]}##{tickets.size + 1}", "Image attached", user.id, user.id, "Urgent",
              [{"id"=>ticket_field["id"], "value"=>params[:phone_number]}])
            download_file
            ticket.comment.uploads << "image.png"
            ticket.save
            `rm image.png`
          end
        else
          ticket = tickets.last
          if params[:notification_type] == "MessageReceived"
            ticket.comment = { :value => params[:text], :author_id => user.id, public: false }
          elsif params[:notification_type] == "ImageReceived"
            ticket.comment = { :value => "Image attached", :author_id => user.id, public: false }
            download_file
            ticket.comment.uploads << "image.png"
          end
          ticket.save!
          `rm image.png`
        end
      end

      def download_file
        open('image.png', 'wb') do |file|
          file << open(params[:image]).read
        end
      end

      def logger
        API.logger
      end

      def current_user
        Zendesk.current_user(account)
      end

      def authenticate!
        error!('401 Unauthorized', 401) unless current_user
      end
    end

    resource :accounts do
      desc "Return an account"
      params do
        requires :ongair_phone_number, type: String, desc: "Ongair Phone Number"
      end
      route_param :ongair_phone_number do
        get do
          Account.find_by(ongair_phone_number: params[:account])
        end
      end

      desc "Create a new account"
      params do
        requires :zendesk_url, type: String
        requires :zendesk_access_token, type: String
        requires :ongair_token, type: String
        requires :ongair_phone_number, type: String
        requires :ongair_url, type: String
      end
      post do
        # authenticate!
        a = Account.find_or_create_by! zendesk_url: params[:zendesk_url], zendesk_access_token: params[:zendesk_access_token],
         zendesk_user: params[:zendesk_user], ongair_token: params[:ongair_token], ongair_phone_number: params[:ongair_phone_number],
         ongair_url: params[:ongair_url]

        # Trigger and action for ticket updates
        
        conditions = {all: [{field: "update_type", operator: "is", value: "Change"}, {field: "comment_is_public", operator: "is", value: "requester_can_see_comment"}, {field: "comment_is_public", operator: "is", value: "true"}]}
        target_url = "http://41.242.1.46/api/notifications?ticket={{ticket.id}}&account=#{a.ongair_phone_number}"
        target = Zendesk.create_target(a, "Ongair - Ticket commented on", target_url, "comment", "POST")
        actions = [{field: "notification_target", value: [target.id, "{{ticket.latest_comment}}"]}]
        Zendesk.create_trigger(a, "Ongair - Ticket commented on", conditions, actions)

        # Trigger for ticket creation auto responder

        conditions = {all: [{field: "update_type", operator: "is", value: "Create"}, {field: "status", operator: "is_not", value: "solved"}], any: []}
        actions = [{field: "notification_target", value: [target.id, "Your request has been received and is being reviewed by our support staff.\n\nTo add additional comments, reply to this message."]}]
        Zendesk.create_trigger(a, "Ongair - Notify requester of received request via WhatsApp", conditions, actions)

        # Trigger and action for ticket status changes

        conditions = {all: [{field: "status", operator: "changed", value: nil}], any: []}
        target_url = "http://41.242.1.46/api/tickets/status_change?ticket={{ticket.id}}&account=#{a.ongair_phone_number}&status={{ticket.status}}"
        target = Zendesk.create_target(a, "Ongair - Ticket status changed", target_url, "comment", "POST")
        actions = [{field: "notification_target", value: [target.id, "The status of your ticket has been changed to {{ticket.status}}"]}]
        Zendesk.create_trigger(a, "Ongair - Ticket status changed", conditions, actions)
        { success: true }
      end
    end

    resource :tickets do 
      # desc "Return all the tickets"
      # get do
      #   Zendesk.tickets account
      # end    

      desc "Return a ticket"
      params do
        requires :id, type: Integer, desc: "Ticket id"
      end
      route_param :id do
        get do
          Zendesk.find_ticket account, params[:id]
        end
      end

      desc "Create a new ticket"
      # params do
      #   # requires :subject, type: String
      #   requires :text, type: String
      #   requires :phone_number, type: String
      #   requires :name, type: String
      #   # requires :priority, type: String
      # end
      post do
        logger.info "Params #{params}"
        puts "Params #{params}"
        if params[:notification_type] == "LocationReceived"
          WhatsApp.send_location params[:latitude], params[:longitude], params[:phone_number]
        elsif params[:notification_type] == "MessageReceived" || params[:notification_type] == "ImageReceived"
          create_ticket
        end
      end

      # desc "Comment on a ticket"
      # params do
      #   requires :value, type: String
      #   requires :author_id, type: String
      #   requires :public, type: String
      # end
      # post do
      #   # authenticate!
      #   tickets = Zendesk.find_tickets_by_phone_number_and_status params[:phone_number], "open"
      #   user = Zendesk.create_user(params[:name], params[:phone_number])
      #   ticket = tickets.last
      #   ticket.comment = { :value => params[:text], :author_id => user.id, public: false }
      #   ticket.save!
      # end

      desc "Ticket status change notifications"

      post :status_change do
        # puts "<><><><><> #{params}"
        # post to Ongair so that a conversation can be closed when a ticket is closed
      end
    end

    resource :locations do
      post do
        Location.find_or_create_by!(address: params[:address], latitude: params[:latitude].to_f, longitude: params[:longitude].to_f, account: account)
        {success: true}
      end
    end

    resource :ticket_fields do
      desc "Return a ticket field"
      params do
        requires :title, type: String, desc: "Ticket field title"
      end
      route_param :id do
        get do
          Zendesk.find_ticket_field account, params[:title]
        end
      end

      desc "Create a new ticket field"
      params do
        requires :type, type: String
        requires :title, type: String
      end
      post do
        Zendesk.create_ticket_field account, params[:type], params[:title]
      end
    end

    resource :notifications do
      desc "Send ticket updates to Ongair"
      params do
        # requires :phone_number, type: String
        # requires :message, type: String
      end
      post do
        phone_number = Zendesk.find_phone_number_for_ticket(account, params[:ticket].to_i)
        WhatsApp.send_message account, phone_number, params[:comment]
      end
    end
  end
end