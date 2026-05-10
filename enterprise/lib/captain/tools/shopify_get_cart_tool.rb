class Captain::Tools::ShopifyGetCartTool < Captain::Tools::ShopifyNext::BaseTool
  description 'Get the current Shopify cart contents from Storefront MCP or the latest storefront cart snapshot'
  param :cart_id, type: 'string', desc: 'Shopify cart GID. Leave blank to use the cart ID from conversation context', required: false

  def perform(tool_context, cart_id: nil)
    cart_id = cart_id.presence || context_cart_id(tool_context.state)
    return format_json(cart_snapshot_response(tool_context.state)) if cart_id.blank?

    call_storefront_tool('get_cart', { cart_id: cart_id })
  end

  private

  def cart_snapshot_response(state)
    snapshot = context_cart_snapshot(state)
    return { status: 'missing_cart_context', message: 'No Shopify cart context is available yet' } if snapshot.blank?

    {
      status: 'storefront_cart_snapshot',
      source: 'shopify_ajax_cart',
      cart: snapshot
    }
  end
end
