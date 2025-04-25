# delete-vendor-bundle.sh

Ruby 프로젝트의 `vendor/bundle` 디렉토리를 찾아 삭제하는 스크립트입니다.

## 위치

```bash
scripts/cleanup/delete-vendor-bundle.sh
```

## 동작 순서

```bash
1. 시작 디렉토리 설정 (인자 또는 현재 디렉토리)
2. vendor/bundle 패턴의 폴더 검색
3. 찾은 폴더 목록 및 용량 정보 표시
4. 사용자에게 삭제 확인 요청
5. 확인 시 모든 폴더 삭제
```

## 주요 기능

- Ruby 프로젝트의 gem 설치 디렉토리 정리
- 디스크 공간 확보 및 시스템 정리
- 삭제 전 용량 정보 표시로 효과 예측 가능
- 프로젝트 간 공유 gem 유지 (시스템 gem은 영향 없음)

## 사용 방법

```bash
# 권한 부여
chmod +x scripts/cleanup/delete-vendor-bundle.sh

# 현재 디렉토리에서 검색 시작
./scripts/cleanup/delete-vendor-bundle.sh

# 특정 디렉토리에서 검색 시작
./scripts/cleanup/delete-vendor-bundle.sh /path/to/directory
```
