import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/brand_logo.dart';

class MaintenancePage extends StatelessWidget {
  const MaintenancePage({
    super.key,
    this.emergency = false,
    this.title,
    this.message,
    this.estimatedReturnAt,
  });

  final bool emergency;
  final String? title;
  final String? message;
  final DateTime? estimatedReturnAt;

  @override
  Widget build(BuildContext context) {
    final heading = title?.trim().isNotEmpty == true
        ? title!
        : emergency
            ? 'Ajuste emergencial em andamento'
            : 'Estamos fazendo uma melhoria';
    final body = message?.trim().isNotEmpty == true
        ? message!
        : emergency
            ? 'O CormeX Easy está temporariamente indisponível. Volte em alguns instantes.'
            : 'Uma manutenção programada está deixando a plataforma ainda melhor. Obrigado pela compreensão.';
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFFFFFAF7), Color(0xFFF5E8EB)]),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(34),
                  child: Column(
                    children: [
                      const BrandLogo(),
                      const SizedBox(height: 30),
                      Container(
                        width: 94,
                        height: 94,
                        decoration: const BoxDecoration(color: Color(0xFFF2E4E8), shape: BoxShape.circle),
                        child: Icon(emergency ? Icons.build_circle_outlined : Icons.handyman_outlined, color: AppColors.wine, size: 48),
                      ),
                      const SizedBox(height: 22),
                      Text(heading, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 12),
                      Text(body, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, height: 1.5)),
                      if (estimatedReturnAt != null) ...[
                        const SizedBox(height: 12),
                        Text('Previsão: ${estimatedReturnAt!.toLocal()}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                      const SizedBox(height: 24),
                      FilledButton.icon(onPressed: () => context.go('/'), icon: const Icon(Icons.refresh), label: const Text('Tentar novamente')),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
