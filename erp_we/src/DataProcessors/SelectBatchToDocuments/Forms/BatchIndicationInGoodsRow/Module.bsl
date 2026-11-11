
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	SeriesDisplayMode = "OnlyBalance";
	
	SeriesSpecificationParameters = Parameters.SeriesSpecificationParameters;
	
	LinkFieldValuesStructure = New Structure(StrConcat(SeriesSpecificationParameters.AdditionalFieldNames,","));
	LinkFieldValuesStructure.Insert("Products");
	LinkFieldValuesStructure.Insert("Characteristic");
	LinkFieldValuesStructure.Insert("Warehouse");
	FillPropertyValues(LinkFieldValuesStructure, Parameters);
	ConnectionFieldValues = New FixedStructure(LinkFieldValuesStructure);
	
	Warehouse = Parameters.Warehouse;
	
	Count = Parameters.Count;
	WizardMode = Parameters.WizardMode;

	AnExternalUserIsAuthorized = TMCommonUseClientServer.AnExternalUserIsAuthorized();
	
	TMCommonUse.CustomizePeripherals(ThisForm, "");
	
	ProductAttributes = New FixedStructure(Common.ObjectAttributesValues(Parameters.Products,
		"ProductKind,UnitOfMeasure,AccountingFeature,ExpirationDate_,ShelfLifeUnitOfMeasure"));
		
	FillPropertyValues(ThisObject, ProductAttributes); 
	
	SeriesUseSettings = New FixedStructure(Catalogs.ItemKinds.SeriesUseSettings(
																							ProductAttributes.ProductKind,
																							SeriesSpecificationParameters,
																							ConnectionFieldValues));
																							
	ProductsServer.CheckWhetherSeriesIndicationFormCanBeOpened(SeriesUseSettings, SeriesSpecificationParameters, ConnectionFieldValues);
	
	ReferenceOrder    = DataProcessors.SelectBatchToDocuments.OrderOnFormParameters(Parameters);
	ProductKind = SeriesUseSettings.BatchOwner;
	
	TimeRequestParameters = New Structure;
	TimeRequestParameters.Insert("Products", Parameters.Products);
	TimeRequestParameters.Insert("Characteristic", Parameters.Characteristic);
	If Parameters.Property("Purpose") Then
		Purpose = Parameters.Purpose;
		
		If SeriesSpecificationParameters.NameOfSenderWarehouseField <> Undefined
			And SeriesSpecificationParameters.NameOfRecipientWarehouseField <> Undefined Then //this is the movement of goods
			Purpose = Parameters.AssignmentSender;
		EndIf;
		
		TimeRequestParameters.Insert("Purpose", Purpose);
		
	Else
		TimeRequestParameters.Insert("Purpose", Catalogs.Assignments.EmptyRef());
	EndIf;
	TimeRequestParameters.Insert("ControlledLotReference", Parameters.ControlledLotReference);
	TimeRequestParameters.Insert("Warehouse", Parameters.Warehouse);
	TimeRequestParameters.Insert("Premise", Parameters.Premise);
	TimeRequestParameters.Insert("Recorder", Parameters.Recorder);
	TimeRequestParameters.Insert("ReferenceOrder", ReferenceOrder);
	
	For Each AdditionalParameter In SeriesSpecificationParameters.ParametersForGettingDataFromRegisters Do
		TimeRequestParameters.Insert(AdditionalParameter.Key, AdditionalParameter.Value);
	EndDo;
	
	QueryOptions = New FixedStructure(TimeRequestParameters);
	
	OptionOfDataReceivingFromRegisters = DataProcessors.SelectBatchToDocuments.OptionGettingDataFromRegistersByFormParameters(SeriesSpecificationParameters, 
																															ReferenceOrder,
																															Parameters.Warehouse,
																															ProductAttributes.ProductKind);
	
	If DataProcessors.SelectBatchToDocuments.ThereAreRightsToReadRegisterData(OptionOfDataReceivingFromRegisters, Warehouse) Then
		ExecuteRequestToFillInBalanceTable();
	Else
		Items.SeriesPages.PagesRepresentation = FormPagesRepresentation.None;
	EndIf;
	
	Headers = DataProcessors.SelectBatchToDocuments.HeadersForOptionGettingDataFromRegisters(OptionOfDataReceivingFromRegisters);
	
	Items.SeriesDisplayMode.ChoiceList[0].Presentation = Headers.ButtonTitle;
	
	If OptionOfDataReceivingFromRegisters <> "AllSeriesProducts" Then
		FreeBalanceHeader = StrReplace(Headers.FreeBalanceHeader,"%UnitOfMeasure%", ProductAttributes.UnitOfMeasure);
		Items.RemainingSeriesAvailableStock.Title = FreeBalanceHeader;
	Else
		Items.RemainingSeriesAvailableStock.Visible = False;
		Items.SeriesDisplayMode.Visible = False;
	EndIf;
	
	Series = Parameters.Series;
	RecordPlacemarkFields = New Structure("RFIDEPC,RFIDUser", False, False);
	
	For Each LongDesc In SeriesUseSettings.DescriptionsOfUseOfSeriesProps Do
		If LongDesc.SettingName = "UseRFIDTags" Then
			
			If LongDesc.AttributeName = "RFIDTID" Then
				If LongDesc.Use Then
					Readers = EquipmentManagerServerCall.EquipmentByParameters("RFIDReaders");
					If Readers.Count() = 0 Then
						ConnectRFIDReader = False;
					ElsIf Readers.Count() = 1 Then
						ConnectRFIDReader = True;
						RFIDReaders = Readers[0].Ref;
					Else
						MessageText = NStr("vi = 'Đã kết nối nhiều thiết bị đọc RFID cho chỗ làm việc. Không hỗ trợ làm việc cùng lúc với một số thiết bị đọc. Hãy để lại chỉ một thiết bị đọc.';
											|ru = 'К рабочему месту подключено несколько считывателей RFID. Работа одновременно с несколькими считывателями не поддерживается. Оставьте только один считываетель.';
											|en = 'Several RFID readers are connected to the workplace. You cannot run multiple readers simultaneously. Please keep only one reader to continue.'; fa = 'Several RFID readers are connected to the workplace. You cannot run multiple readers simultaneously. Please keep only one reader to continue.';
											|it = 'Diversi lettori RFID sono collegati al posto di lavoro. Il lavoro simultaneo con più lettori non è supportato. Lascia un solo lettore.';
											|pl = 'Do miejsca pracy są podłączone kilka czytników RFID. Praca jednocześnie z wieloma czytnikami nie jest obsługiwana. Zostaw tylko jeden czytnik.';
											|tr = 'Çalışma alanına birden fazla RFID okuyucu bağlanmıştır. Birden fazla okuyucu ile eşzamanlı çalışma desteklenmez. Sadece bir okuyucu bırak.'");
						CommonClientServer.MessageToUser(MessageText);
						ConnectRFIDReader = False;
					EndIf;
				Else
					ConnectRFIDReader = False;
				EndIf;
				Items.RFIDOperationStatus.Visible = LongDesc.Use;
				
				Items.ReadRFID.Visible = LongDesc.Use
												 And ConnectRFIDReader
												 And Not AnExternalUserIsAuthorized;
												 
				Items.RFIDTagIsCorruptedAndCannotBeRead.Visible       = LongDesc.Use;
				
			ElsIf (LongDesc.AttributeName = "RFIDEPC"
				Or LongDesc.AttributeName = "RFIDUser")
				And LongDesc.Use Then	
				
				RecordPlacemarkFields[LongDesc.AttributeName] = LongDesc.CanBeEdited;
				
			EndIf;
			
		Else
	
			FormFieldProps = Items[LongDesc.AttributeName]; // FormField
			FormFieldRemnantsOfSeries = Items[DataProcessors.SelectBatchToDocuments.NamesOfSeriesElements(LongDesc.AttributeName).RemainingSeries]; // FormField
			
			FormFieldProps.Visible                  = LongDesc.Use; 
			FormFieldRemnantsOfSeries.Visible              = LongDesc.Use;
			FormFieldProps.ReadOnly             = Not LongDesc.CanBeEdited; 	
			FormFieldProps.AutoMarkIncomplete  = LongDesc.CheckFilling; 	
			
			If Not IsBlankString(LongDesc.Format) Then
				FormFieldProps.Format               = LongDesc.Format;
				FormFieldProps.EditFormat = LongDesc.Format;
				
				FormFieldRemnantsOfSeries.Format               = LongDesc.Format;
				FormFieldRemnantsOfSeries.EditFormat = LongDesc.Format;
			EndIf;
			
			If Not IsBlankString(LongDesc.PresentationOfFormatStringInHeader) Then
				ColumnHeaderPresentation = NStr("vi = '%AttributeRepresentation% (%FormatPresentation%)';
												|ru = '%AttributeRepresentation% (%FormatPresentation%)';
												|en = '%AttributeRepresentation% (%FormatPresentation%)'; fa = '%AttributeRepresentation% (%FormatPresentation%)';
												|it = '%AttributeRepresentation% (%FormatPresentation%)';
												|pl = '%AttributeRepresentation% (%FormatPresentation%)';
												|tr = '%AttributeRepresentation% (%FormatPresentation%)'");
				ColumnHeaderPresentation = StrReplace(ColumnHeaderPresentation, "%AttributeRepresentation%", LongDesc.AttributeRepresentation);
				ColumnHeaderPresentation = StrReplace(ColumnHeaderPresentation, "%FormatPresentation%", LongDesc.PresentationOfFormatStringInHeader);
				
				FormFieldProps.Title     = ColumnHeaderPresentation; 
				FormFieldRemnantsOfSeries.Title = ColumnHeaderPresentation;
			EndIf;
			
			If LongDesc.AttributeName = "Number" Then
				
				Items.GenerateNumber.Visible        = Items.Number.Visible;
				Items.GenerateNumber.Enabled      = Not Items.Number.ReadOnly;
				
			EndIf;
			
			If Not IsBlankString(LongDesc.ConditionalAppearanceText) Then
				ToolTipText = StrReplace(LongDesc.ConditionalAppearanceText, "<","");
				ToolTipText = StrReplace(LongDesc.ConditionalAppearanceText, ">","");
				
				FormFieldProps.InputHint = LongDesc.ConditionalAppearanceText;
				FormFieldProps.ToolTip      = ToolTipText;
			EndIf;
			
		EndIf;
	EndDo;
	
	Items.WriteToRFID.Visible = (RecordPlacemarkFields.RFIDEPC
										Or RecordPlacemarkFields.RFIDUser)
										And ConnectRFIDReader
										And Not AnExternalUserIsAuthorized;
	
	If Not IsBlankString(WizardMode) Then
		
		AttributesStructure1 = New Structure(SerialEntryDetails(SeriesUseSettings));
		
		NewSeries               = Parameters.Series;
		FillInDetailsOfSeries(AttributesStructure1, NewSeries, SeriesUseSettings);
		NewSeriesInputCache       = New FixedStructure(AttributesStructure1);
		
		WrittenOffBatch = Parameters.WrittenOffTheSeries;
		FillInDetailsOfSeries(AttributesStructure1, WrittenOffBatch, SeriesUseSettings);
		ASeriesOfWriteCacheEntry = New FixedStructure(AttributesStructure1);
		
		If WizardMode = "NewSeries_" Then
			CustomizeFormStepByStep("Step2");
		Else
			CustomizeFormStepByStep("Step1");
		EndIf;
		
		Items.OK.Title = NStr("vi = 'Đồng ý';
								|ru = 'Готово';
								|en = 'Finish'; fa = 'پایان';
								|it = 'Fine';
								|pl = 'Finish';
								|tr = 'Bitiş'");
		
	Else
		
		Items.NavigationPanel.CurrentPage = Items.NavigationEndPage;
		Items.BackGroup.Visible = False;
		
		FoundRows = RemainingSeries.FindRows(New Structure("Series",Series));
		If FoundRows.Count() > 0 Then
			Items.RemainingSeries.CurrentRow = FoundRows[0].GetID();
		EndIf;
		
	EndIf;
	
	Items.PrintLabel.Visible = Not AnExternalUserIsAuthorized;
	
	CurrentRowID = Parameters.CurrentRowID;
	
	If Parameters.ReadOnly Then
		Parameters.ReadOnly = False; //To exclude platform processing
		
		Items.Number.ReadOnly   = True;
		Items.ValidUntil_.ReadOnly = True;
		Items.OK.Enabled         = False;
		
		DisplayMode = True;
	EndIf;
	
	CloseOnChoice = False;
	
	FillInDetailsOfSeries(ThisForm, Series, SeriesUseSettings);
	FillInFlagsForWorkingWithPlacemark();
	
	If ValueIsFilled(Parameters.Text)
		And (Not ValueIsFilled(Series) Or Parameters.Text <> Description) Then
		DetailsOfSeriesFromLine = ProductsServer.DetailsOfSeriesFromLine(Parameters.Text, SeriesUseSettings);
		FillPropertyValues(ThisForm,DetailsOfSeriesFromLine);
	EndIf;
	
	SeriesAddingRight = AccessRight("Insert", Metadata.Catalogs.ItemsBatches);
	
	If SeriesAddingRight Then
		
		// We will output the fields for filling in additional details of the series 
		If ValueIsFilled(Parameters.Series) Then
			ObjectSeries = Parameters.Series.GetObject();
		Else
			ObjectSeries = Catalogs.ItemsBatches.EmptyObject(SeriesUseSettings.BatchOwner);
		EndIf;
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("Object", ObjectSeries);
		AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
		PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
		
		TMPropertyManagement.CheckBlankProperties(ThisForm, ObjectSeries);
		
	EndIf;
	
	SetTitleScenerySeries();
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing, Parameters);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If SeriesAddingRight Then
		// StandardSubsystems.Properties
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
		// End StandardSubsystems.Properties
	EndIf;
	
	RFIDRecordingIsUnderway = False;
	
	SupportedTypesOfEquipment = "BarcodeScanner";
	
	If ConnectRFIDReader Then
		SupportedTypesOfEquipment = SupportedTypesOfEquipment + ", RFIDReaders";
	EndIf;
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, SupportedTypesOfEquipment);

	CurrentProductionDate = ProductionDate;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)

	BarcodingOfItemsClient.DisableHardware(Undefined, New Structure("Form",ThisForm));

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If Source = "Peripherals" And IsInputAvailable() And Not ReadOnly Then
		CompleteSelection_1 = False;
		
		If EventName = "ScanData" Then
			
			If DisplayMode Then
				Return;
			EndIf;
			
			If ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToArray(Parameter)) Then
				CompleteSelection_1 = True;
			EndIf;
			
		ElsIf EventName = "RFID"
			And Not RFIDRecordingIsUnderway
			And BarcodingOfItemsClient.ServerCallIsNeededToHandleRFID(Parameter, ThisForm) Then
			ProcessRFIDReading(Parameter);
		EndIf;
		
		If CompleteSelection_1
			And IsBlankString(WizardMode)
			And RequiredDetailsFilledIn(False) Then
			AttachIdleHandler("SelectSeriesCompleteInput", 0.1, True);
		EndIf;
		
	EndIf;
	
	If EventName = "RFID_SeriesRecording" Then
		RFIDEPC = Parameter.RFIDEPC;
		FindCreateSeries();
	EndIf;
	
	If EventName = "Write_ItemsBatches" Then
		FillPropertyValues(ThisForm,Parameter);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If SeriesAddingRight Then
		// Let's check the filling in of the mandatory additional details of the series
		PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlers

&AtClient
Procedure DisplayModeOnChange(Item)
	ExecuteRequestToFillInBalanceTable();
EndProcedure

&AtClient
Procedure RemainingSeriesSelection(Item, RowSelected, Field, StandardProcessing)
	
	RemainingSeriesSelectionClient();
	
EndProcedure

&AtClient
Procedure RemainingSeriesSelectionClient()
	
	ClearMessages();

	CurrentData = Items.RemainingSeries.CurrentData;
	
	If CurrentData = Undefined Then
		WarningText = NStr("vi = 'Hãy chọn phiên bản hoặc nhập mới.';
							|ru = 'Выберите серию или введите новую.';
							|en = 'Select batch or enter a new one'; fa = 'Select batch or enter a new one';
							|it = 'Seleziona la serie o inserire una nuova.';
							|pl = 'Wybierz serię lub wprowadź nową.';
							|tr = 'Partiyi seç veya yenisini gir'");	
		ShowMessageBox(Undefined, WarningText);
		Return;
	EndIf;
	
	If Not IsBlankString(WizardMode)
		And Items.NavigationPanel.CurrentPage = Items.NavigationStartPage Then
		GoToNextStep();
	Else
		SelectSeriesCompleteInput();
	EndIf;
	
EndProcedure

&AtClient
Procedure RFIDTagIsCorruptedAndCannotBeReadOnChange(Item)
	FillInFlagsForWorkingWithPlacemark();
EndProcedure

&AtClient
Procedure SelectASeries(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	SelectASeriesServer(Item.Name);
	
EndProcedure

&AtClient
Procedure ValidUntil_StartChoice(Item, ChoiceData, StandardProcessing)
	
	ParameterNames = "ValidUntil_, ProductionDate, ExpirationDate_, ShelfLifeUnitOfMeasure, DateFormat, 
						|UseProductionDate";
	FormParameters = New Structure(ParameterNames);
	
	FillPropertyValues(FormParameters, ThisForm);
	
	FormParameters.DateFormat                   = Item.EditFormat;
	FormParameters.UseProductionDate = SeriesUseSettings.UseBatchProductionDate;
	
	CallbackDescription = New CallbackDescription("ValidUntil_StartChoiceCompletion", ThisObject);
	
	ProductsClient.ExpirationDateStartOfSelection(ThisForm, FormParameters, CallbackDescription,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure ValidUntil_StartChoiceCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		SelectASeriesServer("ValidUntil_");
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductionDateStartChoice(Item, ChoiceData, StandardProcessing)
	
	CallbackDescription = New CallbackDescription("ProductionDateStartChoiceCompletion", ThisObject);
	
	ProductsClient.ProductionDateStartChoice(ThisForm, CallbackDescription, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ProductionDateStartChoiceCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		SelectASeriesServer("ProductionDate");
	EndIf;
	
EndProcedure


#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	SelectSeriesCompleteInput();
EndProcedure

&AtClient
Procedure Cancel(Command)
	Close();
EndProcedure

&AtClient
Procedure Next(Command)
	
	If Items.SeriesPages.CurrentPage = Items.PageSeriesBalance Then
		RemainingSeriesSelectionClient();
	Else
		
		
		If Not RequiredDetailsFilledIn(,True) Then
			Return;
		EndIf;
		GoToNextStep();
	EndIf;
	
EndProcedure

&AtClient
Procedure Back(Command)
	
	GoBackToPreviousStep();
	
EndProcedure

&AtClient
Procedure ReadTheLabel(Command)
	ClearMessages();
	BarcodingOfItemsClient.OpenRFIDReaderSession(ThisForm);
	AttachIdleHandler("WorkOutTimeoutWaitingForRFIDReading", 5, True);
EndProcedure

&AtClient
Procedure WriteToRFID(Command)
	RFIDRecordingIsUnderway = True;
	
	WriteParameters = New Structure;
	WriteParameters.Insert("SeriesData",SeriesData(SeriesUseSettings, ThisForm));
	WriteParameters.Insert("Form", ThisForm);
	
	BarcodingOfItemsClient.WriteDataToTFID(Undefined, WriteParameters);
	
EndProcedure

&AtClient
Procedure GenerateNumber(Command)
	
	GenerateNumberServer();
	
EndProcedure

&AtClient
Procedure PrintLabel(Command)
	
	NumberOfLabels = Count;
	
	If Not ValueIsFilled(SeriesUseSettings.LabelTemplateBatches) Then
		
		Filter = New Structure;
		Filter.Insert("Purpose", PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.ItemsBatchLabel"));
		
		FormParameters = New Structure("Filter",Filter);
		
		OpenForm(
			"Catalog.LabelAndPriceTagTemplates.ChoiceForm",
			FormParameters,ThisForm,,,,
			New CallbackDescription("PrintCompletion", 
				ThisObject,
				New Structure("NumberOfLabels", NumberOfLabels)),
			FormWindowOpeningMode.LockOwnerWindow);
		
		Return;
		
	EndIf;
	
	PrintFragment(NumberOfLabels);
	
EndProcedure

#EndRegion

#Region Private

// StandardSubsystems.Properties

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject, ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject, ThisObject);
EndProcedure

// End StandardSubsystems.Properties

#Region Print

&AtClient
Procedure PrintCompletion(Result, AdditionalParameters) Export
  
    If Not ValueIsFilled(Result) Then
        Return;
    EndIf;
	
	SeriesUsageSettingsStructure                     = New Structure(SeriesUseSettings);
	SeriesUsageSettingsStructure.LabelTemplateBatches = Result;
	SeriesUseSettings                              = New FixedStructure(SeriesUsageSettingsStructure);
	
    PrintFragment(AdditionalParameters.NumberOfLabels);

EndProcedure

&AtClient
Procedure PrintFragment(NumberOfLabels)
    
	If Not FindCreateSeries() Then
		Return;
	EndIf;
	
	ShowInputNumber(
		New CallbackDescription(
			"PrintFragmentCompletion", 
			ThisObject,
			New Structure("Series", Series)),
		NumberOfLabels,
		NStr("vi = 'Số lượng bản gốc (chính)';
			|ru = 'Количество экземпляров';
			|en = 'Number of copies'; fa = 'تعداد نسخه';
			|it = 'Quantità dei esemplari';
			|pl = 'Ilość egzemplarzy';
			|tr = 'Nüsha miktarı'"),
		8,
		0);
		
EndProcedure

&AtClient
Procedure PrintFragmentCompletion(Result, AdditionalParameters) Export
	
	If Not ValueIsFilled(Result) Or Result < 1 Then
		Return;
	EndIf;
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("AddressInStorage", PrepareDataForPrinting(Result, AdditionalParameters.Series));
    
    ParametersStructure.Insert("LabelsTemplate", SeriesUseSettings.LabelTemplateBatches); 
    ParametersStructure.Insert("TemplateAssignment", PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.ItemsBatchLabel"));
    ParametersStructure.Insert("Copies", 1);
    
    CommandParameter = New Array;
    CommandParameter.Add(PredefinedValue("Catalog.ItemsBatches.EmptyRef"));
    
	PrintManagementClient.ExecutePrintCommand(
        "DataProcessor.PrintPriceTagsAndLabels",
        "ItemsBatchLabel",
        CommandParameter,
        ThisForm,
        ParametersStructure);
    
	
EndProcedure

&AtServer
Function PrepareDataForPrinting(NumberOfLabels, Val Series)
	
	ItemsBatches = New ValueTable;
	ItemsBatches.Columns.Add("Series",		New TypeDescription("CatalogRef.ItemsBatches"));
	ItemsBatches.Columns.Add("Barcode",	New TypeDescription("String"));
	
	NumberOfCopies = NumberOfLabels;
	
	While NumberOfCopies > 0 Do
		
		NumberOfCopies = NumberOfCopies - 1;
		
		NewRow = ItemsBatches.Add();
		NewRow.Series = Series;
		
		DateFormatTemplate = NStr("vi = 'DF=""%1""';
									|ru = 'ДФ=""%1""';
									|en = 'DF=""%1""'; fa = 'DF=""%1""';
									|it = 'ДФ=""%1""';
									|pl = 'DF=""%1""';
									|tr = 'DF=""%1""'");
		DateFormatTemplate = StrTemplate(DateFormatTemplate, "DdMMggHH");
		
		If SeriesUseSettings.UseShelfLifeOnBatchRegistration	And SeriesUseSettings.SpecifyNumberWhenRegisteringBatch Then
			NewRow.Barcode = TrimAll(Number) + Format(ValidUntil_, DateFormatTemplate);
		ElsIf SeriesUseSettings.SpecifyNumberWhenRegisteringBatch Then
			NewRow.Barcode = TrimAll(Number);
		Else
			NewRow.Barcode = Format(ValidUntil_,DateFormatTemplate);
		EndIf;
		
	EndDo;
	
	Return PutToTempStorage(ItemsBatches);
	
EndFunction

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure
// End StandardSubsystems.Properties

#EndRegion

#Region BarcodesAndTradeEquipment

&AtClient
Function ProcessBarcodes(BarcodeData_5)
	
	If BarcodeData_5.Count() <> 1 Then
		
		MessageText = NStr("vi = 'Không hỗ trợ nhận dạng cùng lúc nhiều mã vạch sê-ri. Hãy quét từng sê-ri.';
							|ru = 'Не поддерживается одновременное распознование нескольких штрих-кодов серий. Сканируйте серии по одной.';
							|en = 'Simultaneous recognition of several batch barcodes is not supported. Scan the batch one by one.'; fa = 'Simultaneous recognition of several batch barcodes is not supported. Scan the batch one by one.';
							|it = 'Il riconoscimento simultaneo di più codici a barre serie non è supportato. Analizza le serie una per una.';
							|pl = 'Nie jest możliwe jednoczesne rozpoznawanie kilku kodów kreskowych serii. Skanuj serie po jednej.';
							|tr = 'Bir partideki birden fazla barkodun aynı anda tanınmasını desteklemez. Partileri teker teker tara.'");
		ShowMessageBox(,MessageText);
		Return False;
		
	EndIf;
	
	ProcessBarcodesServer(BarcodeData_5);
	
	Return True;
	
EndFunction

&AtServer
Procedure ProcessBarcodesServer(BarcodeData_5)
	
	BarcodesByType = BarcodingOfItemsServer.StructureByBarcodeType(BarcodeData_5);
	
	If BarcodesByType.WithoutType.Count() > 0 Then
		Barcode = BarcodeData_5[0].Barcode;
		
		FieldsFromBarcode = BarcodingOfItemsServer.SeriesInformationFromBarcode(
							Barcode,
							SeriesUseSettings.SpecifyNumberWhenRegisteringBatch,
							SeriesUseSettings.UseShelfLifeOnBatchRegistration);
		
		Number	= FieldsFromBarcode.Number;
		ValidUntil_	= FieldsFromBarcode.ValidUntil_;
		
		SelectASeriesServer("");
		
	EndIf;
	
	ProcessBarcodesServerLocalization(BarcodesByType);
	
EndProcedure

&AtClient
Procedure WorkOutTimeoutWaitingForRFIDReading()
	
	If RFIDReaderSessionHasBeenOpened Then
		BarcodingOfItemsClient.WorkOutTimeoutWaitingForRFIDReading(ThisForm);
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessRFIDReading(LBLData)
	
	ProcessingParameters = BarcodingOfItemsServer.ReadRFIDProcessingParameters();
	FillPropertyValues(ProcessingParameters,ThisForm);
	
	ProcessingResult = BarcodingOfItemsServer.ProcessRFIDReading(LBLData, ProcessingParameters);
	
	If ValueIsFilled(ProcessingResult.SeriesData) Then
		FillPropertyValues(ThisForm, ProcessingResult.SeriesData);
		If ValueIsFilled(Series) Then
			TheStructureOfTheSearch = New Structure("Series",Series);
			FoundRows = RemainingSeries.FindRows(TheStructureOfTheSearch);
			If FoundRows.Count() > 0 Then
				Items.RemainingSeries.CurrentRow = FoundRows[0].GetID();
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure SelectASeriesServer(EnteringDetails)
	
	If EnteringDetails = "ValidUntil_"
		Or EnteringDetails = "ProductionDate" Then
		
		ProductsClientServer.RecalculateSeriesDate(ThisObject[EnteringDetails]);
		If EnteringDetails = "ProductionDate" Then
			ProductIsValidUntilDateOfProduction();
		EndIf;
		
	EndIf;

	Query = New Query;
	TemplateOfTheConditionForTheBankDetails = " ItemsBatches.%AttributeName% = &%AttributeName% ";
	
	ArrayOfConditionsAnd   = New Array;
	ArrayOfConditionsOR = New Array;
	
	EmptyPropsValues = TMCommonUse.StructureWithMetadataObjectProperties(Metadata.Catalogs.ItemsBatches);
	
	For Each LongDesc In SeriesUseSettings.DescriptionsOfUseOfSeriesProps Do
		If LongDesc.SettingName <> "UseRFIDTags" Then
			If LongDesc.Use Then
				ConditionText = StrReplace(TemplateOfTheConditionForTheBankDetails, "%AttributeName%", LongDesc.AttributeName);
				Query.SetParameter(LongDesc.AttributeName, ThisObject[LongDesc.AttributeName]);
				
				If LongDesc.CheckUniquenessOfValue Then
					ArrayOfConditionsOR.Add(ConditionText);
				Else
					ArrayOfConditionsAnd.Add(ConditionText);
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
	QueryText = 
	"SELECT
	|	ItemsBatches.Ref AS Series
	|FROM
	|	Catalog.ItemsBatches AS ItemsBatches
	|WHERE
	|	ItemsBatches.ProductKind = &ProductKind
	|	AND (&TextOfTermsAndConditions_
	|		OR &ConditionsOrText_)";
	
	If ArrayOfConditionsAnd.Count() > 0 Then
		TextOfTermsAndConditions = StrConcat(ArrayOfConditionsAnd, "And");
	Else
		TextOfTermsAndConditions = "FALSE";
	EndIf;
	
	If ArrayOfConditionsOR.Count() > 0 Then
		ConditionsOrText = StrConcat(ArrayOfConditionsOR, "OR");
	Else
		ConditionsOrText = "FALSE";
	EndIf;
	
	QueryText = StrReplace(QueryText,"&TextOfTermsAndConditions_",TextOfTermsAndConditions);
	QueryText = StrReplace(QueryText,"&ConditionsOrText_",ConditionsOrText);
	
	Query.Text = QueryText;
	
	Query.SetParameter("ProductKind", SeriesUseSettings.BatchOwner);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Series = Selection.Series;
	Else
		Series = Catalogs.ItemsBatches.EmptyRef();
	EndIf;
	
	SetTitleScenerySeries();
	
EndProcedure

&AtServer
Procedure GenerateNumberServer()
	
	PhoneNumber_ = Catalogs.ItemsBatches.CalculateMaximumSeriesNumber(ProductKind) + 1;
	Number = Format(PhoneNumber_, "ND=8; NLZ=; NG=");
	Series = Catalogs.ItemsBatches.EmptyRef();
	SetTitleScenerySeries();
	
EndProcedure

&AtServer
Procedure FillInFlagsForWorkingWithPlacemark()
	
	SeriesData = SeriesData(SeriesUseSettings, ThisObject);
	
	ParametersForFillingInFlagsForWorkingWithPlacemark = BarcodingOfItemsServer.ParametersForFillingInFlagsForWorkingWithPlacemark();
	ParametersForFillingInFlagsForWorkingWithPlacemark.CurLabel_ = Undefined;
	ParametersForFillingInFlagsForWorkingWithPlacemark.SeriesUseSettings = SeriesUseSettings;
	ParametersForFillingInFlagsForWorkingWithPlacemark.ConnectionFieldValues = ConnectionFieldValues;
	
	BarcodingOfItemsServer.FillInFlagsForWorkingWithPlacemark(SeriesData, ParametersForFillingInFlagsForWorkingWithPlacemark);
	
	FillPropertyValues(ThisObject, SeriesData);
	
	If RFIDTagIsCorruptedAndCannotBeRead Then
		YouNeedToSaveMark = False;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function SeriesData(SeriesUseSettings, DataToFill)
	
	SeriesData = New Structure(SerialEntryDetails(SeriesUseSettings));
	FillPropertyValues(SeriesData, DataToFill);
	
	Return SeriesData;
	
EndFunction

&AtClient
Procedure SelectSeriesCompleteInput()
	
	If DisplayMode Then
		Return;
	EndIf;
	
	ClearMessages();
	
	ReturnValue = ProductsClientServer.SelectedSeries();
	
	CurrentData = Items.RemainingSeries.CurrentData;
	
	If Items.SeriesPages.CurrentPage = Items.PageSeriesBalance Then
		If CurrentData = Undefined Then
			WarningText = NStr("vi = 'Chọn hoặc nhập một sê-ri.';
								|ru = 'Выберите или введите серию.';
								|en = 'Select or enter batch.'; fa = 'Select or enter batch.';
								|it = 'Seleziona o inserisci la serie.';
								|pl = 'Wybierz lub wpisz serię.';
								|tr = 'Seçin veya yeni parti gir.'");	
			ShowMessageBox(Undefined, WarningText);
			Return;
		EndIf;
		
		Series = CurrentData.Series;
		
	ElsIf Not RequiredDetailsFilledIn()
		Or Not FindCreateSeries() Then
		
		Return;
		
	EndIf;
	
	ReturnValue.CurrentRowID = CurrentRowID;
	ReturnValue.Value                   = Series;
	ReturnValue.TSName                      = SeriesSpecificationParameters.NameTSGoods;
	If Not IsBlankString(WizardMode) Then
		ReturnValue.ValueOfDebitedSeries = WrittenOffBatch;
	EndIf;
	NotifyChoice(ReturnValue);
	Close();
	
EndProcedure

&AtClient
Function RequiredDetailsFilledIn(OutputMessages = True, ThisIsDecommissionedLabel = False)
	
	Cancel = False;
	
	If Not IsBlankString(WizardMode) 
		And ThisIsDecommissionedLabel 
		And YouNeedToSaveMark Then
		
		MessageText = NStr("vi = 'Các tham số của thẻ RFID không tương ứng các tham số dự kiến: đã đọc thẻ không được cá nhân hóa hoặc thẻ có GTIN khác được đọc hoặc số được ghi trong thẻ không khớp với TID. Đọc nhãn khác.';
							|ru = 'Параметры RFID-метки не соответствуют ожидаемым: либо считана неперсонифицированная метка, либо считана метка с другим GTIN, либо записанный в метку номер не соответствует TID. Считайте другую метку.';
							|en = 'RFID tag parameters are not as expected: either a non-personal tag is scanned, or a tag with another GTIN is scanned, or the number saved to the tag does not match TID. Scan another tag.'; fa = 'RFID tag parameters are not as expected: either a non-personal tag is scanned, or a tag with another GTIN is scanned, or the number saved to the tag does not match TID. Scan another tag.';
							|it = 'I parametri dei tag RFID non sono come previsto: viene letto un tag non personalizzato oppure viene letto un tag con un altro GTIN oppure il numero scritto nel tag non corrisponde al TID. Leggi un''altra etichetta.';
							|pl = 'Parametry znacznika RFID nie są zgodne z oczekiwanymi: albo został odczytany niespersonalizowany znacznik z innym GTIN, albo zapisany w znaczniku numer nie odpowiada TID. Odczytaj inny znacznik.';
							|tr = 'RFID etiket parametreleri beklendiği gibi değil: kişiselleştirilmemiş etiket okundu veya farklı bir GTIN''ye sahip etiket okundu ya da etikete kaydedilen numara TID ile eşleşmiyor. Başka bir etiket okutun.'");
		CommonClientServer.MessageToUser(MessageText);
		Cancel = True;
		
	ElsIf SeriesUseSettings.UseRFIDTags
		And RFIDTIDFilledIn
		And YouNeedToSaveMark Then
		
		Cancel = True;
		If OutputMessages Then
			MessageText = NStr("vi = 'Cần có thẻ RFID.';
								|ru = 'Требуется записать RFID-метку.';
								|en = 'Save RFID tag.'; fa = 'Save RFID tag.';
								|it = 'È richiesto scrivere il tag RFID.';
								|pl = 'Naeży zapisać znacznik RFID';
								|tr = 'RFID etiketinin kaydedilmesi gerekmektedir.'");
			CommonClientServer.MessageToUser(MessageText);
		EndIf;
		
	EndIf;
	
	For Each LongDesc In SeriesUseSettings.DescriptionsOfUseOfSeriesProps Do
		If LongDesc.Use
			And LongDesc.CheckFilling
			And LongDesc.SettingName <> "UseRFIDTags"
			And Not ValueIsFilled(ThisObject[LongDesc.AttributeName]) Then
			
			MessageText = NStr("vi = 'Trường ""%AttributeRepresentation%"" trống';
								|ru = 'Поле ""%AttributeRepresentation%"" не заполнено';
								|en = '""%AttributeRepresentation%"" is required.'; fa = '""%AttributeRepresentation%"" is required.';
								|it = 'Il campo""%AttributeRepresentation%"" non è compilato';
								|pl = 'Pole ""%AttributeRepresentation%"" nie zostało wypełnione';
								|tr = '""%AttributeRepresentation%"" alanı doldurulmadı'");
			MessageText = StrReplace(MessageText, "%AttributeRepresentation%", LongDesc.AttributeRepresentation);
			If OutputMessages Then
				CommonClientServer.MessageToUser(MessageText,,LongDesc.AttributeName,,Cancel);
			Else
				Cancel = True;
			EndIf;
			
		EndIf;
	EndDo;
	
	Return Not Cancel;
	
EndFunction

&AtServer
Function FindCreateSeries()
	
	FillInFlagsForWorkingWithPlacemark();
	
	If Not CheckFilling() Then
		Return False;
	EndIf;
	
	If Not ValueIsFilled(Series) Then
		
		SelectASeriesServer("");
		
	EndIf;
	
	If Not ValueIsFilled(Series) Then
		
		CreateSeries();
		
	ElsIf SeriesAddingRight Then
	
		ObjectSeries = Series.GetObject();
		
		// Let's write down the additional details of the series
		PropertyManager.BeforeWriteAtServer(ThisForm, ObjectSeries);
		
		FillPropertyValues(ObjectSeries, ThisObject, SerialEntryDetails(SeriesUseSettings, True));
		
		ObjectSeries.Write();
		
		Series = ObjectSeries.Ref;
		
	EndIf;
	
	Return ValueIsFilled(Series);
	
EndFunction

&AtServer
Function CreateSeries()
		
	If Not SeriesAddingRight Then
		
		MessageText = NStr("vi = 'Trong chương trình, còn chưa ghi nhận sê-ri %BatchPresentation%. Không đủ quyền để ghi nhận sê-ri mới.';
							|ru = 'В программе еще не зарегистрирована серия %BatchPresentation%. Недостаточно прав для регистрации новой серии.';
							|en = 'Batch %BatchPresentation% is not registered in the application. Insufficient rights to register new batch.'; fa = 'Batch %BatchPresentation% is not registered in the application. Insufficient rights to register new batch.';
							|it = 'Il programma non ha ancora registrato una serie %BatchPresentation%. Non ci sono abbastanza diritti per registrare una nuova serie..';
							|pl = 'W programie nie została jeszcze zarejestrowana seria %BatchPresentation%. Nie masz wystarczających uprawnień dla rejestracji nowej serii.';
							|tr = '%BatchPresentation% partisi henüz programa kaydedilmedi. Yeni bir parti kaydetmek için yeterli erişim yetkisi yok.'");
		
		BatchPresentation = ProductsClientServer.PresentationOfSeriesWithoutCalculationByNameTemplate(SeriesUseSettings, ThisForm);
		
		MessageText = StrReplace(MessageText, "%BatchPresentation%", BatchPresentation);
		
		CommonClientServer.MessageToUser(MessageText);
		
		Return False;
		
	Else
	
		ObjectSeries = Catalogs.ItemsBatches.CreateItem();
			
		// Let's write down the additional details of the series
		PropertyManager.BeforeWriteAtServer(ThisForm, ObjectSeries);
		FillPropertyValues(ObjectSeries, ThisObject, SerialEntryDetails(SeriesUseSettings,True));
		
		ObjectSeries.Write();
		
		Series = ObjectSeries.Ref;
		
		Return True;
		
	EndIf;
	
EndFunction

&AtServer
Procedure ExecuteRequestToFillInBalanceTable()
	
	QueryText = DataProcessors.SelectBatchToDocuments.TextOfRequestToGenerateTableRegisterData(OptionOfDataReceivingFromRegisters, Warehouse);
	
	QueryText = QueryText + "
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
	QueryText = QueryText + 
	"SELECT
	|	DataOfRegister.Series AS Series,
	|	DataOfRegister.AvailableStock AS AvailableStock,
	|	&RequestTextDetailsOfSeries
	|FROM
	|	DataOfRegister AS DataOfRegister
	|WHERE
	|	DataOfRegister.AvailableStock > 0
	|	OR &AllSeries
	|
	|ORDER BY
	|	ValidUntil_,
	|	Number";
	
	QueryText = StrReplace(QueryText, "&RequestTextDetailsOfSeries",
		DataProcessors.SelectBatchToDocuments.RequestTextDetailsOfSeries("DataOfRegister", SeriesUseSettings));
	
	Query = New Query;
	Query.Text = QueryText;
	For Each Parameter In QueryOptions Do
		Query.SetParameter(Parameter.Key, Parameter.Value);
	EndDo;
	
	If OptionOfDataReceivingFromRegisters <> "AllSeriesProducts" Then
		Query.SetParameter("AllSeries", SeriesDisplayMode = "AllSeries");
	Else
		Query.SetParameter("AllSeries", True);
	EndIf;
	
	RemainingSeries.Load(Query.Execute().Unload());
	
	SeriesCount = RemainingSeries.Count();
	
	// Additional banking details
	TMPropertyManagement.AddColumnsOfAdditionalDetails(
		SeriesUseSettings,
		ThisForm,
		"RemainingSeries",
		"RemainingSeries",
		"RemainingSeriesAvailableStock",
		True);
	TMPropertyManagement.FillInColumnsOfAdditionalDetails(
		ThisForm,
		"RemainingSeries",
		"Series");
	
EndProcedure

&AtClientAtServerNoContext
Function SerialEntryDetails(SeriesUseSettings, ToFillInItem = False)
	
	SerialEntryDetails_ = New Array;
	
	For Each LongDesc In SeriesUseSettings.DescriptionsOfUseOfSeriesProps Do
		If LongDesc.Use Then
			SerialEntryDetails_.Add(LongDesc.AttributeName);
		EndIf;
	EndDo;
	SerialEntryDetails_.Add("ProductKind");
	SerialEntryDetails_.Add("Description");
	
	If Not ToFillInItem
		And SeriesUseSettings.UseRFIDTags Then
			SerialEntryDetails_.Add("Series");
			SerialEntryDetails_.Add("YouNeedToSaveMark");
			SerialEntryDetails_.Add("RFIDTIDFilledIn");
			SerialEntryDetails_.Add("RFIDOperationStatus");
	EndIf;	
	
	Return StrConcat(SerialEntryDetails_, ",");
EndFunction

&AtServer
Procedure GoToNextStep()
	
	If Items.SeriesPages.CurrentPage = Items.PageSeriesInput Then
		If Not FindCreateSeries() Then
			Return;
		EndIf;
		WrittenOffBatch = Series;
	Else
		CurrentData    = RemainingSeries.FindByID(Items.RemainingSeries.CurrentRow);
		WrittenOffBatch = CurrentData.Series;
	EndIf;
	
	ASeriesOfWriteCacheEntry = New FixedStructure(SeriesData(SeriesUseSettings, ThisForm));
	
	CustomizeFormStepByStep("Step2");
	
EndProcedure

&AtServer
Procedure GoBackToPreviousStep()
	
	If Items.SeriesPages.CurrentPage = Items.PageSeriesInput Then
		NewSeries = Series;
	Else
		CurrentData =RemainingSeries.FindByID(Items.RemainingSeries.CurrentRow);
		NewSeries = CurrentData.Series;
	EndIf;
	
	NewSeriesInputCache = New FixedStructure(SeriesData(SeriesUseSettings, ThisForm));
	
	CustomizeFormStepByStep("Step1");
	
EndProcedure

&AtServer
Procedure CustomizeFormStepByStep(Step)
	
	If Step = "Step1" Then
		
		FillPropertyValues(ThisForm, ASeriesOfWriteCacheEntry);
		
		Items.NavigationPanel.CurrentPage = Items.NavigationStartPage;
		Items.Next.DefaultButton = True;
		
		Items.ValidUntil_.ReadOnly = True;
		Items.ValidUntil_.AutoMarkIncomplete = False;
		
		ThisForm.Title = NStr("vi = 'Hãy chỉ ra sê-ri ghi giảm';
								|ru = 'Укажите списываемую серию';
								|en = 'Specify written-off batch'; fa = 'Specify written-off batch';
								|it = 'Specifica la serie cancellata';
								|pl = 'Wprowadź wycofywaną serię';
								|tr = 'Kayıttan düşülen partiyi belirt'");
		Items.SeriesPages.CurrentPage = Items.PageSeriesBalance;
		SearchSeries = WrittenOffBatch;
		Items.RFIDTagIsCorruptedAndCannotBeRead.Visible = True;
		
		Items.WriteToRFID.Enabled = False;
	Else
		
		FillPropertyValues(ThisForm, NewSeriesInputCache);
		
		Items.NavigationPanel.CurrentPage = Items.NavigationEndPage;
		Items.OK.DefaultButton = True;
		
		Items.ValidUntil_.ReadOnly = False;
		Items.ValidUntil_.AutoMarkIncomplete = True;
		
		ThisForm.Title = NStr("vi = 'Hãy chỉ ra phiên bản mới';
								|ru = 'Укажите новую серию';
								|en = 'Specify new batch'; fa = 'Specify new batch';
								|it = 'Specifica una nuova serie';
								|pl = 'Wprowadź nową serię';
								|tr = 'Yeni partiyi belirt'");
		Items.SeriesPages.CurrentPage = Items.PageSeriesInput;
		SearchSeries = NewSeries;
		Items.RFIDTagIsCorruptedAndCannotBeRead.Visible = False;
		Items.WriteToRFID.Enabled = True;
		
	EndIf;
	
	FillInFlagsForWorkingWithPlacemark();
	
	FoundRows = RemainingSeries.FindRows(New Structure("Series",SearchSeries));
	If FoundRows.Count() > 0 Then
		Items.RemainingSeries.CurrentRow = FoundRows[0].GetID();
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure FillInDetailsOfSeries(Receiver, Val SeriesToFillIn, SeriesUseSettings)
	
	If ValueIsFilled(SeriesToFillIn) Then
		If TypeOf(SeriesToFillIn) = Type("CatalogRef.ItemsBatches") Then
			Receiver.Series = SeriesToFillIn;
			SeriesReference = SeriesToFillIn;
		Else
			FillPropertyValues(Receiver, SeriesToFillIn);
			SeriesReference = SeriesToFillIn.Series;
		EndIf;
		If ValueIsFilled(SeriesReference) Then
			SeriesAttributes = Common.ObjectAttributesValues(SeriesReference, SerialEntryDetails(SeriesUseSettings, True));
			FillPropertyValues(Receiver, SeriesAttributes);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetTitleScenerySeries()
	
	Items.ScenerySeries.Title = ?(ValueIsFilled(Series), NStr("vi = 'Đăng ký sê-ri';
																|ru = 'Зарегистрированная серия';
																|en = 'Registered batch'; fa = 'Registered batch';
																|it = 'Serie registrata';
																|pl = 'Zarejestrowana seria';
																|tr = 'Kayıtlı parti'"),
		NStr("vi = 'Sê-ri mới';
			|ru = 'Новая серия';
			|en = 'New batch'; fa = 'بچ جدید';
			|it = 'Nuova serie';
			|pl = 'Nowa seria';
			|tr = 'Yeni parti'"));
	
EndProcedure

&AtServer
Procedure ProductIsValidUntilDateOfProduction()
	
	If SeriesUseSettings.UseShelfLifeOnBatchRegistration Then
		
		NewYearSEve = ProductsClientServer.ValidUntilDateOfProduction(ProductionDate, ExpirationDate_, ShelfLifeUnitOfMeasure);
		
		If ValueIsFilled(NewYearSEve)
			And (Not ValueIsFilled(ValidUntil_)
				Or ValidUntil_ = ProductsClientServer.ValidUntilDateOfProduction(CurrentProductionDate, ExpirationDate_, ShelfLifeUnitOfMeasure)) Then
			
			ValidUntil_ = NewYearSEve;
			
		EndIf;
		
	EndIf;
		
	CurrentProductionDate = ProductionDate;
	
EndProcedure


#EndRegion

#EndRegion

#Region Localization

&AtServer
Procedure ProcessBarcodesServerLocalization(BarcodesByType)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure NumberOfSPMSControlIdentificationMarkOnChange(Item)

	
EndProcedure


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
	If Item.Name = "sh_ShamsiInput_F_ProductionDate" Then
		SelectASeries(Items.ProductionDate);
	ElsIf Item.Name = "sh_ShamsiInput_F_ValidUntil_" Then
		SelectASeries(Items.ValidUntil_);
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
