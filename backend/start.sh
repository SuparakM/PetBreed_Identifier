#!/bin/bash
# ใช้ uvicorn bind port จาก environment variable $PORT
exec python -m uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}
