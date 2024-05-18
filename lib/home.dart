import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:myapp/add_disease.dart';
import 'package:myapp/disease_detail.dart';
import 'package:myapp/models/disease.dart';
import 'package:myapp/services/firebase_services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Disease> diseases = []; // List to store disease data
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isLoading) {
      fetchDiseaseData(); // Call the method to fetch disease data from Firebase
    }
  }

  Future<void> fetchDiseaseData() async {
    setState(() {
      _isLoading = true;
    });

    FirebaseService firebaseServices = FirebaseService();

    try {
      List<Disease> diseaseData = await firebaseServices.getDiseases();
      setState(() {
        diseases = diseaseData
            .map((data) => Disease(
                  name: data.name, // Access using named parameters
                  imageUrl: data.imageUrl, // Access using named parameters
                  description: data.description, // Access using named parameters
                ))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching disease data: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Navigate to the page where the user can add a new disease
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddDiseaseForm()),
              );
            },
          ),
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "from bud to bounty our app sees every stage",
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "Explore different diseases",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : ListView.builder(
                      itemCount: diseases.length,
                      itemBuilder: (context, index) {
                        final disease = diseases[index];
                        return Card(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: CachedNetworkImage(
                                  imageUrl: disease.imageUrl,
                                  placeholder: (context, url) =>
                                      const CircularProgressIndicator(),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.error),
                                  height: 120,
                                  width: 200,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 16.0),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        disease.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18.0,
                                        ),
                                      ),
                                      const SizedBox(height: 8.0),
                                      ElevatedButton(
                                        onPressed: () {
                                          // Navigate to the disease detail screen
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  DiseaseDetailScreen(
                                                      disease: disease),
                                            ),
                                          );
                                        },
                                        child: const Text('Read More'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

