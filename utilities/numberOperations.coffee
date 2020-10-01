addSeparators = (numToConvert, thousandsSep, decimalSep) ->
    numToConvert += ''
    numParts = numToConvert.split('.')
    wholePart = numParts[0]
    decimalPart = if numParts.length > 1 then decimalSep + numParts[1] else ''
    rgx = /(\d+)(\d{3})/
    wholePart = wholePart.replace(rgx, '$1' + thousandsSep + '$2') while rgx.test(wholePart)
    wholePart + decimalPart

export numberFormat = (options) ->
    defaults =
        digitsAfterDecimal: 2
        scaler: 1
        thousandsSep: ","
        decimalSep: "."
        prefix: ""
        suffix: ""
    options = {defaults..., options...}
    (x) ->
        if isNaN(x) or not isFinite(x)
            ""
        else
            result = addSeparators (options.scaler*x).toFixed(options.digitsAfterDecimal),
            options.thousandsSep, options.decimalSep
            options.prefix + result + options.suffix

export defaultFormat =
    usFormat: numberFormat()
    usFormatInt: numberFormat(digitsAfterDecimal: 0)
    usFormatPct: numberFormat(digitsAfterDecimal: 1, scaler: 100, suffix: "%")