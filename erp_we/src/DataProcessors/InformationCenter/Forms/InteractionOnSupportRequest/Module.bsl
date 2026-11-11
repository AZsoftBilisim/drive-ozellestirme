
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	InteractionID = Parameters.InteractionID;
	SupportRequestID = Parameters.SupportRequestID;
	InteractionType = Parameters.InteractionType;
	Incoming = Parameters.Incoming;
	If Parameters.Property("UserCode") 
		And ValueIsFilled(Parameters.UserCode) Then
		UserCode = Parameters.UserCode;
	Else
		UserCode = InformationCenterServer.UserCodeForAccess();
	EndIf;
	Viewed = Parameters.Viewed;
	
	FillInInteraction();
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	If Not Viewed Then 
		Notify("ViewedInteractionOnRequest");
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ContentOnClick(Item, EventData, StandardProcessing)

	StandardProcessing = False;
	
	InformationCenterClient.OpenLink(EventData.Href, EventData.Element, Item.Document);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure FilesSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "FilesPresentation" Or Field.Name = "FilesPicture" Then 
		Result = GetFileNameAndFileStorageAddress(Item.CurrentData.Id);
		InformationCenterClient.GetFileFromStorage(Result.StorageAddress, Result.FileName);
	EndIf;
	
EndProcedure

&AtClient
Procedure Reply(Command)
	
	InformationCenterClient.OpenFormForSendingMessageToSupportService(
		False, SupportRequestID, UserCode);
	
EndProcedure

&AtClient
Procedure GoToSupportRequest(Command)
	
	InformationCenterClient.OpenSupportRequest(SupportRequestID, UserCode);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInInteraction()
	
	Try
		InteractionData = GetInteractionData();
		FillInFormElements(InteractionData);
	Except
		ErrorText = InformationCenterInternal.DetailedErrorText(ErrorInfo());
		WriteLogEvent(InformationCenterServer.GetEventNameForLog(), 
		                         EventLogLevel.Error,,, ErrorText);
		OutputText_ = InformationCenterServer.TextOfErrorInformationOutputInSupportService();
		Raise OutputText_;
	EndTry;
	
EndProcedure

// Get interaction data.
// 
// Returns:
//  XDTODataObject 
&AtServer
Function GetInteractionData()
	
	WSProxy = InformationCenterServer.GetSupportProxy();
	
	Result = WSProxy.getInteraction(UserCode, String(InteractionID), 
		InteractionType, Incoming);
	
	Return Result;
	
EndFunction

&AtServer
Procedure FillInFormElements(InteractionData)
	
	Title = InteractionData.Name;
	
	If InteractionData.Type = "PhoneCall" Then
		
		Items.Content.Visible = False;
		Items.Files.Visible = False;
		
		Return;
		
	EndIf;
	
	HTMLText = InteractionData.HTMLText;
	
	// Place images in temporary storage
	For Each DD In InteractionData.HTMLFiles Do
		 
		Picture = New Picture(DD.Data);
		StorageAddress = PutToTempStorage(Picture, UUID);
		HTMLText = StrReplace(HTMLText, DD.Name, StorageAddress);
		
	EndDo;
	
	Content = HTMLText;
	
	// Displaying files
	
	Files.Clear();
	Items.Files.Visible = (InteractionData.Files.Count() <> 0);
	
	For Each CurrentFile In InteractionData.Files Do
		 
		NewItem = Files.Add();
		NewItem.Presentation = CurrentFile.Name + "." + CurrentFile.Extension
			 + " (" + Round(CurrentFile.Size / 1024, 2) + " " + NStr("vi = 'Kb';
																	|ru = 'Кб';
																	|en = 'kB'; fa = 'kB';
																	|it = 'Kb';
																	|pl = 'kB';
																	|tr = 'Kb'") + ")";
		NewItem.Id = New UUID(CurrentFile.Id);
		
	EndDo;
	
EndProcedure

&AtServer
Function GetFileNameAndFileStorageAddress(FileID)
	
	ReturnValue = New Structure;
	ReturnValue.Insert("StorageAddress", "");
	ReturnValue.Insert("FileName", "");
	
	Try
		
		WSProxy = InformationCenterServer.GetSupportProxy();
		Result = WSProxy.getInteractionFile(UserCode, String(InteractionID), 
			String(FileID), InteractionType, Incoming);
		ReturnValue.StorageAddress = PutToTempStorage(Result.Data, UUID);
		ReturnValue.FileName = Result.Name + "." + Result.Extension;
		
	Except
		
		ErrorText = InformationCenterInternal.DetailedErrorText(ErrorInfo());
		WriteLogEvent(InformationCenterServer.GetEventNameForLog(), 
		                         EventLogLevel.Error,,, ErrorText);
		OutputText_ = InformationCenterServer.TextOfErrorInformationOutputInSupportService();
		
		Raise OutputText_;
		
	EndTry;
	
	Return ReturnValue;
	
EndFunction

#EndRegion