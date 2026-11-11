#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	DataProcessorObject = FormAttributeToValue("Object");
	DataProcessorObjectName = DataProcessorObject.Metadata().FullName();
	
	SetPrivilegedMode(True);
	CanConnectToCollaborationSystemSaaS = IntegrationWithCollaborationSystem.CanConnectToCollaborationSystemSaaS();
	IntegrationWithCollaborationSystemUsedSaaS = IntegrationWithCollaborationSystem.IntegrationWithCollaborationSystemUsedSaaS();
	SetPrivilegedMode(False);
	
	RegistrationMethods = New Array;
	RegistrationMethods.Add(RegistrationMethodWithoutService());
	If Not CanConnectToCollaborationSystemSaaS Then
		RegistrationMethods.Add(MethodOfRegistrationThroughService());
		ReadManagementDataFromStorage();
	ElsIf IntegrationWithCollaborationSystemUsedSaaS Then
		RegistrationMethods.Add(MethodOfRegistrationThroughServiceInCloud());
	EndIf;
	
	Items.RegistrationMethod.ChoiceList.Clear();
	For Each Method In RegistrationMethods Do
		Items.RegistrationMethod.ChoiceList.Add(Method.Value, Method.Description);
	EndDo;
	
	RegistrationMethod = RegistrationMethods[0].Value;
	
	If RegistrationMethods.Count() = 1 Then
		Items.RegistrationMethod.Visible = False;
	EndIf;
	
	If InfoBaseUsers.CurrentUser().Name = "" Then
		Cancel = True;
		Return;
	EndIf;
	
	If Not AccessRight("CollaborationSystemInfoBaseRegistration", Metadata) Then
		Cancel = True;
		Return;
	EndIf;
	
	ServerAddress = "wss://1cdialog.com:443";
	BaseName = Metadata.Synonym;
	If BaseName = "" Then
		BaseName = Metadata.BriefInformation;
	EndIf;
	
	BaseRegistered = CollaborationSystem.InfoBaseRegistered();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Not BaseRegistered Then
		OpenRegistrationPage();
	Else
		GoToTrafficPage();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure RegistrationMethodOnChange(Item)
	
	WhenChangingRegistrationMethod();
	
EndProcedure

&AtClient
Procedure BaseNameOnChange(Item)
	
	SetAvailabilityOfRegistrationButtons();
	
EndProcedure

&AtClient
Procedure RegistrationCodeOnChange(Item)
	
	SetAvailabilityOfRegistrationButtons();
	
EndProcedure

&AtClient
Procedure BaseNameEditTextChange(Item, Text, StandardProcessing)
	
	SetAvailabilityOfRegistrationButtons();
	
EndProcedure

&AtClient
Procedure DataToManageOnChange(Item)
	
	DecryptedDataForManagement = DecryptDataForManagementOnServer(DataToManage);
	If Not DecryptedDataForManagement.Deciphered Then
		MessageText = StrTemplate(
			NStr("vi = 'Dữ liệu đã nhập không chính xác: %1';
				|ru = 'Введенные данные не верны: %1';
				|en = 'Entered data is incorrect: %1'; fa = 'Entered data is incorrect: %1';
				|it = 'Dati inseriti non sono corretti: %1';
				|pl = 'Wprowadzone dane nie są poprawne: %1';
				|tr = 'Girilen veriler hatalı: %1'"), 
			DecryptedDataForManagement.MessageText);
		CommonClient.MessageToUser(MessageText);
	Else
		ManagementServicePublicationURL = DecryptedDataForManagement.Data.ManagementServicePublicationURL;
		URIStructure = CommonClientServer.URIStructure(ManagementServicePublicationURL);
		ServiceManagerURL = URIStructure.Host;
		ControlCode = DecryptedDataForManagement.Data.ControlCode;
	EndIf;
	
	SetAvailabilityOfRegistrationButtons();
	
EndProcedure

&AtClient
Procedure SubscriberEmailOnChange(Item)
	
	SetAvailabilityOfRegistrationButtons();
	
EndProcedure

&AtClient
Procedure RegistrationCodeEditTextChange(Item, Text, StandardProcessing)
	
	SetAvailabilityOfRegistrationButtons();
	
EndProcedure

&AtClient
Procedure SubscriberEmailEditTextChange(Item, Text, StandardProcessing)
	
	SetAvailabilityOfRegistrationButtons();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersMappingTable

&AtClient
Procedure MappingTableSaaSUserStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	InitialValue = Undefined;
	
	UsersList = New ValueList;
	For Each TableRow In ServiceUsers Do
		
		ThereIsMapping = False;
		For Each MappingString In MappingTable Do
			
			If MappingString.SaaSUser = TableRow.UserName
				And ValueIsFilled(MappingString.IBUser) Then
				ThereIsMapping = True;
				Break;
			EndIf;
			
		EndDo;
		
		If ThereIsMapping Then
			Continue;
		EndIf;
		
		UsersList.Add(TableRow, TableRow.Description);
		
	EndDo;
	
	Notification = New CallbackDescription("ChoosingServiceUser", ThisObject);
	ShowChooseFromList(Notification, UsersList, Item, InitialValue);
	
EndProcedure

&AtClient
Procedure MappingTableSaaSUserClearing(Item, StandardProcessing)
	
	Items.MappingTable.CurrentData.MatchingKey = "";
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersApplicationsLinks

&AtClient
Procedure ApplicationsLinksSelection(Item, RowSelected, Field, StandardProcessing)
	
	EditLink();
	
EndProcedure

&AtClient
Procedure ApplicationsLinksBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	EditLink();
	
EndProcedure

&AtClient
Procedure ApplicationsLinksBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	LinkFormName = StrTemplate("%1.Form.ApplicationsLinkForm", DataProcessorObjectName);
	Notification = New CallbackDescription("ApplicationCommunicationFormClosed", ThisObject);
	FormOfCommunication = OpenForm(LinkFormName, , , , , , Notification);
	FormOfCommunication.Open();
	
EndProcedure

&AtClient
Procedure ApplicationsLinksBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	Notification = New CallbackDescription("ConfirmationOfCommunicationBreak", ThisObject);
	
	ShowQueryBox(Notification, NStr("vi = 'Hủy bỏ sử dụng chung?';
									|ru = 'Отменить совместное использование?';
									|en = 'Do you want to cancel sharing?'; fa = 'Do you want to cancel sharing?';
									|it = 'Annullare utilizzo condiviso?';
									|pl = 'Anulować wspólne używanie?';
									|tr = 'Ortak kullanım iptal edilsin mi?'"), QuestionDialogMode.YesNo, , 
		DialogReturnCode.No);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure GoToApplicationsLinks(Command)
	
	Title = NStr("vi = 'Sử dụng chung các ứng dụng trong hệ thống giao tiếp';
				|ru = 'Совместное использование приложений системы взаимодействия';
				|en = 'Share collaboration system applications'; fa = 'Share collaboration system applications';
				|it = 'Utilizzo condiviso delle applicazioni del sistema di interazione';
				|pl = 'Wspólne używanie aplikacji systemu interakcji';
				|tr = 'Ortak Çalışma Sistemi uygulamalarını ortak kullanma'");
	FillInApplicationLinks();
	Items.Pages.CurrentPage = Items.ApplicationsLinksPage;
	
EndProcedure

&AtClient
Procedure GoBack(Command)
	
	DetachIdleHandler("CheckSelectedLines");
	GoToTrafficPage();
	
EndProcedure

&AtClient
Procedure UpdateUsers(Command)
	
	FillInUsers();

EndProcedure

&AtClient
Procedure GoToUsersList(Command)
	
	Title = NStr("vi = 'Người sử dụng hệ thống giao tiếp';
				|ru = 'Пользователи системы взаимодействия';
				|en = 'Collaboration system users'; fa = 'Collaboration system users';
				|it = 'Utenti del sistema di interazione';
				|pl = 'Użytkownicy systemu interakcji';
				|tr = 'Ortak Çalışma Sistemi kullanıcıları'");
	FillInUsers();
	Items.Pages.CurrentPage = Items.UsersPage1;
	AttachIdleHandler("CheckSelectedLines", 0.2, True);
	
EndProcedure

&AtClient
Procedure UnlockUser(Command)
	
	UsersArray = New Array;
	
	RowsSelected = Items.UsersTable.SelectedRows;
	For Each IDOfSelectedRow In RowsSelected Do
		String = UsersTable.FindByID(IDOfSelectedRow);
		If Not String.CurrentUser And String.IsCollaborationSystemUser <> Undefined And String.IsLocked Then
			UsersArray.Add(String.CollaborationSystemUserID);
		EndIf;
	EndDo;
	
	BlockingUserOnServer(UsersArray, False);
	SetCommandsAvailability();
	
EndProcedure

&AtClient
Procedure LockUser(Command)
	
	UsersArray = New Array;
	
	RowsSelected = Items.UsersTable.SelectedRows;
	For Each IDOfSelectedRow In RowsSelected Do
		String = UsersTable.FindByID(IDOfSelectedRow);
		If Not String.CurrentUser And String.CollaborationSystemUserID <> Undefined And Not String.IsLocked Then
			UsersArray.Add(String.CollaborationSystemUserID);
		EndIf;
	EndDo;
	
	BlockingUserOnServer(UsersArray, True);
	SetCommandsAvailability();
	
EndProcedure

&AtClient
Procedure CancelRegistration(Command)
	
	NameOfCancellationForm = StrTemplate("%1.Form.RegistrationCancellationForm", DataProcessorObjectName);
	RegistrationCancellationForm = GetForm(NameOfCancellationForm);
	RegistrationCancellationForm.Initialize(IntegrationWithCollaborationSystemUsedSaaS);
	RegistrationCancellationForm.CallbackDescriptionOnClose = New CallbackDescription("RegistrationCancellationFormClosed", ThisObject);
	RegistrationCancellationForm.Open();
	
EndProcedure

&AtClient
Procedure GoToUsersMappingPage(Command)
	
	Title = NStr("vi = 'So sánh người sử dụng dịch vụ';
				|ru = 'Сопоставление пользователей сервиса';
				|en = 'Map service users'; fa = 'Map service users';
				|it = 'Associazione utenti del servizio';
				|pl = 'Porównanie użytkowników serwisu';
				|tr = 'Servis kullanıcıların eşleştirilmesi'", "ru");
	Items.Pages.CurrentPage = Items.UsersMappingPage;
	
EndProcedure

&AtClient
Procedure Register(Command)
	
	If RegistrationMethod = RegistrationMethodWithoutService().Value Then
		
		RegistrationParameters = New CollaborationSystemInfoBaseRegistrationParameters();
		RegistrationParameters.ServerAddress = ServerAddress;
		RegistrationParameters.Email = SubscriberEmail;
		RegistrationParameters.InfoBaseName = BaseName;
		RegistrationParameters.ActivationCode = TrimAll(RegistrationCode);
		
		CallbackDescription = New CallbackDescription("ActivationCompleted", ThisObject, , "ActivationError", ThisObject);
		
		CollaborationSystem.BeginInfoBaseRegistration(CallbackDescription, RegistrationParameters);
		
		Enabled = False;
		
	ElsIf RegistrationMethod = MethodOfRegistrationThroughService().Value Then
		
		RegistrationResult = RegisterViaServiceOnServer();
		If RegistrationResult <> Undefined Then
			If RegistrationResult.Success Then
				CommonClient.MessageToUser(NStr("vi = 'Đã đăng ký thành công';
												|ru = 'Регистрация успешно выполнена';
												|en = 'Registration successfully completed'; fa = 'Registration successfully completed';
												|it = 'Registrazione eseguita con successo';
												|pl = 'Rejestracja została wykonana pomyślnie';
												|tr = 'Kayıt başarıyla tamamlandı'"));
			Else
				MessageText = NStr("vi = 'Không thể đăng ký cơ sở dữ liệu do nguyên nhân: %1';
									|ru = 'Не удалось зарегистрировать базу по причине: %1';
									|en = 'Cannot register the base due to: %1'; fa = 'Cannot register the base due to: %1';
									|it = 'Non è stato possibile registrare il database a causa di: %1';
									|pl = 'Nie udało się zarejestrować bazy z powodu: %1';
									|tr = 'Bu sebepten kayıt başarısız: %1'");
				MessageText = StrTemplate(MessageText, RegistrationResult.MessageText);
				CommonClient.MessageToUser(MessageText);
			EndIf;
		Else
			CommonClient.MessageToUser(NStr("vi = 'Hãy chỉ ra dữ liệu cần thiết';
											|ru = 'Укажите необходимые данные';
											|en = 'Specify required data'; fa = 'Specify required data';
											|it = 'Indica dati richiesti';
											|pl = 'Podaj konieczne dane';
											|tr = 'Gerekli verileri belirtin'"));
		EndIf;
		
		RefreshInterface();
		
		BaseRegistered = CollaborationSystem.InfoBaseRegistered();
		If BaseRegistered Then
			SaveDataForManagement();
			GoToTrafficPage();
		EndIf;
		
	ElsIf RegistrationMethod = MethodOfRegistrationThroughServiceInCloud().Value Then
		
		RegistrationResult = RegisterDatabaseUsingToken();
		
		If RegistrationResult <> Undefined Then
			If RegistrationResult.RegistrationCompleted Then
				CommonClient.MessageToUser(NStr("vi = 'Đã đăng ký thành công';
												|ru = 'Регистрация успешно выполнена';
												|en = 'Registration successfully completed'; fa = 'Registration successfully completed';
												|it = 'Registrazione eseguita con successo';
												|pl = 'Rejestracja została wykonana pomyślnie';
												|tr = 'Kayıt başarıyla tamamlandı'"));
				RefreshInterface();
				BaseRegistered = CollaborationSystem.InfoBaseRegistered();
				GoToTrafficPage();
			Else
				MessageText = StrTemplate(
					NStr("vi = 'Không thể đăng ký cơ sở dữ liệu do nguyên nhân: %1';
						|ru = 'Не удалось зарегистрировать базу по причине: %1';
						|en = 'Cannot register the base due to: %1'; fa = 'Cannot register the base due to: %1';
						|it = 'Non è stato possibile registrare il database a causa di: %1';
						|pl = 'Nie udało się zarejestrować bazy z powodu: %1';
						|tr = 'Bu sebepten kayıt başarısız: %1'"), 
					RegistrationResult.MessageText);
				CommonClient.MessageToUser(MessageText);
			EndIf;
		Else
			CommonClient.MessageToUser(NStr("vi = 'Hãy chỉ ra dữ liệu cần thiết';
											|ru = 'Укажите необходимые данные';
											|en = 'Specify required data'; fa = 'Specify required data';
											|it = 'Indica dati richiesti';
											|pl = 'Podaj konieczne dane';
											|tr = 'Gerekli verileri belirtin'"));
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GetServiceUsersInformation(Command)
	
	GetInformationAboutServiceUsersOnServer();
	
EndProcedure

&AtClient
Procedure EnterDataToManage(Command)
	
	NameOfDataEntryFormToManage = StrTemplate("%1.Form.DataToManageEntryForm", DataProcessorObjectName);
	DataToManageEntryForm = GetForm(NameOfDataEntryFormToManage);
	DataToManageEntryForm.Initialize(DataToManage);
	DataToManageEntryForm.CallbackDescriptionOnClose = New CallbackDescription("DataEntryFormForManagementIsClosed", ThisObject);
	DataToManageEntryForm.Open();
	
EndProcedure

&AtClient
Procedure SaveMappingToServiceUsers(Command)
	
	SaveMappingOnServer();
	
EndProcedure

&AtClient
Procedure GetRegistrationCode(Command)
	
	RegistrationParameters = New CollaborationSystemInfoBaseRegistrationParameters();
	RegistrationParameters.ServerAddress = ServerAddress;
	RegistrationParameters.Email = SubscriberEmail;
	
	CallbackDescription = New CallbackDescription("GetRegistrationCodeCompletion", ThisObject, , "GetRegistrationCodeError", ThisObject);
	
	CollaborationSystem.BeginInfoBaseRegistration(CallbackDescription, RegistrationParameters);
	
	Enabled = False;
	
EndProcedure

&AtClient
Procedure DataProcessorHelp(Command)
	
	OpenFormHelp();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SetClickThroughVisibility()
	
	Items.GoToApplicationsLinks.Visible = BaseRegistered;
	Items.GoToUsersList.Visible = BaseRegistered;
	Items.CancelRegistration.Visible = BaseRegistered;
	Items.GoToUsersMappingPage.Visible = BaseRegistered And ValueIsFilled(DataToManage);
	
EndProcedure

&AtServer
Procedure FillInApplicationLinks()
	
	ObjectOfInteractionSystem = IntegrationWithCollaborationSystem.ObjectOfInteractionSystem();

	ApplicationsLinks.Clear();
	
	ElementsOfSharing = ObjectOfInteractionSystem.GetSubscriberApplicationLinks();
	For Each SharingElement In ElementsOfSharing Do
		
		Link = ApplicationsLinks.Add();
		
		A = 1;
		For Each AppID In SharingElement.Applications Do
			If A = 1 Then
				Link.AppID1 = AppID;
				A = 2;
			Else
				Link.AppID2 = AppID;
				Break;
			EndIf;
		EndDo;
			
		Link.Application1 = ObjectOfInteractionSystem.GetApplication(
			Link.AppID1).Description;
		Link.Application2 = ObjectOfInteractionSystem.GetApplication(
			Link.AppID2).Description;
		
		Link.UserMatching = SharingElement.UserMatching;
		If Link.UserMatching = "Name" Or Link.UserMatching = "Name" Then
			Link.UserMatching = "NAME";
			Link.UsersMappingPresentation = NStr("vi = 'Theo tên';
												|ru = 'По имени';
												|en = 'By name'; fa = 'بر اساس نام';
												|it = 'Per nome';
												|pl = 'Wg nazwy';
												|tr = 'İsme göre'");
		ElsIf Link.UserMatching = "FullName" Or Link.UserMatching = "FullName" Then
			Link.UserMatching = "FULLNAME";
			Link.UsersMappingPresentation = NStr("vi = 'Theo tên đầy đủ';
												|ru = 'По полному имени';
												|en = 'By full name'; fa = 'بر اساس نام کامل';
												|it = 'Per nome completo';
												|pl = 'Wg pełnej nazwy';
												|tr = 'Tam isme göre'");
		ElsIf Link.UserMatching = "MatchingKey" Or Link.UserMatching = "MatchingKey" Then
			Link.UserMatching = "MATCHINGKEY";
			Link.UsersMappingPresentation = NStr("vi = 'Theo khóa tương ứng';
												|ru = 'По ключу соответствия';
												|en = 'By lookup key'; fa = 'By lookup key';
												|it = 'Per chiave di associazione';
												|pl = 'Wg klucza zgodności';
												|tr = 'Eşleşen anahtara göre'");
		EndIf;
			
		Link.ContextConversationsMapping = SharingElement.ConversationContextMatching;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure CheckSelectedLines()
	
	SetCommandsAvailability();
	AttachIdleHandler("CheckSelectedLines", 0.2, True);
	
EndProcedure

&AtClient
Procedure GoToTrafficPage()
	
	SetClickThroughVisibility();
	
	Items.Pages.CurrentPage = Items.Transitions;
	Title = NStr("vi = 'Quản lý hệ thống giao tiếp';
				|ru = 'Управление системой взаимодействия';
				|en = 'Collaboration system management'; fa = 'مدیریت سیستم همکاری';
				|it = 'Gestione del sistema di interazione';
				|pl = 'Zarządzanie systemem interakcji';
				|tr = 'Ortak çalışma sisteminin yönetimi'");

EndProcedure

&AtClient
Procedure SetCommandsAvailability()
	
	LockedAttributesAvailable = False;
	ThereAreUnlocked = False;
	
	RowsSelected = Items.UsersTable.SelectedRows;
	For Each IDOfSelectedRow In RowsSelected Do
		String = UsersTable.FindByID(IDOfSelectedRow);
		If String.CurrentUser Then
			Continue;
		EndIf;
		If String.CollaborationSystemUserID <> Undefined Then
			If String.IsLocked Then
				LockedAttributesAvailable = True;
			Else
				ThereAreUnlocked = True;
			EndIf;
		EndIf;
	EndDo;
	
	Items.UsersTableUnlockUser.Enabled = LockedAttributesAvailable;
	Items.UsersContextMenuUnlockUser.Enabled = LockedAttributesAvailable;
	Items.UsersTableLockUser.Enabled = ThereAreUnlocked;
	Items.UsersContextMenuLockUser.Enabled = ThereAreUnlocked;
	
EndProcedure

&AtClient
Procedure EditLink()
	
	If Items.ApplicationsLinks.CurrentRow = Undefined Then
		Return;
	EndIf;
	
	LinkFormName = StrTemplate("%1.Form.ApplicationsLinkForm", DataProcessorObjectName);
	FormOfCommunication = GetForm(LinkFormName);
	FormOfCommunication.Initialize(Items.ApplicationsLinks.CurrentData);
	FormOfCommunication.CallbackDescriptionOnClose = New CallbackDescription("ApplicationCommunicationFormClosed", ThisObject);
	FormOfCommunication.Open();
	
EndProcedure

&AtClient
Procedure ApplicationCommunicationFormClosed(Result, AdditionalParameters) Export
	
	If Result = True Then
		FillInApplicationLinks();
	EndIf;
	
EndProcedure

&AtClient
Procedure ConfirmationOfCommunicationBreak(Result, AdditionalParameters) Export

	If Result = DialogReturnCode.Yes Then
		curData = Items.ApplicationsLinks.CurrentData;
		BreakConnectionOnServer(curData.AppID1, curData.AppID2);
	EndIf;
	
EndProcedure

&AtServer
Procedure BreakConnectionOnServer(AppID1, AppID2)
	
	ObjectOfInteractionSystem = IntegrationWithCollaborationSystem.ObjectOfInteractionSystem();
	ApplicationsIDs = New(IntegrationWithCollaborationSystem.TypeCollectionOfApplicationIds()); // CollaborationSystemApplicationIDCollection
	ApplicationsIDs.Add(AppID1);
	ApplicationsIDs.Add(AppID2);
	ObjectOfInteractionSystem.CancelSubscriberApplicationLinks(ApplicationsIDs);
	FillInApplicationLinks();

EndProcedure

&AtServer
Procedure FillInUsers()
	
	Var UserMap;
	Var CurrentUserID;
	
	SetPrivilegedMode(True);
	
	CurrentUserID = InfoBaseUsers.CurrentUser().UUID;
	
	UserMap = New Map;
	
	UsersTable.Clear();
	
	IBUsers = InfoBaseUsers.GetUsers();
	For Each IBUser In IBUsers Do
		String = UsersTable.Add();
		String.IBUserID = IBUser.UUID;
		String.UserName = IBUser.Name;
		String.FullName = IBUser.FullName;
		String.IsIBUser = True;
		String.CurrentUser = IBUser.UUID = CurrentUserID;
		
		UserMap.Insert(IBUser.UUID, String.GetID());
		
	EndDo;
	
	ObjectOfInteractionSystem = IntegrationWithCollaborationSystem.ObjectOfInteractionSystem();
	SVUsers = ObjectOfInteractionSystem.GetUsers();
	For Each CollaborationSystemUser In SVUsers Do
		
		IBUserID = CollaborationSystemUser.InfoBaseUserID;
		If IBUserID <> Undefined Then
			
			RowID = UserMap.Get(IBUserID);
			If RowID = Undefined Then
				String = UsersTable.Add();
				String.UserName = CollaborationSystemUser.Name;
				String.FullName = CollaborationSystemUser.FullName;
			Else
				String = UsersTable.FindByID(RowID);
			EndIf;
				
			String.IsCollaborationSystemUser = True;
			String.CollaborationSystemUserID = CollaborationSystemUser.ID;
			String.IsLocked = CollaborationSystemUser.IsLocked;
			
		EndIf;

	EndDo;
	
	SetPrivilegedMode(False);
	
EndProcedure

&AtServer
Procedure BlockingUserOnServer(UsersArray, ThisIsBlocking)
	
	SetPrivilegedMode(True);
	
	For Each UserIdentificator In UsersArray Do
		User = CollaborationSystem.GetUser(UserIdentificator);
		User.IsLocked = ThisIsBlocking;
		User.Write();
		
		Filter = New Structure("CollaborationSystemUserID", User.ID);
		Rows = UsersTable.FindRows(Filter);
		If Rows.Count() = 1 Then
			Rows[0].IsLocked = User.IsLocked;
		EndIf;
	EndDo;
	
	SetPrivilegedMode(False);
	
EndProcedure

&AtServer
Procedure CancelRegistrationOnServer()
	
	BaseRegistered = CollaborationSystem.InfoBaseRegistered();
	Common.DeleteDataFromSecureStorage(
		"DataForInteractionSystemManagement", 
		"DataForInteractionSystemManagement");
	DataToManage = "";
	
EndProcedure

&AtClient
Procedure RegistrationCancellationFormClosed(Result, AdditionalParameters) Export
	
	If Result = 1 Then
		CancelRegistrationOnServer();
		DataToManage = "";
		ServiceManagerURL = "";
		ControlCode = "";
		OpenRegistrationPage();
	Else
		GoToTrafficPage();
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenRegistrationPage()
	
	Items.Pages.CurrentPage = Items.RegistrationPage;
	
	WhenChangingRegistrationMethod();
	
EndProcedure

// Register the database using a token.
// @skip-warning EmptyMethod - a feature of the implementation. Overridable in the extension.
// 
// Returns:
//  Structure:
//   * RegistrationCompleted - Boolean
//   * MessageText - String
&AtServer
Function RegisterDatabaseUsingToken()
	
EndFunction

&AtClient
Procedure ActivationCompleted(Result, MessageText, AdditionalParameters) Export

	CallbackDescription = New CallbackDescription("ActivationCompletedWarning", ThisObject);
	ShowMessageBox(CallbackDescription, NStr("vi = 'Ứng dụng đã được đăng ký';
											|ru = 'Приложение зарегистрировано';
											|en = 'Application registered'; fa = 'Application registered';
											|it = 'Applicazione registrata';
											|pl = 'Aplikacja została zarejestrowana';
											|tr = 'Uygulama kayıtlı'"));
	
EndProcedure

&AtClient
Procedure ActivationCompletedWarning(AdditionalParameters) Export
	
	Enabled = True;
	RefreshInterface();
	BaseRegistered = CollaborationSystem.InfoBaseRegistered();
	If BaseRegistered Then
		GoToTrafficPage();
	EndIf;
	
EndProcedure

&AtClient
Procedure ActivationError(ErrorInfo, StandardProcessing, AdditionalParameters) Export

	StandardProcessing = False;
	ErrorProcessing.ShowErrorInfo(ErrorInfo);

	Enabled = True;
	
EndProcedure

&AtServer
Procedure SaveDataForManagement()
	
	SetPrivilegedMode(True);
	Common.WriteDataToSecureStorage("DataForInteractionSystemManagement", DataToManage, "DataForInteractionSystemManagement");
	SetPrivilegedMode(False);
	
EndProcedure

&AtServer
Function RegisterViaServiceOnServer()
	
	If Not ValueIsFilled(ServiceManagerURL) Then
		Return Undefined;
	EndIf;
	
	If Not ValueIsFilled(ControlCode) Then
		Return Undefined;
	EndIf;
	
	If Not ValueIsFilled(BaseName) Then
		Return Undefined;
	EndIf;
	
	RegistrationResult = IntegrationWithCollaborationSystem.RegisterDatabaseThroughService(ManagementServicePublicationURL, ControlCode, BaseName);
	
	ServiceUsers.Clear();
	
	If RegistrationResult.Success Then
		If RegistrationResult.ResultData <> Undefined Then
			For Each Page1 In RegistrationResult.ResultData.UserData_ Do
				NwRw = ServiceUsers.Add();
				NwRw.UserName = Page1.UserName;
				NwRw.MatchingKey = Page1.UserID;
				NwRw.Description = Page1.UserName;
			EndDo;
		EndIf;
	EndIf;
	
	FillInMappingTable();
	
	Return RegistrationResult;
	
EndFunction

&AtClientAtServerNoContext
Function MethodOfRegistrationThroughServiceInCloud()
	
	Result = New Structure;
	Result.Insert("Value", "UsingServiceInCloud");
	Result.Insert("Description", NStr("vi = 'Thông qua dịch vụ Hash';
										|ru = 'Через сервис Фреш';
										|en = 'Via Fresh service'; fa = 'Via Fresh service';
										|it = 'Tramite il servizio Fresh';
										|pl = 'Za pomocą serwisu Fresh';
										|tr = 'Fresh servisi ile'"));
	Result.Insert("ToolTip", NStr("vi = 'Sẽ cho phép sử dụng chung thảo luận trong cơ sở cục bộ và ứng dụng trong dịch vụ Hash';
									|ru = 'Будет доступно совместное использование обсуждений в локальной базе и приложениях в сервисе Фреш';
									|en = 'Sharing of conversations will be available in the local base and applications in Fresh service'; fa = 'Sharing of conversations will be available in the local base and applications in Fresh service';
									|it = 'L''utilizzo condiviso delle discussioni sarà disponibile nel database locale e nelle applicazioni del servizio Fresh';
									|pl = 'Będzie dostępne wspólne używanie dyskusji w bazie lokalnej i aplikacjach w serwisie Fresh';
									|tr = 'Fresh servisindeki yerel veri tabanındaki müzakereleri ve uygulamaları paylaşmak mümkün olacaktır.'"));
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function MethodOfRegistrationThroughService()
	
	Result = New Structure;
	Result.Insert("Value", "ViaService");
	Result.Insert("Description", NStr("vi = 'Thông qua dịch vụ Hash';
										|ru = 'Через сервис Фреш';
										|en = 'Via Fresh service'; fa = 'Via Fresh service';
										|it = 'Tramite il servizio Fresh';
										|pl = 'Za pomocą serwisu Fresh';
										|tr = 'Fresh servisi ile'"));
	Result.Insert("ToolTip", NStr("vi = 'Sẽ có thể sử dụng chung thảo luận trong cơ sở cục bộ và ứng dụng trong dịch vụ Hash';
									|ru = 'Будет доступно совместное использование обсуждений в локальной базе и приложениях в сервисе Фреш';
									|en = 'Sharing of conversations will be available in the local base and applications in Fresh service'; fa = 'Sharing of conversations will be available in the local base and applications in Fresh service';
									|it = 'L''utilizzo condiviso delle discussioni sarà disponibile nel database locale e nelle applicazioni del servizio Fresh';
									|pl = 'Będzie dostępne wspólne używanie dyskusji w bazie lokalnej i aplikacjach w serwisie Fresh';
									|tr = 'Fresh servisindeki yerel veri tabanındaki müzakereleri ve uygulamaları paylaşmak mümkün olacaktır.'"));
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function RegistrationMethodWithoutService()
	
	Result = New Structure;
	Result.Insert("Value", "WithoutService");
	Result.Insert("Description", NStr("vi = 'Phương thức chuẩn';
										|ru = 'Стандартный способ';
										|en = 'Standard method'; fa = 'Standard method';
										|it = 'Metodo standard';
										|pl = 'Standardowy sposób';
										|tr = 'Standart yöntem'"));
	Result.Insert("ToolTip", "");
	
	Return Result;
	
EndFunction

&AtClient
Procedure WhenChangingRegistrationMethod()
	
	RegistrationMethods = New Array;
	RegistrationMethods.Add(MethodOfRegistrationThroughService());
	RegistrationMethods.Add(MethodOfRegistrationThroughServiceInCloud());
	RegistrationMethods.Add(RegistrationMethodWithoutService());
	
	For Each Method In RegistrationMethods Do
		
		If RegistrationMethod = Method.Value Then
			Items.RegistrationMethod.ToolTip = Method.ToolTip;
		EndIf;
		
	EndDo;
	
	Items.DataToManage.Visible = (RegistrationMethod = MethodOfRegistrationThroughService().Value);
	Items.SubscriberEmail.Visible = (RegistrationMethod = RegistrationMethodWithoutService().Value);
	Items.BaseName.Visible = (RegistrationMethod <> MethodOfRegistrationThroughServiceInCloud().Value);
	Items.RegisterGroup.Visible = (RegistrationMethod = RegistrationMethodWithoutService().Value);
	
	SetAvailabilityOfRegistrationButtons();
	
EndProcedure

&AtServer
Procedure FillInMappingTable()
	
	MappingTable.Clear();
	
	IBUsers = InfoBaseUsers.GetUsers(); // Array of InfoBaseUser
	
	For Each IBUser In IBUsers Do
		
		NwRw = MappingTable.Add();
		NwRw.IBUser = IBUser.Name;
		CollaborationSystemUser = UserOfInteractionSystemForInformationSecurityUser(IBUser);
		If CollaborationSystemUser <> Undefined Then
			NwRw.MatchingKey = CollaborationSystemUser.MatchingKey;
		EndIf;
		
	EndDo;
	
	For Each Page1 In ServiceUsers Do
		
		For Each MappingString In MappingTable Do
			
			If MappingString.MatchingKey = Page1.MatchingKey Then
				MappingString.SaaSUser = Page1.UserName;
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure GetInformationAboutServiceUsersOnServer()
	
	UserInformation_ = IntegrationWithCollaborationSystem.GetDataAboutServiceUsers(ManagementServicePublicationURL, ControlCode);
	
	ServiceUsers.Clear();
	
	If UserInformation_.Success
		And UserInformation_.ResultData <> Undefined
		And UserInformation_.ResultData.Property("UserData_") Then
		
		For Each Page1 In UserInformation_.ResultData.UserData_ Do
			NwRw = ServiceUsers.Add();
			NwRw.UserName = Page1.UserName;
			NwRw.MatchingKey = Page1.UserID;
			NwRw.Description = Page1.UserName;
		EndDo;
		
		FillInMappingTable();
		
	Else
		
		MessageText = StrTemplate(
			NStr("vi = 'Không thể nhận thông tin về người sử dụng dịch vụ do nguyên nhân: %1';
				|ru = 'Не удалось получить информацию о пользователях сервиса по причине: %1';
				|en = 'Cannot get information on service users due to: %1'; fa = 'Cannot get information on service users due to: %1';
				|it = 'Non è stato possibile ottenere le informazioni sugli utenti del servizio a causa di: %1';
				|pl = 'Nie udało się uzyskać informacji o użytkownikach serwisu z powodu: %1';
				|tr = 'Şu sebepten servis kullanıcıları hakkında bilgi alınamadı: %1'"), 
			UserInformation_.MessageText);
		Common.MessageToUser(MessageText);
		
	EndIf;
	
EndProcedure

&AtServer
Function UserOfInteractionSystemForInformationSecurityUser(IBUser)
	
	UserUUID = IBUser.UUID;
	
	// this method is proposed in the article on ITS
	Try
		UserIDCollaborationSystem = CollaborationSystem.GetUserID(UserUUID);
		Return CollaborationSystem.GetUser(UserIDCollaborationSystem);
	Except
		Return Undefined;
	EndTry;
	
EndFunction

&AtServer
Procedure RePopulateMappingTableAfterEditing()
	
	MatchedServiceUsers = New Array;
	
	For Each Page1 In MappingTable Do
		If ValueIsFilled(Page1.IBUser)
			And ValueIsFilled(Page1.SaaSUser) Then
			MatchedServiceUsers.Add(Page1.SaaSUser);
		EndIf;
	EndDo;
	
	For Each MatchedServiceUser In MatchedServiceUsers Do
		FilterParameters = New Structure;
		FilterParameters.Insert("IBUser", "");
		FilterParameters.Insert("SaaSUser", MatchedServiceUser);
		RowsForDeletion = MappingTable.FindRows(FilterParameters);
		For Each RowForDeletion In RowsForDeletion Do
			MappingTable.Delete(RowForDeletion);
		EndDo;
	EndDo;
	
EndProcedure

&AtServer
Procedure SaveMappingOnServer()
	
	SetPrivilegedMode(True);
	
	For Each Page1 In MappingTable Do
		
		If Not ValueIsFilled(Page1.IBUser) Then
			Continue;
		EndIf;
		
		IBUser = InfoBaseUsers.FindByName(Page1.IBUser);
		UserUUID = IBUser.UUID;
		
		UserIDCollaborationSystem = Undefined;
		
		//@skip-check empty-except-statement - this method is proposed in the article on ITS
		Try
			UserIDCollaborationSystem = CollaborationSystem.GetUserID(UserUUID);
		Except
		EndTry;
		
		NewMappingKey = ServiceUserMappingKey(Page1.SaaSUser);
		RecordUser = False;
		
		If UserIDCollaborationSystem = Undefined Then
			CollaborationSystemUser = CollaborationSystem.CreateUser(IBUser);
			RecordUser = True;
		Else
			CollaborationSystemUser = CollaborationSystem.GetUser(UserIDCollaborationSystem);
			If CollaborationSystemUser.MatchingKey <> NewMappingKey Then
				RecordUser = True;
			EndIf;
		EndIf;
		
		If RecordUser Then
			CollaborationSystemUser.MatchingKey = NewMappingKey;
			CollaborationSystemUser.Write();
		EndIf;
		
	EndDo;
	
	SetPrivilegedMode(False);
	
EndProcedure

&AtServer
Function ServiceUserMappingKey(SaaSUser = "")
	
	If Not ValueIsFilled(SaaSUser) Then
		Return "";
	EndIf;
	
	For Each Page1 In ServiceUsers Do
		
		If Page1.UserName = SaaSUser Then
			Return Page1.MatchingKey;
		EndIf;
		
	EndDo;
	
	Return "";
	
EndFunction

&AtClient
Procedure DataEntryFormForManagementIsClosed(Result, AdditionalParameters) Export
	
	If ValueIsFilled(Result) Then
		DecryptedDataForManagement = DecryptDataForManagementOnServer(Result);
		If Not DecryptedDataForManagement.Deciphered Then
			MessageText = StrTemplate(
				NStr("vi = 'Dữ liệu đã nhập không được xác thực: %1';
					|ru = 'Введенные данные не верны: %1';
					|en = 'Entered data is incorrect: %1'; fa = 'Entered data is incorrect: %1';
					|it = 'I parametri inseriti non sono corretti: %1';
					|pl = 'Wprowadzone dane nie są poprawne: %1';
					|tr = 'Girilen veriler hatalı: %1'"), 
				DecryptedDataForManagement.MessageText);
			CommonClient.MessageToUser(MessageText);
		Else
			DataToManage = Result;
			ManagementServicePublicationURL = DecryptedDataForManagement.Data.ManagementServicePublicationURL;
			URIStructure = CommonClientServer.URIStructure(ManagementServicePublicationURL);
			ServiceManagerURL = URIStructure.Host;
			ControlCode = DecryptedDataForManagement.Data.ControlCode;
			SaveDataForManagement();
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Function DecryptDataForManagementOnServer(Data)
	
	Return IntegrationWithCollaborationSystem.DecryptDataForManagement(Data);
	
EndFunction

&AtServer
Procedure ReadManagementDataFromStorage()
	
	SetPrivilegedMode(True);
	DataFromStorage = IntegrationWithCollaborationSystem.DataForInteractionSystemManagement();
	If ValueIsFilled(DataFromStorage) Then
		
		DataToManage = DataFromStorage;
		
		DecryptedDataForManagement = DecryptDataForManagementOnServer(DataToManage);
		If DecryptedDataForManagement.Deciphered Then
			ManagementServicePublicationURL = DecryptedDataForManagement.Data.ManagementServicePublicationURL;
			URIStructure = CommonClientServer.URIStructure(ManagementServicePublicationURL);
			ServiceManagerURL = URIStructure.Host;
			ControlCode = DecryptedDataForManagement.Data.ControlCode;
		EndIf;
		
	EndIf;
	
	SetPrivilegedMode(False);
	
EndProcedure

&AtClient
Procedure GetRegistrationCodeCompletion(Result, MessageText, AdditionalParameters) Export

	CallbackDescription = New CallbackDescription("GetRegistrationCodeCompletionWarning", ThisObject);
	ShowMessageBox(CallbackDescription, MessageText);
	
EndProcedure

&AtClient
Procedure GetRegistrationCodeCompletionWarning(AdditionalParameters) Export
	
	Enabled = True;
	CurrentItem = Items.RegistrationCode;
	
EndProcedure

&AtClient
Procedure GetRegistrationCodeError(ErrorInfo, StandardProcessing, AdditionalParameters) Export

	StandardProcessing = False;
	
	ErrorProcessing.ShowErrorInfo(ErrorInfo);
	
	Enabled = True;

EndProcedure

&AtClient
Procedure SetAvailabilityOfRegistrationButtons()
	
	If RegistrationMethod = MethodOfRegistrationThroughServiceInCloud().Value Then
		Items.Register.Enabled = True;
	ElsIf RegistrationMethod = MethodOfRegistrationThroughService().Value Then
		Items.Register.Enabled = Not IsBlankString(DataToManage) 
			And Not IsBlankString(BaseName) 
			And Not IsBlankString(ServiceManagerURL);
	ElsIf RegistrationMethod = RegistrationMethodWithoutService().Value Then
		Items.Register.Enabled = Not IsBlankString(SubscriberEmail) 
			And Not IsBlankString(BaseName) 
			And Not IsBlankString(RegistrationCode);
	EndIf;
	
	Items.GetRegistrationCode.Enabled = Not IsBlankString(SubscriberEmail) 
		And Not IsBlankString(BaseName);
	
EndProcedure

&AtClient
Procedure ChoosingServiceUser(SelectedElement, AdditionalParameters) Export
	
	If SelectedElement <> Undefined Then
		CurComparisonData = Items.MappingTable.CurrentData;
		CurComparisonData.SaaSUser = SelectedElement.Value.UserName;
		CurComparisonData.MatchingKey = SelectedElement.Value.MatchingKey;
	EndIf;
	
	RePopulateMappingTableAfterEditing();
	
EndProcedure

#EndRegion