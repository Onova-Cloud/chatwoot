require 'rails_helper'

RSpec.describe Captain::Tools::ShopifyGetCartTool do
  let(:assistant) { create(:captain_assistant) }
  let(:tool) { described_class.new(assistant) }
  let(:client) { instance_double(Integrations::ShopifyNext::StorefrontMcpClient) }
  let(:tool_context) do
    OpenStruct.new(
      state: {
        conversation: {
          custom_attributes: {
            shopify_next: {
              cart_id: 'gid://shopify/Cart/123'
            }
          }
        }
      }
    )
  end

  before do
    create(:integrations_hook, :shopify_next, account: assistant.account)
    allow(Integrations::ShopifyNext::StorefrontMcpClient).to receive(:new).and_return(client)
    allow(client).to receive(:call_tool).and_return({ 'cart' => { 'id' => 'gid://shopify/Cart/123' } })
  end

  it 'uses the cart ID from conversation context' do
    result = tool.perform(tool_context)

    expect(client).to have_received(:call_tool).with('get_cart', { cart_id: 'gid://shopify/Cart/123' })
    expect(JSON.parse(result).dig('cart', 'id')).to eq('gid://shopify/Cart/123')
  end

  it 'normalizes raw Shopify cart tokens from conversation context' do
    tool_context.state[:conversation][:custom_attributes][:shopify_next][:cart_id] = 'hWNBvAsj1cKppr025gxaLFEh?key=06493279'

    tool.perform(tool_context)

    expect(client).to have_received(:call_tool).with(
      'get_cart',
      { cart_id: 'gid://shopify/Cart/hWNBvAsj1cKppr025gxaLFEh?key=06493279' }
    )
  end
end
