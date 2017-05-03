# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Tamashii::Server do
  let :env do
    {
      'REQUEST_METHOD'             => 'GET',
      'HTTP_CONNECTION'            => 'Upgrade',
      'HTTP_UPGRADE'               => 'websocket',
      'HTTP_ORIGIN'                => 'http://www.example.com',
      'HTTP_SEC_WEBSOCKET_KEY'     => 'JFBCWHksyIpXV+6Wlq/9pw==',
      'HTTP_SEC_WEBSOCKET_VERSION' => '13',
    }
  end

  let(:client) { double(Tamashii::Server::Connection::ClientSocket) }
  let(:event_loop) { double(Tamashii::Server::Connection::StreamEventLoop) }

  before do
    # Prevent start thread
    allow(Tamashii::Server::Connection::StreamEventLoop).to receive(:new).and_return(event_loop)
  end

  it 'starts http request' do
    request = Rack::MockRequest.env_for('/')
    response = subject.call(request)
    expect(response).to be_instance_of(Tamashii::Server::Response)
  end

  it 'starts websocket request' do
    request = Rack::MockRequest.env_for('/', env)
    expect(Tamashii::Server::Connection::ClientSocket)
      .to receive(:new).with(request, event_loop).and_return(client)
    expect(client).to receive(:rack_response)

    subject.call(request)
  end

  it 'only create one instance' do
    request = Rack::MockRequest.env_for('/')
    described_class.call(request)
    instance = described_class.instance
    described_class.call(request)
    expect(described_class.instance).to eq(instance)
  end
end
