
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("SettingsStructure") Then
		
		FillPropertyValues(ThisObject, Parameters.SettingsStructure);
		
		FillPropertyValues(ThisObject, SettingsStructure);
		
	EndIf;
	
	If Not ValueIsFilled(PriceKind) Then
		PriceKind = PriceManagementSystemServerCall.PriceTypePriceList_();
	EndIf;
	
	AdjustPriceOption(ThisObject);
	
	SetVisibilityOfFormPagesAndAccessibilityOfElements();

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	AttributesNotToCheck = New Array();
	
	If Not (PricePopulationOption = "ItemsPrices" And UsePriceType) Then
		AttributesNotToCheck.Add("PriceKind");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);
	
EndProcedure

#EndRegion

#Region EventHandlers

&AtClient
Procedure OptionToFillInPricesAgreementOnChange(Item)
	
	WhenChangingPriceOption(ThisForm);
	
EndProcedure

&AtClient
Procedure OptionForFillingInPricesPartnerOnChange(Item)
	
	WhenChangingPriceOption(ThisForm);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure FillInAndClose(Command)
	
	EverythingIsFilled = CheckFilling();
	
	If EverythingIsFilled Then
		FillPropertyValues(SettingsStructure, ThisObject);
		Close(SettingsStructure);
	EndIf;
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close(Undefined);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure WhenChangingPriceOption(Form)
	
	If Form.PricePopulationOption = "ItemsPrices" Then
		Form.Items.TypeOfPricePartner.Enabled 	= True;
		Form.Items.TypeOfPriceAgreement.Enabled= True;
		Form.UsePriceType = True;
	Else
		Form.Items.TypeOfPricePartner.Enabled 	= False;
		Form.Items.TypeOfPriceAgreement.Enabled= False;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AdjustPriceOption(Form)

	If Form.FillInPartner And Form.PricePopulationOption = "ItemsPricesOfVendor" And Not Form.FillInTermsOfSales Then
		Form.PricePopulationOption = "MinimumSupplierPrice";
	ElsIf Form.FillInTermsOfSales And Form.PricePopulationOption = "MinimumSupplierPrice" Then
		Form.PricePopulationOption = "ItemsPricesOfVendor";
	ElsIf Not Form.PricePopulationOption = "ItemsPrices" And Not Form.FillInPartner And Not Form.FillInTermsOfSales Then
		Form.PricePopulationOption = "ItemsPrices";
	EndIf;
	
	If Form.PricePopulationOption = "ItemsPrices" And (Form.FillInPartner Or Form.FillInTermsOfSales) Then
		Form.UsePriceType = True;
	EndIf; 

EndProcedure

&AtServer
Procedure SetVisibilityOfFormPagesAndAccessibilityOfElements()
	
	If FillInPartner Then
		If FillInTermsOfSales Then
			Items.PurchasePriceGroup.CurrentPage = Items.GroupPricesAgreement;
		Else
			Items.PurchasePriceGroup.CurrentPage = Items.PriceGroupPartner;
		EndIf;
	Else
		Items.PurchasePriceGroup.CurrentPage = Items.GroupTypeOfPurchasePrice;
		UsePriceType = True;
	EndIf;
	
	WhenChangingPriceOption(ThisForm);
	
EndProcedure

#EndRegion