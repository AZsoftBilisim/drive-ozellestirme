////////////////////////////////////////////////////////////////////////////////
// Contains form events called on the client
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Executes the redefined command
//
// Parameters:
//  Form	- ClientApplicationForm - the form where the team is located
//  Command	- FormCommand - form command
//  AdditionalParameters	- Structure - advanced setting.
//
Procedure ExecuteOverridableCommand(Form, Command, AdditionalParameters = Undefined) Export
	DocumentVerificationClient.ExecuteCommandToChangeDocumentVerificationStatus(Form, Command);
	GLAccountSettingsClient.ExecuteOverridableCommand(Form, Command);
	ConfigurationModificationClientOverridable.ExecuteOverridableCommand(Form, Command, AdditionalParameters);
	
	FormEventsClientLocalization.ExecuteOverridableCommand(Form, Command, AdditionalParameters);
	
EndProcedure

// A procedure called from the form event handler of the same name.
//
// Parameters:
//  Form					- ClientApplicationForm - the form from which the procedure is called from the event handler.
//  EventName				- String - the ID of the message by the receiving form (see the Notify method)
//	Parameter				- Arbitrary - message parameter (see Notify method)
//	Source				- Arbitrary - event source (see Notify method)
//  AdditionalParameters	- Structure - advanced setting.
//
Procedure NotificationProcessing(Form, EventName, Parameter, Source, AdditionalParameters = Undefined) Export
	DocumentVerificationClient.NotificationProcessing(Form, EventName, Parameter, Source);
	FormEventsClientLocalization.NotificationProcessing(Form, EventName, Parameter, Source, AdditionalParameters);
	
	Return;
	
EndProcedure

// A procedure called from the form event handler of the same name.
//
// Parameters:
//  Form					- ClientApplicationForm - the form from which the procedure is called from the event handler.
//  Cancel					- Boolean - flag for refusing to write a document
//	WriteParameters			- Structure - recording parameters (see the event before recording) .
//
Procedure BeforeWrite(Form, Cancel, WriteParameters) Export
	DocumentVerificationClient.BeforeWrite(Form, Cancel, WriteParameters);
EndProcedure

// An overridable procedure called from the form event handler of the same name.
//
// Parameters:
// 	Form - ClientApplicationForm - the form from which the procedure is called from the event handler.
//	WriteParameters - Structure - recording parameters (see Post-recording event) .
//
Procedure AfterWrite(Form, WriteParameters) Export
	
	FormEventsClientLocalization.AfterWrite(Form, WriteParameters);
	ConfigurationModificationClientOverridable.AfterWrite(Form, WriteParameters);
	
EndProcedure

// An overridable procedure called from the form event handler of the same name.
//
// Parameters:
// 	Form - ClientApplicationForm - the form from which the procedure is called from the event handler.
//  Cancel	- Boolean - a sign of refusal to open the form.
//
Procedure OnOpen(Form, Cancel) Export
	
	FormEventsClientLocalization.OnOpen(Form, Cancel);
	
EndProcedure

// An overridable procedure called from the form event handler of the same name.
//
// Parameters:
// 	Form - ClientApplicationForm - the form from which the procedure is called from the event handler.
//	FormattedStringURL - String - navigation link string
//	StandardProcessing - Boolean - a sign of the standard event processing
//
Procedure URLProcessing(Form, FormattedStringURL, StandardProcessing) Export
	
	If Not StandardProcessing Then
		Return;
	EndIf;
	GLAccountSettingsClient.URLProcessing(Form, FormattedStringURL, StandardProcessing);
	FormEventsClientLocalization.URLProcessing(Form, FormattedStringURL, StandardProcessing);
	
EndProcedure

#Region FormElementEvents

// An overridable procedure called from the element's event handler of the same name.
//
// Parameters:
//   Form                   - ClientApplicationForm - the form from which the procedure is called.
//   Item                 - Arbitrary     - element-source of the "when changed" event.
//   AdditionalParameters - Structure        - values of additional parameters that affect processing.
//
Procedure WhenChangingElement(Form, Item, AdditionalParameters = Undefined) Export
	
	FormEventsClientLocalization.WhenChangingElement(Form, Item, AdditionalParameters);
	
EndProcedure

// An overridable procedure called from the element's event handler of the same name.
//
Procedure WhenSelectingItem(Form, Item, RowSelected, Field, StandardProcessing, AdditionalParameters = Undefined) Export
	
	FormEventsClientLocalization.WhenSelectingItem(Form, Item, RowSelected, Field, StandardProcessing, AdditionalParameters);
	
EndProcedure

// An overridable procedure called from the element's event handler of the same name.
//
Procedure OnActivateCell(Form, Item, AdditionalParameters = Undefined) Export
	
	FormEventsClientLocalization.OnActivateCell(Form, Item, AdditionalParameters);
	
EndProcedure

// An overridable procedure called from the element's event handler of the same name.
//
Procedure OnActivateRow(Form, Item, AdditionalParameters = Undefined) Export
	
	FormEventsClientLocalization.OnActivateRow(Form, Item, AdditionalParameters);
	
EndProcedure

// An overridable procedure called from the element's event handler of the same name.
//
Procedure OnStartEdit(Form, Item, NewRow, Copy, AdditionalParameters = Undefined) Export
	
	FormEventsClientLocalization.OnStartEdit(Form, Item, NewRow, Copy, AdditionalParameters);
	
EndProcedure

// An overridable procedure called from the element's event handler of the same name.
//
Procedure StartSelectingItem(Form, Item, ChoiceData, StandardProcessing) Export
	
	FormEventsClientLocalization.StartSelectingItem(Form, Item, ChoiceData, StandardProcessing);
	
EndProcedure
	
#EndRegion

#EndRegion
