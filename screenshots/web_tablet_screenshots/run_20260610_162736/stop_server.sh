#!/bin/bash
echo "🛑 Stopping web server..."
kill 20977 2>/dev/null || true
echo "✅ Server stopped"
