#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Adds IP objects to the queue for updating printed forms in related objects TO.
//
// Parameters:
//   Object - DefinedType.IntegrationWith1CWorkflowAllLinksOverridable - reference to the IP object.
//   Rule - CatalogRef.RulesForIntegrationWith1CDocumentManagement
//           - CatalogRef.RulesForIntegrationWith1CDocumentManagement3 - the integration rule
//     corresponding to the IP object.
//
Procedure Add(Object, Rule) Export
	
	FileUpdatesAreSupported =
		IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.1.9.1.CORP");
		
	If Not FileUpdatesAreSupported Then
		Return;
	EndIf;
	
	Manager = InformationRegisters.PreparationForUpdatingPrintedForms.CreateRecordManager();
	
	Manager.Object = Object;
	Manager.Rule = Rule;
	
	Manager.Write();
	
EndProcedure

#EndRegion

#EndIf