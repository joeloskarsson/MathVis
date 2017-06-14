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

#Show error symbol in formula formula field
showError = (show) ->
    error_sign.css("visibility", (if show then "visible" else "hidden"))

#Send message to of what to draw to BonsaiJS movie
#Example: messageDraw([true, false], ["A"])
messageDraw = (toggled, labels) ->
    setC = Math.log2(toggled.length)
    movie.sendMessage("draw", {
        "setC": setC,
        "toggled": toggled,
        "labels": labels
    })

#Set belongings for A, B, C
FULL_SETS = [
    [
        [false, true]
    ],
    [
        [false, true, false, true]
        [false, false, true, true]
    ],
    [
        [false, true, false, false, true, true, false, true]
        [false, false, true, false, true, false, true, true]
        [false, false, false, true, false, true, true, true]
    ]
]

ACCEPTED_SETS = ["A", "B", "C"]

#*,(,) and special unicode chats
ACCEPTED_OPS = ["*", "\u2206", "\u2216", "\u22c3", "\u22c2", "(", ")"]

getSetNames = (formula) ->
    setNames = []
    for c in formula.toUpperCase()
        if c in ACCEPTED_SETS
            if c not in setNames
                setNames.push(c)
        else if c not in ACCEPTED_OPS
            return false

    #Sort for nice display
    setNames.sort()
    return setNames

#
# Set operations
#
inverse = (s) ->
    return [not e for e in s]

#Help operation to execute set operation (op) on arrays of subsets
setOperation = (s1, s2, op) ->
    return [op(s1[i], s2[i]) for i in [0..(s1.length-1)]]

union = (e1, e2) ->
    return e1 or e2

intersection = (e1, e2) ->
    return e1 and e2

symDiff = (e1, e2) ->
    return (e1 and not e2) || (not e1 and e2) #XOR

relComp = (e1, e2) ->
    return e1 and not e2

#Takes an array containing only sets and operators
calculateSets = (exprArray) ->
    curSet = exprArray[0]

    for i in [1..(exprArray.length-1)] by 2
        switch exprArray[i]
            when "\u2206"
                op = symDiff
            when "\u2216"
                op = relComp
            when "\u22c3"
                op = union
            when "\u22c2"
                op = intersection

        curSet = setOperation(curSet, exprArray[i+1], op)

    return curSet

#Transforms string formula to an array of only sets and operators
makeExprArray = (formula, labels) ->
    if formula is ""
        throw formulaError

    exprArray = []

    pars = 0
    inPars = ""

    inv = false

    for c in formula
        if pars > 0
            if c is "("
                pars++
                inPars = inPars+c
            if c is ")"
                pars--
                if pars is 0
                    #end parenthesis section
                    innerExpr = makeExprArray(inPars)
                    innerSet = calculateSets(innerExpr)
                    inPars = ""

                    if inv
                        exprArray.push(inverse(innerSet))
                        inv = false
                    else
                        exprArray.push(innerSet)
                else
                    inPars = inPars+c
            else
                inPars = inPars+c

        if c is "("
            pars = 1
        else if c is ")"
            throw "formulaError"
        else if c in ACCEPTED_OPS
            #Is operation
            #Check so no not before
            if inv
                throw "formulaError"

            if c is "*"
                inv = true
            else
                exprArray.push(c)
        else if c.toUpperCase() in labels
            setN = labels.indexOf(c)
            setC = labels.length

            newSet = FULL_SETS[setC - 1][setN]
            if inv
                exprArray.push(inverse(newSet))
                inv = false
            else
                exprArray.push(newSet)

    if inv or (pars > 0) or (exprArray.length%2 is 0)
        throw "formulaError"

    console.log(exprArray)

    #check so no double operator or sets
    for val, i in exprArray
        if (i % 2) is 0
            #even
            if typeof val is "string"
                throw "formulaError"
        else if typeof val isnt "string"
            console.log("wut?")
            throw formulaError


    return exprArray

#Actual evaluation
#of formula field
evalFormula = (formula) ->
    showError(false) #reset error syambol

    labels = getSetNames(formula)

    if not labels
        showError(true)
        return
    try
        exprArray = makeExprArray(formula, labels)
        drawSet = calculateSets(exprArray)

        showError(false)

        #send draw message
        messageDraw(drawSet, labels)
        console.log("msg sent")
    catch formulaError
        showError(true)


evalutateField = () ->
    formula = formula_field.val()
    evalFormula(formula)

formula_field.on("keyup", evalutateField)

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

    #reevaluate
    evalutateField()
)
