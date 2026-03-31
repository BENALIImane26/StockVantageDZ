import 'package:flutter/material.dart';
import 'entree_page.dart';
import 'etat_stock_page.dart'; // سنستخدمها كمثال لصفحة الجرد

class EnAttentePage extends StatelessWidget {
  const EnAttentePage({super.key});

  @override
  Widget build(BuildContext context) {
    // قائمة المهام مع تحديد "النوع" برمجياً لكل مهمة
    final List<Map<String, dynamic>> myWorkInProgress = [
      {
        'type': 'inventaire', // نوع المهمة
        'title': 'Reprendre l\'inventaire',
        'detail': 'Zone: Matières Premières',
        'status': '50% complété',
        'icon': Icons.edit_note,
        'color': Colors.orange
      },
      {
        'type': 'reception', // نوع المهمة
        'title': 'Compléter Réception Stock',
        'detail': 'Fournisseur: ABC (3/10 articles)',
        'status': 'En cours',
        'icon': Icons.pending_actions,
        'color': Colors.blue
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text("Mes Tâches en Cours"),
        backgroundColor: Colors.orange,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: myWorkInProgress.length,
          itemBuilder: (context, index) {
            final task = myWorkInProgress[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                onTap: () {
                  // --- الكود الذي سألت عنه: كيف يعرف أين يذهب؟ ---
                  if (task['type'] == 'inventaire') {
                    // إذا كان النوع جرد، اذهب لصفحة الجرد
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EtatStockPage()),
                    );
                  } else if (task['type'] == 'reception') {
                    // إذا كان النوع استقبال، اذهب لصفحة الإدخال
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EntreePage()),
                    );
                  }
                },
                leading: CircleAvatar(
                  backgroundColor: task['color'].withOpacity(0.1),
                  child: Icon(task['icon'], color: task['color']),
                ),
                title: Text(task['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(task['detail']),
                trailing: Icon(Icons.arrow_forward_ios, size: 16, color: task['color']),
              ),
            );
          },
        ),
      ),
    );
  }
}