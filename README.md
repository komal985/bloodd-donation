# Blood Donation App

Blood Donation App is a full-stack project with:
- a Flask backend (web UI + JSON APIs)
- a Flutter mobile client

It helps register blood donors, create blood requests, and find matching donors by blood group and city.

## Project Structure

- `app.py`: Flask routes and API endpoints
- `models.py`: SQLAlchemy models (`Donor`, `BloodRequest`)
- `templates/`: Flask web templates
- `flutter_app/`: Flutter mobile application

## Features

- Donor registration
- Blood request submission
- Donor match lookup for each request
- Mobile app flow with request-to-matches screen

## Backend Setup (Flask)

### 1) Create and activate virtual environment (recommended)

```bash
py -m venv .venv
.venv\Scripts\activate
```

### 2) Install dependencies

```bash
py -m pip install flask==2.2.5 flask_sqlalchemy
```

### 3) Run backend

```bash
py app.py
```

Backend runs at: `http://127.0.0.1:5000`

## Flutter App Setup

Open a new terminal:

```bash
cd flutter_app
flutter pub get
```

### Run on Android Emulator

```bash
flutter emulators
flutter emulators --launch Medium_Phone_API_36.1
flutter run -d emulator-5554
```

## API Endpoints

- `GET /api/donors`
- `POST /api/donors`
- `GET /api/requests`
- `POST /api/requests`
- `GET /api/matches/<req_id>`

Example donor payload:

```json
{
  "name": "Aman Sharma",
  "phone": "9876543210",
  "blood_group": "O+",
  "city": "Delhi",
  "pincode": "110001",
  "last_donation_date": "2026-03-10"
}
```

## Important Notes

- In Flutter, backend base URL is set in `flutter_app/lib/main.dart`.
- For Android emulator use: `http://10.0.2.2:5000`
- For real device, use your computer's local IP (example: `http://192.168.1.10:5000`)

## Troubleshooting

- If Flutter Android build fails with Gradle download errors (for example HTTP 504), retry with a stable internet connection and run:

```bash
cd flutter_app
flutter clean
flutter pub get
flutter run -d emulator-5554
```
