(() => {
  'use strict';

  let deferredPrompt = null;
  let reloadingForWorkerUpdate = false;
  const stateEvent = 'cormex-pwa-state-changed';

  const notifyStateChanged = () => {
    window.dispatchEvent(new Event(stateEvent));
  };

  const isStandalone = () => {
    return window.matchMedia('(display-mode: standalone)').matches ||
      window.navigator.standalone === true;
  };

  const isIos = () => {
    const userAgent = window.navigator.userAgent.toLowerCase();
    const classicIos = /iphone|ipad|ipod/.test(userAgent);
    const ipadDesktopMode = window.navigator.platform === 'MacIntel' &&
      window.navigator.maxTouchPoints > 1;
    return classicIos || ipadDesktopMode;
  };

  const registerServiceWorker = async () => {
    if (!('serviceWorker' in navigator) || !window.isSecureContext) {
      return;
    }

    navigator.serviceWorker.addEventListener('controllerchange', () => {
      if (reloadingForWorkerUpdate) {
        return;
      }
      reloadingForWorkerUpdate = true;
      window.location.reload();
    });

    try {
      const workerUrl = new URL(
        'cormex_service_worker.js?v=2',
        document.baseURI,
      );
      const registration = await navigator.serviceWorker.register(workerUrl);
      if (registration.waiting) {
        registration.waiting.postMessage('SKIP_WAITING');
      }
      await registration.update();
    } catch (error) {
      console.warn('CormeX Easy: service worker indisponível.', error);
    }
  };

  window.addEventListener('beforeinstallprompt', (event) => {
    event.preventDefault();
    deferredPrompt = event;
    notifyStateChanged();
  });

  window.addEventListener('appinstalled', () => {
    deferredPrompt = null;
    notifyStateChanged();
  });

  window.cormexPwa = Object.freeze({
    canInstall: () => deferredPrompt !== null,
    isInstalled: isStandalone,
    isIos,
    install: async () => {
      if (deferredPrompt === null) {
        return 'unavailable';
      }

      const prompt = deferredPrompt;
      await prompt.prompt();
      const choice = await prompt.userChoice;
      deferredPrompt = null;
      notifyStateChanged();
      return choice && choice.outcome ? choice.outcome : 'dismissed';
    },
  });

  if (document.readyState === 'complete') {
    void registerServiceWorker();
  } else {
    window.addEventListener('load', () => void registerServiceWorker(), {
      once: true,
    });
  }
})();
