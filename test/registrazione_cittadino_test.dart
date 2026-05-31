import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:resqpet/models/utente.dart';
import 'package:resqpet/services/auth_service.dart';
import 'package:resqpet/dao/utente_dao.dart';
import 'package:resqpet/repositories/utente_repository.dart';

@GenerateNiceMocks([
  MockSpec<AuthService>(),
  MockSpec<UtenteDao>(),
  MockSpec<UserCredential>(),
  MockSpec<User>(),
])

import 'registrazione_cittadino_test.mocks.dart';

void main() {
  late UtenteRepository utenteRepository;
  late MockAuthService mockAuthService;
  late MockUtenteDao mockUtenteDao;

  setUp(() {
    mockAuthService = MockAuthService();
    mockUtenteDao = MockUtenteDao();
    utenteRepository = UtenteRepository(mockAuthService, mockUtenteDao);
  });

  group('UtenteRepository - registraCittadino Black-Box Tests', () {

    /**
     * ===========================
     * Test Case ID: TC_REG_1
     * Test Frame: TF1
     * Objective: Verify registration fails when email format is invalid.
     *
     * Input parameters:
     * - email = "invalid-email"
     * - password = "password123"
     * - nominativo = "Mario Rossi"
     * - numeroTelefono = "3331234567"
     * ===========================
     */
    test('TC_REG_1 - Invalid email format should throw ArgumentError', () async {
      expect(
            () => utenteRepository.registraCittadino(
          email: "invalid-email",
          password: "password123",
          nominativo: "Mario Rossi",
          numeroTelefono: "3331234567",
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    /**
     * ===========================
     * Test Case ID: TC_REG_2
     * Test Frame: TF2
     * Objective: Verify registration fails when email is already present in database.
     *
     * Input parameters:
     * - email = "mario@test.it"
     * - password = "password123"
     * - nominativo = "Mario Rossi"
     * - numeroTelefono = "3331234567"
     * ===========================
     */
    test('TC_REG_2 - Email already present should throw Exception', () async {
      // Logic assumes _registraUtente checks uniqueness via Dao or AuthService fails
      when(mockAuthService.signUp(any, any)).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

      expect(
            () => utenteRepository.registraCittadino(
          email: "mario@test.it",
          password: "password123",
          nominativo: "Mario Rossi",
          numeroTelefono: "3331234567",
        ),
        throwsA(isA<FirebaseAuthException>()),
      );
    });

    /**
     * ===========================
     * Test Case ID: TC_REG_3
     * Test Frame: TF3
     * Objective: Verify registration fails when password is too short.
     *
     * Input parameters:
     * - email = "mario@test.it"
     * - password = "123"
     * - nominativo = "Mario Rossi"
     * - numeroTelefono = "3331234567"
     * ===========================
     */
    test('TC_REG_3 - Short password (<8) should throw ArgumentError', () async {
      expect(
            () => utenteRepository.registraCittadino(
          email: "mario@test.it",
          password: "123",
          nominativo: "Mario Rossi",
          numeroTelefono: "3331234567",
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    /**
     * ===========================
     * Test Case ID: TC_REG_4
     * Test Frame: TF4
     * Objective: Verify registration fails when nominativo is blank.
     *
     * Input parameters:
     * - email = "mario@test.it"
     * - password = "password123"
     * - nominativo = ""
     * - numeroTelefono = "3331234567"
     * ===========================
     */
    test('TC_REG_4 - Blank nominativo should throw ArgumentError', () async {
      expect(
            () => utenteRepository.registraCittadino(
          email: "mario@test.it",
          password: "password123",
          nominativo: "",
          numeroTelefono: "3331234567",
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    /**
     * ===========================
     * Test Case ID: TC_REG_5
     * Test Frame: TF5
     * Objective: Verify registration fails when phone format is invalid.
     *
     * Input parameters:
     * - email = "mario@test.it"
     * - password = "password123"
     * - nominativo = "Mario Rossi"
     * - numeroTelefono = "123"
     * ===========================
     */
    test('TC_REG_5 - Invalid phone format should throw ArgumentError', () async {
      expect(
            () => utenteRepository.registraCittadino(
          email: "mario@test.it",
          password: "password123",
          nominativo: "Mario Rossi",
          numeroTelefono: "123",
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    /**
     * ===========================
     * Test Case ID: TC_REG_6
     * Test Frame: TF6
     * Objective: Verify successful registration with all valid parameters.
     *
     * Input parameters:
     * - email = "mario@test.it"
     * - password = "password123"
     * - nominativo = "Mario Rossi"
     * - numeroTelefono = "3331234567"
     * ===========================
     */
    test('TC_REG_6 - Successful registration', () async {
      final mockUser = MockUser();
      final mockCredential = MockUserCredential();

      when(mockUser.uid).thenReturn("uid_123");
      when(mockCredential.user).thenReturn(mockUser);
      when(mockAuthService.signUp("mario@test.it", "password123"))
          .thenAnswer((_) async => mockCredential);

      when(mockUtenteDao.create(any)).thenAnswer((realInvocation) async => realInvocation.positionalArguments[0]);

      final result = await utenteRepository.registraCittadino(
        email: "mario@test.it",
        password: "password123",
        nominativo: "Mario Rossi",
        numeroTelefono: "3331234567",
      );

      expect(result.email, "mario@test.it");
      expect(result.tipo, TipoUtente.cittadino);
      expect(result.id, "uid_123");
      verify(mockUtenteDao.create(any)).called(1);
    });
  });
}