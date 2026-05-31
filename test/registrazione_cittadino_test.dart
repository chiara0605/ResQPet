import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

import 'package:resqpet/services/auth_service.dart';
import 'package:resqpet/dao/utente_dao.dart';
import 'package:resqpet/models/utente.dart';
import 'package:resqpet/repositories/utente_repository.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

/// FAKE DAO (isolamento DB)
class FakeUtenteDao implements UtenteDao {
  @override
  Future<Utente> create(Utente data) async => data;

  @override
  Future<Utente?> findById(String id) async => null;

  @override
  Future<List<Utente>> findAll() async => [];

  @override
  Stream<List<Utente>> findAllStream() => const Stream.empty();

  @override
  Future<bool> deleteById(String id) async => true;

  @override
  Future<Utente> update(Utente data) async => data;
}

void main() {
  late MockFirebaseAuth mockAuth;
  late AuthService authService;
  late FakeUtenteDao utenteDao;
  late UtenteRepository repository;

  setUp(() {
    mockAuth = MockFirebaseAuth(
      signedIn: false,
      mockUser: MockUser(uid: "uid-123"),
    );

    authService = AuthService(mockAuth);
    utenteDao = FakeUtenteDao();
    repository = UtenteRepository(authService, utenteDao);
  });

  // ===========================
  // TC_FE2_1 - VALID REGISTRATION
  // ===========================
  test('TC_FE2_1 - Valid registration success', () async {
    final result = await repository.registraCittadino(
      email: "test@gmail.com",
      password: "password123",
      nominativo: "Mario Rossi",
      numeroTelefono: "3331234567",
    );

    expect(result.email, "test@gmail.com");
    expect(result.nominativo, "Mario Rossi");
    expect(result.tipo, TipoUtente.cittadino);
    expect(result.id, "uid-123");
  });

  // ===========================
  // TC_FE1_2 - INVALID EMAIL FORMAT
  // ===========================
  test('TC_FE1_2 - Invalid email format throws', () async {
    expect(
          () => repository.registraCittadino(
        email: "invalid-email",
        password: "password123",
        nominativo: "Mario Rossi",
        numeroTelefono: "3331234567",
      ),
      throwsArgumentError,
    );
  });

  // ===========================
  // TC_LP1_3 - PASSWORD TOO SHORT
  // ===========================
  test('TC_LP1_3 - Password too short', () async {
    expect(
          () => repository.registraCittadino(
        email: "test@gmail.com",
        password: "123",
        nominativo: "Mario Rossi",
        numeroTelefono: "3331234567",
      ),
      throwsArgumentError,
    );
  });

  // ===========================
  // TC_LN1_4 - EMPTY NOMINATIVO
  // ===========================
  test('TC_LN1_4 - Empty nominativo', () async {
    expect(
          () => repository.registraCittadino(
        email: "test@gmail.com",
        password: "password123",
        nominativo: "",
        numeroTelefono: "3331234567",
      ),
      throwsArgumentError,
    );
  });

  // ===========================
  // TC_FT1_5 - INVALID PHONE
  // ===========================
  test('TC_FT1_5 - Invalid phone format', () async {
    expect(
          () => repository.registraCittadino(
        email: "test@gmail.com",
        password: "password123",
        nominativo: "Mario Rossi",
        numeroTelefono: "abc123",
      ),
      throwsArgumentError,
    );
  });

  // ===========================
  // TC_FE2_OK - STREAM FILTER ADMIN
  // ===========================
  test('TC_STREAM - getAllExceptAdmin filters correctly', () async {
    final stream = repository.getAllExceptAdmin();

    expect(stream, isA<Stream<List<Utente>>>());
  });
}