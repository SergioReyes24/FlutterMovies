import 'package:flutter/material.dart';
import 'pokemon_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlutterPokémon + Firebase',
      home: const PokemonScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PokemonScreen extends StatefulWidget {
  const PokemonScreen({super.key});

  @override
  State<PokemonScreen> createState() => _PokemonScreenState();
}

class _PokemonScreenState extends State<PokemonScreen> {
  final service = PokemonService();
  Map<String, dynamic>? pokemon;
  final TextEditingController _controller = TextEditingController();
  String errorMessage = '';

  Future<void> _getPokemon() async {
    final name = _controller.text.trim().toLowerCase();
    if (name.isEmpty) {
      setState(() {
        errorMessage = 'Escribe un nombre de Pokémon';
        pokemon = null;
      });
      return;
    }

    try {
      final data = await service.fetchPokemon(name);
      setState(() {
        pokemon = data;
        errorMessage = '';
      });

      // Guardar en Firestore
      await FirebaseFirestore.instance.collection('pokemons').add({
        'name': data['name'],
        'height': data['height'],
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      setState(() {
        pokemon = null;
        errorMessage = 'Ese Pokémon no existe, intenta de nuevo';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/background.jpg', fit: BoxFit.cover),
          Container(color: const Color.fromRGBO(0, 0, 0, 0.4)),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.catching_pokemon,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.black),
                  decoration: const InputDecoration(
                    hintText: 'Escribe el nombre del Pokémon',
                    filled: true,
                    fillColor: Colors.white70,
                  ),
                ),
                const SizedBox(height: 20),
                if (errorMessage.isNotEmpty)
                  Text(
                    errorMessage,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.redAccent,
                    ),
                  ),
                if (pokemon != null)
                  Column(
                    children: [
                      Text(
                        'Nombre: ${pokemon!['name']}',
                        style: const TextStyle(
                          fontSize: 25,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Altura: ${pokemon!['height']}',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Image.network(
                        pokemon!['sprites']['front_default'],
                        height: 120,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getPokemon,
        child: const Icon(Icons.search),
      ),
    );
  }
}
