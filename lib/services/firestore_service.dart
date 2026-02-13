import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task.dart';
import '../utils/app_logger.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get the tasks collection for the current user
  CollectionReference<Map<String, dynamic>> get _tasksCollection {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return _firestore.collection('users').doc(user.uid).collection('tasks');
  }

  /// Stream of tasks for the current user
  Stream<List<Task>> getTasksStream() {
    try {
      return _tasksCollection.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          // Convert Firestore Timestamps to ISO 8601 Strings for Task.fromMap
          final convertedData = _convertTimestamps(data);
          return Task.fromMap(convertedData);
        }).toList();
      });
    } catch (e) {
      AppLogger.error('Error getting tasks stream', e);
      return Stream.value([]);
    }
  }

  /// Add a task
  Future<void> addTask(Task task) async {
    try {
      await _tasksCollection.doc(task.id).set(task.toMap());
      AppLogger.info('Task added to Firestore: ${task.id}');
    } catch (e) {
      AppLogger.error('Error adding task to Firestore', e);
      rethrow;
    }
  }

  /// Update a task
  Future<void> updateTask(Task task) async {
    try {
      await _tasksCollection.doc(task.id).update(task.toMap());
      AppLogger.info('Task updated in Firestore: ${task.id}');
    } catch (e) {
      AppLogger.error('Error updating task in Firestore', e);
      rethrow;
    }
  }

  /// Delete a task
  Future<void> deleteTask(String taskId) async {
    try {
      await _tasksCollection.doc(taskId).delete();
      AppLogger.info('Task deleted from Firestore: $taskId');
    } catch (e) {
      AppLogger.error('Error deleting task from Firestore', e);
      rethrow;
    }
  }

  /// Delete multiple tasks in a batch
  Future<void> batchDelete(List<String> taskIds) async {
    try {
      final batch = _firestore.batch();
      for (final id in taskIds) {
        final ref = _tasksCollection.doc(id);
        batch.delete(ref);
      }
      await batch.commit();
      AppLogger.info('Batch deleted ${taskIds.length} tasks');
    } catch (e) {
      AppLogger.error('Error batch deleting tasks', e);
      rethrow;
    }
  }

  /// Helper to convert Firestore Timestamps to ISO Strings recursively
  Map<String, dynamic> _convertTimestamps(Map<String, dynamic> data) {
    final Map<String, dynamic> result = {};
    data.forEach((key, value) {
      if (value is Timestamp) {
        result[key] = value.toDate().toIso8601String();
      } else if (value is Map<String, dynamic>) {
        result[key] = _convertTimestamps(value);
      } else if (value is List) {
        result[key] = value.map((item) {
          if (item is Timestamp) {
            return item.toDate().toIso8601String();
          } else if (item is Map<String, dynamic>) {
            return _convertTimestamps(item);
          }
          return item;
        }).toList();
      } else {
        result[key] = value;
      }
    });
    return result;
  }
}
