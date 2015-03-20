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

      post '/api/accounts', { ongair_phone_number: '2541234567890',  zendesk_url: 'dsfsd'}
    end
  end

  describe 'How to get a ticket from ZenDesk' do
    it 'Needs a real ticket' do
      get '/api/tickets/', { id: 'doesnotexist', account: '2541234567890' }


    end
  end
end