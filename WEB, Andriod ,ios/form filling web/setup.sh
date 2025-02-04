#!/bin/bash

# Create virtual environment
echo "Creating virtual environment..."
python -m venv venv

# Activate virtual environment
echo "Activating virtual environment..."
source venv/bin/activate

# Install dependencies
echo "Installing dependencies..."
pip install -r requirements.txt

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env file..."
    cat > .env << EOL
SUPABASE_URL=your_supabase_url
SUPABASE_KEY=your_supabase_anon_key
GOOGLE_API_KEY=your_google_api_key
FLASK_SECRET_KEY=$(python -c 'import secrets; print(secrets.token_hex(32))')
EOL
    echo "Created .env file. Please update it with your actual credentials."
else
    echo ".env file already exists. Skipping creation."
fi

# Create necessary directories
echo "Creating necessary directories..."
mkdir -p logs
mkdir -p flask_session

echo "Setup complete! Next steps:"
echo "1. Update the .env file with your credentials"
echo "2. Run the SQL setup scripts in your Supabase dashboard"
echo "3. Start the application with 'flask run'" 