class Captain::Tools::ShopifyLookupCatalogTool < Captain::Tools::ShopifyNext::BaseTool
  description 'Retrieve Shopify products or variants by their Shopify GID identifiers'
  param :ids, type: 'string', desc: 'Comma-separated Shopify product or variant GIDs, up to 10'
  param :context, type: 'string', desc: 'Optional buyer context for localization or relevance', required: false

  def perform(_tool_context, ids:, context: nil)
    call_storefront_tool('lookup_catalog', { ids: ids.to_s.split(',').map(&:strip).reject(&:blank?).first(10), context: context.presence && { intent: context } })
  end
end
