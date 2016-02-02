// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:instrumentation_client/instrumentation_client.dart';

main() {
  print ("Instrumentation client demo starting");
  InstrumentationClient client = new InstrumentationClient(
      serverEndPoint: "http://localhost:13080/rpc");
  client.log("Sample data");
  client.log("Sample data2");
  client.shutdown();
  print("Done");
}
