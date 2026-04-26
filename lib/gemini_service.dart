import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A service to interact with Google Gemini AI framework for dietary queries.
class GeminiService {
  static const String _defaultApiKey =
      'AIzaSyDXccsm_Hv3WDy37EBDB_Dqtqby1YQXrIU';

  Future<GenerativeModel> _getModel() async {
    final prefs = await SharedPreferences.getInstance();
    final userKey = prefs.getString('gemini_api_key');
    final apiKey = (userKey != null && userKey.isNotEmpty)
        ? userKey
        : _defaultApiKey;

    return GenerativeModel(
      model: 'gemini-3-flash-preview',
      apiKey: apiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );
  }

  /// Generates a simple list of ingredients and step-by-step instructions for a given [mealName].
  /// Returns a structured Map with 'ingredients' (List<dynamic>) and 'instructions' (String) keys.
  Future<Map<String, dynamic>?> generateRecipe(String mealName) async {
    final prompt =
        '''
As a professional culinary assistant, please provide the essential ingredients and very short step-by-step cooking instructions to prepare "$mealName". 

Adhere exactly to the following JSON structure without markdown wrapping:
{
  "ingredients": ["1 cup rice", "2 cups water"],
  "instructions": "1. Rinse rice.\\n2. Boil water.\\n3. Simmer for 20 minutes."
}
''';

    try {
      final model = await _getModel();
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      if (response.text != null) {
        final String rawJson = response.text!.trim();
        // Fallback cleanup in case the model returns markdown code blocks
        final String cleanJson = rawJson
            .replaceAll(RegExp(r'^```[a-zA-Z]*\n|```$'), '')
            .trim();
        return jsonDecode(cleanJson) as Map<String, dynamic>;
      }
    } catch (e) {
      // Basic fallback error handling
      print('GeminiService Error: $e');
    }

    return null;
  }
}
