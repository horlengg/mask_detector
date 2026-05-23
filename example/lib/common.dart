
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

ElevatedButton buildButton(String title,void Function()? tap){
  return ElevatedButton(
    onPressed: tap, 
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 40,vertical: 15),
      backgroundColor: Colors.blueAccent,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0))
    ),
    child: Text(title)
  );
}
