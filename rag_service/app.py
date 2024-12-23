from flask import Flask, request, jsonify
from langchain.embeddings import OpenAIEmbeddings
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.vectorstores import Chroma
from langchain.document_loaders import PyPDFLoader, TextLoader
from langchain.chat_models import ChatOpenAI
from langchain.chains import ConversationalRetrievalChain
import os
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)

# Initialize OpenAI and embedding models
embeddings = OpenAIEmbeddings()
llm = ChatOpenAI(temperature=0.7)

class DocumentProcessor:
    def __init__(self):
        self.text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=1000,
            chunk_overlap=200
        )
        
    def process_document(self, file_path, document_id):
        # Load and split document
        loader = PyPDFLoader(file_path) if file_path.endswith('.pdf') else TextLoader(file_path)
        documents = loader.load()
        texts = self.text_splitter.split_documents(documents)
        
        # Create and persist vector store
        vectorstore = Chroma.from_documents(
            documents=texts,
            embedding=embeddings,
            persist_directory=f"./storage/vectors/{document_id}"
        )
        vectorstore.persist()
        
        return {"status": "success", "chunks": len(texts)}

@app.route('/process', methods=['POST'])
def process_document():
    if 'file' not in request.files:
        return jsonify({"error": "No file provided"}), 400
        
    file = request.files['file']
    document_id = request.form.get('document_id')
    
    if not document_id:
        return jsonify({"error": "No document_id provided"}), 400
    
    # Save file temporarily
    temp_path = f"/tmp/{file.filename}"
    file.save(temp_path)
    
    try:
        processor = DocumentProcessor()
        result = processor.process_document(temp_path, document_id)
        return jsonify(result)
    finally:
        # Cleanup
        os.remove(temp_path)

@app.route('/ask', methods=['POST'])
def ask_question():
    data = request.json
    document_id = data.get('document_id')
    question = data.get('question')
    chat_history = data.get('chat_history', [])
    
    if not all([document_id, question]):
        return jsonify({"error": "Missing required parameters"}), 400
    
    try:
        # Load the persisted vectorstore
        vectorstore = Chroma(
            persist_directory=f"./storage/vectors/{document_id}",
            embedding_function=embeddings
        )
        
        # Create chain
        qa_chain = ConversationalRetrievalChain.from_llm(
            llm=llm,
            retriever=vectorstore.as_retriever(),
            return_source_documents=True
        )
        
        # Get response
        result = qa_chain({"question": question, "chat_history": chat_history})
        
        return jsonify({
            "answer": result["answer"],
            "sources": [doc.page_content for doc in result["source_documents"]]
        })
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(port=5000) 