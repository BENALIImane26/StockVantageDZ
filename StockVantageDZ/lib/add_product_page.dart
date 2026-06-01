import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'production_model.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController idController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController stockController = TextEditingController();
  final TextEditingController unitController = TextEditingController();
  final TextEditingController barcodeController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController expiryDateController = TextEditingController();
  bool isLoading = false;
  String selectedType = "Matière Première";

  @override
  void dispose() {
    idController.dispose();
    nameController.dispose();
    priceController.dispose();
    stockController.dispose();
    unitController.dispose();
    barcodeController.dispose();
    locationController.dispose();
    expiryDateController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController scanController = TextEditingController();
        return AlertDialog(
          title: const Text("Scanner le code barre"),
          content: TextField(
            controller: scanController,
            decoration: const InputDecoration(
              hintText: "Entrez le code barre",
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () {
                if (scanController.text.isNotEmpty) {
                  barcodeController.text = scanController.text;
                  Navigator.pop(context);
                }
              },
              child: const Text("Valider"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectExpiryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        expiryDateController.text = picked.toString().split(' ')[0];
      });
    }
  }

  Future<void> addProduct() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);

      try {
        final productionData = Provider.of<ProductionData>(context, listen: false);

        final existingProduct = await productionData.supabase
            .from('produit')
            .select()
            .eq('idproduit', idController.text.trim())
            .maybeSingle();

        if (existingProduct != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Un produit avec cet ID existe déjà'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => isLoading = false);
          return;
        }

        await productionData.supabase.from('produit').insert({
          'idproduit': idController.text.trim(),
          'nomp': nameController.text.trim(),
          'prix': double.tryParse(priceController.text),
          'quantitestock': double.tryParse(stockController.text) ?? 0,
          'natureproduit': selectedType,
          'unitemesure': unitController.text.trim().isEmpty
              ? "pièce"
              : unitController.text.trim(),
          'code_barre': barcodeController.text.trim().isEmpty
              ? null
              : barcodeController.text.trim(),
          'emplacement': locationController.text.trim().isEmpty
              ? null
              : locationController.text.trim(),
          'dateexpiration': expiryDateController.text.trim().isEmpty
              ? null
              : expiryDateController.text.trim(),
          'seuilalerte': 10,
        });

        await productionData.loadProducts();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Produit ajouté avec succès'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ajouter un produit"),
        backgroundColor: Colors.orange,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scanBarcode,
            tooltip: "Scanner un code barre",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add_box, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Remplissez les informations du produit",
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info, size: 20, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          "Informations de base",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: idController,
                      decoration: const InputDecoration(
                        labelText: "ID Produit *",
                        hintText: "Ex: PRD001",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.qr_code),
                      ),
                      validator: (value) => value == null || value.isEmpty ? "Veuillez entrer l'ID" : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Nom du produit *",
                        hintText: "Ex: Farine",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.production_quantity_limits),
                      ),
                      validator: (value) => value == null || value.isEmpty ? "Veuillez entrer le nom" : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(
                        labelText: "Nature du produit",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: const [
                        DropdownMenuItem(value: "Matière Première", child: Text("Matière Première")),
                        DropdownMenuItem(value: "Produit Fini", child: Text("Produit Fini")),
                        DropdownMenuItem(value: "Consommable", child: Text("Consommable")),
                        DropdownMenuItem(value: "Équipement", child: Text("Équipement")),
                      ],
                      onChanged: (value) => setState(() => selectedType = value!),
                    ),
                  ],
                ),
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
                    const Row(
                      children: [
                        Icon(Icons.attach_money, size: 20, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          "Informations commerciales",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Prix unitaire (DA) *",
                        hintText: "Ex: 45.00",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      validator: (value) => value == null || value.isEmpty ? "Veuillez entrer le prix" : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: stockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Quantité initiale *",
                        hintText: "Ex: 500",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.inventory),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Veuillez entrer la quantité";
                        if (double.tryParse(value) == null) return "Veuillez entrer un nombre valide";
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: unitController,
                      decoration: const InputDecoration(
                        labelText: "Unité de mesure",
                        hintText: "Ex: kg, litre, pièce",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.scale),
                      ),
                    ),
                  ],
                ),
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
                    const Row(
                      children: [
                        Icon(Icons.qr_code_scanner, size: 20, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          "Informations supplémentaires",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: barcodeController,
                      decoration: InputDecoration(
                        labelText: "Code barre",
                        hintText: "Ex: 1234567890123",
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.qr_code),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.camera_alt),
                          onPressed: _scanBarcode,
                          tooltip: "Scanner",
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: "Emplacement",
                        hintText: "Ex: Aile A, Rayon 3",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: expiryDateController,
                      readOnly: true,
                      onTap: _selectExpiryDate,
                      decoration: const InputDecoration(
                        labelText: "Date d'expiration",
                        hintText: "JJ/MM/AAAA",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                        suffixIcon: Icon(Icons.arrow_drop_down),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Annuler"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: isLoading ? null : addProduct,
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text("Ajouter le produit"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}