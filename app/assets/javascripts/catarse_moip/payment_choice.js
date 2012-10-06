CATARSE.PaymentChoice = Backbone.View.extend({
  el: '.list_payment',

  events: {
    'change input[type="radio"]' : 'onListPaymentChange'
  },

  onListPaymentChange: function(e){
    $('.payment_section').fadeOut('fast', function(){
      var currentElementId = $(e.currentTarget).attr('id');
      $('#'+currentElementId+'_section').fadeIn('fast');
    });
  },

  initialize: function(){
    this.$('input#payment_type_cards').click();
  }
});

