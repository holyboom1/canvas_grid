import 'dart:math';

import 'package:canvas_grid/canvas_grid.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() {
  runApp(SpaceCanvasApp());
}

class SpaceCanvasApp extends StatefulWidget {
  @override
  State<SpaceCanvasApp> createState() => _SpaceCanvasAppState();
}

Color getRandomColor() {
  final Random random = Random();

  // Генерируем случайные значения для красного, зеленого и синего каналов.
  final int red = random.nextInt(256);
  final int green = random.nextInt(256);
  final int blue = random.nextInt(256);

  // Возвращаем новый цвет.
  return Color.fromARGB(255, red, green, blue);
}

class _SpaceCanvasAppState extends State<SpaceCanvasApp> {
  final SpaceCanvasController controller = SpaceCanvasController(
    getObjects: () {
      return Future.delayed(
        const Duration(milliseconds: 0),
        () => List.generate(
          10,
          (int index) {
            final Color color = getRandomColor();
            final Widget child = GestureDetector(
              onTap: () {
                print('Object $index tapped');
              },
              child: Container(
                width: 1000,
                height: 1000,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: color,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ...List.generate(
                      3,
                      (int i) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            ...List.generate(
                              3,
                              (int i) {
                                return Container(
                                  width: 300,
                                  height: 300,
                                  decoration: BoxDecoration(
                                    color: getRandomColor(),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
            return SpaceObjectModel(
              child: child,
              childSize: const Size(1000, 1000),
            );
          },
        ),
      );
    },
  );

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((Duration timeStamp) {
      controller.init(windowSize: MediaQuery.of(context).size);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: SpaceCanvas(
          controller: controller,
          onObjectTap: (SpaceObjectModel obj) {
            print('Object tapped: ${obj.id}');
          },
        ),
      ),
    );
  }
}
