class Artwork {
  final int objectId;
  final String title;
  final String? artistName;
  final String? period;
  final String? culture;
  final String? description;
  final String? primaryImageUrl;
  final List<String>? additionalImageUrls;
  final String? department;
  final int? year;
  final String? medium;
  final String? dimensions;
  
  Artwork({
    required this.objectId,
    required this.title,
    this.artistName,
    this.period,
    this.culture,
    this.description,
    this.primaryImageUrl,
    this.additionalImageUrls,
    this.department,
    this.year,
    this.medium,
    this.dimensions,
  });
  
  factory Artwork.fromJson(Map<String, dynamic> json) {
    List<String> additionalImages = [];
    if (json['additionalImages'] != null) {
      additionalImages = List<String>.from(json['additionalImages']);
    }
    
    return Artwork(
      objectId: json['objectID'],
      title: json['title'] ?? 'Unknown Title',
      artistName: json['artistDisplayName'],
      period: json['period'],
      culture: json['culture'],
      description: json['objectDescription'],
      primaryImageUrl: json['primaryImage'],
      additionalImageUrls: additionalImages,
      department: json['department'],
      year: json['objectEndDate'],
      medium: json['medium'],
      dimensions: json['dimensions'],
    );
  }
} 