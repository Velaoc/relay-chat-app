# frozen_string_literal: true

# Provider abstraction for the chat app's AI backend.
#
# An adapter takes the conversation history (oldest first) and yields
# reply chunks as they arrive, so the transport can be swapped without
# touching controllers or views. The demo adapter ships with the app so
# the whole product works out of the box with zero configuration; the
# OpenAI-compatible adapter is wired to environment variables and is the
# only file that changes when a real provider key is added.
module Chat
  class Provider
    class Error < StandardError; end

    class << self
      # Build the adapter from configuration. RELAY_AI_PROVIDER selects the
      # implementation; anything other than "demo" (and every missing or
      # misconfigured real provider) degrades to the demo adapter so the app
      # always boots and always answers.
      def build
        provider = ENV["RELAY_AI_PROVIDER"].to_s.strip.downcase
        case provider
        when "openai", "openai_compatible", "anthropic"
          OpenAICompatible.new
        else
          Demo.new
        end
      end
    end

    # history: array of {role:, content:} oldest first.
    # Yields String chunks; returns the full reply.
    def stream(history)
      raise NotImplementedError
    end

    def model_name
      raise NotImplementedError
    end
  end
end
