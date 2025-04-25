# rsync-backup.sh

rsync를 이용하여 지정된 디렉토리를 외부 디스크에 백업하는 고급 스크립트입니다.

## 위치

```bash
scripts/backup/rsync-backup.sh
```

## 동작 순서

```bash
1. 초기 설정 및 필요 도구 확인
2. 백업 대상 디렉토리 목록 확인
3. 백업 실행 (병렬 또는 순차 실행)
   - 각 디렉토리별 작업:
     - 소스/대상 디렉토리 확인
     - 디스크 마운트 확인
     - 디스크 공간 확인
     - rsync 명령으로 백업 실행
     - 실패 시 재시도 (최대 3회)
4. 백업 검증 (파일 수 비교)
5. 정리 작업 (오래된 로그 및 임시 백업 제거)
6. 결과 요약 출력
```

## 주요 기능

- 지정된 디렉토리를 외부 디스크에 백업
- 병렬 처리 지원으로 빠른 백업 실행
- 대역폭 제한 기능
- 실패 시 자동 재시도
- 백업 완료 후 자동 검증
- 오래된 백업 및 로그 자동 정리
- 상세한 로그 기록

## 사용자 설정

스크립트 사용 전 다음 설정을 확인하고 수정하세요:

```bash
# 사용자명 설정
USER_NAME="mac_user"  # 실제 사용자명으로 변경

# 백업 대상 디렉토리 설정
BACKUP_DIRS=(
    "/Users/${USER_NAME}/Documents:/Volumes/MyBackup/Documents:/dev/null"
    # 형식: "소스경로:대상경로:로컬백업경로"
)

# 로그 디렉토리 설정
LOG_DIR="/Users/${USER_NAME}/Desktop/backup_logs"
```

## 사용 방법

```bash
# 권한 부여
chmod +x scripts/backup/rsync-backup.sh

# 기본 실행
./scripts/backup/rsync-backup.sh

# 테스트 모드 실행 (실제 복사 없이 시뮬레이션)
./scripts/backup/rsync-backup.sh --test

# 대역폭 제한 설정 (5MB/s)
./scripts/backup/rsync-backup.sh --limit 5000

# 병렬 작업 수 설정
./scripts/backup/rsync-backup.sh --threads 4

# 도움말 표시
./scripts/backup/rsync-backup.sh --help
```

## 선택적 옵션

```bash
--help              도움말 표시
--test              테스트 모드 실행 (--dry-run)
--limit SPEED       대역폭 제한 설정 (KB/s)
--threads NUM       병렬 작업 수 설정
--retries NUM       재시도 횟수 설정
--stopOnError       오류 발생 시 중지
--excludePattern    제외할 파일 패턴 (예: "*.tmp|*.bak")
--version           버전 정보 표시
```
