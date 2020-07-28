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
  // Adds class names to distinguish flex-rows from each other
  const wrapped = function () {
    var offset_top_prev;

    $(".triangle-wrapper").each(function () {
      var offset_top = $(this).offset().top;

      if (offset_top > offset_top_prev) {
        $(this).addClass("wrapped");
        $(this).before("<div class='flex-break'></div>");
      } else if (offset_top == offset_top_prev) {
        $(this).removeClass("wrapped");
      }
      offset_top_prev = offset_top;
    });
    for (let i = 0; i < swiperInstances.length; i++) {
      addFlexRowDivsAndClasses(i);
    }
  };

  // Performs all functions needed to arrange flex-rows into pyramid
  const formatPyramid = function () {
    // After the window resize has definitely finished
    // Add classnames to wrapped elements, add flex-break divs between flex-rows
    formatTriangles(swiperInstances[0].slides.length);
    waitForFinalEvent(wrapped, 50, "window-resize");
  };


  function formatTriangles(numTriangles, triangleScale = 12, wrapLength = 7) {
    let rowWidth = Math.min.apply(0, [numTriangles, wrapLength]);
    if (rowWidth < numTriangles) {
      let oddTrianglesSelector =
        "#fractal .triangle-wrapper:nth-of-type(2n + 2) span.triangle";
      $("#fractal span.triangle-wrapper").addClass("tessellated");
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

      let nthTrianglesSelector = `#fractal .triangle-wrapper:nth-of-type(${rowWidth})`;
      console.log(nthTrianglesSelector);
      $(nthTrianglesSelector).after(
        "<div class='flex-break custom-wrap'></div>"
      );
    }
    let triangleWidth = triangleScale * (1 / rowWidth).toFixed(3);
    $("#fractal .swiper-pagination").css("font-size", `${triangleWidth}vh`);
  }
  // Add class identifiers to each element wrapped onto
  // the next flex row. Rows are zero indexed from most recent day to oldest day
  function addFlexRowDivsAndClasses(swiperId) {
    let flexBreaks = Math.max($("[class*='flex-break']").length - 1, 0);
    console.log(flexBreaks);
    let numRows = flexBreaks;

    // Add classes to the span elements in each row
    let pagTriangles = $(`#triangles-${swiperId}`).children();
    pagTriangles.each(function (idx, value) {
      if ($(this).attr("class").includes("flex-break")) {
        flexBreaks--;
      }
      $(this).addClass(`flex-row-${flexBreaks}`);
    });

    // Wrap all spans with their row-classes in a container div for the row
    for (let rowNum = 0; rowNum <= numRows; rowNum++) {
      $(`#triangles-${swiperId} span.flex-row-${rowNum}`).wrapAll(
        '<div class="custom-flex-row"></div>'
      );
    }
  }
