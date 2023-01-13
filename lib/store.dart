import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Store {

  static FirebaseFirestore db = FirebaseFirestore.instance;
  static List<Food> foodItems = [];
  static List<Meal> mealItems = [];
  static List<QuickAdd> quickAddItems = [];
  static int kcalAllowed = 1000;
  static int kcalEatenToday = 0;

  static Future<void> loadFood() async {
    var foodDocs = (await db.collection("food").get()).docs;
    foodItems = [];
    for (var doc in foodDocs) {
      Food food = Food.create(doc.id, doc.data());
      foodItems.add(food);
      for (Portion p in food.portions) {
        if (p.quickAdd) {
          quickAddItems.add(QuickAdd(food, p));
        }
      }
    }
  }

  static Future<void> loadMealsForDate(DateTime date) async {
    var mealDocs = (await db
        .collection("days")
        .doc(DateFormat("yyyy-MM-dd").format(date))
        .collection("meals")
        .get())
        .docs;

    mealItems = [];
    kcalEatenToday = 0;

    for (var doc in mealDocs) {
      Meal meal = Meal.create(doc.id, doc.data());
      mealItems.add(meal);
      kcalEatenToday += meal.kcal;
    }
  }

  static Future<void> addMeal(Food food, Portion portion, double quantityEaten, DateTime date) async {
    int kcalEaten = Store._getKcalEaten(food, portion, quantityEaten);
    DateTime added = DateTime.now();
    var ref = await db
        .collection("days")
        .doc(DateFormat("yyyy-MM-dd").format(date))
        .collection("meals")
        .add({
      "foodId": food.id,
      "foodName": food.name,
      "unit": portion.unit,
      "quantity": quantityEaten,
      "kcal": kcalEaten,
      "added": added
    });

    mealItems.add(Meal(ref.id, food.id, food.name,
        portion.unit, quantityEaten, kcalEaten, added));
    kcalEatenToday += kcalEaten;
  }

  static Future<void> removeMeal(Meal meal) async {
    await db
        .collection("days")
        .doc(DateFormat("yyyy-MM-dd").format(DateTime.now()))
        .collection("meals")
        .doc(meal.id)
        .delete();

    mealItems.remove(meal);
    kcalEatenToday -= meal.kcal;
  }

  static int _getKcalEaten(Food food, Portion portion, double quantity) {
    return ((food.kcal) /
        1000 *
        quantity *
        (portion.grams))
        .round();
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
    portions.add(Portion("gram", 1, 0, false, false));
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
  bool quickAdd;

  Portion(this.unit, this.grams, this.defaultAmount, this.isDefault, this.quickAdd);

  static Portion create(Map<String, dynamic> data) {
    return Portion(data["unit"] ?? "", data["grams"] ?? 0,
        data["defaultAmount"] ?? 0, data["isDefault"] ?? false, data["quickAdd"] ?? false);
  }
}

class Meal {
  String id;
  String foodId;
  String foodName;
  String unit;
  double quantity;
  int kcal;
  DateTime? added;

  Meal(
      this.id, this.foodId, this.foodName, this.unit, this.quantity, this.kcal, this.added);

  static Meal create(String id, Map<String, dynamic> data) {
    Timestamp? added = data["added"];
    return Meal(id, data["foodId"], data["foodName"], data["unit"],
        data["quantity"], data["kcal"], added?.toDate());
  }
}

class QuickAdd {
  Food food;
  Portion portion;

  QuickAdd(this.food, this.portion);
}
