require 'rails_helper'

RSpec.describe Integrations::ShopifyNext::StorefrontMcpClient do
  let(:hook) { create(:integrations_hook, :shopify_next) }
  let(:client) { described_class.new(hook) }
  let(:http_response) { Net::HTTPOK.new('1.1', '200', 'OK') }
  let(:http) { instance_double(Net::HTTP) }

  before do
    allow(http_response).to receive(:body).and_return({ result: { ok: true } }.to_json)
    allow(Net::HTTP).to receive(:start).and_yield(http)
    allow(http).to receive(:request).and_return(http_response)
  end

  it 'wraps UCP catalog arguments with the required agent profile' do
    client.call_tool('search_catalog', { query: 'coffee' })

    expect(http).to have_received(:request) do |request|
      expect(request.uri.to_s).to eq('https://test-store.myshopify.com/api/ucp/mcp')
      @request = request
    end
    request = @request
    body = JSON.parse(request.body)

    expect(body.dig('params', 'arguments', 'catalog', 'query')).to eq('coffee')
    expect(body.dig('params', 'arguments', 'meta', 'ucp-agent', 'profile')).to be_present
  end

  it 'calls the standard MCP endpoint for cart tools' do
    client.call_tool('get_cart', { cart_id: 'gid://shopify/Cart/123' })

    expect(http).to have_received(:request) do |request|
      expect(request.uri.to_s).to eq('https://test-store.myshopify.com/api/mcp')
    end
  end

  context 'with a storefront password' do
    let(:hook) do
      create(:integrations_hook, :shopify_next, settings: {
               api_version: '2026-04',
               enabled_for_captain: true,
               update_cart_enabled: false,
               storefront_password: 'open-sesame'
             })
    end
    let(:password_page_response) { Net::HTTPOK.new('1.1', '200', 'OK') }
    let(:password_submit_response) { Net::HTTPFound.new('1.1', '302', 'Found') }

    before do
      allow(password_page_response).to receive(:body).and_return(
        '<form action="/password" method="post"><input type="hidden" name="authenticity_token" value="secret" /></form>'
      )
      password_page_response.add_field('Set-Cookie', '_shopify_y=abc; path=/')
      allow(password_submit_response).to receive(:body).and_return('')
      password_submit_response.add_field('Set-Cookie', '_shopify_essential=def; path=/')
      allow(http).to receive(:request).and_return(password_page_response, password_submit_response, http_response)
    end

    it 'authenticates through the password page and sends cookies to MCP' do
      client.call_tool('search_policies', { query: 'returns' })

      expect(http).to have_received(:request).exactly(3).times
      requests = []
      expect(http).to have_received(:request).exactly(3).times do |request|
        requests << request
      end

      expect(requests.first).to be_a(Net::HTTP::Get)
      expect(requests.first.uri.to_s).to eq('https://test-store.myshopify.com/password')
      expect(requests.second.body).to include('authenticity_token=secret')
      expect(requests.second.body).to include('password=open-sesame')
      expect(requests.third['Cookie']).to include('_shopify_y=abc')
      expect(requests.third['Cookie']).to include('_shopify_essential=def')
      expect(requests.third.uri.to_s).to eq('https://test-store.myshopify.com/api/mcp')
    end
  end

  it 'raises a readable error when Shopify keeps redirecting to the password page' do
    redirect_response = Net::HTTPFound.new('1.1', '302', 'Found')
    allow(redirect_response).to receive(:body).and_return('')
    allow(http).to receive(:request).and_return(redirect_response)

    expect do
      client.call_tool('search_policies', { query: 'returns' })
    end.to raise_error(described_class::PASSWORD_PROTECTED_ERROR)
  end
end
