(function () {
    "use strict";
    // Restores the Marketplace "installed extensions" state only when it is missing.
    // It never overwrites a state that already exists, so user-installed extensions survive.
    var state = {
        "marketplace:installed-extensions": [
            "marketplace:installed:rxri/spicetify-extensions/adblock/adblock.js"
        ],
        "marketplace:installed:rxri/spicetify-extensions/adblock/adblock.js": {"manifest":{"name":"adblockify","description":"Stream Spotify music without interruptions - Block ads instantly, with ease.","preview":"adblock/assets/preview.png","main":"adblock/adblock.js","readme":"adblock/README.md","authors":[{"name":"ririxi","url":"https://github.com/rxri"}],"tags":["ads","block","remove","disable"]},"type":"extension","title":"adblockify","subtitle":"Stream Spotify music without interruptions - Block ads instantly, with ease.","authors":[{"name":"ririxi","url":"https://github.com/rxri"}],"user":"rxri","repo":"spicetify-extensions","branch":"main","imageURL":"https://raw.githubusercontent.com/rxri/spicetify-extensions/main/adblock/assets/preview.png","extensionURL":"https://raw.githubusercontent.com/rxri/spicetify-extensions/main/adblock/adblock.js","readmeURL":"https://raw.githubusercontent.com/rxri/spicetify-extensions/main/adblock/README.md","stars":491,"lastUpdated":"2026-02-16T20:18:53Z","created":"2024-05-09T16:03:19Z"}
    };
    try {
        Object.keys(state).forEach(function (key) {
            if (localStorage.getItem(key) === null) {
                var value = state[key];
                localStorage.setItem(key, typeof value === "string" ? value : JSON.stringify(value));
            }
        });
    } catch (e) { }
})();
