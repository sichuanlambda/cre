class DocumentsController < ApplicationController
  def new
    @document = Document.new
  end

  def create
    @document = Document.new(document_params)

    if @document.save
      DocumentProcessingService.process(@document)
      redirect_to document_chat_path(@document), notice: 'Document was successfully uploaded.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def document_params
    params.require(:document).permit(:name, :document_type, :file)
  end
end
