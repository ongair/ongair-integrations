describe 'The Zendesk Ticket' do
  it 'Can get the correct status id from the status word' do
    expect(Ticket.get_status('new')).to eql(Ticket::STATUS_NEW)
    expect(Ticket.get_status('novo')).to eql(Ticket::STATUS_NEW)
    expect(Ticket.get_status('nieuw')).to eql(Ticket::STATUS_NEW)

    expect(Ticket.get_status('open')).to eql(Ticket::STATUS_OPEN)
    expect(Ticket.get_status('abierto')).to eql(Ticket::STATUS_OPEN)
    
    expect(Ticket.get_status('pendiente')).to eql(Ticket::STATUS_PENDING)
    expect(Ticket.get_status('pending')).to eql(Ticket::STATUS_PENDING)
    
    
    expect(Ticket.get_status('resolvido')).to eql(Ticket::STATUS_SOLVED)
    expect(Ticket.get_status('solved')).to eql(Ticket::STATUS_SOLVED)
    
    expect(Ticket.get_status('cerrado')).to eql(Ticket::STATUS_CLOSED)
    expect(Ticket.get_status('closed')).to eql(Ticket::STATUS_CLOSED)
  end

  it 'Can be commented on only if it is either new, open or pending' do
    ticket = Ticket.new(status: Ticket::STATUS_NEW )
    expect(ticket.can_be_commented?).to eql(true)

    ticket.status = Ticket::STATUS_OPEN
    expect(ticket.can_be_commented?).to eql(true)

    ticket.status = Ticket::STATUS_PENDING
    expect(ticket.can_be_commented?).to eql(true)

    ticket.status = Ticket::STATUS_SOLVED
    expect(ticket.can_be_commented?).to eql(false)

    ticket.status = Ticket::STATUS_CLOSED
    expect(ticket.can_be_commented?).to eql(false)    
  end
end