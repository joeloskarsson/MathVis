#Graph interface using BonsaiJS

NODE_RADIUS = 40;
EDGE_THICKNESS = 7;

NODE_COLOR = "#9A9A9A"
STROKE_COLOR = "black"
HOVER_COLOR = "#C3C3C3"
BG_COLOR = "white"

WEIGHT_OFFSET = 20

class Node
    constructor: (@shape) ->
        @x = @shape.attr("x")
        @y = @shape.attr("y")

        @edges = []

        @shape.node = this

    setPos: (x, y) ->
        @x = x
        @y = y

        @shape.attr("x", x)
        @shape.attr("y", y)

    clearEdges: () ->
        for e in (ed for ed in @edges)
            e.deleteEdge()

    removeEdge: (e) ->
        remI = @edges.indexOf(e)
        if remI isnt -1
            @edges.splice(remI, 1)

    getGrade: () ->
        return @edges.length;

class Edge
    constructor: (@n1, @n2, @path) ->
        @n1.edges.push(this)
        @n2.edges.push(this)

        @weight = 0.0
        @text = new Text()

    updateEdge: () ->
        @path.clear()
        @path.moveTo(@n1.x, @n1.y)
        @path.lineTo(@n2.x, @n2.y)
        @path.closePath()
        @updateWeight()

    updateWeight:  () ->
        dx = (@n2.x - @n1.x)
        dy = (@n2.y - @n1.y)

        xOffset = 0
        yOffset = 0

        if Math.abs(dy) > Math.abs(dx)
            xOffset = WEIGHT_OFFSET
        else
            yOffset = WEIGHT_OFFSET

        @text.attr("text", @weight)
        @text.attr("x", @n1.x + dx/2 + xOffset)
        @text.attr("y", @n1.y + dy/2 + yOffset)

    deleteEdge: () ->
        @n1.removeEdge(this)
        @n2.removeEdge(this)

        edges.splice(edges.indexOf(this), 1)

    setWeight: (newWeight) ->
        @weight = newWeight
        @updateWeight()

#Parts of graph, State of movie
nodes = []
edges = []

selected = null #Selected shape
bg = new Rect(0, 0, stage.width, stage.height)
bg.fill(BG_COLOR)

isDragging = false
menuOpen = false

#Creating edges
makingEdge = false
newPath = null
newEdgeStart = null
makingEdgeX = 0 #End position to draw of new edge
makingEdgeY = 0

#
# User Interaction
#
dragNode = (e, node) ->
    closeMenu()
    hoverShape(node.shape)

    node.setPos(e.x, e.y)

    for edge in node.edges
        edge.updateEdge()

    isDragging = true

hoverShape = (shape) ->
    if isDragging or menuOpen
        return

    if makingEdge and shape.node?
        makingEdgeX = shape.node.x
        makingEdgeY = shape.node.y
        updateStage()

    if selected isnt null
        selected.stroke(STROKE_COLOR, EDGE_THICKNESS)

    selected = shape
    selected.stroke(HOVER_COLOR, EDGE_THICKNESS)

resetHover = () ->
    if isDragging or menuOpen
        return

    if selected isnt null
        selected.stroke(STROKE_COLOR,  EDGE_THICKNESS)

clickNode = (e, shape) ->
    if makingEdge
        makingEdge = false;
        makeEdge(newEdgeStart, shape.node)
        updateStage()
        updateProperties()
        return

    if isDragging
        isDragging = false
        return

    if menuOpen
        closeMenu()
        hoverShape(shape)

    showNodeMenu(e.x, e.y)

clickEdge = (edge, e) ->
    closeMenu()
    hoverShape(edge.path)

    menuOpen = true
    sendMessage("showEdgeOptions", {
        "x": e.x,
        "y": e.y
        })

showNodeMenu = (x, y) ->
    menuOpen = true
    sendMessage("showNodeOptions", {
        "x": x,
        "y": y
        })

closeMenu = () ->
    sendMessage("hideOptions", [])
    menuOpen = false

#
# Event handling for stage
#
bg.on("click", (e) ->
    if menuOpen
        closeMenu()
        resetHover()
    else
        makeNode(e.x, e.y)
        updateStage()
        updateProperties()
)
bg.on("pointermove", (e) ->
    resetHover()

    if makingEdge
        makingEdgeX = e.x
        makingEdgeY = e.y
        updateStage()
)


#
# Message passing to DOM
#
sendMessage = (action, data) ->
    stage.sendMessage("action", {
        action: action,
        data: data
    })

recMessage = (msg) ->
    action = msg.action
    data = msg.data

    switch action
        when "removeNode"
            removeNode(selected.node)
        when "makeEdge"
            startMakingEdge()
        when "removeEdge"
            removeEdge(selected.edge)
        when "setWeight"
            setEdgeWeight(selected.edge, data)

stage.on("message:action", recMessage)

updateProperties = () ->
    vertC = nodes.length
    edgeC = edges.length

    costTotal = edges.map((e) -> e.weight).reduce((x,y) -> x + y)

    #TODO send one message with all property information
    sendMessage("updateVerticeC", vertC)
    sendMessage("updateEdgeC", edgeC)
    sendMessage("setTotalCost", costTotal)

#
# Add elelments
#
makeNode = (x, y) ->
    newCir = new Circle(x, y, NODE_RADIUS)
    newCir.fill(NODE_COLOR).stroke(STROKE_COLOR, EDGE_THICKNESS)

    newNode = new Node(newCir)

    #Events
    newCir.on("drag", (e) ->
        dragNode(e, newNode)
    )

    newCir.on("pointermove", (e) ->
        hoverShape(newCir)
    )

    newCir.on("click", (e) ->
        clickNode(e,  newCir)
    )

    nodes.push(newNode)
    return newNode

makeEdge = (n1, n2) ->
    path = new Path()
    path.stroke("black", EDGE_THICKNESS)

    newEdge = new Edge(n1, n2, path)
    newEdge.updateEdge()

    #Events
    path.on("pointermove", (e) ->
        hoverShape(path)
    )
    path.on("click", (e) ->
        clickEdge(newEdge, e)
    )
    path.edge = newEdge

    edges.push(newEdge)
    return newEdge

removeNode = (remNode) ->
    remNode.clearEdges()
    nodes.splice(nodes.indexOf(remNode), 1)

    closeMenu()
    updateProperties()
    updateStage()

removeEdge = (remEdge) ->
    remEdge.deleteEdge()
    updateProperties()
    updateStage()
    closeMenu()

setEdgeWeight = (edge, weight) ->
    selected.edge.setWeight(weight)
    closeMenu()
    updateProperties()
    updateStage()

updateStage = () ->
    stage.clear()

    bg.addTo(stage)
    for e in edges
        e.path.addTo(stage)

        #Draw weights for each Path
        if e.weight > 0
            e.text.addTo(stage)

    #Draw edge in the makingEdge
    if makingEdge
        newPath.clear()
        newPath.moveTo(newEdgeStart.x, newEdgeStart.y)
        newPath.lineTo(makingEdgeX, makingEdgeY)
        newPath.closePath()
        newPath.addTo(stage)

    for n in nodes
        n.shape.addTo(stage)

startMakingEdge = () ->
    closeMenu()

    makingEdge = true
    newEdgeStart = selected.node
    newPath = new Path()
    newPath.stroke("black", EDGE_THICKNESS)

    newPath.on("click", () ->
        makingEdge = false
        updateStage()
    )

    newPath.on("pointermove", (e) ->
        makingEdgeX = e.x
        makingEdgeY = e.y
        updateStage()
    )

# Start Example
n1 = makeNode(200, 300)
n2 = makeNode(100, 100)
n3 = makeNode(300, 100)
e1 = makeEdge(n1, n2)
e2 = makeEdge(n2, n3)
updateStage()
updateProperties()
