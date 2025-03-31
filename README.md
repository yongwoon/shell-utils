# shell-utils

## pull_all.sh

### 동작 순서

```bash
process_git_repository() {
    1. Git 저장소 확인
    2. 작업 중인 변경사항 stash
    3. 원격 저장소 정보 최신화 (fetch)
    4. 삭제된 원격 브랜치 정리 (prune)
    5. 각 브랜치(main, master, develop) 처리:
       - 브랜치 존재 확인
       - checkout
       - 원격 브랜치로 강제 초기화(reset --hard)
    6. stash 했던 변경사항 복원
    7. 저장소 정리(git gc)
}
```

### 스크립트 실행 범위

1. 현재 디렉토리
2. 1단계 하위 디렉토리
3. 2단계 하위 디렉토리

### Process

```bash
project/
├── repo1/         # 처리
│   └── subrepo1/  # 처리
├── repo2/         # 처리
│   └── subrepo2/  # 처리
└── repo3/         # 처리
```
