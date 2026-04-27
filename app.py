import os
from flask import Flask, render_template, request, redirect, url_for, jsonify
from models import db, Donor, BloodRequest

app = Flask(__name__)

# Vercel serverless functions can write only to /tmp.
default_db_uri = 'sqlite:////tmp/blood.db' if os.environ.get('VERCEL') else 'sqlite:///blood.db'
app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get('DATABASE_URL', default_db_uri)
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db.init_app(app)

@app.before_first_request
def create_tables():
    db.create_all()

@app.route('/')
def index():
    donors = Donor.query.all()
    requests = BloodRequest.query.all()
    return render_template('index.html', donors=donors, requests=requests)

@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        donor = Donor(
            name=request.form['name'],
            phone=request.form['phone'],
            blood_group=request.form['blood_group'],
            city=request.form['city'],
            pincode=request.form.get('pincode'),
            last_donation_date=request.form.get('last_donation_date')
        )
        db.session.add(donor)
        db.session.commit()
        return redirect(url_for('index'))
    return render_template('register.html')

@app.route('/request', methods=['GET', 'POST'])
def request_blood():
    if request.method == 'POST':
        req = BloodRequest(
            patient_name=request.form['patient_name'],
            required_blood_group=request.form['required_blood_group'],
            city=request.form['city'],
            pincode=request.form.get('pincode'),
            urgency=request.form.get('urgency')
        )
        db.session.add(req)
        db.session.commit()
        return redirect(url_for('find_matches', req_id=req.id))
    return render_template('request.html')

@app.route('/matches/<int:req_id>')
def find_matches(req_id):
    req = BloodRequest.query.get(req_id)
    matches = Donor.query.filter_by(blood_group=req.required_blood_group, city=req.city).all()
    return render_template('matches.html', matches=matches, req=req)


@app.route('/api/donors', methods=['GET', 'POST'])
def api_donors():
    if request.method == 'POST':
        payload = request.get_json(silent=True) or {}
        donor = Donor(
            name=payload.get('name'),
            phone=payload.get('phone'),
            blood_group=payload.get('blood_group'),
            city=payload.get('city'),
            pincode=payload.get('pincode'),
            last_donation_date=payload.get('last_donation_date')
        )
        db.session.add(donor)
        db.session.commit()
        return jsonify({'message': 'Donor registered', 'id': donor.id}), 201

    donors = Donor.query.all()
    data = [{
        'id': d.id,
        'name': d.name,
        'phone': d.phone,
        'blood_group': d.blood_group,
        'city': d.city,
        'pincode': d.pincode,
        'last_donation_date': d.last_donation_date
    } for d in donors]
    return jsonify(data)


@app.route('/api/requests', methods=['GET', 'POST'])
def api_requests():
    if request.method == 'POST':
        payload = request.get_json(silent=True) or {}
        blood_request = BloodRequest(
            patient_name=payload.get('patient_name'),
            required_blood_group=payload.get('required_blood_group'),
            city=payload.get('city'),
            pincode=payload.get('pincode'),
            urgency=payload.get('urgency')
        )
        db.session.add(blood_request)
        db.session.commit()
        return jsonify({'message': 'Blood request submitted', 'id': blood_request.id}), 201

    requests_data = BloodRequest.query.all()
    data = [{
        'id': r.id,
        'patient_name': r.patient_name,
        'required_blood_group': r.required_blood_group,
        'city': r.city,
        'pincode': r.pincode,
        'urgency': r.urgency
    } for r in requests_data]
    return jsonify(data)


@app.route('/api/matches/<int:req_id>', methods=['GET'])
def api_matches(req_id):
    req = BloodRequest.query.get_or_404(req_id)
    matches = Donor.query.filter_by(
        blood_group=req.required_blood_group,
        city=req.city
    ).all()

    data = {
        'request': {
            'id': req.id,
            'patient_name': req.patient_name,
            'required_blood_group': req.required_blood_group,
            'city': req.city,
            'urgency': req.urgency
        },
        'matches': [{
            'id': m.id,
            'name': m.name,
            'phone': m.phone,
            'blood_group': m.blood_group,
            'city': m.city
        } for m in matches]
    }
    return jsonify(data)

if __name__ == '__main__':
    app.run(debug=True)
