class Captain::Tools::ShopifyGetProductTool < Captain::Tools::ShopifyNext::BaseTool
  description 'Get detailed Shopify storefront product information, including variants and option selection context'
  param :id, type: 'string', desc: 'Shopify product or variant GID'
  param :context, type: 'string', desc: 'Optional buyer context or selected options summary', required: false

  def perform(_tool_context, id:, context: nil)
    call_storefront_tool('get_product', { id: id, context: context.presence && { intent: context } })
  end
end
