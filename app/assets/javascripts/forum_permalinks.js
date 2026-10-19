// Forem topic bookmarks carry post_123 fragments, which servers never receive.
// Imported post IDs are preserved. Resolve an off-page anchor via the permalink
// rather than assuming Forem and Thredded have the same page size.
function resolveForumPostFragment() {
  var match = window.location.hash.match(/^#post_([1-9][0-9]*)$/);
  if (!match || document.getElementById("post_" + match[1])) return;

  var template = document.body.dataset.forumPermalinkTemplate;
  if (template) window.location.replace(template.replace(/\/1$/, "/" + match[1]));
}
document.addEventListener("DOMContentLoaded", resolveForumPostFragment);
window.addEventListener("hashchange", resolveForumPostFragment);
