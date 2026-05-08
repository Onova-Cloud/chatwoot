require 'rails_helper'

RSpec.describe Captain::Tools::ShopifyUpdateCartTool do
  let(:assistant) { create(:captain_assistant) }
  let(:tool) { described_class.new(assistant) }
  let(:client) { instance_double(Integrations::ShopifyNext::StorefrontMcpClient) }
  let(:tool_context) do
    OpenStruct.new(
      state: {
        conversation: {
          custom_attributes: {
            shopify_next: {
              cart_token: 'hWNBvAsj1cKppr025gxaLFEh?key=06493279'
            }
          }
        }
      }
    )
  end

  before do
    create(:integrations_hook, :shopify_next, account: assistant.account, settings: { update_cart_enabled: true })
    allow(Integrations::ShopifyNext::StorefrontMcpClient).to receive(:new).and_return(client)
    allow(client).to receive(:call_tool).and_return({ 'cart' => { 'id' => 'gid://shopify/Cart/123' } })
  end

  it 'adds product variants using the Storefront MCP update_cart schema' do
    result = tool.perform(
      tool_context,
      product_variant_id: 'gid://shopify/ProductVariant/42860410568910',
      quantity: 1
    )

    expect(client).to have_received(:call_tool).with(
      'update_cart',
      {
        cart_id: 'gid://shopify/Cart/hWNBvAsj1cKppr025gxaLFEh?key=06493279',
        add_items: [
          {
            product_variant_id: 'gid://shopify/ProductVariant/42860410568910',
            quantity: 1
          }
        ]
      }
    )
    expect(JSON.parse(result).dig('cart', 'id')).to eq('gid://shopify/Cart/123')
  end
end
