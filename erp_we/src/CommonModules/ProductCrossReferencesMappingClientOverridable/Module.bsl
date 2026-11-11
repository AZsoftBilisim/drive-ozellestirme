////////////////////////////////////////////////////////////////////////////////////////
// Comparison of the nomenclature of the counteragents of the client is definable: 
// a mechanism for comparing the nomenclature of counterparties with the nomenclature of the information base.
//
////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region WorkWithProcessingComparisonOfBADNomenclature

// Allows you to override the default settings for item mapping
//
// Parameters:
//  Mapping_Settings - Structure
// 
Procedure WhenDefiningItemMappingSettings(Mapping_Settings) Export
	
EndProcedure

#EndRegion

#Region OverridableCommands_CounterpartyProducts

// Plug-in performs the override command for the forms of the guide Nomenclaturachimica.
//
// Parameters:
//  Form   - ClientApplicationForm - the form in which the team is located.
//  Command - FormCommand               - form command.
//
Procedure Attachable_ExecuteOverridableCommand_CounterpartyNomenclatures(Form, Command) Export
	PartnersProductsClient.Attachable_ExecuteOverridableCommand_CounterpartyNomenclatures(Form, Command);
EndProcedure

// Plug-in performs the override command for the integration of the forms of the guide Nomenclaturachimica.
//
// Parameters:
//  Form    - ClientApplicationForm                 - the form in which the team is located.
//  Command  - FormCommand                               - form command.
//  Source - FormDataStructure, FormDataCollection - data that specifies the command parameter.
//
Procedure Attachable_ExecuteIntegrationCommand_CounterpartyNomenclatures(Form, Command, Source) Export
	PartnersProductsClient.Attachable_ExecuteIntegrationCommand_CounterpartyNomenclatures(
		Command,
		Form,
		Source);
EndProcedure

#Region FilesOperations

// See FilesOperationsClient.AttachmentsControlCommand
Procedure Attachable_CommandOfAttachedFilesPanel_CounterpartyNomenclatures(Form, Command) Export
	PartnersProductsClient.Attachable_CommandOfAttachedFilesPanel_CounterpartyNomenclatures(
		Form, Command);
EndProcedure

// See FilesOperationsClient.PreviewFieldCheckDragging
Procedure Attachable_PreviewFieldCheckDragging_CounterpartyNomenclatures(Form,
																						Item,
																						DragParameters,
																						StandardProcessing) Export
	PartnersProductsClient.Attachable_PreviewFieldCheckDragging_CounterpartyNomenclatures(
		Form, Item, DragParameters, StandardProcessing);
EndProcedure

// See FilesOperationsClient.PreviewFieldDrag
Procedure Attachable_PreviewFieldDrag_CounterpartyNomenclatures(Form, Item, DragParameters, StandardProcessing) Export
	PartnersProductsClient.Attachable_PreviewFieldDrag_CounterpartyNomenclatures(
		Form, Item, DragParameters, StandardProcessing);
EndProcedure

// See FilesOperationsClient.PreviewFieldClick
Procedure Attachable_PreviewFieldClick_CounterpartyNomenclatures(Form, Item, StandardProcessing) Export
	PartnersProductsClient.Attachable_PreviewFieldClick_CounterpartyNomenclatures(
		Form, Item, StandardProcessing);
EndProcedure

#EndRegion

#EndRegion

#Region EventHandlers_CounterpartyProductForms

// Handler for the "Post-recording" event of the form element of the Nomenclaturecontagents directory.
//
// Parameters:
//  Form           - ClientApplicationForm - the form from which the procedure is called from the event handler.
//  WriteParameters - Structure                  - contains the recording settings.
//
Procedure AfterWriting_FormOfCounterpartyProductItem(Form, WriteParameters) Export
	PartnersProductsClient.AfterWriting_FormOfCounterpartyProductItem(Form, WriteParameters);
EndProcedure

// Handler for the "Opening" event of the form element of the Nomenclaturecontagents directory.
//
// Parameters:
//  Form - ClientApplicationForm - the form from which the procedure is called from the event handler.
//  Cancel - Boolean                     - indicates that the form was not created.
//
Procedure WhenOpening_FormOfCounterpartyProductItem(Form, Cancel) Export
	PartnersProductsClient.WhenOpening_FormOfCounterpartyProductItem(Form, Cancel);
EndProcedure

// Handler of the event "Message Processing" of the form element of the Nomenclature of Counteragents directory.
// 
// Parameters:
//  Form      - ClientApplicationForm - the form from which the procedure is called from the event handler.
//  EventName - String                     - the name of the notification processing event.
//  Parameter   - Arbitrary               - parameter passed in the message
//  Source   - Arbitrary               - the source of the event passed to the message.
//
Procedure NotificationProcessing_FormOfCounterpartyProductItem(Form, EventName, Parameter, Source) Export
	PartnersProductsClient.NotificationProcessing_FormOfCounterpartyProductItem(Form, EventName, Parameter, Source);
EndProcedure

#EndRegion

#Region WorkingWithFormsOfInformationSecurityObjects


// Opens the form for selecting the item item of the information base.
//
// Parameters:
//  Parameters - Structure - context of opening the form:
//   * ItemTypeRestriction - Undefined,TypeDescription
//   * AdditionalSearchParameters_ - Arbitrary - the context obtained from the code being overridden when calling 
//  Owner - ClientApplicationForm - owner of the form.
//  Uniqueness - Arbitrary - the key to the uniqueness of the form.
//
// Example:
//  Open the form ("Directory.Nomenclature.Formselection", Parameters, Owner, Uniqueness);
//
Procedure OpenProductSelectionForm(Val Parameters, Val Owner, Val Uniqueness) Export
	PartnersProductsClient.OpenProductSelectionForm(Parameters, Owner, Uniqueness);
EndProcedure

#EndRegion

#EndRegion
