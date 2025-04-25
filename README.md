# shell-utils

쉘 스크립트 유틸리티 모음으로 개발 환경 관리와 시스템 유지보수를 도와줍니다.

## 디렉토리 구조

```
shell-utils/
├── scripts/
│   ├── git/         # Git 관련 스크립트
│   ├── cleanup/     # 정리 및 공간 확보 스크립트
│   └── backup/      # 백업 관련 스크립트
└── docs/            # 문서 파일
```

## 스크립트 목록

### Git 관련

- [pull_all.sh](scripts/git/pull_all.sh) - 여러 Git 저장소를 일괄 업데이트 ([문서](docs/pull_all.md))

### 디스크 공간 관리

- [delete-node-modules.sh](scripts/cleanup/delete-node-modules.sh) - Node.js 프로젝트의 node_modules 폴더 정리 ([문서](docs/delete-node-modules.md))
- [delete-tmp-cache.sh](scripts/cleanup/delete-tmp-cache.sh) - 임시 캐시 디렉토리 정리 ([문서](docs/delete-tmp-cache.md))
- [delete-vendor-bundle.sh](scripts/cleanup/delete-vendor-bundle.sh) - Ruby 프로젝트의 vendor/bundle 디렉토리 정리 ([문서](docs/delete-vendor-bundle.md))

### 백업

- [rsync-backup.sh](scripts/backup/rsync-backup.sh) - rsync를 이용한 고급 백업 스크립트 ([문서](docs/rsync-backup.md))

## 설치 및 사용

1. 이 저장소 클론

   ```bash
   git clone https://github.com/yourusername/shell-utils.git
   cd shell-utils
   ```

2. 사용할 스크립트에 실행 권한 부여

   ```bash
   chmod +x scripts/category/script-name.sh
   ```

3. 스크립트 실행
   ```bash
   ./scripts/category/script-name.sh
   ```

## 주의사항

- 각 스크립트는 실행 전 내용을 검토하고 필요에 따라 설정을 조정하세요.
- 백업 스크립트 사용 시 대상 경로를 신중하게 확인하세요.
- 삭제 작업은 되돌릴 수 없으므로 주의하세요.

## 라이선스

MIT
