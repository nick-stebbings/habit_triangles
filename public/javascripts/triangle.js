const TRIANGLE_SCALE_FACTOR = 18;
const BASE_ROW_WRAP_LENGTH = 12;
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

const addFlexBreakAfterNthTrianglesDescending = function (n, totalTriangles) {
  let flexBreaksRequired = Math.floor(totalTriangles / n);
  let nextElement = n;
  for (let i = 1; i <= flexBreaksRequired; i++) {
    let nthTrianglesSelector = `#fractal .triangle-wrapper:nth-of-type(${nextElement})`; // The break comes one triangle earlier for each row
    $(nthTrianglesSelector).after("<div class='flex-break custom-wrap'></div>");
    n--;
    nextElement += n;
  }
};

const rowNeedsWrapping = function (rowLength) {
  return calculateTrianglesLeft() < rowLength * 2 - 1;
};

const styleInvertedTriangles = function (habitIndex, flexRowIndex) {
  let oddTrianglesSelector = `#triangles-${habitIndex} .flex-row-${flexRowIndex}.triangle-wrapper:nth-of-type(2n + 2) span.triangle`;

  // Add styling for inverted triangles
  $(`#triangles-${habitIndex} span.triangle-wrapper`).addClass("tessellated");
  $(oddTrianglesSelector).each(function (_, element) {
    let dayNotCompleted = [...element.classList].includes("triangle-notyet");
    $(this).attr(
      "style",
      "border-color: " +
        (dayNotCompleted ? "#f1c40f" : "#2ecc71") +
        " transparent transparent transparent;" +
        "border-width: 5em 2.8em 0em 2.8em"
    );
    $(this).find("span").attr("style", "bottom: 2.8em");
  });
};

const scaleTriangles = function (rowLimit = BASE_ROW_WRAP_LENGTH) {
  let triangleWidth = TRIANGLE_SCALE_FACTOR * (1 / rowLimit).toFixed(3);
  $("#fractal .swiper-pagination").css("font-size", `${triangleWidth}vh`);
};

// Add class identifiers to each element that was wrapped onto the next flex row.
// custom-flex-rows are zero indexed from most recent habit day to the oldest habit day
const addFlexRowClasses = function (swiperId) {
  let rows = $(`.custom-wrap`).length + 1;
  let rowNum = rows;
  // Add classes to the span elements in each row
  let pagTriangles = $(`#triangles-${swiperId}`).children();
  pagTriangles.each(function (idx, value) {
    if ($(this).attr("class").includes("flex-break")) {
      rowNum--;
    }
    $(this).addClass(`flex-row-${rows - rowNum}`);
  });
};

// Wrap all (spans with the same row-classes) in a container div for the row
const wrapFlexRows = function (numRows, swiperId) {
  for (let rowNum = 0; rowNum < numRows; rowNum++) {
    $(`#triangles-${swiperId} .flex-row-${rowNum}`).wrapAll(
      '<div class="custom-flex-row"></div>'
    );
  }
};

const addFlexRowPadding = function (rowIndex) {
  let lastRowPadding;
  let workingFontSize = parseFloat($(`#triangles-0`).css("font-size"), 10);
  if (rowIndex === 1) {
    lastRowPadding = 1;
  } else {
    lastRowPadding = $(`#triangles-${rowIndex} .flex-break`).css("font-size");
  }
  return lastRowPadding - workingTriangleWidth();
};

function addCustomFlexBreaks(
  habitIndex,
  wrapOnRowLimit,
  rowLimit,
  baseHabitLength
) {
  if (
    $(`#triangles-0`).width() < 500 &&
    calculateTrianglesLeft() < rowLimit - habitIndex
  ) {
    addFlexBreakOnFlexWrap();
  } else if (wrapOnRowLimit) {
    addFlexBreakAfterNthTrianglesDescending(rowLimit, baseHabitLength);
  }
}

const calculateTrianglesLeft = function() {
  let workingWidth = $(`#triangles-0`).width();
  let workingFontSize = parseFloat($(`#triangles-0`).css("font-size"), 10);
  let trianglesOfPositiveSpace = Math.floor(
    workingWidth / workingTriangleWidth()
  );
  return trianglesOfPositiveSpace;
};

const workingTriangleWidth = function(workingFontSize) {
  return workingFontSize * 3.5;
};

var swiperInstances = [];

// Perform all functions needed to arrange flex-rows into pyramid
const formatPyramid = function (
  rowLimit = BASE_ROW_WRAP_LENGTH,
  wrapOnRowLimit = true,
  baseHabitLength
) {

  for (let habitIndex = 0; habitIndex < swiperInstances.length; habitIndex++) {
    addCustomFlexBreaks(habitIndex, wrapOnRowLimit, rowLimit, baseHabitLength);

    let numFlexRows = $(`#triangles-${habitIndex} .flex-break`).length + 1;
    addFlexRowClasses(habitIndex);

    for (let rowIndex = 0; rowIndex < numFlexRows; rowIndex++) {
      let rowLength = $(`#triangles-${habitIndex}`).find(
        `span.flex-row-${rowIndex}`
      ).length;

      if (rowNeedsWrapping(rowLength)) {
        styleInvertedTriangles(habitIndex, rowIndex);
      }

      addFlexRowPadding(rowIndex);
    }
  }

  wrapFlexRows($("#triangles-0 [class*='flex-break']").length + 1, 0);
  scaleTriangles(rowLimit);
};

export {
  swiperInstances,
  TRIANGLE_SCALE_FACTOR,
  BASE_ROW_WRAP_LENGTH,
  addFlexBreakOnFlexWrap,
  addFlexBreakAfterNthTrianglesDescending,
  rowNeedsWrapping,
  styleInvertedTriangles,
  scaleTriangles,
  addFlexRowClasses,
  wrapFlexRows,
  addFlexRowPadding,
  formatPyramid,
  workingTriangleWidth,
  calculateTrianglesLeft
};