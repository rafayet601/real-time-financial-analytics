import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

class ARService {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;
  
  void onARViewCreated(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager arAnchorManager,
    ARLocationManager arLocationManager,
  ) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;
    this.arAnchorManager = arAnchorManager;
    
    this.arSessionManager!.onInitialize();
    this.arObjectManager!.onInitialize();
  }
  
  Future<void> addArtworkInfoToAnchor(String imageUrl, String artworkInfo) async {
    if (arObjectManager == null || arAnchorManager == null) return;
    
    final node = ARNode(
      type: NodeType.webGLB,
      uri: imageUrl,
      scale: Vector3(0.2, 0.2, 0.2),
      position: Vector3(0, 0, -0.5),
      rotation: Vector4(1, 0, 0, 0),
    );
    
    await arObjectManager!.addNode(node);
  }
  
  void dispose() {
    arSessionManager?.dispose();
  }
} 