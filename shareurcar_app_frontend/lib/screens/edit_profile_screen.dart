import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart'; // Asegúrate de que esta ruta sea correcta

class EditProfileScreen extends StatefulWidget {
  final Map user;
  const EditProfileScreen({super.key, required this.user});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  bool _isLoading = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

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
    _nameController.text =
        "${widget.user['firstname'] ?? ''} ${widget.user['lastname'] ?? ''}";
    _phoneController.text = widget.user['phone'] ?? '';
    _emailController.text = widget.user['email'] ?? '';
    _aboutController.text = widget.user['aboutMe'] ?? '';
    _modelController.text = widget.user['carModel'] ?? '';
    _colorController.text = widget.user['carColor'] ?? '';
    _plateController.text = widget.user['carPlate'] ?? '';
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    try {
      final userId =
          widget.user['idUser'] ?? widget.user['id_user'] ?? widget.user['id'];

      final updatedData = {
        "firstname": _nameController.text.split(' ').first,
        "lastname": _nameController.text.split(' ').length > 1
            ? _nameController.text.split(' ').sublist(1).join(' ')
            : "",
        "phone": _phoneController.text,
        "email": _emailController.text,
        "aboutMe": _aboutController.text,
        "carModel": _modelController.text,
        "carColor": _colorController.text,
        "carPlate": _plateController.text,
      };

      await ApiService.updateUserProfile(
        updatedData,
        int.parse(userId.toString()),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      String error = e.toString().replaceAll("Exception: ", "");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Editar perfil",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: Colors.black),
        actions: [
          _isLoading
              ? Padding(
                  padding: EdgeInsets.only(right: 20),
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.black),
                  ),
                )
              : TextButton(
                  onPressed: _saveProfile,
                  child: Text(
                    "Guardar",
                    style: TextStyle(
                      color: Color(0xFF5F2C82),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: _imageFile != null
                    ? FileImage(_imageFile!)
                    : (widget.user['photoUrl'] != null
                              ? NetworkImage(widget.user['photoUrl'])
                              : null)
                          as ImageProvider?,
                child: _imageFile == null && widget.user['photoUrl'] == null
                    ? Icon(Icons.camera_alt, size: 40, color: Colors.grey)
                    : null,
              ),
            ),
            TextButton(
              onPressed: _pickImage,
              child: Text(
                "Cambiar foto",
                style: TextStyle(color: Color(0xFF5F2C82)),
              ),
            ),
            SizedBox(height: 20),
            _buildField("Nombre completo", _nameController),
            _buildField("Teléfono", _phoneController, isNumber: true),
            _buildField("Email", _emailController),
            _buildField("Sobre mí", _aboutController, maxLines: 3),
            Divider(height: 40),

            if (widget.user['carPlate'] != null) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Vehículo",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              SizedBox(height: 15),

              _buildField("Modelo", _modelController),
              _buildField("Color", _colorController),
              _buildField("Matrícula", _plateController),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: const [
                    Icon(
                      Icons.directions_car,
                      size: 40,
                      color: Color(0xFF5F2C82),
                    ),

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
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
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
          SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: EdgeInsets.symmetric(
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
