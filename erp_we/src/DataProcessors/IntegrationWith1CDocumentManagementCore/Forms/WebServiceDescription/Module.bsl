#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	WebServiceDescription = IntegrationWith1CDocumentManagementCore.WebServiceDescription();
	
	Parameters.Property("Ref", Ref);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If ValueIsFilled(Ref) Then
		AttachIdleHandler("GoToLink_", 0.2, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure HTMLDocumentFieldOnClick(Item, EventData, StandardProcessing)
	
	StandardProcessing = False;
	If Not ValueIsFilled(EventData.HRef) Then
		Return;
	EndIf;
	
	Position = StrFind(EventData.HRef, "#", SearchDirection.FromEnd);
	Ref = Mid(EventData.HRef, Position + 1);
	AttachIdleHandler("GoToLink_", 0.2, True);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure GoToLink_()
	
	// If there are problems with browser compatibility, we will open the document without positioning
	// on the link, swallowing the exception as uncritical.
	Try
		Document = Items.HTMLDocumentField.Document;
		For Each Item In Document.querySelectorAll(StrTemplate("a[name=""%1""]", Ref)) Do
			Item.scrollIntoView(True);
			Break;
		EndDo;
	Except
		Return;
	EndTry;
	
EndProcedure

#EndRegion