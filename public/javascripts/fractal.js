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
  let scaleFactor = 1 + (1 / baseLength - Math.min(Triangle.baseRowPositiveSpace(), 0))
  $(window).resize(function () {
    scaleFactor = 1 + (1 / baseLength - Math.min(Triangle.baseRowPositiveSpace(), 0));
    waitForFinalEvent(function(){
      Triangle.formatPyramid(
        scaleFactor,
        Triangle.BASE_ROW_WRAP_LENGTH,
        baseLength
        )}, 1);
        console.log('sf', scaleFactor);
      });
    Triangle.formatPyramid(
      scaleFactor,
      Triangle.BASE_ROW_WRAP_LENGTH,
      baseLength
    );
    Triangle.swiperInstances[0].slideTo(baseLength);
});
