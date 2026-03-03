import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../services/weather_prediction_service.dart';

class ChatbotScreen extends StatefulWidget {
  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  final Map<String, List<String>> _responses = {
    'greeting': ['Hello! How can I help you plan your Sri Lankan adventure?'],
    'weather': [
      'Sri Lanka has two main monsoon seasons. The best time to visit the west and south coasts is from December to March.',
    ],
    'destinations': [
      'Popular destinations: Sigiriya, Kandy, Galle, Nuwara Eliya, Mirissa, Ella',
    ],
    'beach': [
      'Beautiful beaches: Mirissa, Unawatuna, Bentota, Arugam Bay, Hikkaduwa',
    ],
    'cultural': [
      'Cultural sites: Kandy Temple, Anuradhapura, Polonnaruwa, Dambulla Cave Temple',
    ],
    'food': [
      'Must-try foods: Rice and Curry, Kottu Roti, Hoppers, String Hoppers',
    ],
    'hotels': ['Popular hotels: Jetwing, Cinnamon, Heritance, Amaya chains'],
    'transport': [
      'Transport: Trains (scenic), Buses, Taxis, Tuk-tuks, Private drivers',
    ],
    'budget': [
      'Daily budget: Budget \$30-50, Mid-range \$50-100, Luxury \$100-200+',
    ],
  };

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: _messageController.text, isUser: true));
      _isTyping = true;
    });

    _processMessage(_messageController.text);
    _messageController.clear();
    _scrollToBottom();
  }

  Future<void> _processMessage(String message) async {
    await Future.delayed(const Duration(seconds: 1));

    String response = _getResponse(message.toLowerCase());

    if (message.toLowerCase().contains('weather')) {
      try {
        final service = WeatherPredictionService();
        await service.initialize();
        final recommendations = await service.recommendDestinations(
          tripDate: DateTime.now(),
        );
        if (recommendations.isNotEmpty) {
          response += '\n\nBased on weather, I recommend:\n';
          for (var dest in recommendations.take(3)) {
            response +=
                '• ${dest['name']} (${dest['weatherPrediction']['condition']})\n';
          }
        }
      } catch (e) {
        response +=
            '\n\nSorry, I couldn\'t fetch weather recommendations at the moment.';
      }
    }

    setState(() {
      _messages.add(ChatMessage(text: response, isUser: false));
      _isTyping = false;
    });
    _scrollToBottom();
  }

  String _getResponse(String message) {
    if (message.contains('hello') ||
        message.contains('hi') ||
        message.contains('hey')) {
      return _responses['greeting']![0];
    }
    if (message.contains('weather') ||
        message.contains('rain') ||
        message.contains('sunny')) {
      return _responses['weather']![0];
    }
    if (message.contains('destination') ||
        message.contains('place') ||
        message.contains('visit') ||
        message.contains('see')) {
      return _responses['destinations']![0];
    }
    if (message.contains('beach') ||
        message.contains('sea') ||
        message.contains('ocean')) {
      return _responses['beach']![0];
    }
    if (message.contains('cultural') ||
        message.contains('temple') ||
        message.contains('history') ||
        message.contains('religious')) {
      return _responses['cultural']![0];
    }
    if (message.contains('food') ||
        message.contains('eat') ||
        message.contains('restaurant') ||
        message.contains('curry')) {
      return _responses['food']![0];
    }
    if (message.contains('hotel') ||
        message.contains('stay') ||
        message.contains('accommodation') ||
        message.contains('resort')) {
      return _responses['hotels']![0];
    }
    if (message.contains('transport') ||
        message.contains('train') ||
        message.contains('bus') ||
        message.contains('taxi') ||
        message.contains('tuk')) {
      return _responses['transport']![0];
    }
    if (message.contains('budget') ||
        message.contains('cost') ||
        message.contains('price') ||
        message.contains('expensive')) {
      return _responses['budget']![0];
    }
    if (message.contains('sigiriya')) {
      return 'Sigiriya Rock Fortress is a UNESCO World Heritage site. It\'s best visited during dry season (Dec-Apr). The climb takes about 1-2 hours.';
    }
    if (message.contains('kandy')) {
      return 'Kandy\'s Temple of the Sacred Tooth Relic is a sacred Buddhist site. Best time to visit is during the Esala Perahera festival (July/August).';
    }
    if (message.contains('galle')) {
      return 'Galle Fort is a historic Portuguese-built fort. Perfect for walking tours, shopping, and enjoying colonial architecture.';
    }
    if (message.contains('ella')) {
      return 'Ella is famous for scenic train rides, Nine Arch Bridge, and Little Adam\'s Peak. Best weather from Jan-Apr.';
    }
    if (message.contains('nuwara') || message.contains('eliya')) {
      return 'Nuwara Eliya (Little England) is known for tea plantations, cool climate, and colonial architecture. Best visited Jan-Apr.';
    }
    if (message.contains('mirissa')) {
      return 'Mirissa is famous for whale watching, beautiful beaches, and surfing. Best time Nov-Apr.';
    }

    return 'I can help with:\n'
        '• Weather information\n'
        '• Destinations (Sigiriya, Kandy, Galle, Ella, etc.)\n'
        '• Beaches (Mirissa, Unawatuna, Bentota)\n'
        '• Cultural places (Temples, Historical sites)\n'
        '• Food recommendations\n'
        '• Hotels and accommodation\n'
        '• Transportation (Trains, Buses, Taxis)\n'
        '• Budget planning\n\n'
        'What would you like to know?';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF001F3F),
              const Color(0xFF0074D9),
              const Color.fromARGB(255, 22, 109, 143),
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
                    CircleAvatar(
                      backgroundColor: const Color(0xFF00DFD8),
                      child: const Icon(Icons.chat, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Travel Assistant',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'AI Powered',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
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
                        'assets/animations/chatbot.json',
                        height: 200,
                        width: 200,
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
                        'Ask me anything about Sri Lankan travel!',
                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                      ),
                      const SizedBox(height: 30),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildSuggestionChip('Weather in Sigiriya'),
                          _buildSuggestionChip('Best beaches'),
                          _buildSuggestionChip('Budget tips'),
                          _buildSuggestionChip('Cultural places'),
                          _buildSuggestionChip('Food recommendations'),
                          _buildSuggestionChip('Hotels in Kandy'),
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
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A),
                  borderRadius: const BorderRadius.vertical(
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
                            hintText: 'Type your message...',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                            ),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF007CF0), Color(0xFF00DFD8)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _sendMessage,
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
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!message.isUser)
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF00DFD8),
              child: const Icon(Icons.chat, color: Colors.white, size: 16),
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
              child: Text(
                message.text,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          if (message.isUser) const SizedBox(width: 8),
          if (message.isUser)
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF007CF0),
              child: const Icon(Icons.person, color: Colors.white, size: 16),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return GestureDetector(
      onTap: () {
        _messageController.text = text;
        _sendMessage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF00DFD8).withOpacity(0.5)),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Color(0xFF00DFD8), fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildTypingDot(int delay) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}
