#Graph interface using BonsaiJS

NODE_RADIUS = 30;
EDGE_THICKNESS = 7;

NODE_COLOR = "#9A9A9A"
STROKE_COLOR = "black"
HOVER_COLOR = "#C3C3C3"
BG_COLOR = "white"
SELECTED_COLOR = "#fc7f6f"

PATH_COLOR = "#6ef470"

WEIGHT_OFFSET = 20

STATE = {
    IDLE: 0,
    MAKING_EDGE: 1,
    SELECTING_NODE1: 2,
    SELECTING_NODE2: 3,
    MENU_OPEN: 4,
    DRAGGING_NODE: 5,
    PATH_HIGHLIGHT: 6
}

class Node
    constructor: (@shape) ->
        @x = @shape.attr("x")
        @y = @shape.attr("y")

        @edges = []

        @shape.node = this

        @pathInfo = null

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

        @weight = 1
        @text = new Text()

    updateEdge: () ->
        @path.clear()
        @path.moveTo(@n1.x, @n1.y)
        @path.lineTo(@n2.x, @n2.y)
        @path.closePath()
        @updateWeight()

    updateWeight: () ->
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
    opposite: (node) ->
        return if node is @n1 then @n2 else @n1

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

instructionText = new Text().attr({
    x: 10,
    y: 10
    })

actionState = STATE.IDLE;

#Creating edges
newPath = null
newEdgeStart = null
makingEdgeX = 0 #End position to draw of new edge
makingEdgeY = 0

#pathfinding
pathNode1 =null
pathNode2 =null

#
# User Interaction
#
dragNode = (e, node) ->
    if actionState isnt STATE.IDLE and actionState isnt STATE.DRAGGING_NODE
        return

    closeMenu()
    hoverShape(node.shape)

    node.setPos(e.x, e.y)

    for edge in node.edges
        edge.updateEdge()

    actionState = STATE.DRAGGING_NODE

hoverShape = (shape) ->
    switch actionState
        when STATE.DRAGGING_NODE, STATE.MENU_OPEN, STATE.PATH_HIGHLIGHT
            return
        when STATE.MAKING_EDGE
            if shape.node?
                makingEdgeX = shape.node.x
                makingEdgeY = shape.node.y
                updateStage()

    if selected isnt null
        selected.stroke(STROKE_COLOR, EDGE_THICKNESS)

    selected = shape
    selected.stroke(HOVER_COLOR, EDGE_THICKNESS)

resetHover = () ->
    if actionState is STATE.DRAGGING_NODE or actionState is STATE.MENU_OPEN
        return

    if selected isnt null
        selected.stroke(STROKE_COLOR,  EDGE_THICKNESS)

clickNode = (e, shape) ->
    hoverShape(shape)
    switch actionState
        when STATE.IDLE
            showNodeMenu(e.x, e.y)
        when STATE.PATH_HIGHLIGHT
            stopHighLight()
        when STATE.MENU_OPEN
            closeMenu()
            hoverShape(shape)
        when STATE.MAKING_EDGE
            actionState = STATE.IDLE
            makeEdge(newEdgeStart, shape.node)
            updateStage()
            updateProperties()
        when STATE.SELECTING_NODE1
            setPathNode(shape.node, 1)
            actionState = STATE.SELECTING_NODE2
            updateStage()
        when STATE.SELECTING_NODE2
            setPathNode(shape.node, 2)
            runDijkstra()
        when STATE.DRAGGING_NODE
            actionState = STATE.IDLE

clickEdge = (edge, e) ->
    switch actionState
        when STATE.IDLE
            closeMenu()
            hoverShape(edge.path)

            showEdgeMenu(e.x, e.y)
        when STATE.MAKING_EDGE
            actionState = STATE.IDLE
            updateStage()
        when STATE.SELECTING_NODE1, STATE.SELECTING_NODE2
            actionState = STATE.IDLE
            stopDijkstra()
            updateStage()
        when STATE.PATH_HIGHLIGHT
            stopHighLight()

showEdgeMenu = (x, y) ->
    actionState = STATE.MENU_OPEN
    sendMessage("showEdgeOptions", {
        "x": x,
        "y": y
        })

showNodeMenu = (x, y) ->
    actionState = STATE.MENU_OPEN
    sendMessage("showNodeOptions", {
        "x": x,
        "y": y
        })

closeMenu = () ->
    sendMessage("hideOptions", [])
    actionState = STATE.IDLE

#
# Event handling for stage
#
bg.on("click", (e) ->
    switch actionState
        when STATE.MENU_OPEN
            closeMenu()
            resetHover()
        when STATE.IDLE
            makeNode(e.x, e.y)
            updateProperties()
        when STATE.MAKING_EDGE
            actionState = STATE.IDLE
        when STATE.SELECTING_NODE1, STATE.SELECTING_NODE2
            stopDijkstra()
            actionState = STATE.IDLE
        when STATE.PATH_HIGHLIGHT
            stopHighLight()

    updateStage()
)
bg.on("pointermove", (e) ->
    resetHover()

    if actionState is STATE.MAKING_EDGE
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
        when "clearGraph"
            clearGraph()
        when "startDijkstra"
            selectDijkstra()

stage.on("message:action", recMessage)

updateProperties = () ->
    nodeC = nodes.length
    edgeC = edges.length

    costTotal = 0
    if edgeC > 0
        costTotal = edges.map((e) -> e.weight).reduce((x,y) -> x + y)

    sendMessage("updateProperties", {
        "nodeC": nodeC,
        "edgeC": edgeC,
        "costTot": costTotal
        })

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
    hoverShape(newCir)
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

clearGraph = () ->
    nodes = []
    edges = []

    actionState = STATE.IDLE
    closeMenu()

    updateStage()
    updateProperties()

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
        if e.weight != 1
            e.text.addTo(stage)

    #Draw edge in the makingEdge
    if actionState is STATE.MAKING_EDGE
        newPath.clear()
        newPath.moveTo(newEdgeStart.x, newEdgeStart.y)
        newPath.lineTo(makingEdgeX, makingEdgeY)
        newPath.closePath()
        newPath.addTo(stage)

    for n in nodes
        n.shape.addTo(stage)

    switch actionState
        when STATE.SELECTING_NODE1
            instructionText.attr({text: "Select start node"})
            instructionText.addTo(stage)
        when STATE.SELECTING_NODE2
            instructionText.attr({text: "Select end node"})
            instructionText.addTo(stage)

    console.log(actionState)

startMakingEdge = () ->
    closeMenu()

    actionState = STATE.MAKING_EDGE
    newEdgeStart = selected.node
    newPath = new Path()
    newPath.stroke("black", EDGE_THICKNESS)

    newPath.on("click", () ->
        actionState = STATE.IDLE
        updateStage()
    )

    newPath.on("pointermove", (e) ->
        makingEdgeX = e.x
        makingEdgeY = e.y
        updateStage()
    )

stopHighLight = () ->
    edge.path.stroke(STROKE_COLOR, EDGE_THICKNESS) for edge in edges
    actionState = STATE.IDLE
    stopDijkstra()

#
# Specific Algorithms
#
setPathNode = (node, n) ->
    if n is 1
        pathNode1 = node
        node.shape.fill(SELECTED_COLOR)
    else
        pathNode2 = node
        node.shape.fill(SELECTED_COLOR)

selectDijkstra = () ->
    closeMenu()
    stopHighLight()
    actionState = STATE.SELECTING_NODE1
    updateStage()

stopDijkstra = () ->
    if pathNode1?
        pathNode1.shape.fill(NODE_COLOR)
        pathNode1 = null;
    if pathNode2?
        pathNode2.shape.fill(NODE_COLOR)
        pathNode2 = null;

    updateStage()

runDijkstra = () ->
    node.pathInfo = {
        cost: 0,
        visited: false,
        qued: false,
        prevEdge: null
    } for node in nodes

    nodeQ = [pathNode1]

    #Find path to node2
    until curNode is pathNode2 or nodeQ.length is 0
        #Get next curNode with lowest cost
        nextNodeI = [0..(nodeQ.length - 1)].reduce((i1, i2) -> if nodeQ[i1].pathInfo.cost > nodeQ[i2].pathInfo.cost then i2 else i1)
        curNode = nodeQ[nextNodeI]
        nodeQ.splice(nextNodeI, 1)

        curNode.pathInfo.visited = true

        if curNode is pathNode2
            break

        #Iterate over all edges out from current node
        for edge in curNode.edges
            neighbor = edge.opposite(curNode)

            if not neighbor.pathInfo.visited
                newCost = curNode.pathInfo.cost + edge.weight

                if neighbor.pathInfo.qued
                    #Shorter path to already qued node found
                    if newCost < neighbor.pathInfo.cost
                        neighbor.pathInfo.cost = newCost
                        neighbor.pathInfo.prevEdge = edge
                else
                    #Node not qued before
                    neighbor.pathInfo.cost = newCost
                    neighbor.pathInfo.prevEdge = edge
                    neighbor.pathInfo.qued = true
                    nodeQ.push(neighbor)

    #End node not found
    if curNode isnt pathNode2
        stopDijkstra()
        sendMessage("dijkstraDone", "-")
        alert("No path between nodes exists!")
        return

    #End found, follow path back
    pathCost = curNode.pathInfo.cost

    until curNode.pathInfo.prevEdge is null
        curNode.pathInfo.prevEdge.path.stroke(PATH_COLOR, EDGE_THICKNESS)
        curNode = curNode.pathInfo.prevEdge.opposite(curNode)

    actionState = STATE.PATH_HIGHLIGHT
    resetHover()
    updateStage()
    sendMessage("dijkstraDone", pathCost)

# Start Example
n1 = makeNode(100, 100)
n2 = makeNode(300, 100)
e1 = makeEdge(n1, n2)
updateStage()
updateProperties()
