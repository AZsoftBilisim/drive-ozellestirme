
#Region Public

// The event handler for the navigation links.
// 
// Parameters:
// 	Form - ClientApplicationForm - the form of the document
// 	FormattedStringURL - String - Navigation links
// 	StandardProcessing - Boolean - a sign of the standard event processing
//
Procedure StringFixHandlingNavigationLinks(Form, FormattedStringURL, StandardProcessing) Export
	
	If FormattedStringURL = "OpenListOfCorrectiveDocuments" Then
		
		Object = Form.Object;
		
		FormParameters = New Structure;
		FormParameters.Insert("CorrectedDocument", Object.CorrectedDocument);
		FormParameters.Insert("CurrentDocument", Object.Ref);
		
		OpenForm("CommonForm.ListOfDocumentCorrections", FormParameters, Form);
		
		StandardProcessing = False;
		
	EndIf;
	
EndProcedure

// The procedure opens the document correction form
// 
// Parameters:
// 	CorrectedDocument - DocumentRef - Document being corrected
// 	CurrentDocument - DocumentRef - Current document
//
Procedure OpenListOfFixes(Val CorrectedDocument, Val CurrentDocument) Export
	
	CorrectionListParameters = New Structure;
	CorrectionListParameters.Insert("CorrectedDocument", CorrectedDocument);
	CorrectionListParameters.Insert("CurrentDocument", CurrentDocument);
		
	OpenForm("CommonForm.CorrectionsOfAdjustments", CorrectionListParameters, ThisObject);
	
EndProcedure

// A procedure called from the form event handler of the same name. 
// Notifies you that a document correction has been entered.
//
// Parameters:
// 	Object					- FormDataStructure - Data of the form that the procedure is called from the event handler.
//
Procedure AfterWrite(Object) Export
	
	If Object.Patch Then
		Notify("Conducting_Correction", Object.CorrectedDocument, Object.Ref);
	EndIf;
	
EndProcedure

// A procedure called from the form event handler of the same name. 
// Blocks changes to the document if a correction is entered or the document is reversed.
//
// Parameters:
// 	DocumentForm			- ClientApplicationForm - the form from which the procedure is called from the event handler.
// 	EventName				- String - ID of the message in the receiving form (see the Notify method).
// 	Parameter				- DocumentRef - Corrected / reversed document.
// 	Source				- DocumentRef - A corrective document or a storno document.
//
Procedure NotificationProcessing(DocumentForm, EventName, Parameter, Source) Export
	
	ElementCorrection = DocumentForm.Items.LineCorrection;
	CancellationOfStorno = EventName = "Write_ReversingEntry";
	
	If EventName = "Conducting_Storno" Or EventName = "Conducting_Correction" Or CancellationOfStorno Then
		If Parameter = DocumentForm.Object.Ref Then 
			Object = DocumentForm.Object;
			
			If CommonClientServer.HasAttributeOrObjectProperty(Object, "CorrectedDocument") Then
				CorrectedDocument = ?(ValueIsFilled(Object.CorrectedDocument), Object.CorrectedDocument, Object.Ref);
			Else
				CorrectedDocument = Object.Ref;
			EndIf;
			DocumentForm.LineCorrection = DocumentCorrectionServerCall.DocumentCorrectionHyperlink(
				CorrectedDocument, ?(EventName = "Conducting_Storno", Source, Undefined));
				
			CorrectionIntroduced = ValueIsFilled(DocumentForm.LineCorrection);
			ElementCorrection.Visible = CorrectionIntroduced;
			
			DocumentForm.ReadOnly = False;
			DocumentForm.Read();
		EndIf;
	EndIf;

EndProcedure

#EndRegion
