import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

enum CameraState {
  loading,
  empty,
  exist;
}

extension InputImageFormatMethods on InputImageFormat {
  // source: https://developers.google.com/android/reference/com/google/mlkit/vision/common/InputImage#constants
  static Map<InputImageFormat, int> get _values => {
        InputImageFormat.nv21: 17,
        InputImageFormat.yv12: 842094169,
        InputImageFormat.yuv_420_888: 35,
        InputImageFormat.yuv420: 875704438,
        InputImageFormat.bgra8888: 1111970369,
      };

  int get rawValue => _values[this] ?? 17;

  static InputImageFormat? fromRawValue(int rawValue) {
    return InputImageFormatMethods._values
        .map((k, v) => MapEntry(v, k))[rawValue];
  }
}

InputImageData buildMetaData(
  CameraImage image,
  InputImageRotation rotation,
) {
  return InputImageData(
    size: Size(image.width.toDouble(), image.height.toDouble()),
    imageRotation: rotation,
    inputImageFormat: InputImageFormatMethods.fromRawValue(image.format.raw) ??
        InputImageFormat.nv21,
    planeData: image.planes.map(
      (Plane plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      },
    ).toList(),
  );
}

InputImageRotation rotationIntToImageRotation(int rotation) {
  switch (rotation) {
    case 0:
      return InputImageRotation.rotation0deg;
    case 90:
      return InputImageRotation.rotation90deg;
    case 180:
      return InputImageRotation.rotation180deg;
    default:
      assert(rotation == 270);
      return InputImageRotation.rotation270deg;
  }
}

class FaceFound extends StatelessWidget {
  const FaceFound({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text("Face Found")),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  CameraController? controller;
  CameraState cameraState = CameraState.loading;
  var isProcessing = false;
  var isFound = false;

  @override
  void initState() {
    isProcessing = false;
    isFound = false;
    _initCamera();
    super.initState();
  }

  @override
  void dispose() async {
    if (controller != null) {
      await controller!.stopImageStream();
      await Future.delayed(const Duration(milliseconds: 200));
      await controller!.dispose();
      controller = null;
    }
    super.dispose();
  }

  void _initCamera() async {
    List<CameraDescription> cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      final camera = cameras[1];
      controller = CameraController(camera, ResolutionPreset.high,
          enableAudio: false, imageFormatGroup: ImageFormatGroup.yuv420);
      await controller?.initialize();
      final options = FaceDetectorOptions(
        
      );
      final faceDetector = FaceDetector(options: options);
      controller?.startImageStream((image) {
        
        if (!isProcessing && !isFound) {
          processImage(camera, image, faceDetector);
        }
      });
      cameraState = CameraState.exist;
    } else {
      cameraState = CameraState.empty;
    }
    setState(() {});
  }

  void processImage(CameraDescription camera, CameraImage image,
      FaceDetector faceDetector) async {
    isProcessing = true;
    final bytes = Uint8List.fromList(
      image.planes.fold(
          <int>[],
          (List<int> previousValue, element) =>
              previousValue..addAll(element.bytes)),
    );
    final inputImageData = InputImage.fromBytes(
        bytes: bytes,
        inputImageData: buildMetaData(
            image, rotationIntToImageRotation(camera.sensorOrientation)));
    final result = await faceDetector.processImage(inputImageData);
    if (result.isNotEmpty) {
      goToNextPage();
      isFound = true;
    } else {
    }
    isProcessing = false;
  }

  void goToNextPage() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (ctx) => const FaceFound()));
    isFound = false;
    isProcessing = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Center(
          child: Builder(builder: (ctx) {
            if (cameraState == CameraState.loading) {
              return const CircularProgressIndicator();
            }
            if (cameraState == CameraState.exist && controller != null) {
              return Column(
                children: [
                  Expanded(child: CameraPreview(controller!)),
                ],
              );
            }
            return const Text("No Camera");
          }),
        ));
  }
}
