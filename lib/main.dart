import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'movie_service.dart';

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
      title: 'Catálogo de Películas + Firebase',
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Pantalla de inicio
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
                const Icon(Icons.movie, size: 80, color: Colors.white),
                const SizedBox(height: 20),
                const Text(
                  'Bienvenido al Catálogo de Películas',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MovieSearchScreen(),
                      ),
                    );
                  },
                  child: const Text('Buscar película'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CatalogScreen()),
                    );
                  },
                  child: const Text('Ver catálogo'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Pantalla de búsqueda
class MovieSearchScreen extends StatefulWidget {
  const MovieSearchScreen({super.key});

  @override
  State<MovieSearchScreen> createState() => _MovieSearchScreenState();
}

class _MovieSearchScreenState extends State<MovieSearchScreen> {
  final MovieService service = MovieService(apiKey: '5bc1c2e4');
  Map<String, dynamic>? movie;
  final TextEditingController _controller = TextEditingController();
  String errorMessage = '';

  Future<void> _getMovie() async {
    final title = _controller.text.trim();
    if (title.isEmpty) {
      setState(() {
        errorMessage = 'Escribe el título de la película';
        movie = null;
      });
      return;
    }

    try {
      final data = await service.fetchMovieByTitle(title);
      setState(() {
        movie = data;
        errorMessage = '';
      });

      await FirebaseFirestore.instance.collection('movies').add({
        'title': data['Title'],
        'year': data['Year'],
        'director': data['Director'],
        'genre': data['Genre'],
        'synopsis': data['Plot'],
        'image': data['Poster'],
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      setState(() {
        movie = null;
        errorMessage = 'Esa película no existe o hubo un error';
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.movie_filter, size: 80, color: Colors.white),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.black),
                    decoration: const InputDecoration(
                      hintText: 'Escribe el título de la película',
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
                  if (movie != null)
                    Column(
                      children: [
                        Text(
                          'Título: ${movie!['Title']}',
                          style: const TextStyle(
                            fontSize: 25,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Año: ${movie!['Year']}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 10),
                        if ((movie!['Poster'] ?? '') != 'N/A')
                          Image.network(movie!['Poster'], height: 180),
                        const SizedBox(height: 10),
                        Text(
                          'Director: ${movie!['Director']}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        Text(
                          'Género: ${movie!['Genre']}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            'Sinopsis: ${movie!['Plot']}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getMovie,
        child: const Icon(Icons.search),
      ),
    );
  }
}

// Catálogo con API
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final service = MovieService(apiKey: '5bc1c2e4');
  List<Map<String, dynamic>> movies = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    try {
      final data = await service.getCatalog("Batman"); // ejemplo inicial
      setState(() {
        movies = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        movies = [];
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Catálogo de Películas")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : movies.isEmpty
          ? const Center(child: Text("No se encontraron películas"))
          : ListView.builder(
              itemCount: movies.length,
              itemBuilder: (context, index) {
                final movie = movies[index];
                return ListTile(
                  leading: (movie["Poster"] != null && movie["Poster"] != "N/A")
                      ? Image.network(
                          movie["Poster"],
                          width: 50,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.movie),
                  title: Text(movie["Title"] ?? ""),
                  subtitle: Text(movie["Year"] ?? ""),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            MovieDetailScreen(title: movie["Title"] ?? ""),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

// Pantalla de detalle
class MovieDetailScreen extends StatefulWidget {
  final String title;
  const MovieDetailScreen({super.key, required this.title});

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  final service = MovieService(apiKey: '5bc1c2e4');
  Map<String, dynamic>? movie;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadMovie();
  }

  Future<void> _loadMovie() async {
    try {
      final data = await service.fetchMovieByTitle(widget.title);
      setState(() {
        movie = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        movie = null;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : movie == null
          ? const Center(child: Text("No se pudo cargar la película"))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (movie!["Poster"] != null && movie!["Poster"] != "N/A")
                    Image.network(movie!["Poster"], height: 220),
                  const SizedBox(height: 20),
                  Text(
                    "Año: ${movie!["Year"]}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    "Director: ${movie!["Director"]}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Año: ${movie!["Year"]}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    "Director: ${movie!["Director"]}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    "Género: ${movie!["Genre"]}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Sinopsis:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(movie!["Plot"] ?? ""),
                ],
              ),
            ),
    );
  }
}
