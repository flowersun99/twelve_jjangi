# 카카오 로그인 KOE002 오류 해결 가이드

## 오류 원인
KOE002 오류는 카카오 개발자 콘솔의 설정이 올바르지 않을 때 발생합니다.

## 해결 방법

### 1. 카카오 개발자 콘솔 접속
https://developers.kakao.com/ 접속 후 로그인

### 2. 내 애플리케이션 선택
- 등록한 애플리케이션 선택 (앱 키: 3fdcaa17a7828b19a39c9e312ffb5631)

### 3. 플랫폼 설정 확인

#### Android 플랫폼 설정
1. **앱 설정** → **플랫폼** → **Android 플랫폼 등록**
2. **패키지명** 입력: `com.example.twelve_jjangi`
3. **키 해시** 등록 (디버그용)
   - Windows에서 키 해시 확인:
   ```bash
   keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
   ```
   - SHA1 해시를 복사하여 등록

#### iOS 플랫폼 설정 (iOS 개발 시)
1. **앱 설정** → **플랫폼** → **iOS 플랫폼 등록**
2. **번들 ID** 입력: 프로젝트의 Bundle Identifier

### 4. 카카오 로그인 활성화
1. **제품 설정** → **카카오 로그인** → **활성화 설정** → **활성화**
2. **Redirect URI** 등록:
   - Android: `myapp://oauth` 또는 `kakao3fdcaa17a7://oauth`
   - iOS: `myapp://oauth` 또는 `kakao3fdcaa17a7://oauth`
   - 웹: `http://localhost:61025/callback` (이미 등록하셨다고 하셨으니 확인만)

### 5. 동의 항목 설정
1. **제품 설정** → **카카오 로그인** → **동의항목**
2. 필수 동의 항목:
   - **이메일** (필수): 카카오 계정 이메일
   - **닉네임** (선택): 프로필 닉네임
   - **프로필 사진** (선택): 프로필 사진

### 6. 앱 키 확인
- **앱 설정** → **앱 키**에서 확인
- REST API 키: `3fdcaa17a7828b19a39c9e312ffb5631` (확인)

### 7. 저장 및 확인
- 모든 설정을 저장한 후
- **앱 설정** → **앱 키**에서 **REST API 키**가 올바른지 확인
- **제품 설정** → **카카오 로그인**에서 **활성화** 상태 확인

## 추가 확인 사항

### Android 패키지명 확인
- `android/app/build.gradle.kts` 파일에서 `applicationId` 확인
- 현재: `com.example.twelve_jjangi`
- 카카오 개발자 콘솔의 Android 플랫폼 패키지명과 일치해야 함

### 키 해시 등록 (중요!)
- 디버그용 키 해시를 반드시 등록해야 합니다
- 키 해시가 없으면 KOE002 오류가 발생할 수 있습니다

## 테스트
설정 완료 후:
1. 앱을 완전히 종료하고 재시작
2. 카카오 로그인 버튼 클릭
3. 정상적으로 로그인되는지 확인

## 문제가 계속되면
1. 카카오 개발자 콘솔에서 설정을 다시 한 번 확인
2. 앱을 완전히 삭제하고 재설치
3. 카카오톡 앱이 최신 버전인지 확인
4. 에뮬레이터가 아닌 실제 기기에서 테스트

