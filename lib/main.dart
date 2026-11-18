import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'firebase_options.dart';

const Color primaryBlue = Color(0xFF1769AA);
const Color darkBlue = Color(0xFF124B7A);
const Color lightBlue = Color(0xFFEAF3FC);

final FirebaseAuth auth = FirebaseAuth.instance;
final FirebaseFirestore db = FirebaseFirestore.instance;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const GramSevaApp());
}

class GramSevaApp extends StatelessWidget {
  const GramSevaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GRAM SEVA',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primaryBlue),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
          ),
        ),
        useMaterial3: true,
      ),
      home: const RoleSelectionPage(),
    );
  }
}

// ======================================================
// COMMON MESSAGE
// ======================================================

void showAppMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

// ======================================================
// FIRST SCREEN
// ======================================================

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  Widget roleCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 55, color: primaryBlue),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: darkBlue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(subtitle, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBlue,
      appBar: AppBar(title: const Text('GRAM SEVA')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 35),
            const Icon(Icons.account_balance, size: 75, color: primaryBlue),
            const SizedBox(height: 15),
            const Text(
              'Mana Ooru - Mana Badhyatha',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: darkBlue,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text('Village Development and Complaint Portal'),
            const SizedBox(height: 35),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: roleCard(
                      context,
                      'Citizen Interface',
                      'Register, submit complaints and track problems',
                      Icons.people,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CitizenRegistrationPage(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: roleCard(
                      context,
                      'Official Interface',
                      'Manage complaints and update their status',
                      Icons.account_balance,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OfficialSelectionPage(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// CITIZEN REGISTER / LOGIN CHOICE
// ======================================================

class CitizenRegistrationPage extends StatelessWidget {
  const CitizenRegistrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Citizen Interface')),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_alt, size:  70, color: primaryBlue),
            const SizedBox(height: 18),
            const Text('Welcome, Citizen', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: darkBlue)),
            const SizedBox(height: 28),
            SizedBox(width: double.infinity, height: 52, child: ElevatedButton.icon(
              icon: const Icon(Icons.person_add), label: const Text('Register'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CitizenRegisterFormPage())),
            )),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, height: 52, child: OutlinedButton.icon(
              icon: const Icon(Icons.login), label: const Text('Login'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CitizenLoginPage())),
            )),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// CITIZEN REGISTRATION WITH FIREBASE PHONE OTP
// ======================================================

class CitizenRegisterFormPage extends StatefulWidget {
  const CitizenRegisterFormPage({super.key});

  @override
  State<CitizenRegisterFormPage> createState() => _CitizenRegisterFormPageState();
}

class _CitizenRegisterFormPageState extends State<CitizenRegisterFormPage> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final username = TextEditingController();
  final password = TextEditingController();
  final house = TextEditingController();
  final village = TextEditingController();
  final mandal = TextEditingController();
  final district = TextEditingController();
  final otp = TextEditingController();
  String? verificationId;
  int? resendToken;
  bool loading = false;
  bool otpSent = false;
  bool obscurePassword = true;

  String get formattedPhone {
    final value = phone.text.trim().replaceAll(RegExp(r'[^0-9+]'), '');
    if (value.startsWith('+')) return value;
    if (value.length == 10) return '+91$value';
    if (value.startsWith('91') && value.length == 12) return '+$value';
    return '+$value';
  }

  Future<void> sendOtp() async {
    if (name.text.trim().isEmpty || email.text.trim().isEmpty || username.text.trim().isEmpty || password.text.isEmpty || phone.text.trim().isEmpty) {
      showAppMessage(context, 'Please fill all registration fields.'); return;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.text.trim())) {
      showAppMessage(context, 'Enter a valid email address.'); return;
    }
    if (password.text.length < 6) { showAppMessage(context, 'Password must contain at least 6 characters.'); return; }
    if (username.text.trim().contains(' ')) { showAppMessage(context, 'Username must not contain spaces.'); return; }
    final phoneDigits = formattedPhone.replaceAll(RegExp(r'\D'), '');
    if (phoneDigits.length < 10 || phoneDigits.length > 15) { showAppMessage(context, 'Enter a valid phone number with country code.'); return; }

    setState(() => loading = true);
    try {
      final usernameKey = username.text.trim().toLowerCase();
      final existingUsername = await db.collection('citizen_usernames').doc(usernameKey).get();
      if (existingUsername.exists) { throw Exception('This username is already taken.'); }
      // Firebase Auth 7.x does not provide fetchSignInMethodsForEmail.
      // linkWithCredential() below checks whether this email is already in use.

      await auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        timeout: const Duration(seconds: 60),
        forceResendingToken: resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try { await finishRegistration(credential); }
          catch (e) { if (mounted) showAppMessage(context, 'Registration failed: $e'); }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) { setState(() => loading = false); showAppMessage(context, e.message ?? 'Could not send OTP.'); }
        },
        codeSent: (String id, int? token) {
          if (!mounted) return;
          setState(() { verificationId = id; resendToken = token; otpSent = true; loading = false; });
          showAppMessage(context, 'OTP sent to ${formattedPhone}.');
        },
        codeAutoRetrievalTimeout: (String id) { verificationId = id; },
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) { setState(() => loading = false); showAppMessage(context, e.message ?? 'Unable to send OTP.'); }
    } catch (e) {
      if (mounted) { setState(() => loading = false); showAppMessage(context, e.toString().replaceFirst('Exception: ', '')); }
    }
  }

  Future<void> verifyOtp() async {
    if (verificationId == null || otp.text.trim().length < 4) { showAppMessage(context, 'Enter the OTP received on your phone.'); return; }
    setState(() => loading = true);
    try {
      final credential = PhoneAuthProvider.credential(verificationId: verificationId!, smsCode: otp.text.trim());
      await finishRegistration(credential);
    } on FirebaseAuthException catch (e) {
      if (mounted) { setState(() => loading = false); showAppMessage(context, e.message ?? 'OTP verification failed.'); }
    } catch (e) {
      if (mounted) { setState(() => loading = false); showAppMessage(context, 'Registration failed: $e'); }
    }
  }

  Future<void> finishRegistration(PhoneAuthCredential phoneCredential) async {
    final phoneResult = await auth.signInWithCredential(phoneCredential);
    final user = phoneResult.user;
    if (user == null) throw Exception('Phone verification failed.');

    final emailCredential = EmailAuthProvider.credential(email: email.text.trim(), password: password.text);
    try {
      await user.linkWithCredential(emailCredential);
    } on FirebaseAuthException catch (e) {
      if (e.code != 'provider-already-linked') rethrow;
    }

    final key = username.text.trim().toLowerCase();
    final usernameRef = db.collection('citizen_usernames').doc(key);
    final usernameDoc = await usernameRef.get();
    if (usernameDoc.exists && usernameDoc.data()?['uid'] != user.uid) {
      throw Exception('This username is already taken.');
    }

    await db.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': name.text.trim(),
      'mobile': formattedPhone,
      'email': email.text.trim().toLowerCase(),
      'username': username.text.trim(),
      'houseNumber': house.text.trim(),
      'village': village.text.trim(),
      'mandal': mandal.text.trim(),
      'district': district.text.trim(),
      'registrationType': 'firebase_phone_otp',
      'phoneVerified': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await usernameRef.set({'uid': user.uid, 'email': email.text.trim().toLowerCase(), 'username': username.text.trim()});

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomePage()), (route) => false);
  }

  Widget input(String label, TextEditingController controller, {TextInputType type = TextInputType.text, bool secret = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: TextField(controller: controller, keyboardType: type, obscureText: secret,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), prefixIcon: Icon(secret ? Icons.lock : Icons.edit))),
    );
  }

  @override
  void dispose() { name.dispose(); phone.dispose(); email.dispose(); username.dispose(); password.dispose(); house.dispose(); village.dispose(); mandal.dispose(); district.dispose(); otp.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Citizen Registration')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
        const Icon(Icons.person_add_alt_1, size: 58, color: primaryBlue),
        const SizedBox(height: 16),
        input('Name', name),
        input('Phone Number (with country code if outside India)', phone, type: TextInputType.phone),
        input('Email', email, type: TextInputType.emailAddress),
        input('Username', username),
        input('Password', password, secret: true),
        input('House Number (Optional)', house),
        input('Village', village),
        input('Mandal', mandal),
        input('District', district),
        if (otpSent) input('Enter OTP', otp, type: TextInputType.number),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
          onPressed: loading ? null : (otpSent ? verifyOtp : sendOtp),
          child: loading ? const CircularProgressIndicator(color: Colors.white) : Text(otpSent ? 'Verify OTP & Register' : 'Send OTP'),
        )),
        if (otpSent) TextButton(onPressed: loading ? null : sendOtp, child: const Text('Resend OTP')),
      ])),
    );
  }
}

// ======================================================
// CITIZEN LOGIN - USERNAME AND PASSWORD ONLY
// ======================================================

class CitizenLoginPage extends StatefulWidget {
  const CitizenLoginPage({super.key});
  @override
  State<CitizenLoginPage> createState() => _CitizenLoginPageState();
}

class _CitizenLoginPageState extends State<CitizenLoginPage> {
  final username = TextEditingController();
  final password = TextEditingController();
  bool loading = false;

  Future<void> login() async {
    if (username.text.trim().isEmpty || password.text.isEmpty) { showAppMessage(context, 'Enter username and password.'); return; }
    setState(() => loading = true);
    try {
      final key = username.text.trim().toLowerCase();
      final userDoc = await db.collection('citizen_usernames').doc(key).get();
      if (!userDoc.exists) throw Exception('Username not found. Please register first.');
      final data = userDoc.data()!;
      final emailAddress = (data['email'] ?? '').toString();
      if (emailAddress.isEmpty) throw Exception('Account email is missing. Contact support.');
      final result = await auth.signInWithEmailAndPassword(email: emailAddress, password: password.text);
      final profile = await db.collection('users').doc(result.user!.uid).get();
      if (!profile.exists) { await auth.signOut(); throw Exception('Citizen profile not found.'); }
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomePage()), (route) => false);
    } on FirebaseAuthException catch (e) {
      if (mounted) showAppMessage(context, e.code == 'wrong-password' || e.code == 'invalid-credential' ? 'Incorrect username or password.' : (e.message ?? 'Login failed.'));
    } catch (e) {
      if (mounted) showAppMessage(context, e.toString().replaceFirst('Exception: ', ''));
    } finally { if (mounted) setState(() => loading = false); }
  }

  @override
  void dispose() { username.dispose(); password.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Citizen Login')),
    body: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.account_circle, size: 65, color: primaryBlue), const SizedBox(height: 20),
      TextField(controller: username, decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person))),
      const SizedBox(height: 15),
      TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock))),
      const SizedBox(height: 24),
      SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: loading ? null : login,
        child: loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Login'))),
    ])),
  );
}

// ======================================================
// OFFICIAL SELECTION
// ======================================================

class OfficialSelectionPage extends StatelessWidget {
  const OfficialSelectionPage({super.key});

  static const officers = [
    {
      'name': 'Gram Panchayat Officer',
      'role': 'gram_panchayat_officer',
      'description': 'Sarpanch / Panchayat Secretary',
    },
    {
      'name': 'Mandal Officer',
      'role': 'mandal_officer',
      'description': 'Mandal Level',
    },
    {
      'name': 'District Officer',
      'role': 'district_officer',
      'description': 'District Level',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Official Interface')),
      body: ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: officers.length,
        itemBuilder: (context, index) {
          final officer = officers[index];

          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(15),
              leading: const Icon(
                Icons.account_balance,
                color: primaryBlue,
                size: 35,
              ),
              title: Text(
                officer['name']!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(officer['description']!),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OfficialAccessPage(
                      roleName: officer['name']!,
                      roleCode: officer['role']!,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ======================================================
// OFFICIAL REGISTER / LOGIN
// ======================================================

class OfficialAccessPage extends StatelessWidget {
  final String roleName;
  final String roleCode;
  const OfficialAccessPage({super.key, required this.roleName, required this.roleCode});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(roleName)),
    body: Padding(padding: const EdgeInsets.all(22), child: Column(
      mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.account_balance, size: 70, color: primaryBlue),
        const SizedBox(height: 20),
        Text(roleName, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: darkBlue)),
        const SizedBox(height: 28),
        SizedBox(width: double.infinity, height: 52, child: ElevatedButton.icon(
          icon: const Icon(Icons.person_add), label: const Text('Register'),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OfficialRegisterPage(roleName: roleName, roleCode: roleCode))),
        )),
        const SizedBox(height: 15),
        SizedBox(width: double.infinity, height: 52, child: OutlinedButton.icon(
          icon: const Icon(Icons.login), label: const Text('Login'),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OfficialLoginPage(roleName: roleName, roleCode: roleCode))),
        )),
      ],
    )),
  );
}

class OfficialRegisterPage extends StatefulWidget {
  final String roleName, roleCode;
  const OfficialRegisterPage({super.key, required this.roleName, required this.roleCode});
  @override
  State<OfficialRegisterPage> createState() => _OfficialRegisterPageState();
}

class _OfficialRegisterPageState extends State<OfficialRegisterPage> {
  final name = TextEditingController();
  final mobile = TextEditingController();
  final employeeId = TextEditingController();
  final department = TextEditingController();
  final designation = TextEditingController();
  final village = TextEditingController();
  final mandal = TextEditingController();
  final district = TextEditingController();
  final email = TextEditingController();
  final username = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  final otp = TextEditingController();

  String? verificationId;
  int? resendToken;
  bool loading = false;
  bool otpSent = false;
  bool finishingRegistration = false;

  String get formattedMobile {
    final value = mobile.text.trim().replaceAll(RegExp(r'[^0-9+]'), '');
    if (value.startsWith('+')) return value;
    if (value.length == 10) return '+91$value';
    if (value.startsWith('91') && value.length == 12) return '+$value';
    return '+$value';
  }

  bool validateFields() {
    if ([name, mobile, employeeId, department, designation, district, email,
        username, password, confirm].any((c) => c.text.trim().isEmpty) ||
        (widget.roleCode == 'gram_panchayat_officer' &&
            (village.text.trim().isEmpty || mandal.text.trim().isEmpty)) ||
        (widget.roleCode == 'mandal_officer' && mandal.text.trim().isEmpty)) {
      showAppMessage(context, 'Please fill all required fields.');
      return false;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.text.trim())) {
      showAppMessage(context, 'Enter a valid email address.');
      return false;
    }
    final digits = formattedMobile.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10 || digits.length > 15) {
      showAppMessage(context, 'Enter a valid mobile number.');
      return false;
    }
    if (password.text.length < 6) {
      showAppMessage(context, 'Password must contain at least 6 characters.');
      return false;
    }
    if (password.text != confirm.text) {
      showAppMessage(context, 'Passwords do not match.');
      return false;
    }
    if (username.text.trim().contains(' ')) {
      showAppMessage(context, 'Username must not contain spaces.');
      return false;
    }
    return true;
  }

  Future<void> sendOtp() async {
    if (!validateFields()) return;
    setState(() => loading = true);
    try {
      final key = username.text.trim().toLowerCase();
      final existingUsername = await db.collection('official_usernames').doc(key).get();
      if (existingUsername.exists) throw Exception('Username already exists. Please choose another.');

      await auth.verifyPhoneNumber(
        phoneNumber: formattedMobile,
        timeout: const Duration(seconds: 60),
        forceResendingToken: resendToken,
        verificationCompleted: (PhoneAuthCredential phoneCredential) async {
          await finishRegistration(phoneCredential);
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;
          setState(() => loading = false);
          showAppMessage(context, 'OTP could not be sent: ${e.message ?? e.code}');
        },
        codeSent: (String id, int? token) {
          if (!mounted) return;
          setState(() {
            verificationId = id;
            resendToken = token;
            otpSent = true;
            loading = false;
          });
          showAppMessage(context, 'OTP sent to $formattedMobile.');
        },
        codeAutoRetrievalTimeout: (String id) {
          verificationId = id;
        },
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      showAppMessage(context, 'OTP error: ${e.message ?? e.code}');
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      showAppMessage(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> verifyOtp() async {
    if (verificationId == null) {
      showAppMessage(context, 'Tap Send OTP first.');
      return;
    }
    if (otp.text.trim().length < 6) {
      showAppMessage(context, 'Enter the 6-digit OTP.');
      return;
    }
    setState(() => loading = true);
    try {
      final phoneCredential = PhoneAuthProvider.credential(
        verificationId: verificationId!,
        smsCode: otp.text.trim(),
      );
      await finishRegistration(phoneCredential);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      showAppMessage(context, 'OTP verification failed: ${e.message ?? e.code}');
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      showAppMessage(context, 'Registration failed: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  Future<void> finishRegistration(PhoneAuthCredential phoneCredential) async {
    if (finishingRegistration) return;
    finishingRegistration = true;
    if (mounted) setState(() => loading = true);
    UserCredential? account;
    try {
      // Create the official account only after the phone OTP has been verified.
      account = await auth.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text,
      );
      final user = account.user;
      if (user == null) throw Exception('Could not create the official account.');

      // Link the verified phone number to this Email/Password account.
      await user.linkWithCredential(phoneCredential);

      final key = username.text.trim().toLowerCase();
      final usernameRef = db.collection('official_usernames').doc(key);
      final latestUsername = await usernameRef.get();
      if (latestUsername.exists) throw Exception('Username already exists. Please choose another.');

      final data = <String, dynamic>{
        'uid': user.uid,
        'name': name.text.trim(),
        'mobile': formattedMobile,
        'phoneVerified': true,
        'employeeId': employeeId.text.trim(),
        'department': department.text.trim(),
        'designation': designation.text.trim(),
        'village': village.text.trim(),
        'mandal': mandal.text.trim(),
        'district': district.text.trim(),
        'email': email.text.trim().toLowerCase(),
        'username': username.text.trim(),
        'role': widget.roleCode,
        'roleName': widget.roleName,
        'createdAt': FieldValue.serverTimestamp(),
      };
      await db.collection('officials').doc(user.uid).set(data);
      await usernameRef.set({
        'uid': user.uid,
        'email': email.text.trim().toLowerCase(),
        'username': username.text.trim(),
        'role': widget.roleCode,
      });

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => OfficialDashboardPage(
          roleName: widget.roleName,
          roleCode: widget.roleCode,
          officialData: data,
        )),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (account?.user != null) {
        try { await account!.user!.delete(); } catch (_) {}
      }
      if (mounted) showAppMessage(context, 'Registration failed: ${e.message ?? e.code}');
    } catch (e) {
      if (account?.user != null) {
        try { await account!.user!.delete(); } catch (_) {}
      }
      if (mounted) showAppMessage(context, 'Registration failed: ${e.toString().replaceFirst('Exception: ', '')}');
    } finally {
      finishingRegistration = false;
      if (mounted) setState(() => loading = false);
    }
  }

  Widget field(String label, TextEditingController controller,
      {bool secret = false, TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: TextField(
        controller: controller,
        obscureText: secret,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in [name, mobile, employeeId, department, designation,
      village, mandal, district, email, username, password, confirm, otp]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Official Registration')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(children: [
        Text(widget.roleName, style: const TextStyle(
          fontSize: 20, fontWeight: FontWeight.bold, color: darkBlue,
        )),
        const SizedBox(height: 16),
        field('Full Name', name),
        field('Mobile Number', mobile, type: TextInputType.phone),
        field('Government Employee ID Number', employeeId),
        field('Department', department),
        field('Designation', designation),
        if (widget.roleCode == 'gram_panchayat_officer') field('Village', village),
        if (widget.roleCode != 'district_officer') field('Mandal', mandal),
        field('District', district),
        field('Email', email, type: TextInputType.emailAddress),
        field('Username', username),
        field('Password', password, secret: true),
        field('Confirm Password', confirm, secret: true),
        if (otpSent) ...[
          field('Enter 6-digit OTP', otp, type: TextInputType.number),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: loading ? null : verifyOtp,
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Verify OTP & Register'),
            ),
          ),
          TextButton(
            onPressed: loading ? null : sendOtp,
            child: const Text('Resend OTP'),
          ),
        ] else ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: loading ? null : sendOtp,
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Send OTP'),
            ),
          ),
        ],
      ]),
    ),
  );
}

class OfficialLoginPage extends StatefulWidget {
  final String roleName, roleCode;
  const OfficialLoginPage({super.key, required this.roleName, required this.roleCode});
  @override State<OfficialLoginPage> createState() => _OfficialLoginPageState();
}
class _OfficialLoginPageState extends State<OfficialLoginPage> {
  final username = TextEditingController(), password = TextEditingController();
  bool loading = false;
  Future<void> login() async {
    if (username.text.trim().isEmpty || password.text.isEmpty) { showAppMessage(context, 'Enter username and password.'); return; }
    setState(() => loading = true);
    try {
      final record = await db.collection('official_usernames').doc(username.text.trim().toLowerCase()).get();
      if (!record.exists) throw Exception('Username not found. Please register first.');
      final emailAddress = (record.data()?['email'] ?? '').toString();
      final result = await auth.signInWithEmailAndPassword(email: emailAddress, password: password.text);
      final doc = await db.collection('officials').doc(result.user!.uid).get();
      final data = doc.data();
      if (!doc.exists || data == null || data['role'] != widget.roleCode) { await auth.signOut(); throw Exception('This account is not registered for ${widget.roleName}.'); }
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => OfficialDashboardPage(roleName: widget.roleName, roleCode: widget.roleCode, officialData: data)), (route) => false);
    } on FirebaseAuthException catch (e) { if (mounted) showAppMessage(context, e.code == 'invalid-credential' ? 'Incorrect username or password.' : (e.message ?? 'Login failed.')); }
    catch (e) { if (mounted) showAppMessage(context, e.toString().replaceFirst('Exception: ', '')); }
    finally { if (mounted) setState(() => loading = false); }
  }
  @override void dispose() { username.dispose(); password.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text('${widget.roleName} Login')), body: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.account_circle, size: 68, color: primaryBlue), const SizedBox(height: 20),
    TextField(controller: username, decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person))), const SizedBox(height: 15),
    TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock))), const SizedBox(height: 24),
    SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: loading ? null : login, child: loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Login'))),
  ])));
}

// ======================================================
// PICTURE CARD
// ======================================================

class PictureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final VoidCallback onTap;

  const PictureCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: Image.asset(
                  imageUrl, fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(color: lightBlue, child: const Center(child: Icon(Icons.image_not_supported, size: 45, color: primaryBlue))),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: darkBlue,
                    ),
                  ),
                  Text(subtitle, textAlign: TextAlign.center),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// CITIZEN HOME
// ======================================================

// ======================================================
// CATEGORY DATA
// ======================================================

class GramCategory {
  final String name;
  final String telugu;
  final String image;
  final List<Map<String, String>> subcategories;

  const GramCategory({
    required this.name,
    required this.telugu,
    required this.image,
    required this.subcategories,
  });
}

const List<GramCategory> gramCategories = [
  GramCategory(
    name: 'Roads',
    telugu: 'రోడ్లు',
    image: 'assets/images/roads.jpg',
    subcategories: [
      {
        'name': 'Damaged Roads',
        'image': 'assets/images/roads/damaged_roads.jpg',
      },
      {
        'name': 'Potholes',
        'image': 'assets/images/roads/potholes.jpg',
      },
      {
        'name': 'Roads Not Constructed',
        'image': 'assets/images/roads/roads_not_constructed.jpg',
      },
      {
        'name': 'Broken Bridges',
        'image': 'assets/images/roads/broken_bridges.jpg',
      },
      {
        'name': 'Water Stagnation',
        'image': 'assets/images/roads/water_stagnation.jpg',
      },
      {
        'name': 'Road Repair',
        'image': 'assets/images/roads/road_repair.jpg',
      },
      {
        'name': 'Other Road Problems',
        'image': 'assets/images/roads/other_road_problems.jpg',
      },
    ],
  ),
  GramCategory(
    name: 'Water',
    telugu: 'నీరు',
    image: 'assets/images/water.jpg',
    subcategories: [
      {
        'name': 'Water Supply',
        'image': 'assets/images/water/water_supply.jpg',
      },
      {
        'name': 'Pipeline Leakage',
        'image': 'assets/images/water/pipeline_leakage.jpg',
      },
      {
        'name': 'Drinking Water Quality',
        'image': 'assets/images/water/drinking_water_quality.jpg',
      },
      {
        'name': 'Hand Pumps',
        'image': 'assets/images/water/hand_pumps.jpg',
      },
      {
        'name': 'Borewells',
        'image': 'assets/images/water/borewells.jpg',
      },
      {
        'name': 'Water Tanks',
        'image': 'assets/images/water/water_tanks.jpg',
      },
    ],
  ),
  GramCategory(
    name: 'Electricity',
    telugu: 'విద్యుత్',
    image: 'assets/images/electricity.jpg',
    subcategories: [
      {
        'name': 'Power Cuts',
        'image': 'assets/images/electricity/power_cuts.jpg',
      },
      {
        'name': 'Street Lights',
        'image': 'assets/images/electricity/street_lights.jpg',
      },
      {
        'name': 'Damaged Poles',
        'image': 'assets/images/electricity/damaged_poles.jpg',
      },
      {
        'name': 'Broken Wires',
        'image': 'assets/images/electricity/broken_wires.jpg',
      },
      {
        'name': 'Transformer Problems',
        'image': 'assets/images/electricity/transformer_problems.jpg',
      },
    ],
  ),
  GramCategory(
    name: 'Sanitation',
    telugu: 'పారిశుధ్యం',
    image: 'assets/images/sanitation.jpg',
    subcategories: [
      {
        'name': 'Garbage Collection',
        'image': 'assets/images/sanitation/garbage_collection.jpg',
      },
      {
        'name': 'Drainage',
        'image': 'assets/images/sanitation/drainage.jpg',
      },
      {
        'name': 'Open Drains',
        'image': 'assets/images/sanitation/open_drains.jpg',
      },
      {
        'name': 'Sewage',
        'image': 'assets/images/sanitation/sewage.jpg',
      },
      {
        'name': 'Public Toilets',
        'image': 'assets/images/sanitation/public_toilets.jpg',
      },
      {
        'name': 'Cleanliness',
        'image': 'assets/images/sanitation/cleanliness.jpg',
      },
    ],
  ),
  GramCategory(
    name: 'Education',
    telugu: 'విద్య',
    image: 'assets/images/education.jpg',
    subcategories: [
      {
        'name': 'School Buildings',
        'image': 'assets/images/education/school_buildings.jpg',
      },
      {
        'name': 'Teachers',
        'image': 'assets/images/education/teachers.jpg',
      },
      {
        'name': 'Drinking Water',
        'image': 'assets/images/education/drinking_water.jpg',
      },
      {
        'name': 'School Toilets',
        'image': 'assets/images/education/school_toilets.jpg',
      },
      {
        'name': 'Classrooms',
        'image': 'assets/images/education/classrooms.jpg',
      },
      {
        'name': 'School Facilities',
        'image': 'assets/images/education/school_facilities.jpg',
      },
    ],
  ),
  GramCategory(
    name: 'Health',
    telugu: 'ఆరోగ్యం',
    image: 'assets/images/health.jpg',
    subcategories: [
      {
        'name': 'PHC Facilities',
        'image': 'assets/images/health/phc_facilities.jpg',
      },
      {
        'name': 'Medicines',
        'image': 'assets/images/health/medicines.jpg',
      },
      {
        'name': 'Medical Staff',
        'image': 'assets/images/health/medical_staff.jpg',
      },
      {
        'name': 'Ambulance',
        'image': 'assets/images/health/ambulance.jpg',
      },
      {
        'name': 'Cleanliness',
        'image': 'assets/images/sanitation/cleanliness.jpg',
      },
      {
        'name': 'Health Services',
        'image': 'assets/images/health/health_services.jpg',
      },
    ],
  ),
  GramCategory(
    name: 'Agriculture',
    telugu: 'వ్యవసాయం',
    image: 'assets/images/agriculture.jpg',
    subcategories: [
      {
        'name': 'Irrigation',
        'image': 'assets/images/agriculture/irrigation.jpg',
      },
      {
        'name': 'Crop Damage',
        'image': 'assets/images/agriculture/crop_damage.jpg',
      },
      {
        'name': 'Seeds',
        'image': 'assets/images/agriculture/seeds.jpg',
      },
      {
        'name': 'Fertilizers',
        'image': 'assets/images/agriculture/fertilizers.jpg',
      },
      {
        'name': 'Agricultural Roads',
        'image': 'assets/images/agriculture/agricultural_roads.jpg',
      },
      {
        'name': 'Farm Water Supply',
        'image': 'assets/images/agriculture/farm_water_supply.jpg',
      },
    ],
  ),
  GramCategory(
    name: 'Public Facilities',
    telugu: 'ప్రజా సదుపాయాలు',
    image: 'assets/images/public_facilities.jpg',
    subcategories: [
      {
        'name': 'Bus Shelters',
        'image': 'assets/images/public_facilities/bus_shelters.jpg',
      },
      {
        'name': 'Community Halls',
        'image': 'assets/images/public_facilities/community_halls.jpg',
      },
      {
        'name': 'Public Parks',
        'image': 'assets/images/public_facilities/public_parks.jpg',
      },
      {
        'name': 'Playgrounds',
        'image': 'assets/images/public_facilities/playgrounds.jpg',
      },
      {
        'name': 'Public Buildings',
        'image': 'assets/images/public_facilities/public_buildings.jpg',
      },
    ],
  ),
  GramCategory(
    name: 'Rural Development',
    telugu: 'గ్రామీణ అభివృద్ధి',
    image: 'assets/images/rural_development.jpg',
    subcategories: [
      {
        'name': 'Incomplete Works',
        'image': 'assets/images/rural_development/incomplete_works.jpg',
      },
      {
        'name': 'Government Schemes',
        'image': 'assets/images/rural_development/government_schemes.jpg',
      },
      {
        'name': 'Public Assets',
        'image': 'assets/images/rural_development/public_assets.jpg',
      },
      {
        'name': 'Village Development Projects',
        'image': 'assets/images/rural_development/village_development_projects.jpg',
      },
    ],
  ),
];

// ======================================================
// CITIZEN HOME
// ======================================================

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> logout(BuildContext context) async {
    await auth.signOut();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GRAM SEVA'),
        actions: [
          IconButton(
            tooltip: 'My Complaints',
            icon: const Icon(Icons.track_changes),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyComplaintsPage()),
              );
            },
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () => logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            color: lightBlue,
            child: Column(
              children: [
                const Text(
                  'Mana Ooru - Mana Badhyatha',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: darkBlue,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Village Development and Complaint Portal',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Select Your Problem Category',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.track_changes),
                    label: const Text('Track My Complaints'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyComplaintsPage(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: gramCategories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.82,
              ),
              itemBuilder: (context, index) {
                final category = gramCategories[index];

                return PictureCard(
                  title: category.name,
                  subtitle: category.telugu,
                  imageUrl: category.image,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CategorySubcategoryPage(category: category),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================
// CATEGORY SUBCATEGORIES WITH IMAGES
// ======================================================

class CategorySubcategoryPage extends StatelessWidget {
  final GramCategory category;

  const CategorySubcategoryPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${category.name} Problems')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: lightBlue,
            padding: const EdgeInsets.all(15),
            child: Text(
              'Select a ${category.name} problem',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: darkBlue,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: category.subcategories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.82,
              ),
              itemBuilder: (context, index) {
                final item = category.subcategories[index];

                return PictureCard(
                  title: item['name']!,
                  subtitle: 'Select Problem',
                  imageUrl: item['image']!,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ComplaintFormPage(
                          problem: '${category.name} - ${item['name']}',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================
// COMPLAINT FORM
// ======================================================

class ComplaintFormPage extends StatefulWidget {
  final String problem;

  const ComplaintFormPage({super.key, required this.problem});

  @override
  State<ComplaintFormPage> createState() => _ComplaintFormPageState();
}

class _ComplaintFormPageState extends State<ComplaintFormPage> {
  final description = TextEditingController();
  final location = TextEditingController();
  final ImagePicker picker = ImagePicker();
  final List<XFile> selectedPhotos = [];

  bool loading = false;

  Future<void> addPhoto(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        final photo = await picker.pickImage(source: source, imageQuality: 75, maxWidth: 1600);
        if (photo != null && mounted) setState(() => selectedPhotos.add(photo));
      } else {
        final photos = await picker.pickMultiImage(imageQuality: 75, maxWidth: 1600);
        if (mounted && photos.isNotEmpty) setState(() => selectedPhotos.addAll(photos));
      }
    } catch (e) { if (mounted) showAppMessage(context, 'Could not open camera/gallery: $e'); }
  }

  Future<void> submitComplaint() async {
    if (description.text.trim().isEmpty) {
      showAppMessage(context, 'Please describe your problem.');
      return;
    }

    final user = auth.currentUser;

    if (user == null) {
      showAppMessage(context, 'Please login first.');
      return;
    }

    setState(() => loading = true);

    try {
      final userDoc = await db.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        showAppMessage(context, 'Citizen profile not found. Register again.');
        return;
      }

      final userData = userDoc.data()!;
      final photoUrls = <String>[];
      for (var i = 0; i < selectedPhotos.length; i++) {
        final file = File(selectedPhotos[i].path);
        final ref = FirebaseStorage.instance.ref().child('complaint_photos/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
        final task = await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
        photoUrls.add(await task.ref.getDownloadURL());
      }

      await db.collection('complaints').add({
        'citizenUid': user.uid,
        'citizenName': userData['name'] ?? '',
        'citizenMobile': userData['mobile'] ?? '',
        'village': userData['village'] ?? '',
        'mandal': userData['mandal'] ?? '',
        'district': userData['district'] ?? '',
        'category': widget.problem,
        'description': description.text.trim(),
        'location': location.text.trim(),
        'photoUrls': photoUrls,
        'status': 'Pending',
        'citizenConfirmation': 'Waiting',
        'currentLevel': 'Village',
        'assignedRole': 'gram_panchayat_officer',
        'escalationCount': 0,
        'escalationHistory': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'nextEscalationAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 5)),
        ),
      });

      if (!mounted) return;

      showAppMessage(context, 'Complaint submitted successfully!');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      showAppMessage(context, 'Submission failed: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    description.dispose();
    location.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.problem)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Problem: ${widget.problem}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: darkBlue,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: location,
              decoration: const InputDecoration(
                labelText: 'Problem Location',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: description,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Describe Your Problem',
                hintText: 'Explain the problem here...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Align(alignment: Alignment.centerLeft, child: Text('Attach Complaint Photos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkBlue))),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: OutlinedButton.icon(onPressed: loading ? null : () => addPhoto(ImageSource.camera), icon: const Icon(Icons.camera_alt), label: const Text('Take Photo'))),
              const SizedBox(width: 10),
              Expanded(child: OutlinedButton.icon(onPressed: loading ? null : () => addPhoto(ImageSource.gallery), icon: const Icon(Icons.photo_library), label: const Text('Gallery'))),
            ]),
            if (selectedPhotos.isNotEmpty) SizedBox(height: 115, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: selectedPhotos.length, separatorBuilder: (_, __) => const SizedBox(width: 10), itemBuilder: (context, index) => Stack(children: [
              ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(selectedPhotos[index].path), width: 105, height: 105, fit: BoxFit.cover)),
              Positioned(right: 2, top: 2, child: InkWell(onTap: loading ? null : () => setState(() => selectedPhotos.removeAt(index)), child: const CircleAvatar(radius: 13, backgroundColor: Colors.red, child: Icon(Icons.close, size: 16, color: Colors.white)))),
            ]))),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : submitComplaint,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Complaint'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// MY COMPLAINTS
// ======================================================

// ======================================================
// MY COMPLAINTS
// ======================================================

class MyComplaintsPage extends StatelessWidget {
  const MyComplaintsPage({super.key});

  Color statusColor(String status) {
    switch (status) {
      case 'Closed':
        return Colors.green;
      case 'In Progress':
        return Colors.orange;
      case 'Pending':
        return Colors.red;
      case 'Awaiting Citizen Confirmation':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String formatDate(dynamic value) {
    if (value == null) return 'Not available';

    try {
      final date = (value as Timestamp).toDate();
      return '${date.day}/${date.month}/${date.year} '
          '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return 'Not available';
    }
  }

  Widget buildTimeline(Map<String, dynamic> data) {
    final currentLevel = data['currentLevel']?.toString() ?? 'Village';

    final history = data['escalationHistory'] is List
        ? data['escalationHistory'] as List
        : [];

    DateTime? escalationDate(String stage) {
      for (final item in history) {
        if (item is! Map) continue;

        final level = item['level']?.toString() ?? '';
        final value = item['escalatedAt'];

        if (value is! Timestamp) continue;

        if (stage == 'Village' && level == 'Mandal') {
          return value.toDate();
        }

        if (stage == 'Mandal' && level == 'District') {
          return value.toDate();
        }
      }
      return null;
    }

    final stages = [
      {'name': 'Village Level', 'level': 'Village'},
      {'name': 'Mandal Level', 'level': 'Mandal'},
      {'name': 'District Level', 'level': 'District'},
    ];

    final currentIndex = currentLevel == 'District'
        ? 2
        : currentLevel == 'Mandal'
        ? 1
        : 0;

    return Card(
      color: lightBlue,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Complaint Escalation Timeline',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: darkBlue,
              ),
            ),
            const SizedBox(height: 15),
            ...List.generate(stages.length, (index) {
              final stage = stages[index];
              final level = stage['level']!;
              final completed = index < currentIndex;
              final current = index == currentIndex;
              final date = escalationDate(level);

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Icon(
                        completed
                            ? Icons.check_circle
                            : current
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: completed || current ? primaryBlue : Colors.grey,
                      ),
                      if (index != 2)
                        Container(
                          width: 2,
                          height: 45,
                          color: completed ? primaryBlue : Colors.grey,
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 25),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stage['name']!,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: completed || current
                                  ? darkBlue
                                  : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            completed
                                ? 'Escalated on ${date == null ? 'Date unavailable' : formatDate(Timestamp.fromDate(date))}'
                                : current
                                ? 'Currently handling your complaint'
                                : 'Waiting for escalation',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
            const Divider(),
            Text(
              'Escalation Count: ${data['escalationCount'] ?? 0}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> respondToComplaint(
    BuildContext context,
    String complaintId,
    bool confirmed,
  ) async {
    try {
      if (confirmed) {
        await db.collection('complaints').doc(complaintId).update({
          'citizenConfirmation': 'Confirmed',
          'citizenFeedback': 'Citizen confirmed that the problem is resolved.',
          'status': 'Closed',
          'closedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'nextEscalationAt': null,
        });
      } else {
        await db.collection('complaints').doc(complaintId).update({
          'citizenConfirmation': 'Not Resolved',
          'citizenFeedback':
              'Citizen reported that the problem is not resolved.',
          'status': 'In Progress',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (!context.mounted) return;

      showAppMessage(
        context,
        confirmed
            ? 'Complaint closed successfully.'
            : 'Complaint returned for further action.',
      );
    } catch (e) {
      if (!context.mounted) return;
      showAppMessage(context, 'Error: $e');
    }
  }

  Widget complaintCard(BuildContext context, DocumentSnapshot document) {
    final data = document.data() as Map<String, dynamic>;
    final status = data['status'] ?? 'Pending';
    final confirmation = data['citizenConfirmation'] ?? 'Waiting';

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['category'] ?? 'Complaint',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: darkBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text('Description: ${data['description'] ?? ''}'),
            Text('Village: ${data['village'] ?? ''}'),
            Text('Mandal: ${data['mandal'] ?? ''}'),
            Text('District: ${data['district'] ?? ''}'),
            const SizedBox(height: 8),
            Text(
              'Status: $status',
              style: TextStyle(
                color: statusColor(status),
                fontWeight: FontWeight.bold,
              ),
            ),
            Text('Submitted: ${formatDate(data['createdAt'])}'),
            const SizedBox(height: 15),
            buildTimeline(data),
            const Divider(height: 25),
            Text(
              'Officer Remarks: ${data['officerRemarks'] ?? 'No remarks yet'}',
            ),
            const SizedBox(height: 8),
            Text('Citizen Confirmation: $confirmation'),
            if (status == 'Awaiting Citizen Confirmation') ...[
              const SizedBox(height: 12),
              const Text(
                'The officer marked this complaint as resolved. '
                'Please confirm whether the problem is actually solved.',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          respondToComplaint(context, document.id, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Yes, Solved'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          respondToComplaint(context, document.id, false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Not Solved'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = auth.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Complaints')),
        body: const Center(child: Text('Please login first.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Complaints')),
      body: StreamBuilder<QuerySnapshot>(
        stream: db
            .collection('complaints')
            .where('citizenUid', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No complaints submitted yet.'));
          }

          final docs = snapshot.data!.docs.toList();

          docs.sort((a, b) {
            final first = a.data() as Map<String, dynamic>;
            final second = b.data() as Map<String, dynamic>;

            final firstDate = first['createdAt'] is Timestamp
                ? (first['createdAt'] as Timestamp).toDate()
                : DateTime(2000);

            final secondDate = second['createdAt'] is Timestamp
                ? (second['createdAt'] as Timestamp).toDate()
                : DateTime(2000);

            return secondDate.compareTo(firstDate);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              return complaintCard(context, docs[index]);
            },
          );
        },
      ),
    );
  }
}

// ======================================================
// OFFICIAL DASHBOARD
// ======================================================

class OfficialDashboardPage extends StatelessWidget {
  final String roleName;
  final String roleCode;
  final Map<String, dynamic> officialData;

  const OfficialDashboardPage({
    super.key,
    required this.roleName,
    required this.roleCode,
    required this.officialData,
  });

  // IMPORTANT:
  // Do not filter by assignedRole/currentLevel here.
  // Each officer must see all complaints in their area.

  Query<Map<String, dynamic>> complaintQuery() {
    Query<Map<String, dynamic>> query = db.collection('complaints');

    if (roleCode == 'gram_panchayat_officer') {
      query = query
          .where('village', isEqualTo: officialData['village'])
          .where('mandal', isEqualTo: officialData['mandal'])
          .where('district', isEqualTo: officialData['district']);
    } else if (roleCode == 'mandal_officer') {
      query = query
          .where('mandal', isEqualTo: officialData['mandal'])
          .where('district', isEqualTo: officialData['district']);
    } else if (roleCode == 'district_officer') {
      query = query.where('district', isEqualTo: officialData['district']);
    }

    return query;
  }

  Future<void> logout(BuildContext context) async {
    await auth.signOut();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(roleName),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: lightBlue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Officer: ${officialData['name'] ?? ''}',
                  style: const TextStyle(
                    color: darkBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Village: ${officialData['village'] ?? '-'}',
                  style: const TextStyle(color: darkBlue),
                ),
                Text(
                  'Mandal: ${officialData['mandal'] ?? '-'}',
                  style: const TextStyle(color: darkBlue),
                ),
                Text(
                  'District: ${officialData['district'] ?? '-'}',
                  style: const TextStyle(color: darkBlue),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Showing all complaints in your area, '
                  'including escalated and closed complaints.',
                  style: TextStyle(color: darkBlue, fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: complaintQuery().snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Could not load complaints.\n'
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No complaints found in your area.'),
                  );
                }

                // Show ALL statuses. Do not remove Closed,
                // Awaiting Citizen Confirmation or escalated cases.
                final complaints = snapshot.data!.docs.toList();

                complaints.sort((a, b) {
                  final first = a.data()['createdAt'];
                  final second = b.data()['createdAt'];

                  final firstDate = first is Timestamp
                      ? first.toDate()
                      : DateTime(2000);

                  final secondDate = second is Timestamp
                      ? second.toDate()
                      : DateTime(2000);

                  return secondDate.compareTo(firstDate);
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: complaints.length,
                  itemBuilder: (context, index) {
                    return OfficialComplaintCard(
                      document: complaints[index],
                      roleCode: roleCode,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================
// OFFICIAL COMPLAINT CARD
// ======================================================

class OfficialComplaintCard extends StatefulWidget {
  final DocumentSnapshot document;
  final String roleCode;

  const OfficialComplaintCard({
    super.key,
    required this.document,
    required this.roleCode,
  });

  @override
  State<OfficialComplaintCard> createState() => _OfficialComplaintCardState();
}

class _OfficialComplaintCardState extends State<OfficialComplaintCard> {
  final remarks = TextEditingController();
  bool loading = false;

  // Only the officer currently assigned to this complaint
  // can update its status.
  bool canCurrentOfficerManage(Map<String, dynamic> data) {
    final assignedRole = data['assignedRole']?.toString() ?? '';
    final currentLevel = data['currentLevel']?.toString() ?? '';
    final status = data['status']?.toString() ?? 'Pending';

    String expectedLevel;

    if (widget.roleCode == 'gram_panchayat_officer') {
      expectedLevel = 'Village';
    } else if (widget.roleCode == 'mandal_officer') {
      expectedLevel = 'Mandal';
    } else if (widget.roleCode == 'district_officer') {
      expectedLevel = 'District';
    } else {
      return false;
    }

    final isAssignedOfficer =
        assignedRole == widget.roleCode && currentLevel == expectedLevel;

    final isEditableStatus =
        status != 'Closed' && status != 'Awaiting Citizen Confirmation';

    return isAssignedOfficer && isEditableStatus;
  }

  Future<void> updateStatus(String newStatus) async {
    if (loading) return;

    final data = widget.document.data() as Map<String, dynamic>;

    if (!canCurrentOfficerManage(data)) {
      showAppMessage(
        context,
        'You can only view this complaint. '
        'It is not currently assigned to your level.',
      );
      return;
    }

    setState(() => loading = true);

    try {
      if (newStatus == 'Resolved') {
        await widget.document.reference.update({
          'status': 'Awaiting Citizen Confirmation',
          'citizenConfirmation': 'Waiting',
          'officerRemarks': remarks.text.trim(),
          'resolvedBy': widget.roleCode,
          'resolvedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'nextEscalationAt': null,
        });
      } else {
        await widget.document.reference.update({
          'status': newStatus,
          'officerRemarks': remarks.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      showAppMessage(context, 'Complaint updated successfully.');
    } catch (e) {
      if (!mounted) return;
      showAppMessage(context, 'Update failed: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    remarks.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.document.data() as Map<String, dynamic>;

    final status = data['status'] ?? 'Pending';
    final level = data['currentLevel'] ?? 'Village';
    final assignedRole = data['assignedRole']?.toString() ?? '';

    final canManage = canCurrentOfficerManage(data);

    final isClosed = status == 'Closed';
    final isAwaiting = status == 'Awaiting Citizen Confirmation';

    String assignedLevelText;

    switch (assignedRole) {
      case 'gram_panchayat_officer':
        assignedLevelText = 'Gram Panchayat Officer';
        break;
      case 'mandal_officer':
        assignedLevelText = 'Mandal Officer';
        break;
      case 'district_officer':
        assignedLevelText = 'District Officer';
        break;
      default:
        assignedLevelText = 'Not specified';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['category'] ?? 'Complaint',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: darkBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text('Complaint ID: ${widget.document.id}'),
            Text('Citizen: ${data['citizenName'] ?? ''}'),
            Text('Mobile: ${data['citizenMobile'] ?? ''}'),
            Text('Village: ${data['village'] ?? ''}'),
            Text('Mandal: ${data['mandal'] ?? ''}'),
            Text('District: ${data['district'] ?? ''}'),
            Text('Location: ${data['location'] ?? ''}'),
            const SizedBox(height: 8),
            Text('Problem: ${data['description'] ?? ''}'),
            const SizedBox(height: 8),
            Text(
              'Current Level: $level',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Currently Assigned To: $assignedLevelText'),
            Text(
              'Status: $status',
              style: TextStyle(
                color: isClosed
                    ? Colors.green
                    : isAwaiting
                    ? Colors.purple
                    : status == 'In Progress'
                    ? Colors.orange
                    : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text('Escalation Count: ${data['escalationCount'] ?? 0}'),
            const SizedBox(height: 12),

            // Only the currently assigned officer can edit.
            if (canManage) ...[
              TextField(
                controller: remarks,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Officer Remarks',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: loading
                        ? null
                        : () => updateStatus('In Progress'),
                    child: const Text('In Progress'),
                  ),
                  ElevatedButton(
                    onPressed: loading ? null : () => updateStatus('Resolved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Mark Resolved'),
                  ),
                ],
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: lightBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isClosed
                      ? 'This complaint is closed. You can view its history.'
                      : isAwaiting
                      ? 'Waiting for citizen confirmation. '
                            'You can view this complaint.'
                      : 'Read-only: This complaint is currently '
                            'handled by $assignedLevelText.',
                  style: const TextStyle(
                    color: darkBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Officer Remarks: '
                '${data['officerRemarks'] ?? 'No remarks yet'}',
              ),
              Text(
                'Citizen Confirmation: '
                '${data['citizenConfirmation'] ?? 'Waiting'}',
              ),
            ],

            if (loading) ...[
              const SizedBox(height: 10),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
}
