import 'package:flutter/material.dart';

class DommagePage extends StatelessWidget {
  const DommagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Signaler un Dommage"),
        backgroundColor: Colors.red,
        // زر الرجوع للخروج من الصفحة
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Icon(Icons.report_problem, size: 80, color: Colors.red),
              const SizedBox(height: 20),
              
              const TextField(
                decoration: InputDecoration(
                  labelText: "Produit endommagé",
                  border: OutlineInputBorder(),
                  hintText: "Ex: Daily Apple",
                ),
              ),
              const SizedBox(height: 15),
              
              const TextField(
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Description du dommage",
                  border: OutlineInputBorder(),
                  hintText: "Ex: Bouteille cassée",
                ),
              ),
              const SizedBox(height: 20),
              
              // زر محاكاة الكاميرا (تم إصلاح خطأ الـ const هنا)
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Caméra ouverte (Simulation)")),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.camera_alt, color: Colors.grey),
                      SizedBox(width: 10),
                      Text("Prendre une photo du dommage"),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Rapport envoyé !")),
                  );
                },
                child: const Text("Envoyer le rapport", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}