from supabase import create_client, Client
import json

# Replace these with your actual Supabase credentials (from your main.dart)
SUPABASE_URL = "https://ksvegfckvystodowhcii.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtzdmVnZmNrdnlzdG9kb3doY2lpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQwNzA1MjEsImV4cCI6MjA4OTY0NjUyMX0._qLa3CqiIy9OUhg5OnpD-lBdGQwFPbbqJEe6PXqD_TM"

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

def init_db():
    # Note: In the REST API version, you should create the table 
    # manually in the Supabase Dashboard once.
    # Go to SQL Editor in Supabase and run:
    """
    CREATE TABLE IF NOT EXISTS resume_results (
        id SERIAL PRIMARY KEY,
        user_id TEXT NOT NULL,
        resume_url TEXT NOT NULL,
        extracted_skills JSONB,
        education JSONB,
        experience JSONB,
        matched_jobs JSONB,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
    );
    """
    print("Database ready. (Ensure 'resume_results' table exists in Supabase Dashboard)")

def save_analysis_result(user_id, resume_url, skills, education, experience, matched_jobs):
    try:
        data = {
            "user_id": user_id,
            "resume_url": resume_url,
            "extracted_skills": skills,
            "education": education,
            "experience": experience,
            "matched_jobs": matched_jobs
        }
        
        response = supabase.table("resume_results").insert(data).execute()
        print(f"Analysis saved to Supabase successfully for user: {user_id}")
        return response
    except Exception as e:
        print(f"Failed to save result to Supabase: {e}")
        raise e
