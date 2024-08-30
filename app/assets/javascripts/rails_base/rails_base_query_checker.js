
function _railsBase_urlParams(param){
  urlParams = new URLSearchParams(window.location.search);
  return urlParams.get(param);
}

function _railsBase_goToStandardizedCollapse(q_param, identifier, function_base_name, function_yield){
  param = _railsBase_urlParams(q_param)
  if(param==null){
    return false
  }

  // Let callee decide if they want to continue
  if(typeof(function_yield) === "function") {
    if (function_yield(param) != true) {
      // Callee does not want to continue
      return
    }
  } else {
    // No function provided. Since the param was present, we will continue as expected
  }

  // Scroll to top of provided class
  $('html, body').animate({
    scrollTop: $(`${identifier}`).offset().top
  }, 'slow');


  // function name declared for the collapsable options
  // Toggle it and open it up
  console.log(`trying to open ${function_base_name}_collapse_toggle()`)
  eval(`${function_base_name}_collapse_toggle()`)

  return param
}

