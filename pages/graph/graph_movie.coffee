#Graph interface using BonsaiJS

NODE_RADIUS = 40;
EDGE_THICKNESS = 7;

NODE_COLOR = "#9A9A9A"
STROKE_COLOR = "black"
HOVER_COLOR = "#C3C3C3"
BG_COLOR = "white"

class Node
    edges: []
    x: 0
    y: 0

    constructor: (@shape) ->
        this.x = this.shape.attr("x")
        this.y = this.shape.attr("y")

    setPos: (x, y) ->
        this.x = x
        this.y = y

        this.shape.attr("x", x)
        this.shape.attr("y", y)

    addEdge: (edge) ->
        edgeShapes.push(edge)

    getGrade: () ->
        return edgeShapes.length;

class Edge
    weight: 0

    constructor: (@n1, @n2, @path) ->
        n1.edges.push(this)
        n2.edges.push(this)

    updateEdge: () ->
        this.path.clear()
        this.path.moveTo(this.n1.x, this.n1.y)
        this.path.lineTo(this.n2.x, this.n2.y)
        this.path.closePath()

#Parts of graph

nodes = []
edges = []

nodeShapes = new Group()
edgeShapes = new Group()

selected = null
bg = new Rect(0, 0, stage.width, stage.height)
bg.fill(BG_COLOR)

isDragging = false

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
        selected = null

clickNode = (node) ->
    if isDragging
        isDragging = false
        return

    console.log("node menu")

clickEdge = (edge) ->
    console.log("edge menu")

makeNode = (x, y) ->
    newCir = new Circle(x, y, NODE_RADIUS)
    newCir.fill(NODE_COLOR).stroke(STROKE_COLOR, EDGE_THICKNESS)
    newCir.addTo(nodeShapes)

    newNode = new Node(newCir)

    #Events
    newCir.on("drag", (e) ->
        dragNode(e, newNode)
    )

    newCir.on("pointermove", (e) ->
        hoverShape(newCir)
    )

    newCir.on("click", (e) ->
        clickNode(newNode)
    )

    nodes.push(newNode)
    return newNode

makeEdge = (n1, n2) ->
    path = new Path()
    path.stroke("black", EDGE_THICKNESS)
    path.addTo(edgeShapes)

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

updateStage = () ->
    stage.clear()

    bg.addTo(stage)
    edgeShapes.addTo(stage)
    nodeShapes.addTo(stage)

#Event handling for stage
bg.on("click", (e) ->
    makeNode(e.x, e.y)
)
bg.on("pointermove", (e) ->
    resetHover()
)

n1 = makeNode(200, 300)
n2 = makeNode(100, 100)
n3 = makeNode(300, 100)
e1 = makeEdge(n1, n2)
e2 = makeEdge(n2, n3)
updateStage()
