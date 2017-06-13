WIDTH = 800
HEIGHT = 700

STROKE_COLOR = "black"
OFF_COLOR = "white"
ON_COLOR = "green"

STROKE_WIDTH = 2

SET_RADIUS = 200
CENTER_OFFSET = 120 #distance from center of stage to center of circles

centerX = WIDTH//2
centerY = HEIGHT//2

#initialize state
setGroup = new Group()
bg = new Rect(0, 0, WIDTH, HEIGHT)
bg.addTo(stage)

#Clone shape as well as position (x, y coordinates)
cloneShape = (shape) ->
    newShape = shape.clone()
    newShape.attr("x", shape.attr("x"))
    newShape.attr("y", shape.attr("y"))
    return newShape

#set x and y of shape to be the relative coordinates to relativeTo
moveRelative = (shape, relativeTo) ->
    shape.attr({
        "x": (shape.attr("x") - relativeTo.attr("x")),
        "y": (shape.attr("y") - relativeTo.attr("y"))
        })

createNewSets = (setC, toggled) ->
    return 0 if setC is 0

    angles = []
    for i in [0..(setC - 1)]
        angles.push((2*Math.PI/setC) * i)

    setCenters = []
    for angle in angles
        setCenters.push([Math.cos(angle), Math.sin(angle)])


    sets = []
    #Create full circles
    for [x, y] in setCenters
        newSet = new Circle(centerX + (x*CENTER_OFFSET), centerY + (y*CENTER_OFFSET), SET_RADIUS)
        sets.push(newSet)

    #Create smaller sets
    if setC is 2
        newSet = cloneShape(sets[1])

        clipSet = cloneShape(sets[0])
        moveRelative(clipSet, newSet)

        newSet.attr('clip', clipSet)
        sets.push(newSet)

    #TODO 3 set venn diagram
    #else if amount is 3

    #Paint background
    bg.fill(if toggled[0] then ON_COLOR else OFF_COLOR)

    #Paint sets
    for set, i in sets
        set.fill(if toggled[1+i] then ON_COLOR else OFF_COLOR)
        set.addTo(setGroup)

    #Paint outlines
    for i in [0..(setC-1)]
        cloneShape(sets[i]).stroke(STROKE_COLOR, STROKE_WIDTH).addTo(setGroup)

createNewSets(2, [false, true, false, true])
setGroup.addTo(stage)
