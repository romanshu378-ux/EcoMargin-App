class ChargingStation {
  final String id;
  final String name;
  final String address;
  final String distanceStr;
  final int totalChargers;
  final int availableChargers;
  final String chargerType;
  final String chargerCategory;
  final String priceStr;
  final String priceSubtext;
  final String imageUrl;
  final bool isVerified;
  final bool isFavorite;
  final double latitude;
  final double longitude;

  const ChargingStation({
    required this.id,
    required this.name,
    required this.address,
    required this.distanceStr,
    required this.totalChargers,
    required this.availableChargers,
    required this.chargerType,
    required this.chargerCategory,
    required this.priceStr,
    required this.priceSubtext,
    required this.imageUrl,
    this.isVerified = true,
    this.isFavorite = false,
    required this.latitude,
    required this.longitude,
  });

  ChargingStation copyWith({
    bool? isFavorite,
    int? availableChargers,
    String? distanceStr,
  }) {
    return ChargingStation(
      id: id,
      name: name,
      address: address,
      distanceStr: distanceStr ?? this.distanceStr,
      totalChargers: totalChargers,
      availableChargers: availableChargers ?? this.availableChargers,
      chargerType: chargerType,
      chargerCategory: chargerCategory,
      priceStr: priceStr,
      priceSubtext: priceSubtext,
      imageUrl: imageUrl,
      isVerified: isVerified,
      isFavorite: isFavorite ?? this.isFavorite,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
