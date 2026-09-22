{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    try {
      const appRunner = await engineInitializer.initializeEngine();
      await appRunner.runApp();
      document.documentElement.classList.add('flutter-ready');
      window.setTimeout(function() {
        const splash = document.getElementById('cormex-splash');
        if (splash) splash.remove();
      }, 350);
    } catch (error) {
      const subtitle = document.querySelector('.cormex-splash-subtitle');
      if (subtitle) {
        subtitle.textContent = 'Não foi possível iniciar. Verifique a conexão e tente novamente.';
      }
      throw error;
    }
  },
});
