from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import os
import resume_downloader
import resume_parser
import skill_extractor
import job_matcher
import database

app = FastAPI()

# Initialize database on startup
@app.on_event("startup")
async def startup_event():
    database.init_db()

class ResumeRequest(BaseModel):
    user_id: str
    resume_url: str

@app.post("/analyze_resume")
async def analyze_resume(request: ResumeRequest):
    # Setup temporary file path
    temp_pdf_path = f"temp_{request.user_id}.pdf"

    try:
        # 1. Download Resume
        success = resume_downloader.download_resume(request.resume_url, temp_pdf_path)
        if not success:
            raise HTTPException(status_code=400, detail="Could not download resume from URL")

        # 2. Extract Text
        resume_text = resume_parser.extract_text_from_pdf(temp_pdf_path)
        if not resume_text:
            raise HTTPException(status_code=400, detail="Could not extract text from PDF")

        # 3. Extract Info (Skills, Ed, Exp)
        skills = skill_extractor.extract_skills(resume_text)
        education = skill_extractor.extract_education(resume_text)
        experience = skill_extractor.extract_experience(resume_text)

        # 4. Match Jobs
        jobs_dataset = job_matcher.load_jobs_dataset("jobs_dataset.json")
        matched_jobs = job_matcher.match_jobs(skills, jobs_dataset)

        # 5. Save to Database
        database.save_analysis_result(
            request.user_id,
            request.resume_url,
            skills,
            education,
            experience,
            matched_jobs
        )

        # 6. Return response
        return {
            "extracted_skills": skills,
            "education": education,
            "experience": experience,
            "matched_jobs": matched_jobs
        }

    except Exception as e:
        print(f"Error during analysis: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        # Cleanup
        if os.path.exists(temp_pdf_path):
            os.remove(temp_pdf_path)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
