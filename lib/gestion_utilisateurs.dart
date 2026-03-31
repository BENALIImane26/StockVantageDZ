import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── الألوان الأساسية ──────────────────────────────────────────────────────
const Color kOrange = Color(0xFFC8650A);
const Color kGreen = Color(0xFF3B6D11);
const Color kRed = Color(0xFFA32D2D);

// ─── النموذج (Model) ───────────────────────────────────────────────────────
class UserModel {
  final String id;
  final String identifiant;
  final String nom;
  final String prenom;
  final String role;
  String statuts;

  UserModel({
    required this.id,
    required this.identifiant,
    required this.nom,
    required this.prenom,
    required this.role,
    required this.statuts,
  });

  String get fullName => '$prenom $nom';

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['idutilisateur']?.toString() ?? '', 
      identifiant: map['identifiant'] as String? ?? '',
      nom: map['nom'] as String? ?? '',
      prenom: map['prenom'] as String? ?? '',
      role: map['role'] as String? ?? 'Admin',
      statuts: map['statuts'] as String? ?? 'Active',
    );
  }
}

// ─── الصفحة الرئيسية ───────────────────────────────────────────────────────
class GestionUtilisateursPage extends StatefulWidget {
  const GestionUtilisateursPage({super.key});

  @override
  State<GestionUtilisateursPage> createState() => _GestionUtilisateursPageState();
}

class _GestionUtilisateursPageState extends State<GestionUtilisateursPage> {
  final _supabase = Supabase.instance.client;
  List<UserModel> _users = [];
  bool _isLoading = true;

  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _identCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _selectedRole = 'Gestionnaire de stock';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      setState(() => _isLoading = true);
      final data = await _supabase
          .from('utilisateur')
          .select('idutilisateur, identifiant, nom, prenom, role, statuts')
          .order('nom');

      setState(() {
        _users = (data as List).map((e) => UserModel.fromMap(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Fetch Error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addUser() async {
    if (_identCtrl.text.isEmpty || _nomCtrl.text.isEmpty) return;
    try {
      await _supabase.from('utilisateur').insert({
        'identifiant': _identCtrl.text.trim(),
        'nom': _nomCtrl.text.trim(),
        'prenom': _prenomCtrl.text.trim(),
        'motdepasse': _passCtrl.text.trim(),
        'role': _selectedRole,
        'statuts': 'Active',
      });
      _nomCtrl.clear(); _prenomCtrl.clear(); _identCtrl.clear(); _passCtrl.clear();
      Navigator.pop(context);
      _fetchUsers();
    } catch (e) {
      debugPrint('Insert Error: $e');
    }
  }

  void _openAddUserDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة مستخدم جديد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _identCtrl, decoration: const InputDecoration(labelText: 'المعرف')),
              TextField(controller: _nomCtrl, decoration: const InputDecoration(labelText: 'اللقب')),
              TextField(controller: _prenomCtrl, decoration: const InputDecoration(labelText: 'الاسم')),
              TextField(controller: _passCtrl, decoration: const InputDecoration(labelText: 'كلمة المرور'), obscureText: true),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                items: ['Admin', 'Chef de production', 'Directeur', 'Gestionnaire de stock']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedRole = val!),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(onPressed: _addUser, child: const Text('حفظ')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة المستخدمين'), backgroundColor: kOrange),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (ctx, i) => Card(
                child: ListTile(
                  title: Text(_users[i].fullName),
                  subtitle: Text(_users[i].role),
                  trailing: Text(_users[i].statuts, style: TextStyle(color: _users[i].statuts == 'Active' ? kGreen : kRed)),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(onPressed: _openAddUserDialog, child: const Icon(Icons.add)),
    );
  }
}