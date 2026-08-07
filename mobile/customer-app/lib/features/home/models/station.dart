class ChargingStation {
  final String id;
  final String name;
  final String address;
  final double distanceKm;
  final int totalChargers;
  final int availableChargers;
  final String chargerType; // AC, DC Fast, Ultra Fast
  final double pricePerKwh;
  final String imageUrl;
  final bool isVerified;
  final double rating;
  final bool isFavorite;

  const ChargingStation({
    required this.id,
    required this.name,
    required this.address,
    required this.distanceKm,
    required this.totalChargers,
    required this.availableChargers,
    required this.chargerType,
    required this.pricePerKwh,
    required this.imageUrl,
    this.isVerified = true,
    this.rating = 4.8,
    this.isFavorite = false,
  });

  ChargingStation copyWith({bool? isFavorite, int? availableChargers}) {
    return ChargingStation(
      id: id,
      name: name,
      address: address,
      distanceKm: distanceKm,
      totalChargers: totalChargers,
      availableChargers: availableChargers ?? this.availableChargers,
      chargerType: chargerType,
      pricePerKwh: pricePerKwh,
      imageUrl: imageUrl,
      isVerified: isVerified,
      rating: rating,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
