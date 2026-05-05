import requests
from libgen_api import LibgenSearch
import internetarchive as ia
import os
import json
from concurrent.futures import ThreadPoolExecutor

class BookService:
    def __init__(self):
        self.libgen = LibgenSearch()

    def search_libgen(self, query):
        # mirrors = ["https://libgen.is", "https://libgen.rs", "https://libgen.st", "https://libgen.li"]
        try:
            results = self.libgen.search_title(query)
            if not results: return []
            formatted = []
            for r in results[:10]:
                # Libgen cover URL pattern (often requires a specific host)
                cover = ""
                if r.get("Descr"): # Sometimes description contains cover info or we use a placeholder
                    cover = f"https://libgen.is/covers/{r.get('Coverurl')}"
                
                formatted.append({
                    "source": "Libgen",
                    "id": r.get("ID"),
                    "title": r.get("Title"),
                    "author": r.get("Author"),
                    "format": r.get("Extension"),
                    "size": r.get("Size"),
                    "year": r.get("Year"),
                    "cover_url": cover,
                    "mirror": r.get("Mirror_1") or r.get("Mirror_2")
                })
            return formatted
        except:
            return []

    def search_internet_archive(self, query):
        try:
            search_query = f"title:({query}) AND mediatype:texts"
            results = ia.search_items(search_query)
            formatted = []
            count = 0
            for r in results:
                if count >= 15: break
                try:
                    item_id = r['identifier']
                    item = ia.get_item(item_id)
                    meta = item.metadata
                    if not meta.get('title'): continue
                    
                    formatted.append({
                        "source": "Internet Archive",
                        "id": item_id,
                        "title": meta.get('title'),
                        "author": meta.get('creator') or 'Unknown',
                        "year": meta.get('date'),
                        "format": "EPUB/PDF",
                        "cover_url": f"https://archive.org/services/img/{item_id}",
                        "mirror": f"https://archive.org/details/{item_id}"
                    })
                    count += 1
                except: continue
            return formatted
        except:
            return []

    def search_gutenberg(self, query):
        try:
            url = f"https://gutendex.com/books/?search={query}"
            response = requests.get(url, timeout=20)
            if response.status_code == 200:
                data = response.json()
                results = data.get("results", [])
                formatted = []
                for r in results[:15]:
                    b_id = str(r.get("id"))
                    formatted.append({
                        "source": "Project Gutenberg",
                        "id": b_id,
                        "title": r.get("title"),
                        "author": ", ".join([a.get("name") for a in r.get("authors", [])]),
                        "format": "EPUB/HTML",
                        "cover_url": f"https://www.gutenberg.org/cache/epub/{b_id}/pg{b_id}.cover.medium.jpg",
                        "mirror": r.get("formats", {}).get("text/html") or r.get("formats", {}).get("application/epub+zip")
                    })
                return formatted
            return []
        except:
            return []

    def search_all(self, query):
        all_results = []
        with ThreadPoolExecutor(max_workers=3) as executor:
            # f_libgen = executor.submit(self.search_libgen, query)
            f_ia = executor.submit(self.search_internet_archive, query)
            f_guten = executor.submit(self.search_gutenberg, query)
            
            # try: all_results.extend(f_libgen.result(timeout=45))
            # except: pass
            try: all_results.extend(f_ia.result(timeout=45))
            except: pass
            try: all_results.extend(f_guten.result(timeout=45))
            except: pass
            
        return all_results

    def get_download_link(self, source, book_id, mirror):
        if source == "Internet Archive":
            try:
                item = ia.get_item(book_id)
                # Look for PDF or EPUB files
                files = item.files
                pdf_file = next((f for f in files if f['name'].lower().endswith('.pdf')), None)
                epub_file = next((f for f in files if f['name'].lower().endswith('.epub')), None)
                
                selected_file = pdf_file or epub_file
                if selected_file:
                    # Construct direct download URL
                    return f"https://archive.org/download/{book_id}/{selected_file['name']}"
            except Exception as e:
                print(f"Error getting IA download link: {e}")
        
        return mirror
