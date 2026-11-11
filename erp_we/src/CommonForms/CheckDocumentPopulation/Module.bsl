#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

&AtClient
Var ClosingProcessing; //used to work out the closing of the form

&AtClient
Var CurDataId; //used to pass the current line to the wait handler

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	TMCommonUse.CustomizePeripherals(ThisForm);
	NotUsePackages = Parameters.NotUsePackages;
	
	If Parameters.Property("OutputWeightVolume") Then
		OutputWeightVolume = Parameters.OutputWeightVolume;
	Else
		OutputWeightVolume = False;
	EndIf;
	
	If Parameters.Property("OnlyNonLabeledProductsHaveBeenUnloaded", OnlyNonLabeledProductsHaveBeenUnloaded) Then
		If OnlyNonLabeledProductsHaveBeenUnloaded Then
			Title = NStr("vi = 'Kiểm tra số lượng hàng hóa trong chứng từ (sản phẩm chưa dán nhãn)';
						|ru = 'Проверка количества товаров в документе (немаркируемая продукция)';
						|en = 'Goods quantity check in the document (non-marked products)'; fa = 'Goods quantity check in the document (non-marked products)';
						|it = 'Verifica della quantità di articoli nel documento (produzione non marcata)';
						|pl = 'Sprawdzenie ilości towarów w dokumencie (produkcja nieznakowana)';
						|tr = 'Belgedeki ürün sayısının kontrol edilmesi (etiketlenmemiş imal edilen ürünler)'");
		EndIf;
	EndIf;
	
	GoodsQuantityExcessIsAllowed = Parameters.GoodsQuantityExcessIsAllowed;
	VarianceIsProhibited                  = Parameters.VarianceIsProhibited;
	Warehouse                                = Parameters.Warehouse;
	WarehouseGroup_                          = ItIsGroupOfWarehousesAndWarehousesUsedByWHForSale(Warehouse);
	TransferAgainstOrders                 = Parameters.TransferAgainstOrders;
	Status                               = Parameters.Status;
	Ref                               = Parameters.Ref;
	ByAssemblyDisassemblyOrder                        = Parameters.ByAssemblyDisassemblyOrder;
	Terms                           = Parameters.Terms;
	ReceiptUnderOrders                 = Parameters.ReceiptUnderOrders;
	CalculateSets                   = Parameters.CalculateSets;
	
	If ValueIsFilled(Parameters.SeriesSpecificationParameters) Then
		ParametersForSpecifyingTimeSeries = New Structure(Parameters.SeriesSpecificationParameters);
		ParametersForSpecifyingTimeSeries.NameOfValueSourceInObjectForm = "ThisForm";
		SeriesSpecificationParameters = New FixedStructure(ParametersForSpecifyingTimeSeries);
		
		ProductsServer.AddStatusFieldsForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	EndIf;
	
	ProductSelectionParametersInTableSection = Ref.Metadata().TabularSections[Parameters.TabularSectionName].Attributes.Products.ChoiceParameters;
	For Each TSRow In ProductSelectionParametersInTableSection Do
		If StrFind(TSRow.Name, "Filter.ItemsType") Then
			If TypeOf(TSRow.Value) = Type("EnumRef.ItemsTypes") Then
				ItemsTypes.Add(TSRow.Value);
			Else
				For Each EnumerationValue In TSRow.Value Do
					ItemsTypes.Add(EnumerationValue);
				EndDo;
			EndIf;
		EndIf;
	EndDo;

	If ValueIsFilled(ItemsTypes) Then
		ChoiceParameter  = New ChoiceParameter("Filter.ItemsType", ItemsTypes);
		ChoiceParameters = New Array();
		ChoiceParameters.Add(ChoiceParameter);
		Items.Products.ChoiceParameters = New FixedArray(ChoiceParameters);
	Else
		AllTypesOfProducts = True;
		For Each EnumerationValue In Enums.ItemsTypes Do
			ItemsTypes.Add(EnumerationValue);
		EndDo;
	EndIf;
	
	TMCommonUseClientServer.SetFormItemProperty(
		Items,
		"GoodsSeries",
		"Visible",
		ValueIsFilled(Parameters.SeriesSpecificationParameters) And SeriesSpecificationParameters.UseItemsBatch);
		
	Goods.Load(GetFromTempStorage(Parameters.AddressInTempStorage));
	
	For Each TSRow In Goods Do
		TSRow.ThereIsDiscrepancy = 1;
	EndDo;
	
	SetsServer.FillInServiceDetails(ThisForm, "Goods", True);
	
	If OutputWeightVolume Then
		FillInServiceDetailsForProductRange();
	Else
		Items.GoodsGroupWeight.Visible = False;
		Items.GoodsGroupVolume.Visible = False;
	EndIf;
	
	If NotUsePackages Then
		Items.Package.Visible = False;
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	ProcessingOfTabularForms.InitializeRowCache(Items.Goods);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	
	ClosingProcessing = True;
	CurrentItem = Items.Products;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Then
		Return;
	EndIf;
	
	If Not ClosingProcessing Then
		
		If VarianceIsProhibited Then
			Cancel(Undefined);
		Else
			Cancel = True;
			ShowQueryBox(
				New CallbackDescription("BeforeCloseCompletion", ThisObject),
				NStr("vi = 'Kết thúc kiểm tra mà không chuyển chênh lệch vào chứng từ?';
					|ru = 'Завершить проверку без переноса расхождений в документ?';
					|en = 'Finish checking without discrepancy transfer to the document?'; fa = 'Finish checking without discrepancy transfer to the document?';
					|it = 'Concludere la verifica senza trasferire le discrepanze al documento?';
					|pl = 'Zakończyć weryfikację bez przeniesienia odchylenia do dokumentu?';
					|tr = 'Tutarsızlıklar belgeye aktarılmadan kontrol tamamlansın mı?'"),
				QuestionDialogMode.YesNo);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose()
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessingNotificationOnServer(EventName, Parameter, Source)
	
	AdditionalParameters = New Structure("EventName, Parameter, Source", EventName, Parameter, Source);
	FormEvents.WhenChangingElement(ThisObject, "Event", AdditionalParameters);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("CachedValues",    CachedValues);
	AdditionalParameters.Insert("StandardProcessing",    True);
	AdditionalParameters.Insert("ServerCallRequired__", False);
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source, AdditionalParameters);
	CachedValues = AdditionalParameters.CachedValues;
	If AdditionalParameters.ServerCallRequired__ Then
		ProcessingNotificationOnServer(EventName, Parameter, Source);
	EndIf;
	If Not AdditionalParameters.StandardProcessing Then
		Return;
	EndIf;
	
	// Peripherals
	If IsInputAvailable()
		And Source = "Peripherals" Then
		
		If EventName = "ScanData"
			And EquipmentManagerTMClient.ThereIsRawEvent() Then
			
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToArray(Parameter));
			
		EndIf;
		
	EndIf;
	// End Peripherals
	
	// Unknown barcodes
	If EventName = "UnknownBarcodes"
		And Source = "Peripherals"
		And Parameter.OwnerForm = UUID Then
		
		CachedValues.Barcodes.Clear();
		
		BarcodeData_5 = New Array;
		
		For Each ReceivedBarcode In Parameter.ItemsBarcodes Do
			BarcodeData_5.Add(ReceivedBarcode);
		EndDo;
		
		ProcessBarcodes(BarcodeData_5);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	UseItemVariants = GetFunctionalOption("UseItemVariants");
	
	For Each TSRow In Goods Do
		LineNumberForUser = Goods.IndexOf(TSRow) + 1;
		If Not ValueIsFilled(TSRow.Products) Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Chưa điền trường ""Mặt hàng"" trong dòng %1 danh sách ""Hàng hóa""';
																						|ru = 'Не заполнено поле ""Номенклатура"" в строке %1 списка ""Товары""';
																						|en = '""Items"" in line %1 of the ""Goods"" list is required'; fa = '""Items"" in line %1 of the ""Goods"" list is required';
																						|it = 'Campo ""Articolo"" nella riga %1 dell''elenco ""Merce"" non compilato';
																						|pl = 'Nie wypełniono pola ""Produkt"" w wierszu %1 listy ""Towary""';
																						|tr = '""Ürünler"" listesinin %1 satırında ""Öğe"" alanı doldurulmadı'"), LineNumberForUser);
			PathToRowOfTablePart = CommonClientServer.PathToTabularSection("Goods", LineNumberForUser, "Products");
			Common.MessageToUser(MessageText,,PathToRowOfTablePart,,Cancel);
		EndIf;
		If UseItemVariants And Not ValueIsFilled(TSRow.Characteristic) And TSRow.ItemVariantsAreUsed Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Chưa điền trường ""Đặc tính"" trong dòng %1 danh sách ""Hàng hóa""';
																						|ru = 'Не заполнено поле ""Характеристика"" в строке %1 списка ""Товары""';
																						|en = '""Variant"" in line %1 of the ""Goods"" list is required'; fa = '""Variant"" in line %1 of the ""Goods"" list is required';
																						|it = 'Campo ""Caratteristica"" nella riga %1 dell''elenco ""Merce"" non compilato';
																						|pl = 'Nie wypełniono pola ""Charakterystyka"" w wierszu %1 listy ""Towary""';
																						|tr = '""Ürünler"" listesinin %1 satırında ""Özellik"" alanı doldurulmadı'"), LineNumberForUser);
			PathToRowOfTablePart = CommonClientServer.PathToTabularSection("Goods", LineNumberForUser, "Characteristic");
			Common.MessageToUser(MessageText,,PathToRowOfTablePart,,Cancel);
		EndIf;
	EndDo;
	
	Query = New Query(
	"SELECT
	|	TabularSection.Products AS Products,
	|	TabularSection.LineNumber AS LineNumber
	|INTO TabularSection
	|FROM
	|	&TabularSection AS TabularSection
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TabularSection.Products AS Products,
	|	TabularSection.LineNumber AS LineNumber,
	|	TabularSection.Products.ItemsType AS ItemsType,
	|	CASE
	|		WHEN TabularSection.Products.ItemsType IN (&ItemsTypes)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ErrorByProductType,
	|	&ConditionForLabeledProducts AS MarkingError
	|FROM
	|	TabularSection AS TabularSection");
	
	Query.SetParameter("ConditionForLabeledProducts", False);
	If OnlyNonLabeledProductsHaveBeenUnloaded Then
		ProductsLocalization.UpdateParametersOfRequestProcessingVerificationOfFillingInDocuments(Query);
	EndIf;
	
	TabularSection = Goods.Unload(,"Products");
	TMCommonUse.NumberValueTable(TabularSection, "LineNumber"); //numbering starts from 0
	
	Query.SetParameter("ItemsTypes", ItemsTypes.UnloadValues());
	Query.SetParameter("TabularSection", TabularSection);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		
		If Selection.ErrorByProductType Then
			LineNumberForUser = Selection.LineNumber + 1;
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Kiểu mặt hàng %1 tại dòng %2 của danh sách ""Hàng hóa"" khác với kiểu khả dụng: %3';
					|ru = 'Тип номенклатуры %1 в строке %2 списка ""Товары"" отличается от допустимых типов: %3';
					|en = 'Type of item %1 in line %2 of the Item list differs from available types: %3'; fa = 'Type of item %1 in line %2 of the Item list differs from available types: %3';
					|it = 'Tipo di articolo %1 nella riga %2 dell''elenco ""Merce"" differisce dai tipi disponibili: %3';
					|pl = 'Typ pozycji %1 w wierszu %2 listy ""Towary"" różni się od dozwolonych typów: %3';
					|tr = '""Ürünler"" listesinin %2 satırında %1 öğe tipi erişilebilir: %3 tiplerinden farklı'"),
				Selection.ItemsType, 
				LineNumberForUser,
				StrConcat(ItemsTypes.UnloadValues(),", "));
			PathToRowOfTablePart = CommonClientServer.PathToTabularSection("Goods",
				LineNumberForUser, "Products");
			Common.MessageToUser(MessageText,,PathToRowOfTablePart,,Cancel);
		EndIf;
		
		If Selection.MarkingError Then
			LineNumberForUser = Selection.LineNumber + 1;
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Mặt hàng %1 trong dòng %2 danh sách ""Hàng hóa"" không thể là dán nhãn.';
					|ru = 'Номенклатура %1 в строке %2 списка ""Товары"" не может быть маркируемой.';
					|en = '%1 item in line %2 of the ""Goods"" list cannot be the marked one.'; fa = '%1 item in line %2 of the ""Goods"" list cannot be the marked one.';
					|it = 'Nomenclatura %1 nella riga %2 elenco ""Articoli"" non possono essere marcati.';
					|pl = 'Produkt %1 w wierszu %2 listy ""Towary"" nie może być znakowany.';
					|tr = '""Ürünler"" listesinin %2 satırında %1 öğe işaretlenebilir olabilir.'"),
				Selection.Products, 
				LineNumberForUser);
			PathToRowOfTablePart = CommonClientServer.PathToTabularSection("Goods",
				LineNumberForUser, "Products");
			Common.MessageToUser(MessageText,,PathToRowOfTablePart,,Cancel);
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region EventHandlers

&AtClient
Procedure ProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Products", StructureOfActions);
	
	If Not ValueIsFilled(CurrentRow.Warehouse)
		And Not WarehouseGroup_ Then
		CurrentRow.Warehouse = Warehouse;
	EndIf;
	
	If ValueIsFilled(CurrentRow.Warehouse)
		And SeriesSpecificationParameters <> Undefined Then
		StructureOfActions.Insert("CheckSeriesCalculateStatus",
			New Structure("Warehouse, SeriesSpecificationParameters", CurrentRow.Warehouse, SeriesSpecificationParameters));
	Else
		CurrentRow.BatchesIndicationStatus = 0;
	EndIf;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

	ClearMessages();
	CurLineForUserIs = Items.Goods.CurrentRow + 1;
	ProductsOnChangeServer(CurLineForUserIs, CurrentRow.Products);
	
EndProcedure
	
&AtServer
Procedure ProductsOnChangeServer(CurrentRowNumber1, Products)
	If OnlyNonLabeledProductsHaveBeenUnloaded Then
		If ProductsLocalization.TheseAreMarkedProducts(Products) Then
			
			StandardProcessing = False;
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Mặt hàng %1 được dán nhãn. Chỉ có thể chọn sản phẩm chưa dán nhãn';
				|ru = 'Номенклатура %1 маркируемая. Можно выбрать только немаркируемую продукцию';
				|en = '%1 item is the marked one. You can select only non-marked products'; fa = '%1 item is the marked one. You can select only non-marked products';
				|it = 'Nomenclatura %1 marcatura. Si può selezionare solo la produzione non marcata';
				|pl = 'Produkt %1 jest znakowany. Można wybrać tylko nieznakowane produkty';
				|tr = '%1 öğesi işaretlenebilir. Sadece işaretlenmeyen imal edilen ürünler seçilmeli'"),
			Products);
			PathToRowOfTablePart = CommonClientServer.PathToTabularSection("Goods", CurrentRowNumber1, "Products");
				
			Common.MessageToUser(MessageText,,PathToRowOfTablePart);
			
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure ProductsStartChoice(Item, ChoiceData, StandardProcessing)
	Return;
	
EndProcedure

&AtClient
Procedure OnlyDiscrepanciesOnChange(Item)
	SetSelectionByDivergence();
EndProcedure

&AtClient
Procedure GoodsOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	ThereIsDiscrepancy = CurrentData.ThereIsDiscrepancy;
	CurrentData.ThereIsDiscrepancy = ?(CurrentData.NumberOfPackages = CurrentData.NumberOfPackagesReal, 0, 1);
	
	If ThereIsDiscrepancy <> CurrentData.ThereIsDiscrepancy And OnlyDiscrepancies Then
		SetSelectionByDivergence();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	OpenSelectionOfSeries(Item.EditText);
EndProcedure

&AtClient
Procedure GoodsSeriesOnChange(Item)
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value            		 = Items.Goods.CurrentData.Series;
	ValueSelected.CurrentRowID = Items.Goods.CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisForm, SeriesSpecificationParameters, ValueSelected);

EndProcedure

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)
	
	CurrentData = Items.Goods.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	Cancel = True;
	CurrentRowID = CurrentData.GetID();
	
	ClearMessages();
	
	LinesToDelete = New Array;
	NonErasableLines = New Array;
	For Each Id In Items.Goods.SelectedRows Do
		TableRow = Items.Goods.RowData(Id);
		If Not ValueIsFilled(TableRow.NumberOfPackages) Then
			LinesToDelete.Add(TableRow);
			If Id = CurrentRowID Then
				
				// The current row is deleted - you need to reposition.
				IDOfPreviousLine = Undefined;
				CurLineFound = False;
				NewCurLineFound = False;
				For Each TSRow In Goods Do
					If TSRow.GetID() = CurrentRowID Then
						CurLineFound = True;
					Else
						If CurLineFound Then
							If LinesToDelete.Find(TSRow) = Undefined Then
								Items.Goods.CurrentRow = TSRow.GetID();
								NewCurLineFound = True;
								Break;
							EndIf;
						Else
							If LinesToDelete.Find(TSRow) = Undefined Then
								IDOfPreviousLine = TSRow.GetID();
							EndIf;
						EndIf;
					EndIf;
				EndDo;
				
				If Not NewCurLineFound Then
					Items.Goods.CurrentRow = IDOfPreviousLine;
				EndIf;
				
			EndIf;
		Else
			NonErasableLines.Add(TableRow);
		EndIf;
	EndDo;
	
	For Each TSRow In LinesToDelete Do
		Goods.Delete(TSRow);
	EndDo;
	
	For Each TSRow In NonErasableLines Do
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Không thể xóa dòng %1, bởi vì, dòng này có trong chứng từ gốc.';
																					|ru = 'Строку %1 удалить нельзя, т.к. она присутствует в исходном документе.';
																					|en = 'Line %1 cannot be deleted as it is in the original document.'; fa = 'Line %1 cannot be deleted as it is in the original document.';
																					|it = 'Impossibile eliminare la riga %1, poiché è presente nel documento originale.';
																					|pl = 'Wiesz %1 nie może zostać usunięty, ponieważ znajduje się on w dokumencie źródłowym.';
																					|tr = '%1 satırı silinmemeli çünkü orijinal belgede mevcuttur.'"), Goods.IndexOf(TSRow) + 1);
		CommonClient.MessageToUser(MessageText,,"Goods",,Cancel);
	EndDo;
	
EndProcedure

&AtClient
Procedure GoodsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	If Copy Then
		
		Cancel = True;
		
		CurrentData = Items.Goods.CurrentData;
		
		NewRow = Goods.Add();
		FillPropertyValues(NewRow, CurrentData);
		NewRow.NumberOfPackages     = 0;
		NewRow.NumberOfPackagesReal = 0;
		NewRow.NumberOfPackagesFactTotal = 0;
		NewRow.Discrepancy                = 0;
		
		Items.Goods.CurrentRow = NewRow.GetID();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesRealOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;

	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow,StructureOfActions,CachedValues);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("CachedValues", CachedValues);
	FormEventsClient.WhenChangingElement(ThisObject, Item, AdditionalParameters);
	CachedValues = AdditionalParameters.CachedValues;
	
EndProcedure

&AtClient
Procedure GoodsWeightOnChange(Item)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackagesByWeight", "Real");
	
	CurrentRow = Items.Goods.CurrentData;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure GoodsVolumeM3OnChange(Item)
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackagesByVolume", "Real");
	
	CurrentRow = Items.Goods.CurrentData;
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure FinishCheck(Command)
	
	ClosingProcessing = False;
	
	ProductsUnlinkedFromTheSet.Clear();
	
	AnalysisOfSets();
	
	ClearMessages();
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	ClearMessages();
	
	ArrayOfRowsNewProducts = New Array;
	ArrayOfMissingRows   = New Array;
	ArrayOfExcessRows     = New Array;
	For Each TSRow In Goods Do
		If TSRow.NumberOfPackages = TSRow.NumberOfPackagesFactTotal Then
			// There are no discrepancies
		ElsIf TSRow.NumberOfPackages = 0 And TSRow.NumberOfPackagesFactTotal > 0 Then
			// New product
			ArrayOfRowsNewProducts.Add(TSRow);
			
		ElsIf TSRow.NumberOfPackages > TSRow.NumberOfPackagesFactTotal Then
			// Shortage_
			ArrayOfMissingRows.Add(TSRow);
			
		ElsIf TSRow.NumberOfPackages < TSRow.NumberOfPackagesFactTotal Then
			// Surplus
			ArrayOfExcessRows.Add(TSRow);
			
		EndIf;
	EndDo;
	
	AllowedToCompleteTheCheck = True;
	If    ArrayOfRowsNewProducts.Count() > 0
		Or ArrayOfMissingRows.Count()   > 0
		Or ArrayOfExcessRows.Count()     > 0
		Or ProductsUnlinkedFromTheSet.Count() > 0 Then
		
		If VarianceIsProhibited Then
			AllowedToCompleteTheCheck = False;
		EndIf;
		
		ListOfQuestions = New ValueList();
		ListOfQuestions.Add("MoveTo_", NStr("vi = 'Chuyển sang';
											|ru = 'Перенести';
											|en = 'Transfer'; fa = 'انتقال';
											|it = 'Spostare';
											|pl = 'Transfer';
											|tr = 'Taşı'"));
		ListOfQuestions.Add("NoWrap", NStr("vi = 'Không chuyển sang';
											|ru = 'Не переносить';
											|en = 'Do not transfer'; fa = 'Do not transfer';
											|it = 'Non trasferire';
											|pl = 'Nie przenoś';
											|tr = 'Taşımamak'"));
		ListOfQuestions.Add("ReturnToCheck", NStr("vi = 'Trả lại để kiểm tra';
													|ru = 'Вернуться к проверке';
													|en = 'Return to check'; fa = 'بازگشت به بررسی';
													|it = 'Tornare alla verifica';
													|pl = 'Wróć do weryfikacji';
													|tr = 'Kontrole geri dön'"));
		
		NotifyDescriptionQuestion = New CallbackDescription("ProcessingResponseToQuestion",
		                                                    ThisObject);
		QueryText = NStr("vi = 'Đã tìm thấy chênh lệch giữa số lượng hàng hóa trong chứng từ và kết quả kiểm tra. 
									|Chuyển dữ liệu thực tế vào chứng từ?';
									|ru = 'Обнаружены расхождения между количеством товаров в документе и результатом проверки. 
									|Перенести фактические данные в документ?';
									|en = 'Discrepancies are found between the quantity of goods in the document and the check result. 
									|Do you want to transfer the actual data to the document?'; fa = 'Discrepancies are found between the quantity of goods in the document and the check result. 
									|Do you want to transfer the actual data to the document?';
									|it = 'Sono state rilevate discrepanze tra la quantità di articoli nel documento e il risultato di verifica.
									|Trasferire i dati effettivi nel documento?';
									|pl = 'Wykryto rozbieżności między ilością towarów w dokumencie a wynikiem sprawdzenia. 
									|Przenieść faktyczne dane do dokumentu?';
									|tr = 'Belgedeki ürün sayısı ile kontrol sonucu arasında tutarsızlıklar bulundu.
									|Gerçek verileri belgeye transfer et?'");
		ShowQueryBox(NotifyDescriptionQuestion, QueryText, ListOfQuestions);

	Else
		
		ClosingProcessing = True;
		
		AdditionalParameters = New Structure("ServerCallRequired__, ClosingResult", False, Undefined);
		FormEventsClient.WhenChangingElement(ThisObject, "ClosingResult", AdditionalParameters);
		If AdditionalParameters.ServerCallRequired__ Then
			GetResultOfClosingOnServer(AdditionalParameters);
		EndIf;
		
		Close(AdditionalParameters.ClosingResult);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure GetResultOfClosingOnServer(AdditionalParameters)
	
	FormEvents.WhenChangingElement(ThisObject, "ClosingResult", AdditionalParameters);
	
EndProcedure

&AtClient
Procedure GetWeight(Command)
	
	CurrentRow = EquipmentManagerTMClient.CurrentRow(ThisForm);
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	EquipmentManagerClient.StartGettingWeightWithElectronicScales(
		New CallbackDescription("GetWeightCompletion", ThisObject, CurrentRow),
		UUID);
	
EndProcedure

&AtClient
Procedure GetWeightCompletion(ExecutionResult, CurrentRow) Export
	
	If ExecutionResult.Result Then
		CurrentRow.NumberOfPackagesReal = ExecutionResult.Weight;
	Else
		EquipmentManagerTMClient.ReportError(ExecutionResult);
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
		ProcessBarcodes(Result.TableOfGoods);
	Else
		EquipmentManagerTMClient.ReportError(Result);
	EndIf;
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	ClosingProcessing = True;
	Close(Undefined);
	
EndProcedure

&AtClient
Procedure SearchByBarcodeExecute(Command)
	
	ClearMessages();
	Notification = New CallbackDescription("SearchByBarcodeCompletion", ThisObject);
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "UnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Goods.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm, 
																			 "Characteristic",
																		     "Goods.ItemVariantsAreUsed");

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsNumberOfPackagesReal.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Goods.NumberOfPackages");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("Goods.NumberOfPackagesReal");

	Item.Appearance.SetParameterValue("TextColor", WebColors.Green);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsNumberOfPackagesReal.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Goods.NumberOfPackages");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = New DataCompositionField("Goods.NumberOfPackagesReal");

	Item.Appearance.SetParameterValue("TextColor", WebColors.Red);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisForm, False,, 
																     "Goods.BatchesIndicationStatus", 
																     "Goods.ItemsType");

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Products.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Characteristic.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Package.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UnitOfMeasure.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ProductsNumberOfPackagesInDocument.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSeries.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Goods.NumberOfPackages");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsWeight.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Goods.PackageWeight");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
													|ru = '<не используется>';
													|en = '<not used>'; fa = '<استفاده نمی‌شود>';
													|it = '<non viene utilizzato>';
													|pl = '<nie używa się>';
													|tr = '<kullanılmayan>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsVolumeM3.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Goods.PackageVolume");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng>';
													|ru = '<не используется>';
													|en = '<not used>'; fa = '<استفاده نمی‌شود>';
													|it = '<non viene utilizzato>';
													|pl = '<nie używa się>';
													|tr = '<kullanılmayan>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsUnitOfMeasureForWeight.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Goods.PackageWeight");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("Show", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsUnitOfMeasureForVolume.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Goods.PackageVolume");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("Show", False);

EndProcedure

#Region SetOfSeries

&AtClient
Procedure OpenSelectionOfSeries(Text = "", CurrentData = Undefined)

	CurrentDataStructure = New Structure;
	
	If CurrentData = Undefined Then
		CurrentData = Items.Goods.CurrentData;
	EndIf;
	
	For Each KeyValue In ProcessingOfTabularFormsClientServer.LineCache(Items.Goods, ThisObject) Do
		If KeyValue.Key = "NumberOfPackagesReal" Then
			CurrentDataStructure.Insert(SeriesSpecificationParameters.FieldNameQuantity, CurrentData[KeyValue.Key]);
		Else	
			CurrentDataStructure.Insert(KeyValue.Key, CurrentData[KeyValue.Key]);
		EndIf;
	EndDo;
	CurrentDataStructure.Insert("CurrentRowID", CurrentData.GetID());
	
	If ProductsClient.YouNeedServerCallToSpecifySeries(ThisForm,SeriesSpecificationParameters,Text,CurrentDataStructure, False) Then
		Return;
	EndIf;
	
EndProcedure

#EndRegion

#Region Barcodes

&AtClient
Procedure ProcessBarcodes(BarcodeData_5)
	
	ClearMessages();
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
		Return;
	EndIf;
	
	StructureOfActionsWithAddedStrings = New Structure;
	StructureOfActionsWithAddedStrings.Insert(
		"FillInProductTypeAttribute_",
		New Structure("Products", "ItemsType"));
	StructureOfActionsWithAddedStrings.Insert(
		"CheckFillWarehouse",
		New Structure("DefaultWarehouse, WarehouseGroup_", Warehouse, WarehouseGroup_));
	
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject,
		"Products",
		StructureOfActionsWithAddedStrings);
	
	StructureOfActionsWithModifiedStrings = New Structure;
	
	If SeriesSpecificationParameters <> Undefined Then
		StructureForCalculatingSeries = New Structure("Warehouse, SeriesSpecificationParameters",
													?(WarehouseGroup_,
														PredefinedValue("Catalog.Warehouses.EmptyRef"),
														Warehouse),
													SeriesSpecificationParameters);
		StructureOfActionsWithAddedStrings.Insert("CheckSeriesCalculateStatus", StructureForCalculatingSeries);
	EndIf;
	
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject,
		"ProductsUpdate",
		StructureOfActionsWithModifiedStrings);
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	StructureOfActions.SeriesSpecificationParameters                 = SeriesSpecificationParameters;
	StructureOfActions.ColumnNameQuantity                   = "NumberOfPackagesReal";
	StructureOfActions.NotUsePackages                 = NotUsePackages;
	StructureOfActions.BlockFormData                 = False;
	StructureOfActions.WHBarcodes                           = True;
	StructureOfActions.CalculateSets                     = CalculateSets;
	
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject,
		"ProcessBarcodes",
		StructureOfActions);
	
	If Not AllTypesOfProducts Then
		BarcodingOfItemsClient.DefineConditionsForTypesOfBarcodeProcessingItems(StructureOfActions,
			ItemsTypes);
	EndIf;
	
	ProcessBarcodesServer(StructureOfActions, CachedValues);
	
	DataForProcessing = StructureOfActions;
	Attachable_AfterProcessingBarcodes();
	
EndProcedure

&AtServer
Procedure ProcessBarcodesServer(StructureOfActionParameters, CachedValues)
	
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject, ThisObject, StructureOfActionParameters, CachedValues);
	
	For Each TSRow In Goods Do
		TSRow.ThereIsDiscrepancy = ?(TSRow.NumberOfPackages = TSRow.NumberOfPackagesReal, 0, 1);
	EndDo;
	
	SetSelectionByDivergence();
	
EndProcedure

&AtClient
Procedure SearchByBarcodeCompletion(BarcodeData_1, AdditionalParameters) Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("StandardProcessing",    True);
	AdditionalParameters.Insert("BarcodeData_1",         BarcodeData_1);
	AdditionalParameters.Insert("CachedValues",    CachedValues);
	AdditionalParameters.Insert("ServerCallRequired__", False);
	
	FormEventsClient.WhenChangingElement(ThisObject, "GoodsSearchByBarcode", AdditionalParameters);
	
	If AdditionalParameters.ServerCallRequired__ Then
		BarcodeSearchCompletionOnServer(AdditionalParameters);
		FormEventsClient.WhenChangingElement(ThisObject, "CompleteBarcodeProcessing", AdditionalParameters);
	EndIf;
	
	If Not AdditionalParameters.StandardProcessing Then
		Return;
	
	EndIf;
	
	BarcodeData_5 = New Array;
	BarcodeData_5.Add(BarcodeData_1);
	ProcessBarcodes(BarcodeData_5);
	
EndProcedure

&AtServer
Procedure BarcodeSearchCompletionOnServer(AdditionalParameters)
	
	FormEvents.WhenChangingElement(ThisObject, "ProcessBarcodeData", AdditionalParameters);
	AfterProcessingBarcodes(AdditionalParameters);
	AdditionalParameters.BarcodeProcessingResult.AddedRows = New Array;
	AdditionalParameters.BarcodeProcessingResult.ModifiedRows  = New Array;
	
EndProcedure

&AtServer
Function ProcessingCodeMarkingPerformActionServer(Action, SelectionResult, BarcodeProcessingResult, ScanningParameters, CachedValues)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Action",                    Action);
	AdditionalParameters.Insert("SelectionResult",             SelectionResult);
	AdditionalParameters.Insert("BarcodeProcessingResult", BarcodeProcessingResult);
	AdditionalParameters.Insert("ScanningParameters",       ScanningParameters);
	AdditionalParameters.Insert("CachedValues",        CachedValues);
	
	FormEvents.WhenChangingElement(ThisObject, "ProcessingCodeMarkingPerformActionServer", AdditionalParameters);
	
	AfterProcessingBarcodes(AdditionalParameters);
	
	AdditionalParameters.BarcodeProcessingResult.ModifiedRows  = New Array;
	AdditionalParameters.BarcodeProcessingResult.AddedRows = New Array;
	
	Return AdditionalParameters.BarcodeProcessingResult;
	
EndFunction

&AtClient
Procedure Attachable_OpenDataClarificationForm()
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("DataForProcessing", DataForProcessing());
	
	FormEventsClient.WhenChangingElement(ThisObject, "Attachable_OpenDataClarificationForm", AdditionalParameters);
	
EndProcedure

&AtClient
Procedure Attachable_AfterProcessingBarcodes()
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(DataForProcessing, CachedValues, ThisObject);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("CachedValues", CachedValues);
	AdditionalParameters.Insert("DataForProcessing", DataForProcessing);
	AdditionalParameters.Insert("StandardProcessing", True);
	FormEventsClient.WhenChangingElement(ThisObject, "AfterProcessingBarcodes", AdditionalParameters);
	CachedValues = AdditionalParameters.CachedValues;
	
	If Not AdditionalParameters.StandardProcessing Then
		Return;
	EndIf;
	
	YouNeedToOpenFormForSpecifyingSeriesAfterProcessingBarcodes = BarcodingOfItemsClient.YouNeedToOpenFormForSpecifyingSeriesAfterProcessingBarcodes(DataForProcessing);
	
	If YouNeedToOpenFormForSpecifyingSeriesAfterProcessingBarcodes Then
		CurDataId = DataForProcessing.ArrayOfRowsWithSeries_[0];
		
		If CurDataId <> Undefined Then
			CurrentData = Goods.FindByID(CurDataId);
			
			OpenSelectionOfSeries(, CurrentData);
		EndIf;
	EndIf;
	
	DataForPerProcessing = DataForProcessing; // See BarcodingOfItemsClientServer.BarcodeProcessingParameters
	
	If DataForPerProcessing.CurrentRow <> Undefined Then
		Items.Goods.CurrentRow = DataForPerProcessing.CurrentRow;
	EndIf;
	
EndProcedure

&AtServer
Procedure Attachable_ProcessTSStrings(AddedRows, ModifiedRows, CachedValues = Undefined) Export
	
	StructureOfActionsWithAddedStrings = New Structure;
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_",
		New Structure("Products", "ItemsType"));
		
	StructureOfActionsWithAddedStrings.Insert("RecalculateNumberOfSuffixPacks", "Real");
	StructureOfActionsWithAddedStrings.Insert("CheckCharacteristicsByOwner");
	StructureOfActionsWithAddedStrings.Insert("CheckFillPackageByOwner");
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Products", StructureOfActionsWithAddedStrings);
	
	If SeriesSpecificationParameters <> Undefined Then
		StructureOfActionsWithAddedStrings.Insert("CheckSeriesCalculateStatus",
			New Structure("SeriesSpecificationParameters", SeriesSpecificationParameters));
	EndIf;
		
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		AddedRows,
		StructureOfActionsWithAddedStrings,
		Goods,
		CachedValues);
	
	For Each TSRow In AddedRows Do
		TSRow.ThereIsDiscrepancy = 1;
	EndDo;
	
	StructureOfActionsWithModifiedStrings = New Structure;
	StructureOfActionsWithModifiedStrings.Insert("RecalculateNumberOfSuffixPacks", "Real");
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ModifiedRows,
		StructureOfActionsWithModifiedStrings,
		Goods,
		CachedValues);
		
	For Each TSRow In ModifiedRows Do
		TSRow.ThereIsDiscrepancy = ?(TSRow.NumberOfPackages = TSRow.NumberOfPackagesReal, 0, 1);
	EndDo;
	
	If AddedRows.Count() > 0 Then
		Items.Goods.CurrentRow = AddedRows[AddedRows.Count() - 1].GetID();
	ElsIf ModifiedRows.Count() > 0 Then
		Items.Goods.CurrentRow = ModifiedRows[ModifiedRows.Count() - 1].GetID();
	EndIf;
	
	SetSelectionByDivergence();
	
EndProcedure

&AtServer
Procedure AfterProcessingBarcodes(AdditionalParameters)
	
	BarcodeProcessingResult = AdditionalParameters.BarcodeProcessingResult;
	CachedValues        = AdditionalParameters.CachedValues;
	
	If BarcodeProcessingResult.BarcodeProcessingRequired Then
		
		If TypeOf(BarcodeProcessingResult.RawData) = Type("Structure") Then
			BarcodeData_5 = New Array;
			BarcodeData_5.Add(BarcodeProcessingResult.RawData);
		Else
			BarcodeData_5 = BarcodeProcessingResult.RawData;
		EndIf;
		
		StructureOfActionsWithAddedStrings = New Structure;
		StructureOfActionsWithAddedStrings.Insert(
			"FillInProductTypeAttribute_",
			New Structure("Products", "ItemsType"));
		StructureOfActionsWithAddedStrings.Insert(
			"CheckFillWarehouse",
			New Structure("DefaultWarehouse, WarehouseGroup_", Warehouse, WarehouseGroup_));
		
		BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
			ThisObject,
			"Products",
			StructureOfActionsWithAddedStrings);
		
		StructureOfActionsWithModifiedStrings = New Structure;
		
		If SeriesSpecificationParameters <> Undefined Then
			StructureForCalculatingSeries = New Structure("Warehouse, SeriesSpecificationParameters",
														?(WarehouseGroup_,
															PredefinedValue("Catalog.Warehouses.EmptyRef"),
															Warehouse),
														SeriesSpecificationParameters);
			StructureOfActionsWithAddedStrings.Insert("CheckSeriesCalculateStatus", StructureForCalculatingSeries);
		EndIf;
		
		BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
			ThisObject,
			"ProductsUpdate",
			StructureOfActionsWithModifiedStrings);
		
		DataForProcessing = BarcodingOfItemsClientServer.BarcodeProcessingParameters();
		DataForProcessing.Barcodes                              = BarcodeData_5;
		DataForProcessing.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
		DataForProcessing.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
		DataForProcessing.SeriesSpecificationParameters                 = SeriesSpecificationParameters;
		DataForProcessing.ColumnNameQuantity                   = "NumberOfPackagesReal";
		DataForProcessing.NotUsePackages                 = NotUsePackages;
		DataForProcessing.BlockFormData                 = False;
		DataForProcessing.WHBarcodes                           = True;
		
		BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
			ThisObject,
			"ProcessBarcodes",
			DataForProcessing);
		
		If Not AllTypesOfProducts Then
			BarcodingOfItemsServer.DefineConditionsForTypesOfBarcodeProcessingItems(DataForProcessing,
				ItemsTypes);
		EndIf;
		
		ProcessBarcodesServer(DataForProcessing, CachedValues);
		
	Else
		
		Attachable_ProcessTSStrings(
			BarcodeProcessingResult.AddedRows,
			BarcodeProcessingResult.ModifiedRows,
			CachedValues);
		
	EndIf;
	
	FillInServiceDetailsForProductRange();
	
EndProcedure

// Returns:
// 	See BarcodingOfItemsClientServer.BarcodeProcessingParameters
&AtClient
Function DataForProcessing()
	
	Return DataForProcessing;
	
EndFunction

#EndRegion

#Region Other

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	UserAnswer = QuestionResult;
	If UserAnswer = DialogReturnCode.Yes Then
		Cancel(Undefined);
	EndIf;
	
EndProcedure

&AtServer
Function Analysis()
	
	Query = New Query(
	"SELECT
	|	Table.RowCode              AS RowCode,
	|	Table.RowID    AS RowID,
	|	Table.SalesOrder           AS SalesOrder,
	|	Table.ProductsInSet     AS ProductsInSet,
	|	Table.ItemVariantOfSet   AS ItemVariantOfSet,
	|	Table.Products           AS Products,
	|	Table.Characteristic         AS Characteristic,
	|	Table.Package               AS Package,
	|	Table.NumberOfPackagesReal AS NumberOfPackagesReal,
	|	Table.NumberOfPackages     AS NumberOfPackages
	|INTO _SetComposition
	|FROM
	|	&Table AS Table
	|WHERE Table.RowCode = 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductKitConfigurations.Ref AS ItemKitConfiguration,
	|	ProductKitConfigurations.SetPricingOption AS SetPricingOption,
	|	Table.RowCode            AS RowCode,
	|	Table.RowID  AS RowID,
	|	Table.SalesOrder         AS SalesOrder,
	|	Table.ProductsInSet   AS ProductsInSet,
	|	Table.ItemVariantOfSet AS ItemVariantOfSet,
	|	Table.Products         AS Products,
	|	Table.Characteristic       AS Characteristic,
	|	Table.Package             AS Package,
	|	Table.NumberOfPackagesReal   AS NumberOfPackagesReal,
	|	Table.NumberOfPackages       AS NumberOfPackages
	|INTO SetComposition
	|FROM
	|	_SetComposition AS Table
	|
	|	LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|		ON ProductKitConfigurations.Owner = Table.ProductsInSet
	|		AND ProductKitConfigurations.Characteristic = Table.ItemVariantOfSet
	|		AND ProductKitConfigurations.Main
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ConfigurationOptionsForProductRange.Ref                          AS ItemKitConfiguration,
	|	ConfigurationOptionsForProductRange.Ref.SetPricingOption AS SetPricingOption,
	|	0                                                            AS RowCode,
	|	""""                                                         AS RowID,
	|	UNDEFINED                                                 AS SalesOrder,
	|	ConfigurationOptionsForProductRange.Ref.Owner       AS ProductsInSet,
	|	ConfigurationOptionsForProductRange.Ref.Characteristic AS ItemVariantOfSet,
	|	ConfigurationOptionsForProductRange.Products          AS Products,
	|	ConfigurationOptionsForProductRange.Characteristic        AS Characteristic,
	|	ConfigurationOptionsForProductRange.Package                  AS Package,
	|	SUM(ConfigurationOptionsForProductRange.NumberOfPackages) AS DefaultNumberOfPackages,
	|	SUM(0) AS NumberOfPackagesReal,
	|	SUM(0) AS NumberOfPackages
	|INTO Table
	|FROM
	|	Catalog.ProductKitConfigurations.Goods AS ConfigurationOptionsForProductRange
	|WHERE
	|	ConfigurationOptionsForProductRange.Ref IN (SELECT DISTINCT T.ItemKitConfiguration FROM SetComposition AS T)
	|	AND (ConfigurationOptionsForProductRange.Ref.SetPricingOption IN (VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToPrices),
	|                                                                               VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares))
	|	OR (ConfigurationOptionsForProductRange.Ref.ProductsOfMainComponent = ConfigurationOptionsForProductRange.Products AND ConfigurationOptionsForProductRange.Ref.MainComponentCharacteristic = ConfigurationOptionsForProductRange.Characteristic))
	|
	|GROUP BY
	|	ConfigurationOptionsForProductRange.Ref,
	|	ConfigurationOptionsForProductRange.Ref.SetPricingOption,
	|	0,
	|	ConfigurationOptionsForProductRange.Ref.Owner,
	|	ConfigurationOptionsForProductRange.Ref.Characteristic,
	|	ConfigurationOptionsForProductRange.Products,
	|	ConfigurationOptionsForProductRange.Characteristic,
	|	ConfigurationOptionsForProductRange.Package
	|
	|UNION ALL
	|
	|SELECT
	|	Table.ItemKitConfiguration,
	|	Table.SetPricingOption,
	|	Table.RowCode,
	|	Table.RowID,
	|	Table.SalesOrder,
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet,
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.Package,
	|	0,
	|	Table.NumberOfPackagesReal,
	|	Table.NumberOfPackages
	|FROM
	|	SetComposition AS Table
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.SetPricingOption,
	|	Table.RowCode,
	|	Table.RowID,
	|	Table.SalesOrder,
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet,
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.Package,
	|	SUM(Table.DefaultNumberOfPackages) AS DefaultNumberOfPackages,
	|	SUM(Table.NumberOfPackagesReal) AS NumberOfPackagesReal,
	|	SUM(Table.NumberOfPackages) AS NumberOfPackages
	|INTO Result
	|FROM
	|	Table AS Table
	|
	|GROUP BY
	|	Table.SetPricingOption,
	|	Table.RowCode,
	|	Table.RowID,
	|	Table.SalesOrder,
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet,
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.Package
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Result.RowCode,
	|	Result.RowID,
	|	Result.SalesOrder,
	|	Result.SetPricingOption,
	|	Result.ProductsInSet,
	|	Result.ItemVariantOfSet,
	|	CAST(MIN(CASE
	|			WHEN Result.DefaultNumberOfPackages <> 0
	|				THEN Result.NumberOfPackages / Result.DefaultNumberOfPackages
	|			ELSE null
	|		END) + 0.5 AS NUMBER(10,0)) - 1 AS MinimumQuantity,
	|	CAST(MIN(CASE
	|			WHEN Result.DefaultNumberOfPackages <> 0
	|				THEN Result.NumberOfPackagesReal / Result.DefaultNumberOfPackages
	|			ELSE null
	|		END) + 0.5 AS NUMBER(10,0)) - 1 AS MinimumQuantityFact
	|INTO Coefficients
	|FROM
	|	Result AS Result
	|GROUP BY
	|	Result.RowCode,
	|	Result.RowID,
	|	Result.SalesOrder,
	|	Result.SetPricingOption,
	|	Result.ProductsInSet,
	|	Result.ItemVariantOfSet
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.SetPricingOption,
	|	Table.RowCode,
	|	Table.RowID,
	|	Table.SalesOrder,
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet,
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.Package,
	|	Table.DefaultNumberOfPackages,
	|	Table.NumberOfPackages,
	|	ISNULL(Coefficients.MinimumQuantity, 1) * Table.DefaultNumberOfPackages AS NumberOfPackagesFullSet,
	|	ISNULL(Coefficients.MinimumQuantityFact, 1) * Table.DefaultNumberOfPackages AS NumberOfPackagesIsCompleteSet,
	|	Table.NumberOfPackagesReal - ISNULL(Coefficients.MinimumQuantityFact, 1) * Table.DefaultNumberOfPackages AS Difference
	|FROM
	|	Result AS Table
	|		LEFT JOIN Coefficients AS Coefficients
	|		ON Coefficients.ProductsInSet = Table.ProductsInSet
	|		 AND Coefficients.ItemVariantOfSet = Table.ItemVariantOfSet
	|		 AND Coefficients.RowCode = Table.RowCode
	|		 AND Coefficients.RowID = Table.RowID
	|		 AND Coefficients.SalesOrder = Table.SalesOrder
	|WHERE
	|	Table.SetPricingOption IN (VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToPrices),
	|                                       VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares))
	|	OR Coefficients.MinimumQuantityFact = 0 
	|;
	|SELECT
	|	Coefficients.RowCode,
	|	Coefficients.RowID,
	|	Coefficients.SalesOrder,
	|	Coefficients.SetPricingOption,
	|	Coefficients.ProductsInSet,
	|	Coefficients.ItemVariantOfSet,
	|	Coefficients.MinimumQuantity,
	|	Coefficients.MinimumQuantityFact
	|FROM
	|	Coefficients AS Coefficients
	|WHERE
	|	Coefficients.SetPricingOption IN (VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToPrices),
	|                                            VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares))
	|	OR Coefficients.MinimumQuantityFact = 0 
	|");
	
	Query.SetParameter("Table", Goods.Unload());
	RequestResultPackage = Query.ExecuteBatch();
	
	ReturnValue = New Structure;
	ReturnValue.Insert("SetCoefficients", RequestResultPackage[RequestResultPackage.Count() - 1].Unload());
	ReturnValue.Insert("DataBySets",     RequestResultPackage[RequestResultPackage.Count() - 2].Unload());
	
	Return ReturnValue;
	
EndFunction

&AtServer
Procedure AnalysisOfSets()
	
	AnalysisResult = Analysis();
	
	DataBySets = AnalysisResult.DataBySets;
	
	For Each TSRow In Goods Do
		
		TSRow.NumberOfPackagesFactTotal = TSRow.NumberOfPackagesReal;
		
		SelectionOfSets = New Structure;
		SelectionOfSets.Insert("ProductsInSet", TSRow.ProductsInSet);
		SelectionOfSets.Insert("ItemVariantOfSet", TSRow.ItemVariantOfSet);
		FoundInAnalysis = DataBySets.FindRows(SelectionOfSets).Count() > 0;
		
		If ValueIsFilled(TSRow.ProductsInSet) And FoundInAnalysis Then
			
			Filter = New Structure;
			Filter.Insert("RowID");
			Filter.Insert("RowCode");
			Filter.Insert("SalesOrder");
			Filter.Insert("ProductsInSet");
			Filter.Insert("ItemVariantOfSet");
			Filter.Insert("Products");
			Filter.Insert("Characteristic");
			Filter.Insert("Package");
			FillPropertyValues(Filter, TSRow);
			FoundRows = DataBySets.FindRows(Filter);
			If FoundRows.Count() > 0 Then
				
				NumberOfPackagesReal           = 0;
				NumberOfPackagesFactDeviation = 0;
				For Each FoundRow In FoundRows Do
					NumberOfPackagesFactDeviation = NumberOfPackagesFactDeviation + FoundRow.Difference;
					NumberOfPackagesReal = NumberOfPackagesReal + FoundRow.NumberOfPackagesIsCompleteSet;
				EndDo;
				TSRow.NumberOfPackagesFactTotal = NumberOfPackagesReal;
				
				If NumberOfPackagesFactDeviation <> 0 Then
					NewRow = ProductsUnlinkedFromTheSet.Add();
					FillPropertyValues(NewRow, TSRow);
					NewRow.NumberOfPackages = NumberOfPackagesFactDeviation;
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Function FinishCheckingOnServer()
	
	// Creating an empty table of Products
	GoodsTable = ProductsUnlinkedFromTheSet.Unload(New Structure("Products", Catalogs.Products.EmptyRef())).CopyColumns();
	
	ArrayOfRowsNewProducts = New Array;
	ArrayOfMissingRows   = New Array;
	ArrayOfExcessRows     = New Array;
	
	For Each TSRow In ProductsUnlinkedFromTheSet Do
		NewRow = Goods.Add();
		FillPropertyValues(NewRow, TSRow,,"NumberOfPackages,ProductsInSet, ItemVariantOfSet, SetIndex");
		NewRow.NumberOfPackagesReal = TSRow.NumberOfPackages;
		NewRow.NumberOfPackagesFactTotal = TSRow.NumberOfPackages;
	EndDo;
	
	For Each TSRow In Goods Do
		
		If TSRow.NumberOfPackages = TSRow.NumberOfPackagesFactTotal Then
			// There are no discrepancies
		ElsIf TSRow.NumberOfPackages = 0 And TSRow.NumberOfPackagesFactTotal > 0 Then
			// New product
			ArrayOfRowsNewProducts.Add(TSRow);
		ElsIf TSRow.NumberOfPackages > TSRow.NumberOfPackagesFactTotal Then
			// Shortage_
			ArrayOfMissingRows.Add(TSRow);
		ElsIf TSRow.NumberOfPackages < TSRow.NumberOfPackagesFactTotal Then
			// Surplus
			ArrayOfExcessRows.Add(TSRow);
		EndIf;
		
	EndDo;
	
	ExceedingIsProhibited = False;
	If GoodsQuantityExcessIsAllowed Then
		For Each TSRow In ArrayOfRowsNewProducts Do
			NewRow = GoodsTable.Add();
			FillPropertyValues(NewRow, TSRow, , "NumberOfPackages");
			NewRow.NumberOfPackages = TSRow.NumberOfPackagesFactTotal - TSRow.NumberOfPackages;
		EndDo;
		For Each TSRow In ArrayOfExcessRows Do
			NewRow = GoodsTable.Add();
			FillPropertyValues(NewRow, TSRow, , "NumberOfPackages");
			NewRow.NumberOfPackages = TSRow.NumberOfPackagesFactTotal - TSRow.NumberOfPackages;
		EndDo;
		
	ElsIf ValueIsFilled(ArrayOfExcessRows) Then
		ExceedingIsProhibited = True;
	EndIf;
	
	For Each TSRow In ArrayOfMissingRows Do
		NewRow = GoodsTable.Add();
		FillPropertyValues(NewRow, TSRow, , "NumberOfPackages");
		NewRow.NumberOfPackages = TSRow.NumberOfPackagesFactTotal - TSRow.NumberOfPackages;
	EndDo;
	
	AddressInTempStorage = PutToTempStorage(GoodsTable, AddressInTempStorage);
	
	ClosingParameters = New Structure;
	ClosingParameters.Insert("Goods",				AddressInTempStorage);
	ClosingParameters.Insert("ExceedingIsProhibited",	ExceedingIsProhibited);
	
	FormEvents.WhenChangingElement(ThisObject, "FinishCheck", ClosingParameters);
	
	Return ClosingParameters;
	
EndFunction

&AtServerNoContext
Function ItIsGroupOfWarehousesAndWarehousesUsedByWHForSale(Warehouse)
	
	Return Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWHForSales(Warehouse);
	
EndFunction

&AtServer
Procedure SetSelectionByDivergence()
	If OnlyDiscrepancies Then
		Items.Goods.RowFilter = New FixedStructure("ThereIsDiscrepancy", 1);
	Else
		Items.Goods.RowFilter = Undefined;
	EndIf;
EndProcedure

&AtServer
Procedure FillInServiceDetailsForProductRange()
	
	TableOfGoods = Goods.Unload();
	TableOfGoods.Columns.Add("LineNumber", New TypeDescription("Number"));
	
	For Each TableRow In TableOfGoods Do
		TableRow.LineNumber = TableOfGoods.IndexOf(TableRow) + 1;
	EndDo;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute",      New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_",                 New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillPackageWeight",New Structure("Products, Package", "PackageWeight"));
	StructureOfActions.Insert("FillPackageVolume",New Structure("Products, Package", "PackageVolume"));
	StructureOfActions.Insert("FillInUnitOfWeight",New Structure("Products, Package", "UnitOfMeasureForWeight"));
	StructureOfActions.Insert("FillInVolumeUnit",New Structure("Products, Package", "UnitOfMeasureForVolume"));
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Products_2", StructureOfActions);
	ProductsServer.FillInServiceDetailsForProductInCollection(TableOfGoods, StructureOfActions);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateWeightVolume", "Real");
	
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
	
	SetsServer.FillInServiceDetails(ThisObject, "Goods", True);
	
	BatchProcessingOfTablePartServerLocalization.FillInServiceDetails(ThisObject);
	
EndProcedure

&AtClient
Procedure ProcessingResponseToQuestion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = "MoveTo_" Then
		ClosingProcessing = True;
		Close(FinishCheckingOnServer());
	ElsIf QuestionResult = "NoWrap" Then 
		ClosingProcessing = True;
		Close(Undefined);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions)
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateWeightVolume", "Real");
	
EndProcedure

#EndRegion

#EndRegion

#Region Initialize

ClosingProcessing = True;

#EndRegion
