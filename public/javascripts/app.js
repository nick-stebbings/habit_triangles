// app.js
var swiperInstances = [];

$(function () {
  // Waits for an event to fully elapse before callback is executed
  const waitForFinalEvent = (function () {
    var timers = {};
    return function (callback, ms, uniqueId) {
      if (!uniqueId) {
        uniqueId = "Don't call this twice without a uniqueId";
      }
      if (timers[uniqueId]) {
        clearTimeout(timers[uniqueId]);
      }
      timers[uniqueId] = setTimeout(callback, ms);
    };
  })();
  // Adds flex-break divs to break up triangles into flex-row containers
  const addFlexBreakOnFlexWrap = function () {
    var offset_top_prev;

    $(".triangle-wrapper").each(function () {
      var offset_top = $(this).offset().top;

      if (offset_top > offset_top_prev) {
        // If the triangle moved due to flex wrapping...
        // Add a flex-break element before the first triangle of each line
        $(this).before("<div class='flex-break'></div>");
      }
      offset_top_prev = offset_top;
    });
  };

  const addFlexBreakAfterNthTriangle = function (n, totalTriangles) {
    let flexBreaksRequired = Math.floor(totalTriangles / n);
    console.log(flexBreaksRequired);
    let nextElement = n;
    for (let i = 1; i <= flexBreaksRequired; i++) {
      let nthTrianglesSelector = `#fractal .triangle-wrapper:nth-of-type(${nextElement})`; // The break comes one triangle earlier for each row
      $(nthTrianglesSelector).after(
        "<div class='flex-break custom-wrap'></div>"
      );
      n--;
      nextElement += n;
      console.log(nthTrianglesSelector, i);
    }
  };

  const addFlexRowsForAllHabits = function () {
    // Use our flex-breaks to delineate custom flex-rows for each habit instance
    for (let i = 0; i < swiperInstances.length; i++) {
      addFlexRowClasses(i);
    }
  };

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
    swiperInstances.push(newSwiper);
  });

  function invertAndStyleTrianglesOverLimit(totalTriangles, rowBreak = 9) {
    // If habit is less than rowBreak days old, let rows be that wide
    // Else add wrapping element after rowBreak days
    let maxRowWidth = Math.min(totalTriangles, rowBreak);

    if (maxRowWidth < totalTriangles) {
      styleInvertedTriangles();
    }

    function styleInvertedTriangles() {
      let oddTrianglesSelector =
        "#fractal .triangle-wrapper:nth-of-type(2n + 2) span.triangle";
      $("#fractal span.triangle-wrapper").addClass("tessellated");

      // Add styling for inverted triangles
      $(oddTrianglesSelector).each(function (idx, element) {
        let dayNotCompleted = [...element.classList].includes(
          "triangle-notyet"
        );
        $(this).attr(
          "style",
          "border-color: " +
            (dayNotCompleted ? "#f1c40f" : "#2ecc71") +
            " transparent transparent transparent;" +
            "border-width: 5em 2.8em 0em 2.8em"
        );
        $(this).find("span").attr("style", "bottom: 2.8em");
      });
    }
  }
  function scaleTriangles(scaleFactor, maxRowWidth) {
    let triangleWidth = scaleFactor * (1 / maxRowWidth).toFixed(3);
    $("#fractal .swiper-pagination").css("font-size", `${triangleWidth}vh`);
  }
  // Add class identifiers to each element that was wrapped onto the next flex row.
  // custom-flex-rows are zero indexed from most recent habit day to the oldest habit day
  const addFlexRowClasses = function (swiperId) {
    let flexBreakIndex = Math.max($("[class*='flex-break']").length - 1, 0);

    // Add classes to the span elements in each row
    let pagTriangles = $(`#triangles-${swiperId}`).children();
    pagTriangles.each(function (idx, value) {
      if ($(this).attr("class").includes("flex-break")) {
        flexBreakIndex--;
      }
      $(this).addClass(`flex-row-${flexBreakIndex}`);
    });
    // wrapFlexRows(numRows, swiperId);
  };

  // Wrap all (spans with the same row-classes) in a container div for the row
  const wrapFlexRows = function (numRows, swiperId) {
    console.log(numRows);
    for (let rowNum = 0; rowNum <= numRows; rowNum++) {
      $(`#triangles-${swiperId} .flex-row-${rowNum}`).wrapAll(
        '<div class="custom-flex-row"></div>'
      );
    }
  };

  // Perform all functions needed to arrange flex-rows into pyramid
  const formatPyramid = function (scale = 15, rowLimit = 9) {
    let baseHabitLength = swiperInstances[0].slides.length;
    // DEBUG: Establish number of flex rows for each habit.
    // ITERATE through habits, performing these actions
    // -
    // -
    // -
    // -
    addFlexBreakAfterNthTriangle(rowLimit, baseHabitLength);
    invertAndStyleTrianglesOverLimit(baseHabitLength, rowLimit);
    // addFlexRowsForAllHabits();
    addFlexBreakOnFlexWrap();
    addFlexRowsForAllHabits();
    wrapFlexRows($("#triangles-0 [class*='flex-break']").length, 0);
    scaleTriangles(scale, rowLimit);
  };

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

  // function getSwiperInstanceSlides(swiperId) {
  //   return $(".swiper-wrapper")
  //     .children(".swiper-slide")
  //     .filter((idx, slide) => $(slide).data("name")[0] === swiperId.toString());
  // }

  // function getActivePaginationTriangle(swiperId) {
  //   return $("#triangles-" + swiperId + " .triangle-wrapper")
  //     .children(".triangle")
  //     .filter((idx, slide) =>
  //       $(slide).hasClass("swiper-pagination-bullet-active")
  //     );
  // }

  // Using this function to change display of the remaining (shorter) habits when the prev button is clicked
  function customButtonEvents(event) {
    let swiperId = event.data.swiperId;
    var btnClass = `.swiper-btn-${event.data.direction}-${swiperId}`;
    var baseHabitCurrentDay = swiperInstances[0].activeIndex;

    let swiperSlides = swiperInstances[swiperId].slides;
    let habitLength = swiperSlides.length;

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
          console.log("slide:", swiperSlides[habitLength - 1]);
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
  formatPyramid();

  $(window).resize(formatPyramid);
  // After the window resize has definitely finished, perform pyramid alignment
  // Dynamically resize triangles and turn them upside down to tessellate
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
