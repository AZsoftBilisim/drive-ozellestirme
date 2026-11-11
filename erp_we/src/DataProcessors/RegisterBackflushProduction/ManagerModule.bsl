
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Generate documents by parameters.
// 
// Parameters:
//  DocumentParameters_ - See ProductionClientServer.ParametersForFormationOfProductionDocumentsWithoutOrders
// 
// Returns:
//  Structure - Generate Documents By Parameters:
// * FormObject - DocumentObject
// * DocumentType - String
// * HasErrors - Boolean
// * DocumentsList - ValueList of DocumentRef.BackflushProduction, DocumentRef.RecyclableWasteAllocation - list of documents.
// * ErrorsArray - FixedArray of UserMessage - mistakes.
//
Function GenerateDocumentsByParameters(DocumentParameters_) Export
	
	// StandardSubsystems.PerformanceMeasurement
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"DataProcessor.RegisterBackflushProduction.Form.WorkplaceForm.Procedure.DocumentsOnParameters");
	// End StandardSubsystems.PerformanceMeasurement
	
	// Data caps.
	DocumentDate = Min(EndOfMonth(DocumentParameters_.RegistrationPeriod), CurrentSessionDate());
	HeaderData_ = New Structure("Date", DocumentDate);
	
	ProductTableBySpecification = TableOfProductParameters(DocumentParameters_.ProductsAccordingToSpecification, DocumentDate);
	
	BOMSelectionParameters = ProductDataManagementClientServer.ParametersForSelectingSpecificationsForManufacturingAssembly();
	
	IgnoredDestinationParameters = New Array;
	IgnoredDestinationParameters.Add(Enums.TypesOfBOMAssignmentParameters.ProductionDispatcherBusinessUnit);
	BOMSelectionParameters.Insert("IgnoredDestinationParameters", IgnoredDestinationParameters);
	
	ProductData_2 = New Array;
	For Each String In ProductTableBySpecification Do
		ProductData = ProductDataManagementClientServer.ProductDataStructureForSpecificationSelection();
		FillPropertyValues(ProductData, String);
		ProductData_2.Add(ProductData);
	EndDo;
	
	ProductDataManagement.FillInSpecificationInLines(
		ProductTableBySpecification,
		ProductData_2,
		BOMSelectionParameters,,
		True);
	
	ProductTableByRule = TableOfProductParameters(DocumentParameters_.ProductsByRule, DocumentDate);
	
	DocumentCreationOptions = New Structure("HeaderData_",	HeaderData_);
	DocumentCreationOptions.Insert("ProductsAccordingToSpecification",	PutToTempStorage(ProductTableBySpecification));
	DocumentCreationOptions.Insert("ProductsByRule",		PutToTempStorage(ProductTableByRule));
	DocumentCreationOptions.Insert("AutoFill",	DocumentParameters_.AutoFill);
	DocumentCreationOptions.Insert("ListOfData",			DocumentParameters_.ListOfData);
	
	ListOfObjects = New ValueList;
	
	Documents.BackflushProduction.DocumentsOnParameters(DocumentCreationOptions, ListOfObjects);
	Documents.RecyclableWasteAllocation.DocumentsOnParameters(DocumentCreationOptions, ListOfObjects);
	
	Result = New Structure;
	Result.Insert("FormObject");
	Result.Insert("DocumentType");
	Result.Insert("HasErrors",       False);
	Result.Insert("DocumentsList", New ValueList);
	
	If ListOfObjects.Count() = 1 Then
		
		CurDocument = ListOfObjects[0].Value;
		If TypeOf(CurDocument) = Type("DocumentObject.BackflushProduction") Then
			Result.FormObject = DocumentParameters_.FormObjects["BackflushProduction"];
			Result.DocumentType = "BackflushProduction";
		Else
			Result.FormObject = DocumentParameters_.FormObjects["RecyclableWasteAllocation"];
			Result.DocumentType = "RecyclableWasteAllocation";
		EndIf;
		
		ValueToFormData(CurDocument, Result.FormObject);
		
	Else
		
		For Each CurDocument In ListOfObjects Do
			CurDocument.Value.Write(DocumentWriteMode.Write);
			Result.DocumentsList.Add(CurDocument.Value.Ref);
			
			If CurDocument.Value.CheckFilling() Then
				Try
					CurDocument.Value.Write(DocumentWriteMode.Posting);
				Except
					Result.HasErrors = True;
					Common.MessageToUser(ErrorDescription());
				EndTry;
			Else
				Result.HasErrors = True;
			EndIf;
		EndDo;
		
	EndIf;
	
	Result.Insert("ErrorsArray", GetUserMessages(True));
	
	// StandardSubsystems.PerformanceMeasurement
	OperationsCount = DocumentParameters_.ProductsAccordingToSpecification.Count() + DocumentParameters_.ProductsByRule.Count();
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, OperationsCount);
	// End StandardSubsystems.PerformanceMeasurement
	
	Return Result;
	
EndFunction

#EndRegion

#Region Private

Function TableOfProductParameters(Products_1, DocumentDate)
	
	ProductParameters = New ValueTable;
	ProductParameters.Columns.Add("CostGroupNumber",			New TypeDescription("Number", New NumberQualifiers(10, 0)));
	ProductParameters.Columns.Add("Organization",				New TypeDescription("CatalogRef.Companies"));
	ProductParameters.Columns.Add("GroupCosts",			New TypeDescription("EnumRef.GroupingsOfCostsInBackflushProduction"));
	ProductParameters.Columns.Add("InternalSubcontracting",		New TypeDescription("Boolean"));
	ProductParameters.Columns.Add("MaterialProviderCompany",			New TypeDescription("CatalogRef.Companies"));
	ProductParameters.Columns.Add("Department",				New TypeDescription("CatalogRef.BusinessStructure"));
	ProductParameters.Columns.Add("DirectionOfProductionIssue",			New TypeDescription("EnumRef.BusinessTransactions"));
	
	ProductParameters.Columns.Add("Recipient",					New TypeDescription("CatalogRef.BusinessStructure,
																						|CatalogRef.Warehouses"));
	
	ProductParameters.Columns.Add("ProductionStart",			New TypeDescription("Date"));
	ProductParameters.Columns.Add("Products",				New TypeDescription("CatalogRef.Products"));
	ProductParameters.Columns.Add("Characteristic",				New TypeDescription("CatalogRef.ItemsCharacteristics"));
	ProductParameters.Columns.Add("Series",						New TypeDescription("CatalogRef.ItemsBatches"));
	ProductParameters.Columns.Add("Purpose",					New TypeDescription("CatalogRef.Assignments"));
	ProductParameters.Columns.Add("LineOfBusiness",	New TypeDescription("CatalogRef.LinesOfBusiness"));
	ProductParameters.Columns.Add("BillOfMaterials",				New TypeDescription("CatalogRef.BillsOfMaterials"));
	ProductParameters.Columns.Add("AllocatedAccordingToRule",		New TypeDescription("CatalogRef.CostAllocationRules"));
	ProductParameters.Columns.Add("Count",					New TypeDescription("Number", New NumberQualifiers(15, 3)));
	ProductParameters.Columns.Add("RecordCostsByADocument",	New TypeDescription("Boolean"));
	ProductParameters.Columns.Add("ErrorInModelSettings",	New TypeDescription("Boolean"));
	
	For Each String In Products_1 Do
		
		NewRow = ProductParameters.Add();
		FillPropertyValues(NewRow, String);
		
		NewRow.Organization			= SettingsValueCached.GetDefaultOrganization(NewRow.Organization);
		NewRow.ProductionStart	= DocumentDate;
		
	EndDo;
	
	Return ProductParameters;
	
EndFunction

#Region CreatingHyperlinkInProductionLog

Function RequestTextProductionWithoutOrderForCheckout(Parameters)

	QueryText = "
	|SELECT ALLOWED TOP 1
	|	CompanyGoods.Organization AS Organization,
	|	CatWarehouses.Department       AS Department
	|FROM
	// We get a list of analysts for which the transfer of products was issued this month
	|	(SELECT
	|		ProductsOfTrafficOrganizations.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		ProductsOfTrafficOrganizations.Organization AS Organization
	|	FROM
	|		AccumulationRegister.CompanyGoods AS ProductsOfTrafficOrganizations
	|	WHERE
	|		ProductsOfTrafficOrganizations.RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND VALUETYPE(ProductsOfTrafficOrganizations.Recorder) = TYPE(Document.MovementOfProductsAndMaterials)
	|		AND ProductsOfTrafficOrganizations.BusinessOperation IN (VALUE(Enum.BusinessTransactions.TransferOfProductsFromStoreroom),
	|															VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction))
	|	
	|	GROUP BY
	|		ProductsOfTrafficOrganizations.ItemsLocationAttributes,
	|		ProductsOfTrafficOrganizations.Organization) AS ProductsOfTrafficOrganizations
	|	
	// We receive the remains of the transferred products
	|	INNER JOIN AccumulationRegister.CompanyGoods.Balance AS CompanyGoods
	|		ON ProductsOfTrafficOrganizations.ItemsLocationAttributes = CompanyGoods.ItemsLocationAttributes
	|		AND ProductsOfTrafficOrganizations.Organization = CompanyGoods.Organization
	|	
	|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON (Dimension.Ref = CompanyGoods.ItemsLocationAttributes)
	|	LEFT JOIN Catalog.Warehouses AS CatWarehouses
	|		ON (Dimension.StorageLocation = CatWarehouses.Ref)
	|WHERE
	|	CompanyGoods.CountBalance < 0
	|	AND CatWarehouses.ShopFloorStockroom
	|	AND &ConditionText
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	Works.Organization   AS Organization,
	|	Works.Department AS Department
	|FROM
	|	AccumulationRegister.MaterialsAndWorksInProduction.Balance(,
	|		Products IN (
	|			SELECT
	|				CatProducts.Ref
	|			FROM
	|				Catalog.Products AS CatProducts
	|			WHERE
	|				CatProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5))) AS Works
	|WHERE
	|	Works.CountBalance < 0
	|	AND &TextOfWorkingConditions
	|";
	
	ConditionText       = "";
	TextOfWorkingConditions = "";
	If Parameters.Property("Organization") And ValueIsFilled(Parameters.Organization) Then
		ConditionText       = ConditionText + Chars.LF + " AND CompanyGoods.Organization = &Organization";
		TextOfWorkingConditions = TextOfWorkingConditions + Chars.LF + " AND Works.Organization = &Organization";
	EndIf;
	
	If Parameters.Property("Department") And ValueIsFilled(Parameters.Department) Then
		ConditionText       = ConditionText + Chars.LF + " AND CatWarehouses.Department = &Department";
		TextOfWorkingConditions = TextOfWorkingConditions + Chars.LF + " AND Works.Department = &Department";
	EndIf;
	
	QueryText = StrReplace(QueryText, "AND &TextOfWorkingConditions", TextOfWorkingConditions);
	QueryText = StrReplace(QueryText, "AND &ConditionText", ConditionText);
	
	Return QueryText;
	
EndFunction

Function CreateHyperlinkToDesign(Parameters) Export
	
	If Not (AccessRight("Update", Metadata.Documents.BackflushProduction)
			Or AccessRight("Update", Metadata.Documents.RecyclableWasteAllocation))Then
		Return Undefined;
	EndIf;
	
	Query = New Query;
	Query.Text = RequestTextProductionWithoutOrderForCheckout(Parameters);
	Query.SetParameter("Organization", Parameters.Organization);
	Query.SetParameter("Department", Parameters.Department);
	
	HyperlinkText = NStr("vi = 'Sản xuất không theo đơn đặt hàng';
						|ru = 'Производство без заказа';
						|en = 'Backflush production'; fa = 'تولید با کسر خودکار مواد';
						|it = 'Produzione senza ordine';
						|pl = 'Produkcja bez zamówień';
						|tr = 'Geriye dönük üretim'");
	If Query.Execute().IsEmpty() Then
		Return New FormattedString(HyperlinkText,,StyleColors.EmptyTableField,,
			"DataProcessor.RegisterBackflushProduction.Form.WorkplaceForm");
	Else
		Return New FormattedString(HyperlinkText,,,,
			"DataProcessor.RegisterBackflushProduction.Form.WorkplaceForm");
	EndIf;
	
EndFunction

#EndRegion

#EndRegion

#EndIf