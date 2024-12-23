class DocumentProcessingService
  include HTTParty
  base_uri 'http://localhost:5000'

  def self.process(document)
    # Create temp file from ActiveStorage blob
    temp_file = Tempfile.new(['document', File.extname(document.file.filename.to_s)])
    temp_file.binmode
    temp_file.write(document.file.download)
    temp_file.rewind

    # Send to Flask service
    response = HTTParty.post(
      "#{base_uri}/process",
      multipart: true,
      body: {
        file: File.open(temp_file.path),
        document_id: document.id
      }
    )

    if response.success?
      document.update(processing_status: 'completed')
    else
      document.update(processing_status: 'failed')
      Rails.logger.error "Document processing failed: #{response.body}"
    end
  ensure
    temp_file.close
    temp_file.unlink
  end
end
