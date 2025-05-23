import 'package:Pizza_App/model/category_model.dart' show CategoryModel;

List<CategoryModel> getCategories() {
  List<CategoryModel> category = [];
  CategoryModel categoryModel = new CategoryModel();

  categoryModel.name = "Pizza";
  categoryModel.image = "images/pizza.png";
  category.add(categoryModel);
  categoryModel = new CategoryModel();

  categoryModel.name = "Burger";
  categoryModel.image = "images/burger.png";
  category.add(categoryModel);
  categoryModel = new CategoryModel();

  categoryModel.name = "Chinese";
  categoryModel.image = "images/Chinese.png";
  category.add(categoryModel);
  categoryModel = new CategoryModel();

  categoryModel.name = "Mexican";
  categoryModel.image = "images/tacos.png";
  category.add(categoryModel);
  categoryModel = new CategoryModel();

  return category;
}
