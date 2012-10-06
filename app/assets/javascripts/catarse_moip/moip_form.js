CATARSE.MoipForm = Backbone.View.extend({
  el: 'form.moip',

  events: {
    'keyup input#user_document' : 'onUserDocumentKeyup'
  },

  onUserDocumentKeyup: function(){
    var $documentField = $('input#user_document');
    var loader = $('#loading');
    var projectId = $('input#project_id').val();

    var documentNumber = $documentField.val();
    var resultCpf = this.validateCpf(documentNumber);
    var resultCnpj = this.validateCnpj(documentNumber);

    if(resultCpf || resultCnpj) {
      $documentField.addClass('ok').removeClass('error');
      $documentField.attr('disabled', true);

      $.post('/projects/' + projectId + '/backers/' + this.backerId + '/update_info', {
        backer: { payer_document: documentNumber }
      });

      loader.show();
      this.getMoipToken().success(function(response, textStatus){
        loader.hide();
        console.log(response.widget_tag);
        $('#catarse_moip_form').prepend(response.widget_tag);
      });

    } else {
      $documentField.addClass('error').removeClass('ok');
    }
  },

  getMoipToken: function(){
    return $.post('/payment/moip/' + this.backerId + '/get_moip_token')
  },

  checkoutFailure: function(data) {
    var response_data = (data.length > 0 ? data[0] : data);
    this.message.find('p').html(response_data.Mensagem);
    this.message.fadeIn('fast');
    this.loader.hide();
  },

  updateMoipResponse: function(data){
    return $.post('/payment/moip/' + this.backerId + '/moip_response', {response: data});
  },

  checkoutSuccessful: function(data) {
    this.loader.hide();
    $.post('/payment/moip/' + this.backerId + '/moip_response', {response: data}).success(function(){
      if(data.url) {
        var link = $('<a target="__blank">'+data.url+'</a>')
        link.attr('href', data.url);
        $('.link_content').empty().html(link);
        $('.subtitle').fadeIn('fast');
      }

      if($('#payment_type_cards_section').css('display') == 'block') {
        location.href = '/thank_you';
      }
    });
  },

  validateCpf: function(cpfString){
    var product = 0, i, digit;
    cpfString = cpfString.replace(/[.\- ]/g, '');
    var aux = Math.floor(parseFloat(cpfString) / 100);
    var cpf = aux * 100;
    var quotient;

    for(i=0; i<=8; i++){
      product += (aux % 10) * (i+2);
      aux = Math.floor(aux / 10);
    }
    digit = product % 11 < 2 ? 0 : 11 - (product % 11);
    cpf += (digit * 10);
    product = 0;
    aux = Math.floor(cpf / 10);
    for(i=0; i<=9; i++){
      product += (aux % 10) * (i+2);
      aux = Math.floor(aux / 10);
    }
    digit = product % 11 < 2 ? 0 : 11 - (product % 11);
    cpf += digit;
    return parseFloat(cpfString) === cpf;
  },

  validateCnpj: function(cnpj) {
    var numeros, digitos, soma, i, resultado, pos, tamanho, digitos_iguais;
    digitos_iguais = 1;
    if (cnpj.length < 14 && cnpj.length < 15)
      return false;
    for (i = 0; i < cnpj.length - 1; i++)
    if (cnpj.charAt(i) != cnpj.charAt(i + 1))
      {
        digitos_iguais = 0;
        break;
      }
      if (!digitos_iguais)
        {
          tamanho = cnpj.length - 2
          numeros = cnpj.substring(0,tamanho);
          digitos = cnpj.substring(tamanho);
          soma = 0;
          pos = tamanho - 7;
          for (i = tamanho; i >= 1; i--)
          {
            soma += numeros.charAt(tamanho - i) * pos--;
            if (pos < 2)
              pos = 9;
          }
          resultado = soma % 11 < 2 ? 0 : 11 - soma % 11;
          if (resultado != digitos.charAt(0))
            return false;
          tamanho = tamanho + 1;
          numeros = cnpj.substring(0,tamanho);
          soma = 0;
          pos = tamanho - 7;
          for (i = tamanho; i >= 1; i--)
          {
            soma += numeros.charAt(tamanho - i) * pos--;
            if (pos < 2)
              pos = 9;
          }
          resultado = soma % 11 < 2 ? 0 : 11 - soma % 11;
          if (resultado != digitos.charAt(1))
            return false;
          return true;
        }
        else
          return false;
  },

  initialize: function(){
    this.message = this.$('.next_step_after_valid_document .alert-danger');
    this.backerId = $('input#backer_id').val();
    this.loader = this.$('.loader');

    this.paymentChoice = new CATARSE.PaymentChoice();
    this.paymentCard = new CATARSE.PaymentCard();
    this.paymentSlip = new CATARSE.PaymentSlip();
    this.paymentAccount = new CATARSE.PaymentAccount();


    console.log('ok');
  }
});

