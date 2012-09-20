var checkoutFailure = function(data) {
  console.log('error -> ', data);
}

var checkoutSuccessful = function(data) {
  console.log('ok ->', data)
  if(data.StatusPagamento == 'Sucesso') {
    if(data.url) {
      var link = $('<a target="__blank">'+data.url+'</a>')
      link.attr('href', data.url);
      $('.link_content').empty().html(link);
      $('.subtitle').fadeIn(300);
    }
  }
}

var validators = {
  hasContent: function(element) {
    var value = $(element).val().replace(/[\-\.\_\/\s]/g, '');
    if(value && value.length > 0){
      $(element).addClass("ok").removeClass("error")
      return true
    } else {
      $(element).addClass("error").removeClass("ok")
      return false
    }
  }
}

var creditCardInputValidator = function() {
  all_ok = true;

  $.each($('#payment_type_cards_section input[type="text"]'), function(i, item){
    if($(item).attr('id') != 'payment_card_flag') {
      if(!validators.hasContent(item)){
        all_ok = false
      }
    }
  });

  if(all_ok) {
    $('input#credit_card_submit').attr('disabled', false);
  } else {
    $('input#credit_card_submit').attr('disabled', true);
  }

}

var reviewRequest = {
  getMoipToken: function() {
    $documentField = $('input#user_document');

    var backerId = $('input#backer_id').val();
    var projectId = $('input#project_id').val();

    var documentNumber = $documentField.val();
    var resultCpf = documentValidation.validateCpf(documentNumber);
    var resultCnpj = documentValidation.validateCnpj(documentNumber);

    if(resultCpf || resultCnpj) {
      $documentField.addClass('ok').removeClass('error');
      $documentField.attr('disabled', true);

      $.post('/projects/'+projectId+'/backers/'+backerId+'/update_info', {
        backer: { payer_document: documentNumber }
      });

      $.post('/payment/moip/'+backerId+'/get_moip_token', function(response, textStatus){
        $('#catarse_moip_form').prepend(response.widget_tag);
        if(textStatus == 'success') {
          reviewRequest.observePaymentTypeSelection();
        }
      });

    } else {
      $documentField.addClass('error').removeClass('ok');
    }
  },

  observePaymentTypeSelection: function() {
    $('.next_step_after_valid_document').fadeIn(300);

    $('.list_payment input').live('change', function(e){
      $('.payment_section').fadeOut(300, function(){
        var currentElementId = $(e.currentTarget).attr('id');
        $('#'+currentElementId+'_section').fadeIn(300);
        reviewRequest.observeBoletoLink();
        reviewRequest.observeCreditCardLink();
      });
    });

    $('.list_payment input#payment_type_cards').click();

    $('input#payment_card_date').mask('99/99');
    $('input#payment_card_birth').mask('99/99/9999');
    $('input#payment_card_cpf').mask("999.999.999-99");
    $('input#payment_card_phone').mask("(99) 9999-9999");
  },


  observeBoletoLink: function() {
    $('input#build_boleto').click(function(e){
      e.preventDefault();
      $('.list_payment input').attr('disabled', true);
      var settings = {
        "Forma":"BoletoBancario"
      }
      MoipWidget(settings);
    });

    $('.link_content a').live('click', function(e){
      location.href="/thank_you";
    });
  },

  observeCreditCardLink: function() {
    var cardFlagName = ''
    $('#payment_type_cards_section input[type="text"]').live('focusout', function(e){
      creditCardInputValidator();
    });

    $('#payment_type_cards_section input[type="text"]').live('keyup', function(e){
      $target = $(e.currentTarget);
      creditCardInputValidator();
      if($target.attr('id') == 'payment_card_number') {
        cardFlagName = getCardFlag($target.val());
        $('input#payment_card_flag').val(cardFlagName)
      }
    });

    $('input#credit_card_submit').click(function(e){
      e.preventDefault();
      $('.list_payment input').attr('disabled', true);
      var settings = {
        "Forma": "CartaoCredito",
        "Instituicao": cardFlagName,
        "Parcelas": "1",
        "Recebimento": "AVista",
        "CartaoCredito": {
          "Numero": $('input#payment_card_number').val(),
          "Expiracao": $('input#payment_card_date').val(),
          "CodigoSeguranca": $('input#payment_card_source').val(),
          "Portador": {
            "Nome": $('input#payment_card_name').val(),
            "DataNascimento": $('input#payment_card_birth').val(),
            "Telefone": $('input#payment_card_phone').val(),
            "Identidade": $('input#payment_card_cpf').val()
          }
        }
      }

      MoipWidget(settings);
    });
  }

}

var getCardFlag = function(number) {
  var cc = (number + '').replace(/\s/g, ''); //remove space

  if ((/^(34|37)/).test(cc) && cc.length == 15) {
      return 'AmericanExpress'; //AMEX begins with 34 or 37, and length is 15.
  } else if ((/^(51|52|53|54|55)/).test(cc) && cc.length == 16) {
      return 'MasterCard'; //MasterCard beigins with 51-55, and length is 16.
  } else if ((/^(4)/).test(cc) && (cc.length == 13 || cc.length == 16)) {
      return 'Visa'; //VISA begins with 4, and length is 13 or 16.
  } else if ((/^(300|301|302|303|304|305|36|38)/).test(cc) && cc.length == 14) {
      return 'Diners'; //Diners Club begins with 300-305 or 36 or 38, and length is 14.
  } else if ((/^(38)/).test(cc) && cc.length == 19) {
      return 'Hipercard';
  }
  //else if ((/^(6011)/).test(cc) && cc.length == 16) {
      //return 'Discover'; //Discover begins with 6011, and length is 16.
  //} else if ((/^(3)/).test(cc) && cc.length == 16) {
      //return 'JCB';  //JCB begins with 3, and length is 16.
  //} else if ((/^(2131|1800)/).test(cc) && cc.length == 15) {
      //return 'JCB';  //JCB begins with 2131 or 1800, and length is 15.
  //}
  return false;
}

var documentValidation = {
  validateCpf: function(cpf) {
    var numeros, digitos, soma, i, resultado, digitos_iguais;
    digitos_iguais = 1;
    if (cpf.length < 11)
      return false;
    for (i = 0; i < cpf.length - 1; i++)
    if (cpf.charAt(i) != cpf.charAt(i + 1))
      {
        digitos_iguais = 0;
        break;
      }
      if (!digitos_iguais)
        {
          numeros = cpf.substring(0,9);
          digitos = cpf.substring(9);
          soma = 0;
          for (i = 10; i > 1; i--)
          soma += numeros.charAt(10 - i) * i;
          resultado = soma % 11 < 2 ? 0 : 11 - soma % 11;
          if (resultado != digitos.charAt(0))
            return false;
          numeros = cpf.substring(0,10);
          soma = 0;
          for (i = 11; i > 1; i--)
          soma += numeros.charAt(11 - i) * i;
          resultado = soma % 11 < 2 ? 0 : 11 - soma % 11;
          if (resultado != digitos.charAt(1))
            return false;
          return true;
        }
        else
          return false;
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
  }

}
