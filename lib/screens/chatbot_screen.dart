import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';
import 'dart:math' show min;

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  GenerativeModel? _model;
  ChatSession? _chatSession;
  bool _isInitialized = false;
  String _errorMessage = '';
  bool _useFallbackMode = false;

  // System instruction for Gemini
  final String _systemInstruction = """
You are an AI assistant for the "AI Travel Companion" app, specifically designed to help users with Sri Lankan travel planning.

ABOUT THE APP:
The AI Travel Companion is a smart travel assistant app for Sri Lanka with these features:
- User Registration & Login
- Home Page with current location & weather
- Google Maps Integration
- Weather-based destination recommendations (using ML model)
- Browse destinations by province & category
- Find hotels and tourist attractions
- Create and manage wishlists
- Real-time notifications for trips

DESTINATIONS IN SRI LANKA:
- Historical: Sigiriya Rock Fortress, Anuradhapura, Polonnaruwa, Dambulla Cave Temple
- Cultural: Temple of the Tooth (Kandy), Galle Fort, Kandy Esala Perahera
- Beaches: Mirissa, Unawatuna, Bentota, Arugam Bay, Hikkaduwa, Nilaveli, Trincomalee
- Hills: Nuwara Eliya, Ella, Haputale, Bandarawela, Horton Plains
- Wildlife: Yala National Park, Udawalawe National Park, Wilpattu, Sinharaja Rainforest
- Religious: Adam's Peak (Sri Pada), Koneswaram Temple, Nagapooshani Amman Temple
- Cities: Colombo, Kandy, Galle, Jaffna

WEATHER PATTERNS:
- December to March: Best for west and south coasts (sunny, dry)
- April to September: Southwest monsoon affects west/south coasts
- October to November: Inter-monsoon with occasional showers

IMPORTANT RULES:
1. ONLY answer questions about the AI Travel Companion app and Sri Lankan travel
2. If users ask about other topics, politely say: "I'm designed to help only with the AI Travel Companion app and Sri Lankan travel. Please ask me about travel plans, destinations, or app features!"
3. Be helpful, friendly, and concise with responses
4. Recommend using app features when relevant
5. Provide accurate Sri Lankan travel information

Keep responses conversational and helpful. Use emojis occasionally to make the chat friendly.
""";

  @override
  void initState() {
    super.initState();
    _initializeGemini();
  }

  Future<void> _initializeGemini() async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];

      if (apiKey == null || apiKey.isEmpty) {
        print('❌ Gemini API key not found in .env file');
        setState(() {
          _errorMessage =
              'Gemini API key not configured. Please check your .env file.';
          _useFallbackMode = true;
          _isInitialized = true;
        });
        return;
      }

      print('✅ Gemini API key found: ${apiKey.substring(0, 8)}...');

      // Use the correct model name
      _model = GenerativeModel(
        model: 'gemini-pro',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 800,
          topP: 0.8,
          topK: 40,
        ),
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
          SafetySetting(
              HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium),
          SafetySetting(
              HarmCategory.dangerousContent, HarmBlockThreshold.medium),
        ],
      );

      // Start a chat session
      _chatSession = _model!.startChat();

      setState(() {
        _isInitialized = true;
      });

      print('✅ Gemini initialized successfully with gemini-pro model');

      // Test the connection
      _testGeminiConnection();
    } catch (e) {
      print('❌ Error initializing Gemini: $e');
      setState(() {
        _errorMessage = 'Failed to initialize chat: $e';
        _useFallbackMode = true;
        _isInitialized = true;
      });
    }
  }

  Future<void> _testGeminiConnection() async {
    try {
      if (_chatSession == null) return;

      final response = await _chatSession!.sendMessage(
        Content.text('Hello, are you working?'),
      );

      print('✅ Gemini test response: ${response.text}');
    } catch (e) {
      print('❌ Gemini test failed: $e');
      setState(() {
        _useFallbackMode = true;
      });
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    if (!_isInitialized) {
      _showErrorSnackBar('Chat is initializing. Please wait a moment...');
      return;
    }

    final userMessage = _messageController.text.trim();

    setState(() {
      _messages.add(ChatMessage(text: userMessage, isUser: true));
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    if (!_useFallbackMode && _chatSession != null) {
      await _getGeminiResponse(userMessage);
    } else {
      await _getFallbackResponse(userMessage);
    }
  }

  Future<void> _getGeminiResponse(String message) async {
    try {
      if (_chatSession == null) {
        throw Exception('Chat session not initialized');
      }

      print('📤 Sending to Gemini: $message');

      // Combine system instruction with user message
      final response = await _chatSession!.sendMessage(
        Content.text('$_systemInstruction\n\nUser Query: $message'),
      );

      String responseText =
          response.text ?? 'Sorry, I could not generate a response.';

      print('📥 Received from Gemini');

      setState(() {
        _messages.add(ChatMessage(text: responseText, isUser: false));
        _isTyping = false;
      });
    } catch (e) {
      print('❌ Error getting Gemini response: $e');

      setState(() {
        _useFallbackMode = true;
        _messages.add(ChatMessage(
            text: _getUserFriendlyErrorMessage(e.toString()), isUser: false));
        _isTyping = false;
      });

      _showErrorSnackBar(
          'Switching to offline mode. Some features may be limited.');
    }

    _scrollToBottom();
  }

  String _getUserFriendlyErrorMessage(String error) {
    if (error.contains('API key')) {
      return "⚠️ There's an issue with the API key. Please check your configuration. I'll help you with basic travel info for now.";
    } else if (error.contains('quota') || error.contains('limit')) {
      return "⚠️ API quota exceeded. I'll help you with basic travel information for now.";
    } else if (error.contains('model')) {
      return "⚠️ There's a model configuration issue. I'll use my backup knowledge to help you.";
    } else {
      return "⚠️ I'm having trouble connecting to the AI service. I'll help you with basic travel information for now.";
    }
  }

  Future<void> _getFallbackResponse(String message) async {
    await Future.delayed(const Duration(milliseconds: 800));

    String response = _generateSmartFallbackResponse(message);

    setState(() {
      _messages.add(ChatMessage(text: response, isUser: false));
      _isTyping = false;
    });

    _scrollToBottom();
  }

  String _generateSmartFallbackResponse(String message) {
    final lowerMsg = message.toLowerCase();

    // Greetings
    if (lowerMsg.contains('hi') ||
        lowerMsg.contains('hello') ||
        lowerMsg.contains('hey')) {
      return "👋 Hello! I'm your AI Travel Assistant for Sri Lanka. How can I help you plan your trip today?";
    }

    // App features
    if (lowerMsg.contains('feature') ||
        lowerMsg.contains('what can you do') ||
        lowerMsg.contains('help') ||
        lowerMsg.contains('capabilities')) {
      return _getAppFeaturesResponse();
    }

    // Weather
    if (lowerMsg.contains('weather') ||
        lowerMsg.contains('climate') ||
        lowerMsg.contains('rain') ||
        lowerMsg.contains('sunny') ||
        lowerMsg.contains('monsoon')) {
      return _getWeatherResponse(message);
    }

    // Destinations
    if (lowerMsg.contains('destination') ||
        lowerMsg.contains('place to visit') ||
        lowerMsg.contains('where to go') ||
        lowerMsg.contains('best place')) {
      return _getDestinationRecommendation(message);
    }

    // Specific places
    if (lowerMsg.contains('sigiriya')) {
      return "🏯 **Sigiriya Rock Fortress**\n\nAn ancient rock fortress and UNESCO World Heritage site. It's best visited during dry season (December to April). The climb takes about 1-2 hours. You can find Sigiriya in the app's destination browser under 'Historical' category!";
    }

    if (lowerMsg.contains('kandy')) {
      return "🙏 **Kandy**\n\nHome to the sacred Temple of the Tooth Relic. Best time to visit is during the Esala Perahera festival (July/August). Don't miss the Royal Botanical Gardens! Check it out in the app under 'Cultural' destinations.";
    }

    if (lowerMsg.contains('ella')) {
      return "⛰️ **Ella**\n\nFamous for scenic train rides, Nine Arch Bridge, and Little Adam's Peak. Best weather from January to April. You can find Ella in the app under 'Hills' category!";
    }

    if (lowerMsg.contains('galle')) {
      return "🏰 **Galle Fort**\n\nHistoric Dutch fort with colonial architecture, boutique shops, and cafes. Perfect for walking tours. Find it in the app under 'Historical' destinations!";
    }

    if (lowerMsg.contains('mirissa') || lowerMsg.contains('beach')) {
      return "🏖️ **Mirissa & Beaches**\n\nMirissa is famous for whale watching (Nov-Apr) and beautiful beaches. Other great beaches: Unawatuna, Bentota, Arugam Bay, Hikkaduwa. Use the app's beach filter to explore all coastal destinations!";
    }

    // Hotels
    if (lowerMsg.contains('hotel') ||
        lowerMsg.contains('stay') ||
        lowerMsg.contains('accommodation') ||
        lowerMsg.contains('resort')) {
      return _getHotelsResponse(message);
    }

    // Food
    if (lowerMsg.contains('food') ||
        lowerMsg.contains('eat') ||
        lowerMsg.contains('restaurant') ||
        lowerMsg.contains('curry')) {
      return "🍛 **Sri Lankan Food**\n\nMust-try dishes: Rice & Curry, Kottu Roti, Hoppers, String Hoppers, Lamprais. The app can help you find restaurants near your location using Google Maps integration!";
    }

    // Transport
    if (lowerMsg.contains('transport') ||
        lowerMsg.contains('train') ||
        lowerMsg.contains('bus') ||
        lowerMsg.contains('taxi') ||
        lowerMsg.contains('tuk tuk')) {
      return "🚂 **Transportation in Sri Lanka**\n\n• Train: Scenic rides, especially Kandy to Ella\n• Bus: Extensive network, very affordable\n• Taxi/Tuk-tuk: Convenient for short distances\n• Private drivers: Good for multi-day tours\n\nThe app can help you plan your route with Google Maps integration!";
    }

    // Budget
    if (lowerMsg.contains('budget') ||
        lowerMsg.contains('cost') ||
        lowerMsg.contains('price') ||
        lowerMsg.contains('expensive')) {
      return "💰 **Travel Budget**\n\n• Backpacker: \$30-50 per day\n• Mid-range: \$50-100 per day\n• Luxury: \$100-200+ per day\n\nThe app's hotel browser lets you filter by price range to find accommodations that fit your budget!";
    }

    // App itself
    if (lowerMsg.contains('app') ||
        lowerMsg.contains('application') ||
        lowerMsg.contains('how to use') ||
        lowerMsg.contains('download')) {
      return _getAppFeaturesResponse();
    }

    // Off-topic detection
    if (_isLikelyOffTopic(lowerMsg)) {
      return "I'm designed to help only with the AI Travel Companion app and Sri Lankan travel. Please ask me about travel plans, destinations, or app features! 😊";
    }

    // Default response
    return "I can help you plan your Sri Lankan adventure using the AI Travel Companion app! You can ask me about:\n\n• 🌍 Destinations (Sigiriya, Kandy, Ella, etc.)\n• 🌦️ Weather and best times to visit\n• 🏨 Hotels and accommodations\n• 🏖️ Beaches and attractions\n• 🚗 Transportation tips\n• 💰 Budget planning\n\nWhat would you like to know?";
  }

  bool _isLikelyOffTopic(String message) {
    final travelKeywords = [
      'travel', 'trip', 'tour', 'visit', 'destination', 'place', 'location',
      'sri lanka', 'lanka', 'beach', 'mountain', 'hill', 'temple', 'cultural',
      'historical', 'hotel', 'stay', 'accommodation', 'food', 'eat',
      'restaurant',
      'weather', 'climate', 'rain', 'sunny', 'monsoon', 'season', 'budget',
      'cost', 'price', 'transport', 'train', 'bus', 'taxi', 'tuk', 'flight',
      'map', 'direction', 'route', 'plan', 'itinerary', 'schedule',
      'feature', 'app', 'chatbot', 'assistant', 'help', 'recommend',
      'sigiriya', 'kandy', 'galle', 'ella', 'nuwara', 'mirissa', 'colombo',
      'jaffna', 'trincomalee', 'anuradhapura', 'polonnaruwa', 'dambulla',
      'yala', 'udawalawe', 'horton', 'adams peak', 'haputale', 'bandarawela',
      // Sinhala keywords
      'සංචාරක', 'ගමනාන්ත', 'ස්ථාන', 'කාලගුණය', 'හෝටල්', 'වෙරළ', 'පන්සල',
      'ඓතිහාසික', 'සංස්කෘතික', 'මිරිස්ස', 'උණවටුන', 'බෙන්තොට', 'සිගිරිය',
      'මහනුවර', 'ගාල්ල', 'ඇල්ල', 'නුවරඑළිය', 'යාල', 'උඩවලව'
    ];

    int keywordCount = 0;
    for (var keyword in travelKeywords) {
      if (message.contains(keyword)) {
        keywordCount++;
      }
    }

    if (keywordCount == 0 && message.split(' ').length > 3) {
      return true;
    }

    return false;
  }

  String _getAppFeaturesResponse() {
    return """🌟 **AI Travel Companion Features**

Here's what our app can do for you:

• 👤 **User Account** - Register and login to save your preferences
• 🏠 **Smart Home** - See current location, weather, and personalized recommendations
• 🗺️ **Google Maps** - Integrated maps for easy navigation
• 🌦️ **Weather-Based Planning** - Get destination recommendations based on weather forecasts
• 📍 **Destination Browser** - Filter by province, category, or search
• 🏨 **Hotel Finder** - Browse and book accommodations
• ❤️ **Wishlist** - Save your favorite places
• 💬 **AI Chatbot** - That's me! Get travel advice anytime
• 🔔 **Notifications** - Get reminders for your trips

Which feature would you like to explore? I can guide you through using it! 😊""";
  }

  String _getWeatherResponse(String message) {
    if (message.contains('december') ||
        message.contains('january') ||
        message.contains('february') ||
        message.contains('march')) {
      return "☀️ **December to March** is the best time to visit the west and south coasts (Colombo, Galle, Bentota, Mirissa). Expect sunny skies and calm seas - perfect for beach activities! Use the app's AI Planner to get weather-based recommendations for your specific dates.";
    } else if (message.contains('april') ||
        message.contains('may') ||
        message.contains('june') ||
        message.contains('july') ||
        message.contains('august') ||
        message.contains('september')) {
      return "🌧️ **April to September** is the southwest monsoon season. The west and south coasts experience rain, but the east coast (Trincomalee, Arugam Bay) has great weather! The app's weather feature can help you find the best destinations for your travel dates.";
    } else if (message.contains('october') || message.contains('november')) {
      return "🌤️ **October to November** is the inter-monsoon period with occasional showers. This can be a good time to visit cultural sites like Kandy and Anuradhapura. Check the app's weather predictions for specific destinations!";
    } else {
      return """**Sri Lanka Weather Guide:**

☀️ **Dec-Mar:** Best for west/south coasts (sunny, dry)
🌧️ **Apr-Sep:** Southwest monsoon season
🌤️ **Oct-Nov:** Inter-monsoon, occasional showers

The app's AI Planner can recommend destinations based on weather for YOUR specific travel dates! Try it out!""";
    }
  }

  String _getDestinationRecommendation(String message) {
    if (message.contains('beach') ||
        message.contains('sea') ||
        message.contains('ocean')) {
      return "🏖️ **Best Beaches in Sri Lanka:**\n\n• **Mirissa** - Whale watching, surfing\n• **Unawatuna** - Coral reefs, safe swimming\n• **Bentota** - Water sports, luxury resorts\n• **Arugam Bay** - World-class surfing\n• **Trincomalee** - Pristine beaches\n\nBest time: November to April for east coast, December to March for west coast. Use the app's beach filter to explore all options!";
    }

    if (message.contains('historical') ||
        message.contains('ancient') ||
        message.contains('ruins')) {
      return "🏯 **Historical Sites:**\n\n• **Sigiriya Rock Fortress** - Ancient palace on a rock\n• **Anuradhapura** - Sacred ancient city\n• **Polonnaruwa** - Medieval kingdom ruins\n• **Dambulla Cave Temple** - Cave paintings\n\nFind all these in the app's 'Historical' category!";
    }

    if (message.contains('cultural') ||
        message.contains('temple') ||
        message.contains('religious')) {
      return "🙏 **Cultural & Religious Sites:**\n\n• **Temple of the Tooth (Kandy)** - Sacred Buddhist relic\n• **Galle Fort** - Dutch colonial architecture\n• **Koneswaram Temple (Trincomalee)** - Hindu shrine\n• **Adam's Peak (Sri Pada)** - Sacred mountain\n\nUse the app's 'Cultural' filter to explore more!";
    }

    if (message.contains('hill') ||
        message.contains('mountain') ||
        message.contains('tea')) {
      return "⛰️ **Hill Country Destinations:**\n\n• **Nuwara Eliya** - Tea plantations, cool climate\n• **Ella** - Scenic views, Nine Arch Bridge\n• **Haputale** - Lipton's Seat, tea factories\n• **Horton Plains** - World's End viewpoint\n\nBest time: January to April for clear views. Find these in the app's 'Hills' category!";
    }

    return """**Popular Sri Lankan Destinations:**

🏯 **Historical:** Sigiriya, Anuradhapura, Polonnaruwa
🙏 **Cultural:** Temple of the Tooth (Kandy), Galle Fort
🏖️ **Beaches:** Mirissa, Unawatuna, Bentota, Arugam Bay
⛰️ **Hills:** Nuwara Eliya, Ella, Haputale
🐘 **Wildlife:** Yala National Park, Udawalawe

Which type of destination interests you? I can give more specific recommendations!""";
  }

  String _getHotelsResponse(String message) {
    String city = '';
    if (message.contains('kandy'))
      city = 'Kandy';
    else if (message.contains('colombo'))
      city = 'Colombo';
    else if (message.contains('galle'))
      city = 'Galle';
    else if (message.contains('ella'))
      city = 'Ella';
    else if (message.contains('nuwara'))
      city = 'Nuwara Eliya';
    else if (message.contains('mirissa')) city = 'Mirissa';

    if (city.isNotEmpty) {
      return "🏨 **Hotels in $city**\n\nThe app can help you find hotels in $city! Popular options include:\n\n• Luxury properties\n• Boutique hotels\n• Budget guesthouses\n\nOpen the app's hotel browser, select '$city' as location, and filter by your preferences!";
    }

    return """**Accommodation in Sri Lanka:**

The app helps you find and book hotels across the country:

• 🏨 **Luxury Hotels:** Jetwing, Cinnamon, Heritance chains
• 🏡 **Boutique Hotels:** Unique stays in Ella, Galle, Kandy
• 🏖️ **Beach Resorts:** Bentota, Mirissa, Unawatuna
• ⛰️ **Hill Country B&Bs:** Nuwara Eliya, Ella, Haputale
• 💰 **Budget Options:** Guesthouses and hostels nationwide

Use the app's hotel browser to filter by location, price, and amenities!""";
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showInitializationError() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chat Information'),
        content: Text(_errorMessage.isEmpty
            ? 'Chat will work in offline mode with basic travel information.'
            : _errorMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage.isNotEmpty && _messages.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showInitializationError();
      });
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF001F3F),
              Color(0xFF0074D9),
              Color.fromARGB(255, 22, 109, 143),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const CircleAvatar(
                      backgroundColor: Color(0xFF00DFD8),
                      child: Icon(Icons.chat, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AI Travel Assistant',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                _useFallbackMode
                                    ? 'Offline Mode'
                                    : 'Gemini Powered',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                              if (_useFallbackMode)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: Colors.orange.withOpacity(0.5)),
                                  ),
                                  child: const Text(
                                    'Basic Mode',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!_isInitialized)
                      Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.only(right: 8),
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                  ],
                ),
              ),

              // Welcome Message
              if (_messages.isEmpty)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Lottie.asset(
                        'assets/animations/travel_animation.json',
                        height: 200,
                        width: 200,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            width: 200,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.travel_explore,
                              color: Colors.white,
                              size: 80,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Hi! I\'m your AI Travel Assistant',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _isInitialized
                            ? 'Ask me about Sri Lankan travel or app features!'
                            : 'Initializing chat assistant... Please wait.',
                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      if (_isInitialized)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildSuggestionChip('Best places to visit'),
                            _buildSuggestionChip('Weather in December'),
                            _buildSuggestionChip('Beaches in Sri Lanka'),
                            _buildSuggestionChip('Hotels in Kandy'),
                            _buildSuggestionChip('About Ella'),
                            _buildSuggestionChip('App features'),
                          ],
                        ),
                    ],
                  ),
                ),

              // Chat Messages
              if (_messages.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
                ),

              // Typing Indicator
              if (_isTyping)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildTypingDot(0),
                            const SizedBox(width: 4),
                            _buildTypingDot(150),
                            const SizedBox(width: 4),
                            _buildTypingDot(300),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Input Field
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E3A8A),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: TextField(
                          controller: _messageController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: _isInitialized
                                ? 'Ask about travel or app features...'
                                : 'Initializing chat...',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                            ),
                            border: InputBorder.none,
                          ),
                          enabled: _isInitialized,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        gradient: _isInitialized
                            ? const LinearGradient(
                                colors: [Color(0xFF007CF0), Color(0xFF00DFD8)],
                              )
                            : LinearGradient(
                                colors: [
                                  Colors.grey.shade400,
                                  Colors.grey.shade600
                                ],
                              ),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _isInitialized ? _sendMessage : null,
                        icon: const Icon(Icons.send, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: EdgeInsets.only(
        bottom: 12,
        left: message.isUser ? 50 : 0,
        right: message.isUser ? 0 : 50,
      ),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser)
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF00DFD8),
              child: Icon(Icons.chat, color: Colors.white, size: 16),
            ),
          if (!message.isUser) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? const Color(0xFF007CF0)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: message.isUser
                      ? const Radius.circular(20)
                      : const Radius.circular(0),
                  bottomRight: message.isUser
                      ? const Radius.circular(0)
                      : const Radius.circular(20),
                ),
              ),
              child: SelectableText(
                message.text,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          if (message.isUser) const SizedBox(width: 8),
          if (message.isUser)
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF007CF0),
              child: Icon(Icons.person, color: Colors.white, size: 16),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return GestureDetector(
      onTap: _isInitialized
          ? () {
              _messageController.text = text;
              _sendMessage();
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isInitialized
                ? const Color(0xFF00DFD8).withOpacity(0.5)
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color:
                _isInitialized ? const Color(0xFF00DFD8) : Colors.grey.shade500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingDot(int delay) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.5, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}
