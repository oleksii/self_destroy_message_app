$(function () {
  $("[data-method=DELETE]").click(function(event) {
    event.preventDefault();
    form = $("<form method='post'><input type='hidden' name='_method' value='DELETE'></form>");
    form.attr("action", $(event.target).attr("href"));
    form.submit();
  });
});
