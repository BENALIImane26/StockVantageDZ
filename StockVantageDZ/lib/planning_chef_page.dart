import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

// ==================== Custom Header Widget ====================
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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

// ==================== Planning Chef Page ====================
class PlanningChefPage extends StatefulWidget {
  const PlanningChefPage({super.key});

  @override
  State<PlanningChefPage> createState() => _PlanningChefPageState();
}

class _PlanningChefPageState extends State<PlanningChefPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _demandes = [];
  Map<String, dynamic>? _selectedDemande;
  bool _isLoading = false;
  bool _isProcessing = false;
  bool _isChecking = false;

  String? _selectedCause;
  final List<String> _causesList = [
    'Machine en panne',
    'Maintenance préventive',
    'Manque de personnel',
    'Problème électrique',
    'Absence matière première',
    'Qualité matière non conforme',
    'Autre'
  ];
  final TextEditingController _autreCauseController = TextEditingController();
  String _customCause = '';

  final Color orangeBrand = const Color(0xFFFF9800);
  final Color backgroundBg = const Color(0xFFF8F9FC);

  @override
  void initState() {
    super.initState();
    _loadDemandes();
  }

  @override
  void dispose() {
    _autreCauseController.dispose();
    super.dispose();
  }

  // ==================== Charger les demandes ====================
  Future<void> _loadDemandes() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('demande_production')
          .select('''
            *,
            produit:idproduitfini (idproduit, nomp, unitemesure)
          ''')
          .eq('statut', 'En attente')
          .order('datedemande', ascending: false);

      setState(() {
        _demandes = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });

      if (_demandes.isEmpty && mounted) {
        _showInfoSnackBar("📭 Aucune demande en attente");
      }
    } catch (e) {
      debugPrint("❌ Erreur chargement demandes: $e");
      setState(() => _isLoading = false);
      _showErrorSnackBar("Erreur: ${e.toString()}");
    }
  }

  // ==================== Sauvegarder un rapport ====================
  Future<void> _saveRapportToDatabase({
    required String titre,
    required String type,
    required Map<String, dynamic> contenu,
  }) async {
    try {
      await supabase.from('rapport').insert({
        'titrerapport': titre,
        'typerapport': type,
        'contenujson': jsonEncode(contenu),
        'dategeneration': DateTime.now().toIso8601String(),
      });
      debugPrint("✅ Rapport sauvegardé");
    } catch (e) {
      debugPrint("❌ Erreur sauvegarde rapport: $e");
    }
  }

  // ==================== Vérifier les ingrédients disponibles ====================
  Future<void> _checkAvailability() async {
    if (_selectedDemande == null) {
      _showErrorSnackBar("Veuillez sélectionner une demande");
      return;
    }

    setState(() => _isChecking = true);

    try {
      String demandeId = _selectedDemande!['iddemande'];
      String productId = _selectedDemande!['idproduitfini'];
      String productName = _selectedDemande!['produit']?['nomp'] ?? 'Produit';
      double qtyToProduce =
          double.parse(_selectedDemande!['quantitedemandee'].toString());

      // Récupérer la recette
      final recetteResponse = await supabase.from('recette').select('''
            quantite_necessaire,
            produit:id_matiere_premiere (idproduit, nomp, quantitestock, dateexpiration)
          ''').eq('id_produit_fini', productId);

      if (recetteResponse.isEmpty) {
        _showDialog(
            "⚠️ Information", "Aucune recette trouvée pour ce produit.");
        setState(() => _isChecking = false);
        return;
      }

      List<Map<String, dynamic>> ingredientsReport = [];
      bool allAvailable = true;
      List<String> raisonsIndisponibilite = [];

      for (var item in recetteResponse) {
        var mpData = item['produit'];

        // ✅ Conversion sécurisée
        double neededPerUnit =
            double.tryParse(item['quantite_necessaire'].toString()) ?? 0.0;
        double totalNeeded = neededPerUnit * qtyToProduce;
        double currentStock =
            double.tryParse(mpData['quantitestock'].toString()) ?? 0.0;

        // ✅ La disponibilité = stock suffisant uniquement (on ignore l'expiration)
        bool isAvailable = totalNeeded <= 0 || currentStock >= totalNeeded;

        debugPrint(
            "🔍 ${mpData['nomp']} | stock=$currentStock | besoin=$totalNeeded | dispo=$isAvailable");

        if (!isAvailable) {
          allAvailable = false;
          raisonsIndisponibilite.add(
              "${mpData['nomp']}: Stock insuffisant (${currentStock.toStringAsFixed(2)} disponible, besoin ${totalNeeded.toStringAsFixed(2)})");
        }

        ingredientsReport.add({
          'idproduit': mpData['idproduit'],
          'nom': mpData['nomp'],
          'stock_disponible': currentStock,
          'besoin': totalNeeded,
          'manquant':
              totalNeeded > currentStock ? totalNeeded - currentStock : 0.0,
          'disponible': isAvailable,
          'expire': false,
        });
      }

      // Trier: les indisponibles en premier
      ingredientsReport.sort((a, b) {
        if (a['disponible'] == b['disponible']) return 0;
        return a['disponible'] ? 1 : -1;
      });

      if (allAvailable) {
        _showSuccessStartDialog(
            ingredientsReport, demandeId, productName, qtyToProduce);
      } else {
        await _createAndSaveRapport(
          demandeId: demandeId,
          productName: productName,
          qtyToProduce: qtyToProduce,
          ingredientsReport: ingredientsReport,
          raisons: raisonsIndisponibilite,
        );
        setState(() => _isChecking = false);
        _showProblemDialog(ingredientsReport, productName, qtyToProduce,
            demandeId, raisonsIndisponibilite);
      }
    } catch (e) {
      debugPrint("❌ Erreur checkAvailability: $e");
      _showDialog("Erreur", e.toString());
      setState(() => _isChecking = false);
    }
  }

  // ==================== Créer et sauvegarder le rapport ====================
  Future<void> _createAndSaveRapport({
    required String demandeId,
    required String productName,
    required double qtyToProduce,
    required List<Map<String, dynamic>> ingredientsReport,
    required List<String> raisons,
  }) async {
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    int disponibles = ingredientsReport.where((i) => i['disponible']).length;
    int indisponibles = ingredientsReport.where((i) => !i['disponible']).length;

    Map<String, dynamic> rapportContent = {
      'type': 'RAPPORT_INDISPONIBILITE',
      'demande_id': demandeId,
      'produit': productName,
      'quantite_demandee': qtyToProduce,
      'date_verification': now.toIso8601String(),
      'statistiques': {
        'total_matieres': ingredientsReport.length,
        'disponibles': disponibles,
        'indisponibles': indisponibles,
      },
      'raisons_indisponibilite': raisons,
      'matieres_premieres': ingredientsReport
          .map((i) => {
                'nom': i['nom'],
                'stock_disponible': i['stock_disponible'],
                'besoin': i['besoin'],
                'manquant': i['manquant'],
                'disponible': i['disponible'],
                'expire': i['expire'],
              })
          .toList(),
    };

    await _saveRapportToDatabase(
      titre: 'Rapport pénurie - $productName - $dateStr',
      type: 'Alerte Stock',
      contenu: rapportContent,
    );
  }

  // ==================== Dialog: Tout est disponible ====================
  void _showSuccessStartDialog(
    List<Map<String, dynamic>> ingredientsReport,
    String demandeId,
    String productName,
    double qtyToProduce,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 10),
            const Text("✅ Matières disponibles",
                style: TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  "Tous les ingrédients sont disponibles pour la production."),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("📦 Produit: $productName",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text("📊 Quantité: ${qtyToProduce.toStringAsFixed(2)}"),
                    Text(
                        "🔧 Matières premières: ${ingredientsReport.length} disponibles"),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateDemandeStatut(
                  demandeId, 'Rejetée', "Production annulée par le chef");
            },
            child: const Text("Annuler", style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _startProduction(demandeId, productName, qtyToProduce);
            },
            icon: const Icon(Icons.play_arrow, color: Colors.white),
            label: const Text("Démarrer Production",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ==================== Démarrer la production ====================
  Future<void> _startProduction(
      String demandeId, String productName, double qtyToProduce) async {
    setState(() => _isProcessing = true);
    try {
      await supabase.from('demande_production').update({
        'statut': 'Approuvée',
        'note':
            'Production démarrée le ${DateTime.now().toString().split(' ')[0]}'
      }).eq('iddemande', demandeId);

      String orderId = await _generateNextOrderId();
      String productId = _selectedDemande!['idproduitfini'];
      String? chefId = await _getCurrentChefId();

      await supabase.from('ordre_de_production').insert({
        'idordre': orderId,
        'idproduitfini': productId,
        'quantiteaproduire': qtyToProduce,
        'statutordre': 'En cours',
        'datedebut': DateTime.now().toIso8601String(),
        'idutilisateur': chefId,
        'quantiteproduitereelle': 0,
      });

      final recetteData = await supabase
          .from('recette')
          .select('id_matiere_premiere, quantite_necessaire')
          .eq('id_produit_fini', productId);

      for (var item in recetteData) {
        double needed =
            double.parse(item['quantite_necessaire'].toString()) * qtyToProduce;
        await supabase.rpc('decrement_stock',
            params: {'pid': item['id_matiere_premiere'], 'qte': needed});
      }

      try {
        await supabase.from('log').insert({
          'action': 'PRODUCTION_STARTED',
          'table_nom': 'ordre_de_production',
          'description':
              "Production de $productName (${qtyToProduce.toStringAsFixed(2)} unités) démarrée. Ordre: $orderId",
          'datelog': DateTime.now().toIso8601String(),
          'idutilisateur': chefId,
        });
        debugPrint("✅ Log enregistré: PRODUCTION_STARTED");
      } catch (logError) {
        debugPrint("⚠️ Erreur log (non bloquante): $logError");
      }

      _showDialog(
          "✅ Succès", "Production démarrée avec succès!\nOrdre: $orderId");

      await _loadDemandes();
      setState(() {
        _selectedDemande = null;
        _selectedCause = null;
        _autreCauseController.clear();
      });
    } catch (e) {
      _showDialog("❌ Erreur", "Erreur lors du démarrage: ${e.toString()}");
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  // ==================== Dialog: Problème ====================
  void _showProblemDialog(
    List<Map<String, dynamic>> ingredientsReport,
    String productName,
    double qtyToProduce,
    String demandeId,
    List<String> raisons,
  ) {
    int indisponibleCount =
        ingredientsReport.where((i) => !i['disponible']).length;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.red, size: 28),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text("⚠️ Production impossible",
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("📊 Résumé:",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("Produit: $productName"),
                        Text(
                            "Quantité demandée: ${qtyToProduce.toStringAsFixed(2)}"),
                        Text("❌ Matières manquantes: $indisponibleCount"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text("📋 Matières premières problématiques:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Expanded(
                                    flex: 3,
                                    child: Text("Produit",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                                Expanded(
                                    flex: 2,
                                    child: Text("Stock",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                                Expanded(
                                    flex: 2,
                                    child: Text("Besoin",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                                Expanded(
                                    flex: 2,
                                    child: Text("Manquant",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red))),
                              ],
                            ),
                          ),
                          ...ingredientsReport
                              .where((i) => !i['disponible'])
                              .map((ingredient) {
                            return Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                border: Border(
                                    bottom: BorderSide(
                                        color: Colors.grey.shade200)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                      flex: 3,
                                      child: Text(ingredient['nom'],
                                          style: TextStyle(
                                              color:
                                                  ingredient['expire'] == true
                                                      ? Colors.red
                                                      : Colors.black))),
                                  Expanded(
                                      flex: 2,
                                      child: Text(
                                          "${(ingredient['stock_disponible'] as double).toStringAsFixed(2)}",
                                          textAlign: TextAlign.center)),
                                  Expanded(
                                      flex: 2,
                                      child: Text(
                                          "${(ingredient['besoin'] as double).toStringAsFixed(2)}",
                                          textAlign: TextAlign.center)),
                                  Expanded(
                                      flex: 2,
                                      child: Text(
                                          "${(ingredient['manquant'] as double).toStringAsFixed(2)}",
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold))),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text("⚠️ Cause du non-démarrage:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ..._causesList.map((cause) => RadioListTile<String>(
                        title: Text(cause),
                        value: cause,
                        groupValue: _selectedCause,
                        onChanged: (value) {
                          setDialogState(() {
                            _selectedCause = value;
                            if (value != 'Autre') {
                              _autreCauseController.clear();
                              _customCause = '';
                            }
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      )),
                  if (_selectedCause == 'Autre')
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                      child: TextField(
                        controller: _autreCauseController,
                        decoration: InputDecoration(
                          hintText: "Entrez la cause...",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        onChanged: (value) {
                          _customCause = value;
                        },
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Fermer"),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  String finalCause = _selectedCause == 'Autre'
                      ? _autreCauseController.text
                      : (_selectedCause ?? 'Non spécifiée');
                  if (finalCause.isEmpty) {
                    _showErrorSnackBar("Veuillez sélectionner une cause");
                    return;
                  }
                  Navigator.pop(ctx);
                  _rejectProduction(demandeId, productName, qtyToProduce,
                      ingredientsReport, finalCause);
                },
                icon: const Icon(Icons.send, color: Colors.white),
                label: const Text("Signaler au Manager",
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==================== Rejeter la production ====================
  Future<void> _rejectProduction(
    String demandeId,
    String productName,
    double qtyToProduce,
    List<Map<String, dynamic>> ingredientsReport,
    String cause,
  ) async {
    setState(() => _isProcessing = true);
    try {
      await supabase.from('demande_production').update({
        'statut': 'Rejetée',
        'note': "Production impossible - Cause: $cause"
      }).eq('iddemande', demandeId);

      int indisponibleCount =
          ingredientsReport.where((i) => !i['disponible']).length;
      List<String> manquants = ingredientsReport
          .where((i) => !i['disponible'])
          .map((i) => i['nom'] as String)
          .toList();

      try {
        String? chefId = await _getCurrentChefId();
        await supabase.from('log').insert({
          'action': 'PRODUCTION_REJECTED',
          'table_nom': 'demande_production',
          'description': "🔴 PRODUCTION IMPOSSIBLE\n"
              "Produit: $productName\n"
              "Quantité: ${qtyToProduce.toStringAsFixed(2)}\n"
              "Cause: $cause\n"
              "Matières manquantes (${manquants.length}): ${manquants.join(', ')}",
          'datelog': DateTime.now().toIso8601String(),
          'idutilisateur': chefId,
        });
        debugPrint("✅ Log enregistré: PRODUCTION_REJECTED");
      } catch (logError) {
        debugPrint("⚠️ Erreur log (non bloquante): $logError");
      }

      Map<String, dynamic> rapportContent = {
        'type': 'RAPPORT_REJET_PRODUCTION',
        'demande_id': demandeId,
        'produit': productName,
        'quantite_demandee': qtyToProduce,
        'cause_rejet': cause,
        'date_rejet': DateTime.now().toIso8601String(),
        'matieres_manquantes': manquants,
        'details_matieres': ingredientsReport
            .where((i) => !i['disponible'])
            .map((i) => ({
                  'nom': i['nom'],
                  'stock_disponible': i['stock_disponible'],
                  'besoin': i['besoin'],
                  'manquant': i['manquant'],
                }))
            .toList(),
      };

      await _saveRapportToDatabase(
        titre: 'Rapport rejet - $productName',
        type: 'Alerte Production',
        contenu: rapportContent,
      );

      _showDialog(
          "📋 Rapport envoyé",
          "Le rapport a été envoyé au manager.\n"
              "Cause: $cause\n"
              "Matières manquantes: ${manquants.length}");

      await _loadDemandes();
      setState(() {
        _selectedDemande = null;
        _selectedCause = null;
        _autreCauseController.clear();
      });
    } catch (e) {
      _showDialog("Erreur", e.toString());
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  // ==================== Mettre à jour statut demande ====================
  Future<void> _updateDemandeStatut(
      String demandeId, String statut, String note) async {
    try {
      await supabase
          .from('demande_production')
          .update({'statut': statut, 'note': note}).eq('iddemande', demandeId);
      await _loadDemandes();
    } catch (e) {
      debugPrint("Erreur mise à jour: $e");
    }
  }

  // ==================== Générer ID ordre ====================
  Future<String> _generateNextOrderId() async {
    try {
      final response = await supabase
          .from('ordre_de_production')
          .select('idordre')
          .order('idordre', ascending: false)
          .limit(1)
          .maybeSingle();
      if (response == null) return "OP001";
      String lastId = response['idordre'].toString();
      int lastNumber = int.parse(lastId.replaceAll("OP", ""));
      return "OP${(lastNumber + 1).toString().padLeft(3, '0')}";
    } catch (e) {
      return 'OP-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  // ==================== Récupérer ID chef ====================
  Future<String?> _getCurrentChefId() async {
    try {
      final userData = await supabase
          .from('utilisateur')
          .select('idutilisateur')
          .eq('identifiant', 'DIR001')
          .maybeSingle();
      return userData?['idutilisateur']?.toString();
    } catch (e) {
      return null;
    }
  }

  // ==================== Utilitaires ====================
  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.blue),
    );
  }

  // ==================== Build ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBg,
      appBar: CustomHeader(
        title: "Planning de Production",
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadDemandes,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: orangeBrand))
          : _demandes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text("Aucune demande en attente",
                          style: TextStyle(color: Colors.grey.shade500)),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _loadDemandes,
                        icon: const Icon(Icons.refresh),
                        label: const Text("Actualiser"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: orangeBrand,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "📋 Demandes de production (${_demandes.length})",
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: ListView.builder(
                                itemCount: _demandes.length,
                                itemBuilder: (context, index) {
                                  final demande = _demandes[index];
                                  final isSelected = _selectedDemande != null &&
                                      _selectedDemande!['iddemande'] ==
                                          demande['iddemande'];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                    color: isSelected
                                        ? Colors.orange.shade50
                                        : Colors.white,
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: isSelected
                                            ? orangeBrand
                                            : Colors.grey.shade200,
                                        child: Icon(
                                            Icons.production_quantity_limits,
                                            color: isSelected
                                                ? Colors.white
                                                : orangeBrand),
                                      ),
                                      title: Text(
                                        demande['produit']?['nomp'] ??
                                            'Produit',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              "Quantité: ${demande['quantitedemandee']} ${demande['produit']?['unitemesure'] ?? ''}"),
                                          Text(
                                              "Demandé le: ${_formatDate(demande['datedemande'])}",
                                              style: const TextStyle(
                                                  fontSize: 12)),
                                        ],
                                      ),
                                      trailing: isSelected
                                          ? const Icon(Icons.check_circle,
                                              color: Colors.green)
                                          : const Icon(Icons.arrow_forward_ios,
                                              size: 16),
                                      onTap: () {
                                        setState(() {
                                          _selectedDemande = demande;
                                        });
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_selectedDemande != null) ...[
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, -2)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.factory_outlined,
                                    color: orangeBrand),
                                const SizedBox(width: 8),
                                Text(
                                  "Demande sélectionnée",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: orangeBrand),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      "📦 Produit: ${_selectedDemande!['produit']?['nomp']}",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text(
                                      "📊 Quantité: ${_selectedDemande!['quantitedemandee']} ${_selectedDemande!['produit']?['unitemesure'] ?? ''}"),
                                  Text(
                                      "📅 Demandé le: ${_formatDate(_selectedDemande!['datedemande'])}"),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: (_isChecking || _isProcessing)
                                  ? null
                                  : _checkAvailability,
                              icon: _isChecking || _isProcessing
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.checklist_rtl_outlined,
                                      color: Colors.white),
                              label: Text(
                                _isChecking || _isProcessing
                                    ? "Traitement en cours..."
                                    : "Vérifier disponibilité",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: orangeBrand,
                                minimumSize: const Size(double.infinity, 55),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _selectedDemande = null;
                                  _selectedCause = null;
                                  _autreCauseController.clear();
                                });
                              },
                              icon: const Icon(Icons.close),
                              label: const Text("Annuler la sélection"),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '—';
    try {
      DateTime d = date is DateTime ? date : DateTime.parse(date.toString());
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return date.toString();
    }
  }
}
