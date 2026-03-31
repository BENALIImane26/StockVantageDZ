import 'package:flutter/material.dart';

class SortiePage extends StatelessWidget {
  const SortiePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // صفحة بيضاء للتجربة
      appBar: AppBar(
        title: const Text("Nouvelle Sortie"),
        backgroundColor: Colors.green, // لون أخضر للإخراج
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(Icons.upload, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            // حقل اختيار المنتج
            const TextField(
              decoration: InputDecoration(
                labelText: "Produit",
                border: OutlineInputBorder(),
                hintText: "Ex: Daily Orange",
              ),
            ),
            const SizedBox(height: 15),
            // حقل الكمية
            const TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Quantité",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            // زر التأكيد
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Sortie enregistrée !")),
                );
              },
              child: const Text("Confirmer la Sortie", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}