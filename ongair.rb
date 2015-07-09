require 'grape'
require 'active_record'
require './models/account'
require './models/location'
require './models/ticket'
require './models/user'
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
        Account.find_by(ongair_phone_number: params[:account])
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
        Zendesk.setup_account params[:ongair_phone_number], params[:zendesk_url], params[:zendesk_access_token], params[:zendesk_user], params[:ongair_token], params[:ongair_url], params[:zendesk_ticket_auto_responder]
      end
    end

    resource :tickets do 
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
          ticket = Ticket.find_by(ticket_id: params[:ticket])
          ticket.update(status: params[:status].downcase) if !ticket.nil?
          status = Ticket.get_status(params[:status])
          ticket.update(status: status) if !ticket.nil?
        end
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
        comment = Zendesk.find_ticket(account, params[:ticket].to_i).comments.last
        phone_number = Zendesk.find_phone_number_for_ticket(account, params[:ticket].to_i)
        ticket = Ticket.find_by(ticket_id: params[:ticket].to_i)

        if params.has_key?(:author)
          user = User.where(zendesk_id: params[:author], account: account).first
        else
          user = User.where(zendesk_id: comment.author_id, account: account).first
        end
        
        if (!ticket.nil? && ticket.user != user) || user.nil?
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

require_relative 'config/environment'