require 'grape'

require_relative 'zendesk'

module Share
  class API < Grape::API    
    version 'v1', using: :header, vendor: 'ongair'
    format :txt
    prefix :api

    helpers do
      def account
        Account.find_by(ongair_id: params[:account])
      end

      def current_user
        Zendesk.current_user(account)
      end

      def authenticate!
        error!('401 Unauthorized', 401) unless current_user
      end
    end

    resource :tickets do 
      desc "Return all the tickets"
      get do
        Zendesk.tickets account
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
      params do
        requires :subject, type: String
        requires :comment, type: String
        requires :submitter_id, type: String
        requires :requester_id, type: String
        requires :priority, type: String
      end
      post do
        # authenticate!
        tickets = Zendesk.find_tickets_by_phone_number_and_status params[:phone_number], "open"
        user = Zendesk.create_user(params[:name], params[:phone_number])
        if tickets.size == 0
          ticket_field = Zendesk.find_ticket_field account, params[:title]
          Zendesk.create_ticket "#{params[:phone_number]}##{tickets.size + 1}", params[:text], user.id, user.id, "Urgent", [{"id"=>ticket_field["id"], "value"=>params[:phone_number]}]
        else
          ticket = tickets.last
          ticket.comment = { :value => params[:text], :author_id => user.id, public: false }
          ticket.save!
        end
      end

      desc "Comment on a ticket"
      params do
        requires :value, type: String
        requires :author_id, type: String
        requires :public, type: String
      end
      post do
        # authenticate!
        tickets = Zendesk.find_tickets_by_phone_number_and_status params[:phone_number], "open"
        user = Zendesk.create_user(params[:name], params[:phone_number])
        ticket = tickets.last
        ticket.comment = { :value => params[:text], :author_id => user.id, public: false }
        ticket.save!
      end
    end

    resource :ticket_field do
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
  end
end