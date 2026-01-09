import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Complete notification service for your telemedicine app
/// Handles both FCM (instant) and local scheduled notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _initialized = false;

  /// Initialize notification service (call in main.dart)
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone for local notifications
    tz.initializeTimeZones();

    // Request permissions
    await _requestPermissions();

    // Initialize FCM
    await _initializeFCM();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Listen to Firestore for notification triggers
    _listenToNotificationTriggers();

    _initialized = true;
    print('✅ Notification service initialized');
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('📱 Notification permission: ${settings.authorizationStatus}');
  }

  /// Initialize FCM and save token to Firestore
  Future<void> _initializeFCM() async {
    // Get FCM token
    final token = await _fcm.getToken();
    if (token != null) {
      await _saveFCMToken(token);
    }

    // Listen for token refresh
    _fcm.onTokenRefresh.listen(_saveFCMToken);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages (requires top-level function)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle notification tap when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleLocalNotificationTap,
    );
  }

  /// Save FCM token to Firestore
  Future<void> _saveFCMToken(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'fcmToken': token,
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    });

    print('✅ FCM token saved: ${token.substring(0, 20)}...');
  }

  /// Listen to Firestore notifications collection for triggers
  void _listenToNotificationTriggers() {
    final user = _auth.currentUser;
    if (user == null) return;

    _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('read', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docChanges) {
        if (doc.type == DocumentChangeType.added) {
          final data = doc.doc.data()!;
          _showLocalNotification(
            title: data['title'],
            body: data['body'],
            payload: jsonEncode(data),
          );
        }
      }
    });
  }

  /// Handle FCM message when app is in foreground
  void _handleForegroundMessage(RemoteMessage message) {
    print('📨 Foreground message: ${message.notification?.title}');

    if (message.notification != null) {
      _showLocalNotification(
        title: message.notification!.title ?? 'Notification',
        body: message.notification!.body ?? '',
        payload: jsonEncode(message.data),
      );
    }
  }

  /// Handle notification tap (FCM)
  void _handleNotificationTap(RemoteMessage message) {
    print('👆 Notification tapped: ${message.data}');
    // TODO: Navigate to appropriate screen based on message.data['type']
    // e.g., if type == 'appointment_confirmed' → navigate to appointments
  }

  /// Handle local notification tap
  void _handleLocalNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      print('👆 Local notification tapped: $data');
      // TODO: Navigate based on data['type']
    }
  }

  /// Show local notification (used for foreground + scheduled reminders)
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'appointment_channel',
      'Appointments',
      channelDescription: 'Appointment reminders and updates',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// ⭐ SCHEDULE APPOINTMENT REMINDER (30 minutes before)
  Future<void> scheduleAppointmentReminder({
    required String appointmentId,
    required DateTime appointmentDateTime,
    required String doctorName,
    required String appointmentType,
  }) async {
    try {
      // Calculate reminder time (30 minutes before)
      final reminderTime = appointmentDateTime.subtract(const Duration(minutes: 30));

      // Don't schedule if reminder time is in the past
      if (reminderTime.isBefore(DateTime.now())) {
        print('⚠️ Reminder time is in the past, skipping');
        return;
      }

      final tzReminderTime = tz.TZDateTime.from(reminderTime, tz.local);

      const androidDetails = AndroidNotificationDetails(
        'appointment_reminders',
        'Appointment Reminders',
        channelDescription: '30-minute appointment reminders',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.zonedSchedule(
        appointmentId.hashCode, // Unique ID per appointment
        '🩺 Appointment Starting Soon',
        'Your $appointmentType call with Dr. $doctorName starts in 30 minutes',
        tzReminderTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: jsonEncode({
          'type': 'appointment_reminder',
          'appointmentId': appointmentId,
        }),
      );

      print('✅ Reminder scheduled for $reminderTime');
    } catch (e) {
      print('❌ Error scheduling reminder: $e');
    }
  }

  /// Cancel scheduled appointment reminder
  Future<void> cancelAppointmentReminder(String appointmentId) async {
    await _localNotifications.cancel(appointmentId.hashCode);
    print('✅ Cancelled reminder for appointment: $appointmentId');
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Get pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _localNotifications.pendingNotificationRequests();
  }

  /// Mark notification as read in Firestore
  Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'read': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get unread notification count
  Stream<int> getUnreadNotificationCount() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0);

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}

/// Background message handler (MUST be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📨 Background message: ${message.notification?.title}');
  // Background messages are automatically shown by FCM
  // This is just for logging or additional processing
}