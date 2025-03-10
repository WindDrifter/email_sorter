import os
from transformers import DistilBertTokenizer, DistilBertForSequenceClassification
import torch
from dotenv import load_dotenv

def setup_environment():
    """Set up the necessary environment for the email sorter."""
    # Check for credentials.json
    if not os.path.exists('credentials.json'):
        print("Error: credentials.json not found!")
        print("Please follow these steps:")
        print("1. Go to Google Cloud Console")
        print("2. Create a new project or select an existing one")
        print("3. Enable the Gmail API")
        print("4. Create OAuth 2.0 credentials")
        print("5. Download the credentials and save as 'credentials.json'")
        return False

    # Check for .env file
    if not os.path.exists('.env'):
        email = input("Please enter your Gmail address: ")
        with open('.env', 'w') as f:
            f.write(f"GMAIL_USER={email}")

    return True

def prepare_model():
    """Download and prepare the AI model."""
    print("Downloading and preparing the AI model...")
    
    # Initialize model and tokenizer
    tokenizer = DistilBertTokenizer.from_pretrained('distilbert-base-uncased')
    model = DistilBertForSequenceClassification.from_pretrained(
        'distilbert-base-uncased',
        num_labels=6  # Number of email categories
    )

    # Save the model for later use
    torch.save(model.state_dict(), 'email_classifier.pth')
    print("Model prepared successfully!")

def main():
    print("Setting up Gmail AI Sorter...")
    
    if not setup_environment():
        return
    
    prepare_model()
    
    print("\nSetup completed successfully!")
    print("You can now run 'python email_sorter.py' to start sorting your emails.")

if __name__ == '__main__':
    main() 