class Api::V1::Accounts::Integrations::ShopifyNextController < Api::V1::Accounts::BaseController
  before_action :fetch_hook, only: [:show, :destroy]

  def show
    render json: hook_payload(@hook)
  end

  def create
    hook = Current.account.hooks.find_or_initialize_by(app_id: 'shopify_next')
    assign_hook_attributes(hook)
    hook.save!

    render json: hook_payload(hook)
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def test
    hook = Current.account.hooks.find_by(app_id: 'shopify_next') || Current.account.hooks.new(app_id: 'shopify_next')
    assign_hook_attributes(hook)
    shop = Integrations::ShopifyNext::AdminClient.new(hook).shop.dig('data', 'shop')
    Integrations::ShopifyNext::StorefrontMcpClient.new(hook).call_tool('search_policies', { query: 'shipping' })

    render json: { shop: shop, storefront: { connected: true } }
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def destroy
    @hook.destroy!
    head :ok
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def fetch_hook
    @hook = Current.account.hooks.find_by!(app_id: 'shopify_next')
  end

  def assign_hook_attributes(hook)
    raise 'Admin API access token is required' if hook.new_record? && access_token_param.blank?

    hook.reference_id = normalized_shop_domain
    hook.status = 'enabled'
    hook.settings = settings_params(hook)
    hook.access_token = access_token_param.presence if access_token_param.present? || hook.new_record?
  end

  def settings_params(hook)
    settings = {
      api_version: params[:api_version].presence || Integrations::ShopifyNext::AdminClient::DEFAULT_API_VERSION,
      enabled_for_captain: ActiveModel::Type::Boolean.new.cast(params.fetch(:enabled_for_captain, true)),
      update_cart_enabled: ActiveModel::Type::Boolean.new.cast(params.fetch(:update_cart_enabled, false))
    }

    settings[:storefront_password] = storefront_password_param.presence || saved_storefront_password(hook)
    settings.compact
  end

  def saved_storefront_password(hook)
    hook.settings&.dig('storefront_password') || hook.settings&.dig(:storefront_password)
  end

  def normalized_shop_domain
    shop_domain = params.require(:shop_domain).to_s.strip.downcase
    raise 'Shop domain must be a myshopify.com domain' unless shop_domain.match?(/\A[a-z0-9][a-z0-9-]*\.myshopify\.com\z/)

    shop_domain
  end

  def access_token_param
    params[:access_token].to_s.strip
  end

  def storefront_password_param
    params[:storefront_password].to_s.strip
  end

  def hook_payload(hook)
    {
      id: hook.id,
      app_id: hook.app_id,
      status: hook.enabled?,
      account_id: hook.account_id,
      hook_type: hook.hook_type,
      reference_id: hook.reference_id,
      settings: sanitized_settings(hook)
    }
  end

  def sanitized_settings(hook)
    settings = hook.settings || {}
    settings.except('storefront_password', :storefront_password).merge(
      storefront_password_configured: settings['storefront_password'].present? || settings[:storefront_password].present?
    )
  end
end
