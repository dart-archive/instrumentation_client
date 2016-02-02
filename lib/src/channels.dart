// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library intrumentation.channels;

import 'dart:async';

abstract class Channel {
  void sendData(String data);
  void shutdown() {}
}

/// [Channel] that implements a leaky bucket
/// algorithm to provide rate limiting.
/// See [http://en.wikipedia.org/wiki/Leaky_bucket].
class RateLimitingBufferedChannel extends Channel {
  final List<String> _buffer = <String>[];
  final Channel _innerChannel;
  final int _bufferSizeLimit;
  Timer _timer;

  RateLimitingBufferedChannel(
      this._innerChannel,
      {int bufferSizeLimit: 50,
      num packetsPerSecond: 1.0})
  : this._bufferSizeLimit = bufferSizeLimit {
    if (!(packetsPerSecond > 0)) {
      throw new ArgumentError("packetsPerSecond must be larger than zero.");
    }

    int transmitDelay = (1000 / packetsPerSecond).floor();
    _timer = new Timer.periodic(
        new Duration(milliseconds: transmitDelay), _onTimerTick);
  }

  void _onTimerTick(_) {
    if (_buffer.length > 0) {
      String item = _buffer.removeLast();
      _innerChannel.sendData(item);
    }
  }

  void sendData(String data) {
    if (_buffer.length >= _bufferSizeLimit) return;
    _buffer.add(data);
  }

  void shutdown() {
    _timer.cancel();

    // Flush the buffer.
    for (var item in _buffer) {
      _innerChannel.sendData(item);
    }
    _innerChannel.shutdown();
  }
}
