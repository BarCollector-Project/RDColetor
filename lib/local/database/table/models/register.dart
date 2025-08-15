enum RegiterID {
  collect,
}

abstract class Register implements JsonSerializable<Register> {
  final RegiterID id;
  final DateTime timestamp;

  Register({required this.id, required this.timestamp});

  Map<String, dynamic> toJson();
}

abstract class JsonSerializable<T> {
  T fromJson(Map<String, dynamic> json);
}
