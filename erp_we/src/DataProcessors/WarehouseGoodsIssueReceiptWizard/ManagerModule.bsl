#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Get a list of products for registration of warehouse certificates
//
// Parameters:
//  Warehouses				 - Array of CatalogRef.Warehouses	 - array of warehouses
//  FilterOfProductItem	 - DataCompositionSettingsComposer	 - settings for the selection items
//  StartDate			 - Date									 - inventory start date
//  EndDate		 - Date									 - the end date of the inventory.
// 
// Returns:
//  ValueTable - the nomenclature table.
//
Function GoodsForRegistrationOfWarehouseActs(Val Warehouses, 
														Val FilterOfProductItem = Undefined, 
														Val StartDate = Undefined, 
														Val EndDate = Undefined) Export
	
	SetPrivilegedMode(True);
	
	DataCompositionSchema = GetTemplate("ItemFilterMain");
	RedefineQueryTextOfTemplateSelectionOfMainItem(DataCompositionSchema);
	If FilterOfProductItem = Undefined Then
		FilterOfProductItem = New DataCompositionSettingsComposer;
		URLSchemes = PutToTempStorage(DataCompositionSchema, New UUID());
		SettingsSource = New DataCompositionAvailableSettingsSource(URLSchemes);
		FilterOfProductItem.Initialize(SettingsSource);
		FilterOfProductItem.LoadSettings(DataCompositionSchema.DefaultSettings);
	EndIf;
	SetValueOfSettingsParameter(FilterOfProductItem.Settings, "Warehouse", Warehouses);
	
	DatesAreSpecified = True;
	If StartDate = Undefined And EndDate = Undefined Then
		DatesAreSpecified = False;	
	EndIf;
	
	If StartDate = Undefined Then
		StartDate = Date(1,1,1);
	EndIf;
	
	Period = Date(1,1,1);
	If EndDate = Undefined Then
		EndDate = Date(1,1,1);
	Else
		Period = New Boundary(EndOfDay(EndDate));
	EndIf;
	
	If EndDate < StartDate Then
		Raise NStr("vi = 'Tham số ""Ngày kết thúc"" nhỏ hơn tham số ""Ngày bắt đầu"".';
					|ru = 'Параметр ""Дата окончания"" меньше параметра ""Даты начала"".';
					|en = 'The ""End date"" parameter is less than the ""Start date"" parameter.'; fa = 'The ""End date"" parameter is less than the ""Start date"" parameter.';
					|it = 'Il parametro ""La data del termine"" è inferiore al parametro ""La data di inizio"".';
					|pl = 'Parametr ""Data zakończenia"" jest mniejszy od parametru ""Data rozpoczęcia"".';
					|tr = '""Bitiş tarihi"", ""Başlangıç ​​tarihinden"" daha az parametresi.'");
	EndIf;
			
	SetValueOfSettingsParameter(FilterOfProductItem.Settings, "StartDate", 		StartDate);
	SetValueOfSettingsParameter(FilterOfProductItem.Settings, "EndDate", 	EndDate);
	SetValueOfSettingsParameter(FilterOfProductItem.Settings, "Period", 			Period);
	SetValueOfSettingsParameter(FilterOfProductItem.Settings, "DatesAreSpecified", 	DatesAreSpecified);
	
	SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(FilterOfProductItem);
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate   = TemplateComposer.Execute(DataCompositionSchema, FilterOfProductItem.GetSettings(), , ,
		Type("DataCompositionValueCollectionTemplateGenerator"));
		
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(CompositionTemplate,,, True);
	
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	
	ProductsTable = OutputProcessor.Output(DataCompositionProcessor);
	
	SetPrivilegedMode(False);
	
	// If the FO "Use the characteristics of the Nomenclature" or "Use the Series of Nomenclature" are disabled, then
	// there will be no Characteristic or Series field in the SKD, so this column may not be in the Nomenclature table.
	If ProductsTable.Columns.Find("ItemVariantOfGoodsReceipt") = Undefined Then
		ProductsTable.Columns.Add("ItemVariantOfGoodsReceipt", 
			New TypeDescription("CatalogRef.ItemsCharacteristics"));
	EndIf;
	If ProductsTable.Columns.Find("ItemVariantOfGoodsIssue") = Undefined Then
		ProductsTable.Columns.Add("ItemVariantOfGoodsIssue", 
			New TypeDescription("CatalogRef.ItemsCharacteristics"));
	EndIf;
	If ProductsTable.Columns.Find("AssignmentRecordedAsReceived") = Undefined Then
		ProductsTable.Columns.Add("AssignmentRecordedAsReceived", 
			New TypeDescription("CatalogRef.Assignments"));
	EndIf;
	If ProductsTable.Columns.Find("AssignmentOfWrittingOff") = Undefined Then
		ProductsTable.Columns.Add("AssignmentOfWrittingOff", 
			New TypeDescription("CatalogRef.Assignments"));
	EndIf;
	If ProductsTable.Columns.Find("RecordedAsReceivedBatch") = Undefined Then
		ProductsTable.Columns.Add("RecordedAsReceivedBatch", New TypeDescription("CatalogRef.ItemsBatches"));
	EndIf;
	If ProductsTable.Columns.Find("WrittenOffBatch") = Undefined Then
		ProductsTable.Columns.Add("WrittenOffBatch", New TypeDescription("CatalogRef.ItemsBatches"));
	EndIf;
	
	Return ProductsTable;
	
EndFunction

// Adds an object creation command.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  Undefined, ValueTableRow - Add the create command based on the warehouse report processing assistant
Function AddCreateCommandBasedOnWarehouseActRegistrationForm(GenerationCommands) Export
	If AccessRight("View", Metadata.DataProcessors.WarehouseGoodsIssueReceiptWizard) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.WarehouseGoodsIssueReceiptWizard";
		CreateBasedOnCommand.Id = "WarehouseGoodsIssueReceiptWizard";
		CreateBasedOnCommand.Presentation = NStr("vi = 'Trợ giúp lập biên bản kho';
												|ru = 'Помощник оформления складских актов';
												|en = 'Inventory adjustment wizard'; fa = 'دستیار تعدیل موجودی';
												|it = 'Assistente per la regolarizzazione degli atti di magazzino';
												|pl = 'Asystent rejestracji aktów magazynowych';
												|tr = 'Stok düzeltmeleri düzenleme sihirbazı'");
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseWarehouseManagemantSystemForGoodsSurplusesShortages";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
EndFunction

// Sets a conditional clearance for field 'Operationtest' table.
//
// Parameters:
//	Form			- ClientApplicationForm	- a form containing elements for setting the conditional design.
//	FieldName			- String						- name of the form element in the table part that contains information about the operation.
//														The default value of "Tovariaceae".
//	PathToSelectionField - String						- the full path to the props 'Operationtest' tabular part of the form.
//														The default value is " Object.Goods.Operationtest".
//
Procedure SetConditionalFormattingOperationText(Form,
													FieldName = "ProductsOperationText",
													PathToSelectionField = "Object.Goods.TransactionText") Export
	
	FormItems		= Form.Items;
	ConditionalAppearance	= Form.ConditionalAppearance;
	
	OperationDescriptions = New Structure;
	OperationDescriptions.Insert("WriteOff",		NStr("vi = 'Chi';
														|ru = 'Списание';
														|en = 'Stock shortage'; fa = 'کسری موجودی';
														|it = 'Storno';
														|pl = 'Spisanie';
														|tr = 'Gider yazmak'"));
	OperationDescriptions.Insert("RecordingAsReceived",	NStr("vi = 'Ghi tăng';
																|ru = 'Оприходование';
																|en = 'Stock surplus'; fa = 'اضافه موجودی';
																|it = 'Registrazione in contabilità';
																|pl = 'Rejestracja';
																|tr = 'Envanter girişi oluşturma'"));
	OperationDescriptions.Insert("Damage",			NStr("vi = 'Hàng hỏng';
															|ru = 'Порча';
															|en = 'Stock quality change'; fa = 'تغییر کیفیت موجودی';
															|it = 'Deterioramento';
															|pl = 'Uszkodzenie';
															|tr = 'Stok kalite değişikliği'"));
	OperationDescriptions.Insert("Misgrading",	NStr("vi = 'Chuyển tồn';
														|ru = 'Пересортица';
														|en = 'Stock reclass'; fa = 'تغییر طبقه موجودی';
														|it = 'Smistamento';
														|pl = 'Przesortowanie';
														|tr = 'Yeniden sınıflandırma'"));
	
	For Each TransactionText In OperationDescriptions Do
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		TSFormField = FormItems[FieldName]; // FormField
		ItemField.Field = New DataCompositionField(TSFormField.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(PathToSelectionField);
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = TransactionText.Key;
		
		Item.Appearance.SetParameterValue("Text", TransactionText.Value);
	EndDo;
	
EndProcedure

// The redefined Query Text of the DCS data set of the processing Template.
//
//Parameters:
//	DataCompositionSchema - DataCompositionSchema - layout diagram of the processing Template data.
//
Procedure RedefineQueryTextOfTemplateSelectionOfMainItem(DataCompositionSchema) Export
	
	DataSet = DataCompositionSchema.DataSets.Find("FillingBySelection");
	DataSet.Query =
	"SELECT DISTINCT
	|	Segments.Products,
	|	Segments.Characteristic,
	|	TRUE AS FilterByProductSegmentIsUsed
	|INTO SelectionByProductSegment
	|FROM
	|	InformationRegister.SegmentProducts AS Segments
	|{WHERE
	|	Segments.Segment.* AS ProductSegment,
	|	Segments.Products.* AS Products,
	|	Segments.Characteristic.* AS Characteristic}
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	FilterByProductSegmentIsUsed
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	GoodsForRegistrationOfSurplusesAndShortages.Products,
	|	GoodsForRegistrationOfSurplusesAndShortages.Characteristic,
	|	GoodsForRegistrationOfSurplusesAndShortages.Series,
	|	GoodsForRegistrationOfSurplusesAndShortages.Purpose
	|INTO ProductsWithDeviations
	|FROM
	|	AccumulationRegister.GoodsForRegistrationOfSurplusesAndShortages AS GoodsForRegistrationOfSurplusesAndShortages
	|		LEFT JOIN Catalog.Assignments AS Assignments
	|		ON GoodsForRegistrationOfSurplusesAndShortages.Purpose = Assignments.Ref
	|WHERE
	|	(GoodsForRegistrationOfSurplusesAndShortages.Period BETWEEN &StartDate AND &EndDate
	|		OR NOT &DatesAreSpecified)
	|	AND GoodsForRegistrationOfSurplusesAndShortages.Warehouse IN(&Warehouse)
	|	AND (Assignments.Ref IS NULL
	|		OR NOT (VALUETYPE(Assignments.OrderDocument) IN(
	|				TYPE(Document.MaterialProviderOrder2_5))
	|			AND Assignments.Partner <> VALUE(Catalog.Partners.EmptyRef)))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsForRegistrationOfSurplusesAndShortagesBalance.Products AS Products,
	|	GoodsForRegistrationOfSurplusesAndShortagesBalance.Products AS ProductsWrittenOff,
	|	NULL AS ProductsRecordedAsReceived,
	|	GoodsForRegistrationOfSurplusesAndShortagesBalance.Characteristic AS Characteristic,
	|	GoodsForRegistrationOfSurplusesAndShortagesBalance.Characteristic AS ItemVariantOfGoodsIssue,
	|	NULL AS ItemVariantOfGoodsReceipt,
	|	GoodsForRegistrationOfSurplusesAndShortagesBalance.Purpose AS Purpose,
	|	GoodsForRegistrationOfSurplusesAndShortagesBalance.Purpose AS AssignmentOfWrittingOff,
	|	NULL AS AssignmentRecordedAsReceived,
	|	GoodsForRegistrationOfSurplusesAndShortagesBalance.Series AS WrittenOffBatch,
	|	NULL AS RecordedAsReceivedBatch,
	|	-GoodsForRegistrationOfSurplusesAndShortagesBalance.ToCertificateRegistrationBalance AS Count,
	|	-GoodsForRegistrationOfSurplusesAndShortagesBalance.ToCertificateRegistrationBalance AS QuantityNotAllocated,
	|	0 AS QuantityIsAllocated,
	|	TRUE AS NotAllocated,
	|	FALSE AS Allocated,
	|	""WriteOff"" AS TransactionText,
	|	TRUE AS TransactionConsumption,
	|	FALSE AS GoodsReceiptTransaction,
	|	ISNULL(ProductsVATRates.VATRate, ISNULL(BasicVATRates.VATRate, VALUE(Catalog.VATRates.EmptyRef))) AS VATRate
	|FROM
	|	AccumulationRegister.GoodsForRegistrationOfSurplusesAndShortages.Balance(
	|			&Period,
	|			Warehouse IN (&Warehouse)
	|				AND (Products, Characteristic, Series, Purpose) IN
	|					(SELECT
	|						ProductsWithDeviations.Products,
	|						ProductsWithDeviations.Characteristic,
	|						ProductsWithDeviations.Series,
	|						ProductsWithDeviations.Purpose
	|					FROM
	|						ProductsWithDeviations AS ProductsWithDeviations) {((Products, Characteristic) IN
	|				(SELECT
	|					SelectionByProductSegment.Products,
	|					SelectionByProductSegment.Characteristic
	|				FROM
	|					SelectionByProductSegment
	|				WHERE
	|					SelectionByProductSegment.FilterByProductSegmentIsUsed = &FilterByProductSegmentIsUsed)), (Products).* AS Products}) AS GoodsForRegistrationOfSurplusesAndShortagesBalance
	|		LEFT JOIN InformationRegister.ProductsVATRates.SliceLast(&Period, Country = &CountryOfVATRates) AS ProductsVATRates
	|		ON GoodsForRegistrationOfSurplusesAndShortagesBalance.Products = ProductsVATRates.Products
	|		LEFT JOIN InformationRegister.BasicVATRates.SliceLast(&Period, Country = &CountryOfVATRates) AS BasicVATRates
	|		ON TRUE
	|
	|WHERE
	|	GoodsForRegistrationOfSurplusesAndShortagesBalance.ToCertificateRegistrationBalance < 0
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsForRegistrationOfSurplusesAndShortagesBalance.Products,
	|	NULL,
	|	GoodsForRegistrationOfSurplusesAndShortagesBalance.Products,
	|	GoodsForRegistrationOfSurplusesAndShortagesBalance.Characteristic,
	|	NULL,
	|	GoodsForRegistrationOfSurplusesAndShortagesBalance.Characteristic,
	|	GoodsForRegistrationOfSurplusesAndShortagesBalance.Purpose,
	|	NULL,
	|	GoodsForRegistrationOfSurplusesAndShortagesBalance.Purpose,
	|	NULL,
	|	GoodsForRegistrationOfSurplusesAndShortagesBalance.Series,
	|	GoodsForRegistrationOfSurplusesAndShortagesBalance.ToCertificateRegistrationBalance,
	|	GoodsForRegistrationOfSurplusesAndShortagesBalance.ToCertificateRegistrationBalance,
	|	0,
	|	TRUE,
	|	FALSE,
	|	""RecordingAsReceived"",
	|	FALSE,
	|	TRUE,
	|	ISNULL(ProductsVATRates.VATRate, ISNULL(BasicVATRates.VATRate, VALUE(Catalog.VATRates.EmptyRef)))
	|FROM
	|	AccumulationRegister.GoodsForRegistrationOfSurplusesAndShortages.Balance(
	|			&Period,
	|			Warehouse IN (&Warehouse)
	|				AND (Products, Characteristic, Series, Purpose) IN
	|					(SELECT
	|						ProductsWithDeviations.Products,
	|						ProductsWithDeviations.Characteristic,
	|						ProductsWithDeviations.Series,
	|						ProductsWithDeviations.Purpose
	|					FROM
	|						ProductsWithDeviations AS ProductsWithDeviations) {((Products, Characteristic) IN
	|				(SELECT
	|					SelectionByProductSegment.Products,
	|					SelectionByProductSegment.Characteristic
	|				FROM
	|					SelectionByProductSegment
	|				WHERE
	|					SelectionByProductSegment.FilterByProductSegmentIsUsed = &FilterByProductSegmentIsUsed)), (Products).* AS Products}) AS GoodsForRegistrationOfSurplusesAndShortagesBalance
	|		LEFT JOIN InformationRegister.ProductsVATRates.SliceLast(&Period, Country = &CountryOfVATRates) AS ProductsVATRates
	|		ON GoodsForRegistrationOfSurplusesAndShortagesBalance.Products = ProductsVATRates.Products
	|		LEFT JOIN InformationRegister.BasicVATRates.SliceLast(&Period, Country = &CountryOfVATRates) AS BasicVATRates
	|		ON TRUE
	|		
	|WHERE
	|	GoodsForRegistrationOfSurplusesAndShortagesBalance.ToCertificateRegistrationBalance > 0";
	
EndProcedure

#EndRegion

#Region Private

Procedure SetValueOfSettingsParameter(Settings, ParameterName, Value)
	
	Parameter = Settings.DataParameters.Items.Find(ParameterName);
	
	If Parameter <> Undefined Then
		Parameter.Value = Value;
		Parameter.Use = True;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
