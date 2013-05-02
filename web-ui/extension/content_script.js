// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Glue code that runs on the page referencing dart web components.
// Some logic has to be placed here rather than on the background page
// because of chrome security restrictions.

// Port used to send requests to the background page to proxy urls.
var proxyPort = null;

// Port used to send requests to the background page to parse components.
var parsePort = null;

function endsWith(str, pattern) {
  return str.lastIndexOf(pattern) == str.length - pattern.length;
}

function onRequestParse() {
  if (parsePort == null) {
    parsePort = chrome.extension.connect({name: "parse"});
  }
  var l = window.location;
  var pageUrl = l.protocol + "//" + l.host + l.pathname;
  parsePort.postMessage({url: pageUrl});
  parsePort.onMessage.addListener(function(msg) {
    if (msg.type == "CREATE_DATA_URLS") {
      var requests = msg.requests;
      var response = [];
      for (var i = 0; i < requests.length; i++) {
        var request = requests[i];
        var url = request.url;
        var content = request.content;
        var contentType =
            endsWith(url, ".html") ? "text/html" : "application/javascript";
        var objectUrl = webkitURL.createObjectURL(
          new Blob([content], {type: contentType}));
        response.push({url: url, redirectUrl: objectUrl});
      }
      if (proxyPort == null) {
        proxyPort = chrome.extension.connect({name: "proxy"});
      }
      proxyPort.postMessage({requests: response});
      // TODO(jacobr): remove timeout and listen for a message from the
      // background page instead.
      var generatedPageUrl = pageUrl.replace(/[/]([^/]+)$/,
          function(match, p1) { return "/_" + p1 + ".html"});
      window.setTimeout(function() {
        for (var i = 0; i < requests.length; i++) {
          var request = requests[i];
          var url = request.url;
          var content = request.content;
          if (url == generatedPageUrl) {
            // Replace the contents of the existing document with the
            // proxied content at the url with an additional .html added.
            // We prefer this versus redirecting to the page with an extra
            // .html so that refreshing this page does the right thing.
            var newDoc = document.open("text/html", "replace");
            newDoc.write(content);
            newDoc.close();
          }
        }
      }, 100);
    } else if (msg.type == 'MESSAGES') {
      var messages = msg.messages;
      for (var i = 0; i < messages.length; i++) {
        var level = messages[i][0];
        var message = messages[i][1];
        if (level == 'SEVERE') {
          window.console.error(message);
        } else if (level == 'WARNING') {
          window.console.warn(message);
        } else {
          window.console.info(message);
        }
      }
    }
  })

}

document.addEventListener("DOMContentLoaded", function() {
  // Don't re-run the compiler on code we just generated.
  if (document.childNodes.length > 1 &&
      document.childNodes[1] instanceof Comment &&
      document.childNodes[1].nodeValue.indexOf(
        "This file was auto-generated from") >= 0) {
    return;
  }

  // TODO(sigmund): be more selective and run this only when we know
  // the file is using dwc features.
  // Checking for tags like element, template, etc doesn't work for simple
  // examples that only have data-bindings (such as
  // example/explainer/helloworld.html), but this could be fixed once we require
  // using template tags on top-level bindings too. Alternatively we could
  // require that you have a meta-tag that will trigger the extension.
  onRequestParse();
});

window.addEventListener("message", function(event) {
  if (event.source != window)
    return;

  if (event.data.type == "PARSE") {
    onRequestParse();
  }
}, false);
