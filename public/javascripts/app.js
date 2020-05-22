// app.js
$(function () {
  $('form.delete').submit(function(event) {
    event.preventDefault();
    event.stopPropagation();

    var ok = confirm('Are you sure? This deletes the whole habit!')
    if(ok) {
      this.submit()
    }
  });
});