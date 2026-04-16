import '../repositories/aut_repository.dart';
import '../../../core/services/dio_client.dart';
import '../../../core/contstans/api_constants.dart';

class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<String> verifyFirebaseToken(String firebaseToken) async {
    final response = await DioClient.instance.post(
      ApiConstants.verifyToken,
      data: {'firebase_token': firebaseToken},
    );


    final data = response.data['data'] as Map<String, dynamic>;
    return data['access_token'] as String;
  }
}
