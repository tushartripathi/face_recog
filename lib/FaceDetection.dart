import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart' show ByteData, Uint8List, rootBundle;

import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';

class FaceRecognition extends StatefulWidget {
  const FaceRecognition({Key? key}) : super(key: key);

  @override
  State<FaceRecognition> createState() => _FaceRecognitionState();
}

class _FaceRecognitionState extends State<FaceRecognition> {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
    ),
  );

  File? _imageFile;
  InputImage? _inputImage;
  String _text = 'trace face';
  String path = 'assets/img.jpg';
  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        child: Column(
      children: [
        Image.asset(path),
        TextButton(
            onPressed: () {
              _pickImage(ImageSource.camera);
            },
            child: Text(_text)),
      ],
    ));
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);

    setState(() {
      // path = pickedFile!.path;
      _imageFile = File(pickedFile!.path);
      _inputImage = InputImage.fromFile(_imageFile!);
      processImage(_inputImage!);
    });
  }

  Future<void> faceRec(InputImage image) async {
    final options = FaceDetectorOptions();
    final faceDetector = FaceDetector(options: options);
    try {
      print("tracking id ------ ");
      final List<Face> faces = await faceDetector.processImage(image);
      print(faces.length);
      // for (Face face in faces) {
      //   final Rect boundingBox = face.boundingBox;
      //   setState(() {
      //     _text = "tracking id asdfka";
      //   });
      //   print("t11111 " + face.trackingId.toString());
      //   final double? rotX =
      //       face.headEulerAngleX; // Head is tilted up and down rotX degrees
      //   final double? rotY =
      //       face.headEulerAngleY; // Head is rotated to the right rotY degrees
      //   final double? rotZ =
      //       face.headEulerAngleZ; // Head is tilted sideways rotZ degrees
      //   print("211 " +
      //       rotX.toString() +
      //       " " +
      //       rotY.toString() +
      //       " " +
      //       rotZ.toString());
      //   // If landmark detection was enabled with FaceDetectorOptions (mouth, ears,
      //   // eyes, cheeks, and nose available):
      //   final FaceLandmark? leftEar = face.landmarks[FaceLandmarkType.leftEar];
      //   if (leftEar != null) {
      //     final Point<int> leftEarPos = leftEar.position;
      //     print("got ear");
      //   }
      //
      //   // If classification was enabled with FaceDetectorOptions:
      //   if (face.smilingProbability != null) {
      //     final double? smileProb = face.smilingProbability;
      //     print("smile");
      //   }
      //
      //   print("got tracking.... ");
      //   // If face tracking was enabled with FaceDetectorOptions:
      //   if (face.trackingId != null) {
      //     final int? id = face.trackingId;
      //   }
      //   print("done");
      // }

    } catch (e) {
      setState(() {
        _text = "tracking id " + e.toString();
      });
      print("eroro = " + e.toString());
    }
  }

  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;

  @override
  void dispose() {
    _canProcess = false;
    _faceDetector.close();
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> processImage(InputImage inputImage) async {
    final faces = await _faceDetector.processImage(inputImage);

    String text = 'Faces found: ${faces.length}\n\n';
    for (final face in faces) {
      print("found face");
      text += 'face: ${face.boundingBox}\n\n';
    }
    print("------------------------------------");
    _text = text;
    _customPaint = null;

    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }

  late CameraController _cameraController;
  late StreamSubscription<CameraImage> _cameraStreamSubscription;

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.first;
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
    );

    await _cameraController.initialize();

    _cameraStreamSubscription = _cameraController.startImageStream(
      (CameraImage cameraImage) {
        _sendFrame(cameraImage);
      },
    ) as StreamSubscription<CameraImage>;
  }

  void _sendFrame(CameraImage cameraImage) {
    // Convert the CameraImage to a Uint8List for sending over a network
    final planeBytes = cameraImage.planes.map((plane) {
      return plane.bytes;
    }).toList();
    final bytes = Uint8List.fromList(
      planeBytes.expand((element) => element).toList(),
    );

    // Create a Flutter Image from the bytes
    InputImage value = InputImage.fromBytes(
        bytes: bytes,
        inputImageData: InputImageData(
            size: Size(330, 330), // the size of the image
            imageRotation:
                InputImageRotation.rotation90deg, // the rotation of the image
            inputImageFormat: InputImageFormat.yuv420,
            planeData: []));
    // print("done,,," + value.hashCode.toString());
    processImage(value); // the format of the image);// the format of the image)
  }
}
