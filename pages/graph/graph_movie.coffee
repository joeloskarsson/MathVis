#Graph interface using BonsaiJS

NODE_RADIUS = 40;
EDGE_THICKNESS = 7;

NODE_COLOR = "#9A9A9A"
STROKE_COLOR = "black"
HOVER_COLOR = "#C3C3C3"
BG_COLOR = "white"

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

        @weight = 0

    updateEdge: () ->
        @path.clear()
        @path.moveTo(@n1.x, @n1.y)
        @path.lineTo(@n2.x, @n2.y)
        @path.closePath()

    deleteEdge: () ->
        @n1.removeEdge(this)
        @n2.removeEdge(this)

        edges.splice(edges.indexOf(this), 1)

#Parts of graph, State of movie
nodes = []
edges = []

selected = null
bg = new Rect(0, 0, stage.width, stage.height)
bg.fill(BG_COLOR)

isDragging = false

#
# User Interaction
#
dragNode = (e, node) ->
    node.setPos(e.x, e.y)

    for edge in node.edges
        edge.updateEdge()

    isDragging = true

hoverShape = (shape) ->
    if isDragging
        return

    if selected isnt null
        selected.stroke(STROKE_COLOR, EDGE_THICKNESS)

    selected = shape
    selected.stroke(HOVER_COLOR, EDGE_THICKNESS)

resetHover = () ->
    if isDragging
        return

    if selected isnt null
        selected.stroke(STROKE_COLOR,  EDGE_THICKNESS)

clickNode = (e) ->
    if isDragging
        isDragging = false
        return

    sendMessage("showNodeOptions", {
        "x": e.x,
        "y": e.y
        })

clickEdge = (edge) ->
    console.log("edge menu")

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
            removeNode(selected)


stage.on("message:action", recMessage)

updateProperties = () ->
    vertC = nodes.length
    edgeC = edges.length

    sendMessage("updateVerticeC", vertC)
    sendMessage("updateEdgeC", edgeC)

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
        clickNode(e)
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
        clickNode(newEdge)
    )

    edges.push(newEdge)
    return newEdge

removeNode = (n) ->
    remNode = n.node
    remNode.clearEdges()
    nodes.splice(nodes.indexOf(remNode), 1)

    sendMessage("hideOptions", [])
    updateProperties()
    updateStage()

updateStage = () ->
    stage.clear()

    bg.addTo(stage)
    for e in edges
        e.path.addTo(stage)

    for n in nodes
        n.shape.addTo(stage)

#
# Event handling for stage
#
bg.on("click", (e) ->
    makeNode(e.x, e.y)
    sendMessage("hideOptions", [])
    updateStage()
    updateProperties()
)
bg.on("pointermove", (e) ->
    resetHover()
)

# Start Example
n1 = makeNode(200, 300)
n2 = makeNode(100, 100)
n3 = makeNode(300, 100)
e1 = makeEdge(n1, n2)
e2 = makeEdge(n2, n3)
updateStage()
updateProperties()
