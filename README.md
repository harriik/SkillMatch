# SkillMatch AI 
### AI-Powered Skill & Job Matching System

SkillMatch is a full-stack mobile application that uses **NLP (Natural Language Processing)** to analyze resumes and match users with the best job opportunities based on their actual skills.

---

##  Key Features
- **Smart Resume Parsing**: Extracts skills, education, and experience from PDF resumes using Python & NLP.
- **AI Job Matching**: Uses **TF-IDF Vectorization** and **Cosine Similarity** to calculate the match percentage for various job roles.
- **Real-time ATS Matcher**: Paste a job description and see instantly how well your resume matches the requirements.
- **Unified Auth**: Secure login and sign-up using **Firebase Authentication** (Email & Google).
- **Hybrid Storage**: Fast and reliable file storage for resumes and profile photos using **Supabase Storage**.
- **Dynamic Dashboard**: Personalized job recommendations and skill visualization.

---

## 🛠️ Tech Stack
- **Frontend**: Flutter (Dart)
- **Backend**: FastAPI (Python)
- **Database**: Supabase (PostgreSQL)
- **Authentication**: Firebase Auth
- **AI/ML**: Scikit-learn (TF-IDF), PyMuPDF (Text Extraction), Regex-based Skill Extraction.

---

##  Getting Started

### 1. Backend Setup (FastAPI)
```bash
cd backend
python -m venv venv
.\venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0
```

### 2. Mobile App Setup (Flutter)
1. Ensure you have the `google-services.json` in `android/app/`.
2. Update the `backendUrl` in `lib/screens/resume_upload_screen.dart` with your computer's local IP.
3. Run the app:
```bash
flutter pub get
flutter run
```

---

##  How the Matching Works
The backend converts your resume and job descriptions into mathematical vectors using **TF-IDF**. It then calculates the angle between these vectors using **Cosine Similarity**. 
- **100% Score**: Perfect overlap of skills.
- **Skill Gap**: The app identifies exactly which keywords are missing from your resume to help you improve your ATS score.

---

##  Project Structure
- `lib/`: Flutter UI and logic.
- `backend/`: Python FastAPI server and AI matching scripts.
- `assets/`: App icons and images.

---

