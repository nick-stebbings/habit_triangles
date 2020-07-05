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

    $(".swiper-container").each(function(index, element){
      var $this = $(this);
      $this.addClass("instance-" + index);
      // if (index > 0) { $this.addClass("hidden")};
      
      $this.find(".swiper-button-prev").addClass("btn-prev-" + index);
      $this.find(".swiper-button-next").addClass("btn-next-" + index);
      $this.find(".swiper-wrapper").addClass("swiper-wrapper-" + index);
      $this.find(".swiper-pagination").addClass("swiper-pagination-" + index);
      swiperInstances[index] = swiperFactory(`${index}`);
    });

  function swiperFactory(habitIndex) {
    function trianglePagFactory(classLabelIndex) {
      return function (index, className) {
      
        var currentSlide = $(`.swiper-wrapper-${classLabelIndex}`).find(".swiper-slide")[index];
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
        };
      };

    return new Swiper(".instance-" + habitIndex, {
      grabCursor: true,
      resistanceRatio: 0.2,
      loopAdditionalSlides: 0,
      cssMode: true,
      pagination: {
        el: ".swiper-pagination-" + habitIndex,
        clickable: true,
        renderBullet: trianglePagFactory(habitIndex),
        // paginationBulletRender: function (index, className) {
        //   // This function will render some custom html for each triangle
        //   // - If the day was completed, it will add triangle-success
        //   // - otherwise, it will add triangle-notyet

        //   var slideCompletedInfo = [];
        //   $(".instance-" + habitIndex + " .swiper-slide").each(function (i) {
        //     slideCompletedInfo.push($(this).data("name"));
        //   });

        //   return (
        //     '<span class="' +
        //     className +
        //     '">' +
        //     slideCompletedInfo[index] +
        //     "</span>"
        //   );
        type: "bullet"
        },
      navigation: {
        nextEl: ".swiper-button-next-" + habitIndex,
        prevEl: ".swiper-button-prev-" + habitIndex,
      },
      // bulletClass: "swiper-pagination-bullet-" + habitIndex,
      // currentClass: "swiper-pagination-current-" + habitIndex,
      // paginationClickable: true,
      // renderBullet: function (index, className, habitIndex) {
      //   var slideCompletedInfo = [];
      //   $(".instance-" + habitIndex + " .swiper-slide").each(function (i) {
      //     slideCompletedInfo.push($(this).data("name"));
      //   });
      //   return '<span class="' + className + '">' + slideCompletedInfo[index] + '</span>');

      // },
    });
  };
  
});
