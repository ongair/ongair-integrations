require 'spec_helper'
require 'cgi'
 
describe 'The Ongair Integrations API' do
  before(:each) do
    Account.delete_all
    User.delete_all
    Ticket.delete_all

    @account = Account.create! ongair_phone_number: '254722211222', zendesk_access_token: '0HMc6VD8678RH123X345mO3nffJFl3dTMvT123Kd', zendesk_url: 'https://ongair.zendesk.com/api/v2', zendesk_ticket_auto_responder: nil, zendesk_user: 'admin@ongair.im'
  end
  
  it 'Should return the status of the API and version' do    
    get '/api/status'
    expect(response).to_not be(nil)
    expect_json({success: true, version: '1.0', url: Ongair.config.app_url, integrations: Account.count, zendesk_api_version: ZendeskAPI::VERSION })    
  end

  describe 'The ZenDesk Account creation process' do
    it 'Requires a zendesk url to create account' do
      post '/api/accounts', { ongair_phone_number: '2541234567890' }
      expect_json({error:"zendesk_url is missing, zendesk_access_token is missing, ongair_token is missing, ongair_url is missing"})
    end

    it 'Creates a Zendesk account' do
      email = 'test@domain.com'      
      token = '1234567890'
      zendesk_url = 'test.zendesk.com/api/v2'
      ongair_phone_number = '254123456789'

      expect(Zendesk).to receive(:setup_account).and_return({ success: true })

      post '/api/accounts', { ongair_phone_number: '254123456788',  zendesk_url: "https://#{zendesk_url}", zendesk_access_token: '1234567890', ongair_token: '087654321', ongair_url: 'http://app.ongair.im', zendesk_user: email }
      expect_json({ success: true })
    end
  end

  describe 'The Ticket creation process' do
    before(:each) do

      # stubs for find or create zendesk user
      @user = double()
      @user.stub(:id).and_return('1234567890')
      Zendesk.stub(:find_or_create_user).and_return(@user)

      # stub creating the ticket field
      ticket_field = { "id" => 'ticket_field_id' }
      Zendesk.stub(:find_or_create_ticket_field).and_return(ticket_field)

      # stub the response to ongair
      # TODO: need to test the auto response
      # WhatsApp.stub(:send_message).and_return(anything())
    end

    it 'Creates a Zendesk ticket' do
      email = 'test@domain.com'      
      token = '1234567890'
      zendesk_url = 'test.zendesk.com/api/v2'
      ongair_phone_number = '254123456789'

      # The create ticket method is called
      Zendesk.stub(:create_ticket).and_return({ success: true })

      post '/api/tickets', { account: '254123456789', phone_number: '254722881199', name: 'jsk', text: 'Hi', notification_type: 'MessageReceived'}      
      expect_json({ success: true })
    end

    it 'creates a new ticket if there are no valid tickets' do            
      ticket = double()
      ticket.stub(:id).and_return('T12345')
      ticket.stub(:status).and_return('new')

      # stub the actual ticket creation process
      Zendesk.stub(:create_zendesk_ticket).and_return(ticket)

      post '/api/tickets', { account: @account.ongair_phone_number, phone_number: '254705888999', name: 'John', text: 'Hi', notification_type: 'MessageReceived' }
      expect_json({ success: true })

      # test that a user is created
      created_user = User.find_by(phone_number: '254705888999')
      expect(created_user).to_not be_nil
      expect(created_user.zendesk_id).to eql('1234567890')

      # test that a ticket is created
      ticket = Ticket.first
      expect(ticket.ticket_id).to eql('T12345')
      expect(ticket.user).to eql(created_user)
      expect(ticket.status).to eql(Ticket::STATUS_NEW)
    end

    it 'Creates a comment if there is an existing new ticket' do      
      existing_user = User.find_or_create_by(phone_number: '254705888999', zendesk_id: @user.id)
      ticket = Ticket.find_or_create_by(user: existing_user, status: Ticket::STATUS_NEW, ticket_id: '1234567', account: @account, source: 'Zendesk', phone_number: '254705888999')

      expect(ticket.can_be_commented?).to eql(true)
      
      zendesk_ticket = instance_double('ZendeskAPI::Ticket')
      expect(zendesk_ticket).to receive(:save!)
      expect(zendesk_ticket).to receive(:comment=).with(hash_including(:value=>"What is wrong?"))

      Zendesk.stub(:find_ticket).and_return(zendesk_ticket)

      post '/api/tickets', { account: @account.ongair_phone_number, phone_number: '254705888999', name: 'John', text: 'What is wrong?', notification_type: 'MessageReceived' }
      expect_json({ success: true })
    end


    describe 'The callbacks from Zendesk' do

      before(:each) do
        existing_user = User.find_or_create_by(phone_number: '254705888999', zendesk_id: @user.id)
        @ticket = Ticket.find_or_create_by(user: existing_user, status: Ticket::STATUS_NEW, ticket_id: '1234567', account: @account, source: 'Zendesk', phone_number: '254705888999')
      end

      
      it 'Sends a WhatsApp message when an agent responds to a ticket' do

        # comment = Zendesk.find_ticket(account, params[:ticket].to_i).comments.last
        ticket = double()
        comments = double()
        last_comment = double()
        
        expect(comments).to receive(:last).and_return(last_comment)
        expect(ticket).to receive(:comments).and_return(comments)
        expect(Zendesk).to receive(:find_ticket).with(@account, @ticket.ticket_id.to_i).and_return(ticket)

        # post '/api/notifications', { ticket: @ticket.ticket_id, comment: 'How can I help you?', author: 'admin@ongair.im', account: @account.ongair_phone_number } 
        # expect(response).to be_success
      end
    end
  end  
end