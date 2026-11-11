#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	// A new element is being created
	If Not IsTempStorageURL(DCSAddress) Then
		
		// By copying
		If ValueIsFilled(Parameters.CopyingValue) And Not ValueIsFilled(Parameters.CopyingValue.DCSTemplateName) Then
			
			// When copying, the data layout scheme is obtained from the object being copied
			SourceDiagram = Parameters.CopyingValue.DataCompositionSchema.Get();
			
		ElsIf ValueIsFilled(Parameters.CopyingValue) And ValueIsFilled(Parameters.CopyingValue.DCSTemplateName) Then
			
			// When copying, the data layout scheme is obtained from the template of the object being copied.
			SourceDiagram = Catalogs.PlanningDataSources.LayoutSchemeByTemplateName(Parameters.CopyingValue.DCSTemplateName);
			
		Else
		
			
			// A new data layout scheme is being created
			SourceDiagram = New DataCompositionSchema;
			
		EndIf;
		
		DCSAddress = PutToTempStorage(SourceDiagram, UUID);
		
		RecommendedSelectionByPeriod = RecommendedSelectionByPeriod(SourceDiagram);
		WarnAboutDataSelection(RecommendedSelectionByPeriod);
		
	EndIf;
	
	// A new element is being created
	If Not IsTempStorageURL(DCSSettingsAddress) Then
		
		// By copying
		If ValueIsFilled(Parameters.CopyingValue) Then
			
			// When copying, the data layout scheme is obtained from the object being copied
			Try
				DataCompositionSettings = Parameters.CopyingValue.StorageOfDataCompositionSettings.Get();
			Except
				Common.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Trong nguồn điền dữ liệu ""%1"" có lỗi trong tùy chỉnh. Đã đặt tùy chỉnh mặc định.';
						|ru = 'В источнике заполнения данных ""%1"" имеются ошибки в настройках. Установлены настройки по умолчанию.';
						|en = 'There are errors in the settings in the ""%1"" data filling source. The default settings are set.'; fa = 'There are errors in the settings in the ""%1"" data filling source. The default settings are set.';
						|it = 'Nell''origine di compilazione dati ""%1"" sono presenti errori di impostazione. Sono selezionate le impostazioni predefinite.';
						|pl = 'Źródło wypełnienia danych ""%1"" zawiera błędy w ustawieniach. Ustawione są ustawienia domyślne.';
						|tr = 'Kaynakta ""%1"" verisinin doldurulması esnasında ayarlarda hatalar meydana geldi. Ayarlar varsayılana göre ayarlandı.'"), Parameters.CopyingValue.Ref));
			EndTry;
		Else
			
			// A new data layout scheme is being created
			DataCompositionSettings = Undefined;
			
		EndIf;
		
		If DataCompositionSettings <> Undefined Then
			DCSSettingsAddress = PutToTempStorage(DataCompositionSettings, UUID);
		EndIf; 
		
	EndIf;
	
	FullNameOfTemplateSource = Common.TableNameByRef(Object.Ref);
	TemplateSourceManager = Common.ObjectManagerByRef(Object.Ref);
		
	For Each TemplateTemplate In TemplateSourceManager.DataLayoutSchemaTemplates() Do
		NewRow = Templates.Add();
		NewRow.Synonym = TemplateTemplate.Synonym;
		NewRow.Name = TemplateTemplate.Name;
		If TemplateTemplate.Property("FullNameOfTemplateSource") And ValueIsFilled(TemplateTemplate.FullNameOfTemplateSource) Then
			NewRow.FullNameOfTemplateSource = TemplateTemplate.FullNameOfTemplateSource;
		Else
			NewRow.FullNameOfTemplateSource = FullNameOfTemplateSource;
		EndIf; 
		NewRow.FullName = NewRow.FullNameOfTemplateSource + "." + NewRow.Name;
		Items.DCSTemplateName.ChoiceList.Add(NewRow.FullName, TemplateTemplate.Synonym);
		
	EndDo;
	
	If IsBlankString(Object.DCSTemplateName) Then
		
		Items.DCSTemplateName.ChoiceList.Add("", NStr("vi = 'Tùy ý';
														|ru = 'Произвольная';
														|en = 'Arbitrary'; fa = 'دلخواه';
														|it = 'Casuale';
														|pl = 'Arbitrary';
														|tr = 'İsteğe bağlı'"));
		
	EndIf;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	If ValueIsFilled(CurrentObject.DCSTemplateName) Then
		SourceDiagram = Catalogs.PlanningDataSources.LayoutSchemeByTemplateName(CurrentObject.DCSTemplateName);
		If SourceDiagram = Undefined Then
			SourceDiagram = CurrentObject.DataCompositionSchema.Get();
		EndIf;
	Else
		SourceDiagram = CurrentObject.DataCompositionSchema.Get();
	EndIf; 
	
	Try
		DataCompositionSettings = CurrentObject.StorageOfDataCompositionSettings.Get();
	Except
		Common.MessageToUser(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trong nguồn điền dữ liệu ""%1"" có lỗi trong tùy chỉnh. Đã đặt tùy chỉnh mặc định.';
				|ru = 'В источнике заполнения данных ""%1"" имеются ошибки в настройках. Установлены настройки по умолчанию.';
				|en = 'There are errors in the settings in the ""%1"" data filling source. The default settings are set.'; fa = 'There are errors in the settings in the ""%1"" data filling source. The default settings are set.';
				|it = 'Nell''origine di compilazione dati ""%1"" sono presenti errori di impostazione. Sono selezionate le impostazioni predefinite.';
				|pl = 'Źródło wypełnienia danych ""%1"" zawiera błędy w ustawieniach. Ustawione są ustawienia domyślne.';
				|tr = 'Kaynakta ""%1"" verisinin doldurulması esnasında ayarlarda hatalar meydana geldi. Ayarlar varsayılana göre ayarlandı.'"), CurrentObject.Ref));
		ThisForm.Modified = True;
	EndTry;
	
	// Loading a data layout diagram
	DCSAddress = PutToTempStorage(SourceDiagram, UUID);
	DCSSettingsAddress = "";
	If DataCompositionSettings <> Undefined Then
		DCSSettingsAddress = PutToTempStorage(DataCompositionSettings, UUID);
	EndIf;
	
	RecommendedSelectionByPeriod = RecommendedSelectionByPeriod(SourceDiagram);
	WarnAboutDataSelection(RecommendedSelectionByPeriod);
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If ValueIsFilled(CurrentObject.DCSTemplateName) Then
		DataCompositionSchema = Catalogs.PlanningDataSources.LayoutSchemeByTemplateName(CurrentObject.DCSTemplateName);
	Else
		DataCompositionSchema = GetFromTempStorage(DCSAddress);
		
		// Saving the data layout scheme
		CurrentObject.DataCompositionSchema = New ValueStorage(DataCompositionSchema);
	EndIf; 
	
	SettingsComposer = New DataCompositionSettingsComposer;
	Try
		SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(DataCompositionSchema));
	Except
		WriteLogEvent(NStr("vi = 'Cấu phần tùy chỉnh nguồn dữ liệu lập kế hoạch';
							|ru = 'Компоновка настроек источника данных планирования';
							|en = 'Composition of planning data source settings'; fa = 'Composition of planning data source settings';
							|it = 'Composizione delle impostazioni della fonte d''origine dei dati di pianificazione';
							|pl = 'Konfiguracja ustawień źródła danych planowania';
							|tr = 'Planlama veri kaynağı ayar düzeni'", CommonClientServer.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			DetailErrorDescription(ErrorInfo()));
	EndTry;
	SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
	SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
	If IsTempStorageURL(DCSSettingsAddress) Then
	
		DataCompositionSettings = GetFromTempStorage(DCSSettingsAddress);
		If Common.ValueToXMLString(SettingsComposer.GetSettings()) <> Common.ValueToXMLString(DataCompositionSettings) Then
			CurrentObject.StorageOfDataCompositionSettings = New ValueStorage(DataCompositionSettings);
		Else
			CurrentObject.StorageOfDataCompositionSettings = New ValueStorage(Undefined);
		EndIf;
	Else
	
		CurrentObject.StorageOfDataCompositionSettings = New ValueStorage(Undefined);
	
	EndIf; 
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	AttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure


&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Edit(Command)

	HeaderOfDataLayoutSchemaConfigurationForm = NStr("vi = 'Tùy chỉnh nguồn dữ liệu lập kế hoạch ""%NameOfDataSource%""';
													|ru = 'Настройки источника данных планирования ""%NameOfDataSource%""';
													|en = 'Settings of the ""%NameOfDataSource%"" planning data source'; fa = 'Settings of the ""%NameOfDataSource%"" planning data source';
													|it = 'Impostazioni della fonte d''origine dei dati di pianificazione ""%NameOfDataSource%""';
													|pl = 'Ustawienia źródła danych planowania ""%NameOfDataSource%""';
													|tr = '""%NameOfDataSource%"" planlama veri kaynağı ayarları'");
	HeaderOfDataLayoutSchemaConfigurationForm = StrReplace(HeaderOfDataLayoutSchemaConfigurationForm, "%NameOfDataSource%", Object.Description);
	
	FormParameters = New Structure;
	FormParameters.Insert("AddressOfDataCompositionSchema",                DCSAddress);
	FormParameters.Insert("AddressOfDataCompositionSettings",             DCSSettingsAddress);
	FormParameters.Insert("TemplateSource_",                          Object.Ref);
	FormParameters.Insert("Title",                                 HeaderOfDataLayoutSchemaConfigurationForm);
	FormParameters.Insert("UUID",                   UUID);
	FormParameters.Insert("DCSTemplateName",                             Object.DCSTemplateName);
	FormParameters.Insert("ReturnANameOfTheCurrentDCSTemplate",           True);
	FormParameters.Insert("ReturnAFullNameOfTheCurrentDCSTemplate",     True);
	FormParameters.Insert("DoNotConfigureConditionalFormatting",           True);
	FormParameters.Insert("DonTAdjustTheOrder",                      True);
	FormParameters.Insert("DoNotPlaceSettingsToTheDataCompositionSchema", True);
	
	Notification = New CallbackDescription("EditCompletion", ThisObject);
	OpenForm("CommonForm.SimplifiedSettingOfDataCompositionSchema",
		FormParameters, 
		ThisForm,,,,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
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

#Region Other

&AtClient
Procedure EditCompletion(Result, AdditionalParameters) Export 
	
	If Result <> Undefined Then
	
		Object.DCSTemplateName = Result.NameOfTheCurrentDCSTemplate;
		DCSSettingsAddress = Result.AddressOfComposerConfigurationStore;
		
		Object.DCSTemplateVersion = 0;
		
		EditCompletionOnServer();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure LoadFromTemplate(FullNameOfTemplateSource, TemplateName)
	
	SetPrivilegedMode(True);
	
	DataCompositionSchema = Common.ObjectManagerByFullName(FullNameOfTemplateSource).GetTemplate(TemplateName);
	
	SetPrivilegedMode(False);
	
	PutToTempStorage(DataCompositionSchema, DCSAddress);
	DCSSettingsAddress = "";
	
	RecommendedSelectionByPeriod = RecommendedSelectionByPeriod(DataCompositionSchema);
	
	If RecommendedSelectionByPeriod.Find(3) <> Undefined Then
		Object.SettingOfFilterByPeriod = 3;
	ElsIf RecommendedSelectionByPeriod.Find(2) <> Undefined Then
		Object.SettingOfFilterByPeriod = 2;
	ElsIf RecommendedSelectionByPeriod.Find(1) <> Undefined Then
		Object.SettingOfFilterByPeriod = 1;
	Else
		Object.SettingOfFilterByPeriod = 0;
	EndIf;
	
	WarnAboutDataSelection(RecommendedSelectionByPeriod);
	
EndProcedure

#EndRegion

#Region EventHandlers

&AtClient
Procedure SettingOfFilterByPeriodOnChange(Item)
	
	LimitingSelectionByPeriodWhenChangesAreMadeOnServer();
	
EndProcedure

&AtClient
Procedure DCSTemplateNameOnChange(Item)
	
	If Object.DCSTemplateName = NameOfTheCurrentDCSTemplate Then
		Return;
	EndIf;
	
	FoundRows = Templates.FindRows(New Structure("FullName", Object.DCSTemplateName));
	
	If FoundRows.Count() = 0 Then
		Object.DCSTemplateName = NameOfTheCurrentDCSTemplate;
		WarningText = NStr("vi = 'Lỗi kết nhập khuôn mẫu. Hãy chọn khuôn mẫu khác.';
							|ru = 'Ошибка загрузки шаблона. Выберите другой шаблон.';
							|en = 'An error occurred while importing the template. Select another template.'; fa = 'An error occurred while importing the template. Select another template.';
							|it = 'Errore nel caricamento del modello. Selezionate un altro modello.';
							|pl = 'Błąd pobierania szablonu. Wybierz inny szablon.';
							|tr = 'Numune indirilirken hata oluştu. Başka bir numune seç.'");
  		ShowMessageBox(,WarningText);
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Tùy chỉnh hiện tại sẽ mất. Tiếp tục?';
					|ru = 'Текущие настройки будут потеряны. Продолжить?';
					|en = 'Current settings will be lost. Continue?'; fa = 'Current settings will be lost. Continue?';
					|it = 'Le impostazioni correnti verranno perse. Continuare?';
					|pl = 'Bieżące ustawienia zostaną utracone. Kontynuować?';
					|tr = 'Mevcut ayarlar kaybedilecek. Devam edilsin mi?'");
	Notification = New CallbackDescription("DCSTemplateNameOnChangeCompletion", ThisObject);
	ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo, , DialogReturnCode.No);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure DCSTemplateNameOnChangeCompletion(Result, AdditionalParameters) Export 
	
	If Result <> DialogReturnCode.Yes Then
		Object.DCSTemplateName = NameOfTheCurrentDCSTemplate;
		Return;
	EndIf;
	
	FoundRows = Templates.FindRows(New Structure("FullName", Object.DCSTemplateName));
	
	LoadFromTemplate(FoundRows[0].FullNameOfTemplateSource, FoundRows[0].Name);
	
	Modified = True;
	NameOfTheCurrentDCSTemplate = Object.DCSTemplateName;
	
	Object.DCSTemplateVersion = 0;
	
	EmptyElement = Items.DCSTemplateName.ChoiceList.FindByValue("");
	If EmptyElement <> Undefined Then
		Items.DCSTemplateName.ChoiceList.Delete(EmptyElement);
	EndIf;
	
EndProcedure

&AtServerNoContext
Function RecommendedSelectionByPeriod(DataCompositionSchema)

	RecommendedSelectionByPeriod = New Array;
	
	If DataCompositionSchema.Parameters.Find("PeriodOffset") <> Undefined 
		And DataCompositionSchema.Parameters.Find("PeriodOffsetIsUsed") <> Undefined 
		And DataCompositionSchema.Parameters.Find("OffsetPeriodStart") <> Undefined 
		And DataCompositionSchema.Parameters.Find("OffsetPeriodEnd") <> Undefined Then
	
		RecommendedSelectionByPeriod.Add(3);
	EndIf;
	
	If DataCompositionSchema.Parameters.Find("BeginOfPeriod") <> Undefined 
		And DataCompositionSchema.Parameters.Find("EndOfPeriod") <> Undefined Then
	
		RecommendedSelectionByPeriod.Add(2);
	EndIf;
	
	If DataCompositionSchema.Parameters.Find("Period") <> Undefined 
		And RecommendedSelectionByPeriod.Find(2) = Undefined
		And RecommendedSelectionByPeriod.Find(3) = Undefined Then
	
		RecommendedSelectionByPeriod.Add(1);
	
	EndIf; 
	
	If DataCompositionSchema.Parameters.Find("BeginOfPeriod") = Undefined
		Or Not ValueIsFilled(DataCompositionSchema.Parameters.Find("BeginOfPeriod").Expression)
		Or DataCompositionSchema.Parameters.Find("EndOfPeriod") = Undefined 
		Or Not ValueIsFilled(DataCompositionSchema.Parameters.Find("EndOfPeriod").Expression) Then
	
		RecommendedSelectionByPeriod.Add(0);
	
	EndIf;
	
	Return RecommendedSelectionByPeriod;
	
EndFunction

&AtServer
Procedure WarnAboutDataSelection(RecommendedSelectionByPeriod = Undefined)

	If RecommendedSelectionByPeriod = Undefined Then
		SourceDiagram = GetFromTempStorage(DCSAddress);
		RecommendedSelectionByPeriod = RecommendedSelectionByPeriod(SourceDiagram);
	EndIf; 
	
	If RecommendedSelectionByPeriod.Find(Object.SettingOfFilterByPeriod) <> Undefined Then
		If Items.DecorationWarningAboutDataSampling.Visible Then
			Items.DecorationWarningAboutDataSampling.Visible = False;
		EndIf;
		Return;
	EndIf;
	
	ChoiceList = Items.SettingOfFilterByPeriod.ChoiceList;
	PresentationOfCurSample = ChoiceList.FindByValue(Object.SettingOfFilterByPeriod).Presentation;
	WarningText = StringFunctionsClientServer.SubstituteParametersToString(
									NStr("vi = 'Sơ đồ dàn dựng dữ liệu, có thể, không hỗ trợ chọn dữ liệu ""%1"".';
										|ru = 'Схема компоновки данных, возможно, не поддерживает выборку данных ""%1"".';
										|en = 'Data composition schema may not support selection of the ""%1"" data.'; fa = 'Data composition schema may not support selection of the ""%1"" data.';
										|it = 'Lo schema di composizione dei dati potrebbe non supportare il campionamento dei dati ""%1"".';
										|pl = 'Schemat układu danych, może nie obsługiwać wyboru danych ""%1"".';
										|tr = 'Veri Oluşturma Sistemi, ""%1"" veri kümesini desteklemiyor olabilir.'"),
									PresentationOfCurSample);
									
	RecommendedSelectionsByPeriod = "";
	For Each SampleValueByPeriod In RecommendedSelectionByPeriod Do
		RecommendedSelectionsByPeriod = RecommendedSelectionsByPeriod 
										+ ?(RecommendedSelectionsByPeriod = "", "", ", ")
										+ ChoiceList.FindByValue(SampleValueByPeriod).Presentation;
	EndDo;
	
	WarningText = WarningText
							+ Chars.LF
							+ StringFunctionsClientServer.SubstituteParametersToString(
									NStr("vi = 'Nên sử dụng: %1';
										|ru = 'Рекомендуется использовать: %1.';
										|en = 'It is recommended that you use: %1.'; fa = 'It is recommended that you use: %1.';
										|it = 'Si consiglia di utilizzare: %1.';
										|pl = 'Zaleca się używanie: %1.';
										|tr = 'Kullanılması önerilmektedir: %1.'"), 
									RecommendedSelectionsByPeriod);
							
	Items.DecorationWarningAboutDataSampling.Title = WarningText;

	Items.DecorationWarningAboutDataSampling.Visible = True;
	
EndProcedure

&AtServer
Procedure LimitingSelectionByPeriodWhenChangesAreMadeOnServer()

	WarnAboutDataSelection();

EndProcedure

&AtServer
Procedure EditCompletionOnServer()

	WarnAboutDataSelection();

EndProcedure

#EndRegion

#EndRegion
