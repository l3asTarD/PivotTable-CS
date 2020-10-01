import { aggregatorTemplates } from "../aggregators/aggregators.js"
import { sortOperations } from "../utilities/sorter.js"

export class PivotData
    constructor: (input, opts = {}) ->
        @input = input
        @aggregator = opts.aggregator ? aggregatorTemplates.count()()
        @aggregatorName = opts.aggregatorName ? "Count"
        @colAttrs = opts.cols ? []
        @rowAttrs = opts.rows ? []
        @valAttrs = opts.vals ? []
        @sorters = opts.sorters ? {}
        @rowOrder = opts.rowOrder ? "key_a_to_z"
        @colOrder = opts.colOrder ? "key_a_to_z"
        @derivedAttributes = opts.derivedAttributes ? {}
        @filter = opts.filter ? (-> true)
        @tree = {}
        @rowKeys = []
        @colKeys = []
        @rowTotals = {}
        @colTotals = {}
        @allTotal = @aggregator(this, [], [])
        @sorted = false

        #iterate through input, accumulating data for cells
        PivotData.forEachRecord @input, @derivedAttributes, (record) =>
            @processRecord(record) if @filter(record)

    @forEachRecord = (input, derivedAttributes, f) ->
        if Object.keys(derivedAttributes).length == 0 && derivedAttributes.constructor == Object
            addRecord = f
        else
            addRecord = (record) ->
                record[k] = v(record) ? record[k] for k, v of derivedAttributes
                f(record)

        if typeof input == "function"
            input(addRecord)
        else if Array.isArray(input)
            if Array.isArray(input[0]) #array of arrays
                for own i, compactRecord of input when i > 0
                    record = {}
                    record[k] = compactRecord[j] for own j, k of input[0]
                    addRecord(record)
            else #array of objects
                addRecord(record) for record in input
        else
            throw new Error("unknown input format")

    arrSort: (attrs) =>
        sortersArr = (sortOperations.getSort(@sorters, a) for a in attrs)
        (a,b) ->
            for own i, sorter of sortersArr
                comparison = sorter(a[i], b[i])
                return comparison if comparison != 0
            return 0

    sortKeys: () =>
        if not @sorted
            @sorted = true
            v = (r,c) => @getAggregator(r,c).value()
            switch @rowOrder
                when "value_a_to_z" then @rowKeys.sort (a,b) => sortOperations.naturalSort v(a,[]), v(b,[])
                when "value_z_to_a" then @rowKeys.sort (a,b) => -sortOperations.naturalSort v(a,[]), v(b,[])
                else @rowKeys.sort @arrSort(@rowAttrs)
            switch @colOrder
                when "value_a_to_z" then @colKeys.sort (a,b) => sortOperations.naturalSort v([],a), v([],b)
                when "value_z_to_a" then @colKeys.sort (a,b) => -sortOperations.naturalSort v([],a), v([],b)
                else @colKeys.sort @arrSort(@colAttrs)

    getColKeys: () =>
        @sortKeys()
        return @colKeys

    getRowKeys: () =>
        @sortKeys()
        return @rowKeys

    processRecord: (record) ->
        colKey = []
        rowKey = []
        colKey.push record[x] ? "null" for x in @colAttrs
        rowKey.push record[x] ? "null" for x in @rowAttrs
        flatRowKey = rowKey.join(String.fromCharCode(0))
        flatColKey = colKey.join(String.fromCharCode(0))

        @allTotal.push record

        if rowKey.length != 0
            if not @rowTotals[flatRowKey]
                @rowKeys.push rowKey
                @rowTotals[flatRowKey] = @aggregator(this, rowKey, [])
            @rowTotals[flatRowKey].push record
        
        if colKey.length != 0
            if not @colTotals[flatColKey]
                @colKeys.push colKey
                @colTotals[flatColKey] = @aggregator(this, [], colKey)
            @colTotals[flatColKey].push record

        if colKey.length != 0 and rowKey.length != 0
            if not @tree[flatRowKey]
                @tree[flatRowKey] = {}
            if not @tree[flatRowKey][flatColKey]
                @tree[flatRowKey][flatColKey] = @aggregator(this, rowKey, colKey)
            @tree[flatRowKey][flatColKey].push record

    getAggregator: (rowKey, colKey) =>
        flatRowKey = rowKey.join(String.fromCharCode(0))
        flatColKey = colKey.join(String.fromCharCode(0))
        if rowKey.length == 0 and colKey.length == 0
            agg = @allTotal
        else if rowKey.length == 0
            agg = @colTotals[flatColKey]
        else if colKey.length == 0
            agg = @rowTotals[flatRowKey]
        else
            agg = @tree[flatRowKey][flatColKey]
        return agg ? {value: (-> null), format: -> ""}