import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'firebase_options.dart'; // generated via `flutterfire` CLI
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voercalculator',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Boaz\' Voercalculator'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool loading = true;
  FirebaseFirestore db = FirebaseFirestore.instance;
  List<Food> foodItems = [];
  List<Meal> mealItems = [];
  int kcalEatenToday = 0;
  int kcalAllowed = 1000;
  Food? selectedFood;
  Portion? selectedPortion;
  double quantityEaten = 0;

  void loadDataFromDatabase() async {
    var foodDocs = (await db.collection("food").get()).docs;
    var mealDocs = (await db
            .collection("days")
            .doc(DateFormat("yyyy-MM-dd").format(DateTime.now()))
            .collection("meals")
            .get())
        .docs;

    setState(() {
      foodItems = [];
      for (var doc in foodDocs) {
        foodItems.add(Food.create(doc.id, doc.data()));
      }

      mealItems = [];

      for (var doc in mealDocs) {
        Meal meal = Meal.create(doc.id, doc.data());
        mealItems.add(meal);
        kcalEatenToday += meal.kcal;
      }

      selectedFood = foodItems[0];
      selectedPortion = selectedFood?.portions[0];
      quantityEaten = selectedPortion!.defaultAmount;
      loading = false;
    });
  }

  Future<void> addMeal() async {
    int kcalEaten = getKcalEaten();
    var ref = await db
        .collection("days")
        .doc(DateFormat("yyyy-MM-dd")
        .format(DateTime.now()))
        .collection("meals")
        .add({
      "foodId": selectedFood?.id,
      "foodName": selectedFood?.name,
      "unit": selectedPortion?.unit,
      "quantity": quantityEaten,
      "kcal": kcalEaten
    });

    setState(() {
      mealItems.add(Meal(
        ref.id,
          selectedFood!.id,
          selectedFood!.name,
          selectedPortion!.unit,
          quantityEaten,
          getKcalEaten()));
      kcalEatenToday += kcalEaten;
    });
  }

  void deleteMeal(Meal meal) {
    db
        .collection("days")
        .doc(DateFormat("yyyy-MM-dd")
        .format(DateTime.now()))
        .collection("meals").doc(meal.id).delete();

    setState(() {
      mealItems.remove(meal);
      kcalEatenToday -= meal.kcal;
    });
  }

  int getKcalEaten() {
    return ((selectedFood?.kcal ?? 0) / 1000 *
        quantityEaten *
        (selectedPortion?.grams ?? 0)).round();
  }

  @override
  void initState() {
    loadDataFromDatabase();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                // mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const SizedBox(height: 20),
                  CircularPercentIndicator(
                      radius: 60.0,
                      center: Text("${1000 - kcalEatenToday} kcal"),
                      percent:
                          max((kcalAllowed - kcalEatenToday) / kcalAllowed, 0)),
                  const SizedBox(height: 20),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const SelectableText('Eten'),
                    const SizedBox(width: 10),
                    DropdownButton<Food>(
                        value: selectedFood,
                        items: foodItems.map((Food food) {
                          return DropdownMenuItem<Food>(
                              value: food, child: Text(food.name));
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedFood = value;
                            selectedPortion = selectedFood?.portions[0];
                          });
                        }),
                    const SizedBox(width: 10),
                    const SelectableText('Hoeveelheid'),
                    const SizedBox(width: 10),
                    SizedBox(
                        width: 100,
                        child: TextFormField(
                          initialValue:
                              selectedPortion?.defaultAmount.toString(),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true, signed: false),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r"[0-9.]")),
                            TextInputFormatter.withFunction(
                                (oldValue, newValue) {
                              try {
                                final text = newValue.text;
                                if (text.isNotEmpty) double.parse(text);
                                return newValue;
                              } catch (e) {}
                              return oldValue;
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              if (value != "") quantityEaten = double.parse(value);
                            });
                          },
                        )),
                    const SizedBox(width: 10),
                    DropdownButton<Portion>(
                        value: selectedPortion,
                        items: selectedFood?.portions.map((Portion portion) {
                          return DropdownMenuItem<Portion>(
                              value: portion, child: Text(portion.unit));
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedPortion = value;
                          });
                        }),
                    const SizedBox(width: 10),
                    Container(padding: const EdgeInsets.all(5), decoration: const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(30)), color: Colors.blue), child:  Text("${(selectedFood?.kcal ?? 0) / 1000 *
                        quantityEaten *
                        (selectedPortion?.grams ?? 0)} kcal")),
                    const SizedBox(width: 10),
                    IconButton(onPressed: addMeal, icon: const Icon(Icons.add),)
                  ]),
                  const SizedBox(height: 20),
                  ...mealItems.map((Meal meal) =>
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text("${meal.quantity} ${meal.unit} ${meal.foodName} (${meal.kcal} kcal)"), IconButton(iconSize: 15, splashRadius: 15, onPressed: () { deleteDialog(meal); }, icon: const Icon(Icons.delete))])
                  )
                ],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddMealDialog,
          tooltip: 'Increment',
          child: const Icon(Icons.add),
        ));
  }

  _showAddMealDialog() {
    Food? selectedFood = foodItems[0];
    Portion? selectedPortion = foodItems[0].portions[0];
    double quantityEaten = 0;
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, setState) {
            return SimpleDialog(
                title: const Text("Voeg maaltijd toe"),
                children: [
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            padding: EdgeInsets.only(left: 25, right: 25),
                            child: Column(children: [
                              // Row(
                              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              //   children: [
                              const SelectableText('Eten'),
                              DropdownButton<Food>(
                                  value: selectedFood,
                                  items: foodItems.map((Food food) {
                                    return DropdownMenuItem<Food>(
                                        value: food, child: Text(food.name));
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedFood = value;
                                      selectedPortion =
                                          selectedFood?.portions[0];
                                    });
                                    print(selectedFood?.portions[0].unit ??
                                        "No portions");
                                  }),
                              //   ],
                              // ),
                              // Row(
                              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              //   children: [
                              const SelectableText('Hoeveelheid'),
                              TextField(
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true, signed: false),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r"[0-9.]")),
                                  TextInputFormatter.withFunction(
                                      (oldValue, newValue) {
                                    try {
                                      final text = newValue.text;
                                      if (text.isNotEmpty) double.parse(text);
                                      return newValue;
                                    } catch (e) {}
                                    return oldValue;
                                  }),
                                ],
                                onChanged: (value) {
                                  quantityEaten = double.parse(value);
                                },
                              ),
                              DropdownButton<Portion>(
                                  value: selectedPortion,
                                  items: selectedFood?.portions
                                      .map((Portion portion) {
                                    return DropdownMenuItem<Portion>(
                                        value: portion,
                                        child: Text(portion.unit));
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedPortion = value;
                                    });
                                  }),
                              //   ],
                              // )
                            ])),
                        const SizedBox(height: 20),
                        Center(
                            child: Wrap(spacing: 10, children: [
                          OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text('Annuleren')),
                          ElevatedButton(
                              onPressed: () async {
                                double gramsEaten = quantityEaten *
                                    (selectedPortion?.grams ?? 0);
                                int kcalEaten = ((selectedFood?.kcal ?? 0) /
                                    1000 *
                                    gramsEaten) as int;
                                var ref = await db
                                    .collection("days")
                                    .doc(DateFormat("yyyy-MM-dd")
                                        .format(DateTime.now()))
                                    .collection("meals")
                                    .add({
                                  "foodId": selectedFood?.id,
                                  "foodName": selectedFood?.name,
                                  "unit": selectedPortion?.unit,
                                  "quantity": quantityEaten,
                                  "kcal": kcalEaten
                                });
                                setState(() {
                                  mealItems.add(Meal(
                                    ref.id,
                                      selectedFood!.id,
                                      selectedFood!.name,
                                      selectedPortion!.unit,
                                      quantityEaten,
                                      kcalEaten));
                                });
                              },
                              child: Text('Toevoegen')),
                        ]))
                      ])
                ]);
          });
        });
  }

  deleteDialog(Meal meal) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
              title: SelectableText('Training verwijderen'),
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                      padding: EdgeInsets.only(left: 25, right: 25),
                      child: const SelectableText(
                          'Weet je zeker dat je dit wil verwijderen?')),
                  const SizedBox(height: 20),
                  Center(
                      child: Wrap(spacing: 10, children: [
                        OutlinedButton(
                            onPressed: () {
                              deleteMeal(meal);
                              Navigator.pop(context);
                            },
                            child: Text('Ja')),
                        ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text('Nee')),
                      ]))
                ])
              ]);
        });
  }
}

class Food {
  String id;
  String name;
  int kcal;
  List<Portion> portions;

  Food(this.id, this.name, this.kcal, this.portions) {
    id = id;
    name = name;
    kcal = kcal;
    portions = portions;
    portions.add(Portion("gram", 1, 0, false));
  }

  static Food create(String id, Map<String, dynamic> data) {
    List<Portion> portionsList = [];
    if (data.containsKey("portions")) {
      for (var p in data["portions"]) {
        portionsList.add(Portion.create(p));
      }
    }
    return Food(id, data["name"] ?? "", data["kcal"] ?? 0, portionsList);
  }
}

class Portion {
  String unit;
  int grams;
  double defaultAmount;
  bool isDefault;

  Portion(this.unit, this.grams, this.defaultAmount, this.isDefault);

  static Portion create(Map<String, dynamic> data) {
    return Portion(data["unit"] ?? "", data["grams"] ?? 0,
        data["defaultAmount"] ?? 0, data["isDefault"] ?? false);
  }
}

class Meal {
  String id;
  String foodId;
  String foodName;
  String unit;
  double quantity;
  int kcal;

  Meal(this.id, this.foodId, this.foodName, this.unit, this.quantity, this.kcal);

  static Meal create(String id, Map<String, dynamic> data) {
    return Meal(id, data["foodId"], data["foodName"], data["unit"],
        data["quantity"], data["kcal"]);
  }
}
