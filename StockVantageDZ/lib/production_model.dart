import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SummaryItem {
  final String count;
  final String label;
  final Color color;
  SummaryItem({required this.count, required this.label, required this.color});
}

class ProductionOrderItem {
  final String idordre;
  final String idproduitfini;
  final String productName;
  final String quantiteaproduire;
  final String statutordre;
  final String datedebut;
  final Color statusColor;
  ProductionOrderItem({
    required this.idordre,
    required this.idproduitfini,
    required this.productName,
    required this.quantiteaproduire,
    required this.statutordre,
    required this.datedebut,
    required this.statusColor,
  });
}

class ProductItem {
  final String idproduit;
  final String nomp;
  final double quantitestock;
  final double? prix;
  final double? seuilalerte;
  final String? natureproduit;
  final String? unitemesure;
  ProductItem({
    required this.idproduit,
    required this.nomp,
    required this.quantitestock,
    this.prix,
    this.seuilalerte,
    this.natureproduit,
    this.unitemesure,
  });
}

class StockMovementItem {
  final String idmouv;
  final String idproduit;
  final String productName;
  final String typemouv;
  final double quantitemov;
  final String datemouv;
  StockMovementItem({
    required this.idmouv,
    required this.idproduit,
    required this.productName,
    required this.typemouv,
    required this.quantitemov,
    required this.datemouv,
  });
}

class ProductionData extends ChangeNotifier {
  String chefName = '';
  String chefId = '';
  List<SummaryItem> summaryItems = [];
  List<ProductionOrderItem> productionOrders = [];
  List<ProductItem> products = [];
  List<StockMovementItem> stockMovements = [];
  bool isLoading = false;

  final supabase = Supabase.instance.client;

  RealtimeChannel? _alerteChannel;
  RealtimeChannel? _ordreChannel; // ✅ قناة Realtime لأوامر الإنتاج

  ProductionData() {
    _initData();
    loadAllData();
  }

  void _initData() {
    summaryItems = [
      SummaryItem(count: '0', label: 'Terminé', color: Colors.green),
      SummaryItem(count: '0', label: 'Ordres', color: Colors.blue),
      SummaryItem(count: '0', label: 'Alertes', color: Colors.red),
    ];
  }

  Future<void> loadAllData() async {
    if (isLoading) return;
    isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        loadProducts(),
        loadProductionOrders(),
        loadStockMovements(),
      ]);
      _subscribeToAlertes();
      _subscribeToOrdres(); // ✅ تفعيل Realtime للأوامر
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ✅ Realtime لجدول alerte
  void _subscribeToAlertes() {
    _alerteChannel?.unsubscribe();
    _alerteChannel = supabase
        .channel('realtime:alerte:${DateTime.now().millisecondsSinceEpoch}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'alerte',
          callback: (payload) {
            print('🔔 Alerte changed: ${payload.eventType}');
            updateAlertsCount();
          },
        )
        .subscribe((status, [error]) {
      print('📡 Alerte Realtime: $status error: $error');
    });
  }

  // ✅ Realtime لجدول ordre_de_production
  void _subscribeToOrdres() {
    _ordreChannel?.unsubscribe();
    _ordreChannel = supabase
        .channel('realtime:ordre:${DateTime.now().millisecondsSinceEpoch}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'ordre_de_production',
          callback: (payload) {
            print('📦 Ordre changed: ${payload.eventType}');
            // ✅ إعادة تحميل الأوامر وتحديث العدادات تلقائياً
            loadProductionOrders();
          },
        )
        .subscribe((status, [error]) {
      print('📡 Ordre Realtime: $status error: $error');
    });
  }

  @override
  void dispose() {
    _alerteChannel?.unsubscribe();
    _ordreChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> loadProducts() async {
    try {
      final response = await supabase
          .from('produit')
          .select(
              'idproduit, nomp, quantitestock, prix, seuilalerte, natureproduit, unitemesure')
          .limit(200);

      if (response != null && response.isNotEmpty) {
        final List<ProductItem> tempList = [];
        for (var p in response as List) {
          tempList.add(ProductItem(
            idproduit: p['idproduit'] ?? '',
            nomp: p['nomp'] ?? 'Produit Inconnu',
            quantitestock: (p['quantitestock'] ?? 0).toDouble(),
            prix: p['prix']?.toDouble(),
            seuilalerte: p['seuilalerte']?.toDouble(),
            natureproduit: p['natureproduit'],
            unitemesure: p['unitemesure'],
          ));
        }
        products = tempList;
        await updateAlertsCount();
        notifyListeners();
        print('✅ Loaded ${products.length} products');
      }
    } catch (e) {
      print('Error loading products: $e');
    }
  }

  Future<void> loadProductionOrders() async {
    try {
      final response = await supabase
          .from('ordre_de_production')
          .select(
              'idordre, idproduitfini, quantiteaproduire, statutordre, datedebut')
          .order('datedebut', ascending: false)
          .limit(100);

      if (response != null && response.isNotEmpty) {
        final List<ProductionOrderItem> tempList = [];
        for (var order in response as List) {
          String productName =
              _getProductNameFromList(order['idproduitfini'] ?? '');
          tempList.add(ProductionOrderItem(
            idordre: order['idordre'] ?? '',
            idproduitfini: order['idproduitfini'] ?? '',
            productName: productName,
            quantiteaproduire: order['quantiteaproduire']?.toString() ?? '0',
            statutordre: order['statutordre'] ?? 'En attente',
            datedebut: order['datedebut']?.toString().split('T')[0] ?? '',
            statusColor: _getStatusColor(order['statutordre']),
          ));
        }
        productionOrders = tempList;
        // ✅ تحديث العدادات مباشرة من البيانات المحملة
        _updateOrdersCountFromData(tempList);
        notifyListeners();
        print('✅ Loaded ${productionOrders.length} orders');
      } else {
        productionOrders = [];
        _updateOrdersCountFromData([]);
        notifyListeners();
      }
    } catch (e) {
      print('Error loading orders: $e');
    }
  }

  Future<void> loadStockMovements() async {
    try {
      final response = await supabase
          .from('mouvement_de_stock')
          .select('idmouv, idproduit, typemouv, quantitemov, datemouv')
          .order('datemouv', ascending: false)
          .limit(100);

      if (response != null && response.isNotEmpty) {
        final List<StockMovementItem> tempList = [];
        for (var move in response as List) {
          String productName = _getProductNameFromList(move['idproduit'] ?? '');
          tempList.add(StockMovementItem(
            idmouv: move['idmouv'] ?? '',
            idproduit: move['idproduit'] ?? '',
            productName: productName,
            typemouv: move['typemouv'] ?? 'Entree',
            quantitemov: (move['quantitemov'] ?? 0).toDouble(),
            datemouv: move['datemouv']?.toString().split('T')[0] ?? '',
          ));
        }
        stockMovements = tempList;
        notifyListeners();
        print('✅ Loaded ${stockMovements.length} movements');
      }
    } catch (e) {
      print('Error loading movements: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getStockMovementsHistory(
      {int limit = 100}) async {
    try {
      final response = await supabase.from('mouvement_de_stock').select('''
            idmouv,
            typemouv,
            quantitemov,
            datemouv,
            idproduit,
            produit:produit(nomp, unitemesure)
          ''').order('datemouv', ascending: false).limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error loading stock movements history: $e');
      return [];
    }
  }

  String _getProductNameFromList(String idproduit) {
    for (var p in products) {
      if (p.idproduit == idproduit) return p.nomp;
    }
    return 'Produit Inconnu';
  }

  Future<void> addNewProductionOrder({
    required String idproduitfini,
    required double quantiteaproduire,
    required DateTime datedebut,
  }) async {
    try {
      String newIdOrdre =
          'ORD${(productionOrders.length + 1).toString().padLeft(4, '0')}';
      await supabase.from('ordre_de_production').insert({
        'idordre': newIdOrdre,
        'idutilisateur': chefId,
        'idproduitfini': idproduitfini,
        'quantiteaproduire': quantiteaproduire,
        'statutordre': 'En attente',
        'datedebut': datedebut.toIso8601String(),
      });
      await loadProductionOrders();
      print('✅ Nouvel ordre ajouté: $newIdOrdre');
    } catch (e) {
      print('Error adding order: $e');
      rethrow;
    }
  }

  Future<void> updateOrderStatus(String idordre, String newStatus) async {
    try {
      await supabase
          .from('ordre_de_production')
          .update({'statutordre': newStatus}).eq('idordre', idordre);
      await loadProductionOrders();
      print('✅ Ordre $idordre mis à jour: $newStatus');
    } catch (e) {
      print('Error updating order: $e');
    }
  }

  List<ProductionOrderItem> getCompletedOrders() {
    return productionOrders.where((o) => o.statutordre == 'Terminé').toList();
  }

  List<ProductionOrderItem> getActiveOrders() {
    return productionOrders.where((o) => o.statutordre != 'Terminé').toList();
  }

  // ✅ تحديث العدادات مباشرة من قائمة الأوامر بدون استدعاء إضافي
  void _updateOrdersCountFromData(List<ProductionOrderItem> orders) {
    int completed = orders.where((o) => o.statutordre == 'Terminé').length;
    int active = orders.where((o) => o.statutordre != 'Terminé').length;
    summaryItems = summaryItems.map((item) {
      if (item.label == 'Ordres')
        return SummaryItem(
            count: active.toString(), label: item.label, color: item.color);
      if (item.label == 'Terminé')
        return SummaryItem(
            count: completed.toString(), label: item.label, color: item.color);
      return item;
    }).toList();
    print('✅ Terminé: $completed | Ordres actifs: $active');
  }

  void updateOrdersCount() {
    _updateOrdersCountFromData(productionOrders);
    notifyListeners();
  }

  // ✅ يعد فقط التنبيهات غير المقروءة
  Future<void> updateAlertsCount() async {
    try {
      final response =
          await supabase.from('alerte').select('idalerte').eq('is_read', false);
      final alertCount = response.length;
      summaryItems = summaryItems.map((item) {
        if (item.label == 'Alertes')
          return SummaryItem(
              count: alertCount.toString(),
              label: item.label,
              color: item.color);
        return item;
      }).toList();
      notifyListeners();
      print('✅ Alertes non lues: $alertCount');
    } catch (e) {
      print('Error loading alerts count: $e');
      summaryItems = summaryItems.map((item) {
        if (item.label == 'Alertes')
          return SummaryItem(count: '0', label: item.label, color: item.color);
        return item;
      }).toList();
      notifyListeners();
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

  void setChefName(String name) {
    chefName = name;
    notifyListeners();
  }

  void setChefId(String id) {
    chefId = id;
    notifyListeners();
  }
}
