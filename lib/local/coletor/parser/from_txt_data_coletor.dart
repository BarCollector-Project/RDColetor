class ParserFrom {
  static Future<dynamic> coletorDataLine(String txtDataLine) async {
    if (txtDataLine.length > 48) {
      // Garante que a txt_data_line tem o formato correto
      String codigo = txtDataLine
          .substring(0, 15)
          .trim()
          .replaceAll(RegExp(r"\D"), "");
      String nome = txtDataLine.substring(15, 48).trim();
      String precoStr = txtDataLine
          .substring(48, 57)
          .trim()
          .replaceAll(",", ".");
      double preco = double.tryParse(precoStr) ?? 0.0;

      if (codigo.isNotEmpty && nome.isNotEmpty && preco > 0) {
        return {"codigo": codigo, "nome": nome, "preco": preco};
      }
    }
  }
}
