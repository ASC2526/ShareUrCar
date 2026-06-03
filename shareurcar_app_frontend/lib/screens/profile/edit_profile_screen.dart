import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../app_theme.dart';
import '../../services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  final Map user;
  const EditProfileScreen({super.key, required this.user});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  bool _isLoading = false;
  File? _imageFile;
  final _picker = ImagePicker();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _aboutController = TextEditingController();
  final _modelController = TextEditingController();
  final _colorController = TextEditingController();
  final _plateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _nameController.text = "${u['firstname'] ?? ''} ${u['lastname'] ?? ''}"
        .trim();
    _phoneController.text = u['phone'] ?? '';
    _emailController.text = u['email'] ?? '';
    _aboutController.text = u['aboutMe'] ?? '';
    _modelController.text = u['carModel'] ?? '';
    _colorController.text = u['carColor'] ?? '';
    _plateController.text = u['carPlate'] ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _aboutController.dispose();
    _modelController.dispose();
    _colorController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 800,
    );
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      final userId = int.parse(
        (widget.user['idUser'] ?? widget.user['id_user'] ?? widget.user['id'])
            .toString(),
      );

      // subir foto
      if (_imageFile != null) {
        final bytes = await _imageFile!.readAsBytes();
        final base64Photo = "data:image/jpeg;base64,${base64Encode(bytes)}";
        await ApiService.uploadPhoto(userId, base64Photo);
      }

      // guardar datos perfil
      final parts = _nameController.text.trim().split(' ');
      await ApiService.updateUserProfile({
        "firstname": parts.first,
        "lastname": parts.length > 1 ? parts.sublist(1).join(' ') : "",
        "phone": _phoneController.text.trim(),
        "email": _emailController.text.trim(),
        "aboutMe": _aboutController.text.trim(),
        "carModel": _modelController.text.trim(),
        "carColor": _colorController.text.trim(),
        "carPlate": _plateController.text.trim(),
      }, userId);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll("Exception: ", "")),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? fotoUrl = widget.user['profile_photo'];
    ImageProvider? bgImage;
    if (_imageFile != null) {
      bgImage = FileImage(_imageFile!);
    } else if (fotoUrl != null && fotoUrl.isNotEmpty) {
      bgImage = NetworkImage(fotoUrl);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Editar perfil",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: Colors.black),
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.only(right: 20),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _saveProfile,
                  child: const Text(
                    "Guardar",
                    style: TextStyle(
                      color: kPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: bgImage,
                child: bgImage == null
                    ? const Icon(Icons.camera_alt, size: 40, color: Colors.grey)
                    : null,
              ),
            ),
            TextButton(
              onPressed: _pickImage,
              child: const Text(
                "Cambiar foto",
                style: TextStyle(color: kPrimary),
              ),
            ),

            const SizedBox(height: 20),

            // campos texto
            _field("Nombre completo", _nameController),
            _field("Teléfono", _phoneController, isNumber: true),
            _field("Email", _emailController),
            _field("Sobre mí", _aboutController, maxLines: 3),

            const Divider(height: 40),

            // vehículo
            if (widget.user['carPlate'] != null) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  "Vehículo",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 15),
              _field("Modelo", _modelController),
              _field("Color", _colorController),
              _field("Matrícula", _plateController),
            ] else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.directions_car, size: 40, color: kPrimary),
                    SizedBox(height: 10),
                    Text(
                      "No tienes vehículo registrado",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Para registrar un vehículo debes crear una ruta por primera vez.",
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: ctrl,
            maxLines: maxLines,
            keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
