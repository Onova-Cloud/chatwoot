require 'rails_helper'

RSpec.describe Integrations::ShopifyNext::AdminClient do
  let(:hook) { create(:integrations_hook, :shopify_next) }
  let(:client) { described_class.new(hook) }
  let(:http_response) { Net::HTTPOK.new('1.1', '200', 'OK') }
  let(:http) { instance_double(Net::HTTP) }
  let(:response_body) do
    {
      data: {
        orders: {
          edges: [
            {
              node: {
                id: 'gid://shopify/Order/123',
                legacyResourceId: '123',
                name: '#1001'
              }
            }
          ]
        }
      }
    }
  end

  before do
    allow(http_response).to receive(:body).and_return(response_body.to_json)
    allow(Net::HTTP).to receive(:start).and_yield(http)
    allow(http).to receive(:request).and_return(http_response)
  end

  it 'uses the Admin GraphQL endpoint and access token' do
    result = client.find_customer_orders(email: 'buyer@example.com')

    expect(http).to have_received(:request) do |request|
      expect(request.uri.to_s).to eq('https://test-store.myshopify.com/admin/api/2026-04/graphql.json')
      @request = request
    end
    request = @request
    body = JSON.parse(request.body)

    expect(request['X-Shopify-Access-Token']).to eq('shpat_test_token')
    expect(body.dig('variables', 'query')).to eq('email:buyer@example.com')
    expect(result.dig('orders', 0, 'admin_url')).to eq('https://test-store.myshopify.com/admin/orders/123')
  end
end
