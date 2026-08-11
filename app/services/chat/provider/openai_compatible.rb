# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module Chat
  # OpenAI-compatible streaming adapter (works with OpenAI, and with the
  # many providers that speak the same protocol: local models via
  # LM Studio / Ollama / vLLM, Together, Groq, OpenRouter, etc.).
  #
  # Configuration comes entirely from the environment — no keys in the
  # repo. Set these on the server / in the deploy environment:
  #
  #   RELAY_AI_PROVIDER=openai
  #   RELAY_AI_BASE_URL=https://api.openai.com/v1     (default)
  #   RELAY_AI_API_KEY=sk-...                          (required)
  #   RELAY_AI_MODEL=gpt-4o-mini                       (required)
  #   RELAY_AI_TEMPERATURE=0.7                         (optional)
  #
  # For a local model: RELAY_AI_BASE_URL=http://localhost:11434/v1 with
  # RELAY_AI_API_KEY=ollama and RELAY_AI_MODEL=llama3.2.
  #
  # Swapping in a real key is the only change needed: the demo adapter is
  # selected automatically until RELAY_AI_PROVIDER is set.
  class Provider::OpenAICompatible < Provider
    DEFAULT_BASE_URL = "https://api.openai.com/v1"

    def model_name
      ENV["RELAY_AI_MODEL"].presence || "openai-compatible (unconfigured)"
    end

    def stream(history)
      base_url = ENV["RELAY_AI_BASE_URL"].presence || DEFAULT_BASE_URL
      api_key = ENV["RELAY_AI_API_KEY"].to_s
      model = ENV["RELAY_AI_MODEL"].to_s

      raise Error, "RELAY_AI_API_KEY is not set" if api_key.empty?
      raise Error, "RELAY_AI_MODEL is not set" if model.empty?

      uri = URI.join(base_url, "chat/completions")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      http.open_timeout = 15
      http.read_timeout = 120

      body = {
        model: model,
        messages: history.map { |m| { role: m[:role], content: m[:content] } },
        stream: true
      }
      temperature = ENV["RELAY_AI_TEMPERATURE"]
      body[:temperature] = temperature.to_f if temperature.present?

      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{api_key}"
      request["Content-Type"] = "application/json"
      request.body = body.to_json

      full = +""
      http.request(request) do |response|
        unless response.is_a?(Net::HTTPSuccess)
          raise Error, "provider returned #{response.code}"
        end

        response.read_body do |chunk|
          chunk.split("\n").each do |line|
            line = line.strip
            next unless line.start_with?("data: ")

            payload = line[6..]
            next if payload == "[DONE]"

            begin
              parsed = JSON.parse(payload)
              delta = parsed.dig("choices", 0, "delta", "content")
            rescue JSON::ParserError
              next
            end
            next if delta.nil? || delta.empty?

            full << delta
            yield delta
          end
        end
      end

      full
    end
  end
end
