import 'package:flutter/material.dart';

class AdminDashboard extends StatelessWidget {
  final String userName;

  // Constructor لاستقبال اسم المستخدم
  const AdminDashboard({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("لوحة التحكم - Admin"),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pop(context), // العودة لصفحة Login
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        color: const Color(0xFFF4F7FA),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.orangeAccent,
              child: Icon(Icons.admin_panel_settings, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              "Bienvenue, $userName",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "تم الدخول بنجاح بصلاحيات المسؤول",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            
            // زر تجريبي للتأكد من التفاعل
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("الزر يعمل بنجاح!")),
                );
              },
              icon: const Icon(Icons.check),
              label: const Text("اختبار النظام"),
            ),
          ],
        ),
      ),
    );
  }
}