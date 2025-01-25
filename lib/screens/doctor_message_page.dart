import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DoctorMessagePage extends StatefulWidget {
  @override
  _DoctorMessagePageState createState() => _DoctorMessagePageState();
}

class _DoctorMessagePageState extends State<DoctorMessagePage> {
  final TextEditingController _messageController = TextEditingController();
  String? _selectedUserEmail; // To store the selected user's email
  String? _doctorEmail; // To store the logged-in doctor's email
  List<String> _userEmails = []; // List to store user emails from Firebase
  bool _isLoading = false; // To indicate loading state

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });
    await _fetchDoctorEmail();
    await _fetchUserEmails();
    setState(() {
      _isLoading = false;
    });
  }

  // Fetch the logged-in doctor's email from Firebase Authentication
  Future<void> _fetchDoctorEmail() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          _doctorEmail = user.email;
        });
      }
    } catch (e) {
      print('Error fetching doctor email: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching doctor email.')),
      );
    }
  }

  // Fetch user emails from Firebase
  Future<void> _fetchUserEmails() async {
    try {
      final QuerySnapshot userSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      final List<String> emails = userSnapshot.docs
          .map((doc) => doc.data()
              as Map<String, dynamic>) // Cast to Map<String, dynamic>
          .where(
              (data) => data.containsKey('email')) // Check for the 'email' key
          .map((data) => data['email'] as String) // Extract the email
          .toList();

      setState(() {
        _userEmails = emails;
      });
    } catch (e) {
      print('Error fetching user emails: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching user list.')),
      );
    }
  }

  // Save message to Firebase
  Future<void> _sendMessage() async {
    if (_selectedUserEmail != null &&
        _messageController.text.isNotEmpty &&
        _doctorEmail != null) {
      try {
        // Store the message details in Firebase
        await FirebaseFirestore.instance.collection('messages').add({
          'doctorEmail': _doctorEmail,
          'userEmail': _selectedUserEmail,
          'message': _messageController.text,
          'timestamp': FieldValue.serverTimestamp(), // Timestamp for sorting
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Message sent successfully!')),
        );

        _messageController.clear(); // Clear the message box
        setState(() {}); // Refresh UI to disable button
      } catch (e) {
        print('Error sending message: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a user and write a message.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Doctor Message Page'),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child:
                  CircularProgressIndicator()) // Show loader while fetching data
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display the logged-in doctor's email
                  if (_doctorEmail != null)
                    Text(
                      'Logged in as: $_doctorEmail',
                      style: TextStyle(
                          fontSize: 16.0, fontWeight: FontWeight.bold),
                    ),
                  const SizedBox(height: 20.0),

                  // Dropdown to select user email
                  Text(
                    'Select User:',
                    style:
                        TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<String>(
                    value: _selectedUserEmail,
                    isExpanded: true,
                    hint: Text('Choose a user'),
                    items: _userEmails.map((email) {
                      return DropdownMenuItem<String>(
                        value: email,
                        child: Text(email),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedUserEmail = value;
                      });
                    },
                  ),
                  if (_userEmails.isEmpty)
                    Text(
                      'No users available.',
                      style: TextStyle(color: Colors.red),
                    ),
                  const SizedBox(height: 20.0),

                  // Message box
                  Text(
                    'Write Message:',
                    style:
                        TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                  ),
                  TextField(
                    controller: _messageController,
                    maxLines: 5,
                    onChanged: (_) => setState(() {}), // Trigger UI update
                    decoration: InputDecoration(
                      hintText: 'Type your message here...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  // Send Message button
                  Center(
                    child: ElevatedButton(
                      onPressed: (_selectedUserEmail != null &&
                              _messageController.text.isNotEmpty)
                          ? _sendMessage
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, // Restore green color
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30.0, vertical: 15.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      child: Text(
                        'Send Message',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
