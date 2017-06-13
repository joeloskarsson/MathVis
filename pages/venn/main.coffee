buttons_elem = $(".symbol_button")
formula_field = $("#formula")
error_sign = $("#error_symbol")

#Add BonsaiJS to drawing
movie = bonsai.setup({
    runnerContext: bonsai.IframeRunnerContext
}).run(document.getElementById("drawing"), {
    url: "venn.js",
    width: 800,
    height: 700
})

#Buttons for inserting special chars
buttons_elem.click(() ->
    startSel = formula_field[0].selectionStart
    endSel = formula_field[0].selectionEnd
    newChar = $(this).html()

    oldVal = formula_field.val()
    newVal = oldVal.substring(0, startSel) + newChar + oldVal.substring(endSel)

    formula_field.val(newVal)
    formula_field.focus()

    newCursorPos = startSel + 1
    formula_field[0].selectionStart = newCursorPos
    formula_field[0].selectionEnd = newCursorPos
)

#Show error symbol in formula formula field
showError = (show) ->
    error_sign.css("visibility", (if show then "visible" else "hidden"))

messageDraw = (toggled, labels) ->
    setC = Math.log2(toggled.length)
    movie.sendMessage("draw", {
        "setC": setC,
        "toggled": toggled,
        "labels": labels
    })

#messageDraw([true, false], ["A"])

ACCEPTED_SETS = ["A", "B", "C"]
ACCEPTED_OPS = ["*", "⋃", "⋂", "∆", "∖"]

getSetNames = (formula) ->
    setNames = []
    for c in formula.toUpperCase()
        if c in ACCEPTED_SETS
            if c not in setNames
                setNames.push(c)
        else if c not in ACCEPTED_OPS
            return false

    return setNames

evalFormula = (formula) ->
    showError(false) #reset error syambol

    labels = getSetNames(formula)

    if not labels
        showError(true)
        return

evalutateField = () ->
    formula = formula_field.val()
    evalFormula(formula)

formula_field.on("keyup", evalutateField)
