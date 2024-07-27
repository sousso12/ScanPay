import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TransactionsScreen extends StatefulWidget {
  final String email;

  const TransactionsScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  late Future<List<Transaction>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    // Initialisation de la récupération des transactions
    _transactionsFuture = _fetchTransactions();
  }

  // Fonction pour récupérer les transactions de l'utilisateur
  Future<List<Transaction>> _fetchTransactions() async {
    try {
      final userResponse = await http.post(
        Uri.parse('http://10.0.0.206:3000/get_user_data'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'email': widget.email}),
      );

      if (userResponse.statusCode == 200) {
        final userData = jsonDecode(userResponse.body);
        final numCompte = userData['numCompte'];

        final transactionResponse = await http.post(
          Uri.parse('http://10.0.0.206:3000/get_user_transactions'),
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode({'numCompte': numCompte}),
        );

        if (transactionResponse.statusCode == 200) {
          final List<dynamic> data = jsonDecode(transactionResponse.body);
          return data.map((json) => Transaction.fromJson(json)).toList();
        } else {
          _showErrorSnackbar('Échec de la récupération des transactions');
          return [];
        }
      } else {
        _showErrorSnackbar('Échec de la récupération des données utilisateur');
        return [];
      }
    } catch (error) {
      _showErrorSnackbar('Erreur : $error');
      return [];
    }
  }

  // Fonction pour rejeter une transaction
  Future<void> _rejectTransaction(Transaction transaction) async {
    try {
      // Nettoyer le montant pour retirer les symboles $ et convertir en nombre
      final amount = transaction.amount.replaceAll(RegExp(r'[^0-9.]'), '');

      final response = await http.post(
        Uri.parse('http://10.0.0.206:3000/reject_transaction'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'numTransaction': transaction.numTransaction,
          'amount': amount,
          'numCompteClient': transaction.numCompteClient,
          'numCompteMarchand': transaction.numCompteMarchand,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          // Mise à jour de la liste des transactions après le rejet
          _transactionsFuture = _fetchTransactions();
        });
        _showSuccessSnackbar('Transaction rejetée avec succès.');
      } else {
        _showErrorSnackbar('Échec du rejet de la transaction.');
      }
    } catch (error) {
      _showErrorSnackbar('Erreur : $error');
    }
  }

  // Affichage d'un Snackbar en cas d'erreur
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: TextStyle(color: Colors.red))),
    );
  }

  // Affichage d'un Snackbar en cas de succès
  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: TextStyle(color: Colors.green))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des Transactions'),
      ),
      body: FutureBuilder<List<Transaction>>(
        future: _transactionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Aucune transaction disponible.'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final transaction = snapshot.data![index];
                return ListTile(
                  title: Text('Transaction ID: ${transaction.numTransaction}'),
                  subtitle: Text(
                    'Montant: ${transaction.amount}\nDate: ${transaction.date}\nStatut: ${transaction.status}',
                  ),
                  trailing: transaction.status != 'Rejetée'
                      ? ElevatedButton(
                          onPressed: () {
                            _rejectTransaction(transaction);
                          },
                          child: const Text('Rejeter'),
                        )
                      : null,
                );
              },
            );
          }
        },
      ),
    );
  }
}

class Transaction {
  final String date;
  final String numTransaction;
  final String amount;
  final String status;
  final String numCompteClient;
  final String numCompteMarchand;

  Transaction({
    required this.date,
    required this.numTransaction,
    required this.amount,
    required this.status,
    required this.numCompteClient,
    required this.numCompteMarchand,
  });

  // Factory pour créer une instance de Transaction à partir d'un JSON
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      date: json['date'] ?? 'N/A',
      numTransaction: json['numTransaction'] ?? 'N/A',
      amount: json['amount'] ?? '0.0',
      status: json['status'] ?? 'N/A',
      numCompteClient: json['numCompteClient'] ?? 'N/A',
      numCompteMarchand: json['numCompteMarchand'] ?? 'N/A',
    );
  }
}
