CATARSE.PaymentSlip = CATARSE.UserDocument.extend({
  el: '#payment_type_boleto_section',

  events: {
    'click input#build_boleto' : 'onBuildBoletoClick',
    'click .link_content a' : 'onContentClick',
    'keyup #user_document_payment_slip' : 'onUserDocumentPaymentSlipKeyup'
  },

  onUserDocumentPaymentSlipKeyup: function(e){
    var $documentField = $(e.currentTarget);
    this.onUserDocumentKeyup(e);
    $('input#build_boleto').attr('disabled', !$documentField.hasClass('ok'));
  },

  initialize: function(options){
    this.moipForm = options.moipForm;
    this.$('input#user_document_payment_slip').mask("999.999.999-99");
  },

  onBuildBoletoClick: function(e){
    var that = this;
    e.preventDefault();
    $(e.currentTarget).hide();
    that.moipForm.loader.show();

    // Get token and send payment
    that.moipForm.getMoipToken(function(){
      var settings = {
        "Forma":"BoletoBancario"
      }
      MoipWidget(settings);
    });
  }
});

