import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const rooms = ['Flash', 'Spectrum', 'Sanchar'];
const timelineRooms = [
  TimelineRoomSpec(roomId: 'Spectrum', label: 'Spectrum (GR1)'),
  TimelineRoomSpec(roomId: 'Flash', label: 'Flash (GR2)'),
  TimelineRoomSpec(roomId: 'Sanchar', label: 'Sanchar (GR3)'),
];

class TimelineRoomSpec {
  const TimelineRoomSpec({required this.roomId, required this.label});
  final String roomId;
  final String label;
}

class Roles {
  static const admin = 'admin';
  static const caretaker = 'caretaker';
}

class BookingStatuses {
  static const upcoming = 'Upcoming';
  static const checkedIn = 'Checked-In';
  static const checkedOut = 'Checked-Out';
  static const cancelled = 'Cancelled';
  static const all = [upcoming, checkedIn, checkedOut, cancelled];
}

class Palette {
  static const commandBlue = Color(0xFF0B3D91);
  static const commandDark = Color(0xFF071728);
  static const brass = Color(0xFFC99A2E);
  static const copper = Color(0xFFD36B45);
  static const forest = Color(0xFF167D5A);
  static const teal = Color(0xFF00A6A6);
  static const violet = Color(0xFF6C63FF);
  static const signalRed = Color(0xFFB3261E);
  static const mist = Color(0xFFF5F7FB);
  static const ink = Color(0xFF18202B);
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BootstrapApp());
}

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  late final Future<void> _firebaseInit = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _firebaseInit,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && !snapshot.hasError) {
          return const GRDeskApp();
        }
        return MaterialApp(
          title: 'GR Desk',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Palette.commandBlue),
          ),
          home: FirebaseStartupScreen(error: snapshot.error),
        );
      },
    );
  }
}

class FirebaseStartupScreen extends StatelessWidget {
  const FirebaseStartupScreen({super.key, this.error});
  final Object? error;

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Palette.commandDark, Palette.commandBlue, Color(0xFF123A6D)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.hotel_rounded, color: Colors.white, size: 72),
                const SizedBox(height: 16),
                const Text('GR Desk', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(
                  hasError ? 'Firebase startup failed' : 'Starting secure room operations...',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 22),
                if (hasError)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      error.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  )
                else
                  const LinearProgressIndicator(color: Palette.teal, backgroundColor: Colors.white24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GRDeskApp extends StatelessWidget {
  const GRDeskApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: Palette.commandBlue,
      brightness: Brightness.light,
      surface: Colors.white,
    );
    return MaterialApp(
      title: 'GR Desk',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: Palette.mist,
        cardTheme: CardThemeData(
          elevation: 5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Palette.teal, brightness: Brightness.dark),
      ),
      home: const AuthGate(),
    );
  }
}

class AppUser {
  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  final String uid;
  final String name;
  final String email;
  final String role;
  final int createdAt;

  bool get isAdmin => role.toLowerCase() == Roles.admin;

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      name: (data['name'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      role: (data['role'] ?? Roles.caretaker).toString(),
      createdAt: millis(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'role': role,
        'createdAt': createdAt,
      };
}

class Booking {
  Booking({
    this.id = '',
    required this.guestName,
    required this.rankDesignation,
    required this.unitOfficeRelation,
    required this.mobileNumber,
    required this.idProofType,
    required this.idProofNumber,
    required this.purposeOfVisit,
    required this.roomId,
    required this.numberOfGuests,
    required this.checkInDateTime,
    required this.checkOutDateTime,
    this.actualCheckInAt = 0,
    this.actualCheckOutAt = 0,
    required this.status,
    required this.paymentCharges,
    required this.remarks,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String guestName;
  final String rankDesignation;
  final String unitOfficeRelation;
  final String mobileNumber;
  final String idProofType;
  final String idProofNumber;
  final String purposeOfVisit;
  final String roomId;
  final int numberOfGuests;
  final int checkInDateTime;
  final int checkOutDateTime;
  final int actualCheckInAt;
  final int actualCheckOutAt;
  final String status;
  final double paymentCharges;
  final String remarks;
  final String createdBy;
  final int createdAt;
  final int updatedAt;

  Booking copyWith({
    String? id,
    String? guestName,
    String? rankDesignation,
    String? unitOfficeRelation,
    String? mobileNumber,
    String? idProofType,
    String? idProofNumber,
    String? purposeOfVisit,
    String? roomId,
    int? numberOfGuests,
    int? checkInDateTime,
    int? checkOutDateTime,
    int? actualCheckInAt,
    int? actualCheckOutAt,
    String? status,
    double? paymentCharges,
    String? remarks,
    String? createdBy,
    int? createdAt,
    int? updatedAt,
  }) {
    return Booking(
      id: id ?? this.id,
      guestName: guestName ?? this.guestName,
      rankDesignation: rankDesignation ?? this.rankDesignation,
      unitOfficeRelation: unitOfficeRelation ?? this.unitOfficeRelation,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      idProofType: idProofType ?? this.idProofType,
      idProofNumber: idProofNumber ?? this.idProofNumber,
      purposeOfVisit: purposeOfVisit ?? this.purposeOfVisit,
      roomId: roomId ?? this.roomId,
      numberOfGuests: numberOfGuests ?? this.numberOfGuests,
      checkInDateTime: checkInDateTime ?? this.checkInDateTime,
      checkOutDateTime: checkOutDateTime ?? this.checkOutDateTime,
      actualCheckInAt: actualCheckInAt ?? this.actualCheckInAt,
      actualCheckOutAt: actualCheckOutAt ?? this.actualCheckOutAt,
      status: status ?? this.status,
      paymentCharges: paymentCharges ?? this.paymentCharges,
      remarks: remarks ?? this.remarks,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Booking.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Booking(
      id: doc.id,
      guestName: (data['guestName'] ?? '').toString(),
      rankDesignation: (data['rankDesignation'] ?? '').toString(),
      unitOfficeRelation: (data['unitOfficeRelation'] ?? '').toString(),
      mobileNumber: (data['mobileNumber'] ?? '').toString(),
      idProofType: (data['idProofType'] ?? '').toString(),
      idProofNumber: (data['idProofNumber'] ?? '').toString(),
      purposeOfVisit: (data['purposeOfVisit'] ?? '').toString(),
      roomId: displayRoom((data['roomId'] ?? 'Flash').toString()),
      numberOfGuests: (data['numberOfGuests'] as num?)?.toInt() ?? 1,
      checkInDateTime: millis(data['checkInDateTime']),
      checkOutDateTime: millis(data['checkOutDateTime']),
      actualCheckInAt: millis(data['actualCheckInAt']),
      actualCheckOutAt: millis(data['actualCheckOutAt']),
      status: (data['status'] ?? BookingStatuses.upcoming).toString(),
      paymentCharges: (data['paymentCharges'] as num?)?.toDouble() ?? 0,
      remarks: (data['remarks'] ?? '').toString(),
      createdBy: (data['createdBy'] ?? '').toString(),
      createdAt: millis(data['createdAt']),
      updatedAt: millis(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'guestName': guestName,
        'rankDesignation': rankDesignation,
        'unitOfficeRelation': unitOfficeRelation,
        'mobileNumber': mobileNumber,
        'idProofType': idProofType,
        'idProofNumber': idProofNumber,
        'purposeOfVisit': purposeOfVisit,
        'roomId': displayRoom(roomId),
        'numberOfGuests': numberOfGuests,
        'checkInDateTime': checkInDateTime,
        'checkOutDateTime': checkOutDateTime,
        'actualCheckInAt': actualCheckInAt,
        'actualCheckOutAt': actualCheckOutAt,
        'status': status,
        'paymentCharges': paymentCharges,
        'remarks': remarks,
        'createdBy': createdBy,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}

class RoomSummary {
  RoomSummary(this.roomId, this.status, this.current, this.next);
  final String roomId;
  final String status;
  final Booking? current;
  final Booking? next;
}

class DashboardStats {
  DashboardStats({
    required this.availableRooms,
    required this.occupiedRooms,
    required this.upcomingBookings,
    required this.todayCheckIns,
    required this.todayCheckOuts,
    required this.monthBookings,
    required this.monthlyOccupancyPercent,
    required this.roomWiseBookings,
    required this.statusSummary,
    required this.recentBookings,
    required this.monthlyTrend,
    required this.timelineBookings,
  });

  final int availableRooms;
  final int occupiedRooms;
  final int upcomingBookings;
  final int todayCheckIns;
  final int todayCheckOuts;
  final int monthBookings;
  final double monthlyOccupancyPercent;
  final Map<String, int> roomWiseBookings;
  final Map<String, int> statusSummary;
  final List<Booking> recentBookings;
  final List<double> monthlyTrend;
  final List<Booking> timelineBookings;
}

class FirebaseRepo {
  FirebaseRepo._();
  static final auth = FirebaseAuth.instance;
  static final db = FirebaseFirestore.instance;

  static Stream<List<Booking>> bookings() {
    return db.collection('bookings').orderBy('checkInDateTime').snapshots().map(
          (snapshot) => snapshot.docs.map(Booking.fromDoc).toList(),
        );
  }

  static Stream<AppUser?> currentProfile() {
    final user = auth.currentUser;
    if (user == null) return Stream.value(null);
    return db.collection('users').doc(user.uid).snapshots().asyncMap((doc) async {
      if (!doc.exists) {
        final profile = AppUser(
          uid: user.uid,
          name: user.email?.split('@').first ?? 'Guest Room User',
          email: user.email ?? '',
          role: Roles.caretaker,
          createdAt: nowMs(),
        );
        await doc.reference.set(profile.toMap());
        return profile;
      }
      return AppUser.fromMap(doc.id, doc.data() ?? {});
    });
  }

  static Future<void> login(String email, String password) async {
    await auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  static Future<void> registerViewer(String name, String email, String password) async {
    final result = await auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
    final user = result.user!;
    await db.collection('users').doc(user.uid).set(
          AppUser(
            uid: user.uid,
            name: name.trim(),
            email: email.trim(),
            role: Roles.caretaker,
            createdAt: nowMs(),
          ).toMap(),
        );
  }

  static Future<void> seedRooms() async {
    final batch = db.batch();
    for (final room in rooms) {
      batch.set(
        db.collection('rooms').doc(room),
        {
          'roomId': room,
          'roomName': room,
          'status': 'Available',
          'currentBookingId': '',
          'updatedAt': nowMs(),
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
    await migrateLegacyRoomIds();
    await syncRooms();
  }

  static Future<void> migrateLegacyRoomIds() async {
    final legacy = {
      'GR1': 'Flash',
      'GR2': 'Spectrum',
      'GR3': 'Sanchar',
      'Zanskar': 'Flash',
      'Indus': 'Spectrum',
      'Shyok': 'Sanchar',
    };
    final snapshot = await db.collection('bookings').get();
    final batch = db.batch();
    var hasWrites = false;
    for (final doc in snapshot.docs) {
      final old = (doc.data()['roomId'] ?? '').toString();
      if (legacy.containsKey(old)) {
        batch.update(doc.reference, {'roomId': legacy[old], 'updatedAt': nowMs()});
        hasWrites = true;
      }
    }
    for (final old in legacy.keys) {
      batch.delete(db.collection('rooms').doc(old));
      hasWrites = true;
    }
    if (hasWrites) await batch.commit();
  }

  static Future<void> addBooking(Booking booking) async {
    await _validateConflict(booking);
    final ref = db.collection('bookings').doc();
    final now = nowMs();
    final saved = _withOperationalTimestamps(booking.copyWith(id: ref.id, createdAt: now, updatedAt: now), now);
    await ref.set(saved.toMap());
    await syncRooms();
  }

  static Future<void> updateBooking(Booking booking) async {
    await _validateConflict(booking);
    final now = nowMs();
    final saved = _withOperationalTimestamps(booking.copyWith(updatedAt: now), now);
    await db.collection('bookings').doc(booking.id).set(saved.toMap(), SetOptions(merge: true));
    await syncRooms();
  }

  static Future<void> deleteBooking(String id) async {
    await db.collection('bookings').doc(id).delete();
    await syncRooms();
  }

  static Future<void> updateStatus(Booking booking, String status) async {
    final now = nowMs();
    final update = <String, dynamic>{'status': status, 'updatedAt': now};
    if (status == BookingStatuses.checkedIn && booking.actualCheckInAt == 0) {
      update['actualCheckInAt'] = now;
    }
    if (status == BookingStatuses.checkedOut && booking.actualCheckOutAt == 0) {
      update['actualCheckOutAt'] = now;
    }
    await db.collection('bookings').doc(booking.id).set(update, SetOptions(merge: true));
    await syncRooms();
  }

  static Future<void> syncRooms() async {
    final snapshot = await db.collection('bookings').get();
    final all = snapshot.docs.map(Booking.fromDoc).toList();
    final summaries = roomSummaries(all);
    final batch = db.batch();
    for (final summary in summaries) {
      batch.set(
        db.collection('rooms').doc(summary.roomId),
        {
          'roomId': summary.roomId,
          'roomName': summary.roomId,
          'status': summary.status,
          'currentBookingId': summary.current?.id ?? '',
          'updatedAt': nowMs(),
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  static Future<void> _validateConflict(Booking target) async {
    final errors = validateBooking(target);
    if (errors.isNotEmpty) throw FirebaseException(plugin: 'gr_desk', message: errors.join('\n'));
    final snapshot = await db.collection('bookings').get();
    final conflict = snapshot.docs.map(Booking.fromDoc).where((existing) {
      return existing.id != target.id &&
          roomMatches(existing.roomId, target.roomId) &&
          existing.status != BookingStatuses.cancelled &&
          existing.status != BookingStatuses.checkedOut &&
          existing.checkInDateTime < target.checkOutDateTime &&
          existing.checkOutDateTime > target.checkInDateTime;
    }).firstOrNull;
    if (conflict != null) {
      throw FirebaseException(
        plugin: 'gr_desk',
        message: 'Room ${displayRoom(target.roomId)} already has ${conflict.guestName} booked for this date/time.',
      );
    }
  }

  static Booking _withOperationalTimestamps(Booking booking, int now) {
    if (booking.status == BookingStatuses.checkedIn) {
      return booking.copyWith(actualCheckInAt: booking.actualCheckInAt > 0 ? booking.actualCheckInAt : now);
    }
    if (booking.status == BookingStatuses.checkedOut) {
      return booking.copyWith(
        actualCheckInAt: booking.actualCheckInAt > 0 ? booking.actualCheckInAt : now,
        actualCheckOutAt: booking.actualCheckOutAt > 0 ? booking.actualCheckOutAt : now,
      );
    }
    return booking;
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseRepo.auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const SplashScreen();
        if (snapshot.data == null) return const LoginScreen();
        return StreamBuilder<AppUser?>(
          stream: FirebaseRepo.currentProfile(),
          builder: (context, profile) {
            if (!profile.hasData) return const SplashScreen();
            return AppShell(user: profile.data!);
          },
        );
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PremiumBackground(
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1200),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.92 + value * 0.08,
                child: Opacity(opacity: value, child: child),
              );
            },
            child: const GlassPanel(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.hotel_rounded, size: 72, color: Colors.white),
                  SizedBox(height: 16),
                  Text('GR Desk', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
                  SizedBox(height: 6),
                  Text('Guest Room Operations', style: TextStyle(color: Colors.white70)),
                  SizedBox(height: 22),
                  LinearProgressIndicator(color: Palette.teal, backgroundColor: Colors.white24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  var loading = false;
  String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PremiumBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 34),
              const CommandHero(),
              const SizedBox(height: 18),
              PremiumCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionTitle('Secure Sign In', 'Admin and caretaker access'),
                    const SizedBox(height: 14),
                    TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
                    const SizedBox(height: 12),
                    TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
                    if (error != null) ...[
                      const SizedBox(height: 10),
                      Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ],
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: loading ? null : _login,
                      icon: const Icon(Icons.login_rounded),
                      label: Text(loading ? 'Signing in...' : 'Sign in'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                      child: const Text('Create caretaker / viewer account'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await FirebaseRepo.login(email.text, password.text);
    } on FirebaseException catch (e) {
      setState(() => error = e.message);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  String? error;
  var loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PremiumBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SectionTitle('Register User', 'New users are created as caretaker / viewer'),
              const SizedBox(height: 16),
              PremiumCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(controller: name, decoration: const InputDecoration(labelText: 'Full name')),
                    const SizedBox(height: 12),
                    TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
                    const SizedBox(height: 12),
                    TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
                    if (error != null) ...[
                      const SizedBox(height: 10),
                      Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ],
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: loading ? null : _register,
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: Text(loading ? 'Creating...' : 'Create account'),
                    ),
                    OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Back to login')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _register() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await FirebaseRepo.registerViewer(name.text, email.text, password.text);
      if (mounted) Navigator.pop(context);
    } on FirebaseException catch (e) {
      setState(() => error = e.message);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.user});
  final AppUser user;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  var index = 0;

  @override
  void initState() {
    super.initState();
    if (widget.user.isAdmin) FirebaseRepo.seedRooms();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Booking>>(
      stream: FirebaseRepo.bookings(),
      builder: (context, snapshot) {
        final bookings = snapshot.data ?? [];
        final stats = dashboardStats(bookings);
        final pages = [
          DashboardScreen(stats: stats),
          RoomsScreen(bookings: bookings),
          BookingListScreen(bookings: bookings, user: widget.user),
          BookingListScreen(bookings: bookings, user: widget.user, history: true),
          ReportsScreen(stats: stats),
          ProfileScreen(user: widget.user),
        ];
        return Scaffold(
          body: PremiumBackground(child: SafeArea(child: pages[index])),
          bottomNavigationBar: PremiumBottomNav(
            selectedIndex: index,
            onSelected: (value) => setState(() => index = value),
          ),
        );
      },
    );
  }
}

class PremiumBottomNav extends StatelessWidget {
  const PremiumBottomNav({super.key, required this.selectedIndex, required this.onSelected});
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const items = [
    _NavSpec('Dash', Icons.dashboard_rounded, Palette.commandBlue),
    _NavSpec('Rooms', Icons.bed_rounded, Palette.forest),
    _NavSpec('Book', Icons.list_alt_rounded, Palette.brass),
    _NavSpec('History', Icons.history_rounded, Palette.copper),
    _NavSpec('Stats', Icons.analytics_rounded, Palette.violet),
    _NavSpec('Profile', Icons.person_rounded, Palette.teal),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        border: Border(top: BorderSide(color: Palette.commandBlue.withOpacity(0.10))),
        boxShadow: [BoxShadow(color: Palette.commandBlue.withOpacity(0.14), blurRadius: 24, offset: const Offset(0, -10))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: _PremiumTab(
                  item: items[i],
                  selected: i == selectedIndex,
                  onTap: () => onSelected(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavSpec {
  const _NavSpec(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

class _PremiumTab extends StatelessWidget {
  const _PremiumTab({required this.item, required this.selected, required this.onTap});
  final _NavSpec item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: selected ? 0.92 : 1, end: selected ? 1 : 0.92),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
          decoration: BoxDecoration(
            gradient: selected ? LinearGradient(colors: [item.color.withOpacity(0.20), Palette.commandBlue.withOpacity(0.10)]) : null,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? item.color.withOpacity(0.28) : Colors.transparent),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  if (selected)
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: item.color.withOpacity(0.26), blurRadius: 18, spreadRadius: 2)],
                      ),
                    ),
                  Icon(item.icon, color: selected ? item.color : Palette.ink.withOpacity(0.58), size: selected ? 25 : 22),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  color: selected ? item.color : Palette.ink.withOpacity(0.62),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                width: selected ? 18 : 0,
                height: 3,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(color: item.color, borderRadius: BorderRadius.circular(50)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        HeaderHero(metric: '${stats.monthlyOccupancyPercent.round()}%', label: 'monthly occupancy'),
        const SizedBox(height: 14),
        const SectionTitle('Command Summary', 'Current-time room and movement indicators'),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1.45,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            StatCard('Total rooms', '3', Icons.hotel_rounded, Palette.commandBlue),
            StatCard('Available', '${stats.availableRooms}', Icons.check_circle_rounded, Palette.teal),
            StatCard('Occupied', '${stats.occupiedRooms}', Icons.bed_rounded, Palette.forest),
            StatCard('Upcoming', '${stats.upcomingBookings}', Icons.event_available_rounded, Palette.brass),
            StatCard('Checked in', '${stats.todayCheckIns}', Icons.login_rounded, Palette.commandBlue),
            StatCard('Checked out', '${stats.todayCheckOuts}', Icons.logout_rounded, Palette.forest),
          ],
        ),
        const SizedBox(height: 14),
        ChartCard(title: 'Available vs occupied', child: DonutChart(available: stats.availableRooms, occupied: stats.occupiedRooms)),
        ChartCard(title: 'Room-wise bookings', child: BarChart(values: stats.roomWiseBookings)),
        ChartCard(title: 'Monthly occupancy trend', child: LineTrend(values: stats.monthlyTrend, labels: monthTrendLabels(stats.monthlyTrend.length))),
        RoomTimeline(bookings: stats.timelineBookings),
        const SectionTitle('Recent Bookings'),
        const SizedBox(height: 8),
        if (stats.recentBookings.isEmpty) const EmptyState('No bookings yet', 'Admin users can add the first guest room booking.'),
        ...stats.recentBookings.map((booking) => BookingTile(booking: booking)),
      ],
    );
  }
}

class RoomsScreen extends StatelessWidget {
  const RoomsScreen({super.key, required this.bookings});
  final List<Booking> bookings;

  @override
  Widget build(BuildContext context) {
    final summaries = roomSummaries(bookings);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionTitle('Room Status', 'Fixed room register for Flash, Spectrum and Sanchar'),
        const SizedBox(height: 12),
        ...summaries.map((summary) => RoomSummaryCard(summary: summary)),
      ],
    );
  }
}

class BookingListScreen extends StatelessWidget {
  const BookingListScreen({super.key, required this.bookings, required this.user, this.history = false});
  final List<Booking> bookings;
  final AppUser user;
  final bool history;

  @override
  Widget build(BuildContext context) {
    final visible = history
        ? bookings.where((b) => b.status == BookingStatuses.checkedOut || b.status == BookingStatuses.cancelled).toList()
        : bookings;
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: !history && user.isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingFormScreen(user: user))),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add'),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionTitle(history ? 'Guest History' : 'Bookings', history ? 'Checked-out and cancelled records' : 'All guest room bookings'),
          const SizedBox(height: 12),
          if (visible.isEmpty) const EmptyState('No records found', 'There are no bookings matching this view.'),
          ...visible.map((booking) => BookingTile(booking: booking, user: user)),
        ],
      ),
    );
  }
}

class BookingTile extends StatelessWidget {
  const BookingTile({super.key, required this.booking, this.user});
  final Booking booking;
  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PremiumCard(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingDetailsScreen(booking: booking, user: user))),
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: LinearGradient(colors: [statusColor(booking.status).withOpacity(0.08), Colors.transparent])),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(color: statusColor(booking.status).withOpacity(0.13), borderRadius: BorderRadius.circular(13)),
                    child: Icon(Icons.person_rounded, color: statusColor(booking.status)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(booking.guestName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
                  StatusChip(booking.status),
                ],
              ),
              const SizedBox(height: 10),
              Text('${booking.rankDesignation} | ${booking.unitOfficeRelation}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(displayRoom(booking.roomId), style: TextStyle(color: statusColor(booking.status), fontWeight: FontWeight.w900)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(formatDateTime(booking.checkInDateTime), style: const TextStyle(fontWeight: FontWeight.w700))),
                  const Icon(Icons.chevron_right_rounded, color: Palette.ink),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BookingDetailsScreen extends StatelessWidget {
  const BookingDetailsScreen({super.key, required this.booking, this.user});
  final Booking booking;
  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final isAdmin = user?.isAdmin == true;
    return Scaffold(
      body: PremiumBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionTitle('Booking Details', displayRoom(booking.roomId)),
              const SizedBox(height: 12),
              PremiumCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [Expanded(child: Text(booking.guestName, style: Theme.of(context).textTheme.headlineSmall)), StatusChip(booking.status)]),
                    const SizedBox(height: 12),
                    DetailRow('Rank / designation', booking.rankDesignation),
                    DetailRow('Unit / office / relation', booking.unitOfficeRelation),
                    DetailRow('Mobile number', booking.mobileNumber),
                    DetailRow('ID proof', '${booking.idProofType} - ${booking.idProofNumber}'),
                    DetailRow('Purpose', booking.purposeOfVisit),
                    DetailRow('Room allotted', displayRoom(booking.roomId)),
                    DetailRow('Number of guests', '${booking.numberOfGuests}'),
                    DetailRow('Scheduled check-in', formatDateTime(booking.checkInDateTime)),
                    DetailRow('Scheduled check-out', formatDateTime(booking.checkOutDateTime)),
                    DetailRow('Actual check-in', booking.actualCheckInAt > 0 ? formatDateTime(booking.actualCheckInAt) : 'Not marked'),
                    DetailRow('Actual check-out', booking.actualCheckOutAt > 0 ? formatDateTime(booking.actualCheckOutAt) : 'Not marked'),
                    DetailRow('Payment / charges', 'Rs ${booking.paymentCharges.toStringAsFixed(0)}'),
                    DetailRow('Remarks', booking.remarks.isEmpty ? 'Nil' : booking.remarks),
                    DetailRow('Created by', booking.createdBy),
                    DetailRow('Created', formatDateTime(booking.createdAt)),
                    DetailRow('Last updated', formatDateTime(booking.updatedAt)),
                  ],
                ),
              ),
              if (isAdmin) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingFormScreen(user: user!, existing: booking))),
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Edit booking'),
                ),
                Row(
                  children: [
                    Expanded(child: OutlinedButton(onPressed: () => _status(context, BookingStatuses.checkedIn), child: const Text('Mark in'))),
                    const SizedBox(width: 8),
                    Expanded(child: OutlinedButton(onPressed: () => _status(context, BookingStatuses.checkedOut), child: const Text('Mark out'))),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: OutlinedButton(onPressed: () => _status(context, BookingStatuses.cancelled), child: const Text('Cancel'))),
                    const SizedBox(width: 8),
                    Expanded(child: OutlinedButton(onPressed: () => _delete(context), child: const Text('Delete'))),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _status(BuildContext context, String status) async {
    await FirebaseRepo.updateStatus(booking, status);
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _delete(BuildContext context) async {
    await FirebaseRepo.deleteBooking(booking.id);
    if (context.mounted) Navigator.pop(context);
  }
}

class BookingFormScreen extends StatefulWidget {
  const BookingFormScreen({super.key, required this.user, this.existing});
  final AppUser user;
  final Booking? existing;

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  late final guestName = TextEditingController(text: widget.existing?.guestName ?? '');
  late final rank = TextEditingController(text: widget.existing?.rankDesignation ?? '');
  late final unit = TextEditingController(text: widget.existing?.unitOfficeRelation ?? '');
  late final mobile = TextEditingController(text: widget.existing?.mobileNumber ?? '');
  late final idNumber = TextEditingController(text: widget.existing?.idProofNumber ?? '');
  late final purpose = TextEditingController(text: widget.existing?.purposeOfVisit ?? '');
  late final guests = TextEditingController(text: '${widget.existing?.numberOfGuests ?? 1}');
  late final payment = TextEditingController(text: '${widget.existing?.paymentCharges ?? 0}');
  late final remarks = TextEditingController(text: widget.existing?.remarks ?? '');
  late var idType = widget.existing?.idProofType ?? 'Aadhaar';
  late var room = displayRoom(widget.existing?.roomId ?? rooms.first);
  late var status = widget.existing?.status ?? BookingStatuses.upcoming;
  late var checkIn = DateTime.fromMillisecondsSinceEpoch(widget.existing?.checkInDateTime ?? nowMs() + 3600000);
  late var checkOut = DateTime.fromMillisecondsSinceEpoch(widget.existing?.checkOutDateTime ?? nowMs() + 90000000);
  String? error;
  var loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PremiumBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionTitle(widget.existing == null ? 'Add Booking' : 'Edit Booking', 'Room allotment and guest details'),
              const SizedBox(height: 12),
              PremiumCard(
                child: Column(
                  children: [
                    field(guestName, 'Guest name'),
                    field(rank, 'Rank / designation'),
                    field(unit, 'Unit / office / relation'),
                    field(mobile, 'Mobile number', keyboard: TextInputType.phone),
                    dropdown('ID proof type', idType, ['Aadhaar', 'PAN', 'Passport', 'Service ID', 'Driving Licence'], (v) => setState(() => idType = v)),
                    field(idNumber, 'ID proof number'),
                    field(purpose, 'Purpose of visit'),
                    dropdown('Room allotted', room, rooms, (v) => setState(() => room = v)),
                    field(guests, 'Number of guests', keyboard: TextInputType.number),
                    Row(children: [
                      Expanded(child: pickButton('Check-in', checkIn, true)),
                      const SizedBox(width: 8),
                      Expanded(child: pickButton('Check-out', checkOut, false)),
                    ]),
                    dropdown('Booking status', status, BookingStatuses.all, (v) => setState(() => status = v)),
                    field(payment, 'Payment / charges', keyboard: TextInputType.number),
                    field(remarks, 'Remarks', lines: 3),
                    if (error != null) Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: loading ? null : save,
                      icon: const Icon(Icons.save_rounded),
                      label: Text(widget.existing == null ? 'Save booking' : 'Update booking'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget field(TextEditingController controller, String label, {TextInputType? keyboard, int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(controller: controller, keyboardType: keyboard, maxLines: lines, decoration: InputDecoration(labelText: label)),
    );
  }

  Widget dropdown(String label, String value, List<String> values, ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(labelText: label),
        items: values.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }

  Widget pickButton(String label, DateTime value, bool isIn) {
    return OutlinedButton(
      onPressed: () async {
        final date = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2100), initialDate: value);
        if (date == null || !mounted) return;
        final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(value));
        if (time == null) return;
        setState(() {
          final next = DateTime(date.year, date.month, date.day, time.hour, time.minute);
          if (isIn) {
            checkIn = next;
          } else {
            checkOut = next;
          }
        });
      },
      child: Text('$label\n${formatDateTime(value.millisecondsSinceEpoch)}', textAlign: TextAlign.center),
    );
  }

  Future<void> save() async {
    setState(() {
      loading = true;
      error = null;
    });
    final now = nowMs();
    final existing = widget.existing;
    final booking = Booking(
      id: existing?.id ?? '',
      guestName: guestName.text.trim(),
      rankDesignation: rank.text.trim(),
      unitOfficeRelation: unit.text.trim(),
      mobileNumber: mobile.text.trim(),
      idProofType: idType,
      idProofNumber: idNumber.text.trim(),
      purposeOfVisit: purpose.text.trim(),
      roomId: room,
      numberOfGuests: int.tryParse(guests.text) ?? 0,
      checkInDateTime: checkIn.millisecondsSinceEpoch,
      checkOutDateTime: checkOut.millisecondsSinceEpoch,
      actualCheckInAt: existing?.actualCheckInAt ?? 0,
      actualCheckOutAt: existing?.actualCheckOutAt ?? 0,
      status: status,
      paymentCharges: double.tryParse(payment.text) ?? 0,
      remarks: remarks.text.trim(),
      createdBy: existing?.createdBy.isNotEmpty == true ? existing!.createdBy : widget.user.email,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    try {
      if (existing == null) {
        await FirebaseRepo.addBooking(booking);
      } else {
        await FirebaseRepo.updateBooking(booking);
      }
      if (mounted) Navigator.pop(context);
    } on FirebaseException catch (e) {
      setState(() => error = e.message);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key, required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionTitle('Reports', 'Statistics and room movement summary'),
        const SizedBox(height: 12),
        ChartCard(title: 'Booking status summary', child: BarChart(values: stats.statusSummary)),
        ChartCard(title: 'Room-wise occupancy', child: BarChart(values: stats.roomWiseBookings)),
        ChartCard(title: 'Monthly trend', child: LineTrend(values: stats.monthlyTrend, labels: monthTrendLabels(stats.monthlyTrend.length))),
        PremiumCard(child: Text('Total bookings created this month: ${stats.monthBookings}', style: Theme.of(context).textTheme.titleMedium)),
      ],
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionTitle('Profile', 'Firebase identity, role access and application information'),
        const SizedBox(height: 12),
        HeaderHero(metric: user.isAdmin ? 'Admin' : 'Viewer', label: user.email, name: user.name),
        const SizedBox(height: 12),
        ProfileInfoCard('About GR Desk', 'GR Desk manages Flash, Spectrum and Sanchar with Firebase real-time sync, role-based access, booking history, reports and a two-month visual timeline.', Icons.info_rounded, Palette.teal),
        ProfileInfoCard('Developer', 'This application is made and developed by Pranav Singh with focus on dependable unit-level guest room operations, premium interface quality and clean architecture.', Icons.code_rounded, Palette.copper),
        ProfileInfoCard('Security Model', 'Admin users can add, edit, cancel, check in and check out bookings. Caretaker / viewer users can monitor dashboard, room status, reports, timeline and guest history only.', Icons.security_rounded, Palette.brass),
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Session', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              const Text('Use logout when handing over the device or changing Firebase users.'),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => FirebaseRepo.auth.signOut(),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Logout'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class RoomTimeline extends StatelessWidget {
  const RoomTimeline({super.key, required this.bookings});
  final List<Booking> bookings;

  @override
  Widget build(BuildContext context) {
    final start = startOfToday();
    final days = List.generate(62, (i) => start.add(Duration(days: i)));
    return ChartCard(
      title: 'Two-month room timeline',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'One synchronized scroll for all rooms. Green cells are available; colored cells are booked or active.',
            style: TextStyle(color: Palette.ink, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 106),
                    ...days.map(
                      (day) => Container(
                        width: 78,
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Palette.commandBlue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Palette.commandBlue.withOpacity(0.14)),
                        ),
                        child: Column(
                          children: [
                            Text(DateFormat('EEE').format(day), style: const TextStyle(fontSize: 10, color: Palette.commandBlue, fontWeight: FontWeight.w900)),
                            Text(DateFormat('dd MMM').format(day), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...timelineRooms.map((room) {
                  final roomBookings = bookings.where((b) => roomMatches(b.roomId, room.roomId)).toList();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 100,
                          height: 72,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Palette.commandBlue, Color(0xFF123A6D)]),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [BoxShadow(color: Palette.commandBlue.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 5))],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.hotel_rounded, size: 18, color: Colors.white),
                              const SizedBox(height: 4),
                              Text(room.label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        ...days.map((day) {
                          final booking = roomBookings.where((b) => overlapsDay(b, day)).firstOrNull;
                          final booked = booking != null;
                          final color = booked ? statusColor(booking.status) : Palette.teal;
                          return Container(
                            width: 78,
                            height: 72,
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  color.withOpacity(booked ? 0.22 : 0.11),
                                  Colors.white.withOpacity(0.82),
                                ],
                              ),
                              border: Border.all(color: color.withOpacity(booked ? 0.40 : 0.22)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(booked ? booking.guestName : 'Available', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w900, fontSize: booked ? 11 : 10)),
                                const Spacer(),
                                Text(booked ? booking.status : 'Open', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PremiumBackground extends StatefulWidget {
  const PremiumBackground({super.key, required this.child});
  final Widget child;

  @override
  State<PremiumBackground> createState() => _PremiumBackgroundState();
}

class _PremiumBackgroundState extends State<PremiumBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF7FAFC), Color(0xFFEAF1F8), Color(0xFFF9FBFF)],
                ),
              ),
            ),
            Positioned.fill(child: CustomPaint(painter: BackgroundGridPainter(progress: _controller.value))),
            widget.child,
          ],
        );
      },
    );
  }
}

class BackgroundGridPainter extends CustomPainter {
  BackgroundGridPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Palette.commandBlue.withOpacity(0.035)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    final glow = Paint()..shader = RadialGradient(
      colors: [Palette.teal.withOpacity(0.22), Colors.transparent],
    ).createShader(Rect.fromCircle(center: Offset(size.width * (0.15 + 0.70 * progress), size.height * 0.18), radius: 170));
    canvas.drawCircle(Offset(size.width * (0.15 + 0.70 * progress), size.height * 0.18), 170, glow);
    final sweep = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Palette.brass.withOpacity(0.18);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(size.width * 0.86, size.height * 0.10), radius: 82),
      math.pi * 2 * progress,
      math.pi * 0.72,
      false,
      sweep,
    );
    final wave = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Palette.violet.withOpacity(0.08);
    final path = Path();
    for (var x = 0.0; x <= size.width; x += 18) {
      final y = size.height * 0.74 + math.sin((x / size.width * math.pi * 2) + (progress * math.pi * 2)) * 18;
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, wave);
    final copperGlow = Paint()..shader = RadialGradient(
      colors: [Palette.copper.withOpacity(0.12), Colors.transparent],
    ).createShader(Rect.fromCircle(center: Offset(size.width * 0.08, size.height * (0.55 + 0.12 * math.sin(progress * math.pi * 2))), radius: 140));
    canvas.drawCircle(Offset(size.width * 0.08, size.height * (0.55 + 0.12 * math.sin(progress * math.pi * 2))), 140, copperGlow);
  }

  @override
  bool shouldRepaint(covariant BackgroundGridPainter oldDelegate) => oldDelegate.progress != progress;
}
class GlassPanel extends StatelessWidget {
  const GlassPanel({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(colors: [Palette.commandBlue, Color(0xFF123A6D), Palette.commandDark]),
        border: Border.all(color: Colors.white24),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 24, offset: Offset(0, 12))],
      ),
      child: child,
    );
  }
}

class PremiumCard extends StatelessWidget {
  const PremiumCard({super.key, required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, value, animatedChild) {
        return Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: Opacity(opacity: value, child: animatedChild),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white.withOpacity(0.98), const Color(0xFFF8FBFF).withOpacity(0.96)],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.70)),
          boxShadow: [
            BoxShadow(color: Palette.commandBlue.withOpacity(0.10), blurRadius: 24, offset: const Offset(0, 12)),
            BoxShadow(color: Colors.white.withOpacity(0.90), blurRadius: 2, offset: const Offset(0, -1)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              Positioned(
                right: -36,
                top: -46,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Palette.teal.withOpacity(0.07)),
                ),
              ),
              Positioned(
                left: -28,
                bottom: -42,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Palette.brass.withOpacity(0.06)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
    if (onTap == null) return card;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8), child: card);
  }
}

class CommandHero extends StatelessWidget {
  const CommandHero({super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      builder: (context, value, child) => Transform.translate(offset: Offset(0, 18 * (1 - value)), child: Opacity(opacity: value, child: child)),
      child: Container(
        height: 210,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: const LinearGradient(colors: [Palette.commandDark, Palette.commandBlue, Color(0xFF123A6D)]),
          border: Border.all(color: Colors.white24),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))],
        ),
        child: CustomPaint(
          painter: RadarPainter(),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [MiniPill('Admin', Palette.brass), SizedBox(width: 8), MiniPill('Caretaker', Palette.teal), SizedBox(width: 8), MiniPill('Realtime', Palette.copper)]),
              Spacer(),
              Text('GR Desk', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
              SizedBox(height: 6),
              Text('Secure guest room operations for Flash, Spectrum and Sanchar', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}

class MiniPill extends StatelessWidget {
  const MiniPill(this.label, this.color, {super.key});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(50), border: Border.all(color: color.withOpacity(0.32))),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }
}

class RadarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1;
    for (var y = 24.0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final center = Offset(size.width * 0.78, size.height * 0.35);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Palette.teal.withOpacity(0.34);
    canvas.drawCircle(center, 46, ring);
    canvas.drawCircle(center, 24, ring..color = Palette.brass.withOpacity(0.22));
    final path = Path()
      ..moveTo(size.width * 0.06, size.height * 0.78)
      ..lineTo(size.width * 0.24, size.height * 0.45)
      ..lineTo(size.width * 0.43, size.height * 0.60)
      ..lineTo(size.width * 0.62, size.height * 0.25)
      ..lineTo(size.width * 0.92, size.height * 0.42);
    canvas.drawPath(path, Paint()..color = Palette.teal.withOpacity(0.42)..style = PaintingStyle.stroke..strokeWidth = 3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HeaderHero extends StatelessWidget {
  const HeaderHero({super.key, required this.metric, required this.label, this.name = 'Dashboard'});
  final String metric;
  final String label;
  final String name;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.scale(scale: 0.96 + value * 0.04, child: Opacity(opacity: value, child: child)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Palette.commandDark, Palette.commandBlue, Color(0xFF1556A6), Color(0xFF102039)],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.20)),
          boxShadow: [BoxShadow(color: Palette.commandBlue.withOpacity(0.30), blurRadius: 28, offset: const Offset(0, 16))],
        ),
        child: CustomPaint(
          painter: HeroCircuitPainter(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(Icons.hotel_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900))),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Live operational picture for Flash, Spectrum and Sanchar', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(metric, style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(label, style: const TextStyle(color: Palette.teal, fontWeight: FontWeight.w900))),
                ],
              ),
              const SizedBox(height: 14),
              const Row(children: [MiniPill('Flash', Palette.teal), SizedBox(width: 8), MiniPill('Spectrum', Palette.brass), SizedBox(width: 8), MiniPill('Sanchar', Palette.copper)]),
            ],
          ),
        ),
      ),
    );
  }
}

class HeroCircuitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 34) {
      canvas.drawLine(Offset(x, 0), Offset(x + 48, size.height), line);
    }
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Palette.teal.withOpacity(0.35);
    canvas.drawCircle(Offset(size.width * 0.86, size.height * 0.25), 52, arc);
    canvas.drawCircle(Offset(size.width * 0.86, size.height * 0.25), 27, arc..color = Palette.brass.withOpacity(0.22));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, [this.subtitle, Key? key]) : super(key: key);
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        if (subtitle != null) Text(subtitle!, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        Container(width: 84, height: 4, decoration: BoxDecoration(borderRadius: BorderRadius.circular(50), gradient: const LinearGradient(colors: [Palette.teal, Palette.brass, Palette.copper]))),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard(this.title, this.value, this.icon, this.color, {super.key});
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.elasticOut,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: PremiumCard(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color.withOpacity(0.25), Palette.violet.withOpacity(0.08)]),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.22)),
                boxShadow: [BoxShadow(color: color.withOpacity(0.18), blurRadius: 16, offset: const Offset(0, 8))],
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChartCard extends StatelessWidget {
  const ChartCard({super.key, required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 9, height: 28, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Palette.teal, Palette.brass]), borderRadius: BorderRadius.circular(50))),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(50), gradient: const LinearGradient(colors: [Palette.teal, Palette.brass, Palette.copper])),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class DonutChart extends StatelessWidget {
  const DonutChart({super.key, required this.available, required this.occupied});
  final int available;
  final int occupied;

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 170, child: CustomPaint(painter: DonutPainter(available, occupied), child: Center(child: Text('$available available\n$occupied occupied', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900)))));
  }
}

class DonutPainter extends CustomPainter {
  DonutPainter(this.available, this.occupied);
  final int available;
  final int occupied;

  @override
  void paint(Canvas canvas, Size size) {
    final total = math.max(available + occupied, 1);
    final rect = Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: 132, height: 132);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * available / total, false, stroke..color = Palette.teal);
    canvas.drawArc(rect, -math.pi / 2 + math.pi * 2 * available / total + 0.08, math.pi * 2 * occupied / total, false, stroke..color = Palette.forest);
  }

  @override
  bool shouldRepaint(covariant DonutPainter oldDelegate) => oldDelegate.available != available || oldDelegate.occupied != occupied;
}

class BarChart extends StatelessWidget {
  const BarChart({super.key, required this.values});
  final Map<String, int> values;

  @override
  Widget build(BuildContext context) {
    final maxValue = values.values.fold<int>(1, math.max);
    return Column(
      children: values.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              SizedBox(width: 86, child: Text(entry.key, maxLines: 1, overflow: TextOverflow.ellipsis)),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: LinearProgressIndicator(value: entry.value / maxValue, minHeight: 16, color: Palette.commandBlue, backgroundColor: Palette.commandBlue.withOpacity(0.12)),
                ),
              ),
              const SizedBox(width: 10),
              Text('${entry.value}', style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class LineTrend extends StatelessWidget {
  const LineTrend({super.key, required this.values, required this.labels});
  final List<double> values;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final points = values.isEmpty ? <double>[0] : values.map((value) => value.clamp(0, 100).toDouble()).toList();
    final xLabels = labels.length == points.length ? labels : List.generate(points.length, (index) => 'M${index + 1}');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Y-axis: occupancy %', style: TextStyle(fontSize: 11, color: Palette.ink, fontWeight: FontWeight.w700)),
            Text('X-axis: month', style: TextStyle(fontSize: 11, color: Palette.ink, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const SizedBox(
              width: 36,
              height: 172,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('100%', style: TextStyle(fontSize: 10, color: Palette.ink)),
                  Text('75%', style: TextStyle(fontSize: 10, color: Palette.ink)),
                  Text('50%', style: TextStyle(fontSize: 10, color: Palette.ink)),
                  Text('25%', style: TextStyle(fontSize: 10, color: Palette.ink)),
                  Text('0%', style: TextStyle(fontSize: 10, color: Palette.ink)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 172,
                child: CustomPaint(painter: LineTrendPainter(points), child: const SizedBox.expand()),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 44, top: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: xLabels.map((label) => Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Palette.ink))).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < points.length; i++)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: Palette.violet.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Palette.violet.withOpacity(0.20)),
                ),
                child: Text('${xLabels[i]}: ${points[i].round()}%', style: const TextStyle(color: Palette.violet, fontSize: 11, fontWeight: FontWeight.w900)),
              ),
          ],
        ),
      ],
    );
  }
}

class LineTrendPainter extends CustomPainter {
  LineTrendPainter(this.values);
  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Palette.commandBlue.withOpacity(0.08)
      ..strokeWidth = 1;
    for (var i = 0; i < 5; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    if (values.isEmpty) return;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1 ? 0.0 : size.width * i / (values.length - 1);
      final y = size.height - (values[i] / 100) * (size.height - 18) - 9;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 9, Paint()..color = Palette.violet.withOpacity(0.16));
      canvas.drawCircle(Offset(x, y), 4.5, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(x, y), 3.5, Paint()..color = Palette.violet);
    }
    canvas.drawLine(Offset(0, size.height - 1), Offset(size.width, size.height - 1), Paint()..color = Palette.ink.withOpacity(0.18)..strokeWidth = 1.2);
    canvas.drawLine(const Offset(0, 0), Offset(0, size.height), Paint()..color = Palette.ink.withOpacity(0.18)..strokeWidth = 1.2);
    canvas.drawPath(path, Paint()..color = Palette.violet..style = PaintingStyle.stroke..strokeWidth = 4..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant LineTrendPainter oldDelegate) => oldDelegate.values != values;
}

class RoomSummaryCard extends StatelessWidget {
  const RoomSummaryCard({super.key, required this.summary});
  final RoomSummary summary;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(summary.status);
    return PremiumCard(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(colors: [color.withOpacity(0.08), Colors.transparent]),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(color: color.withOpacity(0.14), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.20))),
                  child: Icon(Icons.bed_rounded, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(summary.roomId, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900))),
                StatusChip(summary.status),
              ],
            ),
            const SizedBox(height: 12),
            Text(summary.current != null ? 'Current guest: ${summary.current!.guestName}' : 'No guest currently checked in', style: const TextStyle(fontWeight: FontWeight.w700)),
            if (summary.next != null) ...[
              const SizedBox(height: 6),
              Text('Next: ${summary.next!.guestName} on ${formatDateTime(summary.next!.checkInDateTime)}', style: const TextStyle(color: Palette.ink)),
            ],
          ],
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.88, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withOpacity(0.18), color.withOpacity(0.07)]),
          border: Border.all(color: color.withOpacity(0.30)),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [BoxShadow(color: color.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11)),
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  const DetailRow(this.label, this.value, {super.key});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState(this.title, this.body, {super.key});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        children: [
          Icon(Icons.info_outline_rounded, size: 42, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          Text(body, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class ProfileInfoCard extends StatelessWidget {
  const ProfileInfoCard(this.title, this.body, this.icon, this.color, {super.key});
  final String title;
  final String body;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color.withOpacity(0.20), Palette.commandBlue.withOpacity(0.06)]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.20)),
              boxShadow: [BoxShadow(color: color.withOpacity(0.14), blurRadius: 16, offset: const Offset(0, 8))],
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                Text(body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

int nowMs() => DateTime.now().millisecondsSinceEpoch;

int millis(dynamic value) {
  if (value == null) return 0;
  if (value is Timestamp) return value.millisecondsSinceEpoch;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

String displayRoom(String roomId) {
  switch (roomId) {
    case 'GR1':
      return 'Flash';
    case 'GR2':
      return 'Spectrum';
    case 'GR3':
      return 'Sanchar';
    case 'Zanskar':
      return 'Flash';
    case 'Indus':
      return 'Spectrum';
    case 'Shyok':
      return 'Sanchar';
    default:
      return roomId;
  }
}

bool roomMatches(String a, String b) => displayRoom(a).toLowerCase() == displayRoom(b).toLowerCase();

String formatDateTime(int value) => value <= 0 ? 'Not marked' : DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(value));

DateTime startOfToday() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

DateTime endOfToday() => startOfToday().add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));

DateTime startOfMonth([int offset = 0]) {
  final now = DateTime.now();
  return DateTime(now.year, now.month + offset);
}

DateTime endOfMonth([int offset = 0]) => DateTime(startOfMonth(offset).year, startOfMonth(offset).month + 1).subtract(const Duration(milliseconds: 1));

List<String> monthTrendLabels(int count) {
  final formatter = DateFormat('MMM');
  return List.generate(count, (index) {
    final monthsBack = count - 1 - index;
    final date = DateTime(DateTime.now().year, DateTime.now().month - monthsBack);
    return formatter.format(date);
  });
}

int overlapMillis(int startA, int endA, int startB, int endB) {
  return math.max(0, math.min(endA, endB) - math.max(startA, startB));
}

List<String> validateBooking(Booking booking) {
  final errors = <String>[];
  if (booking.guestName.isEmpty) errors.add('Guest name is required.');
  if (booking.rankDesignation.isEmpty) errors.add('Rank / designation is required.');
  if (booking.unitOfficeRelation.isEmpty) errors.add('Unit / office / relation is required.');
  if (!RegExp(r'^[0-9]{10}$').hasMatch(booking.mobileNumber)) errors.add('Enter a valid 10 digit mobile number.');
  if (booking.idProofNumber.isEmpty) errors.add('ID proof number is required.');
  if (booking.purposeOfVisit.isEmpty) errors.add('Purpose of visit is required.');
  if (booking.numberOfGuests <= 0) errors.add('Number of guests must be at least 1.');
  if (booking.checkOutDateTime <= booking.checkInDateTime) errors.add('Check-out must be after check-in.');
  return errors;
}

List<RoomSummary> roomSummaries(List<Booking> bookings, [int? now]) {
  final currentTime = now ?? nowMs();
  return rooms.map((room) {
    final roomBookings = bookings
        .where((booking) => roomMatches(booking.roomId, room) && booking.status != BookingStatuses.cancelled && booking.status != BookingStatuses.checkedOut)
        .toList()
      ..sort((a, b) => a.checkInDateTime.compareTo(b.checkInDateTime));
    final current = roomBookings.where((booking) => booking.status == BookingStatuses.checkedIn).firstOrNull;
    final next = roomBookings.where((booking) => booking.status == BookingStatuses.upcoming && booking.checkOutDateTime >= currentTime && booking.id != current?.id).firstOrNull;
    final status = current != null ? 'Occupied' : (next != null ? 'Upcoming Booking' : 'Available');
    return RoomSummary(room, status, current, next);
  }).toList();
}

DashboardStats dashboardStats(List<Booking> bookings, [int? now]) {
  final currentTime = now ?? nowMs();
  final summaries = roomSummaries(bookings, currentTime);
  final todayStart = startOfToday().millisecondsSinceEpoch;
  final todayEnd = endOfToday().millisecondsSinceEpoch;
  final monthStart = startOfMonth().millisecondsSinceEpoch;
  final monthEnd = endOfMonth().millisecondsSinceEpoch;
  final activeMonth = bookings.where((b) => b.status != BookingStatuses.cancelled && b.checkInDateTime <= monthEnd && b.checkOutDateTime >= monthStart).toList();
  final occupiedMs = activeMonth.fold<int>(0, (sum, b) => sum + overlapMillis(b.checkInDateTime, b.checkOutDateTime, monthStart, monthEnd));
  final daysInMonth = DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day;
  final totalRoomMs = rooms.length * daysInMonth * 86400000;
  final trend = List.generate(6, (index) {
    final offset = index - 5;
    final start = startOfMonth(offset).millisecondsSinceEpoch;
    final end = endOfMonth(offset).millisecondsSinceEpoch;
    final dayCount = DateTime(startOfMonth(offset).year, startOfMonth(offset).month + 1, 0).day;
    final roomMs = rooms.length * dayCount * 86400000;
    final ms = bookings.where((b) => b.status != BookingStatuses.cancelled && b.checkInDateTime <= end && b.checkOutDateTime >= start).fold<int>(0, (sum, b) => sum + overlapMillis(b.checkInDateTime, b.checkOutDateTime, start, end));
    return roomMs == 0 ? 0.0 : (ms / roomMs) * 100;
  });

  return DashboardStats(
    availableRooms: summaries.where((s) => s.status != 'Occupied').length,
    occupiedRooms: summaries.where((s) => s.status == 'Occupied').length,
    upcomingBookings: bookings.where((b) => b.status == BookingStatuses.upcoming && b.checkInDateTime > currentTime).length,
    todayCheckIns: bookings.where((b) => b.actualCheckInAt >= todayStart && b.actualCheckInAt <= todayEnd && b.status != BookingStatuses.cancelled).length,
    todayCheckOuts: bookings.where((b) => b.actualCheckOutAt >= todayStart && b.actualCheckOutAt <= todayEnd && b.status != BookingStatuses.cancelled).length,
    monthBookings: bookings.where((b) => b.createdAt >= monthStart && b.createdAt <= monthEnd).length,
    monthlyOccupancyPercent: totalRoomMs == 0 ? 0 : ((occupiedMs / totalRoomMs) * 100).clamp(0, 100).toDouble(),
    roomWiseBookings: {for (final room in rooms) room: bookings.where((b) => roomMatches(b.roomId, room)).length},
    statusSummary: {for (final status in BookingStatuses.all) status: bookings.where((b) => b.status == status).length},
    recentBookings: ([...bookings]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt))).take(6).toList(),
    monthlyTrend: trend,
    timelineBookings: bookings.where((b) => b.status != BookingStatuses.cancelled && b.status != BookingStatuses.checkedOut && b.checkOutDateTime >= todayStart).toList()..sort((a, b) => a.checkInDateTime.compareTo(b.checkInDateTime)),
  );
}

bool overlapsDay(Booking booking, DateTime day) {
  final start = DateTime(day.year, day.month, day.day).millisecondsSinceEpoch;
  final end = start + 86400000 - 1;
  return booking.checkInDateTime <= end && booking.checkOutDateTime >= start;
}

Color statusColor(String status) {
  switch (status) {
    case BookingStatuses.checkedIn:
    case 'Occupied':
      return Palette.forest;
    case BookingStatuses.upcoming:
    case 'Upcoming Booking':
      return Palette.brass;
    case BookingStatuses.cancelled:
      return Palette.signalRed;
    default:
      return Palette.teal;
  }
}

extension FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
