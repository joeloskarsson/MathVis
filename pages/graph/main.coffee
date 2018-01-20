movie_elem = $("#movie")
node_options = $("#node_menu")
edge_options = $("#edge_menu")

#Add BonsaiJS to movie
movie = bonsai.setup({
    runnerContext: bonsai.IframeRunnerContext
}).run(document.getElementById("movie"), {
    url: "graph_movie.js",
    width: movie_elem.width(),
    height: movie_elem.height()
})

showNodeOption = (x, y) ->
    edge_options.css("display", "none")

    node_options.css("display", "block")
    node_options.css("top", y)
    node_options.css("left", x)

closeOptions = () ->
    node_options.css("display", "none")
    edge_options.css("display", "none")

showEdgeOption = (x,y) ->
    node_options.css("display", "none")

    edge_options.css("display", "block")
    edge_options.css("top", y)
    edge_options.css("left", x)

setProperties = (props) ->
    $("#vertice_c").text(props["nodeC"])
    $("#edge_c").html(props["edgeC"])
    $("#total_cost").html(props["costTot"])

showPathResult = (cost) ->
    $("#path_length").html(cost)

#Send message to movie
sendMessage = (action, data = 0) ->
    movie.sendMessage("action", {
        action: action,
        data: data
    })

# Menu option clicked
$("#rem_node").click(() ->
    sendMessage("removeNode")
)
$("#new_edge").click(() ->
    sendMessage("makeEdge")
)
$("#rem_edge").click(() ->
    sendMessage("removeEdge")
)
$("#set_weight").click(() ->
    #Ask user for Weight
    newWeight = prompt("Set weight")

    if isNaN(newWeight)
        alert("Not a number!")
    else
        weightNumber = parseFloat(newWeight)

        if weightNumber < 0
            alert("Weight must be positive!")
        else
            sendMessage("setWeight", weightNumber)
)

#Side menu buttons
$("#clear_btn").click(() ->
    sendMessage("clearGraph")
)
$("#dijkstra").click(() ->
    sendMessage("startDijkstra")
)

#Recieve messages from movie
recMessage = (msg) ->
    action = msg.action
    data = msg.data

    switch action
        when "updateProperties"
            setProperties(data)
        when "showNodeOptions"
            showNodeOption(data.x, data.y)
        when "showEdgeOptions"
            showEdgeOption(data.x, data.y)
        when "hideOptions"
            closeOptions()
        when "dijkstraDone"
            showPathResult(data)

movie.on("message:action", recMessage)
