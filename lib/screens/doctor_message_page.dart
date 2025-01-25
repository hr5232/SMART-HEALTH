import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DoctorMessagePage extends StatefulWidget {
  @override
  _DoctorMessagePageState createState() => _DoctorMessagePageState();
}

class _DoctorMessagePageState extends State<DoctorMessagePage> {
  final TextEditingController _messageController = TextEditingController();
  String? _selectedUserEmail; // To store the selected user's email
  List<String> _userEmails = []; // List to store user emails from Firebase

  @override
  void initState() {
    super.initState();
    _fetchUserEmails(); // Fetch user emails from Firebase on page load
  }

  // Fetch user emails from Firebase
  Future<void> _fetchUserEmails() async {
    try {
      final QuerySnapshot userSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      final List<String> emails = userSnapshot.docs
          .map((doc) => doc['email'] as String) // Assuming 'email' is the field
          .toList();

      setState(() {
        _userEmails = emails;
      });
    } catch (e) {
      print('Error fetching user emails: $e');
    }
  }

  // Save message to Firebase
  Future<void> _sendMessage() async {
    if (_selectedUserEmail != null && _messageController.text.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('messages') // Storing in the 'messages' collection
            .doc(
                _selectedUserEmail) // Using the selected user's email as doc ID
            .set({
          'email': _selectedUserEmail,
          'message': _messageController.text,
          'timestamp': FieldValue.serverTimestamp(), // Timestamp for sorting
        }, SetOptions(merge: true));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Message sent successfully!')),
        );

        _messageController.clear(); // Clear the message box
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dropdown to select user email
            Text(
              'Select User:',
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
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
            const SizedBox(height: 20.0),

            // Message box
            Text(
              'Write Message:',
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _messageController,
              maxLines: 5,
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
                onPressed: _sendMessage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // Nice green color
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
