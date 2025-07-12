import 'package:ntp/ntp.dart';

abstract class TotpService {

  Future<int> get time async => (await NTP.now()).millisecondsSinceEpoch;

  Future<String> generateOtp({
    required String secretKey,
  });

}