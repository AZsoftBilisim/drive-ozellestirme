
#Region Public

// A procedure called from the form event handler of the same name. 
//
// Parameters:
//  DocumentForm - ClientApplicationForm - the form from which the procedure is called from the event handler.
//  EventName     - String - ID of the message in the receiving form (see the Notify method).
//  Parameter       - DocumentRef - parameter of the form event handler with the same name.
//  Source       - DocumentRef - source of the form event handler with the same name.
//
Procedure NotificationProcessing(DocumentForm, EventName, Parameter, Source) Export
	
	
EndProcedure

// Unloads the document and saves the upload file.
//
// Parameters:
//	ApplicationForm	- ClientApplicationForm - The form of the document being uploaded.
//
Procedure UploadImportStatement(ApplicationForm) Export
	
	
EndProcedure

// Checks the possibility of unloading.
//
// Parameters:
//	ApplicationForm	- ClientApplicationForm - The form of the document being uploaded.
//
Procedure CheckUpload(ApplicationForm) Export
	
	
EndProcedure

// Opens the form of the previously created (or new) regulated report "Statistical form of accounting for the movement of goods" or opens the form.
//
// Parameters:
//	ApplicationForm - ClientApplicationForm - The form of the document of the application for the import of goods, for which it is necessary to create a statform for the movement of goods.
//
Procedure CreateVFTSStatform(ApplicationForm) Export
	
	
EndProcedure

// Sends a notification to the supervisory authority.
//
// Parameters:
//	ApplicationForm	- ClientApplicationForm - The form of the document of the application for the import of goods to be sent.
//
Procedure UpdateSubmission(ApplicationForm) Export
	
	
EndProcedure

// Opens the protocol for sending a notification to the supervisory authority.
//
// Parameters:
//	The form of the application - The form of the Client Application - The form of the document of the application for the import of goods to be sent.
//
Procedure HyperlinkProtocolClick(FormApplication) Export
	
	
EndProcedure

// Sends a notification to the supervisory authority.
//
// Parameters:
//	ApplicationForm	- ClientApplicationForm - The form of the document of the application for the import of goods to be sent.
//
Procedure SendUnsentNotification(ApplicationForm) Export
	
	
EndProcedure

// Displays the Status of sending a notification to the supervisory authority.
//
// Parameters:
//	ApplicationForm - ClientApplicationForm - The form of the document of the application for the import of goods to be sent.
//
Procedure StagesOfSendingClick(ApplicationForm) Export
	
	
EndProcedure

// Opens errors that occurred when sending a notification to the supervisory authority.
//
// Parameters:
//	ApplicationForm - ClientApplicationForm - The form of the document of the application for the import of goods to be sent.
//
Procedure CriticalErrorsURLProcessing(ApplicationForm, StandardProcessing) Export
	
	
EndProcedure

#EndRegion

#Region Private


#EndRegion
