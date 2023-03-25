var Phlegethon = (() => {
  var __defProp = Object.defineProperty;
  var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
  var __getOwnPropNames = Object.getOwnPropertyNames;
  var __hasOwnProp = Object.prototype.hasOwnProperty;
  var __export = (target, all) => {
    for (var name in all)
      __defProp(target, name, { get: all[name], enumerable: true });
  };
  var __copyProps = (to, from, except, desc) => {
    if (from && typeof from === "object" || typeof from === "function") {
      for (let key of __getOwnPropNames(from))
        if (!__hasOwnProp.call(to, key) && key !== except)
          __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
    }
    return to;
  };
  var __toCommonJS = (mod) => __copyProps(__defProp({}, "__esModule", { value: true }), mod);
  var __async = (__this, __arguments, generator) => {
    return new Promise((resolve, reject) => {
      var fulfilled = (value) => {
        try {
          step(generator.next(value));
        } catch (e) {
          reject(e);
        }
      };
      var rejected = (value) => {
        try {
          step(generator.throw(value));
        } catch (e) {
          reject(e);
        }
      };
      var step = (x) => x.done ? resolve(x.value) : Promise.resolve(x.value).then(fulfilled, rejected);
      step((generator = generator.apply(__this, __arguments)).next());
    });
  };

  // js/phlegethon/index.js
  var phlegethon_exports = {};
  __export(phlegethon_exports, {
    getTimezone: () => getTimezone,
    hooks: () => hooks,
    sendTimezoneToServer: () => sendTimezoneToServer
  });
  if (localStorage.theme === "dark" || !("theme" in localStorage) && window.matchMedia("(prefers-color-scheme: dark)").matches) {
    document.documentElement.classList.add("dark");
  } else {
    document.documentElement.classList.remove("dark");
  }
  window.addEventListener("phlegethon:theme-dark", (e) => {
    localStorage.theme = "dark";
    document.documentElement.classList.add("dark");
  });
  window.addEventListener("phlegethon:theme-light", (e) => {
    localStorage.theme = "light";
    document.documentElement.classList.remove("dark");
  });
  window.addEventListener("phlegethon:theme-system", (e) => {
    localStorage.removeItem("theme");
    if (window.matchMedia("(prefers-color-scheme: dark)").matches) {
      document.documentElement.classList.add("dark");
    } else {
      document.documentElement.classList.remove("dark");
    }
    document.documentElement.classList.add("dark");
  });
  window.addEventListener("phlegethon:clear", (e) => {
    var _a;
    if (((_a = e == null ? void 0 : e.target) == null ? void 0 : _a.value) != "") {
      e.target.value = "";
    }
  });
  function getTimezone() {
    return Intl.DateTimeFormat().resolvedOptions().timeZone;
  }
  function sendTimezoneToServer() {
    return __async(this, null, function* () {
      const timezone = getTimezone();
      let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
      if (typeof window.localStorage != "undefined" && (!localStorage["timezone"] || localStorage["timezone"] != timezone)) {
        const response = yield fetch("/session/set-timezone", {
          method: "POST",
          mode: "cors",
          cache: "no-cache",
          credentials: "same-origin",
          headers: {
            "Content-Type": "application/json",
            "x-csrf-token": csrfToken
          },
          referrerPolicy: "no-referrer",
          body: JSON.stringify({ timezone })
        });
        if (response.status === 200) {
          localStorage["timezone"] = timezone;
        }
      }
    });
  }
  var hooks = {
    PhlegethonFlashComponent: {
      mounted() {
        this.oldMessageHTML = document.querySelector(
          `#${this.el.id}-message`
        ).innerHTML;
        if (this.el.dataset.autoshow !== void 0) {
          window.liveSocket.execJS(
            this.el,
            this.el.getAttribute("data-show-exec-js")
          );
        }
        resetHideTTL(this);
      },
      updated() {
        newMessageHTML = document.querySelector(
          `#${this.el.id}-message`
        ).innerHTML;
        if (newMessageHTML !== this.oldMessageHTML) {
          this.oldEl = this.el;
          this.oldMessageHTML = newMessageHTML;
          resetHideTTL(this);
        } else {
          el.value = this.countdown;
        }
      },
      destroyed() {
        clearInterval(this.ttlInterval);
      }
    },
    PhlegethonNudgeIntoView: {
      mounted() {
        nudge(this.el);
      },
      updated() {
        nudge(this.el);
      }
    },
    PhlegethonAutocompleteComponent: {
      mounted() {
        this.el.addEventListener("keydown", (event) => {
          switch (event.key) {
            case "ArrowDown":
              this.pushEvent("select_item", {
                index: (this.el.selectedIndex + 1) % this.el.options.length
              });
              break;
            case "ArrowUp":
              this.pushEvent("select_item", {
                index: (this.el.selectedIndex - 1 + this.el.options.length) % this.el.options.length
              });
              break;
            case "Enter":
              break;
            default:
              break;
          }
        });
      }
    }
  };
  function nudge(el2) {
    let width = window.innerWidth;
    let height = window.innerHeight;
    let rect = el2.getBoundingClientRect();
    hOffset = el2.dataset.horizontalOffset || 0;
    vOffset = el2.dataset.verticalOffset || 0;
    if (rect.right + 24 > width) {
      el2.style.right = hOffset;
      el2.style.left = null;
    } else {
      el2.style.left = hOffset;
      el2.style.right = null;
    }
    if (rect.bottom + 24 > height) {
      el2.style.bottom = vOffset;
      el2.style.top = null;
    } else {
      el2.style.top = vOffset;
      el2.style.bottom = null;
    }
  }
  function resetHideTTL(self) {
    clearInterval(self.ttlInterval);
    if (self.el.dataset.ttl > 0) {
      self.countdown = self.el.dataset.ttl;
      self.ttlInterval = setInterval(() => {
        self.countdown = self.countdown - 16.7;
        if (self.countdown <= 0) {
          window.liveSocket.execJS(
            self.el,
            self.el.getAttribute("data-hide-exec-js")
          );
        } else {
          el = document.querySelector(`#${self.el.id}>section>progress`);
          if (el) {
            el.value = self.countdown;
          } else {
            clearInterval(self.ttlInterval);
          }
        }
      }, 16.7);
    }
  }
  return __toCommonJS(phlegethon_exports);
})();
