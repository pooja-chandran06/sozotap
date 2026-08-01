import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/app_colors.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../domain/models/medical_profile.dart';
import '../providers/medical_profile_provider.dart';

class MedicalProfileEditScreen extends ConsumerStatefulWidget {
  const MedicalProfileEditScreen({super.key});

  @override
  ConsumerState<MedicalProfileEditScreen> createState() => _MedicalProfileEditScreenState();
}

class _MedicalProfileEditScreenState extends ConsumerState<MedicalProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _fullNameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _genderCtrl = TextEditingController();
  final _bloodGroupCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _conditionsCtrl = TextEditingController();
  final _allergiesCtrl = TextEditingController();
  final _medicationsCtrl = TextEditingController();
  final _surgeriesCtrl = TextEditingController();
  final _implantsCtrl = TextEditingController();
  final _insuranceCtrl = TextEditingController();
  final _doctorCtrl = TextEditingController();
  final _hospitalCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  bool _isPregnant = false;
  bool _isOrganDonor = false;
  
  File? _imageFile;
  String? _existingPhotoUrl;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(medicalProfileProvider).value;
      if (profile != null) {
        _populateFields(profile);
      }
    });
  }

  void _populateFields(MedicalProfile profile) {
    _fullNameCtrl.text = profile.fullName;
    _ageCtrl.text = profile.age > 0 ? profile.age.toString() : '';
    _genderCtrl.text = profile.gender;
    _bloodGroupCtrl.text = profile.bloodGroup;
    _heightCtrl.text = profile.heightCm > 0 ? profile.heightCm.toString() : '';
    _weightCtrl.text = profile.weightKg > 0 ? profile.weightKg.toString() : '';
    _conditionsCtrl.text = profile.medicalConditions;
    _allergiesCtrl.text = profile.allergies;
    _medicationsCtrl.text = profile.currentMedications;
    _surgeriesCtrl.text = profile.pastSurgeries;
    _implantsCtrl.text = profile.implants;
    _insuranceCtrl.text = profile.insuranceInfo;
    _doctorCtrl.text = profile.primaryDoctor;
    _hospitalCtrl.text = profile.preferredHospital;
    _notesCtrl.text = profile.notes;
    
    setState(() {
      _isPregnant = profile.isPregnant;
      _isOrganDonor = profile.isOrganDonor;
      _existingPhotoUrl = profile.photoUrl;
    });
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _ageCtrl.dispose();
    _genderCtrl.dispose();
    _bloodGroupCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _conditionsCtrl.dispose();
    _allergiesCtrl.dispose();
    _medicationsCtrl.dispose();
    _surgeriesCtrl.dispose();
    _implantsCtrl.dispose();
    _insuranceCtrl.dispose();
    _doctorCtrl.dispose();
    _hospitalCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    String? photoUrl = _existingPhotoUrl;

    if (_imageFile != null) {
      setState(() => _isUploadingPhoto = true);
      try {
        photoUrl = await ref.read(medicalProfileProvider.notifier).uploadPhoto(_imageFile!);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
        }
        setState(() => _isUploadingPhoto = false);
        return;
      }
      setState(() => _isUploadingPhoto = false);
    }

    final profile = MedicalProfile(
      uid: user.id,
      photoUrl: photoUrl,
      fullName: _fullNameCtrl.text.trim(),
      age: int.tryParse(_ageCtrl.text) ?? 0,
      gender: _genderCtrl.text.trim(),
      bloodGroup: _bloodGroupCtrl.text.trim(),
      heightCm: double.tryParse(_heightCtrl.text) ?? 0.0,
      weightKg: double.tryParse(_weightCtrl.text) ?? 0.0,
      medicalConditions: _conditionsCtrl.text.trim(),
      allergies: _allergiesCtrl.text.trim(),
      currentMedications: _medicationsCtrl.text.trim(),
      pastSurgeries: _surgeriesCtrl.text.trim(),
      implants: _implantsCtrl.text.trim(),
      isPregnant: _isPregnant,
      isOrganDonor: _isOrganDonor,
      insuranceInfo: _insuranceCtrl.text.trim(),
      primaryDoctor: _doctorCtrl.text.trim(),
      preferredHospital: _hospitalCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
    );

    await ref.read(medicalProfileProvider.notifier).saveProfile(profile);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved securely.'), backgroundColor: Colors.green));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(medicalProfileProvider);
    final isLoading = profileState.isLoading || _isUploadingPhoto;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Medical Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: profileState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error loading profile: $e')),
          data: (_) => SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: isLoading ? null : _pickImage,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : (_existingPhotoUrl != null ? NetworkImage(_existingPhotoUrl!) : null) as ImageProvider?,
                        child: _imageFile == null && _existingPhotoUrl == null
                            ? const Icon(Icons.camera_alt, size: 40, color: Colors.grey)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Basic Details'),
                  _buildTextField(_fullNameCtrl, 'Full Name', required: true),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_ageCtrl, 'Age', isNumber: true, required: true)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField(_genderCtrl, 'Gender', required: true)),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_heightCtrl, 'Height (cm)', isNumber: true)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField(_weightCtrl, 'Weight (kg)', isNumber: true)),
                    ],
                  ),
                  _buildTextField(_bloodGroupCtrl, 'Blood Group', required: true),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('Medical Information'),
                  _buildTextField(_conditionsCtrl, 'Medical Conditions (e.g., Diabetes, Asthma)', maxLines: 3),
                  _buildTextField(_allergiesCtrl, 'Allergies', maxLines: 2),
                  _buildTextField(_medicationsCtrl, 'Current Medications', maxLines: 2),
                  _buildTextField(_surgeriesCtrl, 'Past Surgeries', maxLines: 2),
                  _buildTextField(_implantsCtrl, 'Implants (e.g., Pacemaker)'),
                  
                  SwitchListTile(
                    title: const Text('Are you pregnant?'),
                    value: _isPregnant,
                    onChanged: (val) => setState(() => _isPregnant = val),
                    activeColor: AppColors.primary,
                  ),
                  SwitchListTile(
                    title: const Text('Registered Organ Donor?'),
                    value: _isOrganDonor,
                    onChanged: (val) => setState(() => _isOrganDonor = val),
                    activeColor: AppColors.primary,
                  ),

                  const SizedBox(height: 24),
                  _buildSectionTitle('Emergency Contacts & Insurance'),
                  _buildTextField(_insuranceCtrl, 'Insurance Information'),
                  _buildTextField(_doctorCtrl, 'Primary Doctor Name / Contact'),
                  _buildTextField(_hospitalCtrl, 'Preferred Hospital'),
                  _buildTextField(_notesCtrl, 'Additional Notes', maxLines: 3),
                  
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Save Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false, int maxLines = 1, bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        validator: required ? (value) {
          if (value == null || value.trim().isEmpty) return 'This field is required';
          return null;
        } : null,
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        ),
      ),
    );
  }
}
