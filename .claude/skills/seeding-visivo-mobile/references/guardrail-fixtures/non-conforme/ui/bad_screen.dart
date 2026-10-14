// Fixture NON-CONFORME — viola di proposito i check, per dimostrare che mordono.
// (Niente tema centralizzato, niente MaterialApp, niente carattere caricato.)
import 'package:flutter/material.dart';

class BadScreen extends StatelessWidget {
  const BadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF123456), // viola 1: colore hardcoded
      body: Padding(
        padding: const EdgeInsets.all(17), // viola 7: spaziatura magica
        child: Text(
          'Ciao',
          style: const TextStyle(fontSize: 22, color: Colors.red), // viola 2 + 1
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange, // viola 6 + 1: FAB ricolorato, secondo accento
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
