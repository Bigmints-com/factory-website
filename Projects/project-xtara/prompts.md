We need to add a new content management to the app for admins.

- Similar to the existing stories management, but for admins - reuse everything
- fetch the data from "career_cluster_resources" collection
- user should be able to filter by "cluster_name"
- user should be able to filter by "status"
- user should be able to filter by "types"
- user should be able to filter by "created_at"
- user should be able to filter by "updated_at"


- all links should have a button to preview it using the existing webview component
- "types" should be a dropdown with the following options:
    - challenge
    - story
    - good_reads
    - video
    - podcast
    - article

This feature should work on both web and mobile.
Add entry point for the feature in the admin menu.
access to the feature should be restricted to admins and editors only (isAdmin and isEditor from the user data)

Read the rules and documentation before you start.

I am looking the the way four features are implemented in the app:
- stories management
- challenges management
- dream careers management
- content management

And there are many inconsistencies in the way they are implemented. and I want to fix it and make rules for any new content management feature that will be added in the future.

I want to use stories management as a template for all other content management features. I want to make reusable template for any new content management and implement it.

I want to cover following aspects:

    - list of all content
        - search
        - filter
        - sort
        - pagination (infinite scroll)
    - add new content button 
    - edit content button
    - delete content button

    On the detail screen should accommodate following:
        - header
        - content dynamic content featched from firestore. This can be custom made.


    Edit screen should accommodate following:
        - header
        - content
        - footer with a primary action button to save the changes


On the web, the feature should be implemented in the same way as the stories management in a two panel layout.

- Read the rules and documentation before you start.
- create a reusable template for the feature
- Implement the template for all 4 content management features.
- Create a documentation cursor can use to implement any new content management feature in the future.
--------------------------------

I want to build a new content management feature on the admin side.

We have 4 categories of content:
- stories
- challenges
- dream_careers
- career_cluster_resources



--------------------------------


I want to build the content generation as firebase functions. The function should first fetch career_cluster_resources with status "published" from firestore, use that source to generate the following content:

- stories, 
- good reads, 
- challenges  

based on the types field in the career_cluster_resources document. 

Refer to challenges/defense-readiness-quiz.json for challenge strusture
Refer to good_reads/structure.json for good read structure
Refer to stories/story_arts_creative_fields_4550.json for story structure

After generating the content, 

- save them in respective collections in firestore with status "draft"
- Update the career_cluster_resources document with a new status "generated".

I want the generation function to be re usable and as a separate function. Keep the firebase functions well organized and easy to maintain.

Check the existing py scripts to get the right prompts. I walso want to make sure the prompts are saved in a separate text file like xtara-firebase/functions/prompts/career_prompt_rag.txt




________________________________________________________

I want to build a new progressive profiling system for students. I want to build a subject wise performance tracker. based on the carriculum the user will have to input marks by sliding a percentage slider.

Step 1:

Check if the user already has selected the subjects. If yes go to step 2.

Else the subject selector should ask the user to select the subjects they are studying with optional other subjects field where the user can enter the subject manually. Like aregional language, etc. The curriculum based subjects are available as a remote config file called carrculums.json. The grade and board are available in the assessment data.

After completing the configuration we need to save the data in the user document under subjectsLearning field in the user document, 

"subjectsLearning": [
    "english",
    "math",
    "science",
    "socialStudies"
],

Step 2:


After the user has selected the subjects, we need to add a new field to the user document. Also build a UI to input the marks for each subject.

"exam_performance": {
    "exam_performance_id": {
    "english": 75,
    "math": 80,
    "science": 85,
    "socialStudies": 90,
    "total": 330,
    "timestamp": "2025-07-21T07:00:00Z"
    }
},


But when resubmitting the form, we need to update the exam_performance field, but also add it a subcollection called "exam_performance" with a new id for comparing the previous and new values.


