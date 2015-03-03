# ongair-integrations
API for integrating Ongair into ZenDesk, FreshDesk and other platforms

## Usage

  1. Create an account:
  
    URL: http://41.242.1.46/api/accounts
    
    `POST {zendesk_url: "https://username.zendesk.com/api/v2", zendesk_access_token: "kshgksehgksjhg", 
    ongair_token: "dssdgsdg", ongair_id: ONGAIR_ACCOUNT_ID, zendesk_user: "you@mail.com"}`
    
  2. Create ticket from WhatsApp message
    
    URL: http://41.242.1.46/api/tickets
    
    `POST {account: ONGAIR_ACCOUNT_ID, subject: "Ticket subject", text: "Ticket body (WhatsApp message)", 
    phone_number: "35325325325", priority: "high/low", name: "Name of WhatsApp message sender", title: "Phone number"}`
    
    NB: The value for the `title` param is just "Phone number". This is used to create a custom field on the Ticket 
    to store the phone number.
