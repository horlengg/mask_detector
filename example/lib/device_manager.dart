

import 'dart:developer';
import 'package:screen_brightness/screen_brightness.dart';

class DeviceManager {

  
  static Future<double> getApplicationBrightness() async{
    try {
      return await ScreenBrightness.instance.application;
    } catch (e) {
      throw 'Failed to get application brightness';
    }
  }

  static Future<void> setApplicationBrightness(double brightness) async {
    try {
      await ScreenBrightness.instance.setApplicationScreenBrightness(brightness);
    } catch (e) {
      log(e.toString());
      throw 'Failed to set application brightness';
    }
  }
}