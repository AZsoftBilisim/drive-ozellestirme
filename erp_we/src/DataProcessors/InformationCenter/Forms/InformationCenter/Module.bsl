#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	UseSeparationByDataAreas = SaaSOperations.DataSeparationEnabled()
		And SaaSOperations.SeparatedDataUsageAvailable();
	
	
	If UseSeparationByDataAreas Then // for the service model
		
		FillInHomePage();
		
		InformationCenterServerOverridable.DefineInformationSearchLink(InformationSearchRef);
		
		CreateListOfNews();
		
		Items.CreateMessageToTechSupportGroup.Visible = InformationCenterServer.ConfiguredIntegrationWithInformationCenter();
		
	Else
		
		IsFullUser = Users.IsFullUser();
		Items.CreateMessageToTechSupportGroup.Visible = IsFullUser
			Or InformationCenterServer.ConfiguredIntegrationWithInformationCenter();
		Items.SupportConnectionSettings.Visible = IsFullUser;
		
		Items.IdeaCreationGroup.Visible = False;
		Items.ExtensionsDirectoryGroup.Visible = False;
		Items.ForumGroup.Visible = False;
		Items.MyTasksGroup.Visible = False;
		
	EndIf;
	
	Items.SearchGroup1.Visible = Not IsBlankString(InformationSearchRef);
	
	InformationCenterServer.OutputContextualLinks(ThisObject, Items.InformationReferences, 1, 10, False);
	
	If Common.SubsystemExists("StandardSubsystems.CallingOnlineSupport") Then
		HasAccessRightTo1CConnect = AccessRight("View", Metadata.CommonCommands["ContactOnlineSupportSpecialist"]);
		If HasAccessRightTo1CConnect Then
			ModuleOnlineSupport = Common.CommonModule("CallingOnlineSupport");
			ModuleOnlineSupport.OnCreateAtServer(Items.ContactSpecialist);
		EndIf;
	Else
		Items.ContactSpecialist.Visible = False;
	EndIf;
	
	If ExtensionsDirectory.Used() Then
		Items.ExtensionsDirectoryGroup.Visible = True;
		Items.ExtensionsDirectory.Title = ExtensionsDirectory.NameOfExtensionCatalogLink();
	Else
		Items.ExtensionsDirectoryGroup.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If HasAccessRightTo1CConnect Then
		CTLSubsystemsIntegrationClient.IntegrationOnlineSupportCallClientNotificationProcessing(EventName, Items.ContactSpecialist);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers


// Parameters:
// 	Item - FormDecoration - element of the news description form.
&AtClient
Procedure Attachable_ClickingOnNewsItem(Item)
	
	Filter = New Structure;
	Filter.Insert("FormItemName", Item.Name);
	
	RowsArray = NewsTable.FindRows(Filter);
	If RowsArray.Count() = 0 Then 
		Return;
	EndIf;
	
	CurMessage = RowsArray.Get(0); // FormDataCollectionItem
	MessageID = CurMessage.Id;
	
	If CurMessage.InformationType = "Unavailability" Then 
		
		ExternalRef = CurMessage.ExternalRef;
		
		If Not IsBlankString(ExternalRef) Then 
			FileSystemClient.OpenURL(ExternalRef);
			Return;
		EndIf;
		
		InformationCenterClient.ShowNews(MessageID);
		
	ElsIf CurMessage.InformationType = "NotificationOfWish" Then 
		
		IdeaID = String(MessageID);
		
		InformationCenterClient.ShowIdea(IdeaID);
		
    ElsIf CurMessage.InformationType = "News" Then
        
		InformationCenterClient.ShowNews(MessageID);
        
    EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ClickingMoreMessages(Item)
	
	InformationCenterClient.ShowAllMessages();
	
EndProcedure

&AtClient
Procedure SupportRequestsClick(Item)
	
	InformationCenterClient.OpenSupportRequests();
	
EndProcedure

&AtClient
Procedure IdeasCenterClick(Item)
	
	InformationCenterClient.OpenIdeaCenter();
	
EndProcedure

&AtClient
Procedure HomePageClick(Item)
	
	If Not HomePage.Property("URL") Then 
		Return;
	EndIf;
	
	FileSystemClient.OpenURL(HomePage.URL);
	
EndProcedure

&AtClient
Procedure ForumClick(Item)
	
	InformationCenterClient.OpenForumDiscussions();
	
EndProcedure

&AtClient
Procedure ExtensionsDirectoryClick(Item)
	
	ExtensionsDirectoryClient.OpenExtensionsDirectory();
	
EndProcedure

// @skip-warning EmptyMethod - a feature of the implementation.
&AtClient
Procedure RequestsToGrantAccessClick(Item)
	Return;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure FindAnswerToQuestion(Command)
	
	FindingAnswerToQuestion();
	
EndProcedure

&AtClient
Procedure Attachable_ClickingOnInformationLink(Command) Export

	InformationCenterClient.ClickingOnInformationLink(ThisObject, Command);
	
EndProcedure

&AtClient
Procedure ContactASupportSpecialist(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.CallingOnlineSupport") Then
		ModuleOnlineSupport = CommonClient.CommonModule("CallingOnlineSupportClient");
		ModuleOnlineSupport.CallOnlineSupport();
	EndIf;
	
EndProcedure

&AtClient
Procedure SupportConnectionSettings(Command)
	
	InformationCenterClient.OpenCuspActivationForm();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInHomePage()
	
	URL = GetInfoBaseURL();
	URIStructure = CommonClientServer.URIStructure(URL);
	
	If Not IsBlankString(URIStructure.Host) Then
		HomePage = New Structure("Host, URL", URIStructure.Host, URIStructure.Schema + "://" + URIStructure.Host);
		Items.HomePage.Title = HomePage.Host;
	Else
		Items.HomePage.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure CreateListOfNews()
	
	InformationCenterServer.GenerateListOfNewsOnDesktop(NewsTable);
	
	If NewsTable.Count() = 0 Then 
		Return;
	EndIf;
	
	NewsGroup = Items.NewsGroup;
	
	For Iteration = 0 To NewsTable.Count() - 1 Do
		
		Description = NewsTable.Get(Iteration).DataRef.Description;
		
		If IsBlankString(Description) Then 
			Continue;
		EndIf;
		
		Severity  = NewsTable.Get(Iteration).DataRef.Severity;
		Picture     = ?(Severity > 5, PictureLib.ServiceNotification, PictureLib.ServiceMessage);
		
		NewsGroup_                     = Items.Add("NewsGroup_" + String(Iteration), Type("FormGroup"), NewsGroup);
		NewsGroup_.Type                 = FormGroupType.UsualGroup;
		NewsGroup_.ShowTitle = False;
		NewsGroup_.Group         = ChildFormItemsGroup.Horizontal;
		NewsGroup_.Representation         = UsualGroupRepresentation.None;
		
		PictureNews                = Items.Add("PictureNews" + String(Iteration), Type("FormDecoration"), NewsGroup_);
		PictureNews.Type            = FormDecorationType.Picture;
		PictureNews.Picture       = Picture;
		PictureNews.Width         = 2;
		PictureNews.Height         = 1;
		PictureNews.PictureSize = PictureSize.Stretch;
		
		NewsName                          = Items.Add("NewsName" + String(Iteration), Type("FormDecoration"), NewsGroup_);	
		NewsName.Type                      = FormDecorationType.Label;
		NewsName.Title                = Description;
		NewsName.HorizontalStretch = True;
		NewsName.VerticalAlign    = ItemVerticalAlign.Center;
		NewsName.TitleHeight          = 1;
		DataProcessors.InformationCenter.SetHyperlinkAttribute(NewsName);
		NewsName.SetAction("Click", "Attachable_ClickingOnNewsItem");
		
		NewsTable.Get(Iteration).FormItemName = NewsName.Name;
		NewsTable.Get(Iteration).InformationType    = NewsTable.Get(Iteration).DataRef.InformationType.Description;
		NewsTable.Get(Iteration).Id    = NewsTable.Get(Iteration).DataRef.Id;
		NewsTable.Get(Iteration).ExternalRef    = NewsTable.Get(Iteration).DataRef.ExternalRef;
		
	EndDo;
	
	MoreMessages                          = Items.Add("MoreMessages", Type("FormDecoration"), NewsGroup);
	MoreMessages.Type                      = FormDecorationType.Label;
	MoreMessages.Title                = NStr("vi = 'Còn có tin nhắn';
											|ru = 'Еще сообщения';
											|en = 'More messages'; fa = 'More messages';
											|it = 'Ancora messaggi';
											|pl = 'Więcej wiadomości';
											|tr = 'Mesaj var'");
	MoreMessages.HorizontalStretch = True;
	MoreMessages.VerticalAlign    = ItemVerticalAlign.Center;
	DataProcessors.InformationCenter.SetHyperlinkAttribute(MoreMessages);
	MoreMessages.SetAction("Click", "Attachable_ClickingMoreMessages");
	
EndProcedure

&AtClient
Procedure FindingAnswerToQuestion()
	
	AttachIdleHandler("HandlingWaitingToFindAnswerToQuestion", 0.1, True);
	
EndProcedure

&AtClient
Procedure HandlingWaitingToFindAnswerToQuestion()
	
	If IsBlankString(SearchString) Then
		Return;
	EndIf;
	
	SearchStringInURLEncoding = SearchStringInURLEncoding(SearchString);
		FileSystemClient.OpenURL(InformationSearchRef + SearchStringInURLEncoding);
	
EndProcedure


&AtServerNoContext
Function SearchStringInURLEncoding(SearchString)
	Return EncodeString(SearchString, StringEncodingMethod.URLEncoding); 
EndFunction 

#EndRegion