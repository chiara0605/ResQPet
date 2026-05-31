import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:resqpet/core/utils/regex.dart';

import 'package:resqpet/dao/utente_dao.dart';
import 'package:resqpet/models/utente.dart';
import 'package:resqpet/services/auth_service.dart';

import 'package:cloud_functions/cloud_functions.dart';

class UtenteRepository {
  final AuthService _authService;
  final UtenteDao _utenteDao;

  UtenteRepository(this._authService, this._utenteDao);
// coverage:ignore-start
  Future<Utente?> getLoggedUtenteInfo() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return null;
    }
    return getUtenteInfoById(currentUser.uid);
  }

  Future<Utente?> getUtenteInfoById(String id) async {
    return _utenteDao.findById(id);
  }

  Future<Utente> aggiornaProfiloInfo(Utente utente) async {
    return _utenteDao.update(utente);
  }
  // coverage:ignore-end

  Future<Utente> registraCittadino({
    required String email,
    required String password,
    required String nominativo,
    required String numeroTelefono,
  }) async {
    return _registraUtente(
      email: email,
      password: password,
      nominativo: nominativo,
      numeroTelefono: numeroTelefono,
      tipo: TipoUtente.cittadino,
    );
  }
// coverage:ignore-start
  Future<Utente> registraSoccorritore({
    required String email,
    required String password,
    required String nominativo,
    required String numeroTelefono,
  }) async {
    return _registraUtente(
      email: email,
      password: password,
      nominativo: nominativo,
      numeroTelefono: numeroTelefono,
      tipo: TipoUtente.soccorritore,
    );
  }

  Future<Venditore> registraVenditore({
    required String email,
    required String password,
    required String nominativo,
    required String numeroTelefono,
    required String partitaIVA,
    required String indirizzo,
    required String abbonamentoRef,
  }) async {
    final userCredential = await _authService.signUp(email, password);
    final uid = userCredential.user!.uid;

    final venditore = Venditore(
      id: uid,
      nominativo: nominativo,
      email: email,
      numeroTelefono: numeroTelefono,
      dataCreazione: Timestamp.now(),
      partitaIVA: partitaIVA,
      indirizzo: indirizzo,
      dataSottoscrizioneAbbonamento: Timestamp.now(),
      abbonamentoRef: abbonamentoRef,
    );

    await _utenteDao.create(venditore);
    return venditore;
  }

  Future<Ente> registraEnte({
    required String email,
    required String password,
    required String nominativo,
    required String numeroTelefono,
    required String sedeLegale,
    required String partitaIVA,
  }) async {

    if (!emailRegex.hasMatch(email)) {
      throw ArgumentError.value(
        email,
        'email',
        'Email non valida',
      );
    }

    if (!min8PasswordRegex.hasMatch(password)) {
      throw ArgumentError.value(
        password,
        'password',
        'La password deve contenere almeno 8 caratteri',
      );
    }

    if (nominativo.trim().isEmpty) {
      throw ArgumentError.value(
        nominativo,
        'nominativo',
        'Il nominativo non può essere vuoto',
      );
    }

    if (!italianPhoneRegex.hasMatch(numeroTelefono)) {
      throw ArgumentError.value(
        numeroTelefono,
        'numeroTelefono',
        'Numero di telefono non valido',
      );
    }

    if (sedeLegale.trim().isEmpty) {
      throw ArgumentError.value(
        sedeLegale,
        'sedeLegale',
        'La sede legale non può essere vuota',
      );
    }

    if (!partitaIvaRegex.hasMatch(partitaIVA)) {
      throw ArgumentError.value(
        partitaIVA,
        'partitaIVA',
        'Partita IVA non valida',
      );
    }

    final userCredential = await _authService.signUp(email, password);
    final uid = userCredential.user!.uid;

    final ente = Ente(
      id: uid,
      nominativo: nominativo,
      email: email,
      numeroTelefono: numeroTelefono,
      dataCreazione: Timestamp.now(),
      sedeLegale: sedeLegale,
      partitaIVA: partitaIVA,
    );

    await _utenteDao.create(ente);
    return ente;
  }

  Future<void> cancellaAccount() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw StateError('Nessun utente autenticato');
    }

    await cancellaAccountById(currentUser.uid);
  }


  Future<void> cancellaAccountById(String id) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw StateError('Nessun utente autenticato');
    }

    await _utenteDao.deleteById(id);
    final callable = FirebaseFunctions.instance
        .httpsCallable("deleteUserAccountByUID");

    await callable.call({ 'uid': id });
  }
  // coverage:ignore-end

  Future<Utente> _registraUtente({
    required String email,
    required String password,
    required String nominativo,
    required String numeroTelefono,
    required TipoUtente tipo,
  }) async {

    if (!emailRegex.hasMatch(email)) {
      throw ArgumentError.value(
        email,
        'email',
        'Email non valida',
      );
    }

    if (!min8PasswordRegex.hasMatch(password)) {
      throw ArgumentError.value(
        'password',
        password,
        'La password deve contenere almeno 8 caratteri',
      );
    }

    if (nominativo.trim().isEmpty) {
      throw ArgumentError.value(
        nominativo,
        'nominativo',
        'Il nominativo non può essere vuoto',
      );
    }

    if (!italianPhoneRegex.hasMatch(numeroTelefono)) {
      throw ArgumentError.value(
        numeroTelefono,
        'numeroTelefono',
        'Numero di telefono non valido',
      );
    }

    final userCredential = await _authService.signUp(email, password);
    final uid = userCredential.user!.uid;

    final utente = Utente(
      id: uid,
      nominativo: nominativo,
      email: email,
      numeroTelefono: numeroTelefono,
      dataCreazione: Timestamp.now(),
      tipo: tipo,
    );

    return await _utenteDao.create(utente);
  }
  // coverage:ignore-start
  Stream<List<Utente>> getAllExceptAdmin() {
    return _utenteDao.findAllStream()
        .map(
            (utenti) =>
            utenti.where((utente) => utente.tipo != TipoUtente.admin)
                .toList()
    );
  }
// coverage:ignore-end
}
