#Graph interface using BonsaiJS

NODE_RADIUS = 40;
EDGE_THICKNESS = 4;

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
        edges.push(edge)

    getGrade: () ->
        return edges.length;

class Edge
    weight: 0

    constructor: (@n1, @n2, @path) ->

nodes = new Group()
edges = new Group()

dragNode = (e, node) ->
    node.setPos(e.x, e.y)
    updateStage()

makeNode = (x, y) ->
    newCir = new Circle(x, y, NODE_RADIUS)
    newCir.fill("#9A9A9A").stroke("black", EDGE_THICKNESS)
    newCir.addTo(nodes)

    newNode = new Node(newCir)
    newCir.on("drag", (e) ->
        dragNode(e, newNode)
    )

    return newNode

makeEdge = (n1, n2) ->
    path = new Path()
    path.moveTo(n1.x, n1.y)
    path.lineTo(n2.x, n2.y)
    path.closePath()
    path.stroke("black", EDGE_THICKNESS)
    path.addTo(edges)

    newEdge = new Edge(n1, n2, path)
    return newEdge

updateStage = () ->
    stage.clear()

    edges.addTo(stage)
    nodes.addTo(stage)

#Event handling for stage
stage.on("click", (e) ->
    makeNode(e.x, e.y)
)


n1 = makeNode(200, 300)
n2 = makeNode(100, 100)
n3 = makeNode(300, 100)
e1 = makeEdge(n1, n2)
e2 = makeEdge(n2, n3)
updateStage()
