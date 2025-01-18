import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome to the Help Center!',
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'This app is designed to help you manage your health efficiently. Here you can book appointments, set reminders, authenticate securely using your voice, and store your medical data safely using blockchain technology.',
              style: TextStyle(fontSize: 16.0, color: Colors.black54),
            ),
            const SizedBox(height: 32.0),

            // **Voice Authentication**
            _buildHelpSection(
              context,
              title: 'Voice Authentication',
              description:
                  'Our app uses advanced voice recognition technology to verify your identity. Simply speak your name or passphrase when prompted, and the app will authenticate you securely. Make sure you have a clear voice and are in a quiet environment for the best results.',
            ),

            const SizedBox(height: 16.0),

            // **Appointment Booking**
            _buildHelpSection(
              context,
              title: 'Booking Appointments',
              description:
                  'To book an appointment, go to the "Appointment Booking" section in the app. Choose your preferred doctor, date, and time, and the app will automatically schedule the appointment for you.',
            ),

            const SizedBox(height: 16.0),

            // **Setting Reminders**
            _buildHelpSection(
              context,
              title: 'Setting Reminders',
              description:
                  'You can set reminders for your upcoming appointments, medication, or health check-ups. Simply go to the "Set Reminder" section, enter the details, and the app will send you a reminder at the time you specified.',
            ),

            const SizedBox(height: 16.0),

            // **Blockchain Integration**
            _buildHelpSection(
              context,
              title: 'Blockchain Integration',
              description:
                  'Our app uses blockchain technology to store your medical records securely and privately. This ensures that only you and authorized professionals can access your medical history. Blockchain guarantees the safety and integrity of your data, making it tamper-proof.',
            ),

            const SizedBox(height: 16.0),

            // **General Troubleshooting**
            _buildHelpSection(
              context,
              title: 'Troubleshooting',
              description:
                  'If you experience any issues with the app, try restarting the app or checking your internet connection. If voice authentication fails, make sure your microphone is working and there is minimal background noise. For appointment or reminder issues, verify that the details entered are correct.',
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to create sections
  Widget _buildHelpSection(BuildContext context, {
    required String title,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8.0),
        Text(
          description,
          style: const TextStyle(fontSize: 16.0, color: Colors.black87),
        ),
      ],
    );
  }
}