
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		
		Return;
		
	EndIf;
	
	// The address passed in the parameter is saved as the address of the original schema
	AddressOfSourceDataCompositionSchema = Parameters.AddressOfDataCompositionSchema;
	UniqueOwnerID = Parameters.UUID;
	
	ProcedureForPlacingTheSettingsInTheDataCompositionSchema = Parameters.ProcedureForPlacingTheSettingsInTheDataCompositionSchema;
	ProcedureForValidatingDataCompositionSchema           = Parameters.ProcedureForValidatingDataCompositionSchema;
	ProcedureForInitializingCompositionSettings      = Parameters.ProcedureForInitializingCompositionSettings;
	DataCompositionSchemaContainsCriticalErrors   = False;
	
	// The header of the form
	Title = Parameters.Title;
	
	NameOfTheCurrentDCSTemplate           	  = Parameters.DCSTemplateName;
	ReturnANameOfTheCurrentDCSTemplate 	  = Parameters.ReturnANameOfTheCurrentDCSTemplate;
	ReturnAFullNameOfTheCurrentDCSTemplate = Parameters.ReturnAFullNameOfTheCurrentDCSTemplate;
	
	// Filling in the list of templates
	If Not Parameters.TemplateSource_ = Undefined Then
		
		FullNameOfTemplateSource = Common.TableNameByRef(Parameters.TemplateSource_);
		TemplateSourceManager = Common.ObjectManagerByRef(Parameters.TemplateSource_);
		
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
			If ReturnAFullNameOfTheCurrentDCSTemplate Then
				Items.TheCurrentTemplateOfDataCompositionSchema.ChoiceList.Add(NewRow.FullName, NewRow.Synonym);
			Else
				Items.TheCurrentTemplateOfDataCompositionSchema.ChoiceList.Add(NewRow.Name, NewRow.Synonym);
			EndIf; 			
		EndDo;
		
		If IsBlankString(NameOfTheCurrentDCSTemplate) Then
			
			Items.TheCurrentTemplateOfDataCompositionSchema.ChoiceList.Add("", NStr("vi = 'Tùy ý';
																					|ru = 'Произвольная';
																					|en = 'Arbitrary'; fa = 'دلخواه';
																					|it = 'Casuale';
																					|pl = 'Dowolna';
																					|tr = 'İsteğe bağlı'"));
			
		EndIf;
		
		TheCurrentTemplateOfDataCompositionSchema = NameOfTheCurrentDCSTemplate;
		Items.TheCurrentTemplateOfDataCompositionSchema.Visible = True;
		
	Else
		
		Items.TheCurrentTemplateOfDataCompositionSchema.Visible = False;
		
	EndIf;
	
	// The original data layout scheme is copied to the editable data layout scheme.
	CopyDataLayoutDiagram(AddressOfEditedDataCompositionSchema, AddressOfSourceDataCompositionSchema);
	
	// The settings linker is initialized by an editable data layout scheme
	InitializeSettingsComposer(SettingsComposer,
	                                    AddressOfEditedDataCompositionSchema,
	                                    Parameters.AddressOfDataCompositionSettings,
	                                    ProcedureForInitializingCompositionSettings);
	
	Items.EditCompositionSchema.Visible = Not Parameters.NotEditDataCompositionSchema;
	Items.FormImportSchemaFromFile.Visible   = Not Parameters.DoNotLoadADataLayoutDiagramFromAFile;
	
	Items.GroupFilter.Visible                  = Not Parameters.DoNotConfigureSelection;
	Items.GroupParameters.Visible              = Not Parameters.DoNotConfigureSettings;
	Items.OrderGroup.Visible                = Not Parameters.DonTAdjustTheOrder;
	Items.ConditionalDesignGroup.Visible     = Not Parameters.DoNotConfigureConditionalFormatting;
	Items.GroupWithFields.Visible                   = Not Parameters.DoNotConfigureTheSelection;
	If Common.DataSeparationEnabled() Then
		Items.EditCompositionSchema.Visible = False;
		Items.FormImportSchemaFromFile.Visible = Parameters.DownloadFromFileInServiceModeIsAvailable;
	EndIf; 
	DoNotPlaceSettingsToTheDataCompositionSchema = Parameters.DoNotPlaceSettingsToTheDataCompositionSchema;
	
	ReadOnly = Parameters.ReadOnly;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ChangedDataLayoutScheme(Form, DataCompositionSchema)
	
	// The schema is obtained from the data layout schema constructor
	Form.Modified = True;
	Form.EditableDataLayoutSchemeModifiability = True;
	
	// The editable data layout scheme is replaced by the scheme obtained from the constructor.
	HadChanges = False;
	
	If Not IsBlankString(Form.ProcedureForValidatingDataCompositionSchema) Then
		Form.ListOfCriticalErrorsInTheCompositionSchema.Clear();
		CheckParameters = New Structure;
		CheckParameters.Insert("FormIdentifier", Form.UUID);
		CheckParameters.Insert("MethodName", Form.ProcedureForValidatingDataCompositionSchema);
		CheckParameters.Insert("ThereAreCriticalErrors", Form.DataCompositionSchemaContainsCriticalErrors);
		CheckParameters.Insert("ListOfCriticalErrorsInTheCompositionSchema", Form.ListOfCriticalErrorsInTheCompositionSchema);
		PerformMethodToCheckDataLayoutScheme(DataCompositionSchema, CheckParameters);
		Form.DataCompositionSchemaContainsCriticalErrors = CheckParameters.ThereAreCriticalErrors;
		Form.ListOfCriticalErrorsInTheCompositionSchema = CheckParameters.ListOfCriticalErrorsInTheCompositionSchema;
	EndIf;
	
	SetDataLayoutScheme(Form.AddressOfEditedDataCompositionSchema, DataCompositionSchema, True, HadChanges);
	
	If HadChanges Then
		
		If Form.Items.TheCurrentTemplateOfDataCompositionSchema.ChoiceList.FindByValue("") = Undefined Then
			Form.Items.TheCurrentTemplateOfDataCompositionSchema.ChoiceList.Add("", NStr("vi = 'Tùy chọn';
																						|ru = 'Произвольная';
																						|en = 'Arbitrary'; fa = 'دلخواه';
																						|it = 'Casuale';
																						|pl = 'Dowolna';
																						|tr = 'İsteğe bağlı'"));
		EndIf;
		
		Form.NameOfTheCurrentDCSTemplate = "";
		Form.TheCurrentTemplateOfDataCompositionSchema = Form.NameOfTheCurrentDCSTemplate;
		
	EndIf;
	
	// The settings linker is initialized by an editable schema
	InitializeSettingsComposer(Form.SettingsComposer,
	                                    Form.AddressOfEditedDataCompositionSchema,,
	                                    Form.ProcedureForInitializingCompositionSettings);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	#If ThickClientOrdinaryApplication Or ThickClientManagedApplication Then
		
		ClearMessages();
		ChangedDataLayoutScheme(ThisForm, ValueSelected);
		
	#EndIf
	
EndProcedure

&AtServer
Function GenerateReturnStructure()
	
	ReturnStructure = New Structure("AddressOfComposerConfigurationStore, NameOfTheCurrentDCSTemplate");
	ReturnStructure.AddressOfComposerConfigurationStore =  GetComposerSettings(SettingsComposer, UniqueOwnerID);
	ReturnStructure.NameOfTheCurrentDCSTemplate = NameOfTheCurrentDCSTemplate;
		
	Return ReturnStructure;
	
EndFunction

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SettingsComposerSettingsFilterOnChange(Item)
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure SettingsComposerSettingsFilterAvailableFilterFieldsSelection(Item, RowSelected, Field, StandardProcessing)
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure SettingsComposerSettingsDataParametersOnChange(Item)
	
	Modified = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CompleteEditing(Command)
	
	If DataCompositionSchemaContainsCriticalErrors Then
		ClearMessages();
		For Each CriticalError In ListOfCriticalErrorsInTheCompositionSchema Do
			CommonClient.MessageToUser(CriticalError.Value);
		EndDo;
		Return;
	EndIf;
	
	If EditableDataLayoutSchemeModifiability Then
		
		If Not DoNotPlaceSettingsToTheDataCompositionSchema Then
			
			// The settings of the settings builder are placed in the editable schema
			If Not IsBlankString(ProcedureForPlacingTheSettingsInTheDataCompositionSchema) Then
				PerformMethodOfPlacingSettingInDataLayoutScheme(ProcedureForPlacingTheSettingsInTheDataCompositionSchema,
				                                                       SettingsComposer,
				                                                       AddressOfEditedDataCompositionSchema);
			Else
				PutSettingsInDataLayoutScheme(SettingsComposer, AddressOfEditedDataCompositionSchema);
			EndIf;
			
		EndIf;
		
		// The original schema is replaced by an editable schema
		SetDataLayoutScheme(AddressOfSourceDataCompositionSchema, AddressOfEditedDataCompositionSchema);
		
	Else
		
		// The settings of the settings linker are placed in the original schema
		If Not DoNotPlaceSettingsToTheDataCompositionSchema Then
			
			If Not IsBlankString(ProcedureForPlacingTheSettingsInTheDataCompositionSchema) Then
				PerformMethodOfPlacingSettingInDataLayoutScheme(ProcedureForPlacingTheSettingsInTheDataCompositionSchema,
				                                                       SettingsComposer,
				                                                       AddressOfSourceDataCompositionSchema);
			Else
				PutSettingsInDataLayoutScheme(SettingsComposer, AddressOfSourceDataCompositionSchema);
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Modified = False;
	
	If ReturnANameOfTheCurrentDCSTemplate And ValueIsFilled(UniqueOwnerID) Then
		
		Close(GenerateReturnStructure());
		
	ElsIf ValueIsFilled(UniqueOwnerID) Then
		
		Close(GetComposerSettings(SettingsComposer, UniqueOwnerID));
		
	Else
		
		Close(Undefined);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

&AtClient
Procedure EditCompositionSchema(Command)
	
	OpenDataLayoutSchemaDesigner();
	
EndProcedure

&AtClient
Procedure TheCurrentTemplateOfDataCompositionSchemaChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If ValueSelected <> Undefined And ValueSelected <> NameOfTheCurrentDCSTemplate Then
		
		QueryText = NStr("vi = 'Tùy chỉnh hiện tại sẽ mất. Tiếp tục?';
						|ru = 'Текущие настройки будут потеряны. Продолжить?';
						|en = 'Current settings will be lost. Continue?'; fa = 'Current settings will be lost. Continue?';
						|it = 'Le impostazioni correnti verranno perse. Continuare?';
						|pl = 'Bieżące ustawienia zostaną utracone. Kontynuować?';
						|tr = 'Mevcut ayarlar kaybedilecek. Devam edilsin mi?'");
		ShowQueryBox(
			New CallbackDescription("TheCurrentTemplateOfDataCompositionSchemaChoiceProcessingCompletion", 
				ThisObject, New Structure("ValueSelected", ValueSelected)), 
			QueryText, 
			QuestionDialogMode.YesNo, 
			, 
			DialogReturnCode.No);
		
		StandardProcessing = False;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TheCurrentTemplateOfDataCompositionSchemaChoiceProcessingCompletion(QuestionResult, AdditionalParameters) Export
	
	ValueSelected = AdditionalParameters.ValueSelected;
	
	If QuestionResult = DialogReturnCode.Yes Then
		
		If ReturnAFullNameOfTheCurrentDCSTemplate Then
			FoundRows = Templates.FindRows(New Structure("FullName", ValueSelected));
		Else
			FoundRows = Templates.FindRows(New Structure("Name", ValueSelected));
		EndIf;
		
		If FoundRows.Count() = 0 Then
			CommonClientServer.MessageToUser(
				NStr("vi = 'Lỗi kết nhập khuôn mẫu. Hãy chọn khuôn mẫu khác.';
					|ru = 'Ошибка загрузки шаблона. Выберите другой шаблон.';
					|en = 'An error occurred while importing the template. Select another template.'; fa = 'An error occurred while importing the template. Select another template.';
					|it = 'Errore nel caricamento del modello. Selezionate un altro modello.';
					|pl = 'Błąd pobierania szablonu. Wybierz inny szablon.';
					|tr = 'Numune indirilirken hata oluştu. Başka bir numune seç.'"),
				,
				"TheCurrentTemplateOfDataCompositionSchema");
			Return;
		EndIf;
		
		LoadFromTemplate(FoundRows[0].FullNameOfTemplateSource,
		                  FoundRows[0].Name,
		                  SettingsComposer,
		                  AddressOfEditedDataCompositionSchema,
		                  ProcedureForInitializingCompositionSettings);
		
		Modified = True;
		EditableDataLayoutSchemeModifiability = True;
		NameOfTheCurrentDCSTemplate = ValueSelected;
		TheCurrentTemplateOfDataCompositionSchema = ValueSelected;
		
		EmptyElement =  Items.TheCurrentTemplateOfDataCompositionSchema.ChoiceList.FindByValue("");
		If EmptyElement <> Undefined Then
			Items.TheCurrentTemplateOfDataCompositionSchema.ChoiceList.Delete(EmptyElement);
		EndIf;
		
	Else
		
		TheCurrentTemplateOfDataCompositionSchema = NameOfTheCurrentDCSTemplate;
		
	EndIf;
	
EndProcedure

#Region GeneralPurposeProceduresAndFunctions

&AtClient
Procedure OpenDataLayoutSchemaDesigner()
	
	#If ThickClientOrdinaryApplication Or ThickClientManagedApplication Then
		
		// The settings of the settings builder are placed in the editable schema
		If Not DoNotPlaceSettingsToTheDataCompositionSchema Then
			If Not IsBlankString(ProcedureForPlacingTheSettingsInTheDataCompositionSchema) Then
				PerformMethodOfPlacingSettingInDataLayoutScheme(ProcedureForPlacingTheSettingsInTheDataCompositionSchema,
				                                                       SettingsComposer,
				                                                       AddressOfEditedDataCompositionSchema);
			Else
				PutSettingsInDataLayoutScheme(SettingsComposer, AddressOfEditedDataCompositionSchema);
			EndIf;
		EndIf;
		
		// A copy of the schema being edited is created
		DataCompositionSchema = XDTOSerializer.ReadXDTO(XDTOSerializer.WriteXDTO(GetFromTempStorage(AddressOfEditedDataCompositionSchema)));
		
		// A copy of the edited schema opens in the constructor
		Designer = New DataCompositionSchemaWizard(DataCompositionSchema);
		Designer.Edit(ThisForm);
		
	#Else
		
		ShowMessageBox(Undefined, NStr("vi = 'Để soạn sơ đồ dàn dựng, cần khởi động cấu hình ở chế độ client dày.';
										|ru = 'Для того, чтобы редактировать схему компоновки, необходимо запустить конфигурацию в режиме толстого клиента.';
										|en = 'To edit the composition schema, run the configuration in the thick client mode.'; fa = 'To edit the composition schema, run the configuration in the thick client mode.';
										|it = 'Per modificare lo schema del layout è necessario avviare la configurazione in modalità thick client.';
										|pl = 'W celu edycji schematu układu należy uruchomić konfigurację w trybie grubego klienta.';
										|tr = 'İnşa etme şemasını düzenlemek için konfigürasyonun kalın istemci modunda çalıştırılması gerekir.'"));
		
	#EndIf
	
EndProcedure

&AtServerNoContext
Procedure SetDataLayoutScheme(ReceiverAddress, AddressSchemeSource, CheckForChanges_ = False, HadChanges = False)
	
	If IsTempStorageURL(AddressSchemeSource) Then
		
		DataCompositionSchema = GetFromTempStorage(AddressSchemeSource);
		
	Else
		
		DataCompositionSchema = AddressSchemeSource;
		
	EndIf;
	
	If CheckForChanges_ Then
		
		HadChanges = False;
		
		If IsTempStorageURL(ReceiverAddress) Then
			
			CurDCS = GetFromTempStorage(ReceiverAddress);
			If TypeOf(CurDCS) = Type("DataCompositionSchema") Then
				
				If Common.ValueToXMLString(DataCompositionSchema) <> Common.ValueToXMLString(CurDCS) Then
					
					HadChanges = True;
					
				EndIf
				
			Else
				
				HadChanges = True;
				
			EndIf;
			
		Else
			
			HadChanges = True;
			
		EndIf;
		
	EndIf;
	
	If IsTempStorageURL(ReceiverAddress) Then
		
		PutToTempStorage(DataCompositionSchema, ReceiverAddress);
		
	Else
		
		ReceiverAddress = PutToTempStorage(DataCompositionSchema, New UUID);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure CopyDataLayoutDiagram(ReceiverAddress, SourceAddress)
	
	DataCompositionSchema = GetFromTempStorage(SourceAddress);
	
	If TypeOf(DataCompositionSchema) = Type("DataCompositionSchema") Then
		
		DataCompositionSchema = XDTOSerializer.ReadXDTO(XDTOSerializer.WriteXDTO(DataCompositionSchema));
		
	Else
		
		DataCompositionSchema = New DataCompositionSchema;
		
	EndIf;
	
	If IsTempStorageURL(ReceiverAddress) Then
		
		PutToTempStorage(DataCompositionSchema, ReceiverAddress);
		
	Else
		
		ReceiverAddress = PutToTempStorage(DataCompositionSchema, New UUID);
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure InitializeSettingsComposer(SettingsComposer, AddressOfDataCompositionSchema, AddressOfDataCompositionSettings = Undefined, ProcedureForInitializingCompositionSettings = "")
	
	DataCompositionSchema = GetFromTempStorage(AddressOfDataCompositionSchema);
	If ValueIsFilled(AddressOfDataCompositionSettings) Then
		DataCompositionSettings = GetFromTempStorage(AddressOfDataCompositionSettings);
	EndIf;
	
	Try
		SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(AddressOfDataCompositionSchema));
	Except
		WriteLogEvent(NStr("vi = 'Thực hiện thao tác';
							|ru = 'Выполнение операции';
							|en = 'Performing operation'; fa = 'در حال اجرای عملیات';
							|it = 'Svolgimento dell''operazione';
							|pl = 'Wykonanie operacji';
							|tr = 'İşlem yürütülüyor'", CommonClientServer.DefaultLanguageCode()),
					EventLogLevel.Error,,,
					DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	If ValueIsFilled(AddressOfDataCompositionSettings) Then
		SettingsComposer.LoadSettings(DataCompositionSettings);
	Else
		SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
	EndIf;
	
	If Not IsBlankString(ProcedureForInitializingCompositionSettings) Then
		ExecuteMethodWhenInitializingLayoutSettings(ProcedureForInitializingCompositionSettings,
		                                                 DataCompositionSchema,
		                                                 SettingsComposer);
	EndIf;
	
	SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
	
EndProcedure

&AtServerNoContext
Procedure PutSettingsInDataLayoutScheme(SettingsComposer, AddressOfDataCompositionSchema)
	
	SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
	
	DataCompositionSchema = GetFromTempStorage(AddressOfDataCompositionSchema);
	
	DataCompositionClientServer.ClearDataLayoutSettings(DataCompositionSchema.DefaultSettings);
	DataCompositionClientServer.CopyDataLayoutSettings(DataCompositionSchema.DefaultSettings, SettingsComposer.Settings);
	
	PutToTempStorage(DataCompositionSchema, AddressOfDataCompositionSchema);
	
EndProcedure

&AtServerNoContext
Function GetComposerSettings(SettingsComposer, UUID)
	
	SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
	
	Return PutToTempStorage(SettingsComposer.GetSettings(), UUID);
	
EndFunction

&AtServerNoContext
Procedure PerformMethodOfPlacingSettingInDataLayoutScheme(NameOfRoomProcedure, SettingsComposer, AddressOfDataCompositionSchema)
	
	DataCompositionSchema = GetFromTempStorage(AddressOfDataCompositionSchema);
	
	MethodParameters = New Structure;
	MethodParameters.Insert("DataCompositionSchema", DataCompositionSchema);
	MethodParameters.Insert("SettingsComposer", SettingsComposer);
	
	ProcedureCall = StringFunctionsClientServer.SubstituteParametersToString(
		"%1(Parameters.%2, Parameters.%3)",
		NameOfRoomProcedure,
		"DataCompositionSchema",
		"SettingsComposer");
		
	Common.ExecuteInSafeMode(ProcedureCall, MethodParameters);
	
	PutToTempStorage(DataCompositionSchema, AddressOfDataCompositionSchema);
	
EndProcedure

&AtServerNoContext
Procedure PerformMethodToCheckDataLayoutScheme(DataCompositionSchema, CheckParameters)
	
	FormIdentifier = CheckParameters.FormIdentifier;
	MethodName = CheckParameters.MethodName;
	ThereAreCriticalErrors = CheckParameters.ThereAreCriticalErrors;
	ListOfCriticalErrorsInTheCompositionSchema = CheckParameters.ListOfCriticalErrorsInTheCompositionSchema;
	
	MethodParameters = New Structure;
	MethodParameters.Insert("DataCompositionSchema", DataCompositionSchema);
	MethodParameters.Insert("ThereAreCriticalErrors", False);
	MethodParameters.Insert("ListOfCriticalErrorsInTheCompositionSchema", New ValueList);
	MethodParameters.Insert("ListOfOtherMessages", New ValueList);
	
	ProcedureCall = StringFunctionsClientServer.SubstituteParametersToString(
		"%1(Parameters.%2, Parameters.%3, Parameters.%4, Parameters.%5)",
		MethodName,
		"DataCompositionSchema",
		"ThereAreCriticalErrors",
		"ListOfCriticalErrorsInTheCompositionSchema",
		"ListOfOtherMessages");
	
	//General purpose.Perform the Configuration method(Method name, method parameters);
	Common.ExecuteInSafeMode(ProcedureCall, MethodParameters);
	
	CheckParameters.ThereAreCriticalErrors = MethodParameters.ThereAreCriticalErrors;
	CheckParameters.ListOfCriticalErrorsInTheCompositionSchema = MethodParameters.ListOfCriticalErrorsInTheCompositionSchema;
	
	If MethodParameters.ThereAreCriticalErrors Then
		For Each CriticalError In MethodParameters.ListOfCriticalErrorsInTheCompositionSchema Do
			UserMessage = New UserMessage;
			UserMessage.Text = CriticalError.Value;
			UserMessage.TargetID = FormIdentifier;
			UserMessage.Message();
		EndDo;
	EndIf;
	If MethodParameters.ListOfOtherMessages.Count() > 0 Then
		For Each VerificationMessage In MethodParameters.ListOfOtherMessages Do
			UserMessage = New UserMessage;
			UserMessage.Text = VerificationMessage.Value;
			UserMessage.TargetID = FormIdentifier;
			UserMessage.Message();
		EndDo;
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure ExecuteMethodWhenInitializingLayoutSettings(MethodName, DataCompositionSchema, SettingsComposer)
	
	MethodParameters = New Structure;
	MethodParameters.Insert("DataCompositionSchema", DataCompositionSchema);
	MethodParameters.Insert("SettingsComposer", SettingsComposer);
	
	ProcedureCall = StringFunctionsClientServer.SubstituteParametersToString(
		"%1(Parameters.%2, Parameters.%3)",
		MethodName,
		"DataCompositionSchema",
		"SettingsComposer");
		
	Common.ExecuteInSafeMode(ProcedureCall, MethodParameters);
	
EndProcedure

&AtServerNoContext
Procedure LoadFromTemplate(FullNameOfTemplateSource, TemplateName, SettingsComposer, AddressOfDataCompositionSchema, ProcedureForInitializingCompositionSettings)
	
	PutToTempStorage(Common.ObjectManagerByFullName(FullNameOfTemplateSource).GetTemplate(TemplateName), AddressOfDataCompositionSchema);
	InitializeSettingsComposer(SettingsComposer,
	                                    AddressOfDataCompositionSchema,,
	                                    ProcedureForInitializingCompositionSettings);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Modified
		And Not Exit Then
		
		ShowQueryBox(New CallbackDescription("BeforeCloseCompletion", ThisObject), 
			NStr("vi = 'Tất cả thông tin chưa được lưu sẽ bị mất. Vẫn đóng?';
				|ru = 'Вся несохраненная информация будет потеряна. Все равно закрыть?';
				|en = 'All unsaved data will be lost. Close anyway?'; fa = 'All unsaved data will be lost. Close anyway?';
				|it = 'Tutte le informazioni non salvate verranno perse. Chiudere lo stesso?';
				|pl = 'Cała wprowadzona informacja zostanie utracona. Zamknąć mimo wszystko?';
				|tr = 'Kaydedilmemiş tüm bilgiler kaybolacaktır. Yine de kapatılsın mı?'"),
			QuestionDialogMode.YesNo);
		Cancel = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		Modified = False;
		Close();
	EndIf;

EndProcedure

&AtServer
Procedure LoadSchemaFromFileOnServer(XMLText)
	
	Try
		
		XMLReader = New XMLReader();
		XMLReader.SetString(XMLText);
		DataCompositionSchema = XDTOSerializer.ReadXML(XMLReader);
		ChangedDataLayoutScheme(ThisForm, DataCompositionSchema);
		
	Except
		
		WriteLogEvent(NStr("vi = 'Thực hiện thao tác';
							|ru = 'Выполнение операции';
							|en = 'Performing operation'; fa = 'در حال اجرای عملیات';
							|it = 'Svolgimento dell''operazione';
							|pl = 'Wykonanie operacji';
							|tr = 'İşlem yürütülüyor'", CommonClientServer.DefaultLanguageCode()),
					EventLogLevel.Error,,,
					DetailErrorDescription(ErrorInfo()));
	
	EndTry;
	
EndProcedure

&AtServer
Procedure DownloadSchemaFromFileOnWebServer(FileAddressInTempStorage)
	
	Try
		
		BinaryData = GetFromTempStorage(FileAddressInTempStorage); // BinaryData
		
		TempFileName = GetTempFileName("xml");
		BinaryData.Write(TempFileName);
		
		TextDocument = New TextDocument;
		TextDocument.Read(TempFileName, TextEncoding.UTF8);
		XMLText = TextDocument.GetText();
		
		XMLReader = New XMLReader();
		XMLReader.SetString(XMLText);
		
		DataCompositionSchema = XDTOSerializer.ReadXML(XMLReader);
		ChangedDataLayoutScheme(ThisForm, DataCompositionSchema);
		
		DeleteFiles(TempFileName);
		
	Except		
		
		WriteLogEvent(NStr("vi = 'Thực hiện thao tác';
							|ru = 'Выполнение операции';
							|en = 'Performing operation'; fa = 'در حال اجرای عملیات';
							|it = 'Svolgimento dell''operazione';
							|pl = 'Wykonanie operacji';
							|tr = 'İşlem yürütülüyor'", CommonClientServer.DefaultLanguageCode()),
					EventLogLevel.Error,,,
					DetailErrorDescription(ErrorInfo())); 	
		
	EndTry;
	
EndProcedure

&AtClient
Procedure ImportSchemaFromFile(Command)
	
	CallbackDescription = New CallbackDescription(
		"DownloadDiagramFromFileExtensionEnabled",
		ThisObject);
	
	BeginAttachingFileSystemExtension(CallbackDescription);
	
EndProcedure

&AtClient
Procedure DownloadDiagramFromFileExtensionEnabled(Attached, AdditionalParameters) Export
	
	If Attached Then
		
		SelectingFile = New FileDialog(FileDialogMode.Open);
		SelectingFile.FullFileName = "";
		SelectingFile.Title = NStr("vi = 'Chọn sơ đồ dàn dựng dữ liệu';
									|ru = 'Выбор схемы компоновки данных';
									|en = 'Select a data composition schema'; fa = 'Select a data composition schema';
									|it = 'Selezione dello schema del layout dei dati';
									|pl = 'Wybór schematu układu danych';
									|tr = 'Veri inşa edilme şeması seçimi'");
		SelectingFile.Filter = NStr("vi = 'Sơ đồ dàn dựng dữ liệu (*.xml)|*.xml';
									|ru = 'Схема компоновки данных (*.xml)|*.xml';
									|en = 'Data composition schema (*.xml)|*.xml'; fa = 'Data composition schema (*.xml)|*.xml';
									|it = 'Schema del layout dei dati (*.xml)|*.xml';
									|pl = 'Schemat układu danych (*.xml)|*.xml';
									|tr = 'Veri inşa edilme şeması (*.xml)|*.xml'");
		
		CallbackDescription = New CallbackDescription(
			"LoadSchemaFromFileFILESelection",
			ThisObject);
		
		SelectingFile.Show(CallbackDescription);
		
	Else
		
		#If WebClient Then
			
			FileAddressInTempStorage = "";
			FileName = "";
			BeginPutFile(
				New CallbackDescription(
					"ImportSchemaFromFileCompletion",
					ThisObject,
					New Structure("FileAddressInTempStorage", FileAddressInTempStorage)),
				FileAddressInTempStorage,
				FileName,
				True,
				UUID);
			
		#EndIf
		
	EndIf;
	
EndProcedure

&AtClient
Procedure LoadSchemaFromFileFILESelection(SelectedFiles, AdditionalParameters) Export
	
	If SelectedFiles = Undefined Then
		Return;
	EndIf;
	
	TextDocument = New TextDocument;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("TextDocument", TextDocument);
	
	CallbackOnCompletion = New CallbackDescription("LoadSchemaFromFileFILESelectionCompletion", ThisObject, AdditionalParameters);
	
	TextDocument.BeginReading(CallbackOnCompletion, SelectedFiles[0], TextEncoding.UTF8);
	
EndProcedure

&AtClient
Procedure LoadSchemaFromFileFILESelectionCompletion(AdditionalParameters) Export
	
	TextDocument = AdditionalParameters.TextDocument;
	
	Text = TextDocument.GetText();
	
	ClearMessages();
	LoadSchemaFromFileOnServer(Text);

EndProcedure

&AtClient
Procedure ImportSchemaFromFileCompletion(Result, Address, FileName, AdditionalParameters) Export
	
	FileAddressInTempStorage = AdditionalParameters.FileAddressInTempStorage;
	
	If Not Result Then
		Return;
	EndIf;
	
	ClearMessages();
	DownloadSchemaFromFileOnWebServer(FileAddressInTempStorage);
	
EndProcedure

#EndRegion

#EndRegion
