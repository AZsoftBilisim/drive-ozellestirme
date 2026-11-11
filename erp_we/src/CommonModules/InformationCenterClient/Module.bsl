
#Region Public

// Handler procedure when clicking on an information link.
//
// Parameters:
//	Form - ClientApplicationForm - context of the managed form.
//	Item - FormGroup - the group forms.
//
Procedure ClickingOnInformationLink(Form, Item) Export
	
	Hyperlink = Form.InformationReferences.FindByValue(Item.Name);
	
	If Hyperlink <> Undefined Then
			FileSystemClient.OpenURL(Hyperlink.Presentation);
	EndIf;
	
EndProcedure

// Handler procedure when clicking on" All " information links.
//
// Parameters:
//	FormPath - String - full path to the form.
//
Procedure ClickingOnAllInfoLinksLink(FormPath) Export

	FormParameters = New Structure("FormPath", FormPath);
	OpenForm("DataProcessor.InformationCenter.Form.InformationLinksInContext", FormParameters);
	
EndProcedure

// Opens a form with all support requests.
//
Procedure OpenSupportRequests() Export
	
	DatabaseIsConnectedByCusp = DatabaseIsConnectedByCusp();
	If DatabaseIsConnectedByCusp Then
		
		UserCode = ReadUserCodeFromComputerForUSP();
		If Not ValueIsFilled(UserCode) Then
			OpenUserCodeEntryForm();
			Return;
		EndIf;
		
		UserEmail = UserEmail();
		If Not ValueIsFilled(UserEmail) Then
			MessageText = NStr("vi = 'Để làm việc với giao tiếp, cần điền e-mail của người sử dụng.';
								|ru = 'Для работы с обращениями нужно заполнить e-mail пользователя.';
								|en = 'To manage requests, fill in user email.'; fa = 'To manage requests, fill in user email.';
								|it = 'Per lavorare con le richieste è necessario compilare l''email dell''utente.';
								|pl = 'Do pDo ppracy ze zgłoszeniami należy wypełnić adres e-mail użytkownika.';
								|tr = 'Başvurular ile çalışmak için kullanıcı e-posta adresini doldurmak gerekiyor.'");
			CommonClient.MessageToUser(MessageText);
			Return;
		EndIf;
		
		CodeReviewResult = CheckUserCodeForUSP(UserCode, UserEmail);
			
		If Not CodeReviewResult.CodeIsCorrect Then
			OpenUserCodeEntryForm();
			Return;
		EndIf;
			
		OpenListOfWUSPRequests(UserCode);
		
	Else
		
		OpenCuspActivationForm(DatabaseIsConnectedByCusp);
		
	EndIf;
	
EndProcedure

// Opens a form with discussions on the forum.
// @skip-warning EmptyMethod - a feature of the implementation.
//
Procedure OpenForumDiscussions() Export 
EndProcedure

// Opens a form with a Center of ideas.
// @skip-warning EmptyMethod - a feature of the implementation.
//
Procedure OpenIdeaCenter() Export 
EndProcedure

// Opens the form for displaying all news.
// @skip-warning EmptyMethod - a feature of the implementation.
//
Procedure ShowAllMessages() Export
EndProcedure

// Determines whether the local database is connected to the support service
// 
// Returns:
//  Boolean - True if the database is connected to the USP
//
Function DatabaseIsConnectedByCusp() Export
	
	SettingsData = InformationCenterServerCall.DataForSuspIntegrationSettings();
	Return SettingsData.ConfirmedCodeForIntegrationOfSUSPS;
	
EndFunction

// Opens the interaction for the request.
//
// Parameters:
//	SupportRequestID - UUID - ID of the request.
//	InteractionID - UUID - the ID of the interaction.
//	InteractionType - String - type of interaction.
//	Incoming - Boolean - flag: incoming message or not.
//	Viewed - Boolean - flag: the message was viewed or not.
//
Procedure OpenInteractionWithSupport(SupportRequestID, InteractionID, InteractionType, 
	Incoming, Viewed = True, UserCode = Undefined) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("SupportRequestID", SupportRequestID);
	FormParameters.Insert("InteractionID", InteractionID);
	FormParameters.Insert("InteractionType", InteractionType);
	FormParameters.Insert("Incoming", Incoming);
	FormParameters.Insert("Viewed", Viewed);
	
	If ValueIsFilled(UserCode) Then
		FormParameters.Insert("UserCode", UserCode);
	EndIf;
	
	OpenForm("DataProcessor.InformationCenter.Form.InteractionOnSupportRequest", FormParameters,,
		New UUID);
	
EndProcedure

// Opens the form for sending a message to the recipient.
//
// Parameters:
//	CreateSupportRequest - Boolean - if True, the Form of a new appeal will be opened.
//	                              if False, the Form of the existing appeal will be opened (in this case it is necessary
//	                              specify the following conversion ID parameter
//	SupportRequestID - UUID - Optional parameter. You must specify if to create a message = A lie
//	UserCode - String - code that allows you to identify the initiator of the request
//	RequestParameters_ - See InformationCenterClientServer.NewParametersForContactingSupportService
//
Procedure OpenFormForSendingMessageToSupportService(CreateSupportRequest, 
	SupportRequestID = Undefined, UserCode = Undefined, RequestParameters_ = Undefined) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("CreateSupportRequest", CreateSupportRequest);
	If SupportRequestID <> Undefined Then 
		FormParameters.Insert("SupportRequestID", SupportRequestID);
	EndIf;
	
	ClosingNotification1 = Undefined;
	If RequestParameters_ <> Undefined Then
		FormParameters.Insert("Subject", RequestParameters_.Subject);
		FormParameters.Insert("Text", RequestParameters_.Text);
		FormParameters.Insert("Use_StandardTemplate", RequestParameters_.Use_StandardTemplate);
		FormParameters.Insert("Attachments", RequestParameters_.Attachments);
		FormParameters.Insert("AdditionalData", RequestParameters_.AdditionalData);
		ClosingNotification1 = RequestParameters_.CompletionHandler;
	EndIf;

	If ValueIsFilled(UserCode) Then
		FormParameters.Insert("UserCode", UserCode);
	EndIf;
	
	OpenForm("DataProcessor.InformationCenter.Form.SendingAMessageToTechnicalSupport",
		FormParameters,,,,,ClosingNotification1);
	
EndProcedure

// Opens the support contact form
//
// Parameters:
//	SupportRequestID - UUID - ID of the request.
//
Procedure OpenSupportRequest(SupportRequestID, UserCode = Undefined) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("SupportRequestID", SupportRequestID);
	If ValueIsFilled(UserCode) Then
		FormParameters.Insert("UserCode", UserCode);
	EndIf;
	OpenForm("DataProcessor.InformationCenter.Form.InteractionsOnSupportRequest", FormParameters,, 
		New UUID);
	
EndProcedure

// Opens a form with a list of requests
//
// Parameters:
//  UserCode	 - String - user code for handling requests
//
Procedure OpenListOfWUSPRequests(UserCode) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("UserCode", UserCode);
	OpenForm("DataProcessor.InformationCenter.Form.TechnicalSupportRequests", FormParameters);
	
EndProcedure

// Opens the Form for editing and sending a new request to the support service.
// The Form can be filled in with data beforehand.
//
// Parameters:
//  RequestParameters_ - See InformationCenterClientServer.NewParametersForContactingSupportService
//
Procedure OpenNewIncidentForm(RequestParameters_ = Undefined) Export
	
	OpenFormForSendingMessageToSupportService(True, Undefined, Undefined, RequestParameters_);
	
EndProcedure

#Region ObsoleteProceduresAndFunctions

// Deprecated. You should use the Information Centerclientserver.newreparametersreferencessupport services
// 
// See InformationCenterClientServer.NewParametersForContactingSupportService
// 
Function NewParametersForContactingSupportService() Export

	Return InformationCenterClientServer.NewParametersForContactingSupportService();
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

// Opens a form for displaying a separate news item.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//	Id - UUID - news ID.
//
Procedure ShowNews(Id) Export
EndProcedure

// Opens a form with the content of the idea.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Parameters:
//	IdeaID - String - unique ID of the idea.
//
Procedure ShowIdea(Val IdeaID) Export
EndProcedure

Procedure PuttingFile(Notification, 
	Address = Undefined, 
	File = Undefined,
	Interactively = Undefined, 
	FormIdentifier = Undefined,
	NotificationBeforePlacement = Undefined) Export

	//@skip-warning DeprecatedMethod - a feature of the implementation.
	BeginPutFile(Notification, Address, File, Interactively, FormIdentifier, NotificationBeforePlacement);
	
EndProcedure

Procedure PlacingFiles(CallbackOnCompletion, Files, 
	Interactively = Undefined,
	FormIdentifier = Undefined,
	NotificationBeforePlacement = Undefined) Export
	
	//@skip-warning DeprecatedMethod - a feature of the implementation.
	BeginPuttingFiles(
		CallbackOnCompletion, Files, Interactively, FormIdentifier, NotificationBeforePlacement)

EndProcedure

// Get the file from the repository.
// 
// Parameters:
//  Address - String - Address
//  FileName - String - file name
//  Interactively - Boolean - the sign of interactive receipt
// 
// Returns:
//  Boolean, Undefined - indication of getting a file from storage
Function GetFileFromStorage(Address, FileName, Interactively = True) Export
	
	//@skip-warning DeprecatedMethod - a feature of the implementation.
	Return GetFile(Address, FileName, Interactively);
	
EndFunction

Procedure SaveUserCodeOnComputer(UserCode) Export
	
	#If WebClient Then
		Return;
	#Else
		
		SplitCode = InformationCenterClientServer.SplitUserCode(UserCode);
		TempFileName = GetTempFileName();
		
		// In a Windows Remote Desktop connection session, the temporary files directory can be a temporary
		// subdirectory created for the duration of the session. In this case, we will create a file in the user's shared directory.
		SharedFolderPosition = StrFind(Upper(TempFileName), "\TEMP\", SearchDirection.FromEnd);
		If SharedFolderPosition <> 0 Then
			PositionOfPenultimateSeparator = SharedFolderPosition + StrLen("\TEMP");
			PositionOfLastSeparator = StrFind(TempFileName, "\", SearchDirection.FromEnd);
			If PositionOfLastSeparator > PositionOfPenultimateSeparator Then
				TempFileName = Left(TempFileName, PositionOfPenultimateSeparator - 1)
				+ Mid(TempFileName, PositionOfLastSeparator);
			EndIf;
		EndIf;
		
		TextDocument = New TextDocument;
		TextDocument.AddLine(SplitCode[1]);
		TextDocument.Write(TempFileName);
		File = New File(TempFileName);
		File.SetReadOnly(True);
		
		InformationCenterServerCall.SaveUserCode(ComputerName(), SplitCode[0], TempFileName);
		
	#EndIf
	
EndProcedure

// Opens unseen interactions.
//
// Parameters:
//	SupportRequestID - UUID - ID of the request.
//	ListOfUnseenInteractions - ValueList - list of unseen interactions.
//
Procedure OpenUnseenInteractions(SupportRequestID, ListOfUnseenInteractions, UserCode) Export 
	
	If ListOfUnseenInteractions.Count() = 1 Then 
		FirstInteraction = ListOfUnseenInteractions.Get(0).Value;
		OpenInteractionWithSupport(SupportRequestID, FirstInteraction.Id, 
			FirstInteraction.Type, FirstInteraction.Incoming, False, UserCode);
	Else
		Parameters = New Structure;
		Parameters.Insert("ListOfUnseenInteractions", ListOfUnseenInteractions);
		Parameters.Insert("SupportRequestID", SupportRequestID);
		
		If ValueIsFilled(UserCode) Then
			Parameters.Insert("UserCode", UserCode);
		EndIf;
		
		OpenForm("DataProcessor.InformationCenter.Form.UnreadInteractions", Parameters,,
			New UUID);
	EndIf;
	
EndProcedure

Procedure OpenLink(Href, Element, HTMLDocument = Undefined) Export
	
	SelectedLink = Undefined;
	
	If Href <> Undefined Then
		// If the event data has the Href property filled in, we will assume that the transition will be via this link.
		SelectedLink = Href;
	Else
		Try
			// If the event element has the Href property and the AREA element filled 
			// in, we will assume that the transition will follow this link.
			If Upper(Element.tagName) = "AREA" Then
				SelectedLink = Element.Href;
			EndIf;
		Except
		EndTry;
	EndIf;
	
	If IsBlankString(SelectedLink) Then
		Return;
	EndIf;
	
	#If WebClient Then
		If Find(SelectedLink, "javascript:_1c") = 1 Then
			
			// FF - javascript of this type is used
			NavigationLinkPosition = Find(SelectedLink, "e1cib/");
			
			If NavigationLinkPosition <> 0 Then
				SelectedLink = 
				"v8doc:" 
				+ Mid(
				SelectedLink, 
				NavigationLinkPosition, 
				StrLen(SelectedLink) - NavigationLinkPosition - 2);
			Else
				Return;
			EndIf;
			
		EndIf;
		
		SeparatorPosition = Find(SelectedLink, "#");
		PositionOfInternalNavigationLink = Find(SelectedLink, "#e1cib/");
		
		If SeparatorPosition = 1  Then
			
			// Safari - just a relative link is passed
			Return;
			
		EndIf;
		
		If Find(SelectedLink, GetInfoBaseURL()) = 1 Then
			
			// Chrome, IE - the full link is transmitted
			If SeparatorPosition <> 0 And PositionOfInternalNavigationLink = 0 Then
				
				Return;
				
			EndIf;
			
		EndIf;
		
	#Else
		If Find(SelectedLink, GetInfoBaseURL()) = 1 Then
			
			ElementID = Mid(SelectedLink, Find(SelectedLink, "#") + 1);
			ElementByID = HTMLDocument.getElementById(ElementID);
			
			If ElementByID <> Undefined Then
				ElementByID.scrollIntoView(True);
				Return;
			EndIf;
			
		EndIf;
	#EndIf
	
	LinkDiagram = DefineLinkScheme(SelectedLink);
	
	If LinkDiagram = "e1c://" Then
		
		GotoURL(SelectedLink);
	
	ElsIf (LinkDiagram = "http://" And Find(SelectedLink, "e1cib") > 0)
		Or (LinkDiagram = "https://" And Find(SelectedLink, "e1cib") > 0) Then
		
		If Not FollowInternalNavigationLink(SelectedLink) Then
			GotoURL(SelectedLink);
		EndIf;
		
	ElsIf LinkDiagram = "http://"
		Or LinkDiagram = "https://"
		Or LinkDiagram = "ftp://"
		Or LinkDiagram = "file://" Then
		
		#If WebClient Then
			GotoURL(SelectedLink);
		#Else
			RunApp(SelectedLink);
		#EndIf
		
	Else
		
		GotoURL(SelectedLink);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private
	
Function ReadUserCodeFromComputerForUSP()
	
	#If WebClient Then
		
		Return "";
		
	#Else
		
		ComputerName = ComputerName();
		ComputerCode = InformationCenterServerCall.ReadUserCode(ComputerName);
		
		If Not ValueIsFilled(ComputerCode) Then
			Return "";
		EndIf;
		
		TextDocument = New TextDocument;
		Try
			TextDocument.Read(ComputerCode.TemporaryFileOfPieceOfCode);
			SplitCode = New Array;
			SplitCode.Add(ComputerCode.PartOfVIBCode);
			SplitCode.Add(TextDocument.GetText());
			UserCode = InformationCenterClientServer.CollectUserCode(SplitCode);
			Return UserCode;
		Except // file deleted or corrupted
			InformationCenterServerCall.WriteWarning(
			NStr("vi = 'Không tìm thấy dữ liệu kế toán đã lưu của người sử dụng bộ phận hỗ trợ';
				|ru = 'Не найдены сохраненные учетные данные пользователя службы поддержки';
				|en = 'Saved credentials of the technical support user are not found'; fa = 'Saved credentials of the technical support user are not found';
				|it = 'Non sono stati trovati dati di account salvati dell''utente del servizio di supporto';
				|pl = 'Nie znaleziono danych kont użytkownika pomocy technicznej';
				|tr = 'Destek hizmeti kullanıcısının kayıtlı bilgileri bulunamadı'"));
			Return "";
		EndTry;
		
	#EndIf
	
EndFunction

// Checks the user's code for working with the support service.
//
// Parameters:
//  UserCode	 - String - the code being checked
//  Email			 - String - e-mail of the user whose code is being checked
// 
// Returns:
//  Structure - With Fields:
//  	* CodeIsCorrect - Boolean
//  	* MessageText - String - filled in if the code is incorrect
//
Function CheckUserCodeForUSP(UserCode, Email)
	
	Return InformationCenterServerCall.CheckUserCode(UserCode, Email);
	
EndFunction

// Opens a form for entering the user code for working with support requests from the local database
//
Procedure OpenUserCodeEntryForm()
	
	OpenForm("DataProcessor.InformationCenter.Form.UserCodeEntryForm");
	
EndProcedure

// Opens the form for connecting the local database to the support service
//
Procedure OpenCuspActivationForm(Val DatabaseEnabled = Undefined) Export
	
	If DatabaseEnabled = Undefined Then
		DatabaseEnabled = DatabaseIsConnectedByCusp();
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("DatabaseEnabled", DatabaseEnabled);
	OpenForm("DataProcessor.InformationCenter.Form.SupportConnectionForm", FormParameters);
	
EndProcedure

// User's e-mail address for handling support requests
// 
// Returns:
//  String - e-mail
//
Function UserEmail()
	
	Return InformationCenterServerCall.UserEmail();
	
EndFunction

Function FollowInternalNavigationLink(URL)
	
	PositionOfInternalNavigationLink = Find(URL, "#e1cib/");
	If PositionOfInternalNavigationLink = 0 Then
		Return False;
	EndIf;
	
	InternalNavigationLink = Mid(URL, PositionOfInternalNavigationLink + 1);
	Try
		GotoURL(InternalNavigationLink);
	Except
		// The internal navigation link may not be in the database.
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

Function DefineLinkScheme(Href)
	
	Schemes = New Array;
	Schemes.Add("v8doc:");
	Schemes.Add("http://");
	Schemes.Add("https://");
	Schemes.Add("ftp://");
	Schemes.Add("e1c://");
	Schemes.Add("file://");
	Schemes.Add("mailto:");
	
	For Each Schema In Schemes Do
		If StrStartsWith(Href, Schema) Then
			Return Schema;
		EndIf;
	EndDo;
	
	Return "";
	
EndFunction

#EndRegion