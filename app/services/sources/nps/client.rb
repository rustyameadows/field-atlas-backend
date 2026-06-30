require "json"
require "net/http"

module Sources
  module Nps
    class Client
      BASE_URL = "https://developer.nps.gov/api/v1"

      Response = Data.define(:status, :body, :headers) do
        def success?
          status.between?(200, 299)
        end
      end

      def initialize(api_key: ENV["NPS_API_KEY"], timeout: 5)
        @api_key = api_key
        @timeout = timeout
      end

      def get(path, params = {})
        raise MissingApiKey, "NPS_API_KEY is not set" if api_key.blank?

        uri = URI("#{BASE_URL}#{path}")
        uri.query = URI.encode_www_form(params.compact)
        request = Net::HTTP::Get.new(uri)
        request["X-Api-Key"] = api_key
        request["Accept"] = "application/json"

        raw_response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, open_timeout: timeout, read_timeout: timeout) do |http|
          http.request(request)
        end

        Response.new(
          status: raw_response.code.to_i,
          body: parse_body(raw_response.body),
          headers: raw_response.each_header.to_h
        )
      end

      private

      attr_reader :api_key, :timeout

      def parse_body(body)
        ::JSON.parse(body)
      rescue ::JSON::ParserError
        {}
      end
    end

    class MissingApiKey < StandardError; end
  end
end
