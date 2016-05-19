
var exec = require("cordova/exec")

var SK = function () {}

SK.prototype.greet = function (name, cbOk, cbErr) {
  cordova.exec(cbOk, cbErr, "SKMain", "greet", [name])
}

SK.prototype.getProducts = function (ids, cbOk, cbErr) {
  cordova.exec(cbOk, cbErr, "SKMain", "getProducts", ids)
}

SK.prototype.getTransactions = function (cbOk, cbErr) {
  cordova.exec(function (r) {
    try {
      cbOk(JSON.parse(r))
    } catch (e) {
      console.warn('json parse error:', e)
      cbErr()
    }
  }, cbErr, "SKMain", "getTransactions")
}

SK.prototype.restoreCompletedTransactions = function (cbOk, cbErr) {
  cordova.exec(cbOk, cbErr, "SKMain", "restoreCompletedTransactions")
}

SK.prototype.order = function (pid, cbOk, cbErr) {
  cordova.exec(cbOk, cbErr, "SKMain", "order", [pid])
}

SK.prototype.finishTransaction = function (tid, cbOk, cbErr) {
  cordova.exec(cbOk, cbErr, "SKMain", "finishTransaction", [tid])
}

SK.prototype.getReceipt = function (cbOk, cbErr) {
  cordova.exec(cbOk, cbErr, "SKMain", "getReceipt")
}

SK.prototype.refreshReceipt = function (cbOk, cbErr) {
  cordova.exec(cbOk, cbErr, "SKMain", "refreshReceipt")
}

module.exports = new SK()

