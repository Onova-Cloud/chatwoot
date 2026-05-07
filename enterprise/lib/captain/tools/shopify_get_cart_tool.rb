class Captain::Tools::ShopifyGetCartTool < Captain::Tools::ShopifyNext::BaseTool
  description 'Get the current Shopify cart contents when a cart ID is available'
  param :cart_id, type: 'string', desc: 'Shopify cart GID. Leave blank to use the cart ID from conversation context', required: false

  def perform(tool_context, cart_id: nil)
    cart_id = cart_id.presence || context_cart_id(tool_context.state)
    return 'No Shopify cart ID is available in the conversation context' if cart_id.blank?

    call_storefront_tool('get_cart', { cart_id: cart_id })
  end
end
