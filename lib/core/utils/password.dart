import 'dart:convert';

import 'package:crypto/crypto.dart';

/// SHA-256 hash (hex) for a plain-text password.
String hashPassword(String password) =>
    sha256.convert(utf8.encode(password)).toString();
