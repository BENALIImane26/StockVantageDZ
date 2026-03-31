import 'package:flutter/material.dart';
import 'entree_page.dart';
import 'sortie_page.dart';
import 'etat_stock_page.dart'; // تأكد من وجود هذا الملف
import 'dommage_page.dart';
import 'en_attente_page.dart';
class StockManagerDashboard extends StatelessWidget {
  final String userName;

  const StockManagerDashboard({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),

      /// --- AppBar ---
      appBar: AppBar(
        backgroundColor: Colors.orange,
        elevation: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.orange),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Bienvenue", style: TextStyle(fontSize: 12, color: Colors.white70)),
                Text(
                  userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),

      /// --- Body ---
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// STATUS BAR (البطاقات العلوية)
            /// STATUS BAR
Row(
  children: [
    _statusCard("2", "Alertes", Icons.warning, Colors.red, null),
    const SizedBox(width: 8),
    
    // ربط بطاقة "في الانتظار" بالصفحة الجديدة
    _statusCard(
      "5", 
      "En attente", 
      Icons.pending, 
      Colors.orange, 
      () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const EnAttentePage()),
        );
      },
    ),
    
    const SizedBox(width: 8),
    _statusCard(
      "14", 
      "Produits", 
      Icons.inventory, 
      Colors.green, 
      () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const EtatStockPage()),
        );
      },
    ),
  ],
),

            const SizedBox(height: 25),

            const Text(
              "Liste des tâches",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),

            const SizedBox(height: 10),

            _taskCard("ORD-2026-001", "En production", Colors.orange),
            _taskCard("ORD-2026-004", "Terminé", Colors.green),
          ],
        ),
      ),

      /// --- الأزرار السفلية ---
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 25),
        color: const Color(0xFFF4F6FA),
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 3.5,
          children: [
            _actionButton(context, "Entrée", Icons.download, Colors.blue, const EntreePage()),
            _actionButton(context, "Sortie", Icons.upload, Colors.green, const SortiePage()),
            _actionButton(context, "Inventaire", Icons.inventory, Colors.orange, const EtatStockPage()),
            _actionButton(context, "Dommage", Icons.dangerous, Colors.red, const DommagePage()),
          ],
        ),
      ),
    );
  }

  /// ويدجت البطاقات العلوية (تمت إضافة خاصية الضغط)
  Widget _statusCard(String value, String title, IconData icon, Color color, VoidCallback? onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              if (onTap != null) // ظل خفيف فقط للبطاقات القابلة للضغط
                BoxShadow(color: color.withOpacity(0.3), blurRadius: 5, offset: const Offset(0, 2))
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ويدجت قائمة المهام
  Widget _taskCard(String order, String status, Color color) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.precision_manufacturing, color: Colors.blueGrey),
        title: Text(order, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Text(
            status,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
          ),
        ),
      ),
    );
  }

  /// ويدجت الأزرار السفلية
  Widget _actionButton(BuildContext context, String label, IconData icon, Color color, Widget page) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}