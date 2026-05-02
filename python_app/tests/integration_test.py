"""
tests/integration_test.py — Integration tests for the RAG system.
Run with: python -m pytest tests/ or python tests/integration_test.py
"""

import os
import sys
import json

# Add parent dir to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def test_config():
    """Test config loads correctly."""
    import config
    assert config.CHROMA_DIR
    assert config.GEMINI_EMBEDDING_MODEL
    assert config.DEFAULT_TOP_K > 0
    print("✅ Config OK")


def test_stopwords():
    """Test stopword loading."""
    from modules.preprocessor import load_stopwords
    sw = load_stopwords()
    assert len(sw) > 10
    assert "yang" in sw
    assert "the" in sw
    print(f"✅ Stopwords OK ({len(sw)} words)")


def test_abbreviations():
    """Test abbreviation loading."""
    from modules.preprocessor import load_abbreviations
    abbrevs = load_abbreviations()
    assert len(abbrevs) > 10
    assert abbrevs.get("yg") == "yang"
    assert abbrevs.get("dgn") == "dengan"
    print(f"✅ Abbreviations OK ({len(abbrevs)} entries)")


def test_normalize():
    """Test text normalization."""
    from modules.preprocessor import normalize_text
    result = normalize_text("  HELLO   World  \n\n\n\nTest  ")
    assert "hello" in result
    assert "world" in result
    assert "test" in result
    # Should not have leading/trailing whitespace
    assert result == result.strip()
    print(f"✅ Normalize OK: '{result}'")


def test_expand_abbreviations():
    """Test abbreviation expansion."""
    from modules.preprocessor import expand_abbreviations
    result = expand_abbreviations("aku yg mau dgn kamu")
    assert "yang" in result
    assert "dengan" in result
    print(f"✅ Expand abbreviations OK: '{result}'")


def test_remove_stopwords():
    """Test stopword removal."""
    from modules.preprocessor import remove_stopwords
    result = remove_stopwords("saya suka lagu green day di library")
    # "green" and "day" should survive
    assert "green" in result
    assert "day" in result
    print(f"✅ Remove stopwords OK: '{result}'")


def test_chunking():
    """Test text chunking."""
    from modules.preprocessor import chunk_text
    # Create text > 1600 chars (400 tokens * 4 chars)
    long_text = "Ini adalah kalimat panjang untuk testing. " * 100
    chunks = chunk_text(long_text, chunk_size=400, overlap=50)
    assert len(chunks) > 1
    print(f"✅ Chunking OK ({len(chunks)} chunks)")


def test_preprocess_pipeline():
    """Test full preprocessing pipeline."""
    from modules.preprocessor import preprocess
    result = preprocess("Aku yg suka lagu Green Day dgn sepenuh hati")
    assert len(result) > 0
    # After stopword removal, 'yang' (expanded from 'yg') may be removed
    # but 'green' and 'day' should survive
    assert "green" in result[0] or "day" in result[0]
    print(f"✅ Preprocess pipeline OK: '{result[0][:80]}'")



def test_query_analyzer():
    """Test query analysis."""
    from modules.query_analyzer import analyze_query

    # Music query
    r1 = analyze_query("ada berapa lagu Green Day di libraryku?")
    assert "music" in r1["detected_types"]
    assert r1["intent"] in ("recall", "search")

    # Recommendation query
    r2 = analyze_query("rekomendasikan buku yang bagus")
    assert "book" in r2["detected_types"]
    assert r2["intent"] == "recommend"

    # Todo query
    r3 = analyze_query("task apa yang harus aku selesaikan minggu ini?")
    assert "todo" in r3["detected_types"]
    assert r3["time_filter"] == "this_week"

    print("✅ Query analyzer OK")


def test_chromadb():
    """Test ChromaDB connectivity."""
    from modules import db_manager
    col = db_manager.get_collection()
    if col is None:
        print("⚠️ ChromaDB not available (chromadb may not be installed)")
        return
    stats = db_manager.get_stats()
    print(f"✅ ChromaDB OK (total docs: {stats.get('total_documents', 0)})")


def test_enricher_cache():
    """Test disk cache read/write."""
    from modules.enricher import _get_cache, _set_cache
    _set_cache("test_key", {"hello": "world"})
    data = _get_cache("test_key")
    assert data is not None
    assert data["hello"] == "world"

    # Cleanup
    import config
    test_file = os.path.join(config.CACHE_DIR, "test_key.json")
    if os.path.exists(test_file):
        os.remove(test_file)

    print("✅ Enricher cache OK")


def test_graceful_degradation():
    """Test that functions handle errors gracefully."""
    from modules.enricher import enrich_music

    # With invalid data — should return None, not crash
    result = enrich_music("", "")
    # This may return None or an empty dict, both are acceptable
    print(f"✅ Graceful degradation OK (result: {result})")


def run_all():
    """Run all tests."""
    print("=" * 50)
    print("🧪 SoundWave RAG Integration Tests")
    print("=" * 50)

    tests = [
        test_config,
        test_stopwords,
        test_abbreviations,
        test_normalize,
        test_expand_abbreviations,
        test_remove_stopwords,
        test_chunking,
        test_preprocess_pipeline,
        test_query_analyzer,
        test_chromadb,
        test_enricher_cache,
        test_graceful_degradation,
    ]

    passed = 0
    failed = 0

    for test in tests:
        try:
            test()
            passed += 1
        except Exception as e:
            print(f"❌ {test.__name__} FAILED: {e}")
            failed += 1

    print("=" * 50)
    print(f"Results: {passed} passed, {failed} failed")
    print("=" * 50)

    return failed == 0


if __name__ == "__main__":
    success = run_all()
    sys.exit(0 if success else 1)
