require 'airborne'
require 'spec_helper'
require 'webmock/rspec'

class OngairTest
	describe 'Test Zendesk integration' do

	  it "should set up accounts" do
	  	url = 'http://accounts'
	  	stub_request(:post, "http://accounts/").
	  	         with(:body => "{\"zendesk_url\":\"https://xyz.zendesk.com/api/v2\",\"zendesk_access_token\":\"8OHrRib1QjB0lZN7GLreXv8fQNFp8Y7Ct629wi48\",\"ongair_token\":\"10qo6fb4al0sd2c58059f7dbd301f2b0\",\"ongair_phone_number\":\"254772200061\",\"zendesk_user\":\"xyz@gmail.com\",\"ongair_url\":\"http://app.ongair.im\"}",
	  	              :headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate', 'Content-Length'=>'268', 'Content-Type'=>'application/json', 'User-Agent'=>'Ruby'}).
	  	         to_return(:status => 200, :body => { success: true }.to_json, :headers => {})
	  	post 'http://accounts', { zendesk_url: "https://xyz.zendesk.com/api/v2", zendesk_access_token: "8OHrRib1QjB0lZN7GLreXv8fQNFp8Y7Ct629wi48", 
	  		ongair_token: "10qo6fb4al0sd2c58059f7dbd301f2b0", ongair_phone_number: "254772200061", zendesk_user: "xyz@gmail.com", ongair_url: "http://app.ongair.im" }, {content_type: "application/json"}
	  	# expect(WebMock).to have_requested(:post, url).with(:body => { zendesk_url: "https://xyz.zendesk.com/api/v2", zendesk_access_token: "8OHrRib1QjB0lZN7GLreXv8fQNFp8Y7Ct629wi48", 
	  		# ongair_token: "10qo6fb4al0sd2c58059f7dbd301f2b0", ongair_phone_number: "254772200061", zendesk_user: "xyz@gmail.com", ongair_url: "http://app.ongair.im" }, :headers => {'Content-Type' => 'application/json'})
			expect_json({ success: true })
	  end

	  it 'should create tickets' do
	    stub_request(:post, "http://tickets/").
         with(:body => "{\"account\":\"255686700088\",\"subject\":\"hello\",\"phone_number\":\"254722123890\",\"name\":\"John\",\"notification_type\":\"MessageReceived\",\"text\":\"help\"}",
              :headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate', 'Content-Length'=>'140', 'Content-Type'=>'application/json', 'User-Agent'=>'Ruby'}).
         to_return(:status => 200, :body => { success: true }.to_json, :headers => {})

       post 'http://tickets', { account: "255686700088", subject: "hello", phone_number: "254722123890", name: "John", notification_type: "MessageReceived", text: "help"}
       expect_json({ success: true })
	  end
	end
end