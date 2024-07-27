import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ScannerScreen extends StatefulWidget {
  final String email;

  ScannerScreen({required this.email});

  @override
  _ScannerScreenState createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  String qrCodeResult = "Scannez un code QR";
  bool isProcessing = false;
  String? numCompteClient;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.0.206:3000/get_user_data'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'email': widget.email}),
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        setState(() {
          numCompteClient = userData['numCompte'];
        });
      } else {
        print(
            "Erreur lors de la récupération des données utilisateur: ${response.reasonPhrase}");
      }
    } catch (e) {
      print("Erreur: $e");
    }
  }

  Future<void> startScan() async {
    String scanResult;
    try {
      scanResult = await FlutterBarcodeScanner.scanBarcode(
        "#4F5AFF",
        "Annuler",
        true,
        ScanMode.QR,
      );

      if (scanResult == '-1') {
        scanResult = "Le scan a été annulé";
      }
    } catch (e) {
      scanResult = 'Erreur: $e';
    }

    if (!mounted) return;

    setState(() {
      qrCodeResult = scanResult;
    });

    if (scanResult.isNotEmpty && scanResult != '-1') {
      _processTransaction(scanResult);
    }
  }

  Future<void> _processTransaction(String qrData) async {
    if (numCompteClient == null) {
      setState(() {
        qrCodeResult = "Erreur: numéro de compte client introuvable";
      });
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      final qrCodeData = jsonDecode(qrData);
      final numCompteMarchand = qrCodeData['numCompteMarchand'];
      final amount = double.parse(qrCodeData['amount']);

      if (amount <= 0) {
        setState(() {
          qrCodeResult = "Le montant doit être supérieur à zéro.";
        });
        return;
      }

      final response = await http.post(
        Uri.parse('http://10.0.0.206:3000/api/process_transaction'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'numCompteClient': numCompteClient,
          'numCompteMarchand': numCompteMarchand,
          'amount': amount,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          qrCodeResult =
              responseData['message'] ?? "Transaction effectuée avec succès";
        });
      } else {
        setState(() {
          qrCodeResult = "Erreur de transaction: ${response.reasonPhrase}";
        });
      }
    } catch (e) {
      setState(() {
        qrCodeResult = "Erreur: $e";
      });
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scanner QR'),
        backgroundColor: Colors.indigoAccent,
      ),
      body: Center(
        child: isProcessing
            ? CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    qrCodeResult,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20.0),
                  ),
                  SizedBox(height: 20.0),
                  ElevatedButton(
                    onPressed: startScan,
                    child: Text('Commencer le scan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigoAccent,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      textStyle:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
