require 'grape'
require 'active_record'
require './models/account'
require './models/location'
require './models/ticket'
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
        response = Zendesk.setup_account params
        { response: response }
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
        # logger.info "Params #{params}"
        # puts "Params #{params}"
        if params[:notification_type] == "LocationReceived"
          WhatsApp.send_location params[:latitude], params[:longitude], params[:phone_number]
        elsif params[:notification_type] == "MessageReceived" || params[:notification_type] == "ImageReceived"
          response = Zendesk.create_ticket params, account
          { response: response }
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
        if params[:ticket]
          ticket = Ticket.find_by(ticket_id: params[:ticket])
          ticket.update(status: params[:status].downcase) if !ticket.nil?
        end
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