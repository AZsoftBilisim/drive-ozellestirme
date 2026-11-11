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
Procedure ExecuteOverridableCommand(Form, Command, AdditionalParameters) Export
	
	Return;
	
EndProcedure

// A procedure called from the form event handler of the same name.
//
// Parameters:
//  Form					- ClientApplicationForm - the form from which the procedure is called from the event handler.
//  EventName				- String - the ID of the message by the receiving form (see the Notify method)
//  Parameter				- Arbitrary - message parameter (see Notify method)
//  Source				- Arbitrary - event source (see Notify method)
//  AdditionalParameters	- Structure - advanced setting.
//
Procedure NotificationProcessing(Form, EventName, Parameter, Source, AdditionalParameters = Undefined) Export
	
	Return;
	
EndProcedure

// An overridable procedure called from the form event handler of the same name.
//
// Parameters:
// 	Form - ClientApplicationForm - THE Form from whose event handler the procedure is called.
//	see the background information on events of the managed Form.
//	FormattedStringURL - String - navigation link string
//	StandardProcessing - Boolean - a sign of the standard event processing
//
Procedure URLProcessing(Form, FormattedStringURL, StandardProcessing) Export
	
	Return;
	
EndProcedure

// A procedure called from the form event handler of the same name.
//
// Parameters:
//  Form			- ClientApplicationForm - the form from which the procedure is called from the event handler.
//  WriteParameters	- Structure        - recording parameters, see the reference information on managed form events
//
Procedure AfterWrite(Form, WriteParameters) Export
	
	Return;
	
EndProcedure

// An overridable procedure called from the form event handler of the same name.
//
// Parameters:
// 	Form - ClientApplicationForm - the form from which the procedure is called from the event handler.
//  Cancel	- Boolean - a sign of refusal to open the form.
//
Procedure OnOpen(Form, Cancel) Export
	
	Return;
	
EndProcedure

#Region FormElementEvents

// An overridable procedure called from the element's event handler of the same name.
//
// Parameters:
//   Form                   - ClientApplicationForm - the form from which the procedure is called.
//   Item                 - Arbitrary     - source of the "when changing" event":
//    *Name                    - String           - name of the source of the "When changing" event
//   AdditionalParameters - Structure        - values of additional parameters that affect processing.
//
Procedure WhenChangingElement(Form, Item, AdditionalParameters) Export
	
	Return;
	
EndProcedure

// An overridable procedure called from the element's event handler of the same name.
//
Procedure WhenSelectingItem(Form, Item, RowSelected, Field, StandardProcessing, AdditionalParameters = Undefined) Export
	
	Return;
	
EndProcedure

// An overridable procedure called from the element's event handler of the same name.
//
Procedure OnActivateCell(Form, Item, AdditionalParameters) Export
	
	Return;
	
EndProcedure

// An overridable procedure called from the element's event handler of the same name.
//
Procedure OnActivateRow(Form, Item, AdditionalParameters) Export
	
	Return;
	
EndProcedure

// An overridable procedure called from the element's event handler of the same name.
//
Procedure OnStartEdit(Form, Item, NewRow, Copy, AdditionalParameters) Export
	
	Return;
	
EndProcedure

Procedure StartSelectingItem(Form, Item, ChoiceData, StandardProcessing) Export
	
	Return;
	
EndProcedure

#EndRegion

Procedure Attachable_CheckCompletionOfICTask() Export
	Return;
EndProcedure

// The function returns the name of the event that requires updating the hyperlink of the GIS MT document verification.
// 
// Returns:
//  String - The name of the event after the receipt was broken for updating the GIS MT check.
Function NameOfEventAfterReceiptWasBreachedForUpdatingGISMTCheck() Export
	
	EventName = "";
	
	Return EventName;
	
EndFunction

#EndRegion
