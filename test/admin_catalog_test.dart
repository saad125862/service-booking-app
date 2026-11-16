import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:seba_app/core/network/api_client.dart';
import 'package:seba_app/core/network/api_exception.dart';
import 'package:seba_app/core/storage/token_storage.dart';
import 'package:seba_app/core/widgets/app_button.dart';
import 'package:seba_app/features/admin/data/admin_repository.dart';
import 'package:seba_app/features/admin/domain/admin_service.dart';
import 'package:seba_app/features/admin/presentation/admin_fields_screen.dart';
import 'package:seba_app/features/admin/presentation/admin_payments_screen.dart';
import 'package:seba_app/features/admin/presentation/admin_providers.dart';
import 'package:seba_app/features/admin/presentation/admin_services_screen.dart';
import 'package:seba_app/features/admin/presentation/service_form_screen.dart';
import 'package:seba_app/features/booking/domain/payment_method.dart';
import 'package:seba_app/features/notifications/presentation/notification_providers.dart';
import 'package:seba_app/features/services/domain/service.dart';

import 'test_helpers.dart';

ServiceField _field(
  String key,
  String label,
  FieldType type, {
  List<String> options = const [],
  bool required = false,
  bool active = true,
}) => ServiceField(
  id: 'f-$key',
  key: key,
  label: label,
  type: type,
  options: options,
  required: required,
  isActive: active,
);

AdminService _service({
  String id = 's1',
  String name = 'Swedish Massage',
  bool active = true,
  Map<String, dynamic>? attrs,
}) => AdminService(
  id: id,
  name: name,
  description: 'A relaxing full-body massage.',
  price: 2500,
  durationMinutes: 60,
  category: 'Wellness',
  isFeatured: false,
  isActive: active,
  bookingsCount: 3,
  attributeValues: attrs ?? const {},
);

class FakeCatalogRepository extends AdminRepository {
  FakeCatalogRepository({List<AdminService>? services, List<ServiceField>? fields, List<PaymentMethod>? methods})
    : services_ = services ?? [_service(), _service(id: 's2', name: 'Classic Facial', active: false)],
      fields_ =
          fields ??
          [
            _field('staff_level', 'Specialist level', FieldType.select, options: ['Junior', 'Senior']),
            _field('materials', 'Materials included', FieldType.boolean),
            _field('prep_note', 'Prep note', FieldType.text, required: true),
            _field('old', 'Retired field', FieldType.text, active: false),
          ],
      methods_ =
          methods ??
          [
            const PaymentMethod(id: 'pm1', code: 'cash', name: 'Cash', type: PaymentType.cash),
            const PaymentMethod(
              id: 'pm2',
              code: 'bkash',
              name: 'bKash',
              type: PaymentType.mobileWallet,
              accountNumber: '01700000000',
              requiresReference: true,
            ),
          ],
      super(ApiClient(tokenStorage: TokenStorage(), onUnauthorized: () {}));

  final List<AdminService> services_;
  final List<ServiceField> fields_;
  final List<PaymentMethod> methods_;

  final List<String> activeCalls = [];
  final List<Map<String, dynamic>> created = [];
  final List<Map<String, dynamic>> updated = [];
  final List<Map<String, dynamic>> createdFields = [];
  final List<Map<String, dynamic>> createdMethods = [];
  final List<Map<String, dynamic>> methodUpdates = [];
  final List<String> fieldActiveCalls = [];

  @override
  Future<List<AdminService>> services({String? search, String status = 'all'}) async {
    return services_.where((s) {
      if (status == 'active' && !s.isActive) return false;
      if (status == 'inactive' && s.isActive) return false;
      return search == null || search.isEmpty || s.name.toLowerCase().contains(search.toLowerCase());
    }).toList();
  }

  @override
  Future<AdminService> service(String id) async => services_.firstWhere((s) => s.id == id);

  @override
  Future<AdminService> createService(Map<String, dynamic> body) async {
    created.add(body);
    return _service(id: 'new', name: body['name'] as String);
  }

  @override
  Future<AdminService> updateService(String id, Map<String, dynamic> body) async {
    updated.add(body);
    return _service(id: id, name: body['name'] as String);
  }

  @override
  Future<AdminService> setServiceActive(String id, bool active) async {
    activeCalls.add('$id:$active');
    return _service(id: id, active: active);
  }

  @override
  Future<List<ServiceField>> fields() async => List.of(fields_);

  @override
  Future<ServiceField> createField(Map<String, dynamic> body) async {
    createdFields.add(body);
    final f = _field(
      (body['label'] as String).toLowerCase().replaceAll(' ', '_'),
      body['label'] as String,
      FieldType.parse(body['type'] as String),
      options: [for (final o in (body['options'] as List? ?? const [])) '$o'],
      required: body['required'] as bool,
    );
    fields_.add(f);
    return f;
  }

  @override
  Future<ServiceField> setFieldActive(String id, bool active) async {
    fieldActiveCalls.add('$id:$active');
    return fields_.firstWhere((f) => f.id == id);
  }

  @override
  Future<List<PaymentMethod>> paymentMethods() async => List.of(methods_);

  @override
  Future<PaymentMethod> createPaymentMethod(Map<String, dynamic> body) async {
    createdMethods.add(body);
    final m = PaymentMethod(
      id: 'pm-new',
      code: body['code'] as String,
      name: body['name'] as String,
      type: PaymentType.parse(body['type'] as String),
    );
    methods_.add(m);
    return m;
  }

  @override
  Future<PaymentMethod> updatePaymentMethod(String id, Map<String, dynamic> body) async {
    methodUpdates.add({'id': id, ...body});
    return methods_.firstWhere((m) => m.id == id);
  }
}

Widget _app(FakeCatalogRepository repo, {required String start}) {
  final router = GoRouter(
    initialLocation: start,
    routes: [
      GoRoute(
        path: '/admin/services',
        builder: (_, _) => const AdminServicesScreen(),
        routes: [
          GoRoute(path: 'new', builder: (_, _) => const ServiceFormScreen()),
          GoRoute(
            path: ':id',
            builder: (_, s) => ServiceFormScreen(serviceId: s.pathParameters['id']),
          ),
        ],
      ),
      GoRoute(path: '/admin/fields', builder: (_, _) => const AdminFieldsScreen()),
      GoRoute(path: '/admin/payments', builder: (_, _) => const AdminPaymentsScreen()),
    ],
  );
  return ProviderScope(
    overrides: [adminRepositoryProvider.overrideWithValue(repo), unreadCountProvider.overrideWith(FixedUnread.new)],
    child: MaterialApp.router(routerConfig: router),
  );
}

void _tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('Service and field models', () {
    test('ServiceAttribute formats booleans and numbers for customers', () {
      expect(const ServiceAttribute(key: 'k', label: 'L', type: 'boolean', value: true).display, 'Yes');
      expect(const ServiceAttribute(key: 'k', label: 'L', type: 'boolean', value: false).display, 'No');
      expect(const ServiceAttribute(key: 'k', label: 'L', type: 'number', value: 3.0).display, '3');
      expect(const ServiceAttribute(key: 'k', label: 'L', type: 'number', value: 2.5).display, '2.5');
      expect(const ServiceAttribute(key: 'k', label: 'L', type: 'textarea', value: 'x').isLong, isTrue);
    });

    test('Service.fromJson reads the custom attributes', () {
      final s = Service.fromJson({
        'id': 's1',
        'name': 'Massage',
        'description': 'Relaxing massage for you',
        'price': 2500,
        'durationMinutes': 60,
        'category': 'Wellness',
        'attributes': [
          {'key': 'level', 'label': 'Specialist level', 'type': 'select', 'value': 'Senior'},
        ],
      });
      expect(s.attributes.single.label, 'Specialist level');
      expect(s.attributes.single.display, 'Senior');
    });

    test('FieldType.parse falls back to text', () {
      expect(FieldType.parse('select'), FieldType.select);
      expect(FieldType.parse('nonsense'), FieldType.text);
    });
  });

  group('Services list', () {
    testWidgets('shows services and filters by visibility', (tester) async {
      _tall(tester);
      final repo = FakeCatalogRepository();
      await tester.pumpWidget(_app(repo, start: '/admin/services'));
      await tester.pumpAndSettle();

      expect(find.text('Swedish Massage'), findsOneWidget);
      expect(find.text('Classic Facial'), findsOneWidget);
      expect(find.text('2 services'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Hidden'));
      await tester.pumpAndSettle();
      expect(find.text('Swedish Massage'), findsNothing);
      expect(find.text('Classic Facial'), findsOneWidget);
    });

    testWidgets('the switch hides a service from customers', (tester) async {
      _tall(tester);
      final repo = FakeCatalogRepository();
      await tester.pumpWidget(_app(repo, start: '/admin/services'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      expect(repo.activeCalls, ['s1:false']);
      expect(find.textContaining('hidden from customers'), findsOneWidget);
    });

    testWidgets('Add service opens the form', (tester) async {
      _tall(tester);
      await tester.pumpWidget(_app(FakeCatalogRepository(), start: '/admin/services'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add service'));
      await tester.pumpAndSettle();
      expect(find.text('Extra details'), findsOneWidget);
    });
  });

  group('Dynamic service form', () {
    testWidgets('renders the active custom fields and not the hidden ones', (tester) async {
      _tall(tester);
      await tester.pumpWidget(_app(FakeCatalogRepository(), start: '/admin/services/new'));
      await tester.pumpAndSettle();

      expect(find.text('Specialist level'), findsOneWidget);
      expect(find.text('Materials included'), findsOneWidget);
      expect(find.text('Prep note *'), findsOneWidget);
      expect(find.text('Retired field'), findsNothing);
    });

    testWidgets('validates the basics and required custom fields before saving', (tester) async {
      _tall(tester);
      final repo = FakeCatalogRepository();
      await tester.pumpWidget(_app(repo, start: '/admin/services/new'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.widgetWithText(AppButton, 'Add service'));
      await tester.tap(find.widgetWithText(AppButton, 'Add service'));
      await tester.pumpAndSettle();

      expect(repo.created, isEmpty);
      expect(find.text('Name must be at least 2 characters'), findsOneWidget);
      expect(find.text('Enter a price'), findsOneWidget);
      expect(find.text('Prep note is required'), findsOneWidget);
    });

    testWidgets('saves the base fields together with the custom attributes', (tester) async {
      _tall(tester);
      final repo = FakeCatalogRepository();
      await tester.pumpWidget(_app(repo, start: '/admin/services/new'));
      await tester.pumpAndSettle();

      Future<void> type(String label, String text) async {
        await tester.enterText(find.widgetWithText(TextFormField, label), text);
      }

      await type('Service name *', 'Hot Stone Massage');
      await type('Description *', 'Heated stones melt away deep tension.');
      await type('Price (৳) *', '3200');
      await type('Duration (min) *', '75');
      await type('Category *', 'Wellness');
      await type('Prep note *', 'Shower first');

      await tester.ensureVisible(find.text('Specialist level'));
      await tester.tap(find.text('Specialist level'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Senior').last);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.widgetWithText(AppButton, 'Add service'));
      await tester.tap(find.widgetWithText(AppButton, 'Add service'));
      await tester.pumpAndSettle();

      expect(repo.created, hasLength(1));
      final body = repo.created.single;
      expect(body['name'], 'Hot Stone Massage');
      expect(body['price'], 3200);
      expect(body['durationMinutes'], 75);
      expect(body['isActive'], isTrue);
      expect(body['attributes'], {'staff_level': 'Senior', 'prep_note': 'Shower first'});
    });

    testWidgets('editing pre-fills the form with the saved values', (tester) async {
      _tall(tester);
      final repo = FakeCatalogRepository(
        services: [
          _service(attrs: {'staff_level': 'Junior', 'materials': true, 'prep_note': 'Arrive early'}),
        ],
      );
      await tester.pumpWidget(_app(repo, start: '/admin/services/s1'));
      await tester.pumpAndSettle();

      expect(find.text('Edit service'), findsWidgets);
      expect(find.text('Swedish Massage'), findsOneWidget);
      expect(find.text('Arrive early'), findsOneWidget);
      expect(find.text('Junior'), findsOneWidget);
      expect(find.text('Yes'), findsOneWidget);

      await tester.ensureVisible(find.text('Save changes'));
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(repo.updated, hasLength(1));
      expect(repo.updated.single['attributes'], {
        'staff_level': 'Junior',
        'materials': true,
        'prep_note': 'Arrive early',
      });
    });

    testWidgets('an admin can add a new field from the form and it appears at once', (tester) async {
      _tall(tester);
      final repo = FakeCatalogRepository();
      await tester.pumpWidget(_app(repo, start: '/admin/services/new'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Add a field'));
      await tester.tap(find.text('Add a field'));
      await tester.pumpAndSettle();
      expect(find.text('Add a custom field'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextFormField, 'Field name'), 'Therapist gender');
      await tester.tap(find.text('Add field'));
      await tester.pumpAndSettle();

      expect(repo.createdFields.single['label'], 'Therapist gender');
      expect(repo.createdFields.single['type'], 'text');
      expect(find.text('Therapist gender'), findsOneWidget);
    });

    testWidgets('a dropdown field needs at least one option', (tester) async {
      _tall(tester);
      final repo = FakeCatalogRepository();
      await tester.pumpWidget(_app(repo, start: '/admin/services/new'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Add a field'));
      await tester.tap(find.text('Add a field'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Field name'), 'Room type');
      await tester.tap(find.text('Short text'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dropdown').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add field'));
      await tester.pumpAndSettle();
      expect(find.text('Add at least one option'), findsOneWidget);
      expect(repo.createdFields, isEmpty);

      await tester.enterText(find.widgetWithText(TextFormField, 'Options'), 'Private, Shared, Private');
      await tester.tap(find.text('Add field'));
      await tester.pumpAndSettle();
      expect(repo.createdFields.single['options'], ['Private', 'Shared']);
    });
  });

  group('Custom fields screen', () {
    testWidgets('lists fields with their type and can hide one', (tester) async {
      _tall(tester);
      final repo = FakeCatalogRepository();
      await tester.pumpWidget(_app(repo, start: '/admin/fields'));
      await tester.pumpAndSettle();

      expect(find.text('Specialist level'), findsOneWidget);
      expect(find.text('Dropdown'), findsOneWidget);
      expect(find.text('Junior · Senior'), findsOneWidget);
      expect(find.text('Required'), findsOneWidget);

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      expect(repo.fieldActiveCalls, ['f-staff_level:false']);
    });
  });

  group('Payment options screen', () {
    testWidgets('lists the options and turns one off', (tester) async {
      _tall(tester);
      final repo = FakeCatalogRepository();
      await tester.pumpWidget(_app(repo, start: '/admin/payments'));
      await tester.pumpAndSettle();

      expect(find.text('Cash'), findsWidgets);
      expect(find.text('bKash'), findsOneWidget);
      expect(find.textContaining('01700000000'), findsOneWidget);

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      expect(repo.methodUpdates.single, {'id': 'pm1', 'isActive': false});
    });

    testWidgets('adds an option, making the code from the name', (tester) async {
      _tall(tester);
      final repo = FakeCatalogRepository();
      await tester.pumpWidget(_app(repo, start: '/admin/payments'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add option'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Google Pay');
      await tester.tap(find.widgetWithText(FilledButton, 'Add option'));
      await tester.pumpAndSettle();

      expect(repo.createdMethods.single['code'], 'google_pay');
      expect(repo.createdMethods.single['name'], 'Google Pay');
      expect(repo.createdMethods.single['type'], 'mobile_wallet');
      expect(find.text('Google Pay'), findsOneWidget);
    });

    testWidgets('shows an error when loading fails', (tester) async {
      _tall(tester);
      final repo = _FailingRepo();
      await tester.pumpWidget(_app(repo, start: '/admin/payments'));
      await tester.pumpAndSettle();
      expect(find.text('Server unavailable'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });
}

class _FailingRepo extends FakeCatalogRepository {
  @override
  Future<List<PaymentMethod>> paymentMethods() async =>
      throw const ApiException(message: 'Server unavailable', code: 'NETWORK');
}
