// app.js
import * as Triangle from "./triangle.js";

$(function () {
  let baseLength = Triangle.swiperInstances[0].slides.length;
  $(window).resize(function (event) {
    Triangle.formatPyramid(
      Triangle.BASE_ROW_WRAP_LENGTH,
      true,
      baseLength
    );
  });
  let scaleFactor =
    baseLength < Triangle.BASE_ROW_WRAP_LENGTH; // not sure yet..
    Triangle.formatPyramid(
      Triangle.BASE_ROW_WRAP_LENGTH,
      true,
      baseLength
    );
});
