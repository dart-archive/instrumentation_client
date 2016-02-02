// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library instrumentation.io_channels;

import 'dart:io';
import 'channels.dart';
import 'dart:convert';

class GaeHttpClientChannel extends Channel {
  int _counter = 0;
  final serverEP;
  final String sessionID;
  final String userID;
  final String versionID;

  GaeHttpClientChannel(
      this.sessionID,
      this.userID,
      this.serverEP,
      this.versionID);

  void sendData(String data) {
    HttpClient client = new HttpClient();
    client.postUrl(Uri.parse(serverEP)).then((HttpClientRequest req) {
      var dataPacked = UTF8.encode(
          '["BasicStore2", {"sessionID" : "$sessionID", "msgN" '
          ': ${_counter++}, "versionID" : "$versionID", "Data" : "$data"}]');
      req.contentLength = dataPacked.length;
      req.add(dataPacked);
      return req.close();
    }).then((HttpClientResponse response) {
      response.drain();
    }).catchError((_) {});
  }
}
