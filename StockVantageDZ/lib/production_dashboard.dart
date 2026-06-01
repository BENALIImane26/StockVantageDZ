import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'production_model.dart';
import 'dommage_page.dart';
import 'alertes_page.dart';
import 'etat_produit.dart';
import 'login_page.dart';
import 'rapport_page.dart';
import 'historique_mouvements_page.dart';
import 'planning_chef_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM HEADER (unchanged)
// ─────────────────────────────────────────────────────────────────────────────
class CustomHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color backgroundColor;
  final List<Widget>? actions;

  const CustomHeader({
    super.key,
    required this.title,
    this.backgroundColor = const Color(0xFFFF9800),
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: preferredSize,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(25),
            bottomRight: Radius.circular(25),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 22),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (actions != null) ...actions! else const SizedBox(width: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ORDER DETAIL PAGE (unchanged)
// ─────────────────────────────────────────────────────────────────────────────
class OrderDetailSupabasePage extends StatefulWidget {
  final String orderId;
  const OrderDetailSupabasePage({super.key, required this.orderId});

  @override
  State<OrderDetailSupabasePage> createState() =>
      _OrderDetailSupabasePageState();
}

class _OrderDetailSupabasePageState extends State<OrderDetailSupabasePage> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? orderData;
  bool isLoading = true;
  bool isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      final response = await supabase
          .from('ordre_de_production')
          .select('*, produit:produit!inner(nomp, unitemesure)')
          .eq('idordre', widget.orderId)
          .maybeSingle();
      setState(() {
        orderData = response;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => isUpdating = true);
    try {
      await supabase
          .from('ordre_de_production')
          .update({'statutordre': newStatus}).eq('idordre', widget.orderId);
      await _loadOrder();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Statut mis à jour: $newStatus ✅'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => isUpdating = false);
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Terminé':
        return Colors.green;
      case 'En cours':
        return Colors.orange;
      case 'En attente':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (orderData == null) {
      return Scaffold(
        appBar: CustomHeader(title: "Détails"),
        body: const Center(child: Text("Ordre introuvable")),
      );
    }

    final String statut = orderData!['statutordre'] ?? 'En attente';
    final Color statusColor = _getStatusColor(statut);
    final String productName =
        orderData!['produit']?['nomp'] ?? orderData!['idproduitfini'] ?? '—';
    final String unit = orderData!['produit']?['unitemesure'] ?? '';

    return Scaffold(
      appBar: CustomHeader(title: "Ordre ${widget.orderId}"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [statusColor, statusColor.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(
                    statut == 'Terminé'
                        ? Icons.check_circle
                        : statut == 'En cours'
                            ? Icons.play_circle
                            : Icons.hourglass_empty,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(statut,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  Text(widget.orderId,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _detailRow(Icons.inventory, "Produit", productName),
                    const Divider(height: 24),
                    _detailRow(Icons.numbers, "Quantité à produire",
                        "${orderData!['quantiteaproduire']} $unit"),
                    const Divider(height: 24),
                    _detailRow(Icons.check_circle, "Quantité réelle",
                        "${orderData!['quantiteproduitereelle'] ?? 0} $unit"),
                    const Divider(height: 24),
                    _detailRow(
                        Icons.calendar_today,
                        "Date début",
                        orderData!['datedebut']?.toString().split('T')[0] ??
                            '—'),
                    if (orderData!['datefinprevue'] != null) ...[
                      const Divider(height: 24),
                      _detailRow(Icons.event, "Date fin prévue",
                          orderData!['datefinprevue'].toString().split('T')[0]),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (statut != 'Terminé') ...[
              if (statut == 'En attente')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed:
                        isUpdating ? null : () => _updateStatus('En cours'),
                    icon: const Icon(Icons.play_arrow, color: Colors.white),
                    label: const Text("Démarrer la production",
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9800),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isUpdating ? null : () => _updateStatus('Terminé'),
                  icon: isUpdating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check, color: Colors.white),
                  label: const Text("Marquer comme Terminé",
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 22, color: const Color(0xFFFF9800)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRODUCTION DASHBOARD  ← redesigned to match StockManagerDashboard
// ─────────────────────────────────────────────────────────────────────────────
class ProductionDashboard extends StatefulWidget {
  final String userName;
  const ProductionDashboard({super.key, required this.userName});

  @override
  State<ProductionDashboard> createState() => _ProductionDashboardState();
}

class _ProductionDashboardState extends State<ProductionDashboard> {
  final supabase = Supabase.instance.client;

  // Supabase Storage image URLs
  final String dommageImageUrl =
      'https://icfybrrflwqjyuhsaaln.supabase.co/storage/v1/object/public/chef/dommage.png';
  final String reportImageUrl =
      'https://icfybrrflwqjyuhsaaln.supabase.co/storage/v1/object/public/chef/report.jpg';
  final String productImageUrl =
      'https://icfybrrflwqjyuhsaaln.supabase.co/storage/v1/object/public/chef/product.jpg';
  final String historiqueImageUrl =
      'https://icfybrrflwqjyuhsaaln.supabase.co/storage/v1/object/public/chef/historique.jpg';
  final String profileImageUrl =
      'https://icfybrrflwqjyuhsaaln.supabase.co/storage/v1/object/public/chef/B.jpg';

  // ── LOGOUT ──────────────────────────────────────────────────────────────────
  Future<void> _showLogoutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          decoration: BoxDecoration(
            color: const Color(0xFFFDF6EC),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Déconnexion",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E)),
              ),
              const SizedBox(height: 12),
              const Text(
                "Êtes-vous sûr de vouloir vous déconnecter ?",
                style: TextStyle(
                    color: Color(0xFF555555), fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text("Annuler",
                        style: TextStyle(
                            color: Color(0xFF888888),
                            fontSize: 15,
                            fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text("Déconnecter",
                        style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      final productionData =
          Provider.of<ProductionData>(context, listen: false);
      if (productionData.chefId.isNotEmpty) {
        await supabase
            .from('utilisateur')
            .update({'online': false}).eq('idutilisateur', productionData.chefId);
      }
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  // ── STAT CARD  (matches _iconStatCard in StockManagerDashboard) ─────────────
  Widget _iconStatCard({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: color)),
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ── BOTTOM NAV IMAGE BUTTON (matches _imageNavButton) ───────────────────────
  Widget _imageNavButton(
      String label, String imgUrl, Color glowColor, Widget page) {
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
            child: ClipOval(
              child: Image.network(
                imgUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.image_not_supported, color: glowColor),
              ),
            ),
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

  // ── BOTTOM BAR: Nouvel Ordre button + glassmorphism nav stacked ─────────────
  Widget _buildBottomNav() {
    final productionData = Provider.of<ProductionData>(context, listen: false);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Fixed "Nouvel Ordre" button above nav ──────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 0, 15, 8),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFFF9800), Color(0xFFF57C00)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PlanningChefPage()),
                );
                await productionData.loadProductionOrders();
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "Nouvel Ordre de Production",
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ),
        // ── Glassmorphism nav ──────────────────────────────────────────────
        Container(
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
                    _imageNavButton("Historique", historiqueImageUrl,
                        Colors.teal, const HistoriqueMouvementsPage()),
                    _imageNavButton("Dommage", dommageImageUrl, Colors.red,
                        const DommagePage()),
                    _imageNavButton("Rapport", reportImageUrl, Colors.blue,
                        const RapportPage()),
                    _imageNavButton("Stock", productImageUrl, Colors.purple,
                        const EtatStockPage()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── BADGE (matches _dashBadge in StockManagerDashboard) ────────────────────
  Widget _badge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6)),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      );

  // ── ORDER CARD (matches _buildBatchCard in StockManagerDashboard) ────────────
  Widget _orderCardVertical(ProductionOrderItem order) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                OrderDetailSupabasePage(orderId: order.idordre),
          ),
        );
        final productionData =
            Provider.of<ProductionData>(context, listen: false);
        await productionData.loadProductionOrders();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
                color: order.statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.assignment_outlined,
                color: order.statusColor, size: 22),
          ),
          title: Text(
            order.productName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _badge(order.statutordre, order.statusColor),
                _badge(order.idordre, Colors.grey),
                _badge("Qté: ${order.quantiteaproduire}", Colors.teal),
                Text(order.datedebut,
                    style:
                        const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          trailing: const Icon(Icons.chevron_right,
              color: Colors.orange, size: 22),
        ),
      ),
    );
  }

  Widget _emptyOrdersWidget() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Icon(Icons.assignment_turned_in_outlined,
              size: 50, color: Colors.green[200]),
          const SizedBox(height: 10),
          const Text(
            "Aucun ordre de production",
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.grey,
                fontSize: 15,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ── BUILD ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    final productionData = Provider.of<ProductionData>(context);

    if (productionData.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF1F3F9),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Color(0xFFFF9800))),
              SizedBox(height: 20),
              Text("Chargement des données...",
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F9),
      // ── AppBar (matches StockManagerDashboard gradient AppBar) ──────────────
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFD35400),
                Color(0xFFD35400),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius:
                BorderRadius.vertical(bottom: Radius.circular(25)),
          ),
        ),
        title: Row(
          children: [
            ClipOval(
              child: Image.network(
                profileImageUrl,
                width: 38,
                height: 38,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Bienvenue, ${widget.userName} 👋🏻',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: Colors.white, size: 22),
            onPressed: () async {
              await productionData.loadAllData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Données actualisées ✅"),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded,
                color: Colors.white, size: 22),
            onPressed: _showLogoutDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      // ── BODY ────────────────────────────────────────────────────────────────
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => await productionData.loadAllData(),
          color: const Color(0xFFFF9800),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                // ── Stat cards row (same AspectRatio + _iconStatCard style) ──
                Row(
                  children: [
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: _iconStatCard(
                          icon: Icons.check_circle_outline,
                          color: Colors.green,
                          label: productionData.summaryItems[0].label,
                          value: productionData.summaryItems[0].count,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OrdersListPage(
                                  title: "Ordres Terminés",
                                  filterStatus: "Terminé",
                                ),
                              ),
                            );
                            await productionData.loadProductionOrders();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: _iconStatCard(
                          icon: Icons.production_quantity_limits_outlined,
                          color: Colors.blue,
                          label: productionData.summaryItems[1].label,
                          value: productionData.summaryItems[1].count,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OrdersListPage(
                                  title: "Ordres Actifs",
                                  filterStatus: "actif",
                                ),
                              ),
                            );
                            await productionData.loadProductionOrders();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: _iconStatCard(
                          icon: Icons.warning_amber_rounded,
                          color: Colors.red,
                          label: productionData.summaryItems[2].label,
                          value: productionData.summaryItems[2].count,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const AlertesPage()),
                            );
                            await productionData.updateAlertsCount();
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // ── Section header ───────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Ordres de Production",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF334155)),
                    ),
                    TextButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrdersListPage(
                              title: "Tous les Ordres",
                              filterStatus: "tous",
                            ),
                          ),
                        );
                        await productionData.loadProductionOrders();
                      },
                      child: const Text("Voir tout",
                          style: TextStyle(
                              color: Colors.orange, fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Orders list ──────────────────────────────────────────────
                productionData.productionOrders.isEmpty
                    ? _emptyOrdersWidget()
                    : Column(
                        children: List.generate(
                          productionData.productionOrders.length > 4
                              ? 4
                              : productionData.productionOrders.length,
                          (index) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _orderCardVertical(
                                productionData.productionOrders[index]),
                          ),
                        ),
                      ),

                const SizedBox(height: 12),

                // ── Tip ──────────────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.orange.shade700, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Astuce : Appuyez sur une carte pour voir les détails",
                          style: TextStyle(
                              color: Colors.orange.shade700, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      // ── Bottom Navigation (glassmorphism — same as Gestionnaire) ────────────
      bottomNavigationBar: _buildBottomNav(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ORDERS LIST PAGE (unchanged)
// ─────────────────────────────────────────────────────────────────────────────
class OrdersListPage extends StatelessWidget {
  final String title;
  final String filterStatus;

  const OrdersListPage({
    super.key,
    required this.title,
    required this.filterStatus,
  });

  Future<List<Map<String, dynamic>>> _fetchOrders(
      SupabaseClient supabase) async {
    if (filterStatus == "Terminé") {
      return await supabase
          .from('ordre_de_production')
          .select(
              'idordre, idproduitfini, quantiteaproduire, statutordre, datedebut, produit:produit!inner(nomp)')
          .eq('statutordre', 'Terminé')
          .order('datedebut', ascending: false);
    } else if (filterStatus == "actif") {
      return await supabase
          .from('ordre_de_production')
          .select(
              'idordre, idproduitfini, quantiteaproduire, statutordre, datedebut, produit:produit!inner(nomp)')
          .neq('statutordre', 'Terminé')
          .order('datedebut', ascending: false);
    } else {
      return await supabase
          .from('ordre_de_production')
          .select(
              'idordre, idproduitfini, quantiteaproduire, statutordre, datedebut, produit:produit!inner(nomp)')
          .order('datedebut', ascending: false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Terminé':
        return Colors.green;
      case 'En cours':
        return Colors.orange;
      case 'En attente':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F9),
      appBar: CustomHeader(title: title),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchOrders(supabase),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Erreur: ${snapshot.error}"));
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text("Aucun ordre",
                      style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final String statut = order['statutordre'] ?? 'En attente';
              final Color statusColor = _getStatusColor(statut);
              final String productName =
                  order['produit']?['nomp'] ?? order['idproduitfini'] ?? '—';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3))
                  ],
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          OrderDetailSupabasePage(orderId: order['idordre']),
                    ),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.assignment_outlined,
                        color: statusColor, size: 22),
                  ),
                  title: Text(productName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                        "${order['idordre']} · Qté: ${order['quantiteaproduire']} · ${order['datedebut']?.toString().split('T')[0] ?? ''}",
                        style: const TextStyle(fontSize: 12)),
                  ),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(statut,
                        style:
                            TextStyle(color: statusColor, fontSize: 11,
                                fontWeight: FontWeight.w600)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}