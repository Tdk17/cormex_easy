import 'package:flutter/material.dart';

import '../../../core/widgets/responsive_shell.dart';

class LegalPage extends StatelessWidget {
  const LegalPage({required this.title, super.key});
  final String title;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: PageWidth(
        maxWidth: 820,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 56),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 18),
              const Text(
                'Documento em preparação para validação jurídica antes da '
                'publicação em produção. A plataforma coleta apenas os dados '
                'necessários, solicita localização com contexto e permite '
                'navegação sem compartilhá-la publicamente.',
                style: TextStyle(height: 1.6),
              ),
              const SizedBox(height: 16),
              const Text(
                'Quando a localização automática é autorizada, a última '
                'cidade, as coordenadas e o catálogo mais recente ficam '
                'armazenados somente no aparelho para continuidade offline. '
                'Esses dados são atualizados quando o aplicativo volta a ter '
                'conexão e podem ser substituídos ao informar outra cidade.',
                style: TextStyle(height: 1.6),
              ),
              const SizedBox(height: 16),
              const Text(
                'Nenhuma credencial de pagamento, token privado ou chave '
                'administrativa é armazenada no aplicativo web.',
                style: TextStyle(height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
