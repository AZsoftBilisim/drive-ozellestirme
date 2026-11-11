
#Region Public

#Region AttachableCommands
// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	
EndProcedure

// Adds a command of creation of the document "expense report".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
Procedure AddGenerateCommand(GenerationCommands) Export
	
	
EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

#Region ObjectModuleEventHandlers

// Event handler for processing Checkfill of the directory object Contracts
//
// Parameters:
//  Cancel - Boolean - see the description of the platform method for processing the check-in
//  CheckedAttributes - Array - see the description of the platform method for processing the check-in
//  NotCheckedAttributeArray - Array - array of paths to details that will not be checked for filling in. 
//  CatalogObject - CatalogObject.LoanAndDepositContracts
//
Procedure FillCheckProcessing(Cancel, CheckedAttributes, NotCheckedAttributeArray, CatalogObject) Export
EndProcedure

// Event handler for handling the Announcement of the form of the directory element Contracts
//
// Parameters:
//  Cancel - Boolean - see the description of the platform method before recording
//  CatalogObject - CatalogObject.LoanAndDepositContracts - A recordable object
//
Procedure BeforeWrite(Cancel, CatalogObject) Export
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

Procedure AtEndOfChangeOfProps(TagName, Form, ProcessingParameters) Export
	If TypeOf(TagName) = Type("Array") Then
		For Each CurItem In TagName Do
			AtEndOfChangeOfProps(CurItem, Form, ProcessingParameters);
		EndDo;
	EndIf;
EndProcedure

#EndRegion

#Region FormEventHandlers

// Event handler for adding a form to The server of an element in the counterparty Contracts directory.
//
// Parameters:
//  Form                - ClientApplicationForm - the form for which the handler is executed.
//  Cancel                - Boolean - indicates that the form was not created.
//  StandardProcessing - Boolean - indicates whether standard (system) event processing is performed.
//
Procedure WhenCreatingElementFormOnServer(Form, Cancel, StandardProcessing) Export
	SystemSettingsLocalization.SetVisibilityOfLocalizationElements(Form);
EndProcedure

// Event handler for processing the Fill check in the server
// 
// Parameters:
// 	Cancel - Boolean - a sign of failure.
// 	CheckedAttributes - Array - array of paths to the details being checked.
// 	Form - ClientApplicationForm - the form handler.
//
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes, Form) Export
EndProcedure

// Called when creating / reading a form on the server
// 
// Parameters:
// 	Form - ClientApplicationForm - handler form
//
Procedure OnReadCreateAtServer(Form) Export
EndProcedure

// Event handler for the post-write event In the server of the form of the directory element Agreementcontragents
//
// Parameters:
//  CurrentObject   - CatalogObject - the object to be read.
//  WriteParameters - Structure - structure containing the record parameters.
//  Form           - ClientApplicationForm - the form for which the handler is executed.
//
Procedure AfterWriteAtServer(CurrentObject, WriteParameters, Form) Export
EndProcedure

// Event handler for the pre-write event in the Server of the form of the directory element Agreementcontragents
//
// Parameters:
//  Cancel           - Boolean - a sign of failure.
//  CurrentObject   - CatalogObject - the object to be read.
//  WriteParameters - Structure - structure containing the record parameters.
//  Form           - ClientApplicationForm - the form for which the handler is executed.
//
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters, Form) Export
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

Procedure ExecuteLocalizationCommand(Form, CommandName, ProcessingParameters) Export
	
	If TypeOf(CommandName) = Type("Array") Then
		For Each CurItem In CommandName Do
			ExecuteLocalizationCommand(Form, CurItem, ProcessingParameters);
		EndDo;
	EndIf;
EndProcedure

#EndRegion

#Region ConditionalAppearance

// Sets the conditional form design
// 
// Parameters:
// 	Form - ClientApplicationForm - handler form
//
Procedure SetConditionalAppearance(Form) Export
	ConditionalAppearance = Form.ConditionalAppearance;
	Items =  Form.Items;
EndProcedure

#EndRegion

#Region OtherUtilityMethods

Procedure AddDataToHeaderOfDDSDocument(HeaderData_, LoanDepositContract) Export
	
EndProcedure

// Updated settings
// 
// Parameters:
//     Settings - ValueTable - table with columns:
//         * Fields - Array of String - Fields that the setting applies to.
//         * Condition - DataCompositionFilter - Determines whether the setting is valid.
//         * Properties - Structure - Field properties.
//
Procedure AddFormFieldSettings(Settings) Export
EndProcedure


#EndRegion

#EndRegion

#Region Private

#Region EventHandlersForFormHeaderElements_Service
#EndRegion

#EndRegion