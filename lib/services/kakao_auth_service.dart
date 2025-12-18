import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'supabase_service.dart';

class KakaoAuthService {
  static const String kakaoApiKey = '3fdcaa17a7828b19a39c9e312ffb5631';

  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      KakaoSdk.init(
        nativeAppKey: kakaoApiKey,
        javaScriptAppKey: kakaoApiKey,
      );
      _isInitialized = true;
    } catch (e) {
      throw Exception('카카오 SDK 초기화 실패: $e');
    }
  }

  static Future<bool> signIn() async {
    try {
      OAuthToken token;
      
      // 카카오톡으로 로그인 시도 (설치되어 있는 경우)
      try {
        token = await UserApi.instance.loginWithKakaoTalk();
      } catch (talkError) {
        // 카카오톡 로그인 실패 시 카카오계정으로 로그인
        try {
          token = await UserApi.instance.loginWithKakaoAccount();
        } catch (accountError) {
          // KOE002 오류인 경우 더 자세한 메시지 제공
          final errorString = accountError.toString();
          if (errorString.contains('KOE002') || errorString.contains('Invalid Request')) {
            throw Exception(
              'KOE002 오류: 카카오 개발자 콘솔 설정을 확인해주세요.\n'
              '1. 플랫폼 설정 확인 (Android/iOS)\n'
              '2. 리디렉션 URI 등록 확인\n'
              '3. 카카오 로그인 활성화 확인\n'
              '원본 오류: $accountError'
            );
          }
          throw accountError;
        }
      }
      
      return await _handleKakaoToken(token);
    } catch (error) {
      // 오류 메시지를 더 자세히 전달
      final errorString = error.toString();
      if (errorString.contains('KOE002')) {
        throw Exception(
          '카카오 로그인 설정 오류 (KOE002)\n\n'
          '카카오 개발자 콘솔에서 다음을 확인해주세요:\n'
          '1. 플랫폼 설정 → Android/iOS 추가\n'
          '2. 카카오 로그인 → Redirect URI 등록\n'
          '   - Android: myapp://oauth\n'
          '   - iOS: myapp://oauth\n'
          '3. 카카오 로그인 활성화 확인\n'
          '4. 앱 키 확인 (REST API 키)\n\n'
          '자세한 내용: https://developers.kakao.com/docs'
        );
      }
      throw Exception('카카오 로그인 오류: $error');
    }
  }

  static Future<bool> _handleKakaoToken(OAuthToken token) async {
    try {
      // 카카오 사용자 정보 가져오기
      User user = await UserApi.instance.me();
      
      // 카카오 사용자 정보
      String? email = user.kakaoAccount?.email;
      String? nickname = user.kakaoAccount?.profile?.nickname ?? '카카오사용자';
      String userId = user.id.toString();
      
      if (email == null || email.isEmpty) {
        throw Exception('카카오 이메일 정보가 필요합니다. 카카오 계정 설정에서 이메일 제공에 동의해주세요.');
      }
      
      // Supabase에 카카오 사용자 정보로 로그인/회원가입
      // 카카오 이메일과 카카오 ID를 사용하여 사용자 생성/로그인
      final kakaoPassword = 'kakao_$userId'; // 카카오 사용자 전용 비밀번호
      
      // 먼저 로그인 시도 (이미 가입된 경우)
      try {
        final signInResponse = await SupabaseService.client.auth.signInWithPassword(
          email: email,
          password: kakaoPassword,
        );
        
        if (signInResponse.user != null) {
          return true; // 로그인 성공
        }
      } catch (signInError) {
        // 로그인 실패 - 회원가입 시도
        try {
          final signUpResponse = await SupabaseService.client.auth.signUp(
            email: email,
            password: kakaoPassword,
            data: {
              'provider': 'kakao',
              'kakao_id': userId,
              'kakao_nickname': nickname,
            },
          );
          
          if (signUpResponse.user != null) {
            // 프로필 생성
            try {
              await SupabaseService.client.from('profiles').insert({
                'id': signUpResponse.user!.id,
                'username': nickname,
                'rank': 1000,
                'wins': 0,
                'losses': 0,
              });
            } catch (profileError) {
              // 프로필이 이미 존재할 수 있음 (무시)
            }
            
            return true; // 회원가입 성공
          }
        } catch (signUpError) {
          // 회원가입도 실패한 경우
          throw Exception('카카오 로그인/회원가입 실패: $signUpError');
        }
      }
      
      return false;
    } catch (error) {
      throw Exception('카카오 사용자 정보 처리 오류: $error');
    }
  }

  static Future<void> signOut() async {
    try {
      await UserApi.instance.unlink();
    } catch (error) {
      // 이미 로그아웃된 경우 무시
    }
  }
}

