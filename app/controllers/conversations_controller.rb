class ConversationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_conversation, only: %i[show destroy]

  def index
    @conversations = current_user.conversations.ordered
    @conversation = @conversations.first
    render :index
  end

  def create
    @conversation = current_user.conversations.create!(title: "New chat")
    redirect_to conversation_path(@conversation)
  end

  def show
    @conversations = current_user.conversations.ordered
    @messages = @conversation.messages.ordered
    render :index
  end

  def destroy
    @conversation.destroy!
    redirect_to conversations_path, notice: "Conversation deleted."
  end

  private

  def set_conversation
    @conversation = current_user.conversations.find(params[:id])
  end
end
