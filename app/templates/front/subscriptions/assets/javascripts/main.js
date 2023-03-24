class Subscription{

  constructor(){
    this.applicationJS = new ApplicationJS;
    this.organization_id = $('input:hidden[name="organization_id"]').val();
    this.customer_id = $('input:hidden[name="customer_id"]').val();
  }


  // TODO...

  main(){}
}


jQuery(function () {
  var subscription = new Subscription();
  subscription.main();
});