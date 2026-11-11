
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
	Return
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

#Region FormHeaderItemsEventHandlers

Procedure AtEndOfChangeOfProps(TagName, Form, ProcessingParameters) Export
	
	If TypeOf(TagName) = Type("Array") Then
		For Each CurItem In TagName Do
			AtEndOfChangeOfProps(CurItem, Form, ProcessingParameters);
		EndDo;
	EndIf;
	
	
EndProcedure

Procedure ExecuteLocalizationCommand(Form, CommandName, ProcessingParameters) Export
	
	If TypeOf(CommandName) = Type("Array") Then
		For Each CurItem In CommandName Do
			ExecuteLocalizationCommand(Form, CurItem, ProcessingParameters);
		EndDo;
	EndIf;
EndProcedure

#EndRegion

#Region ObjectModuleEventHandlers

// Handler for the event processing the check-in of an object in the Catalog Of AGENT AGREEMENTSCONTRAGENTS.
// See the description of the platform method for processing the check-in.
// 
// Parameters:
//   Cancel - Boolean
//   CheckedAttributes - Array of String
//   NotCheckedAttributeArray - Array of String
//   CatalogObject - CatalogObject.CounterpartyContracts
//
Procedure FillCheckProcessing(Cancel, CheckedAttributes, NotCheckedAttributeArray, CatalogObject) Export
EndProcedure

//  see the description of the platform method before recording
// Event handler before recording the object of the directory of contractors
//
// Parameters:
// Cancel - Boolean
// CatalogObject - CatalogObject
//
Procedure BeforeWrite(Cancel, CatalogObject) Export
EndProcedure

// Handler for the event when copying an object from the Catalog of AGENT agreementsreferencesexternal links
//  see the description of the platform method for copying
//
// Parameters:
// CopiedObject - CatalogObject
// CatalogObject - CatalogObject
Procedure OnCopy(CopiedObject, CatalogObject) Export
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

#EndRegion

#Region Private

#Region EventHandlersForFormHeaderElements_Service
#EndRegion

#Region OtherServiceProcedures

#EndRegion

#EndRegion
