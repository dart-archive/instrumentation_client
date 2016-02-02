// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library instrumentation_client.test;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:unittest/unittest.dart';

import '../lib/instrumentation_client.dart';
import 'test_channel.dart';

void main() {
  test('Basic functional test', () => _basicFunctionalityTest());
  test('Buffer split test', () => _splitBufferTest());
}

_basicFunctionalityTest() {
  var client = new InstrumentationClient(
  );
  TestChannel testChannel = new TestChannel();
  TestChannel priorityTestChannel = new TestChannel();

  // Shutdown the default channel impl.
  client.channel.shutdown();
  client.priorityChannel.shutdown();

  // Replace the channel with a mock.
  client.channel = testChannel;
  client.priorityChannel = priorityTestChannel;

  // Send the test data
  client.log("Sample data");
  client.log("Sample data2");
  client.log("Sample3");
  client.logWithPriority("Sample important");
  client.logWithPriority("Sample important2");
  client.shutdown();

  expect(_unpackDataFromChannel(testChannel.channelLog[0]),
    ["~Sample data", "~Sample data2", "~Sample3"]);


  expect(_unpackDataFromChannel(priorityTestChannel.channelLog[0]),
  ["~Sample important"]);

  expect(_unpackDataFromChannel(priorityTestChannel.channelLog[1]),
  ["~Sample important2"]);
}

_splitBufferTest() {
  var client = new InstrumentationClient(
  );

  TestChannel testChannel = new TestChannel();
  TestChannel priorityTestChannel = new TestChannel();

  // Shutdown the default channel impl.
  client.channel.shutdown();
  client.priorityChannel.shutdown();

  // Replace the channel with a mock.
  client.channel = testChannel;
  client.priorityChannel = priorityTestChannel;

  StringBuffer sb = new StringBuffer();
  while (sb.length < MAX_UNCOMPRESSED_MESSAGE_SIZE) {
    sb.write("abc");
  }

  // Write data that is longer than the buffer.
  client.log(sb.toString());
  client.logWithPriority(sb.toString());
  client.shutdown();

  // We should have 2 items in the result.
  expect(testChannel.channelLog.length, 2);
  expect(priorityTestChannel.channelLog.length, 1);

  // Readback the contents of the logging channel.
  List<String> ret =
    _unpackDataFromChannel(testChannel.channelLog[0]);
  ret.addAll(_unpackDataFromChannel(testChannel.channelLog[1]));

  StringBuffer checkSb = new StringBuffer();
  for (String s in ret)
    checkSb.write(s.trim());

  // This should be the same as the data that was sent.
  expect("~" + sb.toString(), checkSb.toString());

  // Check the priority channel
  String priorityData = _unpackDataFromChannel(
      priorityTestChannel.channelLog[0])[0];

  expect("~" + sb.toString().substring(0, MAX_UNCOMPRESSED_MESSAGE_SIZE - 1),
    priorityData);
}

/// Support method for reading data back from the channel.
List<String> _unpackDataFromChannel(String logEntry) {

  // Unpack the data in the channel.
  String passedData = logEntry;
  var gziped = CryptoUtils.base64StringToBytes(passedData);

  var coded = GZIP.decode(gziped);
  var decoded = UTF8.decode(coded);

  return decoded.trim().split("\n");
}
