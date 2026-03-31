import 'package:flutter/material.dart';

class EtatStockPage extends StatefulWidget {
  const EtatStockPage({super.key});

  @override
  State<EtatStockPage> createState() => _EtatStockPageState();
}

class _EtatStockPageState extends State<EtatStockPage> {
  // بيانات وهمية للعرض (Mock Data)
  final List<Map<String, dynamic>> stockData = [
    {
      'id': 'MP001',
      'nom': 'Farine',
      'quantite': 500.0,
      'unite': 'Kg',
      'status': 'green',
      'lastCheck': '2026-03-10',
      'history': ['+100 Kg (01/03)', '-50 Kg (05/03)']
    },
    {
      'id': 'MP002',
      'nom': 'Sucre',
      'quantite': 45.0,
      'unite': 'Kg',
      'status': 'yellow',
      'lastCheck': '2026-03-12',
      'history': ['-10 Kg (10/03)', '-20 Kg (11/03)']
    },
    {
      'id': 'P100',
      'nom': 'Daily Orange',
      'quantite': 5.0,
      'unite': 'Bouteille',
      'status': 'red',
      'lastCheck': '2026-03-15',
      'history': ['-100 Btl (14/03)', '-50 Btl (15/03)']
    },
    {
      'id': 'P106',
      'nom': 'Biscuit Cool',
      'quantite': 12.0,
      'unite': 'Pièce',
      'status': 'red',
      'lastCheck': '2026-03-14',
      'history': ['-200 Pièce (12/03)']
    },
  ];

  // دالة ترتيب المواد بناءً على اللون (الأحمر أولاً)
  void _sortStock() {
    stockData.sort((a, b) {
      int priority(String status) {
        switch (status) {
          case 'red':
            return 0;
          case 'yellow':
            return 1;
          case 'green':
            return 2;
          default:
            return 3;
        }
      }

      return priority(a['status']).compareTo(priority(b['status']));
    });
  }

  @override
  Widget build(BuildContext context) {
    // استدعاء الترتيب قبل بناء الواجهة
    _sortStock();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      /// APPBAR مع زر الخروج
      appBar: AppBar(
        backgroundColor: Colors.orange,
        elevation: 0,
        title: const Text("État du Stock"),
        centerTitle: true,
        // زر الخروج (الرجوع للداشبورد)
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

      body: Column(
        children: [
          /// 1. شريط البحث
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Rechercher un produit...",
                prefixIcon: const Icon(Icons.search, color: Colors.orange),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          /// 2. قائمة المواد المرتبة
          Expanded(
            child: ListView.builder(
              itemCount: stockData.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final item = stockData[index];
                return _buildStockCard(item);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// ويدجت البطاقة (Card)
  Widget _buildStockCard(Map<String, dynamic> item) {
    Color statusColor;
    if (item['status'] == 'green')
      statusColor = Colors.green;
    else if (item['status'] == 'yellow')
      statusColor = Colors.orange;
    else
      statusColor = Colors.red;

    return Card(
      elevation: 3,
      shadowColor: Colors.black12,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.inventory_2, color: statusColor, size: 30),
        ),
        title: Text(
          item['nom'],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration:
                    BoxDecoration(color: statusColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                "${item['quantite']} ${item['unite']}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),

        /// المحتوى عند فتح البطاقة
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow("Dernier Inventaire:", item['lastCheck']),
                const SizedBox(height: 12),
                const Text(
                  "Dernières Mouvements:",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.blueGrey),
                ),
                const SizedBox(height: 8),
                ...List.generate(
                  (item['history'] as List).length,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.history, size: 16, color: Colors.grey),
                        const SizedBox(width: 10),
                        Text(item['history'][i],
                            style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ويدجت صف التفاصيل
  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
