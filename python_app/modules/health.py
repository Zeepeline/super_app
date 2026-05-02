"""
health.py — Flask blueprint for health check and status endpoints.
"""

import os
import time
import logging

from flask import Blueprint, jsonify

from modules import db_manager
import config

logger = logging.getLogger("health")

bp = Blueprint("health", __name__)

_start_time = time.time()


@bp.route("/ping", methods=["GET"])
def ping():
    """Simple health check."""
    return jsonify({"status": "ok", "message": "pong"}), 200


@bp.route("/status", methods=["GET"])
def status():
    """Detailed status: uptime, doc count, memory usage, versions."""
    uptime_seconds = int(time.time() - _start_time)

    # Memory usage (best-effort)
    memory_mb = 0
    try:
        import resource
        usage = resource.getrusage(resource.RUSAGE_SELF)
        memory_mb = round(usage.ru_maxrss / (1024 * 1024), 1)  # macOS reports in bytes
    except Exception:
        try:
            import psutil
            proc = psutil.Process(os.getpid())
            memory_mb = round(proc.memory_info().rss / (1024 * 1024), 1)
        except Exception:
            pass

    # DB stats
    db_stats = db_manager.get_stats()

    # Gemini status
    gemini_key_set = bool(os.environ.get(config.GEMINI_API_KEY_ENV))

    return jsonify({
        "status": "ok",
        "data": {
            "uptime_seconds": uptime_seconds,
            "uptime_human": _format_uptime(uptime_seconds),
            "memory_mb": memory_mb,
            "memory_budget_mb": 200,
            "db": db_stats,
            "gemini_key_set": gemini_key_set,
            "chroma_dir": config.CHROMA_DIR,
            "version": "2.0.0",
        },
    }), 200


def _format_uptime(seconds):
    hours = seconds // 3600
    minutes = (seconds % 3600) // 60
    secs = seconds % 60
    return f"{hours}h {minutes}m {secs}s"
