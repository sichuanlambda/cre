class MunicipalityDataService
  SYSTEM_PROMPT = <<~PROMPT
    You are a municipal data expert. For each city, generate realistic data including:
    1. Council members (3-5 members with names, positions)
    2. Election cycle information (next election date, cycle years)
    3. Development score (0-100) with justification

    Format the response as valid JSON matching this structure:
    {
      "council_members": [
        {"name": "Name", "position": "Position", "social_links": {"linkedin": "url", "twitter": "url"}}
      ],
      "election_cycle": {
        "next_election_date": "YYYY-MM-DD",
        "cycle_years": 4
      },
      "development_score": {
        "current_score": 85,
        "justification": "Brief explanation"
      }
    }
  PROMPT

  def self.generate_data_for_municipality(municipality)
    client = OpenAI::Client.new

    prompt = "Generate realistic municipal data for #{municipality.name}, #{municipality.state}, #{municipality.country}."

    response = client.chat(
      parameters: {
        model: "gpt-3.5-turbo",
        messages: [
          { role: "system", content: SYSTEM_PROMPT },
          { role: "user", content: prompt }
        ],
        temperature: 0.7
      }
    )

    JSON.parse(response.dig("choices", 0, "message", "content"))
  end
end
