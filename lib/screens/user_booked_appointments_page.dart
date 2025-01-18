import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'video_call.dart';

class UserBookedAppointmentsPage extends StatefulWidget {
  const UserBookedAppointmentsPage({super.key});

  @override
  _UserBookedAppointmentsPageState createState() =>  
  _UserBookedAppointmentsPageState();
}

class _UserBookedAppointmentsPageState
    extends State<UserBookedAppointmentsPage> {
  final _currentUserEmail = FirebaseAuth.instance.currentUser!.email;
  String _selectedAppointmentType =
      'virtual'; // Default to virtual appointments

  void _joinVideoCall(String channelName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoCallPage(channelName: channelName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Booked Appointments'),
      ),
      body: Column(
        children: [
          // Toggle between virtual and physical appointments
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: const Text('Virtual Appointments'),
                selected: _selectedAppointmentType == 'virtual',
                onSelected: (selected) {
                  setState(() {
                    _selectedAppointmentType = 'virtual';
                  });
                },
              ),
              const SizedBox(width: 10),
              ChoiceChip(
                label: const Text('Physical Appointments'),
                selected: _selectedAppointmentType == 'physical',
                onSelected: (selected) {
                  setState(() {
                    _selectedAppointmentType = 'physical';
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(_selectedAppointmentType == 'virtual'
                      ? 'online_appointments'
                      : 'physical_appointments')
                  .where('email', isEqualTo: _currentUserEmail)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text('No appointments found'));
                }

                final appointments = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final appointmentDoc = appointments[index];
                    final appointment =
                        appointmentDoc.data() as Map<String, dynamic>;
                    final email = appointment['doctorEmail'];
                    final date = appointment['appointmentDate'];
                    final time = appointment['appointmentTime'];

                    return Card(
                      child: ListTile(
                        title: Text('Doctor: $email'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Date: $date'),
                            Text('Time: $time'),
                          ],
                        ),
                        trailing: _selectedAppointmentType == 'virtual'
                            ? IconButton(
                                icon: const Icon(Icons.videocam,
                                    color: Colors.blueAccent),
                                onPressed: () => _joinVideoCall(
                                    _currentUserEmail!), // Use user email as channel name
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
