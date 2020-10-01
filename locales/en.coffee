import { aggregatorTemplates } from "../aggregators/aggregators.js"
import { pivotTableRenderer } from "../renderers/pivotTableRenderer.js"
import { numberFormat } from "../utilities/numberOperations.js"

usFmt = numberFormat()
usFmtInt = numberFormat(digitsAfterDecimal: 0)
usFmtPct = numberFormat(digitsAfterDecimal: 1, scaler: 100, suffix: "%")

#default aggregators & renderers use US naming and number formatting
export aggregators = do (tpl = aggregatorTemplates) ->
    "Count":                tpl.count(usFmtInt)
    "Count Unique Values":  tpl.countUnique(usFmtInt)
    "List Unique Values":   tpl.listUnique(", ")
    "Sum":                  tpl.sum(usFmt)
    "Integer Sum":          tpl.sum(usFmtInt)
    "Average":              tpl.average(usFmt)
    "Median":               tpl.median(usFmt)
    "Sample Variance":      tpl.var(1, usFmt)
    "Sample Standard Deviation": tpl.stdev(1, usFmt)
    "Minimum":              tpl.min(usFmt)
    "Maximum":              tpl.max(usFmt)
    "First":                tpl.first(usFmt)
    "Last":                 tpl.last(usFmt)
    "Sum over Sum":         tpl.sumOverSum(usFmt)
    "80% Upper Bound":      tpl.sumOverSumBound80(true, usFmt)
    "80% Lower Bound":      tpl.sumOverSumBound80(false, usFmt)
    "Sum as Fraction of Total":     tpl.fractionOf(tpl.sum(),   "total", usFmtPct)
    "Sum as Fraction of Rows":      tpl.fractionOf(tpl.sum(),   "row",   usFmtPct)
    "Sum as Fraction of Columns":   tpl.fractionOf(tpl.sum(),   "col",   usFmtPct)
    "Count as Fraction of Total":   tpl.fractionOf(tpl.count(), "total", usFmtPct)
    "Count as Fraction of Rows":    tpl.fractionOf(tpl.count(), "row",   usFmtPct)
    "Count as Fraction of Columns": tpl.fractionOf(tpl.count(), "col",   usFmtPct)

export renderers =
    "Table": (data, opts) ->   pivotTableRenderer(data, opts)

export locales =
    en:
        aggregators: aggregators
        renderers: renderers
        localeStrings:
            renderError: "An error occurred rendering the PivotTable results."
            computeError: "An error occurred computing the PivotTable results."
            uiRenderError: "An error occurred rendering the PivotTable UI."
            selectAll: "Select All"
            selectNone: "Select None"
            tooMany: "(too many to list)"
            filterResults: "Filter values"
            apply: "Apply"
            cancel: "Cancel"
            totals: "Totals" #for table renderer