// app.js
$(function () {
  $('[data-toggle="switch"]').bootstrapSwitch();

  $("#fractal .bootstrap-switch-label").click(function () {
    let currentDataName = $(this).closest(".swiper-slide").attr("data-name");
    let toggledValue = currentDataName.slice(-1) === "t" ? "f" : "t";
    let newDataName = currentDataName.slice(0, -1) + toggledValue;
    let nodeInfo = newDataName[0];

    $(this).closest(".swiper-slide").attr("data-name", newDataName);

    // Pass the index of the linked list node to alter
    $("#node-completed-index").val(nodeInfo);

    $(this).closest("form").submit();
  });

  $(".todo").on("click", "li", function () {
    $(this).toggleClass("todo-done");
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
    var swiperInstances = {};
  $(".swiper-container").each(function (index, element) {
    var $this = $(this);
    $this.addClass("instance-" + index);
    // if (index > 0) { $this.addClass("hidden")};
    $this.find(".swiper-pagination").slice(0,1).addClass("swiper-pagination-" + index);
    $this.find(".swiper-pagination").slice(0,1).attr("id", "triangles-" + index);
    $this
      .find(".swiper-button-prev")
      .slice(0, 1)
      .addClass("swiper-btn-prev-" + index);
    $this
      .find(".swiper-button-next")
      .slice(0, 1)
      .addClass("swiper-btn-next-" + index);
    var swiper = new Swiper(".instance-" + index, {
      // your settings ...
      nextButton: ".swiper-btn-next-" + index,
      prevButton: ".swiper-btn-prev-" + index,
      paginationType: "bullets",
      paginationClickable: true,
      pagination: "#triangles-" + index,
      paginationBulletRender: function (index, className) {
        var currentSlide = $("." + this.wrapperClass).find(".swiper-slide")[
          index
        ];
        var dayCompletedClass =
          $(currentSlide).attr("data-name").slice(-1) == "t"
            ? "success"
            : "notyet";
        var bulletStyles =
          '<span class="' +
          className +
          " triangle triangle-" +
          dayCompletedClass +
          '"><span>' +
          $(currentSlide).attr("data-date") +
          "</span></span>";
        return bulletStyles;
      },
    });
  });
  
});
