# Supabase 설정 가이드

## 1. Supabase 프로젝트 생성

1. [Supabase](https://supabase.com)에 가입하고 새 프로젝트 생성
2. 프로젝트 설정에서 URL과 anon key 확인

## 2. 데이터베이스 테이블 생성

Supabase SQL Editor에서 다음 SQL을 실행하세요:

```sql
-- 프로필 테이블
CREATE TABLE profiles (
  id UUID REFERENCES auth.users PRIMARY KEY,
  username TEXT NOT NULL,
  rank INTEGER DEFAULT 1000,
  wins INTEGER DEFAULT 0,
  losses INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 매칭 큐 테이블
CREATE TABLE matchmaking (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users NOT NULL,
  mode TEXT NOT NULL CHECK (mode IN ('normal', 'ranked')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id)
);

-- 게임 테이블
CREATE TABLE games (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  player1_id UUID REFERENCES auth.users NOT NULL,
  player2_id UUID REFERENCES auth.users NOT NULL,
  mode TEXT NOT NULL CHECK (mode IN ('normal', 'ranked')),
  game_state JSONB NOT NULL,
  current_player TEXT NOT NULL CHECK (current_player IN ('player1', 'player2')),
  time_remaining INTEGER DEFAULT 30,
  status TEXT NOT NULL DEFAULT 'playing' CHECK (status IN ('playing', 'finished')),
  winner_id UUID REFERENCES auth.users,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  ended_at TIMESTAMP WITH TIME ZONE
);

-- 인덱스 생성
CREATE INDEX idx_matchmaking_mode ON matchmaking(mode);
CREATE INDEX idx_matchmaking_created ON matchmaking(created_at);
CREATE INDEX idx_games_status ON games(status);
CREATE INDEX idx_games_player1 ON games(player1_id);
CREATE INDEX idx_games_player2 ON games(player2_id);

-- RLS (Row Level Security) 정책
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE matchmaking ENABLE ROW LEVEL SECURITY;
ALTER TABLE games ENABLE ROW LEVEL SECURITY;

-- 프로필 정책: 자신의 프로필만 읽기/수정 가능
CREATE POLICY "Users can view own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

-- 매칭 큐 정책: 모든 사용자가 읽기/쓰기 가능
CREATE POLICY "Anyone can view matchmaking" ON matchmaking
  FOR SELECT USING (true);

CREATE POLICY "Users can insert own matchmaking" ON matchmaking
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own matchmaking" ON matchmaking
  FOR DELETE USING (auth.uid() = user_id);

-- 게임 정책: 참여한 게임만 읽기 가능
CREATE POLICY "Players can view own games" ON games
  FOR SELECT USING (auth.uid() = player1_id OR auth.uid() = player2_id);

CREATE POLICY "Players can update own games" ON games
  FOR UPDATE USING (auth.uid() = player1_id OR auth.uid() = player2_id);
```

## 3. 앱에 Supabase 설정 추가

`lib/main.dart` 파일에서 다음 부분을 수정하세요:

```dart
await SupabaseService.initialize(
  url: 'YOUR_SUPABASE_URL', // Supabase 프로젝트 URL
  anonKey: 'YOUR_SUPABASE_ANON_KEY', // Supabase anon key
);
```

## 4. Realtime 활성화

Supabase 대시보드에서:
1. Database > Replication 메뉴로 이동
2. `games` 테이블의 Replication 활성화

## 5. 테스트

1. 앱 실행
2. 회원가입/로그인
3. 일반게임 또는 랭크게임 선택
4. 매칭 대기 후 게임 시작

