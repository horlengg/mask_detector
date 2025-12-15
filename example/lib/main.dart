
import 'package:flutter/material.dart';
import 'package:mask_detector_example/common.dart';
import 'package:mask_detector_example/mask_detection_view.dart';

void main() {
  runApp(MaterialApp(
    home: MaskDetectorExampleApp(),
    initialRoute: '/',
    onGenerateRoute: (settings) {
      Widget page;
      switch (settings.name) {
        case '/':
          page = const MaskDetectorExampleApp();
        case '/do_mask_detection':
          page = const MaskDetectionView();
          break;
        default:
          page = const MaskDetectorExampleApp();
      }

      return PageRouteBuilder(
        settings: settings,
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0); // slide from right
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 200),
      );
    },
  ));
}

class MaskDetectorExampleApp extends StatelessWidget {
  
  const MaskDetectorExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mask Detector'),
        backgroundColor: Colors.blue,
      ),
      backgroundColor: Color(0xFFC7D9E9),
      body: SafeArea(
        child: Center(
          child: buildButton("Start", () => Navigator.pushNamed(context, '/do_mask_detection')),
        ),
      ),
    );
  }
}

class FaceBoxPainter extends CustomPainter {
  final Rect rect;
  final Size size;

  FaceBoxPainter(this.rect, this.size);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant FaceBoxPainter oldDelegate) {
    return rect != oldDelegate.rect || size != oldDelegate.size;
  }
}