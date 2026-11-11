#Region Public

// This procedure is called when clearing products in the device.
// Writes information to the exchange plan node.
//
// Parameters:
//  Device       - CatalogRef.Peripherals - Link to the device.
//  ExecutedSuccessfully - Boolean - Indicates whether the operation was completed successfully.
//
Procedure WhenClearingItemsInDevice(Device, ExecutedSuccessfully = True) Export
	
	OfflinePeripheralsServerCallLocalization.WhenClearingItemsInDevice(Device, ExecutedSuccessfully);
	
EndProcedure

// This procedure is called when goods are uploaded to the device.
// Writes information to the exchange plan node.
//
// Parameters:
//  Device       - CatalogRef.Peripherals - Link to the device.
//  StructureData - Structure -
//  ExecutedSuccessfully - Boolean - Indicates whether the operation was completed successfully.
//  ExtendedUpload - Boolean -
//
Procedure WhenUploadingGoodsToDevice(Device, StructureData, ExecutedSuccessfully = True, ExtendedUpload = False) Export
	
	OfflinePeripheralsServerCallLocalization.WhenUploadingGoodsToDevice(Device, StructureData, ExecutedSuccessfully, ExtendedUpload);
	
EndProcedure

#Region UnloadingGoods

// The function returns a structure with data in the format required for uploading the list of products to scales with label printing.
//
// Parameters:
//  Device - CatalogRef.Peripherals - The device for which you want to get data.
//  OnlyChangedItems - Boolean - Flag for getting only modified data.
//
// Returns:
//  Structure - structure with properties:
//  * Data - Array - Uploaded data.
//  * NumberOfUnloadedRowsWithErrors - Number - The number of lines with errors.
//  * PartialUnloading - Boolean - The characteristic of partial discharge.
//  * Parameters - Structure - see the Get Device Parameters function.
//
Function GetDataForWeights(Device, OnlyChangedItems = True) Export
	
	ReturnValue = Undefined;
	
	OfflinePeripheralsServerCallLocalization.GetDataForWeights(ReturnValue, Device, OnlyChangedItems);
	
	Return ReturnValue;

EndFunction

// The function gets the device parameters
//
// Parameters:
//  Device - CatalogRef.Peripherals - Link to the device.
// 
// Returns:
//  Structure - structure with properties:
//  * ExchangeRule - CatalogRef.RulesOfExchangeWithOfflinePeripherals - The exchange rule.
//  * InfobaseNode - ExchangePlanRef - the node information base.
//  * Warehouse - CatalogRef.Warehouses - warehouse.
//  * PriceKind - CatalogRef.TypesOfPrices - Type of price.
//  * EquipmentType - EnumRef.PeripheralTypes - type of equipment.
//  * MaximumGoodsQuantity - Number - Maximum code.
//  * ExportChanges - Boolean - Indicates whether changes need to be uploaded.
//
Function GetDeviceParameters(Device) Export
	
	ReturnValue = Undefined;
	OfflinePeripheralsServerCallLocalization.GetDeviceParameters(ReturnValue, Device);
	
	Return ReturnValue;
	
EndFunction

// The function registers changes for the device.
//
// Parameters:
//  Device - CatalogRef.Peripherals - Link to the device.
//
Procedure RecordChanges(Device) Export
	
	OfflinePeripheralsServerCallLocalization.RecordChanges(Device);
	
EndProcedure

// The procedure fills in the structure of the price list for uploading to the KKM Offline in an extended format (with product groups)
//
Procedure FillInPriceListStructureFromUploadData(PriceListStructure, GoodsReadyForUnloading) Export
	
	OfflinePeripheralsServerCallLocalization.FillInPriceListStructureFromUploadData(PriceListStructure, GoodsReadyForUnloading);
	
EndProcedure

#EndRegion

#Region WorkingWithRegisterProductCodesOfConnectedEquipment

// Maximum product weight code.
// 
// Returns:
//  Number - Maximum product weight code.
//
Function MaximumCodeOfGoodsSoldByWeight() Export
	
	Return 99999;
	
EndFunction

// The function returns the maximum product code in the product code register of the connected equipment Offline
// for the specified exchange rule.
//
// Parameters:
//  ExchangeRule - CatalogRef.RulesOfExchangeWithOfflinePeripherals - The exchange rule.
//
// Returns:
//  Number - The maximum product code for a given exchange rule.
//
Function GetMaximumCode(ExchangeRule) Export
	
	Query = New Query(
	"SELECT
	|	ISNULL(MAX(ItemsIDOfPeripheralsOffline.Code), 0) AS Code
	|FROM
	|	InformationRegister.ItemsIDOfPeripheralsOffline AS ItemsIDOfPeripheralsOffline
	|WHERE
	|	ItemsIDOfPeripheralsOffline.ExchangeRule = &ExchangeRule");
	
	Query.SetParameter("ExchangeRule", ExchangeRule);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	MaximumCodeOfGoodsSoldByWeight = MaximumCodeOfGoodsSoldByWeight();
	
	If Selection.Next() Then
		
		Code = Selection.Code;
		If Code < MaximumCodeOfGoodsSoldByWeight Then
			Code = MaximumCodeOfGoodsSoldByWeight;	
		EndIf;
		
		Return Code;

	Else
		Return MaximumCodeOfGoodsSoldByWeight;
	EndIf;
	
EndFunction

// The function returns a table of free product codes in the register of product codesoffline
// for the specified exchange rule. Free codes are codes that do not have a corresponding item set.
//
// Parameters:
//  ExchangeRule - CatalogRef.RulesOfExchangeWithOfflinePeripherals - The exchange rule.
//  Count - Number - Required number of free codes.
//
// Returns:
//  ValueTable - Table of free product codes with columns:
//  * Code - Number - free code.
//
Function GetFreeCodes(ExchangeRule, Count = 0) Export
	
	If Count = 0 Then
		QueryText = "SELECT
		|	ItemsIDOfPeripheralsOffline.Code AS Code
		|FROM
		|	InformationRegister.ItemsIDOfPeripheralsOffline AS ItemsIDOfPeripheralsOffline
		|WHERE
		|	ItemsIDOfPeripheralsOffline.ExchangeRule = &ExchangeRule
		|	AND ItemsIDOfPeripheralsOffline.Products = VALUE(Catalog.Products.EmptyRef)
		|
		|ORDER BY
		|	ItemsIDOfPeripheralsOffline.Code ASC";
	Else
		QueryText = "SELECT TOP 0
		|	ItemsIDOfPeripheralsOffline.Code AS Code
		|FROM
		|	InformationRegister.ItemsIDOfPeripheralsOffline AS ItemsIDOfPeripheralsOffline
		|WHERE
		|	ItemsIDOfPeripheralsOffline.ExchangeRule = &ExchangeRule
		|	AND ItemsIDOfPeripheralsOffline.Products = VALUE(Catalog.Products.EmptyRef)
		|
		|ORDER BY
		|	ItemsIDOfPeripheralsOffline.Code ASC";
		QueryText = StrReplace(QueryText, "0", "" + Format(Count, "NG=0"));
	EndIf;
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("ExchangeRule", ExchangeRule);
	
	Return Query.Execute().Unload();
	
EndFunction

// The procedure writes the
// code for the specified exchange rule and the corresponding nomenclature parameters to the register of the product codes of the connected equipment.
//
// Parameters:
//  Data        - Structure - Structure containing fields:
//   * Products - CatalogRef.Products - Nomenclature.
//   * Characteristic - CatalogRef.ItemsCharacteristics - characteristic.
//   * Package - CatalogRef.PackagesAndUnitsOfMeasure - Packaging.
//  ExchangeRule - CatalogRef.RulesOfExchangeWithOfflinePeripherals
//  Code           - Number - Product code in the context of the exchange rules.
//  Used  - Number - Indicates that the product matches the selection set in the exchange rule.
//
Procedure WriteCode(Data, ExchangeRule, Code, Used) Export
	
	RecordManager = InformationRegisters.ItemsIDOfPeripheralsOffline.CreateRecordManager();
	
	FillPropertyValues(RecordManager, Data);
	
	RecordManager.Code             = Code;
	RecordManager.ExchangeRule   = ExchangeRule;
	RecordManager.Used    = Used;
	
	RecordManager.Write();

EndProcedure

// The procedure clears the item parameters for the entry corresponding to the code within the exchange rule
// in the offline switchable equipment Code register.
// This record becomes free.
//
// Parameters:
//  ExchangeRule - CatalogRef.RulesOfExchangeWithOfflinePeripherals - The exchange rule.
//  Code           - Number - Product code in the context of the exchange rules.
//
Procedure DeleteCode(ExchangeRule, Code) Export
	
	WriteCode(New Structure("Products, Characteristic, Package"), ExchangeRule, Code , False);
	
EndProcedure

// The procedure updates the entries in the offline pluggable equipment Code register
// in accordance with the exchange rule. Entries that do not match the rule selection become
// unused. New entries are added that match the selection, if they are found.
//
// Parameters:
//  ExchangeRule - CatalogRef.RulesOfExchangeWithOfflinePeripherals - The exchange rule.
//
Procedure UpdateProductCodes(ExchangeRule) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query(
	"SELECT
	|	RulesOfExchangeWithOfflinePeripherals.Warehouse.RetailPriceType AS PriceKind,
	|	RulesOfExchangeWithOfflinePeripherals.Warehouse.SpecialPriceType AS SpecialPriceType,
	|	RulesOfExchangeWithOfflinePeripherals.UnitOfMeasureForWeight AS UnitOfMeasureForWeight,
	|	RulesOfExchangeWithOfflinePeripherals.DataCompositionSettings AS DataCompositionSettings,
	|	RulesOfExchangeWithOfflinePeripherals.PeripheralType AS PeripheralType
	|FROM
	|	Catalog.RulesOfExchangeWithOfflinePeripherals AS RulesOfExchangeWithOfflinePeripherals
	|WHERE
	|	RulesOfExchangeWithOfflinePeripherals.Ref = &ExchangeRule");
	
	Query.SetParameter("ExchangeRule", ExchangeRule);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		ParametersOfExchangeRule = New Structure;
		ParametersOfExchangeRule.Insert("PriceKind",                      Selection.PriceKind);
		ParametersOfExchangeRule.Insert("SpecialPriceType",        Selection.SpecialPriceType);
		ParametersOfExchangeRule.Insert("UnitOfMeasureForWeight",         Selection.UnitOfMeasureForWeight);
		ParametersOfExchangeRule.Insert("DataCompositionSettings",    Selection.DataCompositionSettings);
		ParametersOfExchangeRule.Insert("PeripheralType", Selection.PeripheralType);
		
		If PriceManagementSystemServerCall.UsePriceManagementSystem25() Then
			ProductRangeSettings = InformationRegisters.HistoryOfStoreFormatChange.CurAssortmentSettings(
				Common.ObjectAttributeValue(ExchangeRule, "Warehouse"));
			If ProductRangeSettings.RetailPricesFromStoreFormat Then
				ObjectAttributes = Common.ObjectAttributesValues(ProductRangeSettings.StoreFormat, "RetailPriceType, SpecialPriceType");
				ParametersOfExchangeRule.PriceKind = ObjectAttributes.RetailPriceType;
				ParametersOfExchangeRule.SpecialPriceType = ObjectAttributes.SpecialPriceType;
			EndIf;
		EndIf;
	Else
		Return;
	EndIf;
	
	If OfflinePeripheralsServerCallLocalization.ThisIsTypeOfOfflineEquipmentCashRegister(ParametersOfExchangeRule.PeripheralType) Then
		DataCompositionSchema = Catalogs.RulesOfExchangeWithOfflinePeripherals.GetTemplate("CRProductCodesUpdate");
	ElsIf ParametersOfExchangeRule.PeripheralType = Enums.PeripheralTypes.LabelPrintingScales Then
		DataCompositionSchema = Catalogs.RulesOfExchangeWithOfflinePeripherals.GetTemplate("UpdateOfPLUItemCodes");
	Else
		Raise NStr("vi = 'Sai kiểu thiết bị bán hàng';
					|ru = 'Некорректный тип подключаемого оборудования';
					|en = 'Invalid peripherals type'; fa = 'Invalid peripherals type';
					|it = 'Tipo incorretto dell''apparecchiatura collegata';
					|pl = 'Nieprawidłowy typ urządzenia peryferyjnego';
					|tr = 'Bağlanan ekipmanın türü yanlış'");
	EndIf;
	
	PriceManagementSystemServerCall.GetPricingScheme(DataCompositionSchema);
	
	// Preparing a data layout layout builder, loading settings
	Composer = New DataCompositionSettingsComposer;
	Composer.Initialize(New DataCompositionAvailableSettingsSource(DataCompositionSchema));
	
	ParametersExchangeRulesDataLayoutSettings = ParametersOfExchangeRule.DataCompositionSettings; // ValueStorage
	Composer.LoadSettings(ParametersExchangeRulesDataLayoutSettings.Get());
	Composer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
	
	// Filling in the report structure and selected fields.
	Composer.Settings.Structure.Clear();
	
	DetailedRecordsGroup = Composer.Settings.Structure.Add(Type("DataCompositionGroup"));
	DetailedRecordsGroup.Use = True;
	
	Composer.Settings.Selection.Items.Clear();
	
	SelectedField               = DetailedRecordsGroup.Selection.Items.Add(Type("DataCompositionSelectedField"));
	SelectedField.Field          = New DataCompositionField("Products");
	SelectedField.Use = True;
	
	If GetFunctionalOption("UseItemVariants") Then
		SelectedField               = DetailedRecordsGroup.Selection.Items.Add(Type("DataCompositionSelectedField"));
		SelectedField.Field          = New DataCompositionField("Characteristic");
		SelectedField.Use = True;
	EndIf;
	
	If GetFunctionalOption("UseItemPackages") Then
		SelectedField               = DetailedRecordsGroup.Selection.Items.Add(Type("DataCompositionSelectedField"));
		SelectedField.Field          = New DataCompositionField("Package");
		SelectedField.Use = True;
	EndIf;
	
	SelectedField               = DetailedRecordsGroup.Selection.Items.Add(Type("DataCompositionSelectedField"));
	SelectedField.Field          = New DataCompositionField("MatchesFilter");
	SelectedField.Use = True;
	
	SelectedField               = DetailedRecordsGroup.Selection.Items.Add(Type("DataCompositionSelectedField"));
	SelectedField.Field          = New DataCompositionField("Code");
	SelectedField.Use = True;
	
	SelectedField               = DetailedRecordsGroup.Selection.Items.Add(Type("DataCompositionSelectedField"));
	SelectedField.Field          = New DataCompositionField("Used");
	SelectedField.Use = True;
	
	SelectedField               = DetailedRecordsGroup.Selection.Items.Add(Type("DataCompositionSelectedField"));
	SelectedField.Field          = New DataCompositionField("SoldByWeight");
	SelectedField.Use = True;
	
	SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(Composer);
	
	// Layout layout and query execution.
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, Composer.GetSettings(), , , Type("DataCompositionValueCollectionTemplateGenerator"));
	
	Parameter = CompositionTemplate.ParameterValues.Find("Date");
	If Parameter <> Undefined Then
		Parameter.Value = CurrentSessionDate();
	EndIf;
	Parameter = CompositionTemplate.ParameterValues.Find("PriceKind");
	If Parameter <> Undefined Then
		Parameter.Value = ParametersOfExchangeRule.PriceKind;
	EndIf;
	Parameter = CompositionTemplate.ParameterValues.Find("SpecialPriceType");
	If Parameter <> Undefined Then
		Parameter.Value = ParametersOfExchangeRule.SpecialPriceType;
	EndIf;
	Parameter = CompositionTemplate.ParameterValues.Find("ExchangeRule");
	If Parameter <> Undefined Then
		Parameter.Value = ExchangeRule;
	EndIf;
	Parameter = CompositionTemplate.ParameterValues.Find("UnitOfMeasureForWeight");
	If Parameter <> Undefined Then
		Parameter.Value = ParametersOfExchangeRule.UnitOfMeasureForWeight;
	EndIf;
	Parameter = CompositionTemplate.ParameterValues.Find("BarcodeFormat");
	If Parameter <> Undefined Then
		Parameter.Value = InformationRegisters.ItemsBarcodes.WeightBarcodeFormat(InformationRegisters.ItemsBarcodes.BarcodeNodePrefix());
	EndIf;
	Parameter = CompositionTemplate.ParameterValues.Find("UseItemPackages");
	If Parameter <> Undefined Then
		Parameter.Value = GetFunctionalOption("UseItemPackages");
	EndIf;
	Parameter = CompositionTemplate.ParameterValues.Find("UseItemVariants");
	If Parameter <> Undefined Then
		Parameter.Value = GetFunctionalOption("UseItemVariants");
	EndIf;
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate);
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	
	ReportData = New ValueTable();
	OutputProcessor.SetObject(ReportData);
	ReportData = OutputProcessor.Output(CompositionProcessor);
	
	BeginTransaction();
	Try
		
		PLU = GetMaximumCode( ExchangeRule) + 1;
		FreePLUS = GetFreeCodes(ExchangeRule);
		For Each Capsule In ReportData Do
			If Capsule.MatchesFilter Then
				If Not ValueIsFilled(Capsule.Code) Then
					
					If FreePLUS.Count() = 0 Then
						WriteCode(Capsule, ExchangeRule, PLU, True);
						PLU = PLU + 1;
					Else
						WriteCode(Capsule, ExchangeRule, FreePLUS[0].Code, True);
						FreePLUS.Delete(0);
					EndIf;
					
				Else
					WriteCode(Capsule, ExchangeRule, Capsule.Code, True);
				EndIf;
			Else
				WriteCode(Capsule, ExchangeRule, Capsule.Code, False);
			EndIf;
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		Common.MessageToUser(BriefErrorDescription(ErrorInfo()));
		
		WriteLogEvent(NStr("vi = 'Bán lẻ';
							|ru = 'Розничные продажи';
							|en = 'Retail sales'; fa = 'فروش خرده‌فروشی';
							|it = 'Vendite al dettaglio';
							|pl = 'Sprzedaże detaliczne';
							|tr = 'Perakende satışlar'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			DetailErrorDescription(ErrorInfo()));
		
	EndTry;
	
	SetPrivilegedMode(False);
	
EndProcedure

// The procedure performs updating commodity codes for all of the rules of the exchange.
//
Procedure RoutineTaskUpdateProductCodes() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.UpdatePeripheralsGoodsCodes);
	
	SetPrivilegedMode(True);
	
	WriteLogEvent(NStr("vi = 'Cập nhật mã hàng hóa thiết bị bán hàng Offline';
						|ru = 'Обновление кодов товаров подключаемого оборудования Offline';
						|en = 'Update of product codes for offline peripherals'; fa = 'Update of product codes for offline peripherals';
						|it = 'Aggiornamento dei codici delle merci delle apparecchiature connesse Offline';
						|pl = 'Aktualizacja kodów towarów podłączanych urządzeń Offline';
						|tr = 'Çevrimdışı çevre birimlerinin ürün kodlarını güncelle'", Common.DefaultLanguageCode()),
	                         EventLogLevel.Information, , ,
	                         NStr("vi = 'Bắt đầu cập nhật thường kỳ mã hàng của thiết bị bán hàng Offline.';
									|ru = 'Начато регламентное обновление кодов товаров подключаемого оборудования Offline.';
									|en = 'Scheduled update of goods codes for offline peripherals has been started.'; fa = 'Scheduled update of goods codes for offline peripherals has been started.';
									|it = 'Iniziato l''aggiornamento di routine dei codici delle merci delle apparecchiature connesse Offline.';
									|pl = 'Została rozpoczęta aktualizacja reglamentowana kodów towarów podłączanych urządzeń Offline.';
									|tr = 'Çevrimdışı çevre birimlerinin ürün kodlarının programlı güncellemesi başlatıldı.'"));
	
	Query = New Query(
	"SELECT
	|	RulesOfExchangeWithOfflinePeripherals.Ref AS ExchangeRule
	|FROM
	|	Catalog.RulesOfExchangeWithOfflinePeripherals AS RulesOfExchangeWithOfflinePeripherals");
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		Try
			UpdateProductCodes(Selection.ExchangeRule);
		Except
			WriteLogEvent(NStr("vi = 'Cập nhật mã hàng hóa thiết bị bán hàng Offline';
								|ru = 'Обновление кодов товаров подключаемого оборудования Offline';
								|en = 'Update of product codes for offline peripherals'; fa = 'Update of product codes for offline peripherals';
								|it = 'Aggiornamento dei codici delle merci delle apparecchiature connesse Offline';
								|pl = 'Aktualizacja kodów towarów podłączanych urządzeń Offline';
								|tr = 'Çevrimdışı çevre birimlerinin ürün kodlarını güncelle'", Common.DefaultLanguageCode()),
			                         EventLogLevel.Error, , ,
			                         NStr("vi = 'Trong thời gian cập nhật thường kỳ mã hàng hóa của thiết bị bán hàng Offline đã xảy ra lỗi.';
											|ru = 'Во время регламентного обновления кодов товаров подключаемого оборудования Offline произошла ошибка.';
											|en = 'An error occurred during the scheduled update of goods codes for offline peripherals.'; fa = 'An error occurred during the scheduled update of goods codes for offline peripherals.';
											|it = 'Si è verificato un errore durante l''aggiornamento di routine dei codici delle merci delle apparecchiature connesse Offline.';
											|pl = 'Podczas reglamentowanej aktualizacji kodów towarów podłączanych urządzeń Offline zaistniał błąd.';
											|tr = 'Çevrimdışı çevre birimleri ürün kodlarının programlı güncellemesi sırasında hata oluştu.'")
			                         + Chars.LF + ErrorInfo().Description);
		EndTry;
	EndDo;
	
	WriteLogEvent(NStr("vi = 'Cập nhật mã hàng hóa thiết bị bán hàng Offline';
						|ru = 'Обновление кодов товаров подключаемого оборудования Offline';
						|en = 'Update of product codes for offline peripherals'; fa = 'Update of product codes for offline peripherals';
						|it = 'Aggiornamento dei codici delle merci delle apparecchiature connesse Offline';
						|pl = 'Aktualizacja kodów towarów podłączanych urządzeń Offline';
						|tr = 'Çevrimdışı çevre birimlerinin ürün kodlarını güncelle'", Common.DefaultLanguageCode()),
	                         EventLogLevel.Information, , ,
	                         NStr("vi = 'Kết thúc cập nhật thường kỳ mã hàng hóa của thiết bị bán hàng Offline.';
									|ru = 'Закончено регламентное обновление кодов товаров подключаемого оборудования Offline.';
									|en = 'Scheduled update of goods codes for offline peripherals is completed.'; fa = 'Scheduled update of goods codes for offline peripherals is completed.';
									|it = 'L''aggiornamento di routine dei codici delle merci delle apparecchiature connesse Offline è completato.';
									|pl = 'Została zakończona aktualizacja reglamentowana kodów towarów podłączanych urządzeń Offline.';
									|tr = 'Çevrimdışı çevre birimlerinin ürün kodlarının programlı güncellemesi tamamlandı.'"));
	
	SetPrivilegedMode(False);
	
EndProcedure

#EndRegion

#Region UnloadingGoods

// The function returns a table of products with data to be uploaded to the device.
//
// Parameters:
//  Device - CatalogRef.Peripherals - The device for which you want to get data
//  Parameters - Structure - 
//  UpdateProductCodes - Boolean - Flag for updating product codes before receiving data.
//  Barcode - String
//
// Returns:
//  ValueTable - Table of products to be uploaded.
//
Function ProductDataToUpload(Device, Parameters, UpdateProductCodes = False, Barcode = "") Export
	
	TableOfGoods = New ValueTable;
	OfflinePeripheralsServerCallLocalization.ProductDataToUpload(TableOfGoods, Device, Parameters, UpdateProductCodes, Barcode);
	
	Return TableOfGoods;
	
EndFunction

#EndRegion

#Region GoodsUnloadingRules

// The function returns a table of products with data about products for the upload rule with prices
//
// Parameters:
//  ExchangeRule - CatalogRef.RulesOfExchangeWithOfflinePeripherals - The exchange rule.
//  PriceKind - CatalogRef.TypesOfPrices - Type of price.
//  SpecialPriceType - CatalogRef.TypesOfPrices - individual view of the price.
//
// Returns:
//  ValueTable - The products table
//
Function DataOfGoodsUnderExchangeRule(ExchangeRule, PriceKind, SpecialPriceType) Export
	
	TableOfGoods = New ValueTable;
	OfflinePeripheralsServerCallLocalization.DataOfGoodsUnderExchangeRule(TableOfGoods, ExchangeRule, PriceKind, SpecialPriceType);
	
	Return TableOfGoods;
	
EndFunction

#EndRegion

// filling in the redefined procedures of the Manager Line Equipment module Undefined

Procedure FillInCashRegisterSettings(OfflineEquipment_, HardwareSettings) Export
	
	OfflinePeripheralsServerCallLocalization.FillInCashRegisterSettings(OfflineEquipment_, HardwareSettings);
	
EndProcedure

Procedure FillInPriceListOfCashRegister(OfflineEquipment_, PriceList, FullUpload) Export
	
	OfflinePeripheralsServerCallLocalization.FillInPriceListOfCashRegister(OfflineEquipment_, PriceList, FullUpload);
	
EndProcedure

Procedure FillInPriceListOfCashRegisterByBarcode(OfflineEquipment_, PriceList, Barcode) Export
	
	OfflinePeripheralsServerCallLocalization.FillInPriceListOfCashRegisterByBarcode(OfflineEquipment_, PriceList, Barcode);
	
EndProcedure

Procedure DeletePriceListRegistrationAfterUploading(OfflineEquipment_) Export
	
	OfflinePeripheralsServerCallLocalization.DeletePriceListRegistrationAfterUploading(OfflineEquipment_);
	
EndProcedure

Procedure DownloadSalesReportsFromCashRegister(Device, SalesData, Cancel, ErrorMessage) Export

	OfflinePeripheralsServerCallLocalization.DownloadSalesReportsFromCashRegister(Device, SalesData, Cancel, ErrorMessage);

EndProcedure

Procedure DownloadContainerOpeningDataFromCashRegister(Device, DataOnOpeningContainers, Cancel, ErrorMessage) Export

	OfflinePeripheralsServerCallLocalization.DownloadContainerOpeningDataFromCashRegister(Device, DataOnOpeningContainers, Cancel, ErrorMessage);

EndProcedure

#EndRegion

#Region Internal

// Fixing an error in the log from the client context. It is intended to be called from a client context.
// Parameters:
//	EventName - String - The name of the log event, 
//						  the name must unambiguously indicate the context of the current method call,
//						  For example, the name of the module and method, separated by a dot.
//	ErrorText - String
Procedure WriteErrorToEventLog(Val EventName, Val ErrorText) Export
	If IsBlankString(EventName) Then
		Return;
	EndIf;
	FixedName = "OfflinePeripheralsServerCall.WriteErrorToEventLog"+EventName;
	WriteLogEvent(FixedName, EventLogLevel.Error, , , ErrorText);
EndProcedure

#EndRegion