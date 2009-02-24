// ==UserScript==
// @name          Netflix Half Stars 
// @description   allows half star user ratings on Netflix
// @include       http://*netflix.com/*
// ==/UserScript==
// From http://userscripts.org/scripts/review/8118?format=txt
// Modified by Brian Adkins

if (!unsafeWindow.sbHandler) { return; } 

var sbHandler = unsafeWindow.sbHandler;
sbHandler.sbOffsets = [8,18,27,37,46,56,65,75,84,94];

sbHandler.displayStrings[0.5] = ".5 stars";
sbHandler.displayStrings[1.5] = "1.5 stars";
sbHandler.displayStrings[2.5] = "2.5 stars";
sbHandler.displayStrings[3.5] = "3.5 stars";
sbHandler.displayStrings[4.5] = "4.5 stars";

sbHandler.sbImages[0.5] = new Image();
sbHandler.sbImages[0.5].src = sbHandler.imageRoot+"stars_2_5.gif";

for (var i = 2; i < 11; i++) {
  sbHandler.sbImages[i/2] = new Image();
  sbHandler.sbImages[i/2].src = sbHandler.imageRoot + "stars_2_" + 
    (Math.floor(i/2)) + (i % 2 === 0 ? "0" : "5") + ".gif";
}

sbHandler.getStarCount = function (evt) {
  var x = unsafeWindow.getElementMouseCoordinate(evt, this.element);

  for (var ii = 0; ii < 10; ii++) {
    if (x <= this.sbOffsets[ii]) { return (ii + 1) / 2; }
  }

  return 0;
};
