import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'retrieve_file.dart'; // Import the FileRetrievalScreen page

class ViewReportPage extends StatefulWidget {
  const ViewReportPage({super.key});

  @override
  _ViewReportPageState createState() => _ViewReportPageState();
}

class _ViewReportPageState extends State<ViewReportPage> {
  final String _currentDoctorEmail = FirebaseAuth.instance.currentUser!.email!;

  // Method to fetch patient's name from the users collection
  Future<String> fetchPatientName(String userEmail) async {
    try {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: userEmail)
          .limit(1) // We expect only one result
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        return userSnapshot.docs.first['name'] ?? 'Unknown';
      } else {
        return 'Unknown'; // If no user is found with that email
      }
    } catch (e) {
      throw Exception('Failed to fetch patient name: $e');
    }
  }

  // Method to fetch transaction reports
  Future<List<Map<String, dynamic>>> fetchTransactionReports() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('doctorEmail', isEqualTo: _currentDoctorEmail)
          .get();

      if (snapshot.docs.isEmpty) {
        return [];
      }

      List<Map<String, dynamic>> reports = [];
      for (var doc in snapshot.docs) {
        reports.add(doc.data());
      }
      return reports;
    } catch (e) {
      throw Exception('Failed to fetch transaction reports: $e');
    }
  }

  // Method to navigate to FileRetrievalScreen with CID or Transaction ID
  void _navigateToFileRetrievalScreen(
    String transactionSignature, String encryptionKey) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => FileRetrievalScreen(
        transactionSignature: transactionSignature,  // Pass the transaction signature
        encryptionKey: encryptionKey,                // Pass the encryption key
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Transaction Report'),
        backgroundColor: Colors.orange,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchTransactionReports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No transaction reports found.'));
          }

          final reports = snapshot.data!;

          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              final signature = report['transactionSignature'] ?? 'N/A';
              final encryptionKey = report['encryptionKey'] ?? 'N/A';
              final userEmail = report['userEmail'] ?? 'N/A'; // Patient's email
              final doctorEmail =
                  report['doctorEmail'] ?? 'N/A'; // Doctor's email
              final transactionId = report['transactionId'] ??
                  'N/A'; // Transaction ID for file retrieval

              return FutureBuilder<String>(
                future: fetchPatientName(userEmail), // Fetch the patient's name
                builder: (context, nameSnapshot) {
                  if (nameSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (nameSnapshot.hasError) {
                    return Center(child: Text('Error: ${nameSnapshot.error}'));
                  }

                  if (!nameSnapshot.hasData || nameSnapshot.data!.isEmpty) {
                    return const Center(child: Text('No name available.'));
                  }

                  final patientName = nameSnapshot.data!;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 15),
                    elevation: 4,
                    child: ListTile(
                      title: Text('Patient Name: $patientName'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Patient Email: $userEmail'),
                       //   Text('Doctor Email: $doctorEmail'),
                          Text('Transaction Signature: $signature'),
                          Text('Encryption Key: $encryptionKey'),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                            Icons.file_download), // Medical report/file icon
                        onPressed: () {
                          _navigateToFileRetrievalScreen(
                            report['transactionSignature'] ??
                             'N/A', // Pass Transaction Signature); // Navigate to FileRetrievalScreen
                            report['encryptionKey'] ??
                                'N/A', // Pass Encryption Key  
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
