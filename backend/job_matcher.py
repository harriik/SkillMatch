import json
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

def load_jobs_dataset(file_path):
    with open(file_path, 'r') as f:
        return json.load(f)

def match_jobs(resume_skills, jobs_dataset):
    matched_jobs = []

    if not resume_skills:
        return []

    # Join skills into a single string for TF-IDF
    resume_skills_str = " ".join(resume_skills)

    # Extract all job requirement strings
    job_requirements = [" ".join(job['required_skills']) for job in jobs_dataset]

    # Combine resume and all jobs for the vectorizer
    all_texts = [resume_skills_str] + job_requirements

    # Use TfidfVectorizer for better weighted matching (TF-IDF)
    vectorizer = TfidfVectorizer()
    tfidf_matrix = vectorizer.fit_transform(all_texts)

    # The first row is the resume vector
    resume_vector = tfidf_matrix[0:1]

    # The rest are job vectors
    job_vectors = tfidf_matrix[1:]

    # Calculate similarity scores using Cosine Similarity
    similarities = cosine_similarity(resume_vector, job_vectors)[0]

    for i, job in enumerate(jobs_dataset):
        score = round(similarities[i] * 100, 2)

        # Calculate missing skills (skill gap)
        missing_skills = [
            skill for skill in job['required_skills']
            if skill.lower() not in [rs.lower() for rs in resume_skills]
        ]

        matched_jobs.append({
            "job_title": job['job_title'],
            "match_score": score,
            "missing_skills": missing_skills
        })

    # Sort by highest match score
    matched_jobs.sort(key=lambda x: x['match_score'], reverse=True)

    return matched_jobs
