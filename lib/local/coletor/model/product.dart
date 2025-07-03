class Product {
  final String codigo;
  final String nome;
  final double preco;

  Product({
    required this.codigo,
    required this.nome,
    required this.preco,
  });

  // Converte um Map em um objeto Product. Útil ao ler do banco de dados.
  factory Product.fromMap(Map<String, dynamic> map) {
    // Tratamento para o preço que pode vir como String ou double/int
    final priceValue = map['preco'];
    double price = 0.0;
    if (priceValue is String) {
      price = double.tryParse(priceValue.replaceAll(',', '.')) ?? 0.0;
    } else if (priceValue is num) {
      price = priceValue.toDouble();
    }

    return Product(
      codigo: map['codigo'] as String,
      nome: map['nome'] as String,
      preco: price,
    );
  }

  // Converte um objeto Product em um Map. Útil ao escrever no banco de dados.
  Map<String, dynamic> toMap() {
    return {
      'codigo': codigo,
      'nome': nome,
      'preco': preco,
    };
  }
}
