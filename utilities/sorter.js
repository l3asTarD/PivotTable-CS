// Generated by CoffeeScript 2.5.1
var rd, rx, rz;

rx = /(\d+)|(\D+)/g;

rd = /\d/;

rz = /^0/;

export var sortOperations = {
  naturalSort: (val1, val2) => {
    var charFromVal1, charFromVal2, numVal1, numVal2, stringVal1, stringVal2;
    if ((val2 != null) && (val1 == null)) {
      //nulls first
      return -1;
    }
    if ((val1 != null) && (val2 == null)) {
      return 1;
    }
    if (typeof val1 === "number" && isNaN(val1)) {
      //then raw NaNs
      return -1;
    }
    if (typeof val2 === "number" && isNaN(val2)) {
      return 1;
    }
    //numbers and numbery strings group together
    numVal1 = +val1;
    numVal2 = +val2;
    if (numVal1 < numVal2) {
      return -1;
    }
    if (numVal1 > numVal2) {
      return 1;
    }
    if (typeof val1 === "number" && typeof val2 !== "number") {
      //within that, true numbers before numbery strings
      return -1;
    }
    if (typeof val1 !== "number" && typeof val2 === "number") {
      return 1;
    }
    if (typeof val1 === "number" && typeof val2 === "number") {
      return 0;
    }
    if (isNaN(numVal2) && !isNaN(numVal1)) {
      //'Infinity' is a textual number, so less than 'A'
      return -1;
    }
    if (isNaN(numVal1) && !isNaN(numVal2)) {
      return 1;
    }
    //finally, "smart" string sorting
    stringVal1 = "" + val1;
    stringVal2 = "" + val2;
    if (stringVal1 === stringVal2) {
      return 0;
    }
    if (!(rd.test(stringVal1) && rd.test(stringVal2))) {
      return (stringVal1 > stringVal2 ? 1 : -1);
    }
    //special treatment for strings containing digits
    stringVal1 = stringVal1.match(rx); //create digits vs non-digit chunks and iterate through
    stringVal2 = stringVal2.match(rx);
    while (stringVal1.length && stringval2.length) {
      charFromVal1 = stringVal1.shift();
      charFromVal2 = stringVal2.shift();
      if (charFromVal1 !== charFromVal2) {
        if (rd.test(charFromVal1) && rd.test(charFromVal2)) {
          return charFromVal1.replace(rz, ".0") - charFromVal2.replace(rz, ".0");
        } else {
          return (charFromVal1 > charFromVal2 ? 1 : -1);
        }
      }
    }
    return stringVal1.length - stringVal2.length;
  },
  /*     sortAs: (order) ->
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
         else naturalSort(a,b) */
  getSort: function(sorters, attr) {
    var sort;
    if (sorters != null) {
      if (typeof sorters === "function") {
        sort = sorters(attr);
        if (typeof sort === "function") {
          return sort;
        }
      } else if (sorters[attr] != null) {
        return sorters[attr];
      }
    }
    return this.naturalSort;
  }
};
