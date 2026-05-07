import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/goal.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String userId;

  // We require the userId when opening the vault so we always save 
  // the data to the correct person's account!
  DatabaseService({required this.userId});

  /// 1. THE PACKAGER (Serialization)
  /// Translates our custom Dart Goal into a Firestore-friendly Map
  Map<String, dynamic> _goalToMap(Goal goal) {
    // These are the universal properties every goal shares
    Map<String, dynamic> data = {
      'id': goal.id,
      'title': goal.title,
      'createdAt': Timestamp.fromDate(goal.createdAt), 
      'privacy': goal.privacy.name,
      'type': goal.runtimeType.toString(),
      'supporterIds': goal.supporterIds,
      'supporterStatuses': goal.supporterStatuses,
    };

    // Now we add the specific properties based on what kind of goal it is
    if (goal is DailyGoal) {
      data['endDate'] = goal.endDate != null ? Timestamp.fromDate(goal.endDate!) : null;
      data['completedDates'] = goal.completedDates.map((d) => Timestamp.fromDate(d)).toList();
      
    } else if (goal is ObjectiveGoal) {
      data['targetCompletionDate'] = goal.targetCompletionDate != null ? Timestamp.fromDate(goal.targetCompletionDate!) : null;
      data['requireSequentialCheckpoints'] = goal.requireSequentialCheckpoints;
      data['isGoalCompleted'] = goal.isGoalCompleted;
      
      // Checkpoints are a list of objects, so we have to package them up too!
      data['checkpoints'] = goal.checkpoints.map((cp) => {
        'title': cp.title,
        'isCompleted': cp.isCompleted,
        'targetDate': cp.targetDate != null ? Timestamp.fromDate(cp.targetDate!) : null,
        'completionDate': cp.completionDate != null ? Timestamp.fromDate(cp.completionDate!) : null,
      }).toList();
    }
    
    // (We will add Avoidance, Irregular, and Cumulative here later!)
    
    return data;
  }

  /// 2. THE SHIPPER
  /// Sends the packaged map to the Cloud
  Future<void> saveGoal(Goal goal) async {
    try {
      // This builds the exact folder path in the cloud:
      // users -> [Your UID] -> goals -> [The Goal ID]
      await _db
          .collection('users')
          .doc(userId)
          .collection('goals')
          .doc(goal.id)
          .set(_goalToMap(goal));
          
    } catch (e) {
      print("Error saving goal: $e");
    }
  }

  /// 3. THE UN-PACKAGER (Deserialization)
  /// Translates Firestore Maps back into Dart Goal objects
  Goal _goalFromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Extract the universal properties
    String id = data['id'];
    String title = data['title'];
    DateTime createdAt = (data['createdAt'] as Timestamp).toDate();
    List<String> supporterIds = List<String>.from(data['supporterIds'] ?? []);
    Map<String, String> supporterStatuses = Map<String, String>.from(data['supporterStatuses'] ?? {});
    
    // Safely parse the privacy level enum
    PrivacyLevel privacy = PrivacyLevel.values.firstWhere(
      (e) => e.name == data['privacy'], 
      orElse: () => PrivacyLevel.public
    );
    
    String type = data['type'];

    // Rebuild the specific goal type
    if (type == 'DailyGoal') {
      DateTime? endDate = data['endDate'] != null ? (data['endDate'] as Timestamp).toDate() : null;
      
      Set<DateTime> completedDates = {};
      if (data['completedDates'] != null) {
        completedDates = (data['completedDates'] as List).map((t) => (t as Timestamp).toDate()).toSet();
      }
      
      return DailyGoal(id: id, title: title, createdAt: createdAt, privacy: privacy, endDate: endDate, completedDates: completedDates, supporterIds: supporterIds, supporterStatuses: supporterStatuses);
      
    } else if (type == 'ObjectiveGoal') {
      DateTime? targetCompletionDate = data['targetCompletionDate'] != null ? (data['targetCompletionDate'] as Timestamp).toDate() : null;
      
      List<Checkpoint> checkpoints = [];
      if (data['checkpoints'] != null) {
        checkpoints = (data['checkpoints'] as List).map((cp) {
          return Checkpoint(
            title: cp['title'],
            isCompleted: cp['isCompleted'] ?? false,
            targetDate: cp['targetDate'] != null ? (cp['targetDate'] as Timestamp).toDate() : null,
            completionDate: cp['completionDate'] != null ? (cp['completionDate'] as Timestamp).toDate() : null,
          );
        }).toList();
      }

      return ObjectiveGoal(
        id: id, 
        title: title, 
        createdAt: createdAt, 
        privacy: privacy, 
        targetCompletionDate: targetCompletionDate, 
        requireSequentialCheckpoints: data['requireSequentialCheckpoints'] ?? false, 
        isGoalCompleted: data['isGoalCompleted'] ?? false, 
        checkpoints: checkpoints,
        supporterIds: supporterIds,
        supporterStatuses: supporterStatuses,
      );
    }
    
    // (We will add Avoidance, Irregular, etc. later. Defaulting to Daily for safety)
    return DailyGoal(id: id, title: title, createdAt: createdAt, supporterIds: supporterIds, supporterStatuses: supporterStatuses);
  }

  /// 4. THE LIVE STREAM
  /// Constantly listens to the user's 'goals' folder
  Stream<List<Goal>> get goals {
    return _db
        .collection('users')
        .doc(userId)
        .collection('goals')
        .snapshots() // This is the magic pipeline!
        .map((snapshot) {
          // Whenever data flows through the pipe, unpack every document into a Goal list
          return snapshot.docs.map((doc) => _goalFromFirestore(doc)).toList();
        });
  }

  // PARTNER FINDING AND REQUESTS
  // --- 1. THE SEARCH ENGINE ---
  // Smartly guesses if the query is an email, code, or username
  Future<Map<String, dynamic>?> searchUser(String query) async {
    query = query.trim();
    QuerySnapshot result;

    try {
      if (query.contains('@')) {
        // It's an email
        result = await _db.collection('users').where('email', isEqualTo: query.toLowerCase()).get();
      } else if (query.length == 6 && query == query.toUpperCase()) {
        // It's a partner code
        result = await _db.collection('users').where('partnerCode', isEqualTo: query).get();
      } else {
        // It's a username
        result = await _db.collection('users').where('username', isEqualTo: query.toLowerCase()).get();
      }

      if (result.docs.isNotEmpty) {
        // Prevent users from adding themselves
        if (result.docs.first.id == userId) return null; 
        return result.docs.first.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print("Search error: $e");
      return null;
    }
  }

  // --- 2. THE POSTMAN (Sending the Request) ---
  Future<void> sendPartnerRequest(String targetUserId, Map<String, dynamic> targetUserData) async {
    // 1. Prevent Duplicates! If you already requested them, silently cancel.
    final existing = await _db.collection('users').doc(userId).collection('partners').doc('supporter_$targetUserId').get();
    if (existing.exists) return; 

    final myDoc = await _db.collection('users').doc(userId).get();
    final myData = myDoc.data()!;

    // 2. Put a receipt in YOUR outbox (They are YOUR supporter)
    await _db.collection('users').doc(userId).collection('partners').doc('supporter_$targetUserId').set({
      'uid': targetUserId,
      'displayName': targetUserData['displayName'],
      'email': targetUserData['email'],
      'status': 'pending_sent', 
    });

    // 3. Put the request in THEIR inbox (You are THEIR supportee)
    await _db.collection('users').doc(targetUserId).collection('partners').doc('supportee_$userId').set({
      'uid': userId,
      'displayName': myData['displayName'],
      'email': myData['email'],
      'status': 'pending_received',
    });
  }

  Future<void> acceptPartnerRequest(String senderId) async {
    // You are accepting to support them.
    // 1. Update THEIR outbox
    await _db.collection('users').doc(senderId).collection('partners').doc('supporter_$userId').update({
      'status': 'accepted',
    });
    // 2. Update YOUR inbox
    await _db.collection('users').doc(userId).collection('partners').doc('supportee_$senderId').update({
      'status': 'supporting',
    });
  }

  Future<void> deletePartnerConnection(String targetUserId, {required bool isMySupporter}) async {
    if (isMySupporter) {
      // I am removing them as my supporter (or canceling my request)
      await _db.collection('users').doc(userId).collection('partners').doc('supporter_$targetUserId').delete();
      await _db.collection('users').doc(targetUserId).collection('partners').doc('supportee_$userId').delete();
    } else {
      // I am declining their incoming request for me to support them
      await _db.collection('users').doc(userId).collection('partners').doc('supportee_$targetUserId').delete();
      await _db.collection('users').doc(targetUserId).collection('partners').doc('supporter_$userId').delete();
    }
  }

  // --- 3. THE PARTNER STREAM ---
  Stream<QuerySnapshot> get partners {
    return _db.collection('users').doc(userId).collection('partners').snapshots();
  }

  // This searches EVERY user's goals folder for goals where YOU are a supporter
  Stream<List<Goal>> get supportedGoals {
    return _db
        .collectionGroup('goals') 
        .where('supporterIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          // Pass the exact 'doc' object to your unpackager! No red lines!
          return snapshot.docs.map((doc) => _goalFromFirestore(doc)).toList();
        });
  }
}