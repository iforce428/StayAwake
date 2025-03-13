import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final CollectionReference user =
      FirebaseFirestore.instance.collection('users');

  Future<void> addUser(String username, String password, String email) {
    return user
        .add({'username': username, 'password': password, 'email': email});
  }
}
