import 'dart:math';

import 'package:boaz_nutrition_calculator/store.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart'; // generated via `flutterfire` CLI
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

import 'food_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  initializeDateFormatting();
  runApp(GetMaterialApp(
      home: const MyApp(),
      title: "Boaz' Voercalculator",
      theme: ThemeData(
          inputDecorationTheme: const InputDecorationTheme(isDense: true))));
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
  Food? selectedFood;
  Portion? selectedPortion;
  double quantityEaten = 0;
  DateTime selectedDate = DateTime.now();
  List<Meal> mealItems = [];
  int kcalEatenToday = 0;

  void loadDataFromDatabase() async {
    await Store.loadData();

    setState(() {
      selectedFood = Store.activeFoodItems[0];
      selectedPortion =
          selectedFood?.portions.firstWhere((Portion p) => p.isDefault);
      quantityEaten = selectedPortion!.defaultAmount;
      mealItems = Store.mealItems;
      kcalEatenToday = Store.kcalEatenToday;
      loading = false;
    });
  }

  String getDay() {
    int day = selectedDate.day;
    int month = selectedDate.month;
    int year = selectedDate.year;

    final now = DateTime.now();
    if (now.day == day && now.month == month && now.year == year)
      return "Vandaag";

    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    if (yesterday.day == day &&
        yesterday.month == month &&
        yesterday.year == year) return "Gisteren";

    return DateFormat("EEE dd-MM-yyyy", "nl").format(selectedDate);
  }

  Widget getAddMealWidget() {
    Widget quickAddButtons = Wrap(
        spacing: 5,
        runSpacing: 5,
        children: Store.quickAddItems
            .map((i) => Tooltip(
                message:
                    "${i.portion.defaultAmount} ${i.portion.unit} ${i.food.name}",
                child: SizedBox(
                    width: 200,
                    child: ElevatedButton.icon(
                        onPressed: () {
                          addMeal(i.food, i.portion, i.portion.defaultAmount);
                        },
                        icon: const Icon(Icons.add),
                        label: Text(
                          "${i.portion.defaultAmount} ${i.portion.unit} ${i.food.name}",
                          overflow: TextOverflow.ellipsis,
                        )))))
            .toList());
    Widget foodLabel = const SelectableText('Eten');
    Widget foodDropdown = DropdownButton<Food>(
        value: selectedFood,
        items: Store.activeFoodItems.map((Food food) {
          return DropdownMenuItem<Food>(value: food, child: Text(food.name));
        }).toList(),
        onChanged: (value) {
          setState(() {
            selectedFood = value;
            selectedPortion = selectedFood?.portions[0];
          });
        });
    Widget quantityLabel = const SelectableText('Hoeveelheid');
    Widget quantityNumber = SizedBox(
        width: 30,
        child: TextFormField(
          decoration: InputDecoration(isDense: true),
          initialValue: selectedPortion?.defaultAmount.toString(),
          keyboardType: const TextInputType.numberWithOptions(
              decimal: true, signed: false),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r"[0-9.]")),
            TextInputFormatter.withFunction((oldValue, newValue) {
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
        ));
    Widget unitDropdown = DropdownButton<Portion>(
        value: selectedPortion,
        items: selectedFood?.portions.map((Portion portion) {
          return DropdownMenuItem<Portion>(
              value: portion, child: Text(portion.unit));
        }).toList(),
        onChanged: (value) {
          setState(() {
            selectedPortion = value;
          });
        });
    Widget kcalLabel = Container(
        padding: const EdgeInsets.only(top: 5, bottom: 5, left: 10, right: 10),
        decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(30)),
            color: Colors.blue),
        child: Text(
            "${(selectedFood?.kcal ?? 0) / 1000 * quantityEaten * (selectedPortion?.grams ?? 0)} kcal"));
    Widget addButton = IconButton(
        onPressed: selectedFood != null && selectedPortion != null
            ? () => addMeal(selectedFood!, selectedPortion!, quantityEaten)
            : null,
        icon: const Icon(Icons.add));

    return Center(
        child: Container(
            margin: const EdgeInsets.all(15.0),
            padding: const EdgeInsets.all(15.0),
            decoration: BoxDecoration(border: Border.all()),
            child: Column(children: [
              quickAddButtons,
              MediaQuery.of(context).size.width >= 700
                  ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      foodLabel,
                      const SizedBox(width: 10),
                      foodDropdown,
                      const SizedBox(width: 10),
                      quantityLabel,
                      const SizedBox(width: 10),
                      quantityNumber,
                      const SizedBox(width: 10),
                      unitDropdown,
                      const SizedBox(width: 10),
                      kcalLabel,
                      const SizedBox(width: 10),
                      addButton
                    ])
                  : Column(
                      children: [
                        if (Store.quickAddItems.isNotEmpty)
                          const SizedBox(height: 10),
                        foodLabel,
                        const SizedBox(height: 10),
                        foodDropdown,
                        const SizedBox(height: 10),
                        quantityLabel,
                        const SizedBox(height: 10),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              quantityNumber,
                              const SizedBox(width: 10),
                              unitDropdown,
                            ]),
                        const SizedBox(height: 10),
                        kcalLabel,
                        const SizedBox(height: 10),
                        addButton
                      ],
                    )
            ])));
  }

  Future<void> addMeal(Food food, Portion portion, quantityEaten) async {
    await Store.addMeal(food, portion, quantityEaten, selectedDate);
    setState(() {
      mealItems = Store.mealItems;
    });
  }

  Future<void> removeMeal(Meal meal) async {
    await Store.removeMeal(meal);
    setState(() {
      mealItems = Store.mealItems;
    });
  }

  void chooseDate(DateTime date) async {
    selectedDate = date;
    await Store.loadMealsForDate(date);
    setState(() {
      mealItems = Store.mealItems;
    });
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
            actions: <Widget>[
              Padding(
                  padding: EdgeInsets.only(right: 20.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (context) => const FoodSettings()),
                      );
                    },
                    child: Icon(
                      Icons.settings,
                      size: 26.0,
                    ),
                  )),
            ]),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                // mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                            width: MediaQuery.of(context).size.width >= 500
                                ? 100
                                : 50,
                            child: TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    chooseDate(selectedDate
                                        .subtract(const Duration(days: 1)));
                                  });
                                },
                                icon: const Icon(Icons.keyboard_arrow_left),
                                label: Text(
                                    MediaQuery.of(context).size.width >= 500
                                        ? 'Vorige'
                                        : ''))),
                        Text(getDay()),
                        SizedBox(
                            width: MediaQuery.of(context).size.width >= 500
                                ? 100
                                : 50,
                            child: getDay() != "Vandaag"
                                ? TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        chooseDate(selectedDate
                                            .add(const Duration(days: 1)));
                                      });
                                    },
                                    label:
                                        const Icon(Icons.keyboard_arrow_right),
                                    icon: Text(
                                      MediaQuery.of(context).size.width >= 500
                                          ? 'Volgende'
                                          : '',
                                    ))
                                : Container())
                      ]),
                  const SizedBox(height: 20),
                  CircularPercentIndicator(
                      radius: 60.0,
                      center: Text("${1000 - Store.kcalEatenToday} kcal"),
                      percent: max(
                          (Store.kcalAllowed - Store.kcalEatenToday) /
                              Store.kcalAllowed,
                          0)),
                  const SizedBox(height: 20),
                  getAddMealWidget(),
                  const SizedBox(height: 20),
                  ...Store.mealItems.map((Meal meal) => Container(
                      margin: const EdgeInsets.only(left: 15, right: 15),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                                width: MediaQuery.of(context).size.width - 120,
                                child: Text(
                                  "${meal.quantity} ${meal.unit} ${meal.foodName} (${meal.kcal} kcal)",
                                  overflow: TextOverflow.ellipsis,
                                )),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                      padding: const EdgeInsets.all(3),
                                      constraints: const BoxConstraints(),
                                      iconSize: 17,
                                      splashRadius: 13,
                                      onPressed: () {
                                        infoDialog(meal);
                                      },
                                      icon: const Icon(Icons.info)),
                                  IconButton(
                                      padding: const EdgeInsets.all(3),
                                      constraints: const BoxConstraints(),
                                      iconSize: 18,
                                      splashRadius: 13,
                                      onPressed: () {
                                        deleteDialog(meal);
                                      },
                                      icon: const Icon(Icons.delete)),
                                ])
                          ]))),
                  const SizedBox(height: 20)
                ],
              )));
  }

  deleteDialog(Meal meal) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
              title: const SelectableText('Maaltijd verwijderen'),
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                      padding: const EdgeInsets.only(left: 25, right: 25),
                      child: const SelectableText(
                          'Weet je zeker dat je deze maaltijd wil verwijderen?')),
                  const SizedBox(height: 20),
                  Center(
                      child: Wrap(spacing: 10, children: [
                    OutlinedButton(
                        onPressed: () {
                          removeMeal(meal);
                          Navigator.pop(context);
                        },
                        child: const Text('Ja')),
                    ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Nee')),
                  ]))
                ])
              ]);
        });
  }

  infoDialog(Meal meal) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
              title: const SelectableText('Details'),
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                      padding: const EdgeInsets.only(left: 25, right: 25),
                      child: SelectableText('Eten: ${meal.foodName}')),
                  const SizedBox(height: 10),
                  Container(
                      padding: const EdgeInsets.only(left: 25, right: 25),
                      child: SelectableText(
                          'Hoeveelheid: ${meal.quantity} ${meal.unit}')),
                  const SizedBox(height: 10),
                  Container(
                      padding: const EdgeInsets.only(left: 25, right: 25),
                      child: SelectableText(meal.added == null
                          ? "Toegevoegd om: -"
                          : 'Toegevoegd om: ${DateFormat("HH:mm").format(meal.added!)} uur')),
                  const SizedBox(height: 20),
                  Center(
                      child: Wrap(spacing: 10, children: [
                    ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Sluiten')),
                  ]))
                ])
              ]);
        });
  }
}
