import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// تأكد من وجود هذه الملفات في مشروعك أو قم بتغيير أسمائها لتطابق ملفاتك
import 'gestionnaire_de_stock_page.dart';
import 'admin_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode passwordFocus = FocusNode();
  bool obscurePassword = true;

  /// دالة تسجيل الدخول والتحقق من الرول
  Future<void> login() async {
    if (_formKey.currentState!.validate()) {
      final supabase = Supabase.instance.client;

      try {
        final response = await supabase
            .from('utilisateur')
            .select()
            .eq('identifiant', idController.text.trim())
            .eq('motdepasse', passwordController.text.trim())
            .maybeSingle();

        if (response != null) {
          String role = response['role'];
          String nom = response['nom'];
          String prenom = response['prenom'];

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Bienvenue $nom $prenom"),
                backgroundColor: Colors.green,
              ),
            );

            // توجيه المستخدم لصفحته بناءً على صلاحياته
            if (role == 'Gestionnaire de stock') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => StockManagerDashboard(userName: nom),
                ),
              );
            } else if (role == 'Admin') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminDashboard(userName: nom),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Accès non autorisé pour ce rôle"),
                ),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Identifiant ou mot de passe incorrect"),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Erreur connexion: $e"),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4E1EF),
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// HEADER مع التصميم المتعرج
            Stack(
              alignment: Alignment.center,
              children: [
                ClipPath(
                  clipper: HeaderClipper(),
                  child: Container(height: 170, color: Colors.white),
                ),
                Positioned(
                  top: 35,
                  child: Image.network(
                    "https://i.ibb.co/ch18ydxw/IMG-20260307-175140-721.png",
                    height: 110,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.business,
                      size: 80,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            /// ترحيب
           Padding(
              padding: EdgeInsets.symmetric(horizontal: 25),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome 👋",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "Sign in to continue",
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            /// فورم تسجيل الدخول
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Form(
                key: _formKey,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(blurRadius: 12, color: Colors.black12),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: idController,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(passwordFocus),
                        validator: (value) => (value == null || value.isEmpty)
                            ? "Enter ID"
                            : null,
                        decoration: InputDecoration(
                          hintText: "ID (e.g. ADM001)",
                          prefixIcon: const Icon(
                            Icons.person,
                            color: Colors.orange,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: passwordController,
                        focusNode: passwordFocus,
                        obscureText: obscurePassword,
                        onFieldSubmitted: (_) => login(),
                        validator: (value) => (value == null || value.isEmpty)
                            ? "Enter Password"
                            : null,
                        decoration: InputDecoration(
                          hintText: "Password",
                          prefixIcon: const Icon(
                            Icons.lock,
                            color: Colors.orange,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () => setState(
                              () => obscurePassword = !obscurePassword,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: login,
                          child: const Text(
                            "Sign in",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        "En cas d'oubli, contactez l'admin",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 40,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}