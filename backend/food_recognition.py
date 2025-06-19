from clarifai_grpc.channel.clarifai_channel import ClarifaiChannel
from clarifai_grpc.grpc.api import resources_pb2, service_pb2, service_pb2_grpc
from clarifai_grpc.grpc.api.status import status_code_pb2
import base64
import requests

CALORIE_NINJAS_KEY = "xlpLBxkUsNH26Y4BpTOw3w==Im0PN24qUdhmFUUN"
SPOONACULAR_KEY = "cbb19f2f2979416f8600b99ba191710b"

class FoodRecognition:
    def __init__(self, api_key):
        self.api_key = api_key
        self.stub = service_pb2_grpc.V2Stub(ClarifaiChannel.get_grpc_channel())
        self.metadata = (('authorization', f'Key {self.api_key}'),)

    def analyze_image(self, image_path):
        """
        Analyze an image using Clarifai's food recognition model
        Returns detected food items and confidence scores
        """
        try:
            with open(image_path, "rb") as f:
                file_bytes = f.read()

            # Construct the request
            request = service_pb2.PostModelOutputsRequest(
                model_id='food-item-recognition',  # Using Clarifai's food recognition model
                inputs=[
                    resources_pb2.Input(
                        data=resources_pb2.Data(
                            image=resources_pb2.Image(
                                base64=file_bytes
                            )
                        )
                    )
                ]
            )

            # Make the request
            response = self.stub.PostModelOutputs(request, metadata=self.metadata)

            # Check response status
            if response.status.code != status_code_pb2.SUCCESS:
                return {
                    'success': False,
                    'error': f'Failed to analyze image: {response.status.description}'
                }

            # Process results
            results = []
            if response.outputs and response.outputs[0].data.concepts:
                for concept in response.outputs[0].data.concepts:
                    results.append({
                        'name': concept.name,
                        'confidence': round(concept.value * 100, 2)
                    })

            # Sort by confidence and get top results
            results.sort(key=lambda x: x['confidence'], reverse=True)
            top_result = results[0] if results else {'name': 'Unknown Food', 'confidence': 0}
            alternatives = [r['name'] for r in results[1:4]] if len(results) > 1 else []

            return {
                'success': True,
                'food_name': top_result['name'],
                'confidence': top_result['confidence'],
                'alternatives': alternatives,
                'all_results': results[:5]  # Return top 5 results
            }

        except Exception as e:
            return {
                'success': False,
                'error': f'Error analyzing image: {str(e)}'
            }

    def get_nutrition_info(self, food_name):
        """
        Get nutrition info using CalorieNinjas and Spoonacular APIs, fallback to mock.
        """
        # Try CalorieNinjas
        try:
            resp = requests.get(
                "https://api.calorieninjas.com/v1/nutrition",
                headers={"X-Api-Key": CALORIE_NINJAS_KEY},
                params={"query": food_name}
            )
            if resp.status_code == 200:
                items = resp.json().get("items", [])
                if items:
                    item = items[0]
                    return {
                        'calories': item.get('calories', 0),
                        'protein': item.get('protein_g', 0),
                        'carbs': item.get('carbohydrates_total_g', 0),
                        'fat': item.get('fat_total_g', 0),
                        'fiber': item.get('fiber_g', 0),
                        'sugar': item.get('sugar_g', 0),
                        'sodium': item.get('sodium_mg', 0)
                    }
        except Exception:
            pass
        # Try Spoonacular
        try:
            resp = requests.get(
                f"https://api.spoonacular.com/food/ingredients/search",
                params={"query": food_name, "apiKey": SPOONACULAR_KEY}
            )
            if resp.status_code == 200:
                results = resp.json().get("results", [])
                if results:
                    id = results[0]["id"]
                    # Get nutrition info for this ingredient
                    nutri_resp = requests.get(
                        f"https://api.spoonacular.com/food/ingredients/{id}/information",
                        params={"amount": 100, "unit": "g", "apiKey": SPOONACULAR_KEY}
                    )
                    if nutri_resp.status_code == 200:
                        nutri = nutri_resp.json()
                        nutrients = {n['name'].lower(): n['amount'] for n in nutri.get('nutrition', {}).get('nutrients', [])}
                        return {
                            'calories': nutrients.get('calories', 0),
                            'protein': nutrients.get('protein', 0),
                            'carbs': nutrients.get('carbohydrates', 0),
                            'fat': nutrients.get('fat', 0),
                            'fiber': nutrients.get('fiber', 0),
                            'sugar': nutrients.get('sugar', 0),
                            'sodium': nutrients.get('sodium', 0)
                        }
        except Exception:
            pass
        # Fallback mock
        nutrition = {
            'calories': 200,
            'protein': 10,
            'carbs': 25,
            'fat': 8,
            'fiber': 3,
            'sugar': 5,
            'sodium': 300
        }
        if 'salad' in food_name.lower():
            nutrition.update({'calories': 100, 'fat': 3, 'carbs': 10})
        elif 'burger' in food_name.lower():
            nutrition.update({'calories': 500, 'fat': 25, 'carbs': 45})
        elif 'fruit' in food_name.lower() or any(fruit in food_name.lower() for fruit in ['apple', 'banana', 'orange']):
            nutrition.update({'calories': 80, 'sugar': 15, 'fiber': 4})
        elif 'pizza' in food_name.lower():
            nutrition.update({'calories': 300, 'fat': 12, 'carbs': 35})
        return nutrition
