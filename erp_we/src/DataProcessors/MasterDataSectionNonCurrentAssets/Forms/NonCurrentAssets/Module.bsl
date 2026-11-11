
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	NonCurrentAssetsLocalization.WhenCreatingOnServer_PanelOfCatalogsNonCurrentAssets(ThisForm);
	
	ManagingElements();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_ConstantsSet" Then
		// The program settings in the administration panels have been changed
		ManagingElements();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OpenPerformanceIndicators(Command)
	
	OpenForm("Catalog.RunningTimeValues.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenFinancialAccountingGroupsForNonCurrentAssets(Command)
	
	OpenForm("Catalog.NonCurrentAssetsAccountingGroups.ListForm");
	
EndProcedure

&AtClient
Procedure TheOpenEventToOS(Command)
	
	OpenForm("Catalog.FixedAssetsEvents.ListForm");
	
EndProcedure

&AtClient
Procedure OpenFAGroups(Command)
	OpenForm("Catalog.FixedAssetsGroupsFinancialAccounting.ListForm");
	Return; // There is an empty handler in the SC.
	
EndProcedure

&AtClient
Procedure OpenIAGroups(Command)
	
	OpenForm("Catalog.IntangibleAssetsGroups.ListForm");
	
EndProcedure

&AtClient
Procedure OpenEGDS(Command)
	OpenForm("Catalog.CashGeneratingUnits.Form.ListForm");
EndProcedure

&AtClient
Procedure OpenTheFeatureClassesOfOperation(Command)
	OpenForm("Catalog.MaintenanceSchemes.ListForm", , ThisForm);
	Return; // There is an empty handler in the SC.

EndProcedure

&AtClient
Procedure OpenGeneralTypesOfRepairs(Command)
	OpenForm("Catalog.GeneralRMTypes.ListForm", , ThisForm);
	Return; // There is an empty handler in the SC.

EndProcedure

&AtClient
Procedure OpenTypesOfDefects(Command)
	OpenForm("Catalog.FailureTypes.ListForm", , ThisForm);
	Return; // There is an empty handler in the SC.
	
EndProcedure

&AtClient
Procedure OpenRepairOfTheEvent(Command)
	OpenForm("Catalog.RMActivities.ListForm", , ThisForm);
	Return; // There is an empty handler in the SC.

EndProcedure

&AtClient
Procedure OpenOperationCategories(Command)
		
	OpenForm("Catalog.OperationCategories.ListForm",, ThisObject);
	
EndProcedure

&AtClient
Procedure OpenWaysToReflectExpenses(Command)

	OpenForm("Catalog.WaysToReflectExpenses.ListForm",, ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_OnExecuteCommand(Command)

	NonCurrentAssetsClientLocalization.WhenExecuting_CommandNonCurrentAssetsReferencePanel(Command, ThisObject);

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ManagingElements()

	ThereAreRightsToRepairs = False;
	ThereAreRightsToRepairs =
		AccessRight("View", Metadata.Catalogs.MaintenanceSchemes)
		Or AccessRight("View", Metadata.Catalogs.GeneralRMTypes)
		Or AccessRight("View", Metadata.Catalogs.RMActivities)
		Or AccessRight("View", Metadata.Catalogs.FailureTypes);
	Items.OpenPerformanceIndicators.Visible = 
		AccessRight("View", Metadata.Catalogs.RunningTimeValues)
		And Not ThereAreRightsToRepairs;
	
	Items.OpenFinancialAccountingGroupsForNonCurrentAssets.Visible = 
		AccessRight("View", Metadata.Catalogs.NonCurrentAssetsAccountingGroups);

	Items.TheOpenEventToOS.Visible = 
		AccessRight("View", Metadata.Catalogs.FixedAssetsEvents);
	
	Items.OpenWaysToReflectExpenses.Visible = 
		AccessRight("View", Metadata.Catalogs.WaysToReflectExpenses);
	Items.OpenTheFeatureClassesOfOperation.Visible = 
		AccessRight("View", Metadata.Catalogs.MaintenanceSchemes);
	
	Items.OpenGeneralTypesOfRepairs.Visible = 
		AccessRight("View", Metadata.Catalogs.GeneralRMTypes);
	
	Items.OpenRepairOfTheEvent.Visible = 
		AccessRight("View", Metadata.Catalogs.RMActivities);
	
	Items.OpenTypesOfDefects.Visible =
		AccessRight("View", Metadata.Catalogs.FailureTypes);
	
	Items.OpenIndicatorsOfOperatingTimeRepairs.Visible = 
		AccessRight("View", Metadata.Catalogs.RunningTimeValues)
		And ThereAreRightsToRepairs;

	Items.OpenFAGroups.Visible = AccessRight("View", Metadata.Catalogs.FixedAssetsGroupsFinancialAccounting);
	Items.OpenIAGroups.Visible = AccessRight("View", Metadata.Catalogs.IntangibleAssetsGroups);
	NonCurrentAssetsLocalization.ItemManagement_CatalogPanelNonCurrentAssets(ThisForm);
	
EndProcedure

#EndRegion
