
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	TMCommonUse.CustomizePeripherals(ThisForm);
	Warehouse     = Parameters.Warehouse;
	Premise = Parameters.Premise;
	
	DataCompositionSchema = Documents.GoodsPickingPlacement.GetTemplate("StorageBinFilterForFilling");
		
	URLSchemes = PutToTempStorage(DataCompositionSchema, New UUID());

	SettingsSource = New DataCompositionAvailableSettingsSource(URLSchemes);

	FilterCells_2.Initialize(SettingsSource);
	FilterCells_2.LoadSettings(DataCompositionSchema.DefaultSettings);
	
	SetValueOfSettingsParameter(FilterCells_2.Settings, "Warehouse" , Warehouse);
	SetValueOfSettingsParameter(FilterCells_2.Settings, "Premise", Premise);

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If Source = "Peripherals" And IsInputAvailable() Then
		If EventName = "ScanData" And EquipmentManagerTMClient.ThereIsRawEvent() Then
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToStructure(Parameter));
		EndIf;
	EndIf;
	// End Peripherals
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	ClearMessages();
	Address = AddressOfCellsInStorage(FormOwner.UUID);
	If ValueIsFilled(Address) Then
		Close(Address);
	EndIf;
EndProcedure

&AtClient
Procedure Cancel(Command)
	Close(Undefined);
EndProcedure

&AtClient
Procedure FillInBinListByPicking(Command)
	If Cells.Count() > 0 Then
		Response = Undefined;

		ShowQueryBox(New CallbackDescription("FillInBinListByPickingCompletion", ThisObject), NStr("vi = 'Trước khi điền, danh sách các ô sẽ bị xóa. Tiếp tục?';
																									|ru = 'Перед заполнением список ячеек будет очищен. Продолжить?';
																									|en = 'Before starting filling in, we need to clear up the storage bin list. Continue?'; fa = 'Before starting filling in, we need to clear up the storage bin list. Continue?';
																									|it = 'Prima della compilazione l''elenco delle celle sarà cancellato. Continuare?';
																									|pl = 'Przed wypełnieniem lista komórek zostanie oczyszczona. Kontynuować?';
																									|tr = 'Hücre listesi doldurulmadan önce temizlenecektir. Devam edilsin mi?'"), QuestionDialogMode.YesNo);
        Return;
	EndIf;
	
	FillInBinListByPickingServer();
EndProcedure

&AtClient
Procedure FillInBinListByPickingCompletion(QuestionResult, AdditionalParameters) Export
    
    Response = QuestionResult;
    If Response <> DialogReturnCode.Yes Then
        Return;
    EndIf;
    
    FillInBinListByPickingServer();

EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region BarcodesAndTradeEquipment

&AtServer
Procedure ProcessBarcodes(Data)
	
	Managers = New Array();
	Managers.Add(Catalogs.StorageBins);
	ReferencesArrray = BarcodingOfPrintForms.GetLinkFromBarcodeOfTabularDocument(Data.Barcode, Managers);
	
	If ReferencesArrray.Count() > 0 Then
    	Cell = ReferencesArrray[0];
	Else
		MessageText = NStr("vi = 'Ô hàng có mã vạch %Barcode% không tìm thấy';
							|ru = 'Складская ячейка со штрихкодом %Barcode% не найдена';
							|en = 'Storage bin with barcode %Barcode% is not found'; fa = 'Storage bin with barcode %Barcode% is not found';
							|it = 'La cella di stoccaggio del codice a barre %Barcode% non è stata trovata';
							|pl = 'Nie znaleziono komórki magazynowej z kodem kreskowym %Barcode%';
							|tr = '%Barcode% barkodlu depo yeri bulunamadı'");
	    MessageText = StrReplace(MessageText,"%Barcode%",Data.Barcode);
		
		CommonClientServer.MessageToUser(MessageText);
		Return;
	EndIf;
	
	NewRow = Cells.Add();
	NewRow.Cell        = Cell;
				
EndProcedure

#EndRegion

#Region Other

&AtServer
Function AddressOfCellsInStorage(FormUniqueID)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Cells.Cell
	|INTO Cells
	|FROM
	|	&Cells AS Cells
	|WHERE
	|	Cells.Cell <> VALUE(Catalog.StorageBins.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Cells.Cell
	|FROM
	|	Cells AS Cells
	|
	|ORDER BY
	|	Cells.Cell.TabIndex,
	|	Cells.Cell.Code";
	Query.SetParameter("Cells", Cells.Unload());
	
	CellTable = Query.Execute().Unload();
	
	If CellTable.Count() = 0 Then
		MessageText = NStr("vi = 'Chưa chỉ ra ô hàng nào';
							|ru = 'Не указано ни одной ячейки';
							|en = 'No storage bin is specified'; fa = 'No storage bin is specified';
							|it = 'Nessuna cella specificata';
							|pl = 'Nie wskazano ani jednej komórki';
							|tr = 'Hiç bir depo belirtilmedi'");
		CommonClientServer.MessageToUser(MessageText,,"Cells");
		Return "";
	Else
		Return PutToTempStorage(CellTable,FormUniqueID);
	EndIf;
	
EndFunction

&AtServer
Procedure SetValueOfSettingsParameter(Settings, ParameterName, Value)

	Parameter = Settings.DataParameters.Items.Find(ParameterName);
	
	If Parameter <> Undefined Then
		Parameter.Value = Value;
		Parameter.Use = True;
	EndIf;

EndProcedure

&AtServer
Procedure FillInBinListByPickingServer()
	DataCompositionSchema = Documents.GoodsPickingPlacement.GetTemplate("StorageBinFilterForFilling");
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate   = TemplateComposer.Execute(DataCompositionSchema, FilterCells_2.GetSettings(),,,Type("DataCompositionValueCollectionTemplateGenerator"));
	
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(CompositionTemplate);
	
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	Cells.Load(OutputProcessor.Output(DataCompositionProcessor));
EndProcedure

#EndRegion

#EndRegion
