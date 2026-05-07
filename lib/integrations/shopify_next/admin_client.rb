class Integrations::ShopifyNext::AdminClient
  DEFAULT_API_VERSION = '2026-04'.freeze
  MAX_ORDERS = 10

  def initialize(hook)
    @hook = hook
  end

  def shop
    graphql('{ shop { name myshopifyDomain primaryDomain { url } currencyCode } }')
  end

  def find_customer(email: nil, phone: nil, query: nil)
    search_query = query.presence || customer_query(email: email, phone: phone)
    return { 'customers' => [] } if search_query.blank?

    response = graphql(<<~GRAPHQL, { query: search_query })
      query($query: String!) {
        customers(first: 5, query: $query) {
          edges {
            node {
              id
              displayName
              email
              phone
              numberOfOrders
              amountSpent { amount currencyCode }
            }
          }
        }
      }
    GRAPHQL

    { 'customers' => nodes(response.dig('data', 'customers')) }
  end

  def find_customer_orders(email: nil, phone: nil, order_query: nil)
    query = order_query.presence || customer_order_query(email: email, phone: phone)
    return { 'orders' => [] } if query.blank?

    response = graphql(orders_query, { query: query, first: MAX_ORDERS })
    { 'orders' => format_orders(nodes(response.dig('data', 'orders'))) }
  end

  def get_order(identifier)
    return { 'order' => nil } if identifier.blank?

    identifier = identifier.to_s.strip
    if identifier.start_with?('gid://shopify/Order/')
      response = graphql(order_by_id_query, { id: identifier })
      return { 'order' => format_order(response.dig('data', 'order')) }
    end

    response = graphql(orders_query, { query: "name:#{identifier}", first: 1 })
    { 'order' => format_order(nodes(response.dig('data', 'orders')).first) }
  end

  def graphql(query, variables = {})
    response = perform_request(query, variables)
    body = JSON.parse(response.body)
    raise "Shopify Admin GraphQL error: #{body['errors'].to_json}" if body['errors'].present?

    body
  end

  private

  def perform_request(query, variables)
    uri = URI("https://#{@hook.reference_id}/admin/api/#{api_version}/graphql.json")
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request['X-Shopify-Access-Token'] = @hook.access_token
    request.body = { query: query, variables: variables }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, read_timeout: 30, open_timeout: 10) do |http|
      http.request(request)
    end

    raise "Shopify Admin request failed with status #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    response
  end

  def api_version
    @hook.settings&.dig('api_version').presence || DEFAULT_API_VERSION
  end

  def customer_query(email:, phone:)
    [email.presence && "email:#{email}", phone.presence && "phone:#{phone}"].compact.join(' OR ')
  end

  def customer_order_query(email:, phone:)
    [email.presence && "email:#{email}", phone.presence && "phone:#{phone}"].compact.join(' OR ')
  end

  def nodes(connection)
    connection&.dig('edges')&.map { |edge| edge['node'] } || []
  end

  def format_orders(orders)
    orders.map { |order| format_order(order) }
  end

  def format_order(order)
    return nil if order.blank?

    order.merge(
      'admin_url' => "https://#{@hook.reference_id}/admin/orders/#{order['legacyResourceId'] || order['id'].to_s.split('/').last}"
    )
  end

  def orders_query
    <<~GRAPHQL
      query($query: String!, $first: Int!) {
        orders(first: $first, reverse: true, query: $query) {
          edges {
            node {
              id
              legacyResourceId
              name
              email
              createdAt
              displayFinancialStatus
              displayFulfillmentStatus
              totalPriceSet { shopMoney { amount currencyCode } }
              customer { id displayName email phone }
              fulfillments(first: 5) {
                status
                trackingInfo { number url company }
              }
              lineItems(first: 20) {
                edges {
                  node {
                    title
                    quantity
                    sku
                    variant { id title sku }
                    originalUnitPriceSet { shopMoney { amount currencyCode } }
                  }
                }
              }
            }
          }
        }
      }
    GRAPHQL
  end

  def order_by_id_query
    <<~GRAPHQL
      query($id: ID!) {
        order(id: $id) {
          id
          legacyResourceId
          name
          email
          createdAt
          displayFinancialStatus
          displayFulfillmentStatus
          totalPriceSet { shopMoney { amount currencyCode } }
          customer { id displayName email phone }
          fulfillments(first: 5) {
            status
            trackingInfo { number url company }
          }
          lineItems(first: 50) {
            edges {
              node {
                title
                quantity
                sku
                variant { id title sku }
                originalUnitPriceSet { shopMoney { amount currencyCode } }
              }
            }
          }
        }
      }
    GRAPHQL
  end
end
