abstract class SystemTableModel {
  final String id;
  final String description;

  SystemTableModel({required this.id, required this.description});

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "description": description,
    };
  }
}
