global.window = require("jsdom")
                .jsdom()
                .createWindow();
global.jQuery = global.$ = require("jquery");

global._ = global.underscore = require("./support/underscore");
global.Backbone = require("./support/backbone");
Backbone.$ = $;

global.Skull = require('./support/skull');
require('./support/app');
require("../../app/assets/javascripts/catarse_moip/moip_form");

describe("MoipForm", function() {
  var view;

  beforeEach(function() {
    view = new App.views.MoipForm();
  });

  it("should be true", function() {
    expect(true).toEqual(true);
  });
});  

