// app.js
$(function () {
  // $('#formDecideAtomic input:radio').change(function () {
  //   location.reload()
  // }

  $("form.delete").submit(function (event) {
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
    loop: true,
    pagination: ".swiper-pagination",
    paginationClickable: true,
    nextButton: ".swiper-button-next",
    prevButton: ".swiper-button-prev",
  });
});
