$(function () {
  window.initializeSoundCloud = () => {
    if (!$('.o-page--cg').length) return;

    let arrWidgets = [];
    $('.c-cg-media__podcast').each((i, el) => {
      let id = el.id;
      let podcast = $(el).parent();
      let start = podcast.data('start');
      let stop = podcast.data('stop');

      let widget = SC.Widget(document.querySelector(`#${id} iframe`));
      arrWidgets.push({
        widget: widget,
        start: start ? parseInt(start) : 0,
        stop: stop ? parseInt(stop) : 0
      });
      // widget.unbind(SC.Widget.Events.READY);
      // widget.unbind(SC.Widget.Events.PLAY);
      // widget.unbind(SC.Widget.Events.PLAY_PROGRESS);
    });

    _.each(arrWidgets, (p) => {
      p.widget.bind(SC.Widget.Events.READY, () => {
        if (p.start) {
          p.widget.play();
          p.widget.bind(SC.Widget.Events.PLAY, () => {
            p.widget.pause();
            p.widget.seekTo(p.start * 1000);
            p.widget.unbind(SC.Widget.Events.PLAY);
          });
        }
        if (p.stop) {
          p.widget.bind(SC.Widget.Events.PLAY_PROGRESS, (e) => {
            if (Math.round(e.currentPosition / 1000) == p.stop) {
              p.widget.pause();
              p.widget.unbind(SC.Widget.Events.PLAY_PROGRESS);
            }
          });
        }
      });
    });
  };
});