import 'dart:math';

import 'package:boaz_nutrition_calculator/database/food_store.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:text_helpers/text_helpers.dart';

class DiaryOverview extends StatefulWidget {
  const DiaryOverview({Key? key}) : super(key: key);

  @override
  State<DiaryOverview> createState() => _DiaryOverviewState();
}

class _DiaryOverviewState extends State<DiaryOverview> {
  bool loading = true;

  void loadDataFromDatabase() async {
    await Store.loadData();

    setState(() {
      // TODO
      loading = false;
    });
  }

  @override
  void initState() {
    loadDataFromDatabase();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            // Here we take the value from the MyHomePage object that was created by
            // the App.build method, and use it to set our appbar title.
            title: const Text("Dagboek"),
            actions: <Widget>[
              Padding(
                  padding: const EdgeInsets.only(right: 20.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) =>
                                const DiaryOverview()), // TODO
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
                    children: <Widget>[])));
  }
}
