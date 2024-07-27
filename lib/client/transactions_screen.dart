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
    _transactionsFuture = _fetchTransactions();
  }

  Future<List<Transaction>> _fetchTransactions() async {
    final response = await http.post(
      Uri.parse('http://10.0.0.206:3000/get_user_data'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'email': widget.email}),
    );

    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body);
      final numCompte = userData['numCompte'];
      print('User Data: $userData'); // Log user data

      final transactionResponse = await http.post(
        Uri.parse('http://10.0.0.206:3000/get_user_transactions'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'numCompte': numCompte}),
      );

      if (transactionResponse.statusCode == 200) {
        final List<dynamic> data = jsonDecode(transactionResponse.body);
        print('Transactions Data: $data'); // Log transactions data
        return data.map((json) => Transaction.fromJson(json)).toList();
      } else {
        print(
            'Failed to load transactions. Status code: ${transactionResponse.statusCode}');
        throw Exception('Failed to load transactions');
      }
    } else {
      print('Failed to load user data. Status code: ${response.statusCode}');
      throw Exception('Failed to load user data');
    }
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
                      'Montant: ${transaction.amount}\nDate: ${transaction.date}\nStatus: ${transaction.status}'),
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

  Transaction({
    required this.date,
    required this.numTransaction,
    required this.amount,
    required this.status,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      date: json['date'],
      numTransaction: json['numTransaction'],
      amount: json['amount'],
      status: json['status'],
    );
  }
}
