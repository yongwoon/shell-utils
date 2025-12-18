#!/bin/bash

# macOS Network Loopback Alias Setup Script
# Docker 또는 로컬 개발 환경을 위한 루프백 IP 별칭 생성
# #############################################
# # 실행 권한 부여
# chmod +x loopback_setup.sh
#
# # sudo로 실행 (root 권한 필요)
# sudo ./loopback_setup.sh
# #############################################
set -eu

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 권한 체크
check_permission() {
    if [ "$EUID" -ne 0 ]; then 
        echo -e "${RED}이 스크립트는 root 권한이 필요합니다.${NC}"
        echo "sudo 로 실행해주세요: sudo $0"
        exit 1
    fi
}

# 루프백 별칭 추가
add_loopback_aliases() {
    echo -e "${GREEN}=== 루프백 IP 별칭 추가 시작 ===${NC}"
    
    local count=0
    
    # 127.0.0.0 ~ 127.0.9.9 범위의 IP 추가
    for i in $(seq 0 9); do
        for j in $(seq 0 9); do
            local ip="127.0.${i}.${j}"
            
            # 127.0.0.1은 이미 존재하므로 스킵
            if [ "$ip" != "127.0.0.1" ]; then
                ifconfig lo0 alias "$ip" 2>/dev/null
                if [ $? -eq 0 ]; then
                    ((count++))
                    echo -e "${GREEN}✓${NC} 추가됨: $ip"
                else
                    echo -e "${RED}✗${NC} 실패: $ip"
                fi
            fi
        done
    done
    
    echo -e "\n${GREEN}총 ${count}개의 IP 별칭이 추가되었습니다.${NC}"
}

# 루프백 별칭 제거
remove_loopback_aliases() {
    echo -e "${YELLOW}=== 루프백 IP 별칭 제거 시작 ===${NC}"
    
    local count=0
    
    for i in $(seq 0 9); do
        for j in $(seq 0 9); do
            local ip="127.0.${i}.${j}"
            
            # 127.0.0.1은 기본 IP이므로 제거하지 않음
            if [ "$ip" != "127.0.0.1" ]; then
                ifconfig lo0 -alias "$ip" 2>/dev/null
                if [ $? -eq 0 ]; then
                    ((count++))
                    echo -e "${YELLOW}✓${NC} 제거됨: $ip"
                fi
            fi
        done
    done
    
    echo -e "\n${YELLOW}총 ${count}개의 IP 별칭이 제거되었습니다.${NC}"
}

# 현재 설정된 루프백 별칭 확인
list_loopback_aliases() {
    echo -e "${GREEN}=== 현재 설정된 루프백 IP 별칭 ===${NC}"
    ifconfig lo0 | grep "inet " | grep "127.0" | awk '{print $2}'
}

# 커스텀 범위 설정
custom_range_aliases() {
    echo -e "${GREEN}=== 커스텀 범위 IP 별칭 추가 ===${NC}"
    
    read -p "시작 IP (예: 127.0.1.0): " start_ip
    read -p "끝 IP (예: 127.0.1.255): " end_ip
    
    # IP를 배열로 변환
    IFS='.' read -ra START <<< "$start_ip"
    IFS='.' read -ra END <<< "$end_ip"
    
    local count=0
    
    for ((a=${START[2]}; a<=${END[2]}; a++)); do
        for ((b=${START[3]}; b<=${END[3]}; b++)); do
            local ip="127.0.${a}.${b}"
            
            if [ "$ip" != "127.0.0.1" ]; then
                ifconfig lo0 alias "$ip" 2>/dev/null
                if [ $? -eq 0 ]; then
                    ((count++))
                    echo -e "${GREEN}✓${NC} 추가됨: $ip"
                fi
            fi
        done
    done
    
    echo -e "\n${GREEN}총 ${count}개의 IP 별칭이 추가되었습니다.${NC}"
}

# 메뉴 표시
show_menu() {
    echo ""
    echo -e "${GREEN}=== macOS 루프백 IP 별칭 관리 ===${NC}"
    echo "1. 기본 범위 IP 별칭 추가 (127.0.0.0 ~ 127.0.9.9)"
    echo "2. 커스텀 범위 IP 별칭 추가"
    echo "3. 현재 설정된 별칭 목록 보기"
    echo "4. 모든 별칭 제거"
    echo "5. 종료"
    echo ""
}

# 메인 함수
main() {
    check_permission
    
    while true; do
        show_menu
        read -p "선택 (1-5): " choice
        
        case $choice in
            1)
                add_loopback_aliases
                ;;
            2)
                custom_range_aliases
                ;;
            3)
                list_loopback_aliases
                ;;
            4)
                read -p "정말로 모든 별칭을 제거하시겠습니까? (y/n): " confirm
                if [[ $confirm == "y" || $confirm == "Y" ]]; then
                    remove_loopback_aliases
                fi
                ;;
            5)
                echo -e "${GREEN}종료합니다.${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}잘못된 선택입니다.${NC}"
                ;;
        esac
        
        echo ""
        read -p "Enter 키를 눌러 계속..."
    done
}

# 스크립트가 직접 실행될 때만 main 실행
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main
fi
