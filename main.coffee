import { aggregatorTemplates } from "./aggregators/aggregators.js"
import { pivotTableRenderer } from "./renderers/pivotTableRenderer.js"
import { deepMerge } from "./utilities/deepMerge.js"
import { PivotData } from "./classes/pivotData.js"
import { sortOperations } from "./utilities/sorter.js"
import { aggregators, renderers, locales } from "./locales/en.js"
import { Sortable } from './sortablejs/modular/sortable.core.esm.js';

#Pivot table core
Element.prototype.pivot = (input, inputOpts, locale="en") ->
    locale = "en" if not locales[locale]?
    defaults =
        cols: []
        rows: []
        vals: []
        rowOrder: "key_a_to_z"
        colOrder: "key_a_to_z"
        dataClass: PivotData
        filter: -> true
        aggregator: aggregatorTemplates.count()()
        aggregatorName: "Count"
        sorters: {}
        derivedAttributes: {}
        renderer: pivotTableRenderer

    #Locale override
    localeStrings = deepMerge(true, locales.en.localeStrings, locales[locale].localeStrings)
    localeDefaults =
        rendererOptions: {localeStrings}
        localeStrings: localeStrings

    opts = deepMerge(true, localeDefaults, {defaults..., inputOpts...})

    result = null
    try
        pivotData = new opts.dataClass(input, opts)
        try
            result = opts.renderer(pivotData, opts.rendererOptions)
        catch e
            console.error(e.stack) if console?
            result = document.getElementsByTagName("span").textContent opts.localeStrings.renderError
    catch e
        console.error(e.stack) if console?
        result = document.getElementsByTagName("span").textContent opts.localeStrings.computeError
    
    x = this
    x.removeChild(x.lastChild) while x.hasChildNodes()
    return @append result

#Pivot table core with UI
Element.prototype.pivotUI = (input, inputOpts, overwrite = false, locale="en") ->  
    locale = "en" if not locales[locale]?
    defaults = 
        derivedAttributes: {}
        aggregators: locales[locale].aggregators
        renderers: locales[locale].renderers
        hiddenAttributes: []
        hiddenFromAggregators: []
        hiddenFromDragDrop: []
        menuLimit: 500
        cols: [], rows: [], vals: []
        rowOrder: "key_a_to_z"
        colOrder: "key_a_to_z"
        dataClass: PivotData
        exclusions: {}
        inclusions: {}
        unusedAttrsVertical: 85
        autoSortUnusedAttrs: false
        onRefresh: null
        showUI: true
        filter: -> true
        sorters: {}

    localeStrings = deepMerge(true, locales.en.localeStrings, locales[locale].localeStrings)
    localeDefaults =
        rendererOptions: {localeStrings}
        localeStrings: localeStrings

    existingOpts = this.dataPivotUIOptions
    if not existingOpts? or overwrite
        opts = deepMerge(true, localeDefaults, {defaults..., inputOpts...})
    else
        opts = existingOpts
 
    try
        attrValues = {}
        materializedInput = []
        recordsProcessed = 0
        
        PivotData.forEachRecord input, opts.derivedAttributes, (record) ->
            return unless opts.filter record
            materializedInput.push record
            for own attr of record
                if not attrValues[attr]?
                    attrValues[attr] = {}
                    if recordsProcessed > 0
                        attrValues[attr]["null"] = recordsProcessed
            for attr of attrValues
                value = record[attr] ? "null"
                attrValues[attr][value] ?= 0
                attrValues[attr][value]++
            recordsProcessed++

        #Start building the output
        uiTable = document.createElement("table")
        uiTable.className = "pvtUi"

        rendererControl = "<td class=\"pvtUiCell\">"
        renderer = "<select class=\"pvtRenderer\" id=\"renderer\">"
        selOpts = ""
        for own x of opts.renderers
            selOpts = selOpts + "<option value=\"#{x}\">#{x}</option>"
        renderer += selOpts + "</select>"
        rendererControl += renderer + "</td>"

        #Axis List, including the double-click menu
        shownAttributes = (a for a of attrValues when a not in opts.hiddenAttributes)
        shownInAggregators = (c for c in shownAttributes when c not in opts.hiddenFromAggregators)
        shownInDragDrop = (c for c in shownAttributes when c not in opts.hiddenFromDragDrop)

        unusedAttrsVerticalAutoOverride = false
        if opts.unusedAttrsVertical == "auto"
            unusedAttrsVerticalAutoCutoff = 120
        else
            unusedAttrsVerticalAutoCutoff = parseInt opts.unusedAttrsVertical

        if not isNaN(unusedAttrsVerticalAutoCutoff)
            attrLength = 0
            attrLength += a.length for a in shownInDragDrop
            unusedAttrsVerticalAutoOverride = attrLength > unusedAttrsVerticalAutoCutoff

        unused = document.createElement("td")
        if opts.unusedAttrsVertical == true or unusedAttrsVerticalAutoOverride
            unused.className = "pvtAxisContainer pvtUnused pvtUiCell pvtVertList"
        else
            unused.className = "pvtAxisContainer pvtUnused pvtUiCell pvtHorizList"

        #toggle class name of checkboxes
        altToggleClass = ->
            if this.className == "pvtFilter"
                this.className = "pvtFilter changed"
            else
                this.className = "pvtFilter"

        #for triangle link distinction
        triId = 1
        for own i, attr of shownInDragDrop
            do (attr) ->
                values = (v for v of attrValues[attr])
                hasExcludedItem = false
                
                valueList = document.createElement("div")
                valueList.className = "pvtFilterBox"
                valueList.style.display = "none"
                valueListStr = "<h4>
                            <span>#{attr}</span>
                            <span class=\"count\">\"(#{values.length})\"</span>
                            </h4>"
                valueList.insertAdjacentHTML("beforeend", valueListStr)
                if values.length > opts.menuLimit
                    valueListStr = "<p>#{opts.localeStrings.tooMany}</p>"
                    valueList.insertAdjacentHTML("beforeend", valueListStr)
                else
                    if values.length > 5
                        controls = "<p>"
                        sorter = sortOperations.getSort(opts.sorters, attr)
                        placeholder = opts.localeStrings.filterResults

                        #onkeyup event for text input
                        inputListener = ->
                            inputFilter = this.value.toLowerCase().trim()
                            accept_gen = (prefix, accepted) -> (v) ->
                                real_filter = inputFilter.substring(prefix.length).trim()
                                return true if real_filter.length == 0
                                return Math.sign(sorter(v.toLowerCase(), real_filter)) in accepted
                            accept =
                                if inputFilter.indexOf(">=") == 0 then accept_gen(">=", [1,0])
                                else if inputFilter.indexOf("<=") == 0 then accept_gen("<=", [-1,0])
                                else if inputFilter.indexOf(">") == 0 then accept_gen(">", [1])
                                else if inputFilter.indexOf("<") == 0 then accept_gen("<", [-1])
                                else if inputFilter.indexOf("~") == 0 then (v) ->
                                    return true if inputFilter.substring(1).trim().length == 0
                                    v.toLowerCase().match(inputFilter.substring(1))
                                else (v) -> v.toLowerCase().indexOf(inputFilter) != -1
                            
                            spanValQuery = valueList.querySelectorAll('.pvtCheckContainer .value')
                            for spanElem in spanValQuery
                                if accept(spanElem.textContent)
                                    spanElem.parentNode.parentNode.style.display = "block"
                                else
                                    spanElem.parentNode.parentNode.style.display = "none"

                        controls += "<input type=\"text\" placeholder=\"#{placeholder}\" 
                        class=\"pvtSearch\" data-target=\"axis_#{i}\"></p><br>"

                        #click listeners for "select-all" and "select-none" buttons
                        selAllLstnr = ->
                            selQuery = checkContainer.querySelectorAll('.pvtFilter')
                            if selQuery != 0 
                                for elem in selQuery
                                    if elem.parentNode.parentNode.style.display != "none"
                                        if !elem.checked
                                            elem.checked = true
                                        if elem.className == "pvtFilter"
                                            elem.className = "pvtFilter changed"
                                        else
                                            elem.className = "pvtFilter"
                            false
                        selNoneLstnr = ->
                            selQuery = checkContainer.querySelectorAll('.pvtFilter')
                            if selQuery != 0 
                                for elem in selQuery
                                    if elem.parentNode.parentNode.style.display != "none"
                                        if elem.checked
                                            elem.checked = false
                                        if elem.className == "pvtFilter"
                                            elem.className = "pvtFilter changed"
                                        else
                                            elem.className = "pvtFilter"
                            false
                        controls += "<button type=\"button\" id=\"selAll\">#{opts.localeStrings.selectAll}</button>"
                        controls += "<button type=\"button\" id=\"selNone\">#{opts.localeStrings.selectNone}</button>"
                        valueList.insertAdjacentHTML("beforeend", controls)
                        
                        #Add event listeners to select-all, select-none and search filter
                        searchFilter = valueList.querySelectorAll(".pvtSearch")
                        for el in searchFilter
                            el.addEventListener("keyup",inputListener)
                        selAll = valueList.querySelector("#selAll")
                        selAll.addEventListener("click",selAllLstnr)
                        selNone = valueList.querySelector("#selNone")
                        selNone.addEventListener("click",selNoneLstnr)
                    
                    checkContainer = "<div class=\"pvtCheckContainer\" id=\"chckContainer\">"

                    for value in values.sort(sortOperations.getSort(opts.sorters, attr))
                        valueCount = attrValues[attr][value]
                        filterItem = "<p><label>"
                        filterItemExcluded = false
                        if opts.inclusions[attr]
                            filterItemExcluded = (value not in opts.inclusions[attr])
                        else if opts.exclusions[attr]
                            filterItemExcluded = (value in opts.exclusions[attr])
                        hasExcludedItem ||= filterItemExcluded
                        defaultState = (if not filterItemExcluded then "checked" else "")
                        filterItem += "<input type=\"checkbox\" class=\"pvtFilter\" data-filter=\"#{attr+","+value}\" #{defaultState}>"
                        filterItem += "<span class=\"value\">#{value}</span>"
                        filterItem += "<span class=\"count\">\"(\"#{valueCount}\")\"</span></label></p>"
                        checkContainer += filterItem
                    valueList.insertAdjacentHTML("beforeend",checkContainer)
                    checkContainer = valueList.querySelector("#chckContainer")

                    filterBoxList = valueList.querySelectorAll(".pvtFilter")
                    for el in filterBoxList
                        el.addEventListener("change", altToggleClass)
                
                closeFilterBox = (target) ->
                    checked = 0
                    cBoxes = valueList.querySelectorAll('[type="checkbox"]')
                    targetAxis = document.querySelector(".#{target}")
                    for el in cBoxes
                        checked++ unless !el.checked
                    if cBoxes.length > checked
                        targetAxis.classList.add("pvtFilteredAttribute")
                    else
                        targetAxis.classList.remove("pvtFilteredAttribute")
                    pvtSearchList = valueList.querySelectorAll(".pvtSearch")
                    for el in pvtSearchList
                        el.value = ""
                    containerList = valueList.querySelectorAll(".pvtCheckContainer p")
                    for el in containerList
                        el.style.display = "block"
                    valueList.style.display = "none"

                finalButtons = "<p>"
                if hasExcludedItem
                    attrElem = "<li class=\"axis_#{i} pvtFilteredAttribute\">"
                else
                    attrElem = "<li class=\"axis_#{i}\">"
                
                applyLstnr = ->
                    applyQuery = valueList.querySelectorAll('.changed')
                    for el in applyQuery
                        el.classList.remove("changed")
                    console.log(applyQuery)
                    refresh() unless applyQuery==0
                    closeFilterBox(this.dataset.target)

                if values.length <= opts.menuLimit
                    finalButtons += "<button type=\"button\" id=\"applyBtn\" 
                    data-target=\"axis_#{i}\">#{opts.localeStrings.apply}</button>"
                    
                cancelLstnr = ->
                    cancelQuery = valueList.querySelectorAll('.changed')
                    for el in cancelQuery
                        if el.checked
                            el.checked = false
                        else
                            el.checked = true
                        el.classList.remove("changed")
                    closeFilterBox(this.dataset.target)
                finalButtons += "<button type\"button\" id=\"cancelBtn\" 
                data-target=\"axis_#{i}\">#{opts.localeStrings.cancel}</button></p>"
                valueList.insertAdjacentHTML("beforeend", finalButtons)
                cancelBtn = valueList.querySelector("#cancelBtn")
                applyBtn = valueList.querySelector("#applyBtn")
                cancelBtn.addEventListener("click", cancelLstnr)
                applyBtn.addEventListener("click", applyLstnr)

                triangleLinkLstnr = ->
                    position = 
                        left: this.offsetLeft
                        top: this.offsetTop
                    valueList.style.top = position.top+10
                    valueList.style.left = position.left+10
                    valueList.style.display = "block"
                triangleLink = "<span class=\"pvtTriangle\" id=\"tri_#{triId}\">&#x25BE;</span>"
                attrElem += "<span class=\"pvtAttr\" data-attrname=\"#{attr}\">#{attr+triangleLink}</span></li>"
                unused.insertAdjacentHTML("beforeend",attrElem)
                unused.appendChild(valueList)
                triLink = unused.querySelector("#tri_#{triId}")
                triLink.addEventListener("click", triangleLinkLstnr)
                triId++

        #aggregator menu and value area
        aggregator = "<select class=\"pvtAggregator\" id=\"aggr\">"
        for own x of opts.aggregators
            aggregator += "<option value=\"#{x}\">#{x}</option>"
        aggregator += "</select>"

        ordering =
            key_a_to_z: {rowSymbol: "\u2195", colSymbol: "\u2194", next: "value_a_to_z"}
            value_a_to_z: {rowSymbol: "\u2193", colSymbol: "\u2192", next: "value_z_to_a"}
            value_z_to_a: {rowSymbol: "\u2191", colSymbol: "\u2190", next: "key_a_to_z"}

        rowOrderLstnr = ->
            this.dataset.order = ordering[this.dataset.order].next
            this.textContent = ordering[this.dataset.order].rowSymbol
            refresh()
        rowOrderArrow = "<a role=\"button\" class=\"pvtRowOrder\" data-order=\"#{opts.rowOrder}\" 
        id=\"rowOrder\">#{ordering[opts.rowOrder].rowSymbol}</a>"

        colOrderLstnr = ->
            this.dataset.order = ordering[this.dataset.order].next
            this.textContent = ordering[this.dataset.order].colSymbol
            refresh()
        colOrderArrow = "<a role=\"button\" class=\"pvtColOrder\" data-order=\"#{opts.colOrder}\"
        id=\"colOrder\">#{ordering[opts.colOrder].colSymbol}</a>"

        tr1 = "<tr id=\"tr1\">"
        menu = "<td class=\"pvtVals pvtUiCell\"> #{aggregator+rowOrderArrow+colOrderArrow}<br></td>"
        tr1 += menu + "<td class=\"pvtAxisContainer pvtHorizList pvtUiCell pvtCols\" id=\"pvtCol\"></td></tr>"
        uiTable.insertAdjacentHTML("beforeend", tr1)
        aggregator = uiTable.querySelector("#aggr")
        rowOrderArrow = uiTable.querySelector("#rowOrder")
        rowOrderArrow.addEventListener("click", rowOrderLstnr)
        colOrderArrow = uiTable.querySelector("#colOrder")
        colOrderArrow.addEventListener("click", colOrderLstnr)
        uiTable = uiTable.querySelector("tbody")
        aggregator.addEventListener("change",-> refresh())

        tr2 = "<tr><td class=\"pvtAxisContainer pvtUiCell pvtRows\" id=\"pvtRow\" style=\"vertical-align: top;\"></td>"
        #the actual pivot table container
        pivotTable = "<td class=\"pvtRendererArea\" style=\"vertical-align:top;\" id=\"pivotTable\"></td></tr>"
        tr2 += pivotTable
        uiTable.insertAdjacentHTML("beforeend",tr2)
        pivotTable = uiTable.querySelector("#pivotTable")

        #finally the renderer dropdown and unused attributes are inserted at the requested location
        if opts.unusedAttrsVertical == true or unusedAttrsVerticalAutoOverride
            fChild = uiTable.querySelector('tr:nth-child(1)')
            fChild.insertAdjacentHTML("afterbegin",rendererControl)
            sChild = uiTable.querySelector('tr:nth-child(2)')
            sChild.prepend(unused)
        else
            ctrlContainer = document.createElement("tr")
            ctrlContainer.insertAdjacentHTML("beforeend",rendererControl)
            ctrlContainer.appendChild(unused)
            uiTable.prepend(ctrlContainer)
        renderer = uiTable.querySelector("#renderer")
        renderer.addEventListener("change",-> refresh())

        #render the UI in its default state
        this.appendChild uiTable

        #setup the UI initial state as requested by moving elements around
        colElems = this.querySelector("#pvtCol")
        colElemsFrag = document.createDocumentFragment()
        rowElems = this.querySelector("#pvtRow")
        rowElemsFrag = document.createDocumentFragment()
        for x in opts.cols
            axisElems = this.querySelector(".axis_#{shownInDragDrop.indexOf(x)}")
            colElemsFrag.appendChild axisElems
        for x in opts.rows
            axisElems = this.querySelector(".axis_#{shownInDragDrop.indexOf(x)}")
            rowElemsFrag.appendChild axisElems
        colElems.appendChild colElemsFrag
        rowElems.appendChild rowElemsFrag
        
        if opts.aggregatorName?
            aggEl = this.querySelector("#aggr")
            aggEl.value = opts.aggregatorName
        if opts.rendererName?
            renEl = this.querySelector("#renderer")
            renEl.value = opts.rendererName

        uiCellList = this.querySelectorAll(".pvtUiCell")
        if not opts.showUI
            for el in uiCellList
                el.style.display = "none"
        initialRender = true

        #set up for refreshing
        refreshDelayed = =>
            #startTime = performance.now()
            subopts =
                derivedAttributes: opts.derivedAttributes
                localeStrings: opts.localeStrings
                rendererOptions: opts.rendererOptions
                sorters: opts.sorters
                cols: []
                rows: []
                dataClass: opts.dataClass
            
            numInputsToProcess = opts.aggregators[aggregator.value]([])().numInputs ? 0
            vals = []
            pvtRowList = this.querySelectorAll('#pvtRow .pvtAttr')
            for el in pvtRowList
                subopts.rows.push el.dataset.attrname
            pvtColList = this.querySelectorAll('#pvtCol .pvtAttr')
            for el in pvtColList
                subopts.cols.push el.dataset.attrname
            dDownList = this.querySelectorAll('.pvtAttrDropdown')
            for el in dDownList
                if numInputsToProcess == 0
                    el.parentNode.removeChild(el)
                else
                    numInputsToProcess--
                    vals.push el.value if el.value != ""
            
            if numInputsToProcess != 0
                pvtVals = this.querySelectorAll('.pvtVals')
                newDropdown = "<select class=\"pvtAttrDropdown\" id=\"newDropDown\">"
                for x in [0...numInputsToProcess]
                    for attr in shownInAggregators
                        newDropdown += "<option value=\"#{attr}\">#{attr}</option>"
                pvtVals[0].insertAdjacentHTML("beforeend",newDropdown+"</select>")
                dDown = pvtVals[0].querySelector("#newDropDown")
                dDown.addEventListener("change",-> refresh())
            
            if initialRender
                vals = opts.vals
                i = 0
                elList = this.querySelectorAll(".pvtAttrDropdown")
                for el in elList
                    el.value = vals[i]
                    i++
                initialRender = false

            subopts.aggregatorName = aggregator.value
            subopts.vals = vals
            subopts.aggregator = opts.aggregators[aggregator.value](vals)
            subopts.renderer = opts.renderers[renderer.value]
            subopts.rowOrder = rowOrderArrow.dataset.order
            subopts.colOrder = colOrderArrow.dataset.order

            #construct filter here
            exclusions = {}
            inclusions = {}
            elList = this.querySelectorAll('.pvtFilter')
            for el in elList
                if !el.checked
                    filter = el.dataset.filter
                    filter = filter.split(',')
                    if exclusions[filter[0]]?
                        exclusions[filter[0]].push(filter[1])
                    else
                        exclusions[filter[0]] = [filter[1]]
                else
                    filter = el.dataset.filter
                    filter = filter.split(',')
                    if exclusions[filter[0]]?
                        if inclusions[filter[0]]?
                            inclusions[filter[0]].push(filter[1])
                        else
                            inclusions[filter[0]] = [filter[1]]

            subopts.filter = (record) ->
                return false if not opts.filter(record)
                for k,excludedItems of exclusions
                    return false if ""+(record[k] ? 'null') in excludedItems
                return true

            pivotTable.pivot(materializedInput,subopts)
            uiOpts = 
                cols: subopts.cols
                rows: subopts.rows
                colOrder: subopts.colOrder
                rowOrder: subopts.rowOrder
                vals: vals
                exclusions: exclusions
                inclusions: inclusions
                inclusionsInfo: inclusions #duplicated for backwards-compatibility
                aggregatorName: aggregator.value
                rendererName: renderer.value
            pivotUIOptions = {opts...,uiOpts}

            this.dataPivotUIOptions = pivotUIOptions
            #if requested make sure unused columns are in alphabetical order
            #To be implemented
            if opts.autoSortUnusedAttrs
                alert("Found use of property: autoSortUnusedAttrs")

            pivotTable.style.opacity = 1
            opts.onRefresh(pivotUIOptions) if opts.onRefresh?
            #endTime = performance.now()
            #console.log(endTime-startTime)
        
        refresh = =>
            pivotTable.style.opacity = 0.5
            setTimeout(refreshDelayed, 10)
        
        #the very first refresh will display the table
        refresh()

        sortableContainers = document.querySelectorAll(".pvtAxisContainer")
        for el in sortableContainers
            Sortable.create(el, {
                group:'sortables'
                onAdd: -> refresh()
                ghostClass: 'pvtPlaceholder'
            })

    catch e
        console.error(e.stack) if console?
        this.textContent = opts.localeStrings.uiRendererError
    return this
