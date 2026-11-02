#!/bin/bash
# Jetson Orin Nano 제어기가 리커버리 모드로 연결되었는지 확인합니다.
#   ./check_recovery.sh        한 번 확인
#   ./check_recovery.sh -w     리커버리 모드가 확인될 때까지 2초마다 다시 확인
# 종료 코드: 0 = Orin Nano 8GB 리커버리 모드, 1 = 그 외

check() {
    local ids
    ids=$(lsusb | grep -oE "ID 0955:[0-9a-f]{4}" | cut -d: -f2)

    if [ -z "$ids" ]; then
        echo "[없음] NVIDIA 장치가 보이지 않습니다. 케이블, 전원, FC REC-GND 점퍼를 확인하세요."
        return 1
    fi
    if [ "$(echo "$ids" | wc -l)" -gt 1 ]; then
        echo "[주의] NVIDIA 장치가 여러 대 연결되어 있습니다. 한 대만 연결하세요."
        lsusb | grep "ID 0955:"
        return 1
    fi

    case "$ids" in
        7523) echo "[정상] 리커버리 모드: Jetson Orin Nano 8GB (0955:7523). 복원을 진행하세요."; return 0 ;;
        7623) echo "[주의] 리커버리 모드: Jetson Orin Nano 4GB (0955:7623). 이 이미지 대상 모듈이 아닙니다." ;;
        7323|7423) echo "[주의] 리커버리 모드: Jetson Orin NX (0955:$ids). 이 이미지 대상 모듈이 아닙니다." ;;
        7035|7020|7045) echo "[아님] 제어기가 일반 부팅 상태입니다 (0955:$ids). FC REC-GND를 연결한 채 전원을 다시 넣으세요." ;;
        *) echo "[확인 필요] 알 수 없는 NVIDIA 장치입니다 (0955:$ids)." ;;
    esac
    return 1
}

if [ "$1" = "-w" ]; then
    until check; do sleep 2; echo "---"; done
else
    check
fi
