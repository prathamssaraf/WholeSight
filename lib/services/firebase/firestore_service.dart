import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:whole_sight/core/utils/logger.dart';

abstract class FirestoreService {
  Future<Map<String, dynamic>?> getDocument({
    required String collection,
    required String documentId,
  });
  
  Future<List<Map<String, dynamic>>> getDocuments({
    required String collection,
    List<List<dynamic>>? whereConditions,
    String? orderBy,
    bool descending,
    int? limit,
  });
  
  Future<void> setDocument({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  });
  
  Future<void> updateDocument({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  });
  
  Future<void> deleteDocument({
    required String collection,
    required String documentId,
  });
  
  Future<String> addDocument({
    required String collection,
    required Map<String, dynamic> data,
  });
  
  Future<List<Map<String, dynamic>>> queryCollection({
    required String collection,
    required Query Function(CollectionReference) queryBuilder,
  });
}

class FirestoreServiceImpl implements FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  FirestoreServiceImpl() {
    // Set Firestore settings for offline persistence
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }
  
  @override
  Future<Map<String, dynamic>?> getDocument({
    required String collection,
    required String documentId,
  }) async {
    try {
      final docSnapshot = await _firestore
          .collection(collection)
          .doc(documentId)
          .get();
      
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        data['id'] = docSnapshot.id; // Add the document ID to the data
        return data;
      } else {
        return null;
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get document: $collection/$documentId', e, stackTrace);
      throw Exception('Failed to get document: $e');
    }
  }
  
  @override
  Future<List<Map<String, dynamic>>> getDocuments({
    required String collection,
    List<List<dynamic>>? whereConditions,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collection);
      
      // Apply where conditions if provided
      if (whereConditions != null) {
        for (final condition in whereConditions) {
          if (condition.length == 3) {
            query = query.where(
              condition[0] as String,
              isEqualTo: condition[1] == '==' ? condition[2] : null,
              isNotEqualTo: condition[1] == '!=' ? condition[2] : null,
              isLessThan: condition[1] == '<' ? condition[2] : null,
              isLessThanOrEqualTo: condition[1] == '<=' ? condition[2] : null,
              isGreaterThan: condition[1] == '>' ? condition[2] : null,
              isGreaterThanOrEqualTo: condition[1] == '>=' ? condition[2] : null,
              arrayContains: condition[1] == 'array-contains' ? condition[2] : null,
              arrayContainsAny: condition[1] == 'array-contains-any'
                  ? condition[2] as List<dynamic>
                  : null,
              whereIn: condition[1] == 'in' ? condition[2] as List<dynamic> : null,
              whereNotIn: condition[1] == 'not-in'
                  ? condition[2] as List<dynamic>
                  : null,
            );
          }
        }
      }
      
      // Apply orderBy if provided
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }
      
      // Apply limit if provided
      if (limit != null) {
        query = query.limit(limit);
      }
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Add the document ID to the data
        return data;
      }).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get documents from $collection', e, stackTrace);
      throw Exception('Failed to get documents: $e');
    }
  }
  
  @override
  Future<void> setDocument({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore
          .collection(collection)
          .doc(documentId)
          .set(data, SetOptions(merge: true));
    } catch (e, stackTrace) {
      AppLogger.error('Failed to set document: $collection/$documentId', e, stackTrace);
      throw Exception('Failed to set document: $e');
    }
  }
  
  @override
  Future<void> updateDocument({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore
          .collection(collection)
          .doc(documentId)
          .update(data);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update document: $collection/$documentId', e, stackTrace);
      throw Exception('Failed to update document: $e');
    }
  }
  
  @override
  Future<void> deleteDocument({
    required String collection,
    required String documentId,
  }) async {
    try {
      await _firestore
          .collection(collection)
          .doc(documentId)
          .delete();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete document: $collection/$documentId', e, stackTrace);
      throw Exception('Failed to delete document: $e');
    }
  }
  
  @override
  Future<String> addDocument({
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    try {
      final docRef = await _firestore
          .collection(collection)
          .add(data);
      
      return docRef.id;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to add document to $collection', e, stackTrace);
      throw Exception('Failed to add document: $e');
    }
  }
  
  @override
  Future<List<Map<String, dynamic>>> queryCollection({
    required String collection,
    required Query Function(CollectionReference) queryBuilder,
  }) async {
    try {
      final query = queryBuilder(_firestore.collection(collection));
      final querySnapshot = await query.get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Add the document ID to the data
        return data;
      }).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to query collection $collection', e, stackTrace);
      throw Exception('Failed to query collection: $e');
    }
  }
}