import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:met_museum_explorer/models/artwork.dart';
import 'package:met_museum_explorer/services/ar_service.dart';
import 'package:vector_math/vector_math_64.dart';

class AROverlay extends StatefulWidget {
  final Artwork artwork;

  const AROverlay({Key? key, required this.artwork}) : super(key: key);

  @override
  _AROverlayState createState() => _AROverlayState();
}

class _AROverlayState extends State<AROverlay> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;
  ARLocationManager? arLocationManager;
  
  List<ARNode> nodes = [];
  bool _showInfo = true;
  
  @override
  void dispose() {
    super.dispose();
    arSessionManager?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AR View: ${widget.artwork.title}'),
        actions: [
          IconButton(
            icon: Icon(_showInfo ? Icons.info_outline : Icons.info),
            onPressed: () {
              setState(() {
                _showInfo = !_showInfo;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          ARView(
            onARViewCreated: onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),
          if (_showInfo)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16.0),
                color: Colors.black.withOpacity(0.7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.artwork.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    if (widget.artwork.artistName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.artwork.artistName!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Tap on the floor to place the artwork',
                      style: TextStyle(color: Colors.white.withOpacity(0.8)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void onARViewCreated(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager arAnchorManager,
    ARLocationManager arLocationManager,
  ) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;
    this.arAnchorManager = arAnchorManager;
    this.arLocationManager = arLocationManager;

    this.arSessionManager!.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      showWorldOrigin: false,
      handlePans: true,
      handleRotation: true,
    );

    this.arObjectManager!.onInitialize();

    this.arSessionManager!.onPlaneOrPointTap = onPlaneOrPointTapped;
  }

  Future<void> onPlaneOrPointTapped(
    List<ARHitTestResult> hitTestResults,
  ) async {
    if (hitTestResults.isEmpty) return;
    
    final hit = hitTestResults.firstWhere(
      (result) => result.type == ARHitTestResultType.plane,
      orElse: () => hitTestResults.first,
    );

    // Create a node using a 3D model or a placeholder cube
    final node = ARNode(
      type: NodeType.localGLTF2,
      uri: widget.artwork.primaryImageUrl ?? 'https://github.com/KhronosGroup/glTF-Sample-Models/raw/master/2.0/BoxTextured/glTF/BoxTextured.gltf',
      scale: Vector3(0.2, 0.2, 0.2),
      position: Vector3(0, 0, 0),
      rotation: Vector4(1, 0, 0, 0),
    );

    bool? didAddNode = await arObjectManager?.addNode(node, planeAnchor: hit.worldTransform);
    
    if (didAddNode != null && didAddNode) {
      nodes.add(node);
    }
  }
} 