"""서울 월별 평균기온(평년값) 꺾은선 그래프를 seoul_temp.png로 저장한다."""

from pathlib import Path

import matplotlib

matplotlib.use("Agg")

import matplotlib.pyplot as plt
from matplotlib import font_manager

# 기상청 1991~2020년 평년값(서울, 월평균기온, °C)을 소수점 한 자리로 반올림한 근사치
MONTHS = [f"{m}월" for m in range(1, 13)]
TEMPS = [-1.9, 0.7, 6.1, 12.6, 18.2, 22.7, 25.3, 26.1, 21.6, 15.0, 7.5, 0.2]

OUTPUT = Path(__file__).with_name("seoul_temp.png")

# 색상 토큰 (light surface 기준)
SURFACE = "#fcfcfb"
SERIES = "#2a78d6"
INK_PRIMARY = "#0b0b0b"
INK_SECONDARY = "#52514e"
INK_MUTED = "#898781"
GRID = "#e1e0d9"
AXIS = "#c3c2b7"

KOREAN_FONT_CANDIDATES = (
    "Malgun Gothic",  # Windows
    "Apple SD Gothic Neo",  # macOS
    "NanumGothic",  # Linux (fonts-nanum)
    "Noto Sans CJK KR",
    "Noto Sans KR",
)


def configure_korean_font() -> str | None:
    """설치된 한글 폰트 중 첫 번째를 matplotlib 기본 폰트로 지정한다."""
    installed = {f.name for f in font_manager.fontManager.ttflist}
    for name in KOREAN_FONT_CANDIDATES:
        if name in installed:
            plt.rcParams["font.family"] = name
            plt.rcParams["axes.unicode_minus"] = False  # 한글 폰트에서 '−' 깨짐 방지
            return name
    return None


def draw() -> None:
    fig, ax = plt.subplots(figsize=(9, 5), dpi=150)
    fig.set_facecolor(SURFACE)
    ax.set_facecolor(SURFACE)

    ax.plot(
        MONTHS,
        TEMPS,
        color=SERIES,
        linewidth=2,
        solid_joinstyle="round",
        solid_capstyle="round",
        marker="o",
        markersize=8,
        markerfacecolor=SERIES,
        markeredgecolor=SURFACE,
        markeredgewidth=2,
        zorder=3,
    )

    # 극값(최고/최저)만 직접 라벨링
    for idx, offset in ((TEMPS.index(max(TEMPS)), 10), (TEMPS.index(min(TEMPS)), -16)):
        ax.annotate(
            f"{TEMPS[idx]:.1f}°C",
            (idx, TEMPS[idx]),
            textcoords="offset points",
            xytext=(0, offset),
            ha="center",
            fontsize=10,
            color=INK_SECONDARY,
        )

    ax.set_title("서울 월별 평균기온", loc="left", fontsize=15, color=INK_PRIMARY, pad=24)
    ax.text(
        0, 1.03, "1991~2020년 평년값 기준 (°C)", transform=ax.transAxes,
        fontsize=10, color=INK_SECONDARY,
    )

    ax.yaxis.grid(True, color=GRID, linewidth=1)
    ax.set_axisbelow(True)
    for side in ("top", "right"):
        ax.spines[side].set_visible(False)
    for side in ("left", "bottom"):
        ax.spines[side].set_color(AXIS)
        ax.spines[side].set_linewidth(1)
    ax.axhline(0, color=AXIS, linewidth=1, zorder=1)

    ax.tick_params(colors=INK_MUTED, labelsize=10, length=0)
    ax.set_ylabel("평균기온 (°C)", color=INK_MUTED, fontsize=10)
    ax.set_ylim(-5, 30)
    ax.set_yticks(range(-5, 31, 5))
    ax.margins(x=0.03)

    fig.tight_layout()
    fig.savefig(OUTPUT, facecolor=SURFACE)
    plt.close(fig)


def main() -> None:
    font = configure_korean_font()
    if font is None:
        print("경고: 한글 폰트를 찾지 못해 한글이 깨질 수 있습니다. "
              f"후보 폰트: {', '.join(KOREAN_FONT_CANDIDATES)}")
    else:
        print(f"폰트: {font}")
    draw()
    print(f"저장 완료: {OUTPUT}")


if __name__ == "__main__":
    main()
