//= require_tree ./catarse_moip

$(function(){
  $('input#user_document').keyup(reviewRequest.getMoipToken);
});
