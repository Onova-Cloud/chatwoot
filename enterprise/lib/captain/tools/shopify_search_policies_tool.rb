class Captain::Tools::ShopifySearchPoliciesTool < Captain::Tools::ShopifyNext::BaseTool
  description 'Search Shopify store policies and FAQs for shipping, returns, payment, and service questions'
  param :query, type: 'string', desc: 'Policy or FAQ question to search'
  param :context, type: 'string', desc: 'Optional current product or cart context', required: false

  def perform(_tool_context, query:, context: nil)
    call_storefront_tool('search_shop_policies_and_faqs', { query: query, context: context })
  end
end
