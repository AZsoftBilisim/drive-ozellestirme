
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("Filter") And Parameters.Filter.Property("Contract") Then
		Contract = Parameters.Filter.Contract; // Reference link.Contractors' agreements, Referenceslink.Agreements between organizations
		If ValueIsFilled(Contract) Then
			ContractDetails_ = Common.ObjectAttributesValues(Contract, "Organization, ARAPCurrency");
			CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(ContractDetails_.Organization);
			Items.CourseNumerator.Title = String(CurrencyOfComplianceAccounting);
			Items.CourseDenominator.Title = String(ContractDetails_.ARAPCurrency);
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ContractClick(Item, StandardProcessing)
	OpeningParameters = New Structure("Key", Contract);
	If TypeOf(Contract) = Type("CatalogRef.IntercompanyContracts") Then
		OpenForm("Catalog.IntercompanyContracts.ObjectForm", OpeningParameters);
	Else
		OpenForm("Catalog.CounterpartyContracts.ObjectForm", OpeningParameters);
	EndIf;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	Parameter = Contract;
EndProcedure

#EndRegion

