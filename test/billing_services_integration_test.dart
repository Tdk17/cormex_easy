import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('frontend usa exclusivamente o contrato oficial de cobrança', () {
    final billing = File(
      'lib/features/advertise/data/billing_repository.dart',
    ).readAsStringSync();
    final plans = File(
      'lib/features/advertise/presentation/plans_page.dart',
    ).readAsStringSync();
    final onboarding = File(
      'lib/features/advertise/presentation/advertise_page.dart',
    ).readAsStringSync();
    final manager = File(
      'lib/features/advertise/presentation/manage_ad_page.dart',
    ).readAsStringSync();
    final account = File(
      'lib/features/account/presentation/account_page.dart',
    ).readAsStringSync();
    final combined = '$billing\n$plans\n$onboarding\n$manager\n$account';

    for (final endpoint in [
      'v1-billing-plans-list',
      'v1-billing-subscription-create',
      'v1-billing-subscription-me',
      'v1-billing-subscription-sync',
      'v1-billing-subscription-cancel',
      'v1-billing-subscription-pause',
      'v1-billing-subscription-resume',
      'v1-billing-subscription-change-plan',
      'v1-billing-subscription-history',
    ]) {
      expect(combined, contains(endpoint));
    }
    expect(combined, contains('EASY_PROFISSIONAL'));
    expect(combined, contains('EASY_NEGOCIOS'));
    expect(combined, isNot(contains('v1-subscriptions-')));
    expect(combined, isNot(contains('v1-plans-eligible')));
  });

  test('gestor de anúncio integra o CRUD oficial de serviços', () {
    final repository = File(
      'lib/features/advertise/data/provider_services_repository.dart',
    ).readAsStringSync();
    final panel = File(
      'lib/features/advertise/presentation/provider_services_panel.dart',
    ).readAsStringSync();
    final manager = File(
      'lib/features/advertise/presentation/manage_ad_page.dart',
    ).readAsStringSync();

    for (final endpoint in [
      'v1-provider-services-list',
      'v1-provider-services-create',
      'v1-provider-services-update',
      'v1-provider-services-delete',
    ]) {
      expect(repository, contains(endpoint));
    }
    expect(panel, contains('serviceLimit'));
    expect(panel, contains('categoryLimit'));
    expect(manager, contains('ProviderServicesPanel'));
  });
}
