import 'dart:async';
import 'dart:io';

import 'package:acars_aggregation_server/src/processors/processor.dart';
import 'package:nats/nats.dart';
import 'package:quick_log/quick_log.dart';

import 'package:acars_aggregation_server/aas.dart';

class TCPIngestServer extends IngestServer {
  TCPIngestServer(name, config, databaseConfig) : super(name, config, databaseConfig) {
    this.logger = Logger('Ingest(${name})');
    this.source = Source(name, 'unknown', 'unknown', 'unknown', 'unknown', 'TCP');
    this.processor =  Processor(source, logger);
    this.natsClient = NatsClient(config.natsHost, config.natsPort);
  }

  Future start() async {
    await this.natsClient.connect();
    this.logger.info('Connected to NATS server at ${config.natsHost} on port ${config.natsPort}.');

    this.receiver = ServerSocket.bind(InternetAddress.anyIPv4, config.port);
    receiver.then((ServerSocket server) {
      server.listen((Socket socket) {
        this.logger.debug('New TCP connection from ${socket.remoteAddress.address}:${socket.remotePort}');
        socket.listen((List<int> data) {
          String result = new String.fromCharCodes(data);
          this.logger.debug('Received TCP packet from ${socket.remoteAddress.address}:${socket.remotePort}: ${result}');
          processor.logger = logger;
          processor.process(result, socket.remoteAddress.address);
        });
      });
    });
  }
}
