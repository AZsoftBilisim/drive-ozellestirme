
#Region Public

// Updates Statuses and information about sales of goods
// 
// Parameters:
//  Form - ClientApplicationForm - the form from which the procedure is called.
Procedure UpdateStatusesAndAllowedItems(Form) Export
	
	
EndProcedure

// Updates Statuses and information about sales permission for goods in the current line
// 
// Parameters:
//  Form - ClientApplicationForm - the form from which the procedure is called.
//  ProductLineData - FormDataCollectionItem - 
Procedure UpdateStatusAndResolutionOfProductInCurrentLine(Form, ProductLineData) Export
	
	
EndProcedure

#Region FiscalTransactions

// Launches the mechanism for checking the marking codes by means of KKT
// 
// Parameters:
//  ReceiptPositions - Array - Receipt positions
//  OwnerForm - ClientApplicationForm - Owner form
//  IgnoreButtonTitle - String, Undefined - Ignore button title
//  CallbackOnCompletion - CallbackDescription - Notification of completion
//  ViewForm - ClientApplicationForm, Undefined - View Form
Procedure CheckMarkingCodeByMeansOfKKT(ReceiptPositions, OwnerForm, IgnoreButtonTitle = Undefined, CallbackOnCompletion, ViewForm = Undefined) Export
	
	
EndProcedure

// Determines whether verification of marking codes by means of KKT is required.
// 
// Parameters:
//  ParametersOfReceiptFiscalizationOperation - Structure - Parameters of the receipt fiscalization operation
// 
// Returns:
//  Boolean - True - verification of marking codes by means of KKT is required
Function VerificationOfMarkingCodesByMeansOfKKTIsRequired(ParametersOfReceiptFiscalizationOperation) Export
	
	Return RetailSalesClientServerLocalization.VerificationOfMarkingCodesByMeansOfKKTIsRequired(ParametersOfReceiptFiscalizationOperation);
	
EndFunction

#EndRegion

#Region PaymentOfSBP


#EndRegion


#Region ConnectedHardwareLibrary

// Opens forms for BPO of operations logs
//
// Parameters:
//  Form - ClientApplicationForm -
//  Command - FormCommand -
//
Procedure OpenLogsOfOperationsOfBPO(Form, Command) Export
	
	CommandExecuteParameters = New Structure;
	CommandExecuteParameters.Insert("Source", Form);
	CommandExecuteParameters.Insert("Uniqueness", Form.UUID);
	CommandExecuteParameters.Insert("Window",);
	
	If Command = Form.Commands.OpenPaymentTransactions Then
		EquipmentManagerClient.OpenPaymentTransactions(Undefined, CommandExecuteParameters);
	ElsIf Command = Form.Commands.OpenFiscalTransactions Then
		EquipmentManagerClient.OpenFiscalTransactions(Undefined, CommandExecuteParameters);
	ElsIf Command = Form.Commands.OpenHardwareOperations Then
		ModuleLoggingOfOperationsOfBPOClient = CommonCELClient.CommonModule("LoggingOfCELOperationsClient");
		ModuleLoggingOfOperationsOfBPOClient.OpenHardwareOperations(Undefined, CommandExecuteParameters);
	EndIf;
	
EndProcedure

// Opens forms for BPO of operations logs
//
// Parameters:
//  Form - ClientApplicationForm -
//  Command - FormCommand -
//
Procedure OpenScheduleSetupFormForRoutineTask(Form, Command) Export

	FormParameters = New Structure;
	FormParameters.Insert("NameOfRoutineTaskMetadata", "");
	FormParameters.Insert("MetadataForCheckingAccessRightsForChanges", New ValueList);
	
	If Command = Form.Commands.SetUpScheduleForClearingPaymentTransactions 
		And Form.DescriptionOfCustomScheduledTasks.Property("ClearHistoryOfPaymentTransactions") Then
		FillPropertyValues(FormParameters, Form.DescriptionOfCustomScheduledTasks.ClearHistoryOfPaymentTransactions);
	ElsIf Command = Form.Commands.SetUpScheduleForClearingFiscalTransactions 
		And Form.DescriptionOfCustomScheduledTasks.Property("ClearHistoryOfFiscalTransactions") Then
		FillPropertyValues(FormParameters, Form.DescriptionOfCustomScheduledTasks.ClearHistoryOfFiscalTransactions);
	ElsIf Command = Form.Commands.SetEquipmentOperationsCleanupSchedule 
		And Form.DescriptionOfCustomScheduledTasks.Property("ClearHistoryOfOperationsWithPeripherals") Then
		FillPropertyValues(FormParameters, Form.DescriptionOfCustomScheduledTasks.ClearHistoryOfOperationsWithPeripherals);
	ElsIf Command = Form.Commands.SetUpScheduleForDeletingUnusedDataOnInventoryBelongingToRetailOutlets 
		And Form.DescriptionOfCustomScheduledTasks.Property("DeleteUnusedInventoryAffiliationDataOfRetailOutlets") Then
		FillPropertyValues(FormParameters, Form.DescriptionOfCustomScheduledTasks.DeleteUnusedInventoryAffiliationDataOfRetailOutlets);
	EndIf;
	If Not IsBlankString(FormParameters.NameOfRoutineTaskMetadata) Then
		OpenForm("DataProcessor.TMAdministrationPanel.Form.ScheduledJobSettingManagement", FormParameters, Form.UUID,,);	
	EndIf;
EndProcedure

#Region GetAddIns

// Opens forms for BPO of operations logs
//
// Parameters:
//  Form - ClientApplicationForm -
//  Command - Form Commands -
//
Procedure SetUpScheduleForUpdatingExternalComponents(Form) Export

	
EndProcedure

// Handler for changing the update option for external components.
// 
// Parameters:
//  Form - ClientApplicationForm - Form
//  Item - FormField - Item
Procedure AddInsUpdateOptionOnChange(Form, Item) Export
	
	
EndProcedure

// Open the BIP form for updating external components of the BPO
Procedure AddInsUpdate() Export
	
	
EndProcedure

// Opens the form for the list of loaded external components.
// 
// Parameters:
//  Command - FormCommand - Command
Procedure OpenAddIns(Command) Export
	
	
EndProcedure

// File change handler for external components
// 
// Parameters:
//  Form - ClientApplicationForm - Form
//  Item - FormField - Item
Procedure AddInsFileOnChange(Form, Item) Export
	
	
EndProcedure

// Handler for the start of the selection of the external components file.
// 
// Parameters:
//  Form - ClientApplicationForm - Form
//  Item - FormField - Item
//  ChoiceData - ValueList of String - Selection data
//  StandardProcessing - Boolean - Standard treatment
Procedure AddInsFileStartChoice(Form, Item, ChoiceData, StandardProcessing) Export
	
	
EndProcedure

// Internet connection support localization.
// 
// Parameters:
//  Form - ClientApplicationForm - Form
//  Item - FormField - Item
//  FormattedStringURL - String - Navigation link of the formatted string
//  StandardProcessing - Boolean - Standard treatment
Procedure ConnectingToInternetSupport(Form, Item, FormattedStringURL, StandardProcessing) Export
	
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion
