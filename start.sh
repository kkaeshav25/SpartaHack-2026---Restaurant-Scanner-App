#!/bin/bash
echo " Restaurant Menu Finder - Backend Setup"
echo "==========================================="

# Check Python
if ! command -v python3 &> /dev/null; then
    echo " Python 3 is not installed."
    exit 1
fi

echo " Python found: $(python3 --version)"

# Create .env if needed
if [ ! -f .env ]; then
    echo " .env file not found!"
    echo "Creating .env from .env.example..."
    cp .env.example .env
    echo " .env file created with your API key"
fi

# Install dependencies
echo " Installing dependencies..."
pip3 install -r requirements.txt

# Start server
echo " Starting FastAPI server..."
echo "   Server: http://localhost:8000"
echo "   API docs: http://localhost:8000/docs"
python3 main_improved.py