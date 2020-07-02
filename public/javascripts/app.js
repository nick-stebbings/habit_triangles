// app.js
$(function () {
  $('[data-toggle="switch"]').bootstrapSwitch();

  $('#fractal .bootstrap-switch-label').click(function () {
    let currentDataName = $(this).closest(".swiper-slide").attr("data-name");
    let newDataName = 'f';
    console.log(currentDataName, newDataName);

    $(this).closest(".swiper-slide").attr("data-name", newDataName);

    $('#node-completed-index').val($(this).closest(".swiper-slide").attr("data-swiper-slide-index"));

    $(this).closest("form").submit();
  });

  $('.todo').on('click', 'li', function () {
    $(this).toggleClass('todo-done');
  });

  $("button.btn-danger").click(function (event) {
    event.preventDefault();
    event.stopPropagation();

    var ok = confirm("Are you sure? This deletes the whole habit!");
    if (ok) {
      this.submit();
    }
  });

  // Initializing the swiper plugin for the slider.
  // Read more here: http://idangero.us/swiper/api/

  var mySwiper = new Swiper(".swiper-container", {
    grabCursor: true,
    resistanceRatio: 0.2,
    loopAdditionalSlides: 0,
    cssMode: true,
    pagination: '.pag-shoes',
    bulletClass: 'swiper-pagination-bullet',
    currentClass: 'swiper-pagination-current',
    nextButton: ".swiper-button-next",
    prevButton: ".swiper-button-prev",
    paginationBulletRender: function (index, className) {
      var currentSlide = $('.' + this.wrapperClass).find('.swiper-slide')[index];
      var dayCompletedClass = ($(currentSlide).attr('data-name').slice(-1) == 't') ? "success" : "warning"
      var bulletStyles = '<span class="' + className + ' progress-bar progress-bar-' + dayCompletedClass + '">' + $(currentSlide).attr('data-date') + '</span>';
      return bulletStyles
    }
    paginationClickable: true
  });
});
