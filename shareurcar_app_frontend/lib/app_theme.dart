import 'package:flutter/material.dart';

// colores
const kPrimary = Color(0xFF5F2C82);
const kSecondary = Color(0xFF49A09D);

// gradiente principal
const kGradient = LinearGradient(
  colors: [kPrimary, kSecondary],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

const kGradientH = LinearGradient(
  colors: [kPrimary, kSecondary],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// decoraciones cabecera
BoxDecoration kHeaderDecoration({double radius = 30}) => BoxDecoration(
  gradient: kGradient,
  borderRadius: BorderRadius.vertical(bottom: Radius.circular(radius)),
);

// tarjeta blanca
BoxDecoration kCardDecoration({double radius = 16}) => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: Colors.grey.shade200),
  boxShadow: [
    BoxShadow(
      color: Colors.grey.shade100,
      blurRadius: 10,
      spreadRadius: 1,
      offset: const Offset(0, 4),
    ),
  ],
);

// appbar blanca
AppBar kWhiteAppBar({
  required String title,
  bool centerTitle = true,
  List<Widget>? actions,
  Widget? leading,
}) => AppBar(
  title: Text(
    title,
    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
  ),
  backgroundColor: Colors.white,
  elevation: 0,
  centerTitle: centerTitle,
  actions: actions,
  leading: leading,
);

// botón primario
ButtonStyle kPrimaryButton({double radius = 12}) => ElevatedButton.styleFrom(
  backgroundColor: kPrimary,
  padding: const EdgeInsets.symmetric(vertical: 16),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
);
