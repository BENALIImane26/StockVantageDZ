import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AlertesPage extends StatefulWidget {
  const AlertesPage({super.key});

  @override
  State<AlertesPage> createState() => _AlertesPageState();
}

class _AlertesPageState extends State<AlertesPage> {
  final supabase = Supabase.instance.client;

  void _onAlertePressed(Map<String, dynamic> alerte) async {
    await supabase
        .from('alerte')
        .update({'is_read': true}).eq('idalerte', alerte['idalerte']);

    final product = await supabase
        .from('produit')
        .select('nomp')
        .eq('idproduit', alerte['idproduit'])
        .maybeSingle();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 25),
            Text(
              product?['nomp'] ?? "Details du Produit",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 25),
            _buildModalInfo(
              Icons.warning_amber_rounded,
              Colors.redAccent,
              "Type d'alerte",
              alerte['message'] ?? "",
            ),
            const SizedBox(height: 20),
            _buildModalInfo(
              Icons.calendar_month_outlined,
              Colors.orange,
              "Date d'emission",
              alerte['date_alerte'].toString().split('T')[0],
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB71C1C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Fermer",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModalInfo(
      IconData icon, Color color, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: Column(
        children: [
          Container(
            height: 95,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFB71C1C),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 10,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 18),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Text(
                    "Alertes",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase
                  .from('alerte')
                  .stream(primaryKey: ['idalerte']).order('date_alerte',
                      ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var alerts = snapshot.data ?? [];

                // عرض آخر 5 تنبيهات فقط
                if (alerts.length > 5) {
                  alerts = alerts.take(5).toList();
                }

                if (alerts.isEmpty) {
                  return const Center(
                    child: Text("Aucune alerte pour le moment",
                        style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: alerts.length,
                  itemBuilder: (context, index) {
                    final item = alerts[index];
                    final String msg = item['message'] ?? "";
                    final bool isRead = item['is_read'] ?? false;
                    final String type = item['type_alerte'] ?? 'STOCK';
                    bool isExpiry = type == 'EXPIRATION';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 6,
                          )
                        ],
                      ),
                      child: ListTile(
                        onTap: () => _onAlertePressed(item),
                        leading: CircleAvatar(
                          backgroundColor: isExpiry
                              ? const Color(0xFFFFF3E0)
                              : const Color(0xFFFEE2E2),
                          child: Icon(
                            isExpiry
                                ? Icons.hourglass_bottom_rounded
                                : Icons.notifications_active,
                            color: isExpiry ? Colors.orange : Colors.red,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          msg,
                          style: TextStyle(
                            fontWeight:
                                isRead ? FontWeight.normal : FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          item['date_alerte'].toString().split('T')[0],
                          style:
                              const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios,
                            size: 12, color: Colors.grey),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
