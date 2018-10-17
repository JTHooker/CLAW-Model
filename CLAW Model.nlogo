;;; things to do
;  export check points on turtle's life, starting conditions and when exiting the screen (x,y,client properties)
;  record number of issues for each client
;  add in TAC processes, add bands for processes, allow moving to different points in the timeline, number of items in each, width of each
;  find out how starting conditions impact the ending point
;  get to ratio of 80% recover in 6 months, 19% are long term, 1% are lifetime
;  if at fault, do not switch to orange, only not at fault eligible for common law
;  find who exits at 6 months, 18, 24, and 36
;  set up configuable problem zones, have a +X% at around 6 months, then a -X%, then +X% at half way, then a -X% after that
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; TAC Common Law process Agent-Based Model V.1.0 ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

extensions [ nw palette ]



globals [
  Waitlisteffect ;; average amount people improve per week
  CurrentDrift
  time
  InjuryRecoverySD
  GoodExit6Months
  GoodExit18Months
  GoodExit24Months
  GoodExit36Months
  GoodExit36PlusMonths
  BadExit6Months
  BadExit18Months
  BadExit24Months
  BadExit36Months
  BadExit36PlusMonths
  NeutralExit36PlusMonths
  DownDriftFactor1
  DownDriftFactor2
  DownDriftFactor3
  UpDriftFactor1
  UpDriftFactor2
  UpDriftFactor3
  CommonLawCapture
  RandomCapture
  DownwardDriftModifier
  UpwardDriftModifier

  TotalClients
  scheme-type
  costs
]

breed [
  clients client
]

breed
 [ issues issue
]

clients-own [
  HealthStatus ;;
  InjurySeverity ;;
  AtFaultStatus ;; (1 not responsible, 3 totally responsible)
  PreviousInjury ;; Have they had a previous injury?
  Drift ;; sum of all risk factors
  ;SixMonthStatus ;;  Mean time it takes for people to exit
  Embeddedness ;;
  EmploymentStatus ;; 0-not employed, 1-employed
  VulnerableStatus ;; 0-not vulnerable, 1-vulnerable
  Gender ;; 0 Female, 1 Male
  Age
  ClaimDuration ;; 0 (0-12 months), 3 (37-72 months)
  InjuryClassification ;; 0=Muscularskeletal, 3=other severe
  Education ;; 1=primary school, 10=postgradute
  EducationWeight
  GenderWeight
  AgeWeight
  VulnerableStatusWeight
  EmploymentStatusWeight ;; 0-not employed, 1-employed, weight of 0.11
  AtFaultStatusWeight ;; personal responsibility for accident: (1 not responsible, 3 totally responsible), a weight of -0.35
  ClaimDurationWeight
  InjuryClassificationWeight
  IssuesEncountered
  StartingHealthStatus
  RockBottom
  ClientCost
  Satisfaction
  ]

;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; SETUP PROCEDURES ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  setup-patches
  setup-globals
  setup-clients
  setup-issues
  reset-ticks
end

to setup-globals
  set InjuryRecoverySD 5
  ;set InjuryRecovery 60
  set GoodExit6Months 0
  set GoodExit18Months 0
  set GoodExit24Months 0
  set GoodExit36Months 0
  set BadExit6Months 0
  set BadExit18Months 0
  set BadExit24Months 0
  set BadExit36Months 0
  set BadExit36PlusMonths 0
  set NeutralExit36PlusMonths 0
  set DownDriftFactor1 1
  set DownDriftFactor2 1
  set DownDriftFactor3 1
  set UpDriftFactor1 1
  set UpDriftFactor2 1
  set UpDriftFactor3 1
  set CommonLawCapture 0
  set DownwardDriftModifier 4
  set UpwardDriftModifier 3
  set TotalClients 0
  set costs 0
end

to setup-clients
    if  100 - Road_Safety_Effectiveness > random 100 [ create-clients 1 [

    set heading 90
    set satisfaction random-normal 7 1
    set IssuesEncountered 0
    set Embeddedness random-normal 0 20

    set InjurySeverity random-normal 50 10
    set HealthStatus random-normal 50 10
    set StartingHealthStatus HealthStatus
    set PreviousInjury random-normal 50 10
    ;set SixMonthStatus ( (xcor + 300) / random-normal 180 180 ) * 10
    ;set SixMonthStatus 1

    set AtFaultStatus random 3
    if AtFaultStatus = 0
      [set AtFaultStatusWeight 1 + (0.35 / 2) set color blue ]
    if AtFaultStatus = 1
      [set AtFaultStatusWeight 1 set color yellow ]
    if AtFaultStatus = 2
      [set AtFaultStatusWeight 1 - (0.35 / 2) set color white ]

    set EmploymentStatus random 2
    if EmploymentStatus = 0
      [set EmploymentStatusWeight 1 ]
    if EmploymentStatus = 1
      [set EmploymentStatusWeight 1 + 0.11 ]

    set VulnerableStatus random 2
    if VulnerableStatus = 0
      [set VulnerableStatusWeight 1 ]
    if VulnerableStatus = 1
      [set VulnerableStatusWeight 1 + 0.17 ]

    set Age (random-float 72 )  + 16  ;; to get range between 16 and 88
    set AgeWeight 0.915 + ((Age - 16) * .0023611)

    set Gender random 2
    if Gender = 0
      [set GenderWeight 1 - 0.10 ]
    if Gender = 1
      [set GenderWeight 1 + 0.12 ]

    set ClaimDuration random 4
    if ClaimDuration = 0
      [set ClaimDurationWeight 1 + 0.05 ]
    if ClaimDuration = 1
      [set ClaimDurationWeight 1 + 0.025  ]
    if ClaimDuration = 2
      [set ClaimDurationWeight 1 - 0.025  ]
    if ClaimDuration = 3
      [set ClaimDurationWeight 1 - 0.05 ]

    set InjuryClassification random 4
    if InjuryClassification = 0
      [set InjuryClassificationWeight 1 - 0.05 ]
    if InjuryClassification = 1
      [set InjuryClassificationWeight 1 - 0.025  ]
    if InjuryClassification = 2
      [set InjuryClassificationWeight 1 + 0.025  ]
    if InjuryClassification = 3
      [set InjuryClassificationWeight 1 + 0.05 ]

    set Education random 11
    set EducationWeight 0.95 + (Education * 0.1 / 11)

    set waitlisteffect random-normal InjuryRecovery InjuryRecoverySD
    set xcor -300
    set ycor Embeddedness
    set shape "person"
    set size 3
    set RockBottom 0
    set TotalClients TotalClients + 1
    set ClientCost 0

    ]
  ]
  end

to setup-issues
  create-issues Issue_Count [ set size random-normal 20 5 set shape "target" set color one-of [ red green ] move-to one-of patches ]
end

to setup-patches
  ask patches [
   ;; set pcolor orange
    ;;if pycor = 0 [set pcolor grey]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;
;;;; GO PROCEDURES ;;;;
;;;;;;;;;;;;;;;;;;;;;;;

to go
  ask clients [
    progress
    exitscheme
    status
    changepatchcolor
    estimatecosts
    estimatehealthstatus
    estimatesatisfaction
   ]
  launchnewclients
  driftissues
  newprocesses
  generateissues
  tick
  set time time + 1
end

to progress
  set heading random-normal 90 5 - ( ((sqrt drift) + (ycor * .5)))
  if  any? issues in-radius 10  with [ color = red ] and heading > 45 and heading < 135 [ set issuesencountered issuesencountered + 1 set heading heading + 45  ] fd .5
  if  any? issues in-radius 10  with [ color = green ]  and heading > 45 and heading < 135 [ set issuesencountered issuesencountered - .5 set heading heading - 45  ] fd .5
end

to exitscheme
  ask clients [
    if ycor > 98 and hidden? = false
    [
      ifelse xcor <= -249 [ set GoodExit6Months GoodExit6Months + 1]
        [ifelse xcor <= -149 [ set GoodExit18Months GoodExit18Months + 1]
          [
             ifelse xcor <= -100 [ set GoodExit24Months GoodExit24Months + 1]
              [ifelse xcor <= 0 [ set GoodExit36Months GoodExit36Months + 1]
                  [set GoodExit36PlusMonths GoodExit36PlusMonths + 1]
              ]
          ]
      ]
      die
    ]
    if xcor > 298 and hidden? = false  ;; what to do in this case? They are in neutral territory but haven't had a good or bad exit
    [ ;ht
      set NeutralExit36PlusMonths  NeutralExit36PlusMonths + 1
      die
    ]

    if ycor < -98 and hidden? = false  ;; if they get here, and it is past 18 months, then see if they get caught by common law
    [
      if xcor > -149 and AtFaultStatus < 3 ;can't use common law if at fault
      [ ;; there are 300 + 150 timesteps. If we want a 25% chance of capture over 450 timesteps (450*4*Solicitors)
         ;; get a random number between 0 and 900000 (for 50 Solicitors), if it is less than the number of Solicitors, then capture it for common law
        set RandomCapture random-float 450 * 4 * Solicitors * 10 * count Clients with [color = orange and hidden? = false]
         if RandomCapture < Solicitors
         [
          ;ht
          set CommonLawCapture CommonLawCapture + 1
          die
         ]
      ]
    ]

  ]
end

to launchnewclients
  setup-clients
end


to changepatchcolor
  ask clients [ if traceclients = true [
    if 10 > random 10000 [ ask patch-here [ set pcolor [ color] of myself ] ]]
  ]
end

to status
  ;;if ycor < 75 and ycor > -75 [ set color white ]
  if ycor > 75 [ set color green ]
  if ycor < -75 and ycor > -99 [ set color orange ]
  if ycor < -99

  [set color red

    if ycor < -99 and hidden? = false and RockBottom = 0
    [
      ifelse xcor <= -250 [ set BadExit6Months BadExit6Months + 1]
        [ifelse xcor <= -150 [ set BadExit18Months BadExit18Months + 1]
          [
             ifelse xcor <= -100 [ set BadExit24Months BadExit24Months + 1]
              [
                ifelse xcor <= 0 [ set BadExit36Months BadExit36Months + 1]
                  [set BadExit36PlusMonths BadExit36PlusMonths + 1]
              ]
          ]
       ]
    ]
    set RockBottom 1

  ]
end

to driftissues
  ask issues [ set heading heading + random 45 fd random .5 ]
end

to newprocesses
  if mouse-down? and Event_Type = "Negative" [ create-issues 1 [set size 20 set color red set shape "target" setxy mouse-xcor mouse-ycor ]]
  if mouse-down? and Event_Type = "Positive" [ create-issues 1 [set size 20 set color green set shape "target" setxy mouse-xcor mouse-ycor ]]
  if mouse-down? and Event_Type = "Delete" [ ask issues-on patch mouse-xcor mouse-ycor [ die ] ]
end

to estimatecosts
  set clientcost Clientcost + 10 ;;+ issuesencountered * 10
end

to estimatehealthstatus
  set healthstatus StartingHealthStatus + (sqrt(ycor + 101) / 2 )
end

to estimatesatisfaction
  if satisfaction > 0 and satisfaction < 10 and issuesencountered > 0 [ set satisfaction ( satisfaction - (issuesencountered / 10)) ]
  if satisfaction > 0 and satisfaction < 10 and issuesencountered < 0 [ set satisfaction ( satisfaction + (( issuesencountered * -1 ) / 10)) ]
  if satisfaction < 1 [ set satisfaction 1 ]
  if satisfaction > 10 [ set satisfaction 10 ]
end

to generateissues
  if count issues < issue_count [ create-issues 1 [  set color one-of [ red green ] set size random 20 move-to one-of patches set shape "target" ]]
  if count issues > issue_count [ ask n-of 1 issues [ die ] ]
end
@#$#@#$#@
GRAPHICS-WINDOW
415
33
1456
387
-1
-1
1.72
1
10
1
1
1
0
1
0
1
-300
300
-100
100
0
0
1
days
30.0

BUTTON
55
93
138
126
setup
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

BUTTON
142
93
225
126
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
86
165
259
198
NewClients
NewClients
0
10
1.0
1
1
NIL
HORIZONTAL

TEXTBOX
833
15
957
33
NIL
11
0.0
1

TEXTBOX
134
63
220
81
Main commands
11
0.0
1

TEXTBOX
99
131
273
149
Incoming Client Controls
11
0.0
1

PLOT
410
450
769
641
Client Status Charts
NIL
NIL
0.0
100.0
0.0
100.0
true
true
"" ";;if ticks = 200 [ clear ] "
PENS
"6 Months +" 1.0 0 -2674135 true "" "plot count clients with [ xcor > -250 ]"
"3 Years +" 1.0 0 -955883 true "" "plot count clients with [ xcor > 50 ] "
"5 Years +" 1.0 0 -6459832 true "" "plot count clients with [ xcor > 250 ]"

SLIDER
91
297
263
330
InjuryRecovery
InjuryRecovery
0
100
22.0
1
1
NIL
HORIZONTAL

SLIDER
69
202
282
235
Road_Safety_Effectiveness
Road_Safety_Effectiveness
1
100
1.0
1
1
NIL
HORIZONTAL

BUTTON
228
93
307
126
Go Once
Go
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
91
334
263
367
RandomVariation
RandomVariation
0
.2
0.049
.001
1
NIL
HORIZONTAL

TEXTBOX
126
278
305
306
Recovery Dynamics
11
0.0
1

PLOT
778
451
1136
640
KPI1 Health
NIL
NIL
0.0
10.0
0.0
2.0
true
true
"" ""
PENS
"HealthStatus" 1.0 0 -5298144 true "" "plot mean [ HealthStatus ] of clients"
"At-Fault Status" 1.0 0 -14070903 true "" "plot 100 * ( count clients with [ Atfaultstatus = 2 ] / count clients ) "

MONITOR
434
468
542
513
Clients > 5 years
count clients with [ xcor > 250 ]
0
1
11

MONITOR
1461
196
1590
241
Total Clients
TotalClients
0
1
11

TEXTBOX
75
237
280
265
Less Effective                      More Effective
11
0.0
1

TEXTBOX
424
411
574
429
Date of Accident
11
0.0
1

TEXTBOX
901
412
944
430
3 years
11
0.0
1

TEXTBOX
1429
413
1467
431
6 years
11
0.0
1

TEXTBOX
644
414
794
432
1.5 years
11
0.0
1

TEXTBOX
1169
413
1319
431
4.5 years
11
0.0
1

MONITOR
1045
580
1124
625
HealthStatus
mean [ HealthStatus ] of clients
1
1
11

MONITOR
406
648
503
693
GoodExit6Months
GoodExit6Months
0
1
11

MONITOR
507
649
641
694
GoodExit18Months
GoodExit18Months
0
1
11

MONITOR
643
649
765
694
GoodExit24Months
GoodExit24Months
0
1
11

MONITOR
406
696
510
741
GoodExit36Months
GoodExit36Months
0
1
11

MONITOR
595
745
707
790
Bad Exit 6 Months
BadExit6Months
0
1
11

MONITOR
675
745
765
790
Bottom18Mo
BadExit18Months
0
1
11

MONITOR
644
697
765
742
Bad Exit 24 Mo
BadExit24Months
0
1
11

MONITOR
406
744
494
789
Bad Exit36Mo
BadExit36Months
0
1
11

MONITOR
495
745
584
790
Bad Exit 36+Mo
BadExit36PlusMonths
0
1
11

MONITOR
512
696
642
741
Neutral 36+
NeutralExit36PlusMonths
0
1
11

MONITOR
498
794
579
839
% Bad exit
100 * count clients with [RockBottom = 1] \n/ \n(TotalClients - count clients)
1
1
11

SLIDER
81
588
253
621
Solicitors
Solicitors
0
100
50.0
1
1
NIL
HORIZONTAL

MONITOR
405
794
495
839
CommonLaw#
CommonLawCapture
1
1
11

PLOT
1144
451
1468
639
KPI #2 Cost per client
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [ clientcost ] of clients "

CHOOSER
100
380
239
425
Event_Type
Event_Type
"Negative" "Neutral" "Positive" "Delete"
0

SLIDER
100
434
240
467
Issue_Count
Issue_Count
0
200
75.0
1
1
NIL
HORIZONTAL

BUTTON
110
536
222
569
Reset_Patches
ask patches [ set pcolor black ] 
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
109
498
223
531
Traceclients
Traceclients
0
1
-1000

MONITOR
1323
578
1462
623
Average $ Cost per Client
mean [ clientcost] of clients
0
1
11

PLOT
973
652
1298
798
KPI 3 Average Client Satisfaction
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [ satisfaction ] of clients"

MONITOR
1194
738
1290
783
Mean Satisfaction
mean [ satisfaction ] of clients
2
1
11

@#$#@#$#@
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

person lefty
false
0
Circle -7500403 true true 170 5 80
Polygon -7500403 true true 165 90 180 195 150 285 165 300 195 300 210 225 225 300 255 300 270 285 240 195 255 90
Rectangle -7500403 true true 187 79 232 94
Polygon -7500403 true true 255 90 300 150 285 180 225 105
Polygon -7500403 true true 165 90 120 150 135 180 195 105

person righty
false
0
Circle -7500403 true true 50 5 80
Polygon -7500403 true true 45 90 60 195 30 285 45 300 75 300 90 225 105 300 135 300 150 285 120 195 135 90
Rectangle -7500403 true true 67 79 112 94
Polygon -7500403 true true 135 90 180 150 165 180 105 105
Polygon -7500403 true true 45 90 0 150 15 180 75 105

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
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>count turtles</metric>
    <metric>mean [ EWratio ] of  Runners</metric>
    <metric>Mean [ ACRatio ] of runners</metric>
    <metric>count runners with [ newinjury? = true ] / count runners</metric>
    <metric>mean [ RecentWorkLoad7 ] of runners</metric>
    <metric>max [ RecentWorkload7 ] of runners</metric>
    <metric>min [ RecentWorkload7 ] of runners</metric>
    <enumeratedValueSet variable="EW_ACRatio">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Promotion">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Original">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="DailyRampupRate">
      <value value="1.05"/>
      <value value="1.1"/>
      <value value="1.2"/>
      <value value="1.25"/>
      <value value="1.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Number_of_Events">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Enough">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialRunners">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RandomVariation">
      <value value="0"/>
      <value value="0.01"/>
      <value value="0.025"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InitialHCProfs">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Inspiration">
      <value value="1.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Ceiling_On">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="InjuryRecovery">
      <value value="15"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
