// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
// = require rails-ujs
// = require activestorage
// = require turbolinks
// = require jquery3
// = require_tree .
// = require popper
// = require bootstrap-sprockets
// = require allow_numeric
// = require jquery.mask


function set_cookie(name, value) {
  document.cookie = `${name}=${value}`
}

function get_cookie(name) {
  var cookie = document.cookie
  return cookie.split('; ').find(row => row.startsWith(`${name}=`)).split('=')[1];
}
