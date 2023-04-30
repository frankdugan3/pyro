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

// js/pyro/index.js
var pyro_exports = {};
__export(pyro_exports, {
  booleanDataset: () => booleanDataset,
  focusAndSelect: () => focusAndSelect,
  getTimezone: () => getTimezone,
  hooks: () => hooks,
  selectValue: () => selectValue,
  sendTimezoneToServer: () => sendTimezoneToServer,
  throttle: () => throttle
});
module.exports = __toCommonJS(pyro_exports);
if (localStorage.theme === "dark" || !("theme" in localStorage) && window.matchMedia("(prefers-color-scheme: dark)").matches) {
  document.documentElement.classList.add("dark");
} else {
  document.documentElement.classList.remove("dark");
}
window.addEventListener("pyro:theme-dark", (e) => {
  localStorage.theme = "dark";
  document.documentElement.classList.add("dark");
});
window.addEventListener("pyro:theme-light", (e) => {
  localStorage.theme = "light";
  document.documentElement.classList.remove("dark");
});
window.addEventListener("pyro:theme-system", (e) => {
  localStorage.removeItem("theme");
  if (window.matchMedia("(prefers-color-scheme: dark)").matches) {
    document.documentElement.classList.add("dark");
  } else {
    document.documentElement.classList.remove("dark");
  }
  document.documentElement.classList.add("dark");
});
window.addEventListener("pyro:clear", (e) => {
  if (e?.target?.value != "") {
    e.target.value = "";
  }
});
function getTimezone() {
  return Intl.DateTimeFormat().resolvedOptions().timeZone;
}
async function sendTimezoneToServer() {
  const timezone = getTimezone();
  let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
  if (typeof window.localStorage != "undefined" && (!localStorage["timezone"] || localStorage["timezone"] != timezone)) {
    const response = await fetch("/session/set-timezone", {
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
}
var hooks = {
  PyroFlashComponent: {
    mounted() {
      this.oldMessageHTML = document.querySelector(
        `#${this.el.id}-message`
      ).innerHTML;
      if (this.el.dataset?.autoshow !== void 0) {
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
  PyroNudgeIntoView: {
    mounted() {
      nudge(this.el);
    },
    updated() {
      nudge(this.el);
    }
  },
  PyroAutocompleteComponent: {
    mounted() {
      this.lastValueSent = null;
      const expanded = () => {
        return booleanDataset(this.el.getAttribute("aria-expanded"));
      };
      const updateSearchThrottled = throttle(() => {
        if (this.lastValueSent !== this.el.value || !expanded()) {
          this.lastValueSent = this.el.value;
          this.pushEventTo(this.el.dataset.myself, "search", this.el.value);
        }
      }, this.el.dataset.throttleTime);
      if (this.el.dataset.autofocus) {
        focusAndSelect(this.el);
      }
      const selectedIndex = () => {
        return parseInt(this.el.dataset.selectedIndex);
      };
      const options = () => {
        const listbox = document.getElementById(
          this.el.getAttribute("aria-controls")
        );
        if (listbox?.children) {
          return Array.from(listbox.children);
        } else {
          return [];
        }
      };
      const setSelectedIndex = (selectedIndex2) => {
        const rc = parseInt(this.el.dataset.resultsCount);
        selectedIndex2 = (selectedIndex2 % rc + rc) % rc;
        this.el.dataset.selectedIndex = selectedIndex2;
        options().forEach((option, i) => {
          if (i === selectedIndex2) {
            option.setAttribute("aria-selected", true);
          } else {
            option.removeAttribute("aria-selected");
          }
        });
      };
      const pick = (e) => {
        const i = selectedIndex();
        const input_el = document.getElementById(this.el.dataset.inputId);
        let label = "";
        let value = "";
        if (i > -1) {
          const option = options()[i];
          label = option.dataset.label;
          value = option.dataset.value;
        }
        e.preventDefault();
        e.stopPropagation();
        this.el.value = label;
        this.el.focus();
        selectValue(this.el);
        this.pushEventTo(this.el.dataset.myself, "pick", {
          label,
          value
        });
        input_el.value = value;
        input_el.dispatchEvent(new Event("input", { bubbles: true }));
        return false;
      };
      this.el.addEventListener("keydown", (e) => {
        switch (e.key) {
          case "Tab":
            if (expanded()) {
              return pick(e);
            } else {
              return true;
            }
          case "Esc":
          case "Escape":
            if (this.el.value !== "" || !expanded()) {
              e.preventDefault();
              e.stopPropagation();
              this.el.value = "";
              this.el.dataset.selectedIndex = -1;
              options().forEach((option, i) => {
                option.removeAttribute("aria-selected");
              });
              updateSearchThrottled();
              return false;
            } else if (expanded()) {
              e.preventDefault();
              e.stopPropagation();
              this.el.value = this.el.dataset.savedLabel || "";
              selectValue(this.el);
              this.pushEventTo(this.el.dataset.myself, "cancel");
              this.lastValueSent = null;
              return false;
            } else {
              return true;
            }
          case "Enter":
            if (expanded()) {
              return pick(e);
            } else {
              this.el.value = "";
              e.preventDefault();
              e.stopPropagation();
              updateSearchThrottled();
              return false;
            }
          case "Up":
          case "Down":
          case "ArrowUp":
          case "ArrowDown":
            if (expanded()) {
              e.preventDefault();
              e.stopPropagation();
              let i = selectedIndex();
              i = e.key === "ArrowUp" || e.key === "Up" ? i - 1 : i + 1;
              setSelectedIndex(i);
              return false;
            } else {
              return true;
            }
          default:
            return true;
        }
      });
      this.el.addEventListener("focus", (e) => {
        selectValue(this.el);
      });
      this.el.addEventListener("input", (e) => {
        switch (e.inputType) {
          case "insertText":
          case "deleteContentBackward":
          case "deleteContentForward":
            updateSearchThrottled();
            return true;
          default:
            return false;
        }
      });
      this.el.addEventListener("pick", (e) => {
        setSelectedIndex(e.detail.dispatcher.dataset.index);
        return pick(e);
      });
    }
  },
  PyroCopyToClipboard: {
    mounted() {
      this.content = this.el.innerHTML;
      let { value, message, ttl } = this.el.dataset;
      this.el.addEventListener("click", (e) => {
        e.preventDefault();
        navigator.clipboard.writeText(value);
        this.el.innerHTML = message || "Copied to clipboard!";
        this.timeout = window.setTimeout(() => {
          this.el.innerHTML = this.content;
        }, ttl);
      });
    },
    updated() {
      window.clearTimeout(this.timeout);
    },
    destroyed() {
      window.clearTimeout(this.timeout);
    }
  }
};
function nudge(el2) {
  let width = window.innerWidth;
  let height = window.innerHeight;
  let rect = el2.getBoundingClientRect();
  hOffset = el2.dataset?.horizontalOffset || 0;
  vOffset = el2.dataset?.verticalOffset || 0;
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
  if (self.el.dataset?.ttl > 0) {
    self.countdown = self.el.dataset?.ttl;
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
function throttle(callback, limit) {
  let waiting = false;
  return function() {
    if (!waiting) {
      callback.apply(this, arguments);
      waiting = true;
      setTimeout(function() {
        callback.apply(this, arguments);
        waiting = false;
      }, limit);
    }
  };
}
function selectValue(el2) {
  if (typeof el2.select === "function") {
    el2.select();
  }
}
function focusAndSelect(el2) {
  el2.focus();
  selectValue(el2);
}
function booleanDataset(value) {
  return ![null, void 0, false, "false"].includes(value);
}
//# sourceMappingURL=pyro.cjs.js.map
