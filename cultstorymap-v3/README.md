# 컬스토리맵 — Supabase 배포 안내

JSON 파일은 사용하지 않습니다. 데이터·로그인·이미지는 Supabase에 저장합니다.

## 1. Supabase 프로젝트 및 관리자 비밀번호 만들기
1. https://supabase.com/dashboard 에서 새 프로젝트를 만듭니다.
2. 왼쪽 **Authentication → Users → Add user → Create new user**를 누릅니다.
3. 이메일에 `2gongi@naver.com`, Password에 본인이 사용할 비밀번호를 입력합니다.
4. 자동 확인 옵션이 보이면 활성화해 계정을 즉시 사용할 수 있게 합니다.
5. 비밀번호는 `config.js`나 HTML에 쓰지 않습니다. 배포된 사이트의 **관리자 로그인 창에서만 직접 입력**합니다.

## 2. 테이블·RLS·Storage 만들기
1. Supabase **SQL Editor → New query**에서 `supabase.sql` 전체를 실행합니다.
2. **Authentication → Users**에서 방금 만든 사용자의 UUID를 복사합니다.
3. SQL Editor에서 아래 한 줄을 UUID만 바꿔 실행합니다.
```sql
insert into public.admin_users(user_id) values ('여기에-관리자-USER-UUID');
```
이 등록을 해야 관리자만 작성·수정·삭제할 수 있습니다.

## 3. 사이트와 Supabase 연결
1. **Project Settings → API**에서 Project URL과 Publishable key 또는 anon public key를 복사합니다.
2. `config.js`의 두 값만 교체합니다.
```js
window.CULTSTORY_CONFIG = {
  url: 'https://xxxx.supabase.co',
  anonKey: 'sb_publishable_xxxx 또는 anon key'
};
```
`service_role` 또는 secret key는 절대 넣지 마세요. anon/publishable key의 프런트 노출은 정상이며, 실제 보호는 `supabase.sql`의 RLS가 담당합니다.

## 4. 배포
### 가장 간단한 방법: Netlify
1. https://app.netlify.com 로그인
2. Add new site → Deploy manually
3. 이 폴더 안의 `index.html`, `config.js`, `korea-dots.png` 3개가 포함되도록 폴더 자체를 드래그합니다.
4. 발급된 `https://....netlify.app` 주소를 공유합니다.

### GitHub Pages
1. 새 GitHub 저장소에 세 파일과 SQL/README를 올립니다.
2. Settings → Pages → Deploy from a branch → main / root → Save
3. 생성된 Pages URL을 공유합니다.

## 5. 비밀번호 변경·분실
- Supabase Dashboard → Authentication → Users → 해당 사용자 메뉴에서 비밀번호를 재설정합니다.
- 사이트에 비밀번호 찾기 기능은 넣지 않았습니다. 관리자 1인용이라 대시보드에서 관리하는 편이 안전합니다.

## 구현 사항
- 방문일과 기록일 분리
- ARCHIVE: 대상·장소·유형·관람 형태·관련 링크·사진
- NOTE 리치 텍스트 편집
- 여러 개 SEED와 여러 개 WORK, 경험으로부터의 연결 흐름 강조
- 고정 유형 9종과 태그/제목/장소 검색
- 연도→월→날짜·제목 구조의 왼쪽 탐색
- 카드의 SEED 개수 표시
- 실제 기록 수·활동 개월·시작 연도 자동 표시
- 업로드 전 최대 1800px WebP 리사이즈
- 관리자 allowlist + RLS + 사용자 UUID 폴더 기반 Storage 정책

## WORK 첨부파일
- 각 WORK에 여러 파일을 첨부할 수 있습니다.
- PDF, DOCX, HWPX, PPTX, XLSX, ZIP, 이미지 등 일반 파일을 지원하며 파일당 최대 20MB입니다.
- 방문자는 공개 기록의 WORK 상세에서 파일명과 크기를 확인하고 다운로드할 수 있습니다.
- 기존 v3를 이미 설치했다면 전체 SQL을 다시 실행하지 말고 `work-files-migration.sql`만 SQL Editor에서 1회 실행하세요.
- 파일은 Supabase Storage의 `work-files` 버킷, 파일 정보는 `work_files` 테이블에 저장됩니다.
