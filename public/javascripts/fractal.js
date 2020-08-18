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
  let scaleFactor = 1 / baseLength - Math.min(Triangle.baseRowPositiveSpace(), 0);

  // $(window).resize(function () {
  //   waitForFinalEvent(function () {
  //     Triangle.formatPyramid(
  //       1 / baseLength - Math.min(Triangle.baseRowPositiveSpace(), 0),
  //       Triangle.BASE_ROW_WRAP_LENGTH,
  //       baseLength
  //     );
  //   }, 1200);
  // });
  Triangle.formatPyramid(
    scaleFactor,
    Triangle.BASE_ROW_WRAP_LENGTH,
    baseLength,
    true /* Add container divs for each flex row */
  );

  Triangle.swiperInstances[0].on("slidePrevTransitionStart", function () {
    let reverseIndex = this.slides.length - this.activeIndex;
    Triangle.swiperInstances.slice(1).forEach((swiper) => {
      if (swiper.pagination.el.innerHTML.includes("active")) {
        if (reverseIndex - 1 >= swiper.slides.length) {
          $(swiper.pagination.bullets[swiper.activeIndex]).removeClass( "swiper-pagination-bullet-active" );
          if (reverseIndex >= swiper.slides.length) {
            $(swiper.slides[swiper.activeIndex]).css('position', 'relative');
          }
        } else {
          swiper.slidePrev();
        }
      }
    }
    )});
    
    Triangle.swiperInstances[0].on("slideNextTransitionStart", function () {
    let reverseIndex = this.slides.length - this.activeIndex;
    Triangle.swiperInstances.slice(1).forEach((swiper) => {
      if (!swiper.pagination.el.innerHTML.includes("active")) {
        if (reverseIndex == swiper.slides.length) {
          $(swiper.pagination.bullets[swiper.activeIndex]).addClass( "swiper-pagination-bullet-active" );
        } 
      } else {
        swiper.slideNext();
      }
    }
  )});

  Triangle.swiperInstances.forEach((s, i) => {
    Triangle.swiperInstances[i].slideTo(s.slides.length - 1);
  });
});
