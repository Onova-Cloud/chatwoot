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
end
