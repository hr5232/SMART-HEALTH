import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'about_us_page.dart';
import 'ambulance_booking_page.dart';
import 'help_page.dart';
import 'upload_medical_report_page.dart';
import 'user_booked_appointments_page.dart';
import 'user_message_page.dart';
import 'virtual_physical_page.dart';
import 'view_remainders_page.dart';

class UserHomePage extends StatelessWidget {
  const UserHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Fetch the logged-in user's email
    final userEmail = FirebaseAuth.instance.currentUser?.email;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'User Home Page',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22.0,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 1, 133, 118),
        elevation: 5.0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Welcome User!',
                  style: TextStyle(
                    fontSize: 28.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 30.0),

                // Appointment Booking Button
                _buildCardButton(
                  context,
                  label: 'Appointment Booking',
                  color: Colors.blue,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const VirtualPhysicalPage()),
                    );
                  },
                  icon: Icons.calendar_today,
                ),

                // Set Reminder Button
                _buildCardButton(
                  context,
                  label: 'Set Reminder',
                  color: const Color.fromARGB(255, 125, 115, 27),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ViewRemindersPage()),
                    );
                  },
                  icon: Icons.notifications,
                ),

                // Upload Medical Report Button
                _buildCardButton(
                  context,
                  label: 'Upload Medical Report',
                  color: const Color.fromARGB(255, 223, 17, 182),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const UploadMedicalReportPage()),
                    );
                  },
                  icon: Icons.upload,
                ),

                // My Appointments Button
                _buildCardButton(
                  context,
                  label: 'My Appointments',
                  color: Colors.green,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const UserBookedAppointmentsPage()),
                    );
                  },
                  icon: Icons.assignment,
                ),

                // My Messages Button
                _buildCardButton(
                  context,
                  label: 'My Messages',
                  color: const Color.fromARGB(255, 1, 59, 136),
                  onPressed: () {
                    if (userEmail != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              UserMessagePage(userEmail: userEmail),
                        ),
                      );
                    } else {
                      // Show an error if the userEmail is null
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Error: Unable to fetch user email. Please log in again.'),
                        ),
                      );
                    }
                  },
                  icon: Icons.message_outlined,
                ),

                // Ambulance Booking Button
                _buildCardButton(
                  context,
                  label: 'Ambulance Booking',
                  color: Colors.red,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AmbulanceBookingPage()),
                    );
                  },
                  icon: Icons.local_hospital,
                ),

                // Help Button
                _buildCardButton(
                  context,
                  label: 'Help',
                  color: Colors.orange,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HelpPage()),
                    );
                  },
                  icon: Icons.help_outline,
                ),

                // About Us Button
                _buildCardButton(
                  context,
                  label: 'About Us',
                  color: Colors.purple,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AboutUsPage()),
                    );
                  },
                  icon: Icons.info_outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build a styled button inside a Card widget
  Widget _buildCardButton(
    BuildContext context, {
    required String label,
    required Color color,
    required VoidCallback onPressed,
    required IconData icon,
  }) {
    return Card(
      elevation: 8.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10.0),
        tileColor: color.withOpacity(0.1),
        leading: Icon(
          icon,
          color: color,
          size: 30.0,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        onTap: onPressed,
      ),
    );
  }
}
