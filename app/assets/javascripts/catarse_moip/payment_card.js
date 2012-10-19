CATARSE.PaymentCard = CATARSE.UserDocument.extend({
  el: '#payment_type_cards_section',
  
  events: {
    'keyup input[type="text"]' : 'creditCardInputValidator',
    'keyup #payment_card_number' : 'onKeyupPaymentCardNumber',
    'click input#credit_card_submit' : 'onSubmit',
    'keyup #payment_card_cpf' : 'onUserDocumentKeyup'
  },

  initialize: function(options){
    // Set credit card fields masks
    this.moipForm = options.moipForm;
    this.$('input#payment_card_date').mask('99/99');
    this.$('input#payment_card_birth').mask('99/99/9999');
    this.$('input#payment_card_cpf').mask("999.999.999-99");
    this.$('input#payment_card_phone').mask("(99) 9999-9999?9");
  },

  onKeyupPaymentCardNumber: function(e){
    this.$('input#payment_card_flag').val(this.getCardFlag($(e.currentTarget).val()))
  },

  onSubmit: function(e) {
    var that = this;
    e.preventDefault();
    $(e.currentTarget).hide();
    that.moipForm.loader.show();

    // Get token and send payment
    that.moipForm.getMoipToken(function(){
      var settings = {
        "Forma": "CartaoCredito",
        "Instituicao": that.$('input#payment_card_flag').val(),
        "Parcelas": "1",
        "Recebimento": "AVista",
        "CartaoCredito": {
          "Numero": that.$('input#payment_card_number').val(),
          "Expiracao": that.$('input#payment_card_date').val(),
          "CodigoSeguranca": that.$('input#payment_card_source').val(),
          "Portador": {
            "Nome": that.$('input#payment_card_name').val(),
            "DataNascimento": that.$('input#payment_card_birth').val(),
            "Telefone": that.$('input#payment_card_phone').val(),
            "Identidade": that.$('input#payment_card_cpf').val()
          }
        }
      };
      MoipWidget(settings);
    });
  },

  hasContent: function(element) {
    var value = $(element).val().replace(/[\-\.\_\/\s]/g, '');
    if(value && value.length > 0){
      $(element).addClass("ok").removeClass("error")
      return true
    } else {
      $(element).addClass("error").removeClass("ok")
      return false
    }
  },

  creditCardInputValidator: function() {
    var that = this;
    var all_ok = true;
    $.each($('#payment_type_cards_section input[type="text"]'), function(i, item){
      all_ok = that.hasContent(item);
    });
    $('input#credit_card_submit').attr('disabled', !all_ok);
  },

  getCardFlag: function(number) {
    var cc = (number + '').replace(/\s/g, ''); //remove space

    if ((/^(34|37)/).test(cc) && cc.length == 15) {
      return 'AmericanExpress'; //AMEX begins with 34 or 37, and length is 15.
    } else if ((/^(51|52|53|54|55)/).test(cc) && cc.length == 16) {
      return 'Mastercard'; //MasterCard beigins with 51-55, and length is 16.
    } else if ((/^(4)/).test(cc) && (cc.length == 13 || cc.length == 16)) {
      return 'Visa'; //VISA begins with 4, and length is 13 or 16.
    } else if ((/^(300|301|302|303|304|305|36|38)/).test(cc) && cc.length == 14) {
      return 'Diners'; //Diners Club begins with 300-305 or 36 or 38, and length is 14.
    } else if ((/^(38)/).test(cc) && cc.length == 19) {
      return 'Hipercard';
    }
    return 'Desconhecido';
  }
});

