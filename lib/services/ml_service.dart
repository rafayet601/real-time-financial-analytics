import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:met_museum_explorer/utils/constants.dart';

class MLService {
  Interpreter? _interpreter;
  List<String>? _labels;
  bool _isDemo = ApiConstants.DEMO_MODE;
  final Random _random = Random();

  Future<void> loadModel() async {
    if (_isDemo) {
      // In demo mode, simulate loading time without actually loading a model
      await Future.delayed(const Duration(seconds: 2));
      print('Demo mode: ML model simulated');
      return;
    }

    try {
      // Load the model
      _interpreter = await Interpreter.fromAsset('ml/model.tflite');
      print('Model loaded successfully');

      // Load the labels
      final labelsData = await rootBundle.loadString('assets/ml/labels.txt');
      _labels = labelsData.split('\n');
      print('Labels loaded successfully: ${_labels?.length} labels');

    } catch (e) {
      print('Error loading model or labels: $e');
      _interpreter = null;
      _labels = null;
      rethrow;
    }
  }

  Future<Map<String, double>?> recognizeImage(Uint8List imageBytes) async {
    if (_isDemo) {
      // In demo mode, return a random artwork ID from our sample list
      await Future.delayed(Duration(milliseconds: 500 + _random.nextInt(1000)));
      
      // Randomly select an artwork ID with a high confidence
      final selectedArtworkId = ApiConstants.DEMO_ARTWORK_IDS[_random.nextInt(ApiConstants.DEMO_ARTWORK_IDS.length)];
      final confidence = 0.75 + (_random.nextDouble() * 0.2); // Random confidence between 0.75 and 0.95
      
      print('Demo mode: "Recognized" artwork ID $selectedArtworkId with confidence $confidence');
      return {selectedArtworkId.toString(): confidence};
    }

    if (_interpreter == null || _labels == null) {
      print('Model or labels not loaded.');
      return null;
    }

    try {
      // Decode image
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) {
        print('Failed to decode image');
        return null;
      }

      // Resize image (adjust dimensions as per your model's input requirements)
      img.Image resizedImage = img.copyResize(image, width: 224, height: 224);

      // Convert image to ByteBuffer (adjust normalization as per your model)
      var input = _imageToByteBuffer(resizedImage);

      // Define the output tensor shape (adjust based on your model's output)
      // Example: Output is a list of probabilities for each label
      var output = List.filled(_labels!.length, 0.0).reshape([1, _labels!.length]);

      // Run inference
      _interpreter!.run(input, output);

      // Process the output
      final results = <String, double>{};
      for (int i = 0; i < _labels!.length; i++) {
        // Filter results below a certain threshold if needed
        if (output[0][i] > 0.1) { // Example threshold: 10%
           results[_labels![i]] = output[0][i];
        }
      }
       print('Recognition results: $results');
      return results;

    } catch (e) {
      print('Error during image recognition: $e');
      return null;
    }
  }

  ByteBuffer _imageToByteBuffer(img.Image image) {
    // Example normalization (adjust based on your model)
    var buffer = ByteData(1 * 224 * 224 * 3 * 4); // Example: FLOAT32, 3 channels
    int pixelIndex = 0;
    for (var y = 0; y < 224; y++) {
      for (var x = 0; x < 224; x++) {
        var pixel = image.getPixel(x, y);
        // Assuming RGB format and normalization to [-1, 1] or [0, 1]
        // Adjust normalization based on your model requirements
        buffer.setFloat32(pixelIndex * 12 + 0, (img.getRed(pixel) - 127.5) / 127.5, Endian.native);
        buffer.setFloat32(pixelIndex * 12 + 4, (img.getGreen(pixel) - 127.5) / 127.5, Endian.native);
        buffer.setFloat32(pixelIndex * 12 + 8, (img.getBlue(pixel) - 127.5) / 127.5, Endian.native);
        pixelIndex++;
      }
    }
    return buffer.buffer;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _labels = null;
     print('MLService disposed');
  }
} 