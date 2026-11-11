// 1. Place Attributes in the object:
//	1.1. Status - Listing Link - Defining the list of Statuses of the document
//	1.2. Author - Reference link.Users are the author of the document
//	1.3. Contractor- Reference Link.Users - The current executor of the document
//	1.4. Comment - Line - The current comment in the document
//	1.5. Protocol - Tabular part - See the example in the document "Application Support"
//	
// 2. In the object module, in the "Before recording" event, call the "Work" of the Document Protocol.Before recording"
//
// 3. In the form of an object:
//	3.1. Call the method "Worksprotocol.Fill in the Data forms" from the events "Registration in the Server", "Registration in the Server", "Post-recording in the Server"
//	3.2. Add the Attribute of the form "Submission of the Executor" - a formatted string displayed on the form with the processing of the navigation link
//		that calls the method "WorkinGProtocolomDocumentaClient.processnavigationnavigationnavigationnavigationnavigationnavigationnavigationnavigationnavigation
//	3.3. Add Attributes of the "Status Submission" form - similar to "Executor Submission".
//	3.4. Add the "Plug-in" method_When changing the protocol protocol", which will be called when the protocol Attributes are changed:
//		Plug-in Procedure_When changing the protocol (description of changes, additional parameters = Undefined) Export
//		End of the procedure

// 4. In the enumeration specified in the Status of the object, describe the methods:
//	4.1. This is the final status of the document (Status). Example:
//		Checks that the Status value completes the process of working with the document
//		// 
//		
//		Parameters:
//		// 
//		Status - Listing link.The transfer name is the Status being checked
//		
//		Return value:
//		
//			Boolean - True if the Status value is included in the list of final Statuses of the enumeration
//		
//		The function is the End Document status(Status) Export
//
//	Returns the final statuses().Find(Status) <> Undefined;
//		The
//		end of Function 4.2 // Fill in the available Status route. Example:
//		Parameters:
//			Form - Clientapplication Form - Protocol Owner
//					Procedure to fill in the available Route statuses (Form) Export
//					Worksprotocolomdocument.Add an accessible Route(
//					Form,
//					When
//					agreeing,
//		filling out, or using the NStr("ru = 'Submit for execution'"),
// "Manager");
// End of the procedure

#Region Internal

#Region EventHandlers

// Event handler for "Navigational Link processing" for protocol fields.
// 
// Parameters:
//  OwnerForm - ClientApplicationForm - Owner of the protocol.
//  ProtocolNavigationLink - String - The value of the navigation link from the protocol fields
//  StandardProcessing - Boolean - The returned parameter. Disables standard processing in the source event
Procedure ProcessProtocolNavigationLink(OwnerForm, ProtocolNavigationLink, StandardProcessing = False) Export
	
	StandardProcessing = False;
		
	If ProtocolNavigationLink = "OpenProtocol" Then
		
		OpenProtocol(OwnerForm);
		Return;
		
	EndIf;
	
	// Adding a new line in one of the ways:
	Object = OwnerForm.Object;
	
	OpeningParameters = ProtocolLineOpeningParameters();
	OperationsWithDocumentProtocolClientServer.FillInProtocolPropertiesFromObject(OpeningParameters.ProtocolData, Object);
	OpeningParameters.DocumentAuthor_ = Object.Author;
	OpeningParameters.ProtocolData.Comment = ""; // We do not set the value (we clear it after filling in from the object).
	If ProtocolNavigationLink = OperationsWithDocumentProtocolClientServer.ValueOfRedirectCommand() Then
		
		// 1. The Status does not change, is not displayed. The Form opens to install a new artist.
		OpeningParameters.Title = NStr("ru = 'Перенаправление документа';
										|vi = 'Forward the document';
										|en = 'Forward the document'; fa = 'Forward the document';
										|it = 'Forward the document';
										|pl = 'Forward the document';
										|tr = 'Belgenin yönlendirilmesi'");
		
	ElsIf ProtocolNavigationLink = "ChangeStatus_" Then
		
		// 2. The Status can be selected from the available values. 
		OpeningParameters.Title = NStr("ru = 'Изменение статуса документа';
										|vi = 'Change the document status';
										|en = 'Change the document status'; fa = 'Change the document status';
										|it = 'Change the document status';
										|pl = 'Change the document status';
										|tr = 'Belge durumunun değişmesi'");
		OpeningParameters.ToChangeStatus = True;
		
	Else
		
		// 3. The transition through the "assistant" is performed. The Status and artist values are determined automatically:
		SetStatus_ = PredefinedValue(ProtocolNavigationLink);
		PerformerBeingInstalled = IdentifyPerformerOnRoute(OwnerForm, SetStatus_);
		
		OpeningParameters.ProtocolData.Status = SetStatus_;
		OpeningParameters.ProtocolData.Performer = PerformerBeingInstalled;
		
		OpeningParameters.Title = StrTemplate(NStr("vi = 'Đặt trạng thái ""%1""';
													|ru = 'Установка статуса ""%1""';
													|en = 'Set the ""%1"" status'; fa = 'Set the ""%1"" status';
													|it = 'Impostazione stato ""%1""';
													|pl = 'Ustawienie statusu ""%1""';
													|tr = '""%1"" durumunun yapılandırılması'"), SetStatus_);
		
	EndIf;
	
	NotificationParameters = New Structure();
	NotificationParameters.Insert("OwnerForm", OwnerForm);
	CallbackDescription = New CallbackDescription("Attachable_BeforeAddingProtocolString", ThisObject, NotificationParameters);
	
	OpenProtocolLine(OwnerForm, OpeningParameters, CallbackDescription);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region ProtocolString

// Parameters for opening the protocol line Form.
// 
// Returns:
//  Structure - Form Opening parameters:
// * ProtocolData - See OperationsWithDocumentProtocolClientServer.StructureOfProtocolString.
// * Title - String - Title of the Form to open.
// * IsNewRecord - Boolean - Hides immutable protocol fields.
// * EnableEdit - Boolean - It is possible to edit changeable protocol fields.
// * ToChangeStatus - Boolean - If false, it hides the Status for a new line or prohibits editing for an existing one
// * DocumentAuthor_ - CatalogRef.Users - The author of the document is the owner of the protocol.
Function ProtocolLineOpeningParameters() Export
	
	ReturnValue = New Structure;
	ReturnValue.Insert("Title",               NStr("ru = 'Строка протокола';
													|vi = 'Protocol line';
													|en = 'Protocol line'; fa = 'Protocol line';
													|it = 'Protocol line';
													|pl = 'Protocol line';
													|tr = 'Protokol satırı'"));
	ReturnValue.Insert("IsNewRecord",          True);
	ReturnValue.Insert("EnableEdit", True);
	ReturnValue.Insert("ToChangeStatus",          False);
	
	ReturnValue.Insert("DocumentAuthor_", UsersClient.AuthorizedUser());
	
	ReturnValue.Insert("ProtocolData", OperationsWithDocumentProtocolClientServer.StructureOfProtocolString());
	
	Return ReturnValue;
	
EndFunction

Procedure OpenProtocolLine(OwnerForm, OpeningParameters, CallbackDescription) Export
		
	OpenForm("CommonForm.DocumentProtocolLine",
		OpeningParameters,
		OwnerForm,,,,
		CallbackDescription);
	
EndProcedure

Procedure Attachable_BeforeAddingProtocolString(ProtocolData, NotificationParameters) Export
	
	If Not ValueIsFilled(ProtocolData) Then
		// Refusal to add a protocol line in the form.
		Return;
	EndIf;
	
	OwnerForm = NotificationParameters.OwnerForm;
	Object = OwnerForm.Object;
	
	Initial_State = OperationsWithDocumentProtocolClientServer.ModifiableProtocolProperties();
	OperationsWithDocumentProtocolClientServer.FillInProtocolPropertiesFromObject(Initial_State, Object);
	
	If Not OperationsWithDocumentProtocolClientServer.ProtocolPropertiesHaveChanged(ProtocolData, Initial_State, True) Then
		Return;
	EndIf;
	
	NewLineOfProtocol(Object.Protocol, ProtocolData);
	UpdateProtocolData(OwnerForm);
	
EndProcedure

// Adds a new line to the document protocol
// 
// Parameters:
//  Protocol - FormDataCollection - To which a new line will be added
//  ProtocolData - See OperationsWithDocumentProtocolClientServer.ModifiableProtocolProperties 
// 
// Returns:
//  FormDataCollectionItem - New Line Of The Protocol
Function NewLineOfProtocol(Protocol, ProtocolData) Export
	
	RowData = OperationsWithDocumentProtocolClientServer.StructureOfProtocolString();
	FillPropertyValues(RowData, ProtocolData);
	RowData.Author = UsersClient.CurrentUser();
	RowData.Date = CommonClient.SessionDate();
	
	Return OperationsWithDocumentProtocolClientServer.NewLineOfProtocol(Protocol, RowData);
	
EndFunction

#EndRegion

#Region Protocol

Procedure OpenProtocol(OwnerForm)
	
	Object = OwnerForm.Object;
	ProtocolData = OperationsWithDocumentProtocolClientServer.StructureOfProtocolString();
	OperationsWithDocumentProtocolClientServer.FillInProtocolPropertiesFromObject(ProtocolData, Object);
	
	OpeningParameters = New Structure;
	
	OpeningParameters.Insert("ProtocolData",         ProtocolData); // The table may still be empty.
	OpeningParameters.Insert("Protocol",                OperationsWithDocumentProtocolClient.ProtocolToArray(OwnerForm.Object.Protocol));
	OpeningParameters.Insert("EnableEdit", Not OwnerForm.ReadOnly); // Including access rights.
	OpeningParameters.Insert("DocumentAuthor_",          Object.Author);
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("OwnerForm", OwnerForm);
	
	CallbackDescription = New CallbackDescription("Attachable_BeforeChangingProtocol", ThisObject, NotificationParameters);
	OpenForm("CommonForm.DocumentProtocol", OpeningParameters, OwnerForm,,,, CallbackDescription);
	
EndProcedure

Procedure Attachable_BeforeChangingProtocol(Protocol, NotificationParameters) Export
	
	If Not ValueIsFilled(Protocol) Then
		Return;
	EndIf;
	
	OwnerForm = NotificationParameters.OwnerForm;
	Object = OwnerForm.Object;
	
	Object.Protocol.Clear();
	For Each ProtocolString In Protocol Do
		FillPropertyValues(Object.Protocol.Add(), ProtocolString);
	EndDo;
	
	UpdateProtocolData(OwnerForm);

EndProcedure

#EndRegion

#Region OwnerNotification

// Sets the values of the object Attributes from the last line of the protocol.
// Updates the Form data.
// Calls the Form change handler.
// 
// Parameters:
//  OwnerForm - ClientApplicationForm
Procedure UpdateProtocolData(OwnerForm)
	
	Object = OwnerForm.Object;
	
	NewState = OperationsWithDocumentProtocolClientServer.ModifiableProtocolProperties();
	LastRow = OperationsWithDocumentProtocolClientServer.LastLineOfProtocol(Object.Protocol);
	FillPropertyValues(NewState, LastRow);
	
	Initial_State = OperationsWithDocumentProtocolClientServer.ModifiableProtocolProperties();
	OperationsWithDocumentProtocolClientServer.FillInProtocolPropertiesFromObject(Initial_State, Object);
	
	ChangedProperties = OperationsWithDocumentProtocolClientServer.ChangedProtocolProperties(NewState, Initial_State);
	
	OwnerForm.Modified = True;
	FillInObjectPropertiesFromProtocol(Object, NewState);
	OperationsWithDocumentProtocolClientServer.FillInFormDataAccordingToProtocol(OwnerForm);
	
	OwnerNotificationParameters = New Structure;
	OwnerNotificationParameters.Insert("Initial_State",  Initial_State);
	OwnerNotificationParameters.Insert("NewState",     NewState);
	OwnerNotificationParameters.Insert("ChangedProperties", ChangedProperties);
	
	MethodName = "Attachable_ONChangeOfProtocol";
	NotificationProcessing = New CallbackDescription(MethodName, OwnerForm);
	RunCallback(NotificationProcessing, OwnerNotificationParameters);
	
EndProcedure

#EndRegion

#Region DataOperations

// Determines the performer along the route (initial Status --> set Status) based on the described settings
// 
// Parameters:
//  Form - ClientApplicationForm - Form-protocol owner
//  SetStatus_ - EnumRef - Set Status
// 
// Returns:
//  CatalogRef.Users - The default performer for the Status to be set
Function IdentifyPerformerOnRoute(Form, SetStatus_)
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("InitialStatus", Form.Object.Status);
	FilterStructure1.Insert("SetStatus_", SetStatus_);
	RoutesFound = Form.AvailableStatusesRoutes.FindRows(FilterStructure1);
	
	If RoutesFound.Count() <> 1 Then
		ErrorText = NStr("ru = 'Не удалось определить исполнителя по умолчанию для установки статуса ""%1""
		|Обратитесь к администратору: Неправильно определен набор доступных статусов в модуле менеджера перечисления.';
		|vi = 'Cannot identify the default assignee to set the ""%1"" status.
		|Contact the administrator: The set of available statuses in the enumeration manager module is defined incorrectly.';
		|en = 'Cannot identify the default assignee to set the ""%1"" status.
		|Contact the administrator: The set of available statuses in the enumeration manager module is defined incorrectly.'; fa = 'Cannot identify the default assignee to set the ""%1"" status.
		|Contact the administrator: The set of available statuses in the enumeration manager module is defined incorrectly.';
		|it = 'Cannot identify the default assignee to set the ""%1"" status.
		|Contact the administrator: The set of available statuses in the enumeration manager module is defined incorrectly.';
		|pl = 'Cannot identify the default assignee to set the ""%1"" status.
		|Contact the administrator: The set of available statuses in the enumeration manager module is defined incorrectly.';
		|tr = '""%1"" statüsünü ayarlamak için varsayılan sorumlu belirlenemedi.
		|Yöneticiye başvurun: Numaralandırma yöneticisi modülünde kullanılabilir statü kümesi yanlış tanımlanmış.'");
		Raise ErrorText;
	EndIf;
	
	NameOfPerformerSAttributes = RoutesFound[0].NameOfPerformerSAttributes;
	
	If IsBlankString(NameOfPerformerSAttributes) Then
		ReturnValue = Form.Object.Performer;
	Else
		ReturnValue = Form.Object[NameOfPerformerSAttributes];
	EndIf;
	
	Return ReturnValue;
	
EndFunction

// Converts the protocol Form table into an array for Transferring between Forms on the client
// Parameters:
//  Protocol - FormDataCollection - The protocol being converted
// 
// Returns:
//  Array 
Function ProtocolToArray(Protocol) Export
	
	ReturnValue = New Array;
	
	For Each InitialString In Protocol Do
		
		ProtocolString = OperationsWithDocumentProtocolClientServer.StructureOfProtocolString();
		FillPropertyValues(ProtocolString, InitialString);
		ReturnValue.Add(ProtocolString);
		
	EndDo;
	
	Return ReturnValue;
	
EndFunction

Procedure FillInObjectPropertiesFromProtocol(Object, ProtocolData)
	
	FillPropertyValues(Object, ProtocolData);
	
EndProcedure

#EndRegion

#EndRegion