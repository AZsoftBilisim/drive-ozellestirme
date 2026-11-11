#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Sort = Items.Sort.ChoiceList.Get(0).Value;
	Filter = Items.Filter.ChoiceList.Get(0).Value;
	CurrentPage = 1;
	If Parameters.Property("UserCode") 
		And ValueIsFilled(Parameters.UserCode) Then
		UserCode = Parameters.UserCode;
	Else
		UserCode = InformationCenterServer.UserCodeForAccess();
	EndIf;
	
	FillInListOfRequests();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "SendingAMessageToTechnicalSupport" 
		Or EventName = "ViewedInteractionOnRequest"  Then
			 
		AttachIdleHandler("FillInListOfRequestsClient", 0.1, True);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SortOnChange(Item)
	
	CurrentPage = 1;
	FillInListOfRequests();
	
EndProcedure

&AtClient
Procedure FilterOnChange(Item)
	
	CurrentPage = 1;
	FillInListOfRequests();
	
EndProcedure

&AtClient
Procedure MoveToTheLeftClick(Item)
	
	CurrentPage = CurrentPage - 1;
	FillInListOfRequests();
	
EndProcedure

&AtClient
Procedure GoRightClick(Item)
	
	CurrentPage = CurrentPage + 1;
	FillInListOfRequests();
	
EndProcedure

&AtClient
Procedure HitsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "HitsLabelAnswerExists" Then 
		InformationCenterClient.OpenUnseenInteractions(
			Item.CurrentData.Id, Item.CurrentData.ListOfUnseenInteractions, UserCode);
	Else
		InformationCenterClient.OpenSupportRequest(Item.CurrentData.Id, UserCode);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ContactTechnicalSupport(Command)
	
	InformationCenterClient.OpenFormForSendingMessageToSupportService(True, , UserCode);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure FillInListOfRequestsClient()
	
	FillInListOfRequests();
	
EndProcedure

&AtServer
Procedure FillInListOfRequests()
	
	Try
		
		PresentationOfListOfRequests = GetPresentationOfListOfRequests();
		GeneratePage(PresentationOfListOfRequests);
		
	Except
		
		ErrorText = InformationCenterInternal.DetailedErrorText(ErrorInfo());
		WriteLogEvent(InformationCenterServer.GetEventNameForLog(), 
		                         EventLogLevel.Error,,, ErrorText);
		OutputText_ = InformationCenterServer.TextOfErrorInformationOutputInSupportService();
		
		Raise OutputText_;
		
	EndTry;
	
EndProcedure

// Get a view of the list of requests.
// 
// Returns:
//  XDTODataObject
&AtServer
Function GetPresentationOfListOfRequests()
	
	WSProxy = InformationCenterServer.GetSupportProxy();
	
	Result = WSProxy.getIncidents(UserCode, CurrentPage, Filter, Sort);
	
	Return Result;
	
EndFunction

&AtServer
Procedure GeneratePage(PresentationOfListOfRequests)
	
	FillOutRequests(PresentationOfListOfRequests);	
	FillBasement(PresentationOfListOfRequests);
	
EndProcedure

&AtServer
Procedure FillOutRequests(PresentationOfListOfRequests)
	
	Hits.Clear();
	
	For Each SupportRequestObject In PresentationOfListOfRequests.Incidents Do 
		
		NewSupportRequest = Hits.Add();
		NewSupportRequest.Id = New UUID(SupportRequestObject.Id);
		NewSupportRequest.State = SupportRequestObject.Status;
		NewSupportRequest.Description = 
			?(IsBlankString(SupportRequestObject.Name), NStr("vi = '<Không có chủ đề>';
															|ru = '<Без темы>';
															|en = '<No subject>'; fa = '<No subject>';
															|it = '<senza soggetto>';
															|pl = '<Bez tematu>';
															|tr = '<Konu yok>'"), SupportRequestObject.Name);
		NewSupportRequest.Picture = InformationCenterServer.ImageByStateOfRequest(SupportRequestObject.Status);
		NewSupportRequest.Date = SupportRequestObject.Date;
		NewSupportRequest.Number = SupportRequestObject.Number;
		NewSupportRequest.NumberOfUnseenInteractions = SupportRequestObject.UnreviewedInteractions.Count();
		
		If NewSupportRequest.NumberOfUnseenInteractions <> 0 Then
			 
			ExplanationKIsAnswer = ?(NewSupportRequest.NumberOfUnseenInteractions = 1, 
				"", " (" + String(NewSupportRequest.NumberOfUnseenInteractions) + ")");
			AnswerExists = ?(NewSupportRequest.NumberOfUnseenInteractions = 1, 
				NStr("vi = 'Chưa đọc';
					|ru = 'Непрочитанные';
					|en = 'Unread'; fa = 'Unread';
					|it = 'Non letti';
					|pl = 'Nieprzeczytane';
					|tr = 'Okunmamış'"), NStr("vi = 'Chưa đọc';
											|ru = 'Непрочитанные';
											|en = 'Unread'; fa = 'Unread';
											|it = 'Non letti';
											|pl = 'Nieprzeczytane';
											|tr = 'Okunmamış'"));
			NewSupportRequest.LabelAnswerExists = AnswerExists + ExplanationKIsAnswer;
			
			For Each UnsolicitedInteraction In SupportRequestObject.UnreviewedInteractions Do
				 
				ListValue = 
					InformationCenterServer.StoredInteractionValue(UnsolicitedInteraction);
				NewSupportRequest.ListOfUnseenInteractions.Add(ListValue);
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure FillBasement(PresentationOfListOfRequests)
	
	ThereArePagesUpTo = (CurrentPage > 1);
	ThereArePagesAfter = PresentationOfListOfRequests.IsStill;
	
	Items.MoveToTheLeft.Hyperlink = ThereArePagesUpTo;
	Items.MoveToTheLeft.Picture = 
		?(ThereArePagesUpTo, PictureLib.MoveToTheLeftActive, PictureLib.MoveToTheLeftNotActive);
	Items.GoRight.Picture = 
		?(ThereArePagesAfter, PictureLib.MoveToTheRightActive, PictureLib.MoveToTheRightNotActive);
	Items.GoRight.Hyperlink = ThereArePagesAfter;
	Items.CurrentPage.Title = CurrentPage;
	
EndProcedure

#EndRegion