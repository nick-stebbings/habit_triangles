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
    
    let nodeInfo = newDataName.split('-')[1]; // This is the node that needs to be altered
    let habitIndex = newDataName.split('-')[0];
    $(this).closest(".swiper-slide").attr("data-name", newDataName); // Now it is toggled, reset the data for the slide
    
    // Pass the node identifier to the backend via a hidden form element
    $("#node-completed-index").val(habitIndex + '_' + nodeInfo);
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
    var ok = confirm("Are you sure? This deletes the item!");
    if (ok) {
      thisForm.attr('action', $(this).attr('formaction'));
      thisForm.submit();;
    }
  });
  $(".swiper-slide1").css("display", "contents");
  $(".swiper-wrapper-1").css("display", "contents");
  $(".swiper-container-1").css("display", "contents");
  $(".swiper-wrapper-2").css("display", "contents");
  $(".swiper-container-2").css("display", "contents");
});
