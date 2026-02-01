#!/bin/bash
echo " Restaurant Menu Finder - Backend Setup"
echo "==========================================="

# Activate virtual environment
source ../.venv/Scripts/activate

# Check Python
if ! command -v python &> /dev/null; then
    echo " Python is not installed."
    exit 1
fi

echo " Python found: $(python --version)"

# Create .env if needed
if [ ! -f .env ]; then
    echo " .env file not found!"
    echo "Creating .env from .env.example..."
    cp .env.example .env
    echo " .env file created with your API key"
fi

# Install dependencies
echo " Installing dependencies..."
pip install -r requirements.txt

# Start server
echo " Starting FastAPI server..."
echo "   Server: http://localhost:8000"
echo "   API docs: http://localhost:8000/docs"
python main.py