
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	Filter = "Modified1";
	
	Device             = Parameters.Device;
	
	DeviceParameters = OfflinePeripheralsServerCall.GetDeviceParameters(Device);
	
	EquipmentType        = DeviceParameters.EquipmentType;
	InfobaseNode = DeviceParameters.InfobaseNode;
	MaximumGoodsQuantity        = DeviceParameters.MaximumGoodsQuantity;
	
	ExchangeRule          = Parameters.ExchangeRule;
	
	UseItemsBatch = GetFunctionalOption("UseItemsBatchWarehouse", New Structure("Warehouse", DeviceParameters.Warehouse));
	If UseItemsBatch Then
		Items.GoodsTextYouNeedToSpecifyTheSeries.Visible = True;
	EndIf;
	
	OfflinePeripheralsServerCall.UpdateProductCodes(ExchangeRule);
	
	SelectionWhenChangingOnServer();
	
	If Not ValueIsFilled(InfobaseNode) Then
		Items.GoodsRegisterChanges.Visible                = False;
		Items.ProductsContextMenuToRegisterTheChange.Visible = False;
	EndIf;
	
	Items.GoodsPrintLabelsForTheSelectedRows.Visible = AccessRight("View", Metadata.DataProcessors.PrintPriceTagsAndLabels);
	
	Title = "Goods" + " " + NStr("vi = 'đối với';
								|ru = 'для';
								|en = 'for'; fa = 'برای';
								|it = 'per';
								|pl = 'dla';
								|tr = 'için'") + " " + Device;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterOnChange(Item)
	
	Status(NStr("vi = 'Đang cập nhật bảng hàng hóa...';
				|ru = 'Выполняется обновление таблицы товаров...';
				|en = 'Updating goods table...'; fa = 'Updating goods table...';
				|it = 'Aggiornamento della tabella delle merci in corso...';
				|pl = 'Aktualizacja tabeli towarów w toku...';
				|tr = 'Ürün tablosu güncelleniyor...'"));
	
	SelectionWhenChangingOnServer();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	RowSelected = Goods.FindByID(RowSelected);
	If RowSelected <> Undefined Then
		ShowValue(Undefined, RowSelected.Products);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure RecordChanges(Command)
	
	ErrorDescription = "";
	ArrayOfCodes = New Array;
	RowsArray = New Array;
	
	For Each SelectedRow In Items.Goods.SelectedRows Do
		FoundRow = Goods.FindByID(SelectedRow);
		RowsArray.Add(FoundRow);
		ArrayOfCodes.Add(FoundRow.Code);
	EndDo;
	
	If ArrayOfCodes.Count() > 0 Then
		Result = RegisterChangesOnServer(ArrayOfCodes);
		If Result Then
			For Each TSRow In RowsArray Do
				TSRow.PictureIndexIsChanges = 1;
			EndDo;
			Notify("Recording_ProductCodesForConnectedEquipment", New Structure, Undefined);
		Else
			ShowMessageBox(
				Undefined, 
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Trong quá trình ghi nhận thay đổi, đã xảy ra lỗi: %1';
						|ru = 'В процессе регистрации изменений произошла ошибка: %1';
						|en = 'An error occurred when registering changes: %1'; fa = 'An error occurred when registering changes: %1';
						|it = 'В процессе регистрации изменений произошла ошибка: %1';
						|pl = 'An error occurred when registering changes: %1';
						|tr = 'Değişiklik kaydı sırasında hata oluştu: %1'"),
					ErrorDescription));
		EndIf;
	Else
		ShowMessageBox(Undefined, NStr("vi = 'Chưa chọn dòng để ghi nhận thay đổi';
										|ru = 'Не выбраны строки для регистрации изменений';
										|en = 'Rows for change registration are not selected'; fa = 'Rows for change registration are not selected';
										|it = 'Non sono state selezionate le righe per registrare le modifiche';
										|pl = 'Nie wybrano żadnych wierszy do rejestracji zmian';
										|tr = 'Değişiklik kaydı sırasında hata oluştu'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsClear(Command)
	
	Devices = New Array;
	Devices.Add(Device);
	
	
	If EquipmentType = PredefinedValue("Enum.PeripheralTypes.LabelPrintingScales") Then
		OfflinePeripheralsClient.ClearGoodsInLibra(
			New CallbackDescription("ExchangeIsCompleted", ThisObject),
			Devices, False);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsReimport(Command)
	
	Devices = New Array;
	Devices.Add(Device);
	
	
	If EquipmentType = PredefinedValue("Enum.PeripheralTypes.LabelPrintingScales") Then
		OfflinePeripheralsClient.UploadFullListOfProductsToLibra(
			New CallbackDescription("ExchangeIsCompleted", ThisObject),
			Devices, False);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsExport(Command)
	
	Devices = New Array;
	Devices.Add(Device);
	
	
	If EquipmentType = PredefinedValue("Enum.PeripheralTypes.LabelPrintingScales") Then
		OfflinePeripheralsClient.ExportGoodsToScales(
			New CallbackDescription("ExchangeIsCompleted", ThisObject),
			Devices, False);
	EndIf;
	
EndProcedure

&AtClient
Procedure PrintingPriceTags(Command)
	
	EquipmentManagerClient.UpdateClientWorkplace();
	AddressInStorage = DataForPrintingPriceTags();
	If AddressInStorage <> Undefined Then
	
		ParametersStructure1 = New Structure("AddressInStorage", AddressInStorage);
		OpenForm(
			"DataProcessor.PrintPriceTagsAndLabels.Form.FormGoods",
			ParametersStructure1,            // Parameters
			,                              // Owner
			New UUID); // Uniqueness
	
	EndIf;

EndProcedure

&AtClient
Procedure PrintGoodsCodes(Command)
	
	ObjectsArray = New Array;
	ObjectsArray.Add(ExchangeRule);
	PrintManagementClient.ExecutePrintCommand(
		"Catalog.RulesOfExchangeWithOfflinePeripherals",
		"GoodsCodes",
		ObjectsArray,
		Undefined,
		Undefined);
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	SelectionWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure DeleteChangeRegistrationForTheSelectedRows(Command)
	
	ErrorDescription = "";
	RowsArray = New Array;
	ArrayOfCodes = New Array;
	
	For Each SelectedRow In Items.Goods.SelectedRows Do
		FoundRow = Goods.FindByID(SelectedRow);
		RowsArray.Add(FoundRow);
		ArrayOfCodes.Add(FoundRow.Code);
	EndDo;
	
	If ArrayOfCodes.Count() > 0 Then
		Result = RemoveRegistrationOfChangesOnServer(ArrayOfCodes);
		If Result Then
			For Each TSRow In RowsArray Do
				TSRow.PictureIndexIsChanges = 0;
			EndDo;
			Notify("Recording_ProductCodesForConnectedEquipment", New Structure, Undefined);
		Else
			ShowMessageBox(
				Undefined,
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Trong quá trình xóa ghi nhận thay đổi, đã xảy ra lỗi: %1';
						|ru = 'В процессе удаления регистрации изменений произошла ошибка: %1';
						|en = 'An error occurred when deleting the change registration: %1'; fa = 'An error occurred when deleting the change registration: %1';
						|it = 'В процессе удаления регистрации изменений произошла ошибка: %1';
						|pl = 'An error occurred when deleting the change registration: %1';
						|tr = 'Değişiklik kaydının silinmesi sırasında hata oluştu: %1'"),
					ErrorDescription)); 
		EndIf;
	Else
		ShowMessageBox(Undefined, NStr("vi = 'Chưa chọn dòng để xóa ghi nhận thay đổi';
										|ru = 'Не выбраны строки для удаления регистрации изменений';
										|en = 'Rows for change registration deletion are not selected'; fa = 'Rows for change registration deletion are not selected';
										|it = 'Non sono state selezionate le righe eliminare le registrazioni delle modifiche';
										|pl = 'Nie wybrano żadnych wierszy do usunięcia zmian';
										|tr = 'Değişiklik kayıt silme için satırlar seçili değil'"));
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsBarcode.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Goods.Barcode");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Goods.Used");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("EquipmentType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.PeripheralTypes.LabelPrintingScales;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<sẽ khởi tạo mã vạch khi kết xuất>';
													|ru = '<штрихкод будет сгенерирован при выгрузке>';
													|en = '<barcode will be generated during exporting>'; fa = '<barcode will be generated during exporting>';
													|it = '<il codice a barre verrà generato durante l''importazione>';
													|pl = '<kod kreskowy zostanie wygenerowany po wyeksportowaniu>';
													|tr = '<barkod yükleme sırasında oluşturulacaktır>'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPrice.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Goods.Price");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Goods.Used");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ErrorNoteText);
	Item.Appearance.SetParameterValue("HorizontalAlign", HorizontalAlign.Left);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Chưa đặt đơn giá>';
													|ru = '<Не задана цена>';
													|en = '<Price not defined>'; fa = '<Price not defined>';
													|it = '<Prezzo non impostato>';
													|pl = '<Cena nie została ustalona>';
													|tr = '<Fiyat ayarlanmadı>'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDescription.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Goods.Description");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Goods.Used");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ErrorNoteText);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Tên không được chỉ định>';
													|ru = '<Не задано наименование>';
													|en = '<Description not defined>'; fa = '<Description not defined>';
													|it = '<Nome non impostato>';
													|pl = '<Nazwa nie została ustalona>';
													|tr = '<Tanım ayarlanmadı>'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCode.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Goods.Code");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = New DataCompositionField("MaximumGoodsQuantity");

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("MaximumGoodsQuantity");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ErrorNoteText);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Goods.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Goods.Used");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsTextYouNeedToSpecifyTheSeries.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Goods.SeriesIndicationIsRequired");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Goods.Used");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.ErrorNoteText);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Dành cho mặt hàng cần chỉ ra sê-ri khi giao hàng khi bán lẻ từ kho này>';
													|ru = '<Для товара требуется указание серий при отгрузке в розницу с данного склада>';
													|en = '<You need to specify batch of the goods on shipment to retail from this warehouse>'; fa = '<You need to specify batch of the goods on shipment to retail from this warehouse>';
													|it = '<È necessario indicare le serie quando la merce per la vendita al dettaglio viene spedita da questo magazzino>';
													|pl = '<Towar wymaga oznaczenia serii podczas wysyłki detalicznej z tego magazynu>';
													|tr = '<Bu ambardan perakendeye gönderilirken ürünler için parti belirtilmesi gereklidir>'"));

EndProcedure

#Region OnChangeAttributes

&AtServer
Procedure SelectionWhenChangingOnServer()
	
	ExportingParameters = OfflinePeripheralsServerCall.GetDeviceParameters(Device);
	
	If Filter = "Modified1" Then
		ExportingParameters.Insert("PartialUnloading", True);
		Table = OfflinePeripheralsServerCall.ProductDataToUpload(Device, ExportingParameters);
	ElsIf Filter = "WithErrors" Then
		ExportingParameters.Insert("PartialUnloading", False);
		Table = OfflinePeripheralsServerCall.ProductDataToUpload(Device, ExportingParameters).Copy(New Structure("HasErrors", True));
	Else
		ExportingParameters.Insert("PartialUnloading", False);
		Table = OfflinePeripheralsServerCall.ProductDataToUpload(Device, ExportingParameters);
	EndIf;
	
	If Table <> Undefined Then
		Goods.Load(Table);
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Function DataForPrintingPriceTags()
	
	Query = New Query;
	
	QueryText =
	"SELECT TOP 1
	|	ISNULL(CatalogPeripherals.ExchangeRule.Warehouse, UNDEFINED) AS Warehouse,
	|	ISNULL(CashRegisters.CashRegister.Owner, UNDEFINED) AS Organization,
	|	ISNULL(CatalogPeripherals.ExchangeRule.Warehouse.RetailPriceType, UNDEFINED) AS PriceKind
	|FROM
	|	Catalog.Peripherals AS CatalogPeripherals
	|		LEFT JOIN Catalog.CWPSettings.CashRegisters AS CashRegisters
	|		ON CashRegisters.Peripherals = CatalogPeripherals.Ref
	|		 AND CashRegisters.Ref.Workplace = &Workplace
	|WHERE
	|	CatalogPeripherals.Ref = &Device";
	
	
	Query.Text = QueryText;
	Query.SetParameter("Device", Device);
	Query.SetParameter("Workplace", EquipmentManagerServerCall.GetClientSWorkplace());
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	If Not Selection.Next() Then
		Return Undefined;
	EndIf;
	
	GoodsTable = New ValueTable;
	GoodsTable.Columns.Add("Products",   New TypeDescription("CatalogRef.Products"));
	GoodsTable.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	GoodsTable.Columns.Add("Series",          New TypeDescription("CatalogRef.ItemsBatches"));
	GoodsTable.Columns.Add("Package",       New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	GoodsTable.Columns.Add("Count",     New TypeDescription("Number"));
	GoodsTable.Columns.Add("Order",        New TypeDescription("Number"));
	
	IndexOf = 1;
	For Each SelectedRow In Items.Goods.SelectedRows Do
		
		TSRow = Goods.FindByID(SelectedRow);
		
		NewRow = GoodsTable.Add();
		NewRow.Products   = TSRow.Products;
		NewRow.Characteristic = TSRow.Characteristic;
		NewRow.Package       = TSRow.Package;
		NewRow.Count     = 1;
		NewRow.Order        = IndexOf;
		
		IndexOf = IndexOf + 1;
		
	EndDo;
	
	// Preparation of the action structure for processing the printing of price tags and labels
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInOrganization",   Selection.Organization);
	StructureOfActions.Insert("FillInTheWarehouse",         Selection.Warehouse);
	StructureOfActions.Insert("FillInPriceView",       Selection.PriceKind);
	StructureOfActions.Insert("FillInExchangeRule", ExchangeRule);
	StructureOfActions.Insert("ShowQuantityColumnInDocument", True);
	StructureOfActions.Insert("SetPrintModeFromDocument");
	StructureOfActions.Insert("SetMode", "PrintingPriceTags");
	StructureOfActions.Insert("FillInTheNumberOfPriceTagsForTheDocument");
	StructureOfActions.Insert("FillInTheGoodsTable");
	
	// Preparation of data for filling in the tabular part of the processing of printing price tags and labels.
	ResultingStructure = New Structure;
	ResultingStructure.Insert("Goods", GoodsTable);
	ResultingStructure.Insert("StructureOfActions", StructureOfActions);
	
	Return PutToTempStorage(ResultingStructure, New UUID());
	
EndFunction

&AtServer
Function RegisterChangesOnServer(ArrayOfCodes, ErrorDescription = "")
	
	ReturnValue = True;
	
	BeginTransaction();
	Try
		
		Set = InformationRegisters.ItemsIDOfPeripheralsOffline.CreateRecordSet();
		For Each Code In ArrayOfCodes Do
			
			Set.Filter.ExchangeRule.Value = ExchangeRule;
			Set.Filter.ExchangeRule.Use = True;
			
			Set.Filter.Code.Value = Code;
			Set.Filter.Code.Use = True;
			
			ExchangePlans.RecordChanges(InfobaseNode, Set);
			
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		WriteLogEvent(NStr("vi = 'Bán lẻ';
							|ru = 'Розничные продажи';
							|en = 'Retail sales'; fa = 'فروش خرده‌فروشی';
							|it = 'Vendite al dettaglio';
							|pl = 'Sprzedaże detaliczne';
							|tr = 'Perakende satışlar'", CommonClientServer.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			DetailErrorDescription(ErrorInfo()));
		
		ReturnValue = False;
		ErrorDescription = ErrorInfo().Description;
		
	EndTry;
	
	Return ReturnValue;
	
EndFunction

&AtServer
Function RemoveRegistrationOfChangesOnServer(ArrayOfCodes, ErrorDescription = "")
	
	ReturnValue = True;
	
	BeginTransaction();
	Try
		
		Set = InformationRegisters.ItemsIDOfPeripheralsOffline.CreateRecordSet();
		For Each Code In ArrayOfCodes Do
			
			Set.Filter.ExchangeRule.Value = ExchangeRule;
			Set.Filter.ExchangeRule.Use = True;
			
			Set.Filter.Code.Value = Code;
			Set.Filter.Code.Use = True;
			
			ExchangePlans.DeleteChangeRecords(InfobaseNode, Set);
			
		EndDo;
		
		If Filter = "Modified1" Then
			SelectionWhenChangingOnServer();
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		WriteLogEvent(NStr("vi = 'Bán lẻ';
							|ru = 'Розничные продажи';
							|en = 'Retail sales'; fa = 'فروش خرده‌فروشی';
							|it = 'Vendite al dettaglio';
							|pl = 'Sprzedaże detaliczne';
							|tr = 'Perakende satışlar'", CommonClientServer.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			DetailErrorDescription(ErrorInfo()));
		
		ReturnValue = False;
		ErrorDescription = ErrorInfo().Description;
		
	EndTry;
	
	Return ReturnValue;
	
EndFunction

&AtClient
Procedure ExchangeIsCompleted(ReturnValue, AdditionalParameters) Export
	
	ClearMessages();
	If ReturnValue.Property("Result") And Not ReturnValue.Result Then
		CommonClientServer.MessageToUser(ReturnValue.ErrorDescription);
	ElsIf Not ReturnValue.Property("Result") And ReturnValue.Completed2 <> ReturnValue.Required2Execute Then
		CommonClientServer.MessageToUser(ReturnValue.MessageText);
	ElsIf Not ReturnValue.Property("Result") And ReturnValue.Completed2 = ReturnValue.Required2Execute Then
		CommonClientServer.MessageToUser(NStr("vi = 'Đã kết xuất thành công dữ liệu';
												|ru = 'Данные успешно выгружены';
												|en = 'Data is exported successfully'; fa = 'Data is exported successfully';
												|it = 'I dati sono stati caricati correttamente';
												|pl = 'Dane zostały pomyślnie przesłane';
												|tr = 'Veri başarıyla dışa aktarıldı'"));
	Else
		
		If TypeOf(AdditionalParameters) = Type("Structure") 
			And AdditionalParameters.Property("ThisIsDownload") Then

			MessageText = ?(ReturnValue.Result, NStr("vi = 'Đã kết nhập thành công dữ liệu';
													|ru = 'Данные успешно загружены';
													|en = 'Data imported successfully'; fa = 'داده‌ها با موفقیت وارد شدند';
													|it = 'I dati sono stati caricati correttamente';
													|pl = 'Dane pobrane pomyślnie';
													|tr = 'Veri başarıyla içe aktarıldı'"), NStr("vi = 'Khi kết nhập dữ liệu, đã xảy ra lỗi';
																								|ru = 'При загрузке данных произошла ошибка';
																								|en = 'An error occurred when importing data'; fa = 'An error occurred when importing data';
																								|it = 'Durante il download dei dati si è verificato un errore';
																								|pl = 'Podczas pobierania danych wystąpił błąd';
																								|tr = 'Veriler içe aktarılırken hata oluştu'"));
		Else
			MessageText = ?(ReturnValue.Result, NStr("vi = 'Đã kết xuất thành công dữ liệu';
													|ru = 'Данные успешно выгружены';
													|en = 'Data is exported successfully'; fa = 'Data is exported successfully';
													|it = 'I dati sono stati caricati correttamente';
													|pl = 'Dane zostały pomyślnie przesłane';
													|tr = 'Veri başarıyla dışa aktarıldı'"), NStr("vi = 'Khi kết xuất dữ liệu, đã xảy ra lỗi';
																									|ru = 'При выгрузке данных произошла ошибка';
																									|en = 'An error occurred while exporting data'; fa = 'An error occurred while exporting data';
																									|it = 'Durante l''upload dei dati si è verificato un errore';
																									|pl = 'Podczas eksportowania danych wystąpił błąd';
																									|tr = 'Veriler dışa aktarılırken hata oluştu'"));
		EndIf;
		
		If ReturnValue.Property("ErrorDescription") And Not IsBlankString(ReturnValue.ErrorDescription) Then
			CommonClientServer.MessageToUser(ReturnValue.ErrorDescription);
		Else
			CommonClientServer.MessageToUser(MessageText);
		EndIf;
		
	EndIf;
	
	Notify("Write_RulesOfExchangeWithOfflinePeripherals", New Structure, Undefined);
	SelectionWhenChangingOnServer();
	
EndProcedure

#EndRegion

#EndRegion
