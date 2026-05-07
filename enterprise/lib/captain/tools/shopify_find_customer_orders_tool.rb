class Captain::Tools::ShopifyFindCustomerOrdersTool < Captain::Tools::ShopifyNext::BaseTool
  description 'Find recent Shopify orders for the current customer using contact email or phone'
  param :email, type: 'string', desc: 'Customer email. Leave blank to use the Chatwoot contact email', required: false
  param :phone, type: 'string', desc: 'Customer phone. Leave blank to use the Chatwoot contact phone', required: false
  param :order_query, type: 'string', desc: 'Optional Shopify order search query', required: false

  def perform(tool_context, email: nil, phone: nil, order_query: nil)
    email = email.presence || contact_email(tool_context.state)
    phone = phone.presence || contact_phone(tool_context.state)

    call_admin_tool do |client|
      client.find_customer_orders(email: email, phone: phone, order_query: order_query)
    end
  end
end
