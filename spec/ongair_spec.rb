require 'spec_helper'
require 'cgi'
 
describe 'The Ongair Integrations API' do
  
  it 'Should return the status of the API and version' do    
    get '/api/status'
    expect(response).to_not be(nil)
    expect_json({success: true, version: '1.0', url: Ongair.config.app_url, integrations: Account.count })    
  end

  describe 'The ZenDesk Account creation process' do
    it 'Requires a zendesk url to create account' do
      post '/api/accounts', { ongair_phone_number: '2541234567890' }
      expect_json({error:"zendesk_url is missing, zendesk_access_token is missing, ongair_token is missing, ongair_url is missing"})

      email = 'test@domain.com'      
      token = '1234567890'
      zendesk_url = 'test.zendesk.com/api/v2'
      ongair_phone_number = '254123456789'

      ongair_url = "#{Ongair.config.app_url}/api/notifications?ticket={{ticket.id}}&account=#{ongair_phone_number}"
      target_url = "#{Ongair.config.app_url}/api/tickets/status_change?ticket={{ticket.id}}&account=#{ongair_phone_number}&status={{ticket.status}}"

      base_zendesk_url = "https://#{CGI.escape(email + '/')}token:#{token}@#{zendesk_url}"

      stub_request(:post, "#{base_zendesk_url}/targets").         
         with(:body => { target: { type: 'url_target', title: 'Ongair - Ticket commented on', target_url: ongair_url, attribute: 'comment', method: 'POST' } }.to_json.to_s ).         
         to_return(:status => 200, :body => "", :headers => {})

      stub_request(:post, "#{base_zendesk_url}/triggers").        
       with(:body => "{\"trigger\":{\"title\":\"Ongair - Ticket commented on\",\"conditions\":{\"all\":[{\"field\":\"update_type\",\"operator\":\"is\",\"value\":\"Change\"},{\"field\":\"comment_is_public\",\"operator\":\"is\",\"value\":\"requester_can_see_comment\"},{\"field\":\"comment_is_public\",\"operator\":\"is\",\"value\":\"true\"}]},\"actions\":[{\"field\":\"notification_target\",\"value\":[null,\"{{ticket.latest_comment}}\"]}],\"output\":null}}").       
       to_return(:status => 200, :body => "", :headers => {})

      stub_request(:post, "#{base_zendesk_url}/triggers").
        with(:body => "{\"trigger\":{\"title\":\"Ongair - Notify requester of received request via WhatsApp\",\"conditions\":{\"all\":[{\"field\":\"update_type\",\"operator\":\"is\",\"value\":\"Create\"},{\"field\":\"status\",\"operator\":\"is_not\",\"value\":\"solved\"}],\"any\":[]},\"actions\":[{\"field\":\"notification_target\",\"value\":[null,\"Your request has been received and is being reviewed by our support staff.\\n\\nTo add additional comments, reply to this message.\"]}],\"output\":null}}").
        to_return(:status => 200, :body => "", :headers => {})

      stub_request(:post, "#{base_zendesk_url}/targets").
         with(:body => "{\"target\":{\"type\":\"url_target\",\"title\":\"Ongair - Ticket status changed\",\"target_url\":\"#{target_url}\",\"attribute\":\"comment\",\"method\":\"POST\"}}").
         to_return(:status => 200, :body => "", :headers => {})

      stub_request(:post, "#{base_zendesk_url}/triggers").
         with(:body => "{\"trigger\":{\"title\":\"Ongair - Ticket status changed\",\"conditions\":{\"all\":[{\"field\":\"status\",\"operator\":\"changed\",\"value\":null}],\"any\":[]},\"actions\":[{\"field\":\"notification_target\",\"value\":[null,\"The status of your ticket has been changed to {{ticket.status}}\"]}],\"output\":null}}").
         to_return(:status => 200, :body => "", :headers => {})

      stub_request(:post, "#{base_zendesk_url}/targets").
         with(:body => "{\"target\":{\"type\":\"url_target\",\"title\":\"Ongair - Ticket commented on\",\"target_url\":\"#{Ongair.config.app_url}/api/notifications?ticket={{ticket.id}}&account=254123456789&comment={{ticket.latest_comment}}\",\"attribute\":\"comment\",\"method\":\"POST\"}}").
         to_return(:status => 200, :body => "", :headers => {})

      post '/api/accounts', { ongair_phone_number: '254123456789',  zendesk_url: "https://#{zendesk_url}", zendesk_access_token: '1234567890', ongair_token: '087654321', ongair_url: 'http://app.ongair.im', zendesk_user: email }
      expect_json({ success: true })
    end
  end


  describe 'Ticket creation' do
    it 'creates ZenDesk ticket' do

      email = 'test@domain.com'      
      token = '1234567890'
      zendesk_url = 'test.zendesk.com/api/v2'
      ongair_phone_number = '254123456789'
      base_zendesk_url = "https://#{CGI.escape(email + '/')}token:#{token}@#{zendesk_url}"

      stub_request(:get, "#{base_zendesk_url}/tickets").
               with(:headers => {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'ZendeskAPI API 1.5.1'}).
               to_return(:status => 200, :body => "", :headers => {})

      stub_request(:get, "#{base_zendesk_url}/users").
               with(:headers => {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'ZendeskAPI API 1.5.1'}).
               to_return(:status => 200, :body => "", :headers => {})

      stub_request(:post, "#{base_zendesk_url}/users").
               with(:body => "{\"user\":{\"name\":\"jsk\",\"phone\":\"254722881199\"}}",
                    :headers => {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type'=>'application/json', 'User-Agent'=>'ZendeskAPI API 1.5.1'}).
               to_return(:status => 200, :body => "", :headers => {})

      stub_request(:get, "#{base_zendesk_url}/ticket_fields").
               with(:headers => {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'ZendeskAPI API 1.5.1'}).
               to_return(:status => 200, :body => "", :headers => {})

      stub_request(:post, "#{base_zendesk_url}/ticket_fields").
               with(:body => "{\"ticket_field\":{\"type\":\"text\",\"title\":\"Phone number\"}}",
                    :headers => {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type'=>'application/json', 'User-Agent'=>'ZendeskAPI API 1.5.1'}).
               to_return(:status => 200, :body => "", :headers => {})

      stub_request(:post, "#{base_zendesk_url}/tickets").
               with(:body => "{\"ticket\":{\"subject\":\"254722881199#1\",\"comment\":{\"value\":\"Hi\"},\"submitter_id\":null,\"requester_id\":null,\"priority\":\"Urgent\",\"custom_fields\":[{\"id\":null,\"value\":\"254722881199\"}]}}",
                    :headers => {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type'=>'application/json', 'User-Agent'=>'ZendeskAPI API 1.5.1'}).
               to_return(:status => 200, :body => "", :headers => {})

      stub_request(:post, "#{base_zendesk_url}/tickets").
               with(:body => "{\"ticket\":{\"subject\":\"254722881199#1\",\"comment\":{\"value\":\"Image attached\"},\"submitter_id\":null,\"requester_id\":null,\"priority\":\"Urgent\",\"custom_fields\":[{\"id\":null,\"value\":\"254722881199\"}]}}",
                    :headers => {'Accept'=>'application/json', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Content-Type'=>'application/json', 'User-Agent'=>'ZendeskAPI API 1.5.1'}).
               to_return(:status => 200, :body => "", :headers => {})

      stub_request(:post, "http://app.ongair.im/api/v1/base/send?token=087654321").
         with(:body => "phone_number=254722881199&text=&thread=true").
         to_return(:status => 200, :body => "", :headers => {})

      # Zendesk.download_file('bird.jpeg')
      # file = "-------------RubyMultipartPost\r\nContent-Disposition: form-data; name=\"filename\"\r\n\r\nimage.png\r\n-------------
      # RubyMultipartPost\r\nContent-Disposition: form-data; name=\"uploaded_data\"; filename=\"image.png\"\r\nContent-Length: 9533
      # \r\nContent-Type: image/png\r\nContent-Transfer-Encoding: binary\r\n\r\n#{File.binread('bird.jpeg')}
      # \r\n-------------RubyMultipartPost--\r\n\r\n"

      # stub_request(:post, "https://#{CGI.escape(email + '/')}token:#{token}@#{zendesk_url}/uploads").
      #          with(:body => File.binread('bird.jpeg'), 
      #               :headers => {}).
      #                        to_return(:status => 200, :body => "", :headers => {})

      post '/api/tickets', { account: '254123456789', phone_number: '254722881199', name: 'jsk', text: 'Hi', notification_type: 'MessageReceived'}      
      expect_json({ success: true })
    end
  end
end