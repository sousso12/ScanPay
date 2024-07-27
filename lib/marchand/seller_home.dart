import 'package:flutter/material.dart';
import 'package:scanpay/marchand/historique_transaction.dart';
import 'package:scanpay/marchand/qrcode_gen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:scanpay/user_data.dart';

class SellerPage extends StatefulWidget {
  final String email;

  const SellerPage({Key? key, required this.email}) : super(key: key);

  @override
  State<SellerPage> createState() => _SellerPageState();
}

class _SellerPageState extends State<SellerPage> {
  int _currentIndex = 0;
  late Future<UserData> _userDataFuture;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _fetchUserData();
  }

  Future<UserData> _fetchUserData() async {
    final response = await http.post(
      Uri.parse('http://10.0.0.206:3000/get_user_data'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'email': widget.email}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserData(
        fullName:
            data['fullName'] ?? 'Nom inconnu', // Valeur par défaut si null
        email:
            data['email'] ?? widget.email, // Assure que l'email n'est pas null
        password:
            '', // Vous pouvez laisser vide ou récupérer ce champ si nécessaire
        phoneNumber:
            '', // Vous pouvez laisser vide ou récupérer ce champ si nécessaire
        solde: data['solde'] ?? 0, // Valeur par défaut si null
        userType:
            data['userType'] ?? 'Type inconnu', // Valeur par défaut si null
      );
    } else {
      throw Exception('Failed to load user data');
    }
  }

  Widget _buildBody(UserData userData) {
    return IndexedStack(
      index: _currentIndex,
      children: [
        BankCard(userData: userData),
        GenererQrcode(email: userData.email ?? ''),
        TransactionsScreen(email: userData.email ?? ''),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: FutureBuilder<UserData>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            // Vérifiez ici si les données sont présentes et non nulles
            UserData userData = snapshot.data!;
            return _buildBody(userData);
          } else {
            return Center(child: Text('Aucune donnée disponible'));
          }
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_2),
            label: 'QRcode',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.currency_exchange),
            label: 'Historique',
          ),
        ],
      ),
    );
  }
}

class BankCard extends StatelessWidget {
  final UserData userData;

  const BankCard({Key? key, required this.userData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 50.0, left: 19.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            color: Colors.indigoAccent,
            child: Container(
              width: constraints.maxWidth * 0.9,
              height: constraints.maxHeight * 0.3,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'UTILISATEUR',
                        style: TextStyle(
                          color: Colors.yellow[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        userData.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Solde',
                            style: TextStyle(
                              color: Colors.yellow[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${userData.solde} \$',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Type Utilisateur',
                            style: TextStyle(
                              color: Colors.yellow[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            userData.userType,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
