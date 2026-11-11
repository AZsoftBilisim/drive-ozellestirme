
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("Ref") Then
		Ref = Parameters.Ref;
	Else
		Warehouse = Parameters.Warehouse;
		Premise = Parameters.Premise;
	EndIf;
	ShowProductPhotos = Parameters.ShowProductPhotos;
	Barcode = Parameters.Barcode;
	ScanningProcedure = Parameters.ScanningProcedure;
	
#If MobileStandaloneServer Then
	Items.FormCancelMove.Visible = False;
#Else
	Status = MobileWarehouseKeeperWorkspace.ObjectAttributeValue(Ref, "Status");
	If Status = Enums.StatusesOfGoodsPickingPlacement.Prepared2 And AccessRight("InteractiveSetDeletionMark", Metadata.Documents.GoodsPickingPlacement) Then
		Items.FormCancelMove.Visible = True;
	Else
		Items.FormCancelMove.Visible = False;
	EndIf;
#EndIf
	
	FillForm();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Items.GroupPages.CurrentPage = Items["InformationPage"] Then
		
		StandardProcessing = False;
		Cancel = True;
		Items.GroupPages.CurrentPage = Items["PageToReceive"];		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If UsedFormServer = UsedServer.Main Then
		// Peripherals
		If Source = "Peripherals" And IsInputAvailable() Then 
			
			ThereIsRawEvent = MobileWarehouseKeeperWorkspaceClient.ThereIsRawEvent();
			
			If EventName = "ScanData" And ThereIsRawEvent Then
				
				Data = MobileWarehouseKeeperWorkspaceClient.ConvertDataFromScannerToStructure(Parameter);
				
				ProcessBarcode(Data);

			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	LongDesc = New CallbackDescription("CompletePlacementInCell", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("Products",                 Item.CurrentData.Products);
	FormParameters.Insert("Characteristic",               Item.CurrentData.Characteristic);
	FormParameters.Insert("Series",                        Item.CurrentData.Series);
	FormParameters.Insert("Package",                     Item.CurrentData.PackagingSelection);
	FormParameters.Insert("PackagePlaced",            Item.CurrentData.PackagingPlacement);
	FormParameters.Insert("NumberOfPackages",           Item.CurrentData.NumberOfPackagesSelection);
	FormParameters.Insert("NumberOfPackagesPlaced",  Item.CurrentData.NumberOfPackagesPlacement);
	FormParameters.Insert("Mode",                        "EditingMoving");
	FormParameters.Insert("LineNumber",                  Item.CurrentRow);
	FormParameters.Insert("Warehouse",                        Warehouse);
	FormParameters.Insert("Premise",                    Premise);
	FormParameters.Insert("Cell",                       Item.CurrentData.SelectionCell);
	FormParameters.Insert("ReplacementCell",                 Item.CurrentData.CellPlacement);
	FormParameters.Insert("OperationType",                  3);
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	FormParameters.Insert("SKU", Item.CurrentData.SKU);
	FormParameters.Insert("Ref", Ref);
	FormParameters.Insert("DocumentBarcode", Barcode);
	FormParameters.Insert("ScanningProcedure", ScanningProcedure);

	OpenForm(
	"DataProcessor.MobileWarehouseKeeperWorkspace.Form.PlacementIntoBins",FormParameters,
	ThisObject,,,,LongDesc,
	FormWindowOpeningMode.Independent);
	
EndProcedure

&AtClient
Procedure FinishControl(Command)
	
	ClearMessages();
	
	ValueList = New ValueList;
	ValueList.Add("ExitApp", NStr("vi = 'Kết thúc';
									|ru = 'Завершить';
									|en = 'Finish'; fa = 'پایان';
									|it = 'Completare';
									|pl = 'Zakończ';
									|tr = 'Tamamla'"));
	ValueList.Add("Continue", NStr("vi = 'Tiếp tục';
									|ru = 'Продолжить';
									|en = 'Continue'; fa = 'ادامه';
									|it = 'Continuare';
									|pl = 'Kontynuuj';
									|tr = 'Devam et'"));
	
	Notification = New CallbackDescription("AfterClosingQuestion_", ThisObject);
	ShowQueryBox(Notification, NStr("vi = 'Hoàn tất điều chuyển?';
									|ru = 'Завершить перемещение?';
									|en = 'Do you want to finish the transfer?'; fa = 'Do you want to finish the transfer?';
									|it = 'Completare lo spostamento?';
									|pl = 'Zakończyć przeniesienie?';
									|tr = 'Transferi tamamla?'"), ValueList, 0);
	
EndProcedure

&AtClient
Procedure Scan(Command)
	
	LongDesc = New CallbackDescription("CellScanResult", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("FindType", "CellSearch");
	FormParameters.Insert("Warehouse", Warehouse);
	FormParameters.Insert("Premise", Premise);
	
	If UsedFormServer = UsedServer.Main Then
		OpenForm(
		"DataProcessor.MobileWarehouseKeeperWorkspace.Form.BarcodeScanning",FormParameters,
		ThisObject,,,, LongDesc,
		FormWindowOpeningMode.Independent);
	Else
		OpenForm(
		"DataProcessor.MobileWarehouseKeeperWorkspace.Form.BarcodeScanningOfflineMode",FormParameters,
		ThisObject,,,, LongDesc,
		FormWindowOpeningMode.Independent);
	EndIf;
	
EndProcedure

&AtClient
Procedure Information(Command)
	
	Items.GroupPages.CurrentPage = Items["InformationPage"];
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillForm()
	
	If ValueIsFilled(Ref) Then
		
		Query = New Query;
		Query.Text = 
			"SELECT
			|	GoodsPickingPlacement.Warehouse AS Warehouse,
			|	GoodsPickingPlacement.Premise AS Premise,
			|	GoodsPickingPlacement.Comment AS Comment,
			|	GoodsPickingPlacement.Performer AS Performer,
			|	GoodsPickingPlacement.GoodsFilter.(
			|		Products AS Products,
			|		Products.SKU AS SKU,
			|		Characteristic AS Characteristic,
			|		Purpose AS Purpose,
			|		Series AS Series,
			|		BatchesIndicationStatus AS BatchesIndicationStatus,
			|		Cell AS Cell,
			|		Package AS Package,
			|		Count AS Count,
			|		NumberOfPackages AS NumberOfPackages
			|	) AS GoodsFilter,
			|	GoodsPickingPlacement.GoodsPlacement.(
			|		Products AS Products,
			|		Characteristic AS Characteristic,
			|		Purpose AS Purpose,
			|		Series AS Series,
			|		Cell AS Cell,
			|		Package AS Package,
			|		Count AS Count,
			|		NumberOfPackages AS NumberOfPackages
			|	) AS GoodsPlacement
			|FROM
			|	Document.GoodsPickingPlacement AS GoodsPickingPlacement
			|WHERE
			|	GoodsPickingPlacement.Ref = &Ref";
		
		Query.SetParameter("Ref", Ref);
		
		QueryResult = Query.Execute();
		
		SelectionDetailRecords = QueryResult.Select();
		SelectionDetailRecords.Next();
		FillPropertyValues(ThisObject, SelectionDetailRecords);
		
		GoodsFilter = SelectionDetailRecords.GoodsFilter.Unload();
		GoodsPlacement = SelectionDetailRecords.GoodsPlacement.Unload();
		
		For Each String In GoodsFilter Do
			
			NewRow = Goods.Add();
			FillPropertyValues(NewRow, String);
			NewRow.SelectionCell = String.Cell;
			NewRow.PackagingSelection = String.Package;
			NewRow.CountFilter = String.Count;
			NewRow.NumberOfPackagesSelection = String.NumberOfPackages;
			
			// Search for lines in the placement
			TheStructureOfTheSearch = New Structure;
			TheStructureOfTheSearch.Insert("Products",   String.Products);
			TheStructureOfTheSearch.Insert("Characteristic", String.Characteristic);
			TheStructureOfTheSearch.Insert("Series",          String.Series);
			TheStructureOfTheSearch.Insert("Purpose",     String.Purpose);
			
			SearchResult = GoodsPlacement.FindRows(TheStructureOfTheSearch);
			If SearchResult.Count() > 0 Then
				NewRow.CellPlacement             = SearchResult[0].Cell;
				NewRow.PackagingPlacement           = SearchResult[0].Package;
				NewRow.NumberOfAccommodation         = SearchResult[0].Count;
				NewRow.NumberOfPackagesPlacement = SearchResult[0].NumberOfPackages;
			EndIf;
			
		EndDo;
	EndIf;
EndProcedure

&AtClient
Procedure ProcessBarcode(BarcodeData_1)
		
	BarcodesAreValid = MobileWarehouseKeeperWorkspaceClient.BarcodesAreValid(BarcodeData_1);
	
	If Not BarcodesAreValid Then
		Return;
	EndIf;
	
	If Barcode = BarcodeData_1.Barcode Then 
		
		TransferIsComplete = FinishTransferAtServer();
		
		If TransferIsComplete Then
			Close();
		Else
			Status(ErrorText);
		EndIf;
		
		Return;
	EndIf;
	
	CellData = CellDataByWK(BarcodeData_1.Barcode);
			
	If ValueIsFilled(CellData.Cell) Then
		CellScanResult(CellData);
		Return;
	EndIf;
		
	Status(NStr("vi = 'Không tìm thấy ô theo mã vạch';
				|ru = 'Ячейка по штрихкоду не найдена';
				|en = 'Storage bin is not found by barcode'; fa = 'Storage bin is not found by barcode';
				|it = 'Storage bin is not found by barcode';
				|pl = 'Storage bin is not found by barcode';
				|tr = 'Barkod ile depo yeri bulunamadı'"));
	
EndProcedure

&AtServer
Function CellDataByWK(Val Barcode)  
	
	Return DataProcessors.MobileWarehouseKeeperWorkspace.CellDataByWK(Warehouse, Premise, Barcode);
	
EndFunction

&AtClient
Procedure CellScanResult(Result = Undefined, AdditionalParameters = Undefined) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	LongDesc = New CallbackDescription("CompletePlacementInCell", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("Cell",      Result.Cell);
	FormParameters.Insert("Warehouse",       Warehouse);
	FormParameters.Insert("Premise",   Premise);
	FormParameters.Insert("OperationType", 3);
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
   	FormParameters.Insert("Ref", Ref);
   	FormParameters.Insert("DocumentBarcode", Barcode);
    FormParameters.Insert("CellBarcode", Result.Barcode);
	FormParameters.Insert("ScanningProcedure", ScanningProcedure);

	OpenForm(
		"DataProcessor.MobileWarehouseKeeperWorkspace.Form.PlacementIntoBins", FormParameters,
		ThisObject,,,, LongDesc, FormWindowOpeningMode.Independent);
	
EndProcedure

&AtClient
Procedure CompletePlacementInCell(Result = Undefined, AdditionalParameters = Undefined) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	For Each String In Result.ArrayOfPlacements Do
		
		If Result.Mode = "EditingMoving" Then
			NewRow = Goods[String.LineNumber];
		Else
			NewRow = Goods.Add();
		EndIf;
		FillPropertyValues(NewRow, String);
		
		NewRow.SelectionCell = String.Cell;
		NewRow.CellPlacement = String.ReplacementCell;
		
		NewRow.PackagingSelection = String.Package;
		NewRow.PackagingPlacement = String.PackagePlaced;
		
		NewRow.NumberOfPackagesSelection = String.NumberOfPackages;
		NewRow.NumberOfPackagesPlacement = String.NumberOfPackagesPlaced;
		
	EndDo;
	
	If ValueIsFilled(Result.NextCellData) Then
		CellScanResult(Result.NextCellData);
	EndIf;

EndProcedure

&AtClient
Procedure AfterClosingQuestion_(Result, Var_Parameters) Export
	
	If Result = "ExitApp" Then
		
		TransferIsComplete = FinishTransferAtServer();
		
		If TransferIsComplete Then 
			Close(); 
		Else
			Status(ErrorText);
		EndIf;
		
	Else
		Return;
	EndIf;
	
EndProcedure

&AtServer
Function FinishTransferAtServer()
	
	WriteErrorTemplate = NStr("vi = 'Không thể ghi lại %1. %2';
								|ru = 'Не удалось записать %1. %2';
								|en = 'Cannot save %1. %2'; fa = 'Cannot save %1. %2';
								|it = 'Impossibile registrare %1. %2';
								|pl = 'Nie udało się zapisać %1. %2';
								|tr = '%1 kaydedilemedi. %2'");

	If ValueIsFilled(Ref) Then
		DocumentObject = Ref.GetObject();
	Else
		DocumentObject                      = Documents.GoodsPickingPlacement.CreateDocument();
		DocumentObject.OperationKind          = Enums.OperationKindsOfGoodsPlacementPicking.Move;
		DocumentObject.ExecutionStartDate = CurrentSessionDate();
		DocumentObject.Date                 = CurrentSessionDate();
		
		Performer = MobileWarehouseKeeperWorkspace.CurrentUser();
	EndIf;
	
	DocumentObject.Status      = Enums.StatusesOfGoodsPickingPlacement.CompletedWithoutErrors;
	DocumentObject.Premise   = Premise;
	DocumentObject.Comment = Comment;
	DocumentObject.Performer = Performer;
	DocumentObject.Warehouse       = Warehouse;
	
	DocumentObject.ExecutionEndDate = CurrentSessionDate();
	
	DocumentObject.GoodsFilter.Clear();
	DocumentObject.GoodsPlacement.Clear();
	
	If MobileWarehouseKeeperWorkspace.ObjectAttributeValue(Warehouse, "UseWarerooms") And Premise.IsEmpty() Then
		
		ErrorText = (NStr("vi = 'Chưa chọn nhà kho';
							|ru = 'Не выбрано помещение';
							|en = 'Wareroom is not selected'; fa = 'Wareroom is not selected';
							|it = 'Locale non selezionato';
							|pl = 'Nie wybrano pomieszczenia';
							|tr = 'Alan seçilmedi'"));
		Items.GroupPages.CurrentPage = Items["InformationPage"];
		Return False;
		
	EndIf;
	
	If Not Goods.Count() Then
		
		ErrorText = (NStr("vi = 'Chưa chọn mặt hàng nào để điều chuyển';
							|ru = 'Не выбрано ни одного товара для перемещения';
							|en = 'No goods to transfer are selected'; fa = 'No goods to transfer are selected';
							|it = 'Не выбрано ни одного товара для перемещения';
							|pl = 'No goods to transfer are selected';
							|tr = 'Transfer edilecek hiç bir ürün seçilmedi'"));
		Items.GroupPages.CurrentPage = Items["PageToReceive"]; 
		Return False;
		
	EndIf;
	
	For Each String In Goods Do
		
		NewRow = DocumentObject.GoodsFilter.Add();
		FillPropertyValues(NewRow, String);
		
		PackagingFactor = MobileWarehouseKeeperWorkspace.PackagingFactor(String.PackagingSelection, String.Products);
		NewRow.CountPicked = String.NumberOfPackagesSelection * PackagingFactor;
		NewRow.NumberOfPackagesPicked = String.NumberOfPackagesSelection;
		NewRow.Count = NewRow.CountPicked;
		NewRow.NumberOfPackages = NewRow.NumberOfPackagesPicked;
		NewRow.Cell = String.SelectionCell;
		NewRow.Package = String.PackagingSelection;
		
		NewRow = DocumentObject.GoodsPlacement.Add();
		FillPropertyValues(NewRow, String);
		
		PackagingFactor = MobileWarehouseKeeperWorkspace.PackagingFactor(String.PackagingPlacement, String.Products);
		NewRow.CountPlaced = String.NumberOfPackagesPlacement * PackagingFactor;
		NewRow.NumberOfPackagesPlaced = String.NumberOfPackagesPlacement;
		NewRow.Count = NewRow.CountPlaced;
		NewRow.NumberOfPackages = NewRow.NumberOfPackagesPlaced;
		NewRow.Cell = String.CellPlacement;
		NewRow.Package = String.PackagingPlacement;
		
	EndDo;
	
	SeriesSpecificationParameters = Documents.GoodsPickingPlacement.SeriesSpecificationParameters(DocumentObject);
	MobileWarehouseKeeperWorkspace.FillInStatusesForSpecifyingSeries(DocumentObject, SeriesSpecificationParameters.Move);

	Try
#If Not MobileStandaloneServer Then
		DocumentObject.Write(DocumentWriteMode.Posting);
#Else
		DocumentObject.Write(DocumentWriteMode.Write);
#EndIf
	Except
		DocumentObject.Write(DocumentWriteMode.Write);
		ErrorText = StrTemplate(WriteErrorTemplate, Ref,
			ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

&AtClient
Procedure CancelMove(Command)
	
	ValueList = New ValueList;
	ValueList.Add("ExitApp", NStr("vi = 'Đặt dấu xóa chứng từ';
									|ru = 'Пометить документ на удаление';
									|en = 'Mark the document for deletion'; fa = 'Mark the document for deletion';
									|it = 'Mark the document for deletion';
									|pl = 'Mark the document for deletion';
									|tr = 'Silinmek üzere belge işaretle'"));
	ValueList.Add("Continue", NStr("vi = 'Tiếp tục điều chuyển hàng hóa nội bộ';
									|ru = 'Продолжить перемещение';
									|en = 'Continue transfer'; fa = 'Continue transfer';
									|it = 'Continue transfer';
									|pl = 'Continue transfer';
									|tr = 'Transfere devam et'"));
	
	Notification = New CallbackDescription("AfterClosingIssueCancelMove", ThisObject);
	ShowQueryBox(Notification, NStr("vi = 'Để hủy điều chuyển, cần đặt dấu xóa chứng từ điều chuyển. Sau đó sẽ không thể quay lại chỉnh sửa. Bạn có muốn đặt dấu xóa không?';
									|ru = 'Для отмены перемещения необходимо пометить на удаление документ перемещения. Вернуться к редактированию будет невозможно. Пометить на удаление?';
									|en = 'To cancel the transfer, mark the transfer document for deletion. It will be impossible to get back to editing. Mark the document for deletion?'; fa = 'To cancel the transfer, mark the transfer document for deletion. It will be impossible to get back to editing. Mark the document for deletion?';
									|it = 'To cancel the transfer, mark the transfer document for deletion. It will be impossible to get back to editing. Mark the document for deletion?';
									|pl = 'To cancel the transfer, mark the transfer document for deletion. It will be impossible to get back to editing. Mark the document for deletion?';
									|tr = 'Transferi geri almak için, transfer belgesini silinmek üzere işaretlemeniz gerekir. Düzenleme yapılamaz. Silinmek üzere işaretlensin mi?'"), ValueList, 0);
	
EndProcedure

&AtClient
Procedure AfterClosingIssueCancelMove(Result, Var_Parameters) Export
	
	If Result = "ExitApp" Then
		
		MoveCanceled = CancelMovingAtServer();
		
		If MoveCanceled Then
			Close();
		EndIf;
		
	Else
		Return;
	EndIf;
	
EndProcedure

&AtServer
Function CancelMovingAtServer()
	
#If MobileStandaloneServer Then
	Return False;
#Else
	Try
		DocumentObject = Ref.GetObject();
		DocumentObject.SetDeletionMark(True);
		
		ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	Except
		Common.MessageToUser(NStr("vi = 'Không thể hủy nhiệm vụ điều chuyển.';
									|ru = 'Не удалось отменить задание на перемещение.';
									|en = 'Cannot cancel the transfer task.'; fa = 'Cannot cancel the transfer task.';
									|it = 'Cannot cancel the transfer task.';
									|pl = 'Cannot cancel the transfer task.';
									|tr = 'Transfer görevi iptal edilemedi.'"));
		
		Return False;
	EndTry;
	
	Return True;
#EndIf
	
EndFunction

#EndRegion
