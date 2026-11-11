
#Region Public

////////////////////////////////////////////////////////////////////////////////
// Information and links

// Displays informational links on the form
//
// Parameters:
//	Form - ClientApplicationForm - the form context.
//	FormGroup - FormGroup - group of the form where informational links are displayed.
//	GroupCount - Number - the number of information link groups in the form.
//	NumberOfLinksInGroup - Number - the number of informational links in the group.
//	DisplayAllLink - Boolean - whether or not to display the "All" link.
//	FormPath - String - full path to the form.
//
Procedure OutputContextualLinks(Form, FormGroup, GroupCount = 3, NumberOfLinksInGroup = 1, 
	DisplayAllLink = True, FormPath = "") Export
	
	Try
		
		If IsBlankString(FormPath) Then 
			FormPath = Form.FormName;
		EndIf;
		
		HashOfPathToForm = HashOfFullPathToForm(FormPath);
		
		FormReferenceTable = InformationCenterServerCached.InformationReferences(HashOfPathToForm);
		If FormReferenceTable.Count() = 0 Then 
			Return;
		EndIf;
		
		// Changing form parameters
		FormGroup.ShowTitle = False;
		FormGroup.ToolTip   = "";
		FormGroup.Representation = UsualGroupRepresentation.None;
		FormGroup.Group = ChildFormItemsGroup.Horizontal;
		
		// Adding a list of Informational Links
		AttributeName = "InformationReferences";
		AttributesToBeAdded = New Array;
		AttributesToBeAdded.Add(New FormAttribute(AttributeName, New TypeDescription("ValueList")));
		Form.ChangeAttributes(AttributesToBeAdded);
		
		FormOutputGroups(
			Form, FormReferenceTable, FormGroup, GroupCount, NumberOfLinksInGroup, DisplayAllLink);
		
	Except
		
		EventName = GetEventNameForLog();
		WriteLogEvent(EventName, EventLogLevel.Error,,,
			DetailErrorDescription(ErrorInfo()));
		
	EndTry;	
		
EndProcedure

// Fills in the form elements with informational links.
//
// Parameters:
//  Form - ClientApplicationForm - shape.
//  ItemArray - Array of FormField - array of form elements.
//  AllLinksElement - FormDecoration - form element.
//  FormPath - String - path to the form.
//
Procedure FillInStaticInformationLinks(Form, ItemArray, AllLinksElement = Undefined, 
	FormPath = "") Export
	
	Try
		
		If IsBlankString(FormPath) Then 
			FormPath = Form.FormName;
		EndIf;
		
		HashOfPathToForm = HashOfFullPathToForm(FormPath);
		
		RefsTable = InformationCenterServerCached.InformationReferences(HashOfPathToForm);
		If RefsTable.Count() = 0 Then 
			Return;
		EndIf;
		
		FillInformationLinks(Form, ItemArray, RefsTable, AllLinksElement);
		
		//@skip-warning StringLiteralContainsError - verification error
		If TypeOf(AllLinksElement) = Type("FormDecoration") Then
			DisplayLink = RefsTable.Count() <= ItemArray.Count();
			AllLinksElement.Visible = DisplayLink;
		EndIf;
		
		
	Except
		
		EventName = GetEventNameForLog();
		WriteLogEvent(EventName, EventLogLevel.Error,,, 
			DetailErrorDescription(ErrorInfo()));
			
	EndTry;	
	
EndProcedure

// Returns an information link by ID.
//
// Parameters:
//	Id - String - the link identifier.
//
// Returns:
//	Structure - contextual link:
//	* Address - String
//	* Description - String
//
Function ContextualLinkByID(Id) Export
	
	ReturnedStructure = New Structure;
	ReturnedStructure.Insert("Address", "");
	ReturnedStructure.Insert("Description", "");
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	InformationReferencesForForms.Address AS Address,
	|	InformationReferencesForForms.Description AS Description
	|FROM
	|	Catalog.InformationReferencesForForms AS InformationReferencesForForms
	|WHERE
	|	InformationReferencesForForms.Id = &ID
	|	AND NOT InformationReferencesForForms.DeletionMark";
	
	Query.SetParameter("ID", Id);
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		ReturnedStructure.Address = Selection.Address;
		ReturnedStructure.Description = Selection.Description;
		Break;
		
	EndDo;
	
	Return ReturnedStructure;
	
EndFunction

// Returns all of the namespace information links.
//
// Returns:
//  Array of String - an array of the namespace of informational links.
//
Function NamespacesOfInformationalLinks() Export
	
	ArrayOfSpaces = New Array;
	ArrayOfSpaces.Add(NamespaceOfInformationalLinks());
	ArrayOfSpaces.Add(NamespaceOfInformationalLinks_1_0_1_1());
	
	Return ArrayOfSpaces;	
	
EndFunction

// Generates a list of news.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//	NewsTable - ValueTable - with columns:
//	 * Description - String - headline news.
//	 * Id - UUID - news ID.
//	 * Severity - Number - criticality of the news.
//	 * ExternalRef - String - the address of the external links.
//	NumberOfDisplayedNews - Number - the number of displayed news items on the desktop.
//
Procedure GenerateListOfNewsOnDesktop(NewsTable, Val NumberOfDisplayedNews = 3) Export
	
EndProcedure

// Returns True if the database is configured to send and receive requests through the Information Center support service
// 
// Returns:
//  Boolean 
//
Function ConfiguredIntegrationWithInformationCenter() Export
	
	Return ConfirmedCodeForIntegrationOfSUSPS();
	
EndFunction

#Region ObsoleteProceduresAndFunctions

// Deprecated. You should use the Information Center Server.The
// configured integration with the Information Center Returns True if integration with the Support Service Information Center is installed.
// 
// Returns:
//	Boolean - True if integration with the support service is installed.
Function IntegrationWithSupportEstablished() Export
	
	Return ConfiguredIntegrationWithInformationCenter();
		
EndFunction

#EndRegion

#EndRegion

#Region Internal

// Returns a list of layouts for informational links.
//
// Returns:
//  Array of TextDocument - array of shared layouts.
//
Function GetCommonTemplatesForInformationalLinks() Export
	
	ArrayOfTemplates = New Array;
	
	InformationCenterServerOverridable.CommonTemplatesWithInformationLinks(ArrayOfTemplates);
	
	Return ArrayOfTemplates;
	
EndFunction

// Generates a hash of the full path to the form when writing.
//
Procedure FullFormPathBeforeWriteBeforeWrite(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	If Not IsBlankString(Source.FullFormPath) Then 
		Source.Hash = HashOfFullPathToForm(Source.FullFormPath);
	EndIf;
	
EndProcedure

// Returns the hash of the full path to the form according to the algorithm.
//
// Parameters:
//	FullFormPath - String - full path to the form.
//
// Returns:
//	String - hash.
//
Function HashOfFullPathToForm(Val FullFormPath) Export
	
	DataHashing = New DataHashing(HashFunction.MD5);
	DataHashing.Append(FullFormPath);
	Return StrReplace(DataHashing.HashSum, " ", "");
	
EndFunction

// Returns the name of the log event.
//
// Returns:
//	String - The name of the log event.
//
Function GetEventNameForLog() Export
	
	Return NStr("vi = 'Trung tâm thông tin';
				|ru = 'Информационный центр';
				|en = 'Information center'; fa = 'مرکز اطلاعات';
				|it = 'Centro informazioni';
				|pl = 'Centrum informacyjne';
				|tr = 'Bilgi Merkezi'", Common.DefaultLanguageCode());
	
EndFunction

// The procedure for the routine task of reading the news of the support service
// @skip-warning EmptyMethod - a feature of the implementation.
//
Procedure SupportNewsReader() Export

EndProcedure

// Returns the Proxy of the Service Manager's Information Center.
// The calling code must independently set the privileged mode.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Returns:
//	WSProxy - proxy of the Information Center.
//
Function GetProxyInformationCenter_1_0_1_1() Export
	
EndFunction

// The address of the http service External Anonymous interface (ext_sd) of the support service
// 
// Returns:
//  String - Address 
//
Function AddressOfExternalAnonymousInterface() Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	Owner = Common.MetadataObjectID("DataProcessor.InformationCenter");
	AddressOfExternalAnonymousInterface = Common.ReadDataFromSecureStorage(
		Owner, "AddressOfExternalAnonymousInterface");
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
	If AddressOfExternalAnonymousInterface = Undefined Then
		Return "";
	EndIf;
	
	Return AddressOfExternalAnonymousInterface;
	
EndFunction

// E-mail of the user on whose behalf the local database is connected to the support service
// 
// Returns:
//  String - e-mail
//
Function SubscriberSEmailAddressForSuspIntegration() Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	Owner = Common.MetadataObjectID("DataProcessor.InformationCenter");
	SubscriberSEmailAddressForSuspIntegration = Common.ReadDataFromSecureStorage(
		Owner, "SubscriberSEmailAddressForSuspIntegration");
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
	If SubscriberSEmailAddressForSuspIntegration = Undefined Then
		Return "";
	EndIf;
	
	Return SubscriberSEmailAddressForSuspIntegration;
	
EndFunction

// Information about connecting the local database to the support service
// 
// Returns:
//  Structure - contains fields:
//  	* AddressOfExternalAnonymousInterface - String - the address of the ext_sd http service of the support service
//  	* AddressOfAnonymousIntegrationServiceWithUSPInformationCenter - String - the address of the support service web service
//  	* ConfirmedCodeForIntegrationOfSUSPS - Boolean - if True, then the database is connected to the support service
//  	* SubscriberSEmailAddressForSuspIntegration - String - E-mail of the user 
//			on whose behalf the local database is connected to the support service
//  	* WUSPRegistrationCode - String - The code with which the database is registered in the support service
//
Function DataForSuspIntegrationSettings() Export
	
	Result = New Structure;
	Result.Insert("AddressOfExternalAnonymousInterface", AddressOfExternalAnonymousInterface());
	
	SetSafeModeDisabled(True);
	Result.Insert("AddressOfAnonymousIntegrationServiceWithUSPInformationCenter", 
		AddressOfAnonymousIntegrationServiceWithUSPInformationCenter());
	SetSafeModeDisabled(False);
	
	Result.Insert("ConfirmedCodeForIntegrationOfSUSPS", ConfirmedCodeForIntegrationOfSUSPS());
	Result.Insert("SubscriberSEmailAddressForSuspIntegration", SubscriberSEmailAddressForSuspIntegration());
	Result.Insert("WUSPRegistrationCode", WUSPRegistrationCode());
	
	Return Result;
	
EndFunction

// Determines whether the code for registering the local database in the support service has been entered.
// 
// Returns:
//  Boolean - True if the code is entered
//
Function ConfirmedCodeForIntegrationOfSUSPS() Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	Owner = Common.MetadataObjectID("DataProcessor.InformationCenter");
	ConfirmedCodeForIntegrationOfSUSPS = Common.ReadDataFromSecureStorage(
		Owner, "ConfirmedCodeForIntegrationOfSUSPS");
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
	If ConfirmedCodeForIntegrationOfSUSPS = Undefined Then
		Return False;
	EndIf;
	
	Return ConfirmedCodeForIntegrationOfSUSPS;
	
EndFunction

// The code with which the database is registered in the support service
// 
// Returns:
//  String - Code
//
Function WUSPRegistrationCode() Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	Owner = Common.MetadataObjectID("DataProcessor.InformationCenter");
	WUSPRegistrationCode = Common.ReadDataFromSecureStorage(
		Owner, "WUSPRegistrationCode");
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
	If WUSPRegistrationCode = Undefined Then
		Return "";
	EndIf;
	
	Return WUSPRegistrationCode;
	
EndFunction

// Saves data about connecting the local database to the support service.
//
// Parameters:
//  ExternalInterfaceAddress		 - String - the address of the ext_sd http service of the support service
//  CodeConfirmed_				 - Boolean - if True, then the database is connected to the support service
//  SubscriberSAddress				 - String - E-mail of the user on whose behalf the local database is connected to the support service
//  RegistrationCode				 - String - The code with which the database is registered in the support service
//  AddressOfInformationCenter	 - String - the address of the web service of the support service for working with requests
//
Procedure RecordDataForSuspIntegrationSettings(ExternalInterfaceAddress, CodeConfirmed_, 
	SubscriberSAddress, RegistrationCode, AddressOfInformationCenter) Export
	
	WriteAddressOfExternalAnonymousInterface(ExternalInterfaceAddress);
	WriteDownAddressOfAnonymousIntegrationServiceWithUSPInformationCenter(AddressOfInformationCenter);
	RecordCodeConfirmationFlagForIntegrationOfSuspension(CodeConfirmed_);
	RecordSubscriberSEmailAddressForSuspIntegration(SubscriberSAddress);
	WriteVUSPRegistrationCode(RegistrationCode);
	
EndProcedure

// Saves the address of the ext_sd http service of the support service
//
// Parameters:
//  Address	 - String
//
Procedure WriteAddressOfExternalAnonymousInterface(Address) Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	Owner = Common.MetadataObjectID("DataProcessor.InformationCenter");
	Common.WriteDataToSecureStorage(Owner, Address, "AddressOfExternalAnonymousInterface");
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
EndProcedure

// Saves the address of the web service of the support service for working with requests
//
// Parameters:
//  Address	 - String
//
Procedure WriteDownAddressOfAnonymousIntegrationServiceWithUSPInformationCenter(Address) Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	Owner = Common.MetadataObjectID("DataProcessor.InformationCenter");
	Common.WriteDataToSecureStorage(
		Owner, Address, "AddressOfAnonymousIntegrationServiceWithUSPInformationCenter");
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
EndProcedure

// Saves the code confirmation flag for integrating the local database with the USP
//
// Parameters:
//  CodeConfirmed	 - Boolean
//
Procedure RecordCodeConfirmationFlagForIntegrationOfSuspension(CodeConfirmed) Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	Owner = Common.MetadataObjectID("DataProcessor.InformationCenter");
	Common.WriteDataToSecureStorage(Owner, CodeConfirmed, "ConfirmedCodeForIntegrationOfSUSPS");
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
EndProcedure

// Saves the e-mail of the user on whose behalf the local database is connected to the support service
//
// Parameters:
//  Address	 - String
//
Procedure RecordSubscriberSEmailAddressForSuspIntegration(Address) Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	Owner = Common.MetadataObjectID("DataProcessor.InformationCenter");
	Common.WriteDataToSecureStorage(Owner, Address, "SubscriberSEmailAddressForSuspIntegration");
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
EndProcedure

// Saves the code with which the database is registered in the support service 
//
// Parameters:
//  Code	 - String
//
Procedure WriteVUSPRegistrationCode(Code) Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	Owner = Common.MetadataObjectID("DataProcessor.InformationCenter");
	Common.WriteDataToSecureStorage(Owner, Code, "WUSPRegistrationCode");
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
EndProcedure

// Clears the data about the connection of the local database to the support service
//
Procedure ClearDataForSuspIntegrationSettings() Export
	
	WriteAddressOfExternalAnonymousInterface("");
	WriteDownAddressOfAnonymousIntegrationServiceWithUSPInformationCenter("");
	RecordCodeConfirmationFlagForIntegrationOfSuspension(False);
	RecordSubscriberSEmailAddressForSuspIntegration("");
	WriteVUSPRegistrationCode("");
	
EndProcedure

// Returns an image based on the state of the request.
//
// Parameters:
//	State - String - status of the request.
//
// Returns:
//	Picture - Picture.
//
Function ImageByStateOfRequest(State) Export
	
	If State = "Closed" Then 
		Return PictureLib.ClosedSupportRequest;
	ElsIf State = "InProgress" Then
		Return PictureLib.SupportRequestIsInProgress;
	ElsIf State = "New" Then
		Return PictureLib.NewSupportRequest;
	ElsIf State = "NeedAnswer" Then
		Return PictureLib.SupportRequestAnswerRequired;
	EndIf;
	
	Return Undefined;
	
EndFunction

// The number of the picture-type interaction.
//
// Parameters:
//	InteractionType - String - type of interaction.
//	Incoming - Boolean - whether the interaction is incoming for the user.
//
// Returns:
//	Number - picture number.
//
Function InteractionImageNumber(InteractionType, Incoming) Export
	
	If InteractionType = "Email" Then 
		If Incoming Then 
			Return 2;
		Else
			Return 3;
		EndIf;
	ElsIf InteractionType = "Comment" Then 
		Return 4;
	ElsIf InteractionType = "PhoneCall" Then 
		Return 1;
	EndIf;
	
	Return 0;
	
EndFunction

// Returns the email address of the current user.
//
// Returns:
//	String - the email address of the current user.
//
Function DetermineUserSEmailAddress() Export
	
	CurrentUser = Users.CurrentUser();
	
	If Common.SubsystemExists("StandardSubsystems.ContactInformation") Then 
		
		Module = Common.CommonModule("ContactsManager");
		If Module = Undefined Then 
			Return "";
		EndIf;
		
		Return Module.ObjectContactInformation(CurrentUser, 
			PredefinedValue("Catalog.ContactInformationKinds.UserEmail"));
		
	EndIf;
	
	Return "";
	
EndFunction

// Text of an exception when the support service is unavailable.
//
// Returns:
//	String - the exception text.
//
Function TextOfErrorInformationOutputInSupportService() Export
	
	Return NStr("vi = 'Dịch vụ hỗ trợ tạm thời không khả dụng.
                       |Vui lòng thử lại sau.';
                       |ru = 'Служба поддержки временно не доступна.
                       |Пожалуйста, повторите попытку позже.';
                       |en = 'Technical support is temporarily unavailable.
                       |Please, try again later.'; fa = 'Technical support is temporarily unavailable.
                       |Please, try again later.';
                       |it = 'Assistenza clienti non è temporaneamente disponibile.
                       |Si prega di riprovare più tardi.';
                       |pl = 'Służba pomocy jest czasowo nie dostępna.
                       |Proszę powtórzyć próbę później.';
                       |tr = 'Destek servisi geçici olarak kullanılamıyor.
                       |Lütfen, daha sonra tekrar deneyin.'")
	
EndFunction

// Returns the text template to technical support.
// 
// Parameters:
//  MessageText - String
//  
// Returns:
//	String - text template to technical support.
//
Function TextTemplateInTech(MessageText = "") Export
	
	Template = NStr("vi = 'Xin chào.
		|<p>%1%2</p>
		|Trân trọng, %3.';
		|ru = 'Здравствуйте.
		|<p>%1%2</p>
		|С уважением, %3.';
		|en = 'Hi,
		|
		|<p>%1%2</p>
		|Best regards, %3'; fa = 'Hi,
		|
		|<p>%1%2</p>
		|Best regards, %3';
		|it = 'Здравствуйте.
		|<p>%1%2</p>
		|С уважением, %3.';
		|pl = 'Hi,
		|
		|<p>%1%2</p>
		|Best regards, %3';
		|tr = 'Merhaba.
		|<p>%1%2</p>
		|Saygılarımızla, %3.'");
	Template = StrTemplate(Template, MessageText, "CursorPosition", Users.CurrentUser().FullDescr());
	
	Return Template;
	
EndFunction

// Gets the Wsproxy of the support service
//
// Returns:
//	WSProxy - WSPROXY support services.
//
Function GetSupportProxy() Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	ServiceAddress = AddressOfAnonymousIntegrationServiceWithUSPInformationCenter();
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
	ConnectionParameters = Common.WSProxyConnectionParameters();
	ConnectionParameters.WSDLAddress = ServiceAddress;
	ConnectionParameters.NamespaceURI = "http://www.1c.ru/1cFresh/InformationCenter/SupportServiceData/1.0.0.1";
	ConnectionParameters.ServiceName = "InformationCenterIntegrationProtected_1_0_0_1";
	ConnectionParameters.EndpointName = "InformationCenterIntegrationProtected_1_0_0_1Soap";
	ConnectionParameters.Timeout = 20;
	
	Proxy = Common.CreateWSProxy(ConnectionParameters);
	
	Return Proxy;
	
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
Function CheckUserCode(UserCode, Email) Export
	
	USPAddress = AddressOfExternalAnonymousInterface();
	
	Result = New Structure;
	Result.Insert("CodeIsCorrect", False);
	Result.Insert("MessageText", "");
	
	ServiceAddress = USPAddress + "/v1/CheckUserCode";
	
	Try
		
		URIStructure = CommonClientServer.URIStructure(ServiceAddress);
		Host = URIStructure.Host;
		PathAtServer = URIStructure.PathAtServer;
		Port = URIStructure.Port;
		
		If Lower(URIStructure.Schema) = Lower("https") Then
			SecureConnection = CommonClientServer.NewSecureConnection(
				, New OSCertificationAuthorityCertificates);
		Else
			SecureConnection = Undefined;
		EndIf;
		
		SetSafeModeDisabled(True);
		Join = New HTTPConnection(
			Host,
			Port,
			,
			,
			GetFilesFromInternet.GetProxy(URIStructure.Schema),
			,
			SecureConnection);
		SetSafeModeDisabled(False);
		
		QueryData = New Structure;
		QueryData.Insert("method_name", "CheckUserCode");
		QueryData.Insert("user_code", UserCode);
		QueryData.Insert("email", Email);
		
		JSONWriter = New JSONWriter;
		JSONWriter.SetString();
		WriteJSON(JSONWriter, QueryData);
		
		QueryString = JSONWriter.Close();
		
		Headers = New Map;
		Headers.Insert("Content-Type", "application/json; charset=utf-8");
		Headers.Insert("Accept", "application/json");
		
		Query = New HTTPRequest(PathAtServer, Headers);
		Query.SetBodyFromString(QueryString);
		
		Response = Join.Post(Query);
		
		If Response.StatusCode <> 200 Then
			ErrorText = StrTemplate(NStr("vi = 'Lỗi %1';
										|ru = 'Ошибка %1';
										|en = 'Error %1'; fa = 'Error %1';
										|it = 'Errore %1';
										|pl = 'Błąd %1';
										|tr = '%1 hatası'", Common.DefaultLanguageCode()), String(Response.StatusCode));
			Result.MessageText = ErrorText;
			Return Result;
		EndIf;
		
		JSONReader = New JSONReader;
		
		ResponseBodyString = Response.GetBodyAsString();
		JSONReader.SetString(ResponseBodyString);
		
		Try
			ResponseData = ReadJSON(JSONReader, False);	
		Except
			
			WriteLogEvent(
				StrTemplate(
					"%1.%2", 
					GetEventNameForLog(), 
					NStr("vi = 'Kiểm tra mã người sử dụng';
						|ru = 'Проверка кода пользователя';
						|en = 'Check user code'; fa = 'Check user code';
						|it = 'Verifica del codice utente';
						|pl = 'Sprawdzenie kodu użytkownika';
						|tr = 'Kullanıcı kodu kontrolü'", Common.DefaultLanguageCode())),
				EventLogLevel.Error,
				,
				,
				ResponseBodyString);
			
			Result.MessageText = ResponseBodyString;
			
			Return Result;
		EndTry;
		
		If Not ResponseData.success Then
			
			WriteLogEvent(
				StrTemplate(
					"%1.%2", 
					GetEventNameForLog(), 
					NStr("vi = 'Kiểm tra mã người sử dụng';
						|ru = 'Проверка кода пользователя';
						|en = 'Check user code'; fa = 'Check user code';
						|it = 'Verifica del codice utente';
						|pl = 'Sprawdzenie kodu użytkownika';
						|tr = 'Kullanıcı kodu kontrolü'", Common.DefaultLanguageCode())),
				EventLogLevel.Error,
				,
				,
				ResponseData.response_text);
			
			Result.MessageText = ResponseData.response_text;
			
			Return Result;
			
		EndIf;
		
		Result.CodeIsCorrect = True;
		
	Except
		
		ErrorInfo = ErrorInfo();
		
		WriteLogEvent(
			StrTemplate(
				"%1.%2", 
				GetEventNameForLog(), 
				NStr("vi = 'Kiểm tra mã người sử dụng';
					|ru = 'Проверка кода пользователя';
					|en = 'Check user code'; fa = 'Check user code';
					|it = 'Verifica del codice utente';
					|pl = 'Sprawdzenie kodu użytkownika';
					|tr = 'Kullanıcı kodu kontrolü'", Common.DefaultLanguageCode())),
			EventLogLevel.Error,
			,
			,
			DetailErrorDescription(ErrorInfo));
		
		Result.MessageText = InformationCenterInternal.DetailedErrorText(ErrorInfo);
		
		Return Result;
		
	EndTry;
	
	Return Result;
	
EndFunction

// Returns the code for accessing the web service of the support information center
// @skip-warning EmptyMethod - a feature of the implementation.
// Returns:
//  String - user code
//
Function UserCodeForAccess() Export
EndFunction

// Returns the structure of the interaction value stored on the form for the interaction XDTO object.
// 
// Parameters:
//	Interaction - XDTODataObject - interaction object. 
// Returns:
//	Structure:
// * Subject - String - topic of interaction. 
// * Date - Date - date the interaction was created.
// * LongDesc - String - description.
// * Id - UUID - ID.
// * Type - String - type. 
// * Incoming - Boolean - sign, True-incoming, False-outgoing.
//
Function StoredInteractionValue(Interaction) Export
		
	StoredValue = New Structure;
	StoredValue.Insert("Subject", Interaction.Name);
	StoredValue.Insert("Date", Interaction.Date);
	StoredValue.Insert("LongDesc", Interaction.Description);
	StoredValue.Insert("Id", New UUID(Interaction.Id));
	StoredValue.Insert("Type", Interaction.Type);
	StoredValue.Insert("Incoming", Interaction.Incoming);
	
	Return StoredValue;
	
EndFunction

// Information about the information base for integration with the support service.
// 
// Returns:
//  Structure - Information about information security for integration with USP:
//  * ConfigurationName - String
//  * ConfigurationVersion - String
//  * PlatformVersion - String
//  * ClientID - UUID
//  * InformationSecurityID - String
//  
Function InformationAboutInformationSecurityForIntegration()  Export
	
	Si = New SystemInfo;
	
	InformationRecords = New Structure();
	InformationRecords.Insert("ConfigurationName", Metadata.Name);
	InformationRecords.Insert("ConfigurationVersion", Metadata.Version);
	InformationRecords.Insert("PlatformVersion", Si.AppVersion);
	InformationRecords.Insert("ClientID", Si.ClientID);
	InformationRecords.Insert("InformationSecurityID", Constants.InfoBaseID.Get());
	
	Return InformationRecords;
	
EndFunction

Function RequestUserCodes(UserData_) Export
	
	USPAddress = AddressOfExternalAnonymousInterface();
	
	Result = New Structure;
	Result.Insert("RequestSent", False);
	Result.Insert("QueryID", Undefined);
	Result.Insert("SentEmailsCount", 0);
	Result.Insert("SubscriberHasNoUserAddress", Undefined);
	Result.Insert("ThereIsPageWithProtection", False);
	Result.Insert("MessageText", "");
	
	MethodName = "RequestLocalUserCodesStart";
	
	ServiceAddress = USPAddress + "/v1/"+MethodName;
	
	Try
		
		URIStructure = CommonClientServer.URIStructure(ServiceAddress);
		Host = URIStructure.Host;
		PathAtServer = URIStructure.PathAtServer;
		Port = URIStructure.Port;
		
		If Lower(URIStructure.Schema) = Lower("https") Then
			SecureConnection = CommonClientServer.NewSecureConnection(
				, New OSCertificationAuthorityCertificates);
		Else
			SecureConnection = Undefined;
		EndIf;
		
		SetSafeModeDisabled(True);
		Join = New HTTPConnection(
			Host,
			Port,
			,
			,
			GetFilesFromInternet.GetProxy(URIStructure.Schema),
			,
			SecureConnection);
		SetSafeModeDisabled(False);
			
		InformationAboutInformationSecurityForIntegration = InformationAboutInformationSecurityForIntegration();
		
		QueryData = New Structure;
		QueryData.Insert("method_name", MethodName);
		QueryData.Insert("users_data", UserData_);
		QueryData.Insert("ibid", InformationAboutInformationSecurityForIntegration.InformationSecurityID);
		QueryData.Insert("register_code", WUSPRegistrationCode());
		
		JSONWriter = New JSONWriter;
		JSONWriter.SetString();
		WriteJSON(JSONWriter, QueryData);
		
		QueryString = JSONWriter.Close();
		
		Headers = New Map;
		Headers.Insert("Content-Type", "application/json; charset=utf-8");
		Headers.Insert("Accept", "application/json");
		
		Query = New HTTPRequest(PathAtServer, Headers);
		Query.SetBodyFromString(QueryString);
		
		Response = Join.Post(Query);
		
		If Response.StatusCode <> 200 Then
			ErrorText = StrTemplate(NStr("vi = 'Lỗi %1';
										|ru = 'Ошибка %1';
										|en = 'Error %1'; fa = 'Error %1';
										|it = 'Errore %1';
										|pl = 'Błąd %1';
										|tr = '%1 hatası'", Common.DefaultLanguageCode()), String(Response.StatusCode));
			Result.MessageText = ErrorText;
			Return Result;
		EndIf;
		
		JSONReader = New JSONReader;
		
		ResponseBodyString = Response.GetBodyAsString();
		JSONReader.SetString(ResponseBodyString);
		
		Try
			ResponseData = ReadJSON(JSONReader, False);	
		Except
			
			WriteLogEvent(
				StrTemplate(
					"%1.%2", 
					GetEventNameForLog(), 
					NStr("vi = 'Kiểm tra mã người sử dụng';
						|ru = 'Проверка кода пользователя';
						|en = 'Check user code'; fa = 'Check user code';
						|it = 'Verifica del codice utente';
						|pl = 'Sprawdzenie kodu użytkownika';
						|tr = 'Kullanıcı kodu kontrolü'", Common.DefaultLanguageCode())),
				EventLogLevel.Error,
				,
				,
				ResponseBodyString);
			
			Result.MessageText = ResponseBodyString;
			
			Return Result;
		EndTry;
		
		If Not ResponseData.success Then
			
			WriteLogEvent(
				StrTemplate(
					"%1.%2", 
					GetEventNameForLog(), 
					NStr("vi = 'Kiểm tra mã người sử dụng';
						|ru = 'Проверка кода пользователя';
						|en = 'Check user code'; fa = 'Check user code';
						|it = 'Verifica del codice utente';
						|pl = 'Sprawdzenie kodu użytkownika';
						|tr = 'Kullanıcı kodu kontrolü'", Common.DefaultLanguageCode())),
				EventLogLevel.Error,
				,
				,
				ResponseData.response_text);
			
			Result.MessageText = ResponseData.response_text;
			
			Return Result;
			
		EndIf;
		
		Result.RequestSent = True;
		
		If ResponseData.Property("request_id") Then
			Result.QueryID = ResponseData.request_id;
		EndIf;
		
		If ResponseData.Property("captcha")
			And ResponseData.captcha Then
			Result.ThereIsPageWithProtection = True;
		Else
			Result.ThereIsPageWithProtection = False;
		EndIf;
		
		If ResponseData.Property("letters_sent_count") Then
			Result.SentEmailsCount = ResponseData.letters_sent_count;
		EndIf;
		
		If ResponseData.Property("no_abonent_users") Then
			Result.SubscriberHasNoUserAddress = ResponseData.no_abonent_users;
		EndIf;
		
	Except
		
		ErrorInfo = ErrorInfo();
		
		WriteLogEvent(
			StrTemplate(
				"%1.%2", 
				GetEventNameForLog(), 
				NStr("vi = 'Kiểm tra mã người sử dụng';
					|ru = 'Проверка кода пользователя';
					|en = 'Check user code'; fa = 'Check user code';
					|it = 'Verifica del codice utente';
					|pl = 'Sprawdzenie kodu użytkownika';
					|tr = 'Kullanıcı kodu kontrolü'", Common.DefaultLanguageCode())),
			EventLogLevel.Error,
			,
			,
			DetailErrorDescription(ErrorInfo));
		
		Result.MessageText = InformationCenterInternal.DetailedErrorText(ErrorInfo);
		
		Return Result;
		
	EndTry;
	
	Return Result;
	
EndFunction

Function DecryptTokenForRegistrationInSupportService(Token) Export
	
	Result = New Structure;
	Result.Insert("MessageText", "");
	Result.Insert("Deciphered", False);
	Result.Insert("Data", Undefined);
	
	Try
	
		BinaryData = base64UrlDecode(Token);
		
		DataReader = New DataReader(BinaryData);
		ReadingResult = "";
		While Not DataReader.ReadCompleted Do
			ReadLine_ = DataReader.ReadLine();
			ReadingResult = ReadingResult + ReadLine_ + Chars.LF;
		EndDo;
		DataReader.Close();
		
		StructureOfData = StructureFromJSONString(ReadingResult);
		
		Result.Data = StructureOfData;
		Result.Deciphered = True;
	
	Except
		
		ErrorInfo = ErrorInfo();
		Result.MessageText = CloudTechnology.ShortErrorText(ErrorInfo);
		
		Return Result;
		
	EndTry;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Private

// The address of the InformationCenterIntegrationProtected web service of the support service
// 
// Returns:
//  String - Address
//
// @unavailable-in-safemode
Function AddressOfAnonymousIntegrationServiceWithUSPInformationCenter()
	
	SetPrivilegedMode(True);
	Owner = Common.MetadataObjectID("DataProcessor.InformationCenter");
	Address = Common.ReadDataFromSecureStorage(
		Owner, "AddressOfAnonymousIntegrationServiceWithUSPInformationCenter");
	SetPrivilegedMode(False);
	
	If Address = Undefined Then
		Return "";
	EndIf;
	
	Return Address;
	
EndFunction

// Returns the namespace for the XDTO package " InformationReferences"
//
// Returns:
//	String - namespace.
//
Function NamespaceOfInformationalLinks()
	
	Return "http://www.1c.ru/SaaS/1.0/XMLSchema/ManageInfoCenter/InformationReferences";
	
EndFunction

// Returns the namespace for the XDTO package " InformationReferences_1_0_1_1"
//
// Returns:
//	String - namespace.
//
Function NamespaceOfInformationalLinks_1_0_1_1()
	
	Return "http://www.1c.ru/1cFresh/InformationCenter/InformationReferences/1.0.1.1";
	
EndFunction

// Forms elements of the informational links form in the group.
//
// Parameters:
//	Form - ClientApplicationForm - Form Context:
//  * InformationReferences - ValueList - values of informational links.
//	RefsTable - See InformationCenterServerCached.InformationReferences
//	FormGroup - FormGroup - group of the form where informational links are displayed.
//	GroupCount - Number - the number of information link groups in the form.
//	NumberOfLinksInGroup - Number - the number of informational links in the group.
//	DisplayAllLink - Boolean - whether or not to display the "All" link.
//
Procedure FormOutputGroups(Form, RefsTable, FormGroup, GroupCount, NumberOfLinksInGroup, 
	DisplayAllLink)
	
	RefsCount = ?(RefsTable.Count() > GroupCount * NumberOfLinksInGroup, 
		GroupCount * NumberOfLinksInGroup, RefsTable.Count());
	
	GroupCount = ?(RefsCount < GroupCount, RefsCount, GroupCount);
	
	IncompleteGroupName = "InformationReferencesGroup";
	
	For Iteration = 1 To GroupCount Do 
		
		FormItemName = IncompleteGroupName + String(Iteration);
		ParentGroup2 = Form.Items.Add(FormItemName, Type("FormGroup"), FormGroup);
		ParentGroup2.Type = FormGroupType.UsualGroup;
		ParentGroup2.ShowTitle = False;
		ParentGroup2.Group = ChildFormItemsGroup.Vertical;
		ParentGroup2.Representation = UsualGroupRepresentation.None;
		
	EndDo;
	
	For Iteration = 1 To RefsCount Do 
		
		GroupLinks = GetGroupOfLinks(Form, GroupCount, IncompleteGroupName, Iteration);
		
		RefData = RefsTable.Get(Iteration - 1);
		RefName = RefData.Description;
		Address = RefData.Address;
		
		LinkElement = 
			Form.Items.Add("LinkElement" + String(Iteration), Type("FormDecoration"), GroupLinks);
		LinkElement.Type = FormDecorationType.Label;
		LinkElement.Title = RefName;
		LinkElement.AutoMaxWidth = False;
		LinkElement.Height = 1;
		DataProcessors.InformationCenter.SetHyperlinkAttribute(LinkElement);
		LinkElement.SetAction("Click", "Attachable_ClickingOnInformationLink");
		
		Form.InformationReferences.Add(LinkElement.Name, Address);
		
	EndDo;
	
	If DisplayAllLink Then
		Item = Form.Items.Add("LinkAllInformationalLinks", Type("FormDecoration"), FormGroup);
		Item.Type = FormDecorationType.Label;
		Item.Title = NStr("vi = 'Tất cả';
							|ru = 'Все';
							|en = 'All'; fa = 'همه';
							|it = 'Tutti';
							|pl = 'All';
							|tr = 'Tümü'");
		Item.Hyperlink = True;
		Item.TextColor = WebColors.Black;
		Item.HorizontalAlign = ItemHorizontalLocation.Right;
		Item.SetAction("Click", "Attachable_ClickingOnAllInfoLinksLink")
	EndIf;
	
EndProcedure

// Fills in the form elements.
//
// Parameters:
//  Form - ClientApplicationForm - Form:
//  * InformationReferences - ValueList - values of informational links.
//  RefsTable - ValueTable - reference table.
//  Array of elements - Array-array of form elements.
//  AllLinksElement - FormDecoration -  the "All" label.
//
Procedure FillInformationLinks(Form, ItemArray, RefsTable, AllLinksElement)
	
	For Iteration = 0 To ItemArray.Count() -1 Do
		
		RefData = RefsTable.Get(Iteration);
		
		LinkElement = ItemArray.Get(Iteration);
		LinkElement.Title = RefData.Description;
		DataProcessors.InformationCenter.SetHyperlinkAttribute(LinkElement);
		LinkElement.ToolTip = RefData.ToolTip;
		
		Form.InformationReferences.Add(LinkElement.Name, RefData.Address);
		
	EndDo;
	
EndProcedure

// Returns the group in which you want to display information links.
//
// Parameters:
//	Form - ClientApplicationForm - the form context.
//	GroupCount - Number - the number of groups with information links on the form.
//	IncompleteGroupName - String - incomplete name of the group.
//	CurrentIteration - Number - the current iteration is.
//
// Returns:
//	FormGroup - a group of informational links or indefinite.
//
Function GetGroupOfLinks(Form, GroupCount, IncompleteGroupName, CurrentIteration)
	
	GroupName = "";
	
	For IteratingGroups = 1 To GroupCount Do
		
		If CurrentIteration % IteratingGroups  = 0 Then 
			GroupName = IncompleteGroupName + String(IteratingGroups);
		EndIf;
		
	EndDo;
	
	Return Form.Items.Find(GroupName);
	
EndFunction

Procedure DetermineConnectionStateInBackground(Parameters, ResultAddress) Export
	
	USPAddress = AddressOfExternalAnonymousInterface();
	
	Result = New Structure;
	Result.Insert("Success", True);
	Result.Insert("MessageText", "");
	
	ServiceAddress = USPAddress + "/version";
	
	Try
		
		URIStructure = CommonClientServer.URIStructure(ServiceAddress);
		Host = URIStructure.Host;
		PathAtServer = URIStructure.PathAtServer;
		Port = URIStructure.Port;
		
		If Lower(URIStructure.Schema) = Lower("https") Then
			SecureConnection = CommonClientServer.NewSecureConnection(
				, New OSCertificationAuthorityCertificates);
		Else
			SecureConnection = Undefined;
		EndIf;
		
		SetSafeModeDisabled(True);
		Join = New HTTPConnection(
			Host,
			Port,
			,
			,
			GetFilesFromInternet.GetProxy(URIStructure.Schema),
			,
			SecureConnection);
		
		Query = New HTTPRequest(PathAtServer);
		Response = Join.Get(Query);
		SetSafeModeDisabled(False);
		
		If Response.StatusCode <> 200 Then
			ErrorText = StrTemplate(NStr("vi = 'Lỗi %1';
										|ru = 'Ошибка %1';
										|en = 'Error %1'; fa = 'Error %1';
										|it = 'Errore %1';
										|pl = 'Błąd %1';
										|tr = '%1 hatası'", Common.DefaultLanguageCode()), String(Response.StatusCode));
			Result.MessageText = ErrorText;
			Result.Success = False;
		EndIf;
		
	Except
		
		ErrorInfo = ErrorInfo();
		
		WriteLogEvent(
			StrTemplate(
				"%1.%2", 
				GetEventNameForLog(), 
				NStr("vi = 'Kiểm tra mã người sử dụng';
					|ru = 'Проверка кода пользователя';
					|en = 'Check user code'; fa = 'Check user code';
					|it = 'Verifica del codice utente';
					|pl = 'Sprawdzenie kodu użytkownika';
					|tr = 'Kullanıcı kodu kontrolü'", Common.DefaultLanguageCode())),
			EventLogLevel.Error,
			,
			,
			DetailErrorDescription(ErrorInfo));
		
		Result.MessageText = InformationCenterInternal.ShortErrorText(ErrorInfo);
		Result.Success = False;
		
	EndTry;
	
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

Function base64UrlDecode(Val String)
	
	While StrLen(String) % 4 <> 0 Do
		String = String + "=";
	EndDo;
	
	String = StrReplace(String, "-", "+");
	String = StrReplace(String, "_", "/");
	
	Return Base64Value(String);
	
EndFunction

Function StructureFromJSONString(String, DateTypeProperties = Undefined)
    
	JSONReader = New JSONReader;
    JSONReader.SetString(String);
    Response = ReadJSON(JSONReader,, DateTypeProperties, JSONDateFormat.ISO); 
    Return Response
    
EndFunction

#EndRegion
