class ChatsController < ApplicationController
  def show
    @document = Document.find(params[:document_id])
  end

  def ask
    @document = Document.find(params[:document_id])
    @question = params[:question]
    @answer = ChatCompletionService.new(@document).ask(@question)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.append(
          "chat-messages",
          partial: "chats/message",
          locals: { question: @question, answer: @answer }
        )
      end
    end
  end
end
