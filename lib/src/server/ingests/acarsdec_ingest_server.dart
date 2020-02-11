import 'dart:io';
import 'package:quick_log/quick_log.dart';
import 'package:udp/udp.dart';

import 'package:acars_aggregation_server/aas.dart';

class AcarsdecIngestServer extends UDPIngestServer {
  AcarsdecIngestServer(name, config, databaseConfig) : super(name, config, databaseConfig) {
    this.source = Source('acarsdec', 'acarsdec', 'ACARS', 'Custom', 'JSON', 'UDP');
    this.processor = AcarsdecProcessor(source, databaseConfig.executor(), natsClient, logger);
  }

  Future start() async {
    await this.natsClient.connect();
    this.logger.info('Connected to NATS server at ${config.natsHost} on port ${config.natsPort}.');

    this.receiver = await UDP.bind(Endpoint.unicast(InternetAddress.anyIPv4, port: Port(config.port)));

    this.logger.info('Listening on ${config.transport} port ${config.port} for incoming JSON messages from ${config.clientApplication} clients...');
    receiver.listen((datagram) {
      this.logger = Logger('Ingest(${name}) #${++packetCount}');
      var str = String.fromCharCodes(datagram.data);
      this.logger.debug('Received UDP from ${datagram.address.address}:${datagram.port}: ${str}');
      this.source = Source('acarsdec', 'acarsdec', 'ACARS', 'Custom', 'JSON', 'UDP');
      this.source.remoteIp = datagram.address.address;
      this.processor = AcarsdecProcessor(source, databaseConfig.executor(), natsClient, logger);
      processor.logger = logger;
      processor.process(str);
    }, timeout: new Duration(days: 365));
  }
}
