// app.js
import * as Triangle from "./triangle.js";

$(function () {
  // Initialise swipers for each habit
  // (habit IDs were already passed and habit swiper markup included in fractal template)
  $(".swiper-container").each(function (index, element) {
    var $this = $(this);
    // Create distinctly numbered classes for swiper elements of each swiper instance
    $this.addClass("instance-" + index);
    $this
      .find(".swiper-pagination")
      .slice(0, 1)
      .addClass("swiper-pagination-" + index);
    $this
      .find(".swiper-pagination")
      .slice(0, 1)
      .attr("id", "triangles-" + index);
    $this
      .find(".swiper-button-prev")
      .slice(0, 1)
      .addClass("swiper-btn-prev-" + index);
    $this
      .find(".swiper-button-next")
      .slice(0, 1)
      .addClass("swiper-btn-next-" + index);

    var newSwiper = new Swiper(".instance-" + index, {
      // Settings
      nextButton: ".swiper-btn-next-" + index,
      prevButton: ".swiper-btn-prev-" + index,
      paginationType: "bullets",
      paginationClickable: true,
      pagination: "#triangles-" + index,
      // Custom pagination rendering for triangles interface
      paginationBulletRender: function (index, className) {
        var currentSlide = $("." + this.wrapperClass).find(".swiper-slide")[
          index
        ];
        var dayCompletedClass =
          $(currentSlide).attr("data-name").slice(-1) == "t"
            ? "success"
            : "notyet";
        var bulletStyles =
          '<span class="triangle-wrapper"><span class="' +
          className +
          " triangle triangle-" +
          dayCompletedClass +
          '"><span>' +
          $(currentSlide).attr("data-date") +
          "</span></span></span>";
        return bulletStyles;
      },
    });
    Triangle.swiperInstances.push(newSwiper);
  });

  /* FlatUI switches on fractal page */
  $('[data-toggle="switch"]').bootstrapSwitch();

  // Function for toggling a day's 'completed status'
  $("#fractal .bootstrap-switch-label").click(function () {
    let currentDataName = $(this).closest(".swiper-slide").attr("data-name");

    // Toggle the boolean representation of 'day completed' in string (t/f)
    let toggledValue = currentDataName.slice(-1) === "t" ? "f" : "t";
    let newDataName = currentDataName.slice(0, -1) + toggledValue;

    let nodeInfo = newDataName[0]; // This is the node that needs to be altered
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

    var ok = confirm("Are you sure? This deletes the whole habit!");
    if (ok) {
      this.submit();
    }
  });

  // Using this function to change display of the remaining (shorter) habits when the prev button is clicked
  // function customButtonEvents(event) {
  //   let swiperId = event.data.swiperId;
  //   var btnClass = `.swiper-btn-${event.data.direction}-${swiperId}`;
  //   var baseHabitCurrentDay = swiperInstances[0].activeIndex;

  //   let swiperSlides = swiperInstances[swiperId].slides;
  //   let habitLength = swiperSlides.length;

  //   if (event.data.direction === "next") {
  //     switch (true) {
  //       case baseHabitCurrentDay == habitLength + 1:
  //         console.log(getActivePaginationTriangle(swiperId));

  //         getActivePaginationTriangle(swiperId).toggleClass(
  //           "swiper-pagination-bullet-active"
  //         );
  //         console.log("toggle fwd");
  //         break;
  //       case baseHabitCurrentDay <= habitLength:
  //         console.log("forward hab 1");
  //         $(btnClass).click();
  //         break;
  //       default:
  //         console.log("nowt");
  //     }
  //   } else if (event.data.direction === "prev") {
  //     switch (true) {
  //       case baseHabitCurrentDay == habitLength:
  //         $(swiperSlides.slice(-1)).toggleClass(
  //           "swiper-pagination-bullet-active"
  //         );
  //         console.log("slide:", swiperSlides[habitLength - 1]);
  //         break;
  //       case baseHabitCurrentDay <= habitLength:
  //         $(btnClass).click();
  //         console.log("back up habit 1");
  //         break;
  //       default:
  //         console.log("nowt");
  //     }
  //   }
  // }

  $(window).resize(function (event) {
    Triangle.formatPyramid(
      Triangle.BASE_ROW_WRAP_LENGTH,
      Triangle.TRIANGLE_SCALE_FACTOR,
      Triangle.swiperInstances[0].slides.length
    );
  });
    Triangle.formatPyramid(
      Triangle.BASE_ROW_WRAP_LENGTH,
      Triangle.TRIANGLE_SCALE_FACTOR,
      Triangle.swiperInstances[0].slides.length
    );
});
