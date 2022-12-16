import 'dart:convert';

import "package:backend/backend.dart";
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

void main() async {
  await db.open();
  final handler =
      Pipeline().addMiddleware(logRequests()).addHandler(handleRequest);
  await shelf_io.serve(handler, "0.0.0.0", 8080);

  print("Running server");
}

Future<Response> handleRequest(Request requestData) async {
  print("Received connection");
  final workAppColl = db.collection("work_app");
  if (requestData.method == "POST") {
    final incomeData = jsonDecode(await requestData.readAsString());
    if (incomeData["type"] == "submit") {
      print(
          "Somebody by the name of ${incomeData['name']} submitted a new request");
      final alreadyHasRequests =
          await workAppColl.findOne({"_id": incomeData["email"]}) != null;
      if (alreadyHasRequests) {
        workAppColl.updateOne({
          "_id": incomeData["email"]
        }, {
          "\$push": {"data": incomeData}
        });
      } else {
        workAppColl.insertOne({
          "_id": incomeData["email"],
          "data": [incomeData]
        });
      }

      return Future.value(Response.ok("Submitted"));
    } else if (incomeData["type"] == "view") {
      print(
          "Somebody that used the email ${incomeData['email']} viewed their past requests");
      {
        final results =
            (await workAppColl.find({"_id": incomeData["email"]}).toList())
                .map((i) => i["data"])
                .toList();
        return Future.value(Response.ok(jsonEncode(results)));
      }
    } else {
      return Future.value(Response.ok("")); // Should never get here
    }
  } else {
    return Future.value(Response.ok("")); // Should never get here
  }
}
