////////////////////////////////////////////////////////////////////////////////
// Contains form events called on the server
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// A procedure called from the form event handler of the same name.
//
// Parameters:
//  Form					- ClientApplicationForm - the form from which the procedure is called from the event handler.
//  Cancel					- Boolean - indicates that the form was not created.
//  StandardProcessing	- Boolean - indicates whether standard (system) event processing is performed
//  AdditionalParameters	- Structure - advanced setting.
//
Procedure OnCreateAtServer(Form, Cancel, StandardProcessing, AdditionalParameters = Undefined) Export
	DocumentVerificationServer.WhenCreatingFormOnServer(Form, Cancel, StandardProcessing, AdditionalParameters);
	FormEventsLocalization.OnCreateAtServer(Form, Cancel, StandardProcessing, AdditionalParameters);
	ConfigurationModificationOverridable.OnCreateAtServer(Form, Cancel, StandardProcessing);
	
EndProcedure

// A procedure called from the form event handler of the same name.
//
// Parameters:
//	Form					- ClientApplicationForm - the form from which the procedure is called from the event handler.
//	CurrentObject			- CatalogObject, DocumentObject - the object to be read.
//	AdditionalParameters - Structure - advanced setting.
//
Procedure OnReadAtServer(Form, CurrentObject, AdditionalParameters = Undefined) Export
	DocumentVerificationServer.WhenReadingFormOnServer(Form, CurrentObject);
	FormEventsLocalization.OnReadAtServer(Form, CurrentObject, AdditionalParameters);
	ConfigurationModificationOverridable.OnReadAtServer(Form, CurrentObject);
	
EndProcedure

Procedure BeforeWriteAtServer(Form, CurrentObject, Cancel, WriteParameters) Export
	
	FormEventsLocalization.BeforeWriteAtServer(Form, CurrentObject, Cancel, WriteParameters);
	ConfigurationModificationOverridable.BeforeWriteAtServer(Form, Cancel, CurrentObject, WriteParameters);
	
EndProcedure

// A procedure called from the form event handler of the same name.
//
// Parameters:
//	Form					- ClientApplicationForm - the form from which the procedure is called from the event handler.
//  Cancel					- Boolean - indicates that the form entry was rejected.
//	CurrentObject			- CatalogObject, DocumentObject - the object being recorded.
//	WriteParameters			- Structure - additional recording parameters.
//
Procedure OnWriteAtServer(Form, Cancel, CurrentObject, WriteParameters) Export
	
	FormEventsLocalization.OnWriteAtServer(Form, Cancel, CurrentObject, WriteParameters);
	
EndProcedure

// A procedure called from the form event handler of the same name.
//
// Parameters:
//	Form					- ClientApplicationForm - the form from which the procedure is called from the event handler.
//	CurrentObject			- CatalogObject, DocumentObject - the object being recorded.
//	WriteParameters			- Structure - additional recording parameters.
//
Procedure AfterWriteAtServer(Form, CurrentObject, WriteParameters) Export
	DocumentVerificationServer.AfterWriteAtServer(Form, CurrentObject, WriteParameters);
	FormEventsLocalization.AfterWriteAtServer(Form, CurrentObject, WriteParameters);
	ConfigurationModificationOverridable.AfterWriteAtServer(Form, CurrentObject, WriteParameters);
	
EndProcedure

// A procedure called from the form event handler of the same name.
//
// Parameters:
//	Form					- ClientApplicationForm - the form from which the procedure is called from the event handler.
//  Cancel					- Boolean - a sign of refusal to successfully check the filling.
//	CheckedAttributes	- Array of String - Verified banking details.
//
Procedure FillCheckProcessingAtServer(Form, Cancel, CheckedAttributes) Export
	
	FormEventsLocalization.FillCheckProcessingAtServer(Form, Cancel, CheckedAttributes);
	
EndProcedure

#Region FormElementEvents

// A server-side redefined procedure that is called from the element's event handler.
//
// Parameters:
//   Form                   - ClientApplicationForm - the form from which the procedure is called.
//   Item                 - String           - name of the source element of the "when changed" event.
//   AdditionalParameters - Structure        - values of additional parameters that affect processing.
//
Procedure WhenChangingElement(Form, Item, AdditionalParameters = Undefined) Export
	
	FormEventsLocalization.WhenChangingElement(Form, Item, AdditionalParameters);
	
EndProcedure

// A server-side redefined procedure that is called from the element's event handler.
//
// Parameters:
//   Form                   - ClientApplicationForm - the form from which the procedure is called.
//   Item                 - String           - name of the source element of the "when changed" event.
//   AdditionalParameters - Structure        - values of additional parameters that affect processing.
//
Procedure WhenChangingFormPages(Form, Item, AdditionalParameters = Undefined) Export
	
	FormEventsLocalization.WhenChangingFormPages(Form, Item, AdditionalParameters);
	
EndProcedure

// Server-side redefined procedure for processing the added command
//
// Parameters:
//   Form                   - ClientApplicationForm - the form from which the procedure is called.
//   AdditionalParameters - Structure        - command call parameters.
//
Procedure ExecuteOverridableCommand(Form, AdditionalParameters) Export
	
	FormEventsLocalization.ExecuteOverridableCommand(Form, AdditionalParameters);
	
EndProcedure

#EndRegion

#EndRegion
