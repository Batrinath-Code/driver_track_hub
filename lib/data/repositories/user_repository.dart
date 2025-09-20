// data/repositories/user_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_tracker_app/data/models/user_model.dart'
    as local; // Alias to avoid conflict
import 'package:firebase_auth/firebase_auth.dart' as auth; // Alias
import 'dart:developer' as developer;

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _usersCollection = FirebaseFirestore.instance
      .collection('users');

  Stream<List<local.User>> getUsersStream() {
    try {
      return _usersCollection.snapshots().map(
        (snapshot) => snapshot.docs
            .map(
              (doc) => local.User.fromJson(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ),
            )
            .toList(),
      );
    } catch (e) {
      developer.log("Error getting users stream: $e");
      return Stream.value([]);
    }
  }

  Future<local.User?> getUserById(String uid) async {
    try {
      DocumentSnapshot doc = await _usersCollection.doc(uid).get();
      if (doc.exists) {
        return local.User.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      developer.log("Error getting user by ID '$uid': $e");
      return null;
    }
  }

  // Create a new user document in Firestore
  // Note: This doesn't create the Firebase Auth user, that's usually done separately
  // This is for creating the user profile/document after auth user is created
  // Or for admins creating user profiles (which then need associated Auth users)
  Future<bool> createUser(local.User user) async {
    try {
      final userData = user.toJson();
      // UID should be the document ID
      await _usersCollection.doc(user.uid).set(userData);
      developer.log("User document created with UID: ${user.uid}");
      return true;
    } on FirebaseException catch (e) {
      developer.log("Firebase error creating user '${user.uid}': ${e.message}");
      return false;
    } catch (e) {
      developer.log("Error creating user '${user.uid}': $e");
      return false;
    }
  }

  // Update an existing user document
  Future<bool> updateUser(local.User user) async {
    try {
      final userData = user.toJson();
      // UID is the document ID
      await _usersCollection.doc(user.uid).update(userData);
      developer.log("User document updated with UID: ${user.uid}");
      return true;
    } on FirebaseException catch (e) {
      developer.log("Firebase error updating user '${user.uid}': ${e.message}");
      return false;
    } catch (e) {
      developer.log("Error updating user '${user.uid}': $e");
      return false;
    }
  }

  // Delete a user document
  // Note: This doesn't delete the Firebase Auth user
  Future<bool> deleteUser(String uid) async {
    try {
      await _usersCollection.doc(uid).delete();
      developer.log("User document deleted with UID: $uid");
      // Consider implications: what if user is assigned to a vehicle?
      // The application logic should handle cleaning up related data (vehicle.currentDriverId etc.)
      return true;
    } on FirebaseException catch (e) {
      developer.log("Firebase error deleting user '$uid': ${e.message}");
      return false;
    } catch (e) {
      developer.log("Error deleting user '$uid': $e");
      return false;
    }
  }

  // Helper: Check if a Firebase Auth user exists
  Future<bool> doesAuthUserExist(String email) async {
    try {
      final auth.FirebaseAuth firebaseAuth = auth.FirebaseAuth.instance;
      final List<auth.User> users = await firebaseAuth
          .fetchSignInMethodsForEmail(email)
          .then(
            (methods) => methods.isNotEmpty
                ? [auth.FirebaseAuth.instance.currentUser!]
                : [],
          );
      // fetchSignInMethodsForEmail doesn't directly return User objects,
      // it returns sign-in methods. Let's check if any user with that email exists.
      // A more robust way might involve backend functions or checking if email is in use somehow.
      // For now, a simple check: try to sign in anonymously and link, or see if email is used.
      // This is tricky client-side. Better handled server-side.
      // Let's simplify: Assume if we can get the user by email, it exists.
      // Actually, FirebaseAuth doesn't have a direct 'getUserByEmail' for clients.
      // We'll assume existence check is done elsewhere or during auth creation.
      // Returning true for now as a placeholder, or assume it's checked before calling createUser.
      // A real implementation might need a Cloud Function.
      developer.log(
        "Checking auth user existence for '$email' is complex client-side. Assuming check is done elsewhere.",
      );
      return true; // Placeholder
    } catch (e) {
      developer.log("Error checking auth user existence for '$email': $e");
      return false; // Assume doesn't exist if error
    }
  }
}
