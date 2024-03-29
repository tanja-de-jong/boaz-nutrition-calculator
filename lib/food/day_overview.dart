import 'dart:math';

import 'package:boaz_nutrition_calculator/database/food_store.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:text_helpers/text_helpers.dart';

import 'food_settings.dart';

class DayOverview extends StatefulWidget {
  const DayOverview({Key? key}) : super(key: key);

  @override
  State<DayOverview> createState() => _DayOverviewState();
}

class _DayOverviewState extends State<DayOverview> {
  bool loading = true;
  Food? selectedFood;
  Portion? selectedPortion;
  double quantityEaten = 0;
  DateTime selectedDate = DateTime.now();
  List<Meal> mealItems = [];
  int kcalEatenToday = 0;
  String? comment;
  TextEditingController quantityController = TextEditingController();
  TextEditingController commentController = TextEditingController();

  void loadDataFromDatabase() async {
    await Store.loadData();

    setState(() {
      selectedFood = Store.activeFoodItems[0];
      selectedPortion = selectedFood?.portions.firstWhere(
          (Portion p) => p.isDefault,
          orElse: () => selectedFood!.portions.last);
      quantityEaten = selectedPortion!.defaultAmount;
      mealItems = Store.mealItems;
      kcalEatenToday = Store.kcalEatenToday;
      quantityController.text =
          selectedPortion?.defaultAmount.toString() ?? "1";
      comment = Store.comment;
      commentController.text = comment ?? "";
      loading = false;
    });
  }

  String getDay() {
    int day = selectedDate.day;
    int month = selectedDate.month;
    int year = selectedDate.year;

    final now = DateTime.now();
    if (now.day == day && now.month == month && now.year == year) {
      return "Vandaag";
    }

    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    if (yesterday.day == day &&
        yesterday.month == month &&
        yesterday.year == year) return "Gisteren";

    return DateFormat("EEE dd-MM-yyyy", "nl").format(selectedDate);
  }

  int getKcal() {
    return ((selectedFood?.kcal ?? 0) /
            1000 *
            quantityEaten *
            (selectedPortion?.grams ?? 0))
        .round();
  }

  Widget getAddMealWidget() {
    final TextEditingController textEditingController = TextEditingController();

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
                          addMeal(i.food, i.portion, i.portion.defaultAmount)
                              .then((value) => ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                      content:
                                          Text("Eten succesvol toegevoegd."))));
                        },
                        icon: const Icon(Icons.add),
                        label: InlineText(
                          "${i.portion.defaultAmount} ${i.portion.unit} ${i.food.name}",
                          // softWrap: false,
                          // overflow: TextOverflow.fade,
                        )))))
            .toList());
    Widget foodLabel = const SelectableText('Eten');
    FocusNode foodFocusNode = FocusNode();
    Widget foodSearchField = TextFormField(
      focusNode: foodFocusNode,
      controller: textEditingController,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),
        hintText: 'Zoek item...',
        hintStyle: const TextStyle(fontSize: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
    Widget foodDropdown = SizedBox(
        height: 30,
        width: 250,
        child: DropdownButtonFormField2<Food>(
          decoration: InputDecoration(
            //Add isDense true and zero Padding.
            //Add Horizontal padding using buttonPadding and Vertical padding by increasing buttonHeight instead of add Padding here so that The whole TextField Button become clickable, and also the dropdown menu open under The whole TextField Button.
            isDense: true,
            contentPadding: const EdgeInsets.only(left: 15, right: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            //Add more decoration as you want here
            //Add label If you want but add hint outside the decoration to be aligned in the button perfectly.
          ),
          isExpanded: true,
          hint: Text(
            "Kies eten",
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).hintColor,
            ),
          ),
          items: Store.activeFoodItems.map((Food food) {
            return DropdownMenuItem<Food>(value: food, child: Text(food.name));
          }).toList(),
          value: selectedFood,
          onChanged: (value) {
            setState(() {
              selectedFood = value;
              selectedPortion = selectedFood?.portions[0];
            });
          },
          buttonHeight: 40,
          buttonWidth: 250,
          itemHeight: 40,
          dropdownMaxHeight: 200,

          searchController: textEditingController,
          searchInnerWidget: Padding(
              padding: const EdgeInsets.only(
                top: 8,
                bottom: 4,
                right: 8,
                left: 8,
              ),
              child: foodSearchField),
          searchMatchFn: (item, searchValue) {
            return (item.value.name
                .toString()
                .toLowerCase()
                .contains(searchValue.toLowerCase()));
          },
          //This to clear the search value when you close the menu
          onMenuStateChange: (isOpen) {
            if (!isOpen) {
              textEditingController.clear();
              FocusScope.of(context).requestFocus(FocusNode());
            } else {
              foodFocusNode.requestFocus();
            }
          },
        ));
    Widget quantityLabel = const SelectableText('Hoeveelheid');
    Widget quantityNumber = SizedBox(
        width: 50,
        height: 30,
        child: TextFormField(
          decoration: InputDecoration(
            //Add isDense true and zero Padding.
            //Add Horizontal padding using buttonPadding and Vertical padding by increasing buttonHeight instead of add Padding here so that The whole TextField Button become clickable, and also the dropdown menu open under The whole TextField Button.
            isDense: true,
            contentPadding:
                const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            //Add more decoration as you want here
            //Add label If you want but add hint outside the decoration to be aligned in the button perfectly.
          ),
          controller: quantityController,
          keyboardType: const TextInputType.numberWithOptions(
              decimal: true, signed: false),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r"[0-9.,]")),
            TextInputFormatter.withFunction((oldValue, newValue) {
              try {
                final text = newValue.text.replaceAll(RegExp(r','), ".");
                if (text.isNotEmpty) double.parse(text);
                return newValue;
              } catch (e) {}
              return oldValue;
            }),
          ],
          onChanged: (value) {
            setState(() {
              if (value != "") {
                value = value.replaceAll(RegExp(r','), ".");
                quantityEaten = double.parse(value);
              }
            });
          },
        ));
    Widget unitDropdown = SizedBox(
        height: 30,
        width: 100,
        child: DropdownButtonFormField<Portion>(
            decoration: InputDecoration(
              //Add isDense true and zero Padding.
              //Add Horizontal padding using buttonPadding and Vertical padding by increasing buttonHeight instead of add Padding here so that The whole TextField Button become clickable, and also the dropdown menu open under The whole TextField Button.
              isDense: true,
              contentPadding: const EdgeInsets.only(
                  left: 10, right: 10, top: 10, bottom: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              //Add more decoration as you want here
              //Add label If you want but add hint outside the decoration to be aligned in the button perfectly.
            ),
            value: selectedPortion,
            items: selectedFood?.portions.map((Portion portion) {
              return DropdownMenuItem<Portion>(
                  value: portion, child: Text(portion.unit));
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedPortion = value;
              });
            }));

    Widget addButton = SizedBox(
        width: 120,
        child: ElevatedButton.icon(
          style: ButtonStyle(
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ))),
          icon: const Icon(Icons.add),
          label: Text("${getKcal()} kcal"),
          onPressed: selectedFood != null && selectedPortion != null
              ? () {
                  quantityEaten = selectedPortion?.defaultAmount ?? 1;
                  quantityController.text = quantityEaten.toString();
                  addMeal(selectedFood!, selectedPortion!, quantityEaten).then(
                      (value) => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Eten succesvol toegevoegd."))));
                }
              : null,
        ));

    return Center(
        child: Container(
            margin: const EdgeInsets.all(15.0),
            padding: const EdgeInsets.all(15.0),
            decoration: BoxDecoration(border: Border.all()),
            child: Column(children: [
              quickAddButtons,
              const SizedBox(height: 10),
              MediaQuery.of(context).size.width >= 700
                  ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      foodLabel,
                      const SizedBox(width: 10),
                      foodDropdown,
                      const SizedBox(width: 10),
                      quantityLabel,
                      const SizedBox(width: 10),
                      quantityNumber,
                      const SizedBox(width: 5),
                      unitDropdown,
                      const SizedBox(width: 10),
                      addButton
                    ])
                  : Column(
                      children: [
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
                              const SizedBox(width: 5),
                              unitDropdown,
                            ]),
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
    await Store.loadMealsAndCommentForDate(date);
    setState(() {
      mealItems = Store.mealItems;
      comment = Store.comment;
      commentController.text = comment ?? "";
    });
  }

  void addComment() async {
    await Store.addComment(selectedDate, comment!);
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
            title: const Text("Voercalculator"),
            actions: <Widget>[
              Padding(
                  padding: const EdgeInsets.only(right: 20.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => const FoodSettings()),
                      );
                    },
                    child: const Icon(
                      Icons.settings,
                      size: 26.0,
                    ),
                  )),
            ]),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                            width: MediaQuery.of(context).size.width >= 500
                                ? 110
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
                  if (comment != null) const SizedBox(height: 20),
                  if (comment != null && comment != "")
                    Padding(
                        padding: const EdgeInsets.only(left: 15, right: 15),
                        child: Text(
                          comment!,
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        )),
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
                                child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Flexible(
                                          child: Text(
                                        "${meal.quantity} ${meal.unit} ${meal.foodName}",
                                        overflow: TextOverflow.ellipsis,
                                      )),
                                      Text(" (${meal.kcal} kcal)"),
                                      const SizedBox(width: 10)
                                    ])),
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
                  const SizedBox(height: 20),
                  Padding(
                      padding: const EdgeInsets.only(
                          left: 15, right: 15, bottom: 10),
                      child: SizedBox(
                          child: TextFormField(
                        controller: commentController,
                        minLines: 3,
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: "Voeg opmerking toe...",
                          isDense: true,
                          contentPadding: const EdgeInsets.only(
                              left: 10, right: 10, top: 10, bottom: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            comment = value;
                          });
                        },
                      ))),
                  OutlinedButton(
                    onPressed: comment == null
                        ? null
                        : () {
                            addComment();
                          },
                    child: const Text("Opslaan"),
                  ),
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
                      child: SelectableText('Kcal: ${meal.kcal} kcal')),
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
