class OpenAiService
  def initialize(website)
    @website = website
  end

  def analyze
    response = OpenAI::Client.new.chat(
      parameters: {
        model: "gpt-4",
        messages: [
          {
            role: "system",
            content: "You are a commercial real estate technology expert. Analyze websites and provide descriptions and relevant category tags."
          },
          {
            role: "user",
            content: "Analyze this website and provide: 1) A brief description (max 200 words) 2) Relevant category tags from the following list: [YOUR_APPROVED_TAGS_HERE]. Website: #{@website}"
          }
        ]
      }
    )

    if response['choices'] && response['choices'][0] && response['choices'][0]['message']
      parse_response(response['choices'][0]['message']['content'])
    else
      { description: "Error analyzing website", tags: [] }
    end
  rescue => e
    Rails.logger.error("Error analyzing website: #{e.message}")
    { description: "Error analyzing website", tags: [] }
  end

  private

  def parse_response(content)
    description = content.match(/Description:(.*?)Tags:/m)&.[](1)&.strip
    tags = content.match(/Tags:(.*)/m)&.[](1)&.strip&.split(',')&.map(&:strip)

    {
      description: description || "No description generated",
      tags: tags || []
    }
  end
end
