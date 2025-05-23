import 'package:Pizza_App/model/burger_model.dart';
import 'package:Pizza_App/model/category_model.dart';
import 'package:Pizza_App/model/pizza_model.dart';
import 'package:Pizza_App/service/burger_data.dart';
import 'package:Pizza_App/service/category_data.dart';
import 'package:Pizza_App/service/pizza_data.dart';
import 'package:Pizza_App/service/widget_support.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<CategoryModel> categories = [];
  List<PizzaModel> pizza = [];
  List<BurgerModel> burger = [];
  String track = "0";

  @override
  void initState() {
    categories = getCategories();
    pizza = getPizza();
    burger = getBurger();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: 50,
                      width: 150,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Order your favourite food!',
                      style: AppWidget.SimpleTextFeildStyle(),
                    ),
                  ],
                ),
                const Spacer(),
                Image.asset(
                  'assets/images/boy.jpg',
                  height: 60,
                  width: 60,
                  fit: BoxFit.cover,
                ),
              ],
            ),
            SizedBox(height: 15),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.only(left: 10),
                    margin: EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(color: Color(0xFFececf8)),
                    child: TextField(
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Search your favorite food...',
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Color(0xffef2b39)),
                  child: Icon(Icons.search, color: Colors.white, size: 30),
                ),
              ],
            ),
            SizedBox(height: 5),
            Container(
              height: 70,
              child: ListView.builder(
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  return CategoryTile(
                    categories[index].name!,
                    categories[index].image!,
                    index.toString(),
                  );
                },
              ),
            ),
            SizedBox(height: 10),
            track == "0"
                ? Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 10,
                    ),
                    itemCount: pizza.length,
                    itemBuilder: (context, index) {
                      return FoodTile(
                        pizza[index].name!,
                        pizza[index].image!,
                        pizza[index].price!,
                      );
                    },
                  ),
                )
                : track == "1"
                ? Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 10,
                    ),
                    itemCount: burger.length,
                    itemBuilder: (context, index) {
                      return FoodTile(
                        burger[index].name!,
                        burger[index].image!,
                        burger[index].price!,
                      );
                    },
                  ),
                )
                : Container(),
          ],
        ),
      ),
    );
  }

  Widget FoodTile(String name, String image, String price) {
    return Container(
      padding: EdgeInsets.only(left: 10, top: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black38),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Image.asset(
              image,
              height: 120,
              width: 120,
              fit: BoxFit.contain,
            ),
          ),
          Text(name, style: AppWidget.boldTextFeildStyle()),
          Text("\$" + price, style: AppWidget.priceTextFeildStyle()),
          SizedBox(height: 10),
          Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                height: 30,
                width: 50,
                decoration: BoxDecoration(
                  color: Color(0xffef2b39),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                ),
                child: Icon(Icons.arrow_forward, color: Colors.white, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget CategoryTile(String name, String image, String categoryindex) {
    return GestureDetector(
      onTap: () {
        track = categoryindex.toString();
        setState(() {});
      },
      child:
          track == categoryindex
              ? Container(
                margin: EdgeInsets.only(right: 20.0, bottom: 10.0),
                child: Material(
                  elevation: 3.0,
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: EdgeInsets.only(left: 20, right: 20),
                    decoration: BoxDecoration(
                      color: Color(0xffef2b39),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          image,
                          height: 40,
                          width: 40,
                          fit: BoxFit.cover,
                        ),
                        SizedBox(width: 10),
                        Text(name, style: AppWidget.whiteTextFeildStyle()),
                      ],
                    ),
                  ),
                ),
              )
              : Container(
                padding: EdgeInsets.only(left: 20, right: 20),
                margin: EdgeInsets.only(right: 20, bottom: 10),
                decoration: BoxDecoration(
                  color: Color(0xFFececf8),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Image.asset(
                      image,
                      height: 40,
                      width: 40,
                      fit: BoxFit.cover,
                    ),
                    SizedBox(width: 10),
                    Text(name, style: AppWidget.SimpleTextFeildStyle()),
                  ],
                ),
              ),
    );
  }
}
