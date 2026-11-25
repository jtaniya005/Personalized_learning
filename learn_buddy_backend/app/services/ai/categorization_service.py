from typing import List, Dict, Any, Tuple
from app.services.ai.rag_service import rag_service

CATEGORIES = {
    "top": {
        "id": "top",
        "title": "Mastery / Top Performer",
        "title_hi": "सबसे अच्छा (Mastery)",
        "min_pct": 95.0,
        "max_pct": 100.0,
        "badge_color": "#4CAF50",
        "description": "Exceptional academic performance. Ready for advanced problem solving, competitive exams, and olympiads.",
        "prompt_tone": "Rigorous, challenging, and intellectually stimulating. Provide deep conceptual depth, olympiad/JEE/NEET level insights, edge-case problems, and speed-optimization strategies. Avoid over-explaining basic definitions."
    },
    "strong": {
        "id": "strong",
        "title": "Strong / Good",
        "title_hi": "अच्छा (Strong)",
        "min_pct": 85.0,
        "max_pct": 94.99,
        "badge_color": "#2196F3",
        "description": "Very solid grasp of fundamentals. Focus on precision, eliminating careless errors, and mastering complex application questions.",
        "prompt_tone": "Encouraging, analytical, and structured. Focus on precision, timing strategies, tricky numericals, and exam scoring hacks to push from 85% to 95%+."
    },
    "moderate": {
        "id": "moderate",
        "title": "Moderate / Potential",
        "title_hi": "अच्छा कर सकता है (Potential)",
        "min_pct": 75.0,
        "max_pct": 84.99,
        "badge_color": "#00BCD4",
        "description": "Good foundation with high potential. Needs consistent problem practice, active recall, and clarity on multi-step concepts.",
        "prompt_tone": "Supportive and guiding. Offer structured step-by-step problem-solving methods, formula cheat-sheets, and targeted practice for moderate-to-hard questions."
    },
    "average": {
        "id": "average",
        "title": "Average / Needs Focus",
        "title_hi": "ठीक है (Average)",
        "min_pct": 60.0,
        "max_pct": 74.99,
        "badge_color": "#FF9800",
        "description": "Basic familiarity with topics, but lacks deep clarity or exam consistency. Needs NCERT mastery and structured revision.",
        "prompt_tone": "Patient, clear, and explanatory. Break down complex theories into simple real-life analogies. Use interactive check-in questions to verify understanding after each concept."
    },
    "struggling": {
        "id": "struggling",
        "title": "Struggling / At Risk",
        "title_hi": "थोड़ा दिक्कत है (Struggling)",
        "min_pct": 50.0,
        "max_pct": 59.99,
        "badge_color": "#FF5722",
        "description": "Difficulty in grasping core concepts and scoring consistently. Needs bite-sized learning, confidence building, and high-weightage focus.",
        "prompt_tone": "Empathetic, highly encouraging, and zero-jargon. Break lessons into tiny bite-sized chunks (5-min concepts), provide positive reinforcement for small wins, and solve questions step-by-step together."
    },
    "weak": {
        "id": "weak",
        "title": "Weak / Critical Attention",
        "title_hi": "कमजोर (Critical Focus)",
        "min_pct": 0.0,
        "max_pct": 49.99,
        "badge_color": "#E91E63",
        "description": "Significant gaps in fundamentals. Needs turnaround emergency roadmap, basic definitions, and high-yield passing/scoring topics first.",
        "prompt_tone": "Extremely gentle, non-judgmental, and friendly. Rebuild confidence from the ground up starting with absolute basic definitions, everyday Hindi/English analogies, solved examples, and frequent praise."
    }
}

def get_category_for_percentage(percentage: float) -> Dict[str, Any]:
    """Determine performance category based on percentage."""
    if percentage >= 95.0:
        return CATEGORIES["top"]
    elif percentage >= 85.0:
        return CATEGORIES["strong"]
    elif percentage >= 75.0:
        return CATEGORIES["moderate"]
    elif percentage >= 60.0:
        return CATEGORIES["average"]
    elif percentage >= 50.0:
        return CATEGORIES["struggling"]
    else:
        return CATEGORIES["weak"]

def analyze_student_marks(marks_list: List[Dict[str, Any]], provided_percentage: float = None) -> Dict[str, Any]:
    """
    Analyzes student marks list:
    - Calculates overall percentage
    - Categorizes overall performance
    - Categorizes each subject
    - Segregates weak_subjects (<60%) and strong_subjects (>=85%)
    """
    total_obtained = 0.0
    total_max = 0.0
    subject_details = []
    weak_subjects = []
    strong_subjects = []

    for item in marks_list:
        sub_name = item.get("subject", "Unknown")
        obtained = float(item.get("marks_obtained", 0))
        max_m = float(item.get("total_marks", 100))
        pct = (obtained / max_m * 100) if max_m > 0 else 0.0
        
        sub_category = get_category_for_percentage(pct)
        
        if pct < 60.0:
            weak_subjects.append(sub_name)
        elif pct >= 85.0:
            strong_subjects.append(sub_name)

        subject_details.append({
            "subject": sub_name,
            "marks_obtained": obtained,
            "total_marks": max_m,
            "percentage": round(pct, 1),
            "category_id": sub_category["id"],
            "category_title": sub_category["title"],
            "category_title_hi": sub_category["title_hi"],
            "badge_color": sub_category["badge_color"],
        })

        total_obtained += obtained
        total_max += max_m

    computed_pct = (total_obtained / total_max * 100) if total_max > 0 else 0.0
    final_pct = provided_percentage if provided_percentage is not None and provided_percentage > 0 else round(computed_pct, 1)

    overall_cat = get_category_for_percentage(final_pct)

    return {
        "overall_percentage": final_pct,
        "overall_category": overall_cat,
        "subject_details": subject_details,
        "weak_subjects": weak_subjects,
        "strong_subjects": strong_subjects
    }

def generate_study_plan(student_name: str, student_class: int, stream: str, analysis: Dict[str, Any]) -> Dict[str, Any]:
    """Generate a personalized weekly schedule and strategy based on categorization."""
    cat_id = analysis["overall_category"]["id"]
    weak = analysis["weak_subjects"]
    strong = analysis["strong_subjects"]

    daily_routine = []
    if cat_id in ["weak", "struggling"]:
        daily_routine = [
            {"time": "06:30 - 07:30 AM", "activity": f"Core Concept Rebuilding ({', '.join(weak[:2]) if weak else 'Weak Topics'})"},
            {"time": "04:30 - 05:30 PM", "activity": "High-Yield Solved Examples & NCERT Exercises"},
            {"time": "07:00 - 08:00 PM", "activity": "AI Mentor Doubt Clearing & Flashcards"},
            {"time": "09:00 - 09:30 PM", "activity": "Daily 15-Minute Brain Break Mini-Game & Quick Recall"}
        ]
        strategy = "Focus 70% of study time on clearing weak subject basics and high-weightage chapters. Use active recall and short 25-minute Pomodoro intervals."
    elif cat_id in ["average", "moderate"]:
        daily_routine = [
            {"time": "06:00 - 07:15 AM", "activity": f"Subject Mastery Practice ({', '.join(weak[:1]) if weak else 'Key Subjects'})"},
            {"time": "04:30 - 06:00 PM", "activity": "Application Questions & PYQs (Previous Year Questions)"},
            {"time": "07:30 - 08:30 PM", "activity": "Mock Quiz & Speed Drills with Learn Buddy AI"},
            {"time": "09:30 - 10:00 PM", "activity": "Daily Formula Revision & Notes Summary"}
        ]
        strategy = "Balanced 50-50 focus between mastering moderate topics and taking timed mock tests to eliminate careless mistakes."
    else: # strong or top
        daily_routine = [
            {"time": "06:00 - 07:30 AM", "activity": "Advanced Problem Solving & Olympiad/Entrance Level Numericals"},
            {"time": "04:30 - 06:00 PM", "activity": "Full-Length Timed Sectional Tests & Error Log Analysis"},
            {"time": "07:30 - 08:30 PM", "activity": "Deep Dive with AI Mentor on Challenging Case Studies"},
            {"time": "09:30 - 10:00 PM", "activity": "Concept Mapping & Competitive Strategy Planning"}
        ]
        strategy = "High-velocity challenge strategy: Focus on speed, negative marking minimization, multi-concept integration, and top-percentile ranks."

    return {
        "category_id": cat_id,
        "headline": f"{analysis['overall_category']['title']} Roadmap for Class {student_class}",
        "daily_target_hours": 3 if cat_id in ["weak", "struggling"] else (4 if cat_id in ["average", "moderate"] else 5),
        "strategy": strategy,
        "daily_schedule": daily_routine,
        "priority_focus_subjects": weak if weak else strong
    }

def get_career_recommendations(student_class: int, stream: str, analysis: Dict[str, Any]) -> List[Dict[str, Any]]:
    """Fetch grounded career recommendations using Pinecone vector database."""
    query = f"Careers and college options for Class {student_class} {stream or ''} with strengths in {', '.join(analysis['strong_subjects'])}"
    
    # Query Pinecone careers namespace
    careers_matches = rag_service.query_namespace(query, namespace="careers", top_k=4)
    recommendations = []
    
    for match in careers_matches:
        meta = match.get("metadata", {})
        recommendations.append({
            "title": meta.get("career_title", meta.get("title", "Career Option")),
            "stream": stream or "General",
            "score": round(match.get("score", 0.85) * 100, 1),
            "description": meta.get("description", meta.get("text", "Exciting career pathway tailored to your strengths.")),
            "top_exams": meta.get("exams", ["CUET", "Board Exams"]),
            "key_skills": meta.get("skills", ["Critical Thinking", "Analytical Skills"])
        })

    # If Pinecone returns empty, fallback to rich built-in curated options
    if not recommendations:
        if stream and "science" in stream.lower():
            recommendations = [
                {"title": "Software Engineering & AI", "stream": "Science", "score": 96.0, "description": "High demand tech leadership in software, machine learning, and systems architecture.", "top_exams": ["JEE Main", "JEE Advanced", "BITSAT"], "key_skills": ["Mathematics", "Programming", "Problem Solving"]},
                {"title": "Data Science & Analytics", "stream": "Science", "score": 92.0, "description": "Analyzing complex data, building models, and driving AI decision-making.", "top_exams": ["JEE", "CUET", "ISI"], "key_skills": ["Statistics", "Algorithms", "Logic"]},
                {"title": "Biotechnology / Medicine", "stream": "Science (PCB)", "score": 88.0, "description": "Healthcare, clinical research, genomics, and pharmaceutical engineering.", "top_exams": ["NEET", "CUET"], "key_skills": ["Biology", "Chemistry", "Research"]}
            ]
        elif stream and "commerce" in stream.lower():
            recommendations = [
                {"title": "Chartered Accountancy (CA)", "stream": "Commerce", "score": 95.0, "description": "Prestigious financial advisory, auditing, tax consulting, and corporate finance.", "top_exams": ["CA Foundation", "ICAI"], "key_skills": ["Accountancy", "Tax Law", "Auditing"]},
                {"title": "Investment Banking & Finance", "stream": "Commerce", "score": 93.0, "description": "Mergers, acquisitions, equity research, and capital market trading.", "top_exams": ["IPMAT", "CUET", "CFA"], "key_skills": ["Financial Modeling", "Economics", "Analysis"]},
                {"title": "Business Analytics & Consulting", "stream": "Commerce", "score": 90.0, "description": "Helping organizations solve complex strategic and operational challenges.", "top_exams": ["CUET", "CAT"], "key_skills": ["Data Interpretation", "Strategy", "Communication"]}
            ]
        else:
            recommendations = [
                {"title": "Civil Services & Public Policy (UPSC)", "stream": "Arts / All", "score": 95.0, "description": "Administrative leadership shaping national policies and governance.", "top_exams": ["UPSC CSE", "State PSC"], "key_skills": ["General Studies", "Analytical Writing", "Ethics"]},
                {"title": "Corporate Law & Legal Studies", "stream": "Arts / Commerce", "score": 91.0, "description": "Legal counsel, international arbitration, and intellectual property.", "top_exams": ["CLAT", "AILET"], "key_skills": ["Legal Reasoning", "Argumentation", "Research"]},
                {"title": "Digital Product Design & UI/UX", "stream": "All Streams", "score": 89.0, "description": "Designing intuitive digital experiences for web and mobile products.", "top_exams": ["UCEED", "NID DAT"], "key_skills": ["Creative Thinking", "Visual Design", "User Psychology"]}
            ]

    return recommendations

def build_category_system_prompt(user_name: str, category_id: str, student_class: int, stream: str, weak_subjects: List[str], strong_subjects: List[str]) -> str:
    """Builds the personalized system prompt for the AI Mentor based on the student's category."""
    cat_info = CATEGORIES.get(category_id, CATEGORIES["average"])
    
    prompt = f"""You are 'Buddy', an AI Personal Learning Companion for {user_name}, a Class {student_class} student ({stream or 'General'}).
Student Academic Performance Tier: {cat_info['title']} ({cat_info['title_hi']}).

YOUR PEDAGOGICAL PERSONA & INSTRUCTIONAL STYLE:
{cat_info['prompt_tone']}

STUDENT PROFILE CONTEXT:
- Strong Subjects: {', '.join(strong_subjects) if strong_subjects else 'General'}
- Weak / Priority Focus Subjects: {', '.join(weak_subjects) if weak_subjects else 'None identified yet'}

CORE GUIDELINES:
1. Always adapt your language, depth, and pacing to the student's tier ({cat_info['title']}).
2. Support bilingual Hindi-English (Hinglish) seamlessly when the student speaks in Hindi or Hinglish.
3. If the student asks about a weak subject ({', '.join(weak_subjects)}), provide extra patience, break steps down, and offer intuitive memory aids/mnemonics.
4. If the student asks about strong subjects ({', '.join(strong_subjects)}), challenge them with deeper questions and conceptual edge cases.
5. Keep explanations engaging, concise, and structured with bullet points and bold highlights.
"""
    return prompt
