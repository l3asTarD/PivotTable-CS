// Generated by CoffeeScript 2.5.1
var addSeparators;

addSeparators = function(numToConvert, thousandsSep, decimalSep) {
  var decimalPart, numParts, rgx, wholePart;
  numToConvert += '';
  numParts = numToConvert.split('.');
  wholePart = numParts[0];
  decimalPart = numParts.length > 1 ? decimalSep + numParts[1] : '';
  rgx = /(\d+)(\d{3})/;
  while (rgx.test(wholePart)) {
    wholePart = wholePart.replace(rgx, '$1' + thousandsSep + '$2');
  }
  return wholePart + decimalPart;
};

export var numberFormat = function(options) {
  var defaults;
  defaults = {
    digitsAfterDecimal: 2,
    scaler: 1,
    thousandsSep: ",",
    decimalSep: ".",
    prefix: "",
    suffix: ""
  };
  options = {...defaults, ...options};
  return function(x) {
    var result;
    if (isNaN(x) || !isFinite(x)) {
      return "";
    } else {
      result = addSeparators((options.scaler * x).toFixed(options.digitsAfterDecimal), options.thousandsSep, options.decimalSep);
      return options.prefix + result + options.suffix;
    }
  };
};

export var defaultFormat = {
  usFormat: numberFormat(),
  usFormatInt: numberFormat({
    digitsAfterDecimal: 0
  }),
  usFormatPct: numberFormat({
    digitsAfterDecimal: 1,
    scaler: 100,
    suffix: "%"
  })
};
