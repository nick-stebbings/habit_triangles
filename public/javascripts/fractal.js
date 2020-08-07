// app.js
import * as Triangle from "./triangle.js";
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

$(function () {
  let baseLength = Triangle.swiperInstances[0].slides.length;
  $(window).resize(function (event) {
    Triangle.formatPyramid(
      Triangle.BASE_ROW_WRAP_LENGTH,
      baseLength
    );
  });
  let scaleFactor =
    baseLength < Triangle.BASE_ROW_WRAP_LENGTH; // not sure yet..
    Triangle.formatPyramid(
      Triangle.BASE_ROW_WRAP_LENGTH,
      baseLength
    );
});
