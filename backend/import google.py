import google.generativeai as genai

genai.configure(api_key="AIzaSyD5Ilz_JtzhJW_aZup7xBFZs9cOzyW_G6M")

def is_workout_or_diet_related(user_input):
    keywords = [
        "workout", "exercise", "fitness", "gym", "training", "diet", "nutrition",
        "calories", "protein", "meal", "weight loss", "muscle", "cardio", "strength"
    ]
    user_input_lower = user_input.lower()
    return any(keyword in user_input_lower for keyword in keywords)

def chatbot_response(user_input):
    if is_workout_or_diet_related(user_input):
        model = genai.GenerativeModel('gemini-2.5-flash')
        response = model.generate_content(user_input)
        return response.text
    else:
        return "Sorry, I can only answer questions related to workout and diet."

# Example usage:
user_input = input("Ask me about workout or diet: ")
print(chatbot_response(user_input))