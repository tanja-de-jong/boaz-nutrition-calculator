import 'package:boaz_nutrition_calculator/main.dart';
import 'package:boaz_nutrition_calculator/store.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FoodSettings extends StatefulWidget {
  const FoodSettings({Key? key}) : super(key: key);

  @override
  State<FoodSettings> createState() => _FoodSettingsState();
}

class _FoodSettingsState extends State<FoodSettings> {
  List<Food> foodItems = Store.foodItems;
  int kcalAllowed = Store.kcalAllowed;
  bool showArchivedFoods = false;

  addFood(String? id, String name, int kcal, List<Portion> portions) async {
    await Store.addFood(id, name, kcal, portions);
    setState(() {
      foodItems = Store.foodItems;
    });
  }

  Future<void> archiveFood(Food food, bool archive) async {
    await Store.archiveFood(food, archive);
    setState(() {
      foodItems = Store.foodItems;
    });
  }

  void updateKcalAllowed(int value) {
    Store.updateKcalAllowed(value);
  }

  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            // Here we take the value from the MyHomePage object that was created by
            // the App.build method, and use it to set our appbar title.
            title: const Text("Instellingen"),
            actions: <Widget>[
              Padding(
                  padding: EdgeInsets.only(right: 20.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (context) => const MyHomePage(
                                title: 'Boaz\' Voercalculator')),
                      );
                    },
                    child: Icon(
                      Icons.close,
                      size: 26.0,
                    ),
                  )),
            ]),
        body: SingleChildScrollView(
            padding: EdgeInsets.all(15),
            child: Column(children: [
              getRow(
                  "Toegestane aantal kcal",
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Expanded(
                        child: TextFormField(
                      initialValue: kcalAllowed.toString(),
                      decoration: const InputDecoration(isDense: true),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) {
                        kcalAllowed = int.parse(value);
                      },
                    )),
                    Expanded(
                        child: IconButton(
                      icon: Icon(Icons.check),
                      onPressed: () {
                        updateKcalAllowed(kcalAllowed);
                      },
                    ))
                  ])),
              SizedBox(height: 10),
              Divider(),
              SizedBox(height: 10),
              ...foodItems.where((f) => !f.archived)
                  .map((item) => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item.name),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                      padding: const EdgeInsets.all(3),
                                      constraints: const BoxConstraints(),
                                      iconSize: 17,
                                      splashRadius: 13,
                                      onPressed: () {
                                        addDialog(item);
                                      },
                                      icon: const Icon(Icons.edit)),
                                  IconButton(
                                      padding: const EdgeInsets.all(3),
                                      constraints: const BoxConstraints(),
                                      iconSize: 18,
                                      splashRadius: 13,
                                      onPressed: () {
                                        deleteDialog(item);
                                      },
                                      icon: const Icon(Icons.delete)),
                                ])
                          ]))
                  .toList(),
              if (Store.activeFoodItems.isNotEmpty)
                Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                          onPressed: () {
                            setState(() {
                              showArchivedFoods = !showArchivedFoods;
                            });
                          },
                          child: Row(children: [
                            const Text('Gearchiveerd'),
                            Icon(showArchivedFoods
                                ? Icons.keyboard_arrow_down
                                : Icons.keyboard_arrow_up)
                          ])),
                    ]),
              if (showArchivedFoods) ...foodItems.where((f) => f.archived)
                  .map((item) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${item.name} ${item.archived}"),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                              padding: const EdgeInsets.all(3),
                              constraints: const BoxConstraints(),
                              iconSize: 17,
                              splashRadius: 13,
                              onPressed: () {
                                addDialog(item);
                              },
                              icon: const Icon(Icons.edit)),
                          IconButton(
                              padding: const EdgeInsets.all(3),
                              constraints: const BoxConstraints(),
                              iconSize: 18,
                              splashRadius: 13,
                              onPressed: () {
                                restoreDialog(item); },
                              icon: const Icon(Icons.restore_from_trash)),
                        ])
                  ]))
                  .toList()
            ])),
        floatingActionButton: FloatingActionButton(
          onPressed: () => addDialog(null),
          child: const Icon(Icons.add),
        ));
  }

  Row getRow(String label, Widget value) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Expanded(child: Text(label)), Expanded(child: value)]);
  }

  addDialog(Food? food) {
    String? name = food?.name;
    int? kcal = food?.kcal;
    List<Portion> portions =
        food == null ? [Portion("gram", 1, 1, false, false)] : food.portions;
    bool expandNewPortion = false;
    Portion? selectedPortion;
    String unit = "";
    String grams = "";
    String defaultAmount = "";
    bool isDefault = false;
    bool quickAdd = false;

    void setPortion(Portion? portion) {
      selectedPortion = portion;
      unit = portion?.unit ?? "";
      grams = portion?.grams.toString() ?? "";
      defaultAmount = portion?.defaultAmount.toString() ?? "";
      isDefault = portion?.isDefault ?? false;
      quickAdd = portion?.quickAdd ?? false;
    }

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, setState) {
            return SimpleDialog(
                title: const SelectableText('Maaltijd toevoegen'),
                children: [
                  Container(
                      padding: const EdgeInsets.only(left: 25, right: 25),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            getRow(
                                "Naam",
                                TextFormField(
                                    initialValue: name,
                                    decoration: InputDecoration(isDense: true),
                                    onChanged: (value) =>
                                        setState(() => {name = value}))),
                            const SizedBox(height: 10),
                            getRow(
                                "Kcal per kg",
                                TextFormField(
                                  initialValue: kcal?.toString(),
                                  decoration: InputDecoration(isDense: true),
                                  onChanged: (value) =>
                                      setState(() => {kcal = int.parse(value)}),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                )),
                            const SizedBox(height: 10),
                            const Text(
                              "Porties",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            ...portions.map((p) => Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(p.unit + (p.isDefault ? "*" : "")),
                                      if (p != portions.last)
                                        IconButton(
                                          onPressed: () {
                                            setState(() {
                                              setPortion(p);
                                              expandNewPortion = true;
                                            });
                                          },
                                          icon: const Icon(Icons.edit),
                                          padding: const EdgeInsets.all(3),
                                          constraints: const BoxConstraints(),
                                          iconSize: 17,
                                          splashRadius: 13,
                                        )
                                    ])),
                            SizedBox(
                              height: 10,
                            ),
                            if (!expandNewPortion)
                              OutlinedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      setPortion(null);
                                      expandNewPortion = true;
                                    });
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text("Portie")),
                            if (expandNewPortion)
                              Container(
                                padding: const EdgeInsets.all(15.0),
                                decoration: BoxDecoration(border: Border.all()),
                                child: Column(children: [
                                  getRow(
                                      "Eenheid",
                                      TextFormField(
                                        initialValue: unit,
                                        decoration:
                                            InputDecoration(isDense: true),
                                        onChanged: (value) =>
                                            setState(() => {unit = value}),
                                      )),
                                  const SizedBox(height: 5),
                                  getRow(
                                      "Aantal gram",
                                      TextFormField(
                                          initialValue: grams,
                                          decoration:
                                              InputDecoration(isDense: true),
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly
                                          ],
                                          onChanged: (value) => setState(() {
                                                grams = value;
                                              }))),
                                  const SizedBox(height: 5),
                                  getRow(
                                      "Standaardhoeveelheid",
                                      TextFormField(
                                          initialValue: defaultAmount,
                                          decoration:
                                              InputDecoration(isDense: true),
                                          keyboardType: const TextInputType
                                                  .numberWithOptions(
                                              decimal: true, signed: false),
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                                RegExp(r"[0-9.]")),
                                            TextInputFormatter.withFunction(
                                                (oldValue, newValue) {
                                              try {
                                                final text = newValue.text;
                                                if (text.isNotEmpty)
                                                  double.parse(text);
                                                return newValue;
                                              } catch (e) {}
                                              return oldValue;
                                            }),
                                          ],
                                          onChanged: (value) {
                                            setState(
                                                () => {defaultAmount = value});
                                          })),
                                  const SizedBox(height: 5),
                                  getRow(
                                      "Is standaard?",
                                      SizedBox(
                                          height: 30,
                                          child: ToggleButtons(
                                            children: [Text("Ja"), Text("Nee")],
                                            isSelected: [isDefault, !isDefault],
                                            onPressed: (int index) {
                                              setState(() {
                                                isDefault = index == 0;
                                              });
                                            },
                                          ))),
                                  const SizedBox(height: 5),
                                  getRow(
                                      "Snel toevoegen?",
                                      SizedBox(
                                          height: 30,
                                          child: ToggleButtons(
                                            children: [Text("Ja"), Text("Nee")],
                                            isSelected: [quickAdd, !quickAdd],
                                            onPressed: (int index) {
                                              setState(() {
                                                quickAdd = index == 0;
                                              });
                                            },
                                          ))),
                                  const SizedBox(height: 10),
                                  OutlinedButton(
                                      onPressed: unit != "" &&
                                              double.tryParse(defaultAmount) !=
                                                  null &&
                                              grams != ""
                                          ? () {
                                              Portion newPortion = Portion(
                                                  unit,
                                                  int.parse(grams),
                                                  double.tryParse(
                                                      defaultAmount)!,
                                                  isDefault,
                                                  quickAdd);

                                              setState(() {
                                                if (selectedPortion == null) {
                                                  // New portion
                                                  if (newPortion.isDefault) {
                                                    for (Portion p
                                                        in portions) {
                                                        p.isDefault = false;
                                                    }
                                                  }

                                                  portions = [
                                                    ...portions.sublist(
                                                        0, portions.length - 1),
                                                    newPortion,
                                                    portions.last
                                                  ];
                                                } else {
                                                  // Edit portion
                                                  for (int i = 0;
                                                      i < portions.length;
                                                      i++) {
                                                    if (portions[i] ==
                                                        selectedPortion) {
                                                      portions[i] = newPortion;
                                                    } else {
                                                      if (newPortion
                                                              .isDefault &&
                                                          !selectedPortion!
                                                              .isDefault) {
                                                        portions[i].isDefault =
                                                            false;
                                                      }
                                                    }
                                                  }
                                                }
                                                expandNewPortion = false;
                                                setPortion(null);
                                              });
                                            }
                                          : null,
                                      child: Text(selectedPortion == null
                                          ? "Voeg toe"
                                          : "Opslaan"))
                                ]),
                              ),
                            const SizedBox(height: 20),
                            Center(
                                child: Wrap(spacing: 10, children: [
                              OutlinedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Annuleren')),
                              ElevatedButton(
                                  onPressed:
                                      name != null && name != "" && kcal != null
                                          ? () {
                                              addFood(
                                                  food?.id,
                                                  name!,
                                                  kcal!,
                                                  portions.sublist(
                                                      0, portions.length - 1));
                                              Navigator.pop(context);
                                            }
                                          : null,
                                  child: const Text('Opslaan')),
                            ]))
                          ]))
                ]);
          });
        });
  }

  deleteDialog(Food food) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
              title: const SelectableText('Eten archiveren'),
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                      padding: const EdgeInsets.only(left: 25, right: 25),
                      child: const SelectableText(
                          'Weet je zeker dat je dit eten wil archiveren?')),
                  const SizedBox(height: 20),
                  Center(
                      child: Wrap(spacing: 10, children: [
                        OutlinedButton(
                            onPressed: () {
                              archiveFood(food, true);
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

  restoreDialog(Food food) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
              title: const SelectableText('Eten activeren'),
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                      padding: const EdgeInsets.only(left: 25, right: 25),
                      child: const SelectableText(
                          'Weet je zeker dat je dit eten wil activeren?')),
                  const SizedBox(height: 20),
                  Center(
                      child: Wrap(spacing: 10, children: [
                        OutlinedButton(
                            onPressed: () {
                              archiveFood(food, false);
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
}
