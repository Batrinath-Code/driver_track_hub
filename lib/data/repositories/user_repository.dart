// data/repositories/user_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_tracker_app/data/models/user_model.dart'
    as local; // Alias to avoid conflict
import 'package:firebase_auth/firebase_auth.dart' as auth; // Alias
import 'dart:developer' as developer;

class UserRepository {
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
  Future<bool> deleteUserCascade(String uid) async {
    final fire = FirebaseFirestore.instance;
    return fire.runTransaction((tx) async {
      final userDoc = await tx.get(fire.collection('users').doc(uid));
      if (!userDoc.exists) return false;

      final avId = userDoc.data()?['assignedVehicleId'] as String?;
      if (avId != null && avId.isNotEmpty) {
        // remove driver from vehicle
        tx.update(fire.collection('vehicles').doc(avId), {
          'currentDriverId': FieldValue.delete(),
          'status': 'idle',
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
      tx.delete(fire.collection('users').doc(uid));
      return true;
    });
  }

  Future<bool> doesAuthUserExist(String email) async {
    try {
      final methods = await auth.FirebaseAuth.instance
          .fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty; // true = email already registered
    } catch (e) {
      // If email is malformed or other error, treat as non-existent
      developer.log("Error checking auth user existence for '$email': $e");
      return false;
    }
  }
}
