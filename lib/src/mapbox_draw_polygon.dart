import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:mapbox_draw_polygon_area/src/alert_dialogue_polyline_len.dart';
import 'package:mapbox_gl_modified/mapbox_gl_modified.dart';
import 'package:snapping_sheet/snapping_sheet.dart';

class MapBoxGetController extends GetxController {
  MapboxMapController? mapBoxcontrollerInstance;
  LatLng? myMapBoxCurrentLocation;

  //Drawing and Area
  RxBool isDrawing = false.obs;
  RxDouble areaOfPolygon = 0.0.obs;
  RxString selectedLayer = MapboxStyles.LIGHT.obs;
  List<List> listOfDrawLatLlongs = [];
//save polygon
  Map<String, double> polylineWithLengthMap = {};
  List<Symbol> symbolList = [];
  RxBool isPolygonSaved = false.obs;
  RxBool isDiagonalStarted = false.obs;
  RxBool isDiagonalSaved = false.obs;
  Map<String, Symbol> diagonalTempMap = {};
  List<String> diagonalLayerCollection = [];
  List<Symbol> symbolListOnlyDiagonal = [];
  RxBool isWatingForSecondSymbolTap = false.obs;
  String lastVertext = "A";

//for area conversion
  Map dropItems = {
    'Sq. meter': 0.00,
    'Acre': 0.00,
    'Bigha': 0.00,
    'kattha': 0.00,
    'Dhur': 0.00,
    'Ropani': 0.00,
    'Aana': 0.00,
    'Paisa:': 0.00,
    'Dam': 0.00,
    'Sq. feet': 0.00
  };
  Rx<String> dropdownvalue = 'Sq. meter'.obs;
  List<DropdownMenuItem<Object>>? dropItemListMap = [];
  RxBool isShowMixedconveresion = false.obs;
  Rx<String> mixedconveresion = '0 ropani, 0 aana, 0 paisa,0 dam'.obs;

  onMapCreateFun() {
    mapBoxcontrollerInstance!.onFeatureTapped.add(onFeatureTap);
    mapBoxcontrollerInstance!.onSymbolTapped.add((symbol) async {
      onSymbolTapFun(symbol);
    });
  }

//end of area conversion
  populateDropdownList() {
    dropItemListMap!.clear();
    dropItems.forEach((key, value) {
      dropItemListMap!.add(DropdownMenuItem(
        value: key,
        child: Text(' ${value.toStringAsFixed(3)} $key'),
      ));
    });
    update();
  }

  dropDownOnchanged(newValue) {
    dropdownvalue(newValue!.toString());
    if (['Ropani', 'Aana', 'Aana', 'Paisa:', 'Dam']
        .contains(dropdownvalue.value)) {
      isShowMixedconveresion(true);
    } else {
      isShowMixedconveresion(false);
    }
    update();
  }

  @override
  onInit() async {
    populateDropdownList();

    super.onInit();
  }

//on feature tap

  Future<void> onFeatureTap(dynamic featureId, dynamic featureDetail,
      math.Point point, LatLng latlng) async {
    try {
      if (featureDetail["properties"]["customType"] == "measuringLine") {
        Get.dialog(EditLenDialogieBox(
          lineName: featureDetail["properties"]["name"],
        ));
      } else if (featureDetail["properties"]["customType"] == "diagonal") {
        Get.dialog(EditDiagonalLenDialogieBox(
            lineName: featureDetail["properties"]["name"],
            centerLatlangPolyline: featureDetail["properties"]["centerLatng"]));
      } else {}
    } catch (e) {
      debugPrint('Feature not available');
    }
  }
  //on symbol tap function

  onSymbolTapFun(Symbol symbol) {
    mapBoxcontrollerInstance!.onSymbolTapped.add((symbol) async {
      //symbol.data!['id'].length is only 1 for A B C D E
      //alter native we can check id is A B C D by ascii value

      if (symbol.data!['id'].length == 1 && !isDiagonalSaved.value) {
        if (isPolygonSaved.value) {
          if (isWatingForSecondSymbolTap.value == false &&
              diagonalTempMap['firstSymbol'] == null) {
            await mapBoxcontrollerInstance!
                .updateSymbol(symbol, const SymbolOptions(textColor: 'red'));
            diagonalTempMap['firstSymbol'] = symbol;
            isWatingForSecondSymbolTap(true);
          } else if (isWatingForSecondSymbolTap.value == true &&
              diagonalTempMap['firstSymbol']!.data!['id'] !=
                  symbol.data!['id'] &&
              diagonalTempMap['firstSymbol']!.data!['id'].codeUnitAt(0) -
                      symbol.data!['id'].codeUnitAt(0) !=
                  0 &&
              !(diagonalTempMap['firstSymbol']!.data!['id'].codeUnitAt(0) -
                          symbol.data!['id'].codeUnitAt(0) ==
                      1 ||
                  diagonalTempMap['firstSymbol']!.data!['id'].codeUnitAt(0) -
                          symbol.data!['id'].codeUnitAt(0) ==
                      -1) &&
              !((lastVertext == diagonalTempMap['firstSymbol']!.data!['id'] &&
                      symbol.data!['id'] == "A") ||
                  ('A' == diagonalTempMap['firstSymbol']!.data!['id'] &&
                      symbol.data!['id'] == lastVertext))) {
            diagonalTempMap['secondSymbol'] = symbol;

            log("lastvertext: $lastVertext tempMapFirst: ${diagonalTempMap['firstSymbol']!.data!['id']} symbol ${symbol.data!['id']} symbolListAfirst 'A' iswating :${isWatingForSecondSymbolTap.value}}");

            drawDiagonalline();

            isWatingForSecondSymbolTap(false);
          } else if (diagonalTempMap['firstSymbol']!.data!['id'].codeUnitAt(0) -
                      symbol.data!['id'].codeUnitAt(0) !=
                  0 ||
              diagonalTempMap['firstSymbol']!.data!['id'].codeUnitAt(0) -
                      symbol.data!['id'].codeUnitAt(0) ==
                  1 ||
              diagonalTempMap['firstSymbol']!.data!['id'].codeUnitAt(0) -
                      symbol.data!['id'].codeUnitAt(0) ==
                  -1) {
            log('do nothing ');
          } else if (diagonalTempMap['firstSymbol']!.data!['id'].codeUnitAt(0) -
                  symbol.data!['id'].codeUnitAt(0) ==
              0) {
            diagonalTempMap.clear();
            isWatingForSecondSymbolTap(false);
            log(diagonalTempMap.toString());
            log(isWatingForSecondSymbolTap.value.toString());
            log(symbol.data!['id']);
            await mapBoxcontrollerInstance!
                .updateSymbol(symbol, const SymbolOptions(textColor: 'black'));
            update();
          } else {}
        }
      }
    });
  }

// Drawing functions Section Start

  drawPolygon() async {
    List<List> localList = List.from(listOfDrawLatLlongs);

    if (listOfDrawLatLlongs.length > 2) {
      localList.add(listOfDrawLatLlongs[0]);
      try {
        Map<String, dynamic> dummyData = {
          "type": "FeatureCollection",
          "features": [
            {
              "type": "Feature",
              "properties": {
                "customType": "polygon",
              },
              "geometry": {
                "coordinates": [localList],
                "type": "Polygon"
              }
            }
          ]
        };

        await mapBoxcontrollerInstance!.addGeoJsonSource(
          'draw_source',
          dummyData,
        );

        await mapBoxcontrollerInstance!.addLayer(
            'draw_source',
            'draw_polygon_layer',
            const FillLayerProperties(
              fillColor: 'blue',
              fillOpacity: 0.1,
              fillOutlineColor: 'red',
            ),
            belowLayerId: 'targetMarker');
        // selectSymbol();
        // drawline();
        // drawPolyline();
      } catch (e) {
        debugPrint('exception thrown from controller $e');
      }
    }

    drawline();
//     mapBoxcontrollerInstance!.addListener(() {
//       mapBoxcontrollerInstance!.onCameraIdle!(
//         drawActive()
//       );
// drawActive () {
//         EasyDebounce.debounce(
//             'my-debouncer', // <-- An ID for this particular debouncer
//             const Duration(milliseconds: 200), // <-- The debounce duration
//             () => drawActiveline() // <-- The target method
//             );
//       }
//     });

    update();
  }

  drawline() async {
    if (listOfDrawLatLlongs.isNotEmpty) {
      List<List> localList = List.from(listOfDrawLatLlongs);
      try {
        if (listOfDrawLatLlongs.length > 1) {
          localList.add(listOfDrawLatLlongs[0]);
        }

        Map<String, dynamic> dummyData = {};
        late List<Map> polylines = [];
        for (int i = 0; i < localList.length - 1; i++) {
          polylines.add({
            "type": "Feature",
            "properties": {
              "customType": "measuringLine",
              "name": i < 26 && localList.length - 2 == i
                  ? String.fromCharCode(i + 65) + String.fromCharCode(0 + 65)
                  : String.fromCharCode(i + 65) +
                      String.fromCharCode(i + 1 + 65)
            },
            "geometry": {
              "type": "LineString",
              "coordinates": [
                localList[i],
                localList[i + 1],
              ]
            }
          });
        }

        dummyData = {"type": "FeatureCollection", "features": polylines};

        try {
          mapBoxcontrollerInstance!.removeLayer('draw_layer_line');
          await mapBoxcontrollerInstance!.removeSource('draw_line_source');
        } catch (e) {
          log('layer does not exit ');
        }

        await mapBoxcontrollerInstance!.addGeoJsonSource(
          'draw_line_source',
          dummyData,
        );

        await mapBoxcontrollerInstance!.addLayer(
            'draw_line_source',
            'draw_layer_line',
            const LineLayerProperties(
              lineColor: '#d4af37',
              lineWidth: 1.5,
            ));

        drawDrawIcons(mapBoxcontrollerInstance!, listOfDrawLatLlongs);
      } catch (e) {
        debugPrint('exception thrown from controller $e');
      }
    }
  }

  saveDiagonals() {
    //Get sides number of polygons  without diagonals
    List<String> listOfSideswithDiagonals =
        List.from(polylineWithLengthMap.keys);
    List<String> listOfSideswithOutDiagonals = [];
    for (String side in listOfSideswithDiagonals) {
      if (side.codeUnitAt(1) - side.codeUnitAt(0) == 1) {
        listOfSideswithOutDiagonals.add(side);
      }
    }
    int numberofDiagonalDrawn = symbolListOnlyDiagonal.length;
    //-2 as  last side  name is LastVertext+FirstextVertext and
    //side.codeUnitAt(1) - side.codeUnitAt(0) == 1 will not work so we will miss one side so instead of -3 we did -2
    int nubmerOfDiagonalsRequired = listOfSideswithOutDiagonals.length - 2;
    // if () ;
    log('save diagonal ${((numberofDiagonalDrawn * 2 - (numberofDiagonalDrawn == 1 || numberofDiagonalDrawn == 0 ? 0 : 1)))}== ${(nubmerOfDiagonalsRequired)}}');
    if (nubmerOfDiagonalsRequired < 2) {
      if (numberofDiagonalDrawn == 1 && 1 == nubmerOfDiagonalsRequired) {
        isDiagonalSaved(true);
      } else if (numberofDiagonalDrawn == 0 && 0 == nubmerOfDiagonalsRequired) {
        isDiagonalSaved(true);
      } else {
        Get.dialog(SimpleDialog(
            contentPadding: const EdgeInsets.all(8),
            title: Text(
              '"Please Draw all the required diagons \nYou have drawn $numberofDiagonalDrawn out of $nubmerOfDiagonalsRequired"',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      Get.back();
                    },
                    child: const Text(
                      'OK',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ]));
      }
    } else if (((numberofDiagonalDrawn)) == nubmerOfDiagonalsRequired) {
      isDiagonalSaved(true);
    } else {
      Get.dialog(SimpleDialog(
          contentPadding: const EdgeInsets.all(8),
          title: Text(
            '"Please Draw all the required diagonals \nYou have drawn $numberofDiagonalDrawn out of $nubmerOfDiagonalsRequired"',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    Get.back();
                  },
                  child: const Text(
                    'OK',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
          ]));
    }
  }

  drawDiagonalline({fromEditDialogue = false, linename, centerlatlng}) async {
    if (fromEditDialogue) {
      Symbol localSymbolLen = await mapBoxcontrollerInstance!.addSymbol(
        SymbolOptions(
          draggable: false,
          geometry: LatLng(centerlatlng[0], centerlatlng[1]),
          // iconImage: 'edit_pen',
          // iconSize: 0.4,
          iconOffset: const Offset(12, 0),
          textOffset: const Offset(-2, 0),
          textField:
              "${polylineWithLengthMap[linename]!.toStringAsFixed(2)} unit",
          textColor: 'green',
          textSize: 14,
          textHaloWidth: 5.0,
          textHaloColor: 'white',
        ),
        {'id': linename},
      );
      symbolListOnlyDiagonal.add(localSymbolLen);
    } else {
      try {
        int asciiValueFirstSymbol =
            diagonalTempMap['firstSymbol']!.data!['id'].codeUnitAt(0);
        int asciiValueSecondSymbol =
            diagonalTempMap['secondSymbol']!.data!['id'].codeUnitAt(0);
        List<LatLng> polyline = [
          LatLng(diagonalTempMap["firstSymbol"]!.options.geometry!.latitude,
              diagonalTempMap["firstSymbol"]!.options.geometry!.longitude),
          LatLng(diagonalTempMap["secondSymbol"]!.options.geometry!.latitude,
              diagonalTempMap["secondSymbol"]!.options.geometry!.longitude),
        ];

        String diagonalName = asciiValueFirstSymbol > asciiValueSecondSymbol
            ? diagonalTempMap['secondSymbol']!.data!['id'] +
                diagonalTempMap['firstSymbol']!.data!['id']
            : diagonalTempMap['firstSymbol']!.data!['id'] +
                diagonalTempMap['secondSymbol']!.data!['id'];

        double sumLat = 0;
        double sumLng = 0;

        for (var point in polyline) {
          sumLat += point.latitude;
          sumLng += point.longitude;
        }
        num length = 0.0;
        //  toolkit.SphericalUtil.computeLength(polyline);

        LatLng centerLatlng =
            LatLng(sumLat / polyline.length, sumLng / polyline.length);
        Map<String, dynamic> dummyData = {
          "type": "FeatureCollection",
          "features": [
            {
              "type": "Feature",
              "properties": {
                "customType": "diagonal",
                "name": diagonalName,
                "centerLatng": centerLatlng
              },
              "geometry": {
                "type": "LineString",
                "coordinates": [
                  [
                    diagonalTempMap["firstSymbol"]!.options.geometry!.longitude,
                    diagonalTempMap["firstSymbol"]!.options.geometry!.latitude
                  ],
                  [
                    diagonalTempMap["secondSymbol"]!
                        .options
                        .geometry!
                        .longitude,
                    diagonalTempMap["secondSymbol"]!.options.geometry!.latitude
                  ]
                ]
              }
            }
          ]
        };
//Naming layers according to id from symbol property
        try {
          mapBoxcontrollerInstance!.removeLayer(diagonalName);
          await mapBoxcontrollerInstance!.removeSource(diagonalName);
        } catch (e) {
          log('layer does not exit ');
        }

        await mapBoxcontrollerInstance!.addGeoJsonSource(
          diagonalName,
          dummyData,
        );

        await mapBoxcontrollerInstance!.addLayer(
            diagonalName,
            diagonalName,
            const LineLayerProperties(
              lineColor: 'red',
              lineWidth: 1.5,
            ),
            belowLayerId: 'draw_layer_point');
        //save diagonals layers to later access and remove them
        diagonalLayerCollection.add(diagonalName);

        //To save new lines into map of lengths
        polylineWithLengthMap[diagonalName] = length.toDouble();

        //clearing temporary map of diagonals for new and updating the default color
        for (var element in diagonalTempMap.values) {
          await mapBoxcontrollerInstance!
              .updateSymbol(element, const SymbolOptions(textColor: 'green'));
        }

        //creating text symbols to show diagonals length

        Symbol localSymbolLen = await mapBoxcontrollerInstance!.addSymbol(
          SymbolOptions(
            draggable: false,
            geometry: centerLatlng,
            // iconImage: 'edit_pen',
            // iconSize: 0.4,
            iconOffset: const Offset(12, 0),
            textOffset: const Offset(-2, 0),
            textField:
                '${polylineWithLengthMap[diagonalName]!.toStringAsFixed(2)} unit',
            textColor: 'green',
            textSize: 14,
            textHaloWidth: 5.0,
            textHaloColor: 'white',
          ),
          {'id': 'lengthmarker$diagonalName'},
        );

        symbolListOnlyDiagonal.add(localSymbolLen);
        //clearing diagonals data for next diagonal
        diagonalTempMap.clear();
      } catch (e) {
        debugPrint('exception thrown from controller $e');
      }
    }
  }

  void removeDiagonallayers() async {
    //removing layer
    for (var diagonal in diagonalLayerCollection) {
      try {
        mapBoxcontrollerInstance!.removeLayer(diagonal);
        await mapBoxcontrollerInstance!.removeSource(diagonal);
        //remove from map of side with length
        polylineWithLengthMap.remove(diagonal);
      } catch (e) {
        log('layer does not exit ');
      }
    }

    //clearing diagonal colection
    diagonalLayerCollection.clear();
    removeDiagonaSymbols();
  }

  void removeDiagonaSymbols() async {
    mapBoxcontrollerInstance!.removeSymbols(symbolListOnlyDiagonal);
    symbolListOnlyDiagonal.clear();
  }

  drawActiveline() async {
    if (listOfDrawLatLlongs.isNotEmpty) {
      if (listOfDrawLatLlongs.length < 3) {
        areaOfPolygon(0.0);
        dropItems = {
          'Sq. meter': 0.00,
          'Acre': 0.00,
          'Bigha': 0.00,
          'kattha': 0.00,
          'Dhur': 0.00,
          'Ropani': 0.00,
          'Aana': 0.00,
          'Paisa:': 0.00,
          'Dam': 0.00,
          'Sq. feet': 0.00
        };
        populateDropdownList();
        mixedconveresion('0 ropani, 0 aana, 0 paisa,0 dam');
      }
      try {
        LatLng? latlang = mapBoxcontrollerInstance!.cameraPosition!.target;

        Map<String, dynamic> dummyData = {
          "type": "FeatureCollection",
          "features": [
            {
              "type": "Feature",
              "properties": {},
              "geometry": {
                "coordinates": [
                  listOfDrawLatLlongs.last,
                  [latlang.longitude, latlang.latitude]
                ], //listOfDrawLatLlongs,
                "type": "LineString"
              }
            }
          ]
        };
        try {
          mapBoxcontrollerInstance!.removeLayer('draw_active_layer_line');
          await mapBoxcontrollerInstance!
              .removeSource('draw_active_line_source');
        } catch (e) {
          log('layer does not exit ');
        }
        if (!isPolygonSaved.value) {
          await mapBoxcontrollerInstance!.addGeoJsonSource(
            'draw_active_line_source',
            dummyData,
          );

          await mapBoxcontrollerInstance!.addLayer(
            'draw_active_line_source',
            'draw_active_layer_line',
            const LineLayerProperties(
                lineColor: '#6CB861', lineWidth: 1, linePattern: 2),
            belowLayerId: 'draw_layer_point',
          );
        }
      } catch (e) {
        debugPrint('exception thrown from controller $e');
      }
    } else {
      try {
        mapBoxcontrollerInstance!.removeLayer('draw_active_layer_line');
        await mapBoxcontrollerInstance!.removeSource('draw_active_line_source');
      } catch (e) {
        log('layer does not exit ');
      }
      areaOfPolygon(0.0);
      dropItems = {
        'Sq. meter': 0.00,
        'Acre': 0.00,
        'Bigha': 0.00,
        'kattha': 0.00,
        'Dhur': 0.00,
        'Ropani': 0.00,
        'Aana': 0.00,
        'Paisa:': 0.00,
        'Dam': 0.00,
        'Sq. feet': 0.00
      };
      populateDropdownList();
      mixedconveresion('0 ropani, 0 aana, 0 paisa,0 dam');
    }
  }

  Future<void> drawDrawIcons(MapboxMapController controller, list) async {
    List<List> localList = List.from(list);

    Map<String, dynamic> dummyData = {
      "type": "FeatureCollection",
      "features": localList
          .map((e) => {
                "type": "Feature",
                "properties": {},
                "geometry": {"coordinates": e, "type": "Point"}
              })
          .toList()
    };
    await mapBoxcontrollerInstance!.addSource(
        "draw_point_source",
        GeojsonSourceProperties(
            data: dummyData,
            cluster: false,
            clusterMaxZoom: 14, // Max zoom to cluster points on
            clusterRadius:
                50 // Radius of each cluster when clustering points (defaults to 50)

            ));

    mapBoxcontrollerInstance!.addLayer(
      "draw_point_source",
      "draw_layer_point",
      const CircleLayerProperties(
          circleColor: 'white',
          circleOpacity: 0.9,
          circleRadius: 6,
          circleStrokeColor: '#6CB861',
          circleStrokeWidth: 2),
    );
  }

  removeDrawing() async {
    try {
      mapBoxcontrollerInstance!.removeLayer('draw_polygon_layer');

      await mapBoxcontrollerInstance!.removeSource('draw_source');
    } catch (e) {
      log('layer does not exit ');
    }

    try {
      mapBoxcontrollerInstance!.removeLayer('draw_layer_line');
      await mapBoxcontrollerInstance!.removeSource('draw_line_source');
    } catch (e) {
      log('layer does not exit ');
    }

    try {
      mapBoxcontrollerInstance!.removeLayer('draw_layer_point');

      await mapBoxcontrollerInstance!.removeSource('draw_point_source');
    } catch (e) {
      log('layer does not exit ');
    }
  }

  savePolygonFun(
      {fromEditLineDialogue = false, fromRecalculate = false}) async {
    if (!fromRecalculate) {
      if (fromEditLineDialogue) {
        List<List> localList = List.from(listOfDrawLatLlongs);
        if (listOfDrawLatLlongs.length > 2) {
          localList.add(listOfDrawLatLlongs[0]);
          for (var i = 0; i < localList.length - 1; i++) {
            List<LatLng> polyline = [
              LatLng(localList[i][1], localList[i][0]),
              LatLng(localList[i + 1][1], localList[i + 1][0]),
            ];

            double sumLat = 0;
            double sumLng = 0;

            for (var point in polyline) {
              sumLat += point.latitude;
              sumLng += point.longitude;
            }
            num length = 0.0;
            // toolkit.SphericalUtil.computeLength(polyline);

            LatLng centerLatlng =
                LatLng(sumLat / polyline.length, sumLng / polyline.length);
            if (!(fromEditLineDialogue || fromRecalculate)) {
              polylineWithLengthMap[i < 26 && localList.length - 2 == i
                  ? String.fromCharCode(i + 65) + String.fromCharCode(0 + 65)
                  : String.fromCharCode(i + 65) +
                      String.fromCharCode(i + 1 + 65)] = length.toDouble();
            }
            Symbol localSymbolLen = await mapBoxcontrollerInstance!.addSymbol(
              SymbolOptions(
                draggable: false,
                geometry: centerLatlng,
                // iconImage: 'edit_pen',
                // iconSize: 0.4,
                iconOffset: const Offset(12, 0),
                textOffset: const Offset(-2, 0),
                textField:
                    '${polylineWithLengthMap[i < 26 && localList.length - 2 == i ? String.fromCharCode(i + 65) + String.fromCharCode(0 + 65) : String.fromCharCode(i + 65) + String.fromCharCode(i + 1 + 65)]!.toStringAsFixed(2)} unit',
                textColor: 'green',
                textSize: 14,
                textHaloWidth: 5.0,
                textHaloColor: 'white',
              ),
              {'id': 'lengthmarker$i'},
            );
            symbolList.add(localSymbolLen);
          }
        }
      } else {
        try {
          mapBoxcontrollerInstance!.removeLayer('draw_active_layer_line');
          await mapBoxcontrollerInstance!
              .removeSource('draw_active_line_source');
        } catch (e) {
          log('layer does not exit ');
        }
        List<List> localList = List.from(listOfDrawLatLlongs);

        if (listOfDrawLatLlongs.length > 2) {
          localList.add(listOfDrawLatLlongs[0]);
          for (var i = 0; i < localList.length - 1; i++) {
            List<LatLng> polyline = [
              LatLng(localList[i][1], localList[i][0]),
              LatLng(localList[i + 1][1], localList[i + 1][0]),
            ];

            double sumLat = 0;
            double sumLng = 0;

            for (var point in polyline) {
              sumLat += point.latitude;
              sumLng += point.longitude;
            }
            num length = 0.0;
            // toolkit.SphericalUtil.computeLength(polyline);

            LatLng centerLatlng =
                LatLng(sumLat / polyline.length, sumLng / polyline.length);
            if (!(fromEditLineDialogue || fromRecalculate)) {
              polylineWithLengthMap[i < 26 && localList.length - 2 == i
                  ? String.fromCharCode(i + 65) + String.fromCharCode(0 + 65)
                  : String.fromCharCode(i + 65) +
                      String.fromCharCode(i + 1 + 65)] = length.toDouble();
            }

            Symbol localSymbolLen = await mapBoxcontrollerInstance!.addSymbol(
              SymbolOptions(
                draggable: false,
                geometry: centerLatlng,
                // iconImage: 'edit_pen',
                // iconSize: 0.4,
                iconOffset: const Offset(12, 0),
                textOffset: const Offset(-2, 0),
                textField:
                    '${polylineWithLengthMap[i < 26 && localList.length - 2 == i ? String.fromCharCode(i + 65) + String.fromCharCode(0 + 65) : String.fromCharCode(i + 65) + String.fromCharCode(i + 1 + 65)]!.toStringAsFixed(2)} unit',
                textColor: 'green',
                textSize: 14,
                textHaloWidth: 5.0,
                textHaloColor: 'white',
              ),
              {'id': 'lengthmarker$i'},
            );
            symbolList.add(localSymbolLen);
            Symbol localSymbolABCD = await mapBoxcontrollerInstance!.addSymbol(
              SymbolOptions(
                draggable: false,
                geometry: LatLng(localList[i][1], localList[i][0]),
                // iconImage: 'edit_pen',
                // iconSize: 0.4,
                textOffset: const Offset(-1.5, 0),
                textField: i < 26
                    ? String.fromCharCode(i + 65)
                    : String.fromCharCode(i + 71),
                textColor: 'green',
                textSize: 22,
                textHaloWidth: 2.0,
                textHaloColor: 'white',
              ),
              {
                'id': i < 26
                    ? String.fromCharCode(i + 65)
                    : String.fromCharCode(i + 71)
              },
            );

            symbolList.add(localSymbolABCD);
            if (i == localList.length - 2) {
              lastVertext = String.fromCharCode(i + 65);
            }
          }
        }

        isPolygonSaved(true);
        isDiagonalStarted(true);
      }
    }
  }

  //
  //
  //
//
//
//
//
  calculateArea({fromEditDialogueBox = false}) {
    List<List<double?>> separateTrianglesvar;
    double totalAreavar;
    double tempArea = 0.0;
    if (!fromEditDialogueBox) {
      separateTrianglesvar =
          separateTriangles(polylineWithLengthMap, lastVertext);
      totalAreavar = totalArea(separateTrianglesvar);
      tempArea = totalAreavar;
    }

    dropItems = {
      'Sq. meter': tempArea,
      'Acre': tempArea / 4046.86,
      'Bigha': tempArea / 6772.631616,
      'kattha': tempArea / 338.6315808,
      'Dhur': tempArea / 16.93157904,
      'Ropani': tempArea / 508.737047,
      'Aana': tempArea / 31.79606544,
      'Paisa:': tempArea / 7.94901636,
      'Dam': tempArea / 1.98725409,
      'Sq. feet': tempArea / 0.09290304
    };

    populateDropdownList();

    //Convert into mixed units
    double dam = tempArea / 1.98725409;
    int ropani, aana, paisa;

    ropani = dam ~/ 256;

    aana = ((dam - (ropani * 256))) ~/ 16;
    paisa = (dam - (ropani * 256) - (aana * 16)) ~/ 4;

    dam = dam - (ropani * 256) - (aana * 16) - (paisa * 4);

    mixedconveresion(
        '$ropani ropani, $aana aana, $paisa paisa,${dam.toStringAsFixed(3)} dam');
    //Mixed unit conversion ends

    /// Checking if the dropdown value is in the list of values.
    if (['Ropani', 'Aana', 'Aana', 'Paisa:', 'Dam']
        .contains(dropdownvalue.value)) {
      isShowMixedconveresion(true);
    } else {
      isShowMixedconveresion(false);
    }

    /// The above code is calculating the area of a polygon.
    areaOfPolygon(tempArea);
  }

  double totalArea(List<List<double?>> triangles) {
    double sum = 0;
    for (List<double?> triangle in triangles) {
      double? a = triangle[0];
      double? b = triangle[1];
      double? c = triangle[2];
      double? s = (a! + b! + c!) / 2;
      sum += math.sqrt(s * (s - a) * (s - b) * (s - c));
    }
    return sum;
  }

  List<List<double?>> separateTriangles(
      Map<String, double> sidesMap, lastVertext) {
    //Get empty sides with zero length
    List<String> sidesWithZeroLength = [];
    for (var key in polylineWithLengthMap.keys) {
      if (polylineWithLengthMap[key] == 0) {
        sidesWithZeroLength.add(key);
      }
    }

    //Step 1 : method to check how many lines are attached to vetex A,B,C.....
    List<List<double?>> triangles = [];
    List<String> listOfSides = List.from(sidesMap.keys);
    Map<String, List<String>> vetexSidesMap = {};
    for (var vertext in listOfSides) {
      List<String> tempSide = [];
      for (var i = 0; i < listOfSides.length; i++) {
        log('keys ${vertext[0] + listOfSides[i][0]}');
        if (sidesMap[vertext[0] + String.fromCharCode(i + 65)] != null) {
          tempSide.add(vertext[0] + listOfSides[i][0]);
        } else if (vertext[0] == "A" && i == listOfSides.length - 1) {
          tempSide.add(lastVertext + "A");
        }
      }
      vetexSidesMap[vertext[0]] = tempSide;
    }

    log("Step 1 ${vetexSidesMap.toString()}");
    //Step 2: extracting triangles form map of vetxSides

    for (var vetex in vetexSidesMap.keys) {
      for (int i = 0; i < vetexSidesMap[vetex]!.length - 1; i++) {
        triangles.add([
          sidesMap[vetexSidesMap[vetex]![i]],
          sidesMap[vetexSidesMap[vetex]![i + 1]],
          sidesMap[vetexSidesMap[vetex]![i][1] +
                  vetexSidesMap[vetex]![i + 1][1]] ??
              sidesMap[
                  vetexSidesMap[vetex]![i][1] + vetexSidesMap[vetex]![i + 1][0]]
        ]);
      }
    }

// list of triangles

    for (List<double?> triangle in triangles) {
      double? a = triangle[0];
      double? b = triangle[1];
      double? c = triangle[2];

      // Check if any side length is null or zero
      if (a == null || b == null || c == null || a == 0 || b == 0 || c == 0) {
        Get.dialog(SimpleDialog(
            contentPadding: const EdgeInsets.all(8),
            title: Text(
              '"Invalid triangle: does not satisfy triangle inequality theorem\nsome of these  sides are 0.0 \n$sidesWithZeroLength "',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      Get.back();
                    },
                    child: const Text(
                      'OK',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ]));

        triangles.clear();
        break;
      }

      // Check if triangle satisfies triangle inequality theorem
      if (a + b >= c && a + c >= b && b + c >= a) {
        // Triangle is a valid geometric triangle
      } else {
        Get.dialog(SimpleDialog(
            contentPadding: const EdgeInsets.all(8),
            title: const Text(
              '"Invalid triangle: does not satisfy triangle inequality theorem"\nMake sure you have entered correct length of the sides',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      Get.back();
                    },
                    child: const Text(
                      'OK',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ]));
        triangles.clear();
        break;
      }
    }

    return triangles;
  }

  removeSymbols() {
    mapBoxcontrollerInstance!.removeSymbols(symbolList);
    symbolList.clear();
  }

  Widget drawPad() {
    return GetX<MapBoxGetController>(builder: (controller) {
      return SnappingSheet(
        snappingPositions: const [
          SnappingPosition.factor(
            positionFactor: 0.25,
            snappingCurve: Curves.easeOutExpo,
            snappingDuration: Duration(seconds: 1),
            grabbingContentOffset: GrabbingContentOffset.middle,
          ),
        ],
        sheetBelow: SnappingSheetContent(child: snappingSheetContent()),
        grabbingHeight: 0,
        grabbing: const SizedBox(),
      );
    });
  }

  Widget centerTargetiIcon() {
    return IgnorePointer(
      child: Align(
          alignment: Alignment.center,
          child: Container(
            width: 25.0,
            height: 25.0,
            decoration: const BoxDecoration(
                image: DecorationImage(
                    image: AssetImage(
                        'packages/mapbox_draw_polygon_area/assets/icon/target.png'))),
          )),
    );
  }

  Widget snappingSheetContent() {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: Colors.white,
            ),
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Visibility(
                  visible: !isPolygonSaved.value,
                  child: IconButton(
                    onPressed: () {
                      listOfDrawLatLlongs.removeLast();
                      removeDrawing();
                      drawPolygon();
                      drawActiveline();
                    },
                    icon: const Icon(
                      Icons.undo,
                    ),
                    // FontAwesomeIcons.arrowRotateLeft,
                    color: Colors.black,
                  ),
                ),
                Visibility(
                  visible: !isPolygonSaved.value,
                  child: IconButton(
                      onPressed: () {
                        listOfDrawLatLlongs.clear();
                        removeDrawing();
                        drawActiveline();
                      },
                      icon: const Icon(
                        Icons.phonelink_erase,
                        color: Colors.black,
                      )),
                ),
                isDiagonalSaved.value == true && isPolygonSaved.value == true
                    ? TextButton(
                        style: ButtonStyle(
                            shape: MaterialStateProperty.all<
                                    RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6.0),
                                    side:
                                        const BorderSide(color: Colors.grey)))),
                        onPressed: () async {
                          calculateArea();
                        },
                        child: const Text(
                          'Area Calculate',
                          style: TextStyle(color: Colors.black),
                        ))
                    : TextButton(
                        style: ButtonStyle(
                            shape: MaterialStateProperty.all<
                                    RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6.0),
                                    side:
                                        const BorderSide(color: Colors.grey)))),
                        onPressed: () async {
                          isPolygonSaved.value == true
                              ? saveDiagonals()
                              : savePolygonFun(
                                  fromRecalculate: isPolygonSaved.value == true
                                      ? true
                                      : false);
                        },
                        child: isPolygonSaved.value == true
                            ? const Text(
                                'Save Diagonals',
                                style: TextStyle(color: Colors.black),
                              )
                            : const Text(
                                'Save Polygon',
                                style: TextStyle(color: Colors.black),
                              )),
                Visibility(
                  visible:
                      isPolygonSaved.value == true && !isDiagonalSaved.value,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: TextButton(
                        style: ButtonStyle(
                            shape: MaterialStateProperty.all<
                                    RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6.0),
                                    side:
                                        const BorderSide(color: Colors.grey)))),
                        onPressed: () async {
                          // listOfDrawLatLlongs.clear();
                          // removeDrawing();
                          // drawActiveline();
                          // polylineWithLengthMap.clear();
                          // isPolygonSaved(false);
                          isDiagonalStarted(false);
                          isDiagonalSaved(false);
                          removeDiagonallayers();
                        },
                        child: const Text(
                          'Try again',
                          style: TextStyle(color: Colors.black),
                        )),
                  ),
                ),
                const Expanded(child: SizedBox()),
                IconButton(
                    onPressed: () {
                      isDrawing.value = !isDrawing.value;
                      listOfDrawLatLlongs.clear();
                      removeDrawing();
                      drawActiveline();
                      polylineWithLengthMap.clear();
                      isPolygonSaved(false);
                      isDiagonalStarted(false);
                      isDiagonalSaved(false);
                      removeDiagonallayers();
                      removeSymbols();
                    },
                    icon: const Icon(
                      Icons.close,
                      color: Colors.black,
                    )),
              ],
            ),
            const Divider(
              thickness: 2,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  isDiagonalSaved.value && isPolygonSaved.value
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              " Area  ",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(
                              height: 6,
                            ),
                            GetBuilder<MapBoxGetController>(
                                builder: (controller) {
                              return DropdownButton(
                                underline: const SizedBox(
                                  height: 2,
                                  width: 2,
                                ),
                                // Initial Value
                                value: controller.dropdownvalue.value,

                                // Down Arrow Icon
                                icon: const Icon(Icons.keyboard_arrow_down),

                                // Array list of items
                                items: controller.dropItemListMap,

                                onChanged: (newValue) {
                                  controller.dropDownOnchanged(newValue);
                                },
                              );
                            }),
                          ],
                        )
                      : isPolygonSaved.value
                          ? const Text(
                              "Draw diagonals by clicking on ABCD vertext.",
                              style: TextStyle(fontSize: 16),
                            )
                          : const SizedBox(),
                  Visibility(
                    visible: !isPolygonSaved.value,
                    child: TextButton(
                        style: ButtonStyle(
                            shape: MaterialStateProperty.all<
                                    RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    side:
                                        const BorderSide(color: Colors.grey)))),
                        onPressed: () async {
                          LatLng? latlang =
                              mapBoxcontrollerInstance!.cameraPosition!.target;

                          try {
                            listOfDrawLatLlongs
                                .add([latlang.longitude, latlang.latitude]);

                            removeDrawing();
                            drawPolygon();
                          } catch (e) {
                            Get.snackbar('No latitide ', 'No longitude found');
                          }
                        },
                        child: Row(
                          children: [
                            Container(
                                decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(50.0)),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.grey,
                                )),
                            const SizedBox(
                              width: 8,
                            ),
                            const Text(
                              'Add point',
                              style: TextStyle(color: Colors.black),
                            )
                          ],
                        )),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: GetBuilder<MapBoxGetController>(
                builder: ((controller) {
                  return Visibility(
                      visible: controller.isShowMixedconveresion.value,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: Text(
                          controller.mixedconveresion.value,
                        ),
                      ));
                }),
              ),
            ),
          ],
        ));
  }
}
