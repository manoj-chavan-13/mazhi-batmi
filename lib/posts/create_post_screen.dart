import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _titleController =
      TextEditingController(); // New title controller
  final SupabaseClient _supabase = Supabase.instance.client;
  XFile? _mediaFile;
  final List<String> _categories = [
    'All',
    'News',
    'Technology',
    'Sports',
    'Entertainment',
    'Politics'
  ];
  final List<String> _locations = [
    'Mumbai',
    'Delhi',
    'Bangalore',
    'Chennai',
    'Hyderabad'
  ];
  String? _selectedCategory = 'All';
  String? _selectedLocation;
  String _visibility = 'Public';

  final ImagePicker _picker = ImagePicker();
  final FocusNode _textFieldFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_textFieldFocusNode);
    });
  }

  Future<void> _pickMedia(ImageSource source, String type) async {
    try {
      XFile? pickedFile;
      if (type == 'image') {
        pickedFile = await _picker.pickImage(source: source);
      } else if (type == 'video') {
        pickedFile = await _picker.pickVideo(source: source);
      }

      if (pickedFile != null) {
        setState(() {
          _mediaFile = pickedFile;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick media: $e')),
      );
    }
  }

  void _removeMedia() {
    setState(() {
      _mediaFile = null;
    });
  }

  void _submitPost() async {
    if (_titleController.text.isEmpty ||
        _textController.text.isEmpty ||
        _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    try {
      String mediaUrl = '';

      // Insert post data into Supabase table
      final user = Supabase.instance.client.auth.currentUser;

      final senderName = await Supabase.instance.client
          .from(
              'users') // Assuming 'users' is the name of the table where user profile is stored
          .select('name') // Fetching the 'name' field from the 'users' table
          .eq('uid', user!.id) // Filter by the current user ID
          .single();

      // If media exists, upload it to Supabase Storage
      if (_mediaFile != null) {
        final file = File(_mediaFile!.path);
        final storageResponse = await _supabase.storage
            .from('posts')
            .upload(_mediaFile!.name, file);

        mediaUrl =
            _supabase.storage.from('posts').getPublicUrl(_mediaFile!.name);
      } else {
        mediaUrl =
            'https://img.freepik.com/free-vector/people-watching-news-concept-illustration_114360-2319.jpg?t=st=1735971452~exp=1735975052~hmac=d881f44d580176c0f6662b5a5dd697ae326c07b84339b6b4d4020b2ad499c040&w=740';
      }

      final response = await Supabase.instance.client.from('posts').insert({
        'sender_name': senderName['name'],
        'user_id': user.id,
        'title': _titleController.text, // Include the title in the post
        'content': _textController.text,
        'media_url': mediaUrl,
        'category': _selectedCategory,
        'location': _selectedLocation,
        'visibility': _visibility,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (response == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Post submitted successfully!')),
        );
        _titleController.clear(); // Clear the title field
        _textController.clear(); // Clear the content field
        setState(() {
          _mediaFile = null;
          _selectedCategory = 'All';
          _selectedLocation = null;
          _visibility = 'Public';
        });
      } else {
        throw Exception('Failed to create post');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
                height: 26), // Top Row: Visibility, Location, Submit Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Visibility Dropdown
                DropdownButton<String>(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  elevation: 4,
                  dropdownColor: Colors.white,
                  value: _visibility,
                  items: ['Public', 'Private'].map((visibility) {
                    return DropdownMenuItem(
                      value: visibility,
                      child: Text(visibility),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _visibility = value!;
                    });
                  },
                  underline: SizedBox(),
                  style: TextStyle(color: Colors.black, fontSize: 14),
                  icon: Icon(Icons.arrow_drop_down),
                ),

                // Location Dropdown
                DropdownButton<String>(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  elevation: 4,
                  dropdownColor: Colors.white,
                  hint: Text('Location'),
                  value: _selectedLocation,
                  items: _locations.map((location) {
                    return DropdownMenuItem(
                      value: location,
                      child: Text(location),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedLocation = value;
                    });
                  },
                  underline: SizedBox(),
                  style: TextStyle(color: Colors.black, fontSize: 14),
                  icon: Icon(Icons.arrow_drop_down),
                ),

                // Submit Button
                IconButton(
                  onPressed: _submitPost,
                  icon: Icon(Icons.send, size: 24),
                  color: const Color.fromARGB(255, 130, 130, 130),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                )
              ],
            ),
            SizedBox(height: 16),

            // Title Field
            TextField(
              controller: _titleController, // Connect the title controller
              decoration: InputDecoration(
                hintText: 'Enter post title...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color: const Color.fromARGB(255, 212, 212, 212)),
                ),
                contentPadding: EdgeInsets.all(12),
              ),
            ),
            SizedBox(height: 16),
            // Expanded Text Field (fills remaining space)
            Expanded(
              child: TextField(
                controller: _textController,
                focusNode: _textFieldFocusNode,
                maxLines: 100,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: 'Write your post here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                        color: const Color.fromARGB(255, 212, 212, 212)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                        color: const Color.fromARGB(255, 212, 212, 212)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                        color: const Color.fromARGB(255, 162, 162, 162)),
                  ),
                  contentPadding: EdgeInsets.all(12),
                  filled: true,
                  fillColor: const Color.fromARGB(255, 243, 243, 243),
                ),
              ),
            ),

            // Media Preview (with option to remove)
            if (_mediaFile != null)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _mediaFile!.path.endsWith('mp4')
                    ? Center(
                        child:
                            Icon(Icons.videocam, size: 50, color: Colors.green))
                    : Image.file(File(_mediaFile!.path), fit: BoxFit.cover),
              ),
            SizedBox(height: 16),

            // Bottom Row: Category, Add Image, Add Video
            Row(
              children: [
                // Category Dropdown
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: const Color.fromARGB(255, 0, 0, 0),
                              width: 2), // Border color when focused
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: const Color.fromARGB(255, 1, 1, 1),
                              width:
                                  1), // Border color when enabled but not focused
                        ),
                        focusColor: Colors.black,
                        fillColor: Colors.white),
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                    elevation: 2,
                    value: _selectedCategory,
                    items: _categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                    dropdownColor: const Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
                SizedBox(width: 8),

                // Add Image Button
                IconButton(
                  onPressed: _mediaFile == null
                      ? () => _pickMedia(ImageSource.gallery, 'image')
                      : null,
                  icon: Icon(Icons.image),
                  color: const Color.fromARGB(255, 0, 138, 57),
                  padding: EdgeInsets.zero,
                  iconSize: 28,
                ),

                // Add Video Button
              ],
            ),
          ],
        ),
      ),
    );
  }
}
