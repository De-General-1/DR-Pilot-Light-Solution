#!/bin/bash

echo "Packaging Lambda function with dependencies..."

# Navigate to script's directory
cd "$(dirname "$0")"

# Clean old package
rm -rf package backup_lambda.zip

# Install dependencies to a temp dir
mkdir -p package
pip install -r requirements.txt -t package

# Copy your lambda code into the package
cp backup_lambda.py package/

# Zip the contents into the parent folder (or current)
cd package
zip -r ../backup_lambda.zip .
cd ..

# Clean up package dir
rm -rf package

echo "Lambda zipped into backup_lambda.zip"
