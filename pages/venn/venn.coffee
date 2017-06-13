WIDTH = 800
HEIGHT = 700

STROKE_COLOR = "black"
OFF_COLOR = "white"
ON_COLOR = "#e23131"

STROKE_WIDTH = 2

SET_RADIUS = 200
CENTER_OFFSET = 120 #distance from center of stage to center of circles
TEXT_OFFSET = 200 #same as CENTER_OFFSET, but for text
TEXT_UP_OFFSET = 10

TEXT_ATTR = {
  fontFamily: 'Arial, sans-serif',
  fontSize: '35',
  textFillColor: 'black',
}

centerX = WIDTH//2
centerY = HEIGHT//2

setGroup = new Group() #drawn sets

#Clone shape as well as position (x, y coordinates)
cloneShape = (shape) ->
    newShape = shape.clone()
    newShape.attr({
        "x": shape.attr("x"),
        "y": shape.attr("y"),
        "clip": shape.attr("clip"),
        })
    return newShape

#set x and y of shape to be the relative coordinates to relativeTo
moveRelative = (shape, relativeTo) ->
    shape.attr({
        "x": (shape.attr("x") - relativeTo.attr("x")),
        "y": (shape.attr("y") - relativeTo.attr("y"))
        })

#Creates visual representations of sets and adds these to setGroup
#setC - amount of sets to create venn-diagram for
#toggled - which subsets that are included, starting with universe,
#followed by smaller and smaller intersection ex, 2 sets: U, A, B, AB
#labels - Names of the sets
drawSets = (setC, toggled, labels) ->
    setGroup.clear()

    angles = []
    for i in [0..(setC - 1)]
        angles.push((2*Math.PI/setC) * i)

    setCenters = []
    for angle in angles
        setCenters.push([centerX + (Math.cos(angle)*CENTER_OFFSET), centerY + (Math.sin(angle)*CENTER_OFFSET)])

    sets = []
    #Create full circles
    for [x, y] in setCenters
        newSet = new Circle(x, y, SET_RADIUS)
        sets.push(newSet)

    #Create smaller sets
    if setC is 2
        newSet = cloneShape(sets[1])
        clipSet = cloneShape(sets[0])
        moveRelative(clipSet, newSet)

        newSet.attr('clip', clipSet)
        sets.push(newSet)

    else if setC is 3
        #Create two intersecting sets
        for [i1, i2] in [[0,1], [0,2], [1,2]]
            newSet = cloneShape(sets[i1])
            clipSet = cloneShape(sets[i2])
            moveRelative(clipSet, newSet)

            newSet.attr('clip', clipSet)
            sets.push(newSet)

        #Create center set
        cSet = cloneShape(sets[sets.length-2])
        clipSet = cloneShape(sets[sets.length-1])
        moveRelative(clipSet, cSet)

        cSet.attr("clip", clipSet)
        sets.push(cSet)

    #Paint background
    stage.setBackgroundColor(if toggled[0] then ON_COLOR else OFF_COLOR)

    #Paint sets
    for set, i in sets
        set.fill(if toggled[1+i] then ON_COLOR else OFF_COLOR)
        set.addTo(setGroup)

    #Paint outlines
    for i in [0..(setC-1)]
        cloneShape(sets[i]).stroke(STROKE_COLOR, STROKE_WIDTH).addTo(setGroup)

    #Paint text
    for label, i in labels
        newText = new Text(label).attr(TEXT_ATTR)
        angle = angles[i]

        newText.attr({
            x: (centerX + (Math.cos(angle)*TEXT_OFFSET)),
            y: (centerY + (Math.sin(angle)*TEXT_OFFSET)) - TEXT_UP_OFFSET
        })

        newText.addTo(setGroup)

    setGroup.addTo(stage)

#recieve mesages and paint sets
recieveMsg = (message) ->
    stage.clear()
    drawSets(message.setC, message.toggled, message.labels)

stage.on("message:draw", recieveMsg)

#drawSets(3, [true, false, false, false, true, true, true, false], ["A", "B", "C"])
#drawSets(2, [true, false, true, false,], ["A", "B"])
#drawSets(1, [true, false], ["A"])
