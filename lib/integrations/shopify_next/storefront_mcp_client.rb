require 'nokogiri'

class Integrations::ShopifyNext::StorefrontMcpClient
  AGENT_PROFILE = 'https://shopify.dev/ucp/agent-profiles/examples/2026-04-08/valid-with-capabilities.json'.freeze
  UCP_TOOLS = %w[search_catalog lookup_catalog get_product].freeze
  PASSWORD_PROTECTED_ERROR = 'Storefront is password protected or the stored password is invalid'.freeze

  def initialize(hook)
    @hook = hook
    @cookies = {}
  end

  def call_tool(name, arguments = {})
    endpoint = UCP_TOOLS.include?(name.to_s) ? ucp_endpoint : mcp_endpoint
    perform_request(endpoint, name, build_arguments(name, arguments))
  end

  private

  def perform_request(endpoint, name, arguments)
    uri = URI(endpoint)
    authenticate_storefront(uri) if storefront_password.present?
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    apply_cookies(request)
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

    store_cookies(response)
    raise PASSWORD_PROTECTED_ERROR if response.is_a?(Net::HTTPRedirection)
    raise "Shopify Storefront MCP request failed with status #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    parse_response(response.body)
  end

  def authenticate_storefront(uri)
    password_uri = URI("#{uri.scheme}://#{uri.host}/password")
    password_response = get(password_uri)
    password_form_uri, password_params = password_form(password_uri, password_response.body)
    password_params['password'] = storefront_password

    response = post_form(password_form_uri, password_params)
    store_cookies(response)
  end

  def get(uri)
    request = Net::HTTP::Get.new(uri)
    apply_cookies(request)
    perform_http_request(uri, request)
  end

  def post_form(uri, params)
    request = Net::HTTP::Post.new(uri)
    request.set_form_data(params)
    apply_cookies(request)
    perform_http_request(uri, request)
  end

  def perform_http_request(uri, request)
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https', read_timeout: 30, open_timeout: 10) do |http|
      http.request(request)
    end
    store_cookies(response)
    response
  end

  def password_form(password_uri, body)
    document = Nokogiri::HTML(body)
    form = document.at_css('form[action*="/password"]') || document.at_css('form')
    action = form&.[]('action').presence || '/password'
    params = {}
    form&.css('input[type="hidden"][name]').to_a.each do |input|
      params[input['name']] = input['value'].to_s
    end

    [URI.join(password_uri, action), params]
  end

  def store_cookies(response)
    response.get_fields('Set-Cookie')&.each do |cookie|
      key, value = cookie.split(';').first.to_s.split('=', 2)
      @cookies[key] = value if key.present? && value.present?
    end
  end

  def apply_cookies(request)
    return if @cookies.blank?

    request['Cookie'] = @cookies.map { |key, value| "#{key}=#{value}" }.join('; ')
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

  def storefront_password
    @hook.settings&.dig('storefront_password').to_s.presence
  end
end
