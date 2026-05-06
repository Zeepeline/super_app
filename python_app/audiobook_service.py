import os
import asyncio
try:
    import edge_tts
except ImportError:
    edge_tts = None

try:
    import fitz  # PyMuPDF
except ImportError:
    fitz = None

class AudiobookService:
    def __init__(self):
        self.output_dir = os.path.join(os.path.expanduser('~'), 'Documents', 'SoundWave', 'Audiobooks')
        os.makedirs(self.output_dir, exist_ok=True)

    def get_pdf_metadata(self, pdf_path):
        """Returns page count and basic info from PDF"""
        if not fitz:
            return {"error": "PyMuPDF not installed"}
        
        try:
            doc = fitz.open(pdf_path)
            meta = {
                "page_count": doc.page_count,
                "title": doc.metadata.get("title") or os.path.basename(pdf_path),
                "author": doc.metadata.get("author") or "Unknown"
            }
            doc.close()
            return meta
        except Exception as e:
            return {"error": str(e)}

    def extract_text(self, pdf_path, page_num):
        """Extracts text from a specific page of PDF"""
        if not fitz:
            return "Library PyMuPDF tidak ditemukan."
            
        try:
            doc = fitz.open(pdf_path)
            if page_num < 0 or page_num >= doc.page_count:
                return ""
            
            page = doc.load_page(page_num)
            text = page.get_text()
            doc.close()
            return text.strip()
        except Exception as e:
            return f"Error extracting text: {e}"

    async def generate_speech(self, text, output_filename, voice="id-ID-ArdiNeural"):
        """Converts text to speech using Edge-TTS"""
        if not edge_tts:
            print("AudiobookService: edge_tts library not found.")
            return None
        if not text:
            return None
            
        output_path = os.path.join(self.output_dir, output_filename)
        
        # Determine voice based on text language (simple heuristic or use provided)
        # default id-ID-ArdiNeural or en-US-GuyNeural
        
        communicate = edge_tts.Communicate(text, voice)
        await communicate.save(output_path)
        return output_path

    def process_page_sync(self, text, filename, voice="id-ID-ArdiNeural"):
        """Wrapper for async speech generation"""
        try:
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            result = loop.run_until_complete(self.generate_speech(text, filename, voice))
            loop.close()
            return result
        except Exception as e:
            print(f"AudiobookService: TTS Error: {e}")
            return None
