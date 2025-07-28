Limit the retrieved dream_careers to be max 5. 
Recommended Careers and alternative paths are kind of similar. 
I want a primary career path to remain as is.
Rest of the career_paths to be the recommendations
Alternative paths and recommended careers are the same. 
Safely remove the alternative paths field, but check the implications.    

The career selection should have all the assessment questions and answers. Igonore null fields.

The matching score should be based on the following criteria:

- Gender [2.5%]
- Financial Background [5%]
- Education Board [2.5%]
- Current Grade [0%]

if currentGrade is grade10

- Subject Strengths [30%]
    - Grade 10 Strengths
- Subject Weaknesses [30%]
    - Grade 10 Weaknesses

if currentGrade is grade12

- Current Stream [10%]
- Subject Strengths[15%]
    - Grade 12 Science Strengths
    - Grade 12 Commerce Strengths
    - Grade 12 Arts Strengths
- Subject Weaknesses[15%]
    - Grade 12 Science Weaknesses
    - Grade 12 Commerce Weaknesses
    - Grade 12 Arts Weaknesses

- Exciters[10%]
- Interests[10%]
- Personality Traits[10%]
- Career Goals[5%]
- Parental Influence [5%]



Check if the following is correct:

the RAG service fetches 5 dream_careers. 
the best match is the primary career_path.
the rest of the careers are the recommendations.



What I need is the following. We are getting 5 matches. 

- relatedCareers field is not required from Rag output.

the top match becomes part of the main career_path [title, description, matchScore, etc...] No change required here.

on the career_path generation prompt, the relatedCareers field should be appended with the rest of the 4 matches.










