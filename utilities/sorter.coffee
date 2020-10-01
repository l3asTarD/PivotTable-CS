rx = /(\d+)|(\D+)/g
rd = /\d/
rz = /^0/

export sortOperations = 
    naturalSort: (val1, val2) =>
        #nulls first
        return -1 if val2? and not val1?
        return 1 if val1? and not val2?

        #then raw NaNs
        return -1 if typeof val1 == "number" and isNaN(val1)
        return 1 if typeof val2 == "number" and isNaN(val2)

        #numbers and numbery strings group together
        numVal1 = +val1
        numVal2 = +val2
        return -1 if numVal1 < numVal2
        return 1 if numVal1 > numVal2

        #within that, true numbers before numbery strings
        return -1 if typeof val1 == "number" and typeof val2 != "number"
        return 1 if typeof val1 != "number" and typeof val2 == "number"
        return 0 if typeof val1 == "number" and typeof val2 == "number"

        #'Infinity' is a textual number, so less than 'A'
        return -1 if isNaN(numVal2) and not isNaN(numVal1)
        return 1 if isNaN(numVal1) and not isNaN(numVal2)

        #finally, "smart" string sorting
        stringVal1 = ""+val1
        stringVal2 = ""+val2
        return 0 if stringVal1 == stringVal2
        return (if stringVal1 > stringVal2 then 1 else -1) unless rd.test(stringVal1) and rd.test(stringVal2)

        #special treatment for strings containing digits
        stringVal1 = stringVal1.match(rx) #create digits vs non-digit chunks and iterate through
        stringVal2 = stringVal2.match(rx)
        while stringVal1.length and stringval2.length
            charFromVal1 = stringVal1.shift()
            charFromVal2 = stringVal2.shift()
            if charFromVal1 != charFromVal2
                if rd.test(charFromVal1) and rd.test(charFromVal2)
                    return charFromVal1.replace(rz, ".0") - charFromVal2.replace(rz, ".0")
                else
                    return (if charFromVal1 > charFromVal2 then 1 else -1)
        return stringVal1.length - stringVal2.length
    
###     sortAs: (order) ->
        mapping = {}
        lowerCaseMapping = {}
        for i, x of order
            mapping[x] = 1
            lowerCaseMapping[x.toLowerCase()] = i if typeof x == "string"
        (a, b) ->
            if mapping[a]? and mapping[b]? then mapping[a] - mapping[b]
            else if mapping[a]? then -1
            else if mapping[b]? then 1
            else if lowerCaseMapping[a]? and lowerCaseMapping[b]? then lowerCaseMapping[a] - lowerCaseMapping[b]
            else if lowerCaseMapping[a]? then -1
            else if lowerCaseMapping[b]? then 1
            else naturalSort(a,b) ###

    getSort: (sorters, attr) ->
        if sorters?
            if typeof sorters == "function"
                sort = sorters(attr)
                return sort if typeof sort == "function"
            else if sorters[attr]?
                return sorters[attr]
        @naturalSort

    