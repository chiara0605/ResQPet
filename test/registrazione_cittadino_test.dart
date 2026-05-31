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
  late UtenteRepository repository;
  late MockAuthService mockAuthService;
  late MockUtenteDao mockUtenteDao;

  setUp(() {
    mockAuthService = MockAuthService();
    mockUtenteDao = MockUtenteDao();
    repository = UtenteRepository(mockAuthService, mockUtenteDao);
  });

  group('UtenteRepository - registraCittadino', () {

    /**
     * ===========================
     * Test Case ID: TC_REG_01
     * Test Frame: TF1
     * Objective: Verify error handling for invalid email format.
     *
     * Input parameters:
     * - email = "invalid-email"
     * - password = "password123"
     * - nominativo = "Mario Rossi"
     * - numeroTelefono = "3331234567"
     * ===========================
     */
    test('TC_REG_01 - Should throw ArgumentError for invalid email', () async {
      expect(
            () => repository.registraCittadino(
          email: 'invalid-email',
          password: 'password123',
          nominativo: 'Mario Rossi',
          numeroTelefono: '3331234567',
        ),
        throwsA(isA<ArgumentError>().having((e) => e.message, 'message', 'Email non valida')),
      );
      verifyZeroInteractions(mockAuthService);
    });

    /**
     * ===========================
     * Test Case ID: TC_REG_02
     * Test Frame: TF2
     * Objective: Verify error handling when email is already registered in Firebase.
     *
     * Input parameters:
     * - email = "mario@test.it"
     * - password = "password123"
     * - nominativo = "Mario Rossi"
     * - numeroTelefono = "3331234567"
     * ===========================
     */
    test('TC_REG_02 - Should propagate error if email already present (AuthException)', () async {
      when(mockAuthService.signUp(any, any)).thenThrow(
        FirebaseAuthException(code: 'email-already-in-use'),
      );

      expect(
            () => repository.registraCittadino(
          email: 'mario@test.it',
          password: 'password123',
          nominativo: 'Mario Rossi',
          numeroTelefono: '3331234567',
        ),
        throwsA(isA<FirebaseAuthException>()),
      );
    });

    /**
     * ===========================
     * Test Case ID: TC_REG_03
     * Test Frame: TF3
     * Objective: Verify error handling for password shorter than 8 characters.
     *
     * Input parameters:
     * - email = "mario@test.it"
     * - password = "123"
     * - nominativo = "Mario Rossi"
     * - numeroTelefono = "3331234567"
     * ===========================
     */
    test('TC_REG_03 - Should throw ArgumentError for short password', () async {
      expect(
            () => repository.registraCittadino(
          email: 'mario@test.it',
          password: '123',
          nominativo: 'Mario Rossi',
          numeroTelefono: '3331234567',
        ),
        throwsA(isA<ArgumentError>().having((e) => e.message, 'message', contains('almeno 8 caratteri'))),
      );
    });

    /**
     * ===========================
     * Test Case ID: TC_REG_04
     * Test Frame: TF4
     * Objective: Verify error handling for empty nominativo.
     *
     * Input parameters:
     * - email = "mario@test.it"
     * - password = "password123"
     * - nominativo = "  "
     * - numeroTelefono = "3331234567"
     * ===========================
     */
    test('TC_REG_04 - Should throw ArgumentError for blank nominativo', () async {
      expect(
            () => repository.registraCittadino(
          email: 'mario@test.it',
          password: 'password123',
          nominativo: '  ',
          numeroTelefono: '3331234567',
        ),
        throwsA(isA<ArgumentError>().having((e) => e.message, 'message', contains('non può essere vuoto'))),
      );
    });

    /**
     * ===========================
     * Test Case ID: TC_REG_05
     * Test Frame: TF5
     * Objective: Verify error handling for non-Italian or invalid phone format.
     *
     * Input parameters:
     * - email = "mario@test.it"
     * - password = "password123"
     * - nominativo = "Mario Rossi"
     * - numeroTelefono = "12345"
     * ===========================
     */
    test('TC_REG_05 - Should throw ArgumentError for invalid phone format', () async {
      expect(
            () => repository.registraCittadino(
          email: 'mario@test.it',
          password: 'password123',
          nominativo: 'Mario Rossi',
          numeroTelefono: '12345',
        ),
        throwsA(isA<ArgumentError>().having((e) => e.message, 'message', 'Numero di telefono non valido')),
      );
    });

    /**
     * ===========================
     * Test Case ID: TC_REG_06
     * Test Frame: TF6
     * Objective: Verify successful registration with valid data.
     *
     * Input parameters:
     * - email = "mario@test.it"
     * - password = "password123"
     * - nominativo = "Mario Rossi"
     * - numeroTelefono = "3331234567"
     * ===========================
     */
    test('TC_REG_06 - Should return Utente object on success', () async {
      final mockCredential = MockUserCredential();
      final mockUser = MockUser();

      when(mockUser.uid).thenReturn('uid_123');
      when(mockCredential.user).thenReturn(mockUser);
      when(mockAuthService.signUp(any, any)).thenAnswer((_) async => mockCredential);

      when(mockUtenteDao.create(any)).thenAnswer((invocation) async {
        return invocation.positionalArguments[0] as Utente;
      });

      final result = await repository.registraCittadino(
        email: 'mario@test.it',
        password: 'password123',
        nominativo: 'Mario Rossi',
        numeroTelefono: '3331234567',
      );

      expect(result.email, 'mario@test.it');
      expect(result.id, 'uid_123');
      expect(result.tipo, TipoUtente.cittadino);

      verify(mockAuthService.signUp('mario@test.it', 'password123')).called(1);
      verify(mockUtenteDao.create(argThat(isA<Utente>()))).called(1);
    });
  });
}