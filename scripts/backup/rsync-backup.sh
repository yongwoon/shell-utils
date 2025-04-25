# Pre-required
# 다른 사용자가 이 스크립트를 사용하기 전 수정해야 할 부분:
#
# 1. 사용자명 설정 (약 50줄 부근):
#    USER_NAME="mac_user" 부분을 실제 사용자명으로 변경
#
# 2. 백업 디렉토리 설정 (약 340줄 부근):
#    BACKUP_DIRS 배열에서 다음 형식으로 백업 경로 설정
#    "/사용자_소스경로:/Volumes/외장디스크명/목적지경로:/dev/null"
#    예시: "/Users/${USER_NAME}/Documents:/Volumes/MyBackup/Documents:/dev/null"
#
# 3. 로그 디렉토리 설정 (약 70줄 부근):
#    LOG_DIR="/Users/${USER_NAME}/Desktop/backup_logs"  # 로그 저장 위치
#
# 4. 임시 백업 디렉토리 설정 (약 65줄 부근):
#    LOCAL_BACKUP_ROOT="/Users/${USER_NAME}/TempBackup"  # 임시 백업 위치
#    (로컬 백업을 /dev/null로 설정한 경우 중요도 낮음)
#
# 참고: ${USER_NAME} 변수의 기본값은 "mac_user"입니다.
#      반드시 실제 사용자명으로 변경하거나, 경로를 직접 수정하세요.
#
# 5. 기타 필요에 따라 조정 가능한 설정:
#    - RSYNC_OPTIONS: rsync 옵션 (약 55줄 부근)
#    - MAX_PARALLEL_JOBS: 병렬 작업 수 (약 58줄 부근)
#    - BANDWIDTH_LIMIT: 대역폭 제한 (약 68줄 부근)
#
# ## How to use ?
# change folder permission
# ```
# chmod +x rsync-backup.sh
# ```
#
# ## execute
# ```
# ./rsync-backup.sh
# ```
#
# ## test (동기화를 실제로 수행하기 전 --dry-run 옵션으로 실행 결과를 시뮬레이션)
# ```
# ./rsync-backup.sh --test
# ```
#
# ## stop process
# ```
# ps aux | grep rsync
# kill -STOP [PROCESS ID]
# ```

#!/bin/bash

# 기본 설정
SCRIPT_NAME=$(basename "$0")
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
DATE_FORMAT="%Y-%m-%d %H:%M:%S"
DATE_STAMP=$(date +%Y%m%d)

# 사용자 설정
USER_NAME="mac_user"  # 사용자명 기본값, 필요에 따라 수정하세요

# 백업 설정
RSYNC_TIMEOUT=172800  # 48시간
RSYNC_OPTIONS="-av --exclude='.DS_Store' --exclude='.Trash*' --stats --human-readable --info=progress2"

# 병렬 처리를 위한 설정
MAX_PARALLEL_JOBS=2  # 동시에 실행할 최대 백업 작업 수
IONICE_ENABLED=true  # IO 우선순위 조정 활성화 (Linux에서만 작동)

# 큰 파일 처리 개선
LARGE_FILE_THRESHOLD="500M"  # 큰 파일 기준 (500MB)
CHUNK_SIZE="100M"  # 큰 파일을 나눌 청크 크기

# 네트워크 제한 설정
BANDWIDTH_LIMIT="0"  # 0은 제한 없음, 단위는 KB/s (예: "5000" = 5MB/s)

# 백업 경로
# 사용자 환경에 맞게 변경하세요
LOCAL_BACKUP_ROOT="/Users/${USER_NAME}/TempBackup"  # 임시 백업 저장 경로

# 로그 설정
# 사용자 환경에 맞게 변경하세요
LOG_DIR="/Users/${USER_NAME}/Desktop/backup_logs"  # 로그 파일 저장 경로
LOG_FILE="$LOG_DIR/${DATE_STAMP}_backup.log"
ERROR_LOG_FILE="$LOG_DIR/${DATE_STAMP}_error.log"
PROGRESS_LOG_FILE="$LOG_DIR/${DATE_STAMP}_progress.log"

# 오류 핸들링 설정
STOP_ON_ERROR=false  # 실패 시 중지하려면 true, 모든 작업 시도하려면 false

# 재시도 설정
MAX_RETRIES=3
RETRY_DELAY=10  # 초

# 임시 파일 및 디렉토리
TMP_DIR="/tmp/backup_tmp_${DATE_STAMP}"

# 카운터 변수 초기화
SUCCESS=0
PARTIAL=0
LOCAL_ONLY=0
FAILED=0
TOTAL=0

# 초기화
init() {
    # 로그 디렉토리 생성
    mkdir -p "$LOG_DIR"

    # 로컬 백업 디렉토리 생성
    mkdir -p "$LOCAL_BACKUP_ROOT/$DATE_STAMP"

    # 임시 디렉토리 생성
    mkdir -p "$TMP_DIR"

    # 로그 파일 시작
    echo "===== 백업 스크립트 시작: $(date +"$DATE_FORMAT") =====" > "$LOG_FILE"
    echo "===== 백업 스크립트 에러 로그: $(date +"$DATE_FORMAT") =====" > "$ERROR_LOG_FILE"
    echo "===== 백업 진행 상황 로그: $(date +"$DATE_FORMAT") =====" > "$PROGRESS_LOG_FILE"

    # 필요한 명령어 확인
    check_requirements
}

# 필요한 명령어 확인
check_requirements() {
    local REQUIRED_COMMANDS=("rsync" "bc" "readlink" "find" "du" "df")
    local MISSING=0

    for CMD in "${REQUIRED_COMMANDS[@]}"; do
        if ! command -v "$CMD" &> /dev/null; then
            log_message "경고: $CMD 명령어를 찾을 수 없습니다."
            ((MISSING++))
        fi
    done

    if [ $MISSING -gt 0 ]; then
        log_message "일부 필수 명령어가 없습니다. 백업이 제대로 실행되지 않을 수 있습니다." "WARNING"
        log_message "Mac에서 필요한 도구 설치: brew install coreutils" "INFO"
    fi
}

# 로그 함수
log_message() {
    local MESSAGE="$1"
    local LOG_LEVEL="${2:-INFO}"
    local TIMESTAMP=$(date +"$DATE_FORMAT")

    echo "[$LOG_LEVEL] $TIMESTAMP - $MESSAGE" >> "$LOG_FILE"

    # 오류 로그는 별도 파일에 기록
    if [[ "$LOG_LEVEL" == "ERROR" || "$LOG_LEVEL" == "WARNING" ]]; then
        echo "[$LOG_LEVEL] $TIMESTAMP - $MESSAGE" >> "$ERROR_LOG_FILE"
    fi

    # 콘솔 출력 (색상 적용)
    case $LOG_LEVEL in
        "INFO")    echo -e "\033[0;32m[$LOG_LEVEL]\033[0m $TIMESTAMP - $MESSAGE" ;;
        "WARNING") echo -e "\033[0;33m[$LOG_LEVEL]\033[0m $TIMESTAMP - $MESSAGE" ;;
        "ERROR")   echo -e "\033[0;31m[$LOG_LEVEL]\033[0m $TIMESTAMP - $MESSAGE" ;;
        *)         echo -e "[$LOG_LEVEL] $TIMESTAMP - $MESSAGE" ;;
    esac
}

# 진행 상황 업데이트
update_progress() {
    local BACKUP_NAME="$1"
    local PERCENT="$2"
    local CURRENT="$3"
    local TOTAL="$4"
    local TIMESTAMP=$(date +"$DATE_FORMAT")

    echo "[$BACKUP_NAME] $TIMESTAMP - 진행률: $PERCENT% ($CURRENT/$TOTAL)" >> "$PROGRESS_LOG_FILE"
    echo -e "\033[0;36m[PROGRESS]\033[0m $TIMESTAMP - [$BACKUP_NAME] 진행률: $PERCENT% ($CURRENT/$TOTAL)"
}

# 디스크 마운트 확인
check_mount() {
    local DISK_PATH="$1"

    if [[ "$DISK_PATH" == /Volumes/* ]]; then
        local DISK_NAME=$(echo "$DISK_PATH" | cut -d'/' -f3)

        if ! df | grep -q "/Volumes/$DISK_NAME"; then
            log_message "디스크가 마운트되어 있지 않습니다: $DISK_NAME" "ERROR"
            return 1
        fi
    else
        # 로컬 디렉토리인 경우 부모 디렉토리가 존재하는지 확인
        local PARENT_DIR=$(dirname "$DISK_PATH")
        if [ ! -d "$PARENT_DIR" ]; then
            log_message "부모 디렉토리가 존재하지 않습니다: $PARENT_DIR" "ERROR"
            return 1
        fi
    fi

    # 디렉토리 쓰기 가능 확인
    if [ -d "$DISK_PATH" ] && [ ! -w "$DISK_PATH" ]; then
        log_message "$DISK_PATH 디렉토리에 쓰기 권한이 없습니다." "ERROR"
        return 1
    fi

    return 0
}

# 디스크 공간 확인 (수정된 버전)
check_disk_space() {
    local SRC="$1"
    local DEST="$2"
    local MARGIN="${3:-1.1}"  # 기본 마진 10%

    # 소스 디렉토리 크기 측정 최적화
    log_message "$SRC 디렉토리 크기 계산 중..."

    # du 명령을 사용하여 소스 크기 측정
    local APPROX_SIZE=$(du -sk "$SRC" 2>/dev/null | cut -f1)

    # du 실패시 기본값 설정
    if [ -z "$APPROX_SIZE" ]; then
        APPROX_SIZE=1
        log_message "du 명령 실패, 크기를 1KB로 설정" "WARNING"
    fi

    # 소스 크기가 0일 경우 최소값 설정 (오류 방지)
    if [ "$APPROX_SIZE" -eq 0 ]; then
        APPROX_SIZE=1
    fi

    # 사람이 읽을 수 있는 형식으로 변환 (KB -> 읽기 쉬운 형식)
    local HUMAN_SIZE_K=$((APPROX_SIZE))
    local HUMAN_SIZE=""

    if [ $HUMAN_SIZE_K -ge 1048576 ]; then
        HUMAN_SIZE="$(echo "scale=2; $HUMAN_SIZE_K/1048576" | bc)GB"
    elif [ $HUMAN_SIZE_K -ge 1024 ]; then
        HUMAN_SIZE="$(echo "scale=2; $HUMAN_SIZE_K/1024" | bc)MB"
    else
        HUMAN_SIZE="${HUMAN_SIZE_K}KB"
    fi

    log_message "소스 크기 (추정): $HUMAN_SIZE"

    # 대상 디스크 여유 공간 (KB)
    local DEST_AVAIL=0
    if [ -d "$DEST" ]; then
        DEST_AVAIL=$(df -k "$DEST" | awk 'NR==2 {print \$4}')

        # df 명령 실패시 기본값 설정
        if [ -z "$DEST_AVAIL" ] || ! [[ "$DEST_AVAIL" =~ ^[0-9]+$ ]]; then
            log_message "대상 디스크 공간 확인 실패" "WARNING"
            DEST_AVAIL=0
        fi
    else
        log_message "대상 디렉토리가 존재하지 않습니다: $DEST" "WARNING"
    fi

    # 여유 공간 포맷
    local HUMAN_AVAIL_K=$((DEST_AVAIL))
    local HUMAN_AVAIL=""

    if [ $HUMAN_AVAIL_K -ge 1048576 ]; then
        HUMAN_AVAIL="$(echo "scale=2; $HUMAN_AVAIL_K/1048576" | bc)GB"
    elif [ $HUMAN_AVAIL_K -ge 1024 ]; then
        HUMAN_AVAIL="$(echo "scale=2; $HUMAN_AVAIL_K/1024" | bc)MB"
    else
        HUMAN_AVAIL="${HUMAN_AVAIL_K}KB"
    fi

    log_message "대상 디스크 여유 공간: $HUMAN_AVAIL"

    # 필요한 공간 계산 (마진 적용)
    local NEEDED_SPACE=$(echo "$APPROX_SIZE * $MARGIN" | bc | cut -d'.' -f1)

    # 공간 충분한지 확인
    if [ $DEST_AVAIL -lt $NEEDED_SPACE ]; then
        log_message "디스크 공간 부족: 필요한 공간 ${HUMAN_SIZE}, 사용 가능한 공간 ${HUMAN_AVAIL}" "ERROR"
        return 1
    fi

    log_message "디스크 공간 확인 완료: 필요한 공간 ${HUMAN_SIZE}, 사용 가능한 공간 ${HUMAN_AVAIL}"
    return 0
}

# 백업 실행 함수
backup_directory() {
    local SRC="$1"
    local DEST="$2"
    local LOCAL_BACKUP="$3" # Keep parameter for compatibility
    local BACKUP_NAME=$(basename "$SRC")

    log_message "[$BACKUP_NAME] 백업 시작"

    # 소스 디렉토리 확인
    if [ ! -d "$SRC" ]; then
        log_message "[$BACKUP_NAME] 소스 디렉토리가 존재하지 않습니다: $SRC" "ERROR"
        return 1
    fi

    # 외부 백업 디스크가 마운트되어 있는지 확인
    if ! check_mount "$DEST"; then
        log_message "[$BACKUP_NAME] 외부 디스크가 마운트되어 있지 않습니다" "ERROR"
        return 2
    fi

    # 외부 디스크 공간 확인
    if ! check_disk_space "$SRC" "$DEST"; then
        log_message "[$BACKUP_NAME] 외부 디스크 공간 부족" "ERROR"
        return 3
    fi

    # rsync 옵션 구성
    local RSYNC_CMD="rsync $RSYNC_OPTIONS"

    # 대역폭 제한 적용
    if [ "$BANDWIDTH_LIMIT" != "0" ]; then
        RSYNC_CMD="$RSYNC_CMD --bwlimit=$BANDWIDTH_LIMIT"
    fi

    log_message "[$BACKUP_NAME] 백업 시작: $SRC -> $DEST"

    # 외부 디스크에 직접 백업
    local ATTEMPT=1
    local EXT_STATUS=1

    while [ $ATTEMPT -le $MAX_RETRIES ] && [ $EXT_STATUS -ne 0 ]; do
        if [ $ATTEMPT -gt 1 ]; then
            log_message "[$BACKUP_NAME] 백업 재시도 $ATTEMPT/$MAX_RETRIES" "WARNING"
            sleep $RETRY_DELAY
        fi

        mkdir -p "$DEST"
        $RSYNC_CMD "$SRC/" "$DEST/" 2>&1 | tee "$TMP_DIR/${BACKUP_NAME}_backup.log"
        EXT_STATUS=${PIPESTATUS[0]}
        ((ATTEMPT++))
    done

    if [ $EXT_STATUS -eq 0 ]; then
        log_message "[$BACKUP_NAME] 백업 성공"
        return 0
    else
        log_message "[$BACKUP_NAME] 백업 실패 (코드: $EXT_STATUS) $MAX_RETRIES회 시도 후" "ERROR"
        return 4
    fi
}

# 메인 함수
main() {
    START_TIME=$(date +%s)

    log_message "백업 스크립트 시작"
    init

    # 백업할 디렉토리 목록
    declare -a BACKUP_DIRS=(
        # 형식: "소스경로:대상경로:로컬백업경로"
        # 예시:
        # "/Users/사용자명/Documents:/Volumes/백업디스크/Documents:/dev/null"
        #
        # 로컬백업경로를 /dev/null로 설정하면 로컬 백업은 수행되지 않습니다.
        # /dev/null은 데이터를 버리는 특수 장치로, 로컬 디스크 공간을 사용하지 않습니다.
        # 로컬 저장 공간이 부족한 경우 이 설정이 적합합니다.
        #
        # 실제 백업할 디렉토리 경로 설정:
        "/Users/${USER_NAME}/Documents:/Volumes/MyBackup/Documents:/dev/null",
        "/Users/${USER_NAME}/Desktop:/Volumes/MyBackup/Desktop:/dev/null",
        "/Users/${USER_NAME}/Pictures:/Volumes/MyBackup/Pictures:/dev/null"
        # 필요한 추가 디렉토리를 여기에 같은 형식으로 추가하세요
    )

    # 총 백업 항목 수
    TOTAL=${#BACKUP_DIRS[@]}
    log_message "총 백업 항목: $TOTAL"

    # 병렬 처리 확인
    if command -v parallel &> /dev/null && [ $MAX_PARALLEL_JOBS -gt 1 ]; then
        log_message "병렬 처리 활성화: 최대 $MAX_PARALLEL_JOBS 작업"

        # 작업 목록 생성
        for ((i=0; i<${#BACKUP_DIRS[@]}; i++)); do
            IFS=':' read -ra DIR_INFO <<< "${BACKUP_DIRS[$i]}"
            echo "$SCRIPT_NAME --job \"${DIR_INFO[0]}\" \"${DIR_INFO[1]}\" \"${DIR_INFO[2]}\"" >> "$TMP_DIR/jobs.txt"
        done

        # 병렬 실행
        cat "$TMP_DIR/jobs.txt" | parallel -j $MAX_PARALLEL_JOBS

        # 결과 수집
        log_message "병렬 백업 완료"
    else
        # 순차 실행
        local COUNTER=1

        for backup_item in "${BACKUP_DIRS[@]}"; do
            log_message "백업 항목 $COUNTER/$TOTAL 시작"

            IFS=':' read -ra DIR_INFO <<< "$backup_item"
            SRC="${DIR_INFO[0]}"
            DEST="${DIR_INFO[1]}"
            LOCAL_BACKUP="${DIR_INFO[2]}"

            backup_directory "$SRC" "$DEST" "$LOCAL_BACKUP"
            local RESULT=$?

            case $RESULT in
                0)
                    log_message "백업 항목 $COUNTER/$TOTAL 완료: 성공"
                    ((SUCCESS++))
                    ;;
                1)
                    log_message "백업 항목 $COUNTER/$TOTAL 완료: 실패" "ERROR"
                    ((FAILED++))
                    if [ "$STOP_ON_ERROR" = true ]; then
                        log_message "오류 발생으로 백업 중단" "ERROR"
                        break
                    fi
                    ;;
                2|3|4)
                    log_message "백업 항목 $COUNTER/$TOTAL 완료: 외부 백업 실패" "ERROR"
                    ((FAILED++))
                    ;;
            esac

            ((COUNTER++))
        done
    fi

    # 백업 후 데이터 검증
    log_message "백업 검증 시작..."
    for backup_item in "${BACKUP_DIRS[@]}"; do
        IFS=':' read -ra DIR_INFO <<< "$backup_item"
        SRC="${DIR_INFO[0]}"
        DEST="${DIR_INFO[1]}"
        BACKUP_NAME=$(basename "$SRC")

        log_message "[$BACKUP_NAME] 백업 검증 중..."

        # 간단한 파일 수 비교로 검증
        if [ -d "$SRC" ] && [ -d "$DEST" ]; then
            local SRC_FILES=$(find "$SRC" -type f | wc -l)
            local DEST_FILES=$(find "$DEST" -type f | wc -l)

            local DIFF_PERCENT=0
            if [ $SRC_FILES -gt 0 ]; then
                DIFF_PERCENT=$(( (SRC_FILES - DEST_FILES) * 100 / SRC_FILES ))
                # 절대값 계산
                if [ $DIFF_PERCENT -lt 0 ]; then
                    DIFF_PERCENT=$((DIFF_PERCENT * -1))
                fi
            fi

            if [ "$DIFF_PERCENT" -gt 10 ]; then
                log_message "[$BACKUP_NAME] 검증 경고: 파일 수 차이가 ${DIFF_PERCENT}% 입니다" "WARNING"
            else
                log_message "[$BACKUP_NAME] 검증 성공: 파일 수 차이가 허용 범위 내입니다"
            fi
        else
            log_message "[$BACKUP_NAME] 검증 실패: 디렉토리가 없습니다" "ERROR"
        fi
    done

    # 백업 완료 후 정리 작업
    log_message "정리 작업 수행 중..."

    # 오래된 로그 파일 정리 (30일 이상 지난 로그)
    if command -v find &> /dev/null; then
        find "$LOG_DIR" -type f -name "*.log" -mtime +30 -exec rm -f {} \; 2>/dev/null
        log_message "30일 이상 지난 로그 파일들을 정리했습니다"
    fi

    # 오래된 백업 정리
    if command -v find &> /dev/null; then
        # 7일 이상 지난 임시 백업 정리 (TempBackup)
        find "$LOCAL_BACKUP_ROOT" -maxdepth 1 -type d -name "2*" -mtime +7 -exec rm -rf {} \; 2>/dev/null
        log_message "7일 이상 지난 임시 백업 디렉토리를 정리했습니다"
    fi

    # 임시 디렉토리 정리
    log_message "임시 파일 정리 중..."
    rm -rf "$TMP_DIR"

    # 백업 종료 시간 및 소요 시간 계산
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    HOURS=$((DURATION / 3600))
    MINUTES=$(( (DURATION % 3600) / 60 ))
    SECONDS=$((DURATION % 60))

    # 결과 요약
    log_message "===== 백업 프로세스 완료 ====="
    log_message "백업 소요 시간: ${HOURS}시간 ${MINUTES}분 ${SECONDS}초"
    log_message "성공: $SUCCESS, 실패: $FAILED, 총: $TOTAL"

    if [ $FAILED -eq 0 ]; then
        log_message "전체 백업 성공"
        return 0
    else
        log_message "일부 백업 실패" "ERROR"
        return 1
    fi
}

# 도움말 보여주기
show_help() {
    cat << EOF
사용법: $SCRIPT_NAME [옵션]

옵션:
  --help              도움말 표시
  --job SRC DEST LOCAL  단일 백업 작업 실행 (병렬처리용)
  --test              실제 복사 없이 테스트 모드로 실행 (dry-run)
  --limit SPEED       대역폭 제한 설정 (KB/s)
  --threads NUM       병렬 작업 수 설정
  --retries NUM       재시도 횟수 설정
  --stopOnError       오류 발생 시 중지
  --excludePattern    제외할 파일 패턴 (예: "*.tmp|*.bak")
  --version           버전 정보 표시
예시:
  $SCRIPT_NAME                        # 모든 백업 실행
  $SCRIPT_NAME --test                 # 테스트 모드로 실행
  $SCRIPT_NAME --limit 5000           # 대역폭을 5MB/s로 제한
  $SCRIPT_NAME --threads 4            # 4개 작업을 병렬로 실행
  $SCRIPT_NAME --excludePattern "*.tmp|*.log"  # tmp와 log 파일 제외
EOF
}

# 버전 정보 표시
show_version() {
    echo "백업 스크립트 버전 1.2.1"
    echo "최종 업데이트: 2023-07-01"  # 현재 날짜로 수정
    echo "개발자: Yongwoon"
}

# 명령줄 인수 처리
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help)
            show_help
            exit 0
            ;;
        --version)
            show_version
            exit 0
            ;;
        --job)
            # 단일 작업 모드
            if [[ $# -lt 4 ]]; then
                echo "오류: --job 옵션에는 3개의 인수가 필요합니다 (SRC DEST LOCAL)"
                exit 1
            fi
            SRC="$2"
            DEST="$3"
            LOCAL_BACKUP="$4"
            backup_directory "$SRC" "$DEST" "$LOCAL_BACKUP"
            exit $?
            ;;
        --test)
            # Dry-run 모드
            RSYNC_OPTIONS="$RSYNC_OPTIONS --dry-run"
            shift
            ;;
        --limit)
            if [[ $# -lt 2 ]]; then
                echo "오류: --limit 옵션에는 속도 값이 필요합니다"
                exit 1
            fi
            BANDWIDTH_LIMIT="$2"
            shift 2
            ;;
        --threads)
            if [[ $# -lt 2 ]]; then
                echo "오류: --threads 옵션에는 숫자 값이 필요합니다"
                exit 1
            fi
            MAX_PARALLEL_JOBS="$2"
            shift 2
            ;;
        --retries)
            if [[ $# -lt 2 ]]; then
                echo "오류: --retries 옵션에는 숫자 값이 필요합니다"
                exit 1
            fi
            MAX_RETRIES="$2"
            shift 2
            ;;
        --stopOnError)
            STOP_ON_ERROR=true
            shift
            ;;
        --excludePattern)
            if [[ $# -lt 2 ]]; then
                echo "오류: --excludePattern 옵션에는 패턴이 필요합니다"
                exit 1
            fi
            # 파이프로 구분된 패턴을 rsync 옵션으로 변환
            IFS='|' read -ra PATTERNS <<< "$2"
            for PATTERN in "${PATTERNS[@]}"; do
                RSYNC_OPTIONS="$RSYNC_OPTIONS --exclude=\"$PATTERN\""
            done
            shift 2
            ;;
        *)
            echo "알 수 없는 옵션: $1"
            show_help
            exit 1
            ;;
    esac
done

# 스크립트가 인터럽트 시그널 수신 시 정리 함수
cleanup() {
    log_message "백업 프로세스가 인터럽트되었습니다." "WARNING"

    # 임시 파일 정리
    if [ -d "$TMP_DIR" ]; then
        rm -rf "$TMP_DIR"
    fi

    exit 130
}

# 시그널 트랩 설정
trap cleanup SIGINT SIGTERM

# 메인 실행
main

exit $?
