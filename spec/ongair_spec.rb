require 'spec_helper'
require 'cgi'
 
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

      email = 'test@domain.com'      
      token = '1234567890'
      zendesk_url = 'test.zendesk.com/api/v2'
      ongair_phone_number = '254123456789'
      ongair_url = "http://41.242.1.46/api/notifications?ticket={{ticket.id}}&account=#{ongair_phone_number}"
      target_url = "http://41.242.1.46/api/tickets/status_change?ticket={{ticket.id}}&account=#{ongair_phone_number}&status={{ticket.status}}"

# with(:body => "{\"target\":{\"type\":\"url_target\",\"title\":\"Ongair - Ticket commented on\",\"target_url\":\"http://41.242.1.46/api/notifications?ticket={{ticket.id}}&account=254123456789\",\"attribute\":\"comment\",\"method\":\"POST\"}}").
      stub_request(:post, "https://#{CGI.escape(email + '/')}token:#{token}@#{zendesk_url}/targets").         
         # with(:body => { target: { type: 'url_target', title: 'Ongair - Ticket commented on', target_url: ongair_url, attribute: 'comment', method: 'POST' } }.to_json.to_s ).
         with(:body => "{\"target\":{\"type\":\"url_target\",\"title\":\"Ongair - Ticket commented on\",\"target_url\":\"#{ongair_url}\",\"attribute\":\"comment\",\"method\":\"POST\"}}").
         to_return(:status => 200, :body => "", :headers => {})

      stub_request(:post, "https://#{CGI.escape(email + '/')}token:#{token}@#{zendesk_url}/triggers").
       with(:body => "{\"trigger\":{\"title\":\"Ongair - Ticket commented on\",\"conditions\":{\"all\":[{\"field\":\"update_type\",\"operator\":\"is\",\"value\":\"Change\"},{\"field\":\"comment_is_public\",\"operator\":\"is\",\"value\":\"requester_can_see_comment\"},{\"field\":\"comment_is_public\",\"operator\":\"is\",\"value\":\"true\"}]},\"actions\":[{\"field\":\"notification_target\",\"value\":[null,\"{{ticket.latest_comment}}\"]}],\"output\":null}}").
       to_return(:status => 200, :body => "", :headers => {})

      stub_request(:post, "https://#{CGI.escape(email + '/')}token:#{token}@#{zendesk_url}/triggers").
        with(:body => "{\"trigger\":{\"title\":\"Ongair - Notify requester of received request via WhatsApp\",\"conditions\":{\"all\":[{\"field\":\"update_type\",\"operator\":\"is\",\"value\":\"Create\"},{\"field\":\"status\",\"operator\":\"is_not\",\"value\":\"solved\"}],\"any\":[]},\"actions\":[{\"field\":\"notification_target\",\"value\":[null,\"Your request has been received and is being reviewed by our support staff.\\n\\nTo add additional comments, reply to this message.\"]}],\"output\":null}}").
        to_return(:status => 200, :body => "", :headers => {})

      stub_request(:post, "https://#{CGI.escape(email + '/')}token:#{token}@#{zendesk_url}/targets").
         with(:body => "{\"target\":{\"type\":\"url_target\",\"title\":\"Ongair - Ticket status changed\",\"target_url\":\"#{target_url}\",\"attribute\":\"comment\",\"method\":\"POST\"}}").
         to_return(:status => 200, :body => "", :headers => {})

      stub_request(:post, "https://#{CGI.escape(email + '/')}token:#{token}@#{zendesk_url}/triggers").
         with(:body => "{\"trigger\":{\"title\":\"Ongair - Ticket status changed\",\"conditions\":{\"all\":[{\"field\":\"status\",\"operator\":\"changed\",\"value\":null}],\"any\":[]},\"actions\":[{\"field\":\"notification_target\",\"value\":[null,\"The status of your ticket has been changed to {{ticket.status}}\"]}],\"output\":null}}").
         to_return(:status => 200, :body => "", :headers => {})

      post '/api/accounts', { ongair_phone_number: '254123456789',  zendesk_url: "https://#{zendesk_url}", zendesk_access_token: '1234567890', ongair_token: '087654321', ongair_url: 'http://app.ongair.im', zendesk_user: email }
      puts response.body
      expect_json({ success: true })
    end
  end

  describe 'How to get a ticket from ZenDesk' do
    it 'Needs a real ticket' do
      get '/api/tickets/', { id: 'doesnotexist', account: '2541234567890' }


    end
  end

  describe 'Ticket creation' do
    # it 'creates ZenDesk ticket' do
    #   stub_request(:get, "https://muadh24%40gmail.com%2Ftoken:8OHrRib1QjB0lZN7GLreXv8fQNFp8Y7Ct6qhUx0E@muaadh.zendesk.com/api/v2/tickets").
    #            with(:headers => {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'ZendeskAPI API 1.5.1'}).
    #            to_return(:status => 200, :body => "", :headers => {})
    #   post '/api/tickets', { account: '255686766788', phone_number: '254722881199', name: 'jsk', text: 'Hi', notification_type: 'MessageReceived'}
    #   puts response.body
    # end
  end
end