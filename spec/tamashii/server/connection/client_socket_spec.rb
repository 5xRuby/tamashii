# frozen_string_literal: true

require 'spec_helper'

RSpec::Matchers.define :detemine_as_secure_request do |env|
  match do
    Tamashii::Server::Connection::ClientSocket.secure_request?(env)
  end
end

RSpec::Matchers.define :use_secure_url do |env|
  match do
    Tamashii::Server::Connection::ClientSocket.determine_url(env).start_with?('wss://')
  end
end

RSpec.describe Tamashii::Server::Connection::ClientSocket do
  context 'ClassMethods' do
    subject { nil }
    describe '#determine_url' do
      it { should use_secure_url('HTTPS' => 'on') }
      it { should_not use_secure_url('HTTPS' => 'off') }
    end

    describe '#secure_request?' do
      it { should detemine_as_secure_request('HTTPS' => 'on') }
      it { should detemine_as_secure_request('HTTP_X_FORWARDED_SSL' => 'on') }
      it { should detemine_as_secure_request('HTTP_X_FORWARDED_SCHEME' => 'https') }
      it { should detemine_as_secure_request('HTTP_X_FORWARDED_PROTO' => 'https') }
      it { should detemine_as_secure_request('rack.url_scheme' => 'https') }
      it { should_not detemine_as_secure_request('OTHERS' => 'ENV') }
    end
  end

  let :env do
    {
      'REQUEST_METHOD'             => 'GET',
      'HTTP_CONNECTION'            => 'Upgrade',
      'HTTP_UPGRADE'               => 'websocket',
      'HTTP_ORIGIN'                => 'http://www.example.com',
      'HTTP_SEC_WEBSOCKET_KEY'     => key,
      'HTTP_SEC_WEBSOCKET_VERSION' => '13',
      'rack.hijack'                => proc {},
      'rack.hijack_io'             => tcp_socket
    }
  end

  let(:request) { Rack::MockRequest.env_for('/', env) }
  let(:tcp_socket) { double(TCPSocket) }
  let(:event_loop) { double(Tamashii::Server::Connection::StreamEventLoop) }
  let(:key) { '2vBVWg4Qyk3ZoM/5d3QD9Q==' }

  subject { Tamashii::Server::Connection::ClientSocket.new(env, event_loop) }

  before do
    allow(event_loop).to receive(:attach)
    allow(tcp_socket).to receive(:write_nonblock) { |message| @bytes = message.bytes.to_a }
  end
end