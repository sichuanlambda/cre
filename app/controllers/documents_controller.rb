class DocumentsController < ApplicationController
  def new
    @document = Document.new
    @documents = Document.order(created_at: :desc)
  end

  def create
    @document = Document.new(document_params)

    if @document.save
      DocumentProcessingService.process(@document)
      redirect_to document_chat_path(@document), notice: 'Document was successfully uploaded.'
    else
      @documents = Document.order(created_at: :desc)
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @document = Document.find(params[:id])
    @document.destroy

    redirect_to new_document_path, notice: 'Document was successfully deleted.'
  end

  private

  def document_params
    params.require(:document).permit(:name, :document_type, :file)
  end
end
