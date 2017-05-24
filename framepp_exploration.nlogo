globals [
  
  cash-on-hand
  cashflow
  daily-revenue
  daily-expenses
  daily-orders
  daily-deliveries
  daily-trim
  daily-sqm
  
  breakeven?
  inversion-order-number
  worst-cash-position
  
]

to setup
  clear-all
  reset-ticks
  set cash-on-hand starting-cash - startup-costs ;; choose whether to go into debt or not
  set cashflow 0
  set breakeven? false
  set inversion-order-number 0
  set worst-cash-position cash-on-hand
  
end

to go
  
  ;; clear daily counters
  
  set daily-revenue 0
  set daily-expenses 0
  set daily-orders 0
  set daily-deliveries 0
  set daily-trim 0
  set daily-sqm 0
  
  ;; do orders and per-item expenses for the day
  
  do-orders
  
  ;; do monthly expenses
  
  if (ticks mod 30 = 0) [
    do-monthlies
    ]
  
  do-balance
  
  do-plotting
  
  tick
  
end

to do-orders
  
  ;; work out how many orders based on mean stddev monthly growth and what they're composed of. Set expenses and revenues. set materials usage
  
  ;; how many orders will we model today? find the month, the day of the month, apply growth rate, report value.
  
  let day ticks mod 30 ;; reports remainder of this month
  
  let month (ticks - day) / 30 ;; should give integer month number
  
  let daily-order-mean first-day-orders * (1 + (monthly-custnum-growth / 100)) ^ month
  set daily-order-mean daily-order-mean * (1 + (monthly-custnum-growth / (30 * 100))) ^ day ;; roughly expected customer numbers
  
  ;; get expected order number randomly from distribution around daily mean
  
  set daily-orders round random-normal daily-order-mean orders-stddev
  if daily-orders < 0 [set daily-orders 0]
  
  ;; for orders today, get the number of pieces, and then update revenues and expenses
  
  repeat daily-orders [
    
    ;; how many pieces in this order?
    let pieces round random-normal mean-order-quant order-stddev
    if pieces < 1 [set pieces 1] ;; minimum order size
    
    repeat pieces [
      
      ;; get the sizes, and work out revenues and expenses
      
      let dimension round random-normal mean-dimension dim-stddev
      if dimension < 10 [set dimension 10]
      
      let dimension2 round dimension / lw-ratio
      
      let trim ((2 * dimension) + (2 * dimension2)) / 100 ;; cm to m conversion
      let area (dimension * dimension2 / 10000) ;; sq cm to sq m conversion
      
      let rawprice (trim * frame-linear-metre) + (area * glass-sq-metre) + (area * masonite-sq-metre) + fittings-cost
      
      if (delivery-outsource? and (random 100 <= pickup-percent)) [ ;; some people elect to pick up themselves
        set rawprice rawprice + outsourced-delivery-cost 
        set daily-deliveries daily-deliveries + 1
      ]   
      
      let price rawprice * (1 + (margin / 100))
      
      if VAT? [set price price * 1.1] ;; Take account of VAT at 10% standard rate, not offset against input tax because who uses that??
      
      ;; all the adding up is done. Now put the revenues and expenses, and materials usage into the daily totals
      
      set daily-revenue daily-revenue + price
      set daily-expenses daily-expenses + rawprice
      
      set daily-trim daily-trim + trim
      set daily-sqm daily-sqm + area
      
    ]
  ]
  
end

to do-monthlies
  
  ;; salaries
  
  set daily-expenses daily-expenses + worker-salary
  if not delivery-outsource? [ set daily-expenses daily-expenses + delivery-salary]
  
  ;; utilities
  
  set daily-expenses daily-expenses + monthly-power + monthly-rent + monthly-net-and-hosting + monthly-water-rubbish + monthly-office + monthly-advertising + monthly-misc
  
end

to do-plotting
  
  ;; update the plots to show totals
  
  set-current-plot "money"
  set-current-plot-pen "revenue"
  plot daily-revenue
  set-current-plot-pen "expenses"
  plot daily-expenses
  set-current-plot-pen "cash"
  plot cash-on-hand
  set-current-plot-pen "cashflow"
  plot cashflow
  
  set-current-plot "orders"
  set-current-plot-pen "order-num"
  plot daily-orders
  set-current-plot-pen "deliveries"
  plot daily-deliveries
  
  set-current-plot "stock-used"
  set-current-plot-pen "trim-linmetre"
  plot daily-trim
  set-current-plot-pen "masonite-glass-sqm"
  plot daily-sqm

end

to do-balance
  
  ;; tot up the figures and set totals
  
  set cashflow daily-revenue - daily-expenses
  set cash-on-hand cash-on-hand + cashflow
  
  if cash-on-hand < worst-cash-position [
    set worst-cash-position cash-on-hand
    set inversion-order-number daily-orders
    ]
  
  if (not breakeven?) and (cash-on-hand >= starting-cash) [
    set breakeven? true
    
    let day ticks mod 30 ;; reports remainder of this month
  
    let month (ticks - day) / 30 ;; should give integer month number
    
    output-print "Break-even occured at:"
    output-type "Month " output-type month output-type " day " output-print day 
    
    output-print "Inversion occured with: "
    output-type "Cash position: $" output-type worst-cash-position output-type " , orders per day: " output-print daily-orders
    ]
  
end
@#$#@#$#@
GRAPHICS-WINDOW
374
10
538
195
16
16
4.67
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks

SLIDER
10
120
182
153
startup-costs
startup-costs
0
10000
4000
100
1
NIL
HORIZONTAL

SLIDER
190
120
362
153
worker-salary
worker-salary
0
300
170
10
1
NIL
HORIZONTAL

TEXTBOX
20
95
170
113
Settings\n
11
0.0
0

TEXTBOX
200
95
350
113
Salaries
11
0.0
1

SWITCH
10
160
180
193
delivery-outsource?
delivery-outsource?
0
1
-1000

SLIDER
190
160
362
193
delivery-salary
delivery-salary
0
300
150
10
1
NIL
HORIZONTAL

BUTTON
10
10
73
43
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

BUTTON
10
50
73
83
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

SLIDER
10
200
182
233
frame-linear-metre
frame-linear-metre
0
3
1
.1
1
NIL
HORIZONTAL

SLIDER
10
240
182
273
glass-sq-metre
glass-sq-metre
0
15
8.4
.1
1
NIL
HORIZONTAL

SLIDER
10
280
182
313
masonite-sq-metre
masonite-sq-metre
0
5
1
.1
1
NIL
HORIZONTAL

SLIDER
10
320
182
353
fittings-cost
fittings-cost
0
2
0.5
.1
1
NIL
HORIZONTAL

SLIDER
10
395
182
428
monthly-power
monthly-power
0
400
140
10
1
NIL
HORIZONTAL

SLIDER
10
435
182
468
monthly-rent
monthly-rent
0
300
180
10
1
NIL
HORIZONTAL

SLIDER
10
475
180
508
monthly-net-and-hosting
monthly-net-and-hosting
0
100
35
5
1
NIL
HORIZONTAL

SLIDER
10
515
182
548
monthly-water-rubbish
monthly-water-rubbish
0
100
30
5
1
NIL
HORIZONTAL

SLIDER
190
395
362
428
monthly-office
monthly-office
0
100
50
10
1
NIL
HORIZONTAL

SLIDER
190
475
362
508
monthly-misc
monthly-misc
0
100
20
10
1
NIL
HORIZONTAL

SLIDER
190
435
362
468
monthly-advertising
monthly-advertising
0
300
50
10
1
NIL
HORIZONTAL

SLIDER
190
200
360
233
outsourced-delivery-cost
outsourced-delivery-cost
0
5
1
.1
1
NIL
HORIZONTAL

SLIDER
190
320
362
353
margin
margin
0
100
53
1
1
%
HORIZONTAL

SLIDER
370
320
540
353
monthly-custnum-growth
monthly-custnum-growth
0
100
3
.1
1
%
HORIZONTAL

SLIDER
370
360
542
393
mean-order-quant
mean-order-quant
0
10
2
1
1
NIL
HORIZONTAL

SLIDER
370
400
542
433
order-stddev
order-stddev
0
10
0.5
.5
1
NIL
HORIZONTAL

SLIDER
370
440
542
473
lw-ratio
lw-ratio
1
4
1.4
.1
1
NIL
HORIZONTAL

SLIDER
370
480
542
513
mean-dimension
mean-dimension
10
100
29
1
1
cm
HORIZONTAL

SLIDER
370
520
542
553
dim-stddev
dim-stddev
0
15
10
1
1
NIL
HORIZONTAL

SLIDER
370
240
542
273
first-day-orders
first-day-orders
0
300
3
1
1
NIL
HORIZONTAL

SLIDER
370
280
542
313
orders-stddev
orders-stddev
0
100
4
1
1
NIL
HORIZONTAL

SWITCH
190
280
293
313
VAT?
VAT?
1
1
-1000

PLOT
550
10
1190
205
money
day
$USD
0.0
10.0
0.0
1.0
true
true
PENS
"revenue" 1.0 0 -13345367 true
"expenses" 1.0 0 -2674135 true
"cash" 1.0 0 -10899396 true
"cashflow" 1.0 0 -955883 true

PLOT
550
210
1190
390
orders
day
voulme
0.0
10.0
0.0
10.0
true
true
PENS
"order-num" 1.0 0 -10899396 true
"deliveries" 1.0 0 -8630108 true

SLIDER
190
515
362
548
pickup-percent
pickup-percent
0
100
5
1
1
%
HORIZONTAL

PLOT
550
395
1190
555
stock-used
day
volume (m or sqm)
0.0
10.0
0.0
10.0
true
true
PENS
"trim-linmetre" 1.0 0 -16777216 true
"masonite-glass-sqm" 1.0 0 -13345367 true

SLIDER
190
240
362
273
starting-cash
starting-cash
0
10000
5000
100
1
USD
HORIZONTAL

OUTPUT
75
10
370
115
12

@#$#@#$#@
WHAT IS IT?
-----------
This section could give a general understanding of what the model is trying to show or explain.


HOW IT WORKS
------------
This section could explain what rules the agents use to create the overall behavior of the model.


HOW TO USE IT
-------------
This section could explain how to use the model, including a description of each of the items in the interface tab.


THINGS TO NOTICE
----------------
This section could give some ideas of things for the user to notice while running the model.


THINGS TO TRY
-------------
This section could give some ideas of things for the user to try to do (move sliders, switches, etc.) with the model.


EXTENDING THE MODEL
-------------------
This section could give some ideas of things to add or change in the procedures tab to make the model more complicated, detailed, accurate, etc.


NETLOGO FEATURES
----------------
This section could point out any especially interesting or unusual features of NetLogo that the model makes use of, particularly in the Procedures tab.  It might also point out places where workarounds were needed because of missing features.


RELATED MODELS
--------------
This section could give the names of models in the NetLogo Models Library or elsewhere which are of related interest.


CREDITS AND REFERENCES
----------------------
This section could contain a reference to the model's URL on the web if it has one, as well as any other necessary credits or references.
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

sheep
false
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

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
NetLogo 4.1.3
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 1.0 0.0
0.0 1 1.0 0.0
0.2 0 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
1
@#$#@#$#@
