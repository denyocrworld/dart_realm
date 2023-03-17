import 'package:faker_dart/faker_dart.dart';
import 'package:hive/hive.dart';

import 'power_socket.dart';

late Box mainStorage;
void main() async {
  // if (!(Platform.isAndroid || Platform.isIOS || Platform.isWindows)) {
  //   Hive.init("./hive");
  // }
  Hive.init("./");
  mainStorage = await Hive.openBox('mainStorage');

  // await HyperBase.instance.collection("products").deleteAll();
  // var response = await HyperBase.instance.collection("products").add({
  //   "product_name": "GG FILTER 12",
  //   "price": 25,
  // });
  // print(response);

  // var getresponse = await HyperBase.instance.collection("products").get();
  // var id = getresponse["data"][0]["id"];
  // print(id);

  // await HyperBase.instance.collection("products").doc(id).update({
  //   "product_name": "CAKALA",
  //   "price": 25,
  // });

  // await Cilukba.instance.collection("products").doc(id).delete();

  var xxx = await HyperBase.instance.collection("products").get();
  print(xxx);
  if (1 == 1)
    for (var i = 1; i <= 1; i++) {
      Future.delayed(Duration(seconds: 1 * i), () {
        HyperBase.instance.collection("products").add({
          "product_name": Faker.instance.commerce.productName(),
          "price": double.parse(Faker.instance.commerce.price(
            symbol: "",
          )),
        });
      });
    }
  await HyperBase.instance.collection("products").clean();
  var snapshot = HyperBase.instance.collection("products").snapshot();
  snapshot.listen((event) {
    print("---");
    print(">>> : $event");
  });
}
