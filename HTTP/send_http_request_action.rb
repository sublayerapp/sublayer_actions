class SendHTTPRequestAction < Sublayer::Actions::Base
  def initialize(url:, method:, headers: {}, params: {}, body: nil)
    @url = url
    @method = method.to_s.upcase
    @headers = headers
    @params = params
    @body = body
  end

  def call
    response = handle_request

    return response.body if response.success?

    raise "HTTP request failed with status code: #{response.code}, body: #{response.body}"
  rescue StandardError => e
    logger.error "Error sending HTTP request: #{e.message}"
    raise e
  end

  private

  def handle_request
    case @method
    when 'GET'
      Net::HTTP.get_response(URI(@url), @params, @headers)
    when 'POST'
      Net::HTTP.post(URI(@url), URI.encode_www_form(@params), @headers, @body)
    when 'PUT'
      Net::HTTP.put(URI(@url), @body, @headers)
    when 'PATCH'
      Net::HTTP.patch(URI(@url), @body, @headers)
    when 'DELETE'
      Net::HTTP.delete(URI(@url), @headers)
    else
      raise "Unsupported HTTP method: #{@method}"
    end
  end
end