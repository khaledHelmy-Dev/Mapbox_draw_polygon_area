import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mapbox_draw_polygon_area/mapbox_draw_polygon_area.dart';

// ignore: must_be_immutable
class EditLenDialogieBox extends StatelessWidget {
  EditLenDialogieBox({Key? key, required this.lineName}) : super(key: key);

  final String lineName;
  final MapBoxGetController mapBoxGetController = Get.find();
  TextEditingController? textController;
  String _textFieldValue = "0.0";

  @override
  Widget build(BuildContext context) {
    _textFieldValue =
        mapBoxGetController.polylineWithLengthMap[lineName].toString();
    return SimpleDialog(
      contentPadding: const EdgeInsets.all(8),
      title: Text(
        'Enter Length for line $lineName in "Meter" ',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16),
      ),
      children: mapBoxGetController.isPolygonSaved.value &&
              mapBoxGetController.isDiagonalSaved.value
          ? [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  onChanged: ((value) {
                    _textFieldValue = value;
                  }),
                  initialValue: mapBoxGetController
                      .polylineWithLengthMap[lineName]
                      .toString(),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Type length in meter',
                    hintStyle: const TextStyle(fontSize: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(
                        width: 0,
                        style: BorderStyle.none,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: const EdgeInsets.all(20),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      try {
                        mapBoxGetController.polylineWithLengthMap[lineName] =
                            double.parse(_textFieldValue);
                        mapBoxGetController.savePolygonFun(
                            fromEditLineDialogue: true);

                        Get.back();
                        mapBoxGetController.calculateArea(
                            fromEditDialogueBox: true);
                      } catch (e) {
                        log('Value null');
                      }
                    },
                    child: const Text(
                      'OK',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Get.back();
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ]
          : [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Please save both polygon and diagonals then  try to edit again.',
                  textAlign: TextAlign.center,
                ),
              )
            ],
    );
  }
}

class EditDiagonalLenDialogieBox extends StatelessWidget {
  EditDiagonalLenDialogieBox(
      {Key? key, required this.lineName, required this.centerLatlangPolyline})
      : super(key: key);
  final dynamic centerLatlangPolyline;
  final String lineName;
  final MapBoxGetController mapBoxGetController = Get.find();
  TextEditingController? textController;
  String _textFieldValue = "0.0";

  @override
  Widget build(BuildContext context) {
    _textFieldValue =
        mapBoxGetController.polylineWithLengthMap[lineName].toString();
    return SimpleDialog(
      contentPadding: const EdgeInsets.all(8),
      title: Text(
        'Enter Length for diagonal $lineName in "Meter" ',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16),
      ),
      children: mapBoxGetController.isPolygonSaved.value &&
              mapBoxGetController.isDiagonalSaved.value
          ? [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  onChanged: ((value) {
                    _textFieldValue = value;
                  }),
                  initialValue: mapBoxGetController
                      .polylineWithLengthMap[lineName]
                      .toString(),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Type length in meter',
                    hintStyle: const TextStyle(fontSize: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(
                        width: 0,
                        style: BorderStyle.none,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: const EdgeInsets.all(20),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      try {
                        mapBoxGetController.polylineWithLengthMap[lineName] =
                            double.parse(_textFieldValue);
                        mapBoxGetController.drawDiagonalline(
                            fromEditDialogue: true,
                            linename: lineName,
                            centerlatlng: centerLatlangPolyline);

                        Get.back();
                        mapBoxGetController.calculateArea(
                            fromEditDialogueBox: true);
                      } catch (e) {
                        log('Value null');
                      }
                    },
                    child: const Text(
                      'OK',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Get.back();
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ]
          : [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Please save diagonals first then try to edit again.',
                  textAlign: TextAlign.center,
                ),
              )
            ],
    );
  }
}
