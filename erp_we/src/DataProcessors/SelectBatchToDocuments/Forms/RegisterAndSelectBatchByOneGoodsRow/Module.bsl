#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

&AtClient
Var CurrentCount; //cache of the quantity in the current row to calculate the number of series

&AtClient
Var CurrentProductionDate;

&AtClient
Var NeedToAskQuestionBeforeClosing;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Not IsTempStorageURL(Parameters.AddressInTempStorage) Then
		MessageText = NStr("vi = 'Chỉ có thể mở bộ xử lý từ chứng từ.';
							|ru = 'Предусмотрено открытие обработки только из документов.';
							|en = 'Data processor can be opened only from documents.'; fa = 'Data processor can be opened only from documents.';
							|it = 'Viene fornita l''apertura dell''elaborazione solo dalle forme dei documenti';
							|pl = 'Przewidziano otwarcie przetwarzania tylko z dokumentów.';
							|tr = 'Yalnızca belgelerden işlem açmak için provizyon sağlanmıştır.'");
		
		Raise MessageText;
	EndIf;
	
	SeriesSpecificationParameters    = Parameters.SeriesSpecificationParameters;
	
	LinkFieldValuesStructure = New Structure(StrConcat(SeriesSpecificationParameters.LinkFields,","));
	LinkFieldValuesStructure.Insert("Products");
	LinkFieldValuesStructure.Insert("Characteristic");
	LinkFieldValuesStructure.Insert("Warehouse");
	FillPropertyValues(LinkFieldValuesStructure, Parameters);
	ConnectionFieldValues = New FixedStructure(LinkFieldValuesStructure);
	
	ProductAttributes = New Structure;
	ProductAttributes.Insert("ProductKind", "ProductKind");
	ProductAttributes.Insert("UnitOfMeasurePresentation", "UnitOfMeasure.Description");
	ProductAttributes.Insert("ExpirationDate_", "ExpirationDate_");
	ProductAttributes.Insert("ShelfLifeUnitOfMeasure", "ShelfLifeUnitOfMeasure");
	ProductAttributes.Insert("TypeOfMeasuredValueOfProductRange", "UnitOfMeasure.MeasuredValueType");
	
	ProductAttributes = New FixedStructure(
		Common.ObjectAttributesValues(ConnectionFieldValues.Products, ProductAttributes));
	
	SeriesUseSettings = New FixedStructure(
		Catalogs.ItemKinds.SeriesUseSettings(
			ProductAttributes.ProductKind, SeriesSpecificationParameters, ConnectionFieldValues));
	
	ProductsServer.CheckWhetherSeriesIndicationFormCanBeOpened(
		SeriesUseSettings, SeriesSpecificationParameters, ConnectionFieldValues);
	
	SetConditionalAppearance();
	
	ReadOnly = Parameters.ReadOnly;
	OnlyQuantityEditing = Parameters.OnlyQuantityEditing;
	
	AnExternalUserIsAuthorized = TMCommonUseClientServer.AnExternalUserIsAuthorized();
	
	TMCommonUse.CustomizePeripherals(ThisForm, "SetOfSeries");
	
	
	AddressInTempStorage = Parameters.AddressInTempStorage;
	QuantityOfGoodsInDocument      = Parameters.Count;
	LineNumbersPresentation  = Parameters.DocumentRowsNumbers;
	Warehouse					  = Parameters.Warehouse;
	Premise 				  = Parameters.Premise;
	ControlledLotReference	  = Parameters.ControlledLotReference;
	Recorder				  = Parameters.Recorder;
	ThereArePackages = SeriesSpecificationParameters.LinkFields.Find("Package") <> Undefined;
	
	Package                  = Parameters.Package;
	If Not ValueIsFilled(Package) Then
		If ValueIsFilled(Parameters.PackagingForSubstitution) Then 
			
			If ProductAttributes.TypeOfMeasuredValueOfProductRange <> Enums.TypesOfMeasuredValues.NumberOfPieces 
				Or ProductAttributes.TypeOfMeasuredValueOfProductRange = Enums.TypesOfMeasuredValues.NumberOfPieces
				And Common.ObjectAttributeValue(Parameters.PackagingForSubstitution, "MeasuredValueType") = Enums.TypesOfMeasuredValues.Package Then
				Package = Parameters.PackagingForSubstitution;
			EndIf;
			
		EndIf;
	EndIf;
	OriginalPackaging = Package;
	
	Title = NStr("vi = 'Ghi nhận sê-ri hàng hóa';
				|ru = 'Регистрация серий товаров';
				|en = 'Goods batch registration'; fa = 'Goods batch registration';
				|it = 'Registrazione delle serie di merci';
				|pl = 'Rejestracja serii towarów';
				|tr = 'Ürün partisi kaydı'");
	
	OwnGoodsPresentation = ProductsServer.PresentationOfGoodsInFormOfIndicationOfSeries(ConnectionFieldValues);
	
	Parameters.Property("ColumnHeadingQuantity", ParameterColumnTitleQuantity);
	
	Items.Package.Enabled = Not ThereArePackages;
	
	Items.SetOfSeries.ChangeRowSet              = Not ReadOnly;
	Items.SetOfSeriesNumberOfPackages.ReadOnly = ReadOnly;
	Items.GroupCommandBarOfATable.Visible = Not ReadOnly;
	
	Items.Count.Visible              = Not ReadOnly;
	
	Items.RemainingSeriesNumberOfPackages.ReadOnly = ReadOnly;

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
				Items.SetOfSeriesRFIDOperationStatus.Visible = LongDesc.Use;
				
				Items.ReadRFID.Visible = LongDesc.Use
												 And ConnectRFIDReader
												 And Not AnExternalUserIsAuthorized;
				
			ElsIf (LongDesc.AttributeName = "RFIDEPC"
				Or LongDesc.AttributeName = "RFIDUser")
				And LongDesc.Use Then	
				
				RecordPlacemarkFields[LongDesc.AttributeName] = LongDesc.CanBeEdited;
				
			EndIf;
			
		Else
			
			NamesOfSeriesElements = DataProcessors.SelectBatchToDocuments.NamesOfSeriesElements(LongDesc.AttributeName);
			
			SeriesFormField        = Items[NamesOfSeriesElements.SetOfSeries]; // FormField
			FormFieldRemnantsOfSeries = Items[NamesOfSeriesElements.RemainingSeries]; // FormField
			
			SeriesFormField.ReadOnly            = Not LongDesc.CanBeEdited;
			SeriesFormField.AutoMarkIncomplete = LongDesc.CheckFilling;
			
			SeriesFormField.Visible        = LongDesc.Use;
			FormFieldRemnantsOfSeries.Visible = LongDesc.Use;
			
			If Not IsBlankString(LongDesc.Format) Then
				SeriesFormField.Format               = LongDesc.Format;
				SeriesFormField.EditFormat = LongDesc.Format;
				FormFieldRemnantsOfSeries.Format        = LongDesc.Format;
			EndIf;
	
			If LongDesc.AttributeName = "Number" Then
				
				Items.SetOfSeriesImportDataFromPDT.Visible = Items.SetOfSeriesNumber.Visible;
				Items.GenerateNumber.Visible        = Items.SetOfSeriesNumber.Visible;
				Items.FillInNumbers.Visible           = Items.SetOfSeriesNumber.Visible;
				
				If Not Items.SetOfSeriesNumber.ReadOnly
					And Items.SetOfSeriesNumber.Visible Then
					Items.SeriesAdd.Title = NStr("vi = 'Nhập số thứ tự';
												|ru = 'Ввести номер';
												|en = 'Enter number'; fa = 'Enter number';
												|it = 'Inserire numero';
												|pl = 'Wprowadź numer';
												|tr = 'Numarayı gir'");
				Else
					Items.SeriesAdd.Title = NStr("vi = 'Nhập';
												|ru = 'Ввести';
												|en = 'Enter'; fa = 'ورود';
												|it = 'Inserire';
												|pl = 'Enter';
												|tr = 'Gir'");
				EndIf;
				
				Items.GenerateNumber.Enabled  = Not Items.SetOfSeriesNumber.ReadOnly;
				Items.FillInNumbers.Enabled     = Not Items.SetOfSeriesNumber.ReadOnly;
		
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
				
				SeriesFormField.Title        = ColumnHeaderPresentation; 
				FormFieldRemnantsOfSeries.Title = ColumnHeaderPresentation;
				
			EndIf;

		EndIf;
	EndDo;
	
	Items.WriteToRFID.Visible = (RecordPlacemarkFields.RFIDEPC
										Or RecordPlacemarkFields.RFIDUser)
										And ConnectRFIDReader
										And Not AnExternalUserIsAuthorized;
	
	Items.FillInByFEFO.Visible  = SeriesUseSettings.BatchesAccountingByFEFO 
										And Enums.WarehouseTransactions.ThereIsShipment(SeriesSpecificationParameters.WarehouseTransactions)
										And Not ThereArePackages
										And Not OnlyQuantityEditing;
	
	Items.PrintGroup.Visible = Not AnExternalUserIsAuthorized;
	Items.FormSetUpSeriesScanningProcedure.Visible = Not AnExternalUserIsAuthorized;
	If AnExternalUserIsAuthorized Then
		Items.SetOfSeriesImportDataFromPDT.Visible = False;
	EndIf;
	
	SeriesDisplayMode = "SeriesInDocument";
	
	ReferenceOrder = DataProcessors.SelectBatchToDocuments.OrderOnFormParameters(Parameters);
	
	OptionOfDataReceivingFromRegisters = DataProcessors.SelectBatchToDocuments.OptionGettingDataFromRegistersByFormParameters(SeriesSpecificationParameters,
				ReferenceOrder,
				Parameters.Warehouse,
				SeriesUseSettings.BatchOwner);
	Headers = DataProcessors.SelectBatchToDocuments.HeadersForOptionGettingDataFromRegisters(OptionOfDataReceivingFromRegisters);
	DefaultAvailableInventoryTitle = Headers.FreeBalanceHeader;
	
	If OptionOfDataReceivingFromRegisters <> "AllSeriesProducts" Then
		Items.SeriesDisplayMode.ChoiceList[1].Presentation = Headers.ButtonTitle;
	Else	
		Items.RemainingSeriesAvailableStock.Visible = False;
		Items.SeriesDisplayMode.ChoiceList.Delete(Items.SeriesDisplayMode.ChoiceList[1]);
	EndIf;
	
	// Entering series
	TableOfSeries = GetFromTempStorage(AddressInTempStorage);
	
	Query = New Query;
	QueryText =
	"SELECT
	|	TableOfSeries.Series,
	|	TableOfSeries.Count,
	|	TableOfSeries.NumberOfPackages
	|INTO TableOfSeries
	|FROM
	|	&TableOfSeries AS TableOfSeries
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfSeries.Series,
	|	SUM(TableOfSeries.Count) AS Count,
	|	SUM(TableOfSeries.NumberOfPackages) AS NumberOfPackages,
	|	&RequestTextDetailsOfSeries
	|FROM
	|	TableOfSeries AS TableOfSeries
	|WHERE
	|	(&SpecifyQuantityWhenRegisteringBatch
	|			OR TableOfSeries.Series <> VALUE(Catalog.ItemsBatches.EmptyRef))
	|
	|GROUP BY
	|	TableOfSeries.Series
	|
	|ORDER BY
	|	ValidUntil_,
	|	Number";
	QueryText = StrReplace(QueryText, "&RequestTextDetailsOfSeries",
		DataProcessors.SelectBatchToDocuments.RequestTextDetailsOfSeries("TableOfSeries", SeriesUseSettings));
	
	Query.Text = QueryText;
	Query.SetParameter("TableOfSeries", TableOfSeries);
	Query.SetParameter("SpecifyQuantityWhenRegisteringBatch", SeriesUseSettings.SpecifyQuantityWhenRegisteringBatch);
	
	Object.SetOfSeries.Load(Query.Execute().Unload());
	
	PackagingFactor = Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(Package, ConnectionFieldValues.Products);
	
	If Not SeriesUseSettings.SpecifyQuantityWhenRegisteringBatch Then
		
		If OnlyQuantityEditing Then
			Items.SetOfSeriesNumberOfPackages.Type = FormFieldType.CheckBoxField;
		Else
			Items.SetOfSeriesNumberOfPackages.Visible = False;
		EndIf;
		Items.RemainingSeriesNumberOfPackages.Type = FormFieldType.CheckBoxField;
		Items.Package.Visible = False;
		
		If PackagingFactor <> 1 Then
			Package = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
		EndIf;
		
	EndIf;
	
	If Not DataProcessors.SelectBatchToDocuments.ThereAreRightsToReadRegisterData(OptionOfDataReceivingFromRegisters, Warehouse) Then
		Items.SeriesPages.PagesRepresentation = FormPagesRepresentation.None;
	EndIf;
	
	UpdatePrintPicture();
	
	SeriesAddingRight = AccessRight("Insert", Metadata.Catalogs.ItemsBatches);
	
	If Not SeriesAddingRight
		Or Parameters.SeriesSpecificationParameters.WarehouseTransactions.Find(Enums.WarehouseTransactions.ConsumptionDuringProduction) <> Undefined
			Then
		Items.SeriesPages.CurrentPage = Items.PageSeriesBalance;
		Items.PageSeriesInput.Visible = False;
		Items.SeriesPages.PagesRepresentation = FormPagesRepresentation.None;
		If Object.SetOfSeries.Total("NumberOfPackages") = 0 Then
			If Items.SeriesDisplayMode.ChoiceList.FindByValue("OnlyBalance") <> Undefined Then
				SeriesDisplayMode = "OnlyBalance";
			Else
				SeriesDisplayMode = "AllSeries";
			EndIf;
		EndIf; 
		If TypeOf(Warehouse) = Type("CatalogRef.BusinessStructure") Then
			Title = NStr("vi = 'Chọn sê-ri theo số dư trong sản xuất';
						|ru = 'Подбор серий по остаткам в производстве';
						|en = 'Select batch by remaining quantity in production'; fa = 'Select batch by remaining quantity in production';
						|it = 'Selezione serie per saldi nella produzione';
						|pl = 'Dobór serii według pozostałości w produkcji';
						|tr = 'Üretim bakiyelerine göre parti seçimi'");
		Else
			Title = NStr("vi = 'Chọn sê-ri theo số dư trong kho';
						|ru = 'Подбор серий по остаткам на складе';
						|en = 'Select batch by warehouse stock'; fa = 'انتخاب بچ بر اساس موجودی انبار';
						|it = 'Selezione serie per saldi di magazzino';
						|pl = 'Wybór serii wg ostatków w magazynie';
						|tr = 'Ambardaki stoka göre parti seçimi'");
		EndIf;
	EndIf;
	
	PackageOnChangeServer();
		
	// Additional banking details
	TMPropertyManagement.AddColumnsOfAdditionalDetails(
		SeriesUseSettings,
		ThisForm,
		"Object.SetOfSeries",
		"SetOfSeries",
		"SetOfSeriesNumberOfPackages");
	TMPropertyManagement.FillInColumnsOfAdditionalDetails(
		ThisForm,
		"Object.SetOfSeries",
		"Series");
	
	If OnlyQuantityEditing Then
		
		Items.SeriesAdd.Visible = False;
		Items.GenerateNumber.Visible = False;
		Items.FillInNumbers.Visible = False;
		Items.SeriesCopy.Visible = False;
		Items.SeriesChange.Visible = False;
		Items.SeriesToRemove.Visible = False;
		Items.SetOfSeriesImportDataFromPDT.Visible = False;
		
		Items.SetOfSeriesContextMenuAdd.Visible = False;
		Items.SetOfSeriesContextMenuCopy.Visible = False;
		Items.SetOfSeriesContextMenuDelete.Visible = False;
			
		For Each Item In Items.RemainingSeries.ChildItems Do
			If Not Item = Items.RemainingSeriesNumberOfPackages Then
				Item.ReadOnly = True;
			EndIf;
		EndDo;
		For Each Item In Items.SetOfSeries.ChildItems Do
			If Not Item = Items.SetOfSeriesNumberOfPackages Then
				Item.ReadOnly = True;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	UpdatePrintPicture();
	ProductsServer.LoadSeriesScanModeSetting(ThisForm);
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	RFIDRecordingIsUnderway = False;
	
	SupportedTypesOfEquipment = "BarcodeScanner";
	
	If ConnectRFIDReader Then
		SupportedTypesOfEquipment = SupportedTypesOfEquipment + ", RFIDReaders";
	EndIf;
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, SupportedTypesOfEquipment);
	
	NeedToAskQuestionBeforeClosing = True;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Modified
		And NeedToAskQuestionBeforeClosing Then
		
		StandardProcessing = False;
		
		ClosingNotification_ = New CallbackDescription("BeforeCloseCompletion", ThisObject);
		QueryText = NStr("vi = 'Đã thay đổi danh sách sê-ri.
			|Lưu lại thay đổi?';
			|ru = 'Список серий был изменен.
			|Сохранить изменения?';
			|en = 'Batch list was changed.
			|Save changes?'; fa = 'Batch list was changed.
			|Save changes?';
			|it = 'L''elenco delle serie è stato modificato.
			|salvare le modifiche?';
			|pl = 'Lista serii została zmieniona.
			|Zapisać zmiany?';
			|tr = 'Parti listesi değiştirildi. 
			|Değişiklikleri kaydet?'");
		
		CommonClient.ShowFormClosingConfirmation(ClosingNotification_, Cancel, Exit, QueryText,
			WarningText);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	BarcodingOfItemsClient.DisableHardware(Undefined, New Structure("Form",ThisForm));

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	CurrentData = Items.SetOfSeries.CurrentData;
	If CurrentData <> Undefined Then
		CurrentRowID = CurrentData.GetID(); 	
	Else
		CurrentRowID = Undefined;
	EndIf;
		
	// Peripherals
	If Source = "Peripherals"
		And IsInputAvailable()
		And Not ReadOnly Then
		
		ProcessingResult = Undefined;
		
		If EventName = "ScanData" Then
			
			ClearMessages(); 
			ProcessingResult = ProcessBarcodesServer(EquipmentManagerTMClient.ConvertDataFromScannerToArray(Parameter), CachedValues, CurrentRowID);
						
		ElsIf EventName = "RFID" Then
			If Not RFIDRecordingIsUnderway
				And BarcodingOfItemsClient.ServerCallIsNeededToHandleRFID(Parameter, ThisForm) Then
				ClearMessages(); 
				ProcessingResult = ProcessRFIDReading(Parameter, CurrentRowID);
			EndIf;
		EndIf;
		
		If ProcessingResult <> Undefined Then
			If ProcessingResult.CloseForm Then
				ClearMessages(); 
				AttachIdleHandler("CloseFormWhenScanning",0.1, True);
			Else
				If ProcessingResult.CurrentRowID <> Undefined Then
					Items.SetOfSeries.CurrentRow = ProcessingResult.CurrentRowID;
				EndIf;
			EndIf;
		EndIf;
		
	EndIf;
	// End Peripherals
	
	If EventName = "RFID_SeriesRecording" Then
		ClearMessages(); 
		SeriesData = Parameter;
		CurrentData.RFIDEPC = SeriesData.RFIDEPC;
		ProcessRFIDRecording(CurrentRowID);
	EndIf;
	
	If EventName = "Write_ItemsBatches" Then
		FoundRows = Object.SetOfSeries.FindRows(New Structure("Series", Source));
		
		If FoundRows.Count() > 0 Then
			SeriesString = FoundRows[0];
			FillPropertyValues(SeriesString, Parameter);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessRFIDRecording(CurrentRowID)
	
	FillInFlagsForWorkingWithPlacemark(CurrentRowID);
	SaveInputToServer(CurrentRowID);

EndProcedure

#EndRegion

#Region EventHandlers

&AtClient
Procedure SeriesPagesOnCurrentPageChange(Item, CurrentPage)
	If CurrentPage = Items.PageSeriesBalance Then
		ExecuteRequestToFillInBalanceTable();
	EndIf;
EndProcedure

&AtClient
Procedure PackageClearing(Item, StandardProcessing)
	
	PackageOnChange(Item);
	
EndProcedure

&AtClient
Procedure PackageOnChange(Item)
	
	PackageOnChangeServer();
		
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSetOfSeries

&AtClient
Procedure SetOfSeriesOnChange(Item)
	SeriesCount = Object.SetOfSeries.Total("NumberOfPackages");
EndProcedure

&AtClient
Procedure SetOfSeriesValidUntil_StartChoice(Item, ChoiceData, StandardProcessing)
	
	CurrentData = Items.SetOfSeries.CurrentData;
	
	ParameterNames = "ValidUntil_, ProductionDate, ExpirationDate_, ShelfLifeUnitOfMeasure, DateFormat, 
						|UseProductionDate";
	FormParameters = New Structure(ParameterNames);
	
	FillPropertyValues(FormParameters, ProductAttributes);
	FillPropertyValues(FormParameters, CurrentData);
	
	FormParameters.DateFormat                   = Item.EditFormat;
	FormParameters.UseProductionDate = SeriesUseSettings.UseBatchProductionDate;
	
	AdditionalParameters = New Structure("Item", Item);
	CallbackDescription      = New CallbackDescription("SetOfSeriesValidUntil_StartChoiceCompletion", ThisObject,
										AdditionalParameters);
	
	ProductsClient.ExpirationDateStartOfSelection(CurrentData, FormParameters, CallbackDescription,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure SetOfSeriesValidUntil_StartChoiceCompletion(Result, AdditionalParameters) Export
	
	SelectASeries(Items.SetOfSeriesValidUntil_);
	Items.SetOfSeries.EndEditRow(False);
	
EndProcedure

&AtClient
Procedure SetOfSeriesNumberOfPackagesOnChange(Item)
		
	CurrentData = Items.SetOfSeries.CurrentData;
	
	ParametersForRecalculatingQuantity = New Structure("Package, Products", Package, ConnectionFieldValues.Products);
	StructureOfActions = New Structure("RecalculateNumberOfUnits", ParametersForRecalculatingQuantity);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure SetOfSeriesOnStartEdit(Item, NewRow, Copy)
	
	
	CurrentData = Item.CurrentData;
	
	CurrentProductionDate = CurrentData.ProductionDate;
	
	If Copy Then
		CurrentCount = 0;
	Else
		CurrentCount =  CurrentData.NumberOfPackages;
	EndIf;
	
EndProcedure

&AtClient
Procedure SetOfSeriesBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	
	If Not CancelEdit Then
		
		If Not SeriesUseSettings.SpecifyQuantityWhenRegisteringBatch Then
			
			CurrentData = Item.CurrentData;
			
			If ThereIsFilledFieldInSeriesRow(CurrentData, SeriesUseSettings) Then
				
				If CurrentData.NumberOfPackages = 0
					And Not OnlyQuantityEditing Then
					CurrentData.NumberOfPackages = 1;
					
					ParametersForRecalculatingQuantity = New Structure("Package, Products", Package, ConnectionFieldValues.Products);
					StructureOfActions = New Structure("RecalculateNumberOfUnits", ParametersForRecalculatingQuantity);
					
					CurrentData = Items.SetOfSeries.CurrentData;
					
					BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
				EndIf;

			Else
				CurrentData.NumberOfPackages = 0;
				CurrentData.Count         = 0;
			EndIf;
		EndIf;
		
		MergeRows(Items.SetOfSeries.CurrentData.GetID());
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SetOfSeriesBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
	SelectedRows = New Array;
	
	For Each LineID In Items.SetOfSeries.SelectedRows Do
		
		SelectedRows.Add(Object.SetOfSeries.FindByID(LineID));
		
	EndDo;	

	For Each CurrentData In SelectedRows Do 
		CurrentCount =  CurrentData.NumberOfPackages;
		
		If OnlyQuantityEditing Then
			If CurrentData.NumberOfPackages > 0 Then
				CurrentData.NumberOfPackages = 0;
				ParametersForRecalculatingQuantity = New Structure("Package, Products", Package, ConnectionFieldValues.Products);
				StructureOfActions = New Structure("RecalculateNumberOfUnits", ParametersForRecalculatingQuantity);
				BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
			EndIf;
		Else
			 Object.SetOfSeries.Delete(CurrentData);	
		EndIf;
		
	EndDo;
	
	SeriesCount = Object.SetOfSeries.Total("NumberOfPackages");

	
EndProcedure

&AtClient
Procedure SetOfSeriesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	If OnlyQuantityEditing Then
		Cancel = True;
	EndIf;
EndProcedure

&AtClient
Procedure SetOfSeriesProductionDateStartChoice(Item, ChoiceData, StandardProcessing)
	
	CurrentData = Items.SetOfSeries.CurrentData;
	
	AdditionalParameters = New Structure("Item", Item);
	CallbackDescription      = New CallbackDescription("SetOfSeriesProductionDateStartChoiceCompletion", ThisObject,
										AdditionalParameters);
	
	ProductsClient.ProductionDateStartChoice(CurrentData, CallbackDescription, StandardProcessing);
	
EndProcedure

&AtClient
Procedure SetOfSeriesProductionDateStartChoiceCompletion(Result, AdditionalParameters) Export
	
	SelectASeries(Items.SetOfSeriesProductionDate);
	Items.SetOfSeries.EndEditRow(False);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersRemainingSeries

&AtClient
Procedure RemainingSeriesNumberOfPackagesOnChange(Item)
	Modified = True;
	
	CurrentRowID = Items.RemainingSeries.CurrentData.GetID();
	
 	RemainingSeriesNumberOfPackagesOnChangeServer(CurrentRowID, CachedValues);	
	
	SeriesCount = Object.SetOfSeries.Total("NumberOfPackages");
	
EndProcedure

&AtClient
Procedure SeriesDisplayModeOnChange(Item)
	ExecuteRequestToFillInBalanceTable();
EndProcedure

&AtClient
Procedure RemainingSeriesOnStartEdit(Item, NewRow, Copy)
	CurrentData = Item.CurrentData;
	CurrentCount =  CurrentData.NumberOfPackages;
EndProcedure

&AtClient
Procedure RemainingSeriesBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	CurrentData = Item.CurrentData;
	
	CurrentData.AvailableStock = CurrentData.AvailableStock + CurrentCount;
	CurrentData.AvailableStock = CurrentData.AvailableStock - CurrentData.NumberOfPackages;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Cancel(Command)
	Modified = False;
	Close();
EndProcedure

&AtClient
Procedure FinishSeriesInput(Command)
	ClearMessages();
	If Not SaveInputToServer() Then
		Return;
	EndIf;
	If Not Modified Then
		Close(AddressInTempStorage);
	EndIf;
EndProcedure

&AtClient
Procedure ImportDataFromPDT(Command)
	
	ClearMessages();
	
	EquipmentManagerClient.StartDownloadingDataFromTSD(
		New CallbackDescription("DownloadFromTSDCompletion", ThisObject),
		UUID);
	
EndProcedure

&AtClient
Procedure DownloadFromTSDCompletion(Result, Var_Parameters) Export
	
	If Result.Result Then
		
		CloseForm = ProcessBarcodesServer(Result, CachedValues, Undefined);
		
		If CloseForm Then
			Close(AddressInTempStorage);
		EndIf;
		
	Else
		EquipmentManagerTMClient.ReportError(Result);
	EndIf;
	
EndProcedure

&AtClient
Procedure SetUpSeriesScanningProcedure(Command)
	Notification = New CallbackDescription("SetUpSeriesScanningProcedureCompletion",ThisForm);
	
	OpenForm("DataProcessor.SelectBatchToDocuments.Form.SettingsOfScanningAndLabelPrinting",
		New Structure("PrintToPrinter",PrintToPrinter),
		ThisForm,
		,
		,
		,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
		
EndProcedure

&AtClient
Procedure SearchByBarcode(Command)
	
	ClearMessages();
	Notification = New CallbackDescription("SearchByBarcodeCompletion", ThisObject);
	TitleOfSeriesEntryForm = NStr("vi = 'Hãy nhập mã vạch, sê-ri';
									|ru = 'Введите штрихкод серии';
									|en = 'Enter barcode batch'; fa = 'Enter barcode batch';
									|it = 'Inserire il codice a barre della serie';
									|pl = 'Wprowadź kod kreskowy serii';
									|tr = 'Barkod partisini gir'");
	BarcodingOfItemsClient.ShowBarcodeInput(Notification,,TitleOfSeriesEntryForm);
	
EndProcedure

&AtClient
Procedure SearchByBarcodeCompletion(BarcodeData_2, AdditionalParameters) Export
		
	CurrentData = Items.SetOfSeries.CurrentData;
	If CurrentData <> Undefined Then
		CurrentRowID = CurrentData.GetID(); 	
	Else
		CurrentRowID = Undefined;
	EndIf;
	
	CloseForm = ProcessBarcodesServer(BarcodeData_2,CachedValues, CurrentRowID);
	If CloseForm Then
		Close(AddressInTempStorage);
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeSeries(Command)
	ChangeSeriesClient();
EndProcedure

&AtClient
Procedure GenerateNumber(Command)
	
	Result = CalculateMaximumNumberAndQuantity(1);
	CurrentRow = Result.CurrentRow;
	Number = Result.Number;
	
	Number = Number+1;
	If Object.SetOfSeries.Count() > 0
		And Not ValueIsFilled(Object.SetOfSeries[0].Number) Then
		CurrentData = Object.SetOfSeries[0];
		If CurrentData.NumberOfPackages = 0 Then
			
			CurrentData.NumberOfPackages = 1; 
			
			ParametersForRecalculatingQuantity = New Structure("Package, Products", Package, ConnectionFieldValues.Products);
			StructureOfActions = New Structure("RecalculateNumberOfUnits", ParametersForRecalculatingQuantity);
			BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
			
		EndIf;
	Else
		Items.SetOfSeries.AddRow();
		CurrentData = Items.SetOfSeries.CurrentData;
		FillPropertyValues(CurrentData,CurrentRow);
	EndIf;
	
	CurrentData.Number =  Format(Number, "ND=8; NLZ=; NG=");
	
	Items.SetOfSeries.EndEditRow(False);
	
	If SeriesUseSettings.UseShelfLifeOnBatchRegistration Then
		Items.SetOfSeries.CurrentItem = Items.SetOfSeriesValidUntil_;
	ElsIf SeriesUseSettings.SpecifyQuantityWhenRegisteringBatch Then
		Items.SetOfSeries.CurrentItem = Items.SetOfSeriesNumberOfPackages;
	EndIf;
	
	SetOfSeriesOnChange(Undefined);
	
EndProcedure

&AtClient
Procedure FillInNumbers(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("SeriesCount",Max(Count - Object.SetOfSeries.Total("NumberOfPackages"),0)); 
	FormParameters.Insert("UseQuantity",SeriesUseSettings.SpecifyQuantityWhenRegisteringBatch); 
	FormParameters.Insert("InEachSeries",InEachSeries); 
	FormParameters.Insert("UnitOfMeasurePage",UnitOfMeasurePage); 
	FormParameters.Insert("ProductKind",SeriesUseSettings.BatchOwner); 
	
	OpenForm(
		"DataProcessor.SelectBatchToDocuments.Form.NumberFillingSettings",
		FormParameters,
		ThisForm,
		,
		,
		,
		New CallbackDescription("FillInNumbersCompletion", ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure FillInNumbersCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
    ActiveString = AddRowsOnServer(Result);
    
    Items.SetOfSeries.EndEditRow(False);
    
    If SeriesUseSettings.UseShelfLifeOnBatchRegistration Then
        Items.SetOfSeries.CurrentRow = ActiveString;
        Items.SetOfSeries.CurrentItem = Items.SetOfSeriesValidUntil_;	
    ElsIf SeriesUseSettings.SpecifyQuantityWhenRegisteringBatch Then
        Items.SetOfSeries.CurrentRow = ActiveString;
        Items.SetOfSeries.CurrentItem = Items.SetOfSeriesNumberOfPackages;
    EndIf;
	
	SeriesCount = Object.SetOfSeries.Total("NumberOfPackages");
	
EndProcedure

&AtClient
Procedure PrintEachPiece(Command)
	Print(True);
EndProcedure

&AtClient
Procedure PrintEachSeries(Command)
	Print(False);
EndProcedure

&AtClient
Procedure FillInByFEFO(Command)
	If Count = 0 Then
		ShowMessageBox(,NStr("vi = 'Trong chứng từ, chưa chỉ ra số lượng hàng hóa. Không thể điền theo FEFO.';
							|ru = 'В документе не указано количество товара. Заполнение по FEFO не возможно.';
							|en = 'Quantity of goods is not specified in the document. Cannot populate by FEFO.'; fa = 'Quantity of goods is not specified in the document. Cannot populate by FEFO.';
							|it = 'Il documento non indica la quantità di merci. Non è possibile eseguire la compilazione con FEFO';
							|pl = 'W dokumencie nie określono ilości towaru. Wypełnienie według FEFO jest niemożliwe.';
							|tr = 'Belge ürün miktarını içermemektedir. FEFO tarafından doldurulması mümkün değildir.'"));
		Return;
	EndIf;	
	
	FillInFEFOOnServer();
	
	SeriesCount = Object.SetOfSeries.Total("NumberOfPackages");
	
EndProcedure

&AtClient
Procedure ReadTheLabel(Command)
	ClearMessages();
	BarcodingOfItemsClient.OpenRFIDReaderSession(ThisForm);
	AttachIdleHandler("WorkOutTimeoutWaitingForRFIDReading", 5, True);
EndProcedure

&AtClient
Procedure WriteToRFID(Command)
	ClearMessages(); 
	RFIDRecordingIsUnderway = True;
	WriteParameters = New Structure;
	WriteParameters.Insert("SeriesData",Items.SetOfSeries.CurrentData);
	WriteParameters.Insert("Form", ThisForm);
	BarcodingOfItemsClient.WriteDataToTFID(Undefined, WriteParameters);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SeriesCount.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SeriesCount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = New DataCompositionField("Count");

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ColorOfDifferentRowOfDocument);

	

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SeriesCount.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SeriesCount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("Count");

	Item.Appearance.SetParameterValue("TextColor", WebColors.Seagreen);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SetOfSeriesSeries.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SetOfSeries.Series");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Font", New Font(WindowsFonts.DefaultGUIFont, , , True, False, False, False, ));
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Mới';
													|ru = 'Новая';
													|en = 'New'; fa = 'جدید';
													|it = 'Nuovo';
													|pl = 'New';
													|tr = 'Yeni'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SetOfSeriesSeries.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SetOfSeries.Series");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Đã ghi nhận';
													|ru = 'Зарегистрированная';
													|en = 'Registered'; fa = 'ثبت‌شده';
													|it = 'Registrato';
													|pl = 'Registered';
													|tr = 'Kaydedildi'"));
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SetOfSeriesNumberOfPackages.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OnlyQuantityEditing");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SetOfSeries.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SetOfSeries.NumberOfPackages");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OnlyQuantityEditing");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	
	//
	
	For Each LongDesc In SeriesUseSettings.DescriptionsOfUseOfSeriesProps Do
		
		If LongDesc.Use 
			And Not IsBlankString(LongDesc.ConditionalAppearanceText) Then
			
			Item = ConditionalAppearance.Items.Add();
			
			NamesOfSeriesElements = DataProcessors.SelectBatchToDocuments.NamesOfSeriesElements(LongDesc.AttributeName);
			
			ItemField = Item.Fields.Items.Add();
			SeriesFormField = Items[NamesOfSeriesElements.SetOfSeries]; // FormField
			ItemField.Field = New DataCompositionField(SeriesFormField.Name);
			
			Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
			Item.Appearance.SetParameterValue("Text", LongDesc.ConditionalAppearanceText);
		EndIf;
		
	EndDo;
	
EndProcedure

#Region BarcodesAndTradeEquipment

&AtClient
Procedure WorkOutTimeoutWaitingForRFIDReading()
	
	If RFIDReaderSessionHasBeenOpened Then
		BarcodingOfItemsClient.WorkOutTimeoutWaitingForRFIDReading(ThisForm);
	EndIf;
	
EndProcedure

&AtServer
Function ProcessBarcodesServer(BarcodeData_5,CachedValues, CurrentRowID)
	
	BarcodesByType = BarcodingOfItemsServer.StructureByBarcodeType(BarcodeData_5);
		
	HasErrors = False;
	ProcessedString = Undefined;
	
	If BarcodesByType.WithoutType.Count() > 0 Then
		BarcodeTable = New ValueTable;
		BarcodeTable.Columns.Add("Number",Metadata.Catalogs.ItemsBatches.Attributes.Number.Type);
		BarcodeTable.Columns.Add("ValidUntil_",New TypeDescription("Date"));
		BarcodeTable.Columns.Add("Count",TMCommonUse.DescriptionOfQuantitativeFieldType(AllowedSign.Nonnegative));
		For Each ArrRow In BarcodesByType.WithoutType Do
			NewRow            = BarcodeTable.Add();
			NewRow.Count = ArrRow.Count;
			
			FieldsFromBarcode = BarcodingOfItemsServer.SeriesInformationFromBarcode(ArrRow.Barcode, 
			SeriesUseSettings.SpecifyNumberWhenRegisteringBatch,
			SeriesUseSettings.UseShelfLifeOnBatchRegistration);
			
			NewRow.Number   = FieldsFromBarcode.Number;
			NewRow.ValidUntil_ = FieldsFromBarcode.ValidUntil_;
			
			If FieldsFromBarcode.HasError Then
				HasErrors = True;
			EndIf;
			
		EndDo;
		
		If Not HasErrors Then
			
			QueryTexts = New Array;
			
			QueryText = 
			"SELECT
			|	Barcodes.Number AS Number,
			|	Barcodes.ValidUntil_ AS ValidUntil_,
			|	Barcodes.Count AS Count
			|INTO Barcodes
			|FROM
			|	&Barcodes AS Barcodes";
			
			QueryTexts.Add(QueryText);
			
			AddQueryTextForFoundSerialNumbers(QueryTexts);
			
			QueryText = 
			"SELECT
			|	SUM(1) AS NumberOfSeriesFound,
			|	FoundNumbersForRequest.Number
			|INTO NumberOfSeriesByNumber
			|FROM
			|	FoundNumbersForRequest AS FoundNumbersForRequest
			|
			|GROUP BY
			|	FoundNumbersForRequest.Number";
			
			QueryTexts.Add(QueryText);
			
			AddQueryTextForNumberOfSerialNumbersFound(QueryTexts);
			
			QueryText = 
			"DROP Barcodes
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|DROP FoundNumbersForRequest
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|DROP NumberOfSeriesByNumber";
			
			QueryTexts.Add(QueryText);
			
			Query = New Query;
			Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
			
			Query.SetParameter("ProductKind",SeriesUseSettings.BatchOwner);
			Query.SetParameter("Barcodes",BarcodeTable);
			
			Selection = Query.Execute().Select();
			
			ExpirationDateFilled = True;
			RowsToProcess = New Array;
			While Selection.Next() Do
				
				PropertiesToExclude	= "";
				TheStructureOfTheSearch		= New Structure("Series, Number, ValidUntil_");
				
				AddSearchParametersForScannedSeries(TheStructureOfTheSearch, Selection, PropertiesToExclude);
				
				FillPropertyValues(TheStructureOfTheSearch, Selection, , PropertiesToExclude);
				
				FoundRows = Object.SetOfSeries.FindRows(TheStructureOfTheSearch);
				
				If FoundRows.Count() = 0 Then
					ProcessedString = Object.SetOfSeries.Add();
					FillPropertyValues(ProcessedString, Selection);
					
					If ValueIsFilled(Selection.Series) Then
						FillPropertyValues(ProcessedString, ReadAdditionalSeriesDetails(Selection.Series));
					EndIf;
					If SeriesUseSettings.SpecifyQuantityWhenRegisteringBatch Then
						ProcessedString.NumberOfPackages = Selection.Count;
					Else
						ProcessedString.NumberOfPackages = 1;
					EndIf;
					
					RowsToProcess.Add(ProcessedString);
					Modified   = True;
					
					If Not ValueIsFilled(ProcessedString.ValidUntil_) Then
						ExpirationDateFilled = False;
					EndIf;
				Else
					ProcessedString = FoundRows[0];
					If SeriesUseSettings.SpecifyQuantityWhenRegisteringBatch Then
						
						CurrentCount = ProcessedString.NumberOfPackages;
						
						ProcessedString.NumberOfPackages = ProcessedString.NumberOfPackages + Selection.Count;
						
						RowsToProcess.Add(ProcessedString);
						Modified = True;
						
					Else
						MessageText = NStr("vi = 'Sê-ri với số %BatchNumber% đã có trong danh sách sê-ri';
											|ru = 'Серия с номером %BatchNumber% уже присутствует в списке серий';
											|en = 'Batch with the %BatchNumber% number is already in the batch list'; fa = 'Batch with the %BatchNumber% number is already in the batch list';
											|it = 'Serie con numero %BatchNumber% già esiste nell''elenco delle serie';
											|pl = 'Seria o numerze %BatchNumber% już jest na liście serii';
											|tr = '%BatchNumber% numarasına sahip parti, parti listesinde zaten mevcut'");
						MessageText = StrReplace(MessageText,"%BatchNumber%",Selection.Number);
						Field = CommonClientServer.PathToTabularSection("SetOfSeries",FoundRows[0].LineNumber,"Number");
						CommonClientServer.MessageToUser(MessageText,,Field,"Object",HasErrors);
					EndIf;
					
					If Not ValueIsFilled(ProcessedString.ValidUntil_) Then
						ExpirationDateFilled = False;
					EndIf;
				EndIf;
				
			EndDo;

			ParametersForRecalculatingQuantity = New Structure("Package, Products", Package, ConnectionFieldValues.Products);
			StructureOfActions = New Structure("RecalculateNumberOfUnits", ParametersForRecalculatingQuantity);
			BatchProcessingOfTablePartServer.ProcessTSStrings(
				RowsToProcess,
				StructureOfActions,
				Object.SetOfSeries,
				CachedValues);

		EndIf;
	EndIf;
	
	ProcessBarcodesServerLocalization(CurrentRowID, CachedValues, BarcodesByType, HasErrors);
	
	CloseForm = False;
	
	If Not HasErrors
		And SeriesScanMode = "ProductSeriesProduct"
		And (ExpirationDateFilled
		Or Not SeriesUseSettings.UseShelfLifeOnBatchRegistration) Then
		SaveInputToServer();
		If Not Modified Then
			CloseForm = True;
		EndIf;
	EndIf;
	
	Result = New Structure;
	Result.Insert("CloseForm", CloseForm);
	Result.Insert("CurrentRowID", ?(ProcessedString <> Undefined,
														ProcessedString.GetID(),
														Undefined));
														
	SeriesCount = Object.SetOfSeries.Total("NumberOfPackages");
	
	Return Result;
	
EndFunction

&AtServer
Function ProcessRFIDReading(LBLData, CurrentRowID)
	
	ProcessingParameters = BarcodingOfItemsServer.ReadRFIDProcessingParameters();
	FillPropertyValues(ProcessingParameters, ThisObject);
	ProcessingResult = BarcodingOfItemsServer.ProcessRFIDReading(LBLData, ProcessingParameters, Object.SetOfSeries, CurrentRowID);
	
	If ProcessingResult.CurrentRowID <> Undefined Then
		Modified = True;
	EndIf;
	
	If ProcessingResult.SeriesData <> Undefined
		And ValueIsFilled(ProcessingResult.SeriesData.Series) Then
		FillPropertyValues(ProcessingResult.SeriesData, ReadAdditionalSeriesDetails(ProcessingResult.SeriesData.Series));
	EndIf;
	
	ProcessingResult.SeriesData = Undefined;
	
	SeriesCount = Object.SetOfSeries.Total("NumberOfPackages");
	
	Return ProcessingResult;
	
EndFunction

&AtServer
Procedure FillInFlagsForWorkingWithPlacemark(CurrentRowID)
	
	If Not SeriesUseSettings.UseRFIDTags Then
		Return;
	EndIf;
	
	CurrentData = Object.SetOfSeries.FindByID(CurrentRowID);
	
	ParametersForFillingInFlagsForWorkingWithPlacemark = BarcodingOfItemsServer.ParametersForFillingInFlagsForWorkingWithPlacemark();
	ParametersForFillingInFlagsForWorkingWithPlacemark.ConnectionFieldValues = ConnectionFieldValues;
	ParametersForFillingInFlagsForWorkingWithPlacemark.CurLabel_ = Undefined;
	ParametersForFillingInFlagsForWorkingWithPlacemark.SeriesUseSettings = SeriesUseSettings;
	
	BarcodingOfItemsServer.FillInFlagsForWorkingWithPlacemark(CurrentData, ParametersForFillingInFlagsForWorkingWithPlacemark);
	
EndProcedure

#EndRegion

#Region Print

&AtClient
Procedure Print(PrintEachPiece)
	
	If Not ValueIsFilled(SeriesUseSettings.LabelTemplateBatches) Then
		
		FormParameters = New Structure();
		Filter = New Structure;
		Filter.Insert("Purpose",PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.ItemsBatchLabel"));
		FormParameters.Insert("Filter",Filter);
		
		OpenForm(
			"Catalog.LabelAndPriceTagTemplates.ChoiceForm",
			FormParameters,ThisForm,,,,
			New CallbackDescription("PrintCompletion", 
				ThisObject,
				New Structure("PrintEachPiece", PrintEachPiece)),
			FormWindowOpeningMode.LockOwnerWindow);
		
		Return;
		
	EndIf;
	
	PrintFragment(PrintEachPiece);
	
EndProcedure

&AtClient
Procedure PrintCompletion(Result, AdditionalParameters) Export
    
    PrintEachPiece = AdditionalParameters.PrintEachPiece;
    
    If Not ValueIsFilled(Result) Then
        Return;
    EndIf;
	
	SeriesUsageSettingsStructure                     = New Structure(SeriesUseSettings);
	SeriesUsageSettingsStructure.LabelTemplateBatches = Result;
	SeriesUseSettings                              = New FixedStructure(SeriesUsageSettingsStructure);
	
    PrintFragment(PrintEachPiece);

EndProcedure

&AtClient
Procedure PrintFragment(Val PrintEachPiece)
    
    Var CommandParameter, ParametersStructure;
    
    ParametersStructure = New Structure();
    
    If Modified Then
        
        If SaveInputToServer() Then
            ParametersStructure.Insert("AddressInStorage",PrepareDataForPrinting(PrintEachPiece,Items.SetOfSeries.SelectedRows));	
        Else
            Return;
        EndIf;
        
    ElsIf Items.SetOfSeries.CurrentData <> Undefined Then
        ParametersStructure.Insert("AddressInStorage",PrepareDataForPrinting(PrintEachPiece,Items.SetOfSeries.SelectedRows));	
    Else
        Return;		
    EndIf;
    
    ParametersStructure.Insert("LabelsTemplate",SeriesUseSettings.LabelTemplateBatches); 
    ParametersStructure.Insert("TemplateAssignment",PredefinedValue("Enum.AssignmentsOfTemplatesOfPriceTagsAndLabels.ItemsBatchLabel"));
    ParametersStructure.Insert("Copies",1);
    
    CommandParameter = New Array;
    CommandParameter.Add(PredefinedValue("Catalog.ItemsBatches.EmptyRef"));
    
    If PrintToPrinter Then
        PrintManagementClient.ExecutePrintToPrinterCommand(
        "DataProcessor.PrintPriceTagsAndLabels", // To call the "Print" processing manager method.
        "ItemsBatchLabel",
        CommandParameter,
        ParametersStructure);
        
    Else
        PrintManagementClient.ExecutePrintCommand(
        "DataProcessor.PrintPriceTagsAndLabels", // To call the "Print" processing manager method.
        "ItemsBatchLabel",
        CommandParameter,
        ThisForm,
        ParametersStructure); // Owner form
        
    EndIf;

EndProcedure

&AtServer
Function PrepareDataForPrinting(PrintEachPiece,Val SelectedRows)
			
	ItemsBatches = New ValueTable;
	ItemsBatches.Columns.Add("Series",		New TypeDescription("CatalogRef.ItemsBatches"));
	ItemsBatches.Columns.Add("Barcode",	New TypeDescription("String"));
	
	For Each Id In SelectedRows Do
		String = Object.SetOfSeries.FindByID(Id);
		
		If PrintEachPiece Then
			NumberOfCopies = String.NumberOfPackages;
		Else
			NumberOfCopies = 1;
		EndIf;
		
		While NumberOfCopies > 0 Do
			NumberOfCopies = NumberOfCopies - 1;
			NewRow = ItemsBatches.Add();
			NewRow.Series    = String.Series;
			
			DateFormatTemplate = NStr("vi = 'DF=""%1""';
										|ru = 'ДФ=""%1""';
										|en = 'DF=""%1""'; fa = 'DF=""%1""';
										|it = 'ДФ=""%1""';
										|pl = 'DF=""%1""';
										|tr = 'DF=""%1""'");
			DateFormatTemplate = StrTemplate(DateFormatTemplate, "DdMMggHH");
			
			If SeriesUseSettings.UseShelfLifeOnBatchRegistration 
				And SeriesUseSettings.SpecifyNumberWhenRegisteringBatch Then
				NewRow.Barcode = TrimAll(String.Number) + Format(String.ValidUntil_, DateFormatTemplate);
			ElsIf SeriesUseSettings.SpecifyNumberWhenRegisteringBatch Then
				NewRow.Barcode = TrimAll(String.Number);
			Else
				NewRow.Barcode = Format(String.ValidUntil_,DateFormatTemplate);
			EndIf;
		EndDo;
		
	EndDo;
	
	Return PutToTempStorage(ItemsBatches);	
EndFunction

#EndRegion

#Region SeriesGeneration

&AtServer
Function CalculateMaximumNumberAndQuantity(Count)
	
	MaximumNumberInDocument = 0;
	
	For Each RowOfTables In Object.SetOfSeries Do
		
		If StrLen(RowOfTables.Number) > 8 Then
			Continue;
		EndIf;
		
		If Not StringFunctionsClientServer.OnlyNumbersInString(RowOfTables.Number) Then
			Continue;
		EndIf;
		
		PhoneNumber_ = StringFunctionsClientServer.StringToNumber(RowOfTables.Number);
		
		If PhoneNumber_ > MaximumNumberInDocument Then
			MaximumNumberInDocument = PhoneNumber_;
		EndIf;
		
	EndDo;
	
	MaximumNumberFromCatalog = Catalogs.ItemsBatches.CalculateMaximumSeriesNumber(SeriesUseSettings.BatchOwner);
	
	Number = Max(MaximumNumberInDocument, MaximumNumberFromCatalog);
	
	CurrentRow = New Structure;
	CurrentRow.Insert("Products", ConnectionFieldValues.Products);
	CurrentRow.Insert("Package", Package);
	CurrentRow.Insert("Count", Count);
	CurrentRow.Insert("NumberOfPackages", Count);
	
	ParametersForRecalculatingQuantity = New Structure("Package,Products", Package, ConnectionFieldValues.Products);
	StructureOfActions = New Structure("RecalculateNumberOfUnits", ParametersForRecalculatingQuantity);
	
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentRow, StructureOfActions, Undefined);

	Result = New Structure("Number, CurrentRow", Number, CurrentRow);
	
	Return Result;
	
EndFunction

#EndRegion

#Region Other

&AtClient
Procedure SetUpSeriesScanningProcedureCompletion(Result, AdditionalParameters) Export
	If Result <> Undefined Then
		SeriesScanMode = Result.SeriesScanMode;
		If Result.PrintToPrinter <> PrintToPrinter Then
			PrintToPrinter = Result.PrintToPrinter;
			UpdatePrintPicture();
		EndIf;	
	EndIf;
EndProcedure

&AtServer
Procedure ExecuteRequestToFillInBalanceTable()
	
	If Items.SeriesPages.PagesRepresentation = FormPagesRepresentation.None
		And Items.SeriesPages.CurrentPage = Items.PageSeriesInput Then
		Return;
	EndIf;
	
	CoefficientOfPacking = Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(Package, ConnectionFieldValues.Products);
	
	QueryOptions = New Structure;
	QueryOptions.Insert("Products", ConnectionFieldValues.Products);
	QueryOptions.Insert("Characteristic", ConnectionFieldValues.Characteristic);
	QueryOptions.Insert("Purpose", AssignmentByLinkFieldValues());
	QueryOptions.Insert("Warehouse", Warehouse);
	QueryOptions.Insert("ControlledLotReference", ControlledLotReference);
	QueryOptions.Insert("Premise", Premise);
	QueryOptions.Insert("Recorder", Recorder);
	QueryOptions.Insert("ReferenceOrder", ReferenceOrder);
	QueryOptions.Insert("CoefficientOfPacking", CoefficientOfPacking);
	
	For Each AdditionalParameter In SeriesSpecificationParameters.ParametersForGettingDataFromRegisters Do
		QueryOptions.Insert(AdditionalParameter.Key, AdditionalParameter.Value);
	EndDo;
	
	QueryText = DataProcessors.SelectBatchToDocuments.TextOfRequestToGenerateTableRegisterData(OptionOfDataReceivingFromRegisters, Warehouse);
	
	QueryText = QueryText + "
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
	QueryText = QueryText + 
	"SELECT
	|	SeriesInDocument.Series,
	|	SeriesInDocument.Count,
	|	SeriesInDocument.NumberOfPackages
	|INTO SeriesInDocument
	|FROM
	|	&SeriesInDocument AS SeriesInDocument
	|WHERE
	|	SeriesInDocument.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
	If SeriesDisplayMode = "SeriesInDocument" Then
		QueryText = QueryText + 
		"SELECT
		|	SeriesInDocument.Series AS Series,
		|	ISNULL(DataOfRegister.AvailableStock, 0) / &CoefficientOfPacking * &RemainderSign - SeriesInDocument.NumberOfPackages AS AvailableStock,
		|	SeriesInDocument.Count AS Count,
		|	SeriesInDocument.NumberOfPackages AS NumberOfPackages,
		|	&RequestTextDetailsOfSeries
		|FROM
		|	SeriesInDocument AS SeriesInDocument
		|		LEFT JOIN DataOfRegister AS DataOfRegister
		|		ON (DataOfRegister.Series = SeriesInDocument.Series)
		|
		|ORDER BY
		|	ValidUntil_,
		|	Number";
		
		QueryText = StrReplace(QueryText, "&RequestTextDetailsOfSeries", 
			DataProcessors.SelectBatchToDocuments.RequestTextDetailsOfSeries("SeriesInDocument", SeriesUseSettings));
	ElsIf SeriesDisplayMode = "OnlyBalance" Then
		QueryText = QueryText + 
		"SELECT
		|	NestedQuery.Series AS Series,
		|	SUM(NestedQuery.AvailableStock) AS AvailableStock,
		|	SUM(NestedQuery.Count) AS Count,
		|	SUM(NestedQuery.NumberOfPackages) AS NumberOfPackages,
		|	&RequestTextDetailsOfSeries
		|FROM
		|	(SELECT
		|		DataOfRegister.Series AS Series,
		|		DataOfRegister.AvailableStock / &CoefficientOfPacking * &RemainderSign AS AvailableStock,
		|		0 AS Count,
		|		0 AS NumberOfPackages
		|	FROM
		|		DataOfRegister AS DataOfRegister
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		SeriesInDocument.Series,
		|		-SeriesInDocument.NumberOfPackages,
		|		SeriesInDocument.Count,
		|		SeriesInDocument.NumberOfPackages
		|	FROM
		|		SeriesInDocument AS SeriesInDocument) AS NestedQuery
		|WHERE
		|	NestedQuery.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|GROUP BY
		|	NestedQuery.Series,
		|	CAST(NestedQuery.Series AS Catalog.ItemsBatches).Number,
		|	CAST(NestedQuery.Series AS Catalog.ItemsBatches).ValidUntil_
		|
		|HAVING
		|	SUM(NestedQuery.AvailableStock) > 0
		|
		|ORDER BY
		|	ValidUntil_,
		|	Number";
		
		QueryText = StrReplace(QueryText, "&RequestTextDetailsOfSeries",
			DataProcessors.SelectBatchToDocuments.RequestTextDetailsOfSeries("NestedQuery", SeriesUseSettings));
	ElsIf SeriesDisplayMode = "AllSeries" Then
		QueryText = QueryText + 
		"SELECT
		|	NestedQuery.Series AS Series,
		|	SUM(NestedQuery.AvailableStock) AS AvailableStock,
		|	SUM(NestedQuery.Count) AS Count,
		|	SUM(NestedQuery.NumberOfPackages) AS NumberOfPackages,
		|	&RequestTextDetailsOfSeries
		|FROM
		|	(SELECT
		|		DataOfRegister.Series AS Series,
		|		DataOfRegister.AvailableStock / &CoefficientOfPacking * &RemainderSign AS AvailableStock,
		|		0 AS Count,
		|		0 AS NumberOfPackages
		|	FROM
		|		DataOfRegister AS DataOfRegister
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		SeriesInDocument.Series,
		|		-SeriesInDocument.NumberOfPackages,
		|		SeriesInDocument.Count,
		|		SeriesInDocument.NumberOfPackages
		|	FROM
		|		SeriesInDocument AS SeriesInDocument) AS NestedQuery
		|WHERE
		|	NestedQuery.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|GROUP BY
		|	NestedQuery.Series,
		|	CAST(NestedQuery.Series AS Catalog.ItemsBatches).Number,
		|	CAST(NestedQuery.Series AS Catalog.ItemsBatches).ValidUntil_
		|
		|ORDER BY
		|	ValidUntil_,
		|	Number";
		QueryText = StrReplace(QueryText, "&RequestTextDetailsOfSeries", 
			DataProcessors.SelectBatchToDocuments.RequestTextDetailsOfSeries("NestedQuery", SeriesUseSettings));
	EndIf;	
		
	Query = New Query;
	Query.Text = QueryText;
	For Each Parameter In QueryOptions Do
		Query.SetParameter(Parameter.Key, Parameter.Value);
	EndDo;
	Query.SetParameter("AllSeries", SeriesDisplayMode = "AllSeries");
	Query.SetParameter("SeriesInDocument", Object.SetOfSeries.Unload());
	
	If OptionOfDataReceivingFromRegisters = "GoodsReadyForReceipt"
		And SeriesSpecificationParameters.ItSWarrant Then
		Query.SetParameter("RemainderSign", -1);
	Else
		Query.SetParameter("RemainderSign", 1);
	EndIf;	
	
	RemainingSeries.Load(Query.Execute().Unload());
	
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
		
	SeriesCount = Object.SetOfSeries.Total("NumberOfPackages");
	
EndProcedure

&AtServer
Procedure RemainingSeriesNumberOfPackagesOnChangeServer(CurrentRowID, CachedValues)
	
	ParametersForRecalculatingQuantity = New Structure("Package,Products", Package, ConnectionFieldValues.Products);
	StructureOfActions = New Structure("RecalculateNumberOfUnits", ParametersForRecalculatingQuantity);

	CurrentData = RemainingSeries.FindByID(CurrentRowID);
	
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	FoundRows = Object.SetOfSeries.FindRows(New Structure("Series", CurrentData.Series));
	
	If FoundRows.Count() = 0 Then
		FoundRows = Object.SetOfSeries.FindRows(New Structure("Series",Catalogs.ItemsBatches.EmptyRef()));
	EndIf;
	
	If FoundRows.Count() > 0 Then
		SeriesString = FoundRows[0];
		If CurrentData.NumberOfPackages = 0 Then
			Object.SetOfSeries.Delete(SeriesString);
			Return;
		EndIf;
	ElsIf CurrentData.NumberOfPackages = 0 Then
		Return;
	Else
		SeriesString = Object.SetOfSeries.Add();
	EndIf;
		
	FillPropertyValues(SeriesString, CurrentData);
    FillPropertyValues(SeriesString, ReadAdditionalSeriesDetails(SeriesString.Series));
	
EndProcedure

&AtServer
Function SaveInputToServer(LineToWrite = Undefined)
	
	If Object.SetOfSeries.Count() > 0 Then
		LastRow = Object.SetOfSeries[Object.SetOfSeries.Count()-1];
		
		ThereIsFilledField = ValueIsFilled(LastRow.Series)
							Or LastRow.NumberOfPackages > 1;
		
		If Not ThereIsFilledField Then
			ThereIsFilledField = ThereIsFilledFieldInSeriesRow(LastRow, SeriesUseSettings);
		EndIf;
		
		If Not ThereIsFilledField Then
			Object.SetOfSeries.Delete(LastRow);
		EndIf;
		
	EndIf;	
	
	CheckParameters = New Structure();
	CheckParameters.Insert("SeriesUseSettings", SeriesUseSettings);
	CheckParameters.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters);
	CheckParameters.Insert("ConnectionFieldValues", ConnectionFieldValues);
	CheckParameters.Insert("OnlyQuantityEditing", OnlyQuantityEditing);
	CheckParameters.Insert("Package", Package);
	
	Object.CheckParameters = New FixedStructure(CheckParameters);
	
	If Not (CheckFilling()
	 And TMPropertyManagement.CheckFillingInAdditionalDetails(ThisForm, "Object.SetOfSeries")) Then
		Return False;
	EndIf;	
			
	FindRegisteredSeries();
	
	ReturnTable = New ValueTable;
	ReturnTable.Columns.Add("Series",New TypeDescription("CatalogRef.ItemsBatches"));
	ReturnTable.Columns.Add("Count",New TypeDescription("Number",New NumberQualifiers(15,3,AllowedSign.Nonnegative)));
	ReturnTable.Columns.Add("NumberOfPackages",New TypeDescription("Number",New NumberQualifiers(15,3,AllowedSign.Nonnegative)));

	InitialPackingRatio = Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(OriginalPackaging, ConnectionFieldValues.Products);
	
	SeriesAttributes = New Array;
	For Each LongDesc In SeriesUseSettings.DescriptionsOfUseOfSeriesProps Do
		If LongDesc.Use Then
			SeriesAttributes.Add(LongDesc.AttributeName);
		EndIf;
	EndDo;
	AttributesOfSeriesUsed = StrConcat(SeriesAttributes, ",");
	
	For Each RowOfTables In Object.SetOfSeries Do
		
		If RowOfTables.Count > 0
			Or OnlyQuantityEditing Then // In the only editing mode, you also need to return rows with zero quantity
			
			SaveSeriesByLine(RowOfTables, AttributesOfSeriesUsed);
			
			NewRow = ReturnTable.Add();
			FillPropertyValues(NewRow, RowOfTables);
			NewRow.NumberOfPackages = NewRow.Count / InitialPackingRatio;
			
		EndIf;
	EndDo;
	
	If SeriesSpecificationParameters.NameTSGoods = SeriesSpecificationParameters.TSSeriesName
		And ReturnTable.Count() = 0 Then
		
		NewRow = ReturnTable.Add();
		NewRow.NumberOfPackages = Count;
		
		AttributesStructure1 = New Structure("Package,Products", Package, ConnectionFieldValues.Products);
		StructureOfActions = New Structure("RecalculateNumberOfUnits", AttributesStructure1);
		
		BatchProcessingOfTablePartServer.ProcessTSString(NewRow, StructureOfActions, Undefined);
		
	EndIf;
	
	PutToTempStorage(ReturnTable,AddressInTempStorage);
	Modified = False;
	
	Return True;
	
EndFunction

&AtClientAtServerNoContext
Function ThereIsFilledFieldInSeriesRow(ProcessedString, SeriesUseSettings)
	
	ThereIsFilledField = False;
	
	For Each LongDesc In SeriesUseSettings.DescriptionsOfUseOfSeriesProps Do
		
		If LongDesc.SettingName <> "UseRFIDTags"
			And LongDesc.Use
			And ValueIsFilled(ProcessedString[LongDesc.AttributeName]) Then
			
			ThereIsFilledField = True;
			Break;
		EndIf;
	EndDo;
	
	Return ThereIsFilledField;

EndFunction

&AtServer
Procedure SaveSeriesByLine(RowID, AttributesOfSeriesUsed)

	If Not SeriesAddingRight Then
		Return;
	EndIf;

	If TypeOf(RowID) <> Type("FormDataCollectionItem") Then
		TableRow = Object.SetOfSeries.FindByID(RowID);
	Else
		TableRow = RowID; 
	EndIf;

	CatalogObject = Undefined;
	If Not ValueIsFilled(TableRow.Series) Then
		
		CatalogObject = Catalogs.ItemsBatches.CreateItem();
		CatalogObject.ProductKind = SeriesUseSettings.BatchOwner;
		
	EndIf;
	
	If TMPropertyManagement.ThereAreAdditionalDetailsInTable(ThisObject, "Object.SetOfSeries") Then
		If CatalogObject = Undefined Then
			CatalogObject = TableRow.Series.GetObject();
		EndIf;
		TMPropertyManagement.TransferAdditionalDetailsFromFormToObject(CatalogObject, ThisObject, TableRow, "Object.SetOfSeries");
	EndIf;

	If Not IsBlankString(AttributesOfSeriesUsed) Then
		If CatalogObject = Undefined Then
			SeriesAttributes = Common.ObjectAttributesValues(TableRow.Series, AttributesOfSeriesUsed);
			LineDetails = New Structure(AttributesOfSeriesUsed);
			FillPropertyValues(LineDetails, TableRow, AttributesOfSeriesUsed);
			If Not Common.DataMatch(SeriesAttributes, LineDetails) Then
				CatalogObject = TableRow.Series.GetObject();
				FillPropertyValues(CatalogObject, TableRow, AttributesOfSeriesUsed);
			EndIf;
		Else
			FillPropertyValues(CatalogObject, TableRow, AttributesOfSeriesUsed);
		EndIf;
	EndIf;

	If CatalogObject <> Undefined Then
		CatalogObject.Write();
		TableRow.Series = CatalogObject.Ref;
	EndIf;

EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	Response = QuestionResult;
	
	If Response = DialogReturnCode.Yes Then
		
		NeedToAskQuestionBeforeClosing = False;
		FinishSeriesInput(Undefined);// Saving the modification results.
		
	ElsIf Response = DialogReturnCode.No Then
		
		NeedToAskQuestionBeforeClosing = False;
		Close(Undefined);
		
	EndIf;

EndProcedure

&AtServer
Function ReadAdditionalSeriesDetails(Series)
	
	Return TMPropertyManagement.ReadAdditionalSeriesDetails(ThisObject, "Object.SetOfSeries", Series);
	
EndFunction

// Function-constructor of additional parameters 
// Returns:
// 	Structure - advanced setting:
// 		* Item - FormGroup, FormTable, FormField, FormButton - Form element
// 		* ChoiceList - ValueList
// 		* CurrentData - FormDataCollectionItem
&AtClient
Function AdditionalCompletionProcessingParameters()
	
	Result = New Structure;
	Result.Insert("Item");
	Result.Insert("ChoiceList");
	Result.Insert("CurrentData");
	Return Result;
	
EndFunction

&AtClient
Procedure SelectASeries(Item)
	
	CurrentData = Items.SetOfSeries.CurrentData;	
	EnteringDetails = StrReplace(Item.Name, "SetOfSeries", "");	
	
	If Not ValueIsFilled(CurrentData[EnteringDetails]) Then
		CurrentData.Series = Undefined;
		Return;
	EndIf;
	
	If EnteringDetails = "ValidUntil_"
		Or EnteringDetails = "ProductionDate" Then
		ProductsClientServer.RecalculateSeriesDate(CurrentData[EnteringDetails]);
		If EnteringDetails = "ProductionDate" Then
			ProductIsValidUntilDateOfProduction();
		EndIf;
	EndIf;
	
	CheckedAttributes = New Array;
	
	For Each LongDesc In SeriesUseSettings.DescriptionsOfUseOfSeriesProps Do
		If LongDesc.SettingName <> "UseRFIDTags"
			And LongDesc.Use
			And LongDesc.AttributeName <> EnteringDetails Then
			
			CheckedAttributes.Add(LongDesc.AttributeName);
		EndIf;
	EndDo;	
	
	CurrentData = Items.SetOfSeries.CurrentData;
	
	SearchParameters = New Structure(StrConcat(CheckedAttributes,","));
	SearchParameters.Insert(EnteringDetails,CurrentData[EnteringDetails]);
	
	SearchParameters.Insert("ProductKind", SeriesUseSettings.BatchOwner);
	SearchParameters.Insert("SeriesUseSettings",SeriesUseSettings);
	SearchParameters.Insert("Filter", New Structure);
	SearchParameters.Insert("SearchString", Undefined);
	
	ChoiceList = GetChoiceData(Type("CatalogRef.ItemsBatches"),SearchParameters);
	
	SelectedElement = Undefined;
	
	Value = New Structure(StrConcat(CheckedAttributes,","));
	Value.Insert(EnteringDetails);
	FillPropertyValues(Value, CurrentData); 
	Value.Insert("Series", Undefined);
	
	Description = ProductsClientServer.PresentationOfSeriesWithoutCalculationByNameTemplate(SeriesUseSettings, CurrentData, True);
	
	ChoiceList.Insert(0, Value, Description);
	
	If ChoiceList.Count() = 1 Then
		SelectedElement = ChoiceList[0];
	ElsIf ChoiceList.Count() = 2 Then
		
		FirstValueInListIsDifferentFromSecond = ChoiceList[0].Value[EnteringDetails] 
														<> ChoiceList[1].Value[EnteringDetails];
		//
		If Not FirstValueInListIsDifferentFromSecond Then
			For Each AttributeName In CheckedAttributes Do
				If ChoiceList[0].Value[AttributeName] 
					  <> ChoiceList[1].Value[AttributeName] Then
				//
					FirstValueInListIsDifferentFromSecond = True;
					Break;
				EndIf;
			EndDo;
		EndIf;
		
		If FirstValueInListIsDifferentFromSecond Then
			
			AdditionalParameters = AdditionalCompletionProcessingParameters();
			AdditionalParameters.ChoiceList = ChoiceList;
			AdditionalParameters.CurrentData = CurrentData;
			AdditionalParameters.Item = Item;
			
			CallbackDescription = New CallbackDescription("SelectASeriesCompletion", ThisObject, AdditionalParameters);
			
			ShowChooseFromList(CallbackDescription, ChoiceList, Item);
		Else
			SelectedElement = ChoiceList[1];
		EndIf;
	ElsIf ChoiceList.Count() > 0 Then
		
		AdditionalParameters = AdditionalCompletionProcessingParameters();
		AdditionalParameters.ChoiceList = ChoiceList;
		AdditionalParameters.CurrentData = CurrentData;
		AdditionalParameters.Item = Item;
		
		CallbackDescription = New CallbackDescription("SelectASeriesCompletion", ThisObject, AdditionalParameters);
	
		ShowChooseFromList(CallbackDescription, ChoiceList, Item);
	EndIf;
	
	PickUpSeriesFragment(SelectedElement, CurrentData);
	
EndProcedure

// Parameters:
// 	SelectedElement - FormGroup, FormTable, FormField, FormButton - Form element
// 	AdditionalParameters - See AdditionalCompletionProcessingParameters
// 
&AtClient
Procedure SelectASeriesCompletion(SelectedElement, AdditionalParameters) Export
	
	ChoiceList = AdditionalParameters.ChoiceList;
	CurrentData = AdditionalParameters.CurrentData;
	Item = AdditionalParameters.Item;
	
	PickUpSeriesFragment(SelectedElement, CurrentData);

EndProcedure

&AtClient
Procedure PickUpSeriesFragment(Val SelectedElement, Val CurrentData)
	
	If SelectedElement <> Undefined Then
		
		FillPropertyValues(CurrentData, SelectedElement.Value); 
		FillPropertyValues(CurrentData, ReadAdditionalSeriesDetails(CurrentData.Series));
		
	Else 
		CurrentData.Series   = Undefined; 
	EndIf;

EndProcedure

&AtClient
Procedure ChangeSeriesClient()
	
	CurrentData = Items.SetOfSeries.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	SeriesFillValues = New Structure;
	SeriesFillValues.Insert("ProductKind", SeriesUseSettings.BatchOwner);
	SeriesFillValues.Insert("Number", CurrentData.Number);
	SeriesFillValues.Insert("ValidUntil_", CurrentData.ValidUntil_);
	SeriesFillValues.Insert("NumberOfSPMSControlIdentificationMark", CurrentData.NumberOfSPMSControlIdentificationMark);
	SeriesFillValues.Insert("ProductionDate", CurrentData.ProductionDate);
	SeriesFillValues.Insert("ManufacturerUSAIS", CurrentData.ManufacturerUSAIS);
	SeriesFillValues.Insert("Certificate2USAIS", CurrentData.Certificate2USAIS);
	SeriesFillValues.Insert("ManufacturerVetIS", CurrentData.ManufacturerVetIS);
	SeriesFillValues.Insert("WarehouseBookRecordVetIS", CurrentData.WarehouseBookRecordVetIS);
	SeriesFillValues.Insert("LotIDVetIS", CurrentData.LotIDVetIS);
	SeriesFillValues.Insert("MaximumRetailPriceMOTP", CurrentData.MaximumRetailPriceMOTP);
	SeriesFillValues.Insert("RFIDTID", CurrentData.RFIDTID);
	SeriesFillValues.Insert("RFIDUser", CurrentData.RFIDUser);
	SeriesFillValues.Insert("RFIDEPC", CurrentData.RFIDEPC);
	SeriesFillValues.Insert("EPCGTIN", CurrentData.EPCGTIN);
	
	SeriesShapeParameters = New Structure;
	SeriesShapeParameters.Insert("FillingValues",SeriesFillValues);
	SeriesShapeParameters.Insert("Key",CurrentData.Series);
	
	OpenForm("Catalog.ItemsBatches.Form.ItemForm",SeriesShapeParameters, ThisForm, , , , Undefined,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure CloseFormWhenScanning()
	Close(AddressInTempStorage);
EndProcedure

&AtServer
Procedure MergeRows(CurrentRowID)
	
	CurrentRow = Object.SetOfSeries.FindByID(CurrentRowID);
	
	DetailsCheckedTogether        = New Array;
	DetailsCheckedSeparately = New Array;
	ItIsNecessaryToDeleteCurLine          = False;
	
	For Each LongDesc In SeriesUseSettings.DescriptionsOfUseOfSeriesProps Do
		If LongDesc.SettingName = "UseRFIDTags" Then
			Continue;
		EndIf;
	
		If LongDesc.Use Then
			If LongDesc.CheckUniquenessOfValue Then
				DetailsCheckedSeparately.Add(LongDesc.AttributeName);
			Else
				DetailsCheckedTogether.Add(LongDesc.AttributeName);
			EndIf;
		EndIf;
	EndDo;
	
	For Each String In Object.SetOfSeries Do
		If String.GetID() = CurrentRowID Then
		 	Continue;
		EndIf;
		
		StringMatches = False;
		
		For Each AttributeName In DetailsCheckedSeparately Do
			If CurrentRow[AttributeName] = String[AttributeName] Then
				StringMatches = True;
				Break;
			EndIf;
		EndDo;
		
		If Not StringMatches Then
			StringMatches = TMCommonUseClientServer.StructuresAreEqual(CurrentRow, String, DetailsCheckedTogether);
		EndIf;	
		
		If StringMatches Then
			
			If SeriesUseSettings.SpecifyQuantityWhenRegisteringBatch Then
				String.Count = String.Count + CurrentRow.Count;
				String.NumberOfPackages = String.NumberOfPackages + CurrentRow.NumberOfPackages;
			EndIf;
			
			ItIsNecessaryToDeleteCurLine = True;
			Break;
		EndIf;
		
	EndDo;
	
	If ItIsNecessaryToDeleteCurLine Then
		Object.SetOfSeries.Delete(CurrentRow);
	Else
		FillInFlagsForWorkingWithPlacemark(CurrentRowID);
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdatePrintPicture()
	If PrintToPrinter Then
		Items.PrintGroup.Picture = PictureLib.PrintImmediately;
	Else
	    Items.PrintGroup.Picture = PictureLib.Print;
	EndIf;
EndProcedure

&AtServer
Function AddRowsOnServer(Result)
	
	If Object.SetOfSeries.Count() > 0
		And Not ValueIsFilled(Object.SetOfSeries[0].Number) Then
		
		Object.SetOfSeries.Delete(0);
		
	EndIf;

    NumberOfSeries = Result.SeriesCount;
    InEachSeries = Result.InEachSeries;
    InEachSeriesQuantity = Result.InEachSeriesQuantity;
	
	ActiveString = Undefined;
	
	RowParameters = New Structure;
	RowParameters.Insert("Products",       ConnectionFieldValues.Products);
	RowParameters.Insert("Package",           Package);
	RowParameters.Insert("Count",         InEachSeriesQuantity);
	RowParameters.Insert("NumberOfPackages", InEachSeriesQuantity);
	
	ParametersForRecalculatingQuantity = New Structure("Package, Products", Package, ConnectionFieldValues.Products);
	StructureOfActions = New Structure("RecalculateNumberOfUnits", ParametersForRecalculatingQuantity);
	BatchProcessingOfTablePartServer.ProcessTSString(RowParameters, StructureOfActions, Undefined);
	
	StructureOfAdditionalBankingDetails = TMPropertyManagement.ReadAdditionalSeriesDetails(ThisObject, "Object.SetOfSeries", Result);
	
	If Result.SeriesNumberingMethod = 0 And Result.NumberGenerationRestriction = 0 Then
	
	    ReturnStructure = CalculateMaximumNumberAndQuantity(InEachSeriesQuantity);
		
		Number = ReturnStructure.Number;

		While NumberOfSeries > 0 Do
			                             
			NumberOfSeries = NumberOfSeries-1;
			Number = Number+1;
			CurrentRow = Object.SetOfSeries.Add();
			   
			If ActiveString = Undefined Then
				ActiveString = CurrentRow.GetID();
			EndIf;
			
			CurrentRow.Number = Format(Number, "ND=8; NLZ=; NG=");
			
			FillPropertyValues(CurrentRow, RowParameters); 
			FillPropertyValues(CurrentRow, StructureOfAdditionalBankingDetails); 
			

		EndDo;	
		
	Else
		
		If Result.SeriesNumberingMethod = 0 And Result.NumberGenerationRestriction = 1 Then
		
			TableOfNumbers = Catalogs.ItemsBatches.GenerateSeriesNumbersInRange(
				SeriesUseSettings.BatchOwner,
				Result.InitialNumber,
				Result.EndNumber,
				NumberOfSeries);
		
			If TableOfNumbers.Count() < NumberOfSeries Then
				TableOfNumbers.Clear();
				CommonClientServer.MessageToUser(NStr("vi = 'Trong khoảng đã chỉ ra không đủ số tự do.';
														|ru = 'В указанном диапазоне недостаточно свободных номеров.';
														|en = 'Insufficient free numbers in the selected range.'; fa = 'Insufficient free numbers in the selected range.';
														|it = 'Nell''intervallo specificato non ci sono abbastanza numeri liberi.';
														|pl = 'W określonym zakresie jest za mało wolnych numerów.';
														|tr = 'Belirtilen aralıkta yeterli boş numara mevcut değildir.'"));
			EndIf;
			
		Else
			
			TableOfNumbers = Catalogs.ItemsBatches.GetSeriesNumbersInRange(
				SeriesUseSettings.BatchOwner,
				Result.InitialNumber,
				Result.EndNumber);
			
		EndIf;
			
		For Each CurrRow In TableOfNumbers Do
			
			ExistingRows = Object.SetOfSeries.FindRows(New Structure("Number", CurrRow.Number));
			
			If ExistingRows.Count() > 0 Then 
				
				CurrentRow = ExistingRows[0];
				
				CurrentRow.Count = CurrentRow.Count + RowParameters.Count;
				CurrentRow.NumberOfPackages = CurrentRow.NumberOfPackages + RowParameters.NumberOfPackages;
				
			Else
				
				CurrentRow = Object.SetOfSeries.Add();
				
				FillPropertyValues(CurrentRow, CurrRow);
				FillPropertyValues(CurrentRow, RowParameters); 
				
			EndIf;
			
			FillPropertyValues(CurrentRow, StructureOfAdditionalBankingDetails); 
			
			If ActiveString = Undefined Then
				ActiveString = CurrentRow.GetID();
			EndIf;
						
		EndDo;
		
	EndIf;
	
	Return ActiveString;
	
EndFunction

&AtServer
Procedure FindRegisteredSeries()
	
	// If the audit is not used, it must be cleared
	For Each RowOfTables In Object.SetOfSeries Do
		
		If Not ValueIsFilled(RowOfTables.Series) Then
			
			For Each Attribute In SeriesUseSettings.DescriptionsOfUseOfSeriesProps Do
				
				If Not Attribute.Use Then
					RowOfTables[Attribute.AttributeName] = Undefined;
				EndIf;
				
			EndDo;
		EndIf;		
		
	EndDo;
	                                           
	
	QueryText =
	"SELECT
	|	SetOfSeries.Series AS Series,
	|	SetOfSeries.LineNumber AS LineNumber,
	|	&RequestTextForSeriesFields
	|INTO SetOfSeries
	|FROM
	|	&SetOfSeries AS SetOfSeries
	|WHERE
	|	SetOfSeries.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CatalogSetOfSeries.Ref AS Series,
	|	SetOfSeries.LineNumber AS LineNumber
	|FROM
	|	SetOfSeries AS SetOfSeries
	|		LEFT JOIN Catalog.ItemsBatches AS CatalogSetOfSeries
	|		ON &TextOfConditionsForFieldsWithUniqueValues
	|				OR (&TextOfConditionsByFieldsWithUniquenessBySetOfValues)
	|WHERE
	|	CatalogSetOfSeries.ProductKind = &ProductKind";
	
	ArrayOfConditionsForFieldsWithUniqueValues               = New Array;
	ArrayOfConditionsByFieldsWithUniquenessBySetOfValues = New Array;
	
	ConditionTemplate = " SetOfSeries.%AttributeName% = CatalogSetOfSeries.%AttributeName% ";
	
	For Each Attribute In SeriesUseSettings.DescriptionsOfUseOfSeriesProps Do
		
		If Attribute.Use
			And Attribute.SettingName <> "UseRFIDTags" Then
			
			ConditionText = StrReplace(ConditionTemplate, "%AttributeName%", Attribute.AttributeName);
			
			If Attribute.CheckUniquenessOfValue Then
				ArrayOfConditionsForFieldsWithUniqueValues.Add(ConditionText);	
			Else
				ArrayOfConditionsByFieldsWithUniquenessBySetOfValues.Add(ConditionText);	
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If ArrayOfConditionsForFieldsWithUniqueValues.Count() > 0 Then	
		TextOfConditionsForFieldsWithUniqueValues
			= StrConcat(ArrayOfConditionsForFieldsWithUniqueValues, "OR");
	Else
		TextOfConditionsForFieldsWithUniqueValues = "FALSE";
	EndIf;
	
	
	If ArrayOfConditionsByFieldsWithUniquenessBySetOfValues.Count() > 0 Then	
		TextOfConditionsByFieldsWithUniquenessBySetOfValues
			= StrConcat(ArrayOfConditionsByFieldsWithUniquenessBySetOfValues, "And");
	Else
		TextOfConditionsByFieldsWithUniquenessBySetOfValues = "FALSE";
	EndIf;
	
	QueryText = StrReplace(QueryText, "&RequestTextForSeriesFields",
				DataProcessors.SelectBatchToDocuments.RequestTextDetailsOfSeries("SetOfSeries", SeriesUseSettings, False, False));
	
	QueryText = StrReplace(QueryText, "&TextOfConditionsForFieldsWithUniqueValues",
												TextOfConditionsForFieldsWithUniqueValues);
												
	QueryText = StrReplace(QueryText, "&TextOfConditionsByFieldsWithUniquenessBySetOfValues",
												TextOfConditionsByFieldsWithUniquenessBySetOfValues);
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("ProductKind",SeriesUseSettings.BatchOwner);
	Query.SetParameter("SetOfSeries",Object.SetOfSeries.Unload());

	SelectionByRefs = Query.Execute().Select();
	
	While SelectionByRefs.Next() Do
		Object.SetOfSeries[SelectionByRefs.LineNumber-1].Series = SelectionByRefs.Series;
	EndDo;	
	
EndProcedure	

&AtServer
Procedure FillInFEFOOnServer()
	
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	DataOfRegister.Series AS Series,
	|	DataOfRegister.Series.Number AS Number,
	|	DataOfRegister.Series.ValidUntil_ AS ValidUntil_,
	|	SUM(DataOfRegister.AvailableStock) AS Count,
	|	DataOfRegister.Series.NumberOfSPMSControlIdentificationMark AS NumberOfSPMSControlIdentificationMark,
	|	DataOfRegister.Series.RFIDTID AS RFIDTID,
	|	DataOfRegister.Series.RFIDUser AS RFIDUser,
	|	DataOfRegister.Series.RFIDEPC AS RFIDEPC,
	|	DataOfRegister.Series.EPCGTIN AS EPCGTIN,
	|	DataOfRegister.Series.RFIDTagIsCorruptedAndCannotBeRead AS RFIDTagIsCorruptedAndCannotBeRead,
	|	DataOfRegister.Series.ProductionDate AS ProductionDate,
	|	DataOfRegister.Series.ManufacturerUSAIS AS ManufacturerUSAIS,
	|	DataOfRegister.Series.Certificate2USAIS AS Certificate2USAIS,
	|	DataOfRegister.Series.ManufacturerVetIS AS ManufacturerVetIS,
	|	DataOfRegister.Series.WarehouseBookRecordVetIS AS WarehouseBookRecordVetIS,
	|	DataOfRegister.Series.LotIDVetIS AS LotIDVetIS,
	|	DataOfRegister.Series.MaximumRetailPriceMOTP AS MaximumRetailPriceMOTP
	|FROM
	|	(SELECT
	|		ProductStockBalance.Series AS Series,
	|		ProductStockBalance.InStockBalance - ProductStockBalance.ToShipBalance AS AvailableStock
	|	FROM
	|		AccumulationRegister.ProductStock.Balance(
	|				,
	|				Products = &Products
	|					AND Characteristic = &Characteristic
	|					AND Purpose = &Purpose
	|					AND Warehouse = &Warehouse
	|					AND Premise = &Premise
	|					AND ControlledLotReference = &ControlledLotReference) AS ProductStockBalance
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ProductStock.Series,
	|		CASE
	|			WHEN ProductStock.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -ProductStock.InStock + ProductStock.ToShip
	|			ELSE ProductStock.InStock - ProductStock.ToShip
	|		END
	|	FROM
	|		AccumulationRegister.ProductStock AS ProductStock
	|	WHERE
	|		ProductStock.Products = &Products
	|		AND ProductStock.Characteristic = &Characteristic
	|		AND ProductStock.Purpose = &Purpose
	|		AND ProductStock.Warehouse = &Warehouse
	|		AND ProductStock.Premise = &Premise
	|		AND ProductStock.ControlledLotReference = &ControlledLotReference
	|		AND ProductStock.Recorder = &Recorder) AS DataOfRegister
	|
	|GROUP BY
	|	DataOfRegister.Series,
	|	DataOfRegister.Series.Number,
	|	DataOfRegister.Series.ValidUntil_,
	|	DataOfRegister.Series.NumberOfSPMSControlIdentificationMark,
	|	DataOfRegister.Series.RFIDTID,
	|	DataOfRegister.Series.RFIDUser,
	|	DataOfRegister.Series.RFIDEPC,
	|	DataOfRegister.Series.EPCGTIN,
	|	DataOfRegister.Series.RFIDTagIsCorruptedAndCannotBeRead,
	|	DataOfRegister.Series.ProductionDate,
	|	DataOfRegister.Series.ManufacturerUSAIS,
	|	DataOfRegister.Series.Certificate2USAIS,
	|	DataOfRegister.Series.ManufacturerVetIS,
	|	DataOfRegister.Series.WarehouseBookRecordVetIS,
	|	DataOfRegister.Series.LotIDVetIS,
	|	DataOfRegister.Series.MaximumRetailPriceMOTP
	|
	|HAVING
	|	SUM(DataOfRegister.AvailableStock) > 0
	|
	|ORDER BY
	|	ValidUntil_";
	
	Query.SetParameter("Products", ConnectionFieldValues.Products);
	Query.SetParameter("Characteristic", ConnectionFieldValues.Characteristic);
	Query.SetParameter("Purpose", AssignmentByLinkFieldValues());
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("ControlledLotReference", ControlledLotReference);
	Query.SetParameter("Premise", Premise);
	Query.SetParameter("Recorder", Recorder);
	
	Selection = Query.Execute().Select();
	
	QuantityToDistribution = Count*PackagingFactor;
	Object.SetOfSeries.Clear();
	
	If Items.SeriesPages.CurrentPage = Items.PageSeriesInput Then
			
		While Selection.Next() And QuantityToDistribution > 0 Do
				
			QuantityPerRow =  Min(Selection.Count, QuantityToDistribution);
			QuantityToDistribution = QuantityToDistribution - QuantityPerRow;
			
			NewRow = Object.SetOfSeries.Add();
			FillPropertyValues(NewRow, Selection);
			FillPropertyValues(NewRow, ReadAdditionalSeriesDetails(NewRow.Series));

			
			NewRow.Count = QuantityPerRow;
			NewRow.NumberOfPackages = QuantityPerRow/PackagingFactor;
			
		EndDo;
		
	Else
		
		For Each String In RemainingSeries Do
			String.AvailableStock = String.AvailableStock + String.Count/PackagingFactor;
			String.NumberOfPackages = 0;
			String.Count = 0;
		EndDo;
		
		While Selection.Next() And QuantityToDistribution > 0 Do
			
			Filter = New Structure("Series", Selection.Series);			
			RowsArray = RemainingSeries.FindRows(Filter);
			If RowsArray.Count() <> 0 Then
				
				QuantityPerRow =  Min(Selection.Count, QuantityToDistribution);
				QuantityToDistribution = QuantityToDistribution - QuantityPerRow;
				
				SeriesString = RowsArray[0];	
				SeriesString.Count = QuantityPerRow;
				SeriesString.NumberOfPackages = QuantityPerRow/PackagingFactor;
								
				SeriesString.AvailableStock = SeriesString.AvailableStock - QuantityPerRow/PackagingFactor;
				
				NewRow = Object.SetOfSeries.Add();
				FillPropertyValues(NewRow, SeriesString);
				FillPropertyValues(NewRow, ReadAdditionalSeriesDetails(NewRow.Series));
							
			Else		
				
				QuantityPerRow =  Min(Selection.Count, QuantityToDistribution);
				QuantityToDistribution = QuantityToDistribution - QuantityPerRow;
				
				NewRow = RemainingSeries.Add();
				FillPropertyValues(NewRow, Selection);
				FillPropertyValues(NewRow, ReadAdditionalSeriesDetails(NewRow.Series));
				
				NewRow.AvailableStock = Selection.Count/PackagingFactor;
				NewRow.Count = QuantityPerRow;
				NewRow.NumberOfPackages = QuantityPerRow/PackagingFactor;
								
				NewRow.AvailableStock = NewRow.AvailableStock - QuantityPerRow/PackagingFactor;
					
				NewRowSeries = Object.SetOfSeries.Add();
				FillPropertyValues(NewRowSeries, NewRow);
				FillPropertyValues(NewRowSeries, ReadAdditionalSeriesDetails(NewRowSeries.Series));
				
			EndIf;
			
		EndDo;
		
	EndIf;
		
EndProcedure

&AtServer
Procedure SetHeadersByPackage()
	
	TitleQuantityInDocument = NStr("vi = 'Cần ghi nhận, %UnitOfMeasure%';
									|ru = 'Необходимо зарегистрировать, %UnitOfMeasure%';
									|en = 'Register, %UnitOfMeasure%'; fa = 'Register, %UnitOfMeasure%';
									|it = 'Necessario registrare, %UnitOfMeasure%';
									|pl = 'Należy zarejestrować, %UnitOfMeasure%';
									|tr = 'Kaydetmek gerekli, %UnitOfMeasure%'");
	TitleNumberOfSeries      = NStr("vi = 'Đã ghi nhận sê-ri, %UnitOfMeasure%';
									|ru = 'Зарегистрировано серий, %UnitOfMeasure%';
									|en = 'Batch registered, %UnitOfMeasure%'; fa = 'Batch registered, %UnitOfMeasure%';
									|it = 'Serie registrate, %UnitOfMeasure%';
									|pl = 'Zarejestrowano serii, %UnitOfMeasure%';
									|tr = 'Kaydedilen partiler, %UnitOfMeasure%'");
	If ValueIsFilled(ParameterColumnTitleQuantity) Then
		ColumnHeadingQuantity = ParameterColumnTitleQuantity; 
	Else
		ColumnHeadingQuantity = NStr("vi = 'Số lượng';
									|ru = 'Количество';
									|en = 'Quantity'; fa = 'مقدار';
									|it = 'Quantità';
									|pl = 'Ilość';
									|tr = 'Miktar'"); 
	EndIf;
	ColumnHeadingQuantity    = ColumnHeadingQuantity + ", %UnitOfMeasure%"; 
	PrintCommandHeader        = NStr("vi = 'Nhãn tem đối với từng %UnitOfMeasure%';
									|ru = 'Этикетки для каждой(ого) %UnitOfMeasure%';
									|en = 'Labels for each %UnitOfMeasure%'; fa = 'Labels for each %UnitOfMeasure%';
									|it = 'Etichette per %UnitOfMeasure%';
									|pl = 'Etykiety dla każdej(go) %UnitOfMeasure%';
									|tr = 'Her biri için etiket (ler) %UnitOfMeasure%'");
	
	If ValueIsFilled(Package) Then
		
		TitleQuantityInDocument = StrReplace(TitleQuantityInDocument,"%UnitOfMeasure%",Package);
		TitleNumberOfSeries      = StrReplace(TitleNumberOfSeries,"%UnitOfMeasure%",Package);
		ColumnHeadingQuantity    = StrReplace(ColumnHeadingQuantity,"%UnitOfMeasure%",Package);
		PrintCommandHeader        = StrReplace(PrintCommandHeader,"%UnitOfMeasure%",Package);
		FreeBalanceHeader    = StrReplace(DefaultAvailableInventoryTitle,"%UnitOfMeasure%", Package);
		UnitOfMeasurePage           = Package;
	    
	Else
		
		ColumnHeadingQuantity    = StrReplace(ColumnHeadingQuantity,"%UnitOfMeasure%",ProductAttributes.UnitOfMeasurePresentation);
		TitleQuantityInDocument = StrReplace(TitleQuantityInDocument,"%UnitOfMeasure%",ProductAttributes.UnitOfMeasurePresentation);
		TitleNumberOfSeries      = StrReplace(TitleNumberOfSeries,"%UnitOfMeasure%",ProductAttributes.UnitOfMeasurePresentation);
		ColumnHeadingQuantity    = StrReplace(ColumnHeadingQuantity,"%UnitOfMeasure%",ProductAttributes.UnitOfMeasurePresentation);
		PrintCommandHeader        = StrReplace(PrintCommandHeader,"%UnitOfMeasure%",ProductAttributes.UnitOfMeasurePresentation);
		FreeBalanceHeader    = StrReplace(DefaultAvailableInventoryTitle,"%UnitOfMeasure%", ProductAttributes.UnitOfMeasurePresentation);
		UnitOfMeasurePage 		  = ProductAttributes.UnitOfMeasurePresentation;
		
	EndIf;
	
	If Not SeriesUseSettings.SpecifyQuantityWhenRegisteringBatch Then
		ColumnHeadingQuantity = " ";
	EndIf;
	
	Items.SetOfSeriesNumberOfPackages.Title = ColumnHeadingQuantity;
	Items.Count.Title              = TitleQuantityInDocument;
	Items.SeriesCount.Title         = TitleNumberOfSeries;
	Items.PrintEachPiece.Title		     = PrintCommandHeader;

	Items.RemainingSeriesAvailableStock.Title   = FreeBalanceHeader;
	Items.RemainingSeriesNumberOfPackages.Title = ColumnHeadingQuantity;
	
EndProcedure

&AtServer
Procedure PackageOnChangeServer()
	
	PackagingFactor = Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(Package, ConnectionFieldValues.Products);
	
	For Each CurrRow In Object.SetOfSeries Do
		CurrRow.NumberOfPackages = CurrRow.Count / PackagingFactor;
	EndDo;
	
	ExecuteRequestToFillInBalanceTable();
	
	Count = QuantityOfGoodsInDocument / PackagingFactor;
	
	SetHeadersByPackage();
	
EndProcedure

&AtClient
Procedure ProductIsValidUntilDateOfProduction()
	
	CurrentData = Items.SetOfSeries.CurrentData;
	
	If SeriesUseSettings.UseShelfLifeOnBatchRegistration Then
		
		ValidUntil_ = ProductsClientServer.ValidUntilDateOfProduction(CurrentData.ProductionDate,
																		ProductAttributes.ExpirationDate_,
																		ProductAttributes.ShelfLifeUnitOfMeasure);
		
		If ValueIsFilled(ValidUntil_)
			And (Not ValueIsFilled(CurrentData.ValidUntil_)
				Or CurrentData.ValidUntil_ = ProductsClientServer.ValidUntilDateOfProduction(CurrentProductionDate,
																		ProductAttributes.ExpirationDate_,
																		ProductAttributes.ShelfLifeUnitOfMeasure)) Then
			
			CurrentData.ValidUntil_ = ValidUntil_;
			
		EndIf;
		
	EndIf;
	
	CurrentProductionDate = CurrentData.ProductionDate;
	
EndProcedure

&AtServer
Function AssignmentByLinkFieldValues()
	
	If SeriesSpecificationParameters.NameOfSenderWarehouseField <> Undefined
		And SeriesSpecificationParameters.NameOfRecipientWarehouseField <> Undefined Then
		Return ConnectionFieldValues.AssignmentSender;
	ElsIf ConnectionFieldValues.Property("Purpose") Then
		Return ConnectionFieldValues.Purpose;
	Else
		Return Catalogs.Assignments.EmptyRef();
	EndIf;
	
EndFunction

#EndRegion

#EndRegion

#Region Localization

&AtServer
Procedure ProcessBarcodesServerLocalization(CurrentRowID, CachedValues, BarcodesByType, HasErrors)
	
	Return;

EndProcedure

&AtServer
Procedure AddQueryTextForFoundSerialNumbers(QueryTexts)
	
	QueryText =
	"SELECT
	|	ISNULL(ItemsBatches.Ref, VALUE(Catalog.ItemsBatches.EmptyRef)) AS Series,
	|	Barcodes.Number,
	|	ISNULL(ItemsBatches.ValidUntil_, Barcodes.ValidUntil_) AS ValidUntil_,
	|	ISNULL(ItemsBatches.ProductionDate, DATETIME(1, 1, 1, 0, 0, 0)) AS ProductionDate,
	|	Barcodes.Count
	|INTO FoundNumbersForRequest
	|FROM
	|	Barcodes AS Barcodes
	|		LEFT JOIN Catalog.ItemsBatches AS ItemsBatches
	|		ON Barcodes.Number = ItemsBatches.Number
	|			AND (Barcodes.ValidUntil_ = ItemsBatches.ValidUntil_
	|				OR Barcodes.ValidUntil_ = DATETIME(1, 1, 1, 0, 0, 0))
	|			AND (ItemsBatches.ProductKind = &ProductKind)";
	
	
	QueryTexts.Add(QueryText);
	
EndProcedure

&AtServer
Procedure AddQueryTextForNumberOfSerialNumbersFound(QueryTexts)
	
	QueryText =
	"SELECT DISTINCT
	|	CASE
	|		WHEN NumberOfSeriesByNumber.NumberOfSeriesFound > 1
	|			THEN VALUE(Catalog.ItemsBatches.EmptyRef)
	|		ELSE FoundNumbersForRequest.Series
	|	END AS Series,
	|	FoundNumbersForRequest.Number,
	|	CASE
	|		WHEN NumberOfSeriesByNumber.NumberOfSeriesFound > 1
	|			THEN DATETIME(1, 1, 1, 0, 0, 0)
	|		ELSE FoundNumbersForRequest.ValidUntil_
	|	END AS ValidUntil_,
	|	CASE
	|		WHEN NumberOfSeriesByNumber.NumberOfSeriesFound > 1
	|			THEN DATETIME(1, 1, 1, 0, 0, 0)
	|		ELSE FoundNumbersForRequest.ProductionDate
	|	END AS ProductionDate,
	|	FoundNumbersForRequest.Count
	|FROM
	|	FoundNumbersForRequest AS FoundNumbersForRequest
	|		INNER JOIN NumberOfSeriesByNumber AS NumberOfSeriesByNumber
	|		ON FoundNumbersForRequest.Number = NumberOfSeriesByNumber.Number";
	
	
	QueryTexts.Add(QueryText);
	
EndProcedure

&AtServer
Procedure AddSearchParametersForScannedSeries(SearchParameters, SeriesData, PropertiesToExclude)
	
	SearchParameters.Insert("ProductionDate");
	
	
EndProcedure

&AtClient
Procedure SetOfSeriesNumberOfSPMSControlIdentificationMarkOnChange(Item)

	
EndProcedure


#EndRegion
