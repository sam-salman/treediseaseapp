import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/models/disease.dart';
import 'package:myapp/services/firebase_services.dart';

class AddDiseaseForm extends StatefulWidget {
  const AddDiseaseForm({super.key});

  @override
  _AddDiseaseFormState createState() => _AddDiseaseFormState();
}

class _AddDiseaseFormState extends State<AddDiseaseForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;

  void _pickImage(ImageSource source) async {
    final pickedImage = await ImagePicker().pickImage(source: source);

    
    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });
    }
  }

  void _addDisease() async {
    setState(() {
      _isLoading = true;
    });

    if (_selectedImage == null) {
      // Show error if no image selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final name = _nameController.text;
    final description = _descriptionController.text;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Adding Disease...'),
          ],
        ),
      ),
    );

    // Call FirebaseService to upload image and add disease
    final imageUrl = await FirebaseService().uploadDiseasePicture(_selectedImage!);
    if (imageUrl != null) {
      await FirebaseService().addDisease(Disease(
        name: name,
        description: description,
        imageUrl: imageUrl,
      ));
      // Close loading dialog
      Navigator.pop(context);
      _nameController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedImage = null;
      });
      //snackbar for long time
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Disease added successfully'),
          duration: Duration(seconds: 3),
        ),
      );
      
    } else {
      // Close loading dialog
      Navigator.pop(context);
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add disease')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Disease'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    onTap: () => _pickImage(ImageSource.gallery),
                    child: CircleAvatar(
                      radius: 80,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : null,
                      child: _selectedImage == null
                          ? const Icon(Icons.camera_alt, size: 50, color: Colors.grey)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _addDisease,
                    child: const Text('Add'),
                  ),
                ],
              ),
            ),
    );
  }
}