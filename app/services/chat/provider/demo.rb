# frozen_string_literal: true

module Chat
  # Demo adapter: returns a canned but context-aware reply, streamed in
  # word-sized chunks so the front end exercises the real streaming path.
  # No network, no credentials, works offline. Swap RELAY_AI_PROVIDER to a
  # real provider (see OpenAICompatible) and this file stops being used.
  class Provider::Demo < Provider
    RESPONSES = [
      "That's a good question. Here's the short version: it depends on what you're optimizing for, and I'd want a bit more context before committing to an answer.",
      "I can help with that. The cleanest approach is to break the problem into smaller pieces, solve each one, and check the result against your goal as you go.",
      "Interesting. My take: start with the smallest version that proves the idea works, then add complexity only when the simple version starts to hurt.",
      "Sure — here's what I'd do. First, pin down what success looks like. Then pick the boringest tool that gets you there. Then measure twice and cut once."
    ].freeze

    def model_name
      "relay-demo (canned replies)"
    end

    def stream(history)
      # Riff slightly on the last user message so the demo feels alive,
      # then stream a canned response word by word.
      last_user = history.reverse.find { |m| m[:role] == "user" }
      lead = if last_user && last_user[:content].present?
        "You asked: \"#{last_user[:content].truncate(80)}\". "
      else
        ""
      end
      reply = lead + RESPONSES.sample

      reply.split(/(\s+)/).each do |chunk|
        next if chunk.empty?

        yield chunk
      end
      reply
    end
  end
end
