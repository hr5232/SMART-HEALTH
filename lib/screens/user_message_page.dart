import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserMessagePage extends StatelessWidget {
  final String
      userEmail; // Pass the user's email to fetch messages specific to them

  UserMessagePage({required this.userEmail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Messages for $userEmail'),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('messages') // Collection containing messages
            .doc(userEmail) // Document for the specific user's email
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                'No messages yet!',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w500),
              ),
            );
          }

          // Fetch the data from the document
          Map<String, dynamic>? data =
              snapshot.data!.data() as Map<String, dynamic>?;

          String? message = data?['message']; // Retrieve the message field
          String? doctorEmail =
              data?['doctorEmail']; // Retrieve the doctor's email
          Timestamp? timestamp =
              data?['timestamp']; // Retrieve the timestamp field

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Message:',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),
                Text(
                  message ?? 'No message available.',
                  style: TextStyle(fontSize: 16.0),
                ),
                const SizedBox(height: 20.0),
                Text(
                  'Sent by:',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),
                Text(
                  doctorEmail ?? 'Unknown Doctor',
                  style: TextStyle(fontSize: 16.0),
                ),
                const SizedBox(height: 20.0),
                Text(
                  'Received at:',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),
                Text(
                  timestamp != null
                      ? DateTime.fromMillisecondsSinceEpoch(
                              timestamp.millisecondsSinceEpoch)
                          .toString()
                      : 'No timestamp available.',
                  style: TextStyle(fontSize: 16.0),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
