import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:whole_sight/core/utils/logger.dart';

abstract class GeminiService {
  Future<String> generateContent({required String prompt});
  Future<String> generateContentWithImage({
    required String prompt,
    required DataPart image,
  });
  Future<List<String>> generateContentStream({required String prompt});
}

class GeminiServiceImpl implements GeminiService {
  final GenerativeModel _model;
  
  GeminiServiceImpl({required GenerativeModel model}) : _model = model;
  
  @override
  Future<String> generateContent({required String prompt}) async {
    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.candidates.isEmpty || 
          response.candidates.first.content.parts.isEmpty) {
        throw Exception('Empty response from Gemini');
      }
      
      final text = response.candidates.first.content.parts
          .whereType<TextPart>()
          .map((part) => part.text)
          .join('\n');
      
      return text;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to generate content', e, stackTrace);
      throw Exception('Failed to generate content: $e');
    }
  }
  
  @override
  Future<String> generateContentWithImage({
    required String prompt,
    required DataPart image,
  }) async {
    try {
      final content = [
        Content.multi([
          TextPart(prompt),
          image,
        ]),
      ];
      
      final response = await _model.generateContent(content);
      
      if (response.candidates.isEmpty || 
          response.candidates.first.content.parts.isEmpty) {
        throw Exception('Empty response from Gemini');
      }
      
      final text = response.candidates.first.content.parts
          .whereType<TextPart>()
          .map((part) => part.text)
          .join('\n');
      
      return text;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to generate content with image', e, stackTrace);
      throw Exception('Failed to generate content with image: $e');
    }
  }
  
  @override
  Future<List<String>> generateContentStream({required String prompt}) async {
    try {
      final content = [Content.text(prompt)];
      final responseStream = _model.generateContentStream(content);
      
      List<String> responses = [];
      
      await for (final response in responseStream) {
        if (response.candidates.isNotEmpty &&
            response.candidates.first.content.parts.isNotEmpty) {
          final text = response.candidates.first.content.parts
              .whereType<TextPart>()
              .map((part) => part.text)
              .join('\n');
          
          responses.add(text);
        }
      }
      
      return responses;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to generate content stream', e, stackTrace);
      throw Exception('Failed to generate content stream: $e');
    }
  }
}