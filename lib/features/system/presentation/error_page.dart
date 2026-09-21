import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/state_view.dart';

class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key, this.code = 404});

  final int code;

  @override
  Widget build(BuildContext context) {
    final config = switch (code) {
      400 => (Icons.rule, 'Não conseguimos entender a solicitação', 'Revise as informações e tente novamente.'),
      401 => (Icons.login, 'Sua sessão terminou', 'Entre novamente para continuar com segurança.'),
      403 => (Icons.lock_outline, 'Acesso não autorizado', 'Você não possui permissão para acessar esta área.'),
      408 => (Icons.timer_off_outlined, 'A resposta demorou demais', 'Confira sua conexão e tente novamente.'),
      429 => (Icons.speed, 'Muitas tentativas', 'Aguarde um pouco antes de tentar outra vez.'),
      500 => (Icons.error_outline, 'Algo saiu do esperado', 'Nossa equipe poderá investigar sem expor detalhes técnicos aqui.'),
      502 || 503 => (Icons.cloud_off, 'Serviço temporariamente indisponível', 'Estamos tentando restabelecer a conexão.'),
      _ => (Icons.explore_off_outlined, 'Página não encontrada', 'O endereço pode estar incorreto ou o conteúdo foi movido.'),
    };
    return StateView(
      icon: config.$1,
      title: '$code — ${config.$2}',
      message: config.$3,
      actionLabel: 'Ir para o início',
      onAction: () => context.go('/'),
    );
  }
}

