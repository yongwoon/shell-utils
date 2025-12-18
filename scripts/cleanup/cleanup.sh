#!/bin/bash

# =============================================================================
# 프로젝트 정리 스크립트 (Project Cleanup Script)
# =============================================================================
# 사용법:
#   chmod +x cleanup.sh
#   ./cleanup.sh                    # 현재 디렉토리에서 실행
#   ./cleanup.sh /path/to/directory # 특정 디렉토리에서 실행
#   ./cleanup.sh --all              # 모든 항목 한번에 삭제 (확인 후)
# =============================================================================

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 삭제 대상 정의
# 폴더 이름으로 검색 (어디서든 해당 이름의 폴더 삭제)
FOLDER_NAMES=("node_modules" ".next" ".astro" "dist" ".pnpm-store" "tmp" ".turbo" ".cache")

# 경로 패턴으로 검색 (특정 경로 구조의 폴더 삭제)
PATH_PATTERNS=("tmp/cache" "vendor/bundle")

# 파일 패턴으로 검색 (특정 패턴의 파일 삭제)
FILE_PATTERNS=("*.log" "*.log.*" ".DS_Store")

# 시작 디렉토리 설정
START_DIR="."
DELETE_ALL=false

# 인자 파싱
for arg in "$@"; do
  case $arg in
    --all)
      DELETE_ALL=true
      ;;
    *)
      if [ -d "$arg" ]; then
        START_DIR="$arg"
      fi
      ;;
  esac
done

# 함수: 구분선 출력
print_separator() {
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# 함수: 헤더 출력
print_header() {
  clear
  echo -e "${CYAN}"
  echo "  ╔═══════════════════════════════════════════════════════════╗"
  echo "  ║           프로젝트 정리 스크립트 (Cleanup)                ║"
  echo "  ╚═══════════════════════════════════════════════════════════╝"
  echo -e "${NC}"
  echo -e "  시작 디렉토리: ${GREEN}$START_DIR${NC}"
  print_separator
}

# 함수: 폴더 이름으로 검색
find_folders_by_name() {
  local name="$1"
  find "$START_DIR" -type d -name "$name" -not -path "*/\.*/$name" 2>/dev/null
}

# 함수: 경로 패턴으로 검색
find_folders_by_path() {
  local pattern="$1"
  find "$START_DIR" -type d -path "*/$pattern" -not -path "*/\.*" 2>/dev/null
}

# 함수: 파일 패턴으로 검색
find_files_by_pattern() {
  local pattern="$1"
  find "$START_DIR" -type f -name "$pattern" -not -path "*/\.*" 2>/dev/null
}

# 함수: 용량 계산 (human readable)
get_size() {
  local path="$1"
  if [ -e "$path" ]; then
    du -sh "$path" 2>/dev/null | cut -f1
  else
    echo "0"
  fi
}

# 함수: 총 용량 계산
get_total_size() {
  local items="$1"
  if [ -n "$items" ]; then
    echo "$items" | xargs du -sc 2>/dev/null | tail -1 | cut -f1 | numfmt --to=iec 2>/dev/null || echo "계산 불가"
  else
    echo "0"
  fi
}

# 함수: 결과 표시
show_results() {
  local category="$1"
  local items="$2"
  local count=$(echo "$items" | grep -c . || echo 0)

  if [ -z "$items" ] || [ "$count" -eq 0 ]; then
    echo -e "  ${YELLOW}$category${NC}: 찾은 항목 없음"
    return 1
  fi

  echo -e "\n  ${GREEN}[$category]${NC} - $count 개 발견"
  echo "$items" | while read -r item; do
    if [ -n "$item" ]; then
      local size=$(get_size "$item")
      echo -e "    ${CYAN}•${NC} $item ${YELLOW}($size)${NC}"
    fi
  done
  return 0
}

# 함수: 항목 삭제
delete_items() {
  local items="$1"
  local deleted=0
  local failed=0

  echo "$items" | while read -r item; do
    if [ -n "$item" ] && [ -e "$item" ]; then
      rm -rf "$item" 2>/dev/null
      if [ $? -eq 0 ]; then
        echo -e "    ${GREEN}✓${NC} 삭제됨: $item"
      else
        echo -e "    ${RED}✗${NC} 실패: $item"
      fi
    fi
  done
}

# 메인 로직
print_header

echo -e "\n${YELLOW}검색 중...${NC}\n"

# 모든 항목 수집
ALL_FOLDERS=""
ALL_FILES=""

# 폴더 이름으로 검색
echo -e "${CYAN}폴더 검색 중...${NC}"
for name in "${FOLDER_NAMES[@]}"; do
  found=$(find_folders_by_name "$name")
  if [ -n "$found" ]; then
    ALL_FOLDERS="$ALL_FOLDERS$found"$'\n'
  fi
done

# 경로 패턴으로 검색
for pattern in "${PATH_PATTERNS[@]}"; do
  found=$(find_folders_by_path "$pattern")
  if [ -n "$found" ]; then
    ALL_FOLDERS="$ALL_FOLDERS$found"$'\n'
  fi
done

# 파일 패턴으로 검색
echo -e "${CYAN}파일 검색 중...${NC}"
for pattern in "${FILE_PATTERNS[@]}"; do
  found=$(find_files_by_pattern "$pattern")
  if [ -n "$found" ]; then
    ALL_FILES="$ALL_FILES$found"$'\n'
  fi
done

# 빈 줄 제거 및 중복 제거
ALL_FOLDERS=$(echo "$ALL_FOLDERS" | sed '/^$/d' | sort -u)
ALL_FILES=$(echo "$ALL_FILES" | sed '/^$/d' | sort -u)

# 결과 출력
print_separator
echo -e "\n${GREEN}검색 결과:${NC}"

FOLDER_COUNT=0
FILE_COUNT=0

if [ -n "$ALL_FOLDERS" ]; then
  FOLDER_COUNT=$(echo "$ALL_FOLDERS" | wc -l | tr -d ' ')
fi

if [ -n "$ALL_FILES" ]; then
  FILE_COUNT=$(echo "$ALL_FILES" | wc -l | tr -d ' ')
fi

TOTAL_COUNT=$((FOLDER_COUNT + FILE_COUNT))

if [ "$TOTAL_COUNT" -eq 0 ]; then
  echo -e "\n${YELLOW}삭제할 항목을 찾지 못했습니다.${NC}"
  exit 0
fi

# 폴더 결과 표시
if [ -n "$ALL_FOLDERS" ]; then
  echo -e "\n${GREEN}[폴더]${NC} - $FOLDER_COUNT 개 발견"
  echo "$ALL_FOLDERS" | while read -r item; do
    if [ -n "$item" ]; then
      size=$(get_size "$item")
      echo -e "  ${CYAN}•${NC} $item ${YELLOW}($size)${NC}"
    fi
  done
fi

# 파일 결과 표시
if [ -n "$ALL_FILES" ]; then
  echo -e "\n${GREEN}[파일]${NC} - $FILE_COUNT 개 발견"
  echo "$ALL_FILES" | head -20 | while read -r item; do
    if [ -n "$item" ]; then
      size=$(get_size "$item")
      echo -e "  ${CYAN}•${NC} $item ${YELLOW}($size)${NC}"
    fi
  done
  if [ "$FILE_COUNT" -gt 20 ]; then
    echo -e "  ${YELLOW}... 그 외 $((FILE_COUNT - 20))개 파일${NC}"
  fi
fi

print_separator

echo -e "\n${GREEN}총 $TOTAL_COUNT 개 항목 발견${NC} (폴더: $FOLDER_COUNT, 파일: $FILE_COUNT)"

# 삭제 메뉴
echo -e "\n${YELLOW}삭제 옵션을 선택하세요:${NC}"
echo "  1) 모든 항목 삭제"
echo "  2) 폴더만 삭제"
echo "  3) 파일만 삭제 (*.log, .DS_Store 등)"
echo "  4) 취소"
echo ""
read -p "선택 (1-4): " CHOICE

case $CHOICE in
  1)
    echo -e "\n${YELLOW}모든 항목을 삭제합니다...${NC}\n"
    if [ -n "$ALL_FOLDERS" ]; then
      echo -e "${CYAN}폴더 삭제 중...${NC}"
      echo "$ALL_FOLDERS" | while read -r item; do
        if [ -n "$item" ] && [ -e "$item" ]; then
          rm -rf "$item" 2>/dev/null
          if [ $? -eq 0 ]; then
            echo -e "  ${GREEN}✓${NC} $item"
          else
            echo -e "  ${RED}✗${NC} $item (권한 오류)"
          fi
        fi
      done
    fi
    if [ -n "$ALL_FILES" ]; then
      echo -e "\n${CYAN}파일 삭제 중...${NC}"
      echo "$ALL_FILES" | while read -r item; do
        if [ -n "$item" ] && [ -e "$item" ]; then
          rm -f "$item" 2>/dev/null
          if [ $? -eq 0 ]; then
            echo -e "  ${GREEN}✓${NC} $item"
          else
            echo -e "  ${RED}✗${NC} $item (권한 오류)"
          fi
        fi
      done
    fi
    ;;
  2)
    if [ -n "$ALL_FOLDERS" ]; then
      echo -e "\n${YELLOW}폴더를 삭제합니다...${NC}\n"
      echo "$ALL_FOLDERS" | while read -r item; do
        if [ -n "$item" ] && [ -e "$item" ]; then
          rm -rf "$item" 2>/dev/null
          if [ $? -eq 0 ]; then
            echo -e "  ${GREEN}✓${NC} $item"
          else
            echo -e "  ${RED}✗${NC} $item (권한 오류)"
          fi
        fi
      done
    else
      echo -e "${YELLOW}삭제할 폴더가 없습니다.${NC}"
    fi
    ;;
  3)
    if [ -n "$ALL_FILES" ]; then
      echo -e "\n${YELLOW}파일을 삭제합니다...${NC}\n"
      echo "$ALL_FILES" | while read -r item; do
        if [ -n "$item" ] && [ -e "$item" ]; then
          rm -f "$item" 2>/dev/null
          if [ $? -eq 0 ]; then
            echo -e "  ${GREEN}✓${NC} $item"
          else
            echo -e "  ${RED}✗${NC} $item (권한 오류)"
          fi
        fi
      done
    else
      echo -e "${YELLOW}삭제할 파일이 없습니다.${NC}"
    fi
    ;;
  4|*)
    echo -e "\n${YELLOW}작업을 취소했습니다.${NC}"
    exit 0
    ;;
esac

echo -e "\n${GREEN}정리 완료!${NC}\n"
