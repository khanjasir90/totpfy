import 'package:otp/otp.dart';
import 'package:totpfy/core/totp/totp_service.dart';

class TotpServiceImpl extends TotpService {

  @override
  Future<String> generateOtp({required String secretKey}) async {
    final time = await super.time;
    return OTP.generateTOTPCodeString(
      secretKey,
      time,
      length: 6,
      algorithm: Algorithm.SHA1,
      interval: 30,
      isGoogle: true,
    );
    
  }
}