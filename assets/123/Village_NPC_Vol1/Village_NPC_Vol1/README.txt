==============================================
Village NPC Vol.1 — 6 Characters
8-Direction Sprite Sheets (Idle + Walk)
==============================================

FRAME / SHEET SPECS (ALL CHARACTERS SAME)
  Frame size : 96 x 96 px
  Sheet size  : 768 x 192 px  (8 cols x 2 rows)
  How to slice : Grid / Cell Size = 96 x 96

  Row 0 (top)    : Idle | cols 0-3 = 4-frame loop | cols 4-7 = empty
  Row 1 (bottom) : Walk | cols 0-7 = 8-frame loop

DIRECTIONS
  Hand-drawn (5) : down / downleft / left / upleft / up
  Mirrored (3)   : right     = left      flip X
                   downright = downleft  flip X
                   upright   = upleft    flip X

FILE STRUCTURE
  NPC_01/  NPC_02/ ... NPC_06/
  Each folder contains:
    npc_XX__down.png / __downleft.png / __left.png / __upleft.png / __up.png
    preview_idle.gif  (down direction)
    preview_walk.gif (down direction, optional)

ENGINE QUICK START
  Unity:
    Texture -> Sprite(2D/UI) -> SpriteMode=Multiple
    -> Sprite Editor -> Slice -> By Cell Size -> 96x96 -> Apply
    -> frames 0-3 = Idle , 4-11 = Walk

  Godot (AnimatedSprite2D):
    import texture -> set HFrames=8 VFrames=2 -> SpriteFrames -> auto-slice

SUGGESTED SPEED
  Idle 6 FPS   Walk 8 FPS

LICENSE
  Commercial use allowed.
  Do NOT resell / redistribute the raw asset files.
==============================================

