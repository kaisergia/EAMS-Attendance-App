import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Supabase Configuration
const String supabaseUrl = 'https://kiafesclibvrecjpfeku.supabase.co';
const String supabaseAnonKey = 'sb_publishable_5RwmLdO8UZHXDQ0-dQCGww_U6wvUCsq';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GCC Attendance Scanner',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF96161C),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Poppins',
      ),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Color Constants
const Color primaryRed = Color(0xFF96161C);
const Color darkRed = Color(0xFF540B0E);
const Color backgroundColor = Colors.white;
const Color lightGray = Color(0xFFF5F5F5);

// Supabase Service
class SupabaseService {
  static final supabase = Supabase.instance.client;

  // Sign up with email and password
  static Future<AuthResponse> signUpWithEmail(
      String email, String password) async {
    return await supabase.auth.signUp(email: email, password: password);
  }

  // Sign in with email and password
  static Future<AuthResponse> signInWithEmail(
      String email, String password) async {
    return await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign in with Google
  static Future<void> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn();
      final googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) return;
      
      // For this implementation, we'll use the Google sign-in 
      // without OAuth flow. The user is authenticated via Google locally.
      // In production, you'd send the ID token to your backend.
    } catch (e) {
      rethrow;
    }
  }

  // Get current user
  static User? getCurrentUser() {
    return supabase.auth.currentUser;
  }

  // Sign out
  static Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  // Check if user is logged in
  static bool isLoggedIn() {
    return supabase.auth.currentUser != null;
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;
  bool _isSignUp = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo/Icon Row at Top
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/icons/cjc_logo.png',
                    width: 80,
                    height: 80,
                  ),
                  const SizedBox(width: 30),
                  Image.asset(
                    'assets/icons/gcc_logo.png',
                    width: 80,
                    height: 80,
                  ),
                ],
              ),
              const SizedBox(height: 50),
              Text(
                'GCC Attendance Monitoring App',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: darkRed,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                'Attendance Management System',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 40),
              // Email Field
              TextField(
                controller: _emailController,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: const TextStyle(color: primaryRed),
                  hintText: 'Enter email',
                  prefixIcon: Icon(Icons.email_outlined, color: primaryRed),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryRed, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: darkRed, width: 2),
                  ),
                  filled: true,
                  fillColor: lightGray,
                ),
              ),
              const SizedBox(height: 16),
              // Password Field
              TextField(
                controller: _passwordController,
                obscureText: _obscureText,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: primaryRed),
                  hintText: 'Enter password',
                  prefixIcon: Icon(Icons.lock_outline, color: primaryRed),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: primaryRed,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryRed, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: darkRed, width: 2),
                  ),
                  filled: true,
                  fillColor: lightGray,
                ),
              ),
              const SizedBox(height: 30),
              // Login/Sign Up Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: Material(
                  color: primaryRed,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: _isLoading
                        ? null
                        : () => _isSignUp ? _handleSignUp() : _handleLogin(),
                    child: Align(
                      alignment: Alignment.center,
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              ),
                            )
                          : Text(
                              _isSignUp ? 'Sign Up' : 'Login',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Toggle Sign Up / Login
              GestureDetector(
                onTap: _isLoading
                    ? null
                    : () {
                        setState(() {
                          _isSignUp = !_isSignUp;
                          _emailController.clear();
                          _passwordController.clear();
                        });
                      },
                child: Text(
                  _isSignUp
                      ? 'Already have an account? Login'
                      : "Don't have an account? Sign Up",
                  style: const TextStyle(
                    color: primaryRed,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Divider
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Colors.grey[300],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Colors.grey[300],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Google Sign In Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: _isLoading ? null : _handleGoogleSignIn,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: primaryRed, width: 2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.g_mobiledata,
                            color: primaryRed,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Sign in with Google',
                            style: TextStyle(
                              color: darkRed,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await SupabaseService.signInWithEmail(
        _emailController.text,
        _passwordController.text,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const EventDashboard()),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Login failed';
        if (e.toString().contains('Invalid login credentials') || 
            e.toString().contains('invalid credentials')) {
          errorMessage = 'Incorrect email or password. Please try again.';
        } else if (e.toString().contains('User not found')) {
          errorMessage = 'This email is not registered. Please sign up first.';
        } else if (e.toString().contains('Email not confirmed')) {
          errorMessage = 'Please confirm your email before logging in.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignUp() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await SupabaseService.signUpWithEmail(
        _emailController.text,
        _passwordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Sign up successful! Check your email to confirm your account.'),
            backgroundColor: Colors.green,
          ),
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _isSignUp = false;
              _emailController.clear();
              _passwordController.clear();
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign up failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      await SupabaseService.signInWithGoogle();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const EventDashboard()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google sign in failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class EventDashboard extends StatefulWidget {
  const EventDashboard({super.key});

  @override
  State<EventDashboard> createState() => _EventDashboardState();
}

class _EventDashboardState extends State<EventDashboard> {
  late List<Event> events;

  @override
  void initState() {
    super.initState();
    events = [
      Event(
        id: '1',
        name: 'Science Workshop',
        description: 'Advanced Physics & Chemistry',
        icon: Icons.science,
      ),
      Event(
        id: '2',
        name: 'Art Exhibition',
        description: 'Student Artwork Showcase',
        icon: Icons.palette,
      ),
      Event(
        id: '3',
        name: 'Sports Day',
        description: 'Annual Athletic Competition',
        icon: Icons.sports_soccer,
      ),
      Event(
        id: '4',
        name: 'Tech Conference',
        description: 'Innovation & Technology',
        icon: Icons.computer,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryRed,
        elevation: 0,
        title: const Text(
          'Attendance Events',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await SupabaseService.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Available Events',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: darkRed,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  return EventCard(
                    event: events[index],
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              AttendanceScreen(event: events[index]),
                        ),
                      );
                    },
                    onDelete: () {
                      setState(() {
                        events.removeAt(index);
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
              Center(
                child: FloatingActionButton.extended(
                  backgroundColor: primaryRed,
                  onPressed: () {
                    _showAddEventDialog();
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Add Event',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddEventDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    IconData selectedIcon = Icons.event;

    final iconOptions = [
      Icons.event,
      Icons.science,
      Icons.palette,
      Icons.sports_soccer,
      Icons.computer,
      Icons.music_note,
      Icons.camera_alt,
      Icons.book,
      Icons.sports_basketball,
      Icons.theater_comedy,
      Icons.volunteer_activism,
      Icons.groups,
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            backgroundColor: backgroundColor,
            title: Text(
              'Create New Event',
              style: TextStyle(color: darkRed, fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Event Name',
                      labelStyle: const TextStyle(color: primaryRed),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: primaryRed),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      labelStyle: const TextStyle(color: primaryRed),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: primaryRed),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Select Icon',
                    style: TextStyle(color: darkRed, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: primaryRed),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 4,
                        crossAxisSpacing: 4,
                      ),
                      itemCount: iconOptions.length,
                      itemBuilder: (context, index) {
                        final icon = iconOptions[index];
                        final isSelected = selectedIcon == icon;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedIcon = icon;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? primaryRed : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected
                                  ? null
                                  : Border.all(
                                      color: primaryRed.withValues(alpha: 0.3)),
                            ),
                            child: Icon(
                              icon,
                              color: isSelected ? Colors.white : primaryRed,
                              size: 24,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: primaryRed)),
              ),
              TextButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    this.setState(() {
                      events.add(
                        Event(
                          id: DateTime.now().toString(),
                          name: nameController.text,
                          description: descController.text,
                          icon: selectedIcon,
                        ),
                      );
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text('Create', style: TextStyle(color: primaryRed)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class EventCard extends StatefulWidget {
  final Event event;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const EventCard({
    required this.event,
    required this.onTap,
    required this.onDelete,
    super.key,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _animationController.forward().then((_) {
      _animationController.reverse();
      widget.onTap();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: _handleTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: primaryRed.withValues(alpha: 0.15),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 180,
            maxHeight: 180,
          ),
          child: Stack(
            children: [
              // Glass morphism background
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withValues(alpha: 0.15),
                  border: Border.all(
                    color: Colors.black,
                    width: 1,
                  ),
                ),
              ),
              // Content
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryRed.withValues(alpha: 0.2),
                          ),
                          child: Icon(
                            widget.event.icon,
                            color: primaryRed,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Flexible(
                              child: Text(
                                widget.event.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: darkRed,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Flexible(
                              child: Text(
                                widget.event.description,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 10,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Delete button
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: widget.onDelete,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(6),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
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
}

class AttendanceScreen extends StatefulWidget {
  final Event event;

  const AttendanceScreen({required this.event, super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final _studentIdController = TextEditingController();
  String? scannedId;
  bool _showScanner = false;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryRed,
        elevation: 0,
        title: Text(
          widget.event.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Event Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryRed.withValues(alpha: 0.1),
                  border: Border.all(color: primaryRed, width: 2),
                ),
                child: Icon(
                  widget.event.icon,
                  color: primaryRed,
                  size: 50,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Mark Attendance',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: darkRed,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.event.description,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 40),

              if (_showScanner)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: primaryRed, width: 2),
                    ),
                    child: Stack(
                      children: [
                        MobileScanner(
                          onDetect: (capture) {
                            // Prevent multiple scans while processing
                            if (_isProcessing) return;
                            
                            final List<Barcode> barcodes = capture.barcodes;
                            if (barcodes.isNotEmpty) {
                              final String scannedValue = barcodes.first.rawValue ?? '';
                              if (scannedValue.isNotEmpty) {
                                // Set flag immediately before setState to prevent race conditions
                                _isProcessing = true;
                                
                                setState(() {
                                  scannedId = scannedValue;
                                });
                                
                                // Auto-submit immediately
                                Future.delayed(const Duration(milliseconds: 300), () {
                                  if (mounted) {
                                    _submitAttendance();
                                  }
                                });
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                )
              else
                // Manual Entry
                Column(
                  children: [
                    TextField(
                      controller: _studentIdController,
                      decoration: InputDecoration(
                        labelText: 'Student ID',
                        labelStyle: const TextStyle(color: primaryRed),
                        hintText: 'Enter student ID',
                        prefixIcon: Icon(Icons.person, color: primaryRed),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: primaryRed, width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: darkRed, width: 2),
                        ),
                        filled: true,
                        fillColor: lightGray,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),

              const SizedBox(height: 30),

              // Toggle Scanner Mode Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: Material(
                  color: _showScanner ? darkRed : primaryRed,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _showScanner = !_showScanner;
                        scannedId = null;
                        _studentIdController.clear();
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _showScanner ? Icons.edit : Icons.qr_code_scanner,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _showScanner ? 'Manual Entry' : 'Scan Barcode',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Tip for Scanner Mode
              if (_showScanner)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryRed, width: 1),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info, color: primaryRed, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Point your camera at a barcode to scan',
                          style: TextStyle(color: primaryRed, fontSize: 12),
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

  void _submitAttendance() {
    final id = _showScanner
        ? scannedId
        : _studentIdController.text.isEmpty
            ? null
            : _studentIdController.text;

    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please scan or enter a student ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        title: const Text(
          'Attendance Marked',
          style: TextStyle(color: darkRed, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified, color: Colors.green, size: 50),
            const SizedBox(height: 16),
            Text(
              'Event: ${widget.event.name}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Student ID: $id',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Time: ${DateTime.now().toString().substring(0, 19)}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                scannedId = null;
                _isProcessing = false;
                _studentIdController.clear();
              });
            },
            child: const Text('OK', style: TextStyle(color: primaryRed)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    super.dispose();
  }
}

class Event {
  final String id;
  final String name;
  final String description;
  final IconData icon;

  Event({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });
}
