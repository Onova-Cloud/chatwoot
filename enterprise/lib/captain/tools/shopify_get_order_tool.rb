class Captain::Tools::ShopifyGetOrderTool < Captain::Tools::ShopifyNext::BaseTool
  description 'Get a Shopify order by order GID or order name, including line items and fulfillment tracking'
  param :identifier, type: 'string', desc: 'Shopify order GID or order name, for example #1001'

  def perform(_tool_context, identifier:)
    call_admin_tool { |client| client.get_order(identifier) }
  end
end
