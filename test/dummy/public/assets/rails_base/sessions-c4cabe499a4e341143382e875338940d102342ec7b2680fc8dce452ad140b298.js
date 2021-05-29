// TODO: ADD a readme about how this works
// TODO: Clean this up
var SessionsSingleton = function () {
  var SessionsClass = function SessionsClass() {
    return {
      sessionTimoutClock: undefined,
      reminderClock: undefined,
      reminderTime: 60000, // 1min prior to expiration
      timeout: undefined,
      url_get: undefined,
      url_post: undefined,
      ajax_timing: undefined,

      init: function init(timeout, url_get, url_post, csrf, show_warning) {
        var _self = this;
        _self.timeout = timeout * 1000;
        _self.url_get = url_get;
        _self.url_post = url_post;
        _self.csrf = csrf;
        _self.show_warning = show_warning;

        _self.logging(`Initialized. timeout ${_self.timeout}`)

        _self.sessionTimoutClock = window.setTimeout(function () {
          return _self.checkForWarning();
        }, _self.timeout + 500);

        if(!_self.show_warning){
          return;
        }
        return _self.reminderClock = window.setTimeout(function () {
          return _self.checkForWarning();
        }, _self.timeout - _self.reminderTime);
      },
      checkForWarning: function checkForWarning() {
        var _self = this;
        _self.ajax_timing = new Date();
        _self.logging(`Heartbeat warning`)
        $.ajax({
          type: 'GET',
          url: _self.url_get,
          success: function success(result) {
            _self.logging(`TTL check success: ${JSON.stringify(result)}`)
            _self.warningHeartbeatSuccess(result);
          },
          error: function error() {
            _self.logging(`TTL check failed. Reloading page`)
            return _self.doRedirect();
          }
        });
      },
      checkForSessionHeartbeat: function checkForSessionHeartbeat(){
        var _self = this;
        _self.ajax_timing = new Date()
        $.ajax({
          type: 'GET',
          url: _self.url_get,
          success: function success(result) {
            _self.logging(`TTL check success: ${JSON.stringify(result)}`)
            _self.ajaxPollTtlServer(result);
          },
          error: function error() {
            _self.logging(`TTL check failed. Reloading page`)
            return _self.doRedirect();
          }
        });
      },
      latency: function latency() {
        var _self = this;
        // milliseconds difference
        return ((new Date() - _self.ajax_timing));
      },
      warningHeartbeatSuccess: function warningHeartbeatSuccess(result) {
        var _self = this;
        var ttlMs = result.ttl * 1000
        var latency = _self.latency();
        var skew = (ttlMs - _self.reminderTime);
        _self.logging(`latency ${latency}ms`)
        _self.logging(`skew ${skew}ms`)
        // if the skew more than 5 seconds
        // reset the clock to that time
        if(skew>5000) {
          _self.logging(`Skew is high. Resetting clock`)
          _self.resetClock(ttlMs)
          closeSessionWarning();
        } else {
          _self.logging(`Within skew. Showing countdown`)

          showSessionWarning(result.ttl);
        }
      },
      ajaxPollTtlServer: function ajaxPollTtlServer() {
        var _self = this;
        _self.ajax_timing = new Date()
        $.ajax({
          type: 'POST',
          url: _self.url_post,
          headers: { 'X-CSRF-Token': _self.csrf },
          success: function success(result) {
            _self.logging(`POST Heartbeat success: ${JSON.stringify(result)}`)
            // TTL comes from server as seconds -- convert to ms
            closeSessionWarning();
            return _self.resetClock(result.ttl * 1000);
          },
          error: function error() {
            _self.logging(`POST TTL check failed. Reloading page`)
            return _self.doRedirect();
          }
        });
      },
      doRedirect: function doRedirect() {
        return window.location.search += '&timeout';
      },
      resetClock: function resetClock(timeout) {
        var _self = this;
        var timeout = timeout / 1000;
        _self.logging(`Clock Reset timout: ${timeout}`)
        var url_get = _self.url_get;
        var url_post = _self.url_post;
        var csrf = _self.csrf;
        var show_warning = _self.show_warning;
        _self.destroy();
        return _self.init(timeout, url_get, url_post, csrf, show_warning);
      },
      destroy: function destroy() {
        var _self = this;
        window.clearTimeout(_self.reminderClock);
        window.clearTimeout(_self.sessionTimoutClock);
        _self.sessionTimoutClock = undefined;
        _self.reminderClock = undefined;
        _self.timeout = undefined;
        return;
      },
      logging: function logging(msg){
        console.log(`${new Date().toJSON()}: SessionManager - ${msg}`)
      }
    };
  };

  var instance = undefined;
  return {
    getInstance: function getInstance() {
      if (instance == null) {
        instance = new SessionsClass();
        instance.constructor = null;
      }
      return instance;
    }
  };
}();

var sessionManager = SessionsSingleton.getInstance();
