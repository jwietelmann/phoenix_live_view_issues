// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from "../css/app.css"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
import "mdn-polyfills/NodeList.prototype.forEach"
import "mdn-polyfills/Element.prototype.closest"
import "mdn-polyfills/Element.prototype.matches"
import "child-replace-with-polyfill"
import "url-search-params-polyfill"
import "formdata-polyfill"
import "classlist-polyfill"

import "phoenix_html"
import LiveSocket, {View} from "phoenix_live_view"

let liveSocket = new LiveSocket("/live")
liveSocket.connect()
window.liveSocket = liveSocket

View.prototype._originalUpdate = View.prototype.update
View.prototype.update = function(diff) {
  console.log("Diff:")
  console.log(diff)
  this._originalUpdate(diff)
}

// Import local files
//
// Local files can be imported directly using relative paths, for example:
// import socket from "./socket"

