import 'package:flutter/material.dart';

class EntreePage extends StatelessWidget {
  const EntreePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // صفحة بيضاء للتجربة
      appBar: AppBar(
        title: const Text("Nouvelle Entrée"),
        backgroundColor: Colors.blue, // لون أزرق للإدخال
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(Icons.download, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            // حقل اختيار المنتج (وهمي للتجربة)
            const TextField(
              decoration: InputDecoration(
                labelText: "Produit",
                border: OutlineInputBorder(),
                hintText: "Ex: Farine",
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
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Entrée enregistrée !")),
                );
              },
              child: const Text("Confirmer l'Entrée",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
