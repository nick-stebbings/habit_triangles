const BASE_TRIANGLE_SCALE = 12;
const BASE_ROW_WRAP_LENGTH = 13;
var swiperInstances = [];

jQuery.fn.reverse = [].reverse;

// Initialise swipers for each habit
// (habit IDs were already passed and habit swiper markup included in fractal template)
$(".swiper-container").each(function (index, element) {
  var $this = $(this);
  // Create distinctly numbered classes for swiper elements of each swiper instance
  $this.addClass("instance-" + index);
  $this
  .find(".swiper-pagination")
  .reverse()
  .slice(0,1)
  .addClass("swiper-pagination-" + index);
  $this
  .find(".swiper-pagination-" + index)
  .attr("id", "triangles-" + index);
  $this
  .find(".swiper-button-prev")
  .slice(index, 1)
  .addClass("swiper-btn-prev-" + index);
  $this
  .find(".swiper-button-next")
  .slice(index, 1)
  .addClass("swiper-btn-next-" + index);
  
  var newSwiper = new Swiper(".instance-" + index, {
    // Settings
    preventInteractionOnTransition: true,
    cssMode: true,
    speed: 100,
    nextButton: ".swiper-btn-next-" + index,
    prevButton: ".swiper-btn-prev-" + index,
    pagination: {
      el: "#triangles-" + index,
      clickable: false,
      renderBullet: function (idx, className) {
        var slides = $(this.wrapperEl).find(
          ".swiper-slide"
        );
        var len = slides.length;
        var currentSlide = slides.reverse()[len - idx - 1];
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
    },
  });
    swiperInstances.push(newSwiper);
  });

const addFlexBreakAfterNthTriangle = function (n, rowLimit) {
  let flexBreaksRequired = Math.floor(rowLimit / n*2);
  let nextElement = n;
  for (let i = 1; i <= flexBreaksRequired; i++) {
    let nthTrianglesSelector = `#fractal .triangle-wrapper:nth-of-type(${nextElement})`; // The break comes one triangle earlier for each row
    $(nthTrianglesSelector).after("<div class='flex-break custom-wrap'></div>");
    n -= 2;
    nextElement += n;
  }
};

const styleInvertedTriangles = function (habitIndex, flexRowIndex) {
  let oddTrianglesSelector = `#triangles-${habitIndex} .flex-row-${flexRowIndex}.triangle-wrapper:nth-of-type(2n + ${flexRowIndex + 2} ) span.triangle`;
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
    $(this).find("span").attr("style", "bottom: 3.2em");
  });
};

const scaleTriangles = function (scaleFactor) {
  let triangleWidth =
    scaleFactor * BASE_TRIANGLE_SCALE;
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

function addCustomFlexBreaks(
  rowLimit,
  baseHabitLength
) {
  let widestBaseRowPossible = Math.floor((baseHabitLength *2  + 6) / 3);
  let finalBaseRowSize = widestBaseRowPossible % 2 != 0 ? widestBaseRowPossible : widestBaseRowPossible - 1
  finalBaseRowSize =
    $(`#triangles-0`).width() > 480 ? rowLimit : finalBaseRowSize;
  addFlexBreakAfterNthTriangle(finalBaseRowSize, baseHabitLength);
}

const baseRowPositiveSpace = function() {
  let workingWidth = $(`#triangles-0`).width();
  let workingFontSize = parseFloat($(`#triangles-0`).css("font-size"), 10);
  let trianglesOfPositiveSpace = Math.floor(
    workingWidth / workingTriangleWidth(workingFontSize)
  );
  return trianglesOfPositiveSpace;
};

const workingTriangleWidth = function(workingFontSize) {
  return workingFontSize * 3.5;
};

// Perform all functions needed to arrange flex-rows into pyramid
const formatPyramid = function (
  scaleFactor,
  rowLimit = BASE_ROW_WRAP_LENGTH,
  baseHabitLength,
  addDivs = false
) {
  let baseWidth = Math.floor((baseHabitLength * 2) / 3);
  if (addDivs) {
    for (let habitIndex = 0; habitIndex < swiperInstances.length; habitIndex++) {
      
      addCustomFlexBreaks(rowLimit, baseHabitLength);
      addFlexRowClasses(habitIndex);
      let numFlexRows = $(`#triangles-${habitIndex} .flex-break`).length + 1;
    
      for (let rowIndex = 0; rowIndex < numFlexRows; rowIndex++) {
        let rowLength = $(`#triangles-${habitIndex}`).find( `span.flex-row-${rowIndex}` ).length;
        if (baseWidth < rowLength * 2 - 1) { styleInvertedTriangles(habitIndex, rowIndex); }
      }
      wrapFlexRows(numFlexRows, habitIndex );
    }
  }
  scaleTriangles(scaleFactor, baseWidth);
};
  
export {
  swiperInstances,
  BASE_TRIANGLE_SCALE,
  BASE_ROW_WRAP_LENGTH,
  addFlexBreakAfterNthTriangle,
  styleInvertedTriangles,
  scaleTriangles,
  addFlexRowClasses,
  wrapFlexRows,
  formatPyramid,
  workingTriangleWidth,
  baseRowPositiveSpace
};
