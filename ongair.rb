require 'grape'
require 'active_record'
require './models/account'
require './models/location'
require './models/ticket'
require './models/user'
require './models/client'
require './models/response'
require './models/business_hour'
require 'rubygems'
require 'zendesk_api'
require 'open-uri'
# require 'pry'

require_relative 'zendesk'
require_relative 'whatsapp'


module Ongair
  include ActiveSupport::Configurable

  class API < Grape::API 
    environment = ENV['RACK_ENV'] || 'development'
    dbconfig = YAML.load(File.read('config/database.yml'))
    ActiveRecord::Base.establish_connection dbconfig[environment]

    version 'v1', using: :header, vendor: 'ongair'
    format :json
    prefix :api

    helpers do
      def account
        account = Account.find_by(ongair_phone_number: params[:account])
        if account.nil? && !params[:client].blank?
          client = Client.find(params[:client])
          tickets = Ticket.where(ticket_id: params[:ticket])
          if !client.nil?
            account = (client.accounts & tickets.collect{|t| t.account}).first
          end
        end
        account
      end

      def logger
        API.logger
      end
    end

    resource :status do
      get do
        { version: '1.0', success: true, url: Ongair.config.app_url, integrations: Account.count, zendesk_api_version: ZendeskAPI::VERSION }
      end
    end

    resource :accounts do
      # desc "Return all accounts"
      # get do
      #   Account.all
      # end

      desc "Return an account"
      params do
        requires :ongair_phone_number, type: String, desc: "Ongair Phone Number"
      end
      route_param :ongair_phone_number do
        get do
          Account.find_by(ongair_phone_number: params[:account])
        end
      end

      desc "Return users for an account"
      route_param :id do
        get :users do
          Account.find(params[:id]).users
        end
      end

      desc "Return tickets for an account"
      route_param :id do
        get :tickets do
          Account.find(params[:id]).tickets
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
        Zendesk.setup_account params[:ongair_phone_number], params[:zendesk_url], params[:zendesk_access_token], params[:zendesk_user], params[:ongair_token], params[:ongair_url], params[:zendesk_ticket_auto_responder], params[:source], params[:ticket_end_status]
      end
    end

    resource :tickets do 
      desc "Return all tickets"
      get do
        Ticket.all
      end

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

      post do
        # Create a ticket if message is text and send a location if message is location
        if params[:notification_type] == "LocationReceived"
          WhatsApp.send_location params[:latitude], params[:longitude], params[:phone_number]
        elsif params[:notification_type] == "MessageReceived" || params[:notification_type] == "ImageReceived"
          Zendesk.create_ticket params[:phone_number], params[:name], params[:text], params[:notification_type], params[:image], account
        end
      end

      desc "Ticket status change notifications"

      post :status_change do
        if params[:ticket]
          ticket = Ticket.find_by(ticket_id: params[:ticket], account: account)
          if !ticket.nil?
            status = Ticket.get_status(params[:status])
            ticket.update(status: status) if !ticket.nil?
            if ticket.status == "5" && !account.ticket_closed_notification.blank?
              WhatsApp.send_message account, ticket.phone_number, account.ticket_closed_notification
            end
          end
        end
      end
      # Autoresponder to notify user of new ticket. This can be based on either language or time.
      post :notification do
        ticket = Ticket.find_by(account: account, ticket_id: params[:ticket])
        if !ticket.nil?
          phone_number = ticket.phone_number
          WhatsApp.send_message(account, phone_number, params[:message])
        else
          ticket = Ticket.find_by(account: account, ticket_id: params[:ticket])
          n = 1
          while ticket.nil?
            ticket = Ticket.find_by(account: account, ticket_id: params[:ticket])
            n += 1
            if n == 5
              break
            end
          end

          if !ticket.nil?
            phone_number = ticket.phone_number
            WhatsApp.send_message(account, phone_number, params[:message])
          end
        end
      end
      # This allows for a ticket to be created on Zendesk on behalf of a user and the ticket message will be sent to the user.
      post :new do
        payload = eval(params[:payload])
        account = Account.find_by(ongair_phone_number: payload[:account])
        ticket = payload[:ticket]
        requester = ticket[:requester]
        phone_number = requester[:phone_number]
        phone_number = Zendesk.find_phone_number_for_ticket account, ticket[:id] if phone_number.blank?
        name = requester[:name]

        if !phone_number.blank?
          zen_user = Zendesk.find_or_create_user account, name, phone_number
          zen_ticket = Zendesk.find_ticket account, ticket[:id]
          zen_ticket.requester_id = zen_user.id
          zen_ticket.save!
          WhatsApp.create_contact account, phone_number, name
          user = User.find_or_create_by! phone_number: phone_number, zendesk_id: zen_user.id, account: account
          Ticket.create! phone_number: phone_number, ticket_id: ticket[:id], status: Ticket.get_status(ticket[:status]), source: "Zendesk", account: account, user: user
          WhatsApp.send_message(account, phone_number, params[:comment])
        end
        {success: true}
      end
    end

    resource :slack do
      post do
        account = Account.where(ongair_phone_number: "254770381135").first
        users = {
          'muaad' => 1039482362,
          'kimenye' => 512527842,
          'chief_intern' => 1046175161,
          'jobkimathi' => 1092318601
        }
        user_id = users[params[:user_name]]
        # zendesk#12 hey
        text = params[:text]
        ticket_id = text.split(" ")[0].split('#')[1]
        comment = text.split(" ")[1..text.length].join(" ")
        if !ticket_id.blank? && !comment.blank? && !user_id.blank?
          user = Zendesk.client(account).users.find(id: user_id)
          if !user.nil?
            ticket = Zendesk.find_ticket(account, ticket_id.strip)
            if !ticket.nil?
              ticket.comment = { :value => comment.strip, :author_id => user.id }
              ticket.save!
            else
              { error: "Ticket ##{ticket_id} doesn't exist on Zendesk" }
            end
          else
            { error: "User doesn't exist on Zendesk" }
          end
        else
          { message: "Not meant for Zendesk" }
        end
      end
    end

    resource :users do
      desc "Return all users"
      get do
        User.all
      end
    end

    resource :locations do
      post do
        location = Location.find_or_create_by!(address: params[:address], latitude: params[:latitude].to_f, longitude: params[:longitude].to_f, account: account)
        {success: !location.nil?}
      end
    end

    resource :notifications do
      desc "Send ticket updates, i.e. comments, to user via WhatsApp"
      
      post do
        if !account.nil?
          zen_ticket = Zendesk.find_ticket(account, params[:ticket].to_i)
          if !zen_ticket.nil?
            comment = zen_ticket.comments.last
            ticket = Ticket.find_by(ticket_id: params[:ticket].to_i, account: account)
            if !ticket.nil?
              if !params[:phone_number].blank? && !params[:requester_name].blank?
                if ticket.phone_number != params[:phone_number]
                  WhatsApp.create_contact account, params[:phone_number], params[:requester_name]
                  ticket.update(phone_number: params[:phone_number])
                  ticket.user.update(phone_number: params[:phone_number])
                end
              end
              phone_number = ticket.phone_number # Zendesk.find_phone_number_for_ticket(account, params[:ticket].to_i)

              if params.has_key?(:author)
                user = User.where(zendesk_id: params[:author], account: account).first
              else
                user = User.where(zendesk_id: comment.author_id, account: account).first
              end

              role = Zendesk.client(account).users.find(id: comment.author_id)['role']
              
              if !ticket.nil? && role != "end-user"
                # Send ticket comment through WhatsApp
                WhatsApp.send_message account, phone_number, params[:comment]

                attachments = comment.attachments
                if !attachments.empty?
                  files = attachments.collect{|a| a.content_url if (a.content_type && a.content_type.split("/")[0] == "image") }.compact
                  # Send image through WhatsApp
                  files.each do |image_url|
                    WhatsApp.send_image account, phone_number, image_url
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end

require_relative 'config/environment'