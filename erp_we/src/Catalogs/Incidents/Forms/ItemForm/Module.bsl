#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("SubjectOf") Then
		Object.Basis = Parameters.SubjectOf;
	EndIf;

	Items.Basis.Title = Common.SubjectString(Object.Basis);
	Items.BaseGroup_.Visible = ValueIsFilled(Object.Basis);

	CurrentStatus = Object.Status;
	CurrentAuthor = Object.Author;
	CurrentPerformer = Object.Author;

	If Object.Ref.IsEmpty() Then
		Object.Author 	= Users.CurrentUser();
		Object.Status 	= StatusRegistered();

		OnReadCreateAtServer();
	EndIf;

	Interactions.PrepareNotifications(ThisObject, Parameters, False);

	ProcessingOfTabularForms.InitializeRowCache(Items.RecipientsOfNotifications);
		
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);

	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations

	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure RecipientsOfNotificationsOnStartEdit(Item, NewRow, Copy)

	ProcessingOfTabularFormsClient.CacheCurLine(Items.RecipientsOfNotifications, ThisObject);

	If NewRow Then

		CurrentData = Items.RecipientsOfNotifications.CurrentData;

	EndIf;

EndProcedure

&AtClient
Procedure RecipientsOfNotificationsOnEditEnd(Item, NewRow, CancelEdit)

	If CancelEdit Then
		Return;
	EndIf;

	CurrentData = Items.RecipientsOfNotifications.CurrentData;
	LineCache = ProcessingOfTabularFormsClientServer.LineCache(Items.RecipientsOfNotifications, ThisObject);

	If (LineCache.User <> CurrentData.User Or NewRow) Then
		NewNotificationRecipients.Add(CurrentData.User);
	EndIf;

EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	ClosingDuplicatesOfIncident();
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	SendAlert(WriteParameters.Property("DoubleChanged"));

	CurrentStatus = Object.Status;
	CurrentAuthor = Object.Author;
	CurrentPerformer = Object.Author;

	NewNotificationRecipients.Clear();
	ConfigureDependentFormElements(ThisForm, "ToolTip, Duplicates");

EndProcedure

&AtClient
Procedure OnOpen(Cancel)

	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	OnReadCreateAtServer();
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	// End StandardSubsystems.Properties

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters) 
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	If Common.ObjectAttributeValue(Object.Ref, "Duplicate1") <> CurrentObject.Duplicate1 Then
		WriteParameters.Insert("DoubleChanged", True);
	EndIf;

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure BasisClick(Item)

	ShowValue( , Object.Basis);

EndProcedure

&AtClient
Procedure StatusOnChange(Item)

	ConfigureDependentFormElements(ThisForm, "Status");

EndProcedure

&AtClient
Procedure CloseIncident(Command)

	Object.Status = TheClosedStatus();

	ConfigureDependentFormElements(ThisForm, "Status");

EndProcedure

&AtClient
Procedure IncidentHasBeenResolved(Command)

	Object.Status = StatusResolved();

	ConfigureDependentFormElements(ThisForm, "Status");

EndProcedure

&AtClient
Procedure ReturnToResponsiblePerson(Command)

	Object.Status = StatusRegistered();

	ConfigureDependentFormElements(ThisForm, "Status");

EndProcedure

&AtServer
Procedure SendAlert(DoubleChanged)

	If Object.Status = StatusRegistered() Then
		If ValueIsFilled(Object.Duplicate1) And DoubleChanged Then
			GeneratingAlert("RecipientsOfNotifications", "MarkedAsDouble");
			GeneratingAlert("ToAuthor", "MarkedAsDouble");
		ElsIf CurrentStatus = StatusResolved() Then
			GeneratingAlert("RecipientsOfNotifications", "ReturnToPerformer");
			GeneratingAlert("ToPerformer", "ReturnToPerformer");
		Else
			GeneratingAlert("RecipientsOfNotifications", "Registered");
			GeneratingAlert("ToPerformer", "Registered");
		EndIf;
	ElsIf Object.Status = StatusResolved() Then
		GeneratingAlert("RecipientsOfNotifications", "Solved");
		GeneratingAlert("ToAuthor", "Solved");
	ElsIf Object.Status = TheClosedStatus() Then
		GeneratingAlert("RecipientsOfNotifications", "Closed");
		GeneratingAlert("ToPerformer", "Closed");
	ElsIf Object.Status = StatusIsNotRelevant() Then
		GeneratingAlert("RecipientsOfNotifications", "Outdated");
		GeneratingAlert("ToPerformer", "Outdated");
	EndIf;

	ThereAreDuplicates = DuplicatesOfIncident();
	
EndProcedure

&AtServer
Function GenerateMessageText(ToWhomItWasSent, Status)

	MessageText = "";

	If ToWhomItWasSent = "RecipientsOfNotifications" Then
		If Status = "Registered" Then
			MessageText = NStr("vi = 'Đã ghi nhận sự cố %1';
								|ru = 'Зарегистрирован инцидент %1';
								|en = 'The %1 incident is registered'; fa = 'The %1 incident is registered';
								|it = 'Incidente registrato %1';
								|pl = 'Zarejestrowano incydent %1';
								|tr = 'Olay kaydedildi %1'");
		ElsIf Status = "Solved" Then
			MessageText = NStr("vi = 'Đã giải quyết sự cố %1';
								|ru = 'Решен инцидент %1';
								|en = 'The %1 incident is solved'; fa = 'The %1 incident is solved';
								|it = 'Incidente risolto %1';
								|pl = 'Został rozwiązany incydent %1';
								|tr = 'Olay çözüldü %1'");
		ElsIf Status = "Closed" Then
			MessageText = NStr("vi = 'Đã đóng sự cố %1';
								|ru = 'Закрыт инцидент %1';
								|en = 'The %1 incident is closed'; fa = 'The %1 incident is closed';
								|it = 'Incidente chiuso %1';
								|pl = 'Został zamknięty incydent %1';
								|tr = 'Olay kapalı %1'");
		ElsIf Status = "ReturnToPerformer" Then
			MessageText = NStr("vi = 'Chưa giải quyết và gửi lại sự cố %1 cho người thực hiện';
								|ru = 'Не решен и повторно направлен исполнителю инцидент %1';
								|en = 'The %1 incident has not been solved and sent to the assignee again'; fa = 'The %1 incident has not been solved and sent to the assignee again';
								|it = 'L''incidente %1 non risolto e rimandato all''esecutore ';
								|pl = 'Nie rozwiązano i ponownie wysłano do wykonawcy incydent %1';
								|tr = 'Çözülmedi ve atanana yeniden gönderildi olay %1'");
		ElsIf Status = "Outdated" Then
			MessageText = NStr("vi = 'Đã thu hồi sự cố %1do mất tính hiệu lực';
								|ru = 'Отозван в связи с потерей актуальности инцидент %1';
								|en = 'The %1 incident is recalled as it is no longer relevant'; fa = 'The %1 incident is recalled as it is no longer relevant';
								|it = 'L''incidente %1 richiamato in quanto non più attuale';
								|pl = 'Odwołany w związku z utratą aktualności incydent %1';
								|tr = 'Aktüellik kaybı nedeniyle geri çekildi olay %1'");
		ElsIf Status = "MarkedAsDouble" Then
			MessageText = NStr("vi = 'Đã chỉ ra sự cố %1 là sự trùng lặp của sự cố %2';
								|ru = 'Инцидент %1 указан как дубль инцидента %2';
								|en = 'The %1 incident is specified as a duplicate of the %2 incident'; fa = 'The %1 incident is specified as a duplicate of the %2 incident';
								|it = 'L''incidente %1 è indicato come doppione dell''incidente %2';
								|pl = 'Incydent %1 jest podany jako duplikat incydentu %2';
								|tr = '%1 olayı %2 olayının tekrarı gibi belirtildi'");
		EndIf;
	ElsIf ToWhomItWasSent = "ToPerformer" Then
		If Status = "Registered" Then
			MessageText = NStr("vi = 'Đã ghi nhận và gửi cho bạn sự cố %1 để giải quyết';
								|ru = 'Зарегистрирован и направлен Вам на решение инцидент %1';
								|en = 'The %1 incident has been registered and sent to you for review'; fa = 'The %1 incident has been registered and sent to you for review';
								|it = 'L''incidente %1 registrato e inviato a Lei per la soluzione';
								|pl = 'Zarejestrowano i wyłano Ci do rozwiązania incydent %1';
								|tr = 'Kaydedildi ve karar için Size iletildi olay %1'");
		ElsIf Status = "Closed" Then
			MessageText = NStr("vi = 'Đã đóng sự cố %1';
								|ru = 'Закрыт инцидент %1';
								|en = 'The %1 incident is closed'; fa = 'The %1 incident is closed';
								|it = 'Incidente chiuso %1';
								|pl = 'Został zamknięty incydent %1';
								|tr = 'Olay kapalı %1'");
		ElsIf Status = "ReturnToPerformer" Then
			MessageText = NStr("vi = 'Chưa xác nhận và gửi lại cho bạn sự cố %1 để giải quyết';
								|ru = 'Не подтвержден и повторно направлен Вам на решение инцидент %1';
								|en = 'The %1 incident has not been confirmed and sent to you for review again'; fa = 'The %1 incident has not been confirmed and sent to you for review again';
								|it = 'L''incidente %1 non confermato e inviato nuovamente a Lei per la soluzione';
								|pl = 'Nie potwierdzono i ponownie wysłano do Ciebie do rozwiązania incydent %1';
								|tr = 'Onaylanmadı ve karar için Size yeniden gönderildi olay %1'");
		ElsIf Status = "Outdated" Then
			MessageText = NStr("vi = 'Đã thu hồi sự cố %1do mất tính hiệu lực';
								|ru = 'Отозван в связи с потерей актуальности инцидент %1';
								|en = 'The %1 incident is recalled as it is no longer relevant'; fa = 'The %1 incident is recalled as it is no longer relevant';
								|it = 'L''incidente %1 richiamato in quanto non più attuale';
								|pl = 'Odwołany w związku z utratą aktualności incydent %1';
								|tr = 'Aktüellik kaybı nedeniyle geri çekildi olay %1'");
		Else
			MessageText = "";
		EndIf;
	ElsIf ToWhomItWasSent = "ToAuthor" Then
		If Status = "Solved" Then
			MessageText = NStr("vi = 'Đã giải quyết và gửi sự cố %1 cho bạn để xác nhận';
								|ru = 'Решен и направлен Вам для подтверждения инцидент %1';
								|en = 'The %1 incident has been solved and sent to you for confirmation'; fa = 'The %1 incident has been solved and sent to you for confirmation';
								|it = 'L''incidente %1 è risolto e inviato a Lei per la conferma';
								|pl = 'Został rozwiązany i wysłany do Ciebie do potwierdzenia incydent %1';
								|tr = 'Çözüldü ve onay için size gönderildi olay %1'");
		ElsIf Status = "MarkedAsDouble" Then
			MessageText = NStr("vi = 'Đã chỉ ra sự cố %1 là sự trùng lặp của sự cố %2';
								|ru = 'Инцидент %1 указан как дубль инцидента %2';
								|en = 'The %1 incident is specified as a duplicate of the %2 incident'; fa = 'The %1 incident is specified as a duplicate of the %2 incident';
								|it = 'L''incidente %1 è indicato come doppione dell''incidente %2';
								|pl = 'Incydent %1 jest podany jako duplikat incydentu %2';
								|tr = '%1 olayı %2 olayının tekrarı gibi belirtildi'");
		Else
			MessageText = "";
		EndIf;
	EndIf;

	Return MessageText;

EndFunction

&AtServer
Procedure GeneratingAlert(ToWhomItWasSent, Status)

#Region Validation

	If Not Common.SubsystemExists("StandardSubsystems.Conversations") Then
		Return;
	EndIf;

	ModuleConversations = Common.CommonModule("Conversations");

	StatusIsChanged 		= Object.Status <> CurrentStatus;
	AuthorHasBeenChanged 		= Object.Author <> CurrentAuthor;
	PerformerChanged 	= Object.Performer <> CurrentPerformer;
	DoubleChanged		= Status = "MarkedAsDouble";
	
	Recipients = New Array;
	If ToWhomItWasSent = "RecipientsOfNotifications" Then
		If StatusIsChanged Or DoubleChanged Then
			Recipients = Object.RecipientsOfNotifications.Unload( , "User").UnloadColumn("User");
		Else
			Recipients = NewNotificationRecipients.UnloadValues();
		EndIf;
	ElsIf ToWhomItWasSent = "ToAuthor" Then
		If ValueIsFilled(Object.Author) And (StatusIsChanged Or AuthorHasBeenChanged Or DoubleChanged) Then
			Recipients.Add(Object.Author);
		EndIf;
	ElsIf ToWhomItWasSent = "ToPerformer" Then
		If ValueIsFilled(Object.Performer) And (StatusIsChanged Or PerformerChanged Or DoubleChanged) Then
			Recipients.Add(Object.Performer);
		EndIf;
	EndIf;

	If Recipients.Count() = 0 Then
		Return;
	EndIf;

#EndRegion

#Region GeneratingAlert

	MessageText = GenerateMessageText(ToWhomItWasSent, Status);

	If IsBlankString(MessageText) Then
		Return;
	EndIf;

	Text = StringFunctionsClientServer.SubstituteParametersToString(
	MessageText, GetURL(Object.Ref), GetURL(Object.Duplicate1));

	Message = ModuleConversations.MessageDetails(Text);

	Try
		ModuleConversations.SendMessage(
		Users.CurrentUser(), Recipients, Message, Object.Ref);
	Except

		DefaultLanguageCode = Common.DefaultLanguageCode();

		WriteLogEvent(
		NStr("vi = 'Sự cố.Thông báo ghi nhận sự cố';
			|ru = 'Инциденты.Оповещение о регистрации инцидента';
			|en = 'Incidents.Incident registration notification'; fa = 'Incidents.Incident registration notification';
			|it = 'Incidenti. Notifica di registrazione incidente';
			|pl = 'Incydenty.Powiadomienie o rejestracji incydentu';
			|tr = 'Olaylar. Olay kaydı bildirimi'", DefaultLanguageCode),
			EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(ErrorInfo()));

	EndTry;

#EndRegion

EndProcedure

&AtClient
Procedure SeverityOnChange(Item)

	FillInRecipientsOfNotification();

EndProcedure

#EndRegion

#Region EventHandlersForFormPageElementsMain

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If CurrentPage.Name = "AdditionalPage"
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then

		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);

	EndIf;
	// End StandardSubsystems.Properties

EndProcedure

&AtClient
Procedure SceneryDuplicatesOfIncidentsClick(Item)

	If Object.Ref.IsEmpty() Then
		Return;
	EndIf;

	IncidentUnderReview = Object.Ref;
	If ValueIsFilled(Object.Duplicate1) Then
		IncidentUnderReview = Object.Duplicate1;
	EndIf;

	FilterValues = New Structure("IncidentUnderReview", IncidentUnderReview);
	FormParameters = New Structure("Filter, GenerateOnOpen", FilterValues, True);
	OpenForm("Report.IncidentDuplicates.Form", FormParameters);

EndProcedure

&AtClient
Procedure IncidentKindOnChange(Item)

	TypeOfIncidentWhenChangingOnServer();

EndProcedure

&AtServer
Procedure TypeOfIncidentWhenChangingOnServer()

	UpdateAdditionalAttributesItems();
	FillInRecipientsOfNotification();

EndProcedure

#EndRegion

#Region EventHandlersForPageElementsResultOfReview

&AtClient
Procedure Duplicate1OnChange(Item)

	If Not ValueIsFilled(Object.Duplicate1) Then
		Return;
	EndIf;

	TheClosedStatus = StatusOfDouble(Object.Duplicate1);
	If TheClosedStatus Then
		QueryText = NStr("vi = 'Đã đóng sự cố được chọn ""%1"".
							|Sẽ đặt trạng thái đã đóng đối với sự cố hiện tại, tiếp tục?';
							|ru = 'Выбранный инцидент ""%1"" закрыт.
							|Для текущего инцидента будет установлен статус закрыт, продолжить?';
							|en = 'The selected ""%1"" incident is closed.
							|The Closed status will be set to the current incident. Continue?'; fa = 'The selected ""%1"" incident is closed.
							|The Closed status will be set to the current incident. Continue?';
							|it = 'L''incidente ""%1"" selezionato è chiuso.
							|All''incidente corrente verrà assegnato lo stato chiuso, continuare?';
							|pl = 'Wybrany incydent ""%1"" jest zamknięty.
							|Dla bieżącego incydentu zostanie ustawiony status zamknięty, kontynuować?';
							|tr = '""%1"" seçilen olay kapalı.
							|Mevcut olayın durumu kapalı olarak ayarlanacak, devam edilsin mi?'");

		QueryText = StrTemplate(QueryText, Object.Duplicate1);

		ShowQueryBox(New CallbackDescription("Duplicate1OnChangeCompletion", ThisObject), QueryText,
			QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
	EndIf;

EndProcedure

&AtClient
Procedure Duplicate1OnChangeCompletion(QuestionResult, AdditionalParameters) Export

	If QuestionResult = DialogReturnCode.Yes Then
		Object.Status = TheClosedStatus();
		ConfigureDependentFormElements(ThisForm, "Status");
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined,
	StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure
// End StandardSubsystems.Properties

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)
	FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item, DragParameters,
		StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)
	FilesOperationsClient.PreviewFieldDrag(ThisObject, Item, DragParameters,
		StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)
	FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

#EndRegion

#Region Private

#Region StandardSubsystems

// StandardSubsystems.Properties 
&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	PropertyManager.FillAdditionalAttributesInForm(ThisObject);
EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()

	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);

EndProcedure
// End StandardSubsystems.Properties

#EndRegion

#Region FormSettingsItem

&AtServer
Procedure CustomizeFormElements()

	ConfigureDependentFormElements(ThisForm);

EndProcedure

// The procedure is called when changing the details that depend on the properties of other details, such as visibility.
//
&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")

	Object = Form.Object;
	Items = Form.Items;

	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	Result = Undefined;

	If AttributesStructure1.Property("Status", Result) Or Initialize Then

		If Not Object.Ref.IsEmpty() Then
			Items.IncidentHasBeenResolved.Visible = Object.Status = StatusRegistered();
			Items.CloseIncident.Visible = Object.Status = StatusResolved();
			Items.ReturnToResponsiblePerson.Visible = Object.Status = StatusResolved();
		Else
			Items.IncidentHasBeenResolved.Visible = False;
			Items.CloseIncident.Visible = False;
			Items.ReturnToResponsiblePerson.Visible = False;
		EndIf;

	EndIf;

	If AttributesStructure1.Property("ToolTip", Result) Or Initialize Then

		If Object.Status = StatusRegistered() Then
			If Object.Ref.IsEmpty() Then
				Items.Explanation.Title = NStr("vi = 'Hãy điền thông tin về sự cố.
													|Sự cố sẽ được ghi nhận cho người thực hiện sau khi ghi lại.';
													|ru = 'Заполните информацию по инциденту. 
													|Инцидент будет зарегистрирован на исполнителя после записи.';
													|en = 'Fill information about the incident. 
													|The incident will be registered to an assignee after saving.'; fa = 'Fill information about the incident. 
													|The incident will be registered to an assignee after saving.';
													|it = 'Compilare le informazioni sull''incidente. 
													|L''incidente verrà registrato all''esecutore dopo la registrazione.';
													|pl = 'Wypełnij informacje dotyczące incydentu. 
													| Incydent zostanie zarejestrowany po zapisie.';
													|tr = 'Olay bilgilerini doldur. 
													|Olay, kayıttan sonra atanana kaydedilecektir.'");
			ElsIf ValueIsFilled(Object.Duplicate1) Then
				Items.Explanation.Title = NStr("vi = 'Được đánh dấu là trùng lặp, không cần thực hiện thao tác nào đối với sự cố.
													|Sẽ tự động đóng khi đóng sự cố chính.';
													|ru = 'Помечен как дубль, никаких действий над инцидентом выполнять не нужно. 
													|Будет автоматически закрыт при закрытии основного инцидента.';
													|en = 'It is marked as a duplicate, no actions with the incident are required. 
													|It will be automatically closed when you close the main incident.'; fa = 'It is marked as a duplicate, no actions with the incident are required. 
													|It will be automatically closed when you close the main incident.';
													|it = 'Contrassegnato come doppione, non richiede alcuna azione. 
													|Sarà chiuso automaticamente contestualmente alla chiusura dell''incidente principale.';
													|pl = 'Jest zaznaczony jako duplikat, żadnych działań z incydentem nie trzeba wykonywać. 
													|Automatycznie zostanie zamknięty przy zamknięciu podstawowego incydentu.';
													|tr = 'Kopya olarak işaretlendi, olayla ilgili herhangi işlemin yapılması gerekmiyor. 
													|Ana olay kapatıldığında otomatik olarak kapatılacaktır.'");
			Else
				Items.Explanation.Title = NStr(
					"vi = 'Đã ghi nhận sự cố, người thực hiện cần khắc phục sự cố và đặt trạng thái ""đã giải quyết"".';
					|ru = 'Инцидент зарегистрирован, исполнителю необходимо устранить инцидент и установить статус ""решен"".';
					|en = 'The incident is registered. The assignee must solve the incident and set the ""Solved"" status.'; fa = 'The incident is registered. The assignee must solve the incident and set the ""Solved"" status.';
					|it = 'L''incidente è registrato, l''esecutore deve rimuovere l''incidente e impostare lo stato ""risolto"".';
					|pl = 'Incydent został zarejestrowany, wykonawcy należy usunąć incydent i ustawić status ""rozwiązany"".';
					|tr = 'Olay kaydedildi, atananın olayı ortadan kaldırması ve durumu ""çözüldü"" olarak ayarlaması gerekir.'");
			EndIf;
		ElsIf Object.Status = StatusResolved() Then
			Items.Explanation.Title = NStr("vi = 'Người thực hiện đã giải quyết sự cố, tác giả cần kiểm tra việc thực hiện sự cố và xác nhận bằng cách đặt trạng thái ""đã đóng"" 
												|hoặc gửi lại cho người thực hiện bằng cách nhấn nút ""trả lại người thực hiện"", nếu sự cố chưa được giải quyết.';
												|ru = 'Инцидент решен исполнителем, автору необходимо проверить исполнение инцидента и подтвердить установив статус ""закрыт"" 
												|или повторно направить исполнителю нажав ""вернуть исполнителю"", если инцидент не решен.';
												|en = 'The incident is solved by the assignee. The author must check the incident fulfillment and confirm it by setting the ""Closed"" status. 
												|If the incident is not solved, the author must return it to the assignee by clicking ""Return to assignee"".'; fa = 'The incident is solved by the assignee. The author must check the incident fulfillment and confirm it by setting the ""Closed"" status. 
												|If the incident is not solved, the author must return it to the assignee by clicking ""Return to assignee"".';
												|it = 'L''incidente è risolto dall''esecutore, l''autore deve verificare l''esecuzione dell''incidente e confermare lo stato ""chiuso"" 
												| o rimandarlo di nuovo all''esecutore premendo ""rimandare all''esecutore"" se l''incidente non è stato risolto.';
												|pl = 'Incydent został rozwiązany przez wykonawcę, autor powinien sprawdzić wykonanie incydentu i potwierdzić, ustawiając status ""zamknięty"" 
												|lub ponownie wysłać do wykonawcy, naciskając ""zwróć do wykonawcy"", jeśli incydent nie jest rozwiązany.';
												|tr = 'Olay atanan tarafından çözülür, oluşturanın olayın yürütülmesini kontrol etmesi ve durumu ""kapalı"" olarak ayarlayarak onaylaması gerekir
												| veya olay çözülmezse ""atanana geri gönder"" seçeneğine tıklayarak atanana yeniden göndermesi gerekir.'");
		ElsIf Object.Status = TheClosedStatus() Then
			Items.Explanation.Title = NStr("vi = 'Đã đóng sự cố, không cần thao tác gì.';
											|ru = 'Инцидент закрыт, не требует никаких действий.';
											|en = 'The incident is closed. No actions are required.'; fa = 'The incident is closed. No actions are required.';
											|it = 'L''incidente è chiuso, non richiede alcuna azione.';
											|pl = 'Incydent został zamknięty, nie wymaga żadnych działań.';
											|tr = 'Olay kapalı, herhangi bir işlem yapılmasına gerek yoktur.'");
		ElsIf Object.Status = StatusIsNotRelevant() Then
			Items.Explanation.Title = NStr(
				"vi = 'Đã thu hồi sự cố do mất tính hiệu lực, không cần thao tác gì.';
				|ru = 'Инцидент отозван в связи с потерей актуальности, не требует никаких действий.';
				|en = 'The incident is recalled as it is no longer relevant. No actions are required.'; fa = 'The incident is recalled as it is no longer relevant. No actions are required.';
				|it = 'L''incidente è stato richiamato in quanto non più attuale, non richiede alcuna azione.';
				|pl = 'Incydent został odwołany w związku z utratą aktualności, nie wymaga żadnych działań.';
				|tr = 'Olay aktüellik kaybı nedeniyle geri çekilmiştir, herhangi bir işlem yapılmasını gerektirmiyor.'");
		EndIf;

	EndIf;

	If AttributesStructure1.Property("Duplicates", Result) Or Initialize Then

		Items.SceneryDuplicatesOfIncidents.Visible = Form.ThereAreDuplicates;

	EndIf;

EndProcedure

#EndRegion

#EndRegion

#Region OtherItems

&AtServer
Procedure OnReadCreateAtServer()

	ThereAreDuplicates = DuplicatesOfIncident();

	CustomizeFormElements();

EndProcedure

&AtServer
Procedure FillInRecipientsOfNotification()

	If Not ValueIsFilled(Object.IncidentKind) Then
		Return;
	EndIf;

	DeleteTSNotificationRecipientsLines();

	Query = New Query;

	QuerySchema = New QuerySchema;

	QuerySchema.SetQueryText("
										|	SELECT
										|	TypesOfIncidentsNotificationRecipients.User AS User,
										|	TypesOfIncidentsNotificationRecipients.Role AS Role,
										|	TRUE AS FilledFromSettings
										|FROM
										|	Catalog.IncidentKinds.RecipientsOfNotifications AS TypesOfIncidentsNotificationRecipients
										|WHERE
										|	TypesOfIncidentsNotificationRecipients.Ref = &Ref
										|	AND TypesOfIncidentsNotificationRecipients.Ref.DeletionMark = FALSE");

	Query.SetParameter("Ref", Object.IncidentKind);
	If ValueIsFilled(Object.Severity) Then
		Query.SetParameter("Severity", Common.ObjectAttributeValue(Object.Severity,
			"AddlOrderingAttribute"));
		SelectionOperator = QuerySchema.QueryBatch[0].Operators[0];
		SelectionOperator.Filter.Add(
			"TypesOfIncidentsNotificationRecipients.Severity.AddlOrderingAttribute >= &Severity");
		SelectionRequest = QuerySchema.QueryBatch[0];
		QueryOperator = SelectionRequest.Operators.Add();
		QueryOperator.UnionType = QuerySchemaUnionType.UnionAll;
		QueryOperator.Sources.Add("Catalog.IncidentKinds.RecipientsOfNotifications", "RecipientsOfNotifications");
		QueryOperator.SelectedFields.Add("RecipientsOfNotifications.User");
		QueryOperator.SelectedFields.Add("RecipientsOfNotifications.Role");
		QueryOperator.SelectedFields.Add("TRUE");
		QueryOperator.Filter.Add("RecipientsOfNotifications.Ref = &Ref");
		QueryOperator.Filter.Add(
			"ISNULL(RecipientsOfNotifications.Severity, VALUE(Catalog.IncidentsSeverity.EmptyRef)) = VALUE(Catalog.IncidentsSeverity.EmptyRef)");
		QueryOperator.Filter.Add("RecipientsOfNotifications.Ref.DeletionMark = False");
		SelectionRequest.Index.Add(SelectionRequest.Columns[1]);
	EndIf;

	Query.Text = QuerySchema.GetQueryText();

	Selection = Query.Execute().Select();
	While Selection.Next() Do
		FoundRows = Object.RecipientsOfNotifications.FindRows(New Structure("User",
			Selection.User));
		If FoundRows.Count() = 0 Then
			NewRow = Object.RecipientsOfNotifications.Add();
			FillPropertyValues(NewRow, Selection);
			NewNotificationRecipients.Add(Selection.User);
		EndIf;
	EndDo;

EndProcedure

&AtServer
Procedure ClosingDuplicatesOfIncident()
	
	If Object.Ref.IsEmpty() Or Object.Status <> TheClosedStatus() Then
		Return;
	EndIf;

	If Not ThereAreDuplicatesOfIncident(Object.Ref) Then
		Return;
	EndIf;

	IncidentsPassed = New Array;
	IncidentDuplicates = Catalogs.Incidents.IncidentDuplicates(Object.Ref, IncidentsPassed);
	IncidentDuplicates = CommonClientServer.CollapseArray(IncidentDuplicates);
	CommonClientServer.DeleteValueFromArray(IncidentDuplicates, Object.Ref);
	IncidentDuplicates = Common.ObjectsAttributeValue(IncidentDuplicates, "Status");
	
	For Each Incident In IncidentDuplicates Do
		
		If Incident.Value = TheClosedStatus() Then
			Continue;
		EndIf;

		IncidentObject = Incident.Key.GetObject();
		
		Try
			IncidentObject.Lock();
		Except
			TextOfRecordException = StrTemplate(
							NStr("vi = 'Không thể thiết lập trạng thái đã đóng cho sự cố trùng lặp ""%1"".
								 |Có thể là, người sử dụng khác đang điều chỉnh dữ liệu';
								 |ru = 'Не удалось установить статус закрыт для дубля инцидента ""%1"".
								 |Возможно, данные редактируется другим пользователем';
								 |en = 'Cannot set the Closed status to the ""%1"" incident duplicate.
								 |Another user might be editing the data'; fa = 'Cannot set the Closed status to the ""%1"" incident duplicate.
								 |Another user might be editing the data';
								 |it = 'Non è stato possibile impostare lo stato chiuso per il doppione dell''incidente ""%1"".
								 |I dati potrebbero essere modificati da un altro utente';
								 |pl = 'Nie udało się ustawić statusu zamknięty dla duplikatu incydentu ""%1"".
								 |Możliwe, że dane są edytowane przez innego użytkownika';
								 |tr = '""%1"" olay kopyası için kapalı durumu ayarlanamadı.
								 |Veriler başka bir kullanıcı tarafından düzenleniyor olabilir'"), IncidentObject.Ref);

			Raise TextOfRecordException;
		EndTry;
		IncidentObject.Status = Enums.IncidentStatuses.Closed;
		IncidentObject.Write();

	EndDo;
	
EndProcedure

&AtServer
Function ThereAreDuplicatesOfIncident(Ref)

	Query = New Query;

	Query.Text =
	"SELECT
	|	TRUE
	|FROM
	|	Catalog.Incidents AS Incidents
	|WHERE
	|	Incidents.Duplicate1 = &Ref
	|	AND Incidents.DeletionMark = FALSE";

	Query.SetParameter("Ref", Ref);

	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return False;
	EndIf;

	Return True;
	
EndFunction

&AtServer
Procedure DeleteTSNotificationRecipientsLines()

	For Each RowToDelete In Object.RecipientsOfNotifications.FindRows(New Structure("FilledFromSettings",
		True)) Do

		Object.RecipientsOfNotifications.Delete(RowToDelete);

	EndDo;

EndProcedure

&AtServer
Function StatusOfDouble(Ref)

	Return Common.ObjectAttributeValue(Ref, "Status") = TheClosedStatus();

EndFunction

&AtServer
Function DuplicatesOfIncident()

	If Not ValueIsFilled(Object.Ref) Then
		Return False;
	EndIf;

	Query = New Query;

	Query.Text =
	"SELECT
	|	Incidents.Ref AS Ref
	|FROM
	|	Catalog.Incidents AS Incidents
	|WHERE
	|	Incidents.Duplicate1 = &Ref
	|	AND Incidents.DeletionMark = FALSE
	|
	|UNION ALL
	|
	|SELECT
	|	Incidents.Ref
	|FROM
	|	Catalog.Incidents AS Incidents
	|WHERE
	|	Incidents.Ref = &Ref
	|	AND ISNULL(Incidents.Duplicate1,
	|		VALUE(Catalog.Incidents.EmptyRef)) <> VALUE(Catalog.Incidents.EmptyRef)
	|	AND Incidents.DeletionMark = FALSE";

	Query.SetParameter("Ref", Object.Ref);

	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return False;
	EndIf;

	Return True;

EndFunction

&AtClientAtServerNoContext
Function StatusRegistered()

	Return PredefinedValue("Enum.IncidentStatuses.Registered");

EndFunction

&AtClientAtServerNoContext
Function StatusResolved()

	Return PredefinedValue("Enum.IncidentStatuses.Solved");

EndFunction

&AtClientAtServerNoContext
Function TheClosedStatus()

	Return PredefinedValue("Enum.IncidentStatuses.Closed");

EndFunction

&AtClientAtServerNoContext
Function StatusIsNotRelevant()

	Return PredefinedValue("Enum.IncidentStatuses.Outdated");

EndFunction

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
