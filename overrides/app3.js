// app.js
$(function () {
  // Flat UI switches
  $('[data-toggle="switch"]').bootstrapSwitch();

  $("#fractal .bootstrap-switch-label").click(function () {
    let currentDataName = $(this).closest(".swiper-slide").attr("data-name");
    let toggledValue = currentDataName.slice(-1) === "t" ? "f" : "t";
    let newDataName = currentDataName.slice(0, -1) + toggledValue;
    let nodeInfo = newDataName[0];

    // Toggle the data-name so the pagination can update
    $(this).closest(".swiper-slide").attr("data-name", newDataName);

    // Pass the index of the linked list node to alter the session data
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

  var mySwiper = swiperFactory("0");
  var mySwiper1 = swiperFactory("1");
  var mySwiper2 = swiperFactory("2");
  
  function swiperFactory(classLabelIndex) {
    return new Swiper(`#swiper${classLabelIndex}`, {
      // grabCursor: true,
      // resistanceRatio: 0.2,
      // loopAdditionalSlides: 0,
      // cssMode: true,
      pagination: `#pag-triangles${classLabelIndex}`,
      bulletClass: "triangle",
      currentClass: `swiper-pagination-current${classLabelIndex}`,
      nextButton: `.swiper-button-next${classLabelIndex}`,
      prevButton: `.swiper-button-prev${classLabelIndex}`,
      paginationType: "bullets",
      paginationClickable: true,
      paginationBulletRender: trianglePaginationFactory(classLabelIndex),
    });
  };

  function trianglePaginationFactory(classLabelIndex) {
    return function (index, className) {
    
      var currentSlide = $(`.swiper-wrapper${classLabelIndex}`).find(".swiper-slide" + classLabelIndex)[index];
      console.log(
        $(`.swiper-wrapper${classLabelIndex}`).find(
          ".swiper-slide" + classLabelIndex
        )
      );
      var dayCompletedClass =
        $(currentSlide).attr("data-name").slice(-1) == "t"
        ? "success"
          : "notyet";
      var bulletStyles =
        '<span class="' +
        className +
        " triangle triangle-" +
        dayCompletedClass +
        '">' +
        $(currentSlide).attr("data-date") +
        "</span>";
        console.log(bulletStyles);
        
        return bulletStyles;
      }
    };
  });


    $(".swiper-container").each(function (index, element) {
      var $this = $(this);
      $this.addClass("instance-" + index);
      $this.find(".swiper-pagination").addClass("swiper-pagination-" + index);
      $this.find(".swiper-button-prev").addClass("btn-prev-" + index);
      $this.find(".swiper-button-next").addClass("btn-next-" + index);
      var swiper = new Swiper(".instance-" + index, {
        // your settings ...
        nextButton: ".btn-next-" + index,
        prevButton: ".btn-prev-" + index,
        paginationType: "bullets",
        paginationClickable: true,
        pagination: ".swiper-pagination",
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
            '">' +
            $(currentSlide).attr("data-date") +
            "</span>";
          return bulletStyles;
        },
      });
    });