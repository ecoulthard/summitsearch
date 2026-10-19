(() => {
  if (window.SummitForumPhotos) return;
  window.SummitForumPhotos = true;

  const context = (widget) => {
    const params = new URLSearchParams();
    params.set(widget.dataset.topicId ? 'topic_id' : 'messageboard_id',
      widget.dataset.topicId || widget.dataset.messageboardId);
    return params;
  };
  const status = (widget, text) => { widget.querySelector('[data-photo-status]').textContent = text; };
  const request = async (url, options = {}) => {
    const response = await fetch(url, { credentials: 'same-origin', ...options,
      headers: { Accept: 'application/json', 'X-CSRF-Token': document.querySelector('meta[name=csrf-token]')?.content || '' } });
    const data = await response.json();
    if (!response.ok) throw new Error(data.error || 'Unable to load photos. Please sign in and try again.');
    return data;
  };
  const add = (widget, photo) => {
    const selection = widget.querySelector('[data-photo-selection]');
    if ([...selection.querySelectorAll('input')].some((input) => input.value === String(photo.id))) return;
    if (selection.querySelectorAll('input').length >= 50) throw new Error('Choose up to 50 photos per post.');
    const field = document.getElementById(widget.dataset.textareaId);
    if (!field) throw new Error('The comment field could not be found.');
    const input = document.createElement('input');
    input.type = 'hidden'; input.name = 'forum_photo_ids[]'; input.value = photo.id;
    selection.append(input);
    const marker = `\n\n[[photo=${photo.id}]]\n\n`;
    field.setRangeText(marker, field.selectionStart, field.selectionEnd, 'end');
    field.dispatchEvent(new Event('input', { bubbles: true }));
    status(widget, `Added ${photo.title}.`);
  };
  const load = async (widget, page) => {
    const params = context(widget);
    params.set('search', widget.querySelector('[data-photo-search]').value);
    params.set('page', page);
    const data = await request(`${widget.dataset.photosUrl}?${params}`);
    const results = widget.querySelector('[data-photo-results]');
    if (page === 1) results.replaceChildren();
    data.photos.forEach((photo) => {
      const button = document.createElement('button');
      button.type = 'button';
      const image = document.createElement('img');
      image.src = photo.thumbnail; image.alt = ''; image.width = 80; image.loading = 'lazy';
      button.append(image, document.createTextNode(photo.title));
      button.addEventListener('click', () => {
        try { add(widget, photo); button.disabled = true; }
        catch (error) { status(widget, error.message); }
      });
      results.append(button);
    });
    const more = widget.querySelector('[data-photo-more]');
    more.hidden = !data.more; more.dataset.page = page + 1;
    status(widget, data.photos.length ? 'Choose a photo to add it to your comment.' : 'No available photos found.');
  };
  document.addEventListener('click', async (event) => {
    const button = event.target.closest('button');
    const widget = button?.closest('[data-forum-photos]');
    if (!widget) return;
    const action = ['photoLoad', 'photoMore', 'placeLoad', 'photoUpload'].find((name) => name in button.dataset);
    if (!action) return;
    event.preventDefault(); button.disabled = true;
    try {
      if (action === 'photoLoad' || action === 'photoMore') {
        await load(widget, action === 'photoMore' ? Number(button.dataset.page) : 1);
      } else if (action === 'placeLoad') {
        const params = context(widget);
        params.set('search', widget.querySelector('[data-place-search]').value);
        const places = await request(`${widget.dataset.placesUrl}?${params}`);
        const select = widget.querySelector('[data-photo-place]');
        select.replaceChildren(new Option('Choose a nearby place', ''));
        places.forEach((place) => select.add(new Option(place.name, place.id)));
        status(widget, places.length ? 'Choose a reference place for your photos.' : 'No places found; enter at least two letters.');
      } else {
        const files = [...widget.querySelector('[data-photo-files]').files];
        const place = widget.querySelector('[data-photo-place]').value;
        if (!place || !files.length) throw new Error('Choose a nearby place and at least one photo.');
        if (files.length + widget.querySelectorAll('[data-photo-selection] input').length > 50) throw new Error('Choose up to 50 photos per post.');
        for (const file of files) {
          status(widget, `Uploading ${file.name}…`);
          const form = new FormData();
          context(widget).forEach((value, key) => form.set(key, value));
          form.set('file', file); form.set('place_id', place); form.set('title', file.name);
          add(widget, await request(widget.dataset.photosUrl, { method: 'POST', body: form }));
        }
        widget.querySelector('[data-photo-files]').value = '';
      }
    } catch (error) { status(widget, error.message); }
    finally { button.disabled = false; }
  });
  document.addEventListener('keydown', (event) => {
    if (event.key !== 'Enter') return;
    const widget = event.target.closest('[data-forum-photos]');
    if (!widget) return;
    const button = event.target.matches('[data-photo-search]') ? '[data-photo-load]' :
      event.target.matches('[data-place-search]') ? '[data-place-load]' : null;
    if (button) { event.preventDefault(); widget.querySelector(button).click(); }
  });
})();
