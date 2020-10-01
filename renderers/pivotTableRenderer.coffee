import { deepMerge } from "../utilities/deepMerge.js"

export pivotTableRenderer = (pivotData, opts) ->
    defaults =
        table:
            rowTotals: true
            colTotals: true
        localeStrings: totals: "Totals"

    opts = deepMerge(true, defaults, opts)
    colAttrs = pivotData.colAttrs
    rowAttrs = pivotData.rowAttrs
    rowKeys = pivotData.getRowKeys()
    colKeys = pivotData.getColKeys()
    #console.log(pivotData)

    spanSize = (arr, i, j) ->
        if i != 0
            noDraw = true
            for x in [0..j]
                if arr[i-1][x] != arr[i][x]
                    noDraw = false
            if noDraw
                return -1 #do not draw cell
        len = 0
        while i+len < arr.length
            stop = false
            for x in [0..j]
                stop = true if arr[i][x] != arr[i+len][x]
            break if stop
            len++
        return len

    #the first few rows are for col headers
    result = document.createElement("table")
    result.className = "pvtTable"
    thead = document.createElement("thead")
    theadFrag = document.createDocumentFragment()
    for own j, c of colAttrs
        tr = document.createElement("tr")
        if parseInt(j) == 0 and rowAttrs.length != 0
            th = "<th colspan=\"#{rowAttrs.length}\" rowspan=\"#{colAttrs.length}\"></th>"
            tr.insertAdjacentHTML "beforeend", th
        th = "<th class=\"pvtAxisLabel\">#{c}</th>"
        tr.insertAdjacentHTML "beforeend", th
        for own i, colKey of colKeys
            x = spanSize(colKeys, parseInt(i), parseInt(j))
            if x != -1
                th = "<th class=\"pvtColLabel\" colspan=\"#{x}\">#{colKey[j]}</th>"
                if parseInt(j) == colAttrs.length-1 and rowAttrs.length != 0
                    th = "<th class=\"pvtColLabel\" colspan=\"#{x}\" rowspan=\"2\">#{colKey[j]}</th>"
                tr.insertAdjacentHTML "beforeend", th
        if parseInt(j) == 0 && opts.table.rowTotals
            rSpan = colAttrs.length + (if rowAttrs.length ==0 then 0 else 1)
            th = "<th class=\"pvtTotalLabel pvtRowTotalLabel\" rowspan=\"#{rSpan}\">
            #{opts.localeStrings.totals}</th>"
            tr.insertAdjacentHTML "beforeend", th
        theadFrag.appendChild tr
            
    #then a row for row header headers
    if rowAttrs.length !=0
        tr = document.createElement("tr")
        for own i, r of rowAttrs
            th = "<th class=\"pvtAxisLabel\">#{r}</th>"
            tr.insertAdjacentHTML "beforeend", th
        th = "<th></th>"
        if colAttrs.length ==0
            th = "<th class=\"pvtTotalLabel pvtRowTotalLabel\">#{opts.localeStrings.totals}</th>"
        tr.insertAdjacentHTML "beforeend", th
        theadFrag.appendChild tr
    thead.appendChild theadFrag
    result.appendChild thead
    
    #now the actual data rows, with their row headers and totals
    tbody = document.createElement("tbody")
    tbodyFrag = document.createDocumentFragment()
    for own i, rowKey of rowKeys
        tr = document.createElement("tr")
        for own j, txt of rowKey
            x = spanSize(rowKeys, parseInt(i), parseInt(j))
            if x != -1
                th = "<th class=\"pvtRowLabel\" rowspan=\"#{x}\">#{txt}</th>"
                if parseInt(j) == rowAttrs.length-1 and colAttrs.length !=0
                    th = "<th class=\"pvtRowLabel\" rowspan=\"#{x}\" colspan=\"2\">#{txt}</th>"
                tr.insertAdjacentHTML("beforeend", th)
        for own j, colKey of colKeys #this is the tight loop
            aggregator = pivotData.getAggregator(rowKey, colKey)
            val = aggregator.value()
            td = "<td class=\"pvtVal row#{i} col#{j}\" data-value=\"#{val}\">#{aggregator.format(val)}</td>"
            tr.insertAdjacentHTML "beforeend", td

        if opts.table.rowTotals || colAttrs.length == 0
            totalAggregator = pivotData.getAggregator(rowKey, [])
            val = totalAggregator.value()
            td = "<td class=\"pvtTotal rowTotal\" data-value=\"#{val}\">#{totalAggregator.format(val)}</td>"
            tr.insertAdjacentHTML "beforeend", td
        tbodyFrag.appendChild tr

    #finally, the row for col totals, and a grand total
    if opts.table.colTotals || rowAttrs.length == 0
        tr = document.createElement("tr")
        if opts.table.colTotals || rowAttrs.length == 0
            cSpan = rowAttrs.length + (if colAttrs.length == 0 then 0 else 1)
            th = "<th class=\"pvtTotalLabel pvtColTotalLabel\" colspan=\"#{cSpan}\">#{opts.localeStrings.totals}</th>"
            tr.insertAdjacentHTML "beforeend", th
        for own j, colKey of colKeys
            totalAggregator = pivotData.getAggregator([], colKey)
            val = totalAggregator.value()
            td = "<td class=\"pvtTotal colTotal\" data-value=\"#{val}\" data-for=\"col#{j}\">
            #{totalAggregator.format(val)}</td>"
            tr.insertAdjacentHTML "beforeend", td
        if opts.table.rowTotals || colAttrs.length == 0
            totalAggregator = pivotData.getAggregator([], [])
            val = totalAggregator.value()
            td = "<td class=\"pvtGrandTotal\" data-value=\"#{val}\">#{totalAggregator.format(val)}</td>"
            tr.insertAdjacentHTML "beforeend", td
        tbodyFrag.appendChild tr
    tbody.appendChild tbodyFrag
    result.appendChild tbody

    #squirrel this away for later
    result.setAttribute("data-numrows", rowKeys.length)
    result.setAttribute("data-numcols", colKeys.length)
    result