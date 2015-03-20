require 'spec_helper'
 
describe 'The Ongair Integrations API' do
  
  # it 'Should return the status of the API and version' do    
  #   get '/api/status'
  #   expect(response).to_not be(nil)
  #   expect_json({success: true, version: '1.0'})    
  # end

  describe 'The ZenDesk Account creation process' do
    it 'Requires a zendesk url to create account' do
      post '/api/accounts', { ongair_phone_number: '2541234567890' }
      expect_json({error:"zendesk_url is missing, zendesk_access_token is missing, ongair_token is missing, ongair_url is missing"})

      post '/api/accounts', { ongair_phone_number: '254123456789',  zendesk_url: 'https://test.zendesk.com', zendesk_access_token: '1234567890', ongair_token: '087654321', ongair_url: 'http://app.ongair.im', zendesk_user: 'test@domain.com' }
      expect_json({ success: true })
    end
  end

  describe 'How to get a ticket from ZenDesk' do
    it 'Needs a real ticket' do
      get '/api/tickets/', { id: 'doesnotexist', account: '2541234567890' }


    end
  end
end