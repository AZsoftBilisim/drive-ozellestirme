
#Region Public

// This function returns the settings of forms that can be opened when the system starts working.
//
//	Parameters:
//		Form - EnumRef.FormsOpenedOnApplicationStart - form for which you want to configure
//	Returns:
//		Structure - a structure with the following keys:
//			*NameOfFormToRun - String - full name of the form to open (to pass to the OpenForm function)
//			*Role - String - name of the role that gives the user the right to run the form
//			*RequiredSettings - Boolean - the settings must be set for the form to open
//          *SettingsFormName - String - if you need Settings = TRUE, then this parameter specifies the full name
//										of the settings editing form (to pass to the Open Form function)
//          *LaunchParameter - String - a startup parameter that will be checked for when the system starts,
//										the form will be opened if the startup parameter is passed or the form is configured
//										to be opened by default (i.e. without checking the startup parameter).
//
Function FormSettings(Form) Export
	
	ParametersStructure = DescriptionOfFormSettings();
	
	If Form = PredefinedValue("Enum.FormsOpenedOnApplicationStart.SalesWizard") Then
		
		ParametersStructure.Insert("NameOfFormToRun", "DataProcessor.SalesWizard.Form.Form");
		ParametersStructure.Insert("Role",                "UseSalesWizard");
		ParametersStructure.Insert("LaunchParameter",     "SaleAssistant");
		
	ElsIf Form = PredefinedValue("Enum.FormsOpenedOnApplicationStart.WorkplaceOfWarehouseWorker") Then
		
		ParametersStructure.Insert("NameOfFormToRun", "DataProcessor.WorkplaceOfWarehouseWorker.Form.FormOfWorkplace");
		ParametersStructure.Insert("Role",                "UseWorkplaceOfWarehouseWorker");
		ParametersStructure.Insert("LaunchParameter",     "WarehouseMobileWorkplace");
		
		ParametersStructure.Insert("RequiredSettings", True);
		ParametersStructure.Insert("SettingsFormName",    "DataProcessor.WorkplaceOfWarehouseWorker.Form.ParameterSettings");
		
	ElsIf Form = PredefinedValue("Enum.FormsOpenedOnApplicationStart.CashRegisterReceipt") Then
		
		ParametersStructure.Insert("NameOfFormToRun", "Document.CashRegisterReceipt.Form.CWPDocumentForm");
		ParametersStructure.Insert("Role",                "AddEditCashRegisterReceipts");
		ParametersStructure.Insert("LaunchParameter",     "CashRegisterReceipt");
		
	ElsIf Form = PredefinedValue("Enum.FormsOpenedOnApplicationStart.WorkplaceOfDeliveryOfficer") Then
		
		ParametersStructure.Insert("NameOfFormToRun", "DataProcessor.WorkplaceOfDeliveryOfficer.Form.Form");
		ParametersStructure.Insert("Role",                "UseDeliveryWorkplace");
		ParametersStructure.Insert("LaunchParameter",     "DeliveryWorkplace");
	ElsIf Form = PredefinedValue("Enum.FormsOpenedOnApplicationStart.MobileWorkplaceExecutionOfOperations") Then
		
		ParametersStructure.Insert("NameOfFormToRun", "DataProcessor.ExecutionOfOperations2_2.Form.MobileApplicationDesktop");
		ParametersStructure.Insert("Role",                "UseOfWorkplaceExecutionOfOperations");
		ParametersStructure.Insert("LaunchParameter",     "ShopFloorManagement");
		
		ParametersStructure.Insert("RequiredSettings", True);
		ParametersStructure.Insert("SettingsFormName",    "DataProcessor.ExecutionOfOperations2_2.Form.WorkplaceParametersConfiguration");
	ElsIf Form = PredefinedValue("Enum.FormsOpenedOnApplicationStart.MobileWorkspaceForAssemblyAndCourierDelivery") Then
		
		ParametersStructure.Insert("NameOfFormToRun", "DataProcessor.MobileWorkspaceForAssemblyAndCourierDelivery.Form.Desktop");
		ParametersStructure.Insert("Role",                "UseOfAssemblyAndCourierDeliveryWorkspace");
		ParametersStructure.Insert("LaunchParameter",     "AssemblyAndCourierDeliveryWorkplace");
		
	ElsIf Form = PredefinedValue("Enum.FormsOpenedOnApplicationStart.MobileWarehouseKeeperWorkspace") Then
		
		ParametersStructure.Insert("NameOfFormToRun", "DataProcessor.MobileWarehouseKeeperWorkspace.Form.Desktop");
		ParametersStructure.Insert("Role",                "UseWarehouseKeeperWorkplace");
		ParametersStructure.Insert("LaunchParameter",     "WarehouseWorkplace");
		
	ElsIf Form = PredefinedValue("Enum.FormsOpenedOnApplicationStart.PerformanceDashboard") Then
		
		ParametersStructure.Insert("NameOfFormToRun", "Report.PerformanceDashboard.Form.PerformanceDashboardForm");
		ParametersStructure.Insert("Role",                "TargetValuesSection");
		ParametersStructure.Insert("LaunchParameter",     "PerformanceDashboard");
		
	EndIf;
	
	Return ParametersStructure;
	
EndFunction

#EndRegion

#Region Private

Function DescriptionOfFormSettings() Export
	
	FormSettings = New Structure;
	
	FormSettings.Insert("NameOfFormToRun", 	"");
	FormSettings.Insert("Role", 				"FullAccess");
	FormSettings.Insert("RequiredSettings", 	False);
	FormSettings.Insert("SettingsFormName", 	"");
	FormSettings.Insert("LaunchParameter", 		"");
	FormSettings.Insert("OpenModally", 	False);
	FormSettings.Insert("SettingsAreSet", False);
	FormSettings.Insert("Parameters", 			New Structure);
	FormSettings.Insert("OpenByDefault", False);
	
	Return FormSettings;
	
EndFunction

#EndRegion
