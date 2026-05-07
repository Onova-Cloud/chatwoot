class Captain::Tools::ShopifyFindCustomerTool < Captain::Tools::ShopifyNext::BaseTool
  description 'Find a Shopify customer profile using email, phone, or a Shopify customer search query'
  param :email, type: 'string', desc: 'Customer email. Leave blank to use the Chatwoot contact email', required: false
  param :phone, type: 'string', desc: 'Customer phone. Leave blank to use the Chatwoot contact phone', required: false
  param :query, type: 'string', desc: 'Optional Shopify customer search query', required: false

  def perform(tool_context, email: nil, phone: nil, query: nil)
    email = email.presence || contact_email(tool_context.state)
    phone = phone.presence || contact_phone(tool_context.state)

    call_admin_tool { |client| client.find_customer(email: email, phone: phone, query: query) }
  end
end
