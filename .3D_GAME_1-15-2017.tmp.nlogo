extensions [matrix bitmap]
globals [
  cam-pos cam-rot move-speed sensitivity
  near far focal-length height-width borders
  d
  latest-ray latest-ray-cross
  game-data objects bounds additional-info player-bounds total-data applied-data current-type initial-pos initial-rot initial-scale remaining-enemies
  numbers time ammo
  shot? was-shot?
  pls
  game-state next-game-state paused? highscores editor? normals?
]

patches-own [
  pre-fade-color
]

;Sorts the 3d points based on distance from camera for the painter's algorithm.
to-report sort-3d-points [fa1 fa2]
  let f1 first fa1
  let f2 first fa2

  let k 0

  let f1-x 0
  let f1-y 0
  let f1-z 0

  while [k < length f1] [
    let a-point item k f1
    set f1-x f1-x + item 0 a-point
    set f1-y f1-y + item 1 a-point
    set f1-z f1-z + item 2 a-point
    set k k + 1
  ]

  let x1 f1-x / length f1
  let y1 f1-y / length f1
  let z1 f1-z / length f1

  let f2-x 0
  let f2-y 0
  let f2-z 0

  let h 0

  while [h < length f2] [
    let a-point item h f2
    set f2-x f2-x + item 0 a-point
    set f2-y f2-y + item 1 a-point
    set f2-z f2-z + item 2 a-point
    set h h + 1
  ]

  let x2 f2-x / length f2
  let y2 f2-y / length f2
  let z2 f2-z / length f2

  ;show (word y1 ", " z2)

  ;let dist sqrt (((x2 - x1) ^ 2) + ((y2 - y1) ^ 2) + ((z2 - z1) ^ 2))
  let dist1 sqrt (((x1 - 0) ^ 2) + ((y1 * 2) ^ 2) + ((z1 - 0) ^ 2))
  let dist2 sqrt (((x2 - 0) ^ 2) + ((y2 * 2) ^ 2) + ((z2 - 0) ^ 2))

  if dist1 < dist2 [report true]
  report false
end

;Gets the minimum 2d y point of a set of points for simple scanline.
to-report min-y [some-points]
  let miny max-pycor

  let u 0
  while [u < length some-points] [
    let single-point item u some-points
    if item 1 single-point < miny [set miny item 1 single-point]
    set u u + 1
  ]
  ;show (word "minY: " miny)
  report miny
end

;Gets the maximum 2d y point of a set of points for simple scanline.
to-report max-y [some-points]
  let maxy min-pycor

  let u 0
  while [u < length some-points] [
    let single-point item u some-points
    ;show item 1 single-point
    if item 1 single-point > maxy [set maxy item 1 single-point]
    set u u + 1
  ]
  report maxy
end

;Minimum point of an object for AABB 3D collision.
to-report obj-min [faces axis]
  let i 0

  let min-var 999999999999999

  while [ i < length faces] [
    let a-face item i faces
    let j 0
    while [j < length a-face] [
      let point item j a-face

      if item axis point < min-var [
        set min-var item axis point
      ]

      set j j + 1
    ]
    set i i + 1
  ]
  report min-var
end

;Minimum point of an object for AABB 3D collision.
to-report obj-max [faces axis]
  let i 0

  let max-var -999999999999999

  while [ i < length faces] [
    let a-face item i faces
    let j 0
    while [j < length a-face] [
      let point item j a-face

      if item axis point > max-var [
        set max-var item axis point
      ]

      set j j + 1
    ]
    set i i + 1
  ]
  report max-var
end

to-report screen-height
  report ((max-pycor * 2) + 1)
end

to-report screen-width
  report ((max-pxcor * 2) + 1)
end

to-report min-point
  report (list min-pxcor min-pxcor)
end

to-report max-point
  report (list max-pxcor max-pycor)
end

to-report arctan [x]
  report asin (x / sqrt(1 + x * x))
end

;Gets the next point in the set, useful for clipping and line intersection.
to-report next-point [curr-point-set curr]
  let next curr + 1
  if curr = (length curr-point-set) - 1 [
    set next 0
  ]
  report item next curr-point-set
end

;Gets the previous point in the set, useful for clipping and line intersection.
to-report prev-point [curr-point-set curr]
  let next curr - 1
  if curr = 0 [
    set next length curr-point-set - 1
  ]
  report item next curr-point-set
end

to-report vector-add [v1 v2]
  report (list (item 0  v1 + item 0 v2) (item 1 v1 + item 1 v2) (item 2 v1 + item 2 v2) (item 3 v1 + item 3 v2))
end

to-report vector-subtract [v1 v2]
  report (list (item 0 v1 - item 0 v2) (item 1 v1 - item 1 v2) (item 2 v1 - item 2 v2) (item 3 v1 - item 3 v2))
end

to-report vector-multiplication [v1 v2]
  report (list (item 0 v1 * item 0 v2) (item 1 v1 * item 1 v2) (item 2 v1 * item 2 v2) (item 3 v1 * item 3 v2))
end

;The previous vector reporters are for homogeneous inputs.

to-report vector-add3 [v1 v2]
  report (list (item 0 v1 + item 0 v2) (item 1 v1 + item 1 v2) (item 2 v1 + item 2 v2))
end

to-report vector-subtract3 [v1 v2]
  report (list (item 0 v1 - item 0 v2) (item 1 v1 - item 1 v2) (item 2 v1 - item 2 v2))
end

to-report vector-multiplication3 [v1 v2]
  report (list (item 0 v1 * item 0 v2) (item 1 v1 * item 1 v2) (item 2 v1 * item 2 v2))
end

to-report vector-divide3 [v1 v2]
  report (list (item 0 v1 / item 0 v2) (item 1 v1 / item 1 v2) (item 2 v1 / item 2 v2))
end

to-report vector-cross-product [v1 v2]
  let newx (item 1 v1 * item 2 v2) - (item 2 v1 * item 1 v2)
  let newy (item 2 v1 * item 0 v2) - (item 0 v1 * item 2 v2)
  let newz (item 0 v1 * item 1 v2) - (item 1 v1 * item 0 v2)
  report (list newx newy newz)
end

to-report vector-magnitude [vector]
  report sqrt ((item 0 vector) ^ 2 + (item 1 vector) ^ 2 + (item 2 vector) ^ 2)
end

to-report vector-normalized [vector]
  let magnitude vector-magnitude vector
  if magnitude != 0 [
    report vector-divide3 vector (list magnitude magnitude magnitude)
  ]
  report vector
end

to-report vector-dot-product [v1 v2]
  report (item 0 v1 * item 0 v2) + (item 1 v1 * item 1 v2) + (item 2 v1 * item 2 v2)
end

to-report vector-round [vector]
  report (list ((round (item 0 vector * 1000)) / 1000) ((round (item 1 vector * 1000)) / 1000) ((round (item 2 vector * 1000)) / 1000) )
end

to-report vector-mod3 [v1 v2]
  report (list (item 0 v1 mod item 0 v2) (item 1 v1 mod item 1 v2) (item 2 v1 mod item 2 v2))
end

;report number of points of the player bounds within the total level bounds.
to-report points-in
  let total 0
  let total-points []

  let i 0
  while [i < length bounds] [
    let bound item i bounds

    let points-within containing-individual? player-bounds item 0 bound

    let j 0
    while [j < length points-within] [
      let a-point item j points-within
      set total-points lput a-point total-points

      set j j + 1
    ]
    set i i + 1
  ]
  set total length remove-duplicates total-points
  report total
end

to update-player-bounds
  let player-bound1 vector-add3 cam-pos (list .3 (1.2 - 1) .3)
  let player-bound2 vector-add3 cam-pos (list -.3 (1.2 - 1) .3)
  let player-bound3 vector-add3 cam-pos (list .3 (1.2 - 1) -.3)
  let player-bound4 vector-add3 cam-pos (list -.3 (1.2 - 1) -.3)
  let player-bound5 vector-add3 cam-pos (list -.3 (0 - 1) -.3)
  let player-bound6 vector-add3 cam-pos (list .3 (0 - 1) -.3)
  let player-bound7 vector-add3 cam-pos (list -.3 (0 - 1) .3)
  let player-bound8 vector-add3 cam-pos (list .3 (0 - 1) .3)
  set player-bounds (list (list player-bound1 player-bound2 player-bound3 player-bound4 player-bound5 player-bound6 player-bound7 player-bound8))
end

to move-forward

  let temp-pos cam-pos
  let temp-bounds player-bounds

  let move-over-two move-speed / 2

  let vec-list matrix:to-row-list d
  let vec (list item 0 item 2 vec-list item 1 item 2 vec-list item 2 item 2 vec-list )
  let half (list move-over-two move-over-two move-over-two)
  set cam-pos vector-subtract3 cam-pos (vector-multiplication3 vec half)

  ;Get the new player bounds after this theoretical move
  update-player-bounds

  ;If the move is done when paused or is not valid, set it back to the original values.
  if (points-in < 8 and length bounds > 0) or paused? [
    set cam-pos temp-pos
    set player-bounds temp-bounds
  ]
end

to move-backward

  let temp-pos cam-pos
  let temp-bounds player-bounds

  let move-over-two move-speed / 2

  let vec-list matrix:to-row-list d
  let vec (list item 0 item 2 vec-list item 1 item 2 vec-list item 2 item 2 vec-list )
  let half (list move-over-two move-over-two move-over-two)
  set cam-pos vector-add3 cam-pos (vector-multiplication3 vec half)

  update-player-bounds

  if (points-in < 8 and length bounds > 0) or paused? [
    set cam-pos temp-pos
    set player-bounds temp-bounds
  ]
end

;Debug-type method
to move-up
  let move-over-two move-speed / 2

  set cam-pos replace-item 1 cam-pos ((item 1 cam-pos) + .5)
end

;Debug-type method
to move-down
  let move-over-two move-speed / 2

  set cam-pos replace-item 1 cam-pos ((item 1 cam-pos) - .5)
end

to move-right

  let temp-pos cam-pos
  let temp-bounds player-bounds

  let move-over-two move-speed / 2

  let vec-list matrix:to-row-list d
  let vec (list item 0 item 0 vec-list item 1 item 0 vec-list item 2 item 0 vec-list )
  let half (list move-over-two move-over-two move-over-two)
  set cam-pos vector-add3 cam-pos (vector-multiplication3 vec half)

  update-player-bounds

  if (points-in < 8 and length bounds > 0) or paused? [
    set cam-pos temp-pos
    set player-bounds temp-bounds
  ]
end

to move-left

  let temp-pos cam-pos
  let temp-bounds player-bounds

  let move-over-two move-speed / 2

  let vec-list matrix:to-row-list d
  let vec (list item 0 item 0 vec-list item 1 item 0 vec-list item 2 item 0 vec-list )
  let half (list move-over-two move-over-two move-over-two)
  set cam-pos vector-subtract3 cam-pos (vector-multiplication3 vec half)
  update-player-bounds

  if (points-in < 8 and length bounds > 0) or paused? [
    set cam-pos temp-pos
    set player-bounds temp-bounds
  ]
end

to rotate-right
  if not paused? [
  set cam-rot replace-item 1 cam-rot ((item 1 cam-rot) - sensitivity)
  ]
end

to rotate-left
  if not paused? [
  set cam-rot replace-item 1 cam-rot ((item 1 cam-rot) + sensitivity)
  ]
end

to set-time [value]
  ifelse value > 999 [set time 999]
  [set time value]
end

to-report get-time
  report time
end

to set-ammo [value]
  ifelse value > 99 [ set ammo 99]
  [set ammo value]
end

to-report get-ammo
  report ammo
end

to fire
  if ammo >= 1 and was-shot? = false and editor? = false and not paused?[
    set shot? true
    set ammo ammo - 1

    if latest-ray-cross != -1 [
      let hit-object item (first latest-ray-cross) objects
      if item 6 hit-object = "enemy" [
        set hit-object replace-item 0 hit-object []
        set hit-object replace-item 6 hit-object "none"
        set objects replace-item (first latest-ray-cross) objects hit-object
      ]
    ]
  ]
end

;Normal 3D AABB collision detection between two sets of faces (probably from 2 different objects)
to-report colliding? [faces1 faces2]

  let on-x (obj-min faces1 0 <= obj-max faces2 0) and (obj-max faces1 0 >= obj-min faces2 0)
  let on-y (obj-min faces1 1 <= obj-max faces2 1) and (obj-max faces1 1 >= obj-min faces2 1)
  let on-z (obj-min faces1 2 <= obj-max faces2 2) and (obj-max faces1 2 >= obj-min faces2 2)
  ;show (word "colliding: " (on-x and on-y and on-z))
  report on-x and on-y and on-z
end

;Check if a single point is within a set of faces.
to-report within? [point faces2]
  ;show faces2
  let on-x (item 0 point <= obj-max faces2 0) and (item 0 point >= obj-min faces2 0)
  let on-y (item 1 point <= obj-max faces2 1) and (item 1 point >= obj-min faces2 1)
  let on-z (item 2 point <= obj-max faces2 2) and (item 2 point >= obj-min faces2 2)
  report on-x and on-y and on-z
end

;Check each point the first set of faces within the second.
to-report containing-individual? [faces1 faces2]
  let total 0
  let i 0

  let report-points []

  ;show (word "faces: " faces1)
  while [i < length faces1] [
    let a-face item i faces1
    let j 0
    while [ j < length a-face] [
      let point item j a-face

      ;show (word "point: " within? point faces2)

      if within? point faces2 = true [
        set total total + 1
        set report-points lput point report-points
      ]
      set j j + 1
    ]

    set i i + 1
  ]
  report report-points
end

to return-to-main-menu
  set next-game-state "menu"
end

to setup
  ca
  file-close-all
  reset-ticks

  set pls false

  set move-speed 1.25
  set sensitivity 7.5

  set objects []
  set bounds []
  set player-bounds []
  set additional-info (list (list 0 1 0) (list 0 90 0) 99 0 0)

  let polys []
  let lines []

  ;set mouse-previously-down? false

  ;let corners (list (list min-pxcor max-pycor) (list max-pxcor max-pycor) (list min-pxcor min-pycor) (list max-pxcor min-pycor))
  let corners (list (list min-pxcor max-pycor) (list max-pxcor max-pycor) (list min-pxcor (min-pycor + 25)) (list max-pxcor (min-pycor + 25)))
  ;show corners
  set borders (list (list item 1 corners item 0 corners) (list item 0 corners item 2 corners) (list item 2 corners item 3 corners) (list item 3 corners item 1 corners))

  set cam-pos (list 0 1 0)
  set cam-rot (list 0 90 0)

  ;let view-z 1 / (tan ((pi / 2) / 2))
  ;set view-position (list 0 0 view-z)

  set near .00001
  set far 1000

  ;let fov pi / 2

  ;I don't think this is how it's supposed to work, but it seems to work ???
  let fov pi / (max-pxcor / 50)
  set focal-length 1 / (tan (fov / 2))
  ;set height-width screen-height / screen-width
  ;set height-width screen-width / screen-height
  set height-width 1

  set numbers []
  set numbers lput (bitmap:import "0.png") numbers
  set numbers lput (bitmap:import "1.png") numbers
  set numbers lput (bitmap:import "2.png") numbers
  set numbers lput (bitmap:import "3.png") numbers
  set numbers lput (bitmap:import "4.png") numbers
  set numbers lput (bitmap:import "5.png") numbers
  set numbers lput (bitmap:import "6.png") numbers
  set numbers lput (bitmap:import "7.png") numbers
  set numbers lput (bitmap:import "8.png") numbers
  set numbers lput (bitmap:import "9.png") numbers

  set-time 0
  set-ammo 12

  let rotx (- item 0 cam-rot)
  let roty (- item 1 cam-rot)
  let rotz (- item 2 cam-rot)

  let rotate-z-matrix matrix:from-row-list (list
    (list (cos rotz) (- (sin rotz)) 0 0)
    (list (sin rotz) (cos rotz) 0 0)
    (list 0 0 1 0)
    (list 0 0 0 1)
    )
  let rotate-y-matrix matrix:from-row-list (list
    (list (cos roty) 0 (sin roty) 0)
    (list 0 1 0 0)
    (list (- (sin roty)) 0 (cos roty) 0)
    (list 0 0 0 1)
    )
  let rotate-x-matrix matrix:from-row-list (list
    (list 1 0 0 0)
    (list 0 (cos rotx) (- (sin rotx)) 0)
    (list 0 (sin rotx) (cos rotx) 0)
    (list 0 0 0 1)
    )
  set d rotate-z-matrix matrix:* rotate-y-matrix matrix:* rotate-x-matrix
  ; d is the direction vector of the camera

  set shot? false

  set initial-pos [0 0 0]
  set initial-rot [0 0 0]
  set initial-scale [1 1 1]
  set current-type "default"

  set remaining-enemies 0

  set game-state "menu"
  set next-game-state "menu"
  set paused? false

  ;set game-data (list (n-values 10 [""]))

  load-game-data
  set editor? false
  set normals? true
end

to load-game-data
  ifelse file-exists? "game-data" [
    file-open "game-data"
    set game-data read-from-string file-read-line
    file-close
  ] [
    set game-data (list (n-values 10 [-1]))
    file-open "game-data"
    file-print game-data
    file-close
  ]
end

to save-game-data
  ifelse file-exists? "game-data" [
    file-delete "game-data"
    file-open "game-data"
    file-print game-data
    file-close
  ] [
    file-open "game-data"
    file-print game-data
    file-close
  ]
end

to-report min-x-2d [a-face]
  let min-x2d 999999999999999
  let i 0
  while [i < length a-face] [
    let a-point item i a-face
    if item 0 a-point < min-x2d [ set min-x2d item 0 a-point]
    set i i + 1
  ]
  report min-x2d
end
to-report min-y-2d [a-face]
  let min-y2d 999999999999999
  let i 0
  while [i < length a-face] [
    let a-point item i a-face
    if item 1 a-point < min-y2d [ set min-y2d item 1 a-point]
    set i i + 1
  ]
  report min-y2d
end

to-report max-x-2d [a-face]
  let max-x2d -999999999999999
  let i 0
  while [i < length a-face] [
    let a-point item i a-face
    if item 0 a-point > max-x2d [ set max-x2d item 0 a-point]
    set i i + 1
  ]
  report max-x2d
end
to-report max-y-2d [a-face]
  let max-y2d -999999999999999
  let i 0
  while [i < length a-face] [
    let a-point item i a-face
    if item 1 a-point > max-y2d [ set max-y2d item 1 a-point]
    set i i + 1
  ]
  report max-y2d
end

;2D collision between a point and a face for the menu
to-report colliding-2d? [point a-face]
  let px item 0 point
  let py item 1 point
  ;show (word min-x-2d a-face ", " max-x-2d a-face)
  report px >= min-x-2d a-face and px <= max-x-2d a-face and py >= min-y-2d a-face and py <= max-y-2d a-face
end

to pause
  set paused? not paused?
end

to draw-menu

  let selected -1

  let i 0
  while [ i < 10] [
    let y 90 - (i * 20)
    ask patch -40 y [
      let y-temp y + 5
      if colliding-2d? (list mouse-xcor mouse-ycor) (list (list -38 y-temp) (list -73 y-temp) (list -73 (y-temp - 10)) (list -38 (y-temp - 10))) [
        set selected i
        ;show selected
        ask patches with [pxcor <= -38 and pxcor >= -73 and pycor <= y-temp and pycor >= (y-temp - 10)] [ set pcolor red]
        ;set pcolor white
      ]
      ifelse i < 9 [
        set plabel (word "Stage: " (i + 1))
      ] [
        set plabel (word "Custom Lvl")
      ]
    ]

    ask patch 25 y [
      let score item i item 0 game-data
      if i < 9 [
        ifelse score = -1 [
          set plabel (word "Highscore: " "N/A" " sec")
        ] [
          set plabel (word "Highscore: " score " sec")
        ]
      ]
    ]
    set i i + 1
  ]

  if mouse-down? and mouse-inside? and selected != -1 [
    set additional-info []
    set objects []
    set bounds []

    ifelse selected < 9 [

      import-scene (word "maps/stage" selected "final")

      set next-game-state "game"
    ] [
      if import-scene-helper-bool != false [
        set next-game-state "game"
      ]
    ]

  ]
end

to reset-highscores
  let reset? user-input "Do you really want to clear the highscores? (y/n)"
  if member? reset? "yes" [
    set game-data (list (n-values 10 [-1]))
    save-game-data
  ]
end

to run-loop
  let prev-game-state game-state
  set game-state next-game-state

  if game-state != "game" [
    set paused? false
  ]

  if game-state = "menu" [
    reset-pixels
    draw-menu
    set time 0
  ]

  if game-state = "game" [

    if game-state = "game" and prev-game-state != "game" [
      load-game-data
    ]

    let new-object-list apply-transforms

    combine-data new-object-list

    calc-collisions new-object-list
    reset-pixels
    render-ui
    render-3d

  ]

  if game-state = "over" and prev-game-state != "over" [
    lose-sequence
  ]

  if game-state = "win" and prev-game-state != "win" [
    win-sequence
  ]

  if editor? = true [
    set next-game-state "game"
  ]
  tick
end

to lose-sequence
  ask patches [
      carefully [
        set pre-fade-color approximate-rgb item 0 pcolor item 1 pcolor item 2 pcolor
      ]
      [
        set pre-fade-color pcolor
      ]
    ]
    ask patches [
      set pcolor pre-fade-color
    ]
    fade-out .5

    reset-pixels

    import-pcolors "game-over-image.png"

    ask patches [
      set pre-fade-color pcolor
    ]
    fade-in .5

    wait 3

    fade-out .5

    set next-game-state "menu"
end

to win-sequence
  ask patches [
      carefully [
        set pre-fade-color approximate-rgb item 0 pcolor item 1 pcolor item 2 pcolor
      ]
      [
        set pre-fade-color pcolor
      ]
    ]
    ask patches [
      set pcolor pre-fade-color
    ]
    fade-out .5

    reset-pixels

    import-pcolors "win-image.png"

    ask patches [
      set pre-fade-color pcolor
    ]

    ask patch 20 -50 [
      set plabel (word "Time: " time " sec")
      set plabel-color red
    ]

    fade-in .5

    wait 3

    fade-out .5

    let level item 2 additional-info
    let scores item 0 game-data

    if (level - 1) < length scores [

      let score item (level - 1) scores
      if time < score or score = -1 [
        set scores replace-item (level - 1) scores time
      ]
    ]

    set game-data replace-item 0 game-data scores

    save-game-data

    set next-game-state "menu"
end

;Distance from the current shade of the color to that shade's black.
to-report dist-color
  report pre-fade-color mod 10
end

to fade-out [fade-rate]
  let curr-time timer
  while [timer - curr-time <= fade-rate] [
    ask patches [
      let diff ((timer - curr-time) / fade-rate)
      if diff > 1 [set diff 1]
      set pcolor pre-fade-color - (dist-color * diff)
    ]
    tick
  ]
end

to fade-in [fade-rate]
  ask patches [set pcolor black]
  let curr-time timer
  while [timer - curr-time <= fade-rate] [
    ask patches [
      let diff ((timer - curr-time) / fade-rate)
      if diff > 1 [set diff 1]
      set pcolor (pre-fade-color - dist-color) + (dist-color * diff)
    ]
    tick
  ]
  ask patches [
    set pcolor pre-fade-color
  ]
end

;Apply each objects own position, rotation, and scale tranformation.
to-report apply-transforms

  let new-objects []

  let i 0
  while [ i < length objects] [
    let object item i objects

    let pos-offset item 3 object
    let rot-offset item 4 object
    let scale-offset item 5 object

    let j 0
    let faces item 0 object
    while [ j < length faces] [
      let a-face item j faces
      let k 0
      while [ k < length a-face] [
        let vertex item k a-face

        let vertex-matrix matrix:from-row-list (list
          (list item 0 vertex)
          (list item 1 vertex)
          (list item 2 vertex)
          (list 1)
          )
        let translate-matrix matrix:from-row-list (list
          (list 1 0 0 item 0 pos-offset)
          (list 0 1 0 item 1 pos-offset)
          (list 0 0 1 item 2 pos-offset)
          (list 0 0 0 1)
          )
        let rotate-z-matrix matrix:from-row-list (list
          (list (cos item 2 rot-offset) (- (sin item 2 rot-offset)) 0 0)
          (list (sin item 2 rot-offset) (cos item 2 rot-offset) 0 0)
          (list 0 0 1 0)
          (list 0 0 0 1)
          )
        let rotate-y-matrix matrix:from-row-list (list
          (list (cos item 1 rot-offset) 0 (sin item 1 rot-offset) 0)
          (list 0 1 0 0)
          (list (- (sin item 1 rot-offset)) 0 (cos item 1 rot-offset) 0)
          (list 0 0 0 1)
          )
        let rotate-x-matrix matrix:from-row-list (list
          (list 1 0 0 0)
          (list 0 (cos item 0 rot-offset) (- (sin item 0 rot-offset)) 0)
          (list 0 (sin item 0 rot-offset) (cos item 0 rot-offset) 0)
          (list 0 0 0 1)
          )
        let scale-matrix matrix:from-row-list (list
          (list (item 0 scale-offset) 0 0 0)
          (list 0 (item 1 scale-offset) 0 0)
          (list 0 0 (item 2 scale-offset) 0)
          (list 0 0 0 1)
          )
        ;let homo-point-translated rotate-x-matrix matrix:* rotate-y-matrix matrix:* rotate-z-matrix matrix:* translate-matrix matrix:* homo-point
        let homo-point-applied translate-matrix matrix:* rotate-x-matrix matrix:* rotate-y-matrix matrix:* rotate-z-matrix matrix:* scale-matrix matrix:* vertex-matrix
        ;let homo-point-applied rotate-x-matrix matrix:* rotate-y-matrix matrix:* rotate-z-matrix matrix:* translate-matrix matrix:* scale-matrix matrix:* vertex-matrix
        let homo-point-applied-list matrix:to-row-list homo-point-applied
        let applied-point (list item 0 item 0 homo-point-applied-list item 0 item 1 homo-point-applied-list item 0 item 2 homo-point-applied-list)

        set a-face replace-item k a-face applied-point

        set k k + 1
      ]
      set faces replace-item j faces a-face
      set j j + 1
    ]
    set object replace-item 0 object faces
    set new-objects lput object new-objects
    set i i + 1
  ]
  report new-objects
end

to calc-collisions [object-list]

  let ammo-packs []
  let enemies []

  update-player-bounds

  set remaining-enemies 0

  let i 0
  while [ i < length objects] [
    let object item i objects
    if item 6 object = "ammopack" [
      set ammo-packs lput i ammo-packs
      set object replace-item 4 object cam-rot
    ]
    if item 6 object = "enemy" [
      set enemies lput i enemies
      set remaining-enemies remaining-enemies + 1
    ]
    set objects replace-item i objects object
    set i i + 1
  ]

  if editor? = false and not paused?[

    every 1 [
      if length enemies > 0 [
        set-time get-time + 1
      ]
    ]

    if ammo = 0 and length ammo-packs = 0 [
      set next-game-state "over"
    ]

    if length enemies = 0 [
      set next-game-state "win"
    ]

    let k 0
    while [ k < length ammo-packs] [
      let obj-id item k ammo-packs
      let ammo-obj item obj-id object-list
      let ammo-polys item 0 ammo-obj

      if colliding? player-bounds ammo-polys = true [
          set-ammo get-ammo + (item 4 additional-info)
          set ammo-obj replace-item 0 ammo-obj []
          set ammo-obj replace-item 6 ammo-obj "none"
          set objects replace-item obj-id objects ammo-obj
      ]

      set k k + 1
    ]
  ]

end

;Combine all objects into a single list for easier rendering and sorting.
to combine-data [object-list]
  set total-data []
  let total-polys []
  let total-colors []
  let total-obj-ids []
  let total-pos []
  let total-rot []
  let total-scale []
  let total-types []

  let spaghetti 0
  while [spaghetti < length object-list] [
    let object item spaghetti object-list

    let obj-polys item 0 object
    let colors item 1 object
    let obj-id item 2 object
    let obj-pos item 3 object
    let obj-rots item 4 object
    let obj-scales item 5 object
    let obj-types item 6 object

    ;set total-data lput (list obj-polys colors obj-id) total-data

    let arms 0
    while [arms < length obj-polys] [
      let a-poly item arms obj-polys
      set total-polys lput a-poly total-polys

      set total-obj-ids lput obj-id total-obj-ids

      let a-color item arms colors
      set total-colors lput a-color total-colors

      set arms arms + 1
    ]

    set total-pos lput obj-pos total-pos
    set total-rot lput obj-rots total-rot
    set total-scale lput obj-scales total-scale
    set total-types lput obj-types total-types

    set spaghetti spaghetti + 1
  ]

  set total-data (list total-polys total-colors total-obj-ids total-pos total-rot total-scale total-types)
end

to reset-pixels
  cp
  cd
end

to render-3d
  let vec-list matrix:to-row-list d
  let vec (list item 0 item 0 vec-list item 0 item 1 vec-list item 0 item 2 vec-list )
  set cam-rot vector-mod3 cam-rot (list 360 360 360)

  let total-polys item 0 total-data
  let total-colors item 1 total-data
  let total-obj-ids item 2 total-data
  let total-types item 6 total-data

  let new-order sort-polys-depth total-polys
  let new-2d-order []

  set latest-ray -1
  set latest-ray-cross -1

  let c 0

  while [c < length new-order]
  [
    let points first item c new-order
    let id last item c new-order

    let unedit-points item id total-polys

    let facing? calc-facing unedit-points

     ;if facing? != "" [
    if (facing? >= 0) or (not normals?) [

    ; convert 3d points to homogeneous
    let draw-points convert-3d-to-homogeneous points

    ;  convert homogeneous to clipped
    let new-points convert-homogeneous-to-clipped draw-points

    ;set new-points remove-duplicates new-points

    ; convert clipped to 2d
    let new-2d-points convert-clipped-to-2d new-points

    let ray []

    let ray-cross []

    let frame-time3 timer

    if editor? = true [
      set ray find-inside new-2d-points (list mouse-xcor mouse-ycor)
    ]

    set ray-cross find-inside new-2d-points (list 0 0)

    if ray != false [
      if latest-ray = -1 [
      set latest-ray (list (item id total-obj-ids) id)
      ]
    ]

    if ray-cross != false [
      if latest-ray-cross = -1 [
      set latest-ray-cross (list (item id total-obj-ids) id)
      ]
    ]

    let frame-time4 timer

    ;clip off the points at the edges
    set new-2d-points sutherland borders new-2d-points

    ;add the processed 2d points to a new list for them for line and face rendering
    set new-2d-order lput (list new-2d-points id) new-2d-order
    ]

    set c c + 1
  ]

  ;draw the lines and faces
  draw-lines-faces total-obj-ids new-2d-order total-colors
end

to-report calc-facing [unedit-points]
  let i 0

  let average-vertex [0 0 0]

  while [ i < length unedit-points] [
    let vertex item i unedit-points

    ;show vertex

    set average-vertex vector-add3 average-vertex vertex

    set i i + 1
  ]

  if length unedit-points > 0 [
    set average-vertex vector-divide3 average-vertex (list length unedit-points length unedit-points length unedit-points)

    ;show (word "average: " average-vertex)

    let vec1 vector-subtract3 item 1 unedit-points item 0 unedit-points
    let vec2 vector-subtract3 item 2 unedit-points item 1 unedit-points

    let normal-vec vector-cross-product vec1 vec2

    set normal-vec vector-round normal-vec

    ;show normal-vec

    let invert-vertex vector-subtract3 [0 0 0] average-vertex

    ;let facing? vector-dot-product (normal-vec) (vector-subtract3 cam-pos average-vertex)
    report vector-dot-product (normal-vec) (vector-subtract3 cam-pos average-vertex)
  ]
  report -1
end

to render-ui

  import-pcolors-rgb "bottom-bar10.png"
  set was-shot? shot?
  if editor? = false [
    ifelse shot? = true [set shot? false import-pcolors-rgb "gun-shot-overlay.png"]
    [import-pcolors-rgb "gun-overlay.png"]
  ]

  let time-ones time mod 10
  let time-tens (floor (time / 10)) mod 10
  let time-hundreds floor (time / 100)

  draw-number-scaled item time-hundreds numbers 48 -83 35 35
  draw-number-scaled item time-tens numbers 56.5 -83 35 35
  draw-number-scaled item time-ones numbers 65 -83 35 35

  let ammo-ones ammo mod 10
  let ammo-tens floor (ammo / 10)

  draw-number-scaled item ammo-tens numbers -12.5 -83 35 35
  draw-number-scaled item ammo-ones numbers -4 -83 35 35

  let enemy-ones remaining-enemies mod 10
  let enemy-tens floor (remaining-enemies / 10)

  draw-number-scaled item enemy-tens numbers -55.5 -83 35 35
  draw-number-scaled item enemy-ones numbers -47 -83 35 35

  let level item 2 additional-info
  ;show additional-info

  let level-ones level mod 10
  let level-tens floor (level / 10)

  draw-number-scaled item level-tens numbers -94.5 -83 35 35
  draw-number-scaled item level-ones numbers -86 -83 35 35

  if paused? [
    import-pcolors-rgb "paused2.png"
  ]
end

to draw-number-scaled [pic x y w h]
  let image-scaled bitmap:scaled pic w h
  set image-scaled pic
  bitmap:copy-to-drawing image-scaled (x + max-pxcor) * patch-size ((- y) + max-pycor) * patch-size
end

to-report import-scene-helper-bool
  let f user-file
  if f != false [
    import-scene f
  ]
  report f
end

to import-scene [f]
  let imported-objects []
  let imported-bounds []
  let imported-info []

    file-open f

    set imported-objects read-from-string file-read-line
    set imported-bounds read-from-string file-read-line
    set imported-info read-from-string file-read-line

    file-close

  let i 0
  while [i < length imported-objects] [
    let imported-object item i imported-objects
    let obj-id item 2 imported-object

    let obj-type item 6 imported-object

    set obj-id length objects
    set imported-object replace-item 2 imported-object obj-id
    ;set imported-object replace-item 6 imported-object obj-type
    set objects lput imported-object objects
    set i i + 1
  ]

  let j 0
  while [j < length imported-bounds] [
    let imported-bound item j imported-bounds
    let obj-id item 1 imported-bound
    set obj-id length bounds
    set imported-bound replace-item 1 imported-bound obj-id
    set bounds lput imported-bound bounds
    set j j + 1
  ]

  if length imported-info > 0 [

    set additional-info imported-info
    set cam-pos item 0 additional-info
    set cam-rot item 1 additional-info
    set ammo item 3 additional-info
  ]
end

to-report sort-polys-depth [poly-list]
  let ordered-polys []
  let z 0
  while [z < length poly-list] [
    let points item z poly-list
    let draw-points-first convert-poly-to-3d points
    set ordered-polys lput (list draw-points-first z) ordered-polys
    set z z + 1
  ]

  ;sort the 3d points by depth
  set ordered-polys sort-by sort-3d-points ordered-polys

  report ordered-polys
end

to-report convert-poly-to-3d [points]
  let three-d-points []
  let i 0
  while [i < length points] [

    let reg-homo get-homo-points item i points
    let reg-list matrix:to-row-list reg-homo
    let reg-list3 (list item 0 item 0 reg-list item 0 item 1 reg-list item 0 item 2 reg-list)
    set three-d-points lput reg-list3 three-d-points

    set i i + 1
  ]
  report three-d-points
end

to-report convert-3d-to-homogeneous [three-d-points]
  let homogeneous-points []
  let ba 0
  while [ba < length three-d-points] [
    let norm-point item ba three-d-points
    let norm-point-matrix matrix:from-row-list (list
      (list item 0 norm-point)
      (list item 1 norm-point)
      (list item 2 norm-point)
      (list 1)
    )

    set homogeneous-points lput get-projection-points norm-point-matrix homogeneous-points
    set ba ba + 1
  ]
  report homogeneous-points
end

to-report convert-homogeneous-to-clipped [homogeneous-points]

  let clipped-points []

  let q 0
  while [q < length homogeneous-points]
  [
    let current-point-matrix item q homogeneous-points
    let point-to-matrix (next-point homogeneous-points q)

    let before-point-matrix (prev-point homogeneous-points q)
    ;print matrix:pretty-print-text point-to-matrix

    let current-point-list matrix:to-row-list current-point-matrix
    let point-to-list matrix:to-row-list point-to-matrix
    let before-point-list matrix:to-row-list before-point-matrix

    let x1 item 0 item 0 current-point-list
    let y1 item 0 item 1 current-point-list
    let z1 item 0 item 2 current-point-list
    let w1 item 0 item 3 current-point-list

    let x2 item 0 item 0 point-to-list
    let y2 item 0 item 1 point-to-list
    let z2 item 0 item 2 point-to-list
    let w2 item 0 item 3 point-to-list

    let x3 item 0 item 0 before-point-list
    let y3 item 0 item 1 before-point-list
    let z3 item 0 item 2 before-point-list
    let w3 item 0 item 3 before-point-list

    let current-point-vector (list x1 y1 z1 w1)
    let point-to-vector (list x2 y2 z2 w2)
    let before-point-vector (list x3 y3 z3 w3)


    if (min (list z1 z2) < near and max (list z1 z2) > near) [
      let delta vector-subtract current-point-vector point-to-vector
      let diff item 3 delta
      let percent (near - w1) / diff
      let percent-vector (list percent percent percent percent)
      let intersection vector-add current-point-vector (vector-multiplication percent-vector delta )

      ;invert z
      set intersection replace-item 2 intersection (- (item 2 intersection))
      set clipped-points lput intersection clipped-points
    ]
    ifelse w1 >= near and w2 >= near
      [
        set clipped-points lput current-point-vector clipped-points
        set clipped-points lput point-to-vector clipped-points
    ]
    [
      if w1 >= near and w2 < near and w3 < near [
        ;print "one"
        set clipped-points lput current-point-vector clipped-points
      ]
    ]

    set q q + 1
  ]
  report clipped-points
end

to-report convert-clipped-to-2d [clipped-points]
  let converted []
  let u 0
  while [u < length clipped-points]
  [

    let three-d-point item u clipped-points
    ;show three-d-point
    let two-d-point get-projected-point three-d-point
    set converted lput two-d-point converted
    set u u + 1
  ]
  report converted
end

to draw-lines-faces [all-object-ids the-2d-order draw-colors]

  ;set frame-time7 timer
  let y 0
  while [y < length the-2d-order] [

    ;draw the lines between the points

    let the-2d-points first (item y the-2d-order)
    let id last (item y the-2d-order)

    let h 0
    while [h < length the-2d-points]
    [
      ask patch (item 0 item h the-2d-points) (item 1 item h the-2d-points) [
        sprout 1 [
          let point-to (next-point the-2d-points h)
          facexy item 0 point-to item 1 point-to
          let dist distancexy item 0 point-to item 1 point-to
          let traveled 0
          while [traveled < dist]
          [
            if pcolor = 0 [
            ;ask patches in-radius 1.5 [set pcolor white]
              set pcolor white
            ]
            ;set pcolor white
            fd 1
            set traveled traveled + 1
          ]
          die
        ]
      ]
      set h h + 1
    ]

    ;fill faces
    filler (item id all-object-ids) id the-2d-points draw-colors

    set y y + 1
  ]
end

to draw-crosshair
  ask patch -1 0 [ set pcolor yellow - .7]
  ask patch 1 0 [ set pcolor yellow - .7]
  ask patch 0 -1 [ set pcolor yellow - .7]
  ask patch 0 1 [ set pcolor yellow - .7]
end

to filler [obj-id index points draw-colors]
  if length points > 2 [

    let max-y-point max-y points
    let initial-scan-line min-y points

    let scan-line initial-scan-line

    let intersections []

    while [scan-line < max-y-point] [

      set intersections []

      let n 0
      while [ n < length points ]
      [
        let current-point item n points
        let point-to (next-point points n)
        let intersection find-intersecting (list current-point point-to) scan-line
        ;show (word "wop: " intersection)
        if intersection != -1 [
          ;show "wtf"
          set intersections lput intersection intersections
        ]
        set n n + 1
      ]

      set intersections sutherland borders intersections

      let h 0
      while [h < length intersections] [
        if length intersections mod 2 = 1 [set intersections lput (item h intersections) intersections]
        let p1 item h intersections
        let p2 item (h + 1) intersections

        ;show (list item 0 p1 item 1 p1)

        ask patch item 0 p1 item 1 p1 [
          sprout 1 [
            facexy item 0 p2 item 1 p2
            let dist distancexy item 0 p2 item 1 p2
            let traveled 0

            let chosen-color (item index draw-colors)
            let smooth-color chosen-color + ((scan-line - 15) / 25) + .5
            if smooth-color < chosen-color - (chosen-color mod 10) [set smooth-color chosen-color - (chosen-color mod 10) + 0.05]
            if smooth-color > chosen-color - (chosen-color mod 10) + 9.9 [set smooth-color chosen-color - (chosen-color mod 10) + 9.9]

            while [traveled < dist]
            [
              ;if traveled >= 1 [
              if pcolor = 0 [
                set pcolor smooth-color
                ;set pcolor [255 255 0 127]
              ]
              ;]
              fd 1
              set traveled traveled + 1
            ]
            die
          ]
        ]

        set h h + 2
      ]

      set scan-line scan-line + 1
    ]
  ]
end

to-report get-homo-points [point]

  ;let homo-cam matrix:from-row-list (list (list item 0 cam-rot) (list item 1 cam-rot) (list item 2 cam-rot) (list 1))

  let movex (- item 0 cam-pos)
  let movey (- item 1 cam-pos)
  let movez (- item 2 cam-pos)

  let rotx (- item 0 cam-rot)
  let roty (- item 1 cam-rot)
  let rotz (- item 2 cam-rot)

  let homo-point matrix:from-row-list (list (list item 0 point) (list item 1 point) (list item 2 point) (list 1))
  let translate-matrix matrix:from-row-list (list
    (list 1 0 0 movex)
    (list 0 1 0 movey)
    (list 0 0 1 movez)
    (list 0 0 0 1)
  )
  let rotate-z-matrix matrix:from-row-list (list
    (list (cos rotz) (- (sin rotz)) 0 0)
    (list (sin rotz) (cos rotz) 0 0)
    (list 0 0 1 0)
    (list 0 0 0 1)
  )
  let rotate-y-matrix matrix:from-row-list (list
    (list (cos roty) 0 (sin roty) 0)
    (list 0 1 0 0)
    (list (- (sin roty)) 0 (cos roty) 0)
    (list 0 0 0 1)
  )
  let rotate-x-matrix matrix:from-row-list (list
    (list 1 0 0 0)
    (list 0 (cos rotx) (- (sin rotx)) 0)
    (list 0 (sin rotx) (cos rotx) 0)
    (list 0 0 0 1)
  )
  let homo-point-translated rotate-x-matrix matrix:* rotate-y-matrix matrix:* rotate-z-matrix matrix:* translate-matrix matrix:* homo-point
  set d rotate-z-matrix matrix:* rotate-y-matrix matrix:* rotate-x-matrix

  report homo-point-translated
end

to-report get-projection-points [homo-point-translate]
  let projection-matrix matrix:from-row-list (list
    (list focal-length 0 0 0)
    (list 0 (focal-length / height-width) 0 0)
    (list 0 0 (- ((far + near) / (far - near))) (- ((2 * far * near) / (far - near))) )
    (list 0 0 -1 0)
  )

  let fov1 (arctan (1 / matrix:get projection-matrix 1 1)) * 2 * (360 / (pi * 2))

  let homo-clip projection-matrix matrix:* homo-point-translate

  report homo-clip
end

to-report get-projected-point [homo-clip-point]
  ;show homo-clip-point
  let x1 item 0 homo-clip-point / ( (item 3 homo-clip-point))
  let y1 item 1 homo-clip-point / ( (item 3 homo-clip-point))
  let z1 item 2 homo-clip-point / ( (item 3 homo-clip-point))

  report (list (x1 / z1) (y1 / z1))
end

;Code adapated from Wikipedia's Pseudo Code
;https://en.wikipedia.org/wiki/Sutherland%E2%80%93Hodgman_algorithm
;START
to-report sutherland [clip-poly subject-poly]
  let output-list subject-poly
  let i 0
  while [i < length clip-poly]
  [
    let clip-edge item i clip-poly
    let input-list output-list
    set output-list []
    if not empty? input-list [
      let point-s last input-list
      let j 0
      while [j < length input-list]
      [
        let point-e item j input-list
        ifelse inside? point-e clip-edge [
          if not inside? point-s clip-edge [
            set output-list lput (compute-intersection point-s point-e item 0 clip-edge item 1 clip-edge false) output-list
          ]
          set output-list lput point-e output-list
        ]
        [
          if inside? point-s clip-edge [
            set output-list lput (compute-intersection point-s point-e item 0 clip-edge item 1 clip-edge false) output-list
          ]
        ]
        set point-s point-e
        set j j + 1
      ]
    ]
    set i i + 1
  ]

  report output-list
end
;END

;Necessary to see if a point is "inside" and edge for the Sutherland-Hodgman algorithm. I forgot where I got the formula from.
to-report inside? [a-point an-edge]
  let bool false
  let x item 0 a-point
  let y item 1 a-point
  let x1 item 0 item 0 an-edge
  let y1 item 1 item 0 an-edge
  let x2 item 0 item 1 an-edge
  let y2 item 1 item 1 an-edge
  let p ((x2 - x1) * (y - y1) - (y2 - y1) * (x - x1))
  if p > 0 [set bool true]
  report bool
end

to-report get-eq [pt1 pt2]
  let slope 0
  ifelse (item 0 pt2 - item 0 pt1 ) = 0 [set slope 999999999]
  [set slope (item 1 pt2 - item 1 pt1) / (item 0 pt2 - item 0 pt1)]
  let offset (item 1 pt2) - (slope * item 0 pt2)

  report (list (0 - slope) 1 offset)
end

;Uses built in matrix reporter to get the intersection of two lines, likely for clipping of sorts.
to-report compute-intersection [pt1 pt2 pt3 pt4 round?]

  let eq1 get-eq pt1 pt2
  let eq2 get-eq pt3 pt4

  let A matrix:from-row-list (list (list item 0 eq1 item 1 eq1) (list item 0 eq2 item 1 eq2))
  let C matrix:from-row-list (list (list item 2 eq1) (list item 2 eq2))
  let fin (list (list 0) (list 0))
  let intersect? false
  let determinant (item 0 eq1 * item 1 eq2) - (item 1 eq1 * item 0 eq2)

  if determinant != 0 [
    set intersect? true
    set fin matrix:to-row-list (matrix:solve A C)
  ]

  ifelse round? [
    set fin (list (round item 0 item 0 fin) (round item 0 item 1 fin))
  ]
  [
    set fin (list (item 0 item 0 fin) (item 0 item 1 fin))
  ]

  report fin
end

; report intersections between a scanline and the lines it intersections
to-report find-intersecting [line-points scan-pos]

  let point1 item 0 line-points
  let point2 item 1 line-points

  let x1 item 0 point1
  let y1 item 1 point1

  let x2 item 0 point2
  let y2 item 1 point2

  if (y1 != y2) [
    if (min (list y1 y2) <= scan-pos and max (list y1 y2) >= scan-pos) [
      let intersection compute-intersection point1 point2 (list min-pxcor scan-pos) (list max-pxcor scan-pos) false
      report intersection
    ]
  ]
  report -1
end

;Used for 2D raycasting
to-report find-inside [poly-points chosen-point]
  let values []

  let final-val 0

  let r 0
  while [r < length poly-points] [
    let current-point item r poly-points
    let point-to (next-point poly-points r)

    let val 0
    ifelse item 1 current-point > item 1 point-to [set val -1] [set val 1]

    set values lput val values
    set val (val * -1)
    set r r + 1
  ]
  let u 0
  while [u < length poly-points]
  [
    let current-point item u poly-points
    let point-to (next-point poly-points u)
    if (find-intersecting-bool (list current-point point-to) chosen-point) = true [
      set final-val final-val + item u values
      ;show (word "hi: " u)
    ]
    set u u + 1
  ]

  ;show final-val
  ifelse final-val != 0 [report true] [report false]
end

;Report true if any intersection found to the left of a point.
to-report find-intersecting-bool [line-points chosen-point]

  let scan-pos item 1 chosen-point

  let point1 item 0 line-points
  let point2 item 1 line-points

  let x1 item 0 point1
  let y1 item 1 point1

  let x2 item 0 point2
  let y2 item 1 point2

  if (y1 != y2) [
    if (min (list y1 y2) <= scan-pos and max (list y1 y2) >= scan-pos) [
      let intersection compute-intersection point1 point2 (list min-pxcor scan-pos) (list max-pxcor scan-pos) false
      ;show (word "inter: " intersection)
      if (item 0 intersection <= item 0 chosen-point) [
        ;show intersection
        report true
      ]
    ]
  ]
  report false
end
@#$#@#$#@
GRAPHICS-WINDOW
249
10
860
622
-1
-1
3.0
1
20
1
1
1
0
0
0
1
-100
100
-100
100
1
1
1
ticks
60.0

BUTTON
26
27
89
60
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

BUTTON
102
26
180
59
NIL
run-loop\n
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
73
83
148
116
Forward
move-forward
NIL
1
T
OBSERVER
NIL
W
NIL
NIL
1

BUTTON
71
150
146
183
Backward
move-backward
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
6
115
72
148
Left
move-left
NIL
1
T
OBSERVER
NIL
A
NIL
NIL
1

BUTTON
147
118
217
151
Right
move-right\n
NIL
1
T
OBSERVER
NIL
D
NIL
NIL
1

BUTTON
122
188
218
221
NIL
rotate-right
NIL
1
T
OBSERVER
NIL
L
NIL
NIL
1

BUTTON
5
189
94
222
NIL
rotate-left
NIL
1
T
OBSERVER
NIL
J
NIL
NIL
1

BUTTON
45
305
179
338
Reset Highscores
reset-highscores
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
79
235
226
268
Return to Main Menu
return-to-main-menu
NIL
1
T
OBSERVER
NIL
T
NIL
NIL
1

BUTTON
7
236
72
269
Pause
pause
NIL
1
T
OBSERVER
NIL
P
NIL
NIL
1

BUTTON
77
116
141
149
Shoot
fire
NIL
1
T
OBSERVER
NIL
I
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

This is a timed 3D target shooting game in which the player can play one of the 9 premade levels or import one of their own levels to complete as quickly as possible.

## AUTHOR

Greg Zborovsky, January 2018

## HOW TO USE IT

1. Press setup to setup game variables or so.
2. Press run-loop to begin the game.
3. Using your mouse, select from any of the stages or choose your own level.
4. Once in the game world, use WASD for movement, J and L for rotation, I to fire, P to pause, and T to return to the main menu screen. Each target is colored blue, green, and yellow.
5. For premade levels, highscores will kept and can be reset after each playthrough of a level.

## BUGS AND LIMITATIONS

Limits - Cheating is as simple as modifying the data file or changing a single line of code. Mouse based rotation can't be done efficiently, and netlogo action buttons are not particularly smooth in movement. The game also runs below desired framerate due to the inability to use the GPU. Reading the code is somewhat difficult and there are unused variables. (Sorry about that.)

Bugs - Selected an incompatible file for the custom level may throw an error. When the camera is parallel to a shape, an extra set of collisions is occasionally detected and will draw an extra, small protruding line. The depth sort will occasionally fail when objects with significant size differences are close by - I didn't have time to implement a z-buffer to fix this - but this issue doesn't appear in the premade levels.

## EXTERNAL SOURCES

https://en.wikipedia.org/wiki/3D_projection
https://en.wikipedia.org/wiki/Sutherland%E2%80%93Hodgman_algorithm
https://en.wikipedia.org/wiki/Rotation_matrix
https://en.wikipedia.org/wiki/Clipping_(computer_graphics)
http://www.songho.ca/opengl/gl_projectionmatrix.html
http://www.codinglabs.net/article_world_view_projection_matrix.aspx
https://computergraphics.stackexchange.com/questions/2310/could-we-dispense-the-near-clipping-plane

...and more.

## TODO

1. Implement Z-Buffer instead of some version of Painter's Algorithm.
2. Add support for transparency.
3. Optimize the application, especially with UI rendering and systems of equations.
4. Fix the "extra line" rendering issue.
5. Make the level editor simpler to use. (Not included in this file.)
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
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.1
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
