import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../services/auth_service.dart';
import '../widgets/feature_card.dart';
import '../widgets/weather_card.dart';
import '../widgets/destination_card.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Store BuildContext for safe use in async callbacks
  BuildContext? _dialogContext;

  @override
  void dispose() {
    // Clear the stored context when widget is disposed
    _dialogContext = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF001F3F), Color(0xFF0074D9), Color(0xFF7FDBFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Bar with back button style
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {
                        // Optional: Show confirmation dialog or exit app
                      },
                      icon: Icon(Icons.menu, color: Colors.white),
                      padding: EdgeInsets.zero,
                    ),
                    Text(
                      'AI Travel Companion',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (value) {
                        if (value == 'logout') {
                          _showLogoutConfirmation(context);
                        } else if (value == 'profile') {
                          _showProfileDialog(context, authService);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(value: 'profile', child: Text('Profile')),
                        PopupMenuItem(value: 'logout', child: Text('Logout')),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 20),

                // Animation
                Container(
                  height: 120,
                  child: Lottie.asset(
                    'assets/animations/travel_animation.json',
                    fit: BoxFit.contain,
                  ),
                ),

                SizedBox(height: 20),

                // Welcome text
                Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                SizedBox(height: 8),

                Text(
                  'Ready to explore beautiful Sri Lanka?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),

                SizedBox(height: 40),

                // Weather card
                WeatherCard(),

                SizedBox(height: 30),

                // Quick actions title
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                SizedBox(height: 20),

                // Quick actions grid
                _buildQuickActions(context),

                SizedBox(height: 30),

                // Featured destinations header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Featured Destinations',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _showFeatureMessage(
                          context,
                          'Explore All',
                          'Browse all destinations coming soon!',
                        );
                      },
                      child: Text(
                        'See All',
                        style: TextStyle(
                          color: Color(0xFF00DFD8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20),

                // Featured destinations list
                _buildFeaturedDestinations(context),

                SizedBox(height: 30),

                // Plan My Trip button - Same style as login/signup buttons
                Container(
                  width: double.infinity,
                  height: 65,
                  child: Material(
                    borderRadius: BorderRadius.circular(18),
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        _showFeatureMessage(
                          context,
                          'AI Planner',
                          'AI Trip Planner coming soon!',
                        );
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF007CF0), Color(0xFF00DFD8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF007CF0).withOpacity(0.4),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                color: Colors.white,
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'PLAN MY TRIP WITH AI',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        FeatureCard(
          title: 'AI Planner',
          subtitle: 'Smart Itinerary',
          icon: Icons.auto_awesome,
          color: Colors.white,
          onTap: () => _showFeatureMessage(
            context,
            'AI Planner',
            'Generate smart itineraries with AI',
          ),
        ),
        FeatureCard(
          title: 'Explore',
          subtitle: 'Destinations',
          icon: Icons.explore,
          color: Colors.white,
          onTap: () => _showFeatureMessage(
            context,
            'Explore',
            'Discover amazing places in Sri Lanka',
          ),
        ),
        FeatureCard(
          title: 'Chat Assistant',
          subtitle: '24/7 Help',
          icon: Icons.chat,
          color: Colors.white,
          onTap: () => _showFeatureMessage(
            context,
            'Chat Assistant',
            'Get instant travel assistance',
          ),
        ),
        FeatureCard(
          title: 'Offline Maps',
          subtitle: 'No Internet',
          icon: Icons.map,
          color: Colors.white,
          onTap: () => _showFeatureMessage(
            context,
            'Offline Maps',
            'Download maps for offline use',
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedDestinations(BuildContext context) {
    final featuredDestinations = [
      {
        'name': 'Sigiriya Rock',
        'location': 'Central Province',
        'image': 'assets/images/sigiriya.jpg',
        'rating': 4.8,
      },
      {
        'name': 'Galle Fort',
        'location': 'Southern Province',
        'image': 'assets/images/galle_fort.jpg',
        'rating': 4.6,
      },
      {
        'name': 'Ella Rock',
        'location': 'Uva Province',
        'image': 'assets/images/ella.jpg',
        'rating': 4.7,
      },
      {
        'name': 'Temple of Tooth',
        'location': 'Kandy',
        'image': 'assets/images/temple.jpg',
        'rating': 4.5,
      },
    ];

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: featuredDestinations.length,
        itemBuilder: (context, index) {
          final destination = featuredDestinations[index];
          return DestinationCard(
            name: destination['name'] as String,
            location: destination['location'] as String,
            rating: destination['rating'] as double,
            onTap: () {
              _showDestinationDetail(context, destination['name'] as String);
            },
          );
        },
      ),
    );
  }

  void _showFeatureMessage(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1E3A8A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF00DFD8), size: 24),
              SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(message, style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK', style: TextStyle(color: Color(0xFF00DFD8))),
            ),
          ],
        );
      },
    );
  }

  void _showDestinationDetail(BuildContext context, String name) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1E3A8A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            name,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [Color(0xFF007CF0), Color(0xFF00DFD8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(Icons.landscape, color: Colors.white, size: 50),
              ),
              SizedBox(height: 16),
              Text(
                'Discover the beauty of $name with our AI-powered travel guide.',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showFeatureMessage(
                  context,
                  'Add to Trip',
                  '$name added to your itinerary!',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF00DFD8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text('Add to Trip', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showProfileDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1E3A8A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.person, color: Color(0xFF00DFD8), size: 28),
              SizedBox(width: 10),
              Text(
                'Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFF00DFD8),
                  child: Text(
                    _getUserInitials(authService.userName),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  authService.userName ?? 'Traveler',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  authService.userEmail ?? 'No email',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Travel Stats',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00DFD8),
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('Trips', '0'),
                        _buildStatItem('Places', '0'),
                        _buildStatItem('Badges', '0'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Color(0xFF00DFD8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Close',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getUserInitials(String? userName) {
    if (userName == null || userName.isEmpty) return 'T';
    final names = userName.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return userName[0].toUpperCase();
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF00DFD8),
          ),
        ),
        SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1E3A8A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.logout, color: Colors.orange, size: 24),
              SizedBox(width: 10),
              Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () async {
                // Close the dialog first
                Navigator.pop(context);

                try {
                  // Get authService using the current context
                  final authService = Provider.of<AuthService>(
                    context,
                    listen: false,
                  );

                  // Sign out
                  await authService.signOut();

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.green,
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 10),
                          Text('Logged out successfully'),
                        ],
                      ),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );

                  // Navigate to login screen IMMEDIATELY
                  // Use Future.microtask for immediate navigation
                  Future.microtask(() {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                      (route) => false,
                    );
                  });
                } catch (error) {
                  // Handle error
                  _showErrorDialog(context, 'Logout Failed', error.toString());
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1E3A8A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.orange, size: 24),
            SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(message, style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Color(0xFF00DFD8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'OK',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
