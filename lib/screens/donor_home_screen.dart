import 'package:flutter/material.dart';

import '../widgets/notification_button.dart';
import 'donor/donor_emergency_screen.dart';

class DonorHomeScreen extends StatelessWidget {
  const DonorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MyDarah'),
        actions: const [NotificationButton()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              'Hi, Donor 👋',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Welcome back!',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Card(
              color: Colors.red,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'You can save lives',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Be a blood donor',
                            style: TextStyle(color: Colors.white),
                          ),
                          SizedBox(height: 18),
                          Text(
                            'Keep your donor profile updated',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.bloodtype, size: 70, color: Colors.white),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DonorEmergencyScreen(),
                  ),
                ),
                leading: const Icon(
                  Icons.emergency_outlined,
                  color: Colors.red,
                ),
                title: const Text('Emergency blood requests'),
                subtitle: const Text(
                  'View active requests matching your profile',
                ),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: const [
                HomeMenuItem(icon: Icons.location_on, title: 'Find Centre'),
                HomeMenuItem(icon: Icons.event, title: 'Events'),
                HomeMenuItem(icon: Icons.history, title: 'My Donations'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class HomeMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;

  const HomeMenuItem({super.key, required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.red, size: 35),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
