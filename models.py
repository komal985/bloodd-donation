from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

class Donor(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    phone = db.Column(db.String(20), nullable=False)
    blood_group = db.Column(db.String(5), nullable=False)
    city = db.Column(db.String(100), nullable=False)
    pincode = db.Column(db.String(10))
    last_donation_date = db.Column(db.String(20))

class BloodRequest(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    patient_name = db.Column(db.String(100), nullable=False)
    required_blood_group = db.Column(db.String(5), nullable=False)
    city = db.Column(db.String(100), nullable=False)
    pincode = db.Column(db.String(10))
    urgency = db.Column(db.String(20))
