class ChatCompletionService
  include HTTParty
  base_uri 'http://localhost:5000'

  def initialize(document)
    @document = document
  end

  def ask(question, chat_history = [])
    response = self.class.post(
      '/ask',
      body: {
        document_id: @document.id,
        question: question,
        chat_history: chat_history
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    if response.success?
      response_body = JSON.parse(response.body)
      response_body["answer"]
    else
      { error: "Failed to get response: #{response.body}" }
    end
  end
end
