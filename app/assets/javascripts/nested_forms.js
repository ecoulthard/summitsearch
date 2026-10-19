(function() {
  let nextIndex = Date.now();

  document.addEventListener("click", function(event) {
    const add = event.target.closest(".add_nested_fields");
    if (add) {
      event.preventDefault();
      const template = document.createElement("template");
      template.innerHTML = add.dataset.fields.split(add.dataset.placeholder).join(String(++nextIndex));
      const field = template.content.firstElementChild;
      add.before(template.content);
      if (window.jQuery) {
        window.jQuery(field).trigger({ type: "nested:fieldAdded", field: window.jQuery(field) });
      }
      return;
    }

    const remove = event.target.closest(".remove_nested_fields");
    if (remove) {
      event.preventDefault();
      const field = remove.closest(".nested_fields");
      field.querySelector('input[name$="[_destroy]"]').value = "1";
      field.hidden = true;
    }
  });
})();
