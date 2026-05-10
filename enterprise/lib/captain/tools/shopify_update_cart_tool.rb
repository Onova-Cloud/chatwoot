class Captain::Tools::ShopifyUpdateCartTool < Captain::Tools::ShopifyNext::BaseTool
  description(
    'Add one merchandise line to a Shopify cart. If the browser cart is not writable from the server, returns a browser action payload'
  )
  param :product_variant_id, type: 'string', desc: 'Shopify product variant GID to add'
  param :quantity, type: 'integer', desc: 'Quantity for the cart line'
  param :cart_id, type: 'string', desc: 'Shopify cart GID. Leave blank to use conversation context or create a cart', required: false

  def perform(tool_context, product_variant_id:, quantity:, cart_id: nil)
    return 'Shopify cart updates are disabled for this account' unless update_cart_enabled?

    cart_id = cart_id.presence || context_cart_id(tool_context.state)
    return missing_writable_cart_message(tool_context.state, product_variant_id, quantity) if cart_id.blank?

    arguments = {
      cart_id: cart_id,
      add_items: [
        {
          product_variant_id: product_variant_id,
          quantity: quantity
        }
      ]
    }

    call_storefront_tool('update_cart', arguments)
  end

  private

  def update_cart_enabled?
    (shopify_next_hook&.settings || {}).fetch('update_cart_enabled', false)
  end

  def missing_writable_cart_message(state, product_variant_id, quantity)
    snapshot = context_cart_snapshot(state)

    format_json(
      {
        status: 'browser_action_required',
        message: 'The current Shopify cart cannot be updated from the server yet. Ask the shopper to confirm the add-to-cart action.',
        action: {
          type: 'shopify_next_add_to_cart',
          bridge_method: 'addToCart',
          product_variant_id: product_variant_id,
          quantity: quantity
        },
        cart: snapshot.presence || {}
      }
    )
  end
end
