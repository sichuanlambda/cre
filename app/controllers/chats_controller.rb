class ChatsController < ApplicationController
  def show
    @document = Document.find(params[:document_id])
  end

  def ask
    @document = Document.find(params[:document_id])
    question = params[:question]

    response = ChatCompletionService.new(@document).ask(question)

    render json: { answer: response }
  end
end
