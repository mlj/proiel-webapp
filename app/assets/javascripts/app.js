if (document.querySelector('#app')) {
  Vue.config.debug = true;

  var router = new VueRouter;
  var store = new Store;

  router.map({
    '/syntax': {
      component: SyntaxEditor
    },
    '/morphology': {
      component: MorphologyEditor
    }
  });

  router.beforeEach(function () {
    window.scrollTo(0, 0)
  });

  router.redirect({
    '*': '/morphology'
  });

  router.start(App, '#app');
}
