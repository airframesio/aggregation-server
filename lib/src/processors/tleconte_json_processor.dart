import 'package:angel_orm_postgres/angel_orm_postgres.dart';
import 'package:nats/nats.dart';
import 'package:quick_log/quick_log.dart';

import 'package:acars_aggregation_server/aas.dart';

class TLeconteJsonProcessor extends Processor {
  PostgreSqlExecutorPool databaseExecutor;
  NatsClient natsClient;

  TLeconteJsonProcessor(Source source, this.databaseExecutor, this.natsClient, Logger logger) : super(source, logger) {
  }

  Future parseJson(String str) async {
    JsonMessageParser jsonParser = new JsonMessageParser(logger);
    JsonMessage jsonMessage = await jsonParser.parse(str);
    if (jsonMessage.tail != null)
      jsonMessage.sanitizedTail = new Tail(jsonMessage.tail).sanitize();
    return jsonMessage;
  }

  Future process(String str, String ipAddress) async {
    var jsonMessage = await parseJson(str);
    var jsonMessageImporter = new TLeconteJsonMessageImporter(source, jsonMessage, natsClient, databaseExecutor, logger);

    var station = await jsonMessageImporter.findOrCreateStation(ipAddress);
    var airframe = await jsonMessageImporter.findOrCreateAirframe();
    var flight = await jsonMessageImporter.updateOrCreateFlight(airframe);
    var message = await jsonMessageImporter.insertOrSkipMessage(station, airframe, flight, ipAddress);
  }
}
