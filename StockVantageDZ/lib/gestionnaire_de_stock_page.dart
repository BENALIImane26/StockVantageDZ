import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'entree_page.dart';
import 'sortie_page.dart';
import 'etat_stock_page.dart';
import 'dommage_page.dart';
import 'en_attente_page.dart';

class StockManagerDashboard extends StatelessWidget {
  final String userName;

  const StockManagerDashboard({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F9),

      /// --- AppBar المحدث (لوق اوت بدلاً من الجرس) ---
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                  color: Colors.white24, shape: BoxShape.circle),
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white30,
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Bienvenue",
                    style: TextStyle(fontSize: 11, color: Colors.white70)),
                Text(userName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white)),
              ],
            ),
          ],
        ),
        actions: [
          // استبدال الجرس بأيقونة Logout
          IconButton(
            icon:
                const Icon(Icons.logout_rounded, color: Colors.white, size: 22),
            tooltip: "Déconnexion",
            onPressed: () {
              // هنا نضع كود تسجيل الخروج والعودة لصفحة Login
              Navigator.pop(context);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              /// --- القائمة العلوية بالرموز (Icons) فقط ---
              Row(
                children: [
                  _iconStatCard(
                    context,
                    icon: Icons.warning_amber_rounded,
                    color: Colors.red,
                    label: "Alertes",
                    value: "2",
                    onTap: null,
                  ),
                  const SizedBox(width: 10),
                  _iconStatCard(
                    context,
                    icon: Icons.inventory_2_outlined,
                    color: Colors.blue,
                    label: "Stocks",
                    value: "14",
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const EtatStockPage())),
                  ),
                  const SizedBox(width: 10),
                  _iconStatCardWithBadge(
                    context,
                    icon: Icons.update_rounded,
                    color: Colors.orange,
                    label: "Attente",
                    value: "5",
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const EnAttentePage())),
                  ),
                ],
              ),

              const SizedBox(height: 30),
              const Text(
                "Tâches récentes",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF334155)),
              ),
              const SizedBox(height: 15),
              _taskCard("ORD-2026-001", "Production", Colors.orange),
              _taskCard("ORD-2026-004", "Terminé", Colors.green),
            ],
          ),
        ),
      ),

      /// --- القائمة السفلية بالصور (كما هي) ---
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(15, 0, 15, 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 110,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _imageNavButton(context, "Entrée", 'assets/entree.png',
                      Colors.blue, const EntreePage()),
                  _imageNavButton(context, "Sortie", 'assets/sortie.png',
                      Colors.green, const SortiePage()),
                  _imageNavButton(context, "Stock", 'assets/inventaire.png',
                      Colors.orange, const EtatStockPage()),
                  _imageNavButton(context, "Trafic", 'assets/dommage.png',
                      Colors.red, const DommagePage()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ويدجت البطاقة العلوية (رموز)
  Widget _iconStatCard(BuildContext context,
      {required IconData icon,
      required Color color,
      required String label,
      required String value,
      required VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 12),
              Text(value,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: color,
                      height: 1)),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: Colors.blueGrey,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  /// ويدجت بطاقة علوية مع علامة تنبيه
  Widget _iconStatCardWithBadge(BuildContext context,
      {required IconData icon,
      required Color color,
      required String label,
      required String value,
      required VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                children: [
                  Icon(icon, color: color, size: 28),
                  const SizedBox(height: 12),
                  Text(value,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: color,
                          height: 1)),
                  const SizedBox(height: 4),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.blueGrey,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: const Text("!",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// أزرار القائمة السفلية (بالصور)
  Widget _imageNavButton(BuildContext context, String label, String imgPath,
      Color glowColor, Widget page) {
    return GestureDetector(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: glowColor.withOpacity(0.15),
                    blurRadius: 12,
                    spreadRadius: 1)
              ],
            ),
            child: ClipOval(child: Image.asset(imgPath, fit: BoxFit.cover)),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155))),
        ],
      ),
    );
  }

  Widget _taskCard(String order, String status, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10)),
          child:
              const Icon(Icons.receipt_long_outlined, color: Colors.blueGrey),
        ),
        title: Text(order,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle:
            const Text("Vérifié le 31 Mars", style: TextStyle(fontSize: 11)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20)),
          child: Text(status,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 10)),
        ),
      ),
    );
  }
}
