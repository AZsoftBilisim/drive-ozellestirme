
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	// Deceived.Loading
	// Before recording an object, it is necessary to update the service details and clean up unused,
	// but possibly selected selection values, during the node configuration process.
	ExchangePlans.DataSynchronizationViaUniversalFormat.UpdatingDetailsOfExchangePlanNode(ThisObject);
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DataExchangeEventsTMERP.UpdateRegistrationMechanismCache();
	
EndProcedure

Procedure BeforeDelete(Cancel)
	
	// Deceived.Loading
	// The exchange can be deleted programmatically. 
	// In this case, it is necessary to update the constant used by the exchange of the company's account.
	If GetFunctionalOption("TradeManagement")
		And (SettingsMode = ExchangePlans.DataSynchronizationViaUniversalFormat.IdOfExchangeSetupBP30()
		Or SettingsMode = ExchangePlans.DataSynchronizationViaUniversalFormat.IdOfExchangeSetupBPCORP30()
		Or SettingsMode = ExchangePlans.DataSynchronizationViaUniversalFormat.IdOfBasicUTBP30ExchangeSetup()
		Or SettingsMode = ExchangePlans.DataSynchronizationViaUniversalFormat.IdOfExchangeSettingsIsUniversal()) Then
		
		TMDataExchange.UpdateAttributeForUsingExchangeWithAccounting(ThisObject, True);
		
	EndIf;

	If DataExchange.Load Then
		Return;
	EndIf;
	
EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	If FillingData = Undefined Then
		
		// Customizing the Selection node.
		UseFilterByCompanies      = False;
		DocumentsExportStartDate         = BegOfYear(CurrentSessionDate());
		CatalogsSendingRules          = "AutoSynchronization";
		DocumentsSendingRules            = "AutoSynchronization";
		RulesForCreatingCounterpartyContracts = "WithoutSeparation";
		ExportModeOnDemand        = Enums.ExchangeObjectExportModes.ExportIfNecessary;
		ManagementCompany            = Catalogs.Companies.ManagementCompany;
		UnloadManagementCompany   = False;
		UploadAnalyticsByWarehouse          = True;
		ExchangeFormatVersion                  = "1.8";
		UploadProductPrices            = SettingsMode = "CashExchange";
				
		If ExchangePlans.DataSynchronizationViaUniversalFormat.ThisIsIdOfSBP3Setting(SettingsMode) Then
			ExchangeFormatVersion = "1.10";
			DoNotExportPictures = True;
		ElsIf SettingsMode = "ExchangeUP2ZUP3" Then
			ExchangeFormatVersion = "1.10";
		ElsIf SettingsMode = "UpuppExchange" Then
			ExchangeFormatVersion = "1.8";
		EndIf;
	
		If SettingsMode <> "ExchangeUP2ZUP3" Then
			AccountingSections.Load(ExchangePlans.DataSynchronizationViaUniversalFormat.GetAccountingSections(
				False, SettingsMode));
		EndIf;
	
	EndIf;
	
EndProcedure

#EndRegion

#EndIf