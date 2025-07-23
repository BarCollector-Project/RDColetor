import 'dart:convert';

/// A classe modelo que representa um único produto.
/// Ela contém a lógica para serialização/desserialização de e para
/// Map (para o banco de dados local) e JSON (para a API do servidor).
class Product {
  final String? id; // Nulo se ainda não foi sincronizado com o servidor.
  final String name;
  final String barcode;
  final double price;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    this.id,
    required this.name,
    required this.barcode,
    required this.price,
    this.createdAt,
    this.updatedAt,
  });

  /// Construtor de fábrica para criar uma instância de [Product] a partir de um Map.
  /// Usado para ler dados do banco de dados local (sqflite).
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String?,
      name: map['name'] as String,
      barcode: map['barcode'] as String,
      price: (map['price'] as num).toDouble(),
      // SQLite não tem tipo DateTime, então convertemos de String (ISO 8601).
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']) : null,
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at']) : null,
    );
  }

  /// Converte a instância de [Product] em um Map.
  /// Usado para escrever dados no banco de dados local (sqflite).
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'price': price,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Construtor de fábrica para criar uma instância de [Product] a partir de um JSON.
  /// Usado para decodificar a resposta da API.
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String?,
      name: json['name'] as String,
      barcode: json['barcode'] as String,
      price: (json['price'] as num).toDouble(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  /// Converte a instância de [Product] em um JSON.
  /// Usado para enviar dados no corpo de uma requisição para a API.
  String toJson() => json.encode(toMapForJson());

  /// Cria um Map pronto para ser codificado em JSON.
  /// Omitimos campos que o servidor gera (como id, timestamps) ao criar um novo produto.
  Map<String, dynamic> toMapForJson() {
    return {
      'name': name,
      'barcode': barcode,
      'price': price,
    };
  }
}
