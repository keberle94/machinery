$(document).ready(function () {
  // Render the system description
  var description = getDescription()

  templates = {}
  scopes = [
    "os",
    "changed_managed_files",
    "config_files",
    "unmanaged_files",
    "groups",
    "users",
    "packages",
    "patterns",
    "repositories",
    "services"
  ]


  // Enrich description with meta information summaries
  description.meta_info = {}
  $.each(scopes, function(index, scope) {
    if(description.meta[scope]) {
      description.meta_info[scope] = " (" +
        "inspected host: '" + description.meta[scope].hostname + "', " +
        "at: " + new Date(description.meta[scope].modified).toLocaleString() + ")"
    }
  })

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

  $('.scope_logo_big').each(function(){
    var icon = $(this)
    var pos = icon.offset()
    var container = icon.closest(".scope")
    var bottom_boundary = container.offset().top + container.height() - 20
    $(window).scroll(function() {
      var top_pos = $(this).scrollTop() + header_height;
      var bottom_pos = top_pos + icon.height();
      if(top_pos >= pos.top && icon.css('position') == 'static') {
        icon.addClass('fixed').css("top", header_height);
      } else if(top_pos <= pos.top && icon.hasClass('fixed')) {
        icon.removeClass('fixed');
      }
    })
  })

  // Set meta information in scope headers
  $('')
})
