// app.js

$(function () {
  /* FlatUI switches*/
  $('[data-toggle="switch"]').bootstrapSwitch();
  /*Tooltips */
  $('[data-toggle="tooltip"]').tooltip();

  // Toggling a day's 'completed status'
  $("#fractal .bootstrap-switch-label").click(function () {
    let currentDataName = $(this).closest(".swiper-slide").attr("data-name");
    // Toggle the boolean representation of 'day completed' in string (t/f)
    let toggledValue = currentDataName.slice(-1) === "t" ? "f" : "t";
    let newDataName = currentDataName.slice(0, -1) + toggledValue;
    
    let nodeInfo = newDataName[2]; // This is the node that needs to be altered
    $(this).closest(".swiper-slide").attr("data-name", newDataName); // Now it is toggled, reset the data for the slide
    
    // Pass the node identifier to the backend via a hidden form element
    $("#node-completed-index").val(nodeInfo);
    $(this).closest("form").submit();
  });

  /* Action list click handler */
  $(".todo").on("click", "li", function (event) {
    // Atomic habit action list functionality
    let checkboxInput = $(".check > input");
    $(this).toggleClass("todo-done");
    $(".check > input").val(!checkboxInput);

    let form = $("form.check");
    // Upate the action list in the backend (via AJAX) when an action has been toggled
    $.ajax({
      url: form.attr("action"),
      method: form.attr("method"),
    });
  });

  /* Ask if habit deletion is final */
  $("button.btn-danger").click(function (event) {
    event.preventDefault();
    event.stopPropagation();
    var thisForm = $(this).closest("form");
    var ok = confirm("Are you sure? This deletes the whole habit!");
    if (ok) {
      thisForm.attr('action', $(this).attr('formaction'));
      thisForm.submit();;
    }
  });
});
