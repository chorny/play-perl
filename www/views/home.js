pp.views.Home = pp.View.Common.extend({
    t: 'home',
    selfRender: true,

    events: {
        'click .login-with-persona': 'personaLogin',
    },

    subviews: {
        '.signin': function () { return new pp.views.Signin(); }
    },

    afterInitialize: function () {
        this.listenTo(pp.app.user, 'change:registered', function () {
            pp.app.router.navigate("/", { trigger: true, replace: true });
        });
    },

    personaLogin: function () {
        navigator.id.request();
    }
});
