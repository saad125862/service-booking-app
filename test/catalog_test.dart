import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seba_app/core/network/api_client.dart';
import 'package:seba_app/core/network/api_exception.dart';
import 'package:seba_app/core/storage/token_storage.dart';
import 'package:seba_app/core/utils/formatters.dart';
import 'package:seba_app/features/auth/domain/user.dart';
import 'package:seba_app/features/auth/presentation/auth_controller.dart';
import 'package:seba_app/features/services/data/service_repository.dart';
import 'package:seba_app/features/services/domain/service.dart';
import 'package:seba_app/features/services/domain/service_filters.dart';
import 'package:seba_app/features/services/presentation/home_screen.dart';
import 'package:seba_app/features/services/presentation/service_details_screen.dart';
import 'package:seba_app/features/services/presentation/services_providers.dart';

const _massage = Service(
  id: 'svc-1',
  name: 'Swedish Massage',
  description: 'A relaxing full-body massage.',
  price: 60,
  durationMinutes: 60,
  category: 'Wellness',
  isFeatured: true,
  bookingsCount: 3,
);
const _facial = Service(
  id: 'svc-2',
  name: 'Classic Facial',
  description: 'Deep cleansing facial.',
  price: 45,
  durationMinutes: 45,
  category: 'Beauty',
);

/// In-memory repository: filters by search/category like the real API would.
class FakeServiceRepository extends ServiceRepository {
  FakeServiceRepository({this.failList = false, this.all = const [_massage, _facial]})
      : super(ApiClient(tokenStorage: TokenStorage(), onUnauthorized: () {}));

  final bool failList;
  final List<Service> all;
  final List<ServiceFilters> requested = [];

  @override
  Future<ServicePage> list({
    ServiceFilters filters = const ServiceFilters(),
    int page = 1,
    int limit = 12,
    bool featuredOnly = false,
  }) async {
    if (failList && !featuredOnly) {
      throw const ApiException(message: 'Server unavailable', code: 'NETWORK');
    }
    requested.add(filters);
    var items = all.where((s) {
      final q = filters.search.trim().toLowerCase();
      final matchesSearch = q.isEmpty || s.name.toLowerCase().contains(q);
      final matchesCategory = filters.category == null || s.category == filters.category;
      return matchesSearch && matchesCategory && (!featuredOnly || s.isFeatured);
    }).toList();
    return ServicePage(items: items, page: 1, totalPages: 1, total: items.length);
  }

  @override
  Future<List<ServiceCategory>> categories() async => const [
        ServiceCategory(name: 'Beauty', count: 1),
        ServiceCategory(name: 'Wellness', count: 1),
      ];

  @override
  Future<Service> detail(String id) async => all.firstWhere((s) => s.id == id);
}

class FakeAuth extends AuthController {
  @override
  Future<User?> build() async => const User(id: 'u1', name: 'Demo User', email: 'demo@example.com');
}

Widget _app(Widget home, FakeServiceRepository repo) => ProviderScope(
      overrides: [
        serviceRepositoryProvider.overrideWithValue(repo),
        authProvider.overrideWith(FakeAuth.new),
      ],
      child: MaterialApp(home: home),
    );

void main() {
  group('models and filters', () {
    test('Service.fromJson parses the API payload (numbers may be ints)', () {
      final s = Service.fromJson({
        'id': 'a',
        'name': 'Yoga',
        'description': 'd',
        'price': 40,
        'durationMinutes': 60,
        'imageUrl': null,
        'category': 'Fitness',
        'isFeatured': false,
        'bookingsCount': 2,
      });
      expect(s.price, 40.0);
      expect(s.imageUrl, isNull);
      expect(s.bookingsCount, 2);
    });

    test('formatters', () {
      expect(Formatters.price(2500), '৳2,500');
      expect(Formatters.price(45.5), '৳45.50');
      expect(Formatters.duration(45), '45 min');
      expect(Formatters.duration(60), '1 h');
      expect(Formatters.duration(90), '1 h 30 min');
    });

    test('ServiceFilters builds the API query and knows when it is active', () {
      const none = ServiceFilters();
      expect(none.isActive, isFalse);
      expect(none.toQuery(), isEmpty);

      const f = ServiceFilters(
        search: '  massage ',
        category: 'Wellness',
        sort: ServiceSort.priceAsc,
        maxPrice: 70,
      );
      expect(f.isActive, isTrue);
      expect(f.toQuery(), {
        'search': 'massage',
        'category': 'Wellness',
        'sort': 'price_asc',
        'maxPrice': 70.0,
      });
    });
  });

  group('home screen', () {
    testWidgets('shows greeting, featured section and the service list', (tester) async {
      await tester.pumpWidget(_app(const HomeScreen(), FakeServiceRepository()));
      await tester.pumpAndSettle();

      expect(find.text('Hello, Demo'), findsOneWidget);
      expect(find.text('Featured'), findsWidgets); // section title + badge
      expect(find.text('All services'), findsOneWidget);
      expect(find.text('Swedish Massage'), findsWidgets);
      expect(find.text('Classic Facial'), findsOneWidget);
      expect(find.text('2 services'), findsOneWidget);
    });

    testWidgets('searching narrows the list, and no match shows an empty state that can be cleared', (tester) async {
      final repo = FakeServiceRepository();
      await tester.pumpWidget(_app(const HomeScreen(), repo));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'facial');
      await tester.pump(const Duration(milliseconds: 500)); // debounce
      await tester.pumpAndSettle();
      expect(find.text('Classic Facial'), findsOneWidget);
      expect(find.text('Swedish Massage'), findsNothing);
      expect(find.text('Results'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.text('No services found'), findsOneWidget);

      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();
      expect(find.text('Swedish Massage'), findsWidgets);
      expect(find.text('No services found'), findsNothing);
    });

    testWidgets('choosing a category chip filters the list', (tester) async {
      await tester.pumpWidget(_app(const HomeScreen(), FakeServiceRepository()));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, 'Beauty'));
      await tester.pumpAndSettle();

      expect(find.text('Classic Facial'), findsOneWidget);
      expect(find.text('Swedish Massage'), findsNothing);
    });

    testWidgets('shows an error with a retry when the list cannot load', (tester) async {
      await tester.pumpWidget(_app(const HomeScreen(), FakeServiceRepository(failList: true)));
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Server unavailable'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });

  group('service details', () {
    testWidgets('shows price, duration, description and the Book now action', (tester) async {
      await tester.pumpWidget(_app(
        const ServiceDetailsScreen(serviceId: 'svc-1', initial: _massage),
        FakeServiceRepository(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Swedish Massage'), findsOneWidget);
      expect(find.text('৳60'), findsWidgets);
      expect(find.text('1 h'), findsOneWidget);
      expect(find.text('3 times'), findsOneWidget);
      expect(find.text('A relaxing full-body massage.'), findsOneWidget);
      expect(find.text('Book now'), findsOneWidget);
    });
  });
}
