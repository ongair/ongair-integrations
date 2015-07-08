require 'spec_helper'
require 'cgi'
 
describe 'The Ongair Integrations API' do
  # fixtures :accounts
  
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

      # We are only testing that setup account is called
      Zendesk.stub(:setup_account).and_return({ success: true })

      post '/api/accounts', { ongair_phone_number: '254123456788',  zendesk_url: "https://#{zendesk_url}", zendesk_access_token: '1234567890', ongair_token: '087654321', ongair_url: 'http://app.ongair.im', zendesk_user: email }
      expect_json({ success: true })
    end
  end

  describe 'The Ticket creation process' do
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
      # move to setup
      Account.delete_all
      User.delete_all
      Ticket.delete_all

      account = Account.create! ongair_phone_number: '254722211222', zendesk_access_token: '0HMc6VD8678RH123X345mO3nffJFl3dTMvT123Kd', zendesk_url: 'https://ongair.zendesk.com/api/v2', zendesk_ticket_auto_responder: 'Hi {{ticket_id}}', zendesk_user: 'admin@ongair.im'

      # stubs for find or create zendesk user
      user = double()
      user.stub(:id).and_return('1234567890')
      Zendesk.stub(:find_or_create_user).and_return(user)

      # stub creating the ticket field
      ticket_field = { "id" => 'ticket_field_id' }
      Zendesk.stub(:find_or_create_ticket_field).and_return(ticket_field)

      ticket = double()
      ticket.stub(:id).and_return('T12345')
      ticket.stub(:status).and_return('new')

      # stub the actual ticket creation process
      Zendesk.stub(:create_zendesk_ticket).and_return(ticket)

      # stub the response to ongair
      # TODO: need to test the auto response
      WhatsApp.stub(:send_message).and_return(anything())

      post '/api/tickets', { account: account.ongair_phone_number, phone_number: '254705888999', name: 'John', text: 'Hi', notification_type: 'MessageReceived' }
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
  end  
end