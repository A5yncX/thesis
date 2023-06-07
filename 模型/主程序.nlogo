breed [humans human]
humans-own ;个体具有的属性
[
  ;对于是否到达终点的判断
  goal? ;是否到达过终点判断
  endpoint ;终点坐标

  ;速度相关
  speed ;个体当前的速度
  max-speed ;属性决定的最大速度

  dsts ;和最近个体的距离
  dsts-patch ;和目标点的距离
  goal-patch ;目标点
  goals ;时间序列目标点集合
  goal ;imagine-way正前方视距
  crash ;碰撞


  ;身高体重等初始因素
  height
  weight
  age
  nature ;性格
  ;
  patient ;耐心,v=0时候会减少，在为0时判断为死锁尝试跳出
  ;上指标缺乏量化标准，本文呈线性
  emotion ;情绪稳定度
  max-k ;个体身体素质可跨越高度

  ;视野
  theta ;角度列表-数组
  thetadata ;视线截断点
  thetadata0 ;身体截断点
  thetadata1 ;特异行动点
  rough;权重点-这条路好不好走

  ;choose way
  dkdata ;特征点导数列表
  vpdata ;有特异点路径

  crowd ;路线上个体数量列表
  rate-way ;各路线分值

  ;;
  patch-before ;死锁跳出

  ;决策次数
  mind
]
patches-own ;瓦片具有的属性
[
  ;;体系1
  value-endpoint ;;基础移动值
  ;体系2
  k ;方向导数-数组
  s ;路程-数组
  z ;高度
]

to resethumans ;初始化每个个体
  set mind 0
  set patient nature
  set goal? false
  set emotion 100
  set endpoint patch 35 35
  set max-speed 0.7 + random-float 0.7

  set goal-patch one-of patches in-cone 10 30
  set goals [];时间序列目标选择

  set nature 1 + random 5 ;随机个体性格
  ;set nature 5
  set color black
  ;ifelse nature = 1 [set color (nature * 10 + 5)][]
  ;ifelse nature = 2 [set color (nature * 10 + 5)][]
  ;ifelse nature = 3 [set color (nature * 10 + 5)][]
  set color (nature * 10 + 5) ;根据性格指定颜色(导入数据要改)
  set height 1.4 + random-float 0.4
  set weight 40 + random 40
  set max-k 2 ;身体顺序可跨越高度
  set size 1.5
  set speed 0 ;初始速度
  set theta [0 1 2 3 4] ;角度列表
    set thetadata [] ;初始数据列表
  set thetadata0 [] ;数据列表0
  set thetadata1 [] ;数据列表1
  ;choose way
  set dkdata [] ;特征点导数列表
  set rate-way [];路径评分
  ;face endpoint
end

to resetpatches ;初始化瓦片属性
  ask patches[
    set k [1 2 3 4 5 6 7 8] ;现在是默认，导入后需要加入判断
    set s [1 2 3 4 5 6 7 8]
    set z 0 + random-float 10  ;现在是默认，导入后需要加入判断
  ]
  repeat 1 [diffuse z 1]

  ask patches [set pcolor z]
  ;ask patches [set pcolor white]

  ask  patch -45 -45[ ;命令点-25，-25
    set pcolor black
    set value-endpoint 0 ;值为起点（世界初始值0
  ]
  ask  patch 35 35[ ;;命令点 35，35
    set pcolor red
    set value-endpoint 100 ;; 让点25,25的值为终点（值为100
  ]
  repeat 100 [ diffuse value-endpoint 1 ] ;对每个格子平滑1次-本指令重复100次
end

to summon ;个体生成
  ifelse rdm? [
    repeat number [create-humans 1 [resethumans move-to one-of patches]]]
  [ ask patch -45 -45 [ sprout-humans number [
    fd 3
    resethumans
  ]]]
end

to setup ;生成世界
  clear-all
  resetpatches
  summon
  reset-ticks
    ;inspect human 1 ;观察个体1
end

to go ;按照tick运行
    if all? humans [goal?]
    [ stop ]
  ask humans[  ;要求人类执行以下模块
    let old-gp goal-patch

    ;face endpoint
    vision-distance
    characteristic-point
    vp
    roughs
    see-way
    think
    crowding
    imagine-way

    move
    speed-change

    ifelse goal-patch != old-gp [set mind mind + 1][]
    ifelse show-line? ;轨迹展示模块（开关
    [ pen-down ]
    [ pen-up ]
    ifelse show-nature? ;轨迹展示模块（开关
    [ set label nature ]
    [ set label "" ]
  ]
  tick ;计时
end

to crashing
  set speed 0 ;碰撞减速处理
end

to speed-change ;加速

  set dsts (distance min-one-of other humans [distance myself])
  let next-patch patch-ahead 1 ;确定目标点后近处路程点的判断
  let dz0 ([z] of next-patch - [z] of patch-here) ;用于确定下一步的移动
  if dsts <= 0.5[

    set crash min-one-of other humans [distance myself] ;碰撞目标
    ask crash [set speed speed / 2]
    set emotion (emotion - (6 - nature))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ;todo 情绪感染（好像有点问题）
    if ticks > 200 [
      if nature < 2 [
        set emotion ([emotion] of crash)
    ]]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;改良社会力模型
    set patch-before patch-here
    let fbody ((max-speed - speed) / (1 + random-float 0.2))
    let fslide (0.8 * 9.8 * (0.5 - dsts) * (0.3 + random-float 0.5)) / weight
    let fsocial (nature * 0.1 * (exp (0.5 - dsts) / 2) * (0.3 + random-float 0.5)) / weight
    ifelse dz0 >= (height - 0.5) [set speed 0]
    [set speed (speed + (fbody + fslide + fsocial) / 2)
      lt random 40
      rt random 40
      crashing
      fd speed / 2]
  ]
  if dsts > 0.5[ ;无碰撞

    set emotion (emotion + nature)

    let fbody ((max-speed - speed) / (1 + random-float 0.3))
    let fsocial random-float 0.05
    if dz0 <= (height - 0.5) [set speed 0]
    set speed ((speed + fsocial + fbody ) / 1)
    fd speed / 2
  ]
  if speed > max-speed [set emotion emotion + 1 set speed max-speed]


  if speed = 0 [ ;todo 或许无抖动防死锁更好？
    if patch-here = patch-before [ ;同瓦片不动
      set patient patient - 1
      if patient <= 0 [
        ;lt 180
        fd 0.75
        set speed 0
        set patient nature];跳出循环
  ]
]
  if emotion < 0 [set emotion 0] ;防止越界
  if emotion > 100 [set emotion 100];防止越界
end

to vision-distance ;确定视野距离
  face endpoint
  let times 0
    set thetadata [];初始数据列表
  set thetadata0 [] ;数据列表0
  set heading heading - 40
  while [times < 5]
  [
    let dist 1
    while [dist <= 10][
      let z1 ([z] of patch-ahead dist)
      let gz (dist * tan 30 + height + [z] of patch-here);可视角度
      ifelse z1 >= gz [
        set thetadata0 lput dist thetadata0
        set dist 11]
        [
        set dist dist + 1
        if dist = 11 [set thetadata0 lput (dist - 1) thetadata0]
      ]
    ]
    set heading heading + 20
    set times (times + 1)
  ]
  set thetadata thetadata0
  face endpoint
end

to characteristic-point ;身体截断点
  face endpoint
  let times 0
  set heading heading - 40
while [times < 5]
  [
    let z1 item times thetadata0
    let dist 1
    let dkheading round(abs((heading - 180) / 45));截断点对于人的角度
    ;let dk item (dkheading - 1) k  ;确定对于人方向最大导数
    let dk item dkheading k
    while [dist <= z1][
      ;身体截断点
      ifelse dk > max-k[ ;如果身体截断点的导数大于可跨最高则在此截断
      set dist replace-item times thetadata0 dist ;将目前循环的点作为截断点替换数组中的对应点
      set dist (z1 + 1);跳出循环
      ]
      [set dist dist + 1]
    ]
    set heading heading + 20
    set times (times + 1)
  ]
  face endpoint
end

to vp ;特异行动点选取
  ;face endpoint
  set thetadata1 []
  let times 0
  set heading heading - 40
while [times < 5]
  [
    let z1 item times thetadata0
    let dist 1
    let dkheading round(abs((heading - 180) / 45));截断点对于人的角度
    ;let dk item (dkheading - 1) k  ;确定对于人方向最大导数
    let dk item dkheading k
    let -dk (0 - dk)
    let min-k (0 - dkheading)
    while [dist <= z1][
      ;身体截断点
      ifelse -dk < min-k[ ;如果
        set thetadata1 lput dist thetadata1 ;将
      set dist (z1 + 1);跳出循环
      ][
        set dist dist + 1
        if dist >= z1 [set thetadata1 lput z1 thetadata1]
      ]
    ]
    set heading heading + 20
    set times (times + 1)
  ]
  face endpoint
end

to roughs ;权重点-判断路面崎岖程度
  set rough []
  let times 0
  set heading heading - 40
  while [times < 5][
    let rnumber 0
    let dist 1
    while [dist <= 10][
      let z1 ([z] of patch-ahead dist)
      let z2 ([z] of  patch-ahead (dist + 1))
      ifelse abs(z1 - z2)  >= 1 [
        set rnumber (rnumber + 1)
        set dist dist + 1
      ]
      [
        set dist dist + 1
      ]
    ]
    set rough lput rnumber rough
    set heading heading + 20
    set times (times + 1)
  ]
end

to see-way ;分路
  set vpdata []
  let times 0
  set heading heading - 40
  while [times < 5][
    let p0 item times thetadata0
    let p1 item times thetadata1 ;此点可确定特异点后评分
    ifelse p0 = p1
    [;平缓路径，可直接走过去
      set vpdata lput p0 vpdata
    ][;有特异点路径
      set vpdata lput p1 vpdata
    ]
    set heading heading + 20
    set times (times + 1)
  ]
end

to think ;时间序列的目标点决策
  set dsts-patch (distance goal-patch)
  set goals fput goal-patch goals
  if length goals = 4 [
    set goals remove-item 3 goals
  ]
end

to crowding ;路线拥挤程度
  set crowd []
   let times 0

  set heading heading - 40
while [times < 5]
  [
;in-cone count
    let z1 item times thetadata0
    let c1 humans in-cone z1 1
    let c2 count c1
    set crowd lput c2 crowd
    set heading heading + 20
    set times (times + 1)
  ]
  face endpoint
end

to imagine-way ;路径打分
  ;todo加上路上个体判定？

  face endpoint
  set rate-way []

  set goal item 2 thetadata
  set goal-patch patch-ahead goal

  let times 0
  ;set heading heading - 40
  while [times < 5][
    let cd1 item times crowd
    let pp item times thetadata
    let p0 item times thetadata0
    let p1 item times thetadata1
    let rnumber item times rough
    let headingpoint (2 - abs(times - 2))

    ;评分,后面两项占比有点小，需要调节

    let aaa 100 - emotion
    let bbb emotion
    let ccc 100 - emotion
    let ddd 100 - emotion
    let eee 100 - emotion
    let point (headingpoint + aaa * 0.3 * (dsts-patch / 10) + bbb * 0.4 * (1 - (rnumber / 10)) + ccc * 0.15 * (1 - ((pp - p0) / pp)) + ddd * 0.15 * (1 - ((p0 - p1) / p0)) - 5 * cd1)
    set rate-way lput point rate-way
    set times (times + 1)
  ]
end

to move ;选择朝向，准备此tick移动
  let way max rate-way ;让当前路径为分数最高路径
  let head position way rate-way ;确定偏转角度

  set heading (heading - 40 + (20 * head));确定偏转角度
  let tk ticks ;时间序列转向
  if ticks = tk + 5 [set tk ticks
  if length goals >= 2 [let sub-goal-patch item 1 goals let heading2 towards sub-goal-patch let heading1 towards goal-patch set heading (heading + (heading1 - heading2) / 2 )]
  ]
  if nature < 3 [lt random 10 rt random 10]
  if endpoint = patch-here [ht set goal? true
    stop
    move-to patch -30 30 ]
  if goal = true[
    move-to patch -30 30 ;todo取消最后到终点的掉分
  stop]

end
@#$#@#$#@
GRAPHICS-WINDOW
192
38
806
653
-1
-1
6.0
1
10
1
1
1
0
0
0
1
-50
50
-50
50
0
0
1
ticks
60.0

BUTTON
76
552
167
585
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
8
143
41
293
number
number
2
200
43.0
1
1
NIL
VERTICAL

SWITCH
49
187
173
220
show-line?
show-line?
0
1
-1000

BUTTON
102
509
165
542
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
52
234
155
267
rdm?
rdm?
1
1
-1000

MONITOR
123
87
180
132
NIL
ticks
17
1
11

SWITCH
47
142
189
175
show-nature?
show-nature?
1
1
-1000

PLOT
0
303
160
423
5类人的平均情绪稳定度
tick
emotion
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"pen-1" 1.0 0 -2674135 true "" "plot mean [ emotion ] of humans with [ nature = 1 ]"
"pen-2" 1.0 0 -955883 true "" "plot mean [ emotion ] of humans with [ nature = 2 ]"
"pen-3" 1.0 0 -6459832 true "" "plot mean [ emotion ] of humans with [ nature = 3 ]"
"pen-4" 1.0 0 -1184463 true "" "plot mean [ emotion ] of humans with [ nature = 4 ]"
"pen-5" 1.0 0 -10899396 true "" "plot mean [ emotion ] of humans with [ nature = 5 ]"

MONITOR
38
89
95
134
mind
mean [ mind ] of humans
17
1
11

@#$#@#$#@
## WHAT IS IT?

This example shows how to make turtles climb hills -- or descend into valleys -- using the `uphill`, `uphill4`, `downhill`, and `downhill4` commands.  The same technique is useful for modeling any kind of creature that follows a gradient in its environment.

## THINGS TO NOTICE

These commands always make the turtle move to the center of a patch.

`uphill` and `downhill` make the turtle look at all eight neighboring patches (including diagonal neighbors).  `uphill4` and `downhill4` only look at the four neighboring patches (to the north, south, east, and west).

With the `uphill` and `downhill` commands, diagonal moves are longer (1.414...) than vertical or horizontal moves (1.0).  If you use the `uphill4` and `downhill4` commands, all moves are the same length (1.0).

If there is a tie between neighboring patches, NetLogo breaks the tie randomly.

## THINGS TO TRY

In the `go` procedure in the Code tab, change `uphill` to `uphill4`, `downhill`, or `downhill4` and observe the results.

## NETLOGO FEATURES

If you look at the entry for `uphill` in the NetLogo Dictionary, it shows some code that does the exact same thing as the primitive does. If you need to do something that is similar to the primitive, but different in so way, you could use that code as a starting point.

<!-- 2007 -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
