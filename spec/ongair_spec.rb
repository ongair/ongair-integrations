require 'spec_helper'
require 'cgi'
 
describe 'The Ongair Integrations API' do
  
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
  end
end