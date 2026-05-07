require 'rails_helper'

RSpec.describe Captain::Tools::ShopifyFindCustomerOrdersTool do
  let(:assistant) { create(:captain_assistant) }
  let(:tool) { described_class.new(assistant) }
  let(:client) { instance_double(Integrations::ShopifyNext::AdminClient) }
  let(:tool_context) do
    OpenStruct.new(
      state: {
        contact: {
          email: 'buyer@example.com',
          phone_number: '+1234567890'
        }
      }
    )
  end

  before do
    create(:integrations_hook, :shopify_next, account: assistant.account)
    allow(Integrations::ShopifyNext::AdminClient).to receive(:new).and_return(client)
    allow(client).to receive(:find_customer_orders).and_return({ 'orders' => [{ 'name' => '#1001' }] })
  end

  it 'defaults to the Chatwoot contact email and phone' do
    result = tool.perform(tool_context)

    expect(client).to have_received(:find_customer_orders).with(email: 'buyer@example.com', phone: '+1234567890', order_query: nil)
    expect(JSON.parse(result).dig('orders', 0, 'name')).to eq('#1001')
  end
end
