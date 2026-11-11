
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If ValueIsFilled(Record.Contract) Then
		ContractDetails_ = Common.ObjectAttributesValues(Record.Contract, "Organization, ARAPCurrency");
		BaseCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(ContractDetails_.Organization);
		Currency = ContractDetails_.ARAPCurrency;
		Items.Contract.Visible = False;
	Else
		Items.ContractInscription.Visible = False;
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ContractInscriptionClick(Item, StandardProcessing)
	OpeningParameters = New Structure("Key", Record.Contract);
	If TypeOf(Record.Contract) = Type("CatalogRef.IntercompanyContracts") Then
		OpenForm("Catalog.IntercompanyContracts.ObjectForm", OpeningParameters);
	Else
		OpenForm("Catalog.CounterpartyContracts.ObjectForm", OpeningParameters);
	EndIf;
EndProcedure

#EndRegion
