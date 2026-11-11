#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	// StandardSubsystems.Properties
	If Common.SubsystemExists("StandardSubsystems.Properties") Then
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
		ModulePropertyManager = Common.CommonModule("PropertyManager");
		ModulePropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	EndIf;
	// End StandardSubsystems.Properties
	
	DefaultLanguageCode = Common.DefaultLanguageCode();
	Items.FormValidate.Enabled = AccessRight("Update", Metadata.Catalogs.UserNotificationKinds);
	
	If Object.Ref.IsEmpty() Then
		OnCreatReadAtServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	If CommonClient.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManagerClient = CommonClient.CommonModule("PropertyManagerClient");
		ModulePropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.Properties
	If CommonClient.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManagerClient = CommonClient.CommonModule("PropertyManagerClient");
		If ModulePropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
			UpdateAdditionalAttributesItems();
			ModulePropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
		EndIf;
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.Properties
	If Common.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManager = Common.CommonModule("PropertyManager");
		ModulePropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	OnCreatReadAtServer(CurrentObject);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.Properties
	If Common.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManager = Common.CommonModule("PropertyManager");
		ModulePropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.Properties	
	
	DataCompositionSchema = DataCompositionSchemaByDefault();
	If IsTempStorageURL(DCSAddress) Then
		DataCompositionSchema = GetFromTempStorage(DCSAddress);
	EndIf;
	If HasChanges(DataCompositionSchema, DataCompositionSchemaByDefault()) Then
		CurrentObject.DataCompositionSchema = New ValueStorage(DataCompositionSchema);
	Else
		CurrentObject.DataCompositionSchema = New ValueStorage(Undefined);
	EndIf;
	
	DataCompositionSettings = Undefined;
	If IsTempStorageURL(DCSSettingsAddress) Then
		DataCompositionSettings = GetFromTempStorage(DCSSettingsAddress);
	EndIf;
	If ValueIsFilled(DataCompositionSettings)
		And HasChanges(DataCompositionSettings, DefaultSchemaSettings(DataCompositionSchema)) Then
		
		CurrentObject.StorageOfDataCompositionSettings = New ValueStorage(DataCompositionSettings);
	Else
		CurrentObject.StorageOfDataCompositionSettings = New ValueStorage(Undefined);
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	SetFormHeader();
	FillInPresentationsOfDataSources();
	FillInSuppliedInfo();
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	If Common.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManager = Common.CommonModule("PropertyManager");
		ModulePropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure NotificationTypeOnChange(Item)
	AvailabilityControl(ThisObject);
EndProcedure

&AtClient
Procedure NotificationTextTemplateClick(Item, StandardProcessing)
	StandardProcessing = False;
	OpeningParameters = New Structure;
	OpeningParameters.Insert("NotificationTextTemplate", Object.NotificationTextTemplate);
	OpeningParameters.Insert("SubstitutionParameters", AvailableFields());
	Notification = New CallbackDescription("NotificationTextTemplateClickCompletion", ThisObject);
	OpenForm("Catalog.UserNotificationKinds.Form.TemplateSetup",
		OpeningParameters,
		ThisObject,,,,
		Notification);
EndProcedure

&AtClient
Procedure GroupedNotificationTextClick(Item, StandardProcessing)
	StandardProcessing = False;
	OpeningParameters = New Structure;
	OpeningParameters.Insert("NotificationTextTemplate", Object.GroupedNotificationText);
	Notification = New CallbackDescription("GroupedNotificationTextClickCompletion", ThisObject);
	OpenForm("Catalog.UserNotificationKinds.Form.TemplateSetup",
		OpeningParameters,
		ThisObject,,,,
		Notification);
EndProcedure

&AtClient
Procedure InformationTextURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	If FormattedStringURL = "Refill" Then
		Modified = True;
		ReFillNotificationView();
	EndIf;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDataSources

&AtClient
Procedure DataSourcesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	Cancel = True;
	Modified = True;
	
	Notification = New CallbackDescription("PickSourcesCompletion", ThisObject);
	OpenForm("Catalog.UserNotificationKinds.Form.PickSources",,
		ThisObject, 
		UUID,,,
		Notification);
EndProcedure

&AtClient
Procedure DataSourcesSourceDetails_StartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	CurrentRow = Items.DataSources.CurrentRow;
	If CurrentRow <> Undefined Then
		AttributesSelectionList = AttributesSelectionList(CurrentRow);
		ChoiceList = Item.ChoiceList;
		ChoiceList.Clear();
		
		For Each ListItem In AttributesSelectionList Do
			ChoiceList.Add(ListItem.Value,
				ListItem.Presentation,
				ListItem.Check,
				ListItem.Picture);
		EndDo;
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Edit(Command)
	
	HeaderOfDataLayoutSchemaConfigurationForm = NStr("vi = 'Truy vấn dữ liệu thông báo ""%NameOfNotificationType%""';
													|ru = 'Запрос данных оповещения ""%NameOfNotificationType%""';
													|en = 'Request for %NameOfNotificationType% notification data'; fa = 'Request for %NameOfNotificationType% notification data';
													|it = 'Request for %NameOfNotificationType% notification data';
													|pl = 'Request for %NameOfNotificationType% notification data';
													|tr = '""%NameOfNotificationType%"" bildiri verisi talebi'");
	HeaderOfDataLayoutSchemaConfigurationForm = StrReplace(HeaderOfDataLayoutSchemaConfigurationForm, "%NameOfNotificationType%", Object.Description);
	
	FormParameters = New Structure;
	FormParameters.Insert("AddressOfDataCompositionSchema", DCSAddress);
	FormParameters.Insert("AddressOfDataCompositionSettings", DCSSettingsAddress);
	FormParameters.Insert("TemplateSource_", Undefined);
	FormParameters.Insert("Title", HeaderOfDataLayoutSchemaConfigurationForm);
	FormParameters.Insert("UUID", UUID);
	FormParameters.Insert("DCSTemplateName", Object.DCSTemplateName);
	FormParameters.Insert("ReturnANameOfTheCurrentDCSTemplate", True);
	FormParameters.Insert("ReturnAFullNameOfTheCurrentDCSTemplate", True);
	FormParameters.Insert("DoNotConfigureConditionalFormatting", True);
	FormParameters.Insert("DonTAdjustTheOrder", True);
	FormParameters.Insert("DoNotConfigureSettings", True);
	FormParameters.Insert("DoNotPlaceSettingsToTheDataCompositionSchema", True);
	FormParameters.Insert("DownloadFromFileInServiceModeIsAvailable", True);
	If Object.NotificationType = PredefinedValue("Enum.UserNotificationTypes.Nonexclusive") Then
		FormParameters.Insert("ProcedureForValidatingDataCompositionSchema", 
			"UserNotificationsOfEvents.CheckingCorrectnessOfSchemeForReceivingDataOfOperationalTypeOfAlerts");
	Else
		FormParameters.Insert("ProcedureForValidatingDataCompositionSchema", 
			"UserNotificationsOfEvents.CheckingCorrectnessOfSchemeForReceivingDataOfNonOperationalTypeOfAlerts");
	EndIf;
	Notification = New CallbackDescription("EditCompletion", ThisObject);
	OpenForm("CommonForm.SimplifiedSettingOfDataCompositionSchema",
		FormParameters, 
		ThisObject,,,,
		Notification,
		FormWindowOpeningMode.LockWholeInterface);

EndProcedure

&AtClient
Procedure RefillingObject(Command)
	If Not Object.Supplied Then
		DoMessageBoxAsync(NStr("vi = 'Không cần điền lại.';
								|ru = 'Перезаполнение не требуется.';
								|en = 'No need to refill.'; fa = 'No need to refill.';
								|it = 'No need to refill.';
								|pl = 'No need to refill.';
								|tr = 'Yeniden doldurma gerekli değil.'"));
		Return;
	EndIf;
	ReFillNotificationView();
EndProcedure

&AtClient
Procedure CheckNotification(Command)
	If Modified Or Not ValueIsFilled(Object.Ref) Then
		DoMessageBoxAsync(NStr("vi = 'Trước khi kiểm tra, cần ghi lại dạng thông báo.';
								|ru = 'Перед проверкой вид оповещения должен быть записан.';
								|en = 'Save the notification kind before checking.'; fa = 'Save the notification kind before checking.';
								|it = 'Save the notification kind before checking.';
								|pl = 'Save the notification kind before checking.';
								|tr = 'Kontrol öncesinde bildirim türünün kaydedilmesi gerekmektedir.'"));
		Return;
	EndIf;
	ClearMessages();
	If CheckCorrectnessOfTypeOfNotifications(Object.Ref) Then
		ShowUserNotification(
			NStr("vi = 'Dạng thông báo cho người sử dụng.';
				|ru = 'Виды оповещений пользователей.';
				|en = 'User notification kinds.'; fa = 'User notification kinds.';
				|it = 'User notification kinds.';
				|pl = 'User notification kinds.';
				|tr = 'Kullanıcı bildirimlerinin türleri.'"),,
			NStr("vi = 'Đã thông báo mà không bị lỗi.';
				|ru = 'Оповещение выполнено без ошибок.';
				|en = 'Notification is sent without errors.'; fa = 'Notification is sent without errors.';
				|it = 'Notification is sent without errors.';
				|pl = 'Notification is sent without errors.';
				|tr = 'Bildirim hatasız bir şekilde tamamlandı.'"),
			PictureLib.Information32);
	Else
		ShowUserNotification(
			NStr("vi = 'Dạng thông báo cho người sử dụng.';
				|ru = 'Виды оповещений пользователей.';
				|en = 'User notification kinds.'; fa = 'User notification kinds.';
				|it = 'User notification kinds.';
				|pl = 'User notification kinds.';
				|tr = 'Kullanıcı bildirimlerinin türleri.'"),,
			NStr("vi = 'Trong quá trình thông báo cho người sử dụng, đã xảy ra lỗi.';
				|ru = 'В ходе оповещения пользователей возникли ошибки.';
				|en = 'Errors occurred while notifying users.'; fa = 'Errors occurred while notifying users.';
				|it = 'Errors occurred while notifying users.';
				|pl = 'Errors occurred while notifying users.';
				|tr = 'Kullanıcılara bildirim yapılırken hatalar oluştu.'"),
			PictureLib.Error32);
	EndIf;
	
EndProcedure

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	If CommonClient.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManagerClient = CommonClient.CommonModule("PropertyManagerClient");
		ModulePropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
	EndIf;
EndProcedure
// End StandardSubsystems.Properties

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.DataSourcesSourceDetails_.Name);

	SelectionGroupAnd = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupAnd.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DataSources.PictureIndex");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	ItemFilter.RightValue = EditableIndexes();

	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.DataSources.SourceDetails_");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ClosedDocument);

EndProcedure

&AtServer
Function EditableIndexes()
	
	IndexesOfImagesByType = UserNotificationsOfEvents.IndexesOfImagesByType();
	
	ListOfEditableIndexes = New ValueList;
	ListOfEditableIndexes.Add(IndexesOfImagesByType["InformationRegister"]);
	ListOfEditableIndexes.Add(IndexesOfImagesByType["AccumulationRegister"]);
	ListOfEditableIndexes.Add(IndexesOfImagesByType["AccountingRegister"]);
	ListOfEditableIndexes.Add(IndexesOfImagesByType["CalculationRegister"]);
	
	Return ListOfEditableIndexes
	
EndFunction

&AtServer
Procedure OnCreatReadAtServer(CurrentObject = Undefined)
	
	SetFormHeader(CurrentObject = Undefined);
	FillInSuppliedInfo();
	AvailabilityControl(ThisObject);
	FillInPresentationsOfDataSources();
	
	If CurrentObject <> Undefined Then
		DCS = CurrentObject.DataCompositionSchema.Get();
		Settings = CurrentObject.StorageOfDataCompositionSettings.Get();
	EndIf;
	FillInLayoutDiagram(DCS, Settings);
	
EndProcedure

&AtServer
Procedure FillInSuppliedInfo()
	If Object.Supplied Then
		Items.InformationText.Visible = True;
		RowsArray = New Array;
		RowsArray.Add(PictureLib.Information);
		RowsArray.Add(" ");
		RowsArray.Add(" ");
		If Object.Changed Then
			RowsArray.Add(New FormattedString(
				NStr("vi = 'Dạng thông báo khác với dạng được cung cấp.';
					|ru = 'Вид оповещения отличается от поставляемого.';
					|en = 'The notification kind differs from the built-in one.'; fa = 'The notification kind differs from the built-in one.';
					|it = 'The notification kind differs from the built-in one.';
					|pl = 'The notification kind differs from the built-in one.';
					|tr = 'Bildirimin türü, sağlanan bildirimden farklıdır.'"), ,
				StyleColors.NoteText));
			RowsArray.Add(" ");
			RowsArray.Add(" ");
			RowsArray.Add(New FormattedString(
				NStr("vi = 'Điền lại';
					|ru = 'Перезаполнить';
					|en = 'Refill'; fa = 'پرکردن مجدد';
					|it = 'Refill';
					|pl = 'Refill';
					|tr = 'Yeniden doldur'"), ,
				StyleColors.HyperlinkColor,
				Undefined,
				"Refill"));
		Else
			RowsArray.Add(New FormattedString(
				NStr("vi = 'Dạng thông báo có sẵn trong cấu hình.';
					|ru = 'Вид оповещения поставляется с конфигурацией.';
					|en = 'The notification kind is supplied together with the configuration.'; fa = 'The notification kind is supplied together with the configuration.';
					|it = 'The notification kind is supplied together with the configuration.';
					|pl = 'The notification kind is supplied together with the configuration.';
					|tr = 'Bildirim türü konfigürasyon ile sağlanır.'"), ,
				StyleColors.NoteText));
		EndIf;
		InformationText = New FormattedString(RowsArray);
	Else
		Items.InformationText.Visible = False;
	EndIf;
	Items.InformationText.Enabled = Not ReadOnly;
EndProcedure

&AtClientAtServerNoContext
Procedure AvailabilityControl(Form)
	Items = Form.Items;
	Object = Form.Object;
	
	Items.GroupGrouping.Enabled = Object.NotificationType = PredefinedValue("Enum.UserNotificationTypes.NonOperational");
	
	If Object.NotificationType = PredefinedValue("Enum.UserNotificationTypes.NonOperational") Then
		Items.PageGroupByType.CurrentPage = Items.GroupPageNonOperationalAttributes;
	ElsIf Object.NotificationType = PredefinedValue("Enum.UserNotificationTypes.Nonexclusive") Then
		Items.PageGroupByType.CurrentPage = Items.GroupPageOperationalAttributes;
	EndIf;
	
	UpdateMultilanguageStrings(Form);
	Items.NotificationTextTemplate.Enabled = Not Form.ReadOnly;
	Items.GroupedNotificationText.Enabled = Not Form.ReadOnly;
EndProcedure

&AtServer
Procedure FillInPresentationsOfDataSources()
	
	If Object.DataSources.Count() = 0 Then
		Return
	EndIf;
	
	ArrayOfSources = Object.DataSources.Unload().UnloadColumn("SourceType");
	
	MetadataObjectsByIDs = Common.MetadataObjectsByIDs(
		ArrayOfSources,
		False);
		
	For Each DataSource In Object.DataSources Do
		MetadataObject = MetadataObjectsByIDs.Get(DataSource.SourceType);
		If MetadataObject = Null Or MetadataObject = Undefined Then
			DataSource.Description = NStr("vi = '<đối tượng không xác định>';
											|ru = '<неизвестный объект>';
											|en = '<unknown object>'; fa = '<unknown object>';
											|it = '<unknown object>';
											|pl = '<unknown object>';
											|tr = '<belirsiz nesne>'");
			DataSource.FullName = NStr("vi = '<kiểu đối tượng không xác định>';
										|ru = '<неизвестный тип объекта>';
										|en = '<unknown object type>'; fa = '<unknown object type>';
										|it = '<unknown object type>';
										|pl = '<unknown object type>';
										|tr = '<belirsiz nesne tipi>'");
			DataSource.PictureIndex = 0;
		Else
			DataSource.Description = MetadataObject.Presentation();
			DataSource.FullName = MetadataObject.FullName();
			DataSource.PictureIndex = UserNotificationsOfEvents.PictureIndex(DataSource.FullName);
		EndIf;
	EndDo;
EndProcedure

&AtClientAtServerNoContext
//@skip-check bsl-nstr-string-literal-format
Procedure UpdateMultilanguageStrings(Form)
	Object = Form.Object;
	
	If ValueIsFilled(Object.GroupedNotificationText) Then
		Form.GroupedNotificationText = NStr(Object.GroupedNotificationText);
		If Not ValueIsFilled(Form.GroupedNotificationText) Then
			Form.GroupedNotificationText = NStr(Object.GroupedNotificationText, Form.DefaultLanguageCode);
		EndIf;
	EndIf;
	If Not ValueIsFilled(Form.GroupedNotificationText) Then
		Form.GroupedNotificationText = NStr("vi = '<chỉ định>';
											|ru = '<указать>';
											|en = '<specify>'; fa = '<specify>';
											|it = '<specify>';
											|pl = '<specify>';
											|tr = '<belirt>'");
	EndIf;
	
	If ValueIsFilled(Object.NotificationTextTemplate) Then
		Form.NotificationTextTemplate = NStr(Object.NotificationTextTemplate);
		If Not ValueIsFilled(Form.NotificationTextTemplate) Then
			Form.NotificationTextTemplate = NStr(Object.NotificationTextTemplate, Form.DefaultLanguageCode);
		EndIf;
	EndIf;
	If Not ValueIsFilled(Form.NotificationTextTemplate) Then
		Form.NotificationTextTemplate = NStr("vi = '<chỉ định>';
											|ru = '<указать>';
											|en = '<specify>'; fa = '<specify>';
											|it = '<specify>';
											|pl = '<specify>';
											|tr = '<belirt>'");
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationTextTemplateClickCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined And TypeOf(Result) = Type("String") Then
		Object.NotificationTextTemplate = Result;
		UpdateMultilanguageStrings(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure GroupedNotificationTextClickCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined And TypeOf(Result) = Type("String") Then
		Object.GroupedNotificationText = Result;
		UpdateMultilanguageStrings(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure PickSourcesCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		If TypeOf(Result) = Type("Map") Then
			For Each Type In Result Do
				FoundRows = Object.DataSources.FindRows(New Structure("SourceType", Type.Key));
				If FoundRows.Count() = 0 Then
					NewSource = Object.DataSources.Add();
					NewSource.SourceType = Type.Key;
					FillPropertyValues(NewSource, Type.Value);
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure EditCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		DCSSettingsAddress = Result.AddressOfComposerConfigurationStore;
		UpdateLayoutDiagram(True);
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateLayoutDiagram(CheckUpdate = False)
	DCSSettings = Undefined;
	If IsTempStorageURL(DCSSettingsAddress) Then
		DCSSettings = GetFromTempStorage(DCSSettingsAddress);
	EndIf;
	If IsTempStorageURL(DCSAddress) Then
		DCS = GetFromTempStorage(DCSAddress);
	Else
		DCS = DataCompositionSchemaByDefault();
		DCSAddress = PutToTempStorage(DCS, UUID);
	EndIf;
	InitializeSettingsComposer(DCS, DCSSettings);
	
	If CheckUpdate And Object.Supplied Then
		If HasChanges(DCS, DataCompositionSchemaByDefault())
			Or ValueIsFilled(DCSSettings) And HasChanges(DCSSettings, DefaultSchemaSettings(DCS)) Then
			Object.Changed = True;
		EndIf;
	EndIf;
	FillInSuppliedInfo();
	
EndProcedure

&AtServer
Procedure FillInLayoutDiagram(DCS, Settings)

	If DCS <> Undefined Then
		DCSAddress = PutToTempStorage(DCS, New UUID);
	Else
		DCS = DataCompositionSchemaByDefault();
		DCSAddress = PutToTempStorage(DCS, UUID);
	EndIf;
	If Settings <> Undefined Then
		DCSSettingsAddress = PutToTempStorage(Settings, New UUID);
	Else
		DCSSettingsAddress = "";
	EndIf;
	
	InitializeSettingsComposer(DCS, Settings);
EndProcedure

&AtServer
Function AvailableFields()
	
	AvailableFields = New Array;
	Settings = DataCompositionSettingsComposer.GetSettings();
	For Each AvailableField In Settings.Selection.Items Do
		If TypeOf(AvailableField) = Type("DataCompositionAutoSelectedField")
			Or Not AvailableField.Use 
			Or AvailableField.Field = Undefined Then
			Continue;
		EndIf;
		FieldDetails = New Structure("Field, Title");
		FieldDetails.Field = AvailableField.Field;
		FoundField = Settings.SelectionAvailableFields.FindField(AvailableField.Field);
		If FoundField <> Undefined Then
			FieldDetails.Title = FoundField.Title;
		EndIf;
		AvailableFields.Add(FieldDetails);
	EndDo;
	
	Return AvailableFields
	
EndFunction

&AtServer
Procedure InitializeSettingsComposer(SourceDiagram, Settings = Undefined)
	
	DataCompositionSettingsComposer = UserNotificationsOfEvents.InitializeSettingsComposer(SourceDiagram, Settings);
	
EndProcedure

&AtServer
Function DefaultSchemaSettings(DataCompositionSchema)
	SettingsComposer = UserNotificationsOfEvents.InitializeSettingsComposer(DataCompositionSchema, 
		DataCompositionSchema.DefaultSettings);
	Return SettingsComposer.GetSettings()
EndFunction

&AtServer
Function DataCompositionSchemaByDefault()
	
	Schema = UserNotificationsOfEvents.TemplateByFullName(Object.DCSTemplateName);
	
	If Schema = Undefined Then
		Common.MessageToUser(NStr("vi = 'Đối với dạng thông báo có chỉ định khuôn mẫu sơ đồ dàn dựng không chính xác. Cần điền lại dạng thông báo.';
									|ru = 'Для вида оповещения указан некорректный шаблон СКД. Необходимо перезаполнить вид оповещения.';
									|en = 'An incorrect DCS template is specified for the notification kind. Refill the notification kind.'; fa = 'An incorrect DCS template is specified for the notification kind. Refill the notification kind.';
									|it = 'An incorrect DCS template is specified for the notification kind. Refill the notification kind.';
									|pl = 'An incorrect DCS template is specified for the notification kind. Refill the notification kind.';
									|tr = 'Bildirim türü için hatalı VOS şablonu belirtildi. Bildirim türünün yeniden doldurulması gerekli.'"));
	EndIf;
	
	Return Schema
EndFunction

&AtServer
Function HasChanges(Value, DefaultValue)
	Return UserNotificationsOfEvents.HasChanges(Value, DefaultValue);
EndFunction

&AtServer
Function AttributesSelectionList(CurrentRow)
	AttributesSelectionList = New ValueList;
	
	CurrentData = Object.DataSources.FindByID(CurrentRow);
	If CurrentData = Undefined Then
		Return AttributesSelectionList;
	EndIf;
	
	MetadataObject = Common.MetadataObjectByID(CurrentData.SourceType);
	If MetadataObject <> Undefined Then
		If StrStartsWith(CurrentData.FullName, "AccumulationRegister")
			Or StrStartsWith(CurrentData.FullName, "AccountingRegister")
			Or StrStartsWith(CurrentData.FullName, "CalculationRegister") Then
			
			AttributesSelectionList.Add("Recorder",
				NStr("vi = 'Nguồn ghi';
					|ru = 'Регистратор';
					|en = 'Recorder'; fa = 'ثبت‌کننده';
					|it = 'Registratore';
					|pl = 'Rejestrator';
					|tr = 'Kaydedici'"),,
				PictureLib.Attribute);
			
			AddAttributesToList(AttributesSelectionList, MetadataObject.Dimensions, PictureLib.Dimension);
			AddAttributesToList(AttributesSelectionList, MetadataObject.Attributes, PictureLib.Attribute);
		ElsIf StrStartsWith(CurrentData.FullName, "InformationRegister") Then
			If MetadataObject.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.RecorderSubordinate Then
				AttributesSelectionList.Add("Recorder",
					NStr("vi = 'Nguồn ghi';
						|ru = 'Регистратор';
						|en = 'Recorder'; fa = 'ثبت‌کننده';
						|it = 'Registratore';
						|pl = 'Rejestrator';
						|tr = 'Kaydedici'"),,
					PictureLib.Attribute);
			EndIf;
			AddAttributesToList(AttributesSelectionList, MetadataObject.Dimensions, PictureLib.Dimension);
			AddAttributesToList(AttributesSelectionList, MetadataObject.Attributes, PictureLib.Attribute);
		Else
			AttributesSelectionList.Add("Ref",
				NStr("vi = 'Tham chiếu';
					|ru = 'Ссылка';
					|en = 'Reference'; fa = 'مرجع';
					|it = 'Link';
					|pl = 'Odnośnik';
					|tr = 'Bağlantı'"),,
				PictureLib.Attribute);
		EndIf;
	EndIf;
	
	Return AttributesSelectionList
EndFunction

&AtServer
Procedure AddAttributesToList(AttributesSelectionList, ObjectAttributes, Picture)
	
	For Each ObjectAttribute In ObjectAttributes Do
		
		If StrStartsWith(ObjectAttribute.Name, "Delete") Then
			Continue;
		EndIf;
		
		AttributeTypes = ObjectAttribute.Type.Types();
		IsReferenceType = False;
		For Each AttributeType In AttributeTypes Do
			IsReferenceType = Common.IsReference(AttributeType);
			If IsReferenceType Then
				Break;
			EndIf;
		EndDo;
		If IsReferenceType Then
			AttributesSelectionList.Add(ObjectAttribute.Name,
				?(ValueIsFilled(ObjectAttribute.Synonym),ObjectAttribute.Synonym,ObjectAttribute.Name),,
				Picture);
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Async Procedure ReFillNotificationView()
	
	QueryText = NStr("vi = 'Điền lại dạng thông báo theo khuôn mẫu có sẵn?';
					|ru = 'Перезаполнить вид оповещения по поставляемому шаблону?';
					|en = 'Refill the notification kind using the built-in template?'; fa = 'Refill the notification kind using the built-in template?';
					|it = 'Refill the notification kind using the built-in template?';
					|pl = 'Refill the notification kind using the built-in template?';
					|tr = 'Sağlanan şablon kullanılarak bildirim türü yeniden doldurulsun mu?'");
	
	ButtonsList = New ValueList();
	ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Điền lại';
												|ru = 'Перезаполнить';
												|en = 'Refill'; fa = 'پرکردن مجدد';
												|it = 'Ricompilare';
												|pl = 'Refill';
												|tr = 'Yeniden doldur'"));
	ButtonsList.Add(DialogReturnCode.No, NStr("vi = 'Hủy bỏ';
												|ru = 'Отмена';
												|en = 'Cancel'; fa = 'انصراف';
												|it = 'Annulla';
												|pl = 'Cancel';
												|tr = 'İptal'"));
	
	Response = Await DoQueryBoxAsync(QueryText, ButtonsList);
	If Response = DialogReturnCode.Yes Then
		If ReFillNotificationViewAtServer() Then
			ShowUserNotification(
				NStr("vi = 'Dạng thông báo cho người sử dụng.';
					|ru = 'Виды оповещений пользователей.';
					|en = 'User notification kinds.'; fa = 'User notification kinds.';
					|it = 'User notification kinds.';
					|pl = 'User notification kinds.';
					|tr = 'Kullanıcı bildirimlerinin türleri.'"),,
				NStr("vi = 'Đã điền lại dạng thông báo.';
					|ru = 'Перезаполнение вида оповещения завершено.';
					|en = 'The notification kind is refilled.'; fa = 'The notification kind is refilled.';
					|it = 'The notification kind is refilled.';
					|pl = 'The notification kind is refilled.';
					|tr = 'Bildirim türünün yeniden doldurulması tamamlandı.'"),
				PictureLib.Information32);
		Else
			ShowUserNotification(
				NStr("vi = 'Dạng thông báo cho người sử dụng.';
					|ru = 'Виды оповещений пользователей.';
					|en = 'User notification kinds.'; fa = 'User notification kinds.';
					|it = 'User notification kinds.';
					|pl = 'User notification kinds.';
					|tr = 'Kullanıcı bildirimlerinin türleri.'"),,
				NStr("vi = 'Không thể điền lại dạng thông báo.';
					|ru = 'Перезаполнение вида оповещения не удалось.';
					|en = 'Cannot refill the notification kind.'; fa = 'Cannot refill the notification kind.';
					|it = 'Cannot refill the notification kind.';
					|pl = 'Cannot refill the notification kind.';
					|tr = 'Bildirim türünün yeniden doldurulması başarısız oldu.'"),
				PictureLib.Error32);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Function ReFillNotificationViewAtServer()
	IdOfNotificationType = Object.Ref.UUID();
	DescriptionOfTypeOfAlerts = UserNotificationsOfEvents.DescriptionOfTypeOfUserAlertsById(IdOfNotificationType);
	ObjectIsOverfilled = False;
	If DescriptionOfTypeOfAlerts <> Undefined Then
		DCSAddress = "";
		DCSSettingsAddress = "";
		FillPropertyValues(Object, DescriptionOfTypeOfAlerts, , "DataSources");
		
		Object.DataSources.Clear();
		For Each DataSource In DescriptionOfTypeOfAlerts.DataSources Do
			NewRow = Object.DataSources.Add();
			If TypeOf(DataSource.SourceType) = Type("String") Then
				NewRow.SourceType = Common.MetadataObjectID(DataSource.SourceType);
			Else
				NewRow.SourceType = DataSource.SourceType;
			EndIf;
			NewRow.SourceDetails_ = DataSource.SourceDetails_;
		EndDo;
		
		UpdateLayoutDiagram();
		AvailabilityControl(ThisObject);
		FillInPresentationsOfDataSources();
		ObjectIsOverfilled = True;
	EndIf;
	
	Return ObjectIsOverfilled
	
EndFunction

&AtServerNoContext
Function CheckCorrectnessOfTypeOfNotifications(NotificationKind)
	UserNotificationsOfEvents.CheckCorrectnessOfTypeOfUserAlerts(NotificationKind);
	Return True;
EndFunction

&AtServer
Procedure SetFormHeader(IsNew = False)
	
	If IsNew Then
		Title = NStr("vi = 'Dạng thông báo cho người sử dụng (tạo mới)';
					|ru = 'Вид оповещения пользователей (создание)';
					|en = 'User notification kinds (Create)'; fa = 'User notification kinds (Create)';
					|it = 'User notification kinds (Create)';
					|pl = 'User notification kinds (Create)';
					|tr = 'Kullanıcı bildirim türü (oluşturma)'");
	Else
		Title = Object.Description;
	EndIf;
	
EndProcedure

// StandardSubsystems.Properties
&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	If Common.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManager = Common.CommonModule("PropertyManager");
		ModulePropertyManager.UpdateAdditionalAttributesItems(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	
	If CommonClient.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManagerClient = CommonClient.CommonModule("PropertyManagerClient");
		ModulePropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	
	If CommonClient.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManagerClient = CommonClient.CommonModule("PropertyManagerClient");
		ModulePropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
	EndIf;
	
EndProcedure
// End StandardSubsystems.Properties

#EndRegion