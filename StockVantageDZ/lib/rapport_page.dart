import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// ==================== RapportPage ====================
class RapportPage extends StatefulWidget {
  const RapportPage({super.key});

  @override
  State<RapportPage> createState() => _RapportPageState();
}

class _RapportPageState extends State<RapportPage>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _termineOrders = [];
  List<Map<String, dynamic>> _encoursOrders = [];
  List<Map<String, dynamic>> _attenteOrders = [];

  bool _isLoading = true;
  String _searchQuery = '';
  late TabController _tabController;

  final Color orangeBrand = const Color(0xFFFF9800);
  final Color orangeLight = const Color(0xFFFFB74D);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadAllOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllOrders() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase.from('ordre_de_production').select('''
            idordre,
            idproduitfini,
            quantiteaproduire,
            quantiteproduitereelle,
            statutordre,
            datedebut,
            datefinprevue,
            produit:produit!inner(nomp, unitemesure)
          ''').order('datedebut', ascending: false);

      final List<Map<String, dynamic>> allOrders =
          List<Map<String, dynamic>>.from(response);

      setState(() {
        _termineOrders =
            allOrders.where((o) => o['statutordre'] == 'Terminé').toList();
        _encoursOrders =
            allOrders.where((o) => o['statutordre'] == 'En cours').toList();
        _attenteOrders =
            allOrders.where((o) => o['statutordre'] == 'En attente').toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading orders: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _currentFilteredOrders {
    List<Map<String, dynamic>> orders;
    switch (_tabController.index) {
      case 0:
        orders = _termineOrders;
        break;
      case 1:
        orders = _encoursOrders;
        break;
      case 2:
        orders = _attenteOrders;
        break;
      default:
        orders = _termineOrders;
    }
    if (_searchQuery.isEmpty) return orders;
    return orders.where((order) {
      final productName = order['produit']?['nomp']?.toString() ??
          order['idproduitfini']?.toString() ??
          '';
      final idordre = order['idordre']?.toString() ?? '';
      return productName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          idordre.contains(_searchQuery);
    }).toList();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '—';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return dateStr;
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

  String _getStatusIcon(String status) {
    switch (status) {
      case 'Terminé':
        return '✅';
      case 'En cours':
        return '🔄';
      case 'En attente':
        return '⏳';
      default:
        return '📋';
    }
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: Column(
        children: [
          // ── Header avec bouton retour ──
          Container(
            height: 60 + statusBarHeight,
            width: double.infinity,
            padding: EdgeInsets.only(top: statusBarHeight),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [orangeBrand, orangeLight]),
              borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25)),
            ),
            child: Stack(
              children: [
                // ✅ زر الرجوع (يسار)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Retour',
                  ),
                ),
                // العنوان في المنتصف
                const Center(
                  child: Text("Rapport des Ordres",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                ),
                // الأزرار في الجهة اليمنى
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: _loadAllOrders,
                        tooltip: 'Rafraîchir',
                      ),
                      IconButton(
                        icon: const Icon(Icons.history, color: Colors.white),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SavedRapportsListPage()),
                        ),
                        tooltip: 'Historique',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_isLoading)
            Expanded(
                child: Center(
                    child: CircularProgressIndicator(color: orangeBrand)))
          else ...[
            // ── TabBar ──
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: orangeBrand,
                unselectedLabelColor: Colors.grey,
                indicator: BoxDecoration(
                  color: orangeBrand.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                tabs: [
                  Tab(text: '✅ Terminé (${_termineOrders.length})'),
                  Tab(text: '🔄 En cours (${_encoursOrders.length})'),
                  Tab(text: '⏳ Attente (${_attenteOrders.length})'),
                ],
              ),
            ),

            // ── Search ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Rechercher par produit ou ID...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),

            // ── Liste ──
            Expanded(
              child: _currentFilteredOrders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox,
                              size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'Aucun ordre à afficher'
                                : 'Aucun résultat',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: _currentFilteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = _currentFilteredOrders[index];
                        final statut = order['statutordre']?.toString() ?? '—';
                        final statusColor = _getStatusColor(statut);
                        final statusIcon = _getStatusIcon(statut);
                        final productName =
                            order['produit']?['nomp']?.toString() ??
                                order['idproduitfini']?.toString() ??
                                '—';
                        final idordre = order['idordre']?.toString() ?? '—';
                        final quantiteReelle =
                            (order['quantiteproduitereelle'] as num?)
                                    ?.toInt() ??
                                0;
                        final quantiteAProduire =
                            (order['quantiteaproduire'] as num?)?.toInt() ?? 0;
                        final dateDebut =
                            _formatDate(order['datedebut']?.toString());

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 1,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      RapportOrderDetailPage(order: order),
                                ),
                              );
                              if (result == true) _loadAllOrders();
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                            color: statusColor,
                                            shape: BoxShape.circle),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(statusIcon,
                                          style: const TextStyle(fontSize: 14)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(productName,
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(statut,
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: statusColor,
                                                fontWeight: FontWeight.w500)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        child: Text(idordre,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey)),
                                      ),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.numbers,
                                          size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text("$quantiteReelle/$quantiteAProduire",
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500)),
                                      const Spacer(),
                                      const Icon(Icons.calendar_today,
                                          size: 12, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(dateDebut,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

// ==================== RapportOrderDetailPage ====================
class RapportOrderDetailPage extends StatefulWidget {
  final Map<String, dynamic> order;
  const RapportOrderDetailPage({super.key, required this.order});

  @override
  State<RapportOrderDetailPage> createState() => _RapportOrderDetailPageState();
}

class _RapportOrderDetailPageState extends State<RapportOrderDetailPage> {
  final supabase = Supabase.instance.client;
  bool _isUpdating = false;
  bool _isSaving = false;
  bool _isExporting = false;

  late Map<String, dynamic> _currentOrder;

  final Color orangeBrand = const Color(0xFFFF9800);
  final Color orangeLight = const Color(0xFFFFB74D);

  @override
  void initState() {
    super.initState();
    _currentOrder = Map<String, dynamic>.from(widget.order);
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdating = true);
    try {
      await supabase.from('ordre_de_production').update(
          {'statutordre': newStatus}).eq('idordre', _currentOrder['idordre']);
      if (mounted) {
        setState(() {
          _currentOrder['statutordre'] = newStatus;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Statut mis à jour: $newStatus ✅'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _saveRapportToSupabase() async {
    setState(() => _isSaving = true);
    final order = _currentOrder;
    final statut = order['statutordre'] ?? 'Inconnu';
    final productName =
        order['produit']?['nomp'] ?? order['idproduitfini'] ?? '—';
    final unit = order['produit']?['unitemesure'] ?? '';
    final quantiteAProduire =
        (order['quantiteaproduire'] as num?)?.toInt() ?? 0;
    final quantiteReelle =
        (order['quantiteproduitereelle'] as num?)?.toInt() ?? 0;

    try {
      final contenuJson = {
        'idordre': order['idordre']?.toString(),
        'produit': productName,
        'unite': unit,
        'statut': statut,
        'quantite_a_produire': quantiteAProduire,
        'quantite_reelle': quantiteReelle,
        'date_debut': order['datedebut']?.toString().split('T')[0],
        'date_fin_prevue': order['datefinprevue']?.toString().split('T')[0],
      };

      await supabase.from('rapport').insert({
        'titrerapport': 'Rapport Ordre ${order['idordre']} - $productName',
        'typerapport': 'Rapport Ordre Production',
        'contenujson': contenuJson,
        'dategeneration': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('✅ Rapport de l\'ordre ${order['idordre']} enregistré!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _previewPDF() async {
    setState(() => _isExporting = true);
    try {
      final order = _currentOrder;
      final statut = order['statutordre'] ?? 'Inconnu';
      final productName =
          order['produit']?['nomp'] ?? order['idproduitfini'] ?? '—';
      final unit = order['produit']?['unitemesure'] ?? '';
      final quantiteAProduire =
          (order['quantiteaproduire'] as num?)?.toInt() ?? 0;
      final quantiteReelle =
          (order['quantiteproduitereelle'] as num?)?.toInt() ?? 0;
      final dateDebut = order['datedebut']?.toString().split('T')[0] ?? '—';
      final dateFin = order['datefinprevue']?.toString().split('T')[0] ?? '—';
      final idordre = order['idordre']?.toString() ?? '—';

      final pdf = pw.Document();

      final now = DateTime.now();
      final dateStr =
          "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'Rapport de Production',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.orange,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 20),
                _buildInfoRow('ID Ordre', idordre),
                _buildInfoRow('Produit', productName),
                _buildInfoRow('Statut', statut),
                _buildInfoRow('Unité de mesure', unit),
                _buildInfoRow(
                    'Quantité à produire', quantiteAProduire.toString()),
                _buildInfoRow('Quantité réelle', quantiteReelle.toString()),
                _buildInfoRow('Date début', dateDebut),
                _buildInfoRow('Date fin prévue', dateFin),
                pw.SizedBox(height: 30),
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Généré par: StockVantage DZ',
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                    ),
                    pw.Text(
                      'Date: $dateStr',
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (_) async => pdf.save(),
        name: 'Rapport_Ordre_${order['idordre']}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ PDF généré avec succès!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          pw.Text(': ', style: pw.TextStyle(fontSize: 12)),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '—';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return dateStr;
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

  String _getStatusIcon(String status) {
    switch (status) {
      case 'Terminé':
        return '✅';
      case 'En cours':
        return '🔄';
      case 'En attente':
        return '⏳';
      default:
        return '📋';
    }
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final order = _currentOrder;
    final statut = order['statutordre'] ?? 'En attente';
    final statusColor = _getStatusColor(statut);
    final statusIcon = _getStatusIcon(statut);
    final productName =
        order['produit']?['nomp'] ?? order['idproduitfini'] ?? '—';
    final idordre = order['idordre'] ?? '—';
    final quantiteAProduire =
        (order['quantiteaproduire'] as num?)?.toInt() ?? 0;
    final quantiteReelle =
        (order['quantiteproduitereelle'] as num?)?.toInt() ?? 0;
    final unit = order['produit']?['unitemesure'] ?? '';
    final dateDebut = _formatDate(order['datedebut']?.toString());
    final dateFin = _formatDate(order['datefinprevue']?.toString());

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: Column(
        children: [
          Container(
            height: 60 + statusBarHeight,
            width: double.infinity,
            padding: EdgeInsets.only(top: statusBarHeight),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [orangeBrand, orangeLight]),
              borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25)),
            ),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white),
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ),
                Center(
                  child: Text("Ordre $idordre",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.save_alt, color: Colors.white),
                        onPressed: _isSaving ? null : _saveRapportToSupabase,
                        tooltip: 'Enregistrer le rapport',
                      ),
                      IconButton(
                        icon: _isExporting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.picture_as_pdf,
                                color: Colors.white),
                        onPressed: _isExporting ? null : _previewPDF,
                        tooltip: 'Exporter en PDF',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [statusColor, statusColor.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Text(statusIcon, style: const TextStyle(fontSize: 48)),
                        const SizedBox(height: 8),
                        Text(statut,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold)),
                        Text(productName,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 16)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _detailRow(
                              Icons.production_quantity_limits,
                              "Quantité à produire",
                              "$quantiteAProduire $unit"),
                          _detailRow(Icons.check_circle_outline,
                              "Quantité réelle", "$quantiteReelle $unit"),
                          _detailRow(
                              Icons.calendar_today, "Date début", dateDebut),
                          _detailRow(Icons.event, "Date fin prévue", dateFin),
                          const SizedBox(height: 16),
                          LinearProgressIndicator(
                            value: quantiteAProduire > 0
                                ? (quantiteReelle / quantiteAProduire)
                                    .clamp(0.0, 1.0)
                                : 0.0,
                            backgroundColor: Colors.grey.shade200,
                            color: statusColor,
                            borderRadius: BorderRadius.circular(8),
                            minHeight: 8,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Progression: ${((quantiteReelle / (quantiteAProduire > 0 ? quantiteAProduire : 1)) * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                                fontSize: 14,
                                color: statusColor,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (statut == 'En attente') ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isUpdating
                            ? null
                            : () => _updateStatus('En cours'),
                        icon: const Icon(Icons.play_arrow, color: Colors.white),
                        label: const Text("Démarrer la production",
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: orangeBrand,
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
                        onPressed:
                            _isUpdating ? null : () => _updateStatus('Terminé'),
                        icon: const Icon(Icons.check, color: Colors.white),
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
                  ] else if (statut == 'En cours') ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            _isUpdating ? null : () => _updateStatus('Terminé'),
                        icon: const Icon(Icons.check, color: Colors.white),
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
                  if (_isUpdating)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 22, color: orangeBrand),
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
      ),
    );
  }
}

// ==================== SavedRapportsListPage ====================
class SavedRapportsListPage extends StatefulWidget {
  const SavedRapportsListPage({super.key});

  @override
  State<SavedRapportsListPage> createState() => _SavedRapportsListPageState();
}

class _SavedRapportsListPageState extends State<SavedRapportsListPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _rapports = [];
  bool _isLoading = true;

  final Color orangeBrand = const Color(0xFFFF9800);
  final Color orangeLight = const Color(0xFFFFB74D);

  @override
  void initState() {
    super.initState();
    _loadRapports();
  }

  Future<void> _loadRapports() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('rapport')
          .select()
          .order('dategeneration', ascending: false);
      setState(() {
        _rapports = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '—';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: Column(
        children: [
          Container(
            height: 60 + statusBarHeight,
            width: double.infinity,
            padding: EdgeInsets.only(top: statusBarHeight),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [orangeBrand, orangeLight]),
              borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25)),
            ),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const Center(
                  child: Text("Historique des Rapports",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: _loadRapports,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: orangeBrand))
                : _rapports.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history,
                                size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text('Aucun rapport enregistré',
                                style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _rapports.length,
                        itemBuilder: (context, index) {
                          final rapport = _rapports[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            child: ListTile(
                              leading:
                                  Icon(Icons.description, color: orangeBrand),
                              title: Text(rapport['titrerapport'] ?? 'Rapport'),
                              subtitle: Text(
                                'Créé le: ${_formatDate(rapport['dategeneration'])}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
