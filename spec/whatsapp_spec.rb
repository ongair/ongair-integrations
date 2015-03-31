describe 'The Ongair WhatsApp client' do
  
  it 'Can send a WhatsApp message through Ongair' do
    account = Account.new({ ongair_phone_number: '254722200200', ongair_token: '123', ongair_url: 'http://localhost' });
    phone_number = '254705123456'
    message = 'Hi'

    request = stub_request(:post, "#{account.ongair_url}/api/v1/base/send?token=#{account.ongair_token}").
         with(:body => "phone_number=#{phone_number}&text=#{message}&thread=true").
         to_return(:status => 200, :body => "", :headers => {})

    WhatsApp.send_message account, phone_number, message
    expect(request).to have_been_made.times(1)
  end

  it 'Can send a location through Ongair' do
    account = Account.create! ongair_phone_number: '254722200200', ongair_token: '123', ongair_url: 'http://localhost'
    phone_number = '254705123456'

    Location.delete_all
    location = Location.create! latitude: 1.5, longitude: 2.0, account_id: account.id    


    request = stub_request(:post, "#{account.ongair_url}/api/v1/base/send?token=#{account.ongair_token}").
         with(:body => "phone_number=#{phone_number}&text=&thread=true").
         to_return(:status => 200, :body => "", :headers => {})

    WhatsApp.send_location location.latitude, location.longitude, phone_number
    expect(request).to have_been_made.times(1)
  end

end