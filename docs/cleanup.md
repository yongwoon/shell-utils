# cleanup.sh

프로젝트 디렉토리 내의 불필요한 폴더와 파일을 검색하고 삭제하는 통합 정리 스크립트입니다.

## 위치

```bash
scripts/cleanup/cleanup.sh
```

## 주요 기능

- **폴더 검색 및 삭제**: node_modules, .next, .astro, dist, .pnpm-store, tmp, .turbo, .cache
- **경로 패턴 검색**: tmp/cache, vendor/bundle
- **파일 패턴 검색**: *.log, *.log.*, .DS_Store
- **대화형 인터페이스**: 삭제 전 검색 결과 확인 및 선택적 삭제
- **용량 정보 표시**: 각 항목의 디스크 사용량 확인

## 동작 순서

```
1. 시작 디렉토리 설정 (인자 또는 현재 디렉토리)
2. 삭제 대상 검색
   - 폴더 이름으로 검색 (node_modules, .next 등)
   - 경로 패턴으로 검색 (tmp/cache, vendor/bundle)
   - 파일 패턴으로 검색 (*.log, .DS_Store 등)
3. 검색 결과 및 용량 정보 표시
4. 삭제 옵션 선택
   - 모든 항목 삭제
   - 폴더만 삭제
   - 파일만 삭제
   - 취소
5. 선택된 항목 삭제 실행
```

## 삭제 대상

### 폴더 (이름 기준)

| 폴더명 | 설명 |
|--------|------|
| `node_modules` | Node.js 패키지 디렉토리 |
| `.next` | Next.js 빌드 캐시 |
| `.astro` | Astro 빌드 캐시 |
| `dist` | 빌드 출력 디렉토리 |
| `.pnpm-store` | pnpm 패키지 저장소 |
| `tmp` | 임시 파일 디렉토리 |
| `.turbo` | Turborepo 캐시 |
| `.cache` | 일반 캐시 디렉토리 |

### 경로 패턴

| 패턴 | 설명 |
|------|------|
| `tmp/cache` | 임시 캐시 디렉토리 |
| `vendor/bundle` | Ruby 번들러 디렉토리 |

### 파일 패턴

| 패턴 | 설명 |
|------|------|
| `*.log` | 로그 파일 |
| `*.log.*` | 롤링 로그 파일 |
| `.DS_Store` | macOS 메타데이터 파일 |

## 사용 방법

```bash
# 권한 부여
chmod +x scripts/cleanup/cleanup.sh

# 현재 디렉토리에서 실행
./scripts/cleanup/cleanup.sh

# 특정 디렉토리에서 실행
./scripts/cleanup/cleanup.sh /path/to/directory

# 모든 항목 한번에 삭제 (확인 후)
./scripts/cleanup/cleanup.sh --all
```

## 옵션

| 옵션 | 설명 |
|------|------|
| `--all` | 검색된 모든 항목을 한번에 삭제 (확인 메뉴 표시) |
| `[경로]` | 검색을 시작할 디렉토리 경로 지정 |

## 주의사항

- 삭제된 파일과 폴더는 복구할 수 없습니다.
- 실행 전 검색 결과를 반드시 확인하세요.
- 숨김 폴더(`.`로 시작하는 경로) 내부의 항목은 검색에서 제외됩니다.
