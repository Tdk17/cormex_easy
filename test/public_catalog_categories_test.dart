import 'package:cormex_easy/features/catalog/domain/catalog_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catálogo público mostra somente as seis categorias definidas', () {
    const categories = <ServiceCategory>[
      ServiceCategory(
        id: 'extra-1',
        name: 'Mecânico',
        slug: 'mecanico',
        iconKey: 'car',
      ),
      ServiceCategory(
        id: 'cat-4',
        name: 'Pedreiro',
        slug: 'pedreiro',
        iconKey: 'build',
      ),
      ServiceCategory(
        id: 'cat-6',
        name: 'Jardineiro',
        slug: 'jardineiro',
        iconKey: 'garden',
      ),
      ServiceCategory(
        id: 'cat-2',
        name: 'Encanador',
        slug: 'encanador',
        iconKey: 'water',
      ),
      ServiceCategory(
        id: 'cat-5',
        name: 'Limpeza residencial',
        slug: 'limpeza-residencial',
        iconKey: 'clean',
      ),
      ServiceCategory(
        id: 'cat-1',
        name: 'Eletricista',
        slug: 'eletricista',
        iconKey: 'bolt',
      ),
      ServiceCategory(
        id: 'extra-2',
        name: 'Chaveiro',
        slug: 'chaveiro',
        iconKey: 'key',
      ),
      ServiceCategory(
        id: 'cat-3',
        name: 'Pintura',
        slug: 'pintura',
        iconKey: 'paint',
      ),
    ];

    final visible = publicCatalogCategories(categories);

    expect(
      visible.map((category) => category.name),
      orderedEquals(const [
        'Eletricista',
        'Encanador',
        'Pintor',
        'Pedreiro',
        'Diarista',
        'Jardinagem',
      ]),
    );
    expect(visible.map((category) => category.id), isNot(contains('extra-1')));
    expect(visible.map((category) => category.id), isNot(contains('extra-2')));
  });
}
