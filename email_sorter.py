import os
import pickle
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from transformers import DistilBertTokenizer, DistilBertForSequenceClassification
import torch
from dotenv import load_dotenv
import base64
from email.mime.text import MIMEText
import json

# Load environment variables
load_dotenv()

# Gmail API scopes
SCOPES = ['https://www.googleapis.com/auth/gmail.modify']

class GmailAISorter:
    def __init__(self):
        self.creds = None
        self.service = None
        self.model = None
        self.tokenizer = None
        self.categories = [
            'Important',
            'Work',
            'Personal',
            'Promotions',
            'Updates',
            'Social'
        ]
        
    def authenticate(self):
        """Authenticate with Gmail API."""
        if os.path.exists('token.pickle'):
            with open('token.pickle', 'rb') as token:
                self.creds = pickle.load(token)

        if not self.creds or not self.creds.valid:
            if self.creds and self.creds.expired and self.creds.refresh_token:
                self.creds.refresh(Request())
            else:
                flow = InstalledAppFlow.from_client_secrets_file(
                    'credentials.json', SCOPES)
                self.creds = flow.run_local_server(port=0)
            
            with open('token.pickle', 'wb') as token:
                pickle.dump(self.creds, token)

        self.service = build('gmail', 'v1', credentials=self.creds)

    def load_ai_model(self):
        """Load the pre-trained BERT model for email classification."""
        self.tokenizer = DistilBertTokenizer.from_pretrained('distilbert-base-uncased')
        self.model = DistilBertForSequenceClassification.from_pretrained(
            'distilbert-base-uncased',
            num_labels=len(self.categories)
        )
        
        # Load fine-tuned weights if they exist
        if os.path.exists('email_classifier.pth'):
            self.model.load_state_dict(torch.load('email_classifier.pth'))
        self.model.eval()

    def classify_email(self, subject, body):
        """Classify email using the AI model."""
        text = f"{subject} {body}"
        inputs = self.tokenizer(text, return_tensors="pt", truncation=True, max_length=512)
        
        with torch.no_grad():
            outputs = self.model(**inputs)
            predictions = torch.softmax(outputs.logits, dim=1)
            category_idx = torch.argmax(predictions).item()
            
        return self.categories[category_idx]

    def create_label(self, label_name):
        """Create a Gmail label if it doesn't exist."""
        try:
            self.service.users().labels().create(
                userId='me',
                body={'name': label_name}
            ).execute()
        except Exception as e:
            if 'Label already exists' not in str(e):
                raise e

    def process_emails(self, max_results=50):
        """Process unread emails and sort them using AI."""
        # Create labels if they don't exist
        for category in self.categories:
            self.create_label(category)

        # Get unread messages
        results = self.service.users().messages().list(
            userId='me',
            labelIds=['UNREAD'],
            maxResults=max_results
        ).execute()

        messages = results.get('messages', [])
        
        for message in messages:
            msg = self.service.users().messages().get(
                userId='me',
                id=message['id'],
                format='full'
            ).execute()

            # Extract subject and body
            subject = ''
            body = ''
            
            headers = msg['payload']['headers']
            for header in headers:
                if header['name'] == 'Subject':
                    subject = header['value']
                    break

            if 'parts' in msg['payload']:
                for part in msg['payload']['parts']:
                    if part['mimeType'] == 'text/plain':
                        body = base64.urlsafe_b64decode(
                            part['body']['data']
                        ).decode('utf-8')
                        break
            else:
                if 'data' in msg['payload']['body']:
                    body = base64.urlsafe_b64decode(
                        msg['payload']['body']['data']
                    ).decode('utf-8')

            # Classify the email
            category = self.classify_email(subject, body)

            # Apply the label
            self.service.users().messages().modify(
                userId='me',
                id=message['id'],
                body={'addLabelIds': [self.get_label_id(category)]}
            ).execute()

            print(f"Processed email: {subject} -> {category}")

    def get_label_id(self, label_name):
        """Get Gmail label ID by name."""
        results = self.service.users().labels().list(userId='me').execute()
        labels = results.get('labels', [])
        
        for label in labels:
            if label['name'] == label_name:
                return label['id']
        return None

def main():
    sorter = GmailAISorter()
    sorter.authenticate()
    sorter.load_ai_model()
    sorter.process_emails()

if __name__ == '__main__':
    main() 