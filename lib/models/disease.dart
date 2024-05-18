class Disease {
  final String name;
  final String description;
  final String imageUrl;

  Disease( 
      {required this.name, required this.description, required this.imageUrl});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
    };
  }

  operator [](String key) {
    switch (key) {
      case 'name':
        return name;
      case 'imageUrl':
        return imageUrl;
      case 'description':
        return description;
      default:
        throw ArgumentError('Invalid key: $key');
    }
  }

  static Disease fromMap(Map<String, dynamic> map) {
    return Disease(
      name: map['name'],
      description: map['description'],
      imageUrl: map['imageUrl'],
    );
  }
}
