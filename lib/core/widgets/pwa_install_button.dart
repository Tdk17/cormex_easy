import 'dart:async';

import 'package:flutter/material.dart';

import '../pwa/pwa_install_service.dart';

class PwaInstallButton extends StatefulWidget {
  const PwaInstallButton({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  State<PwaInstallButton> createState() => _PwaInstallButtonState();
}

class _PwaInstallButtonState extends State<PwaInstallButton> {
  final _service = PwaInstallService.instance;
  late final StreamSubscription<void> _subscription;
  late bool _visible;

  @override
  void initState() {
    super.initState();
    _visible = _service.shouldShowInstall;
    _subscription = _service.stateChanges.listen((_) {
      if (!mounted) return;
      setState(() => _visible = _service.shouldShowInstall);
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    if (widget.compact) {
      return IconButton(
        key: const Key('pwa-install-button'),
        tooltip: 'Instalar CormeX Easy',
        color: Colors.white,
        onPressed: _onInstall,
        icon: const Icon(Icons.download_for_offline_outlined),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: TextButton.icon(
        key: const Key('pwa-install-button'),
        onPressed: _onInstall,
        icon: const Icon(Icons.download_rounded, size: 20),
        label: const Text('Instalar'),
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.white.withValues(alpha: .1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Future<void> _onInstall() async {
    if (_service.isIos && !_service.canInstall) {
      await _showInstallHelp(ios: true);
      return;
    }

    final result = await _service.install();
    if (!mounted) return;

    switch (result) {
      case PwaInstallOutcome.accepted:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Instalação do CormeX Easy iniciada.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      case PwaInstallOutcome.dismissed:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Você pode instalar o aplicativo quando quiser.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      case PwaInstallOutcome.unavailable:
        await _showInstallHelp();
    }
  }

  Future<void> _showInstallHelp({bool ios = false}) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.install_mobile_rounded,
                size: 46,
                color: Color(0xFF7A1830),
              ),
              const SizedBox(height: 12),
              Text(
                'Instale o CormeX Easy',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                ios
                    ? 'No iPhone, a instalação é feita pelo menu do Safari.'
                    : 'Instale pelo menu do navegador e use como um aplicativo.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              if (ios) ...[
                const _InstallStep(
                  number: '1',
                  icon: Icons.ios_share_rounded,
                  text: 'Toque no botão Compartilhar do Safari.',
                ),
                const _InstallStep(
                  number: '2',
                  icon: Icons.add_box_outlined,
                  text: 'Escolha “Adicionar à Tela de Início”.',
                ),
                const _InstallStep(
                  number: '3',
                  icon: Icons.check_circle_outline,
                  text: 'Confirme tocando em “Adicionar”.',
                ),
              ] else ...[
                const _InstallStep(
                  number: '1',
                  icon: Icons.more_vert_rounded,
                  text: 'Abra o menu do seu navegador.',
                ),
                const _InstallStep(
                  number: '2',
                  icon: Icons.install_mobile_rounded,
                  text: 'Escolha “Instalar app” ou “Adicionar à tela inicial”.',
                ),
              ],
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstallStep extends StatelessWidget {
  const _InstallStep({
    required this.number,
    required this.icon,
    required this.text,
  });

  final String number;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFF5E8EC),
            foregroundColor: const Color(0xFF7A1830),
            child: Text(
              number,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: const Color(0xFF7A1830)),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
