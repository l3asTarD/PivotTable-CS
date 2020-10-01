import { defaultFormat } from "../utilities/numberOperations.js"
import { sortOperations } from "../utilities/sorter.js"

export aggregatorTemplates =
    count: (formatter=defaultFormat.usFormatInt) -> () -> (data, rowKey, colKey) ->
        count: 0
        push: -> @count++
        value: -> @count
        format: formatter

    uniques: (fn, formatter=defaultFormat.usFormatInt) -> ([attr]) -> (data, rowKey, colKey) ->
        uniq: []
        push: (record) -> @uniq.push(record[attr]) if record[attr] not in @uniq
        value: -> fn(@uniq)
        format: formatter
        numInputs: if attr? then 0 else 1

    sum: (formatter=defaultFormat.usFormat) -> ([attr]) -> (data, rowKey, colKey) ->
        sum: 0
        push: (record) -> @sum += +record[attr] if not isNaN +record[attr]
        value: -> @sum
        format: formatter
        numInputs: if attr? then 0 else 1

    extremes: (mode, formatter=defaultFormat.usFormat) -> ([attr]) -> (data, rowKey, colKey) ->
        val: null
        sorter: sortOperations.getSort(data?.sorters, attr)
        push: (record) ->
            x = record[attr]
            if mode in ["min","max"]
                x = +x
                if not isNaN(x) then @val = Math[mode](x, @val ? x)
            if mode == "first" then @val = x if @sorter(x, @val ? x) <= 0
            if mode == "last" then @val = x if @sorter(x, @val ? x) >= 0
        value: -> @val
        format: (x) -> if isNaN(x) then x else formatter(x)
        numInputs: if attr? then 0 else 1

    quantile: (q, formatter=defaultFormat.usFormat) -> ([attr]) -> (data, rowKey, colKey) ->
        vals: []
        push: (record) ->
            x = +record[attr]
            @vals.push(x) if not isNaN(x)
        value: ->
            return null if @vals.length == 0
            @vals.sort((a,b) -> a-b)
            i = (@vals.length-1)*q
            (@vals[Math.floor(i)] + @vals[Math.ceil(i)])/2.0
        format: formatter
        numInputs: if attr? then 0 else 1

    runningStat: (mode="mean", ddof=1, formatter=defaultFormat.usFormat) -> ([attr]) -> (data, rowKey, colKey) ->
        n: 0.0, m: 0.0, s: 0.0
        push: (record) ->
            x = +record[attr]
            return if isNaN(x)
            @n += 1.0
            if @n == 1.0
                @m = x
            else
                m_new = @m + (x - @m)/@n
                @s = @s + (x - @m)*(x - m_new)
                @m = m_new
        value: ->
            if mode == "mean"
                return if @n == 0 then 0/0 else @m
            return 0 if @n <= ddof
            switch mode
                when "var" then @s/(@n-ddof)
                when "stdev" then Math.sqrt(@s/(@n-ddof))
        format: formatter
        numInputs: if attr? then 0 else 1

    sumOverSum: (formatter=defaultFormat.usFormat) -> ([num, denom]) -> (data, rowKey, colKey) ->
        sumNum: 0
        sumNumDenom: 0
        push: (record) ->
            @sumNum += +record[num] if not isNaN +record[num]
            @sumNumDenom += +record[denom] if not isNaN +record[denom]
        value: -> @sumNum/@sumNumDenom
        format: formatter
        numInputs: if num? and denom? then 0 else 2

    sumOverSumBound80: (upper=true, formatter=defaultFormat.usFormat) -> ([num, denom]) -> (data, rowKey, colKey) ->
            sumNum: 0
            sumDenom: 0
            push: (record) ->
                @sumNum   += +record[num]  if not isNaN +record[num]
                @sumDenom += +record[denom] if not isNaN +record[denom]
            value: ->
                sign = if upper then 1 else -1
                (0.821187207574908/@sumDenom + @sumNum/@sumDenom + 1.2815515655446004*sign*
                    Math.sqrt(0.410593603787454/ (@sumDenom*@sumDenom) + (@sumNum*(1 - @sumNum/ @sumDenom))/ (@sumDenom*@sumDenom)))/
                    (1 + 1.642374415149816/@sumDenom)
            format: formatter
            numInputs: if num? and denom? then 0 else 2

    #TODO getAggregator()
    fractionOf: (wrapped, type="total", formatter=defaultFormat.usFormat) -> (x...) -> (data, rowKey, colKey) ->
            selector: {total:[[],[]],row:[rowKey,[]],col:[[],colKey]}[type]
            inner: wrapped(x...)(data, rowKey, colKey)
            push: (record) -> @inner.push record
            format: formatter
            value: -> @inner.value() / data.getAggregator(@selector...).inner.value()
            numInputs: wrapped(x...)().numInputs

aggregatorTemplates.countUnique = (f) -> aggregatorTemplates.uniques(((x) -> x.length), f)
aggregatorTemplates.listUnique = (s) -> aggregatorTemplates.uniques(((x) -> x.sort(sortOperations.naturalSort).join(s)), ((x) -> x))
aggregatorTemplates.max = (f) -> aggregatorTemplates.extremes('max', f)
aggregatorTemplates.min = (f) -> aggregatorTemplates.extremes('min', f)
aggregatorTemplates.first = (f) -> aggregatorTemplates.extremes('first', f)
aggregatorTemplates.last = (f) -> aggregatorTemplates.extremes('last', f)
aggregatorTemplates.median = (f) -> aggregatorTemplates.quantile(0.5, f)
aggregatorTemplates.average = (f) -> aggregatorTemplates.runningStat("mean", 1, f)
aggregatorTemplates.var = (ddof, f) -> aggregatorTemplates.runningStat("mean", ddof, f)
aggregatorTemplates.stdev = (ddof, f) -> aggregatorTemplates.runningStat("stdev", ddof, f)