import 'package:Pizza_App/model/burger_model.dart';

List<BurgerModel> getBurger() {
  List<BurgerModel> burger = [];
  BurgerModel burgerModel = new BurgerModel();
  burgerModel.name = "Cheese Burger";
  burgerModel.image = "assets/images/burger1.png";
  burgerModel.price = "50";
  burger.add(burgerModel);
  burgerModel = new BurgerModel();

  burgerModel.name = "Veggie Burger";
  burgerModel.image = "assets/images/burger2.png";
  burgerModel.price = "80";
  burger.add(burgerModel);
  burgerModel = new BurgerModel();

  burgerModel.name = "Veggie Burger";
  burgerModel.image = "assets/images/burger2.png";
  burgerModel.price = "80";
  burger.add(burgerModel);
  burgerModel = new BurgerModel();

  burgerModel.name = "Veggie Burger";
  burgerModel.image = "assets/images/burger2.png";
  burgerModel.price = "80";
  burger.add(burgerModel);
  burgerModel = new BurgerModel();
  return burger;
}
