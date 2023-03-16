import 'power_socket.dart';

void main() async {
  await Cilukba.instance.collection("products").deleteAll();
  var response = await Cilukba.instance.collection("products").add({
    "product_name": "GG FILTER 12",
    "price": 25,
  });
  print(response);

  var getresponse = await Cilukba.instance.collection("products").get();
  var id = getresponse["data"][0]["id"];
  print(id);

  await Cilukba.instance.collection("products").doc(id).update({
    "product_name": "CAKALA",
    "price": 25,
  });

  // await Cilukba.instance.collection("products").doc(id).delete();

  var xxx = await Cilukba.instance.collection("products").get();
  print(xxx);
}
