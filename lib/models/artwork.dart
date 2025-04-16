class Artwork {
  final int objectID;
  final String title;
  final String? artistDisplayName;
  final String? department;
  final String? objectDate;
  final String? medium;
  final String? dimensions;
  final String? creditLine;
  final String? primaryImage;
  final String? culture;
  final String? period;
  final String? dynasty;
  final String? reign;
  final String? portfolio;
  final String? artistNationality;
  final String? artistBeginDate;
  final String? artistEndDate;
  final String? artistGender;
  final String? artistWikidataURL;
  final String? objectWikidataURL;
  final bool isHighlight;
  final bool isPublicDomain;
  final String? accessionNumber;
  final String? accessionYear;
  final String? objectURL;

  Artwork({
    required this.objectID,
    required this.title,
    this.artistDisplayName,
    this.department,
    this.objectDate,
    this.medium,
    this.dimensions,
    this.creditLine,
    this.primaryImage,
    this.culture,
    this.period,
    this.dynasty,
    this.reign,
    this.portfolio,
    this.artistNationality,
    this.artistBeginDate,
    this.artistEndDate,
    this.artistGender,
    this.artistWikidataURL,
    this.objectWikidataURL,
    required this.isHighlight,
    required this.isPublicDomain,
    this.accessionNumber,
    this.accessionYear,
    this.objectURL,
  });

  factory Artwork.fromJson(Map<String, dynamic> json) {
    return Artwork(
      objectID: json['objectID'] ?? 0,
      title: json['title'] ?? 'Unknown Title',
      artistDisplayName: json['artistDisplayName'],
      department: json['department'],
      objectDate: json['objectDate'],
      medium: json['medium'],
      dimensions: json['dimensions'],
      creditLine: json['creditLine'],
      primaryImage: json['primaryImage'],
      culture: json['culture'],
      period: json['period'],
      dynasty: json['dynasty'],
      reign: json['reign'],
      portfolio: json['portfolio'],
      artistNationality: json['artistNationality'],
      artistBeginDate: json['artistBeginDate'],
      artistEndDate: json['artistEndDate'],
      artistGender: json['artistGender'],
      artistWikidataURL: json['artistWikidata_URL'],
      objectWikidataURL: json['objectWikidata_URL'],
      isHighlight: json['isHighlight'] ?? false,
      isPublicDomain: json['isPublicDomain'] ?? false,
      accessionNumber: json['accessionNumber'],
      accessionYear: json['accessionYear'],
      objectURL: json['objectURL'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'objectID': objectID,
      'title': title,
      'artistDisplayName': artistDisplayName,
      'department': department,
      'objectDate': objectDate,
      'medium': medium,
      'dimensions': dimensions,
      'creditLine': creditLine,
      'primaryImage': primaryImage,
      'culture': culture,
      'period': period,
      'dynasty': dynasty,
      'reign': reign,
      'portfolio': portfolio,
      'artistNationality': artistNationality,
      'artistBeginDate': artistBeginDate,
      'artistEndDate': artistEndDate,
      'artistGender': artistGender,
      'artistWikidata_URL': artistWikidataURL,
      'objectWikidata_URL': objectWikidataURL,
      'isHighlight': isHighlight,
      'isPublicDomain': isPublicDomain,
      'accessionNumber': accessionNumber,
      'accessionYear': accessionYear,
      'objectURL': objectURL,
    };
  }
} 