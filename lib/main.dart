import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth/_slpash.dart';
import 'auth/login_screen.dart';
import 'home/home_screen.dart';
import 'posts/create_post_screen.dart';
import 'user/profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://qmjufimqenugdvqdbqky.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFtanVmaW1xZW51Z2R2cWRicWt5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzU0NjM3NzksImV4cCI6MjA1MTAzOTc3OX0.fnfbsE5UUaEbTbcOdtUhfZ4zcDNq355MaflfIHnu7kI',
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder(
        future: _checkLoginStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return WelcomePage(); // or your splash screen
          } else if (snapshot.hasData && snapshot.data == true) {
            return MainScreen(); // User is logged in
          } else {
            return LoginPage(); // User is not logged in
          }
        },
      ),
      routes: {
        '/createPost': (context) => CreatePostScreen(),
        '/profile': (context) => ProfileScreen(),
      },
    );
  }

  Future<bool> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await prefs.setBool('isLoggedIn', true);
      return true;
    } else {
      await prefs.setBool('isLoggedIn', false);
      return false;
    }
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late PageController _pageController;
  static const platform = MethodChannel('com.example.notifications/notify');

  Future<void> _sendNotification(
    String message,
  ) async {
    try {
      await platform.invokeMethod('showNotification', {
        "message": message,
      });
    } on PlatformException catch (e) {
      print("Failed to send notification: '${e.message}'.");
    }
  }

  Future<void> _requestPermissions() async {
    // Requesting permissions
    PermissionStatus cameraStatus = await Permission.camera.status;
    PermissionStatus storageReadStatus = await Permission.storage.status;
    PermissionStatus storageWriteStatus =
        await Permission.manageExternalStorage.status;
    PermissionStatus mediaStatus = await Permission.mediaLibrary.status;
    PermissionStatus notificationsStatus = await Permission.notification.status;

    // Request permissions if not granted
    if (!cameraStatus.isGranted) {
      await Permission.camera.request();
    }
    if (!storageReadStatus.isGranted) {
      await Permission.storage.request();
    }
    if (!storageWriteStatus.isGranted) {
      await Permission.manageExternalStorage.request();
    }
    if (!mediaStatus.isGranted) {
      await Permission.mediaLibrary.request();
    }
    if (!notificationsStatus.isGranted) {
      await Permission.notification.request();
    }
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    listenToPosts();
  }

  void listenToPosts() {
    final supabase = Supabase.instance.client;

    final subscription = supabase
        .from('posts')
        .stream(primaryKey: ['id']) // You can specify a primary key if needed
        .order('created_at', ascending: false) // Optionally order the results
        .listen((List<Map<String, dynamic>> data) {
          if (data.isNotEmpty) {
            final payload = data.first; // Handle new record
            _sendNotification(payload['title']);

            String newNotification = payload['title'];
          }
        });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onItemTapped(int index) {
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          HomeScreen(),
          CreatePostScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(FontAwesomeIcons.house),
            label: 'home',
          ),
          BottomNavigationBarItem(
              icon: Icon(FontAwesomeIcons.add), label: 'create post'),
          BottomNavigationBarItem(
              icon: Icon(FontAwesomeIcons.solidUser), label: 'profile'),
        ],
      ),
    );
  }
}
