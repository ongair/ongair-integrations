require 'spec_helper'

describe 'The Zendesk integration client' do
  it 'Creates a Zendesk client by using the account' do

    account = Account.new({ zendesk_url: 'https://gogole.com', zendesk_user: 'info@google.com', zendesk_access_token: '1234567890' })
    client = Zendesk.client(account)

    expect(client.config.url).to equal(account.zendesk_url)
    expect(client.config.username).to start_with(account.zendesk_user)
    expect(client.config.token).to start_with(account.zendesk_access_token)
  end
end