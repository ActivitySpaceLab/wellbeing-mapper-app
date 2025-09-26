#!/bin/bash
echo "🛑 Stopping web server..."
kill 33138 2>/dev/null || true
echo "✅ Server stopped"
