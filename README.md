# WeGo LIMO Pro — Orin Nano 이미지 복원

LIMO Pro의 Jetson Orin Nano 제어기를 출고 상태 이미지로 되돌리는 방법입니다.
NVIDIA 공식 백업·복원 도구(`l4t_backup_restore.sh`)를 사용해 NVMe와 QSPI 부트로더를 한 번에 복원합니다.

> **주의:** 복원하면 제어기의 NVMe와 QSPI가 **모두 이 이미지로 덮어써집니다.**
> 제어기에 필요한 데이터가 있다면 먼저 다른 곳에 옮겨 두세요.

> **소프트웨어 기준일:** 이 이미지는 **2026년 11월 2일 기준** 소프트웨어 상태를 보장합니다.
> 이후에 나온 소프트웨어 업데이트는 포함되어 있지 않으므로, 복원한 뒤 별도로 반영해야 합니다.

## 이미지 정보

| 항목 | 값 |
|---|---|
| 이미지 파일 | `WeGo_LimoPro_OrinNano_20261008.tar` (26 GB) |
| 다운로드 | [Google Drive](https://drive.google.com/file/d/1hRFOESqsSLWrAem05-u29LQXz0JkeL5_/view?usp=drive_link) |
| SHA256 | `8da4e5d60e25548c595138c8a7ea86239dd05433e669fbb7a47e1c75d1de9ed1` |
| 대상 모듈 | Jetson Orin Nano 8GB (P3767-0003) |
| 로봇 OS | Jetson Linux R36.4.7 (JetPack 6) |
| 저장 장치 | NVMe (`nvme0n1`) |
| 보드 설정 이름 | `jetson-orin-nano-devkit-super` |
| 복원 도구 | NVIDIA Jetson Linux R36.4.4 BSP |

## 준비물

- **호스트 PC:** x86_64 Ubuntu 22.04
- **디스크 여유 공간:** 80 GB 이상 (이미지 26 GB + 압축 해제 26 GB + BSP)
- **USB-C 데이터 케이블:** 충전 전용 케이블은 사용할 수 없습니다.
- **인터넷 연결:** BSP와 이미지 다운로드용

## 전체 순서

```
1. 저장소 받기  →  2. BSP 준비  →  3. 이미지 다운로드·검증  →  4. 이미지 배치
→  5. 리커버리 모드 연결  →  6. 복원 실행  →  7. 재부팅
```

전체 약 1~2시간 걸리며, 대부분은 다운로드 시간입니다. 복원 자체는 30~40분 정도 걸립니다.

---

## 1. 저장소 받기

```bash
cd ~
git clone https://github.com/WeGo-Robotics/limo-pro-orin-nano-restore.git WeGo_LimoPro_OrinNano_Restore
```

## 2. NVIDIA BSP 준비

복원 도구가 들어 있는 NVIDIA Jetson Linux **R36.4.4** BSP를 준비합니다.
처음 한 번만 하면 됩니다.

```bash
mkdir -p ~/jetson && cd ~/jetson

# BSP와 샘플 루트 파일시스템 다운로드
wget https://developer.nvidia.com/downloads/embedded/l4t/r36_release_v4.4/release/Jetson_Linux_r36.4.4_aarch64.tbz2
wget https://developer.nvidia.com/downloads/embedded/l4t/r36_release_v4.4/release/Tegra_Linux_Sample-Root-Filesystem_r36.4.4_aarch64.tbz2

# 압축 해제
tar xf Jetson_Linux_r36.4.4_aarch64.tbz2
sudo tar xpf Tegra_Linux_Sample-Root-Filesystem_r36.4.4_aarch64.tbz2 -C Linux_for_Tegra/rootfs/

# 의존 패키지 설치 및 바이너리 적용
cd Linux_for_Tegra
sudo ./tools/l4t_flash_prerequisites.sh
sudo ./apply_binaries.sh
```

다운로드 주소가 바뀌었다면 [Jetson Linux R36.4.4 페이지](https://developer.nvidia.com/embedded/jetson-linux-r3644)에서
**Driver Package (BSP)** 와 **Sample Root Filesystem** 을 받으세요.

## 3. 이미지 다운로드 및 검증

### 다운로드

1. [Google Drive 링크](https://drive.google.com/file/d/1hRFOESqsSLWrAem05-u29LQXz0JkeL5_/view?usp=drive_link)를 엽니다.
2. **다운로드**를 누릅니다.
3. 파일이 커서 바이러스 검사를 할 수 없다는 안내가 나오면 **무시하고 다운로드**를 누릅니다. 이 안내가 나오는 것은 정상입니다.
4. 받은 파일을 `~/WeGo_LimoPro_OrinNano_Restore/` 폴더로 옮깁니다.

   ```bash
   mv ~/Downloads/WeGo_LimoPro_OrinNano_20261008.tar ~/WeGo_LimoPro_OrinNano_Restore/
   ```

### 검증

```bash
cd ~/WeGo_LimoPro_OrinNano_Restore
sha256sum -c SHA256SUMS
```

`WeGo_LimoPro_OrinNano_20261008.tar: OK`가 나와야 합니다.
`FAILED`가 나오면 파일이 손상된 것이므로 다시 받으세요.

## 4. 이미지 배치

이미지를 BSP의 복원 폴더(`tools/backup_restore/images`)에 풉니다.

```bash
cd ~/jetson/Linux_for_Tegra
sudo mkdir -p tools/backup_restore/images
sudo tar xf ~/WeGo_LimoPro_OrinNano_Restore/WeGo_LimoPro_OrinNano_20261008.tar -C tools/backup_restore/images/
ls tools/backup_restore/images/
```

다음 파일들이 `images` 폴더 **바로 아래**에 있어야 합니다.

```
nvpartitionmap.txt   nvme0n1p1.tar.zst   QSPI0.img
nvme0n1_gptmbr.img   nvme0n1_gptbackup.img   nvme0n1p2_bak.img ... nvme0n1p15_bak.img
```

> `images` 폴더에 이미 다른 이미지가 있다면 먼저 다른 곳으로 옮기세요.
> 압축 해제가 끝나면 원본 `.tar`는 지워도 됩니다.

## 5. 제어기를 리커버리 모드로 연결

### 리커버리 모드 진입

[LIMO PRO 소프트웨어 업데이트 가이드](https://goofy-pleasure-a84.notion.site/2ce09b2ac4bf8044b9bcf9b339c7ce5a)의
**STEP.2 JetPack 업그레이드**를 **4번까지** 진행해 리커버리 모드로 진입합니다.

1. NVIDIA SDK Manager를 설치합니다.
2. SDK Manager를 실행합니다.
3. 점퍼 케이블로 상위 제어기 핀의 **FC REC**와 **GND**를 연결합니다.
4. C to USB 케이블로 상위 제어기와 노트북을 연결하고 전원을 넣어 **Recovery 모드**로 진입합니다.

> 제어기를 LIMO에서 분리해야 핀에 접근할 수 있다면, 같은 가이드의 **STEP.1 상위 제어기 분리**를 먼저 진행하세요.
> 이 저장소의 복원은 SDK Manager 대신 6단계의 복원 명령을 사용합니다.
> 그래서 가이드 4번 이후의 SDK Manager 단계(장치 선택, Jetson Linux 설치)는 **진행하지 않습니다.**

### 리커버리 모드 확인

이 저장소에 들어 있는 확인 스크립트를 실행합니다.

```bash
cd ~/WeGo_LimoPro_OrinNano_Restore
./check_recovery.sh        # 한 번 확인
./check_recovery.sh -w     # 리커버리 모드가 확인될 때까지 2초마다 다시 확인
```

| 출력 | 의미 |
|---|---|
| `[정상] 리커버리 모드: Jetson Orin Nano 8GB (0955:7523)` | 복원을 진행하면 됩니다. |
| `[없음] NVIDIA 장치가 보이지 않습니다` | 케이블, 전원, FC REC-GND 점퍼를 확인합니다. |
| `[아님] 제어기가 일반 부팅 상태입니다` | 점퍼가 연결되지 않은 채 부팅된 상태입니다. 점퍼를 연결하고 전원을 다시 넣습니다. |
| `[주의] ... 이 이미지 대상 모듈이 아닙니다` | Orin Nano 8GB가 아닙니다. **진행하지 마세요.** |
| `[주의] NVIDIA 장치가 여러 대 연결되어 있습니다` | 제어기 한 대만 연결합니다. |

스크립트 없이 직접 확인하려면 다음 명령을 실행합니다.

```bash
lsusb | grep -i nvidia
```

`0955:7523 ... APX`가 보이면 리커버리 모드입니다.

```
Bus 001 Device 010: ID 0955:7523 NVIDIA Corp. APX
```

## 6. 복원 실행

```bash
cd ~/jetson/Linux_for_Tegra
sudo ./tools/backup_restore/l4t_backup_restore.sh -e nvme0n1 -r jetson-orin-nano-devkit-super
```

- `-r`은 복원 모드입니다. `-b`(백업 모드)와 헷갈리지 마세요.
- 보드 설정 이름은 반드시 `jetson-orin-nano-devkit-super`를 사용하세요.
- 진행 중에는 **USB 케이블과 전원을 절대 빼지 마세요.**

### 진행 단계

| 단계 | 터미널 메시지 | `lsusb` 상태 |
|---|---|---|
| 1. 복원용 임시 시스템 생성 | `Step 1: Generate flash package` | `0955:7523 APX` |
| 2. 임시 시스템 전송 | `Step 2: Boot the device with flash initrd image` | `0955:7523 APX` |
| 3. 임시 시스템 부팅 | `Step 3: Start the flashing process` | 잠시 사라짐 → `0955:7035 Linux for Tegra` |
| 4. NVMe·QSPI에 이미지 쓰기 | `Device has booted into initrd`, `Cleaning up...` | `0955:7035 Linux for Tegra` |
| 5. 체크섬 검증 후 종료 | 복원 완료 메시지 | `0955:7035` 유지 |

- 3단계에서 USB 장치가 잠깐 사라지는 것은 정상입니다.
- 4단계의 `Cleaning up...`은 오류가 아닙니다.
- 단계별 상세 로그는 `Linux_for_Tegra/initrdlog/flash_*.log`에 남습니다.

## 7. 재부팅

스크립트가 끝나도 제어기는 **자동으로 재부팅되지 않습니다.**

1. FC REC-GND 점퍼 케이블을 뺍니다.
2. 제어기 전원을 껐다 켜거나 리셋 버튼을 누릅니다.
3. NVMe로 부팅되면 LIMO Pro 기본 환경(사용자 `wego`)으로 시작됩니다.

---

## (선택) 재부팅 전 복원 결과 확인

복원 스크립트가 끝난 직후, 재부팅하기 전에 호스트 PC에서 확인할 수 있습니다.

```bash
S="sshpass -p root ssh -q -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null root@fc00:1:1::2"

# 파티션 15개, p1 약 117.8G
$S 'lsblk /dev/nvme0n1'

# 루트 파일시스템 확인
$S 'd=$(mktemp -d); mount -o ro /dev/nvme0n1p1 $d && { head -1 $d/etc/nv_tegra_release; ls $d/home; df -h $d | tail -1; umount $d; }'
```

정상이라면 다음과 비슷하게 나옵니다.

```
# R36 (release), REVISION: 4.7, ...
wego
/dev/nvme0n1p1  116G   51G   60G  46% ...
```

제어기 로그에 `NFS: state manager: check lease failed`가 반복될 수 있습니다.
복원이 끝나 호스트 PC의 NFS 공유가 닫혀서 생기는 메시지이며, 복원 결과에는 영향이 없습니다.

## 문제 해결

| 증상 | 해결 방법 |
|---|---|
| 구글 드라이브에서 다운로드 한도 초과 안내가 나옴 | 하루 다운로드 한도를 넘은 경우입니다. 몇 시간 뒤 다시 시도하세요 |
| `sha256sum -c`에서 `FAILED` | 다운로드가 손상됨 → 다시 받기 |
| `check_recovery.sh`가 `[정상]`을 출력하지 않음 | FC REC-GND 점퍼를 확인하고 전원을 다시 넣기, 데이터 전송용 USB-C 케이블인지 확인 |
| 복원 중 체크섬 불일치 오류 | `images` 폴더 파일이 손상됨 → 4단계부터 다시 진행 |
| `Waiting for target to boot-up...`이 계속 반복됨 | USB 포트나 케이블을 바꾸고, 가상머신이 아닌 실제 PC에서 처음부터 다시 시도 |
| SSH 접속 실패 (`fc00:1:1::2`) | `sudo ./tools/l4t_flash_prerequisites.sh`를 다시 실행하고 방화벽 확인 |
| 재부팅 후 다시 리커버리 모드로 들어감 | FC REC-GND 점퍼 케이블을 뺐는지 확인 |

## 참고

- LIMO PRO 소프트웨어 업데이트 가이드: https://goofy-pleasure-a84.notion.site/2ce09b2ac4bf8044b9bcf9b339c7ce5a
- NVIDIA 공식 설명서: `Linux_for_Tegra/tools/backup_restore/README_backup_restore.txt`
- Jetson Linux R36.4.4: https://developer.nvidia.com/embedded/jetson-linux-r3644
