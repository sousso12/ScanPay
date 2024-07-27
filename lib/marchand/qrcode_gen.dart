import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:scanpay/user_data.dart';

class GenererQrcode extends StatefulWidget {
  final String email;

  const GenererQrcode({Key? key, required this.email}) : super(key: key);

  @override
  State<GenererQrcode> createState() => _GenererQrcodeState();
}

class _GenererQrcodeState extends State<GenererQrcode> {
  final TextEditingController _controller = TextEditingController();
  String _qrData = '';
  late Future<UserData> _userDataFuture;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _userDataFuture = _fetchUserData();
  }

  // Fonction pour récupérer les données de l'utilisateur
  Future<UserData> _fetchUserData() async {
    try {
      print('Fetching user data for email: ${widget.email}');
      final response = await http.post(
        Uri.parse('http://10.0.0.206:3000/get_user_data'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'email': widget.email}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('User data received: $data');
        return UserData(
          fullName: data['fullName'] ?? 'Nom inconnu',
          email: widget.email,
          password: data['password'] ?? '',
          phoneNumber: data['phoneNumber'] ?? '',
          solde: data['solde'] ?? 0,
          userType: data['userType'] ?? 'Type inconnu',
          numCompte: data['numCompte'] ?? 'Compte inconnu',
        );
      } else {
        print('Failed to fetch user data with status: ${response.statusCode}');
        throw Exception('Failed to load user data');
      }
    } catch (e) {
      print('Error fetching user data: $e');
      rethrow;
    }
  }

  void _generateQrCode(UserData userData) {
    final amountText = _controller.text;
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      setState(() {
        _errorMessage = 'Veuillez entrer un montant valide.';
        _qrData = '';
      });
    } else {
      setState(() {
        _qrData = jsonEncode({
          'amount': amount.toString(),
          'numCompteMarchand': userData.numCompte,
        });
        _errorMessage = '';
        print('QR Data generated: $_qrData');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text("Générer le QR Code")),
        backgroundColor: Colors.indigoAccent,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      backgroundColor: Colors.white,
      body: FutureBuilder<UserData>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            return _buildQrCodeGenerator(snapshot.data!, bottomPadding);
          } else {
            return const Center(child: Text('Aucune donnée disponible'));
          }
        },
      ),
    );
  }

  // Widget pour construire le générateur de QR Code
  Widget _buildQrCodeGenerator(UserData userData, double bottomPadding) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SizedBox(height: bottomPadding > 0 ? 20 : 100),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Entrez une valeur',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _generateQrCode(userData),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.indigoAccent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            child: const Text('Générer le QR Code'),
          ),
          const SizedBox(height: 20),
          if (_errorMessage.isNotEmpty)
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          const SizedBox(height: 10),
          if (_qrData.isNotEmpty)
            QrImageView(
              data: _qrData,
              size: 200.0,
              foregroundColor: Colors.indigoAccent,
            ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
