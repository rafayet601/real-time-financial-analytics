import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:met_museum_explorer/models/artwork.dart';

class ARViewScreen extends StatefulWidget {
  final Artwork artwork;

  const ARViewScreen({Key? key, required this.artwork}) : super(key: key);

  @override
  _ARViewScreenState createState() => _ARViewScreenState();
}

class _ARViewScreenState extends State<ARViewScreen> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;

  // Placeholder for the AR node representing the artwork
  ARNode? artworkNode;

  @override
  void dispose() {
    arSessionManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AR View: ${widget.artwork.title}'),
      ),
      body: Stack(
        children: [
          ARView(
            onARViewCreated: onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontal, // Detect horizontal planes
          ),
          // Add UI elements here if needed, e.g., instructions or buttons
           Padding(
             padding: const EdgeInsets.all(16.0),
             child: Text(
               "Tap on a detected plane to place the artwork", 
               style: TextStyle(color: Colors.white.withOpacity(0.8), backgroundColor: Colors.black54)
              ),
           )
        ],
      ),
    );
  }

  void onARViewCreated(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager arAnchorManager,
    /*ARLocationManager arLocationManager,*/ // Location manager might not be needed here
  ) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;

    this.arSessionManager?.onInitialize(
          showFeaturePoints: false,
          showPlanes: true, // Show detected planes for user interaction
          customPlaneTexturePath: "assets/images/triangle.png", // Optional: custom texture for planes
          showWorldOrigin: false,
          handleTaps: true, // Enable tap handling
        );
    this.arObjectManager?.onInitialize();

    // Add tap listener
    this.arSessionManager?.onPlaneOrPointTap = _onPlaneTap;

     print("AR View Created and Initialized");
  }

  Future<void> _onPlaneTap(List<dynamic /*ARHitTestResult*/ > hits) async {
    if (hits.isEmpty) {
       print("No plane tapped.");
       return;
    }

    final hit = hits.first; // Use the first hit result
    
    // Remove previous artwork node if exists
    if (artworkNode != null) {
      arObjectManager?.removeNode(artworkNode!);
    }

    // Create a new node for the artwork
    // For simplicity, using a placeholder cube. Replace with artwork image/model
    // You would typically download the primaryImage and use it as a texture 
    // or load a 3D model if available.

     print("Plane tapped, attempting to add node...");

     // Example: Create a textured plane node (replace with actual artwork)
     // Need to handle image loading/availability properly
     var newNode = ARNode(
       type: NodeType.webGLB, // Or NodeType.image for a 2D representation
       uri: "https://github.com/KhronosGroup/glTF-Sample-Models/raw/master/2.0/Duck/glTF-Binary/Duck.glb", // Placeholder GLB model
       // uri: widget.artwork.primaryImage ?? "", // Use image URL if available
       scale: vector.Vector3(0.2, 0.2, 0.2),
       position: vector.Vector3(0,0,0), // Position will be set by anchor
       rotation: vector.Vector4(1.0, 0.0, 0.0, 0.0),
     );

    // Add the node to the scene anchored to the tapped point
    // The ar_flutter_plugin might require specific handling for anchors/hits
    // This part needs careful implementation based on the plugin's API
    // bool? didAdd = await arObjectManager?.addNode(newNode, planeAnchor: hit.anchor); // Example using anchor
    
    // Placeholder: Directly add node using hit matrix (adjust as per plugin API)
    final transform = hit.worldTransform; // Assuming this provides the matrix
     newNode.transform = transform;
     bool? didAdd = await arObjectManager?.addNode(newNode);

    if (didAdd ?? false) {
      artworkNode = newNode;
      print("Artwork node added successfully.");
    } else {
      print("Failed to add artwork node.");
    }
  }
} 