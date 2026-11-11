#Region Internal

#Region FormEventHandlers

// Occurs AT server when creating the Form of the Employment document.
//
// Parameters:
//  Form - ClientApplicationForm - the Form being created,
//  Cancel - Boolean - whether to refuse to create a Form,
//  StandardProcessing - Boolean - indicates whether standard processing is being performed.
//
Procedure OnCreateAtServer(Form, Cancel, StandardProcessing) Export
	
EndProcedure

// Called when reading an object on the server.
//
// Parameters:
//  Form - ClientApplicationForm - The Form of the readable object,
//  CurrentObject - DocumentObject, CatalogObject - readable object.
//
Procedure OnReadAtServer(Form, CurrentObject) Export
	
EndProcedure

// Overridable procedure for the handler of the event "Before recording in the server" of the document Form.
//
// Parameters:
//   Form - ClientApplicationForm - The Form of the document from whose event handler the procedure is called.
//   Cancel - Boolean - The write rejection flag.
//   WriteParameters - Structure - Document recording parameters.
Procedure BeforeWriteAtServer(Form, Cancel, WriteParameters)Export
	
EndProcedure

// An overridable procedure for processing the event "After recording on the server" of the document Form.
//
// Parameters:
//   Form - ClientApplicationForm - The Form of the document from whose event handler the procedure is called.
//   CurrentObject - DocumentObject - The object that is being recorded.
//   WriteParameters - Structure - Document recording parameters.
Procedure AfterWriteAtServer(Form, CurrentObject, WriteParameters)Export
	
EndProcedure

#EndRegion

#EndRegion
