import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

class HistoriqueMouvementsPage extends StatefulWidget {
  const HistoriqueMouvementsPage({super.key});

  @override
  State<HistoriqueMouvementsPage> createState() =>
      _HistoriqueMouvementsPageState();
}

class _HistoriqueMouvementsPageState extends State<HistoriqueMouvementsPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _movements = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'TOUT';

  @override
  void initState() {
    super.initState();
    _loadMovements();
  }

  // دالة عرض الصورة المقتبسة من صفحة EtatStock
  Widget _buildProductImage(String? path, Color iconColor, {double size = 50}) {
    if (path != null && path.isNotEmpty) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        width: size,
        height: size,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(iconColor),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Icon(
            Icons.inventory_2_outlined,
            color: iconColor,
            size: size * 0.6),
      );
    } else {
      return Icon(Icons.inventory_2_outlined,
          color: iconColor, size: size * 0.6);
    }
  }

  Future<void> _loadMovements() async {
    setState(() => _isLoading = true);
    try {
      // الاستعلام الصحيح بناءً على "لاباز" الخاصة بك
      final response = await supabase.from('mouvement_de_stock').select('''
            idmouv,
            typemouv,
            quantitemov,
            datemouv,
            idproduit,
            produit:produit!inner(nomp, unitemesure, image_path)
          ''').order('datemouv', ascending: false).limit(100);

      setState(() {
        _movements = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading history: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredMovements {
    var filtered = _movements;
    if (_selectedFilter != 'TOUT') {
      filtered = filtered
          .where(
              (m) => m['typemouv']?.toString().toUpperCase() == _selectedFilter)
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((m) {
        final productName =
            m['produit']?['nomp']?.toString().toLowerCase() ?? '';
        return productName.contains(_searchQuery.toLowerCase());
      }).toList();
    }
    return filtered;
  }

  Color _getTypeColor(String type) {
    if (type.toUpperCase() == 'ENTREE') return Colors.green;
    if (type.toUpperCase() == 'SORTIE') return Colors.red;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: CustomHeader(
        title: "Historique des Mouvements",
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadMovements,
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط البحث
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: "Rechercher un produit...",
                prefixIcon: const Icon(Icons.search, color: Color(0xFFFF9800)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none),
              ),
            ),
          ),

          // أزرار الفلترة
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterButton('TOUT', Colors.grey),
                const SizedBox(width: 8),
                _buildFilterButton('ENTREE', Colors.green),
                const SizedBox(width: 8),
                _buildFilterButton('SORTIE', Colors.red),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF9800)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredMovements.length,
                    itemBuilder: (context, index) {
                      final move = _filteredMovements[index];
                      final type =
                          move['typemouv']?.toString().toUpperCase() ?? '';
                      final color = _getTypeColor(type);

                      // جلب بيانات المنتج من العلاقة (Relation)
                      final product = move['produit'];
                      final String productName = product?['nomp'] ?? 'Inconnu';
                      final String? imagePath = product?['image_path'];
                      final String unit = product?['unitemesure'] ?? '';
                      final double qty = (move['quantitemov'] ?? 0).toDouble();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0.5,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          // هنا وضعنا الصورة بجانب الاسم بنفس تصميم EtatStock
                          leading: Container(
                            width: 55,
                            height: 55,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: ClipOval(
                              child: Center(
                                child: _buildProductImage(imagePath, color,
                                    size: 55),
                              ),
                            ),
                          ),
                          title: Text(
                            productName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                "${type == 'SORTIE' ? '-' : '+'}$qty $unit",
                                style: TextStyle(
                                    color: color, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                move['datemouv']?.toString().split('T')[0] ??
                                    '',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              type == 'ENTREE' ? 'Entrée' : 'Sortie',
                              style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
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

  Widget _buildFilterButton(String type, Color color) {
    final isSelected = _selectedFilter == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedFilter = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              type,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}