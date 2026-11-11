
#Region FormEventHandlers

&AtServer
Procedure OnReadAtServer(CurrentObject)

	OnCreatReadAtServer();

	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);

	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	DataSeparationEnabled = Common.DataSeparationEnabled();
	
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	// Subsystem prohibiting editing of key details of objects	
	ObjectAttributesLock.LockAttributes(ThisForm);
	
	GetScheduleForRoutineTask(ThisForm);
	
	// Filling in the list of data layout schemes
	Items.DataCompositionSchema.ChoiceList.Clear();
	
	WhetherTemplateIsPredefined = Upper("Predefined");
	LengthOfPredefinedTemplateAttribute = StrLen(WhetherTemplateIsPredefined);
	For Each Template In Metadata.FindByType(TypeOf(Object.Ref)).Templates Do
		If Template.TemplateType = Metadata.ObjectProperties.TemplateType.DataCompositionSchema Then
			
			If Upper(Right(Template.Name, LengthOfPredefinedTemplateAttribute)) = WhetherTemplateIsPredefined Then
				Items.DataCompositionSchema.ChoiceList.Add(Template.Name, Template.Synonym);
			EndIf;
			
		EndIf;
	EndDo;
	
	UseArbitraryDataCompositionSchemas = Not Common.DataSeparationEnabled();
	If UseArbitraryDataCompositionSchemas Then
		
		PresentationOfArbitraryCircuit = NStr("vi = 'Tùy ý';
												|ru = 'Произвольный';
												|en = 'Arbitrary'; fa = 'دلخواه';
												|it = 'Libero';
												|pl = 'Dowolny';
												|tr = 'İsteğe bağlı'");
		Items.DataCompositionSchema.ChoiceList.Add("", PresentationOfArbitraryCircuit);
	
	EndIf;
	
	SettingCompliance = New Structure;
	PreviousDataCompositionSchema = Object.DataCompositionSchema;
	ItemReferenceDetails = Common.ObjectAttributesValues(
		Object.Ref, 
		"StorageOfDataCompositionSettings, StorageOfDataCompositionSchema");
	If TypeOf(ItemReferenceDetails.StorageOfDataCompositionSettings) <> Type("ValueStorage") Then
		ItemReferenceDetails.StorageOfDataCompositionSettings = New ValueStorage(Undefined);
	EndIf;
	If TypeOf(ItemReferenceDetails.StorageOfDataCompositionSchema) <> Type("ValueStorage") Then
		ItemReferenceDetails.StorageOfDataCompositionSchema = New ValueStorage(Undefined);
	EndIf;
	StorageOfDataCompositionSettings = ItemReferenceDetails.StorageOfDataCompositionSettings; // ValueStorage
	StorageOfDataLayoutSettingsTyping = StorageOfDataCompositionSettings; // ValueStorage
	ArbitraryFilterIsUsed = StorageOfDataLayoutSettingsTyping.Get() <> Undefined;
	StorageOfDataCompositionSchema = ItemReferenceDetails.StorageOfDataCompositionSchema; // ValueStorage
	
	OnCreatReadAtServer();

	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)

	// Subsystem "Properties"
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	Items.ScheduleGroup.CurrentPage = Items.ScheduleGroup.ChildItems.ScheduleAccrualPage;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	CurrentObject.AdditionalProperties.Insert("Schedule", Schedule);
	CurrentObject.AdditionalProperties.Insert("Use", ScheduledJobUsed);
	
	DataLayoutSchemaStorageTyping = StorageOfDataCompositionSchema; // ValueStorage
	If ValueIsFilled(CurrentObject.DataCompositionSchema) Then
		Schema = Catalogs.CustomerRewardProgramRules.GetTemplate(CurrentObject.DataCompositionSchema);
	Else
		Schema = DataLayoutSchemaStorageTyping.Get();
	EndIf;
	
	StorageOfDataLayoutSettingsTyping = StorageOfDataCompositionSettings; // ValueStorage
	DataCompositionSettings = StorageOfDataLayoutSettingsTyping.Get(); // DataCompositionSettings
	
	If Schema = Undefined Then
		Common.MessageToUser(
			NStr("vi = 'Sơ đồ dàn dựng dữ liệu không chính xác.';
				|ru = 'Схема компоновки данных не корректна.';
				|en = 'Data composition schema is incorrect.'; fa = 'Data composition schema is incorrect.';
				|it = 'Schema di composizione dati non è corretto.';
				|pl = 'Schemat układu danych jest nieprawidłowy.';
				|tr = 'Veri inşa edilme şeması yanlış.'"),
			,
			"Object.DataCompositionSchema",,
			Cancel);
	Else
		For Each SchemeParameter In Schema.Parameters Do
			
			If SchemeParameter.DenyIncompleteValues Then
				
				DisplayMessage = False;
				If DataCompositionSettings = Undefined And Not ValueIsFilled(SchemeParameter.Value) Then
				
					DisplayMessage = True;
					
				ElsIf DataCompositionSettings <> Undefined Then
					
					Parameter = DataCompositionSettings.DataParameters.Items.Find(SchemeParameter.Name);
					If (Parameter = Undefined And Not ValueIsFilled(SchemeParameter.Value))
						Or (Parameter <> Undefined And Not ValueIsFilled(Parameter.Value))Then
						DisplayMessage = True;
					EndIf;
					
				EndIf;
				
				If DisplayMessage Then
					Common.MessageToUser(
						StrTemplate(NStr("vi = 'Chưa điền giá trị tham số ""%1""';
										|ru = 'Не заполнено значение параметра ""%1""';
										|en = 'Value is required for parameter ""%1""'; fa = 'Value is required for parameter ""%1""';
										|it = 'Il valore del parametro ""%1"" non è compilato';
										|pl = 'Nie wypełniono wartości parametru ""%1""';
										|tr = '""%1"" parametresi değeri doldurulmadı'"), SchemeParameter.Name),
						,
						"Object.DataCompositionSchema",,
						Cancel);
				EndIf;
				
			EndIf;
			
		EndDo;
	EndIf;
	
	CurrentObject.StorageOfDataCompositionSettings = StorageOfDataCompositionSettings;
	CurrentObject.StorageOfDataCompositionSchema    = StorageOfDataCompositionSchema;
	
	// Handler of the "Properties" subsystem
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// Subsystem prohibiting editing of key details of objects	
	ObjectAttributesLock.LockAttributes(ThisForm);

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	AttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure RuleKindOnChange(Item)
	
	FillDataLayoutSchemeSelectionList();
	
	If Items.DataCompositionSchema.ChoiceList.FindByValue(Object.DataCompositionSchema) = Undefined Then
		Object.DataCompositionSchema = Items.DataCompositionSchema.ChoiceList[0].Value;
	EndIf;
	
	If (Object.RuleKind = PredefinedValue("Enum.KindsOfBonusPointAccrualRules.WriteOff")) Then
		
		UseValidityPeriod                      = 0;
		Object.NumberOfValidityPeriods               = 0;
		UseActionStartDelay              = 0;
		Object.NumberOfActionStartDelayPeriods = 0;
		
	EndIf;
	
	ChangeAvailability(ThisForm);
	
EndProcedure

&AtClient
Procedure DataCompositionSchemaOnChange(Item)
	
	DataLayoutDiagramWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure UseValidityPeriodOnChange(Item)
	
	ChangeAvailability(ThisForm);
	
	Object.NumberOfValidityPeriods = UseValidityPeriod;
	
EndProcedure

&AtClient
Procedure UseActionStartDelayOnChange(Item)
	
	ChangeAvailability(ThisForm);
	
	Object.NumberOfActionStartDelayPeriods = UseActionStartDelay;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EditDataCompositionSchema(Command)
	
	// Open the Data Layout Schema Settings Editor
	HeaderOfDataLayoutSchemaConfigurationForm = NStr("vi = 'Tùy chỉnh sơ đồ dàn dựng dữ liệu để tính toán tự động ""%1""';
													|ru = 'Настройка схемы компоновки данных для автоматического начисления ""%1""';
													|en = 'Setting of data composition schema for automatic accrual ""%1""'; fa = 'Setting of data composition schema for automatic accrual ""%1""';
													|it = 'Impostazione dello schema di composizione dati per accredito automatico ""%1""';
													|pl = 'Ustawienia schematu układu danych do automatycznego naliczenia ""%1""';
													|tr = '""%1"" otomatik tahakkuk için veri inşa edilme şeması ayarı'");
	HeaderOfDataLayoutSchemaConfigurationForm = StrReplace(HeaderOfDataLayoutSchemaConfigurationForm, "%1", Object.Description);
	
	Addresses = GetAddressesOfDataLayoutSchemeInTemporaryStorage();
	
	AddressOfComposerConfigurationStore = Undefined;
	
	FormParameters = New Structure;
	FormParameters.Insert("DoNotPlaceSettingsToTheDataCompositionSchema", True);
	FormParameters.Insert("NotEditDataCompositionSchema", False);
	FormParameters.Insert("DoNotLoadADataLayoutDiagramFromAFile", False);
	FormParameters.Insert("DoNotConfigureConditionalFormatting", True);
	FormParameters.Insert("DoNotConfigureTheSelection", True);
	FormParameters.Insert("DonTAdjustTheOrder", True);
	FormParameters.Insert("UUID", UUID);
	FormParameters.Insert("AddressOfDataCompositionSchema", Addresses.DataCompositionSchema);
	FormParameters.Insert("AddressOfDataCompositionSettings", Addresses.DataCompositionSettings);
	FormParameters.Insert("Title", HeaderOfDataLayoutSchemaConfigurationForm);
	
	OpenForm("CommonForm.SimplifiedSettingOfDataCompositionSchema",
		FormParameters,,,,,
		New CallbackDescription("EditDataCompositionSchemaCompletion",
			ThisObject,
			New Structure("Addresses", Addresses)),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure EditDataCompositionSchemaCompletion(Result, AdditionalParameters) Export
    
    Addresses = AdditionalParameters.Addresses;
    
    
    AddressOfComposerConfigurationStore = Result;
    
    If ValueIsFilled(AddressOfComposerConfigurationStore) Then
        ApplyChangesToDataLayoutScheme(Addresses.DataCompositionSchema, AddressOfComposerConfigurationStore);
    EndIf;

EndProcedure

&AtClient
Procedure SetUpSchedule(Command)
	
	ScheduleDialog1 = New ScheduledJobDialog(Schedule);
	ScheduleDialog1.Show(New CallbackDescription("SetUpScheduleCompletion", ThisObject, New Structure("ScheduleDialog1", ScheduleDialog1)));
	
EndProcedure

&AtClient
Procedure SetUpScheduleCompletion(Result, AdditionalParameters) Export
	
	ScheduleDialog1 = AdditionalParameters.ScheduleDialog1;
	
	If Result <> Undefined Then
		
		Modified = True;
		Schedule         = ScheduleDialog1.Schedule;
		If DataSeparationEnabled 
			And Schedule.RepeatPeriodInDay > 0
			And Schedule.RepeatPeriodInDay < 3600 Then
			
			Schedule.RepeatPeriodInDay = 3600;
			
		EndIf;
		ScheduleAsString  = String(Schedule);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	ObjectAttributesLockClient.AllowObjectAttributeEdit(ThisForm);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
	
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	
	ExecuteCommandAtServer(ExecutionParameters);
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
	
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

// StandardSubsystems.Properties

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

// End StandardSubsystems.Properties

#Region Properties

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

#EndRegion

#Region OtherItems

&AtServer
Procedure FillDataLayoutSchemeSelectionList()
	
	Items.DataCompositionSchema.ChoiceList.Clear();
	
	// Filling in the list of data layout schemes
	WhetherTemplateIsPredefined = Upper("Predefined");
	WriteOffFlag = Upper("WriteOff");
	AccrualAttribute = Upper("Accrual");
	LengthOfPredefinedTemplateAttribute = StrLen(WhetherTemplateIsPredefined);
	For Each Template In Metadata.FindByType(TypeOf(Object.Ref)).Templates Do
		If Template.TemplateType = Metadata.ObjectProperties.TemplateType.DataCompositionSchema Then
			
			If Upper(Right(Template.Name, LengthOfPredefinedTemplateAttribute)) = WhetherTemplateIsPredefined Then
				
				If Upper(Left(Template.Name, StrLen(WriteOffFlag))) = WriteOffFlag
					And Object.RuleKind = Enums.KindsOfBonusPointAccrualRules.WriteOff Then
				
					Items.DataCompositionSchema.ChoiceList.Add(Template.Name, Template.Synonym);
				
				EndIf;
				If Upper(Left(Template.Name, StrLen(AccrualAttribute))) = AccrualAttribute
					And Object.RuleKind = Enums.KindsOfBonusPointAccrualRules.Accrual Then
				
					Items.DataCompositionSchema.ChoiceList.Add(Template.Name, Template.Synonym);
				
				EndIf;
				
			EndIf;
			
		EndIf;
	EndDo;
	
	Items.DataCompositionSchema.ChoiceList.Add("", NStr("vi = 'Tùy ý';
														|ru = 'Произвольный';
														|en = 'Arbitrary'; fa = 'دلخواه';
														|it = 'Libero';
														|pl = 'Arbitrary';
														|tr = 'İsteğe bağlı'"));
	
EndProcedure

&AtServer
Function GetXML(Value)
	
	Record = New XMLWriter();
	Record.SetString();
	XDTOSerializer.WriteXML(Record, Value);
	Return Record.Close();
	
EndFunction

&AtServer
Function ApplyChangesToDataLayoutScheme(AddressOfDataLayoutSchemaInStorage, AddressOfDataCompositionSettings)
	
	If ValueIsFilled(Object.DataCompositionSchema) Then
		
		SchemeAndSettings = Catalogs.CustomerRewardProgramRules.GetDescriptionAndLayoutDiagramOfDataByTemplateName(Object.Ref, Object.DataCompositionSchema);
		
		// If the data layout scheme from the layout <> is obtained from the data layout scheme editor.
		If GetXML(SchemeAndSettings.DataCompositionSchema) <> GetXML(GetFromTempStorage(AddressOfDataLayoutSchemaInStorage)) Then
			Object.DataCompositionSchema   = "";
			StorageOfDataCompositionSchema = New ValueStorage(GetFromTempStorage(AddressOfDataLayoutSchemaInStorage));
		EndIf;
		
		// The resulting settings can be equal to the default settings of the scheme.
		SettingsComposer = New DataCompositionSettingsComposer;
		SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(SchemeAndSettings.DataCompositionSchema));
		SettingsComposer.LoadSettings(SchemeAndSettings.DataCompositionSchema.DefaultSettings);
		SettingsComposer.Refresh();
		If GetXML(SettingsComposer.GetSettings()) <> GetXML(GetFromTempStorage(AddressOfDataCompositionSettings)) Then
			StorageOfDataCompositionSettings = New ValueStorage(GetFromTempStorage(AddressOfDataCompositionSettings));
		Else
			StorageOfDataCompositionSettings = New ValueStorage(Undefined);
		EndIf;
		
	Else
		
		Schema = GetFromTempStorage(AddressOfDataLayoutSchemaInStorage);
		StorageOfDataCompositionSchema = New ValueStorage(Schema);
		
		SettingsComposer = New DataCompositionSettingsComposer;
		SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(Schema));
		SettingsComposer.LoadSettings(Schema.DefaultSettings);
		SettingsComposer.Refresh();
		If GetXML(SettingsComposer.GetSettings()) <> GetXML(GetFromTempStorage(AddressOfDataCompositionSettings)) Then
			StorageOfDataCompositionSettings = New ValueStorage(GetFromTempStorage(AddressOfDataCompositionSettings));
		Else
			StorageOfDataCompositionSettings = New ValueStorage(Undefined);
		EndIf;
		
	EndIf;
	
	StorageOfDataLayoutSettingsTyping = StorageOfDataCompositionSettings; // ValueStorage
	ArbitraryFilterIsUsed = StorageOfDataLayoutSettingsTyping.Get() <> Undefined;
	
	Return Undefined;
EndFunction

&AtServer
Function GetAddressesOfDataLayoutSchemeInTemporaryStorage()
	
	Addresses = New Structure("DataCompositionSchema, DataCompositionSettings");
	
	// Schema
	If ValueIsFilled(Object.DataCompositionSchema) Or StorageOfDataCompositionSchema = Undefined Then
		SchemeAndSettings = Catalogs.CustomerRewardProgramRules.GetDescriptionAndLayoutDiagramOfDataByTemplateName(Object.Ref, Object.DataCompositionSchema);
		DataCompositionSchema = SchemeAndSettings.DataCompositionSchema;
	Else
		DataLayoutSchemaStorageTyping = StorageOfDataCompositionSchema; // ValueStorage
		DataCompositionSchema = DataLayoutSchemaStorageTyping.Get();
	EndIf;
	
	If DataCompositionSchema = Undefined Then
		DataCompositionSchema = Catalogs.CustomerRewardProgramRules.CreateNewDataLayoutScheme();
	EndIf;
	
	Addresses.DataCompositionSchema = PutToTempStorage(DataCompositionSchema, UUID);
	
	// Settings
	StorageOfDataLayoutSettingsTyping = StorageOfDataCompositionSettings; // ValueStorage
	Settings = StorageOfDataLayoutSettingsTyping.Get();
	If ValueIsFilled(Settings) Then
		Addresses.DataCompositionSettings = PutToTempStorage(Settings, UUID);
	EndIf;
	
	Return Addresses;
	
EndFunction

&AtServer
Procedure ShouldSaveSettings()

	Var_Key = PreviousDataCompositionSchema + "Schema";
	
	AddressInTempStorage = Undefined;
	AddressInTempStorage = SettingCompliance.Property(Var_Key, AddressInTempStorage);
	
	If StorageOfDataCompositionSettings = Undefined Then
		StorageOfDataCompositionSettings = New ValueStorage(Undefined);
	EndIf;
	
	If ValueIsFilled(AddressInTempStorage) Then
		AddressInTempStorage = PutToTempStorage(
			StorageOfDataCompositionSettings,
			AddressInTempStorage);
	Else
		AddressInTempStorage = PutToTempStorage(
			StorageOfDataCompositionSettings,
			UUID);
	EndIf;
	
	SettingCompliance.Insert(Var_Key, AddressInTempStorage);
	
EndProcedure

&AtServer
Procedure DataLayoutDiagramWhenChangedOnServer()
	
	ShouldSaveSettings();
	
	Var_Key = Object.DataCompositionSchema + "Schema";
	
	AddressInTempStorage = Undefined;
	If SettingCompliance.Property(Var_Key, AddressInTempStorage) And ValueIsFilled(AddressInTempStorage) Then
		StorageOfDataCompositionSettings = GetFromTempStorage(AddressInTempStorage);
	Else
		StorageOfDataCompositionSettings = New ValueStorage(Undefined);
	EndIf;
	
	StorageOfDataLayoutSettingsTyping = StorageOfDataCompositionSettings; // ValueStorage
	ArbitraryFilterIsUsed = StorageOfDataLayoutSettingsTyping.Get() <> Undefined;
	
	PreviousDataCompositionSchema = Object.DataCompositionSchema;
	
EndProcedure

&AtServer
Procedure OnCreatReadAtServer()
	
	FillDataLayoutSchemeSelectionList();
	
	UseValidityPeriod         = ?(Object.NumberOfValidityPeriods > 0, 1, 0);
	UseActionStartDelay = ?(Object.NumberOfActionStartDelayPeriods > 0, 1, 0);
	
	ChangeAvailability(ThisForm);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ChangeAvailability(Form)
	
	Form.Items.GroupValidityPeriodRight.Enabled = (Form.UseValidityPeriod = 1);
	Form.Items.GroupDeferralRight.Enabled     = (Form.UseActionStartDelay = 1);
	
	Form.Items.GroupExpirationDates.Visible       = (Form.Object.RuleKind = PredefinedValue("Enum.KindsOfBonusPointAccrualRules.Accrual"));
	
	Form.Items.GroupExpirationDates.Visible       = (Form.Object.RuleKind = PredefinedValue("Enum.KindsOfBonusPointAccrualRules.Accrual"));
	
	If Form.Object.RuleKind = PredefinedValue("Enum.KindsOfBonusPointAccrualRules.Accrual") Then
		Form.Items.ScheduleGroup.CurrentPage    = Form.Items.ScheduleGroup.ChildItems.ScheduleAccrualPage;
	Else
		Form.Items.ScheduleGroup.CurrentPage    = Form.Items.ScheduleGroup.ChildItems.ScheduleDebitingPage;
	EndIf;
	
EndProcedure

&AtServer
Procedure GetScheduleForRoutineTask(Form)
	
	Form.Schedule = New JobSchedule;
	
	If Form.Object.Ref.IsEmpty() Then
		
		Form.Schedule.BeginTime = '00010101020000'; // at 02:00
		Form.Schedule.EndTime  = '00010101060000'; // at 06:00
		Form.Schedule.DaysRepeatPeriod = 1; //every day
		
	Else
		
		SetPrivilegedMode(True);
		JobID = Form.Object.ScheduledJob;
		If TypeOf(JobID) = Type("UUID") Then
			Job = ScheduledJobsServer.Job(JobID);
			If Job <> Undefined Then
				Form.Schedule = Job.Schedule;
				Form.ScheduledJobUsed = Job.Use;
				Form.ScheduleAsString = String(Form.Schedule);
			EndIf;
		EndIf; 
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

