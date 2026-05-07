class Captain::Tools::ShopifySearchCatalogTool < Captain::Tools::ShopifyNext::BaseTool
  description 'Search the Shopify storefront catalog for products that match a customer request'
  param :query, type: 'string', desc: 'Free-text product search query'
  param :context, type: 'string', desc: 'Optional buyer intent, country, language, or preference context', required: false

  def perform(_tool_context, query:, context: nil)
    call_storefront_tool('search_catalog', { query: query, context: context.presence && { intent: context } })
  end
end
