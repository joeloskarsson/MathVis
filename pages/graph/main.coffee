movie_elem = $("#movie")

#Add BonsaiJS to movie
movie = bonsai.setup({
    runnerContext: bonsai.IframeRunnerContext
}).run(document.getElementById("movie"), {
    url: "graph_movie.js",
    width: movie_elem.width(),
    height: movie_elem.height()
})

#Catch window resize
$(window).resize(() ->
    #alert(movie.width)

)
