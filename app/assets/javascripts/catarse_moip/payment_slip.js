CATARSE.PaymentSlip = Backbone.View.extend({
  el: '#payment_type_boleto_section',

  events: {
    'click input#build_boleto' : 'onBuildBoletoClick',
    'click .link_content a' : 'onContentClick'
  },

  onBuildBoletoClick: function(e){
    e.preventDefault();
    $(e.currentTarget).hide();
    this.loader.show();

    $('.list_payment input').attr('disabled', true);
    var settings = {
      "Forma":"BoletoBancario"
    }
    MoipWidget(settings);
  },

  onContentClick: function(e){
    location.href="/thank_you";
  }
});

