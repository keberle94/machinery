$(document).ready(function () {
  // Render the system description
  var description = getDescription()
  templates = {}
  scopes = [
    "os",
    "changed-managed-files",
    "config-files",
    "unmanaged-files",
    "groups",
    "users",
    "packages",
    "patterns",
    "repositories",
    "services"
  ]
  $.each(scopes, function(index, scope) {
    templates[scope] = Hogan.compile($("#scope_" + scope).html())
  })

  template = Hogan.compile($('#content').html())
  $("#content_container").html(
    template.render(description, templates)
  )

  // Implement filter functionality
  var run_when_done_typing = (function(){
    var timer = 0;
    return function(callback, timeout){
      clearTimeout(timer);
      timer = setTimeout(callback, timeout);
      };
  })()

  $("#filter").keyup(function() {
    run_when_done_typing(function() {
      var rows = $("body").find("tr");
      if($("#filter").val() == "") {
        rows.show();
        return;
      }

      var filters = $("#filter").val().split(" ");

      rows
        .hide()
        .filter(function() {
          var $t = $(this);
          for(var i = 0; i < filters.length; ++i) {
            if($t.is(":contains('" + filters[i] + "')")) {
              return true;
            }
          }
          return false;
        })
        .show();
    }, 500)
  })

  // Align content below floating menu
  var header_height =  $("#nav-bar").height() + 20
  $("#content_container").css("margin-top", header_height)
  $("a.scope_anchor").css("height", header_height)
  $("a.scope_anchor").css("margin-top", -header_height)
})
