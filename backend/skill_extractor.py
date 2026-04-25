import re

# Comprehensive list of skills for matching
SKILLS_DB = [
    "Python", "FastAPI", "PostgreSQL", "Docker", "Git", "REST API", "Unit Testing", 
    "Microservices", "React", "JavaScript", "HTML", "CSS", "TypeScript", "Tailwind", 
    "Redux", "Webpack", "Pandas", "Scikit-learn", "Machine Learning", "Statistics", 
    "SQL", "TensorFlow", "NLP", "Flutter", "Dart", "Firebase", "Android", "iOS", 
    "State Management", "API Integration", "Node.js", "Express", "MongoDB", "Redis", 
    "AWS", "Nginx", "Java", "C++", "C#", "Spring Boot", "Kotlin", "Swift", "PHP", 
    "Laravel", "Go", "Rust", "Vue.js", "Angular", "Jenkins", "Kubernetes", "Azure", 
    "GCP", "PyTorch", "Keras", "Deep Learning", "Data Analysis", "Tableau", "Power BI"
]

def extract_skills(text):
    extracted_skills = []
    # Use regex to find skills (case insensitive)
    # This replaces the need for spacy which is failing to install
    for skill in SKILLS_DB:
        # Matches the skill as a whole word
        pattern = r"\b" + re.escape(skill) + r"\b"
        if re.search(pattern, text, re.IGNORECASE):
            extracted_skills.append(skill)
    return list(set(extracted_skills))

def extract_education(text):
    # Simple regex based education extractor
    education_keywords = ['Bsc', 'B.Tech', 'M.Tech', 'BCA', 'MCA', 'Bachelor', 'Master', 'PhD', 'Diploma', 'University', 'College']
    lines = text.split('\n')
    education = []
    for line in lines:
        for keyword in education_keywords:
            if keyword.lower() in line.lower():
                education.append(line.strip())
                break
    return list(set(education))[:3] # Limit to top 3 found

def extract_experience(text):
    # Look for years or duration and job titles
    # This is highly simplified
    lines = text.split('\n')
    experience = []
    for line in lines:
        if any(kw in line.lower() for kw in ['year', 'month', 'experience', 'worked', 'at']):
             experience.append(line.strip())
             if len(experience) > 3: break
    return experience
