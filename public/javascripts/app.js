// app.js
$(function () {
  // Initializing the swiper plugin for the slider.
  // Read more here: http://idangero.us/swiper/api/
  var swiperInstances = [];

  $(".swiper-container").each(function (index, element) {
    var $this = $(this);
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
      // Custom pagination rendering for Triangles
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
    swiperInstances.push(newSwiper);
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

  /* Asking if habit deletion is final */
  $("button.btn-danger").click(function (event) {
    event.preventDefault();
    event.stopPropagation();

    var ok = confirm("Are you sure? This deletes the whole habit!");
    if (ok) {
      this.submit();
    }
  });

  /* Swiper prev/next button click handlers for base habit only */
  $(".swiper-btn-prev-0").click(
    { swiperId: 1, direction: "prev" },
    customButtonEvents
  );
  $(".swiper-btn-next-0").click(
    { swiperId: 1, direction: "next" },
    customButtonEvents
  );
  $(".swiper-btn-prev-0").click(
    { swiperId: 2, direction: "prev" },
    customButtonEvents
  );
  $(".swiper-btn-next-0").click(
    { swiperId: 2, direction: "next" },
    customButtonEvents
  );

  function getSwiperInstanceSlides(swiperId) {
    return $(".swiper-wrapper")
      .children(".swiper-slide")
      .filter((idx, slide) => $(slide).data("name")[0] === swiperId.toString());
  }

  function getActivePaginationTriangle(swiperId) {
    return $("#triangles-" + swiperId + " .triangle-wrapper")
      .children(".triangle")
      .filter((idx, slide) =>
        $(slide).hasClass("swiper-pagination-bullet-active")
      );
  }

  // Using this function to change display of the remaining (shorter) habits when the prev button is clicked
  function customButtonEvents(event) {
    let swiperId = event.data.swiperId;
    var btnClass = `.swiper-btn-${event.data.direction}-${swiperId}`;
    let baseSwiperSlides = getSwiperInstanceSlides(0);
    var baseHabitCurrentDay;

    let swiperSlides = getSwiperInstanceSlides(swiperId);
    let habitLength = swiperSlides.length;
    console.log(habitLength, swiperId);

    // Get index of active day (from base habit's swiper slides)
    for (let index = 0; index < baseSwiperSlides.length; index++) {
      let currentBaseSlide = baseSwiperSlides[index];

      if ($(currentBaseSlide).hasClass("swiper-slide-active")) {
        baseHabitCurrentDay = index;
        console.log(baseHabitCurrentDay);
        break;
      }
    }
    if (event.data.direction === "next") {
      switch (true) {
        case baseHabitCurrentDay == habitLength + 1:
          console.log(getActivePaginationTriangle(swiperId));
          
          getActivePaginationTriangle(swiperId).toggleClass(
            "swiper-pagination-bullet-active"
          );
          console.log("toggle fwd");
          break;
        case baseHabitCurrentDay <= habitLength:
          console.log("forward hab 1");
          $(btnClass).click();
          break;
        default:
          console.log("nowt");
      }
    } else if (event.data.direction === "prev") {
      switch (true) {
        case baseHabitCurrentDay == habitLength:
          $(swiperSlides.slice(-1)).toggleClass(
            "swiper-pagination-bullet-active"
          );
          console.log("slide:", swiperSlides[habitLength-1]);
          break;
        case baseHabitCurrentDay <= habitLength:
          $(btnClass).click();
          console.log("back up habit 1");
          break;
        default:
          console.log("nowt");
      }
    }
  }

  // PSEUDO CODE:
  // For the prev button
  // prevent swiping until base habit's arrow controller is pressed, then OnClick:
  //  - SET current_node to be the active slide of the base habit
  //  - FOREACH swiper
  //    - SET the habit_length var to be length of swiper's habit
  //    - CASE current_node
  //        - WHEN == habit_length
  //          - then toggle the active class for the last bullet element in pagination
  //        - WHEN  > habit length
  //          - then click the habit's prev button

  // For the next button
  // prevent swiping until base habit's arrow controller is pressed, then OnClick:
  //  - SET current_node to be the active slide of the base habit
  //  - FOREACH swiper
  //    - SET the habit_length var to be length of swiper's habit
  //    - CASE current_node
  //        - WHEN == habit_length
  //          - then toggle the active class for the last bullet element in pagination
  //        - WHEN  < habit length
  //          - then click the habit's prev button
});
