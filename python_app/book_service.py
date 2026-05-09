import requests
import os
import json
from concurrent.futures import ThreadPoolExecutor
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

class BookService:
    def __init__(self):
        pass

    def search_libgen(self, query):
        # Libgen search is currently disabled as it requires external library
        return []

    def search_internet_archive(self, query):
        try:
            search_query = f"title:({query}) AND mediatype:texts"
            url = "https://archive.org/advancedsearch.php"
            params = {
                'q': search_query,
                'fl[]': 'identifier,title,creator,date',
                'output': 'json',
                'rows': 15,
                'page': 1
            }
            response = requests.get(url, params=params, timeout=20, verify=False)
            if response.status_code == 200:
                data = response.json()
                docs = data.get('response', {}).get('docs', [])
                formatted = []
                for doc in docs:
                    item_id = doc.get('identifier')
                    if not item_id or not doc.get('title'): continue
                    
                    creator = doc.get('creator')
                    if isinstance(creator, list): creator = ", ".join(creator)
                    elif not creator: creator = 'Unknown'
                    
                    date_str = doc.get('date', '')
                    year = date_str[:4] if isinstance(date_str, str) and len(date_str) >= 4 else None
                    
                    formatted.append({
                        "source": "Internet Archive",
                        "id": item_id,
                        "title": doc.get('title'),
                        "author": creator,
                        "year": year,
                        "format": "EPUB/PDF",
                        "cover_url": f"https://archive.org/services/img/{item_id}",
                        "mirror": f"https://archive.org/details/{item_id}"
                    })
                return formatted
            return []
        except Exception as e:
            print(f"Error searching IA: {e}")
            return []

    def search_gutenberg(self, query):
        try:
            url = f"https://gutendex.com/books/?search={query}"
            response = requests.get(url, timeout=20, verify=False)
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
                url = f"https://archive.org/metadata/{book_id}"
                response = requests.get(url, timeout=10)
                if response.status_code == 200:
                    data = response.json()
                    files = data.get('files', [])
                    
                    pdf_file = next((f for f in files if f.get('name', '').lower().endswith('.pdf')), None)
                    epub_file = next((f for f in files if f.get('name', '').lower().endswith('.epub')), None)
                    
                    selected_file = pdf_file or epub_file
                    if selected_file:
                        return f"https://archive.org/download/{book_id}/{selected_file['name']}"
            except Exception as e:
                print(f"Error getting IA download link: {e}")
        
        return mirror
