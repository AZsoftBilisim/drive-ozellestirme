#Region Internal

#Region FormEventHandlers

// Event handler before writing an object from the Form.
//
// Parameters:
//   Form           - ClientApplicationForm - the shape of the object being recorded.
//   Cancel           - Boolean           - indicates that the recording was rejected.
//   WriteParameters - Structure        - structure containing the record parameters.
Procedure BeforeWrite(Form, Cancel, WriteParameters) Export
	
	Return;
	
EndProcedure

// Occurs on the client after writing an object from the Form.
//
// Parameters:
//  Form           - ClientApplicationForm - form of the object being recorded,
//  WriteParameters - Structure        - structure containing the record parameters.
//
Procedure AfterWrite(Form, WriteParameters) Export
	
	Return;
	
EndProcedure

// Called in all created forms when the Notify method is called.
//
// Parameters:
//  Form      - ClientApplicationForm - notifiable form,
//  DocumentReference - DocumentRef    - link to the document,
//  EventName - String                  - event name,
//  Parameter   - Arbitrary            - the parameter of the message. Any necessary data can be transmitted,
//  Source   - Arbitrary            - event source.
//
Procedure NotificationProcessing(Form, DocumentReference, EventName, Parameter, Source) Export
	
	Return;
	
EndProcedure

#EndRegion

#EndRegion
