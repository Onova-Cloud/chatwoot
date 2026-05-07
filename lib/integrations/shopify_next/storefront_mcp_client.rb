class Integrations::ShopifyNext::StorefrontMcpClient
  AGENT_PROFILE = 'https://shopify.dev/ucp/agent-profiles/examples/2026-04-08/valid-with-capabilities.json'.freeze
  UCP_TOOLS = %w[search_catalog lookup_catalog get_product].freeze

  def initialize(hook)
    @hook = hook
  end

  def call_tool(name, arguments = {})
    endpoint = UCP_TOOLS.include?(name.to_s) ? ucp_endpoint : mcp_endpoint
    perform_request(endpoint, name, build_arguments(name, arguments))
  end

  private

  def perform_request(endpoint, name, arguments)
    uri = URI(endpoint)
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = {
      jsonrpc: '2.0',
      method: 'tools/call',
      id: SecureRandom.uuid,
      params: {
        name: name,
        arguments: arguments
      }
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, read_timeout: 30, open_timeout: 10) do |http|
      http.request(request)
    end

    raise "Shopify Storefront MCP request failed with status #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    parse_response(response.body)
  end

  def parse_response(body)
    parsed = JSON.parse(body)
    raise "Shopify Storefront MCP error: #{parsed['error'].to_json}" if parsed['error'].present?

    parsed['result'] || parsed
  end

  def build_arguments(name, arguments)
    return arguments unless UCP_TOOLS.include?(name.to_s)

    {
      meta: {
        'ucp-agent': {
          profile: AGENT_PROFILE
        }
      },
      catalog: arguments
    }
  end

  def mcp_endpoint
    "https://#{@hook.reference_id}/api/mcp"
  end

  def ucp_endpoint
    "https://#{@hook.reference_id}/api/ucp/mcp"
  end
end
