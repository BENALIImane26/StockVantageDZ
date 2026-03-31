import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 1. أضفنا هذا السطر
//import 'etat_stock_page.dart'; 
import 'gestionnaire_de_stock_page.dart';
//import 'login_page.dart';
//import 'gestion_utilisateurs.dart';
Future<void> main() async { // 2. أضفنا Future و async
  // 3. تأكدي من تهيئة الأدوات قبل الربط
  WidgetsFlutterBinding.ensureInitialized();

  // 4. ربط التطبيق بقاعدة البيانات
  // ملاحظة: استبدلي الروابط بالتي لديكِ في حساب Supabase
  await Supabase.initialize(
    url: 'https://icfybrrflwqjyuhsaaln.supabase.co', // رابط المشروع
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImljZnlicnJmbHdxanl1aHNhYWxuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI3MDQ4OTcsImV4cCI6MjA4ODI4MDg5N30.jwaK728HPBc2lkf4ui_iR4uoYcykL4ur5iWKd0Nalxg',         // مفتاح anon
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StockVantage DZ', // غيرت العنوان لاسم مشروعك
      theme: ThemeData(
        primarySwatch: Colors.orange,
        useMaterial3: true,
      ),
      // يبدأ التطبيق من لوحة تحكم مدير المخزن باسمك
      home: const StockManagerDashboard(userName: "BENALI Mohamed"), 
     //home: const GestionUtilisateursPage(),
    );
  }
}