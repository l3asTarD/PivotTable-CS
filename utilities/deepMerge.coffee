export deepMerge = (args...) ->
  extended = {}
  deep = false
  i = 0;

  if typeof args[i] == "boolean"
    deep = args[i]
    i++

  merge = (obj) ->
    for prop of obj
      if Object.prototype.hasOwnProperty.call( obj, prop )
        if deep and Object.prototype.toString.call(obj[prop]) == '[object Object]'
          extended[prop] = deepMerge(true, extended[prop], obj[prop])
        else if deep and Array.isArray(obj[prop])
          if extended[prop] == undefined
            extended[prop] = obj[prop]
          else
            Array.prototype.splice.apply(extended[prop], [0, obj[prop].length].concat(obj[prop]))
        else
          extended[prop] = obj[prop]

  while i < args.length
    obj = args[i]
    merge(obj)
    i++

  extended