// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library instrumentation_client.test_channel;

import '../lib/src/channels.dart';

class TestChannel extends Channel {
  List<String> channelLog = [];

  void sendData(String data) {
    channelLog.add(data);
  }

  bool contains(String data) {
    return channelLog.contains(data);
  }
}
