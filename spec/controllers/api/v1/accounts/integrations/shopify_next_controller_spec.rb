require 'rails_helper'

RSpec.describe 'Shopify Next Integration API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:shop_domain) { 'test-store.myshopify.com' }
  let(:access_token) { 'shpat_test_token' }

  describe 'POST /api/v1/accounts/:account_id/integrations/shopify_next' do
    it 'creates a Shopify Next hook' do
      post "/api/v1/accounts/#{account.id}/integrations/shopify_next",
           params: { shop_domain: shop_domain, access_token: access_token, storefront_password: 'open-sesame', update_cart_enabled: true },
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:ok)
      hook = account.hooks.find_by(app_id: 'shopify_next')
      expect(hook.reference_id).to eq(shop_domain)
      expect(hook.access_token).to eq(access_token)
      expect(hook.settings['update_cart_enabled']).to be true
      expect(hook.settings['storefront_password']).to eq('open-sesame')
      expect(response.parsed_body.dig('settings', 'storefront_password')).to be_nil
      expect(response.parsed_body.dig('settings', 'storefront_password_configured')).to be true
    end

    it 'keeps saved secrets when blank values are submitted' do
      hook = create(:integrations_hook, :shopify_next, account: account, access_token: 'saved_token',
                                                          settings: { storefront_password: 'saved_password' })

      post "/api/v1/accounts/#{account.id}/integrations/shopify_next",
           params: { shop_domain: shop_domain, access_token: '', storefront_password: '', enabled_for_captain: false },
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:ok)
      expect(hook.reload.access_token).to eq('saved_token')
      expect(hook.settings['storefront_password']).to eq('saved_password')
      expect(hook.settings['enabled_for_captain']).to be false
      expect(response.parsed_body.dig('settings', 'storefront_password')).to be_nil
    end

    it 'rejects non-myshopify domains' do
      post "/api/v1/accounts/#{account.id}/integrations/shopify_next",
           params: { shop_domain: 'example.com', access_token: access_token },
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['error']).to eq('Shop domain must be a myshopify.com domain')
    end
  end

  describe 'POST /api/v1/accounts/:account_id/integrations/shopify_next/test' do
    let(:client) { instance_double(Integrations::ShopifyNext::AdminClient) }
    let(:storefront_client) { instance_double(Integrations::ShopifyNext::StorefrontMcpClient) }

    before do
      allow(Integrations::ShopifyNext::AdminClient).to receive(:new).and_return(client)
      allow(client).to receive(:shop).and_return({ 'data' => { 'shop' => { 'name' => 'Test Store' } } })
      allow(Integrations::ShopifyNext::StorefrontMcpClient).to receive(:new).and_return(storefront_client)
      allow(storefront_client).to receive(:call_tool).and_return({ 'ok' => true })
    end

    it 'tests the Admin GraphQL and Storefront MCP connections' do
      post "/api/v1/accounts/#{account.id}/integrations/shopify_next/test",
           params: { shop_domain: shop_domain, access_token: access_token, storefront_password: 'open-sesame' },
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig('shop', 'name')).to eq('Test Store')
      expect(response.parsed_body.dig('storefront', 'connected')).to be true
      expect(storefront_client).to have_received(:call_tool).with('search_policies', { query: 'shipping' })
    end
  end

  describe 'DELETE /api/v1/accounts/:account_id/integrations/shopify_next' do
    before do
      create(:integrations_hook, :shopify_next, account: account)
    end

    it 'deletes the Shopify Next hook' do
      expect do
        delete "/api/v1/accounts/#{account.id}/integrations/shopify_next",
               headers: admin.create_new_auth_token,
               as: :json
      end.to change { account.hooks.where(app_id: 'shopify_next').count }.by(-1)

      expect(response).to have_http_status(:ok)
    end
  end
end
