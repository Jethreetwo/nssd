import csv
import json
import os
from datetime import datetime
from flask import Flask, request, jsonify, send_from_directory

app = Flask(__name__, static_folder='static')
DATA_FILE = 'submissions.csv'

@app.route('/')
def index():
    return send_from_directory(app.static_folder, 'index.html')

@app.route('/<path:path>')
def static_proxy(path):
    return send_from_directory(app.static_folder, path)

@app.route('/submit', methods=['POST'])
def submit():
    data = request.get_json()
    if not data:
        return jsonify({'error': 'Invalid data'}), 400

    file_exists = os.path.isfile(DATA_FILE)
    with open(DATA_FILE, 'a', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        if not file_exists:
            writer.writerow(['timestamp', 'name', 'email', 'referral', 'availability', 'activities'])
        writer.writerow([
            datetime.utcnow().isoformat(),
            data.get('name', ''),
            data.get('email', ''),
            data.get('referral', ''),
            json.dumps(data.get('availability', [])),
            ', '.join(data.get('activities', []))
        ])
    return jsonify({'status': 'success'})

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=80, debug=True)
