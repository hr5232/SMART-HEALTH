import 'package:flutter/material.dart';
import 'package:harry/screens/appoinment_booked_page.dart';
import 'package:harry/screens/set_schedule_page.dart';
import 'package:harry/screens/view_report_page.dart';
import 'package:harry/screens/doctor_message_page.dart';

class DoctorHomePage extends StatelessWidget {
  const DoctorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Home Page'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blueGrey],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          image: DecorationImage(
            image: AssetImage("assets/img/image.jpg"), // Background image
            fit: BoxFit.cover,
            opacity: 0.3,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Welcome Doctor!',
                style: TextStyle(
                  fontSize: 28.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10.0),
              const Text(
                'Manage your appointments and schedules with ease.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16.0, color: Colors.black54),
              ),
              const SizedBox(height: 30.0),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 20.0),
                elevation: 5.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AppointmentBookedPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.calendar_today, size: 20.0),
                        label: const Text('Appointments'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20.0, vertical: 15.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15.0),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SetSchedulePage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.schedule, size: 20.0),
                        label: const Text('Set Schedule'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20.0, vertical: 15.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15.0),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ViewReportPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.article, size: 20.0),
                        label: const Text('View Report'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20.0, vertical: 15.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15.0),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DoctorMessagePage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.message_outlined, size: 20.0),
                        label: const Text('Send Message'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 4, 233, 245),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20.0, vertical: 15.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
