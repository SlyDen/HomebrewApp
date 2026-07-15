(() => {
  const normalizedBasePath = (() => {
    const configuredBasePath = window.baseUrl || "/";
    const leadingSlashPath = configuredBasePath.startsWith("/")
      ? configuredBasePath
      : `/${configuredBasePath}`;

    return leadingSlashPath.endsWith("/")
      ? leadingSlashPath
      : `${leadingSlashPath}/`;
  })();

  const rootPaths = new Set([
    normalizedBasePath,
    normalizedBasePath === "/" ? "/" : normalizedBasePath.slice(0, -1),
  ]);
  const documentationPath = `${normalizedBasePath}documentation/homebrewapp/`;
  const documentationPaths = new Set([
    documentationPath,
    documentationPath.slice(0, -1),
  ]);

  const showDocumentationRoute = () => {
    if (!rootPaths.has(window.location.pathname)) {
      return;
    }

    window.history.replaceState(
      window.history.state,
      "",
      `${documentationPath}${window.location.search}${window.location.hash}`,
    );
  };

  const restoreRootUrl = () => {
    if (!documentationPaths.has(window.location.pathname)) {
      return;
    }

    const pageTitle = document.querySelector("main h1");
    if (pageTitle?.textContent?.trim() !== "HomebrewApp") {
      return;
    }

    window.history.replaceState(
      window.history.state,
      "",
      `${normalizedBasePath}${window.location.search}${window.location.hash}`,
    );
  };

  showDocumentationRoute();

  const pageObserver = new MutationObserver(restoreRootUrl);
  pageObserver.observe(document.documentElement, {
    childList: true,
    subtree: true,
  });

  window.addEventListener("popstate", () => {
    showDocumentationRoute();
    window.requestAnimationFrame(restoreRootUrl);
  });
})();
