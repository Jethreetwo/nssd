from flask_sqlalchemy import SQLAlchemy
import json
from datetime import datetime
from src.models.user import db

class Application(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(120), nullable=False)
    referral = db.Column(db.String(100), nullable=True)
    availability = db.Column(db.Text, nullable=False)  # Stored as JSON string
    activities = db.Column(db.Text, nullable=False)  # Stored as JSON string
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def __repr__(self):
        return f'<Application {self.name}>'

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'email': self.email,
            'referral': self.referral,
            'availability': json.loads(self.availability),
            'activities': json.loads(self.activities),
            'created_at': self.created_at.isoformat()
        }

