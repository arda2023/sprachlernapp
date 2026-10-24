"""Generates scene.rml for the onboarding animations (Rive CLI project).

Three artboards, each with an "Intro" (plays once) that hands over to a
looping "Idle" through its state machine:

  Logo     the Lingvist mark: an orange speech bubble whose white "L" draws
           itself in, with a bouncing accent dot.
  Welcome  an open book; word bubbles rise out of it and float, sparkles
           twinkle around them.
  Goal     a daily-goal ring that fills to 80 % around a flickering flame.

Build (macOS / Linux / Windows, from the repository root):

  python3 tool/rive/onboarding/build_scene.py
  rive tool/rive/onboarding --once
  rive inspect tool/rive/onboarding --summary

rive.yaml writes the .riv to assets/rive/onboarding.riv. Colours follow
lib/theme/app_theme.dart; the artboards are transparent so they sit on both
the light and the dark page.
"""

from pathlib import Path

ORANGE = "FFF77F00"
DEEP_ORANGE = "FFE26C00"
WHITE = "FFFFFFFF"
CREAM = "FFFFF4E6"
PAGE_LINE = "FFE9D8C2"
BLUE = "FF5AA2FF"
GREEN = "FF34C77B"
VIOLET = "FFA77BFF"
YELLOW = "FFFFC94D"
RING_TRACK = "33F77F00"

EASE_OUT = (0.22, 1.0, 0.36, 1.0)
EASE_IN_OUT = (0.45, 0.0, 0.55, 1.0)
BACK_OUT = (0.34, 1.56, 0.64, 1.0)

X, Y, ROTATION, SCALE_X, SCALE_Y, OPACITY = 13, 14, 15, 16, 17, 18
TRIM_END = 115


class Ids:
    def __init__(self):
        self.n = 1

    def __call__(self):
        self.n += 1
        return f"0:{self.n}"


ids = Ids()


def fill(color):
    return f'<Fill name="Fill"><SolidColor colorValue="{color}" name="C"/></Fill>'


def stroke(color, thickness, trim_id=None, trim_end=1.0):
    trim = (
        f'<TrimPath start="0" end="{trim_end}" name="Trim" id="{trim_id}"/>'
        if trim_id
        else ""
    )
    return (
        f'<Stroke thickness="{thickness}" cap="round" join="round" name="Stroke">'
        f'<SolidColor colorValue="{color}" name="C"/>{trim}</Stroke>'
    )


def rect(w, h, r):
    return f'<Rectangle width="{w}" height="{h}" cornerRadiusTL="{r}" name="Path"/>'


def ellipse(w, h):
    return f'<Ellipse width="{w}" height="{h}" name="Path"/>'


def points(vertices, closed=True):
    body = "".join(vertices)
    return f'<PointsPath isClosed="{str(closed).lower()}" name="Path">{body}</PointsPath>'


def v(x, y, radius=0):
    r = f' radius="{radius}"' if radius else ""
    return f'<StraightVertex x="{x}" y="{y}"{r}/>'


def cv(x, y, rotation, distance):
    return (
        f'<CubicMirroredVertex x="{x}" y="{y}" rotation="{rotation}" '
        f'distance="{distance}"/>'
    )


def shape(name, x, y, *children, id=None, opacity=None):
    i = f' id="{id}"' if id else ""
    o = f' opacity="{opacity}"' if opacity is not None else ""
    return f'<Shape x="{x}" y="{y}" name="{name}"{i}{o}>{"".join(children)}</Shape>'


def node(name, x, y, *children, id, scale=None, opacity=None):
    s = f' scaleX="{scale}" scaleY="{scale}"' if scale is not None else ""
    o = f' opacity="{opacity}"' if opacity is not None else ""
    return f'<Node x="{x}" y="{y}" name="{name}" id="{id}"{s}{o}>{"".join(children)}</Node>'


def keyframes(frames):
    """frames: [(frame, value, ease)] where ease is None (linear), 'hold' or
    a cubic tuple. The ease on a keyframe shapes the segment after it."""
    out = []
    for frame, value, ease in frames:
        if ease == "hold":
            out.append(
                f'<KeyFrameDouble value="{value}" frame="{frame}" interpolationType="hold"/>'
            )
        elif ease is None:
            out.append(
                f'<KeyFrameDouble value="{value}" frame="{frame}" interpolationType="linear"/>'
            )
        else:
            x1, y1, x2, y2 = ease
            out.append(
                f'<KeyFrameDouble value="{value}" frame="{frame}" interpolationType="cubic">'
                f'<CubicEaseInterpolator x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}"/>'
                f"</KeyFrameDouble>"
            )
    return "".join(out)


def keyed(object_id, props):
    """props: {propertyKey: frames}"""
    body = "".join(
        f'<KeyedProperty propertyKey="{key}">{keyframes(frames)}</KeyedProperty>'
        for key, frames in props.items()
    )
    return f'<KeyedObject objectId="{object_id}">{body}</KeyedObject>'


def animation(name, id, duration, loop, objects):
    return (
        f'<LinearAnimation loopValue="{loop}" duration="{duration}" name="{name}" id="{id}">'
        f'{"".join(objects)}</LinearAnimation>'
    )


def bob(base, amplitude, duration, phase=0):
    """A smooth up-down loop of `duration` frames, shifted by `phase`."""
    half = duration // 2
    a, b = base, base - amplitude
    if phase == 0:
        return [(0, a, EASE_IN_OUT), (half, b, EASE_IN_OUT), (duration, a, None)]
    # Start part-way down the swing so neighbours don't move in lockstep.
    p = phase % duration
    mid = base - amplitude / 2
    if p < half:
        return [
            (0, mid, EASE_IN_OUT),
            (half - p, b, EASE_IN_OUT),
            (duration - p, a, EASE_IN_OUT),
            (duration, mid, None),
        ]
    return [
        (0, mid, EASE_IN_OUT),
        (duration - p, a, EASE_IN_OUT),
        (duration - p + half, b, EASE_IN_OUT),
        (duration, mid, None),
    ]


def state_machine(intro_id, idle_id):
    sm, layer, intro_state, idle_state = ids(), ids(), ids(), ids()
    xml = (
        f'<StateMachine name="Onboarding" id="{sm}">'
        f'<StateMachineLayer name="Layer" id="{layer}">'
        f'<AnyState x="0" y="-150"/><ExitState x="600" y="-150"/>'
        f'<EntryState x="0" y="0"><StateTransition stateToId="{intro_state}"/></EntryState>'
        f'<AnimationState x="200" y="0" animationId="{intro_id}" id="{intro_state}">'
        f'<StateTransition stateToId="{idle_state}" duration="0" '
        f'enableExitTime="true" exitTimeIsPercetange="true" exitTime="100"/>'
        f"</AnimationState>"
        f'<AnimationState x="400" y="0" animationId="{idle_id}" id="{idle_state}"/>'
        f"</StateMachineLayer></StateMachine>"
    )
    return sm, xml


def artboard(name, x, width, height, body, intro, idle):
    style = ids()
    sm, sm_xml = state_machine(intro[0], idle[0])
    return (
        f'<Artboard x="{x}" y="0" defaultStateMachineId="{sm}" styleId="{style}" '
        f'width="{width}" height="{height}" clip="true" name="{name}" id="{ids()}">'
        f'<LayoutComponentStyle name="{name} Style" id="{style}"/>'
        f"{body}{sm_xml}{intro[1]}{idle[1]}</Artboard>"
    )


def sparkle(name, x, y, size, color, id):
    s = size
    q = size * 0.22
    return shape(
        name,
        x,
        y,
        points([v(0, -s), v(q, -q), v(s, 0), v(q, q), v(0, s), v(-q, q), v(-s, 0), v(-q, -q)]),
        fill(color),
        id=id,
    )


# --------------------------------------------------------------------- Logo


def logo():
    mark, letter_trim, dot = ids(), ids(), ids()
    body = node(
        "Mark",
        120,
        120,
        # The first child paints on top: accent dot and letter over the
        # tile, the speech-bubble tail underneath it.
        shape("Dot", 40, -36, ellipse(26, 26), fill(WHITE), id=dot),
        shape(
            "Letter",
            -6,
            2,
            points([v(-26, -46), v(-26, 38, 14), v(38, 38)], closed=False),
            stroke(WHITE, 24, trim_id=letter_trim, trim_end=0),
        ),
        shape("Tile", 0, 0, rect(168, 168, 48), fill(ORANGE)),
        shape("Tail", -46, 70, points([v(-22, -20), v(26, -20), v(-30, 26, 6)]), fill(ORANGE)),
        id=mark,
        scale=0.4,
        opacity=0,
    )
    intro_id, idle_id = ids(), ids()
    intro = animation(
        "Intro",
        intro_id,
        64,
        "oneShot",
        [
            keyed(
                mark,
                {
                    SCALE_X: [(0, 0.4, BACK_OUT), (26, 1, None)],
                    SCALE_Y: [(0, 0.4, BACK_OUT), (26, 1, None)],
                    OPACITY: [(0, 0, EASE_OUT), (12, 1, None)],
                    Y: [(0, 120, "hold")],
                },
            ),
            keyed(letter_trim, {TRIM_END: [(0, 0, "hold"), (14, 0, EASE_OUT), (44, 1, None)]}),
            keyed(
                dot,
                {
                    SCALE_X: [(0, 0, "hold"), (40, 0, BACK_OUT), (56, 1, None)],
                    SCALE_Y: [(0, 0, "hold"), (40, 0, BACK_OUT), (56, 1, None)],
                    Y: [(0, -36, "hold")],
                },
            ),
        ],
    )
    idle = animation(
        "Idle",
        idle_id,
        180,
        "loop",
        [
            keyed(
                mark,
                {
                    Y: bob(120, 5, 180),
                    ROTATION: [(0, 0, EASE_IN_OUT), (90, 0.035, EASE_IN_OUT), (180, 0, None)],
                    SCALE_X: [(0, 1, "hold")],
                    SCALE_Y: [(0, 1, "hold")],
                    OPACITY: [(0, 1, "hold")],
                },
            ),
            keyed(letter_trim, {TRIM_END: [(0, 1, "hold")]}),
            keyed(
                dot,
                {
                    Y: bob(-36, 7, 90),
                    SCALE_X: [(0, 1, "hold")],
                    SCALE_Y: [(0, 1, "hold")],
                },
            ),
        ],
    )
    return artboard("Logo", 0, 240, 240, body, (intro_id, intro), (idle_id, idle))


# ------------------------------------------------------------------ Welcome


def bubble(name, x, y, w, h, color, tail_left, id):
    tail_x = -w / 2 + 22 if tail_left else w / 2 - 22
    lines = [
        shape("Line", -w / 2 + 18 + (w - 50) / 2, -6, rect(w - 50, 7, 3.5), fill("CCFFFFFF")),
        shape("Line", -w / 2 + 18 + (w - 70) / 2, 8, rect(w - 70, 7, 3.5), fill("88FFFFFF")),
    ]
    return node(
        name,
        x,
        y,
        *lines,
        shape("Pill", 0, 0, rect(w, h, h / 2), fill(color)),
        shape(
            "Tail",
            tail_x,
            h / 2 - 2,
            points([v(-9, -6), v(9, -6), v(-4 if tail_left else 4, 12, 3)]),
            fill(color),
        ),
        id=id,
        scale=0,
    )


def welcome():
    book = ids()
    page_lines = []
    for side in (-1, 1):
        for i, width in enumerate((70, 58, 66, 44)):
            cx = side * (22 + width / 2)
            page_lines.append(shape("Text", cx, -14 + i * 15, rect(width, 6, 3), fill(PAGE_LINE)))
    book_xml = node(
        "Book",
        200,
        236,
        *page_lines,
        shape("Spine", 0, 9, rect(4, 82, 2), fill(PAGE_LINE)),
        shape(
            "Left page",
            0,
            0,
            points([v(-118, -40, 10), cv(-58, -50, 0.2, 30), v(0, -32), v(0, 50), cv(-58, 40, 0.15, 30), v(-118, 46, 10)]),
            fill(CREAM),
        ),
        shape(
            "Right page",
            0,
            0,
            points([v(0, -32), cv(58, -50, -0.2, 30), v(118, -40, 10), v(118, 46, 10), cv(58, 40, -0.15, 30), v(0, 50)]),
            fill(WHITE),
        ),
        shape("Cover", 0, 52, rect(252, 16, 8), fill(ORANGE)),
        id=book,
        scale=0.85,
        opacity=0,
    )
    b1, b2, b3 = ids(), ids(), ids()
    bubbles = [
        bubble("Bubble Hello", 112, 104, 126, 46, BLUE, True, b1),
        bubble("Bubble Hallo", 292, 78, 108, 42, GREEN, False, b2),
        bubble("Bubble Word", 236, 150, 92, 38, VIOLET, True, b3),
    ]
    s1, s2, s3, s4 = ids(), ids(), ids(), ids()
    sparkles = [
        sparkle("Sparkle 1", 56, 48, 11, YELLOW, s1),
        sparkle("Sparkle 2", 352, 150, 9, YELLOW, s2),
        sparkle("Sparkle 3", 178, 34, 7, YELLOW, s3),
        sparkle("Sparkle 4", 60, 176, 6, ORANGE, s4),
    ]
    body = "".join(sparkles) + "".join(bubbles) + book_xml

    targets = {b1: (112, 104), b2: (292, 78), b3: (236, 150)}
    intro_objects = [
        keyed(
            book,
            {
                OPACITY: [(0, 0, EASE_OUT), (14, 1, None)],
                SCALE_X: [(0, 0.85, BACK_OUT), (24, 1, None)],
                SCALE_Y: [(0, 0.85, BACK_OUT), (24, 1, None)],
            },
        )
    ]
    for delay, (bid, (bx, by)) in zip((14, 22, 30), targets.items()):
        intro_objects.append(
            keyed(
                bid,
                {
                    X: [(0, 200, "hold"), (delay, 200, EASE_OUT), (delay + 26, bx, None)],
                    Y: [(0, 220, "hold"), (delay, 220, EASE_OUT), (delay + 26, by, None)],
                    SCALE_X: [(0, 0, "hold"), (delay, 0, BACK_OUT), (delay + 24, 1, None)],
                    SCALE_Y: [(0, 0, "hold"), (delay, 0, BACK_OUT), (delay + 24, 1, None)],
                },
            )
        )
    for delay, sid in zip((40, 46, 52, 58), (s1, s2, s3, s4)):
        intro_objects.append(
            keyed(
                sid,
                {
                    SCALE_X: [(0, 0, "hold"), (delay, 0, BACK_OUT), (delay + 14, 1, None)],
                    SCALE_Y: [(0, 0, "hold"), (delay, 0, BACK_OUT), (delay + 14, 1, None)],
                },
            )
        )
    intro_id, idle_id = ids(), ids()
    intro = animation("Intro", intro_id, 72, "oneShot", intro_objects)

    idle_objects = [
        keyed(
            book,
            {
                OPACITY: [(0, 1, "hold")],
                SCALE_X: [(0, 1, "hold")],
                SCALE_Y: [(0, 1, "hold")],
                Y: bob(236, 3, 240),
            },
        )
    ]
    for phase, (bid, (bx, by)) in zip((0, 80, 160), targets.items()):
        idle_objects.append(
            keyed(
                bid,
                {
                    X: [(0, bx, "hold")],
                    Y: bob(by, 8, 240, phase),
                    SCALE_X: [(0, 1, "hold")],
                    SCALE_Y: [(0, 1, "hold")],
                },
            )
        )
    for phase, sid in zip((0, 60, 120, 180), (s1, s2, s3, s4)):
        tw = [(0, 1, EASE_IN_OUT), (60, 0.45, EASE_IN_OUT), (120, 1, None)]
        if phase:
            tw = [(0, 0.72, EASE_IN_OUT), (60 - phase % 60, 1 if phase % 120 else 0.45, EASE_IN_OUT), (120, 0.72, None)]
        idle_objects.append(
            keyed(sid, {SCALE_X: tw, SCALE_Y: tw, ROTATION: [(0, 0, None), (240, 1.5707964, None)]})
        )
    idle = animation("Idle", idle_id, 240, "loop", idle_objects)
    return artboard("Welcome", 300, 400, 320, body, (intro_id, intro), (idle_id, idle))


# --------------------------------------------------------------------- Goal


def goal():
    ring_trim, flame, inner = ids(), ids(), ids()
    body = (
        f'<Shape x="150" y="150" rotation="-1.5707964" name="Progress">'
        f"{ellipse(200, 200)}{stroke(ORANGE, 20, trim_id=ring_trim, trim_end=0)}</Shape>"
        + shape("Track", 150, 150, ellipse(200, 200), stroke(RING_TRACK, 20))
        + node(
            "Flame",
            150,
            190,
            node(
                "Inner",
                2,
                -4,
                shape(
                    "Core",
                    0,
                    0,
                    points([v(0, 0), cv(-18, -18, -1.9, 12), cv(-2, -46, -1.2, 14), v(4, -58), cv(16, -30, 1.3, 12), cv(18, -12, 1.9, 9)]),
                    fill(YELLOW),
                ),
                id=inner,
            ),
            shape(
                "Outer",
                0,
                0,
                points([v(0, 0), cv(-38, -30, -1.9, 22), cv(-8, -78, -1.1, 26), v(2, -104), cv(30, -52, 1.25, 22), cv(36, -24, 1.9, 18)]),
                fill(ORANGE),
            ),
            id=flame,
            scale=0,
        )
    )
    intro_id, idle_id = ids(), ids()
    intro = animation(
        "Intro",
        intro_id,
        70,
        "oneShot",
        [
            keyed(ring_trim, {TRIM_END: [(0, 0, "hold"), (8, 0, EASE_OUT), (60, 0.8, None)]}),
            keyed(
                flame,
                {
                    SCALE_X: [(0, 0, BACK_OUT), (26, 1, None)],
                    SCALE_Y: [(0, 0, BACK_OUT), (26, 1, None)],
                },
            ),
        ],
    )
    idle = animation(
        "Idle",
        idle_id,
        96,
        "loop",
        [
            keyed(ring_trim, {TRIM_END: [(0, 0.8, "hold")]}),
            keyed(
                flame,
                {
                    SCALE_X: [(0, 1, EASE_IN_OUT), (24, 0.95, EASE_IN_OUT), (56, 1.03, EASE_IN_OUT), (96, 1, None)],
                    SCALE_Y: [(0, 1, EASE_IN_OUT), (24, 1.07, EASE_IN_OUT), (56, 0.96, EASE_IN_OUT), (96, 1, None)],
                    ROTATION: [(0, 0, EASE_IN_OUT), (32, -0.05, EASE_IN_OUT), (64, 0.04, EASE_IN_OUT), (96, 0, None)],
                },
            ),
            keyed(
                inner,
                {
                    SCALE_Y: [(0, 1, EASE_IN_OUT), (16, 1.14, EASE_IN_OUT), (48, 0.9, EASE_IN_OUT), (72, 1.08, EASE_IN_OUT), (96, 1, None)],
                    SCALE_X: [(0, 1, EASE_IN_OUT), (16, 0.92, EASE_IN_OUT), (48, 1.06, EASE_IN_OUT), (96, 1, None)],
                },
            ),
        ],
    )
    return artboard("Goal", 760, 300, 300, body, (intro_id, intro), (idle_id, idle))


def main():
    scene = (
        '<Rive version="1" kind="fragment">\n'
        + "\n".join([logo(), welcome(), goal()])
        + "\n</Rive>\n"
    )
    out = Path(__file__).with_name("scene.rml")
    out.write_text(scene, encoding="utf-8")
    print(f"wrote {out}")


if __name__ == "__main__":
    main()
