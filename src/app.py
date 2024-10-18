import os
import logging
from urllib.parse import quote  # Using Python's standard library for URL quoting
from flask import Flask, request, abort, jsonify, render_template
from twilio.twiml.messaging_response import MessagingResponse
from twilio.request_validator import RequestValidator

app = Flask(__name__)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

messages = []

# Twilio credentials
TWILIO_AUTH_TOKEN = os.environ.get('twilio_auth_token')

@app.route('/sms', methods=['POST'])
def sms_reply():
    # Validate incoming request from Twilio
    validator = RequestValidator(TWILIO_AUTH_TOKEN)
    url = request.url
    post_vars = request.form.to_dict()
    signature = request.headers.get('X-Twilio-Signature', '')

    if not validator.validate(url, post_vars, signature):
        logger.warning('Unauthorized request to /sms endpoint')
        abort(403)

    msg_body = post_vars.get('Body')
    messages.append(msg_body)
    logger.info(f'Received SMS message: {msg_body}')

    resp = MessagingResponse()
    resp.message("Message received. Thank you!")

    return str(resp)

@app.route('/')
def home():
    # Render the page where we'll load messages asynchronously
    return render_template('index.html')

@app.route('/get_messages', methods=['GET'])
def get_messages():
    # Return the list of messages as JSON
    return jsonify(messages)

if __name__ == '__main__':
    # Use a production-ready server (e.g., Gunicorn) in production environments
    app.run(host='0.0.0.0', port=5000)
