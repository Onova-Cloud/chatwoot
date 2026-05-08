class Captain::Tools::ShopifyUpdateCartTool < Captain::Tools::ShopifyNext::BaseTool
  description 'Update a Shopify cart by adding or changing one merchandise line. Quantity 0 removes an existing line'
  param :product_variant_id, type: 'string', desc: 'Shopify product variant GID to add'
  param :quantity, type: 'integer', desc: 'Quantity for the cart line'
  param :cart_id, type: 'string', desc: 'Shopify cart GID. Leave blank to use conversation context or create a cart', required: false
  param :line_item_id, type: 'string', desc: 'Existing Shopify cart line GID when updating/removing a line', required: false

  def perform(tool_context, product_variant_id:, quantity:, cart_id: nil, line_item_id: nil)
    return 'Shopify cart updates are disabled for this account' unless update_cart_enabled?

    cart_id = cart_id.presence || context_cart_id(tool_context.state)
    arguments = {
      cart_id: cart_id,
      add_items: [
        {
          product_variant_id: product_variant_id,
          quantity: quantity
        }
      ]
    }
    arguments[:update_items] = [{ id: line_item_id, quantity: quantity }] if line_item_id.present?

    call_storefront_tool('update_cart', arguments)
  end

  private

  def update_cart_enabled?
    (shopify_next_hook&.settings || {}).fetch('update_cart_enabled', false)
  end
end
