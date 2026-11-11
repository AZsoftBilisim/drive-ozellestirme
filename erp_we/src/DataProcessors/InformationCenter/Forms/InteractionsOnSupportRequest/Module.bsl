#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SupportRequestID = Parameters.SupportRequestID;
	If Parameters.Property("UserCode") 
		And ValueIsFilled(Parameters.UserCode) Then
		UserCode = Parameters.UserCode;
	Else
		UserCode = InformationCenterServer.UserCodeForAccess();
	EndIf;
	CurrentPage = 1;
	Reviewed = False;
	
	FillInRequestContent();
	FillInCorrespondenceOnRequest();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "SendingAMessageToTechnicalSupport" Or EventName = "ViewedInteractionOnRequest" Then 
		AttachIdleHandler("FillInCorrespondenceOnRequestClient", 0.1, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure InteractionsListSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Item.CurrentData;
	
	InformationCenterClient.OpenInteractionWithSupport(SupportRequestID, 
		CurrentData.Id, CurrentData.Type, CurrentData.Incoming, CurrentData.Viewed, UserCode);
	
EndProcedure

&AtClient
Procedure LeftButtonClick(Item)
	
	CurrentPage = CurrentPage - 1;
	FillInCorrespondenceOnRequest();
	
EndProcedure

&AtClient
Procedure RightButtonClick(Item)
	
	CurrentPage = CurrentPage + 1;
	FillInCorrespondenceOnRequest();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure AddComment(Command)
	
	InformationCenterClient.OpenFormForSendingMessageToSupportService(
		False, SupportRequestID, UserCode);
	
EndProcedure

&AtClient
Procedure Reviewed(Command)
	
	ReviewedOnServer();
	
	If Reviewed Then 
		Notify("ViewedInteractionOnRequest");
	EndIf;
	
	Reviewed = False;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInRequestContent()
	
	Try
		
		DataByIncident = GETRequestData();
		FillInContent(DataByIncident);
		
	Except
		
		ErrorText = InformationCenterInternal.DetailedErrorText(ErrorInfo());
		WriteLogEvent(InformationCenterServer.GetEventNameForLog(), 
		                         EventLogLevel.Error,,, ErrorText);
		OutputText_ = InformationCenterServer.TextOfErrorInformationOutputInSupportService();
		
		Raise OutputText_;
		
	EndTry;
	
EndProcedure

// Get the data on the request.
// 
// Returns:
//  XDTODataObject 
&AtServer
Function GETRequestData()
	
	WSProxy = InformationCenterServer.GetSupportProxy();
	
	Result = WSProxy.getIncident(UserCode, String(SupportRequestID));
	
	Return Result;
	
EndFunction

&AtServer
Procedure FillInContent(DataByIncident)
	
	ThisObject.Title = DataByIncident.Name + " (" + DataByIncident.Number + ")";
	
EndProcedure

&AtClient
Procedure FillInCorrespondenceOnRequestClient()
	
	FillInCorrespondenceOnRequest();
	
EndProcedure

&AtServer
Procedure FillInCorrespondenceOnRequest()
	
	Try
		
		CorrespondenceData = GetDataOnCorrespondence();
		FillInCorrespondence(CorrespondenceData);
		
	Except
		
		ErrorText = InformationCenterInternal.DetailedErrorText(ErrorInfo());
		WriteLogEvent(InformationCenterServer.GetEventNameForLog(), 
		                         EventLogLevel.Error,,, ErrorText);
		OutputText_ = InformationCenterServer.TextOfErrorInformationOutputInSupportService();
		
		Raise OutputText_;
		
	EndTry;
	
EndProcedure

// Get data on correspondence.
// 
// Returns:
//  XDTODataObject
&AtServer
Function GetDataOnCorrespondence()
	
	WSProxy = InformationCenterServer.GetSupportProxy();
	
	Result = WSProxy.getInteractions(UserCode, String(SupportRequestID), 
		CurrentPage);
	
	Return Result;
	
EndFunction

&AtServer
Procedure FillInCorrespondence(CorrespondenceData)
	
	InteractionsList.Clear();
	
	For Each InteractionElement In CorrespondenceData.Interactions Do
		 
		NewInteraction = InteractionsList.Add();
		NewInteraction.Id = New UUID(InteractionElement.Id);
		NewInteraction.Subject = InteractionElement.Name;
		NewInteraction.LongDesc = ?(IsBlankString(InteractionElement.Description), 
			NStr("vi = '<Không có nội dung>';
				|ru = '<Без текста>';
				|en = '<No text>'; fa = '<No text>';
				|it = '<Senza testo>';
				|pl = '<Bez tekstu>';
				|tr = '<Metin yok>'"), InteractionElement.Description);
		NewInteraction.Date = InteractionElement.Date;
		NewInteraction.PictureNumber = InformationCenterServer.InteractionImageNumber(
			InteractionElement.Type, InteractionElement.Incoming);
		NewInteraction.AttachmentPicture = 
			?(InteractionElement.IsFiles, PictureLib.Clip, Undefined);
		NewInteraction.ImageExplanation = 
			?(InteractionElement.Incoming, NStr("vi = 'Đến';
												|ru = 'Вх.';
												|en = 'Incoming'; fa = 'ورودی';
												|it = 'In entrata';
												|pl = 'Incoming';
												|tr = 'Gelen'"), NStr("vi = 'Đi';
																		|ru = 'Исх.';
																		|en = 'Outgoing'; fa = 'خروجی';
																		|it = 'Orig.';
																		|pl = 'Outgoing';
																		|tr = 'Giden'"));
		NewInteraction.Incoming = InteractionElement.Incoming;
		NewInteraction.Type = InteractionElement.Type;
		NewInteraction.Viewed = InteractionElement.Viewed;
		
	EndDo;
	
	FillBasement(CorrespondenceData);
	
EndProcedure

&AtServer
Procedure FillBasement(CorrespondenceData)
	
	ThereArePagesUpTo = (CurrentPage > 1);
	ThereArePagesAfter = CorrespondenceData.IsStill;
	
	Items.LeftButton.Hyperlink = ThereArePagesUpTo;
	Items.LeftButton.Picture = 
		?(ThereArePagesUpTo, PictureLib.MoveToTheLeftActive, PictureLib.MoveToTheLeftNotActive);
	Items.RightButton.Picture = 
		?(ThereArePagesAfter, PictureLib.MoveToTheRightActive, PictureLib.MoveToTheRightNotActive);
	Items.RightButton.Hyperlink = ThereArePagesAfter;
	Items.CurrentPage.Title = CurrentPage;
	
EndProcedure

&AtServer
Procedure ReviewedOnServer()
	
	WSProxy = InformationCenterServer.GetSupportProxy();
	
	Factory = WSProxy.XDTOFactory;
	
	TypeListOfInteractions = 
		Factory.Type("http://www.1c.ru/1cFresh/InformationCenter/SupportServiceData/1.0.0.1", "ListInteraction");
	ListOfXDTOInteractions = Factory.Create(TypeListOfInteractions);
	
	RowsArray = Items.InteractionsList.SelectedRows;
	
	For Each ArrayElement In RowsArray Do
		 
		FoundRow = InteractionsList.FindByID(ArrayElement);
		
		If FoundRow = Undefined Then 
			Continue;
		EndIf;
		
		If FoundRow.Viewed Then 
			Continue;
		EndIf;
		
		Reviewed = True;
		
		XdtoInteraction = GenerateXDTOInteraction(FoundRow, Factory);
		DataProcessors.InformationCenter.AddValueToXDTOList(
			ListOfXDTOInteractions, "Interactions", XdtoInteraction);
		
	EndDo;
	
	WSProxy.setInteractionsViewed(UserCode, ListOfXDTOInteractions);
	
EndProcedure

&AtServer
Function GenerateXDTOInteraction(FoundRow, Factory)
	
	InteractionType = 
		Factory.Type("http://www.1c.ru/1cFresh/InformationCenter/SupportServiceData/1.0.0.1", "Interaction");
	Interaction = Factory.Create(InteractionType);
	
	Interaction.Id = String(FoundRow.Id);
	Interaction.Type = FoundRow.Type;
	Interaction.Incoming = FoundRow.Incoming;
	
	Return Interaction;
	
EndFunction

#EndRegion