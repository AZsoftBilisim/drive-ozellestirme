#Region Variables

&AtClient
Var RefreshInterface;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ThereIsSubsystemUPTo2 = IntegrationWith1CDocumentManagementCore.ThereIsSubsystemUPTo2();
	ThereIsSubsystemUPTo3 = IntegrationWith1CDocumentManagementCore.ThereIsSubsystemUPTo3();
	
	// the values of the details form.
	CompositionOfSetOfConstantsOfForm = CompositionOfSetOfConstants(ConstantsSet);
	ExternalParentConstants = ParentConstants(CompositionOfSetOfConstantsOfForm);
	AdministrationRightIsAvailable = AccessRight("Administration", Metadata) Or IsInRole("FullAccess");
	
	WorkMode = New Structure;
	WorkMode.Insert("CompositionOfSetOfConstantsOfForm", New FixedStructure(CompositionOfSetOfConstantsOfForm));
	WorkMode.Insert("ExternalParentConstants", New FixedStructure(ExternalParentConstants));
	
	WorkMode = New FixedStructure(WorkMode);
	
	GetMaximumSizeOfTransmittedFile();
	
	ArrayOfStringsExplanationShelfLife = New Array;
	ArrayOfStringsExplanationShelfLife.Add(NStr("vi = 'Khoảng thời gian sẽ lưu';
												|ru = 'Количество времени, в течение которого будет храниться';
												|en = 'Period of time during which'; fa = 'Period of time during which';
												|it = 'Period of time during which';
												|pl = 'Period of time during which';
												|tr = 'Saklanacağı süre'"));
	ArrayOfStringsExplanationShelfLife.Add(" ");
	ArrayOfStringsExplanationShelfLife.Add(
		New FormattedString(NStr("vi = 'lịch sử gửi';
								|ru = 'история отправки';
								|en = 'the sending history'; fa = 'the sending history';
								|it = 'the sending history';
								|pl = 'the sending history';
								|tr = 'gönderi geçmişi'"),,
			Items.ExplanationMessageRetentionPeriod.TextColor,,
			"e1cib/list/InformationRegister.HistoryOfSendingMessagesTo1CDocumentManagement"));
	ArrayOfStringsExplanationShelfLife.Add(" ");
	ArrayOfStringsExplanationShelfLife.Add(NStr("vi = 'và';
												|ru = 'и';
												|en = 'and'; fa = 'و';
												|it = 'and';
												|pl = 'and';
												|tr = 've'"));
	ArrayOfStringsExplanationShelfLife.Add(" ");
	ArrayOfStringsExplanationShelfLife.Add(
		New FormattedString(NStr("vi = 'trình tự gửi';
								|ru = 'очередь отправки';
								|en = 'a message sending queue'; fa = 'a message sending queue';
								|it = 'a message sending queue';
								|pl = 'a message sending queue';
								|tr = 'gönderim kuyruğu'"),,
			Items.ExplanationMessageRetentionPeriod.TextColor,,
			"e1cib/list/InformationRegister.QueueOfMessagesIn1CDocumentManagement"));
	ArrayOfStringsExplanationShelfLife.Add(" ");
	ArrayOfStringsExplanationShelfLife.Add(NStr("vi = 'thông báo';
												|ru = 'сообщений';
												|en = 'messages'; fa = 'messages';
												|it = 'messages';
												|pl = 'messages';
												|tr = 'mesaj'"));
	Items.ExplanationMessageRetentionPeriod.Title = New FormattedString(ArrayOfStringsExplanationShelfLife);
	Items.ExplanationMessageRetentionPeriodBefore3.Title = New FormattedString(ArrayOfStringsExplanationShelfLife);
	
	AbbreviatedNameOfConfiguration =
		IntegrationWith1CDocumentManagementCore.AbbreviatedNameOfConfiguration();
	If ValueIsFilled(AbbreviatedNameOfConfiguration) Then
		Items.CreateDigitalSignaturesFor1CDocumentManagementObjectsUsingIntegratedSystem.Title = StrTemplate(
			NStr("vi = 'Tạo chữ ký bằng các công cụ của %1';
				|ru = 'Создавать подписи средствами %1';
				|en = 'Create signatures using %1'; fa = 'Create signatures using %1';
				|it = 'Create signatures using %1';
				|pl = 'Create signatures using %1';
				|tr = 'İmzalar %1 araçlarıyla oluşturulsun'"),
			AbbreviatedNameOfConfiguration);
		Items.ExplanationCreateDigitalSignaturesFor1CDocumentManagementObjectsUsingIntegratedSystem.Title = StrTemplate(
			NStr("vi = 'Chữ ký điện tử cho các đối tượng của 1C:Document Management sẽ được tạo dựa trên chứng thư và các thiết lập đã được chỉ định ở phía %1';
				|ru = 'Электронные подписи объектов 1С:Документооборота будут создаваться с использованием сертификатов и настроек, указанных на стороне %1';
				|en = 'Digital signatures of 1C:Document Management objects will be created using certificates and settings specified on the %1 side.'; fa = 'Digital signatures of 1C:Document Management objects will be created using certificates and settings specified on the %1 side.';
				|it = 'Digital signatures of 1C:Document Management objects will be created using certificates and settings specified on the %1 side.';
				|pl = 'Digital signatures of 1C:Document Management objects will be created using certificates and settings specified on the %1 side.';
				|tr = '1C:Document Management nesnelerinin elektronik imzaları, %1 tarafında belirtilen sertifika ve ayarlar kullanılarak oluşturulacaktır'"),
			AbbreviatedNameOfConfiguration);
		Items.ExplanationSynchronizeConnections.Title = StrTemplate(
			NStr("vi = 'Đồng bộ hóa liên kết các đối tượng của 1C:Document Management và %1';
				|ru = 'Синхронизировать связи объектов 1С:Документооборота и %1';
				|en = 'Synchronize connections of 1C:Document Management and %1 objects'; fa = 'Synchronize connections of 1C:Document Management and %1 objects';
				|it = 'Синхронизировать связи объектов 1С:Документооборота и %1';
				|pl = 'Synchronize connections of 1C:Document Management and %1 objects';
				|tr = '1C:Document Management ve %1 nesneleri arasındaki bağlantıları senkronize et'"),
			AbbreviatedNameOfConfiguration);
		Items.ExplanationOfHoldingSettings.Title = StrTemplate(
			NStr("vi = 'Cho phép bạn chỉ định địa chỉ đăng tải của các nút phụ, cũng như thiết lập sự tương ứng của người dùng %1 với các nút của 1C:Document Management tập đoàn';
				|ru = 'Позволяет указать адреса публикации подчиненных узлов, а также задать соответствие пользователей %1 узлам 1С:Документооборота холдинга';
				|en = 'Allows you to specify the publication URLs of subordinate nodes and map %1 users to 1C:Document Management nodes of the holding company'; fa = 'Allows you to specify the publication URLs of subordinate nodes and map %1 users to 1C:Document Management nodes of the holding company';
				|it = 'Позволяет указать адреса публикации подчиненных узлов, а также задать соответствие пользователей %1 узлам 1С:Документооборота холдинга';
				|pl = 'Allows you to specify the publication URLs of subordinate nodes and map %1 users to 1C:Document Management nodes of the holding company';
				|tr = 'Alt düğümlerin yayın URL''lerinin belirlenmesine ilaveten, entegre edilmiş sistem kullanıcılarının holding şirketinin%11C:Document Management düğümleri ile yazışmalarını ayarlayabilmeyi sağlar'"),
			AbbreviatedNameOfConfiguration);
		ExplanationOfIntegrationRule = StrTemplate(
			NStr("vi = 'Xác định sự tương ứng giữa các đối tượng của 1C:Document management và %1, cũng như quy tắc điền các mục tin';
				|ru = 'Задают соответствия между объектами объектами 1С:Документооборота и %1, а также правила заполнения реквизитов';
				|en = 'Set correspondence between the 1C:Document Management objects and %1 objects, as well as attribute filling rules'; fa = 'Set correspondence between the 1C:Document Management objects and %1 objects, as well as attribute filling rules';
				|it = 'Задают соответствия между объектами объектами 1С:Документооборота и %1, а также правила заполнения реквизитов';
				|pl = 'Set correspondence between the 1C:Document Management objects and %1 objects, as well as attribute filling rules';
				|tr = '1C:Document Management ve %1 nesneleri arasındaki uygunluğun yanı sıra özniteliklerin doldurulmasına ilişkin kuralları belirler'"),
			AbbreviatedNameOfConfiguration);
		Items.ExplanationOfIntegrationRule.Title = ExplanationOfIntegrationRule;
		Items.ExplanationOfIntegrationRuleBefore3.Title = ExplanationOfIntegrationRule;
	EndIf;
	
	UpdateStorageMethodForAttachedFiles();
	UpdateSettingsUpdateRelatedDetails();
	GetRetentionPeriodOfMessagesIn1CDocumentManagement();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	Items.GroupPages.Visible = False;
	Items.HoldingCompanySettings.Visible = False;
	Items.ExternalURLHostAddress.Visible = False;
	
	If ValueIsFilled(ConstantsSet.AddressOf1CDocumentManagementWebService) Then
		CallbackDescription = New CallbackDescription("TestConnectionCompletion", ThisObject);
		IntegrationWith1CDocumentManagementCoreClient.TestConnection(
			CallbackDescription,
			ThisObject,,,,
			ConstantsSet.AddressOf1CDocumentManagementWebService);
	EndIf;
	
	SetAvailability();
	
EndProcedure

&AtClient
Procedure OnClose()
	
	RefreshApplicationInterface();
	
EndProcedure

// The alert handler of the form.
//
// Parameters:
//   EventName - String - is processed only event Zapisnik generated by the administration panels.
//   Parameter   - Structure - contains the names of constants that are subordinate to the changed constant that "triggered" the alert.
//   Source   - String - name of the changed constant that "triggered" the alert.
//
&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If Not IsOpen() Then
		Return;
	EndIf;
	
	If EventName = "IntegrationWith1CDocumentManagement_SuccessfulConnection"
			And TypeOf(Source) = Type("ClientApplicationForm")
			And Source.UUID = UUID Then
		SetVisibility1();
	EndIf;
	
	If EventName <> "Write_ConstantsSet" Then
		Return; // Such events are not processed.
	EndIf;
	
	// If it is a changed constant located in a different form and affecting the values of the constants of this form,
	// then we will read the values of the constants and update the elements of this form.
	If WorkMode.ExternalParentConstants.Property(Source)
			Or (TypeOf(Parameter) = Type("Structure")
			And GetSharedKeysOfStructures(Parameter, WorkMode.ExternalParentConstants).Count() > 0) Then
		Read();
		SetAvailability();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AuthorizationSettingsDecorationClick(Item)
	
	If Not ValueIsFilled(ConstantsSet.AddressOf1CDocumentManagementWebService) Then
		ShowMessageBox(, NStr("vi = 'Chưa chỉ ra địa chỉ web-service.';
								|ru = 'Не указан адрес веб-сервиса.';
								|en = 'A web service address is not specified.'; fa = 'A web service address is not specified.';
								|it = 'Не указан адрес веб-сервиса.';
								|pl = 'A web service address is not specified.';
								|tr = 'Web servisi adresi belirtilmedi.'"));
		Return;
	EndIf;
	
	Notification = New CallbackDescription("AuthorizationSettingsClickEnd", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("CallingToSetUpAccess", True);
	
	OpenForm(
		"DataProcessor.IntegrationWith1CDocumentManagementCore.Form.AuthorizationIn1CDocumentManagement",
		FormParameters,
		ThisObject,,,,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure UseIntegrationWith1CDocumentManagementOnChange(Item)
	
	Attachable_OnChangeAttribute(Item);
	
EndProcedure

&AtClient
Procedure AddressOf1CDocumentManagementWebServiceOnChange(Item)
	
	Attachable_OnChangeAttribute(Item, False);
	
	If ConstantsSet.AddressOf1CDocumentManagementWebService = "" Then
		If ConstantsSet.UseIntegrationWith1CDocumentManagement Then
			ConstantsSet.UseIntegrationWith1CDocumentManagement = False;
			Attachable_OnChangeAttribute(Items.UseIntegrationWith1CDocumentManagement);
		EndIf;
		If ConstantsSet.UseIntegrationWith1CDocumentManagement3 Then
			ConstantsSet.UseIntegrationWith1CDocumentManagement3 = False;
			Attachable_OnChangeAttribute(Items.UseIntegrationWith1CDocumentManagement3);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure UseRelatedDocuments1CDocumentManagementOnChange(Item)
	
	Attachable_OnChangeAttribute(Item);
	
EndProcedure

&AtClient
Procedure UseProcessesAndTasks1CDocumentManagementOnChange(Item)
	
	Attachable_OnChangeAttribute(Item);
	
EndProcedure

&AtClient
Procedure UseProcessingOf1CDocumentManagementObjectsOnChange(Item)
	
	Attachable_OnChangeAttribute(Item);
	
EndProcedure

&AtClient
Procedure UseDailyReports1CDocumentManagementOnChange(Item)
	
	Attachable_OnChangeAttribute(Item);
	
EndProcedure

&AtClient
Procedure UseEmail1CDocumentManagementOnChange(Item)
	
	Attachable_OnChangeAttribute(Item);
	
EndProcedure

&AtClient
Procedure HowToStoreAttachedFilesOnChange(Item)
	
	If HowToStoreAttachedFiles = 0 Then // Do NOT use BEFORE.
		ConstantsSet.UseAttachedFiles1CDocumentManagement = False;
		ConstantsSet.UseFileStorage1CDocumentManagement = False;
		
	ElsIf HowToStoreAttachedFiles = 1 Then // Files of related objects.
		ConstantsSet.UseAttachedFiles1CDocumentManagement = True;
		ConstantsSet.UseFileStorage1CDocumentManagement = False;
		
	Else // Files in folders.
		ConstantsSet.UseAttachedFiles1CDocumentManagement = False;
		ConstantsSet.UseFileStorage1CDocumentManagement = True;
		
	EndIf;
	
	Attachable_OnChangeAttribute(Item);
	
EndProcedure

&AtClient
Procedure NameOf1CDocumentManagementRootFilesFolderStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CallbackDescription = New CallbackDescription(
		"NameOfRootFolderOfFilesConnectionCheckEnd",
		ThisObject,
		Item);
	IntegrationWith1CDocumentManagementCoreClient.TestConnection(
		CallbackDescription,
		ThisObject,
		True);
	
EndProcedure

&AtClient
Procedure NameOfRootFolderOfFilesConnectionCheckEnd(Result, FormItem) Export
	
	If Result = True Then
		SetRootFolderOf1CDocumentManagementFiles(FormItem);
	EndIf;
	
EndProcedure

&AtClient
Procedure SetRootFolderOf1CDocumentManagementFiles(Item)
	
	FormParameters = New Structure;
	FormParameters.Insert("TypeOfSelectionObject", "DMFileFolder");
	FormParameters.Insert("Filter", Undefined);
	FormParameters.Insert("SelectedElement", ConstantsSet.IdentifierOf1CDocumentManagementRootFilesFolder);
	FormParameters.Insert("Title", NStr("vi = 'Chọn thư mục tệp';
										|ru = 'Выбор папки файлов';
										|en = 'Select file folder'; fa = 'Select file folder';
										|it = 'Selezione cartella file';
										|pl = 'Wybór folderu plików';
										|tr = 'Dosya klasörleri seçimi'"));
	
	Notification = New CallbackDescription(
		"SetRootFolderOf1CDocumentManagementFilesCompletion",
		ThisObject,
		Item);
	
	OpenForm(
		"DataProcessor.IntegrationWith1CDocumentManagementCore.Form.SelectingFromList",
		FormParameters,
		ThisObject,,,,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure NameOf1CDocumentManagementRootFilesFolderClearing(Item, StandardProcessing)
	
	ConstantsSet.IdentifierOf1CDocumentManagementRootFilesFolder = "";
	Attachable_OnChangeAttribute(Item, False);
	
EndProcedure

&AtClient
Procedure MaximumFileSizeForTransferIn1CDocumentManagementOnChange(Item)
	
	Attachable_OnChangeAttribute(Item, False, "MaximumFileSizeForTransferIn1CDocumentManagement");
	
EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)
	
	If FormattedStringURL = "ModifySchedule" Then
		
		StandardProcessing = False;
		
		CallbackDescription = New CallbackDescription("ScheduleSettingsDialogCompletion", ThisObject);
		
		ScheduleSettingsDialog = New ScheduledJobDialog(TaskSchedule());
		ScheduleSettingsDialog.Show(CallbackDescription);
		
	ElsIf FormattedStringURL = "EnterUsernameAndPassword" Then
		
		StandardProcessing = False;
		
		FormParameters = New Structure;
		FormParameters.Insert("CallingExchangeJobForUser", True);
		
		OpenForm("DataProcessor.IntegrationWith1CDocumentManagementCore.Form.AuthorizationIn1CDocumentManagement",
			FormParameters,
			ThisObject,,,,
			New CallbackDescription("UserInputForSharingEnd", ThisObject),
			FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateRelatedObjectsAutomaticallyOnChange(Item)
	
	UpdateUseOfRoutineTask(UpdateRelatedObjectsAutomatically);
	
EndProcedure

&AtClient
Procedure TermOfStorageOfMessagesTo1CDocumentManagementOnChange(Item)
	
	Attachable_OnChangeAttribute(Item, False, "TermOfStorageOfMessagesTo1CDocumentManagement");
	
EndProcedure

&AtClient
Procedure DecorationHoldingCompanySettingsClick(Item)
	
	NameOfConfigurationForm = "DataProcessor.IntegrationWith1CDocumentManagement3.Form.HoldingCompanySettings";
	FormParameters = New Structure("AddressOfCentralSUBAsset", ConstantsSet.AddressOf1CDocumentManagementWebService);
	OpenForm(NameOfConfigurationForm, FormParameters, ThisObject,,,,, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure CreateDigitalSignaturesFor1CDocumentManagementObjectsUsingIntegratedSystemOnChange(Item)
	
	Attachable_OnChangeAttribute(Item);
	
EndProcedure

&AtClient
Procedure UseAttachedFiles1CDocumentManagementOnChange(Item)
	
	Attachable_OnChangeAttribute(Item);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ExternalURLHostAddress(Command)
	
	DataOfSUBAsset = DataOfSUBAsset("");
	ClosingNotification1 = New CallbackDescription(
		"HostAddressOfExternalNavigationLinksONChange",
		ThisObject,
		DataOfSUBAsset);
	FormNameHostAddress = "DataProcessor.IntegrationWith1CDocumentManagement3.Form.ExternalURLHostAddress";
	OpenForm(FormNameHostAddress, DataOfSUBAsset,,,,, ClosingNotification1);
	
EndProcedure

&AtClient
Procedure HostAddressOfExternalNavigationLinksONChange(Result, DataOfSUBAsset) Export
	
	If TypeOf(Result) <> Type("Structure") Then
		Return;
	EndIf;
	
	DataOfSUBAsset.ExternalURLHostAddress = Result.ExternalURLHostAddress;
	DataOfSUBAsset.LocationTypeOfExternalURLHostAddress = Result.LocationTypeOfExternalURLHostAddress;
	
	ToSetDataOfSUBAsset("", DataOfSUBAsset);
	
EndProcedure

&AtClient
Procedure IntegratedObjects(Command)
	
	NameOfIntegratedObjectsForm = "Catalog.RulesForIntegrationWith1CDocumentManagement.Form.IntegratedObjects";
	OpenForm(NameOfIntegratedObjectsForm, , ThisObject);
	
EndProcedure

&AtClient
Procedure RulesForIntegration(Command)
	
	ListFormName = "Catalog.RulesForIntegrationWith1CDocumentManagement.Form.ListForm";
	OpenForm(ListFormName, , ThisObject);
	
EndProcedure

&AtClient
Procedure RulesForIntegrationBefore3(Command)
	
	ListFormName = "Catalog.RulesForIntegrationWith1CDocumentManagement3.Form.ListForm";
	OpenForm(ListFormName, , ThisObject);
	
EndProcedure

&AtClient
Procedure IdOfThisDatabase(Command)
	
	ShowValue(, ThisNode());
	
EndProcedure

#EndRegion

#Region Private

#Region Client

&AtClient
Procedure UserInputForSharingEnd(Result, NotificationParameters) Export
	
	If Result = True Then
		UpdateSettingsUpdateRelatedDetails();
	EndIf;
	
EndProcedure

&AtClient
Procedure TestConnectionCompletion(Result, NotificationParameters) Export
	
	If Result = True Then
		
		SetVisibility1();
		
		If Left(ServiceVersion, 1) = "2"
				And ThereIsSubsystemUPTo3
				And ConstantsSet.UseIntegrationWith1CDocumentManagement3 Then
			ConstantsSet.UseIntegrationWith1CDocumentManagement3 = False;
			Attachable_OnChangeAttribute(Items.UseIntegrationWith1CDocumentManagement3);
			
		ElsIf Left(ServiceVersion, 1) = "3"
				And ThereIsSubsystemUPTo2
				And ConstantsSet.UseIntegrationWith1CDocumentManagement Then
			ConstantsSet.UseIntegrationWith1CDocumentManagement = False;
			Attachable_OnChangeAttribute(Items.UseIntegrationWith1CDocumentManagement);
			
		EndIf;
		
		If Left(ServiceVersion, 1) = "3"
				And ThereIsSubsystemUPTo3
				And ConstantsSet.UseIntegrationWith1CDocumentManagement3 Then
			InstallSubAsset();
		EndIf;
		
	Else // Couldn't connect to BEFORE.
		
		Notification = New CallbackDescription("AuthorizationSettingsClickEnd", ThisObject);
		
		FormParameters = New Structure;
		FormParameters.Insert("ConnectingToCentralSubAsset", True);
		
		OpenForm(
			"DataProcessor.IntegrationWith1CDocumentManagementCore.Form.AuthorizationIn1CDocumentManagement",
			FormParameters,
			ThisObject,,,,
			Notification,
			FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AuthorizationSettingsClickEnd(Result, NotificationParameters) Export
	
	SetVisibility1();
	
	If Result = True Then
		UpdateSettingsUpdateRelatedDetails();
	EndIf;
	
EndProcedure

&AtClient
Procedure ScheduleSettingsDialogCompletion(Schedule, NotificationParameters) Export
	
	If Schedule <> Undefined Then
		UpdateUseOfRoutineTask(UpdateRelatedObjectsAutomatically, Schedule);
	EndIf;
	
EndProcedure

&AtClient
Procedure SetAvailability()
	
	If ThereIsSubsystemUPTo2 Then
		
		ConstantValue = ConstantsSet.UseIntegrationWith1CDocumentManagement;
		SetAvailabilityOfIntegrationUsage(ConstantValue);
		
		ConstantValue = ConstantsSet.UseFileStorage1CDocumentManagement;
		Items.NameOf1CDocumentManagementRootFilesFolder.Enabled = ConstantValue;
		
	EndIf;
	
	If ThereIsSubsystemUPTo3 Then
		
		ConstantValue = ConstantsSet.UseIntegrationWith1CDocumentManagement3;
		SetAvailabilityOfIntegrationUsageBefore3(ConstantValue);
		
	EndIf;
	
	Items.ExternalURLHostAddress.Enabled =
		ValueIsFilled(ConstantsSet.AddressOf1CDocumentManagementWebService);
	
EndProcedure

&AtClient
Procedure SetAvailabilityOfIntegrationUsage(Value)
	
	If Not Items.ActivationGroup.Enabled Then
		Items.ActivationGroup.Enabled = True;
		
		If ValueIsFilled(ConstantsSet.AddressOf1CDocumentManagementWebService) Then
			CallbackDescription = New CallbackDescription("TestConnectionCompletion", ThisObject);
			IntegrationWith1CDocumentManagementCoreClient.TestConnection(
				CallbackDescription,
				ThisObject,,,,
				ConstantsSet.AddressOf1CDocumentManagementWebService);
		Else
			SetVisibility1();
		EndIf;
	EndIf;
	
	Items.UseProcessesAndTasks1CDocumentManagement.Enabled = Value;
	Items.UseRelatedDocuments1CDocumentManagement.Enabled = Value;
	Items.UseDailyReports1CDocumentManagement.Enabled = Value;
	Items.UseEmail1CDocumentManagement.Enabled = Value;
	Items.HowToStoreAttachedFiles.Enabled = Value;
	Items.FieldGroupMaximumFileSizeToTransfer.Enabled = Value;
	Items.IntegratedObjects.Enabled = Value;
	Items.RulesForIntegration.Enabled = Value;
	
	Items.AutoUpdateGroupBefore2.Enabled = Value And AdministrationRightIsAvailable;
	Items.UpdateSetupCommandsBefore2.Enabled = Value And AdministrationRightIsAvailable;
	Items.GroupShelfLifeUPTo2.Enabled = Value And AdministrationRightIsAvailable;
	
EndProcedure

&AtClient
Procedure SetAvailabilityOfIntegrationUsageBefore3(Value)
	
	If Not Items.ActivationGroup.Enabled Then
		Items.ActivationGroup.Enabled = True;
		
		If ValueIsFilled(ConstantsSet.AddressOf1CDocumentManagementWebService) Then
			CallbackDescription = New CallbackDescription("TestConnectionCompletion", ThisObject);
			IntegrationWith1CDocumentManagementCoreClient.TestConnection(
				CallbackDescription,
				ThisObject,,,,
				ConstantsSet.AddressOf1CDocumentManagementWebService);
		Else
			SetVisibility1();
		EndIf;
	EndIf;
	
	Items.UseProcessingOf1CDocumentManagementObjects.Enabled = Value;
	Items.CreateDigitalSignaturesFor1CDocumentManagementObjectsUsingIntegratedSystem.Enabled = Value;
	Items.UseAttachedFiles1CDocumentManagement.Enabled = Value;
	Items.FieldGroupMaximumFileSizeToTransferBefore3.Enabled = Value;
	Items.SynchronizeLinks.Enabled = Value;
	Items.IdOfThisDatabase.Enabled = Value;
	Items.RulesForIntegrationBefore3.Enabled = Value;
	
	Items.AutoUpdateGroupBefore3.Enabled = Value And AdministrationRightIsAvailable;
	Items.UpdateSetupCommandsBefore3.Enabled = Value And AdministrationRightIsAvailable;
	Items.GroupShelfLifeUPTO3.Enabled = Value And AdministrationRightIsAvailable;
	
EndProcedure

&AtClient
Procedure SetRootFolderOf1CDocumentManagementFilesCompletion(Result, Item) Export
	
	If TypeOf(Result) = Type("Structure") Then
		ConstantsSet.NameOf1CDocumentManagementRootFilesFolder  = Result.AttributePresentation;
		ConstantsSet.IdentifierOf1CDocumentManagementRootFilesFolder = Result.AttributeID;
	EndIf;
	
	Attachable_OnChangeAttribute(Item, False);
	
EndProcedure

&AtClient
Procedure Attachable_OnChangeAttribute(Item, ShouldRefreshInterface = True, ConstantName = "")
	
	OnChangeAttributeServer(Item.Name, ConstantName);
	
	If ConstantName = "UseIntegrationWith1CDocumentManagement"
			And Not ConstantsSet.UseIntegrationWith1CDocumentManagement Then
		SetAvailabilityOfIntegrationUsage(False);
	EndIf;
	
	If ConstantName = "UseIntegrationWith1CDocumentManagement3"
			And Not ConstantsSet.UseIntegrationWith1CDocumentManagement3 Then
		SetAvailabilityOfIntegrationUsageBefore3(False);
	EndIf;
	
	If ConstantName = "AddressOf1CDocumentManagementWebService" Then
		Items.ActivationGroup.Enabled = False;
	EndIf;
	
	If ShouldRefreshInterface Then
#If Not WebClient Then
		AttachIdleHandler("RefreshApplicationInterface", 1, True);
		RefreshInterface = True;
#Else
		SetAvailability();
#EndIf
	Else
		SetAvailability();
	EndIf;
	
	If ConstantName <> "" Then
		Notify("Write_ConstantsSet", New Structure, ConstantName);
	EndIf;
	
EndProcedure

&AtClient
Procedure RefreshApplicationInterface()
	
	If RefreshInterface = True Then
		RefreshInterface = False;
		RefreshInterface();
	EndIf;
	
	SetAvailability();
	
EndProcedure

&AtClient
Function GetSharedKeysOfStructures(Structure1, Structure2)
	
	Result = New Structure;
	
	For Each KeyAndValue In Structure1 Do
		If Structure2.Property(KeyAndValue.Key) Then
			Result.Insert(KeyAndValue.Key);
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Server

&AtServer
Procedure SetVisibility1()
	
	Items.GroupPages.Visible = False;
	Items.HoldingCompanySettings.Visible = False;
	Items.ExternalURLHostAddress.Visible = False;
	
	ServiceVersion = IntegrationWith1CDocumentManagementCore.ServiceVersion();
	
	If IntegrationWith1CDocumentManagementCoreClientServer.ServiceIsAvailable(ServiceVersion) Then
		
		EditionNumber = Left(ServiceVersion, 1);
		
		Items.GroupPages.Visible = True;
		If EditionNumber = "1" Then
			Items.GroupPages.CurrentPage = Items.VersionPageIsNotSupported;
			Items.DecorationDescriptionVersionIsNotSupported.Title = NStr(
				"vi = 'Không hỗ trợ tích hợp với 1C:Document Management phiên bản 1.';
				|ru = 'Интеграция с 1С:Документооборот редакции 1 не поддерживается.';
				|en = 'Integration with 1C:Document Management (revision 1) is not supported.'; fa = 'Integration with 1C:Document Management (revision 1) is not supported.';
				|it = 'Integrazione con 1C:Document Management non è supportata.';
				|pl = 'Integracja z 1C:Document Management edycji 1 nie jest obsługiwana.';
				|tr = '1C:Document Management revizyon 1 ile entegrasyon desteklenmiyor.'");
			
		ElsIf EditionNumber = "2" Then
			If ThereIsSubsystemUPTo2 Then
				Items.GroupPages.CurrentPage = Items.GroupIntegrationWith1CDocumentManagementEdition2;
			Else
				Items.GroupPages.CurrentPage = Items.VersionPageIsNotSupported;
				Items.DecorationDescriptionVersionIsNotSupported.Title = NStr(
					"vi = 'Không hỗ trợ tích hợp với 1C:Document Management phiên bản 2.';
					|ru = 'Интеграция с 1С:Документооборот редакции 2 не поддерживается.';
					|en = 'Integration with 1C:Document Management (revision 2) is not supported.'; fa = 'Integration with 1C:Document Management (revision 2) is not supported.';
					|it = 'Integrazione con 1C:Document Management versione 2 non è supportata.';
					|pl = 'Integracja z 1C:Document Management edycji 2 nie jest obsługiwana.';
					|tr = '1C:Document Management revizyon 2 ile entegrasyon desteklenmiyor.'");
			EndIf;
			
		ElsIf EditionNumber = "3" Then
			If ThereIsSubsystemUPTo3 Then
				If IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable("3.0.7.31") Then
					Items.GroupPages.CurrentPage = Items.GroupIntegrationWith1CDocumentManagementEdition3;
					Items.ExternalURLHostAddress.Visible = True;
				Else
					Items.GroupPages.CurrentPage = Items.VersionPageIsNotSupported;
					Items.DecorationDescriptionVersionIsNotSupported.Title = NStr(
						"vi = 'Chức năng không được hỗ trợ trong phiên bản 1C:Document Management hiện tại.
						|Cần có phiên bản 1C:Document Management từ 3.0.7 trở lên.';
						|ru = 'Функционал не поддерживается в данной версии 1С:Документооборота.
						|Требуется 1С:Документооборот версии 3.0.7 или выше.';
						|en = 'Functionality is not supported in this version of 1C:Document Management.
						|Version 3.0.7 or later is required.'; fa = 'این قابلیت در این نسخه از 1C:Document Management پشتیبانی نمی‌شود.
						|نسخه 3.0.7 یا بالاتر لازم است.';
						|it = 'La funzione non è supportata da questa versione di 1C:Document Management.
						|Si richiede 1C:Document Management versione 3.0.7 o successive.';
						|pl = 'Funkcjonalność nie jest obsługiwana w tej wersji 1C:Document Management.
						|Wymagany jest 1C:Document Management wersji 3.0.7 lub wyżej.';
						|tr = 'Fonksiyonellik 1C:Document Management''ın bu sürümünde desteklenmemektedir.
						|1C:Document Management 3.0.7 veya üstü sürüm gerekmektedir.'");
				EndIf;
				LinkSynchronizationIsAvailable = IntegrationWith1CDocumentManagementCore.FunctionalityOfServiceVersionIsAvailable(
					"3.0.11.25");
				Items.SynchronizeLinks.Visible = LinkSynchronizationIsAvailable;
				Items.ExplanationSynchronizeConnections.Visible = LinkSynchronizationIsAvailable;
				Items.DecorationSeparatingOtherGroupUPTO3.Visible = LinkSynchronizationIsAvailable;
			Else
				Items.GroupPages.CurrentPage = Items.VersionPageIsNotSupported;
				Items.DecorationDescriptionVersionIsNotSupported.Title = NStr(
					"vi = 'Không hỗ trợ tích hợp với 1C:Document Management phiên bản 3.';
					|ru = 'Интеграция с 1С:Документооборот редакции 3 не поддерживается.';
					|en = 'Integration with 1C:Document Management (revision 3) is not supported.'; fa = 'Integration with 1C:Document Management (revision 3) is not supported.';
					|it = 'Integrazione con 1C:Document Management versione 3 non è supportata.';
					|pl = 'Integracja z 1C:Document Management edycji 3 nie jest obsługiwana.';
					|tr = '1C:Document Management revizyon 3 ile entegrasyon desteklenmiyor.'");
			EndIf;
			
		Else
			Items.GroupPages.CurrentPage = Items.VersionPageIsNotSupported;
			Items.DecorationDescriptionVersionIsNotSupported.Title = StrTemplate(
				NStr("vi = 'Không hỗ trợ tích hợp với 1C:Document Management phiên bản %1.';
					|ru = 'Интеграция с 1С:Документооборот редакции %1 не поддерживается.';
					|en = 'Integration with 1C:Document Management (revision %1) is not supported.'; fa = 'Integration with 1C:Document Management (revision %1) is not supported.';
					|it = 'Integrazione con 1C:Document Management versione %1 non è supportata.';
					|pl = 'Integracja z 1C:Document Management edycji %1 nie jest obsługiwana.';
					|tr = '1C:Document Management revizyon %1 ile entegrasyon desteklenmiyor.'"),
				EditionNumber);
			
		EndIf;
		
		Items.HoldingCompanySettings.Visible = (Right(ServiceVersion, 11) = "HOLD_CENTER");
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateStorageMethodForAttachedFiles()
	
	If ConstantsSet.UseAttachedFiles1CDocumentManagement Then
		HowToStoreAttachedFiles = 1;
	ElsIf ConstantsSet.UseFileStorage1CDocumentManagement Then
		HowToStoreAttachedFiles = 2;
	Else
		HowToStoreAttachedFiles = 0;
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateUseOfRoutineTask(Use, Schedule = Undefined)
	
	If Use And IsBlankString(Constants.IntegrationWith1CDocumentManagementUsernameForExchange.Get()) Then
		UpdateRelatedObjectsAutomatically = False;
		Raise NStr("vi = 'Chưa xác định người sử dụng hệ thống để trao đổi';
					|ru = 'Не задан служебный пользователь для обмена';
					|en = 'A utility user for exchange is not set'; fa = 'A utility user for exchange is not set';
					|it = 'Не задан служебный пользователь для обмена';
					|pl = 'A utility user for exchange is not set';
					|tr = 'Değişim için hizmet kullanıcısı girilmemiş'");
	EndIf;
	
	JobParameters = New Structure("Use", Use);
	
	Jobs = ScheduledJobsServer.FindJobs(New Structure("Metadata",
		Metadata.ScheduledJobs.ExchangeDataWith1CDocumentManagement));
	
	If Jobs.Count() = 0 Then
		
		JobParameters.Insert("Metadata", Metadata.ScheduledJobs.ExchangeDataWith1CDocumentManagement);
		
		Schedule = New JobSchedule;
		Schedule.DaysRepeatPeriod = 1;
		Schedule.RepeatPeriodInDay = 120;
		JobParameters.Insert("Schedule", Schedule);
		
		ScheduledJobsServer.AddJob(JobParameters);
		
	Else
		
		If Schedule <> Undefined Then
			JobParameters.Insert("Schedule", Schedule);
		EndIf;
		
		For Each Job In Jobs Do
			ScheduledJobsServer.ChangeJob(Job.UUID, JobParameters);
		EndDo;
		
	EndIf;
	
	UpdateSettingsUpdateRelatedDetails();
	
EndProcedure

&AtServer
Procedure UpdateSettingsUpdateRelatedDetails()
	
	UpdateRelatedObjectsAutomatically = False;
	DescriptionOfUpdateSettings = New FormattedString(NStr("vi = 'Lịch biểu không khả dụng';
															|ru = 'Расписание не доступно';
															|en = 'Schedule is unavailable'; fa = 'Schedule is unavailable';
															|it = 'Orario non disponibile';
															|pl = 'Harmonogram nie jest dostępny';
															|tr = 'Program erişilebilir değil'"));
	
	If Not AdministrationRightIsAvailable Then
		Return;
	EndIf;
	
	Jobs = ScheduledJobsServer.FindJobs(New Structure("Metadata",
		Metadata.ScheduledJobs.ExchangeDataWith1CDocumentManagement));
	
	If Jobs.Count() > 0 Then
		UpdateRelatedObjectsAutomatically = Jobs[0].Use;
		DescriptionOfUpdateSettings = New FormattedString(String(Jobs[0].Schedule));
	EndIf;
	
	ArrayOfCommandLines = New Array;
	
	RefRow = New FormattedString(NStr("vi = 'Thay đổi lịch biểu';
										|ru = 'Изменить расписание';
										|en = 'Change schedule'; fa = 'تغییر زمان‌بندی';
										|it = 'Modificare l''orario';
										|pl = 'Zmień harmonogram';
										|tr = 'Programı değiştirmek'"),,,, "ModifySchedule");
	ArrayOfCommandLines.Add(RefRow);
	
	ArrayOfCommandLines.Add("  ");
	
	UserNameForExchange = Constants.IntegrationWith1CDocumentManagementUsernameForExchange.Get();
	If IsBlankString(UserNameForExchange) Then
		CommandName = NStr("vi = 'Đặt người sử dụng dịch vụ để trao đổi';
							|ru = 'Задать служебного пользователя для обмена';
							|en = 'Set a utility user for exchange'; fa = 'Set a utility user for exchange';
							|it = 'Задать служебного пользователя для обмена';
							|pl = 'Wyznacz służbowego użytkownika dla wymiany';
							|tr = 'Değişim için hizmet kullanıcısını ayarla'");
	Else
		PositionOfAdditionalInfo = StrFind(UserNameForExchange, "(");
		If PositionOfAdditionalInfo > 0 Then
			UserNameForExchange = TrimAll(Mid(UserNameForExchange, 1, PositionOfAdditionalInfo - 1));
		EndIf;
		CommandName = StrTemplate(NStr("vi = 'Thay đổi người sử dụng để trao đổi (%1)';
										|ru = 'Изменить пользователя для обмена (%1)';
										|en = 'Change the user for exchange (%1)'; fa = 'Change the user for exchange (%1)';
										|it = 'Изменить пользователя для обмена (%1)';
										|pl = 'Change the user for exchange (%1)';
										|tr = 'Değiştirilecek kullanıcıyı değiştir (%1)'"), UserNameForExchange);
	EndIf;
	RefRow = New FormattedString(CommandName,,,, "EnterUsernameAndPassword");
	ArrayOfCommandLines.Add(RefRow);
	
	UpdateSetupCommands = New FormattedString(ArrayOfCommandLines);
	
EndProcedure

&AtServer
Function TaskSchedule()
	
	Jobs = ScheduledJobsServer.FindJobs(New Structure("Metadata",
		Metadata.ScheduledJobs.ExchangeDataWith1CDocumentManagement));
	
	If Jobs.Count() = 0 Then
		
		UpdateRelatedObjectsAutomatically =
			Not IsBlankString(Constants.IntegrationWith1CDocumentManagementUsernameForExchange.Get());
		
		JobParameters = New Structure("Use", UpdateRelatedObjectsAutomatically);
		JobParameters.Insert("Metadata", Metadata.ScheduledJobs.ExchangeDataWith1CDocumentManagement);
		
		Schedule = New JobSchedule;
		Schedule.DaysRepeatPeriod = 1;
		Schedule.RepeatPeriodInDay = 120;
		JobParameters.Insert("Schedule", Schedule);
		
		ScheduledJobsServer.AddJob(JobParameters);
		
		Return Schedule;
		
	Else
		
		Return Jobs[0].Schedule;
		
	EndIf;
	
EndFunction

&AtServer
Procedure OnChangeAttributeServer(TagName, ConstantName)
	
	DataPathAttribute = Items[TagName].DataPath;
	
	SaveAttributeValue(DataPathAttribute, ConstantName);
	
	If ConstantName = "UseIntegrationWith1CDocumentManagement"
			Or ConstantName = "UseIntegrationWith1CDocumentManagement3" Then
		UpdateStorageMethodForAttachedFiles();
		UpdateSettingsUpdateRelatedDetails();
	EndIf;
	
	If ConstantName = "AddressOf1CDocumentManagementWebService" Then
		SessionParameters.IntegrationWith1CDocumentManagementNode = "";
		IntegrationWith1CDocumentManagementCoreServerCall.ResetInternetConnectionCache();
		If Not ValueIsFilled(ConstantsSet.AddressOf1CDocumentManagementWebService) Then
			SessionParameters.IntegrationWith1CDocumentManagementServiceVersion = "0.0.0.0";
		EndIf;
	Else
		IntegrationWith1CDocumentManagementCore.UpdateReusedParameters();
	EndIf;
	
EndProcedure

&AtServer
Procedure SaveAttributeValue(DataPathAttribute, ConstantName = "", RereadForm = True)
	
	// Storing the values of the details that are not directly related to the constants (in a one-to-one relationship).
	If DataPathAttribute = "" Then
		Return;
	EndIf;
	
	If ConstantName = "" Then
		// Definition of the constant name.
		ArrayOfPartsPropsDataPath = StrSplit(DataPathAttribute, ".");
		If ArrayOfPartsPropsDataPath.Count() = 2
				And Lower(ArrayOfPartsPropsDataPath[0]) = Lower("ConstantsSet") Then
			// If the path to the data of the props is specified through the "Setconstant".
			ConstantName = ArrayOfPartsPropsDataPath[1];
		EndIf;
	EndIf;
	
	// Defining the name and recording the value of the props in the corresponding constant from the "Setconstant".
	// It is used for those form details that are directly related to constants (in a one-to-one relationship).
	If DataPathAttribute = "MaximumFileSizeForTransferIn1CDocumentManagement"
			Or ConstantName = "MaximumFileSizeForTransferIn1CDocumentManagement" Then
		ConstantsSet.MaximumFileSizeForTransferIn1CDocumentManagement =
			MaximumFileSizeForTransferIn1CDocumentManagement * (1024*1024);
		ConstantName = "MaximumFileSizeForTransferIn1CDocumentManagement";
		
	ElsIf DataPathAttribute = "TermOfStorageOfMessagesTo1CDocumentManagement"
			Or ConstantName = "TermOfStorageOfMessagesTo1CDocumentManagement" Then
		ConstantsSet.TermOfStorageOfMessagesTo1CDocumentManagement = TermOfStorageOfMessagesTo1CDocumentManagement;
		ConstantName = "TermOfStorageOfMessagesTo1CDocumentManagement";
		
	EndIf;
	
	// Saving the value of a constant.
	If ConstantName <> "" Then
		ConstantManager = Constants[ConstantName];
		ConstantValue = ConstantsSet[ConstantName];
		
		If ConstantManager.Get() <> ConstantValue Then
			ConstantManager.Set(ConstantValue);
		EndIf;
		
		If ThereAreSubordinateConstants(ConstantName, ConstantValue) And RereadForm Then
			Read();
		EndIf;
		
	EndIf;
	
	If ConstantName = "NameOf1CDocumentManagementRootFilesFolder" Then
		SaveAttributeValue("ConstantsSet.IdentifierOf1CDocumentManagementRootFilesFolder");
	EndIf;
	
	If DataPathAttribute = "HowToStoreAttachedFiles" Then
		SaveAttributeValue("ConstantsSet.UseFileStorage1CDocumentManagement",, False);
		SaveAttributeValue("ConstantsSet.UseAttachedFiles1CDocumentManagement");
		ConstantName = "UseAttachedFiles1CDocumentManagement";
	EndIf;
	
	If ConstantName = "UseIntegrationWith1CDocumentManagement3" And ConstantValue = True Then
		InstallSubAsset();
	EndIf;
	
EndProcedure

&AtServer
Procedure GetRetentionPeriodOfMessagesIn1CDocumentManagement()
	
	TermOfStorageOfMessagesTo1CDocumentManagement = ConstantsSet.TermOfStorageOfMessagesTo1CDocumentManagement;
	
	If TermOfStorageOfMessagesTo1CDocumentManagement = 0 Then
		TermOfStorageOfMessagesTo1CDocumentManagement = 30; // OfDays
		SaveAttributeValue("TermOfStorageOfMessagesTo1CDocumentManagement");
	EndIf;
	
EndProcedure

&AtServer
Procedure GetMaximumSizeOfTransmittedFile()
	
	MaximumFileSizeForTransferIn1CDocumentManagement =
		ConstantsSet.MaximumFileSizeForTransferIn1CDocumentManagement / (1024*1024);
	
	If MaximumFileSizeForTransferIn1CDocumentManagement = 0 Then
		MaximumFileSizeForTransferIn1CDocumentManagement = 10; // mb
		SaveAttributeValue("MaximumFileSizeForTransferIn1CDocumentManagement");
	EndIf;
	
EndProcedure

&AtServer
Function CompositionOfSetOfConstants(Set)
	
	Result = New Structure;
	
	For Each MetaConstant In Metadata.Constants Do
		If HasObjectAttribute(Set, MetaConstant.Name) Then
			Result.Insert(MetaConstant.Name);
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

&AtServer
Function HasObjectAttribute(Object, Var_AttributeName)
	
	ObjectUniquenessKey = New UUID;
	AttributeStructure = New Structure(Var_AttributeName, ObjectUniquenessKey);
	
	FillPropertyValues(AttributeStructure, Object);
	
	Return AttributeStructure[Var_AttributeName] <> ObjectUniquenessKey;
	
EndFunction

&AtServer
Function ThereAreSubordinateConstants(NameOfParentConstant, ValueOfParentConstant)
	
	TableOfConstants = IntegrationWith1CDocumentManagementCore.DependenciesOfConstants();
	
	SubordinateConstants = TableOfConstants.FindRows(
		New Structure(
			"NameOfParentConstant, ValueOfParentConstant",
			NameOfParentConstant, ValueOfParentConstant));
	
	Return SubordinateConstants.Count() > 0;
	
EndFunction

&AtServer
Function ParentConstants(StructureOfSubordinateConstants)
	
	Result = New Structure;
	TableOfConstants = IntegrationWith1CDocumentManagementCore.DependenciesOfConstants();
	
	For Each DesiredConstant In StructureOfSubordinateConstants Do
		
		ParentConstants = TableOfConstants.FindRows(
			New Structure("NameOfSubordinateConstant", DesiredConstant.Key));
		
		For Each ParentLevelRow In ParentConstants Do
			
			If Result.Property(ParentLevelRow.NameOfParentConstant)
					Or StructureOfSubordinateConstants.Property(ParentLevelRow.NameOfParentConstant) Then
				Continue;
			EndIf;
			
			Result.Insert(ParentLevelRow.NameOfParentConstant);
			
			ParentSParents = ParentConstants(New Structure(ParentLevelRow.NameOfParentConstant));
			
			For Each ParentOfParent In ParentSParents Do
				Result.Insert(ParentOfParent.Key);
			EndDo;
			
		EndDo;
		
	EndDo;
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function ThisNode()
	
	Return ExchangePlans.IntegrationWith1CDocumentManagementSubsystemOverridable.ThisNode();
	
EndFunction

&AtServer
Procedure InstallSubAsset()
	
	SessionParameters.IntegrationWith1CDocumentManagementNode = "";
	If Left(ServiceVersion, 1) = "3" And ThereIsSubsystemUPTo3 Then
		ModuleIntegrationWith1CDocumentManagement3 = Common.CommonModule("IntegrationWith1CDocumentManagement3");
		SessionParameters.IntegrationWith1CDocumentManagementNode =
			ModuleIntegrationWith1CDocumentManagement3.CurrentUserSSUBAsset();
	EndIf;
	
EndProcedure

&AtServer
Function DataOfSUBAsset(NodeID)
	
	If ThereIsSubsystemUPTo3 Then
		RegisterName = "DataOf1CDocumentManagementNodes";
		RegisterDataOf1CDocumentManagementNodes = InformationRegisters[RegisterName];
		Return RegisterDataOf1CDocumentManagementNodes.DataOfSUBAsset(NodeID);
	EndIf;
	
EndFunction

&AtServer
Procedure ToSetDataOfSUBAsset(NodeID, DataOfSUBAsset)
	
	If ThereIsSubsystemUPTo3 Then
		RegisterName = "DataOf1CDocumentManagementNodes";
		RegisterDataOf1CDocumentManagementNodes = InformationRegisters[RegisterName];
		RegisterDataOf1CDocumentManagementNodes.ToSetDataOfSUBAsset(NodeID, DataOfSUBAsset);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
