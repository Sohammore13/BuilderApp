import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants.dart';
import '../models/user_model.dart';
import '../models/site_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ===========================================================================
  // USERS
  // ===========================================================================

  Future<void> createUser({
    required String uid,
    required String name,
    required String email,
    required String role,
  }) async {
    await _db.collection(kUsersCollection).doc(uid).set({
      'name': name,
      'email': email,
      'role': role,
    });
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection(kUsersCollection).doc(uid).get();
    if (doc.exists) {
      return UserModel.fromDocument(doc);
    }
    return null;
  }

  Stream<UserModel?> streamUser(String uid) {
    return _db.collection(kUsersCollection).doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromDocument(doc);
      }
      return null;
    });
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db.collection(kUsersCollection).doc(uid).update(data);
  }

  /// Fetch all users with a given role
  Future<List<UserModel>> getUsersByRole(String role) async {
    final snap = await _db
        .collection(kUsersCollection)
        .where('role', isEqualTo: role)
        .get();
    return snap.docs.map((d) => UserModel.fromDocument(d)).toList();
  }

  // ===========================================================================
  // SITES
  // ===========================================================================

  /// Create a new site and return its document ID
  Future<String> createSite({
    required String siteName,
    required String location,
    required DateTime startDate,
    required String createdBy,
    required List<String> assignedEngineers,
    required List<String> assignedPurchaseTeam,

    // ✅ NEW (optional so old code doesn't break)
    double? latitude,
    double? longitude,
  }) async {
    final docRef = await _db.collection('sites').add({
      'siteName': siteName,
      'location': location,
      'startDate': Timestamp.fromDate(startDate),
      'createdBy': createdBy,
      'assignedEngineers': assignedEngineers,
      'assignedPurchaseTeam': assignedPurchaseTeam,
      'createdAt': FieldValue.serverTimestamp(),

      // ✅ NEW FIELDS (safe — will be null if not passed)
      'latitude': latitude,
      'longitude': longitude,
      'radius': 250,
    });
    return docRef.id;
  }

  Stream<List<SiteModel>> streamSitesForOwner(String ownerUid) {
    return _db.collection('sites').snapshots().map((snap) {
      final list = snap.docs.map((d) => SiteModel.fromDocument(d)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Stream sites created by a specific manager
  Stream<List<SiteModel>> streamSitesForManager(String managerUid) {
    return _db
        .collection('sites')
        .where('createdBy', isEqualTo: managerUid)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => SiteModel.fromDocument(d)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Stream sites assigned to a specific engineer
  Stream<List<SiteModel>> streamSitesForEngineer(String uid) {
    return _db
        .collection('sites')
        .where('assignedEngineers', arrayContains: uid)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => SiteModel.fromDocument(d)).toList(),
        );
  }

  /// Stream sites assigned to a specific purchase team member
  Stream<List<SiteModel>> streamSitesForPurchase(String uid) {
    return _db
        .collection('sites')
        .where('assignedPurchaseTeam', arrayContains: uid)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => SiteModel.fromDocument(d)).toList(),
        );
  }

  /// Get a single site by ID
  Future<SiteModel?> getSite(String siteId) async {
    final doc = await _db.collection('sites').doc(siteId).get();
    if (doc.exists) return SiteModel.fromDocument(doc);
    return null;
  }

  /// Stream a single site document in real time (for Edit Members)
  Stream<SiteModel?> streamSite(String siteId) {
    return _db.collection('sites').doc(siteId).snapshots().map((doc) {
      if (doc.exists) return SiteModel.fromDocument(doc);
      return null;
    });
  }

  // ===========================================================================
  // MEMBER MANAGEMENT — arrayUnion / arrayRemove (never overwrites full array)
  // ===========================================================================

  /// Add engineer UIDs to a site (arrayUnion — duplicates are ignored)
  Future<void> addMembersToSite({
    required String siteId,
    List<String> engineerUids = const [],
    List<String> purchaseUids = const [],
  }) async {
    final updates = <String, dynamic>{};
    if (engineerUids.isNotEmpty) {
      updates['assignedEngineers'] = FieldValue.arrayUnion(engineerUids);
    }
    if (purchaseUids.isNotEmpty) {
      updates['assignedPurchaseTeam'] = FieldValue.arrayUnion(purchaseUids);
    }
    if (updates.isNotEmpty) {
      await _db.collection('sites').doc(siteId).update(updates);
    }
  }

  /// Remove a single member UID from a site (arrayRemove)
  Future<void> removeMemberFromSite({
    required String siteId,
    required String uid,
    required String field, // 'assignedEngineers' or 'assignedPurchaseTeam'
  }) async {
    await _db.collection('sites').doc(siteId).update({
      field: FieldValue.arrayRemove([uid]),
    });
  }

  Future<void> deleteSite(String siteId) async {
    await _db.collection('sites').doc(siteId).delete();
  }

  // ===========================================================================
  // ATTENDANCE — attendance/{siteId}/records/{date}/{engineerUID}
  // ===========================================================================

  /// Mark attendance for an engineer on a given date
  Future<void> markAttendance({
    required String siteId,
    required String date,
    required String engineerUid,
  }) async {
    // We only write to the specific engineer document to avoid permission errors 
    // on the parent collection/document. Redundant fields enable collection group queries.
    await _db
        .collection('attendance')
        .doc(siteId)
        .collection('records')
        .doc(date)
        .collection('engineers')
        .doc(engineerUid)
        .set({
          'status': 'present', 
          'markedAt': FieldValue.serverTimestamp(),
          'siteId': siteId,
          'date': date,
          'uid': engineerUid,
        });
  }

  /// Check if engineer already marked attendance for a date
  Future<bool> hasMarkedAttendance({
    required String siteId,
    required String date,
    required String engineerUid,
  }) async {
    final doc = await _db
        .collection('attendance')
        .doc(siteId)
        .collection('records')
        .doc(date)
        .collection('engineers')
        .doc(engineerUid)
        .get();
    return doc.exists;
  }

  /// Stream attendance records for an engineer at a site (all dates).
  /// Uses collectionGroup to avoid needing permissions to list the parent 'records' collection.
  Future<List<Map<String, dynamic>>> getAttendanceForEngineer({
    required String siteId,
    required String engineerUid,
  }) async {
    final snap = await _db
        .collectionGroup('engineers')
        .where('siteId', isEqualTo: siteId)
        .where('uid', isEqualTo: engineerUid)
        .get();

    final results = snap.docs.map((d) {
      final data = d.data();
      return {
        'date': data['date'] ?? d.reference.parent.parent?.id ?? '',
        'status': data['status'] ?? 'present',
      };
    }).toList();

    results.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
    return results;
  }

  /// Get all attendance records for a site (owner view) — returns map of date → list of UIDs
  Future<Map<String, List<String>>> getAttendanceForSite(String siteId) async {
    final snap = await _db
        .collectionGroup('engineers')
        .where('siteId', isEqualTo: siteId)
        .get();

    final Map<String, List<String>> result = {};
    for (final doc in snap.docs) {
      final data = doc.data();
      final date = data['date'] as String?;
      if (date != null) {
        result.putIfAbsent(date, () => []).add(doc.id);
      }
    }
    return result;
  }

  /// REAL-TIME: Stream all engineer attendance for a site
  /// Uses collectionGroup to find records regardless of parent document existence.
  Stream<Map<String, List<String>>> streamAttendanceForSite(String siteId) {
    return _db
        .collectionGroup('engineers')
        .where('siteId', isEqualTo: siteId)
        .snapshots()
        .map((snap) {
      final Map<String, List<String>> result = {};
      for (final doc in snap.docs) {
        final data = doc.data();
        final date = data['date'] as String?;
        if (date != null) {
          result.putIfAbsent(date, () => []).add(doc.id);
        }
      }
      return result;
    });
  }

  // ---------------------------------------------------------------------------
  // PURCHASE TEAM ATTENDANCE — attendance/{siteId}/records/{date}/purchase/{uid}
  // ---------------------------------------------------------------------------

  /// Mark attendance for a purchase team member on a given date
  Future<void> markPurchaseAttendance({
    required String siteId,
    required String date,
    required String memberUid,
  }) async {
    await _db
        .collection('attendance')
        .doc(siteId)
        .collection('records')
        .doc(date)
        .collection('purchase')
        .doc(memberUid)
        .set({
          'status': 'present',
          'markedAt': FieldValue.serverTimestamp(),
          'role': 'purchase_team',
          'siteId': siteId,
          'date': date,
          'uid': memberUid,
        });
  }

  /// Check if a purchase team member already marked attendance for a date
  Future<bool> hasMarkedPurchaseAttendance({
    required String siteId,
    required String date,
    required String memberUid,
  }) async {
    final doc = await _db
        .collection('attendance')
        .doc(siteId)
        .collection('records')
        .doc(date)
        .collection('purchase')
        .doc(memberUid)
        .get();
    return doc.exists;
  }

  /// Get attendance history for a single purchase team member at a site
  Future<List<Map<String, dynamic>>> getAttendanceForPurchaseMember({
    required String siteId,
    required String memberUid,
  }) async {
    final snap = await _db
        .collectionGroup('purchase')
        .where('siteId', isEqualTo: siteId)
        .where('uid', isEqualTo: memberUid)
        .get();

    final results = snap.docs.map((doc) {
      final data = doc.data();
      return {
        'date': data['date'] ?? doc.reference.parent.parent?.id ?? '',
        'status': data['status'] ?? 'present',
      };
    }).toList();

    results.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
    return results;
  }

  /// Get all purchase team attendance for a site (owner view) — date → list of UIDs
  Future<Map<String, List<String>>> getPurchaseAttendanceForSite(
    String siteId,
  ) async {
    final snap = await _db
        .collectionGroup('purchase')
        .where('siteId', isEqualTo: siteId)
        .get();

    final Map<String, List<String>> result = {};
    for (final doc in snap.docs) {
      final data = doc.data();
      final date = data['date'] as String?;
      if (date != null) {
        result.putIfAbsent(date, () => []).add(doc.id);
      }
    }
    return result;
  }

  /// REAL-TIME: Stream all purchase attendance for a site
  Stream<Map<String, List<String>>> streamPurchaseAttendanceForSite(String siteId) {
    return _db
        .collectionGroup('purchase')
        .where('siteId', isEqualTo: siteId)
        .snapshots()
        .map((snap) {
      final Map<String, List<String>> result = {};
      for (final doc in snap.docs) {
        final data = doc.data();
        final date = data['date'] as String?;
        if (date != null) {
          result.putIfAbsent(date, () => []).add(doc.id);
        }
      }
      return result;
    });
  }

  Future<void> postAnnouncement({
    required String siteId,
    required String message,
    required String postedBy,
  }) async {
    await _db.collection('announcements').doc(siteId).collection('posts').add({
      'message': message,
      'postedBy': postedBy,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteAnnouncement({
    required String siteId,
    required String announcementId,
  }) async {
    await _db
        .collection('announcements')
        .doc(siteId)
        .collection('posts')
        .doc(announcementId)
        .delete();
  }

  Stream<QuerySnapshot> streamAnnouncements(String siteId) {
    return _db
        .collection('announcements')
        .doc(siteId)
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ===========================================================================
  // PURCHASE ORDERS — purchaseOrders/{siteId}/orders/{orderId}
  // ===========================================================================

  Future<void> submitPurchaseOrder({
    required String siteId,
    required String itemName,
    required int quantity,
    required double estimatedCost,
    String? notes,
    required String submittedBy,
  }) async {
    await _db
        .collection('purchaseOrders')
        .doc(siteId)
        .collection('orders')
        .add({
          'itemName': itemName,
          'quantity': quantity,
          'estimatedCost': estimatedCost,
          'notes': notes ?? '',
          'submittedBy': submittedBy,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'reviewedAt': null,
        });
  }

  /// Stream all purchase orders for a site (owner view)
  Stream<QuerySnapshot> streamPurchaseOrders(String siteId) {
    return _db
        .collection('purchaseOrders')
        .doc(siteId)
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Stream ALL pending purchase orders across ALL sites (for Owner Approvals)
  Stream<QuerySnapshot> streamAllPendingPurchaseOrders() {
    return _db
        .collectionGroup('orders')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Stream purchase orders submitted by a specific user
  Stream<QuerySnapshot> streamMyPurchaseOrders({
    required String siteId,
    required String uid,
  }) {
    return _db
        .collection('purchaseOrders')
        .doc(siteId)
        .collection('orders')
        .where('submittedBy', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Approve or reject a purchase order
  Future<void> updateOrderStatus({
    required String siteId,
    required String orderId,
    required String status,
  }) async {
    await _db
        .collection('purchaseOrders')
        .doc(siteId)
        .collection('orders')
        .doc(orderId)
        .update({'status': status, 'reviewedAt': FieldValue.serverTimestamp()});
  }

  // ===========================================================================
  // MATERIAL REQUESTS
  // ===========================================================================

  Stream<QuerySnapshot> streamMaterialRequests(String siteId) {
    return _db
        .collection('materialRequests')
        .doc(siteId)
        .collection('requests')
        .snapshots();
  }

  Stream<QuerySnapshot> streamAllMaterialRequests() {
    return _db.collectionGroup('requests').snapshots();
  }

  Stream<QuerySnapshot> streamAllMaterialRequestsByStatus(String status) {
    return _db
        .collectionGroup('requests')
        .where('status', isEqualTo: status)
        .snapshots();
  }

  Stream<QuerySnapshot> streamMyMaterialRequests({
    required String siteId,
    required String uid,
  }) {
    return _db
        .collection('materialRequests')
        .doc(siteId)
        .collection('requests')
        .where('uploadedBy', isEqualTo: uid)
        .snapshots();
  }

  // Update material request status (owner approve/reject)
  Future<void> updateMaterialRequestStatus({
    required String siteId,
    required String requestId,
    required String status,
    required String reviewedBy,
    String? rejectionReason,
  }) async {
    final data = {
      'status': status,
      'reviewedBy': reviewedBy,
      'reviewedAt': FieldValue.serverTimestamp(),
    };
    if (rejectionReason != null) data['rejectionReason'] = rejectionReason;
    await _db
        .collection('materialRequests')
        .doc(siteId)
        .collection('requests')
        .doc(requestId)
        .update(data);
  }

  // Add PDF to existing material request (purchase team)
  Future<void> uploadPurchaseOrderPdf({
    required String siteId,
    required String requestId,
    required String pdfUrl,
    required String uploadedBy,
    String? quotationNote,
  }) async {
    await _db
        .collection('materialRequests')
        .doc(siteId)
        .collection('requests')
        .doc(requestId)
        .update({
          'purchaseOrderPdfURL': pdfUrl,
          'pdfUploadedBy': uploadedBy,
          'pdfUploadedAt': FieldValue.serverTimestamp(),
          'quotationNote': quotationNote ?? '',
          'status': 'pending_approval',
        });
  }
}
