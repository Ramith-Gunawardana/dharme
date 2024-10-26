class Prediction {
  final String displayName;
  final String color;
  final String icon;
  final String prediction;

  Prediction({
    required this.displayName,
    required this.color,
    required this.icon,
    required this.prediction,
  });

  factory Prediction.fromJson(Map<String, dynamic> json) {
    return Prediction(
      displayName: json['display_name'],
      color: json['color'],
      icon: json['icon'],
      prediction: json['probability'],
    );
  }
}
