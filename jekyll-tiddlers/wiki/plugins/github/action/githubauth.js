/*\
title: $:/plugins/jorgebg/github/action/githubauth.js
type: application/javascript
module-type: widget

Action widget to auth with GitHub

\*/
(function(){
  "use strict";

  var Widget = require("$:/core/modules/widgets/widget.js").widget;

  var GithubLoginWidget = function(parseTreeNode,options) {
    this.initialise(parseTreeNode,options);
  };

  /*
  Inherit from the base widget class
  */
  GithubLoginWidget.prototype = new Widget();

  /*
  Render this widget into the DOM
  */
  GithubLoginWidget.prototype.render = function(parent,nextSibling) {
    this.computeAttributes();
    this.execute();
  };

  /*
  Compute the internal state of the widget
  */
  GithubLoginWidget.prototype.execute = function() {

  };

  /*
  Refresh the widget by ensuring our attributes are up to date
  */
  GithubLoginWidget.prototype.refresh = function(changedTiddlers) {
  };

  /*
  Invoke the action associated with this widget
  */
  GithubLoginWidget.prototype.invokeAction = function(triggeringWidget,event) {
    var OAuth = require('$:/plugins/jorgebg/github/githubadaptor.js').OAuth;
    (new OAuth($tw.wiki)).login();
    return true; // Action was invoked
  };

  exports["action-githubauth"] = GithubLoginWidget;

})();
