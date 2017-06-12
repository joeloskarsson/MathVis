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

setGroup = new Group()

c1 = Path.circle(50, 50, 30).attr({fillColor: "green"})
c2 = Path.circle(50, 70, 30).attr({fillColor: "red"})
c2.attr("mask", c1)
#c1.addTo(stage)
c2.addTo(stage)

cloneShape = (shape) ->
    newShape = shape.clone()
    newShape.attr("x", shape.attr("x"))
    newShape.attr("y", shape.attr("y"))
    return newShape

createNewSets = (amount) ->
    return 0 if amount is 0

    angles = []
    for i in [0..(amount - 1)]
        angles.push((2*Math.PI/amount) * i)

    setCenters = []
    for angle in angles
        setCenters.push([Math.cos(angle), Math.sin(angle)])


    sets = []
    #Create full circles
    for [x, y] in setCenters
        newSet = new Circle(centerX + (x*CENTER_OFFSET), centerY + (y*CENTER_OFFSET), SET_RADIUS)
        sets.push(newSet)

    #Create smaller sets
    if amount is 2
        clipSet = cloneShape(sets[0])
        newSet = cloneShape(sets[1])

        newSet.attr('clip', clipSet)
        #sets.push(newSet)

    #TODO 3 set venn diagram
    #else if amount is 3

    #Paint sets
    for set in sets
        set.fill(OFF_COLOR)
        set.stroke(STROKE_COLOR, STROKE_WIDTH)
        set.addTo(setGroup)

    #sets[2].addTo(setGroup)
    #alert(angles)

createNewSets(2)
setGroup.addTo(stage)
