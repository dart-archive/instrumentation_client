// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library instrumentation.client;

import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:math';
import 'src/channels.dart';
import 'src/io_channels.dart';

final int MAX_UNCOMPRESSED_MESSAGE_SIZE = 450 * 1024;
final String VERSION_ID = "2016-02-02";

class InstrumentationClient {
  Channel channel;
  Channel priorityChannel;
  String _sessionID;
  StringBuffer sb = new StringBuffer();
  InstrumentationClient(
      {String userID: "NoUserID",
      String serverEndPoint: "http://localhost:13080/rpc",
      int bufferSizeLimit: 50,
      num packetsPerSecond: 2.0}) {
    if (!serverEndPoint.startsWith("https://") &&
        !serverEndPoint.startsWith("http://localhost")) {
          throw new ArgumentError("Data must be sent over TLS or to localhost.");
    }

    _sessionID = (new DateTime.now().millisecondsSinceEpoch +
        new Random().nextDouble()).toString();

    this.channel = new RateLimitingBufferedChannel(
        new GaeHttpClientChannel(
            _sessionID, userID, serverEndPoint, VERSION_ID),
        bufferSizeLimit: bufferSizeLimit,
        packetsPerSecond: packetsPerSecond);

    this.priorityChannel = new RateLimitingBufferedChannel(
        new GaeHttpClientChannel(
            "PRI" + _sessionID, userID, serverEndPoint, VERSION_ID),
        bufferSizeLimit: bufferSizeLimit,
        packetsPerSecond: packetsPerSecond);
  }

  void log(String s) {
    sb.write("~");
    sb.writeln(s);
    if (sb.length > MAX_UNCOMPRESSED_MESSAGE_SIZE) {
      String outStr = sb.toString();
      while (outStr.length > MAX_UNCOMPRESSED_MESSAGE_SIZE) {
        String first = outStr.substring(0, MAX_UNCOMPRESSED_MESSAGE_SIZE);
        String second = outStr.substring(MAX_UNCOMPRESSED_MESSAGE_SIZE);
        _send(first);
        outStr = second;
      }
      sb = new StringBuffer();
      sb.write(outStr);
    }
  }

  /// Log a message via the priority channel. These messages will be
  /// trimmed to MAX_UNCOMPRESSED_MESSAGE_SIZE. Calls to this method
  /// should be reserved for critical metadata and
  void logWithPriority(String s) {
    StringBuffer message = new StringBuffer();
    message.write("~");
    message.writeln(s);

    String outStr = message.toString();
    if (outStr.length > MAX_UNCOMPRESSED_MESSAGE_SIZE) outStr =
        outStr.substring(0, MAX_UNCOMPRESSED_MESSAGE_SIZE);

    _prioritySend(outStr);
  }

  void shutdown() {
    _send(sb.toString());
    _internalShutdown();
  }

  String _encode(String s) {
    // Data -> UTF8 Bytes -> GZip -> Encrypt -> Base64
    var coded = UTF8.encode(s);
    var gzed = GZIP.encode(coded);
    String packed = CryptoUtils.bytesToBase64(gzed, urlSafe: true);
    return packed;
  }

  _send(String s) {
    channel.sendData(_encode(s));
  }

  _prioritySend(String s) {
    priorityChannel.sendData(_encode(s));
  }

  _internalShutdown() {
    priorityChannel.shutdown();
    channel.shutdown();
  }
}
