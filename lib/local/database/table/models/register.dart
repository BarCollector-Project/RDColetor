enum RegiterID {
  collect,
}

abstract class Register {
  final RegiterID id;
  final DateTime timestamp;

  Register({required this.id, required this.timestamp});

  Map<String, dynamic> toJson();
}
