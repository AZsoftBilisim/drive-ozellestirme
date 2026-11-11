#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - See ReportsClientServer.GetDefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	Settings.Events.OnCreateAtServer = True;
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - report form.
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	FormSettingsComposer = ThisForm.Report.SettingsComposer;
	Parameters = ThisForm.Parameters;
	
	If Parameters.Property("CommandParameter") Then
		
		If Documents.AllRefsType().ContainsType(TypeOf(Parameters.CommandParameter)) Then
			
			DocumentObject = Parameters.CommandParameter.GetObject();
			If Not DocumentObject.CheckFilling() Then
				
				Cancel = True;
				Common.MessageToUser(
					NStr("vi = 'Không thể tạo báo cáo! Đã điền sai dữ liệu của chứng từ.';
						|ru = 'Невозможно сформировать отчет! Данные документа заполнены некорректно.';
						|en = 'Cannot generate a report. The document data is filled incorrectly.'; fa = 'Cannot generate a report. The document data is filled incorrectly.';
						|it = 'Невозможно сформировать отчет! Данные документа заполнены некорректно.';
						|pl = 'Cannot generate a report. The document data is filled incorrectly.';
						|tr = 'Rapor oluşturulamaz! Belge verileri yanlış doldurulmuş.'"));
				Return;
				
			EndIf;
			
		EndIf;
		
		ThisForm.ParametersForm.Filter.Insert("Document", Parameters.CommandParameter);
		ThisForm.ParametersForm.PurposeUseKey = String(Parameters.CommandParameter);
		Parameters.PurposeUseKey = String(Parameters.CommandParameter);
		
		ParameterType = TypeOf(Parameters.CommandParameter);
		If ParameterType = Type("DocumentRef.IntercompanyGoodsReturn")
			Or ParameterType = Type("DocumentRef.RetailSalesReport")
			Or ParameterType = Type("DocumentRef.CustomerInvoiceIntercompany")
			Or ParameterType = Type("DocumentRef.TransferOfGoodsToBailee")
			Or ParameterType = Type("DocumentRef.CustomerInvoice") Then
			
			Parameters.VariantKey = "StockBalanceForSale";
			
		Else
			Parameters.VariantKey = "StockBalanceForDocument";
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
 	SetPrivilegedMode(True);
		
	TableInLine = DataCompositionClientServer.GetParameter(SettingsComposer, "TableInLine").Value;
	ForAutomaticRegistrationOfWarehouseActs = ValueIsFilled(TableInLine);
	
	Document = DataCompositionClientServer.GetParameter(SettingsComposer, "Document").Value;
	If Not ValueIsFilled(Document)
		And Not ForAutomaticRegistrationOfWarehouseActs Then
		Return;
	EndIf;
	
	ParametersForFillingInventoryTypes = InventoriesServer.ParametersForFillingInventoryTypes();
	ParametersForFillingInventoryTypes.CompanyFieldName1 = "Organization";
	
	If ForAutomaticRegistrationOfWarehouseActs Then
		
		Warehouse = DataCompositionClientServer.GetParameter(SettingsComposer, "Warehouse").Value;
		
		DocumentObject = New Structure();
		DocumentObject.Insert("Date", CurrentSessionDate());
		DocumentObject.Insert("Warehouse", Warehouse);
		DocumentObject.Insert("Organization", Undefined);
		DocumentObject.Insert("Ref", Undefined);
		DocumentObject.Insert("Posted", False);
		DocumentObject.Insert("AdditionalProperties", New Structure());
		
		TableOfProductsFromRow = ValueFromStringInternal(TableInLine);
		TempTablesManager = New TempTablesManager;
		
		Query = New Query;
		Query.TempTablesManager = TempTablesManager;
		Query.SetParameter("Warehouse", DocumentObject.Warehouse);
		Query.SetParameter("TableOfGoods", TableOfProductsFromRow);
		Query.Text =
		"SELECT
		|	Goods.Products,
		|	Goods.Characteristic,
		|	Goods.Series,
		|	Goods.Purpose,
		|	Goods.Count,
		|	Goods.QuantityToRecordAsReceived,
		|	Goods.QuantityToWriteOff
		|INTO Goods
		|FROM
		|	&TableOfGoods AS Goods
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Dimension.DimensionKey AS ItemsLocationAttributes,
		|	Goods.Products,
		|	Goods.Characteristic,
		|	Goods.Series,
		|	Goods.Purpose,
		|	&Warehouse AS Warehouse,
		|
		|	UNDEFINED AS GoodsOwner,
		|	UNDEFINED AS Terms,
		|	UNDEFINED AS VATTaxation,
		|
		|	Goods.Count,
		|	Goods.QuantityToRecordAsReceived AS QuantityToRecordAsReceived,
		|	Goods.QuantityToWriteOff AS QuantityToWriteOff
		|
		|INTO TableOfProductsAndModAnalytics
		|FROM
		|	Goods AS Goods
		|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
		|		ON Goods.Products = Dimension.Products
		|			AND Goods.Characteristic = Dimension.Characteristic
		|			AND Goods.Series = Dimension.Series
		|			AND VALUE(Catalog.Assignments.EmptyRef)  = Dimension.Purpose
		|			AND (Dimension.StorageLocation = &Warehouse)
		|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
		|
		|INDEX BY
		|	ItemsLocationAttributes
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	UNDEFINED AS Organization
		|INTO SelectedCompanies
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	Table.ItemsLocationAttributes,
		|	VALUE(Catalog.CCDNumbers.EmptyRef) AS CCDNumber,
		|	Table.Products
		|INTO TableOfGoods
		|FROM
		|	TableOfProductsAndModAnalytics AS Table
		|;
		|/////////////////////////////////////////////////////////////////////////////
		|DROP Goods";
		
		Query.Execute();
		
		ParametersForFillingInventoryTypes.SelectTypesOfStocksForIntercampany = False; // in the selection of inventory types, an array is already transmitted for all organizations.
		
		Filters = ParametersForFillingInventoryTypes.SelectionOfStockTypes_;
		Filters.Organization = Catalogs.Companies.AvailableCompanies(True);
		
		InventoriesServer.PrepareDataForReport(DocumentObject, TempTablesManager, ParametersForFillingInventoryTypes);
		
		DocumentObject.Date = EndOfMonth(DocumentObject.Date);
		
	Else
		
		DocumentObject = Document.GetObject();
		DocumentObject.FillInProductTrackingForm();
		
		TempTablesManager = DocumentObject.TemporaryDocumentDataTables();
		DocumentObject.CreateTemporaryTableOfProductsAndAnalytics(TempTablesManager);
		
		ParametersForFillingInventoryTypes.SelectTypesOfStocksForIntercampany = True;
		
		Filters = ParametersForFillingInventoryTypes.SelectionOfStockTypes_;
		Filters.Organization = DocumentObject[ParametersForFillingInventoryTypes.CompanyFieldName1];
		
		ArrayOfStockTypes = GetTypesOfDocumentStocks(DocumentObject);
		If ArrayOfStockTypes.Count() > 0 Then
			
			Query = New Query;
			Query.SetParameter("ArrayOfStockTypes", ArrayOfStockTypes);
			Query.Text =
			"SELECT DISTINCT
			|	InventoryType
			|FROM
			|	Catalog.InventoryKinds
			|WHERE
			|	Ref IN (&ArrayOfStockTypes)";
			
			Filters.InventoryType = Query.Execute().Unload().UnloadColumn("InventoryType");
			
		EndIf;
		
		InventoriesServer.PrepareDataForReport(DocumentObject, TempTablesManager, ParametersForFillingInventoryTypes);
		
		Query = New Query;
		Query.TempTablesManager = TempTablesManager;
		Query.SetParameter("Organization", DocumentObject[ParametersForFillingInventoryTypes.CompanyFieldName1]);
		Query.Text =
		"SELECT
		|	&Organization AS Organization
		|INTO SelectedCompanies
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Goods.ItemsLocationAttributes,
		|	Goods.Products,
		|	Goods.Characteristic,
		|	Goods.Series,
		|	Goods.Purpose,
		|	Goods.Warehouse,
		|	UNDEFINED AS GoodsOwner,
		|	UNDEFINED AS Terms,
		|	Goods.VATTaxation AS VATTaxation,
		|	Goods.Count,
		|	0 AS QuantityToRecordAsReceived,
		|	0 AS QuantityToWriteOff
		|INTO TableOfProductsAndModAnalytics
		|FROM
		|	TableOfProductsAndAnalytics AS Goods
		|";
		
		Query.Execute();

	EndIf;
	
	DateOfRemainingGoods = EndOfMonth(DocumentObject.Date);
	
	InventoriesServer.GenerateTTTableOfBalances("CompanyGoods", DocumentObject, TempTablesManager, ParametersForFillingInventoryTypes, True);
	
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("Date", DocumentObject.Date);
	Query.SetParameter("ProhibitOperationsWithGoodsWithoutCCDNumbers", GetFunctionalOption("RestrictTransactionsWithImportedGoodsWithoutCCDNumbers"));
	Query.Text =
	"SELECT
	|	Companies.Ref AS Organization,
	|	VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT) AS VATTaxation
	|INTO TaxationOfOrganizations
	|FROM
	|	InformationRegister.TaxationSystemSettings.SliceLast(&Date,) AS Setting
	|	INNER JOIN Catalog.Companies AS Companies
	|	ON Setting.Organization = Companies.ParentCompany
	|WHERE
	|	Setting.STSIsApplied
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SelectedCompanies.Organization,
	|	TableOfGoods.VATTaxation,
	|	CASE
	|		WHEN TableOfGoods.ItemsLocationAttributes <> VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)
	|			THEN TableOfGoods.ItemsLocationAttributes
	|		ELSE ISNULL(Dimension.DimensionKey, VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef))
	|	END AS ItemsLocationAttributes,
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	TableOfGoods.Series,
	|	TableOfGoods.Warehouse,
	|	SUM(TableOfGoods.Count) AS Count,
	|	SUM(TableOfGoods.QuantityToRecordAsReceived) AS QuantityToRecordAsReceived,
	|	SUM(TableOfGoods.QuantityToWriteOff) AS QuantityToWriteOff,
	|
	|	TableOfGoods.Purpose,
	|	TableOfGoods.GoodsOwner,
	|	TableOfGoods.Terms
	|
	|INTO Goods
	|FROM
	|	SelectedCompanies AS SelectedCompanies
	|	LEFT JOIN TableOfProductsAndModAnalytics AS TableOfGoods
	|		ON TRUE
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON Dimension.Products = TableOfGoods.Products
	|		AND Dimension.Characteristic = TableOfGoods.Characteristic
	|		AND Dimension.Series = TableOfGoods.Series
	|		AND Dimension.StorageLocation = TableOfGoods.Warehouse
	|		AND Dimension.Purpose = TableOfGoods.Purpose
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|
	|GROUP BY
	|	SelectedCompanies.Organization,
	|	TableOfGoods.VATTaxation,
	|	CASE
	|		WHEN TableOfGoods.ItemsLocationAttributes <> VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)
	|			THEN TableOfGoods.ItemsLocationAttributes
	|		ELSE ISNULL(Dimension.DimensionKey, VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef))
	|	END ,
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	TableOfGoods.Series,
	|	TableOfGoods.Warehouse,
	|	TableOfGoods.Purpose,
	|	TableOfGoods.GoodsOwner,
	|	TableOfGoods.Terms
	|
	|INDEX BY
	|	ItemsLocationAttributes
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.Organization AS ForCompany,
	|	TableOfGoods.Organization AS Organization,
	|	TableOfGoods.VATTaxation,
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	TableOfGoods.Series,
	|	TableOfGoods.Warehouse,
	|	TableOfGoods.Count,
	|	TableOfGoods.QuantityToRecordAsReceived,
	|	TableOfGoods.QuantityToWriteOff,
	|
	|	TableOfGoods.Purpose,
	|	TableOfGoods.GoodsOwner,
	|	TableOfGoods.Terms
	|FROM
	|	Goods AS TableOfGoods
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.Organization AS ForCompany,
	|	BalanceTable.Organization AS Organization,
	|	BalanceTable.ItemsLocationAttributes,
	|	Keys.Products,
	|	Keys.Characteristic,
	|	Keys.Series,
	|	Keys.StorageLocation AS Warehouse,
	|	BalanceTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|
	|	BalanceTable.CCDNumber AS CCDNumber,
	|	BalanceTable.CCDNumber.OriginCountry AS OriginCountry,
	|	BalanceTable.DateOfReceipt AS DateOfReceipt,
	|	BalanceTable.CountBalance,
	|	CASE
	|		WHEN NOT AvailableInventoryTypesForOrganizations.InventoryOwnerAttribute IS NULL
	|			THEN CASE
	|					WHEN (Keys.Products.TracedGoods
	|								OR (Keys.Products.KeepRecordsByCCD
	|									AND &ProhibitOperationsWithGoodsWithoutCCDNumbers))
	|							AND BalanceTable.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef)
	|						THEN 0
	|					ELSE BalanceTable.CountBalance
	|				END
	|		ELSE 0
	|	END AS AvailableBalance,
	|
	|	CASE
	|		WHEN NOT AvailableInventoryTypesForOrganizations.InventoryOwnerAttribute IS NULL
	|			THEN CASE
	|					WHEN (Keys.Products.TracedGoods
	|								OR (Keys.Products.KeepRecordsByCCD
	|									AND &ProhibitOperationsWithGoodsWithoutCCDNumbers))
	|							AND BalanceTable.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef)
	|						THEN 0
	|					ELSE CASE
	|							WHEN AvailableInventoryTypesForOrganizations.InventoryOwnerAttribute.Organization = TableOfGoods.Organization
	|									OR TableOfGoods.Organization = UNDEFINED
	|								THEN BalanceTable.CountBalance
	|							ELSE 0
	|						END
	|				END
	|		ELSE 0
	|	END AS AvailableRemainingGoodsWithoutIntercompany,
	|
	|	UNDEFINED AS Department,
	|	UNDEFINED AS Manager,
	|	UNDEFINED AS SalesOpportunity,
	|
	|	BalanceTable.InventoryOwnerAttribute.Terms AS Terms,
	|	BalanceTable.InventoryOwnerAttribute.GoodsOwner AS GoodsOwner,
	|	BalanceTable.InventoryOwnerAttribute.VATTaxation AS VATTaxation,
	|	BalanceTable.InventoryOwnerAttribute.Contract AS Contract,
	|
	|	CASE
	|		WHEN NOT AvailableInventoryTypesForOrganizations.InventoryOwnerAttribute IS NULL
	|				AND NOT TableOfGoods.Purpose IS NULL
	|			THEN CASE
	|					WHEN (Keys.Products.TracedGoods
	|								OR (Keys.Products.KeepRecordsByCCD
	|									AND &ProhibitOperationsWithGoodsWithoutCCDNumbers))
	|							AND BalanceTable.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef)
	|						THEN FALSE
	|					ELSE TRUE
	|				END
	|		ELSE FALSE
	|	END AS AvailableForDocument,
	|
	|	CASE
	|		WHEN NOT AvailableInventoryTypesForOrganizations.InventoryOwnerAttribute IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThereIsConnectionWithAvailableStockTypesForOrganizations
	|FROM
	|	BalanceTable AS BalanceTable
	|
	|	INNER JOIN
	|		Catalog.InventoryLocationAttributeKeys AS Keys
	|	ON
	|		BalanceTable.ItemsLocationAttributes = Keys.Ref
	|	
	|	LEFT JOIN
	|		Goods AS TableOfGoods
	|	ON  
	|		BalanceTable.ItemsLocationAttributes = TableOfGoods.ItemsLocationAttributes
	|	
	|	LEFT JOIN
	|		AvailableTypesOfStocks AS AvailableInventoryTypesForOrganizations
	|	ON BalanceTable.InventoryOwnerAttribute = AvailableInventoryTypesForOrganizations.InventoryOwnerAttribute
	|		
	|	LEFT JOIN
	|		TaxationOfOrganizations AS TaxationOfOrganizations
	|	ON
	|		BalanceTable.Organization = TaxationOfOrganizations.Organization
	|WHERE
	|	BalanceTable.CountBalance > 0";
	
	ResultsArray = Query.ExecuteBatch();
	
	// Array of results[0] - Taxation of organizations
	// Array of results[1] - Products.
	TableOfGoods = ResultsArray[2].Unload();
	BalanceTable = ResultsArray[3].Unload();
	
	ExternalDataSets = New Structure("TableOfGoods, BalanceTable",
		TableOfGoods,
		BalanceTable
	);
	
	DateParameter_ = SettingsComposer.Settings.DataParameters.Items.Find("OnDate");
	If DateParameter_ <> Undefined Then
		
		CustomSettingParameter = SettingsComposer.UserSettings.Items.Find(DateParameter_.UserSettingID);
		If CustomSettingParameter <> Undefined Then
			CustomSettingParameter.Value = DateOfRemainingGoods;
		Else
			DateParameter_.Value = DateOfRemainingGoods;
		EndIf;
		
	EndIf;
	
	// Generate a report
	ReportSettings = SettingsComposer.GetSettings();
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	
	DataCompositionServer.SetLayoutTemplateHeaders(GetFieldHeaders(DateOfRemainingGoods), CompositionTemplate);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, ExternalDataSets, DetailsData);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	TableInLine = DataCompositionClientServer.GetParameter(SettingsComposer, "TableInLine").Value;	
 	If IsTempStorageURL(TableInLine) Then
		NotCheckedAttributeArray = New Array;
		NotCheckedAttributeArray.Add("Document");		
		Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function GetTypesOfDocumentStocks(DocumentObject)
	
	Result = New Array;
	
	NamesArray = New Array;
	NamesArray.Add("InventoryKinds");
	NamesArray.Add("InventoryOwnerAttributesRevenueAdjustment");
	NamesArray.Add("InventoryOwnerAttributesGoodsReceipt");
	NamesArray.Add("InventoryOwnerAttributesConsumption");
	NamesArray.Add("InventoryOwnerAttributesProducts");
	NamesArray.Add("InventoryOwnerAttributesMaterials");
	NamesArray.Add("InventoryOwnerAttributesMaterialsAndWorks");
	NamesArray.Add("InventoryOwnerAttributesFinishedProducts");
	NamesArray.Add("InventoryOwnerAttributesSideProducts");
	
	For Each TabularSectionName In NamesArray Do
		
		If DocumentObject.Metadata().TabularSections.Find(TabularSectionName) <> Undefined Then
			
			CommonClientServer.SupplementArray(Result, DocumentObject[TabularSectionName].UnloadColumn("InventoryOwnerAttribute"), True);
			
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

Function GetFieldHeaders(DateOfControl)
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	RegisterRecords.Period
	|FROM
	|	AccumulationRegister.CompanyGoods AS RegisterRecords
	|ORDER BY
	|	RegisterRecords.Period DESC";
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		UpdateDate = Selection.Period;
	Else
		UpdateDate = CurrentSessionDate();
	EndIf;
	
	FieldHeaders = New Map;
	FieldHeaders.Insert("1", Format(UpdateDate, "DLF=D"));
	
	Return FieldHeaders;
	
EndFunction

#EndRegion

#EndIf
