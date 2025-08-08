import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rdcoletor/features/app_route.dart';
import 'package:rdcoletor/local/auth/service/auth_service.dart';

class BlocksLayout {
  final BuildContext context;

  BlocksLayout({required this.context});

  Widget buildSectionTitle(String title) {
    return Padding(
      // Adiciona um espaçamento vertical e um pouco de padding horizontal.
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0, left: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }

  /// Constrói um botão padrão para o GridView da home.
  Widget buildGridButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    double maxSize = 160.0, // Tamanho ideal para um layout com quebra de linha.
  }) {
    // O SizedBox força o botão a ter um tamanho máximo específico,
    // permitindo que o Wrap os organize lado a lado.
    return SizedBox(
      width: maxSize,
      height: maxSize,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12), // Para o efeito de clique
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 50, color: Theme.of(context).primaryColor),
              const SizedBox(height: 12),
              Padding(
                // Adiciona um padding para evitar que o texto encoste nas bordas.
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _build(List<Widget> children) {
    List<Widget> processedChildren = [];
    for (int i = 0; i < children.length; i++) {
      if (children[i] is SizedBox) {
        final List<Widget> wrapChildren = [];
        while (i < children.length && children[i] is SizedBox) {
          wrapChildren.add(
            children[i],
          );
          i++;
        }
        final wrap = Wrap(
          spacing: 16.0, // Espaçamento horizontal entre os botões.
          runSpacing: 16.0, // Espaçamento vertical entre as linhas.
          alignment: WrapAlignment.center, // Centraliza os botões.
          children: wrapChildren,
        );
        processedChildren.add(wrap);
        i--;
      } else {
        processedChildren.add(children[i]);
      }
    }

    return processedChildren;
  }

  Widget buildScaffold({List<Widget> children = const []}) {
    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          // Adiciona rolagem para evitar overflow em telas menores ou com muitos botões.
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _build(children),
          ),
        ),
      ),
    );
  }
}
