class HealthCenter {
  const HealthCenter({
    required this.id,
    required this.name,
    required this.distance,
    required this.address,
    required this.rating,
    required this.open,
  });

  final String id;
  final String name;
  final String distance;
  final String address;
  final double rating;
  final bool open;
}
