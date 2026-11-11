
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Parameters.Property("PaymentMethod", PaymentMethod);
	Parameters.Property("AmountToPay", AmountToPay);
	Parameters.Property("Currency", Currency);
	
	AvailablePaymentMethods_ = Undefined;
	Parameters.Property("AvailablePaymentMethods_", AvailablePaymentMethods_);
	
	UpdateFormData();
	SetVisibility1(AvailablePaymentMethods_);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ChooseAPaymentMethod(Command)
	
	Button = CurrentItem;
	
	If Button = Items.BankCardButton Then
		PaymentMethod_ = "BankCard";
	ElsIf Button = Items.CashButton Then
		PaymentMethod_ = "CashPayment";
	ElsIf Button = Items.YandexCheckoutButton Then
		PaymentMethod_ = "YandexCheckout";
	EndIf;
	
	ProcessSelection(PaymentMethod_);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure UpdateFormData()
	
	Module = DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery;
	AmountToPayPresentation = Module.AmountToPayPresentation(ThisForm);
	PaymentMethodPresentation = Module.PaymentMethodPresentation(ThisForm);
	
	Items.DecorationAmountToBePaid.Title = New FormattedString(AmountToPayPresentation,
		StyleFonts.EnlargedTextFontSelectedAssemblyAndDelivery,
		StyleColors.TextColorMainKittingAndDelivery);
		
	Items.DecorationMethodOfPayment.Title = New FormattedString(PaymentMethodPresentation,
		StyleFonts.TextFontAssemblyAndDelivery,
		StyleColors.TextColorMainKittingAndDelivery);
	
EndProcedure

&AtServer
Procedure SetVisibility1(AvailablePaymentMethods_)
	
	Items.CashGroup_2.Visible = (AvailablePaymentMethods_.FindByValue("CashPayment") <> Undefined);
	Items.CashFrame.Visible = Items.CashGroup_2.Visible;
	Items.BankCardGroup.Visible = (AvailablePaymentMethods_.FindByValue("ByPaymentCard") <> Undefined);
	Items.BankCardFrame.Visible = Items.BankCardGroup.Visible;
	
EndProcedure

&AtClient
Procedure ProcessSelection(PaymentMethod_)
	
	StandardProcessing = False;
	Close(PaymentMethod_);
	
EndProcedure

#EndRegion
