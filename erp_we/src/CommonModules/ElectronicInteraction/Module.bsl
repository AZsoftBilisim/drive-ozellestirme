
////////////////////////////////////////////////////////////////////////////////
// Electronic interaction: a common mechanism for the exchange of electronic documents.
////////////////////////////////////////////////////////////////////////////////
//

#Region Public


#Region InterfaceImplementation


// See AccessManagementOverridable.OnFillListsWithAccessRestriction
Procedure OnFillListsWithAccessRestriction(Lists) Export
	
	
	
	
	
	
	
	
	
	
	
	
EndProcedure

// See AccessManagementOverridable.OnFillMetadataObjectsAccessRestrictionKinds
Procedure OnFillMetadataObjectsAccessRestrictionKinds(LongDesc) Export

	
	
	
	
	
	
	
	
	
	
	
	// GISEPDExchange
	If Common.SubsystemExists("ElectronicInteraction.GISEPDExchange") Then
		
		SubsystemModule = Common.CommonModule("GISEPDExchange");
		SubsystemModule.OnFillMetadataObjectsAccessRestrictionKinds(LongDesc);
		
	EndIf;
	// End ElectronicInteraction.GISEPDExchange
	
EndProcedure

// See CommonOverridable.OnAddServerNotifications
//
Procedure OnAddServerNotifications(Notifications) Export
	If Common.SubsystemExists("ElectronicInteraction.ExchangeWithCounterparties") Then
		SubsystemModule = Common.CommonModule("ExchangeWithCounterpartiesIntegrationEvents");
		SubsystemModule.OnAddServerNotifications(Notifications);
	EndIf;
	
	If Common.SubsystemExists("ElectronicInteraction.EDIWithBanks") Then
		SubsystemModule = Common.CommonModule("EDIWithBanksIntegrationEvents");
		SubsystemModule.OnAddServerNotifications(Notifications);
	EndIf;
	
EndProcedure

// See CommonOverridable.OnAddClientParameters
Procedure OnAddClientParameters(Parameters) Export
	
	If Common.SubsystemExists("ElectronicInteraction.ExchangeWithCounterparties.ConnectingTaxcom") Then
		SubsystemModule = Common.CommonModule("ConnectingTaxcomLED");
		SubsystemModule.OnAddClientParameters(Parameters);
	EndIf;
	
EndProcedure

// See CommonOverridable.BeforeStartApplication
//
Procedure BeforeStartApplication() Export
	If Common.SubsystemExists("ElectronicInteraction.ExchangeWithCounterparties") Then
		SubsystemModule = Common.CommonModule("ExchangeWithCounterpartiesIntegrationEvents");
		SubsystemModule.BeforeStartApplication();
	EndIf;
EndProcedure

// See PrintManagementOverridable.OnDefinePrintSettings
Procedure OnDefinePrintSettings(Settings) Export
	
EndProcedure

// See ExternalResourcesOperationsLockOverridable.WhenYouAreForbiddenToWorkWithExternalResources
Procedure WhenYouAreForbiddenToWorkWithExternalResources() Export
	
	
EndProcedure

#EndRegion

#Region ObsoleteProceduresAndFunctions

// See PrintManagementOverridable.OnDefineObjectsWithPrintCommands
Procedure OnDefineObjectsWithPrintCommands(ListOfObjects) Export
	
	
	
EndProcedure

#EndRegion

#EndRegion
