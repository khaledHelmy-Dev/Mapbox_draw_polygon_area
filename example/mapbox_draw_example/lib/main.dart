import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mapbox_draw_polygon_area/src/mapbox_draw_polygon.dart'
    as myPacakge;
import 'package:mapbox_gl/mapbox_gl.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      home: MapboxMapExample(),
    );
  }
}

class MapboxMapExample extends StatefulWidget {
  @override
  _MapboxMapExampleState createState() => _MapboxMapExampleState();
}

class _MapboxMapExampleState extends State<MapboxMapExample> {
  var myController = Get.put(myPacakge.MapBoxGetController());

  void _onMapCreated(MapboxMapController controller) {
    myController.mapBoxcontrollerInstance = controller;
    myController.onMapCreateFun();
  }

  @override
  void initState() {
    // myController = myPacakge.MapBoxGetController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniCenterDocked,
      floatingActionButton: Stack(
        fit: StackFit.expand,
        children: [
          // GetX<myPacakge.MapBoxGetController>(
          //     init: myController.MapBoxGetController(),
          //     builder: (controller) {
          //       return Visibility(
          //         visible: controller.isDrawing.value,
          // child:
          myController.drawPad(),
          myController.centerTargetiIcon(),
          //           );
          //         }),
        ],
      ),
      body: MapboxMap(
        styleString: MapboxStyles.LIGHT,
        accessToken: 'mapbox public token',
        onMapCreated: _onMapCreated,
        trackCameraPosition: true,
        initialCameraPosition: const CameraPosition(
          target: LatLng(40.384950128422496, -85.56492779229464),
          zoom: 16,
        ),
        onCameraIdle: (() {
          if (myController.listOfDrawLatLlongs.isNotEmpty &&
              !myController.isPolygonSaved.value &&
              !myController.isDiagonalSaved.value) {
            myController.drawActiveline();
          }
        }),
      ),
    );
  }
}
