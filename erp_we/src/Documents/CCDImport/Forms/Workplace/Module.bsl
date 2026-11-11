
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Parameters.Property("QuickFilterStructure") Then
		Parameters.QuickFilterStructure.Property("Organization", Organization);
	EndIf;
	
	ControlCompanyStockBalance = GetFunctionalOption("ControlCompanyStockBalanceForRegistrationByReceipts");
	UseBranchOfficesWithSeparateBalanceSheets = GetFunctionalOption("UseBranchOfficesWithSeparateBalanceSheets");
	
	IDCustomsDeclarationImport = AccountingForTraceableGoodsLocalization.IDCustomsDeclarationImport();
	
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.MainTable = "AccumulationRegister.GoodsForRegistrationOfImportDocuments.Balance";
	ListProperties.DynamicDataRead = False;
	
	If ControlCompanyStockBalance Then
		ListProperties.QueryText = RequestTextCustomsDeclarationImportForProcessing();
	Else
		ListProperties.QueryText = QueryTextToRegister();
	EndIf;
	Common.SetDynamicListProperties(Items.ToRegister, ListProperties);
	
	Items.ToRegisterDocumentInflow.Visible = ControlCompanyStockBalance;
	Items.ToRegisterOrganization.Visible = GetFunctionalOption("UseMultipleCompanies");
	
	SetSelectionByDate(Period, ThisForm);
	SetSelectionByOrganization();
	SetSelectionByImportDocumentType();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "Write_CCDImport" Then
		Items.ToRegister.Refresh();
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PeriodOptionOnChange(Item)
	
	SetSelectionByDate(Period, ThisForm);
	
EndProcedure

&AtClient
Procedure PeriodStartDate_OnChange(Item)
	
	SetSelectionByDate(Period, ThisForm);
	
EndProcedure

&AtClient
Procedure PeriodEndDate_2OnChange(Item)
	
	SetSelectionByDate(Period, ThisForm);
	
EndProcedure

&AtClient
Procedure CompanyFilterOnChange(Item)
	
	If CompanySavedValue <> Organization Then
		
		SetSelectionByOrganization();
		CompanySavedValue = Organization;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure HyperlinkPurchaseHistoryURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	If FormattedStringURL = "PurchaseDocumentsAll" Then
		TMCommonUseClient.OpenLog(LogParameters());
	Else
		
		OpeningParameters = New Structure;
		OpeningParameters.Insert("VariantKey", "ImportedGoodsForRegistration");
		OpeningParameters.Insert("PurposeUseKey", );
		OpeningParameters.Insert("Filter", );
		OpeningParameters.Insert("GenerateOnOpen", True);
		OpeningParameters.Insert("ReportOptionsCommandsVisibility", False);
		
		OpenForm("Report.ImportedGoodsForRegistration.Form", OpeningParameters);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersToRegister

&AtClient
Procedure ToRegisterSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "ToRegisterDocumentInflow" Then
		
		ShowValue(Undefined, Items.ToRegister.CurrentData.DocumentInflow);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CreateCustomsDeclaration(Command)
	TheListForRegistration = Items.ToRegister;
	CurLineToDesign = TheListForRegistration.CurrentData;
	
	If CurLineToDesign = Undefined Then
		WarningText = NStr("vi = 'Không thể thực hiện lệnh đối với đối tượng đã chỉ ra!';
							|ru = 'Команда не может быть выполнена для указанного объекта!';
							|en = 'Cannot execute this command for the specified object.'; fa = 'Cannot execute this command for the specified object.';
							|it = 'Il comando non può essere eseguito per oggetto indicato!';
							|pl = 'Nie można wykonać polecenia dla wskazanego obiektu!';
							|tr = 'Komut, belirtilen nesne için yürütülemiyor.'");
		ShowMessageBox(Undefined, WarningText);
		Return;
	EndIf;

	
	If Not TMCommonUseClient.SelectedDocumentsForRegistration(TheListForRegistration.SelectedRows,LogParameters()) Then
		
		Return;
		
	EndIf;
	
		
	OrganizationData_1 = New Map();
	
	For Each CurLineToDesign In TheListForRegistration.SelectedRows Do 
		
		CurRowData = TheListForRegistration.RowData(CurLineToDesign);
		InformationByCompany = OrganizationData_1.Get(CurRowData.Organization);
		
		If InformationByCompany = Undefined Then
			InformationByCompany = New Map();			
			Basis = FormBasisForDeclaration(CurRowData);
			InformationByCompany.Insert(CurRowData.Vendor, Basis); 			
			OrganizationData_1.Insert(CurRowData.Organization, InformationByCompany);
		Else
			PartnerSearch = InformationByCompany.Get(CurRowData.Vendor); // See FormBasisForDeclaration
			If PartnerSearch = Undefined Then
				Basis = FormBasisForDeclaration(CurRowData);
				InformationByCompany.Insert(CurRowData.Vendor, Basis); 							
				OrganizationData_1.Insert(CurRowData.Organization, InformationByCompany);
			Else	
				If ControlCompanyStockBalance Then				
					PartnerSearch.DocumentInflow.Add(CurRowData.DocumentInflow);
					InformationByCompany.Insert(CurRowData.Vendor, PartnerSearch);
					OrganizationData_1.Insert(CurRowData.Organization, InformationByCompany);
				EndIf;
			EndIf;	
		EndIf;
		
	EndDo;
				
	For Each TheseGrounds In  OrganizationData_1 Do
		For Each PartnerData_1 In TheseGrounds.Value Do
			OpenForm("Document.CCDImport.ObjectForm", New Structure("Basis", PartnerData_1.Value));
		EndDo;
	EndDo;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region OnChangeAttributes

&AtClientAtServerNoContext
Procedure SetSelectionByDate(Period, Form)
	
	If ValueIsFilled(Period.StartDate)
		And ValueIsFilled(Period.EndDate) 
		And Period.StartDate > Period.EndDate Then
		
		Period.EndDate = Period.StartDate;			
		
	EndIf;
	
	StartDate =
		?(ValueIsFilled(Period.StartDate), BegOfDay(Period.StartDate), '00010101');
	Form.ToRegister.Parameters.SetParameterValue("StartDate", StartDate);
	
	EndDate =
		?(ValueIsFilled(Period.EndDate), EndOfDay(Period.EndDate) + 1, '39991231235959');
	Form.ToRegister.Parameters.SetParameterValue("EndDate", EndDate);
	
EndProcedure

#EndRegion

&AtServer
Function QueryTextToRegister()
	
	QueryText =
	"SELECT DISTINCT
	|	UNDEFINED AS DocumentInflow,
	|	ForThePeriod.Vendor AS Vendor,
	|	ForThePeriod.Organization AS Organization,
	|	VALUE(Catalog.Counterparties.EmptyRef) AS VendorSCounterparty,
	|	UNDEFINED AS Ref
	|FROM
	|	AccumulationRegister.GoodsForRegistrationOfImportDocuments.Turnovers(&StartDate, &EndDate, , ImportDocumentType = &ImportDocumentType ) AS ForThePeriod
	|		INNER JOIN AccumulationRegister.GoodsForRegistrationOfImportDocuments.Balance(, ) AS ForNow
	|		ON ForThePeriod.ItemsLocationAttributes = ForNow.ItemsLocationAttributes
	|			AND ForThePeriod.Vendor = ForNow.Vendor
	|			AND ForThePeriod.Organization = ForNow.Organization
	|			AND ForThePeriod.InventoryOwnerAttribute = ForNow.InventoryOwnerAttribute
	|			AND ForThePeriod.ImportDocumentType = ForNow.ImportDocumentType
	|WHERE
	|	ForNow.CountBalance > 0
	|	AND ForThePeriod.CountTurnover > 0
	|";
	
	Return QueryText;
	
EndFunction

&AtServer
Function RequestTextCustomsDeclarationImportForProcessing()

	QueryText = 
	"SELECT ALLOWED DISTINCT
	|	ForThePeriod.DocumentInflow AS DocumentInflow,
	|	ForThePeriod.Vendor AS Vendor,
	|	ForThePeriod.Organization AS Organization,
	|	ISNULL(VendorInvoice.Counterparty, VALUE(Catalog.Counterparties.EmptyRef)) AS VendorSCounterparty,
	|	ForThePeriod.DocumentInflow AS Ref
	|FROM
	|	AccumulationRegister.GoodsForRegistrationOfImportDocuments.Turnovers(&StartDate, &EndDate, , ImportDocumentType = &ImportDocumentType) AS ForThePeriod
	|		INNER JOIN AccumulationRegister.GoodsForRegistrationOfImportDocuments.Balance(, ) AS ForNow
	|		ON ForThePeriod.ItemsLocationAttributes = ForNow.ItemsLocationAttributes
	|			AND ForThePeriod.Vendor = ForNow.Vendor
	|			AND ForThePeriod.Organization = ForNow.Organization
	|			AND ForThePeriod.InventoryOwnerAttribute = ForNow.InventoryOwnerAttribute
	|			AND ForThePeriod.DocumentInflow = ForNow.DocumentInflow
	|			AND ForThePeriod.ImportDocumentType = ForNow.ImportDocumentType
	|		LEFT JOIN Document.VendorInvoice AS VendorInvoice
	|		ON ForThePeriod.DocumentInflow = VendorInvoice.Ref
	|WHERE
	|	ForNow.CountBalance > 0
	|	AND ForThePeriod.CountTurnover > 0
	|";

	Return QueryText;
	
EndFunction

&AtServer
Procedure SetSelectionByOrganization()
	
	CompaniesList = New ValueList;
	CompaniesList.Add(Organization);
	
	If ValueIsFilled(Organization)
		And UseBranchOfficesWithSeparateBalanceSheets Then
		
		Query = New Query("
		|SELECT ALLOWED
		|	Companies.Ref
		|FROM
		|	Catalog.Companies AS Companies
		|WHERE
		|	Companies.BranchOffice
		|	AND Companies.ParentCompany = &Organization
		|	AND Companies.TransactionsUsingParentCompanyAreAllowed");
		Query.SetParameter("Organization", Organization);
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			CompaniesList.Add(Selection.Ref);
		EndDo;
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(
		ToRegister,
		"Organization",
		CompaniesList,
		DataCompositionComparisonType.InList,
		,
		ValueIsFilled(Organization));
	
EndProcedure

&AtServer
Procedure SetSelectionByImportDocumentType()
	
	ToRegister.Parameters.SetParameterValue("ImportDocumentType", IDCustomsDeclarationImport);
	
EndProcedure

&AtClient
Function LogParameters()
	
	QuickFilterStructure = New Structure;
	QuickFilterStructure.Insert("Organization",Organization);
	LogParameters = New Structure;
	LogParameters.Insert("QuickFilterStructure",QuickFilterStructure);
	LogParameters.Insert("FormAssignmentKey", "CCDsImport");
	LogParameters.Insert("WorkplaceName","LogOfPurchaseDocuments");
	LogParameters.Insert("JournalSynonym",NStr("vi = 'Chứng từ mua hàng';
												|ru = 'Документы закупки';
												|en = 'Purchase documents'; fa = 'اسناد خرید';
												|it = 'Documenti d''acquisto';
												|pl = 'Dokument zakupu';
												|tr = 'Satın alma belgeleri'"));
	
	Return LogParameters;
	
EndFunction

// Parameters:
// 	CurLineToDesign - FormDataCollectionItem, FormDataTreeItem, FormDataStructure - 
// 	
// Returns:
// 	Structure:
// 		* RequestProducts - String
// 		* DateOfRemainingGoods - Date
// 		* VendorSCounterparty - CatalogRef.Counterparties
// 		* Vendor - CatalogRef.Partners
// 		* Organization - CatalogRef.Companies
// 		* DocumentInflow - Array of DocumentRef.VendorInvoice
// 		* ImportDocumentType - CatalogRef.MetadataObjectIDs
// 		* ControlCompanyStockBalance - Boolean
//
&AtClient
Function FormBasisForDeclaration(CurLineToDesign)
	
	Text = "SELECT
	|	GoodsForRegistrationOfImportDocumentsBalance.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	CAST(GoodsForRegistrationOfImportDocumentsBalance.DocumentInflow AS Document.VendorInvoice) AS DocumentInflow,
	|	GoodsForRegistrationOfImportDocumentsBalance.CountBalance AS CountBalance,
	|	GoodsForRegistrationOfImportDocumentsBalance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	GoodsForRegistrationOfImportDocumentsBalance.SumBalance AS Sum
	|INTO TTBalance
	|FROM
	|	AccumulationRegister.GoodsForRegistrationOfImportDocuments.Balance(&DateOfRemainingGoods, Organization = &Organization
	|	AND ImportDocumentType = &ImportDocumentType
	|	AND Vendor = &Vendor
	|	AND (NOT &ControlCompanyStockBalance
	|	OR DocumentInflow IN (&DocumentInflow))) AS GoodsForRegistrationOfImportDocumentsBalance
	|WHERE
	|	GoodsForRegistrationOfImportDocumentsBalance.CountBalance > 0
	|
	|INDEX BY
	|	DocumentInflow,
	|	InventoryOwnerAttribute,
	|	ItemsLocationAttributes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VendorInvoice.Ref AS DocumentInflow,
	|	VendorInvoice.Date AS Date,
	|	VendorInvoice.Currency AS Currency,
	|	PurchaseOfGoodsServicesGoods.Warehouse AS Warehouse,
	|	VendorInvoice.PriceIncludesVAT AS PriceIncludesVAT,
	|	VendorInvoice.PurchaseForActivity AS PurchaseForActivity,
	|	VendorInvoice.BusinessOperation AS BusinessOperation,
	|	PurchaseOfGoodsServicesGoods.Products AS Products,
	|	PurchaseOfGoodsServicesGoods.Purpose AS Purpose,
	|	PurchaseOfGoodsServicesGoods.Characteristic AS Characteristic,
	|	PurchaseOfGoodsServicesGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	PurchaseOfGoodsServicesGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	SUM(PurchaseOfGoodsServicesGoods.Count) AS NumberOfReceipts_1,
	|	PurchaseOfGoodsServicesGoods.Series AS Series,
	|	PurchaseOfGoodsServicesGoods.VATRate AS VATRate,
	|	SUM(PurchaseOfGoodsServicesGoods.Sum) AS Sum,
	|	SUM(PurchaseOfGoodsServicesGoods.AmountIncludingVAT) AS AmountIncludingVAT,
	|	SUM(PurchaseOfGoodsServicesGoods.VATAmount) AS VATAmount
	|INTO TTReceipts
	|FROM
	|	TTBalance AS TTBalance
	|		LEFT JOIN Document.VendorInvoice.Goods AS PurchaseOfGoodsServicesGoods
	|			INNER JOIN Document.VendorInvoice AS VendorInvoice
	|			ON PurchaseOfGoodsServicesGoods.Ref = VendorInvoice.Ref
	|		ON TTBalance.DocumentInflow = PurchaseOfGoodsServicesGoods.Ref
	|		AND TTBalance.ItemsLocationAttributes = PurchaseOfGoodsServicesGoods.ItemsLocationAttributes
	|WHERE
	|	TTBalance.DocumentInflow <> VALUE(Document.VendorInvoice.EmptyRef)
	|	AND NOT TTBalance.DocumentInflow IS NULL
	|GROUP BY
	|	VendorInvoice.Ref,
	|	VendorInvoice.Date,
	|	PurchaseOfGoodsServicesGoods.Warehouse,
	|	VendorInvoice.Currency,
	|	VendorInvoice.PriceIncludesVAT,
	|	VendorInvoice.BusinessOperation,
	|	VendorInvoice.PurchaseForActivity,
	|	PurchaseOfGoodsServicesGoods.Products,
	|	PurchaseOfGoodsServicesGoods.Purpose,
	|	PurchaseOfGoodsServicesGoods.PartnerProducts,
	|	PurchaseOfGoodsServicesGoods.Characteristic,
	|	PurchaseOfGoodsServicesGoods.InventoryOwnerAttribute,
	|	PurchaseOfGoodsServicesGoods.ItemsLocationAttributes,
	|	PurchaseOfGoodsServicesGoods.VATRate,
	|	PurchaseOfGoodsServicesGoods.Series
	|
	|UNION ALL
	|
	|SELECT
	|	Goods.DocumentInflow,
	|	NULL,
	|	NULL,
	|	Goods.ItemsLocationAttributes.StorageLocation,
	|	FALSE,
	|	NULL,
	|	NULL,
	|	Goods.ItemsLocationAttributes.Products,
	|	Goods.ItemsLocationAttributes.Purpose,
	|	Goods.ItemsLocationAttributes.Characteristic,
	|	Goods.InventoryOwnerAttribute,
	|	Goods.ItemsLocationAttributes,
	|	Goods.CountBalance,
	|	Goods.ItemsLocationAttributes.Series,
	|	VALUE(Catalog.VATRates.EmptyRef),
	|	Goods.Sum,
	|	0,
	|	0
	|FROM
	|	TTBalance AS Goods
	|WHERE
	|	Goods.DocumentInflow = VALUE(Document.VendorInvoice.EmptyRef)
	|	OR Goods.DocumentInflow IS NULL
	|
	|INDEX BY
	|	DocumentInflow,
	|	InventoryOwnerAttribute
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(TTReceipts.DocumentInflow, VALUE(Document.VendorInvoice.EmptyRef)) AS
	|		DocumentInflow,
	|	TTReceipts.Currency AS CurrencyOfReceipt,
	|	ISNULL(TTReceipts.Warehouse, TTBalance.ItemsLocationAttributes.StorageLocation) AS Warehouse,
	|	TTReceipts.Date AS DateOfReceipt,
	|	TTReceipts.PriceIncludesVAT AS PriceIncludesVAT,
	|	TTReceipts.PurchaseForActivity AS PurchaseForActivity,
	|	TTReceipts.BusinessOperation AS BusinessOperation,
	|	ISNULL(TTReceipts.Products, TTBalance.ItemsLocationAttributes.Products) AS Products,
	|	ISNULL(TTReceipts.Purpose, TTBalance.ItemsLocationAttributes.Purpose) AS Purpose,
	|	ISNULL(TTReceipts.Characteristic, TTBalance.ItemsLocationAttributes.Characteristic) AS Characteristic,
	|	CASE
	|		WHEN NOT &ControlCompanyStockBalance
	|			THEN TTBalance.CountBalance
	|		WHEN TTBalance.CountBalance >= ISNULL(TTReceipts.NumberOfReceipts_1, 1)
	|			THEN ISNULL(TTReceipts.NumberOfReceipts_1, 1)
	|		ELSE TTBalance.CountBalance
	|	END AS Count,
	|	CASE
	|		WHEN NOT &ControlCompanyStockBalance
	|			THEN TTBalance.CountBalance
	|		WHEN TTBalance.CountBalance >= ISNULL(TTReceipts.NumberOfReceipts_1, 1)
	|			THEN ISNULL(TTReceipts.NumberOfReceipts_1, 1)
	|		ELSE TTBalance.CountBalance
	|	END AS NumberOfPackages,
	|	TTBalance.ItemsLocationAttributes.Series AS Series,
	|	UNDEFINED AS Package,
	|	0 AS Price,
	|	0 AS PercentRateOfManualDiscount,
	|	0 AS ManualDiscount,
	|	TTReceipts.VATRate AS VATRate,
	|	ISNULL(TTReceipts.Sum, 0) / ISNULL(TTReceipts.NumberOfReceipts_1, 1) * CASE
	|		WHEN TTBalance.CountBalance >= ISNULL(TTReceipts.NumberOfReceipts_1, 1)
	|			THEN ISNULL(TTReceipts.NumberOfReceipts_1, 1)
	|		ELSE TTBalance.CountBalance
	|	END AS Sum,
	|	ISNULL(TTReceipts.AmountIncludingVAT, 0) / ISNULL(TTReceipts.NumberOfReceipts_1, 1) * CASE
	|		WHEN TTBalance.CountBalance >= ISNULL(TTReceipts.NumberOfReceipts_1, 1)
	|			THEN ISNULL(TTReceipts.NumberOfReceipts_1, 1)
	|		ELSE TTBalance.CountBalance
	|	END AS AmountIncludingVAT,
	|	ISNULL(TTReceipts.VATAmount, 0) / ISNULL(TTReceipts.NumberOfReceipts_1, 1) * CASE
	|		WHEN TTBalance.CountBalance >= ISNULL(TTReceipts.NumberOfReceipts_1, 1)
	|			THEN ISNULL(TTReceipts.NumberOfReceipts_1, 1)
	|		ELSE TTBalance.CountBalance
	|	END AS VATAmount,
	|	TTBalance.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TTBalance.ItemsLocationAttributes AS ItemsLocationAttributes
	|FROM
	|	TTBalance AS TTBalance
	|		LEFT JOIN TTReceipts AS TTReceipts
	|		ON (TTReceipts.DocumentInflow = TTBalance.DocumentInflow)
	|		AND (TTReceipts.ItemsLocationAttributes = TTBalance.ItemsLocationAttributes)
	|		AND (TTBalance.InventoryOwnerAttribute = TTReceipts.InventoryOwnerAttribute
	|		OR NOT TTBalance.ItemsLocationAttributes.StorageLocation REFS Catalog.Warehouses)
	|
	|ORDER BY
	|	ISNULL(TTReceipts.DocumentInflow, VALUE(Document.VendorInvoice.EmptyRef))";


	DateOfRemainingGoods = ?(ValueIsFilled(Period.EndDate), Period.EndDate, '39991231');
	
	Basis = New Structure;
	Basis.Insert("Organization", CurLineToDesign.Organization);
	Basis.Insert("Vendor", CurLineToDesign.Vendor);
	Basis.Insert("VendorSCounterparty", CurLineToDesign.VendorSCounterparty);
	Basis.Insert("DateOfRemainingGoods", DateOfRemainingGoods);
	Basis.Insert("ImportDocumentType", IDCustomsDeclarationImport);
	
	If ControlCompanyStockBalance Then
		ArrayOfReceiptDocuments = New Array();
		ArrayOfReceiptDocuments.Add(CurLineToDesign.DocumentInflow);
		Basis.Insert("DocumentInflow", ArrayOfReceiptDocuments);
		Basis.Insert("ControlCompanyStockBalance", True);
	Else
		Basis.Insert("DocumentInflow", Undefined);
		Basis.Insert("ControlCompanyStockBalance", False);
	EndIf;
	
	Basis.Insert("RequestProducts", Text);
	
	Return Basis;
EndFunction

#EndRegion
