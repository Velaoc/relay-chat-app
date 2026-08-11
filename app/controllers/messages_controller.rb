class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_conversation

  # POST /conversations/:conversation_id/messages
  # Saves the user message, then streams the assistant reply as
  # Server-Sent Events so the UI shows tokens arriving one by one.
  def create
    @user_message = @conversation.messages.build(
      role: Message::ROLE_USER,
      content: params.require(:message).require(:content).to_s.strip
    )

    unless @user_message.save
      return redirect_to conversation_path(@conversation),
        alert: "Message can't be blank."
    end

    history = @conversation.messages.ordered.map { |m| { role: m.role, content: m.content } }

    response.headers["Content-Type"] = "text/event-stream"
    response.headers["Cache-Control"] = "no-cache"
    response.headers["X-Accel-Buffering"] = "no"

    self.response_body = build_stream(history)
  end

  private

  def set_conversation
    @conversation = current_user.conversations.find(params[:conversation_id])
  end

  # Returns an Enumerator that persists the assistant message only after
  # the full reply has streamed, so a partial reply never lands in the DB.
  def build_stream(history)
    Enumerator.new do |yielder|
      yielder << "event: user_message\ndata: #{@user_message.to_json}\n\n"

      assistant = @conversation.messages.build(role: Message::ROLE_ASSISTANT)
      full = +""
      provider = Chat::Provider.build

      begin
        provider.stream(history) do |chunk|
          full << chunk
          yielder << "data: #{chunk.to_json}\n\n"
        end
      rescue Chat::Provider::Error => e
        full = "Sorry, the AI provider errored: #{e.message}"
        yielder << "data: #{full.to_json}\n\n"
      end

      assistant.content = full
      assistant.save!
      yielder << "event: done\ndata: #{assistant.id}\n\n"
    rescue StandardError => e
      yielder << "event: error\ndata: #{e.message.to_json}\n\n"
    ensure
      yielder.close
    end
  end
end
