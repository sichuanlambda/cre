require 'net/http'
require 'uri'
require 'nokogiri'
require 'csv'

class AnalyzerController < ApplicationController
  CATEGORIES = [
    'Commercial Real Estate', 'Valuation', 'Risk Management', 'CRM', 'Broker Tools',
    'Property Management', 'Real Estate Portfolio', 'Space Optimization', 'Listing Services',
    'Artificial Intelligence', 'Architecture', 'Site Selection', 'Advisory', 'Finance',
    'Market Insights', 'News', 'Events', 'Transactions', 'Real Estate', 'Networking',
    'Collaboration', 'Marketing', 'Real Estate Investment', 'Market Analysis',
    'Data & Analytics', 'Real Estate Data', 'Analytics', 'Due Diligence', 'Investments',
    'Transaction Management', 'EV Sharing', 'Mobility Solutions', 'Venture Capital',
    'PropTech', '3D Modeling', 'Real Estate Visualization',
    'Process Intelligence', 'Operations', 'Data Analysis', 'Crowdfunding',
    'Diversification', 'Sustainability', 'ESG Management', 'Inspections', 'Maintenance',
    'Construction & Development', 'Construction', 'Real Estate Owners', 'Tenant Experience','Prospecting'
  ]

  def analyze
    @website = params[:website]
    @website = "https://#{@website}" unless @website.start_with?('http://', 'https://')

    begin
      uri = URI.parse(@website)
      response = Net::HTTP.get_response(uri)

      # Parse HTML and extract text
      doc = Nokogiri::HTML(response.body)
      # Remove script and style elements
      doc.css('script, style').remove
      # Get text content
      text_content = doc.text.strip.gsub(/\s+/, ' ')[0...1000] # First 1000 chars for API efficiency

      @analysis = {
        status: response.code,
        content_length: response.body.length,
        title: doc.at_css('title')&.text,
        description: doc.at_css('meta[name="description"]')&.[]('content'),
        categories: analyze_with_llm(text_content)
      }
    rescue => e
      @error = "Error analyzing website: #{e.message}"
    end

    respond_to do |format|
      format.turbo_stream
    end
  end

  def batch_analyze
    @websites = params[:websites].to_s.split(/[\n,]/).map(&:strip).reject(&:empty?)

    @results = []
    @websites.each do |website|
      website = "https://#{website}" unless website.start_with?('http://', 'https://')

      begin
        uri = URI.parse(website)
        response = Net::HTTP.get_response(uri)
        doc = Nokogiri::HTML(response.body)
        doc.css('script, style').remove
        text_content = doc.text.strip.gsub(/\s+/, ' ')[0...1000]

        categories = analyze_with_llm(text_content)
        @results << {
          website: website,
          categories: categories,
          status: response.code
        }

        sleep 1 # Rate limiting
      rescue => e
        @results << {
          website: website,
          categories: [],
          error: "Error: #{e.message}",
          status: nil
        }
      end
    end

    respond_to do |format|
      format.turbo_stream
      format.csv do
        csv_data = CSV.generate(headers: true) do |csv|
          csv << ['Website', 'Categories', 'Status']
          @results.each do |result|
            csv << [
              result[:website],
              result[:error] || result[:categories].join('; '),
              result[:status]
            ]
          end
        end
        send_data csv_data, filename: "website_analysis_#{Time.current.to_i}.csv"
      end
    end
  end

  private

  def analyze_with_llm(content)
    client = OpenAI::Client.new

    prompt = <<~PROMPT
      You are a PropTech and Real Estate industry expert. Analyze this website content and categorize it into the most relevant categories from this list:
      #{CATEGORIES.join('; ')}

      Website content:
      #{content}

      Instructions:
      1. Return between 1-5 most relevant categories as a semicolon-separated list
      2. Only use categories from the provided list
      3. Focus on the main purpose/offering of the website
      4. If the content is unclear, prioritize categories that best match any real estate or property technology elements present
      5. Format your response exactly like this example: "Category 1; Category 2; Category 3"

      Return only the matching categories as a semicolon-separated list, nothing else.
    PROMPT

    response = client.chat(
      parameters: {
        model: "gpt-3.5-turbo",
        messages: [{ role: "user", content: prompt }],
        temperature: 0.3,
        max_tokens: 150
      }
    )

    # Split by semicolon and clean up any whitespace
    response.dig("choices", 0, "message", "content").split(';').map(&:strip)
  rescue => e
    ["Error categorizing: #{e.message}"]
  end
end
