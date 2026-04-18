import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String backendBaseUrl = 'http://10.0.2.2:5000';

void main() {
  runApp(const BloodDonationApp());
}

class BloodDonationApp extends StatelessWidget {
  const BloodDonationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Blood Donation',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late final ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(baseUrl: backendBaseUrl);
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      DashboardPage(apiService: _apiService),
      RegisterDonorPage(apiService: _apiService),
      RequestBloodPage(apiService: _apiService),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Blood Donation App')),
      body: SafeArea(child: pages[_selectedIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.volunteer_activism), label: 'Donor'),
          NavigationDestination(icon: Icon(Icons.bloodtype), label: 'Request'),
        ],
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.apiService});

  final ApiService apiService;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<DashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.apiService.fetchDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DashboardData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final data = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () async {
            setState(() => _future = widget.apiService.fetchDashboard());
            await _future;
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  title: const Text('Total Donors'),
                  subtitle: Text('${data.donors.length}'),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Blood Requests'),
                  subtitle: Text('${data.requests.length}'),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Recent Donors', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...data.donors.take(5).map(
                (donor) => Card(
                  child: ListTile(
                    title: Text(donor.name),
                    subtitle: Text('${donor.bloodGroup} | ${donor.city}'),
                    trailing: Text(donor.phone),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class RegisterDonorPage extends StatefulWidget {
  const RegisterDonorPage({super.key, required this.apiService});

  final ApiService apiService;

  @override
  State<RegisterDonorPage> createState() => _RegisterDonorPageState();
}

class _RegisterDonorPageState extends State<RegisterDonorPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _bloodGroup = TextEditingController();
  final _city = TextEditingController();
  final _pincode = TextEditingController();
  final _lastDate = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _bloodGroup.dispose();
    _city.dispose();
    _pincode.dispose();
    _lastDate.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await widget.apiService.registerDonor(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        bloodGroup: _bloodGroup.text.trim(),
        city: _city.text.trim(),
        pincode: _pincode.text.trim(),
        lastDonationDate: _lastDate.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Donor registered')),
      );
      _formKey.currentState!.reset();
      _name.clear();
      _phone.clear();
      _bloodGroup.clear();
      _city.clear();
      _pincode.clear();
      _lastDate.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            _textField('Name', _name),
            _textField('Phone', _phone, keyboardType: TextInputType.phone),
            _textField('Blood Group', _bloodGroup),
            _textField('City', _city),
            _textField('Pincode', _pincode, keyboardType: TextInputType.number),
            _textField('Last Donation Date (YYYY-MM-DD)', _lastDate),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Register Donor'),
            ),
          ],
        ),
      ),
    );
  }
}

class RequestBloodPage extends StatefulWidget {
  const RequestBloodPage({super.key, required this.apiService});

  final ApiService apiService;

  @override
  State<RequestBloodPage> createState() => _RequestBloodPageState();
}

class _RequestBloodPageState extends State<RequestBloodPage> {
  final _formKey = GlobalKey<FormState>();
  final _patientName = TextEditingController();
  final _requiredBloodGroup = TextEditingController();
  final _city = TextEditingController();
  final _pincode = TextEditingController();
  final _urgency = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _patientName.dispose();
    _requiredBloodGroup.dispose();
    _city.dispose();
    _pincode.dispose();
    _urgency.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final id = await widget.apiService.createRequest(
        patientName: _patientName.text.trim(),
        requiredBloodGroup: _requiredBloodGroup.text.trim(),
        city: _city.text.trim(),
        pincode: _pincode.text.trim(),
        urgency: _urgency.text.trim(),
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MatchesPage(
            apiService: widget.apiService,
            requestId: id,
          ),
        ),
      );
      _formKey.currentState!.reset();
      _patientName.clear();
      _requiredBloodGroup.clear();
      _city.clear();
      _pincode.clear();
      _urgency.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            _textField('Patient Name', _patientName),
            _textField('Required Blood Group', _requiredBloodGroup),
            _textField('City', _city),
            _textField('Pincode', _pincode, keyboardType: TextInputType.number),
            _textField('Urgency', _urgency),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit Request'),
            ),
          ],
        ),
      ),
    );
  }
}

class MatchesPage extends StatefulWidget {
  const MatchesPage({
    super.key,
    required this.apiService,
    required this.requestId,
  });

  final ApiService apiService;
  final int requestId;

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  late Future<MatchesData> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.apiService.fetchMatches(widget.requestId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Matches (Request #${widget.requestId})')),
      body: FutureBuilder<MatchesData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final data = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  title: Text(data.request.patientName),
                  subtitle: Text(
                    '${data.request.requiredBloodGroup} needed in ${data.request.city}',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Matching Donors (${data.matches.length})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (data.matches.isEmpty)
                const Card(
                  child: ListTile(
                    title: Text('No matching donors found'),
                  ),
                ),
              ...data.matches.map(
                (donor) => Card(
                  child: ListTile(
                    title: Text(donor.name),
                    subtitle: Text('${donor.bloodGroup} | ${donor.city}'),
                    trailing: Text(donor.phone),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

Widget _textField(
  String label,
  TextEditingController controller, {
  TextInputType keyboardType = TextInputType.text,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Required';
        }
        return null;
      },
    ),
  );
}

class ApiService {
  ApiService({required this.baseUrl});

  final String baseUrl;

  Future<DashboardData> fetchDashboard() async {
    final donors = await _getList('$baseUrl/api/donors');
    final requests = await _getList('$baseUrl/api/requests');
    return DashboardData(
      donors: donors.map(DonorModel.fromJson).toList(),
      requests: requests.map(BloodRequestModel.fromJson).toList(),
    );
  }

  Future<void> registerDonor({
    required String name,
    required String phone,
    required String bloodGroup,
    required String city,
    required String pincode,
    required String lastDonationDate,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/donors'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'phone': phone,
        'blood_group': bloodGroup,
        'city': city,
        'pincode': pincode,
        'last_donation_date': lastDonationDate,
      }),
    );
    _ensureSuccess(response);
  }

  Future<int> createRequest({
    required String patientName,
    required String requiredBloodGroup,
    required String city,
    required String pincode,
    required String urgency,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/requests'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'patient_name': patientName,
        'required_blood_group': requiredBloodGroup,
        'city': city,
        'pincode': pincode,
        'urgency': urgency,
      }),
    );
    _ensureSuccess(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['id'] as int;
  }

  Future<MatchesData> fetchMatches(int requestId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/matches/$requestId'));
    _ensureSuccess(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final requestJson = data['request'] as Map<String, dynamic>;
    final matchesJson = (data['matches'] as List<dynamic>).cast<Map<String, dynamic>>();

    return MatchesData(
      request: BloodRequestModel.fromJson(requestJson),
      matches: matchesJson.map(DonorModel.fromJson).toList(),
    );
  }

  Future<List<Map<String, dynamic>>> _getList(String url) async {
    final response = await http.get(Uri.parse(url));
    _ensureSuccess(response);
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode > 299) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }
}

class DashboardData {
  DashboardData({required this.donors, required this.requests});

  final List<DonorModel> donors;
  final List<BloodRequestModel> requests;
}

class MatchesData {
  MatchesData({required this.request, required this.matches});

  final BloodRequestModel request;
  final List<DonorModel> matches;
}

class DonorModel {
  DonorModel({
    required this.name,
    required this.phone,
    required this.bloodGroup,
    required this.city,
  });

  final String name;
  final String phone;
  final String bloodGroup;
  final String city;

  factory DonorModel.fromJson(Map<String, dynamic> json) {
    return DonorModel(
      name: (json['name'] ?? '') as String,
      phone: (json['phone'] ?? '') as String,
      bloodGroup: (json['blood_group'] ?? '') as String,
      city: (json['city'] ?? '') as String,
    );
  }
}

class BloodRequestModel {
  BloodRequestModel({
    required this.patientName,
    required this.requiredBloodGroup,
    required this.city,
    required this.urgency,
  });

  final String patientName;
  final String requiredBloodGroup;
  final String city;
  final String urgency;

  factory BloodRequestModel.fromJson(Map<String, dynamic> json) {
    return BloodRequestModel(
      patientName: (json['patient_name'] ?? '') as String,
      requiredBloodGroup: (json['required_blood_group'] ?? '') as String,
      city: (json['city'] ?? '') as String,
      urgency: (json['urgency'] ?? '') as String,
    );
  }
}
