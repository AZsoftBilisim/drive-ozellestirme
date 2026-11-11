/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Batch accounting mechanism version 2.2
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//

// The structure of the main procedures and functions of the module:
// - To reflect in the mechanism of accounting for the cost of the cost () - the basic procedure of the interface for the formation of Registered Records. 
//		Called from the document data procedure for checking() the Document manager module.
// - Reflect the operation of the accounting of the cost() - the procedure for generating all Query Texts in accordance with the description of the document operation.
//	it has descriptions in the fields:
//		#Area Description_Reflect the operation of the Cost accounting - description of the algorithm for generating Query Texts
//		#Area Description_Operation Textthe value is a description of the rules for filling in fields in Register Records

#Region Public

Procedure ReflectInCostAndCostAccountingMechanism(Document, Query, QueryTexts, Registers, Object = Undefined) Export
	
	MediumSlipValuationIsUsed = CalculationOfCostCached.MediumSlipValuationIsUsed();
	
	If MediumSlipValuationIsUsed Then
		
		ArrayRegisters = CalculationOfCostCached.RelatedRegistersWhenConductingMediumSlip();
		ThereAreCostRegisters = False;
		
		For Each MetaRegister In ArrayRegisters Do
			If DocumentsPosting.RequiresTableForRegisteredRecords(MetaRegister.Name, Registers) Then
				ThereAreCostRegisters = True;
				Break;
			EndIf;
		EndDo;
		
		If Not ThereAreCostRegisters Then
			Return;
		EndIf;
		
	Else
		
		If Not DocumentsPosting.RequiresTableForRegisteredRecords(Metadata.AccumulationRegisters.InventoryCost.Name, Registers)
		 And Not DocumentsPosting.RequiresTableForRegisteredRecords(Metadata.AccumulationRegisters.RevenueAndCOGS.Name, Registers) Then
			Return;
		EndIf;
		
	EndIf;
	
	MetaDocument = Metadata.FindByType(TypeOf(Document));
	
	If MetaDocument = Undefined Or Not Metadata.Documents.Contains(MetaDocument) Then
		Raise NStr("vi = 'Không thể xác định kiểu chứng từ';
					|ru = 'Не удалось определить тип документа';
					|en = 'Cannot determine a document type'; fa = 'Cannot determine a document type';
					|it = 'Non è stato possibile definire il tipo di documento';
					|pl = 'Nie udało się określić typu dokumentu';
					|tr = 'Belge türü belirlenemedi'");
	EndIf;
	
	ThisIsStornoDocument = (MetaDocument = Metadata.Documents.ReversingEntry);
	
	ReflectionParameters = New Structure;
	ReflectionParameters.Insert("ThereIsReversal", False);
	
	// For corrective documents, the table of the data of the inspection must be generated earlier than the call of the mechanism of carrying out at cost.
	If ThisIsStornoDocument Or MetaDocument.Attributes.Find("Patch") <> Undefined Then
		
		CheckTableStorno = False;
		
		If ThisIsStornoDocument Then

			CheckTableStorno = True;
			
		ElsIf Query.Parameters.Property("Patch") And Query.Parameters.Patch Then
			
			CheckTableStorno = True;
			
		ElsIf Not Query.Parameters.Property("Patch") And Query.Parameters.Property("Ref") Then
			
			QueryTextCorrections =
			"SELECT TOP 1
			|	Documents.Ref AS Ref
			|FROM
			|	&DocumentName AS Documents
			|WHERE
			|	Documents.Ref IN (&Ref)
			|	AND Documents.Patch
			|";
			
			QueryTextCorrections = StrReplace(QueryTextCorrections, "&DocumentName", "Document." + MetaDocument.Name);
			
			RequestForCorrection = New Query;
			RequestForCorrection.Text = QueryTextCorrections;
			RequestForCorrection.SetParameter("Ref", Document);
			
			CheckTableStorno = Not RequestForCorrection.Execute().IsEmpty();
			
		EndIf;
		
		If CheckTableStorno Then
			
			ThereAreRegisteredRecordsOfCost = False;
			RegisterNameCost = Metadata.AccumulationRegisters.InventoryCost.Name;
			
			For Each ListItem In QueryTexts Do
				
				If ListItem.Presentation = RegisterNameCost Then
					ThereAreRegisteredRecordsOfCost = True;
				EndIf;
				
				If StrFind(ListItem.Value, "TTReversalDataCost") > 0 Then
					ReflectionParameters.Insert("ThereIsReversal", True);
					Break;
				EndIf;
				
			EndDo;
			
			If Not ReflectionParameters.ThereIsReversal And ThereAreRegisteredRecordsOfCost Then
				Raise NStr("vi = 'Lỗi tạo truy vấn kết chuyển chứng từ:
					|yêu cầu đảo ngược bản ghi kết chuyển cần được thực hiện trước yêu cầu kết chuyển theo biểu ghi ""Giá vốn hàng hóa""';
					|ru = 'Ошибка формирования запроса проведения документа:
					|запросы сторнирования движений должны выполняться до запросов проведения по регистру ""Себестоимость товаров""';
					|en = 'An error occurred when generating the document posting query:
					|Record reversal queries must be performed before posting queries for the ""Inventory cost"" register'; fa = 'An error occurred when generating the document posting query:
					|Record reversal queries must be performed before posting queries for the ""Inventory cost"" register';
					|it = 'An error occurred when generating the document posting query:
					|Record reversal queries must be performed before posting queries for the ""Inventory cost"" register';
					|pl = 'An error occurred when generating the document posting query:
					|Record reversal queries must be performed before posting queries for the ""Inventory cost"" register';
					|tr = 'Belge yürütme talebi oluşturma hatası:
					|Hareketlerin tersine döndürülmesine ilişkin talepler, ""Ürünlerin maliyeti"" kaydına ilişkin yürütme taleplerinden önce tamamlanmalıdır'");
			EndIf;
			
		EndIf;
		
	EndIf;
	
	// Description of the document.
	ReflectionParameters.Insert("Document", 			Document);
	ReflectionParameters.Insert("MetadataOfDocument", 	MetaDocument);
	ReflectionParameters.Insert("ManagerOfDocument", 	ObjectManagerByRef(Document));
	// Parameters of the document.
	ReflectionParameters.Insert("Query", 				Query);
	ReflectionParameters.Insert("QueryTexts", 		QueryTexts);
	ReflectionParameters.Insert("Registers", 			Registers);
	// Registers for reflection.
	ReflectionParameters.Insert("RegistersForReflection", New Structure);
	
	ReflectionParameters.Insert("MediumSlipIsUsed", MediumSlipValuationIsUsed);
	ReflectionParameters.Insert("DifferentPeriodsInRegisteredRecordsArePossible",
		Query.TempTablesManager <> Undefined
		And Query.TempTablesManager.Tables.Find("TTParametersOfBatchAccountingForConducting") <> Undefined);
	
	AdditionalParameterDescription = Undefined;
	DescriptionOfAdditionalTables = Undefined;
	
	// Cost_
	RegisterMetadata = Metadata.AccumulationRegisters.InventoryCost;
	RegisterName 	   = RegisterMetadata.Name;
	
	If (MediumSlipValuationIsUsed Or DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, ReflectionParameters.Registers))
	 And ReflectionParameters.ManagerOfDocument.DescriptionOfCostAndCostRegisters(ReflectionParameters.Document).Find(RegisterMetadata) <> Undefined Then 
		
		ReflectionParameters.Insert("RegisterName", RegisterName);
		
		RegisterDescription = New Structure;
	
		// We will get the data to reflect the document.
		AdditionalParameterDescription = ReflectionParameters.ManagerOfDocument.SetAdditionalParametersForCostAndCostAccountingOperations(
			ReflectionParameters.Document,
			ReflectionParameters.Query);
		
		If Not Object = Undefined Then
			DescriptionOfAdditionalTables = ReflectionParameters.ManagerOfDocument.GenerateAdditionalTablesOfCostAndCostAccountingOperations(
				Object,
				ReflectionParameters.Query,
				ReflectionParameters.QueryTexts);
			
			DescriptionOfDocumentOperations = ReflectionParameters.ManagerOfDocument.DescriptionOfCostAccountingOperations(
				Object);
		Else
			DescriptionOfAdditionalTables = ReflectionParameters.ManagerOfDocument.GenerateAdditionalTablesOfCostAndCostAccountingOperations(
				ReflectionParameters.Document,
				ReflectionParameters.Query,
				ReflectionParameters.QueryTexts);
			
			DescriptionOfDocumentOperations = ReflectionParameters.ManagerOfDocument.DescriptionOfCostAccountingOperations(
				ReflectionParameters.Document);
		EndIf;
		
		RegisterDescription.Insert("RegisterMetadata", 			  RegisterMetadata);
		RegisterDescription.Insert("RegisterFields", 			  		  AllRegisterFields(RegisterMetadata));
		RegisterDescription.Insert("AdditionalParameterDescription", AdditionalParameterDescription);
		RegisterDescription.Insert("DescriptionOfAdditionalTables", 	  DescriptionOfAdditionalTables);
		RegisterDescription.Insert("DescriptionOfDocumentOperations", 		  DescriptionOfDocumentOperations);
		
		ReflectionParameters.RegistersForReflection.Insert(RegisterName, RegisterDescription);
		
		// We will form the request texts to be reflected in the cost accounting.
		ReflectTransactionsInCostAccounting(ReflectionParameters);
		
	EndIf;
	
	// Revenue
	RegisterMetadata = Metadata.AccumulationRegisters.RevenueAndCOGS;
	RegisterName 	   = RegisterMetadata.Name;
	
	If DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, ReflectionParameters.Registers)
	 And ReflectionParameters.ManagerOfDocument.DescriptionOfCostAndCostRegisters(ReflectionParameters.Document).Find(RegisterMetadata) <> Undefined Then
	
		ReflectionParameters.Insert("RegisterName", RegisterName);
		
		RegisterDescription = New Structure;
		
		If Not ValueIsFilled(AdditionalParameterDescription) Then
			AdditionalParameterDescription = ReflectionParameters.ManagerOfDocument.SetAdditionalParametersForCostAndCostAccountingOperations(
				ReflectionParameters.Document,
				ReflectionParameters.Query);
		EndIf;
		
		If Not ValueIsFilled(DescriptionOfAdditionalTables) Then
			DescriptionOfAdditionalTables = ReflectionParameters.ManagerOfDocument.GenerateAdditionalTablesOfCostAndCostAccountingOperations(
				ReflectionParameters.Document,
				ReflectionParameters.Query,
				ReflectionParameters.QueryTexts);
		EndIf;
		
		DescriptionOfDocumentOperations = ReflectionParameters.ManagerOfDocument.DescriptionOfRevenueAccountingOperations(
			ReflectionParameters.Document);
		
		RegisterDescription.Insert("RegisterMetadata", 			  RegisterMetadata);
		RegisterDescription.Insert("AdditionalParameterDescription", AdditionalParameterDescription);
		RegisterDescription.Insert("DescriptionOfAdditionalTables", 	  DescriptionOfAdditionalTables);
		RegisterDescription.Insert("DescriptionOfDocumentOperations", 		  DescriptionOfDocumentOperations);
		
		ReflectionParameters.RegistersForReflection.Insert(RegisterName, RegisterDescription);
		
	EndIf;
	
EndProcedure

// Adds a description of the operation to reflect.
//
// Parameters:
//	DescriptionOfOperations - Array -
//	OperationKind  - EnumRef.CostAccountingTransactions -
//	QueryText - String -
//	OperationDescription - String -
//	
Procedure AddDescriptionOfTransactionForCostAccounting(DescriptionOfOperations, OperationKind, QueryText, OperationDescription = "") Export
	
	CurrentOperation = New Structure;
	
	CurrentOperation.Insert("OperationKind",  	 OperationKind);
	CurrentOperation.Insert("QueryText", 	 QueryText);
	CurrentOperation.Insert("OperationNumber", 	 0);
	CurrentOperation.Insert("OperationDescription", OperationDescription);
	
	DescriptionOfOperations.Add(CurrentOperation);
	
EndProcedure

#EndRegion

#Region Private

#Region DescriptionOfOperations

Function GenerateDescriptionOfOperation(RegisterMetadata) Export
	
	LongDesc = New Structure;
	Fields 	 = New Array;
	
	// General and service fields.
	AddDescriptionOfOperationField(RegisterMetadata, Fields, "Period");
	AddDescriptionOfOperationField(RegisterMetadata, Fields, "Ref");
	AddDescriptionOfOperationField(RegisterMetadata, Fields, "DocumentToBeCorrected",, True);
	
	AddDescriptionOfOperationField(RegisterMetadata, Fields, "BusinessOperation");
	AddDescriptionOfOperationField(RegisterMetadata, Fields, "FinRecordID");
	AddDescriptionOfOperationField(RegisterMetadata, Fields, "BusinessTransactionSetting");
	
	LongDesc.Insert("Fields", Fields);
	LongDesc.Insert("OperationKind", Undefined);
	
	Return LongDesc;
	
EndFunction

Procedure AddDescriptionOfOperationField(RegisterMetadata, Fields, FieldName, DefaultFieldType = Undefined, Additional = False)
	
	FieldDetails = New Structure;
	FieldDetails.Insert("Name", FieldName);
	
	FieldType = Undefined;
	
	If DefaultFieldType <> Undefined Then
		
		FieldType = DefaultFieldType;
		
	ElsIf Lower(FieldName) = Lower("Period") Then
		
		FieldType = RegisterMetadata.StandardAttributes["Period"].Type;
		
	ElsIf Lower(FieldName) = Lower("Ref") Then
		
		FieldType = RegisterMetadata.StandardAttributes["Recorder"].Type;
		
	Else
		
		FieldMetadata = RegisterMetadata.Dimensions.Find(FieldName);
		
		If FieldMetadata <> Undefined Then
			FieldType = FieldMetadata.Type;
		Else
			
			FieldMetadata = RegisterMetadata.Resources.Find(FieldName);
			
			If FieldMetadata <> Undefined Then
				FieldType = FieldMetadata.Type;
			Else
				
				FieldMetadata = RegisterMetadata.Attributes.Find(FieldName);
				
				If FieldMetadata <> Undefined Then
					FieldType = FieldMetadata.Type;
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	FieldDetails.Insert("Type", FieldType);
	FieldDetails.Insert("Additional", Additional);
	
	Fields.Add(FieldDetails);
	
EndProcedure

Procedure AddDescriptionOfFinancialAccountingAnalyticsFields(RegisterMetadata, OperationDescription, ProductsGroupRequired_ = True)
	
	AddDescriptionOfOperationField(
		RegisterMetadata,
		OperationDescription.Fields,
		"SalesOpportunity",
		New TypeDescription("CatalogRef.SalesOpportunitiesToCustomer"));
	
	AddDescriptionOfOperationField(
		RegisterMetadata,
		OperationDescription.Fields,
		"Department",
		New TypeDescription("CatalogRef.BusinessStructure"));
	
	AddDescriptionOfOperationField(
		RegisterMetadata,
		OperationDescription.Fields,
		"Manager",
		New TypeDescription("CatalogRef.Users"));
	
	AddDescriptionOfOperationField(
		RegisterMetadata,
		OperationDescription.Fields,
		"ProductsGroup",
		New TypeDescription("CatalogRef.AnalyticalInventoryGroups"),
		Not ProductsGroupRequired_);
	
EndProcedure

Procedure AddDescriptionOfTotalCostFields(RegisterMetadata, OperationDescription)
	
	AddDescriptionOfOperationField(
		RegisterMetadata,
		OperationDescription.Fields,
		Metadata.AccumulationRegisters.InventoryCost.Resources.Cost.Name);
	
	AddDescriptionOfOperationField(
		RegisterMetadata,
		OperationDescription.Fields,
		Metadata.AccumulationRegisters.InventoryCost.Resources.CostExcludingVAT.Name);
	
	AddDescriptionOfOperationField(
		RegisterMetadata,
		OperationDescription.Fields,
		Metadata.AccumulationRegisters.InventoryCost.Resources.LocalCost.Name);
	
	AddDescriptionOfOperationField(
		RegisterMetadata,
		OperationDescription.Fields,
		Metadata.AccumulationRegisters.InventoryCost.Attributes.VATLocal.Name);
	
	AddDescriptionOfOperationField(
		RegisterMetadata,
		OperationDescription.Fields,
		Metadata.AccumulationRegisters.InventoryCost.Resources.CostMan.Name);
	
	AddDescriptionOfOperationField(
		RegisterMetadata,
		OperationDescription.Fields,
		Metadata.AccumulationRegisters.InventoryCost.Attributes.VATManag.Name);
	
	AddDescriptionOfOperationField(
		RegisterMetadata,
		OperationDescription.Fields,
		Metadata.AccumulationRegisters.InventoryCost.Resources.OffBalanceCost.Name);
	
	AddDescriptionOfOperationField(
		RegisterMetadata,
		OperationDescription.Fields,
		Metadata.AccumulationRegisters.InventoryCost.Resources.OffBalanceCostLocal.Name);
	
	AddDescriptionOfOperationField(
		RegisterMetadata,
		OperationDescription.Fields,
		Metadata.AccumulationRegisters.InventoryCost.Resources.AddExpensesForGoods.Name);
	
	AddDescriptionOfOperationField(
		RegisterMetadata,
		OperationDescription.Fields,
		Metadata.AccumulationRegisters.InventoryCost.Resources.AdditionalExpensesExcludingVAT.Name);
	
	AddDescriptionOfOperationField(
		RegisterMetadata,
		OperationDescription.Fields,
		Metadata.AccumulationRegisters.InventoryCost.Resources.AddExpensesLocal.Name);
		
	AddDescriptionOfOperationField(
		RegisterMetadata,
		OperationDescription.Fields,
		Metadata.AccumulationRegisters.InventoryCost.Resources.AddExpensesMan.Name);
		
	AddDescriptionOfOperationField(
		RegisterMetadata,
		OperationDescription.Fields,
		Metadata.AccumulationRegisters.InventoryCost.Resources.PermanentDifference.Name);
	
	AddDescriptionOfOperationField(
		RegisterMetadata,
		OperationDescription.Fields,
		Metadata.AccumulationRegisters.InventoryCost.Resources.CostTD.Name);
	
	AddDescriptionOfOperationField(
		RegisterMetadata,
		OperationDescription.Fields,
		Metadata.AccumulationRegisters.InventoryCost.Attributes.CorGrossInitialCostENT.Name);
	
	AddDescriptionOfOperationField(
		RegisterMetadata,
		OperationDescription.Fields,
		Metadata.AccumulationRegisters.InventoryCost.Resources.CostOfPersonalIncomeTax.Name);
	
EndProcedure

Procedure AddDescriptionOfSumCostFieldsAbbreviated(RegisterMetadata, OperationDescription, Additional = False)
	
	AddDescriptionOfOperationField(
		RegisterMetadata,
		OperationDescription.Fields,
		Metadata.AccumulationRegisters.InventoryCost.Resources.Cost.Name,,
		Additional);
	
	AddDescriptionOfOperationField(
		RegisterMetadata,
		OperationDescription.Fields,
		Metadata.AccumulationRegisters.InventoryCost.Resources.CostExcludingVAT.Name,,
		Additional);
	
	AddDescriptionOfOperationField(
		RegisterMetadata,
		OperationDescription.Fields,
		Metadata.AccumulationRegisters.InventoryCost.Resources.LocalCost.Name,,
		Additional);
	
	AddDescriptionOfOperationField(
		RegisterMetadata,
		OperationDescription.Fields,
		Metadata.AccumulationRegisters.InventoryCost.Resources.CostMan.Name,,
		Additional);
	
	AddDescriptionOfOperationField(
		RegisterMetadata,
		OperationDescription.Fields,
		Metadata.AccumulationRegisters.InventoryCost.Attributes.CorGrossInitialCostENT.Name,,
		Additional);
	
	AddDescriptionOfOperationField(
		RegisterMetadata,
		OperationDescription.Fields,
		Metadata.AccumulationRegisters.InventoryCost.Resources.OffBalanceCost.Name,
		,
		True);
	
	AddDescriptionOfOperationField(
		RegisterMetadata,
		OperationDescription.Fields,
		Metadata.AccumulationRegisters.InventoryCost.Resources.OffBalanceCostLocal.Name,
		,
		True);
	
	AddDescriptionOfOperationField(
		RegisterMetadata,
		OperationDescription.Fields,
		Metadata.AccumulationRegisters.InventoryCost.Resources.PermanentDifference.Name,
		,
		True);
	
	AddDescriptionOfOperationField(
		RegisterMetadata,
		OperationDescription.Fields,
		Metadata.AccumulationRegisters.InventoryCost.Resources.CostTD.Name,
		,
		True);
	
EndProcedure

Function ThereIsDataTableField(ReflectionParameters, FieldName)
	
	RegisterName = ReflectionParameters.RegisterName;
	ColumnsOfDataTable = ReflectionParameters.RegistersForReflection[RegisterName].ColumnsOfDataTable;
	
	Return ColumnsOfDataTable.Property(FieldName);
	
EndFunction


Function DescriptionOfCostOperationExternalReceipt(ReflectionParameters) Export
	
	RegisterMetadata = ReflectionParameters.RegistersForReflection[ReflectionParameters.RegisterName].RegisterMetadata;
	OperationDescription   = GenerateDescriptionOfOperation(RegisterMetadata);
	
	// Service fields.
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "DocumentSource");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "SourceDocumentPeriod", New TypeDescription("Date"));
	
	// Batch accounting analysis fields.
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "LotVendorAttributes");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "LotVendorAttributesCorr");
	AddDescriptionOfOperationField(
		RegisterMetadata,
		OperationDescription.Fields,
		"Vendor",
		Metadata.Catalogs.KeysForLotVendorAttributes.Attributes.Vendor.Type);
	AddDescriptionOfOperationField(
		RegisterMetadata,
		OperationDescription.Fields,
		"Counterparty",
		Metadata.Catalogs.KeysForLotVendorAttributes.Attributes.Counterparty.Type);
	AddDescriptionOfOperationField(
		RegisterMetadata,
		OperationDescription.Fields,
		"VATRate",
		Metadata.Catalogs.KeysForLotVendorAttributes.Attributes.VATRate.Type);
	
	// Item accounting fields.
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "Organization");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "ItemsLocationAttributes");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "InventoryOwnerAttribute");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "Lot");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "VATActivityType");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "DocumentVATActivityType");
	
	// Corresponding fields.
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CorItemsLocationAttributes");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CorInventoryOwnerAttribute");
	
	// Quantitative and summary indicators.
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "Count");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "RowID");
	
	AddDescriptionOfTotalCostFields(RegisterMetadata, OperationDescription);
	
	// Fields of financial accounting analytics.
	AddDescriptionOfFinancialAccountingAnalyticsFields(RegisterMetadata, OperationDescription, False);
	
	// Optional fields.
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "VariancePeriod", New TypeDescription("Date"), True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "AccountingSection",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CorAccountingSection",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "AccountingDimensionByPartners",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "EntryType",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CorLot",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CostOfPersonalIncomeTax",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CorCompany",, True);
	
	// For the unfactured delivery of works and services
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "ExpenseItemOfWriteOff",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "DimensionOfExpenses",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CorLineOfBusiness",, True);
	
	// They are used only in the document "Entering product balances".
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "ProvisionForImpairmentLocal",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "ProvisionForImpairmentMan",, True);
	
	Return OperationDescription;
	
EndFunction

Function DescriptionOfCostOperationInternalRevenue(ReflectionParameters) Export
	
	RegisterMetadata = ReflectionParameters.RegistersForReflection[ReflectionParameters.RegisterName].RegisterMetadata;
	OperationDescription   = GenerateDescriptionOfOperation(RegisterMetadata);
	
	// Service fields.
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "DocumentSource");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "SourceDocumentPeriod", New TypeDescription("Date"));
	
	// Batch accounting analysis fields.
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "LotVendorAttributes");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "LotVendorAttributesCorr");
	AddDescriptionOfOperationField(
		RegisterMetadata,
		OperationDescription.Fields,
		"RowCode",
		Metadata.Catalogs.KeysForLotVendorAttributes.Attributes.RowCode.Type);
	
	// Item accounting fields.
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "Organization");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "ItemsLocationAttributes");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "InventoryOwnerAttribute");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "Lot");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "VATActivityType");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "DocumentVATActivityType");
	
	// Corresponding fields.
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CorItemsLocationAttributes");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CorInventoryOwnerAttribute");
	AddDescriptionOfOperationField(
			RegisterMetadata,
			OperationDescription.Fields,
			"CorGroupOfManufacturedProducts",
			New TypeDescription("CatalogRef.AnalyticalInventoryGroups"));
	
	// Quantitative and summary indicators.
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "Count");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "RowID");
	
	AddDescriptionOfTotalCostFields(RegisterMetadata, OperationDescription);
	
	// Fields of financial accounting analytics.
	AddDescriptionOfFinancialAccountingAnalyticsFields(RegisterMetadata, OperationDescription);
	
	// Optional fields.
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "VariancePeriod", New TypeDescription("Date"), True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "AccountingSection",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CorAccountingSection",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CorLot",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CorVATActivityTypes",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "EntryType",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "DocumentRegisterRecords",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "AccountingDimensionByPartners",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CostOfPersonalIncomeTax",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CorCompany",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CostDefiningMethod",, True);

	// They are used only in the document "Entering product balances".
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "ProvisionForImpairmentLocal",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "ProvisionForImpairmentMan",, True);
	
	Return OperationDescription;
	
EndFunction

Function DescriptionOfTransactionCostDisposalAtFixedCost(ReflectionParameters) Export
	
	RegisterMetadata = ReflectionParameters.RegistersForReflection[ReflectionParameters.RegisterName].RegisterMetadata;
	OperationDescription   = GenerateDescriptionOfOperation(RegisterMetadata);
	
	// Service fields.
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "DocumentSource");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "SourceDocumentPeriod", New TypeDescription("Date"));
	
	// Item accounting fields.
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "Organization");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "ItemsLocationAttributes");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "InventoryOwnerAttribute");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "VATActivityType");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "DocumentVATActivityType");
	
	// Corresponding fields.
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CorItemsLocationAttributes");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CorInventoryOwnerAttribute");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "ExpenseItemAssets");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "AssetExpenseAnalytics");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "IncomeItem");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "DimensionOfRevenue");
	
	// Quantitative and summary indicators.
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "Count");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "RowID");
	
	AddDescriptionOfSumCostFieldsAbbreviated(RegisterMetadata, OperationDescription);
	
	// Fields of financial accounting analytics.
	AddDescriptionOfFinancialAccountingAnalyticsFields(RegisterMetadata, OperationDescription);
	
	// Optional fields.
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "VariancePeriod", New TypeDescription("Date"), True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "AccountingSection",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CorAccountingSection",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "EntryType",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "AccountingDimensionByPartners",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "Lot",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CorLot",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "GLAccountSettings",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CorCompany",, True);
	
	Return OperationDescription;
	
EndFunction

Function DescriptionOfCostOperationMoving(ReflectionParameters) Export
	
	RegisterMetadata = ReflectionParameters.RegistersForReflection[ReflectionParameters.RegisterName].RegisterMetadata;
	OperationDescription   = GenerateDescriptionOfOperation(RegisterMetadata);
	
	// Item accounting fields.
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "Organization");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "ItemsLocationAttributes");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "InventoryOwnerAttribute");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "VATActivityType");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "DocumentVATActivityType");
	
	// Corresponding fields.
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CorCompany");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CorLot");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CorItemsLocationAttributes");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CorInventoryOwnerAttribute");
	
	// Quantitative and summary indicators.
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "Count");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "RowID");
	
	AddDescriptionOfSumCostFieldsAbbreviated(RegisterMetadata, OperationDescription, True);
	
	// Fields of financial accounting analytics.
	AddDescriptionOfFinancialAccountingAnalyticsFields(RegisterMetadata, OperationDescription);
	
	// Optional fields.
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "AccountingSection",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CorAccountingSection",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "LotVendorAttributes",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "SalesOrder",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "Lot",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "AccountingDimensionByPartners",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "VariancePeriod", New TypeDescription("Date"), True);
	
	Return OperationDescription;
	
EndFunction

Function DescriptionOfCostOfSalesOperation(ReflectionParameters) Export
	
	RegisterMetadata = ReflectionParameters.RegistersForReflection[ReflectionParameters.RegisterName].RegisterMetadata;
	OperationDescription   = GenerateDescriptionOfOperation(RegisterMetadata);
	
	// Service fields.
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "DocumentSource");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "SourceDocumentPeriod", New TypeDescription("Date"));
	
	// Item accounting fields.
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "Organization");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "ItemsLocationAttributes");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "InventoryOwnerAttribute");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "VATActivityType");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "DocumentVATActivityType");
	
	// Corresponding fields.
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CorCompany");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CorItemsLocationAttributes");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CorInventoryOwnerAttribute");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CorLot");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "LotVendorAttributesCorr");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "AccountingDimensionByPartners");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "SalesOrder");
	
	// Quantitative and summary indicators.
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "Count");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "RowID");
	
	// Fields of financial accounting analytics.
	AddDescriptionOfFinancialAccountingAnalyticsFields(RegisterMetadata, OperationDescription);
	
	// Optional fields.
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "VariancePeriod", New TypeDescription("Date"), True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "AccountingSection",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CorAccountingSection",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "Cost",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CostExcludingVAT",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "LocalCost",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CostMan",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "OffBalanceCost",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "OffBalanceCostLocal",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "EntryType",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CorVATActivityTypes",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "Lot",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "LotVendorAttributes",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CostDefiningMethod",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "DocumentRegisterRecords",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "SalePeriod",, True);
	
	Return OperationDescription;
	
EndFunction

Function DescriptionOfCostOperationWriteOffToOtherLots(ReflectionParameters) Export
	
	RegisterMetadata = ReflectionParameters.RegistersForReflection[ReflectionParameters.RegisterName].RegisterMetadata;
	OperationDescription   = GenerateDescriptionOfOperation(RegisterMetadata);
	
	// Item accounting fields.
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "Organization");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "ItemsLocationAttributes");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "InventoryOwnerAttribute");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "VATActivityType");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "DocumentVATActivityType");
	
	// Corresponding fields.
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CorCompany");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CorLot");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CorItemsLocationAttributes");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CorInventoryOwnerAttribute");
	
	// Quantitative and summary indicators.
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "Count");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "RowID");
	
	// Fields of financial accounting analytics.
	AddDescriptionOfFinancialAccountingAnalyticsFields(RegisterMetadata, OperationDescription);
	
	// Optional fields.
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "VariancePeriod", New TypeDescription("Date"), True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "AccountingSection",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CorAccountingSection",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "LotVendorAttributesCorr",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "Lot",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "LotVendorAttributes",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "Cost",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CostExcludingVAT",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "LocalCost",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CostMan",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "OffBalanceCost",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "OffBalanceCostLocal",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "VATLocal",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "VATManag",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "EntryType",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CorControllingAttributes",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "FinancialAccountingDimensionOfDocument",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "DocumentRegisterRecords",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CostDefiningMethod",, True);
	
	Return OperationDescription;
	
EndFunction

Function DescriptionOfCostTransactionWriteOffForExpensesAssets(ReflectionParameters) Export
	
	RegisterMetadata = ReflectionParameters.RegistersForReflection[ReflectionParameters.RegisterName].RegisterMetadata;
	OperationDescription   = GenerateDescriptionOfOperation(RegisterMetadata);
	
	// Service fields.
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "DocumentSource");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "SourceDocumentPeriod", New TypeDescription("Date"));
	
	// Item accounting fields.
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "Organization");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "ItemsLocationAttributes");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "InventoryOwnerAttribute");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "VATActivityType");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "DocumentVATActivityType");
	
	// Corresponding fields.
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CorCompany");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CorItemsLocationAttributes");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CorInventoryOwnerAttribute");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "ExpenseItemAssets");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "AssetExpenseAnalytics");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CorLineOfBusiness");
	
	// Quantitative and summary indicators.
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "Count");
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "RowID");
	
	// Fields of financial accounting analytics.
	AddDescriptionOfFinancialAccountingAnalyticsFields(RegisterMetadata, OperationDescription);
	
	// Optional fields.
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "VariancePeriod", New TypeDescription("Date"), True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "AccountingSection",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CorAccountingSection",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "Lot",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "LotVendorAttributes",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CorLot",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "LotVendorAttributesCorr",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "Cost",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CostExcludingVAT",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "LocalCost",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "CostMan",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "EntryType",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "GLAccountSettings",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "AccountingDimensionByPartners",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "SalesOrder",, True);
	AddDescriptionOfOperationField(RegisterMetadata, OperationDescription.Fields, "DocumentRegisterRecords",, True);
	
	Return OperationDescription;
	
EndFunction

Function GetDescriptionOfOperation(ReflectionParameters, OperationKind) Export
	
	If OperationKind = Enums.CostAccountingTransactions.ExternalReceipt Then
		OperationDescription = DescriptionOfCostOperationExternalReceipt(ReflectionParameters);
	ElsIf OperationKind = Enums.CostAccountingTransactions.InternalReceipt Then
		OperationDescription = DescriptionOfCostOperationInternalRevenue(ReflectionParameters);
	ElsIf OperationKind = Enums.CostAccountingTransactions.DisposalAtFixedCost Then
		OperationDescription = DescriptionOfTransactionCostDisposalAtFixedCost(ReflectionParameters);
	ElsIf OperationKind = Enums.CostAccountingTransactions.Move Then
		OperationDescription = DescriptionOfCostOperationMoving(ReflectionParameters);
	ElsIf OperationKind = Enums.CostAccountingTransactions.SaleOfGoodsAndServices Then
		OperationDescription = DescriptionOfCostOfSalesOperation(ReflectionParameters);
	ElsIf OperationKind = Enums.CostAccountingTransactions.ExpensesToOtherProductionLots Then
		OperationDescription = DescriptionOfCostOperationWriteOffToOtherLots(ReflectionParameters);
	ElsIf OperationKind = Enums.CostAccountingTransactions.RecogniseAsExpensesAssets Then
		OperationDescription = DescriptionOfCostTransactionWriteOffForExpensesAssets(ReflectionParameters);
	Else
		OperationDescription = Undefined;
	EndIf;
	
	If OperationDescription <> Undefined Then
		OperationDescription.OperationKind = OperationKind;
	EndIf;
	
	Return OperationDescription;
	
EndFunction

#EndRegion

#Region TransactionTextsCost

#Region Description_ReflectOfOperationsInCostAccounting

// In the procedure to reflect the operation of the Cost Accounting(), the formation of the full text of the request for the
// document on the cost accounting registers is performed.
// Structure of the procedure:
// 1) Temporary tables are formed in accordance with the operations of the document:
// Requests for the formation of temporary tables are described in procedures corresponding to the name of the modular operation:
//	Externalapproach - Reflect the operation_international access() - temporary table of operation_international access
//	Internal Access - Reflect the operation_international access() - Time table_international access_international access_international access_international access_international access_international access_international access_international access_international access_international access_international access_international access_international access_international access_international access
//	Withdrawal of unfixed value- Reflect the operation of the highest value of the withdrawal of Unfixed value() - time table of iteration_Disposals of unfixed value
//	Moving - Reflect the operationsthe value of the move() is a temporary table next_Moving
//	Implementation - Reflect operation_realization() - temporary table_realization OPEration_rEalization
//	Write-off of another Party - Reflect the operation of the highest value of write-off of another Party() - temporary tablereferences_Write-offsother parties
//	Write-off of expended assets - Reflect the operationsthe cost of write-off of expended assets() - temporary tablereferences_Write-offsourcesactivities

// 2) A summary query is generated based on the temporary operation tables of the document.
// Performed in the procedure to add the text of the Movement formationquery().
// Source data: temporary tables
//	- operation_international access
//	- operation_international access
//	- Vtoperation_Disposals of unfixed value
//	- Vtoperation_Moving
//	- ITEration_rEalization
//	- Vtoperation_Write-offsother parties
//	- Vtoperation_Write-offsourcesactivities
// Output data:
//	When using the "Medium-sliding" cost estimation method, a temporary table is generated for the operation of the document.
//	When using other assessment methods, a sample is formed from the original time tables.

// The following items 3 - 9 are performed only when using the cost estimation method "Medium-slip".

#Region Description_ReflectOfOperationsInCostAccounting_AverageSlidingCostCalculation

// 3) Requests for obtaining and calculating the average sliding cost are generated.
// It is performed in the procedure Add a textquery to account for the average sliding cost().

// 3.1) A request for obtaining an average sliding cost is generated.
// Performed in the #Add textquestionareferencesexternal links
// Initial data:
// 	 - temporary table of document operation
// 	 - the Registered Records of the Cur document according to the Accumulation register "Cost of goods"
// Conditions for sampling data from the table of the second document:
//	- Method of estimating the cost of goods = "Medium-slip"
//	- Type of movement = "Expense"
// Performed actions:
//	- It turns out the Balance without specifying the date from the virtual table Balances of the Accumulation register of the "Cost of goods"
//	by the first 4 dimensions (analyticaccountmentcounts, accounting, type of inventory, Organization).
//	- The amounts from the previously generated RegisteredRecorded document are obtained (to save the previously calculated value). 
// Output data: temporary tables
//	- The total cost of the cost is the calculated Balance of the cost 
//	- In the cost identifier table - a table of ids of the FIN record for which the cost price has already been calculated

// 3.2) A cost determination request is generated using the "Medium-slip" method.
// Performed in the area #The area add the text of the query to the value of the average slip
// Source data: temporary tables
// 	- Operation of the document
//	- Vtsebestostostatok 
//	- In the identificatorsreferences
// Actions performed:
//	For Registered Records on new lines of the document, the cost is determined by the Balance of the cost.
//	For Registered Records on lines that this document already had, the cost is determined by its old Registered Records.
// Output data: a temporary table for the calculation of the average sliding
// 
// RESTRICTION: if there are two or more identical lines, there may be a cumulative Balance for rounding error,
// if as a result the entire amount is written off to 0. Such a Balance will be written off at the end of the month or will be taken into account after
// the next purchase of goods.

// 3.3) A cost determination request is generated for the source document.
// Performed in the #Area Add textquery value movementdocumentsource.
// Initial data:
// 	 - temporary table of document operation
// 	 - the Registered Records of the source document according to the Accumulation register "Cost of goods"
// Conditions for sampling data from the table of the second document:
//	Method of estimating the cost of goods = "Medium-slip"
//	Document Source <> Undefined
// Actions performed:
//	The Registered Records of the source document are obtained according to the register "Cost of goods".
// Output data: A temporary table of the value of the source document

// 3.4) A cost calculation request is generated for the source document.
// Executed in the #Area Add a textquestionaccount of the value of the document to the source
// Source data: temporary tables
//	- Operation of the document
//	- All the values of the Source documentation
// Conditions for sampling data from the table of the second document:
//	Method of estimating the cost of goods = "Medium-slip"
//	And
//	(Method of determining the cost = "Movement of the source document" 
//	OR 
//	Operationaccountable cost = "Out of fixed cost" and the method of evaluation is medium-sliding)
// Actions performed:
//	The cost is calculated according to the data of the source document.
// Output data: Temporary table of the movement of the settlement document Source

// 3.5) A request is generated to calculate deviations in the cost.
// Performed in the #Area Add textquestionquestionreferences
// Source data: temporary tables
//	- In the movement of the calculation of the average sliding
//	- In the movement of the settlement to the document source
// Data sampling conditions:
//	Operationaccountable cost = "Out of fixed cost"
// Performed actions:
//	- Deviations of the calculated value from the original value of the document are calculated.
//	- Deviations will be attributed to other income if the deviations are less than 0 (the calculated value is less than the value in the document)
//	- Deviations will be charged to other expenses if the deviations are greater than 0 (the calculated cost is greater than the cost in the document)
// Output data: a temporary table of the movement of the deviation of the cost

// 3.6) The resulting request is generated for the formation of Registered Records according to the register "Cost of goods".
// Performed in the #Add textquestioningstateability area 
// Source data: temporary tables
//	- Operation of the document
//	- In the movement of the calculation of the average sliding
//	- In the movement of the settlement to the document source
//	- In the movement of the worship of the cost
// Actions performed: The resulting RegisteredRecords are formed
//	- with the method of determining the cost of "Publishing a document"
//	- with the method of determining the cost of "Mediocre sliding"
//	- with the method of determining the cost of "Subordination"
//	- with the method of determining the cost of "Movement of the documentary source"
//	- Registered Records of deviations in value are formed.
// Output data:
//	- A temporary table of the following movements of the highest value of goods
//	- Selection from the final table. The structure of the sample fields fully corresponds to the source table of the second document

#EndRegion

#Region Description_ReflectOfOperationsInCostAccounting_MediumSlipFormationOfRegisteredRecords

// In the procedures, corresponding Registered Records are generated for different registers, the initial data for which are
// Registered Records for the "Cost of goods" register.

// 4) There are Registered Recorded movements according to the register "Revenue and cost of sales".
// Performed in the procedure to add a text request to the hand and the value of sales().
// Source data: temporary tables
//	- The following movements are the highest value of goods
//	- Movements of the hands and feet - request for the formation of Registered Records of the Ministry of Health of the document manager module
// Performed actions: in the RegisteredRecords table, the calculated cost price is filled in
// Output data: a sample for the formation of register-based Register Records

// 5) The corresponding Registered Records are formed according to the register "Other expenses".
// It is performed in the procedure Add a textquery of the movement procedure. Inputs().
// Source data: temporary tables
//	- In the movement of the calculation of the average sliding
//	- In the movement of the settlement to the document source
//	- In the movement of adoration of the cost
// Condition for data selection: 
//	(operationaccountingreferences = "Write-offsourcesactivities"
//	OR operationaccountable cost = "Out of fixed cost")
//	And the Description article field is filled in
// Actions performed: a table is being formed to record RegisteredRecorded by register
// Output data: a sample for the formation of register-based Register Records

// 6) The corresponding Registered Records according to the register "Other income" are formed.
// It is performed in the procedure Add a textquery of the movementprochiedoads().
// Source data:
//	- temporary table of the movement of the deviation of the cost
// Data selection condition: the Revenue state_field is filled in
// Actions performed: a table is being formed to record RegisteredRecorded by register
// Output data: a sample for the formation of register-based Register Records

// 7) The corresponding Registered Records are formed according to the register "Assets and liabilities".
// It is performed in the procedure Add a textquery for moving through the activitiesarrays().
// Source data:
//	- a temporary table for the calculation of the average sliding
// Data selection condition:
//	Operationaccountingreferences = "Write-off of expended assets"
//	And the field of Asset statespassults is filled in
// Actions performed: a table is being formed to record Registered Recorded by register
// Output data: a sample for the formation of register-based Register Records

// 8) The corresponding Registered Records are formed according to the register "Registered Records of Other assets and liabilities".
// It is performed in the procedure Add a textquery of the movement to the other active arrays().
// Source data:
//	- a temporary table for the calculation of the average sliding
// Data selection condition:
//	Operationaccountingreferences = "Write-off of expended assets"
//	And the field of Asset statespassults is filled in
// Actions performed: a table is being formed to record Registered Recorded by register
// Output data: a sample for the formation of register-based Register Records

// 9) Correspondents of the Registered Records are formed according to the register "Registered Records of the Nomenclature - Income/Expenses."
// Performed in the procedure Add a textquery for the nomenclature of income expenditure().
// Source data: temporary tables
//	- In the movement of the calculation of the average sliding
//	- In the movement of the settlement to the document source
//	- In the movement of the worship of the cost
// Condition for fetching data from the tables of average-moving and average-moving settlement according to the source document
//	Operationaccountingreferences = "Write-offsourcesactivities"
// Performed actions: a table is being formed to record Registered Recorded by register
// Output data: a sample for the formation of register-based Register Records

#EndRegion

#EndRegion

// Generates a request for conducting a document on the register of cost of goods.
//
// Parameters:
//	Optiondescription-Array-array of operations
//
Procedure ReflectTransactionsInCostAccounting(ReflectionParameters)
	
	RegisterName 	   			= ReflectionParameters.RegisterName;
	DescriptionOfDocumentOperations   = ReflectionParameters.RegistersForReflection[RegisterName].DescriptionOfDocumentOperations;
	
	If DescriptionOfDocumentOperations.Count() = 0 Then
		 Return;
	EndIf;
	
	OperationNumber = 0;
	
	TypesOfDocumentOperations  = New Map;
	DocumentQuerySchemes = New Array;
	
	FieldTable = New ValueTable;
	FieldTable.Columns.Add("Name");
	FieldTable.Columns.Add("Type");
	FieldTable.Columns.Add("PresentInOperations");
	FieldTable.Columns.Add("Additional");
	
	ColumnsOfDataTable = New Structure;
	
	For Each CurDocumentOperation In DescriptionOfDocumentOperations Do
		
		CurDocumentOperation.OperationNumber = OperationNumber;
		OperationNumber = OperationNumber + 1;
		
		// Let's analyze the request scheme of the current operation.
		ParsingRequestSchema = New Structure;
		
		Try
			
			ParsingRequestSchema.Insert("QuerySchema", New QuerySchema);
			
			ParsingRequestSchema.QuerySchema.SetQueryText(CurDocumentOperation.QueryText);
			
			ParsingRequestSchema.Insert("QueryDetails", ParsingRequestSchema.QuerySchema.QueryBatch[ParsingRequestSchema.QuerySchema.QueryBatch.Count() - 1]);
			ParsingRequestSchema.Insert("RequestColumns", New Structure);
			
			For Each CurrentColumn In ParsingRequestSchema.QueryDetails.Columns Do
				ParsingRequestSchema.RequestColumns.Insert(CurrentColumn.Alias);
			EndDo;
			
			ParsingRequestSchema.Insert("OperationKind", CurDocumentOperation.OperationKind);
			
		Except

			ErrorText = NStr("vi = 'Không thể thực hiện phân tích sơ đồ truy vấn số %1 bản ghi kết chuyển chứng từ %2 theo biểu ghi %3';
							|ru = 'Невозможно выполнить разбор схемы запроса №%1 движений документа %2 по регистру %3';
							|en = 'Unable to parse query schema %1 of document register records %2 by register %3'; fa = 'Unable to parse query schema %1 of document register records %2 by register %3';
							|it = 'Impossibile completare l''analisi dello schema di richiesta №%1 dei movimenti del documento %2 per il registro %3';
							|pl = 'Wykonanie rozbioru schematu jest zapytania jest niemożliwe nr%1 ruchów dokumentu %2 wg rejestru %3';
							|tr = 'Sorgunun şeması ayrıştırılamıyor №%1 %3 kaydına göre %2 belge kayıtları '") + ":
				|" + BriefErrorDescription(ErrorInfo());
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				ErrorText,
				OperationNumber,
				ReflectionParameters.MetadataOfDocument.Name,
				ReflectionParameters.RegisterName);
				
			Raise ErrorText;
			
		EndTry;
		
		DocumentQuerySchemes.Add(ParsingRequestSchema);
		
		// Fill in the description of the fields for all types of operations used
		OperationDescription = TypesOfDocumentOperations.Get(CurDocumentOperation.OperationKind);
		ThereIsDescriptionOfOperation = (OperationDescription <> Undefined);
		
		If Not ThereIsDescriptionOfOperation Then
			OperationDescription = GetDescriptionOfOperation(ReflectionParameters, CurDocumentOperation.OperationKind);
		EndIf;
		
		CheckFieldsOfDataFetchRequest(ReflectionParameters, OperationDescription, ParsingRequestSchema);
		
		If ThereIsDescriptionOfOperation Then
			Continue;
		EndIf;
		
		If OperationDescription = Undefined Then
			
			ErrorText = NStr("vi = 'Sai giao dịch tính giá vốn đối với chứng từ ""%1""';
							|ru = 'Некорректная операция учета себестоимости для документа ""%1""';
							|en = 'Incorrect cost accounting transaction for document ""%1""'; fa = 'Incorrect cost accounting transaction for document ""%1""';
							|it = 'Operazione di calcolo errata del costo di produzione per il documento ""%1""';
							|pl = 'Niepoprawna operacja ewidencji kosztów własnych dla dokumentu ""%1""';
							|tr = '""%1"" belgesi için hatalı maliyet muhasebesi işlemi'");
			
			If ValueIsFilled(ReflectionParameters.Document) Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					ErrorText,
					TrimAll(ReflectionParameters.Document));
			Else
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					ErrorText,
					ReflectionParameters.MetadataOfDocument);
				
			EndIf;
			
			Raise ErrorText; // incorrect cost accounting operation
			
		EndIf;
		
		For Each FieldDetails In OperationDescription.Fields Do
			
			If ColumnsOfDataTable.Property(FieldDetails.Name) Then
				FieldString = FieldTable[ColumnsOfDataTable[FieldDetails.Name]];
			Else
				FieldString = Undefined;
			EndIf;
			
			If FieldString = Undefined Then
				
				FieldString = FieldTable.Add();
				FieldString.Name = FieldDetails.Name;
				FieldString.Type = ?(FieldDetails.Type = Undefined, New TypeDescription, FieldDetails.Type);
				FieldString.PresentInOperations = New Map;
				FieldString.Additional = New Map;
				
				ColumnsOfDataTable.Insert(FieldDetails.Name, FieldTable.Count() - 1);
				
			Else
				
				If FieldDetails.Type <> Undefined Then
					FieldString.Type = New TypeDescription(FieldString.Type, FieldDetails.Type.Types());
				EndIf;
				
			EndIf;
			
			FieldString.PresentInOperations.Insert(CurDocumentOperation.OperationKind, True);
			
			If FieldDetails.Additional Then
				FieldString.Additional.Insert(CurDocumentOperation.OperationKind, True);
			EndIf;
			
		EndDo;
		
		TypesOfDocumentOperations.Insert(CurDocumentOperation.OperationKind, OperationDescription);
		
	EndDo;
	
	ReflectionParameters.RegistersForReflection[RegisterName].Insert("FieldTable",  			FieldTable);
	ReflectionParameters.RegistersForReflection[RegisterName].Insert("ColumnsOfDataTable",  	ColumnsOfDataTable);
	ReflectionParameters.RegistersForReflection[RegisterName].Insert("DocumentQuerySchemes",	DocumentQuerySchemes);
	ReflectionParameters.RegistersForReflection[RegisterName].Insert("TypesOfDocumentOperations", 	TypesOfDocumentOperations);
	
	ReflectionParameters.Insert("ReflectionTemplateTexts",  	 New Structure);
	ReflectionParameters.Insert("TTTemplateTexts", 			 New Structure);
	ReflectionParameters.Insert("TextsOfDocumentDataRequests", New Structure);
	
	AddQueryTextToDataTable(ReflectionParameters);
	
	For Each CurDocumentOperation In TypesOfDocumentOperations Do
		
		// We will form the Query Text of the formation of a temporary table of operation reflection of the document.
		If CurDocumentOperation.Key = Enums.CostAccountingTransactions.ExternalReceipt Then
			ReflectCostOperationExternalRevenue(ReflectionParameters);
		ElsIf CurDocumentOperation.Key = Enums.CostAccountingTransactions.InternalReceipt Then
			ReflectCostOperationInternalRevenue(ReflectionParameters);
		ElsIf CurDocumentOperation.Key = Enums.CostAccountingTransactions.DisposalAtFixedCost Then
			ReflectTransactionCostDisposalAtFixedCost(ReflectionParameters);
		ElsIf CurDocumentOperation.Key = Enums.CostAccountingTransactions.Move Then
			ReflectCostTransaction(ReflectionParameters);
		ElsIf CurDocumentOperation.Key = Enums.CostAccountingTransactions.SaleOfGoodsAndServices Then
			ReflectCostOperation(ReflectionParameters);
		ElsIf CurDocumentOperation.Key = Enums.CostAccountingTransactions.ExpensesToOtherProductionLots Then
			ReflectTransactionCostWriteOffToOtherParties(ReflectionParameters);
		ElsIf CurDocumentOperation.Key = Enums.CostAccountingTransactions.RecogniseAsExpensesAssets Then
			ReflectCostTransactionWriteOffToExpensesAssets(ReflectionParameters);
		EndIf;
		
	EndDo;
	
	// Add the Query Text of the document data selection (or document processing generation when using medium-slip)
	AddMotionGenerationRequestText(ReflectionParameters);
	
	If ReflectionParameters.MediumSlipIsUsed Then
		
		// Additional summative Registered Records are calculated and the Query Text of the document data sample is generated
		AddQueryTextCalculationAverageSlidingCost(ReflectionParameters);
		AddQueryTextOfRegisteredRecordsRevenueAndCostOfGoodsSold(ReflectionParameters);
		AddQueryTextOfRegisteredRecordsOfOtherExpenses(ReflectionParameters);
		AddQueryTextOfRegisteredRecordsOtherIncome(ReflectionParameters);
		AddQueryTextOfRegisteredRecordsCorOtherAssetsLiabilities(ReflectionParameters);
		AddQueryTextOfRegisteredRecordsForOtherAssetsLiabilities(ReflectionParameters);
		AddQueryTextOfRegisteredRecordsItemIncomeExpenses(ReflectionParameters);
		AddQueryTextOfRegisteredRecordsItemItem(ReflectionParameters);
		AddQueryTextForDeviationsInCostOfGoods(ReflectionParameters);
		
	EndIf;
	
	SetAdditionalRequestParameters(ReflectionParameters);
	
	// We will supplement the texts of the requests for the document.
	DocumentsPosting.AddDocumentReflectionRequest(
		ReflectionParameters.Query,
		ReflectionParameters.QueryTexts,
		ReflectionParameters.ReflectionTemplateTexts,
		ReflectionParameters.TextsOfDocumentDataRequests,
		ReflectionParameters.TTTemplateTexts);
	
EndProcedure

#Region Description_TransactionTextsCost

// The general rules for filling in the fields in the Register Recorded by the register "Cost of goods" are described.
// 
// Rules for filling in the "Accounting" field:
// - "Materials received for processing" - type of stocks "MaterialDavalets" and type of storage place "Warehouse" or "Subdivision";
// - "Material received for processing the form of the list" - the type of stocks "MaterialDavaltsa" and only for the following households. Operations:
// 		Write-offsdavaltsaschetdavalts,
// 		Write-offsesdavaltsanarayouts;
// - "Materials received and processed transferred to partners" - type of stocks "MaterialDavaltsa" and type of storage place "Contract"
// 	with the type of Contract "SPereobotchikom2_5" or "SPEREOBOTCHIKOM2_5_EPP";
// - "Incomplete production" - if the "Batch" field contains a link to the "Batch Production" Catalog,
// 	production batches can only be reflected in this accounting section;
// - "Unfactuated deliveries" - the type of stocks "Own goods without actual delivery", but it cannot
// 	be determined for services, therefore, it is determined for them by the household. operations:
// 		Purchasing in the countryaesnotfactuated delivery,
// 		Procurementposterthe actual delivery,
// 		procurementposterfactuation of delivery,
// 		Purchasing in the countryaesfakturovkapostavki;
// - "Production costs" - the type of nomenclature "Work" or "Service", or the type of storage location "Warehouse" with the Attribute
// 	"Shop warehouse" = True, or the type of storage location "Subdivision";
// - "Own goods way" - type of stocks "Own goods way";
// - "Own goods transferred to partners" - type of storage place "Contract" with the type of Contract "With the custodian";
// - "Goods halfway" - is determined only by the farm. operations "Realizationwithout the transition of ownership";
// - "Inventory" - the type of inventory "Goods" and the type of storage location "Warehouse", as a rule, is set when
// 	the other options did not fit;
// - "Inventory safekeeping" - the type of inventory "Inventory safekeeping" and the type of storage location is not "Contract";
// - "Inventory safekeeping and Clearance of sales" - type of inventory "Inventory safekeeping and clearance of sales" and only for the following households. Operations:
// 		Registration of inventory items in the depositor's use,
// 		Write-off of accepted goods from the depositor's account,
// 		Write-off of accepted goods expenses,
// 		Write-offs of goods,
// 		Write-off of the depositor's paycheck,
// 		Write-off of the processor's salesreferences,
// 		Re-sorting of goods,
// 		Re-sorting of goods by re-evaluation,
// 		Damaged goods,
// 		Spoilage of goods by overestimation;
// - "Commodity storage and right of sale transferred to partners" - type of stocks "Commodity storage and right of sale" and type
// 	of storage place "Contract" with type of Contract not "SPereobotchikom2_5" and not "SPEREOBOTCHIKOM2_5_EPP";
// - "Goods transferred to the commission" - the type of inventory "Goods" and the type of storage location "Contract" with the type "Joint commission".
// 	Such a definition is valid only for the new commission, for the old commission, a definition is possible only for the farm. operations:
// 		Inputstatements of goods transferred to the commission,
// 		Using the subscriber's inventory listingreferences,
// 		Write-offseddostachsaccountcommittee,
// 		Write-offsecommissioner's worksreferences,
// 		Realizationreferences,
// 		Realizationreferencesexamination of ownership,
// 		Return of goods through the Commissionaire,
// 		Commissioner's return,
// 		Transferring a video message,
// 		Transferring a message to another organization,
// 		Commissionaire's Report,
// 		Registration Commission Report;
// - "The goods transferred by the Wayside commission" - is determined only by the farm. Operations "realizationreferencesexamination of ownership";
// - "Goods transferred to the processor" - the type of storage location "Contract" with the type of Contract "SPereobotchikom2_5" and "SPEREOBOTCHIKOM2_5_EPP",
// 	while the type of nomenclature is not a job or a service.
// 	Such a definition is valid only for new processing, for old processing it is possible to determine only by household goods. operations:
// 		Inputting the data of the materials transferred to the processors,
// 		Re-sorting the goods of the processor,
// 		Write-off of the processor's salesreferences,
// 		The return processer,
// 		The receipt of the processor,
// 		Spoilage of the processor's goods,
// 		Transfer to the processor,
// 		Repurchase of goods by the processor;
// - "Merchandise received by commission" - inventory type "Commission goods";
// - "Goods received by the Commission at the Way" - type of inventory "Commission goods" and only for the following households. Operations:
// 		realizationreferencesexternal links,
// 		Realizationreferencesexamination of ownership;
// - "Goods received for storage" - the type of stocks "Semi-finished goods" or "Products" and the type of storage place "Warehouse" or "Subdivision";
// - "Goods received for storage and formalization of the inventory" - the type of stocks "Semi-finished goods" or "Products" and only for the following households. Operations:
// 		Write-offsdavaltsaschetdavalts,
// 		Write-offsesdavaltsanarayouts;
// - "Goods received and stored transferred to partners" - the type of stocks "Semi-finished goods" or "Products"
// 	and the type of storage place "Contract" with the type of Contract "SPereobotchikom2_5" or "SPEREOBOTCHIKOM2_5_EPP".

#EndRegion

Procedure ReflectCostOperationExternalRevenue(ReflectionParameters)
	
	// Let's form a template of the request text to reflect the operation.
	ReflectionRequestText =
	"SELECT
	|	DocumentData.OperationNumber AS OperationNumber,
	// Document description
	|	CASE
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.ImportFromEAEUUninvoicedDelivery),
	|		   VALUE(Enum.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery))
	|		  AND DocumentData.ThereIsRequestField_AccountingSection
	|		  AND DocumentData.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
	|			THEN VALUE(AccumulationRecordType.Expense)
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.ReturnOfGoodsToVendor))
	|		  AND VALUETYPE(DocumentData.Ref) IN (TYPE(Document.VendorInvoice))
	|			THEN VALUE(AccumulationRecordType.Expense)
	|			ELSE VALUE(AccumulationRecordType.Receipt)
	|	END									AS RecordType,
	|	DocumentData.Period 					AS Period,
	|	DocumentData.SourceDocumentPeriod AS SourceDocumentPeriod,
	|	(CASE
	|		WHEN DocumentData.ThereIsRequestField_VariancePeriod
	|			THEN DocumentData.VariancePeriod
	|		 ELSE DATETIME(1,1,1) END) AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentData.Organization 															AS Organization,
	|	ISNULL(DocumentData.AnalyticsOfItemInventoryLocationAttributeTT, UNDEFINED) AS ItemsLocationAttributes,
	|	ISNULL(DocumentData.InitialInventoryLocationAttributeTTAnalyticsForItemTypesIsOriginalOne, UNDEFINED) AS AnalysisOfAccountingProductsInitial,
	|	CASE
	|		WHEN DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.OperationService)
	|		  OR DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.Work_5)
	|			  AND NOT DocumentData.CatItemOfTraceableItem
	|			THEN VALUE(Catalog.InventoryKinds.EmptyRef)
	|		ELSE DocumentData.InventoryOwnerAttribute
	|	END									AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN DocumentData.ThereIsRequestField_AccountingSection AND DocumentData.AccountingSection <> UNDEFINED
	|		 AND DocumentData.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
	|			THEN DocumentData.AccountingSection
	|		WHEN DocumentData.Settlement_AccountingSection <> UNDEFINED
	|			THEN DocumentData.Settlement_AccountingSection
	|		WHEN VALUETYPE(DocumentData.Ref) IN (TYPE(Document.OBEntryGoods), TYPE(Document.OBEntry))
	|		  AND DocumentData.DocumentBusinessTransaction = VALUE(Enum.BusinessTransactions.EnterRemainingReceivedVMI)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsAtStorageWithRightOfSale)
	|		WHEN VALUETYPE(DocumentData.Ref) IN (TYPE(Document.OBEntryGoods), TYPE(Document.OBEntry))
	|		  AND DocumentData.DocumentBusinessTransaction = VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent)
	|		WHEN VALUETYPE(DocumentData.Ref) IN (TYPE(Document.OBEntryGoods), TYPE(Document.OBEntry))
	|		 AND DocumentData.DocumentBusinessTransaction = VALUE(Enum.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse) 
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		WHEN VALUETYPE(DocumentData.Ref) IN (TYPE(Document.OBEntryGoods), TYPE(Document.OBEntry))
	|		  AND DocumentData.DocumentBusinessTransaction = VALUE(Enum.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.ReceivingForStorageWithRightOfSale),
	|		   VALUE(Enum.BusinessTransactions.ReceivingForPrincipal))
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsAtStorageWithRightOfSale)
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.SubcontractorReportAdjustment)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
	|		WHEN ISNULL(DocumentData.InventoryLocationAttributeIsOriginalDestinationTypeOfDestination, UNDEFINED) = VALUE(Enum.AssignmentTypes.DeliveryForPrincipal)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsAtStorageWithRightOfSale)
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
	|		   VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt))
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.ConsignmentProcurement))
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.OwnGoodsInTransit)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors)
	|		WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.OwnGoodsOfUninvoicedDelivery)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
	|		WHEN VALUETYPE(DocumentData.Lot) = TYPE(Catalog.ProductionLots)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
	|		WHEN DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
	|		 AND (DocumentData.CatItemKeysContractTypeOfContract = VALUE(Enum.ContractTypes.TransferToTolling2_5)
	|			OR DocumentData.CatItemKeysContractTypeOfContract = VALUE(Enum.ContractTypes.SubcontractingToTheEAEUCountries))
	|		 AND DocumentData.CatProductsTypeOfProducts <> VALUE(Enum.ItemsTypes.Work_5)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller)
	|		WHEN DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.Work_5)
	|			OR DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.OperationService)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		WHEN DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom
	|			OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		WHEN DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsTransferredToPartners)
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|	END 																					AS AccountingSection,
	|	CASE WHEN DocumentData.ThereIsRequestField_CorAccountingSection
	|		THEN DocumentData.CorAccountingSection
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
	|	END 																					AS CorAccountingSection,
	|
	// Corresponding fields
	|	ISNULL(DocumentData.TTCorItemAnalyticsOfInventoryLocationAttribute, UNDEFINED) AS CorItemsLocationAttributes,
	|	ISNULL(DocumentData.TTCorAnalyticsItemInventoryLocationAttributeSource, UNDEFINED) AS CorAnalysisOfAccountingProductsInitial,
	|	CASE
	|		WHEN DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.OperationService)
	|		  OR DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.Work_5)
	|			  AND NOT DocumentData.CatItemOfTraceableItem
	|			THEN VALUE(Catalog.InventoryKinds.EmptyRef)
	|		ELSE DocumentData.CorInventoryOwnerAttribute
	|	END 																					AS CorInventoryOwnerAttribute,
	|
	// Other fields
	|	DocumentData.BusinessOperation 													AS BusinessOperation,
	|	DocumentData.Department 															AS Department,
	|	CASE WHEN DocumentData.ThereIsRequestField_AccountingDimensionByPartners
	|		THEN DocumentData.AccountingDimensionByPartners
	|		ELSE UNDEFINED
	|	END 																					AS AccountingDimensionByPartners,
	|
	// Quantitative and summary indicators
	|	DocumentData.Count 						AS Count,
	|	(CASE
	// When Transferring between organizations, the cost is filled in if the recipient organization applies the average sliding one.
	|		WHEN DocumentData.ThereIsRequestField_CorCompany
	|			THEN (CASE WHEN DocumentData.AccountingPoliciesOfOrganizationsAverageSlidingValuation
	|					THEN DocumentData.Cost ELSE 0 END)
	|		ELSE DocumentData.Cost END)		AS Cost,
	|	(CASE
	|		WHEN DocumentData.ThereIsRequestField_CorCompany
	|			THEN (CASE WHEN DocumentData.AccountingPoliciesOfOrganizationsAverageSlidingValuation
	|					THEN DocumentData.CostExcludingVAT ELSE 0 END)
	|		ELSE DocumentData.CostExcludingVAT END) AS CostExcludingVAT,
	|	DocumentData.LocalCost
	|	+ CASE WHEN NOT DocumentData.AccountingPoliciesOfOrganizationsAverageSlidingValuation
	|		AND (NOT &GenerateVATChargedWhenIncludingInCost
	// In case of non-invoice delivery, VAT is not allocated as a separate Registered Record. 
	|			OR DocumentData.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.ImportFromEAEUUninvoicedDelivery),
	|				VALUE(Enum.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery))
	// There is no separate VAT-inclusion Registered Records for the actual Registered Records.
	|			OR DocumentData.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses))
	|		AND DocumentData.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|		AND (DocumentData.Count <> 0
	|			OR BEGINOFPERIOD(DocumentData.SourceDocumentPeriod, MONTH) = BEGINOFPERIOD(DocumentData.Period, MONTH)
	// In batch accounting 2.1, the inclusion of VAT in the cost is reflected in the resource cost of the register, regardless of the period of the founding document.
	|			OR NOT &Constant_BatchAccountingVersion22
	|			OR DocumentData.Period < BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH))
	|		THEN DocumentData.VATLocal
	|		ELSE 0
	|	END 											AS LocalCost,
	// VAT is not filled in in case of unfactured delivery.
	|	(CASE
	|		WHEN DocumentData.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.ImportFromEAEUUninvoicedDelivery),
	|				VALUE(Enum.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery))
	|			THEN 0
	|		ELSE DocumentData.VATLocal END)		AS VATLocal,
	|	CASE WHEN &Constant_KeepManagementRecordsOfOrganizations
	|		AND DocumentData.Period >= BEGINOFPERIOD(&Constant_StartDateOfManagementAccountingOfOrganizations, MONTH)
	|		AND &Constant_BatchAccountingVersion22
	|		AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN DocumentData.CostMan
	|			+ CASE WHEN NOT DocumentData.AccountingPoliciesOfOrganizationsAverageSlidingValuation
	|				AND (NOT &GenerateVATChargedWhenIncludingInCost
	// In case of non-invoice delivery, VAT is not allocated as a separate Registered Record. 
	|					OR DocumentData.BusinessOperation IN (
	|						VALUE(Enum.BusinessTransactions.ImportFromEAEUUninvoicedDelivery),
	|						VALUE(Enum.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery))
	// There is no separate VAT-inclusion Registered Records for the actual Registered Records.
	|					OR DocumentData.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses))
	|				AND DocumentData.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|				AND (DocumentData.Count <> 0
	|					OR BEGINOFPERIOD(DocumentData.SourceDocumentPeriod, MONTH) = BEGINOFPERIOD(DocumentData.Period, MONTH)
	|					OR NOT &Constant_BatchAccountingVersion22
	|					OR DocumentData.Period < BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH))
	|				THEN DocumentData.VATManag
	|				ELSE 0
	|			END
	|		ELSE 0
	|	END 											AS CostMan,
	|	(CASE
	|		WHEN DocumentData.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.ImportFromEAEUUninvoicedDelivery),
	|				VALUE(Enum.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery))
	|			THEN 0
	|		ELSE DocumentData.VATManag END)			AS VATManag,
	|	DocumentData.OffBalanceCost			AS OffBalanceCost,
	|	DocumentData.OffBalanceCostLocal		AS OffBalanceCostLocal,
	|	CASE WHEN DocumentData.AccountingPoliciesOfOrganizationsAverageSlidingValuation
	|		THEN 0
	|		ELSE DocumentData.AddExpensesForGoods
	|	END 											AS AddExpensesForGoods,
	|	CASE WHEN DocumentData.AccountingPoliciesOfOrganizationsAverageSlidingValuation
	|		THEN 0
	|		ELSE DocumentData.AdditionalExpensesExcludingVAT
	|	END 											AS AdditionalExpensesExcludingVAT,
	|	CASE WHEN DocumentData.AccountingPoliciesOfOrganizationsAverageSlidingValuation
	|		THEN 0
	|		ELSE DocumentData.AddExpensesLocal
	|			+ CASE WHEN
	|				BEGINOFPERIOD(DocumentData.SourceDocumentPeriod, MONTH) < BEGINOFPERIOD(DocumentData.Period, MONTH)
	|				AND &Constant_BatchAccountingVersion22
	|				AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|				AND DocumentData.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|	  			AND DocumentData.Count = 0
	|				AND (NOT &GenerateVATChargedWhenIncludingInCost
	// There is no separate VAT-inclusion Registered Records for the actual Registered Records.
	|					OR DocumentData.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses))
	|				THEN DocumentData.VATLocal
	|				ELSE 0
	|			END
	|	END 											AS AddExpensesLocal,
	|	CASE WHEN &Constant_KeepManagementRecordsOfOrganizations
	|		AND DocumentData.Period >= BEGINOFPERIOD(&Constant_StartDateOfManagementAccountingOfOrganizations, MONTH)
	|		AND &Constant_BatchAccountingVersion22
	|		AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		AND NOT DocumentData.AccountingPoliciesOfOrganizationsAverageSlidingValuation
	|		THEN DocumentData.AddExpensesMan
	|			+ CASE WHEN
	|				BEGINOFPERIOD(DocumentData.SourceDocumentPeriod, MONTH) < BEGINOFPERIOD(DocumentData.Period, MONTH)
	|				AND &Constant_BatchAccountingVersion22
	|				AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|				AND DocumentData.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|	  			AND DocumentData.Count = 0
	|				AND (NOT &GenerateVATChargedWhenIncludingInCost
	// There is no separate VAT-inclusion Registered Records for the actual Registered Records.
	|					OR DocumentData.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses))
	|				THEN DocumentData.VATManag
	|				ELSE 0
	|			END
	|		ELSE 0
	|	END 											AS AddExpensesMan,
	|	CASE WHEN DocumentData.AccountingPoliciesOfOrganizationsAverageSlidingValuation
	|		THEN 0
	|		ELSE DocumentData.PermanentDifference
	|	END 											AS PermanentDifference,
	|	CASE WHEN DocumentData.AccountingPoliciesOfOrganizationsAverageSlidingValuation
	|		THEN 0
	|		ELSE DocumentData.CostTD
	|	END 											AS CostTD,
	// The cost of personal income tax is formed according to the rules of cost TA See Calculation of the cost of personal income tax.Substitute the value of the request
	|	&CostOfPersonalIncomeTax 									AS CostOfPersonalIncomeTax,
	|	DocumentData.ProvisionForImpairmentLocal		AS ProvisionForImpairmentLocal,
	|	CASE WHEN &Constant_KeepManagementRecordsOfOrganizations
	|	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_StartDateOfManagementAccountingOfOrganizations, MONTH)
	|	  AND &Constant_BatchAccountingVersion22
	|	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN DocumentData.ProvisionForImpairmentMan
	|		ELSE 0
	|	END 											AS ProvisionForImpairmentMan,
	|	DocumentData.CorGrossInitialCostENT					AS CorGrossInitialCostENT,
	|
	// Batch accounting fields of version 2.2
	// The "Batch" and "Batch accounting analytics" fields are always filled in in the sections "Unfactured deliveries" and "Own goods in transit (from suppliers)".
	// For goods, the accounting section is determined by the type of inventory, for works and services - by the accounting section defined in the document. 
	|	CASE
	|		WHEN &Constant_BatchAccountingVersion22
	|	  	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|	  	  AND DocumentData.FIFOAccountingPoliciesRollingValuation
	|	 	  OR ISNULL(DocumentData.InventoryOwnerAttributeIsTypeOfInventory, UNDEFINED) = VALUE(Enum.InventoryTypes.OwnGoodsInTransit)
	|	 	  OR ISNULL(DocumentData.InventoryOwnerAttributeIsTypeOfInventory, UNDEFINED) = VALUE(Enum.InventoryTypes.OwnGoodsOfUninvoicedDelivery)
	|		  OR DocumentData.ThereIsRequestField_AccountingSection
	|			AND DocumentData.AccountingSection IN (
	|				VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries),
	|				VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors))
	|			THEN DocumentData.Lot
	|		WHEN VALUETYPE(DocumentData.Lot) = TYPE(Catalog.ProductionLots)
	|			THEN DocumentData.Lot
	|			ELSE UNDEFINED
	|	END 																				AS Lot,
	|	CASE
	|		WHEN &Constant_BatchAccountingVersion22
	|		  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		  AND DocumentData.FIFOAccountingPoliciesRollingValuation
	|	 	  OR ISNULL(DocumentData.InventoryOwnerAttributeIsTypeOfInventory, UNDEFINED) = VALUE(Enum.InventoryTypes.OwnGoodsInTransit)
	|	 	  OR ISNULL(DocumentData.InventoryOwnerAttributeIsTypeOfInventory, UNDEFINED) = VALUE(Enum.InventoryTypes.OwnGoodsOfUninvoicedDelivery)
	|		  OR DocumentData.ThereIsRequestField_AccountingSection
	|			AND DocumentData.AccountingSection IN (
	|				VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries),
	|				VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors))
	|		THEN DocumentData.LotVendorAttributes
	|		ELSE UNDEFINED
	|	END 																				AS LotVendorAttributes,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	// The reason is NOT in front of the given document.Accounting policypolitics Sliding valuation:
	// When accounting for the average cost, the coralitika of the accounting of parties is filled in, it is used for the purposes of VAT accounting
	|	  AND NOT DocumentData.FIFOAccountingPoliciesRollingValuation
	|			THEN DocumentData.LotVendorAttributesCorr
	|	  WHEN DocumentData.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.ImportFromEAEU),
	|		VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
	|		VALUE(Enum.BusinessTransactions.AdditionalExpensesWithLotDocumentSpecification),
	|		VALUE(Enum.BusinessTransactions.AdditionalExpensesWithoutLotDocumentSpecification),
	|		VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredIntercompany))
	|			THEN DocumentData.LotVendorAttributesCorr
	|			ELSE UNDEFINED
	|	END 																				AS LotVendorAttributesCorr,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|			AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN CASE 
	|				WHEN VALUETYPE(DocumentData.Lot) = TYPE(Catalog.ProductionLots)
	|					AND DocumentData.Lot <> VALUE(Catalog.ProductionLots.EmptyRef)
	|					AND CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup <> VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|				THEN CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup
	|				WHEN (ISNULL(DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom, FALSE)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.CounterpartyContract))
	|					AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) = TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Estimated_FinancialAccountingDimension
	|				WHEN NOT (ISNULL(DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom, FALSE)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.CounterpartyContract))
	|					AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) <> TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Estimated_FinancialAccountingDimension
	|				ELSE UNDEFINED
	|			END
	|		WHEN &Constant_BatchAccountingVersion22 AND DocumentData.DocumentBusinessTransaction = VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse) 
	|		THEN DocumentData.Estimated_FinancialAccountingDimension
	|		ELSE UNDEFINED
	|	END 																				AS FinancialAccountingDimension,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|		AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|	THEN CASE 
	|				WHEN VALUETYPE(DocumentData.Lot) = TYPE(Catalog.ProductionLots)
	|					AND DocumentData.Lot <> VALUE(Catalog.ProductionLots.EmptyRef)
	|					AND CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup <> VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|				THEN CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup
	|				WHEN (ISNULL(DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom, FALSE)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.CounterpartyContract))
	|					AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) = TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Estimated_FinancialAccountingDimension
	|				WHEN NOT (ISNULL(DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom, FALSE)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.CounterpartyContract))
	|					AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) <> TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Estimated_FinancialAccountingDimension
	|				ELSE UNDEFINED
	|			END
	|	ELSE UNDEFINED
	|	END 																				AS FinancialAccountingDimensionOfDocument,
	|	CASE WHEN NOT &Constant_BatchAccountingVersion22
	|	  OR DocumentData.Period < BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN UNDEFINED
	|		ELSE DocumentData.VATActivityType
	|	END 																				AS VATActivityType,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN DocumentData.DocumentVATActivityType
	|		ELSE UNDEFINED
	|	END 																				AS DocumentVATActivityType,
	|	CASE
	|	  WHEN DocumentData.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.ProductsRelease),
	|		VALUE(Enum.BusinessTransactions.ReturnOfGoodsToVendor),
	|		VALUE(Enum.BusinessTransactions.AdditionalExpensesWithLotDocumentSpecification),
	|		VALUE(Enum.BusinessTransactions.AdditionalExpensesWithoutLotDocumentSpecification),
	|		VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
	|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt))
	|			THEN DocumentData.VATActivityType
	|	  WHEN DocumentData.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.ImportFromEAEUUninvoicedDelivery),
	|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery))
	|			THEN CASE WHEN &Constant_UseVATAccounting
	|				THEN VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|				ELSE VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|			END
	|			ELSE UNDEFINED
	|	END 																				AS CorVATActivityTypes,
	|
	|	CASE
	|		WHEN DocumentData.ThereIsRequestField_EntryType
	|			THEN DocumentData.EntryType
	|		WHEN VALUETYPE(DocumentData.Ref) = TYPE(Document.ApplicationForImportationOfGoods)
	|			THEN CASE
	|				WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.OwnGoodsOfUninvoicedDelivery)
	|					THEN VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified)
	|				WHEN BEGINOFPERIOD(DocumentData.SourceDocumentPeriod, MONTH) < BEGINOFPERIOD(DocumentData.Period, MONTH)
	|					THEN VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod)
	|					ELSE VALUE(Enum.LotRecordTypes.CostAdjustment)
	|				END
	// Filling in the type of records for an unfactured delivery
	|		WHEN DocumentData.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.ImportFromEAEUUninvoicedDelivery),
	|				VALUE(Enum.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery))
	|			THEN VALUE(Enum.LotRecordTypes.Lot)
	// When adjusting the cost, the record type should be "Additional expenses (the batch is indicated)", because with such an adjustment, filling
	// in batch measurements in the cost of goods must be performed according to the movements of the source document (the document 
	// of purchase of goods and services for the invoice of delivery).
	|		WHEN (ISNULL(DocumentData.InventoryOwnerAttributeIsTypeOfInventory, UNDEFINED) = VALUE(Enum.InventoryTypes.OwnGoodsOfUninvoicedDelivery)
	|		 OR DocumentData.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
	|				VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt))) // for works and services
	|		 AND DocumentData.Count = 0
	|			THEN VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified)
	// When invoicing a delivery, the record type should be "Consumption", because a batch is selected for invoicing, formed
	// by the documents "Receipt of goods to the warehouse" and "Receipt of services to the division". 
	|		WHEN (ISNULL(DocumentData.InventoryOwnerAttributeIsTypeOfInventory, UNDEFINED) = VALUE(Enum.InventoryTypes.OwnGoodsOfUninvoicedDelivery) 
	|		 OR DocumentData.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
	|				VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt))) // for works and services
	|		 AND DocumentData.Count > 0
	|			THEN VALUE(Enum.LotRecordTypes.Consumption)
	// With a decrease in the number of delivery invoices, the type of record should be "Side of consumption", because for such an adjustment
	// , batches written off by the document - basis "Purchase of goods and services" are selected.
	|		WHEN (ISNULL(DocumentData.InventoryOwnerAttributeIsTypeOfInventory, UNDEFINED) = VALUE(Enum.InventoryTypes.OwnGoodsOfUninvoicedDelivery) 
	|		 OR DocumentData.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
	|				VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt))) // for works and services
	|		 AND DocumentData.Count < 0
	|			THEN VALUE(Enum.LotRecordTypes.ConsumptionReverseTransaction)
	|
	|		WHEN VALUETYPE(DocumentData.Ref) IN (
	|		  TYPE(Document.SubcontractorReport2_5))
	|			THEN
	|				CASE 
	|				WHEN DocumentData.BusinessOperation IN
	|		  		  (VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost))
	|					THEN VALUE(Enum.LotRecordTypes.Supplement)
	|				WHEN DocumentData.Period = DocumentData.SourceDocumentPeriod
	|				  AND DocumentData.DocumentSource <> UNDEFINED
	|					THEN VALUE(Enum.LotRecordTypes.Supplement)
	|				WHEN DocumentData.Period = DocumentData.SourceDocumentPeriod
	|				  AND DocumentData.DocumentSource = UNDEFINED
	|					THEN VALUE(Enum.LotRecordTypes.Consumption)
	|				WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
	|				  OR DocumentData.Count < 0
	|					THEN CASE WHEN &Constant_BatchAccountingVersion22
	|	  				  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|						THEN VALUE(Enum.LotRecordTypes.Supplement)
	|						ELSE VALUE(Enum.LotRecordTypes.EmptyRef)
	|					END
	|				END
	|
	|		WHEN VALUETYPE(DocumentData.Lot) = TYPE(Catalog.ProductionLots)
	|			THEN VALUE(Enum.LotRecordTypes.Supplement)
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.AdditionalExpensesWithoutLotDocumentSpecification)
	|			THEN VALUE(Enum.LotRecordTypes.AddExpensesLotIsNotSpecified)
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.AdditionalExpensesWithLotDocumentSpecification)
	|			THEN VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified)
	|		WHEN DocumentData.BusinessOperation IN (
	|		   VALUE(Enum.BusinessTransactions.ReturnOfGoodsToVendor))
	|		  AND VALUETYPE(DocumentData.Ref) IN (
	|				TYPE(Document.VendorInvoice))
	|			THEN VALUE(Enum.LotRecordTypes.Consumption)
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsToVendor)
	|			THEN VALUE(Enum.LotRecordTypes.PurchaseAdjustment)
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
	|		  AND DocumentData.Count = 0
	|		  AND DocumentData.DocumentSource <> UNDEFINED
	|			THEN VALUE(Enum.LotRecordTypes.CostAdjustment)
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
	|		  AND DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.Work_5)
	|		  AND &Constant_BatchAccountingVersion22
	|	  	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|			THEN VALUE(Enum.LotRecordTypes.Lot)
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.DebitNoteForPreviousPeriod)
	|			THEN VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod)
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.GoodsReceiptByGoodsReturn),
	|		   VALUE(Enum.BusinessTransactions.ReceiptFromMaterialProvider2_5))
	|			THEN VALUE(Enum.LotRecordTypes.Lot)
	|		WHEN &Constant_BatchAccountingVersion22
	|	  	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		  OR VALUETYPE(DocumentData.Ref) IN (
	|			TYPE(Document.OBEntry),
	|			TYPE(Document.PurchaseAdjustment))
	|			THEN VALUE(Enum.LotRecordTypes.Lot)
	|		ELSE VALUE(Enum.LotRecordTypes.EmptyRef)
	|	END																				AS EntryType,
	|	VALUE(Enum.CostAccountingTransactions.ExternalReceipt) 				AS CostAccountingTransaction,
	|	CASE
	|		WHEN FALSE
	|			THEN UNDEFINED
	|		ELSE DocumentData.DocumentSource
	|	END																				AS DocumentSource,
	|	CASE
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.GoodsReceiptByGoodsReturn))
	|			THEN DocumentData.Ref
	|			ELSE UNDEFINED
	|	END 																				AS DocumentRegisterRecords,
	|	DocumentData.RowID 						  						AS RowID,
	|	DocumentData.FinRecordID 						  						AS FinRecordID,
	|	DocumentData.BusinessTransactionSetting 				  						AS BusinessTransactionSetting,
	// Optional fields
	|	CASE
	|		WHEN VALUETYPE(DocumentData.ExpenseItemOfWriteOff) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|			THEN DocumentData.ExpenseItemOfWriteOff
	|			ELSE UNDEFINED
	|	END 																					AS ExpenseItemOfWriteOff,
	|	CASE
	|		WHEN VALUETYPE(DocumentData.ExpenseItemOfWriteOff) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|			THEN DocumentData.DimensionOfExpenses
	|			ELSE UNDEFINED
	|	END 																					AS DimensionOfExpenses,
	|	DocumentData.CorLineOfBusiness			    								AS CorLineOfBusiness,
	|	DocumentData.AccountingPoliciesInventoryValuationMethod								AS InventoryValuationMethod,
	|	VALUE(Enum.WaysToCalculateInventoryCost.FromDocument) 				AS CostDefiningMethod
	|INTO TTOperation_ExternalReceipt
	|FROM
	|	TTDocumentData_ AS DocumentData
	|WHERE
	|	DocumentData.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.ExternalReceipt)
	|
	// Inclusion of VAT in the price
	|UNION ALL
	|
	|SELECT
	|	DocumentData.OperationNumber AS OperationNumber,
	// Document description
	|	CASE
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.ImportFromEAEUUninvoicedDelivery),
	|		   VALUE(Enum.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery))
	|		  AND DocumentData.ThereIsRequestField_AccountingSection
	|		  AND DocumentData.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
	|			THEN VALUE(AccumulationRecordType.Expense)
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.ReturnOfGoodsToVendor))
	|		  AND VALUETYPE(DocumentData.Ref) IN (TYPE(Document.VendorInvoice))
	|			THEN VALUE(AccumulationRecordType.Expense)
	|			ELSE VALUE(AccumulationRecordType.Receipt)
	|	END									AS RecordType,
	|	DocumentData.Period 					AS Period,
	|	DocumentData.SourceDocumentPeriod AS SourceDocumentPeriod,
	|	(CASE
	|		WHEN DocumentData.ThereIsRequestField_VariancePeriod
	|			THEN DocumentData.VariancePeriod
	|		 ELSE DATETIME(1,1,1) END) AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentData.Organization 															AS Organization,
	|	ISNULL(DocumentData.AnalyticsOfItemInventoryLocationAttributeTT, UNDEFINED) AS ItemsLocationAttributes,
	|	ISNULL(DocumentData.InitialInventoryLocationAttributeTTAnalyticsForItemTypesIsOriginalOne, UNDEFINED) AS AnalysisOfAccountingProductsInitial,
	|	CASE
	|		WHEN DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.OperationService)
	|		  OR DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.Work_5)
	|			  AND NOT DocumentData.CatItemOfTraceableItem
	|			THEN VALUE(Catalog.InventoryKinds.EmptyRef)
	|		ELSE DocumentData.InventoryOwnerAttribute
	|	END									AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN DocumentData.ThereIsRequestField_AccountingSection AND DocumentData.AccountingSection <> UNDEFINED
	|		 AND DocumentData.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
	|			THEN DocumentData.AccountingSection
	|		WHEN DocumentData.Settlement_AccountingSection <> UNDEFINED
	|			THEN DocumentData.Settlement_AccountingSection
	|		WHEN VALUETYPE(DocumentData.Ref) IN (TYPE(Document.OBEntryGoods), TYPE(Document.OBEntry))
	|		  AND DocumentData.DocumentBusinessTransaction = VALUE(Enum.BusinessTransactions.EnterRemainingReceivedVMI)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsAtStorageWithRightOfSale)
	|		WHEN VALUETYPE(DocumentData.Ref) IN (TYPE(Document.OBEntryGoods), TYPE(Document.OBEntry))
	|		  AND DocumentData.DocumentBusinessTransaction = VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent)
	|		WHEN VALUETYPE(DocumentData.Ref) IN (TYPE(Document.OBEntryGoods), TYPE(Document.OBEntry))
	|		 AND DocumentData.DocumentBusinessTransaction = VALUE(Enum.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse) 
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		WHEN VALUETYPE(DocumentData.Ref) IN (TYPE(Document.OBEntryGoods), TYPE(Document.OBEntry))
	|		  AND DocumentData.DocumentBusinessTransaction = VALUE(Enum.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.ReceivingForStorageWithRightOfSale),
	|		   VALUE(Enum.BusinessTransactions.ReceivingForPrincipal))
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsAtStorageWithRightOfSale)
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.SubcontractorReportAdjustment)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
	|		WHEN ISNULL(DocumentData.InventoryLocationAttributeIsOriginalDestinationTypeOfDestination, UNDEFINED) = VALUE(Enum.AssignmentTypes.DeliveryForPrincipal)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsAtStorageWithRightOfSale)
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
	|		   VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt))
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.ConsignmentProcurement))
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.OwnGoodsInTransit)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors)
	|		WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.OwnGoodsOfUninvoicedDelivery)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
	|		WHEN VALUETYPE(DocumentData.Lot) = TYPE(Catalog.ProductionLots)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
	|		WHEN DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
	|		 AND (DocumentData.CatItemKeysContractTypeOfContract = VALUE(Enum.ContractTypes.TransferToTolling2_5)
	|			OR DocumentData.CatItemKeysContractTypeOfContract = VALUE(Enum.ContractTypes.SubcontractingToTheEAEUCountries))
	|		 AND DocumentData.CatProductsTypeOfProducts <> VALUE(Enum.ItemsTypes.Work_5)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller)
	|		WHEN DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.Work_5)
	|			OR DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.OperationService)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		WHEN DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom
	|			OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		WHEN DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsTransferredToPartners)
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|	END 																					AS AccountingSection,
	|	CASE WHEN DocumentData.ThereIsRequestField_CorAccountingSection
	|		THEN DocumentData.CorAccountingSection
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
	|	END 																					AS CorAccountingSection,
	|
	// Corresponding fields
	|	ISNULL(DocumentData.TTCorItemAnalyticsOfInventoryLocationAttribute, UNDEFINED) AS CorItemsLocationAttributes,
	|	ISNULL(DocumentData.TTCorAnalyticsItemInventoryLocationAttributeSource, UNDEFINED) AS CorAnalysisOfAccountingProductsInitial,
	|	CASE
	|		WHEN DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.OperationService)
	|		  OR DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.Work_5)
	|			  AND NOT DocumentData.CatItemOfTraceableItem
	|			THEN VALUE(Catalog.InventoryKinds.EmptyRef)
	|		ELSE DocumentData.CorInventoryOwnerAttribute
	|	END 																					AS CorInventoryOwnerAttribute,
	|
	// Other fields
	|	DocumentData.BusinessOperation 													AS BusinessOperation,
	|	DocumentData.Department 															AS Department,
	|	CASE WHEN DocumentData.ThereIsRequestField_AccountingDimensionByPartners
	|		THEN DocumentData.AccountingDimensionByPartners
	|		ELSE UNDEFINED
	|	END 																					AS AccountingDimensionByPartners,
	|
	// Quantitative and summary indicators
	|	0												AS Count,
	|	0												AS Cost,
	|	0 												AS CostExcludingVAT,
	|	CASE WHEN DocumentData.Count <> 0
	|	 OR BEGINOFPERIOD(DocumentData.SourceDocumentPeriod, MONTH) = BEGINOFPERIOD(DocumentData.Period, MONTH)
	|		THEN DocumentData.VATLocal
	|		ELSE 0
	|	END 											AS LocalCost,
	|	0												AS VATLocal,
	|	CASE WHEN &Constant_KeepManagementRecordsOfOrganizations
	|	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_StartDateOfManagementAccountingOfOrganizations, MONTH)
	|	  AND &Constant_BatchAccountingVersion22
	|	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|	  AND (DocumentData.Count <> 0
	|	 		OR BEGINOFPERIOD(DocumentData.SourceDocumentPeriod, MONTH) = BEGINOFPERIOD(DocumentData.Period, MONTH))
	|		THEN DocumentData.VATManag
	|		ELSE 0
	|	END 											AS CostMan,
	|	0												AS VATManag,
	|	0												AS OffBalanceCost,
	|	0												AS OffBalanceCostLocal,
	|	0 												AS AddExpensesForGoods,
	|	0 												AS AdditionalExpensesExcludingVAT,
	|	CASE WHEN DocumentData.Count = 0
	|	 AND BEGINOFPERIOD(DocumentData.SourceDocumentPeriod, MONTH) < BEGINOFPERIOD(DocumentData.Period, MONTH)
	|		THEN DocumentData.VATLocal
	|		ELSE 0
	|	END 											AS AddExpensesLocal,
	|	CASE WHEN &Constant_KeepManagementRecordsOfOrganizations
	|	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_StartDateOfManagementAccountingOfOrganizations, MONTH)
	|	  AND &Constant_BatchAccountingVersion22
	|	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|	  AND DocumentData.Count = 0
	|	  AND BEGINOFPERIOD(DocumentData.SourceDocumentPeriod, MONTH) < BEGINOFPERIOD(DocumentData.Period, MONTH)
	|		THEN DocumentData.VATManag
	|		ELSE 0
	|	END 											AS AddExpensesMan,
	|	0												AS PermanentDifference,
	|	0												AS CostTD,
	|	0 												AS CostOfPersonalIncomeTax,
	|	0												AS ProvisionForImpairmentLocal,
	|	0 												AS ProvisionForImpairmentMan,
	|	0												AS CorGrossInitialCostENT,
	|
	// Batch accounting fields of version 2.2
	// The "Batch" and "Batch accounting analytics" fields are always filled in in the sections "Unfactured deliveries" and "Own goods in transit (from suppliers)".
	// For goods, the accounting section is determined by the type of inventory, for works and services - by the accounting section defined in the document. 
	|	CASE
	|		WHEN &Constant_BatchAccountingVersion22
	|	  	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|	  	  AND DocumentData.FIFOAccountingPoliciesRollingValuation
	|	 	  OR ISNULL(DocumentData.InventoryOwnerAttributeIsTypeOfInventory, UNDEFINED) = VALUE(Enum.InventoryTypes.OwnGoodsInTransit)
	|	 	  OR ISNULL(DocumentData.InventoryOwnerAttributeIsTypeOfInventory, UNDEFINED) = VALUE(Enum.InventoryTypes.OwnGoodsOfUninvoicedDelivery)
	|		  OR DocumentData.ThereIsRequestField_AccountingSection
	|			AND DocumentData.AccountingSection IN (
	|				VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries),
	|				VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors))
	|			THEN DocumentData.Lot
	|		WHEN VALUETYPE(DocumentData.Lot) = TYPE(Catalog.ProductionLots)
	|			THEN DocumentData.Lot
	|			ELSE UNDEFINED
	|	END 																				AS Lot,
	|	CASE
	|		WHEN &Constant_BatchAccountingVersion22
	|		  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		  AND DocumentData.FIFOAccountingPoliciesRollingValuation
	|	 	  OR ISNULL(DocumentData.InventoryOwnerAttributeIsTypeOfInventory, UNDEFINED) = VALUE(Enum.InventoryTypes.OwnGoodsInTransit)
	|	 	  OR ISNULL(DocumentData.InventoryOwnerAttributeIsTypeOfInventory, UNDEFINED) = VALUE(Enum.InventoryTypes.OwnGoodsOfUninvoicedDelivery)
	|		  OR DocumentData.ThereIsRequestField_AccountingSection
	|			AND DocumentData.AccountingSection IN (
	|				VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries),
	|				VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors))
	|		THEN DocumentData.LotVendorAttributes
	|		ELSE UNDEFINED
	|	END 																				AS LotVendorAttributes,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	// The reason is NOT in front of the given document.Accounting policypolitics Sliding valuation:
	// When accounting for the average cost, the coralitika of the accounting of parties is filled in, it is used for the purposes of VAT accounting
	|	  AND NOT DocumentData.FIFOAccountingPoliciesRollingValuation
	|			THEN DocumentData.LotVendorAttributesCorr
	|	  WHEN DocumentData.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.ImportFromEAEU),
	|		VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
	|		VALUE(Enum.BusinessTransactions.AdditionalExpensesWithLotDocumentSpecification),
	|		VALUE(Enum.BusinessTransactions.AdditionalExpensesWithoutLotDocumentSpecification),
	|		VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredIntercompany))
	|			THEN DocumentData.LotVendorAttributesCorr
	|			ELSE UNDEFINED
	|	END 																				AS LotVendorAttributesCorr,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|			AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN CASE 
	|				WHEN VALUETYPE(DocumentData.Lot) = TYPE(Catalog.ProductionLots)
	|					AND DocumentData.Lot <> VALUE(Catalog.ProductionLots.EmptyRef)
	|					AND CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup <> VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|				THEN CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup
	|				WHEN (ISNULL(DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom, FALSE)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.CounterpartyContract))
	|					AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) = TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Estimated_FinancialAccountingDimension
	|				WHEN NOT (ISNULL(DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom, FALSE)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.CounterpartyContract))
	|					AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) <> TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Estimated_FinancialAccountingDimension
	|				ELSE UNDEFINED
	|			END
	|		WHEN &Constant_BatchAccountingVersion22 AND DocumentData.DocumentBusinessTransaction = VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryInOurWarehouse) 
	|		THEN DocumentData.Estimated_FinancialAccountingDimension
	|		ELSE UNDEFINED
	|	END 																				AS FinancialAccountingDimension,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|		AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|	THEN CASE 
	|				WHEN VALUETYPE(DocumentData.Lot) = TYPE(Catalog.ProductionLots)
	|					AND DocumentData.Lot <> VALUE(Catalog.ProductionLots.EmptyRef)
	|					AND CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup <> VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|				THEN CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup
	|				WHEN (ISNULL(DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom, FALSE)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.CounterpartyContract))
	|					AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) = TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Estimated_FinancialAccountingDimension
	|				WHEN NOT (ISNULL(DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom, FALSE)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.CounterpartyContract))
	|					AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) <> TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Estimated_FinancialAccountingDimension
	|				ELSE UNDEFINED
	|			END
	|	ELSE UNDEFINED
	|	END 																				AS FinancialAccountingDimensionOfDocument,
	|	CASE WHEN NOT &Constant_BatchAccountingVersion22
	|	  OR DocumentData.Period < BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN UNDEFINED
	|		ELSE DocumentData.VATActivityType
	|	END 																				AS VATActivityType,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN DocumentData.DocumentVATActivityType
	|		ELSE UNDEFINED
	|	END 																				AS DocumentVATActivityType,
	|	CASE
	|	  WHEN DocumentData.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.ProductsRelease),
	|		VALUE(Enum.BusinessTransactions.ReturnOfGoodsToVendor),
	|		VALUE(Enum.BusinessTransactions.AdditionalExpensesWithLotDocumentSpecification),
	|		VALUE(Enum.BusinessTransactions.AdditionalExpensesWithoutLotDocumentSpecification),
	|		VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
	|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt))
	|			THEN DocumentData.VATActivityType
	|	  WHEN DocumentData.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.ImportFromEAEUUninvoicedDelivery),
	|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery))
	|			THEN CASE WHEN &Constant_UseVATAccounting
	|				THEN VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|				ELSE VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|			END
	|			ELSE UNDEFINED
	|	END 																				AS CorVATActivityTypes,
	|
	|	CASE
	|		WHEN DocumentData.ThereIsRequestField_EntryType
	|			THEN DocumentData.EntryType
	// For customs declaration on imports, when VAT is included in the cost, a separate type of record is used,
	// because the document also has Registered Records with the record types "Additional expenses with a batch" or "Additional expenses without a batch". 
	|		WHEN VALUETYPE(DocumentData.Ref) = TYPE(Document.CCDImport)
	|			THEN VALUE(Enum.LotRecordTypes.IncludeVATInCostExpenses)
	
	// When adjusting the cost, the record type should be "Additional expenses (the batch is indicated)", because with such an adjustment, filling
	// in batch measurements in the cost of goods must be performed according to the movements of the source document (the document 
	// of purchase of goods and services for the invoice of delivery).
	|		WHEN (ISNULL(DocumentData.InventoryOwnerAttributeIsTypeOfInventory, UNDEFINED) = VALUE(Enum.InventoryTypes.OwnGoodsOfUninvoicedDelivery)
	|		 OR DocumentData.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
	|				VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt))) // for works and services
	|			THEN VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified)
	|		WHEN VALUETYPE(DocumentData.Lot) = TYPE(Catalog.ProductionLots)
	|			THEN VALUE(Enum.LotRecordTypes.Supplement)
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.AdditionalExpensesWithoutLotDocumentSpecification)
	|			THEN VALUE(Enum.LotRecordTypes.AddExpensesLotIsNotSpecified)
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.AdditionalExpensesWithLotDocumentSpecification)
	|			THEN VALUE(Enum.LotRecordTypes.AddExpensesLotIsSpecified)
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsToVendor)
	|			THEN VALUE(Enum.LotRecordTypes.CostAdjustment)
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
	|		  AND DocumentData.Count = 0
	|		  AND DocumentData.DocumentSource <> UNDEFINED
	|			THEN VALUE(Enum.LotRecordTypes.CostAdjustment)
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.DebitNoteForPreviousPeriod)
	|			THEN VALUE(Enum.LotRecordTypes.DebitNoteForPreviousPeriod)
	|		ELSE VALUE(Enum.LotRecordTypes.Lot)
	|	END																				AS EntryType,
	|	VALUE(Enum.CostAccountingTransactions.ExternalReceipt) 				AS CostAccountingTransaction,
	|	CASE
	// For an unfactated delivery in Registered Records for the inclusion of VAT in the cost, the type of record of additional charges by the party is indicated.
	// The Document Source field must be filled in for the Additional Expenses by Party record type.
	|		WHEN (ISNULL(DocumentData.InventoryOwnerAttributeIsTypeOfInventory, UNDEFINED) = VALUE(Enum.InventoryTypes.OwnGoodsOfUninvoicedDelivery)
	|		 OR DocumentData.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
	|				VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt))) // for works and services
	|			THEN DocumentData.Ref
	|		ELSE DocumentData.DocumentSource
	|	END																				AS DocumentSource,
	|	CASE
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.GoodsReceiptByGoodsReturn))
	|			THEN DocumentData.Ref
	|			ELSE UNDEFINED
	|	END 																				AS DocumentRegisterRecords,
	|	DocumentData.RowID 						  						AS RowID,
	|	DocumentData.RowID 						  						AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses)			AS BusinessTransactionSetting,
	// Optional fields
	|	CASE
	|		WHEN VALUETYPE(DocumentData.ExpenseItemOfWriteOff) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|			THEN DocumentData.ExpenseItemOfWriteOff
	|			ELSE UNDEFINED
	|	END 																					AS ExpenseItemOfWriteOff,
	|	CASE
	|		WHEN VALUETYPE(DocumentData.ExpenseItemOfWriteOff) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|			THEN DocumentData.DimensionOfExpenses
	|			ELSE UNDEFINED
	|	END 																					AS DimensionOfExpenses,
	|	DocumentData.CorLineOfBusiness			    								AS CorLineOfBusiness,
	|	DocumentData.AccountingPoliciesInventoryValuationMethod								AS InventoryValuationMethod,
	|	VALUE(Enum.WaysToCalculateInventoryCost.FromDocument) 				AS CostDefiningMethod
	|FROM
	|	TTDocumentData_ AS DocumentData
	|WHERE
	|	DocumentData.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.ExternalReceipt)
	|	AND NOT DocumentData.AccountingPoliciesOfOrganizationsAverageSlidingValuation
	|	AND &GenerateVATChargedWhenIncludingInCost
	|	AND DocumentData.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|	AND (DocumentData.VATLocal <> 0 OR DocumentData.VATManag <> 0)
	// In case of non-invoice delivery, VAT is not allocated as a separate Registered Record. 
	|	AND NOT DocumentData.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.ImportFromEAEUUninvoicedDelivery),
	|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery))
	// There is no separate VAT-inclusion Registered Records for the actual Registered Records.
	|	AND DocumentData.BusinessTransactionSetting <> VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses)
	// In case of non-invoice delivery of works and services, VAT is not allocated to individual Registered Records.
	|	AND NOT (DocumentData.ThereIsRequestField_AccountingSection
	|		AND DocumentData.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
	|		AND DocumentData.InventoryOwnerAttribute = VALUE(Catalog.InventoryKinds.EmptyRef))
	|";
	
	CalculationOfCostLocalization.SubstituteCostOfPersonalDataRequest(ReflectionRequestText, "TTOperation_ExternalReceipt");
	
	ReflectionRequestText = StrReplace(ReflectionRequestText, "&CostOfPersonalIncomeTax", "0");
	
	ReflectionParameters.TTTemplateTexts.Insert("TTOperation_ExternalReceipt", ReflectionRequestText);
	
EndProcedure

Procedure ReflectCostOperationInternalRevenue(ReflectionParameters)
	
	// Let's form a template of the request text to reflect the operation.
	ReflectionRequestText =
	"SELECT
	|	DocumentData.OperationNumber AS OperationNumber,
	// Document description
	|	VALUE(AccumulationRecordType.Receipt)	AS RecordType,
	|	DocumentData.Period 					AS Period,
	|	(CASE
	|		WHEN DocumentData.ThereIsRequestField_VariancePeriod
	|			THEN DocumentData.VariancePeriod
	|		 ELSE DATETIME(1,1,1) END) AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentData.Organization 															AS Organization,
	|	ISNULL(DocumentData.AnalyticsOfItemInventoryLocationAttributeTT, UNDEFINED) AS ItemsLocationAttributes,
	|	ISNULL(DocumentData.InitialInventoryLocationAttributeTTAnalyticsForItemTypesIsOriginalOne, UNDEFINED) AS AnalysisOfAccountingProductsInitial,
	|	CASE
	|		WHEN DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.Work_5)
	|				AND NOT DocumentData.CatItemOfTraceableItem
	|			THEN VALUE(Catalog.InventoryKinds.EmptyRef)
	|		ELSE DocumentData.InventoryOwnerAttribute
	|	END																					AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN DocumentData.ThereIsRequestField_AccountingSection AND DocumentData.AccountingSection <> UNDEFINED
	|		 AND DocumentData.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
	|			THEN DocumentData.AccountingSection
	|		WHEN DocumentData.Settlement_AccountingSection <> UNDEFINED
	|			THEN DocumentData.Settlement_AccountingSection
	|		WHEN VALUETYPE(DocumentData.Ref) IN (TYPE(Document.OBEntryGoods), TYPE(Document.OBEntry))
	|		  AND DocumentData.DocumentBusinessTransaction = VALUE(Enum.BusinessTransactions.EnterRemainingReceivedVMI)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsAtStorageWithRightOfSale)
	|		WHEN VALUETYPE(DocumentData.Ref) IN (TYPE(Document.OBEntryGoods), TYPE(Document.OBEntry))
	|		  AND DocumentData.DocumentBusinessTransaction = VALUE(Enum.BusinessTransactions.OBEntryCostOfOwnedInventoryOnConsignmentWarehouse)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent)
	|		WHEN VALUETYPE(DocumentData.Ref) IN (TYPE(Document.OBEntryGoods), TYPE(Document.OBEntry))
	|		 AND DocumentData.DocumentBusinessTransaction = VALUE(Enum.BusinessTransactions.OBEntryCostOfConsignedInventoryOnOurWarehouse) 
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		WHEN VALUETYPE(DocumentData.Ref) IN (TYPE(Document.OBEntryGoods), TYPE(Document.OBEntry))
	|		  AND DocumentData.DocumentBusinessTransaction = VALUE(Enum.BusinessTransactions.OBEntryCostOfInventoryInWIPOwned)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		WHEN VALUETYPE(DocumentData.Ref) IN (TYPE(Document.OBEntryGoods), TYPE(Document.OBEntry))
	|		  AND DocumentData.DocumentBusinessTransaction IN
	|				(VALUE(Enum.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers),
	|				VALUE(Enum.BusinessTransactions.EnterBalanceOfMaterialsTransferredToTollers2_5))
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller)
	|		WHEN DocumentData.DocumentBusinessTransaction IN
	|		  (VALUE(Enum.BusinessTransactions.DamageAtCustodian))
	|			THEN
	|				CASE
	|					WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|						THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInCustodyWithSalesTransferredToPartners)
	|						ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsTransferredToPartners)
	|				END
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.RecognizeInventorySurplusForTheBenefitOfConsignor))
	|			THEN
	|				CASE
	|					WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|						THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|						ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent)
	|				END
	|		WHEN DocumentData.DocumentBusinessTransaction IN
	|		  (VALUE(Enum.BusinessTransactions.MisgradingOfGoodsAtCustodian),
	|		   VALUE(Enum.BusinessTransactions.MisgradingOfGoodsAtToller))
	|			THEN
	|				CASE
	|					WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|						THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInCustodyWithSalesTransferredToPartners)
	|					WHEN DocumentData.DocumentBusinessTransaction IN (VALUE(Enum.BusinessTransactions.MisgradingOfGoodsAtCustodian))
	|						THEN VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsTransferredToPartners)
	|						ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller)
	|				END
	|		WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsAtStorageWithRightOfSale)
	|		WHEN VALUETYPE(DocumentData.Lot) = TYPE(Catalog.ProductionLots)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
	|		WHEN DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
	|		 AND (DocumentData.CatItemKeysContractTypeOfContract = VALUE(Enum.ContractTypes.TransferToTolling2_5)
	|			OR DocumentData.CatItemKeysContractTypeOfContract = VALUE(Enum.ContractTypes.SubcontractingToTheEAEUCountries))
	|		 AND DocumentData.CatProductsTypeOfProducts <> VALUE(Enum.ItemsTypes.Work_5)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller)
	|		WHEN DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.Work_5)
	|		 OR DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.OperationService)
	|		 OR DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom
	|		 OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		WHEN DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsTransferredToPartners)
	|			ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|	END 																					AS AccountingSection,
	|	CASE
	|		WHEN DocumentData.ThereIsRequestField_CorAccountingSection
	|			THEN DocumentData.CorAccountingSection
	|			ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
	|	END 																					AS CorAccountingSection,
	|
	// Corresponding fields
	|	ISNULL(DocumentData.TTCorItemAnalyticsOfInventoryLocationAttribute, UNDEFINED) AS CorItemsLocationAttributes,
	|	ISNULL(DocumentData.TTCorAnalyticsItemInventoryLocationAttributeSource, UNDEFINED) AS CorAnalysisOfAccountingProductsInitial,
	|	CASE
	|		WHEN DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.Work_5)
	|				AND NOT DocumentData.CatItemOfTraceableItem
	|			THEN VALUE(Catalog.InventoryKinds.EmptyRef)
	|		ELSE DocumentData.CorInventoryOwnerAttribute
	|	END																					AS CorInventoryOwnerAttribute,
	|	CASE WHEN DocumentData.ThereIsRequestField_CorLot
	|		THEN DocumentData.CorLot
	|		ELSE UNDEFINED
	|	END 																					AS CorLot,
	|
	// Other fields
	|	DocumentData.BusinessOperation 													AS BusinessOperation,
	|	DocumentData.Department 															AS Department,
	|	CASE
	|		WHEN FALSE
	|			THEN UNDEFINED
	

	|	END                                            										AS ProductsGroup,
	|	CASE WHEN DocumentData.ThereIsRequestField_AccountingDimensionByPartners
	|		THEN DocumentData.AccountingDimensionByPartners
	|		ELSE UNDEFINED
	|	END 																					AS AccountingDimensionByPartners,
	|	CASE
	|		WHEN FALSE
	|			THEN 0
	|			ELSE 0
	|	END																					AS RowCode,
	|
	// Quantitative and summary indicators
	|	DocumentData.Count 						AS Count,
	|	(CASE
	// The planned cost of manufactured products is reflected in individual movements.
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsRelease)
	
	
	|			THEN 0
	|		ELSE DocumentData.Cost END)		AS Cost,
	|	(CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsRelease)
	
	
	|			THEN 0
	|		ELSE DocumentData.CostExcludingVAT END) AS CostExcludingVAT,
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsRelease)
	
	
	|			THEN 0
	|		ELSE DocumentData.LocalCost
	|		  + CASE WHEN NOT DocumentData.AccountingPoliciesOfOrganizationsAverageSlidingValuation
	|		      AND DocumentData.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|				THEN DocumentData.VATLocal
	|				ELSE 0
	|			END
	|	END											AS LocalCost,
	|	DocumentData.VATLocal							AS VATLocal,
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsRelease)
	
	
	|			THEN 0 
	|		WHEN &Constant_KeepManagementRecordsOfOrganizations
	|		 AND DocumentData.Period >= BEGINOFPERIOD(&Constant_StartDateOfManagementAccountingOfOrganizations, MONTH)
	|		 AND &Constant_BatchAccountingVersion22
	|		 AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|			THEN DocumentData.CostMan
	|		  	  + CASE WHEN NOT DocumentData.AccountingPoliciesOfOrganizationsAverageSlidingValuation
	|		      	  AND DocumentData.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|					THEN DocumentData.VATManag
	|					ELSE 0
	|				END
	|		ELSE 0
	|	END											AS CostMan,
	|	DocumentData.VATManag							AS VATManag,
	|	(CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsRelease)
	
	
	|			THEN 0
	|		ELSE DocumentData.OffBalanceCost END) AS OffBalanceCost,
	|	(CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsRelease)
	
	
	|			THEN 0
	|		ELSE DocumentData.OffBalanceCostLocal END) AS OffBalanceCostLocal,
	|	CASE WHEN DocumentData.AccountingPoliciesOfOrganizationsAverageSlidingValuation
	|		THEN 0
	|		ELSE DocumentData.AddExpensesForGoods
	|	END 											AS AddExpensesForGoods,
	|	CASE WHEN DocumentData.AccountingPoliciesOfOrganizationsAverageSlidingValuation
	|		THEN 0
	|		ELSE DocumentData.AdditionalExpensesExcludingVAT
	|	END 											AS AdditionalExpensesExcludingVAT,
	|	CASE WHEN DocumentData.AccountingPoliciesOfOrganizationsAverageSlidingValuation
	|		THEN 0
	|		ELSE DocumentData.AddExpensesLocal
	|	END 											AS AddExpensesLocal,
	|	CASE WHEN &Constant_KeepManagementRecordsOfOrganizations
	|	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_StartDateOfManagementAccountingOfOrganizations, MONTH)
	|	  AND &Constant_BatchAccountingVersion22
	|	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|	  AND NOT DocumentData.AccountingPoliciesOfOrganizationsAverageSlidingValuation
	|		THEN DocumentData.AddExpensesMan
	|		ELSE 0
	|	END 											AS AddExpensesMan,
	|	(CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsRelease)
	
	
	|			THEN 0
	|		WHEN DocumentData.AccountingPoliciesOfOrganizationsAverageSlidingValuation
	|			THEN 0
	|		ELSE DocumentData.PermanentDifference END) AS PermanentDifference,
	
	|	(CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsRelease)
	
	
	|			THEN 0
	|		WHEN DocumentData.AccountingPoliciesOfOrganizationsAverageSlidingValuation
	|			THEN 0
	|		ELSE DocumentData.CostTD END) AS CostTD,
	// The cost of personal income tax is formed according to the rules of cost TA See Calculation of the cost of personal income tax.Substitute the value of the request
	|	&CostOfPersonalIncomeTax 									AS CostOfPersonalIncomeTax,
	|	DocumentData.ProvisionForImpairmentLocal		AS ProvisionForImpairmentLocal,
	|	CASE WHEN &Constant_KeepManagementRecordsOfOrganizations
	|	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_StartDateOfManagementAccountingOfOrganizations, MONTH)
	|	  AND &Constant_BatchAccountingVersion22
	|	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN DocumentData.ProvisionForImpairmentMan
	|		ELSE 0
	|	END 											AS ProvisionForImpairmentMan,
	|	DocumentData.CorGrossInitialCostENT					AS CorGrossInitialCostENT,
	|
	// Batch accounting fields version 2.2
	|	CASE
	|		WHEN VALUETYPE(DocumentData.Lot) = TYPE(Catalog.ProductionLots)
	|			THEN DocumentData.Lot
	|		WHEN &Constant_BatchAccountingVersion22
	|				AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|				AND DocumentData.FIFOAccountingPoliciesRollingValuation
	|			THEN DocumentData.Lot
	|
	|		ELSE UNDEFINED
	|	END 																				AS Lot,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|	  AND DocumentData.FIFOAccountingPoliciesRollingValuation
	|		THEN DocumentData.LotVendorAttributes
	|		ELSE UNDEFINED
	|	END 																				AS LotVendorAttributes,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|			THEN DocumentData.LotVendorAttributesCorr
	|			ELSE UNDEFINED
	|	END 																				AS LotVendorAttributesCorr,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|	 AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH) THEN
	|		(CASE
	|			WHEN VALUETYPE(DocumentData.Lot) = TYPE(Catalog.ProductionLots)
	|				AND DocumentData.Lot <> VALUE(Catalog.ProductionLots.EmptyRef)
	|				AND CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup <> VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|			THEN CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup
	|			WHEN (ISNULL(DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom, FALSE)
	|					OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department)
	|					OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Partner))
	|				AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) = TYPE(Catalog.AnalyticalInventoryGroups)
	|			THEN DocumentData.Estimated_FinancialAccountingDimension
	|			WHEN NOT (ISNULL(DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom, FALSE)
	|					OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department)
	|					OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Partner))
	|				AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) <> TYPE(Catalog.AnalyticalInventoryGroups)
	|			THEN DocumentData.Estimated_FinancialAccountingDimension
	|			ELSE UNDEFINED
	|			END)
	|		ELSE UNDEFINED
	|	END																				AS FinancialAccountingDimension,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|			AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN CASE 
	|				WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsRelease)
	|			 		AND VALUETYPE(DocumentData.Lot) = TYPE(Catalog.ProductionLots)
	|			 		AND &Constant_AnalyticalAccountingByProductsGroups
	|				THEN DocumentData.CorGroupOfManufacturedProducts
	|				WHEN VALUETYPE(DocumentData.Lot) = TYPE(Catalog.ProductionLots)
	|					AND DocumentData.Lot <> VALUE(Catalog.ProductionLots.EmptyRef)
	|					AND CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup <> VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|				THEN CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup
	|				WHEN (ISNULL(DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom, FALSE)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Partner))
	|					AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) = TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Estimated_FinancialAccountingDimension
	|				WHEN NOT (ISNULL(DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom, FALSE)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Partner))
	|					AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) <> TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Estimated_FinancialAccountingDimension
	|				ELSE UNDEFINED
	|			END
	|		ELSE UNDEFINED
	|	END 																				AS FinancialAccountingDimensionOfDocument,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|			AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN CASE
	|				WHEN VALUETYPE(DocumentData.CorLot) = TYPE(Catalog.ProductionLots)
	|					AND DocumentData.CorLot <> VALUE(Catalog.ProductionLots.EmptyRef)
	|					AND CAST(DocumentData.CorLot AS Catalog.ProductionLots).ProductsGroup <> VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|				THEN CAST(DocumentData.CorLot AS Catalog.ProductionLots).ProductsGroup
	|				WHEN ISNULL(DocumentData.TTCorItemAnalyticsOfInventoryLocationAttribute, UNDEFINED) = UNDEFINED THEN
	|					UNDEFINED
	|				WHEN (ISNULL(DocumentData.CatBoxItemKeysWarehouseAreaShopFloorStockroom, FALSE)
	|						OR DocumentData.CatBoxItemKeysTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department)
	|						OR DocumentData.CatBoxItemKeysTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Partner))
	|					AND VALUETYPE(DocumentData.CorGroupOfManufacturedProducts) = TYPE(Catalog.AnalyticalInventoryGroups)
	|					AND DocumentData.CorGroupOfManufacturedProducts <> VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|				THEN DocumentData.CorGroupOfManufacturedProducts
	|				WHEN NOT (ISNULL(DocumentData.CatBoxItemKeysWarehouseAreaShopFloorStockroom, FALSE)
	|						OR DocumentData.CatBoxItemKeysTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department)
	|						OR DocumentData.CatBoxItemKeysTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Partner))
	|					AND VALUETYPE(DocumentData.CorGroupOfManufacturedProducts) <> TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.CorGroupOfManufacturedProducts
	|				ELSE UNDEFINED
	|			END
	|		ELSE UNDEFINED
	|	END 																				AS CorControllingAttributes,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|	  AND ISNULL(DocumentData.InventoryOwnerAttributeIsTypeOfInventory, UNDEFINED) <> VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|		THEN DocumentData.VATActivityType
	|		ELSE UNDEFINED
	|	END 																				AS VATActivityType,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN DocumentData.DocumentVATActivityType
	|		ELSE UNDEFINED
	|	END 																				AS DocumentVATActivityType,
	|	CASE
	|		WHEN DocumentData.ThereIsRequestField_CorVATActivityTypes
	|			THEN DocumentData.CorVATActivityTypes
	|		WHEN DocumentData.BusinessOperation IN (
	|		  VALUE(Enum.BusinessTransactions.ProductsRelease))
	
	
	|			THEN DocumentData.VATActivityType
	|			ELSE UNDEFINED
	|	END 																				AS CorVATActivityTypes,
	|
	|	CASE
	// The type of record is defined in the procedure of operation descriptionaccounting for the following documents:
	//	- Processor Report
	//	- Processing REPORT2_5 
	|		WHEN DocumentData.ThereIsRequestField_EntryType
	|			THEN DocumentData.EntryType
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsRelease)
	|		  AND VALUETYPE(DocumentData.Lot) = TYPE(Catalog.ProductionLots)
	|			THEN VALUE(Enum.LotRecordTypes.Supplement)
	|		WHEN VALUETYPE(DocumentData.Ref) IN (
	|		  TYPE(Document.SubcontractorReport2_5))
	|			THEN
	|				CASE 
	|				WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffForExpensesFixedCost)
	|					THEN VALUE(Enum.LotRecordTypes.Supplement)
	|				WHEN DocumentData.Period = DocumentData.SourceDocumentPeriod
	|				  AND DocumentData.DocumentSource <> UNDEFINED
	|					THEN VALUE(Enum.LotRecordTypes.Supplement)
	|				WHEN DocumentData.Period = DocumentData.SourceDocumentPeriod
	|				  AND DocumentData.DocumentSource = UNDEFINED
	|					THEN VALUE(Enum.LotRecordTypes.Consumption)
	|				WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
	|				  OR DocumentData.Count < 0
	|					THEN CASE WHEN &Constant_BatchAccountingVersion22
	|	  				  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|						THEN VALUE(Enum.LotRecordTypes.Supplement)
	|						ELSE VALUE(Enum.LotRecordTypes.EmptyRef)
	|					END
	|					ELSE VALUE(Enum.LotRecordTypes.Lot)
	|				END
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
	|		  AND DocumentData.Count = 0
	|		  AND DocumentData.DocumentSource <> UNDEFINED
	|			THEN VALUE(Enum.LotRecordTypes.CostAdjustment)		
	|		ELSE VALUE(Enum.LotRecordTypes.Lot)
	|	END																				AS EntryType,
	|	VALUE(Enum.CostAccountingTransactions.InternalReceipt) 			AS CostAccountingTransaction,
	|	CASE
	|		WHEN FALSE
	|			THEN UNDEFINED
	|		ELSE DocumentData.DocumentSource
	|	END																				AS DocumentSource,
	|	CASE
	|		WHEN FALSE
	|			THEN UNDEFINED
	|		WHEN VALUETYPE(DocumentData.Ref) IN (
	|		  TYPE(Document.BackflushProduction),
	|		  TYPE(Document.WIPOpeningBalancesByProductionLots),
	|		  TYPE(Document.RecyclableWasteAllocation))
	|			THEN DocumentData.Ref
	|		WHEN DocumentData.ThereIsRequestField_DocumentRegisterRecords 
	|			THEN DocumentData.DocumentRegisterRecords
	|			ELSE UNDEFINED
	|	END																				AS DocumentRegisterRecords,
	|	DocumentData.RowID 												AS RowID,
	|	DocumentData.FinRecordID												AS FinRecordID,
	|	DocumentData.BusinessTransactionSetting 										AS BusinessTransactionSetting,
	|	DocumentData.AccountingPoliciesInventoryValuationMethod							AS InventoryValuationMethod,
	// The field "Method of determining the cost" is filled in the documents:
	//	- Assembly of goods - the value of "Pokordvizhenie", because the cost of the kit must be calculated at the cost of components.
	|	(CASE
	|		WHEN DocumentData.ThereIsRequestField_CostDefiningMethod
	|			THEN DocumentData.CostDefiningMethod
	|		ELSE VALUE(Enum.WaysToCalculateInventoryCost.FromDocument) END) AS CostDefiningMethod
	|
	|INTO TTOperation_InternalReceipt
	|FROM
	|	TTDocumentData_ AS DocumentData
	|	LEFT JOIN AITExpenseRecognitionSettings AS SettingsForRecognitionOfLBExpensesByBusinessUnit
	|		ON DocumentData.Organization = SettingsForRecognitionOfLBExpensesByBusinessUnit.Organization
	|		AND DocumentData.Department = SettingsForRecognitionOfLBExpensesByBusinessUnit.ObjectOfSeparateAccountingAIT
	|		AND SettingsForRecognitionOfLBExpensesByBusinessUnit.ExpensesAreIncludedInCost
	|	LEFT JOIN AITExpenseRecognitionSettings AS SettingsForRecognitionOfExpensesLBDpoLineOfBusiness
	|		ON DocumentData.Organization = SettingsForRecognitionOfExpensesLBDpoLineOfBusiness.Organization
	|		AND DocumentData.InventoriedLocationAttributeAnalysisPurposeLineOfBusiness = SettingsForRecognitionOfExpensesLBDpoLineOfBusiness.ObjectOfSeparateAccountingAIT
	|		AND SettingsForRecognitionOfExpensesLBDpoLineOfBusiness.ExpensesAreIncludedInCost
	|WHERE
	|	DocumentData.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.InternalReceipt)
	|
	// The planned cost of the issue is allocated in a separate movement, because there is no corresponding movement for this record and
	// the planned cost is reversed after calculation. 
	|UNION ALL
	|
	|SELECT
	|	DocumentData.OperationNumber AS OperationNumber,
	// Document description
	|	VALUE(AccumulationRecordType.Receipt)	AS RecordType,
	|	DocumentData.Period 					AS Period,
	|	(CASE
	|		WHEN DocumentData.ThereIsRequestField_VariancePeriod
	|			THEN DocumentData.VariancePeriod
	|		 ELSE DATETIME(1,1,1) END) AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentData.Organization 															AS Organization,
	|	ISNULL(DocumentData.AnalyticsOfItemInventoryLocationAttributeTT, UNDEFINED) AS ItemsLocationAttributes,
	|	ISNULL(DocumentData.InitialInventoryLocationAttributeTTAnalyticsForItemTypesIsOriginalOne, UNDEFINED) AS AnalysisOfAccountingProductsInitial,
	|	CASE
	|		WHEN DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.Work_5)
	|				AND NOT DocumentData.CatItemOfTraceableItem
	|			THEN VALUE(Catalog.InventoryKinds.EmptyRef)
	|		ELSE DocumentData.InventoryOwnerAttribute
	|	END 																					AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN DocumentData.ThereIsRequestField_AccountingSection AND DocumentData.AccountingSection <> UNDEFINED
	|		 AND DocumentData.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
	|			THEN DocumentData.AccountingSection
	|		WHEN DocumentData.Settlement_AccountingSection <> UNDEFINED
	|			THEN DocumentData.Settlement_AccountingSection
	|		WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsAtStorageWithRightOfSale)
	|		WHEN DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
	|		 AND (DocumentData.CatItemKeysContractTypeOfContract = VALUE(Enum.ContractTypes.TransferToTolling2_5)
	|			OR DocumentData.CatItemKeysContractTypeOfContract = VALUE(Enum.ContractTypes.SubcontractingToTheEAEUCountries))
	|		 AND DocumentData.CatProductsTypeOfProducts <> VALUE(Enum.ItemsTypes.Work_5)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller)
	|		WHEN DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.Work_5)
	|		 OR DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.OperationService)
	|		 OR DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom
	|		 OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		WHEN DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsTransferredToPartners)
	|			ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|	END 																					AS AccountingSection,
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)					AS CorAccountingSection,
	|
	// Corresponding fields
	|	UNDEFINED 																			AS CorItemsLocationAttributes,
	|	UNDEFINED 																			AS CorAnalysisOfAccountingProductsInitial,
	|	UNDEFINED 																			AS CorInventoryOwnerAttribute,
	|	CASE WHEN DocumentData.ThereIsRequestField_CorLot
	|		THEN DocumentData.CorLot
	|		ELSE UNDEFINED
	|	END 																					AS CorLot,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.PostingOfReleaseTargetCost)			AS BusinessOperation,
	|	DocumentData.Department 															AS Department,
	|	CASE
	|		WHEN FALSE
	|			THEN UNDEFINED
	|			ELSE UNDEFINED
	|	END                                            										AS ProductsGroup,
	|	CASE WHEN DocumentData.ThereIsRequestField_AccountingDimensionByPartners
	|		THEN DocumentData.AccountingDimensionByPartners
	|		ELSE UNDEFINED
	|	END 																					AS AccountingDimensionByPartners,
	|	0																						AS RowCode,
	|
	// Quantitative and summary indicators
	|	0												AS Count,
	|	DocumentData.Cost						AS Cost,
	|	DocumentData.CostExcludingVAT					AS CostExcludingVAT,
	|	DocumentData.LocalCost
	|		+ CASE WHEN NOT DocumentData.AccountingPoliciesOfOrganizationsAverageSlidingValuation
	|		  AND DocumentData.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|			THEN DocumentData.VATLocal
	|			ELSE 0
	|		END										AS LocalCost,
	|	0												AS VATLocal,
	|	CASE WHEN &Constant_KeepManagementRecordsOfOrganizations
	|	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_StartDateOfManagementAccountingOfOrganizations, MONTH)
	|	  AND &Constant_BatchAccountingVersion22
	|	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN DocumentData.CostMan
	|	  	  + CASE WHEN NOT DocumentData.AccountingPoliciesOfOrganizationsAverageSlidingValuation
	|	      	  AND DocumentData.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|				THEN DocumentData.VATManag
	|				ELSE 0
	|			END
	|		ELSE 0
	|	END											AS CostMan,
	|	0												AS VATManag,
	|	DocumentData.OffBalanceCost			AS OffBalanceCost,
	|	DocumentData.OffBalanceCostLocal		AS OffBalanceCostLocal,
	|	0												AS AddExpensesForGoods,
	|	0												AS AdditionalExpensesExcludingVAT,
	|	0												AS AddExpensesLocal,
	|	0	 											AS AddExpensesMan,
	|	DocumentData.PermanentDifference				AS PermanentDifference,
	|	DocumentData.CostTD				AS CostTD,
	|	0												AS ProvisionForImpairmentLocal,
	|	0	 											AS ProvisionForImpairmentMan,
	|	0 												AS CostOfPersonalIncomeTax,
	|	DocumentData.CorGrossInitialCostENT					AS CorGrossInitialCostENT,
	|
	// Batch accounting fields version 2.2
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|	 AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|	 AND DocumentData.FIFOAccountingPoliciesRollingValuation
	|		THEN DocumentData.Lot
	|		ELSE UNDEFINED
	|	END 																				AS Lot,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|	  AND DocumentData.FIFOAccountingPoliciesRollingValuation
	|		THEN DocumentData.LotVendorAttributes
	|		ELSE UNDEFINED
	|	END 																				AS LotVendorAttributes,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|			THEN DocumentData.LotVendorAttributesCorr
	|			ELSE UNDEFINED
	|	END 																				AS LotVendorAttributesCorr,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|		AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH) 
	|		THEN
	|			(CASE
	|				WHEN VALUETYPE(DocumentData.Lot) = TYPE(Catalog.ProductionLots)
	|					AND DocumentData.Lot <> VALUE(Catalog.ProductionLots.EmptyRef)
	|					AND CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup <> VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|				THEN CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup
	|				WHEN (ISNULL(DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom, FALSE)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department))
	|					AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) = TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Estimated_FinancialAccountingDimension
	|				WHEN NOT (ISNULL(DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom, FALSE)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department))
	|					AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) <> TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Estimated_FinancialAccountingDimension
	|				ELSE UNDEFINED
	|			END)
	|		ELSE UNDEFINED
	|	END 																				AS FinancialAccountingDimension,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|		AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN
	|			(CASE
	|				WHEN VALUETYPE(DocumentData.Lot) = TYPE(Catalog.ProductionLots)
	|					AND DocumentData.Lot <> VALUE(Catalog.ProductionLots.EmptyRef)
	|					AND CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup <> VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|				THEN CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup
	|				WHEN (ISNULL(DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom, FALSE)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department))
	|					AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) = TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Estimated_FinancialAccountingDimension
	|				WHEN NOT (ISNULL(DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom, FALSE)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department))
	|					AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) <> TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Estimated_FinancialAccountingDimension
	|				ELSE UNDEFINED
	|			END)
	|		ELSE UNDEFINED
	|	END 																				AS FinancialAccountingDimensionOfDocument,
	|	UNDEFINED																		AS CorControllingAttributes,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN DocumentData.VATActivityType
	|		ELSE UNDEFINED
	|	END 																				AS VATActivityType,
	|	UNDEFINED																		AS DocumentVATActivityType,
	|	UNDEFINED																		AS CorVATActivityTypes,
	|
	|	VALUE(Enum.LotRecordTypes.Lot)										AS EntryType,
	|	VALUE(Enum.CostAccountingTransactions.InternalReceipt) 			AS CostAccountingTransaction,
	|	UNDEFINED																		AS DocumentSource,
	|	DocumentData.Ref																AS DocumentRegisterRecords,
	|	DocumentData.RowID 						  						AS RowID,
	|	DocumentData.FinRecordID 						  						AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.PostingOfReleaseTargetCost) AS BusinessTransactionSetting,
	|	DocumentData.AccountingPoliciesInventoryValuationMethod							AS InventoryValuationMethod,
	|	VALUE(Enum.WaysToCalculateInventoryCost.FromDocument) 			AS CostDefiningMethod
	|FROM
	|	TTDocumentData_ AS DocumentData
	|	LEFT JOIN AITExpenseRecognitionSettings AS SettingsForRecognitionOfLBExpensesByBusinessUnit
	|		ON DocumentData.Organization = SettingsForRecognitionOfLBExpensesByBusinessUnit.Organization
	|		AND DocumentData.Department = SettingsForRecognitionOfLBExpensesByBusinessUnit.ObjectOfSeparateAccountingAIT
	|		AND SettingsForRecognitionOfLBExpensesByBusinessUnit.ExpensesAreIncludedInCost
	|	LEFT JOIN AITExpenseRecognitionSettings AS SettingsForRecognitionOfExpensesLBDpoLineOfBusiness
	|		ON DocumentData.Organization = SettingsForRecognitionOfExpensesLBDpoLineOfBusiness.Organization
	|		AND DocumentData.InventoriedLocationAttributeAnalysisPurposeLineOfBusiness = SettingsForRecognitionOfExpensesLBDpoLineOfBusiness.ObjectOfSeparateAccountingAIT
	|		AND SettingsForRecognitionOfExpensesLBDpoLineOfBusiness.ExpensesAreIncludedInCost
	|WHERE
	|	DocumentData.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.InternalReceipt)
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.ProductsRelease)
	|	AND (DocumentData.Cost <> 0 OR DocumentData.LocalCost <> 0)
	// In the Accounting section "Output", there should be no Registered Recorded Receipts at the planned cost. 
	// The planned cost is reflected by the Registered Recorded Expense from the Accounting section "Output".
	|	AND (CASE
	|		WHEN DocumentData.ThereIsRequestField_AccountingSection AND DocumentData.AccountingSection <> UNDEFINED
	|		 AND DocumentData.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
	|			THEN DocumentData.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
	|		ELSE TRUE END)
	// 
	|
	
	
	|";
	
	CalculationOfCostLocalization.SubstituteCostOfPersonalDataRequest(ReflectionRequestText, "TTOperation_InternalReceipt", True);
	
	ReflectionRequestText = StrReplace(ReflectionRequestText, "&CostOfPersonalIncomeTax", "0");
	
	ReflectionParameters.TTTemplateTexts.Insert("TTOperation_InternalReceipt", ReflectionRequestText);
	
EndProcedure

Procedure ReflectTransactionCostDisposalAtFixedCost(ReflectionParameters)
	
	// Let's form a template of the request text to reflect the operation.
	ReflectionRequestText =
	"SELECT
	|	DocumentData.OperationNumber AS OperationNumber,
	// Document description
	|	CASE
	|		WHEN DocumentData.BusinessOperation IN
	|			(VALUE(Enum.BusinessTransactions.ReturnPackageFromCustomerOfPreviousPeriods),
	|			VALUE(Enum.BusinessTransactions.TransferredPackageReverseTransactionReturnToAnotherWarehouse))
	|		THEN VALUE(AccumulationRecordType.Receipt)
	|		ELSE VALUE(AccumulationRecordType.Expense)
	|	END AS RecordType,
	|	DocumentData.Period AS Period,
	|	(CASE
	|		WHEN DocumentData.ThereIsRequestField_VariancePeriod
	|			THEN DocumentData.VariancePeriod
	|		 ELSE DATETIME(1,1,1) END) AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentData.Organization 															AS Organization,
	|	ISNULL(DocumentData.AnalyticsOfItemInventoryLocationAttributeTT, UNDEFINED) AS ItemsLocationAttributes,
	|	ISNULL(DocumentData.InitialInventoryLocationAttributeTTAnalyticsForItemTypesIsOriginalOne, UNDEFINED) AS AnalysisOfAccountingProductsInitial,
	|	CASE
	// When a commission item is written off for expenses in Registered Records, the inventory type is not filled in, because in the report to the committee on the write 
	// -off, it is impossible to determine the type of inventory for which the write-off was performed. For such Registered Records, a partner is indicated in the type of storage location.
	|		WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		 AND DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Partner)
	|			THEN VALUE(Catalog.InventoryKinds.EmptyRef)
	|		WHEN DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.OperationService)
	|		  OR DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.Work_5)
	|			  AND NOT DocumentData.CatItemOfTraceableItem
	|			THEN VALUE(Catalog.InventoryKinds.EmptyRef)
	|			ELSE DocumentData.InventoryOwnerAttribute
	|	END 																				AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN DocumentData.ThereIsRequestField_AccountingSection AND DocumentData.AccountingSection <> UNDEFINED
	|		 AND DocumentData.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
	|			THEN DocumentData.AccountingSection
	|		WHEN DocumentData.Settlement_AccountingSection <> UNDEFINED
	|			THEN DocumentData.Settlement_AccountingSection
	// Filling in the accounting section for works and services
	|		WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory IN (VALUE(Enum.InventoryTypes.EmptyRef),
	|														VALUE(Enum.InventoryTypes.Work_5))
	|			AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffDiscrepanciesBetweenReceiptAndPurchase)
	|		THEN VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
	|		WHEN DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.Work_5)
	|		  OR DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.OperationService)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|
	|		WHEN DocumentData.DocumentBusinessTransaction IN
	|		  (VALUE(Enum.BusinessTransactions.MisgradingOfGoodsAtCustodian),
	|		   VALUE(Enum.BusinessTransactions.MisgradingOfGoodsAtToller),
	|		   VALUE(Enum.BusinessTransactions.DamageAtCustodian),
	|		   VALUE(Enum.BusinessTransactions.DamageAtToller),
	|		   VALUE(Enum.BusinessTransactions.GoodsWriteOffAtToller))
	|			THEN
	|				CASE
	|					WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|						THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInCustodyWithSalesTransferredToPartners)
	|					WHEN DocumentData.DocumentBusinessTransaction IN
	|					 (VALUE(Enum.BusinessTransactions.MisgradingOfGoodsAtCustodian),
	|					  VALUE(Enum.BusinessTransactions.DamageAtCustodian))
	|						THEN VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsTransferredToPartners)
	|						ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller)
	|				END
	|		WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsAtStorageWithRightOfSale)
	|		WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.OwnGoodsInTransit)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors)
	|		WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.OwnGoodsOfUninvoicedDelivery)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.WriteOffShortagesAtConsignorSExpense))
	|			THEN 
	|				CASE
	|					WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.OwnGoods)
	|						THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent)
	|						ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|				END
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.SaleOfTransferredReturnablePackaging),
	|		   VALUE(Enum.BusinessTransactions.TransferredPackageReverseTransaction),
	|		   VALUE(Enum.BusinessTransactions.TransferredPackageReverseTransactionReturnToAnotherWarehouse))
	|		 AND DocumentData.DocumentBusinessTransaction IN
	|		  (VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent),
	|		   VALUE(Enum.BusinessTransactions.ReturnOfGoodsViaCommissionAgent))
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent)
	|		WHEN DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom
	|			OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|			ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|	END 																					AS AccountingSection,
	|	CASE
	|		WHEN DocumentData.ThereIsRequestField_CorAccountingSection
	|			THEN DocumentData.CorAccountingSection
	|			ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
	|	END 																					AS CorAccountingSection,
	|
	// Corresponding fields
	|	ISNULL(DocumentData.TTCorItemAnalyticsOfInventoryLocationAttribute, UNDEFINED) AS CorItemsLocationAttributes,
	|	ISNULL(DocumentData.TTCorAnalyticsItemInventoryLocationAttributeSource, UNDEFINED) AS CorAnalysisOfAccountingProductsInitial,
	|	CASE
	|		WHEN DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.OperationService)
	|		  OR DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.Work_5)
	|			  AND NOT DocumentData.CatItemOfTraceableItem
	|			THEN VALUE(Catalog.InventoryKinds.EmptyRef)
	|		ELSE DocumentData.CorInventoryOwnerAttribute
	|	END 															AS CorInventoryOwnerAttribute,
	|
	// Other fields
	|	DocumentData.BusinessOperation 													AS BusinessOperation,
	|	DocumentData.Department 															AS Department,
	|	CASE
	|		WHEN VALUETYPE(DocumentData.ExpenseItemAssets) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|			THEN DocumentData.ExpenseItemAssets
	|			ELSE UNDEFINED
	|	END 																					AS ExpenseItemOfWriteOff,
	|	CASE
	|		WHEN VALUETYPE(DocumentData.ExpenseItemAssets) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|			THEN DocumentData.AssetExpenseAnalytics
	|			ELSE UNDEFINED
	|	END 																					AS DimensionOfExpenses,
	|	CASE
	|		WHEN VALUETYPE(DocumentData.ExpenseItemAssets) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|			THEN DocumentData.ExpenseItemAssets
	|			ELSE UNDEFINED
	|	END 																					AS AssetAndLiabilityItem,
	|	CASE
	|		WHEN VALUETYPE(DocumentData.ExpenseItemAssets) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|			THEN DocumentData.AssetExpenseAnalytics
	|			ELSE UNDEFINED
	|	END 																					AS AssetsLiabilitiesDimension,
	|	CASE
	|		WHEN DocumentData.ThereIsRequestField_GLAccountSettings
	|		 AND VALUETYPE(DocumentData.ExpenseItemAssets) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|			THEN DocumentData.GLAccountSettings
	|			ELSE UNDEFINED
	|	END 																					AS GLAccountSettings,
	|	DocumentData.IncomeItem 															AS IncomeItem,
	|	DocumentData.DimensionOfRevenue 														AS DimensionOfRevenue,
	|	DocumentData.SourceDocumentPeriod												AS SalePeriod,
	|	CASE WHEN DocumentData.ThereIsRequestField_AccountingDimensionByPartners
	|		THEN DocumentData.AccountingDimensionByPartners
	|		ELSE UNDEFINED
	|	END 																					AS AccountingDimensionByPartners,
	|
	// Quantitative and summary indicators
	|	DocumentData.Count 						AS Count,
	|	DocumentData.Cost 						AS Cost,
	|	DocumentData.CostExcludingVAT 				AS CostExcludingVAT,
	|	DocumentData.LocalCost 					AS LocalCost,
	|	CASE WHEN &Constant_KeepManagementRecordsOfOrganizations
	|	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_StartDateOfManagementAccountingOfOrganizations, MONTH)
	|	  AND &Constant_BatchAccountingVersion22
	|	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN DocumentData.CostMan
	|		ELSE 0
	|	END 											AS CostMan,
	|	DocumentData.CorGrossInitialCostENT 					AS CorGrossInitialCostENT,
	|	CASE WHEN DocumentData.ThereIsRequestField_OffBalanceCost
	|		THEN DocumentData.OffBalanceCost
	|		ELSE 0
	|	END 											AS OffBalanceCost,
	|	CASE WHEN DocumentData.ThereIsRequestField_OffBalanceCostLocal
	|		THEN DocumentData.OffBalanceCostLocal
	|		ELSE 0
	|	END 											AS OffBalanceCostLocal,
	|
	// Batch accounting fields version 2.2
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|		AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN CASE 
	|				WHEN VALUETYPE(DocumentData.Lot) = TYPE(Catalog.ProductionLots)
	|					AND DocumentData.Lot <> VALUE(Catalog.ProductionLots.EmptyRef)
	|					AND CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup <> VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|				THEN CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup
	|				WHEN (ISNULL(DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom, FALSE)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department))
	|					AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) = TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Estimated_FinancialAccountingDimension
	|				WHEN NOT (ISNULL(DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom, FALSE)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department))
	|					AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) <> TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Estimated_FinancialAccountingDimension
	|				ELSE UNDEFINED
	|			END
	|		ELSE UNDEFINED
	|	END 																				AS FinancialAccountingDimensionOfDocument,
	|	UNDEFINED 																		AS Lot,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN DocumentData.VATActivityType
	|		ELSE UNDEFINED
	|	END 																				AS VATActivityType,
	|	DocumentData.VATActivityType													AS CorVATActivityTypes,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN DocumentData.DocumentVATActivityType
	|		ELSE UNDEFINED
	|	END 																				AS DocumentVATActivityType,
	|
	|	CASE
	|		WHEN DocumentData.ThereIsRequestField_EntryType
	|			THEN DocumentData.EntryType
	// For items in transit from suppliers with a negative quantity, the record type must be write-offstatingparty.
	// See the description in the Operation descriptionaccountingthe cost of the document write-offingreferences
	|		WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.OwnGoodsInTransit)
	|		 AND DocumentData.Count < 0
	|			THEN VALUE(Enum.LotRecordTypes.WriteOffOfBalanceWithoutLot)
	// If there is an unfactated delivery and the quantity is positive, the record type must be write-offstatethe date of the non-party.
	// See the description in the Operation descriptionaccountingthe cost of the document write-offsreferences
	|		WHEN (DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.OwnGoodsOfUninvoicedDelivery)
	|			OR DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.EmptyRef)
	|			AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffDiscrepanciesBetweenReceiptAndPurchase))
	|		AND DocumentData.Count > 0
	|			THEN VALUE(Enum.LotRecordTypes.WriteOffOfBalanceWithoutLot)
	|		ELSE VALUE(Enum.LotRecordTypes.Consumption)
	|	END														  						AS EntryType,
	|	VALUE(Enum.CostAccountingTransactions.DisposalAtFixedCost) 	AS CostAccountingTransaction,
	|	DocumentData.DocumentSource 												  	AS DocumentSource,
	|	UNDEFINED																		AS DocumentRegisterRecords,
	|	DocumentData.RowID 						  						AS RowID,
	|	DocumentData.FinRecordID 						  						AS FinRecordID,
	|	DocumentData.BusinessTransactionSetting 				  						AS BusinessTransactionSetting,
	|	DocumentData.AccountingPoliciesInventoryValuationMethod							AS InventoryValuationMethod,
	|	VALUE(Enum.WaysToCalculateInventoryCost.FromDocument) 			AS CostDefiningMethod
	|INTO TTOperation_DisposalAtFixedCost
	|FROM
	|	TTDocumentData_ AS DocumentData
	|WHERE
	|	DocumentData.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.DisposalAtFixedCost)
	|";
	
	ReflectionParameters.TTTemplateTexts.Insert("TTOperation_DisposalAtFixedCost", ReflectionRequestText);
	
EndProcedure

Procedure ReflectCostTransaction(ReflectionParameters)
	
	// Let's form a template of the request text to reflect the operation.
	ReflectionRequestText =
	"
	// EXPENSE - debiting from the sender
	|SELECT
	|	DocumentData.OperationNumber AS OperationNumber,
	// Document description
	|	VALUE(AccumulationRecordType.Expense) 	AS RecordType,
	|	DocumentData.Period 					AS Period,
	|	(CASE
	|		WHEN DocumentData.ThereIsRequestField_VariancePeriod
	|			THEN DocumentData.VariancePeriod
	|		 ELSE DATETIME(1,1,1) END) AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentData.Organization 														AS Organization,
	|	CASE WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		  AND ISNULL(DocumentData.CorInventoryOwnerAttributeTypeOfInventory, UNDEFINED) <> VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		  AND NOT DocumentData.BusinessOperation IN
	|	  	    (VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting))
	|		THEN ISNULL(DocumentData.CommitteeSInventoryLocationAttributeAnalyticsTTItemTypeOfCommitteeSInventoryTypeOfCommitteeTypeOfCommitteeTypeOfCommitteeTypeOfCommitteeTypeOfCommitteeTypeOfCommitteeTypeOfCommittee, UNDEFINED)
	|		ELSE ISNULL(DocumentData.AnalyticsOfItemInventoryLocationAttributeTT, UNDEFINED)
	|	END 																				AS ItemsLocationAttributes,
	|	ISNULL(DocumentData.InitialInventoryLocationAttributeTTAnalyticsForItemTypesIsOriginalOne, UNDEFINED) AS AnalysisOfAccountingProductsInitial,
	|	CASE
	|		WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		  AND ISNULL(DocumentData.CorInventoryOwnerAttributeTypeOfInventory, UNDEFINED) <> VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		  AND NOT DocumentData.BusinessOperation IN
	|	  	    (VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting))
	|		THEN VALUE(Catalog.InventoryKinds.EmptyRef)
	|		WHEN DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.Work_5)
	|		 AND NOT DocumentData.CatItemOfTraceableItem
	|			THEN VALUE(Catalog.InventoryKinds.EmptyRef)
	|		ELSE DocumentData.InventoryOwnerAttribute
	|	END 																				AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN DocumentData.ThereIsRequestField_AccountingSection AND DocumentData.AccountingSection <> UNDEFINED
	|		 AND DocumentData.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
	|			THEN DocumentData.AccountingSection
	|		WHEN DocumentData.Settlement_AccountingSection <> UNDEFINED AND NOT
	//	We redefine the Accounting section only when we do not redefine the analytics of accounting and the type of inventory. For a commission product
	//	, it is redefined, and therefore the Accounting section defined by general principles is no longer suitable.
	|			(DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|				AND ISNULL(DocumentData.CorInventoryOwnerAttributeTypeOfInventory, UNDEFINED) <> VALUE(Enum.InventoryTypes.ConsignedGoods)
	|				AND NOT DocumentData.BusinessOperation IN (VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting)))
	|			THEN DocumentData.Settlement_AccountingSection
	|		WHEN DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.Work_5)
	|				OR DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.OperationService)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting))
	|		  AND DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		  AND ISNULL(DocumentData.CorInventoryOwnerAttributeTypeOfInventory, UNDEFINED) <> VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.WriteOffShortagesAtConsignorSExpense))
	|			THEN 
	|				CASE
	|					WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.OwnGoods)
	|						THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent)
	|						ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|				END
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.WorkAcceptanceAndTransferBetweenBusinessUnits),
	|		   VALUE(Enum.BusinessTransactions.WorkAcceptanceAndTransferBetweenBranchOffices))
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit),
	|		   VALUE(Enum.BusinessTransactions.ImportReceiptFromGoodsInTransit),
	|		   VALUE(Enum.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit))
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors)
	|		WHEN DocumentData.DocumentBusinessTransaction IN
	|				(VALUE(Enum.BusinessTransactions.ReturnFromCustodian),
	|				VALUE(Enum.BusinessTransactions.MisgradingOfGoodsAtCustodian),
	|				VALUE(Enum.BusinessTransactions.DamageAtCustodian),
	|				VALUE(Enum.BusinessTransactions.WriteOffShortagesAtDepositorSExpense))
	|			THEN
	|				CASE
	|					WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|						THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInCustodyWithSalesTransferredToPartners)
	|					ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsTransferredToPartners)
	|				END
	|		WHEN DocumentData.DocumentBusinessTransaction IN
	|				(VALUE(Enum.BusinessTransactions.ReturnFromProcessingCompany2_5),
	|				VALUE(Enum.BusinessTransactions.ReceiptFromToller2_5),
	|				VALUE(Enum.BusinessTransactions.MisgradingOfGoodsAtToller),
	|				VALUE(Enum.BusinessTransactions.DamageAtToller),
	|				VALUE(Enum.BusinessTransactions.GoodsWriteOffAtToller))
	|			THEN
	|				CASE
	|					WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|						THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInCustodyWithSalesTransferredToPartners)
	|					ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller)
	|				END
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent),
	|		   VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit),
	|		   VALUE(Enum.BusinessTransactions.ReturnOfGoodsViaCommissionAgent))
	|		AND DocumentData.InventoryOwnerAttributeIsTypeOfInventory <> VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent)
	|		WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		  AND DocumentData.CorInventoryOwnerAttributeTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		  AND VALUETYPE(DocumentData.Ref) IN
	|			(TYPE(Document.CustomerInvoiceIntercompany),
	|			 TYPE(Document.ReturnOfGoodsFromCustomer),
	|			 TYPE(Document.IntercompanyGoodsReturn))
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsAtStorageWithRightOfSale)
	|		WHEN DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom
	|				OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|			ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|	END 																				AS AccountingSection,
	|
	// Corresponding fields
	|	CASE
	|		WHEN DocumentData.ThereIsRequestField_CorAccountingSection
	|			THEN DocumentData.CorAccountingSection
	|		WHEN DocumentData.Settlement_CorAccountingSection <> UNDEFINED
	|			THEN DocumentData.Settlement_CorAccountingSection
	|		WHEN DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.Work_5)
	|				OR DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.OperationService)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	// The goods are in storage with the right to sell
	|		WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|		 AND DocumentData.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.GoodsConsumption),
	|				VALUE(Enum.BusinessTransactions.WriteOffShortagesAtDepositorSExpense),
	|				VALUE(Enum.BusinessTransactions.RecognizeInventorySurplusForTheBenefitOfDepositor),
	|				VALUE(Enum.BusinessTransactions.GoodsWriteOffAtToller))
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInStorageWithRightOfSaleToRegisterWriteOff)
	// If, during the re-sorting or damage of goods in storage, own goods are accounted for, then the transfer 
	// to the Accounting section "Goods in storage with the right of sale (for write-off)" is reflected.
	|		WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|		 AND DocumentData.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.GoodsMisgrading),
	|				VALUE(Enum.BusinessTransactions.GoodsMisgradingWithRevaluation),
	|				VALUE(Enum.BusinessTransactions.GoodsDamage),
	|				VALUE(Enum.BusinessTransactions.GoodsDamageRevaluation))
	|		 AND DocumentData.CorInventoryOwnerAttributeTypeOfInventory = VALUE(Enum.InventoryTypes.OwnGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInStorageWithRightOfSaleToRegisterWriteOff)
	|		WHEN DocumentData.DocumentBusinessTransaction IN
	|				(VALUE(Enum.BusinessTransactions.TransferToStorageWithRightOfSale),
	|				VALUE(Enum.BusinessTransactions.MisgradingOfGoodsAtCustodian),
	|				VALUE(Enum.BusinessTransactions.DamageAtCustodian))
	|			THEN
	|				CASE
	|					WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|						THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInCustodyWithSalesTransferredToPartners)
	|						ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsTransferredToPartners)
	|				END
	|		WHEN DocumentData.DocumentBusinessTransaction IN
	|				(VALUE(Enum.BusinessTransactions.TransferToToller2_5),
	|				VALUE(Enum.BusinessTransactions.MisgradingOfGoodsAtToller),
	|				VALUE(Enum.BusinessTransactions.DamageAtToller))
	|			THEN
	|				CASE
	|					WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|						THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInCustodyWithSalesTransferredToPartners)
	|						ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller)
	|				END
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.WorkAcceptanceAndTransferBetweenBusinessUnits),
	|		   VALUE(Enum.BusinessTransactions.WorkAcceptanceAndTransferBetweenBranchOffices))
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.TransferToCommissionAgent),
	|		   VALUE(Enum.BusinessTransactions.RecognizeInventorySurplusForTheBenefitOfConsignor))
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent)
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.WriteOffShortagesAtConsignorSExpense))
	|			THEN 
	|				CASE
	|					WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.OwnGoods)
	|						THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent)
	|						ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|				END
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle))
	|		  AND DocumentData.InventoryOwnerAttributeIsTypeOfInventory <> VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransit)
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle))
	|		  AND DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitReceivedByCommissionAgent)
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
	|		  AND DocumentData.InventoryOwnerAttributeIsTypeOfInventory <> VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitTransferredToCommissionAgent)
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
	|		  AND DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitReceivedByCommissionAgent)
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer),
	|		   VALUE(Enum.BusinessTransactions.ReturnFromRetailCustomer),
	|		   VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent),
	|		   VALUE(Enum.BusinessTransactions.ReturnOfGoodsViaCommissionAgent))
	|		  AND DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.TransferOfGoodsToCommissionAgentInAnotherCompany))
	|			THEN 
	|				CASE
	|					WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|						THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|						ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent)
	|				END
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.ReturnFromCustodian),
	|			VALUE(Enum.BusinessTransactions.ReturnFromProcessingCompany2_5))
	|			THEN 
	|				CASE
	|					WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|						THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|					WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|						THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsAtStorageWithRightOfSale)
	|					WHEN DocumentData.CorInventoryLocationSAttributesStorageAreaShopFloorStockroom
	|		  			  OR DocumentData.CorOfInventoryLocationAttributeTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department)
	|						THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|						ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|				END
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting))
	|			THEN UNDEFINED
	|		WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		  AND DocumentData.CorInventoryOwnerAttributeTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsAtStorageWithRightOfSale)
	|		WHEN DocumentData.CorInventoryLocationSAttributesStorageAreaShopFloorStockroom
	|		  OR DocumentData.CorOfInventoryLocationAttributeTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|			ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|	END 																					AS CorAccountingSection,
	|	CASE
	|		WHEN DocumentData.CorCompany = DocumentData.Organization
	|			THEN UNDEFINED
	|			ELSE DocumentData.CorCompany
	|	END 																					AS CorCompany,
	|	ISNULL(DocumentData.TTCorItemAnalyticsOfInventoryLocationAttribute, UNDEFINED) AS CorItemsLocationAttributes,
	|	ISNULL(DocumentData.TTCorAnalyticsItemInventoryLocationAttributeSource, UNDEFINED) AS CorAnalysisOfAccountingProductsInitial,
	|	(CASE
	|		WHEN DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.Work_5)
	|		 AND NOT DocumentData.CatItemOfTraceableItem
	|			THEN VALUE(Catalog.InventoryKinds.EmptyRef)
	|		WHEN DocumentData.BusinessOperation IN
	|		   (VALUE(Enum.BusinessTransactions.GoodsMisgrading),
	|		   VALUE(Enum.BusinessTransactions.GoodsMisgradingWithRevaluation),
	|		   VALUE(Enum.BusinessTransactions.GoodsConsumption),
	|		   VALUE(Enum.BusinessTransactions.GoodsDamage),
	|		   VALUE(Enum.BusinessTransactions.GoodsDamageRevaluation))
	|		  AND DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN DocumentData.InventoryOwnerAttribute
	|		ELSE DocumentData.CorInventoryOwnerAttribute END)											AS CorInventoryOwnerAttribute,
	|
	// Other fields
	|	DocumentData.BusinessOperation 													AS BusinessOperation,
	|	CASE WHEN VALUETYPE(DocumentData.Ref) IN (TYPE(Document.MovementOfProductsAndMaterials))
	|		THEN UNDEFINED
	|		ELSE DocumentData.Department
	|	END 								  													AS Department,
	|	CASE
	|		WHEN FALSE
	|			THEN UNDEFINED
	|		WHEN VALUETYPE(DocumentData.Ref) IN (TYPE(Document.InternalAcceptanceCertificate))
	|			THEN UNDEFINED
	|		WHEN VALUETYPE(DocumentData.Ref) = TYPE(Document.MovementOfProductsAndMaterials)
	|		  AND DocumentData.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.TransferOfSemiFinishedProducts),
	|			VALUE(Enum.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices))
	|			THEN UNDEFINED
	|			ELSE DocumentData.ProductsGroup
	|	END                                            										AS ProductsGroup,
	|	CASE WHEN DocumentData.ThereIsRequestField_SalesOrder
	|		THEN DocumentData.SalesOrder
	|		ELSE UNDEFINED
	|	END																					AS SalesOrder,
	|	CASE WHEN DocumentData.ThereIsRequestField_AccountingDimensionByPartners
	|	 AND DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		THEN DocumentData.AccountingDimensionByPartners
	|		ELSE UNDEFINED
	|	END																					AS AccountingDimensionByPartners,
	|
	// Quantitative and summary indicators
	|	DocumentData.Count 																AS Count,
	|	DocumentData.Cost 																AS Cost,
	|	DocumentData.CostExcludingVAT 														AS CostExcludingVAT,
	|	DocumentData.LocalCost 															AS LocalCost,
	|	CASE WHEN &Constant_KeepManagementRecordsOfOrganizations
	|	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_StartDateOfManagementAccountingOfOrganizations, MONTH)
	|	  AND &Constant_BatchAccountingVersion22
	|	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN DocumentData.CostMan
	|		ELSE 0
	|	END 																					AS CostMan,
	|	CASE WHEN DocumentData.ThereIsRequestField_PermanentDifference
	|		THEN DocumentData.PermanentDifference
	|		ELSE 0
	|	END 																					AS PermanentDifference,
	|	CASE WHEN DocumentData.ThereIsRequestField_CostTD
	|		THEN DocumentData.CostTD
	|		ELSE 0
	|	END 																					AS CostTD,
	|
	// Batch accounting fields version 2.2
	|	UNDEFINED 																			AS Lot,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|		AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN CASE 
	|				WHEN VALUETYPE(DocumentData.Lot) = TYPE(Catalog.ProductionLots)
	|					AND DocumentData.Lot <> VALUE(Catalog.ProductionLots.EmptyRef)
	|					AND CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup <> VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|				THEN CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup
	|				WHEN (ISNULL(DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom, FALSE)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department))
	|					AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) = TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Estimated_FinancialAccountingDimension
	|				WHEN NOT (ISNULL(DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom, FALSE)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department))
	|					AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) <> TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Estimated_FinancialAccountingDimension
	|				ELSE UNDEFINED
	|			END
	|		ELSE UNDEFINED
	|	END																					AS FinancialAccountingDimension,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|		AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN CASE 
	|				WHEN VALUETYPE(DocumentData.Lot) = TYPE(Catalog.ProductionLots)
	|					AND DocumentData.Lot <> VALUE(Catalog.ProductionLots.EmptyRef)
	|					AND CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup <> VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|				THEN CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup
	|				WHEN ISNULL(DocumentData.TTCorItemAnalyticsOfInventoryLocationAttribute, UNDEFINED) = UNDEFINED THEN
	|					UNDEFINED
	|				WHEN (ISNULL(DocumentData.CatBoxItemKeysWarehouseAreaShopFloorStockroom, FALSE)
	|						OR DocumentData.CatBoxItemKeysTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department))
	|					AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) = TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Estimated_FinancialAccountingDimension
	|				WHEN NOT (ISNULL(DocumentData.CatBoxItemKeysWarehouseAreaShopFloorStockroom, FALSE)
	|						OR DocumentData.CatBoxItemKeysTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department))
	|					AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) <> TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Estimated_FinancialAccountingDimension
	|				ELSE UNDEFINED
	|			END
	|		ELSE UNDEFINED
	|	END																					AS CorControllingAttributes,
	|	CASE
	|		WHEN NOT &Constant_BatchAccountingVersion22
	|		  OR DocumentData.Period < BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|			THEN UNDEFINED
	|		WHEN VALUETYPE(DocumentData.Ref) IN (
	|		  TYPE(Document.InternalAcceptanceCertificate),
	|		  TYPE(Document.RecyclableWasteAllocation))
	|			THEN DocumentData.VATActivityType
	|			ELSE UNDEFINED
	|	END 																					AS VATActivityType,
	|	CASE
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
	|		   VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
	|			THEN DocumentData.VATActivityType
	|			ELSE DocumentData.VATActivityType
	|	END 																					AS CorVATActivityTypes,
	|
	|	CASE 
	|		WHEN NOT &Constant_BatchAccountingVersion22
	|		  OR DocumentData.Period < BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|			THEN UNDEFINED
	|		WHEN DocumentData.FIFOAccountingPoliciesRollingValuation
	|			THEN DocumentData.CorLot
	|			ELSE UNDEFINED
	|	END 																					AS CorLot,
	|	UNDEFINED 																			AS LotVendorAttributes,
	|	CASE WHEN DocumentData.ThereIsRequestField_LotVendorAttributes
	|		THEN DocumentData.LotVendorAttributes
	|		ELSE UNDEFINED
	|	END 																					AS LotVendorAttributesCorr,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|			AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN CASE 
	|				WHEN VALUETYPE(DocumentData.Lot) = TYPE(Catalog.ProductionLots)
	|					AND DocumentData.Lot <> VALUE(Catalog.ProductionLots.EmptyRef)
	|					AND CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup <> VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|				THEN CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup
	|				WHEN (ISNULL(DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom, FALSE)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department))
	|					AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) = TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Estimated_FinancialAccountingDimension
	|				WHEN NOT (ISNULL(DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom, FALSE)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department))
	|					AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) <> TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Estimated_FinancialAccountingDimension
	|				ELSE UNDEFINED
	|			END
	|		ELSE UNDEFINED
	|	END 																					AS FinancialAccountingDimensionOfDocument,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN DocumentData.DocumentVATActivityType
	|		ELSE UNDEFINED
	|	END 																					AS DocumentVATActivityType,
	|
	|	CASE
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer),
	|		   VALUE(Enum.BusinessTransactions.ReturnFromRetailCustomer),
	|		   VALUE(Enum.BusinessTransactions.ReturnOfGoodsViaCommissionAgent))
	|		  AND VALUETYPE(DocumentData.Ref) IN
	|			(TYPE(Document.ReturnOfGoodsFromCustomer),
	|			 TYPE(Document.IntercompanyGoodsReturn))
	|			THEN VALUE(Enum.LotRecordTypes.ReturnToAnotherWarehouse)
	|		ELSE VALUE(Enum.LotRecordTypes.Consumption)
	|	END 														  							AS EntryType,
	|	VALUE(Enum.CostAccountingTransactions.Move) 							AS CostAccountingTransaction,
	|	UNDEFINED 												  							AS DocumentSource,
	|	CASE
	|		WHEN VALUETYPE(DocumentData.Ref) IN (
	|		  TYPE(Document.InternalAcceptanceCertificate),
	|		  TYPE(Document.RecyclableWasteAllocation))
	|			THEN DocumentData.Ref
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent))
	|			THEN DocumentData.Ref
	|			ELSE UNDEFINED
	|	END 																					AS DocumentRegisterRecords,
	|	DocumentData.RowID 						  							AS RowID,
	|	DocumentData.FinRecordID 						  							AS FinRecordID,
	|	CASE
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting))
	|		  AND DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		  AND ISNULL(DocumentData.CorInventoryOwnerAttributeTypeOfInventory, UNDEFINED) <> VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.ConsignmentSale)
	|		ELSE DocumentData.BusinessTransactionSetting
	|	END																					AS BusinessTransactionSetting,
	|	DocumentData.AccountingPoliciesInventoryValuationMethod								AS InventoryValuationMethod,
	|	DocumentData.AccountingPoliciesWayToDetermineCost							AS CostDefiningMethod
	|INTO TTOperation_Move
	|FROM
	|	TTDocumentData_ AS DocumentData
	|WHERE
	|	DocumentData.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.Move)
	|	AND NOT (NOT (&Constant_BatchAccountingVersion22
	|			AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH))
	|		AND DocumentData.BusinessOperation IN
	|	  		(VALUE(Enum.BusinessTransactions.ReturnFromProduction))
	|		)
	|
	|UNION ALL
	|
	// ARRIVAL - registration with the recipient
	|SELECT
	|	DocumentData.OperationNumber AS OperationNumber,
	// Document description
	|	VALUE(AccumulationRecordType.Receipt) 	AS RecordType,
	|	DocumentData.Period 					AS Period,
	|	(CASE
	|		WHEN DocumentData.ThereIsRequestField_VariancePeriod
	|			THEN DocumentData.VariancePeriod
	|		 ELSE DATETIME(1,1,1) END) AS VariancePeriod,
	|
	// Item accounting fields
	|	ISNULL(DocumentData.CorCompanyLink, DocumentData.Organization) 							AS Organization,
	|	ISNULL(DocumentData.TTCorItemAnalyticsOfInventoryLocationAttribute, UNDEFINED) AS ItemsLocationAttributes,
	|	ISNULL(DocumentData.TTCorAnalyticsItemInventoryLocationAttributeSource, UNDEFINED) AS AnalysisOfAccountingProductsInitial,
	|	(CASE
	|		WHEN DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.Work_5)
	|		 AND NOT DocumentData.CatItemOfTraceableItem
	|			THEN VALUE(Catalog.InventoryKinds.EmptyRef)
	|		WHEN DocumentData.BusinessOperation IN
	|		   (VALUE(Enum.BusinessTransactions.GoodsMisgrading),
	|		   VALUE(Enum.BusinessTransactions.GoodsMisgradingWithRevaluation),
	|		   VALUE(Enum.BusinessTransactions.GoodsConsumption),
	|		   VALUE(Enum.BusinessTransactions.GoodsDamage),
	|		   VALUE(Enum.BusinessTransactions.GoodsDamageRevaluation))
	|		  AND DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN DocumentData.InventoryOwnerAttribute
	|		ELSE DocumentData.CorInventoryOwnerAttribute END)											AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN DocumentData.ThereIsRequestField_CorAccountingSection
	|			THEN DocumentData.CorAccountingSection
	|		WHEN DocumentData.Settlement_CorAccountingSection <> UNDEFINED
	|			THEN DocumentData.Settlement_CorAccountingSection
	|		WHEN DocumentData.CatBoxItemTypeOfItem = VALUE(Enum.ItemsTypes.Work_5)
	|				OR DocumentData.CatBoxItemTypeOfItem = VALUE(Enum.ItemsTypes.OperationService)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	// The goods are in storage with the right to sell
	|		WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|		 AND DocumentData.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.GoodsConsumption),
	|				VALUE(Enum.BusinessTransactions.WriteOffShortagesAtDepositorSExpense),
	|				VALUE(Enum.BusinessTransactions.RecognizeInventorySurplusForTheBenefitOfDepositor),
	|				VALUE(Enum.BusinessTransactions.GoodsWriteOffAtToller))
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInStorageWithRightOfSaleToRegisterWriteOff)
	// If, during the re-sorting or damage of goods in storage, own goods are accounted for, then the transfer 
	// to the Accounting section "Goods in storage with the right of sale (for write-off)" is reflected.
	|		WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|		 AND DocumentData.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.GoodsMisgrading),
	|				VALUE(Enum.BusinessTransactions.GoodsMisgradingWithRevaluation),
	|				VALUE(Enum.BusinessTransactions.GoodsDamage),
	|				VALUE(Enum.BusinessTransactions.GoodsDamageRevaluation))
	|		 AND DocumentData.CorInventoryOwnerAttributeTypeOfInventory = VALUE(Enum.InventoryTypes.OwnGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInStorageWithRightOfSaleToRegisterWriteOff)
	|		WHEN DocumentData.DocumentBusinessTransaction IN
	|				(VALUE(Enum.BusinessTransactions.TransferToStorageWithRightOfSale),
	|				VALUE(Enum.BusinessTransactions.MisgradingOfGoodsAtCustodian),
	|				VALUE(Enum.BusinessTransactions.DamageAtCustodian))
	|			THEN
	|				CASE
	|					WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|						THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInCustodyWithSalesTransferredToPartners)
	|						ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsTransferredToPartners)
	|				END
	|		WHEN DocumentData.DocumentBusinessTransaction IN
	|				(VALUE(Enum.BusinessTransactions.TransferToToller2_5),
	|				VALUE(Enum.BusinessTransactions.MisgradingOfGoodsAtToller),
	|				VALUE(Enum.BusinessTransactions.DamageAtToller))
	|			THEN
	|				CASE
	|					WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|						THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInCustodyWithSalesTransferredToPartners)
	|						ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller)
	|				END
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.WorkAcceptanceAndTransferBetweenBusinessUnits),
	|		   VALUE(Enum.BusinessTransactions.WorkAcceptanceAndTransferBetweenBranchOffices))
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.TransferToCommissionAgent),
	|		   VALUE(Enum.BusinessTransactions.RecognizeInventorySurplusForTheBenefitOfConsignor))
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent)
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.WriteOffShortagesAtConsignorSExpense))
	|			THEN 
	|				CASE
	|					WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.OwnGoods)
	|						THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent)
	|						ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|				END
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle))
	|		  AND DocumentData.CorInventoryOwnerAttributeTypeOfInventory <> VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransit)
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle))
	|		  AND DocumentData.CorInventoryOwnerAttributeTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitReceivedByCommissionAgent)
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
	|		  AND DocumentData.CorInventoryOwnerAttributeTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitReceivedByCommissionAgent)
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
	|		  AND DocumentData.CorInventoryOwnerAttributeTypeOfInventory <> VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitTransferredToCommissionAgent)
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer),
	|		   VALUE(Enum.BusinessTransactions.ReturnFromRetailCustomer),
	|		   VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent),
	|		   VALUE(Enum.BusinessTransactions.ReturnOfGoodsViaCommissionAgent))
	|		  AND DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.TransferOfGoodsToCommissionAgentInAnotherCompany))
	|			THEN 
	|				CASE
	|					WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|						THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|						ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent)
	|				END
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.ReturnFromCustodian),
	|		  VALUE(Enum.BusinessTransactions.ReturnFromProcessingCompany2_5))
	|			THEN 
	|				CASE
	|					WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|						THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|					WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|						THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsAtStorageWithRightOfSale)
	|					WHEN DocumentData.CorInventoryLocationSAttributesStorageAreaShopFloorStockroom
	|		  			  OR DocumentData.CorOfInventoryLocationAttributeTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department)
	|						THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|						ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|				END
	|		WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		  AND DocumentData.CorInventoryOwnerAttributeTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsAtStorageWithRightOfSale)
	|		WHEN DocumentData.CorInventoryLocationSAttributesStorageAreaShopFloorStockroom
	|		  OR DocumentData.CorOfInventoryLocationAttributeTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|			ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|	END 																					AS AccountingSection,
	|
	// Corresponding fields
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) AS CorAccountingSection,
	|	UNDEFINED AS CorCompany,
	|	UNDEFINED AS CorItemsLocationAttributes,
	|	UNDEFINED AS CorAnalysisOfAccountingProductsInitial,
	|	UNDEFINED AS CorInventoryOwnerAttribute,
	|
	// Other fields
	|	CASE
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.WorkAcceptanceAndTransferBetweenBranchOffices))
	|			THEN VALUE(Enum.BusinessTransactions.InternalWorkReceipt)
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.TransferOfGoodsBetweenBranchOffices),
	|		   VALUE(Enum.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices))
	|			THEN VALUE(Enum.BusinessTransactions.InternalGoodsReceipt)
	|		ELSE DocumentData.BusinessOperation
	|	END 							AS BusinessOperation,
	|	CASE WHEN VALUETYPE(DocumentData.Ref) IN (TYPE(Document.MovementOfProductsAndMaterials))
	|		THEN UNDEFINED
	|		ELSE DocumentData.Department
	|	END 							AS Department,
	|	CASE
	|		WHEN FALSE
	|			THEN UNDEFINED
	|
	|
	|
	|			ELSE UNDEFINED
	|
	|	END							AS ProductsGroup,
	|	CASE WHEN DocumentData.ThereIsRequestField_SalesOrder
	|		THEN DocumentData.SalesOrder
	|		ELSE UNDEFINED
	|	END							AS SalesOrder,
	|	UNDEFINED					AS AccountingDimensionByPartners,
	|
	// Quantitative and summary indicators
	|	DocumentData.Count 																AS Count,
	|	DocumentData.Cost 																AS Cost,
	|	DocumentData.CostExcludingVAT 														AS CostExcludingVAT,
	|	DocumentData.LocalCost 															AS LocalCost,
	|	CASE WHEN &Constant_KeepManagementRecordsOfOrganizations
	|	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_StartDateOfManagementAccountingOfOrganizations, MONTH)
	|	  AND &Constant_BatchAccountingVersion22
	|	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN DocumentData.CostMan
	|		ELSE 0
	|	END 																					AS CostMan,
	|	CASE WHEN DocumentData.ThereIsRequestField_PermanentDifference
	|		THEN DocumentData.PermanentDifference
	|		ELSE 0
	|	END 																					AS PermanentDifference,
	|	CASE WHEN DocumentData.ThereIsRequestField_CostTD
	|		THEN DocumentData.CostTD
	|		ELSE 0
	|	END 																					AS CostTD,
	|
	// Batch accounting fields version 2.2
	|	CASE
	|		WHEN NOT &Constant_BatchAccountingVersion22
	|		  OR DocumentData.Period < BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|			THEN UNDEFINED
	|		WHEN DocumentData.BusinessOperation IN
	|			(VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
	|			VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
	|	      AND DocumentData.FIFOAccountingPoliciesRollingValuation
	|			THEN DocumentData.Ref
	|			ELSE UNDEFINED
	|	END 															AS Lot,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|			AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN CASE 
	|				WHEN VALUETYPE(DocumentData.Lot) = TYPE(Catalog.ProductionLots)
	|					AND DocumentData.Lot <> VALUE(Catalog.ProductionLots.EmptyRef)
	|					AND CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup <> VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|				THEN CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup
	|				WHEN (ISNULL(DocumentData.CatBoxItemKeysWarehouseAreaShopFloorStockroom, FALSE)
	|						OR DocumentData.CatBoxItemKeysTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department))
	|					AND VALUETYPE(DocumentData.Settlement_CorControllingAttributeOfFinancialAccounting) = TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Settlement_CorControllingAttributeOfFinancialAccounting
	|				WHEN NOT (ISNULL(DocumentData.CatBoxItemKeysWarehouseAreaShopFloorStockroom, FALSE)
	|						OR DocumentData.CatBoxItemKeysTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department))
	|					AND VALUETYPE(DocumentData.Settlement_CorControllingAttributeOfFinancialAccounting) <> TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Settlement_CorControllingAttributeOfFinancialAccounting
	|				ELSE UNDEFINED
	|			END
	|		ELSE UNDEFINED
	|	END															AS FinancialAccountingDimension,
	|	UNDEFINED 													AS CorControllingAttributes,
	|	CASE
	|		WHEN NOT &Constant_BatchAccountingVersion22
	|		  OR DocumentData.Period < BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|			THEN UNDEFINED
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
	|		   VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
	|			THEN DocumentData.VATActivityType
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.TransferToCommissionAgent))
	|			THEN UNDEFINED
	|		WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN UNDEFINED
	|		ELSE DocumentData.VATActivityType
	|	END 															AS VATActivityType,
	|	CASE
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
	|		   VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
	|			THEN DocumentData.VATActivityType
	|		WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN DocumentData.VATActivityType
	|			ELSE UNDEFINED
	|	END 															AS CorVATActivityTypes,
	|
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|	  AND NOT DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
	|		   VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
	|		THEN DocumentData.CorLot
	|		ELSE UNDEFINED
	|	END 															AS CorLot,
	|	CASE WHEN DocumentData.ThereIsRequestField_LotVendorAttributes
	|		THEN DocumentData.LotVendorAttributes
	|		ELSE UNDEFINED
	|	END 															AS LotVendorAttributes,
	|	UNDEFINED 													AS LotVendorAttributesCorr,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|			AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN CASE 
	|				WHEN VALUETYPE(DocumentData.Lot) = TYPE(Catalog.ProductionLots)
	|					AND DocumentData.Lot <> VALUE(Catalog.ProductionLots.EmptyRef)
	|					AND CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup <> VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|				THEN CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup
	|				WHEN (ISNULL(DocumentData.CatBoxItemKeysWarehouseAreaShopFloorStockroom, FALSE)
	|						OR DocumentData.CatBoxItemKeysTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department))
	|					AND VALUETYPE(DocumentData.Settlement_CorControllingAttributeOfFinancialAccounting) = TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Settlement_CorControllingAttributeOfFinancialAccounting
	|				WHEN NOT (ISNULL(DocumentData.CatBoxItemKeysWarehouseAreaShopFloorStockroom, FALSE)
	|						OR DocumentData.CatBoxItemKeysTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department))
	|					AND VALUETYPE(DocumentData.Settlement_CorControllingAttributeOfFinancialAccounting) <> TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Settlement_CorControllingAttributeOfFinancialAccounting
	|				ELSE UNDEFINED
	|			END
	|		ELSE UNDEFINED
	|	END 															AS FinancialAccountingDimensionOfDocument,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN DocumentData.DocumentVATActivityType
	|		ELSE UNDEFINED
	|	END 															AS DocumentVATActivityType,
	|
	|	CASE
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.WorkAcceptanceAndTransferBetweenBranchOffices))
	|			THEN VALUE(Enum.LotRecordTypes.TransferOnAssignmentBasis)
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting))
	|			THEN VALUE(Enum.LotRecordTypes.TransferMan)
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.TransferOfGoodsBetweenBranchOffices),
	|		   VALUE(Enum.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices))
	|			THEN VALUE(Enum.LotRecordTypes.TransferOnAssignmentBasis)
	|		WHEN DocumentData.BusinessOperation = 
	|			VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle) THEN
	|			VALUE(Enum.LotRecordTypes.TransferGoodsInTransit)
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferBalancesToNewActivityType)
	|			AND BEGINOFPERIOD(DocumentData.Period, MONTH) <> DocumentData.Period
	|			THEN VALUE(Enum.LotRecordTypes.TransferToBalance)
	|		ELSE VALUE(Enum.LotRecordTypes.Move)
	|	END 															AS EntryType,
	|	VALUE(Enum.CostAccountingTransactions.Move) 	AS CostAccountingTransaction,
	|	CASE
	|		WHEN VALUETYPE(DocumentData.Ref) IN 
	|		  (TYPE(Document.ReceiptOfGoodsFromCustodian), TYPE(Document.TransferOfGoodsToBailee))
	|			THEN DocumentData.Ref
	|		ELSE UNDEFINED
	|	END 															AS DocumentSource,
	|	CASE
	|		WHEN VALUETYPE(DocumentData.Ref) IN (
	|		  TYPE(Document.InternalAcceptanceCertificate),
	|		  TYPE(Document.RecyclableWasteAllocation))
	|			THEN DocumentData.Ref
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent))
	|			THEN DocumentData.Ref
	|		ELSE UNDEFINED
	|	END 															AS DocumentRegisterRecords,
	|	DocumentData.RowID 						  	AS RowID,
	|	DocumentData.FinRecordID 						  	AS FinRecordID,
	|	DocumentData.BusinessTransactionSetting				  	AS BusinessTransactionSetting,
	|	DocumentData.AccountingPoliciesInventoryValuationMethod		AS InventoryValuationMethod,
	|	CASE WHEN DocumentData.AccountingPoliciesOfOrganizationsAverageSlidingValuation
	|		THEN VALUE(Enum.WaysToCalculateInventoryCost.ByCorRecord)
	|		ELSE DocumentData.AccountingPoliciesWayToDetermineCost
	|	END 															AS CostDefiningMethod
	|FROM
	|	TTDocumentData_ AS DocumentData
	|WHERE
	|	DocumentData.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.Move)
	|
	|UNION ALL
	|
	// EXPENSE - write-off of commission goods
	|SELECT
	|	DocumentData.OperationNumber AS OperationNumber,
	// Document description
	|	VALUE(AccumulationRecordType.Expense) 	AS RecordType,
	|	DocumentData.Period 					AS Period,
	|	(CASE
	|		WHEN DocumentData.ThereIsRequestField_VariancePeriod
	|			THEN DocumentData.VariancePeriod
	|		 ELSE DATETIME(1,1,1) END) AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentData.Organization 														AS Organization,
	|	ISNULL(DocumentData.AnalyticsOfItemInventoryLocationAttributeTT, UNDEFINED) AS ItemsLocationAttributes,
	|	ISNULL(DocumentData.InitialInventoryLocationAttributeTTAnalyticsForItemTypesIsOriginalOne, UNDEFINED) AS AnalysisOfAccountingProductsInitial,
	|	CASE
	|		WHEN DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.Work_5)
	|				AND NOT DocumentData.CatItemOfTraceableItem
	|			THEN VALUE(Catalog.InventoryKinds.EmptyRef)
	|		ELSE DocumentData.InventoryOwnerAttribute
	|	END					 															AS InventoryOwnerAttribute,
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent) 	AS AccountingSection,
	|
	// Corresponding fields
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) AS CorAccountingSection,
	|	UNDEFINED AS CorCompany,
	|	UNDEFINED AS CorItemsLocationAttributes,
	|	UNDEFINED AS CorAnalysisOfAccountingProductsInitial,
	|	UNDEFINED AS CorInventoryOwnerAttribute,
	|
	// Other fields
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	CASE WHEN VALUETYPE(DocumentData.Ref) IN (TYPE(Document.MovementOfProductsAndMaterials))
	|		THEN UNDEFINED
	|		ELSE DocumentData.Department
	|	END 								  AS Department,
	|	UNDEFINED						  AS ProductsGroup,
	|	CASE WHEN DocumentData.ThereIsRequestField_SalesOrder
	|		THEN DocumentData.SalesOrder
	|		ELSE UNDEFINED
	|	END								  AS SalesOrder,
	|	UNDEFINED						  AS AccountingDimensionByPartners,
	|
	// Quantitative and summary indicators
	|	DocumentData.Count AS Count,
	|	0 AS Cost,
	|	0 AS CostExcludingVAT,
	|	0 AS LocalCost,
	|	0 AS CostMan,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|
	// Batch accounting fields version 2.2
	|	UNDEFINED 																	AS Lot,
	|	UNDEFINED 																	AS FinancialAccountingDimension,
	|	UNDEFINED 																	AS CorControllingAttributes,
	|	UNDEFINED 																	AS VATActivityType,
	|	CASE
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
	|		   VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
	|			THEN DocumentData.VATActivityType
	|			ELSE UNDEFINED
	|	END 																			AS CorVATActivityTypes,
	|
	|	CASE
	|		WHEN NOT &Constant_BatchAccountingVersion22
	|		  OR DocumentData.Period < BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|			THEN UNDEFINED
	|		WHEN DocumentData.FIFOAccountingPoliciesRollingValuation
	|			THEN DocumentData.CorLot
	|			ELSE UNDEFINED
	|	END 																			AS CorLot,
	|	UNDEFINED 																	AS LotVendorAttributes,
	|	UNDEFINED 																	AS LotVendorAttributesCorr,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|			AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN CASE 
	|				WHEN VALUETYPE(DocumentData.Lot) = TYPE(Catalog.ProductionLots)
	|					AND DocumentData.Lot <> VALUE(Catalog.ProductionLots.EmptyRef)
	|					AND CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup <> VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|				THEN CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup
	|				WHEN (ISNULL(DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom, FALSE)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department))
	|					AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) = TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Estimated_FinancialAccountingDimension
	|				WHEN NOT (ISNULL(DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom, FALSE)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department))
	|					AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) <> TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Estimated_FinancialAccountingDimension
	|				ELSE UNDEFINED
	|			END
	|		ELSE UNDEFINED
	|	END 																			AS FinancialAccountingDimensionOfDocument,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN DocumentData.DocumentVATActivityType
	|		ELSE UNDEFINED
	|	END 																			AS DocumentVATActivityType,
	|
	|	VALUE(Enum.LotRecordTypes.Consumption) 		  					AS EntryType,
	|	VALUE(Enum.CostAccountingTransactions.Move) 					AS CostAccountingTransaction,
	|	UNDEFINED 												  					AS DocumentSource,
	|	UNDEFINED 																	AS DocumentRegisterRecords,
	|	DocumentData.RowID 						  					AS RowID,
	|	DocumentData.FinRecordID 						  					AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ConsignedGoodsWriteOff)	AS BusinessTransactionSetting,
	|	DocumentData.AccountingPoliciesInventoryValuationMethod						AS InventoryValuationMethod,
	|	DocumentData.AccountingPoliciesWayToDetermineCost					AS CostDefiningMethod
	|FROM
	|	TTDocumentData_ AS DocumentData
	|WHERE
	|	DocumentData.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.Move)
	|	AND DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|	AND ISNULL(DocumentData.CorInventoryOwnerAttributeTypeOfInventory, UNDEFINED) <> VALUE(Enum.InventoryTypes.ConsignedGoods)
	|	AND NOT DocumentData.BusinessOperation IN
	|	  	(VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting))
	|";
	
	ReflectionParameters.TTTemplateTexts.Insert("TTOperation_Move", ReflectionRequestText);
	
EndProcedure

// Description of the principles of the formation of movements of the modular operation "Implementation".
// 
// When selling the inventory type "Semi-finished giver", if the inventory type "Giver's products" is filled in the source data
// - : - the book value of the Product is written off to the cost of sales, in the register "Revenue and cost of sales" -
// - off-balance sheet cost is transferred to the cost of the giver's products (inventory type "Giver's Products")   
// 	for this additional incoming movement is generated by cor type of stocks
//
Procedure ReflectCostOperation(ReflectionParameters)
	
	// Let's form a template of the request text to reflect the operation.
	ReflectionRequestText =
	"SELECT
	|	DocumentData.OperationNumber AS OperationNumber,
	// Document description
	|	CASE
	|		WHEN DocumentData.BusinessOperation IN
	|			(VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomerOfPreviousPeriods),
	|			VALUE(Enum.BusinessTransactions.GoodsReturnViaCommissionAgentOfPreviousPeriods),
	|			VALUE(Enum.BusinessTransactions.ReverseOfSaleReturnToAnotherWarehouse),
	|			VALUE(Enum.BusinessTransactions.ReportToMaterialProviderAdjustmentOfPastPeriod))
	|		THEN VALUE(AccumulationRecordType.Receipt)
	|			ELSE VALUE(AccumulationRecordType.Expense)
	|	END									AS RecordType,
	|	DocumentData.Period 					AS Period,
	|	(CASE
	|		WHEN DocumentData.ThereIsRequestField_VariancePeriod
	|			THEN DocumentData.VariancePeriod
	|		 ELSE DATETIME(1,1,1) END) AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentData.Organization 															AS Organization,
	|	ISNULL(DocumentData.AnalyticsOfItemInventoryLocationAttributeTT, UNDEFINED) AS ItemsLocationAttributes,
	|	ISNULL(DocumentData.InitialInventoryLocationAttributeTTAnalyticsForItemTypesIsOriginalOne, UNDEFINED) AS AnalysisOfAccountingProductsInitial,
	|	CASE
	|		WHEN DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.Work_5)
	|				AND NOT DocumentData.CatItemOfTraceableItem
	|			THEN VALUE(Catalog.InventoryKinds.EmptyRef)
	|		ELSE DocumentData.InventoryOwnerAttribute
	|	END																					AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN DocumentData.ThereIsRequestField_AccountingSection AND DocumentData.AccountingSection <> UNDEFINED
	|		 AND DocumentData.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
	|			THEN DocumentData.AccountingSection
	|		WHEN DocumentData.Settlement_AccountingSection <> UNDEFINED
	|			THEN DocumentData.Settlement_AccountingSection
	|		WHEN DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.Work_5)
	|				OR DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.OperationService)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.WriteOffShortagesAtDepositorSExpense))
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsTransferredToPartners)
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.GoodsWriteOffAtToller))
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller)
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer),
	|		   VALUE(Enum.BusinessTransactions.RecognizeInventorySurplusForTheBenefitOfConsignor),
	|		   VALUE(Enum.BusinessTransactions.WriteOffShortagesAtConsignorSExpense),
	|		   VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent))
	|		  AND DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.OwnGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent)
	|		WHEN DocumentData.BusinessOperation IN(
	|		  VALUE(Enum.BusinessTransactions.ShipGoodsReceivedFromStorageWithRightOfSale),
	|		  VALUE(Enum.BusinessTransactions.DeliveryForPrincipal))
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsAtStorageWithRightOfSale)
	|		WHEN DocumentData.BusinessOperation IN(
	|		  VALUE(Enum.BusinessTransactions.RedemptionOfProviderGoods))
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping)
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.RedemptionOfGoodsFromStorage))
	|			THEN 
	|				CASE WHEN DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
	|					THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInCustodyWithSalesTransferredToPartners)
	|					ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsAtStorageWithRightOfSale)
	|				END
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.RedemptionOfGoodsByCustodian),
	|		   VALUE(Enum.BusinessTransactions.RedemptionOfGoodsByToller))
	|			THEN 
	|				CASE
	|					WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|						THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInCustodyWithSalesTransferredToPartners)
	|					WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.RedemptionOfGoodsByToller)
	|						THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller)
	|						ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsTransferredToPartners)
	|				END
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
	|			AND DocumentData.InventoryOwnerAttributeIsTypeOfInventory <> VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitTransferredToCommissionAgent)
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
	|			AND DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitReceivedByCommissionAgent)
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle))
	|		  AND DocumentData.InventoryOwnerAttributeIsTypeOfInventory <> VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransit)
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle))
	|		  AND DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitReceivedByCommissionAgent)
	|		WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		WHEN DocumentData.DocumentBusinessTransaction IN
	|		  (VALUE(Enum.BusinessTransactions.ReturnOfGoodsViaCommissionAgent))
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent)
	|		WHEN DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom
	|				OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|	END 																					AS AccountingSection,
	|
	// Corresponding fields
	|	CASE
	|		WHEN DocumentData.ThereIsRequestField_CorAccountingSection
	|			THEN DocumentData.CorAccountingSection
	// The conditions for filling in the accounting field of Operation from the accounting table must correspond to the conditions for generating 
	// the Receipt movement for the modular Implementation operation.
	|		WHEN ISNULL(DocumentData.CorInventoryOwnerAttributeTypeOfInventory, UNDEFINED) = VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider)
	|		 AND ISNULL(DocumentData.InventoryOwnerAttributeIsTypeOfInventory, UNDEFINED) = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|		 AND DocumentData.Settlement_CorAccountingSection <> UNDEFINED
	|			THEN DocumentData.Settlement_CorAccountingSection
	|		WHEN DocumentData.BusinessOperation =
	|				VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany)
	|			THEN CASE
	|				WHEN ISNULL(DocumentData.CatBoxItemTypeOfItem, UNDEFINED)
	|						= VALUE(Enum.ItemsTypes.Work_5)
	|					THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|				WHEN DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom
	|					OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department)
	|					THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|					ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|				END
	|		WHEN DocumentData.BusinessOperation =
	|			VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredIntercompany)
	|				THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
	|	END																					AS CorAccountingSection,
	|	DocumentData.CorCompany 															AS CorCompany,
	|	ISNULL(DocumentData.TTCorItemAnalyticsOfInventoryLocationAttribute, UNDEFINED) AS CorItemsLocationAttributes,
	|	ISNULL(DocumentData.TTCorAnalyticsItemInventoryLocationAttributeSource, UNDEFINED) AS CorAnalysisOfAccountingProductsInitial,
	|	CASE
	|		WHEN DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.Work_5)
	|				AND NOT DocumentData.CatItemOfTraceableItem
	|			THEN VALUE(Catalog.InventoryKinds.EmptyRef)
	|		ELSE DocumentData.CorInventoryOwnerAttribute
	|	END 															AS CorInventoryOwnerAttribute,
	|
	// Other fields
	|	(CASE
	|		WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		 AND DocumentData.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.SaleToCustomer),
	|				VALUE(Enum.BusinessTransactions.RetailSaleOfGoods))
	|			THEN VALUE(Enum.BusinessTransactions.ConsignmentSale)
	|		ELSE DocumentData.BusinessOperation END) AS BusinessOperation,
	|	DocumentData.AccountingDimensionByPartners 	AS AccountingDimensionByPartners,
	|	DocumentData.Department 				AS Department,
	|	DocumentData.SalesOrder 				AS SalesOrder,
	|	CASE
	|		WHEN DocumentData.ThereIsRequestField_SalePeriod
	|			THEN DocumentData.SalePeriod
	|		ELSE DocumentData.SourceDocumentPeriod
	|	END										AS SalePeriod,
	|
	// Quantitative and summary indicators
	|	DocumentData.Count 					AS Count,
	|	CASE WHEN DocumentData.ThereIsRequestField_Cost
	|		THEN DocumentData.Cost
	|		ELSE 0
	|	END										AS Cost,
	|	CASE WHEN DocumentData.ThereIsRequestField_CostExcludingVAT
	|		THEN DocumentData.CostExcludingVAT
	|		ELSE 0
	|	END										AS CostExcludingVAT,
	|	CASE WHEN DocumentData.ThereIsRequestField_LocalCost
	|		THEN DocumentData.LocalCost
	|		ELSE 0
	|	END										AS LocalCost,
	|	CASE WHEN DocumentData.ThereIsRequestField_CostMan
	|		THEN DocumentData.CostMan
	|		ELSE 0
	|	END										AS CostMan,
	|	CASE WHEN DocumentData.ThereIsRequestField_OffBalanceCost
	|		THEN DocumentData.OffBalanceCost
	|		ELSE 0
	|	END 										AS OffBalanceCost,
	|	CASE WHEN DocumentData.ThereIsRequestField_OffBalanceCostLocal
	|		THEN DocumentData.OffBalanceCostLocal
	|		ELSE 0
	|	END 										AS OffBalanceCostLocal,
	|
	// Batch accounting fields version 2.2
	|	CASE
	|		WHEN NOT &Constant_BatchAccountingVersion22
	|		  OR DocumentData.Period < BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|			THEN UNDEFINED
	|		WHEN DocumentData.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
	|				VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit),
	|				VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredIntercompany))
	|			AND DocumentData.FIFOAccountingPoliciesRollingValuation
	|			THEN DocumentData.Ref
	|			ELSE UNDEFINED
	|	END 														AS Lot,
	|	CASE WHEN DocumentData.ThereIsRequestField_LotVendorAttributes
	|				AND DocumentData.FIFOAccountingPoliciesRollingValuation
	|		THEN DocumentData.LotVendorAttributes
	|		ELSE UNDEFINED
	|	END														AS LotVendorAttributes,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		AND ISNULL(DocumentData.CorAccountingPoliciesFIFORollingValuation, TRUE) = TRUE
	|		THEN DocumentData.LotVendorAttributesCorr
	|		ELSE UNDEFINED
	|	END 														  AS LotVendorAttributesCorr,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|			AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN CASE 
	|				WHEN VALUETYPE(DocumentData.Lot) = TYPE(Catalog.ProductionLots)
	|					AND DocumentData.Lot <> VALUE(Catalog.ProductionLots.EmptyRef)
	|					AND CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup <> VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|				THEN CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup
	|				WHEN (ISNULL(DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom, FALSE)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department))
	|					AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) = TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Estimated_FinancialAccountingDimension
	|				WHEN NOT (ISNULL(DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom, FALSE)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department))
	|					AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) <> TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Estimated_FinancialAccountingDimension
	|				ELSE UNDEFINED
	|			END
	|		ELSE UNDEFINED
	|	END 														AS FinancialAccountingDimension,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|			AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|			AND (VALUETYPE(DocumentData.Ref) = TYPE(Document.CustomerInvoice)
	|			AND DocumentData.CatProductsTypeOfProducts <> VALUE(Enum.ItemsTypes.Work_5))
	|		THEN DocumentData.Estimated_FinancialAccountingDimension
	|		ELSE UNDEFINED
	|	END 														  AS CorControllingAttributes,
	|	CASE
	|		WHEN NOT &Constant_BatchAccountingVersion22
	|		  OR DocumentData.Period < BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|			THEN UNDEFINED
	|		WHEN NOT DocumentData.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
	|				VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit),
	|				VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredIntercompany),
	|				VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomerOfPreviousPeriods))
	|			THEN UNDEFINED
	|		ELSE DocumentData.VATActivityType
	|	END 														  AS VATActivityType,
	|	CASE
	|		WHEN DocumentData.ThereIsRequestField_CorVATActivityTypes
	|			THEN DocumentData.CorVATActivityTypes
	|		ELSE DocumentData.VATActivityType
	|	END							 							  AS CorVATActivityTypes,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		AND (ISNULL(DocumentData.CorAccountingPoliciesFIFORollingValuation, TRUE) = TRUE
	|			OR VALUETYPE(DocumentData.CorLot) = TYPE(Catalog.ProductionLots)
	|			)
	|		THEN DocumentData.CorLot
	|		ELSE UNDEFINED
	|	END 														  AS CorLot,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|			AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN CASE 
	|				WHEN VALUETYPE(DocumentData.Lot) = TYPE(Catalog.ProductionLots)
	|					AND DocumentData.Lot <> VALUE(Catalog.ProductionLots.EmptyRef)
	|					AND CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup <> VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|				THEN CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup
	|				WHEN (ISNULL(DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom, FALSE)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department))
	|					AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) = TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Estimated_FinancialAccountingDimension
	|				WHEN NOT (ISNULL(DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom, FALSE)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department))
	|					AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) <> TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Estimated_FinancialAccountingDimension
	|				ELSE UNDEFINED
	|			END
	|		ELSE UNDEFINED
	|	END 														AS FinancialAccountingDimensionOfDocument,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN DocumentData.DocumentVATActivityType
	|		ELSE UNDEFINED
	|	END 														  AS DocumentVATActivityType,
	|
	|	CASE
	|		WHEN DocumentData.ThereIsRequestField_EntryType
	|			THEN DocumentData.EntryType
	|		WHEN DocumentData.BusinessOperation IN(
	|				VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
	|				VALUE(Enum.BusinessTransactions.Subcontracting2_5),
	|				VALUE(Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5))
	|			AND DocumentData.Count < 0
	|			THEN VALUE(Enum.LotRecordTypes.ConsumptionReverseTransaction)
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomerOfPreviousPeriods),
	|		   VALUE(Enum.BusinessTransactions.GoodsReturnViaCommissionAgentOfPreviousPeriods))
	|			THEN VALUE(Enum.LotRecordTypes.PreviousPeriodReturn)
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer))
	|		  AND DocumentData.Count < 0
	|			THEN VALUE(Enum.LotRecordTypes.ReturnWithoutSourceDocument)
	|		WHEN DocumentData.BusinessOperation IN
	|			(VALUE(Enum.BusinessTransactions.TransferredPackageReverseTransaction),
	|			VALUE(Enum.BusinessTransactions.ReturnOfGoodsViaCommissionAgent),
	|			VALUE(Enum.BusinessTransactions.ReverseOfSale))
	|		THEN VALUE(Enum.LotRecordTypes.ReversingEntry)
	|		WHEN DocumentData.BusinessOperation IN
	|			(VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle))
	|		THEN VALUE(Enum.LotRecordTypes.ConsumptionGoodsInTransit)
	|		ELSE VALUE(Enum.LotRecordTypes.Consumption)
	|	END														  AS EntryType,
	|	VALUE(Enum.CostAccountingTransactions.SaleOfGoodsAndServices)  AS CostAccountingTransaction,
	|	DocumentData.DocumentSource 							  AS DocumentSource,
	|	CASE
	|		WHEN DocumentData.ThereIsRequestField_DocumentRegisterRecords
	|		 AND DocumentData.ThereIsRequestField_CostDefiningMethod
	|		 AND DocumentData.CostDefiningMethod = VALUE(Enum.WaysToCalculateInventoryCost.FromDocument)
	|			THEN DocumentData.DocumentRegisterRecords
	|		WHEN DocumentData.AccountingPoliciesWayToDetermineCost = VALUE(Enum.WaysToCalculateInventoryCost.ByMovingAverage)
	|			THEN DocumentData.Ref
	|		ELSE UNDEFINED END								  AS DocumentRegisterRecords,
	|	DocumentData.RowID 						  AS RowID,
	|	DocumentData.FinRecordID 						  AS FinRecordID,
	|	(CASE
	|		WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		 AND DocumentData.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.SaleToCustomer),
	|				VALUE(Enum.BusinessTransactions.RetailSaleOfGoods))
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.ConsignmentSale)
	|		ELSE DocumentData.BusinessTransactionSetting END) AS BusinessTransactionSetting,
	|	DocumentData.AccountingPoliciesInventoryValuationMethod	  AS InventoryValuationMethod,
	// The field "Method of determining the cost" is filled in the documents:
	//	- The report is issued between organizations - the value of the "Document", because when issued at the standard cost
	//		, the standard cost from the document is indicated in Registered Records.
	|	CASE
	|		WHEN DocumentData.ThereIsRequestField_CostDefiningMethod
	|		 AND DocumentData.CostDefiningMethod <> VALUE(Enum.WaysToCalculateInventoryCost.EmptyRef)
	|			THEN DocumentData.CostDefiningMethod
	|		WHEN DocumentData.AccountingPoliciesOfOrganizationsAverageSlidingValuation THEN
	|			CASE WHEN DocumentData.DocumentSource <> UNDEFINED
	|				THEN VALUE(Enum.WaysToCalculateInventoryCost.BySourceDocumentRegisterRecords)
	|				ELSE DocumentData.AccountingPoliciesWayToDetermineCost
	|			END
	|		ELSE DocumentData.AccountingPoliciesWayToDetermineCost
	|	END 															AS CostDefiningMethod
	|
	|INTO TTOperation_SaleOfGoodsAndServices
	|FROM
	|	TTDocumentData_ AS DocumentData
	|WHERE
	|	DocumentData.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.SaleOfGoodsAndServices)
	|
	|UNION ALL
	|
	// PARISH - giving goods
	|SELECT
	|	DocumentData.OperationNumber AS OperationNumber,
	// Document description
	|	VALUE(AccumulationRecordType.Receipt)	AS RecordType,
	|	DocumentData.Period 					AS Period,
	|	(CASE
	|		WHEN DocumentData.ThereIsRequestField_VariancePeriod
	|			THEN DocumentData.VariancePeriod
	|		 ELSE DATETIME(1,1,1) END) AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentData.Organization 															AS Organization,
	|	ISNULL(DocumentData.TTCorItemAnalyticsOfInventoryLocationAttribute, UNDEFINED) AS ItemsLocationAttributes,
	|	ISNULL(DocumentData.TTCorAnalyticsItemInventoryLocationAttributeSource, UNDEFINED) AS AnalysisOfAccountingProductsInitial,
	|	CASE
	|		WHEN DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.Work_5)
	|				AND NOT DocumentData.CatItemOfTraceableItem
	|			THEN VALUE(Catalog.InventoryKinds.EmptyRef)
	|		ELSE DocumentData.CorInventoryOwnerAttribute
	|	END															AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN DocumentData.ThereIsRequestField_CorAccountingSection
	|			THEN DocumentData.CorAccountingSection
	|		WHEN DocumentData.Settlement_CorAccountingSection <> UNDEFINED
	|			THEN DocumentData.Settlement_CorAccountingSection
	|			ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
	|	END 																					AS AccountingSection,
	|
	// Corresponding fields
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)					AS CorAccountingSection,
	|	UNDEFINED																			AS CorCompany,
	|	UNDEFINED																			AS CorItemsLocationAttributes,
	|	UNDEFINED																			AS CorAnalysisOfAccountingProductsInitial,
	|	UNDEFINED																			AS CorInventoryOwnerAttribute,
	|
	// Other fields
	|	DocumentData.BusinessOperation		AS BusinessOperation,
	|	UNDEFINED								AS AccountingDimensionByPartners,
	|	DocumentData.Department 				AS Department,
	|	UNDEFINED								AS SalesOrder,
	|	UNDEFINED								AS SalePeriod,
	|
	// Quantitative and summary indicators
	|	DocumentData.Count 					AS Count,
	|	0											AS Cost,
	|	0											AS CostExcludingVAT,
	|	0											AS LocalCost,
	|	0											AS CostMan,
	|	0	 										AS OffBalanceCost,
	|	0											AS OffBalanceCostLocal,
	|
	// Batch accounting fields version 2.2
	|	UNDEFINED													AS Lot,
	|	UNDEFINED													AS LotVendorAttributes,
	|	UNDEFINED													AS LotVendorAttributesCorr,
	|	UNDEFINED													AS FinancialAccountingDimension,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|			AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN CASE 
	|				WHEN VALUETYPE(DocumentData.Lot) = TYPE(Catalog.ProductionLots)
	|					AND DocumentData.Lot <> VALUE(Catalog.ProductionLots.EmptyRef)
	|					AND CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup <> VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|				THEN CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup
	|				WHEN (ISNULL(DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom, FALSE)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department))
	|					AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) = TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Estimated_FinancialAccountingDimension
	|				WHEN NOT (ISNULL(DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom, FALSE)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department))
	|					AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) <> TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Estimated_FinancialAccountingDimension
	|				ELSE UNDEFINED
	|			END
	|		ELSE UNDEFINED
	|	END 															AS CorControllingAttributes,
	|	CASE
	|		WHEN NOT &Constant_BatchAccountingVersion22
	|		  OR DocumentData.Period < BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|			THEN UNDEFINED
	|		ELSE DocumentData.VATActivityType
	|	END 															AS VATActivityType,
	|	UNDEFINED							 						AS CorVATActivityTypes,
	|	UNDEFINED 													AS CorLot,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|			AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN CASE 
	|				WHEN VALUETYPE(DocumentData.Lot) = TYPE(Catalog.ProductionLots)
	|					AND DocumentData.Lot <> VALUE(Catalog.ProductionLots.EmptyRef)
	|					AND CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup <> VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|				THEN CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup
	|				WHEN (ISNULL(DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom, FALSE)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department))
	|					AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) = TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Estimated_FinancialAccountingDimension
	|				WHEN NOT (ISNULL(DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom, FALSE)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department))
	|					AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) <> TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Estimated_FinancialAccountingDimension
	|				ELSE UNDEFINED
	|			END
	|		ELSE UNDEFINED
	|	END 															AS FinancialAccountingDimensionOfDocument,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN DocumentData.DocumentVATActivityType
	|		ELSE UNDEFINED
	|	END 															AS DocumentVATActivityType,
	|
	|	VALUE(Enum.LotRecordTypes.Move)			AS EntryType,
	|	VALUE(Enum.CostAccountingTransactions.SaleOfGoodsAndServices)	AS CostAccountingTransaction,
	|	DocumentData.Ref 											AS DocumentSource,
	|	UNDEFINED												  	AS DocumentRegisterRecords,
	|	DocumentData.RowID 							AS RowID,
	// For the arrival of toll-free products, we do not fill in the ID of the fin record, because toll-free products do not have a book value.
	|	&IDOfUnusedFinRecord 							AS FinRecordID,
	|	DocumentData.BusinessTransactionSetting					AS BusinessTransactionSetting,
	|	DocumentData.AccountingPoliciesInventoryValuationMethod		AS InventoryValuationMethod,
	|	CASE
	|		WHEN DocumentData.ThereIsRequestField_CostDefiningMethod
	|		 AND DocumentData.CostDefiningMethod <> VALUE(Enum.WaysToCalculateInventoryCost.EmptyRef)
	|			THEN DocumentData.CostDefiningMethod
	|		WHEN DocumentData.AccountingPoliciesOfOrganizationsAverageSlidingValuation
	|			THEN VALUE(Enum.WaysToCalculateInventoryCost.ByCorRecord)
	|		ELSE DocumentData.AccountingPoliciesWayToDetermineCost
	|	END 															AS CostDefiningMethod
	|FROM
	|	TTDocumentData_ AS DocumentData
	|WHERE
	|	DocumentData.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.SaleOfGoodsAndServices)
	|	AND ISNULL(DocumentData.CorInventoryOwnerAttributeTypeOfInventory, UNDEFINED) = VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider)
	|	AND ISNULL(DocumentData.InventoryOwnerAttributeIsTypeOfInventory, UNDEFINED) = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|";
	
	ReflectionParameters.TTTemplateTexts.Insert("TTOperation_SaleOfGoodsAndServices", ReflectionRequestText);
	
EndProcedure

Procedure ReflectTransactionCostWriteOffToOtherParties(ReflectionParameters)
	
	// Let's form a template of the request text to reflect the operation.
	ReflectionRequestText =
	"
	// EXPENSE - debiting from the sender
	|SELECT
	|	DocumentData.OperationNumber AS OperationNumber,
	// Document description
	|	VALUE(AccumulationRecordType.Expense) 	AS RecordType,
	|	DocumentData.Period 					AS Period,
	|	(CASE
	|		WHEN DocumentData.ThereIsRequestField_VariancePeriod
	|			THEN DocumentData.VariancePeriod
	|		 ELSE DATETIME(1,1,1) END) AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentData.Organization 														AS Organization,
	|	CASE WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		  AND ISNULL(DocumentData.CorInventoryOwnerAttributeTypeOfInventory, UNDEFINED) <> VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		THEN ISNULL(DocumentData.CommitteeSInventoryLocationAttributeAnalyticsTTItemTypeOfCommitteeSInventoryTypeOfCommitteeTypeOfCommitteeTypeOfCommitteeTypeOfCommitteeTypeOfCommitteeTypeOfCommitteeTypeOfCommittee, UNDEFINED)
	|		ELSE ISNULL(DocumentData.AnalyticsOfItemInventoryLocationAttributeTT, UNDEFINED)
	|	END 																				AS ItemsLocationAttributes,
	|	ISNULL(DocumentData.InitialInventoryLocationAttributeTTAnalyticsForItemTypesIsOriginalOne, UNDEFINED) AS AnalysisOfAccountingProductsInitial,
	|	CASE
	|		WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		  AND ISNULL(DocumentData.CorInventoryOwnerAttributeTypeOfInventory, UNDEFINED) <> VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		THEN VALUE(Catalog.InventoryKinds.EmptyRef)
	|		WHEN DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.Work_5)
	|		 AND NOT DocumentData.CatItemOfTraceableItem
	|			THEN VALUE(Catalog.InventoryKinds.EmptyRef)
	|		ELSE DocumentData.InventoryOwnerAttribute
	|	END 																				AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN DocumentData.ThereIsRequestField_AccountingSection AND DocumentData.AccountingSection <> UNDEFINED
	|		 AND DocumentData.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
	|			THEN DocumentData.AccountingSection
	|		WHEN DocumentData.Settlement_AccountingSection <> UNDEFINED AND NOT
	//	We redefine the Accounting section only when we do not redefine the analytics of accounting and the type of inventory. For a commission product
	//	, it is redefined, and therefore the Accounting section defined by general principles is no longer suitable.
	|			(DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|				AND ISNULL(DocumentData.CorInventoryOwnerAttributeTypeOfInventory, UNDEFINED) <> VALUE(Enum.InventoryTypes.ConsignedGoods))
	|			THEN DocumentData.Settlement_AccountingSection
	|		WHEN DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.Work_5)
	|		  OR DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.OperationService)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	// The goods are in storage with the right to sell
	|		WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN (CASE
	|				WHEN DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
	|					THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInCustodyWithSalesTransferredToPartners)
	|				ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsAtStorageWithRightOfSale) END)
	|		WHEN DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
	|		 AND (DocumentData.CatItemKeysContractTypeOfContract = VALUE(Enum.ContractTypes.TransferToTolling2_5)
	|			OR DocumentData.CatItemKeysContractTypeOfContract = VALUE(Enum.ContractTypes.SubcontractingToTheEAEUCountries))
	|		 AND DocumentData.CatProductsTypeOfProducts <> VALUE(Enum.ItemsTypes.Work_5)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller)
	|		WHEN DocumentData.BusinessOperation IN (
	|								VALUE(Enum.BusinessTransactions.ExpensingToProductionLots),
	|								VALUE(Enum.BusinessTransactions.GoodsConsumptionOnDemand))
	|			AND DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|					THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|		WHEN (DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom
	|				OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department))
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|			ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|	END 																				AS AccountingSection,
	|
	// Corresponding fields
	|	CASE
	|		WHEN DocumentData.ThereIsRequestField_CorAccountingSection
	|			THEN DocumentData.CorAccountingSection
	|		WHEN DocumentData.Settlement_CorAccountingSection <> UNDEFINED
	|			THEN DocumentData.Settlement_CorAccountingSection
	|		WHEN DocumentData.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.ExpensingToProductionLots),
	|			VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredIntercompany))
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.RedemptionOfProviderGoods)
	|		 AND DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
	|		 AND DocumentData.CatItemKeysContractTypeOfContract = VALUE(Enum.ContractTypes.TransferToTolling2_5)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller)
	|
	|		WHEN DocumentData.CatBoxItemKeysTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
	|		 AND (DocumentData.CorAnalyticsContractTypeOfContract = VALUE(Enum.ContractTypes.TransferToTolling2_5)
	|			OR DocumentData.CorAnalyticsContractTypeOfContract = VALUE(Enum.ContractTypes.SubcontractingToTheEAEUCountries))
	|		 AND DocumentData.CatBoxItemTypeOfItem <> VALUE(Enum.ItemsTypes.Work_5)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller)
	|		WHEN DocumentData.CorInventoryOwnerAttributeTypeOfInventory = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsAtStorageWithRightOfSale)
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.RedemptionOfProviderGoods)
	|		 AND DocumentData.InventoryOwnerAttributeIsTypeOfInventory IN
	|		  (VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider),
	|		   VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.AllocationOfExpensesForProductionLots)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
	|		WHEN DocumentData.CorInventoryLocationSAttributesStorageAreaShopFloorStockroom
	|		  OR DocumentData.CorOfInventoryLocationAttributeTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|			ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|	END 																					AS CorAccountingSection,
	|	CASE
	|		WHEN DocumentData.CorCompany = DocumentData.Organization
	|			THEN UNDEFINED
	|			ELSE DocumentData.CorCompany
	|	END 																					AS CorCompany,
	|	ISNULL(DocumentData.TTCorItemAnalyticsOfInventoryLocationAttribute, UNDEFINED) AS CorItemsLocationAttributes,
	|	ISNULL(DocumentData.TTCorAnalyticsItemInventoryLocationAttributeSource, UNDEFINED) AS CorAnalysisOfAccountingProductsInitial,
	|	CASE
	|		WHEN DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.Work_5)
	|				AND NOT DocumentData.CatItemOfTraceableItem
	|			THEN VALUE(Catalog.InventoryKinds.EmptyRef)
	|		ELSE DocumentData.CorInventoryOwnerAttribute
	|	END 															AS CorInventoryOwnerAttribute,
	|
	// Other fields
	|	DocumentData.BusinessOperation 													AS BusinessOperation,
	|	DocumentData.Department 															AS Department,
	|	CASE
	|		WHEN FALSE
	|			THEN UNDEFINED
	|
	// To Register Records under the "Work in progress" section, the product group is not filled in.
	|		WHEN VALUETYPE(DocumentData.Lot) = TYPE(Catalog.ProductionLots)
	|			THEN VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|			ELSE UNDEFINED
	|	END																					AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	DocumentData.Count 																AS Count,
	|	CASE WHEN DocumentData.ThereIsRequestField_Cost
	|		THEN DocumentData.Cost
	|		ELSE 0
	|	END																					AS Cost,
	|	CASE WHEN DocumentData.ThereIsRequestField_CostExcludingVAT
	|		THEN DocumentData.CostExcludingVAT
	|		ELSE 0
	|	END																					AS CostExcludingVAT,
	|	CASE WHEN DocumentData.ThereIsRequestField_LocalCost
	|		THEN DocumentData.LocalCost
	|		ELSE 0
	|	END																					AS LocalCost,
	|	CASE WHEN DocumentData.ThereIsRequestField_CostMan
	|		THEN DocumentData.CostMan
	|		ELSE 0
	|	END																					AS CostMan,
	|	CASE WHEN DocumentData.ThereIsRequestField_VATLocal
	|		THEN DocumentData.VATLocal
	|		ELSE 0
	|	END																					AS VATLocal,
	|	CASE WHEN DocumentData.ThereIsRequestField_VATManag
	|		THEN DocumentData.VATManag
	|		ELSE 0
	|	END																					AS VATManag,
	|	CASE WHEN DocumentData.ThereIsRequestField_OffBalanceCost
	|		THEN DocumentData.OffBalanceCost
	|		ELSE 0
	|	END																					AS OffBalanceCost,
	|	CASE WHEN DocumentData.ThereIsRequestField_OffBalanceCostLocal
	|		THEN DocumentData.OffBalanceCostLocal
	|		ELSE 0
	|	END																					AS OffBalanceCostLocal,
	|
	// Batch accounting fields version 2.2
	|	CASE WHEN DocumentData.ThereIsRequestField_Lot
	|		AND &Constant_BatchAccountingVersion22
	|		AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		AND (DocumentData.FIFOAccountingPoliciesRollingValuation
	|			OR VALUETYPE(DocumentData.Lot) = TYPE(Catalog.ProductionLots)
	|			)
	|		THEN DocumentData.Lot
	|		ELSE UNDEFINED
	|	END																					AS Lot,
	|	CASE WHEN DocumentData.ThereIsRequestField_LotVendorAttributes
	|			AND (DocumentData.FIFOAccountingPoliciesRollingValuation
	|			OR VALUETYPE(DocumentData.Lot) = TYPE(Catalog.ProductionLots)
	|			)
	|		THEN DocumentData.LotVendorAttributes
	|		ELSE UNDEFINED
	|	END																					AS LotVendorAttributes,
	|	CASE
	|		WHEN &Constant_BatchAccountingVersion22
	|			AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN CASE 
	|
	// In the "Work in progress" Controlling attribute, the financial accounting should correspond to a group of products from
	// the production batch, or have an UNDEFINED value if the product group is not filled in.
	|				WHEN VALUETYPE(DocumentData.Lot) = TYPE(Catalog.ProductionLots)
	|				 AND DocumentData.Lot <> VALUE(Catalog.ProductionLots.EmptyRef)
	|					THEN CASE
	|						WHEN CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup
	|							<> VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|							THEN CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup
	|						ELSE UNDEFINED END
	|				WHEN (ISNULL(DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom, FALSE)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Partner))
	|					AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) = TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Estimated_FinancialAccountingDimension
	|				WHEN NOT (ISNULL(DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom, FALSE)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Partner))
	|					AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) <> TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Estimated_FinancialAccountingDimension
	|				ELSE UNDEFINED
	|			END
	|		ELSE UNDEFINED
	|	END																					AS FinancialAccountingDimension,
	// The field "Coralitikafinancovogoucheta" is filled in the documents:
	// - Processor's report - indicates the product group for the distribution of output costs.
	|	CASE
	|		WHEN DocumentData.ThereIsRequestField_CorControllingAttributes
	|			THEN DocumentData.CorControllingAttributes
	|		WHEN &Constant_BatchAccountingVersion22
	|			AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|			AND NOT DocumentData.TTCorItemAnalyticsOfInventoryLocationAttribute IS NULL
	|		THEN CASE
	|				WHEN VALUETYPE(DocumentData.CorLot) = TYPE(Catalog.ProductionLots)
	|				 AND DocumentData.CorLot <> VALUE(Catalog.ProductionLots.EmptyRef)
	|					THEN CASE
	|						WHEN CAST(DocumentData.CorLot AS Catalog.ProductionLots).ProductsGroup
	|							<> VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|							THEN CAST(DocumentData.CorLot AS Catalog.ProductionLots).ProductsGroup
	|						ELSE UNDEFINED END
	|				WHEN (ISNULL(DocumentData.CatBoxItemKeysWarehouseAreaShopFloorStockroom, FALSE)
	|						OR DocumentData.CatBoxItemKeysTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department)
	|						OR DocumentData.CatBoxItemKeysTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Partner))
	|					AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) = TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Estimated_FinancialAccountingDimension
	|				WHEN NOT (ISNULL(DocumentData.CatBoxItemKeysWarehouseAreaShopFloorStockroom, FALSE)
	|						OR DocumentData.CatBoxItemKeysTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department)
	|						OR DocumentData.CatBoxItemKeysTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Partner))
	|					AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) <> TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Estimated_FinancialAccountingDimension
	|				ELSE UNDEFINED
	|			END
	|		ELSE UNDEFINED
	|	END 																					AS CorControllingAttributes,
	|	CASE
	|		WHEN NOT &Constant_BatchAccountingVersion22
	|		  OR DocumentData.Period < BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|			THEN UNDEFINED
	|			ELSE DocumentData.VATActivityType
	|	END 																					AS VATActivityType,
	|	DocumentData.VATActivityType														AS CorVATActivityTypes,
	|
	|	CASE 
	|		WHEN NOT &Constant_BatchAccountingVersion22
	|		  OR DocumentData.Period < BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|			THEN UNDEFINED
	|	  	WHEN NOT DocumentData.FIFOAccountingPoliciesRollingValuation
	|		  AND VALUETYPE(DocumentData.CorLot) <> TYPE(Catalog.ProductionLots)
	|			THEN UNDEFINED
	|			ELSE DocumentData.CorLot
	|	END 																					AS CorLot,
	|	CASE WHEN DocumentData.ThereIsRequestField_LotVendorAttributesCorr
	|	  	AND (DocumentData.FIFOAccountingPoliciesRollingValuation
	|		  OR VALUETYPE(DocumentData.CorLot) = TYPE(Catalog.ProductionLots)
	|		  OR FALSE)
	|		THEN DocumentData.LotVendorAttributesCorr
	|		ELSE UNDEFINED
	|	END 																					AS LotVendorAttributesCorr,
	// The "Analysis of the Financial accounting document" field is filled in in the documents:
	// - Processor's report - indicates the product group for the distribution of output costs.
	|	CASE
	|		WHEN DocumentData.ThereIsRequestField_FinancialAccountingDimensionOfDocument
	|			THEN DocumentData.FinancialAccountingDimensionOfDocument
	|		WHEN &Constant_BatchAccountingVersion22
	|		 AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN CASE
	|
	// In the "Work in progress" Controlling attribute, the financial accounting should correspond to a group of products from
	// the production batch, or have an UNDEFINED value if the product group is not filled in.
	|				WHEN VALUETYPE(DocumentData.Lot) = TYPE(Catalog.ProductionLots)
	|				 AND DocumentData.Lot <> VALUE(Catalog.ProductionLots.EmptyRef)
	|					THEN CASE
	|						WHEN CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup
	|							<> VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|							THEN CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup
	|						ELSE UNDEFINED END
	|				WHEN (ISNULL(DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom, FALSE)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Partner))
	|					AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) = TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Estimated_FinancialAccountingDimension
	|				WHEN NOT (ISNULL(DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom, FALSE)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Partner))
	|					AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) <> TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Estimated_FinancialAccountingDimension
	|				ELSE UNDEFINED
	|			END
	|		ELSE UNDEFINED
	|	END 																					AS FinancialAccountingDimensionOfDocument,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN DocumentData.DocumentVATActivityType
	|		ELSE UNDEFINED
	|	END 																					AS DocumentVATActivityType,
	|
	|	CASE
	|		WHEN DocumentData.ThereIsRequestField_EntryType
	|			THEN DocumentData.EntryType
	|		WHEN VALUETYPE(DocumentData.Lot) = TYPE(Catalog.ProductionLots)
	|			THEN VALUE(Enum.LotRecordTypes.Supplement)
	|		ELSE
	|			CASE WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.ExpensingToProductionLots)
	|				THEN VALUE(Enum.LotRecordTypes.ExpensesToOtherProductionLots)
	|				ELSE VALUE(Enum.LotRecordTypes.Consumption)
	|			END
	|	END																					AS EntryType,
	|	VALUE(Enum.CostAccountingTransactions.ExpensesToOtherProductionLots)				AS CostAccountingTransaction,
	|	UNDEFINED 												  							AS DocumentSource,
	|	DocumentData.RowID 						  							AS RowID,
	|	DocumentData.FinRecordID 						  							AS FinRecordID,
	|	DocumentData.BusinessTransactionSetting 				  							AS BusinessTransactionSetting,
	// The "Document movements" field is filled in in the documents:
	// - Processor's report - the value is uncertain for the distribution of materials for release, because the cost is determined
	//		at the close of the month.
	|	CASE
	|		WHEN DocumentData.ThereIsRequestField_DocumentRegisterRecords 
	|			THEN DocumentData.DocumentRegisterRecords
	|		WHEN DocumentData.AccountingPoliciesOfOrganizationsAverageSlidingValuation
	|			THEN DocumentData.Ref
	|			ELSE UNDEFINED
	|	END																					AS DocumentRegisterRecords,
	|	DocumentData.AccountingPoliciesInventoryValuationMethod								AS InventoryValuationMethod,
	// The field "Method of determining the cost" is filled in the documents:
	// - The giver's report between organizations - the value of the "Document", because the cost of coming to the Unfinished production from the giver is determined
	//	by the amount in the document.
	// - The processor's report - the value of the "Document", because the cost of expenses from the Unfinished production is calculated at the close of the month
	|	CASE
	|		WHEN DocumentData.ThereIsRequestField_CostDefiningMethod
	|		 AND DocumentData.CostDefiningMethod <> VALUE(Enum.WaysToCalculateInventoryCost.EmptyRef)
	|			THEN DocumentData.CostDefiningMethod
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfProductsFromProductionFixedCost)
	|			THEN VALUE(Enum.WaysToCalculateInventoryCost.FromDocument)
	|		WHEN DocumentData.ThereIsRequestField_AccountingSection
	|		 AND DocumentData.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
	|			THEN VALUE(Enum.WaysToCalculateInventoryCost.FromDocument)
	|		ELSE DocumentData.AccountingPoliciesWayToDetermineCost
	|	END 															AS CostDefiningMethod
	|
	|INTO TTOperation_ExpensesToOtherProductionLots
	|FROM
	|	TTDocumentData_ AS DocumentData
	|WHERE
	|	DocumentData.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.ExpensesToOtherProductionLots)
	|
	|UNION ALL
	|
	// ARRIVAL - registration with the recipient
	|SELECT
	|	DocumentData.OperationNumber AS OperationNumber,
	// Document description
	|	VALUE(AccumulationRecordType.Receipt) 	AS RecordType,
	|	DocumentData.Period 					AS Period,
	|	(CASE
	|		WHEN DocumentData.ThereIsRequestField_VariancePeriod
	|			THEN DocumentData.VariancePeriod
	|		 ELSE DATETIME(1,1,1) END) AS VariancePeriod,
	|
	// Item accounting fields
	|	ISNULL(DocumentData.CorCompanyLink, DocumentData.Organization) 							AS Organization,
	|	ISNULL(DocumentData.TTCorItemAnalyticsOfInventoryLocationAttribute, UNDEFINED) AS ItemsLocationAttributes,
	|	ISNULL(DocumentData.TTCorAnalyticsItemInventoryLocationAttributeSource, UNDEFINED) AS AnalysisOfAccountingProductsInitial,
	|	CASE
	|		WHEN DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.Work_5)
	|				AND NOT DocumentData.CatItemOfTraceableItem
	|			THEN VALUE(Catalog.InventoryKinds.EmptyRef)
	|		ELSE DocumentData.CorInventoryOwnerAttribute
	|	END 																					AS InventoryOwnerAttribute,
	|	(CASE
	|		WHEN DocumentData.ThereIsRequestField_CorAccountingSection
	|			THEN DocumentData.CorAccountingSection
	|		WHEN DocumentData.Settlement_CorAccountingSection <> UNDEFINED
	|			THEN DocumentData.Settlement_CorAccountingSection
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress) END) AS AccountingSection,
	|
	// Corresponding fields
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) AS CorAccountingSection,
	|	UNDEFINED AS CorCompany,
	|	UNDEFINED AS CorItemsLocationAttributes,
	|	UNDEFINED AS CorAnalysisOfAccountingProductsInitial,
	|	UNDEFINED AS CorInventoryOwnerAttribute,
	|
	// Other fields
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.Department	AS Department,
	|	CASE
	|		WHEN FALSE
	|			THEN UNDEFINED
	|			ELSE UNDEFINED
	|	END							AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	DocumentData.Count									AS Count,
	|	CASE WHEN DocumentData.ThereIsRequestField_Cost
	|		THEN DocumentData.Cost
	|		ELSE 0
	|	END														AS Cost,
	|	CASE WHEN DocumentData.ThereIsRequestField_CostExcludingVAT
	|		THEN DocumentData.CostExcludingVAT
	|		ELSE 0
	|	END														AS CostExcludingVAT,
	|	CASE WHEN DocumentData.ThereIsRequestField_LocalCost
	|		THEN DocumentData.LocalCost
	|		ELSE 0
	|	END														AS LocalCost,
	|	CASE WHEN DocumentData.ThereIsRequestField_CostMan
	|		THEN DocumentData.CostMan
	|		ELSE 0
	|	END														AS CostMan,
	|	CASE WHEN DocumentData.ThereIsRequestField_VATLocal
	|		THEN DocumentData.VATLocal
	|		ELSE 0
	|	END														AS VATLocal,
	|	CASE WHEN DocumentData.ThereIsRequestField_VATManag
	|		THEN DocumentData.VATManag
	|		ELSE 0
	|	END														AS VATManag,
	|	CASE WHEN DocumentData.ThereIsRequestField_OffBalanceCost
	|		THEN DocumentData.OffBalanceCost
	|		ELSE 0
	|	END														AS OffBalanceCost,
	|	CASE WHEN DocumentData.ThereIsRequestField_OffBalanceCostLocal
	|		THEN DocumentData.OffBalanceCostLocal
	|		ELSE 0
	|	END														AS OffBalanceCostLocal,
	|
	// Batch accounting fields version 2.2
	|	CASE
	|		WHEN NOT &Constant_BatchAccountingVersion22
	|		  OR DocumentData.Period < BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|			THEN UNDEFINED
	|		ELSE DocumentData.CorLot
	|	END 															AS Lot,
	|	CASE WHEN DocumentData.ThereIsRequestField_LotVendorAttributes
	|			AND NOT VALUETYPE(DocumentData.CorLot) = TYPE(Catalog.ProductionLots)
	|				THEN DocumentData.LotVendorAttributes
	|		ELSE UNDEFINED
	|	END															AS LotVendorAttributes,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|		AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|			THEN CASE
	|				WHEN VALUETYPE(DocumentData.CorLot) = TYPE(Catalog.ProductionLots)
	|				 AND DocumentData.CorLot <> VALUE(Catalog.ProductionLots.EmptyRef)
	|					THEN CASE
	|						WHEN CAST(DocumentData.CorLot AS Catalog.ProductionLots).ProductsGroup
	|							<> VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|							THEN CAST(DocumentData.CorLot AS Catalog.ProductionLots).ProductsGroup
	|						ELSE UNDEFINED END
	|				WHEN (ISNULL(DocumentData.CatBoxItemKeysWarehouseAreaShopFloorStockroom, FALSE)
	|						OR DocumentData.CatBoxItemKeysTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department))
	|					AND VALUETYPE(DocumentData.Settlement_CorControllingAttributeOfFinancialAccounting) = TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Settlement_CorControllingAttributeOfFinancialAccounting
	|				WHEN NOT (ISNULL(DocumentData.CatBoxItemKeysWarehouseAreaShopFloorStockroom, FALSE)
	|						OR DocumentData.CatBoxItemKeysTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department))
	|					AND VALUETYPE(DocumentData.Settlement_CorControllingAttributeOfFinancialAccounting) <> TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Settlement_CorControllingAttributeOfFinancialAccounting
	|				ELSE UNDEFINED
	|			END
	|			ELSE UNDEFINED
	|	END 															AS FinancialAccountingDimension,
	|	UNDEFINED 													AS CorControllingAttributes,
	|	CASE
	|		WHEN NOT &Constant_BatchAccountingVersion22
	|		  OR DocumentData.Period < BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|			THEN UNDEFINED
	|		ELSE DocumentData.VATActivityType
	|	END 															AS VATActivityType,
	|	UNDEFINED													AS CorVATActivityTypes,
	|
	|	UNDEFINED													AS CorLot,
	|	UNDEFINED													AS LotVendorAttributesCorr,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|		AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN CASE
	|				WHEN VALUETYPE(DocumentData.CorLot) = TYPE(Catalog.ProductionLots)
	|				 AND DocumentData.CorLot <> VALUE(Catalog.ProductionLots.EmptyRef)
	|					THEN CASE
	|						WHEN CAST(DocumentData.CorLot AS Catalog.ProductionLots).ProductsGroup
	|							<> VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|							THEN CAST(DocumentData.CorLot AS Catalog.ProductionLots).ProductsGroup
	|						ELSE UNDEFINED END
	|				WHEN (ISNULL(DocumentData.CatBoxItemKeysWarehouseAreaShopFloorStockroom, FALSE)
	|						OR DocumentData.CatBoxItemKeysTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department))
	|					AND VALUETYPE(DocumentData.Settlement_CorControllingAttributeOfFinancialAccounting) = TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Settlement_CorControllingAttributeOfFinancialAccounting
	|				WHEN NOT (ISNULL(DocumentData.CatBoxItemKeysWarehouseAreaShopFloorStockroom, FALSE)
	|						OR DocumentData.CatBoxItemKeysTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department))
	|					AND VALUETYPE(DocumentData.Settlement_CorControllingAttributeOfFinancialAccounting) <> TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Settlement_CorControllingAttributeOfFinancialAccounting
	|				ELSE UNDEFINED
	|			END
	|		ELSE UNDEFINED
	|	END 															AS FinancialAccountingDimensionOfDocument,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN DocumentData.DocumentVATActivityType
	|		ELSE UNDEFINED
	|	END 															AS DocumentVATActivityType,
	|
	|	VALUE(Enum.LotRecordTypes.Supplement)				AS EntryType,
	|	VALUE(Enum.CostAccountingTransactions.ExpensesToOtherProductionLots) 	AS CostAccountingTransaction,
	|	UNDEFINED 												  	AS DocumentSource,
	|	DocumentData.RowID 						  	AS RowID,
	|	DocumentData.FinRecordID 						  	AS FinRecordID,
	|	DocumentData.BusinessTransactionSetting					AS BusinessTransactionSetting,
	|	CASE WHEN DocumentData.AccountingPoliciesOfOrganizationsAverageSlidingValuation
	|		THEN DocumentData.Ref
	|		ELSE UNDEFINED
	|	END 															AS DocumentRegisterRecords,
	|	DocumentData.AccountingPoliciesInventoryValuationMethod		AS InventoryValuationMethod,
	// The field "Method of determining the cost" is filled in the documents:
	// - The giver's report between organizations - the value of the "Document", because the cost of coming to the Unfinished production from the giver is determined
	//	by the amount in the document.
	|	CASE
	|		WHEN DocumentData.ThereIsRequestField_CostDefiningMethod
	|		 AND DocumentData.CostDefiningMethod <> VALUE(Enum.WaysToCalculateInventoryCost.EmptyRef)
	|			THEN DocumentData.CostDefiningMethod
	|		WHEN DocumentData.AccountingPoliciesOfOrganizationsAverageSlidingValuation
	|			THEN VALUE(Enum.WaysToCalculateInventoryCost.ByCorRecord)
	|		ELSE DocumentData.AccountingPoliciesWayToDetermineCost
	|	END 															AS CostDefiningMethod
	|FROM
	|	TTDocumentData_ AS DocumentData
	|WHERE
	|	DocumentData.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.ExpensesToOtherProductionLots)
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.ExpensingToProductionLots)
	|
	|UNION ALL
	|
	// EXPENSE - write-off of commission goods
	|SELECT
	|	DocumentData.OperationNumber AS OperationNumber,
	// Document description
	|	VALUE(AccumulationRecordType.Expense) 	AS RecordType,
	|	DocumentData.Period 					AS Period,
	|	(CASE
	|		WHEN DocumentData.ThereIsRequestField_VariancePeriod
	|			THEN DocumentData.VariancePeriod
	|		 ELSE DATETIME(1,1,1) END) AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentData.Organization 														AS Organization,
	|	ISNULL(DocumentData.AnalyticsOfItemInventoryLocationAttributeTT, UNDEFINED) AS ItemsLocationAttributes,
	|	ISNULL(DocumentData.InitialInventoryLocationAttributeTTAnalyticsForItemTypesIsOriginalOne, UNDEFINED) AS AnalysisOfAccountingProductsInitial,
	|	CASE
	|		WHEN DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.Work_5)
	|				AND NOT DocumentData.CatItemOfTraceableItem
	|			THEN VALUE(Catalog.InventoryKinds.EmptyRef)
	|		ELSE DocumentData.InventoryOwnerAttribute
	|	END																				AS InventoryOwnerAttribute,
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent) 	AS AccountingSection,
	|
	// Corresponding fields
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) AS CorAccountingSection,
	|	UNDEFINED AS CorCompany,
	|	UNDEFINED AS CorItemsLocationAttributes,
	|	UNDEFINED AS CorAnalysisOfAccountingProductsInitial,
	|	UNDEFINED AS CorInventoryOwnerAttribute,
	|
	// Other fields
	|	CASE WHEN VALUETYPE(DocumentData.Ref) = TYPE(Document.AssemblyFromComponents)
	|		THEN DocumentData.BusinessOperation
	|		ELSE VALUE(Enum.BusinessTransactions.ConsignedGoodsWriteOff)
	|	END								  AS BusinessOperation,
	|	DocumentData.Department		  AS Department,
	|	CASE
	|		WHEN FALSE
	|			THEN UNDEFINED
	|			ELSE UNDEFINED
	|	END								  AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	DocumentData.Count AS Count,
	|	0 AS Cost,
	|	0 AS CostExcludingVAT,
	|	0 AS LocalCost,
	|	0 AS CostMan,
	|	0 AS VATLocal,
	|	0 AS VATManag,
	|	0 AS OffBalanceCost,
	|	0 AS OffBalanceCostLocal,
	|
	// Batch accounting fields version 2.2
	|	UNDEFINED 																	AS Lot,
	|	CASE WHEN DocumentData.ThereIsRequestField_LotVendorAttributes
	|		THEN DocumentData.LotVendorAttributes
	|		ELSE UNDEFINED
	|	END																			AS LotVendorAttributes,
	|	UNDEFINED 																	AS FinancialAccountingDimension,
	|	UNDEFINED 																	AS CorControllingAttributes,
	|	UNDEFINED 																	AS VATActivityType,
	|	CASE
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
	|		   VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit))
	|			THEN DocumentData.VATActivityType
	|			ELSE UNDEFINED
	|	END 																			AS CorVATActivityTypes,
	|
	|	CASE
	|		WHEN NOT &Constant_BatchAccountingVersion22
	|		  OR DocumentData.Period < BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|			THEN UNDEFINED
	|		WHEN DocumentData.FIFOAccountingPoliciesRollingValuation
	|			THEN DocumentData.CorLot
	|			ELSE UNDEFINED
	|	END 																			AS CorLot,
	|	UNDEFINED																	AS LotVendorAttributesCorr,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|		AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN CASE
	|				WHEN VALUETYPE(DocumentData.Lot) = TYPE(Catalog.ProductionLots)
	|				 AND DocumentData.Lot <> VALUE(Catalog.ProductionLots.EmptyRef)
	|					THEN CASE
	|						WHEN CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup
	|							<> VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|							THEN CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup
	|						ELSE UNDEFINED END
	|				WHEN (ISNULL(DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom, FALSE)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department))
	|					AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) = TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Estimated_FinancialAccountingDimension
	|				WHEN NOT (ISNULL(DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom, FALSE)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department))
	|					AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) <> TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Estimated_FinancialAccountingDimension
	|				ELSE UNDEFINED
	|			END
	|		ELSE UNDEFINED
	|	END 																			AS FinancialAccountingDimensionOfDocument,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN DocumentData.DocumentVATActivityType
	|		ELSE UNDEFINED
	|	END 																			AS DocumentVATActivityType,
	|
	|	CASE WHEN VALUETYPE(DocumentData.Ref) = TYPE(Document.AssemblyFromComponents)
	|		THEN VALUE(Enum.LotRecordTypes.ExpensesToOtherProductionLots)
	|		ELSE VALUE(Enum.LotRecordTypes.Consumption)
	|	END 		  																	AS EntryType,
	|	VALUE(Enum.CostAccountingTransactions.ExpensesToOtherProductionLots)		AS CostAccountingTransaction,
	|	UNDEFINED 												  					AS DocumentSource,
	|	UNDEFINED 						  											AS RowID,
	|	DocumentData.FinRecordID 						  					AS FinRecordID,
	|	CASE WHEN VALUETYPE(DocumentData.Ref) = TYPE(Document.AssemblyFromComponents)
	|		THEN DocumentData.BusinessTransactionSetting
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ConsignedGoodsWriteOff)
	|	END 		  																	AS BusinessTransactionSetting,
	|	UNDEFINED																	AS DocumentRegisterRecords,
	|	DocumentData.AccountingPoliciesInventoryValuationMethod						AS InventoryValuationMethod,
	|	DocumentData.AccountingPoliciesWayToDetermineCost					AS CostDefiningMethod
	|FROM
	|	TTDocumentData_ AS DocumentData
	|WHERE
	|	DocumentData.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.ExpensesToOtherProductionLots)
	|	AND DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|	AND ISNULL(DocumentData.CorInventoryOwnerAttributeTypeOfInventory, UNDEFINED) <> VALUE(Enum.InventoryTypes.ConsignedGoods)
	|";
	
	ReflectionParameters.TTTemplateTexts.Insert("TTOperation_ExpensesToOtherProductionLots", ReflectionRequestText);
	
EndProcedure

Procedure ReflectCostTransactionWriteOffToExpensesAssets(ReflectionParameters)
	
	// Let's form a template of the request text to reflect the operation.
	ReflectionRequestText =
	"
	// EXPENSE - write-off for expenses
	|SELECT
	|	DocumentData.OperationNumber AS OperationNumber,
	// Document description
	|	CASE
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.InventoryConsumptionReverseTransaction))
	|			THEN CASE
	|				WHEN BEGINOFPERIOD(DocumentData.SourceDocumentPeriod, MONTH) < BEGINOFPERIOD(DocumentData.Period, MONTH)
	|					THEN VALUE(AccumulationRecordType.Receipt)
	|					ELSE VALUE(AccumulationRecordType.Expense)
	|				END
	|		ELSE VALUE(AccumulationRecordType.Expense)
	|	END									AS RecordType,
	|	DocumentData.Period 					AS Period,
	|	(CASE
	|		WHEN DocumentData.ThereIsRequestField_VariancePeriod
	|			THEN DocumentData.VariancePeriod
	|		 ELSE DATETIME(1,1,1) END) AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentData.Organization 															AS Organization,
	|	CASE WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		THEN ISNULL(DocumentData.CommitteeSInventoryLocationAttributeAnalyticsTTItemTypeOfCommitteeSInventoryTypeOfCommitteeTypeOfCommitteeTypeOfCommitteeTypeOfCommitteeTypeOfCommitteeTypeOfCommitteeTypeOfCommittee, UNDEFINED)
	|		ELSE ISNULL(DocumentData.AnalyticsOfItemInventoryLocationAttributeTT, UNDEFINED)
	|	END 																					AS ItemsLocationAttributes,
	|	ISNULL(DocumentData.InitialInventoryLocationAttributeTTAnalyticsForItemTypesIsOriginalOne, UNDEFINED) AS AnalysisOfAccountingProductsInitial,
	|	CASE
	|		WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Catalog.InventoryKinds.EmptyRef)
	|		WHEN DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.Work_5)
	|		 AND NOT DocumentData.CatItemOfTraceableItem
	|			THEN VALUE(Catalog.InventoryKinds.EmptyRef)
	|		ELSE DocumentData.InventoryOwnerAttribute
	|	END 																					AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN DocumentData.ThereIsRequestField_AccountingSection AND DocumentData.AccountingSection <> UNDEFINED
	|		 AND DocumentData.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
	|			THEN DocumentData.AccountingSection
	|		WHEN DocumentData.Settlement_AccountingSection <> UNDEFINED AND NOT
	//	We redefine the Accounting section only when we do not redefine the analytics of accounting and the type of inventory. For a commission product
	//	, it is redefined, and therefore the Accounting section defined by general principles is no longer suitable.
	|			DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN DocumentData.Settlement_AccountingSection
	|		WHEN DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.Work_5)
	|		  OR DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.OperationService)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|		 AND DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.WriteOffOfAcceptedGoodsAtExpenseOfDepositor),
	|		   VALUE(Enum.BusinessTransactions.ConsumptionOfGoodsReceivedAsExpenses))
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInStorageWithRightOfSaleToRegisterWriteOff)
	|		WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsAtStorageWithRightOfSale)
	|		WHEN DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
	|		 AND (DocumentData.CatItemKeysContractTypeOfContract = VALUE(Enum.ContractTypes.TransferToTolling2_5)
	|			OR DocumentData.CatItemKeysContractTypeOfContract = VALUE(Enum.ContractTypes.SubcontractingToTheEAEUCountries))
	|		 AND DocumentData.CatProductsTypeOfProducts <> VALUE(Enum.ItemsTypes.Work_5)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToToller)
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.WriteOffReportFromCommissionAgent),
	|			VALUE(Enum.BusinessTransactions.WriteOffShortagesAtConsignorSExpense))
	|			THEN 
	|				CASE
	|					WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.OwnGoods)
	|						THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent)
	|						ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|				END
	|
	|		WHEN DocumentData.CatItemKeysContractTypeOfContract = VALUE(Enum.ContractTypes.TransferToCustody)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsTransferredToPartners)
	|
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.WriteOffShortagesAtDepositorSExpense))
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsTransferredToPartners)
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.WriteOffGoodsOfCommissionAgent))
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent)
	|		WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|		WHEN DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom
	|		  OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|			ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|	END 																					AS AccountingSection,
	|	CASE
	|		WHEN DocumentData.ThereIsRequestField_CorAccountingSection
	|			THEN DocumentData.CorAccountingSection
	//		When debiting expenses, the Accounting section is changed - the arrival in ...Co-formationdescription
	//		The peculiarity of the document REPORTDAVALTSU2_5:
	//		for it, only the type of inventory is changed from a semi-finished product to a product (the cor. section is defined below as for all toll-free goods)
	|		WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory IN (VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider),
	|														VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
	|														VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
	|			AND NOT DocumentData.BusinessOperation IN(
	|					VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
	|					VALUE(Enum.BusinessTransactions.Subcontracting2_5),
	|					VALUE(Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5),
	|					VALUE(Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5),
	|					VALUE(Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5),
	|					VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredWriteOffAsExpenses),
	|					VALUE(Enum.BusinessTransactions.ProviderGoodsWriteOffAtTheExpenseOfProvider),
	|					VALUE(Enum.BusinessTransactions.ProviderGoodsWriteOffAsExpenses))
	|			THEN CASE WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider)
	|				THEN VALUE(Enum.SectionsOfInventoryCostAccounting.MaterialsReceivedForSubcontractingToRegisterWriteOff)
	|				ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.VendorManagedInventoryToRegisterWriteOff)
	|				END
	|		WHEN DocumentData.Settlement_CorAccountingSection <> UNDEFINED
	|			THEN DocumentData.Settlement_CorAccountingSection
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
	|	END 																					AS CorAccountingSection,
	|
	// Corresponding fields
	|	CASE
	|		WHEN DocumentData.CorCompany = DocumentData.Organization
	|			THEN UNDEFINED
	|			ELSE DocumentData.CorCompany
	|	END 																					AS CorCompany,
	// The conditions for the coralitika of the nomenclature should be synchronized with the condition for the formation of incoming movements for toll goods in this operation
	|	CASE WHEN NOT DocumentData.BusinessOperation IN(
	|					VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
	|					VALUE(Enum.BusinessTransactions.Subcontracting2_5),
	|					VALUE(Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5),
	|					VALUE(Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5),
	|					VALUE(Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5),
	|					VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredWriteOffAsExpenses),
	|					VALUE(Enum.BusinessTransactions.ProviderGoodsWriteOffAtTheExpenseOfProvider),
	|					VALUE(Enum.BusinessTransactions.ProviderGoodsWriteOffAsExpenses))
	|	  AND DocumentData.InventoryOwnerAttributeIsTypeOfInventory IN
	|		(VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider),
	|		 VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
	|		 VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
	|			THEN ISNULL(DocumentData.AnalyticsOfItemInventoryLocationAttributeTT, UNDEFINED)
	|			ELSE ISNULL(DocumentData.TTCorItemAnalyticsOfInventoryLocationAttribute, UNDEFINED)
	|	END 																					AS CorItemsLocationAttributes,
	|	ISNULL(DocumentData.TTCorAnalyticsItemInventoryLocationAttributeSource, UNDEFINED) AS CorAnalysisOfAccountingProductsInitial,
	// The conditions for CorVidZapazov should be synchronized with the condition for the formation of incoming movements for giveaway goods in this operation
	|	CASE WHEN DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.Work_5)
	|	 AND NOT DocumentData.CatItemOfTraceableItem
	|		THEN VALUE(Catalog.InventoryKinds.EmptyRef)
	|	WHEN NOT DocumentData.BusinessOperation IN(
	|				VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
	|				VALUE(Enum.BusinessTransactions.Subcontracting2_5),
	|				VALUE(Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5),
	|				VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredWriteOffAsExpenses),
	|				VALUE(Enum.BusinessTransactions.ProviderGoodsWriteOffAtTheExpenseOfProvider),
	|				VALUE(Enum.BusinessTransactions.ProviderGoodsWriteOffAsExpenses))
	|	  AND DocumentData.InventoryOwnerAttributeIsTypeOfInventory IN
	|		(VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider),
	|		 VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
	|		 VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
	|			THEN DocumentData.InventoryOwnerAttribute
	|			ELSE DocumentData.CorInventoryOwnerAttribute
	|	END 																					AS CorInventoryOwnerAttribute,
	|	DocumentData.CorLineOfBusiness			    								AS CorLineOfBusiness,
	|	CASE WHEN DocumentData.ThereIsRequestField_CorLot
	|		THEN DocumentData.CorLot
	|		ELSE UNDEFINED
	|	END 																					AS CorLot,
	|	CASE WHEN DocumentData.ThereIsRequestField_LotVendorAttributesCorr
	|		THEN DocumentData.LotVendorAttributesCorr
	|		ELSE UNDEFINED
	|	END 																					AS LotVendorAttributesCorr,
	|
	// Other fields
	|	DocumentData.BusinessOperation 													AS BusinessOperation,
	|	DocumentData.Department 															AS Department,
	|	CASE
	|		WHEN VALUETYPE(DocumentData.ExpenseItemAssets) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|			THEN DocumentData.ExpenseItemAssets
	|			ELSE UNDEFINED
	|	END 																					AS ExpenseItemOfWriteOff,
	|	CASE
	|		WHEN VALUETYPE(DocumentData.ExpenseItemAssets) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|			THEN DocumentData.AssetExpenseAnalytics
	|			ELSE UNDEFINED
	|	END 																					AS DimensionOfExpenses,
	|	CASE
	|		WHEN VALUETYPE(DocumentData.ExpenseItemAssets) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|			THEN DocumentData.ExpenseItemAssets
	|			ELSE UNDEFINED
	|	END 																					AS AssetAndLiabilityItem,
	|	CASE
	|		WHEN VALUETYPE(DocumentData.ExpenseItemAssets) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|			THEN DocumentData.AssetExpenseAnalytics
	|			ELSE UNDEFINED
	|	END 																					AS AssetsLiabilitiesDimension,
	|	DocumentData.SourceDocumentPeriod												AS SalePeriod,
	|	CASE
	|		WHEN FALSE
	|			THEN UNDEFINED
	|	END                                            										AS ProductsGroup,
	|	CASE WHEN DocumentData.ThereIsRequestField_AccountingDimensionByPartners
	|		THEN DocumentData.AccountingDimensionByPartners
	|		ELSE UNDEFINED
	|	END 																					AS AccountingDimensionByPartners,
	|	CASE
	|		WHEN DocumentData.ThereIsRequestField_GLAccountSettings
	|			THEN DocumentData.GLAccountSettings
	|			ELSE UNDEFINED
	|	END 																					AS GLAccountSettings,
	|	CASE WHEN DocumentData.ThereIsRequestField_SalesOrder
	|		THEN DocumentData.SalesOrder
	|		ELSE UNDEFINED
	|	END																					AS SalesOrder,
	|
	// Quantitative and summary indicators
	|	CASE
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.InventoryConsumptionReverseTransaction))
	|			THEN CASE
	|				WHEN BEGINOFPERIOD(DocumentData.SourceDocumentPeriod, MONTH) < BEGINOFPERIOD(DocumentData.Period, MONTH)
	|					THEN DocumentData.Count
	|					ELSE -DocumentData.Count
	|				END
	|		ELSE DocumentData.Count
	|	END																		AS Count,
	|	CASE WHEN DocumentData.ThereIsRequestField_Cost
	|		THEN DocumentData.Cost
	|		ELSE 0
	|	END 																		AS Cost,
	|	CASE WHEN DocumentData.ThereIsRequestField_CostExcludingVAT
	|		THEN DocumentData.CostExcludingVAT
	|		ELSE 0
	|	END 																		AS CostExcludingVAT,
	|	CASE WHEN DocumentData.ThereIsRequestField_LocalCost
	|		THEN DocumentData.LocalCost
	|		ELSE 0
	|	END 																		AS LocalCost,
	|	CASE WHEN DocumentData.ThereIsRequestField_CostMan
	|		THEN DocumentData.CostMan
	|		ELSE 0
	|	END 																		AS CostMan,
	|
	// Batch accounting fields version 2.2
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|		AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|	THEN
	|		(CASE 
	|				WHEN VALUETYPE(DocumentData.Lot) = TYPE(Catalog.ProductionLots)
	|					AND DocumentData.Lot <> VALUE(Catalog.ProductionLots.EmptyRef)
	|					AND CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup <> VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|				THEN CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup
	|				WHEN (ISNULL(DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom, FALSE)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department))
	|					AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) = TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Estimated_FinancialAccountingDimension
	|				WHEN NOT (ISNULL(DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom, FALSE)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department))
	|					AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) <> TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Estimated_FinancialAccountingDimension
	|				ELSE UNDEFINED
	|			END
	|		)
	|		ELSE UNDEFINED
	|	END 																		AS FinancialAccountingDimension,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|		AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN CASE 
	|				WHEN VALUETYPE(DocumentData.Lot) = TYPE(Catalog.ProductionLots)
	|					AND DocumentData.Lot <> VALUE(Catalog.ProductionLots.EmptyRef)
	|					AND CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup <> VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|				THEN CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup
	|				WHEN (ISNULL(DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom, FALSE)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department))
	|					AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) = TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Estimated_FinancialAccountingDimension
	|				WHEN NOT (ISNULL(DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom, FALSE)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department))
	|					AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) <> TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Estimated_FinancialAccountingDimension
	|				ELSE UNDEFINED
	|			END
	|		ELSE UNDEFINED
	|	END 																		AS FinancialAccountingDimensionOfDocument,
	|	CASE
	|		WHEN NOT &Constant_BatchAccountingVersion22
	|		  OR DocumentData.Period < BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|			THEN UNDEFINED
	|			ELSE DocumentData.VATActivityType
	|	END 																		AS VATActivityType,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN DocumentData.DocumentVATActivityType
	|		ELSE UNDEFINED
	|	END 																		AS DocumentVATActivityType,
	|	CASE
	|		WHEN VALUETYPE(DocumentData.Ref) IN (
	|				TYPE(Document.InventoryConsumption),
	|				TYPE(Document.WriteOffOfGoodsShortages),
	|				TYPE(Document.CustomerInvoiceIntercompany),
	|				TYPE(Document.WriteOffReportFromCommissionAgent),
	|				TYPE(Document.ConsumptionReportSubcontractingServicesDeliveredIntercompany),
	|				TYPE(Document.CommissionWriteOffReportIntercompany))
	|			THEN DocumentData.VATActivityType
	|			ELSE UNDEFINED
	|	END																		AS CorVATActivityTypes,
	|	CASE
	|	  WHEN FALSE
	|		THEN UNDEFINED
	|		ELSE UNDEFINED
	|	END 																		AS CorControllingAttributes,
	|	CASE WHEN DocumentData.ThereIsRequestField_Lot
	|		AND &Constant_BatchAccountingVersion22
	|		AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		AND (DocumentData.FIFOAccountingPoliciesRollingValuation
	|			OR VALUETYPE(DocumentData.Lot) = TYPE(Catalog.ProductionLots)
	|			)
	|		THEN DocumentData.Lot
	|		ELSE UNDEFINED
	|	END																		AS Lot,
	|	CASE WHEN DocumentData.ThereIsRequestField_LotVendorAttributes
	|			AND (DocumentData.FIFOAccountingPoliciesRollingValuation
	|			OR VALUETYPE(DocumentData.Lot) = TYPE(Catalog.ProductionLots)
	|			)
	|		THEN DocumentData.LotVendorAttributes
	|		ELSE UNDEFINED
	|	END																		AS LotVendorAttributes,
	|
	|	CASE
	// The type of record is determined in the procedure of operation descriptionaccounting for the following documents:
	//	- Processor Report
	//	- Processing REPORT2_5
	//	- Adjustment of the implementation
	|		WHEN DocumentData.ThereIsRequestField_EntryType
	|			THEN DocumentData.EntryType
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.InventoryConsumptionReverseTransaction))
	|			THEN CASE
	|				WHEN BEGINOFPERIOD(DocumentData.SourceDocumentPeriod, MONTH) < BEGINOFPERIOD(DocumentData.Period, MONTH)
	|					THEN VALUE(Enum.LotRecordTypes.PreviousPeriodReturn)
	|					ELSE VALUE(Enum.LotRecordTypes.ReversingEntry)
	|				END
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.WriteOffForExpensesFixedCost))
	|			THEN VALUE(Enum.LotRecordTypes.Supplement)
	|		ELSE VALUE(Enum.LotRecordTypes.Consumption)
	|	END																		AS EntryType,
	|	VALUE(Enum.CostAccountingTransactions.RecogniseAsExpensesAssets) 	AS CostAccountingTransaction,
	|	DocumentData.DocumentSource							  				AS DocumentSource,
	|	DocumentData.RowID 						  				AS RowID,
	|	DocumentData.FinRecordID 						  				AS FinRecordID,
	|	DocumentData.BusinessTransactionSetting 				  				AS BusinessTransactionSetting,
	|	CASE WHEN DocumentData.ThereIsRequestField_DocumentRegisterRecords 
	|		THEN DocumentData.DocumentRegisterRecords
	|		ELSE UNDEFINED
	|	END																		AS DocumentRegisterRecords,
	|	DocumentData.AccountingPoliciesInventoryValuationMethod					AS InventoryValuationMethod,
	|	CASE
	|		WHEN DocumentData.ThereIsRequestField_AccountingSection
	|		 AND DocumentData.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease)
	|			THEN VALUE(Enum.WaysToCalculateInventoryCost.FromDocument) 
	|		WHEN DocumentData.AccountingPoliciesOfOrganizationsAverageSlidingValuation
	|			THEN CASE
	|				WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffForExpensesFixedCost)
	|					THEN VALUE(Enum.WaysToCalculateInventoryCost.FromDocument)
	|				WHEN DocumentData.DocumentSource <> UNDEFINED
	|					THEN VALUE(Enum.WaysToCalculateInventoryCost.BySourceDocumentRegisterRecords)
	|				ELSE DocumentData.AccountingPoliciesWayToDetermineCost
	|			END
	|		ELSE DocumentData.AccountingPoliciesWayToDetermineCost
	|	END 															AS CostDefiningMethod
	|INTO TTOperation_RecogniseAsExpensesAssets
	|FROM
	|	TTDocumentData_ AS DocumentData
	|WHERE
	|	DocumentData.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.RecogniseAsExpensesAssets)
	// For the transfer of goods between organizations with a write-off for expenses, this movement does not need to be done, because unlike processing, there will be no additional incoming movement 
	|	AND NOT (ISNULL(DocumentData.InventoryOwnerAttributeIsTypeOfInventory, UNDEFINED) = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany))
	|
	|UNION ALL
	|
	// EXPENSE - write-off of commission goods
	|SELECT
	|	DocumentData.OperationNumber AS OperationNumber,
	// Document description
	|	CASE
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.InventoryConsumptionReverseTransaction))
	|			THEN CASE
	|				WHEN BEGINOFPERIOD(DocumentData.SourceDocumentPeriod, MONTH) < BEGINOFPERIOD(DocumentData.Period, MONTH)
	|					THEN VALUE(AccumulationRecordType.Receipt)
	|					ELSE VALUE(AccumulationRecordType.Expense)
	|				END
	|		ELSE VALUE(AccumulationRecordType.Expense)
	|	END									AS RecordType,
	|	DocumentData.Period 					AS Period,
	|	(CASE
	|		WHEN DocumentData.ThereIsRequestField_VariancePeriod
	|			THEN DocumentData.VariancePeriod
	|		 ELSE DATETIME(1,1,1) END) AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentData.Organization 														AS Organization,
	|	ISNULL(DocumentData.AnalyticsOfItemInventoryLocationAttributeTT, UNDEFINED) AS ItemsLocationAttributes,
	|	ISNULL(DocumentData.InitialInventoryLocationAttributeTTAnalyticsForItemTypesIsOriginalOne, UNDEFINED) AS AnalysisOfAccountingProductsInitial,
	|	CASE
	|		WHEN DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.Work_5)
	|				AND NOT DocumentData.CatItemOfTraceableItem
	|			THEN VALUE(Catalog.InventoryKinds.EmptyRef)
	|		ELSE DocumentData.InventoryOwnerAttribute
	|	END																				AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN DocumentData.ThereIsRequestField_AccountingSection AND DocumentData.AccountingSection <> UNDEFINED
	|		 AND DocumentData.AccountingSection <> VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
	|		THEN DocumentData.AccountingSection
	|		WHEN DocumentData.Settlement_AccountingSection <> UNDEFINED
	|		THEN DocumentData.Settlement_AccountingSection
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|	END AS AccountingSection,
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)				AS CorAccountingSection,
	|
	// Corresponding fields
	|	UNDEFINED 																		AS CorCompany,
	|	UNDEFINED 																		AS CorItemsLocationAttributes,
	|	UNDEFINED 																		AS CorAnalysisOfAccountingProductsInitial,
	|	CASE
	|		WHEN DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.Work_5)
	|				AND NOT DocumentData.CatItemOfTraceableItem
	|			THEN VALUE(Catalog.InventoryKinds.EmptyRef)
	|		ELSE DocumentData.CorInventoryOwnerAttribute
	|	END																				AS CorInventoryOwnerAttribute,
	|	UNDEFINED			    														AS CorLineOfBusiness,
	|	UNDEFINED 																		AS CorLot,
	|	UNDEFINED 																		AS LotVendorAttributesCorr,
	|
	// Other fields
	|	DocumentData.BusinessOperation 												AS BusinessOperation,
	|	DocumentData.Department 														AS Department,
	|	CASE
	|		WHEN VALUETYPE(DocumentData.ExpenseItemAssets) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|			THEN DocumentData.ExpenseItemAssets
	|			ELSE UNDEFINED
	|	END 																				AS ExpenseItemOfWriteOff,
	|	CASE
	|		WHEN VALUETYPE(DocumentData.ExpenseItemAssets) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|			THEN DocumentData.AssetExpenseAnalytics
	|			ELSE UNDEFINED
	|	END 																				AS DimensionOfExpenses,
	|	CASE
	|		WHEN VALUETYPE(DocumentData.ExpenseItemAssets) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|			THEN DocumentData.ExpenseItemAssets
	|			ELSE UNDEFINED
	|	END 																				AS AssetAndLiabilityItem,
	|	CASE
	|		WHEN VALUETYPE(DocumentData.ExpenseItemAssets) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|			THEN DocumentData.AssetExpenseAnalytics
	|			ELSE UNDEFINED
	|	END 																				AS AssetsLiabilitiesDimension,
	|	DocumentData.SourceDocumentPeriod											AS SalePeriod,
	|	UNDEFINED																		AS ProductsGroup,
	|	CASE WHEN DocumentData.ThereIsRequestField_AccountingDimensionByPartners
	|		THEN DocumentData.AccountingDimensionByPartners
	|		ELSE UNDEFINED
	|	END 																				AS AccountingDimensionByPartners,
	|	CASE
	|		WHEN DocumentData.ThereIsRequestField_GLAccountSettings
	|			THEN DocumentData.GLAccountSettings
	|			ELSE UNDEFINED
	|	END 																				AS GLAccountSettings,
	|	CASE WHEN DocumentData.ThereIsRequestField_SalesOrder
	|		THEN DocumentData.SalesOrder
	|		ELSE UNDEFINED
	|	END																				AS SalesOrder,
	|
	// Quantitative and summary indicators
	|	CASE
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.InventoryConsumptionReverseTransaction))
	|			THEN CASE
	|				WHEN BEGINOFPERIOD(DocumentData.SourceDocumentPeriod, MONTH) < BEGINOFPERIOD(DocumentData.Period, MONTH)
	|					THEN DocumentData.Count
	|					ELSE -DocumentData.Count
	|				END
	|		ELSE DocumentData.Count
	|	END																				AS Count,
	|	0 																					AS Cost,
	|	0 																					AS CostExcludingVAT,
	|	0 																					AS LocalCost,
	|	0 																					AS CostMan,
	|
	// Batch accounting fields version 2.2
	|	UNDEFINED 																		AS FinancialAccountingDimension,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|		AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN CASE 
	|				WHEN VALUETYPE(DocumentData.Lot) = TYPE(Catalog.ProductionLots)
	|					AND DocumentData.Lot <> VALUE(Catalog.ProductionLots.EmptyRef)
	|					AND CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup <> VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|				THEN CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup
	|				WHEN (ISNULL(DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom, FALSE)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department))
	|					AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) = TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Estimated_FinancialAccountingDimension
	|				WHEN NOT (ISNULL(DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom, FALSE)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department))
	|					AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) <> TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Estimated_FinancialAccountingDimension
	|				ELSE UNDEFINED
	|			END
	|		ELSE UNDEFINED
	|	END 																				AS FinancialAccountingDimensionOfDocument,
	|	UNDEFINED																		AS VATActivityType,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN DocumentData.DocumentVATActivityType
	|		ELSE UNDEFINED
	|	END 																				AS DocumentVATActivityType,
	|	CASE
	|		WHEN VALUETYPE(DocumentData.Ref) IN (
	|		  TYPE(Document.InventoryConsumption),
	|	   	  TYPE(Document.WriteOffOfGoodsShortages))
	|			THEN DocumentData.VATActivityType
	|			ELSE UNDEFINED
	|	END 																				AS CorVATActivityTypes,
	|	UNDEFINED 																		AS CorControllingAttributes,
	|	UNDEFINED																		AS Lot,
	|	UNDEFINED																		AS LotVendorAttributes,
	|
	|	CASE
	|		WHEN DocumentData.BusinessOperation IN
	|		  (VALUE(Enum.BusinessTransactions.InventoryConsumptionReverseTransaction))
	|			THEN CASE
	|				WHEN BEGINOFPERIOD(DocumentData.SourceDocumentPeriod, MONTH) < BEGINOFPERIOD(DocumentData.Period, MONTH)
	|					THEN VALUE(Enum.LotRecordTypes.PreviousPeriodReturn)
	|					ELSE VALUE(Enum.LotRecordTypes.ReversingEntry)
	|				END
	|		ELSE VALUE(Enum.LotRecordTypes.Consumption)
	|	END																				AS EntryType,
	|	VALUE(Enum.CostAccountingTransactions.RecogniseAsExpensesAssets) 			AS CostAccountingTransaction,
	|	DocumentData.DocumentSource							  						AS DocumentSource,
	|	DocumentData.RowID 						  						AS RowID,
	|	DocumentData.FinRecordID 						  						AS FinRecordID,
	|	CASE WHEN VALUETYPE(DocumentData.Ref) IN (TYPE(Document.InventoryConsumption))
	|		THEN DocumentData.BusinessTransactionSetting
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ConsignedGoodsWriteOff)
	|	END 																				AS BusinessTransactionSetting,
	|	CASE WHEN DocumentData.ThereIsRequestField_DocumentRegisterRecords 
	|		THEN DocumentData.DocumentRegisterRecords
	|		ELSE UNDEFINED
	|	END																				AS DocumentRegisterRecords,
	|	DocumentData.AccountingPoliciesInventoryValuationMethod							AS InventoryValuationMethod,
	|	CASE WHEN DocumentData.AccountingPoliciesOfOrganizationsAverageSlidingValuation
	|		THEN
	|			CASE WHEN DocumentData.DocumentSource <> UNDEFINED
	|				THEN VALUE(Enum.WaysToCalculateInventoryCost.BySourceDocumentRegisterRecords)
	|				ELSE DocumentData.AccountingPoliciesWayToDetermineCost
	|			END
	|		ELSE DocumentData.AccountingPoliciesWayToDetermineCost
	|	END 															AS CostDefiningMethod
	|FROM
	|	TTDocumentData_ AS DocumentData
	|WHERE
	|	DocumentData.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.RecogniseAsExpensesAssets)
	|	AND DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|
	|UNION ALL
	|
	// PARISH - giving goods
	|SELECT
	|	DocumentData.OperationNumber AS OperationNumber,
	// Document description
	|	VALUE(AccumulationRecordType.Receipt)	AS RecordType,
	|	DocumentData.Period 					AS Period,
	|	(CASE
	|		WHEN DocumentData.ThereIsRequestField_VariancePeriod
	|			THEN DocumentData.VariancePeriod
	|		 ELSE DATETIME(1,1,1) END) AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentData.Organization 															AS Organization,
	|	CASE WHEN DocumentData.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
	|			VALUE(Enum.BusinessTransactions.Subcontracting2_5),
	|			VALUE(Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5),
	|			VALUE(Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5),
	|			VALUE(Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5),
	|			VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredWriteOffAsExpenses))
	|		THEN DocumentData.TTCorItemAnalyticsOfInventoryLocationAttribute
	|		ELSE DocumentData.AnalyticsOfItemInventoryLocationAttributeTT
	|	END																					AS ItemsLocationAttributes,
	|	CASE WHEN DocumentData.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
	|			VALUE(Enum.BusinessTransactions.Subcontracting2_5),
	|			VALUE(Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5),
	|			VALUE(Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5),
	|			VALUE(Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5),
	|			VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredWriteOffAsExpenses))
	|		THEN DocumentData.TTCorAnalyticsItemInventoryLocationAttributeSource
	|		ELSE DocumentData.InitialInventoryLocationAttributeTTAnalyticsForItemTypesIsOriginalOne
	|	END																					AS AnalysisOfAccountingProductsInitial,
	|	CASE WHEN DocumentData.CatProductsTypeOfProducts = VALUE(Enum.ItemsTypes.Work_5)
	|		 AND NOT DocumentData.CatItemOfTraceableItem
	|			THEN VALUE(Catalog.InventoryKinds.EmptyRef)
	|		WHEN DocumentData.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
	|			VALUE(Enum.BusinessTransactions.Subcontracting2_5),
	|			VALUE(Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5),
	|			VALUE(Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5),
	|			VALUE(Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5),
	|			VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredWriteOffAsExpenses))
	|		THEN DocumentData.CorInventoryOwnerAttribute
	|		ELSE DocumentData.InventoryOwnerAttribute
	|	END																					AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN DocumentData.ThereIsRequestField_CorAccountingSection
	|			THEN DocumentData.CorAccountingSection
	//		When debiting expenses, the Accounting section is changed - the arrival in ...Co-formationdescription
	//		The peculiarity of the document REPORTDAVALTSU2_5:
	//		for it, only the type of inventory is changed from a semi-finished product to a product (the cor. section is defined below as for all toll-free goods)
	|		WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory IN (VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider),
	|														VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
	|														VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
	|			AND NOT DocumentData.BusinessOperation IN (
	|					VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
	|					VALUE(Enum.BusinessTransactions.Subcontracting2_5),
	|					VALUE(Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5),
	|					VALUE(Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5),
	|					VALUE(Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5),
	|					VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredWriteOffAsExpenses),
	|					VALUE(Enum.BusinessTransactions.ProviderGoodsWriteOffAtTheExpenseOfProvider),
	|					VALUE(Enum.BusinessTransactions.ProviderGoodsWriteOffAsExpenses))
	|			THEN CASE WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider)
	|				THEN VALUE(Enum.SectionsOfInventoryCostAccounting.MaterialsReceivedForSubcontractingToRegisterWriteOff)
	|				ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.VendorManagedInventoryToRegisterWriteOff)
	|				END
	|		WHEN DocumentData.Settlement_CorAccountingSection <> UNDEFINED
	|			THEN DocumentData.Settlement_CorAccountingSection
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
	|	END 																					AS AccountingSection,
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)					AS CorAccountingSection,
	|
	// Corresponding fields
	|	UNDEFINED 																		AS CorCompany,
	|	UNDEFINED 																		AS CorItemsLocationAttributes,
	|	UNDEFINED 																		AS CorAnalysisOfAccountingProductsInitial,
	|	UNDEFINED																		AS CorInventoryOwnerAttribute,
	|	UNDEFINED			    														AS CorLineOfBusiness,
	|	UNDEFINED 																		AS CorLot,
	|	UNDEFINED 																		AS LotVendorAttributesCorr,
	|
	// Other fields
	|	DocumentData.BusinessOperation 												AS BusinessOperation,
	|	DocumentData.Department 														AS Department,
	|	CASE
	|		WHEN VALUETYPE(DocumentData.ExpenseItemAssets) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|			THEN DocumentData.ExpenseItemAssets
	|			ELSE UNDEFINED
	|	END 																				AS ExpenseItemOfWriteOff,
	|	CASE
	|		WHEN VALUETYPE(DocumentData.ExpenseItemAssets) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|			THEN DocumentData.AssetExpenseAnalytics
	|			ELSE UNDEFINED
	|	END 																				AS DimensionOfExpenses,
	|	CASE
	|		WHEN VALUETYPE(DocumentData.ExpenseItemAssets) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|			THEN DocumentData.ExpenseItemAssets
	|			ELSE UNDEFINED
	|	END 																				AS AssetAndLiabilityItem,
	|	CASE
	|		WHEN VALUETYPE(DocumentData.ExpenseItemAssets) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|			THEN DocumentData.AssetExpenseAnalytics
	|			ELSE UNDEFINED
	|	END 																				AS AssetsLiabilitiesDimension,
	|	DocumentData.SourceDocumentPeriod											AS SalePeriod,
	|	UNDEFINED																		AS ProductsGroup,
	|	CASE WHEN DocumentData.ThereIsRequestField_AccountingDimensionByPartners
	|		THEN DocumentData.AccountingDimensionByPartners
	|		ELSE UNDEFINED
	|	END 																				AS AccountingDimensionByPartners,
	|	CASE
	|		WHEN DocumentData.ThereIsRequestField_GLAccountSettings
	|			THEN DocumentData.GLAccountSettings
	|			ELSE UNDEFINED
	|	END 																				AS GLAccountSettings,
	|	CASE WHEN DocumentData.ThereIsRequestField_SalesOrder
	|		THEN DocumentData.SalesOrder
	|		ELSE UNDEFINED
	|	END																				AS SalesOrder,
	|
	// Quantitative and summary indicators
	|	DocumentData.Count															AS Count,
	|	0 																					AS Cost,
	|	0 																					AS CostExcludingVAT,
	|	0 																					AS LocalCost,
	|	0 																					AS CostMan,
	|
	// Batch accounting fields version 2.2
	|	UNDEFINED 																		AS FinancialAccountingDimension,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|		AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN CASE 
	|				WHEN VALUETYPE(DocumentData.Lot) = TYPE(Catalog.ProductionLots)
	|					AND DocumentData.Lot <> VALUE(Catalog.ProductionLots.EmptyRef)
	|					AND CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup <> VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|				THEN CAST(DocumentData.Lot AS Catalog.ProductionLots).ProductsGroup
	|				WHEN (ISNULL(DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom, FALSE)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department))
	|					AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) = TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Estimated_FinancialAccountingDimension
	|				WHEN NOT (ISNULL(DocumentData.CatItemKeysWarehouseTerritoryShopFloorStockroom, FALSE)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department))
	|					AND VALUETYPE(DocumentData.Estimated_FinancialAccountingDimension) <> TYPE(Catalog.AnalyticalInventoryGroups)
	|				THEN DocumentData.Estimated_FinancialAccountingDimension
	|				ELSE UNDEFINED
	|			END
	|		ELSE UNDEFINED
	|	END 																				AS FinancialAccountingDimensionOfDocument,
	|	CASE
	|		WHEN NOT &Constant_BatchAccountingVersion22
	|		  OR DocumentData.Period < BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|			THEN UNDEFINED
	|		ELSE DocumentData.VATActivityType
	|	END 																				AS VATActivityType,
	|	CASE WHEN &Constant_BatchAccountingVersion22
	|	  AND DocumentData.Period >= BEGINOFPERIOD(&Constant_DateOfMigrationToBatchAccounting22, MONTH)
	|		THEN DocumentData.DocumentVATActivityType
	|		ELSE UNDEFINED
	|	END 																				AS DocumentVATActivityType,
	|	UNDEFINED																		AS CorVATActivityTypes,
	|	UNDEFINED 																		AS CorControllingAttributes,
	|	UNDEFINED																		AS Lot,
	|	UNDEFINED																		AS LotVendorAttributes,
	|
	|	VALUE(Enum.LotRecordTypes.Move)								AS EntryType,
	|	VALUE(Enum.CostAccountingTransactions.RecogniseAsExpensesAssets) 			AS CostAccountingTransaction,
	|	DocumentData.DocumentSource							  						AS DocumentSource,
	|	DocumentData.RowID 						  						AS RowID,
	// For the arrival of toll-free products, we do not fill in the ID of the fin record, because toll-free products do not have a book value.
	|	&IDOfUnusedFinRecord 						  						AS FinRecordID,
	|	DocumentData.BusinessTransactionSetting 										AS BusinessTransactionSetting,
	|	CASE WHEN DocumentData.ThereIsRequestField_DocumentRegisterRecords 
	|		THEN DocumentData.DocumentRegisterRecords
	|		ELSE UNDEFINED
	|	END																				AS DocumentRegisterRecords,
	|	DocumentData.AccountingPoliciesInventoryValuationMethod							AS InventoryValuationMethod,
	|	CASE WHEN DocumentData.AccountingPoliciesOfOrganizationsAverageSlidingValuation
	|		THEN
	|			CASE WHEN DocumentData.DocumentSource <> UNDEFINED
	|				THEN VALUE(Enum.WaysToCalculateInventoryCost.BySourceDocumentRegisterRecords)
	|				ELSE VALUE(Enum.WaysToCalculateInventoryCost.ByCorRecord)
	|			END
	|		ELSE DocumentData.AccountingPoliciesWayToDetermineCost
	|	END 															AS CostDefiningMethod
	|FROM
	|	TTDocumentData_ AS DocumentData
	|WHERE
	|	DocumentData.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.RecogniseAsExpensesAssets)
	// The condition for the formation of incoming movements for tolling goods must coincide with the conditions for the coralitika of the nomenclature and Corvidzapas in the expenditure movement in this operation
	|	AND ((DocumentData.BusinessOperation IN(
	|			VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
	|			VALUE(Enum.BusinessTransactions.Subcontracting2_5),
	|			VALUE(Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5),
	|			VALUE(Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5),
	|			VALUE(Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5),
	|			VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredWriteOffAsExpenses))
	|		AND DocumentData.CatProductsTypeOfProducts <> VALUE(Enum.ItemsTypes.Work_5))
	|		OR 
	|		(DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5)
	|			AND DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.Subcontracting2_5)
	|			AND DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5)
	|			AND DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5)
	|			AND DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5)
	|			AND DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.ConsumptionReportSubcontractingServicesDeliveredWriteOffAsExpenses)
	|			AND DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.ProviderGoodsWriteOffAtTheExpenseOfProvider)
	|			AND DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.ProviderGoodsWriteOffAsExpenses)
	|			AND DocumentData.InventoryOwnerAttributeIsTypeOfInventory IN
	|				(VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider),
	|				 VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
	|				 VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))))
	|";
	
	ReflectionParameters.TTTemplateTexts.Insert("TTOperation_RecogniseAsExpensesAssets", ReflectionRequestText);
	
EndProcedure

#EndRegion

#Region TextsOfAuxiliaryTemporaryTables

Procedure AddQueryTextToDataTable(ReflectionParameters)
	
	RegisterName = ReflectionParameters.RegisterName;
	RegisterDescription = ReflectionParameters.RegistersForReflection[RegisterName];
	FillInFieldTextsByCase(RegisterDescription, ReflectionParameters);
	
	// We will form a table with a detailed documentation with all the additional fields necessary for the formation of subsequent temporary tables.
	// All fields in the table are typed. If in the future it is necessary to access any fields through a dot, it is necessary to do this here.
	QueryTextTTDocumentDataPreliminary = QueryTextTTDocumentDataPreliminary(RegisterName, RegisterDescription);
	ReflectionParameters.TTTemplateTexts.Insert("TTDocumentData_Preliminary", QueryTextTTDocumentDataPreliminary);
	
	// Reversal
	If ReflectionParameters.MediumSlipIsUsed
	 And Not ReflectionParameters.ThereIsReversal Then

			QueryText =
			"SELECT TOP 0
			|	T.Period AS PeriodOfPrimaryRegisteredRecords,
			|	*
			|INTO TTReversalDataCost
			|FROM
			|	AccumulationRegister.InventoryCost AS T";
			
			ReflectionParameters.TTTemplateTexts.Insert("TTReversalDataCost", QueryText);
			
	EndIf;
	
	// Create auxiliary temporary tables
	AddTextOfRequestForProductAnalytics(ReflectionParameters);
	AddTextOfRequestForGeneratingFinancialAccountingAnalytics(ReflectionParameters);
	AddQueryTextAccountingPolicies(ReflectionParameters);
	AddTextOfRequestAccountingSection(ReflectionParameters);
	AddQueryTextForAITRecognitionSettings(ReflectionParameters);

	// Reversal
	If ReflectionParameters.MediumSlipIsUsed Then
		
		QueryText =
		"SELECT
		|	0 AS OperationNumber,
		|	AccountingPoliciesOfOrganizations_.InventoryValuationMethod AS InventoryValuationMethod,
		|	T.Period,
		|	T.Period AS SourceDocumentPeriod,
		|	T.RecordType,
		|	T.ItemsLocationAttributes AS AnalysisOfAccountingProductsInitial,
		|	T.CorItemsLocationAttributes AS CorAnalysisOfAccountingProductsInitial,
		|	&SelectionFields1
		|INTO TTOfRegisteredRecordedReversal
		|FROM
		|	TTReversalDataCost AS T
		|	INNER JOIN TTAccountingPoliciesOfOrganizations AS AccountingPoliciesOfOrganizations_
		|		ON T.Organization = AccountingPoliciesOfOrganizations_.Organization
		|		AND T.Period = AccountingPoliciesOfOrganizations_.Period
		|		AND AccountingPoliciesOfOrganizations_.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|	LEFT JOIN TTAccountingPoliciesOfOrganizations AS AccountingPoliciesOfPrimaryDocumentOrganizations
		|		ON T.Organization = AccountingPoliciesOfPrimaryDocumentOrganizations.Organization
		|		AND T.PeriodOfPrimaryRegisteredRecords = AccountingPoliciesOfPrimaryDocumentOrganizations.Period
		|		AND AccountingPoliciesOfPrimaryDocumentOrganizations.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|WHERE
		|	T.RecordType = VALUE(AccumulationRecordType.Receipt)
		|" + "
		|INDEX BY
		|	ItemsLocationAttributes
		|";
		
		SelectionFieldText = "";
		
		For Each CurField In Metadata.AccumulationRegisters.InventoryCost.Dimensions Do
			SelectionFieldText = SelectionFieldText + ?(SelectionFieldText = "", "", "," + Chars.LF + "	") + "T." + CurField.Name + " AS " + CurField.Name;
		EndDo;
		
		For Each CurField In Metadata.AccumulationRegisters.InventoryCost.Attributes Do
			If CurField.Type.ContainsType(Type("Number")) Then
				SelectionFieldText = SelectionFieldText + ?(SelectionFieldText = "", "", "," + Chars.LF + "	") + "-T." + CurField.Name + " AS " + CurField.Name;
			ElsIf CurField.Name = Metadata.AccumulationRegisters.InventoryCost.Attributes.CostDefiningMethod.Name Then
				SelectionFieldText = SelectionFieldText + ?(SelectionFieldText = "", "", "," + Chars.LF + "	")
					+ "CASE WHEN AccountingPoliciesOfPrimaryDocumentOrganizations.Organization IS NULL
						| AND T.CostDefiningMethod = VALUE(Enum.WaysToCalculateInventoryCost.EmptyRef)
						|	THEN VALUE(Enum.WaysToCalculateInventoryCost.FromDocument)
						|	ELSE T." + CurField.Name + "
						|END AS " + CurField.Name;
			Else
				SelectionFieldText = SelectionFieldText + ?(SelectionFieldText = "", "", "," + Chars.LF + "	") + "T." + CurField.Name + " AS " + CurField.Name;
			EndIf;
		EndDo;
		
		For Each CurField In Metadata.AccumulationRegisters.InventoryCost.Resources Do
			SelectionFieldText = SelectionFieldText + ?(SelectionFieldText = "", "", "," + Chars.LF + "	") + "-T." + CurField.Name + " AS " + CurField.Name;
		EndDo;
		
		QueryText = StrReplace(QueryText, "&SelectionFields1", SelectionFieldText);
		
		ReflectionParameters.TTTemplateTexts.Insert("TTOfRegisteredRecordedReversal", QueryText);
		
	EndIf;
	
	// Let's create a document data table with all the additional fields necessary to form temporary tables of operation_<name of the cost Operation>
	// Important! In the operation_<name of the cost Operation> tables, do not
	// - access the Attributes fields "through two points"
	// - add connections to other temporary tables.
	// All necessary fields and connections should be added to the Document data table. Some of the additional fields are obtained in the data table. The documentation is preliminary,
	// in this table there is a connection with additional temporary tables and additional fields are obtained that come from temporary tables.
	QueryTextTTDocumentData = QueryTextTTDocumentData(RegisterDescription);
	
	QueryTextData = QueryTextData(RegisterDescription);
	
	ReflectionParameters.TTTemplateTexts.Insert("TTDocumentData_", QueryTextTTDocumentData);
	ReflectionParameters.TextsOfDocumentDataRequests.Insert("DocumentData", QueryTextData);
	
EndProcedure

Procedure AddTextOfRequestForProductAnalytics(ReflectionParameters)
	
	QueryTextTempTable =
	"SELECT DISTINCT
	|	DocumentData.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	DocumentData.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	DocumentData.InventoryOwnerAttribute AS StockTypeSource,
	|	DocumentData.InventoryOwnerAttributeIsTypeOfInventory AS InventoryType,
	|	DocumentData.TypeOfInventoryOwnerAttributeOwnerOfItem AS GoodsOwner,
	|	DocumentData.Period AS Period
	|INTO TTAnalyticsForAccountingForDocumentProducts
	|FROM
	|	TTDocumentData_Preliminary AS DocumentData
	|";
	
	If ThereIsDataTableField(ReflectionParameters, "CorItemsLocationAttributes") Then
		
		QueryTextTempTable = QueryTextTempTable + "
		|UNION
		|" + "
		|SELECT DISTINCT
		|	DocumentData.CorItemsLocationAttributes AS ItemsLocationAttributes,
		|	DocumentData.CorInventoryOwnerAttribute AS InventoryOwnerAttribute,
		|	DocumentData.CorInventoryOwnerAttribute AS StockTypeSource,
		|	DocumentData.CorInventoryOwnerAttributeTypeOfInventory AS InventoryType,
		|	DocumentData.CorInventoryOwnerAttributeOwnerOfItem AS GoodsOwner,
		|	DocumentData.Period AS Period
		|FROM
		|	TTDocumentData_Preliminary AS DocumentData
		|";
		
	EndIf;

	QueryTextTempTable = QueryTextTempTable + "
	|INDEX BY
	|	ItemsLocationAttributes";
	
	ReflectionParameters.TTTemplateTexts.Insert("TTAnalyticsForAccountingForDocumentProducts", QueryTextTempTable);
	
	QueryTextTempTable =
	"SELECT DISTINCT
	|	DocumentAnalysis.ItemsLocationAttributes AS AnalysisOfAccountingProductsInitial,
	|	Dimension.Purpose.AssignmentType AS AssignmentType,
	|	CASE WHEN &Constant_KeepRecordsOfInventoryCostByAssignments
	|	  AND DocumentAnalysis.Period >= BEGINOFPERIOD(&Constant_CostAccountingByAssignmentValidFrom, MONTH)
	|		THEN DocumentAnalysis.ItemsLocationAttributes
	|		ELSE AnalyticsWithoutAssignment.DimensionKey
	|	END AS ItemsLocationAttributes,
	|	ISNULL(CommitteeAnalytics.DimensionKey, UNDEFINED) AS CommitteeProductAccountingAnalysis,
	|	DocumentAnalysis.StockTypeSource AS InventoryOwnerAttribute
	|INTO TTReplacementProductAccountingAnalyst
	|FROM
	|	TTAnalyticsForAccountingForDocumentProducts AS DocumentAnalysis
	|	INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON DocumentAnalysis.ItemsLocationAttributes = Dimension.Ref
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|		ON Dimension.Products = AnalyticsWithoutAssignment.Products
	|		AND Dimension.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|		AND Dimension.Series = AnalyticsWithoutAssignment.Series
	|		AND Dimension.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|		AND Dimension.ProductCostElement = AnalyticsWithoutAssignment.ProductCostElement
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS CommitteeAnalytics
	|	ON	Dimension.Products = CommitteeAnalytics.Products
	|		AND Dimension.Characteristic = CommitteeAnalytics.Characteristic
	|		AND VALUE(Catalog.Assignments.EmptyRef) = CommitteeAnalytics.Purpose
	|		AND VALUE(Catalog.ItemsBatches.EmptyRef) = CommitteeAnalytics.Series
	|		AND DocumentAnalysis.GoodsOwner = CommitteeAnalytics.StorageLocation
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = CommitteeAnalytics.ProductCostElement
	|		AND DocumentAnalysis.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|INDEX BY
	|	AnalysisOfAccountingProductsInitial
	|";
	
	ReflectionParameters.TTTemplateTexts.Insert("TTReplacementProductAccountingAnalyst", QueryTextTempTable);
	
EndProcedure

Procedure AddTextOfRequestForGeneratingFinancialAccountingAnalytics(ReflectionParameters)
	
	QueryTextTempTable =
	"SELECT DISTINCT
	|	DocumentData.SalesOpportunity 			AS SalesOpportunity,
	|	DocumentData.Manager 		AS Manager,
	|	DocumentData.Department 	AS Department,
	|	DocumentData.CatProductsTypeOfProducts	AS ItemsType,
	|	CASE
	|		WHEN DocumentData.ThereIsRequestField_ProductsGroup
	|			THEN DocumentData.ProductsGroup
	|		ELSE VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|	END AS ProductsGroup,
	|	CASE
	|		WHEN &Constant_AnalyticalAccountingByProductsGroups
	|		  AND NOT AnalyticalInventoryGroups.Ref IS NULL
	|			THEN AnalyticalInventoryGroups.Ref
	// For works and services, a division, manager, or transaction is not accounted for in financial accounting analytics.
	// The manager, division, and transaction are counted only for products. 
	|		WHEN DocumentData.CatProductsTypeOfProducts IN (
	|				VALUE(Enum.ItemsTypes.Work_5),
	|				VALUE(Enum.ItemsTypes.OperationService))
	|			THEN UNDEFINED
	|		WHEN &Constant_GenerateInventoryOwnerAttributesBySalesOpportunities
	|			AND ISNULL(SalesOpportunities.Ref.EnabledGoodsAssignmentInSalesOpportunity, FALSE)
	|			THEN ISNULL(SalesOpportunities.Ref, UNDEFINED)
	|		WHEN &Constant_GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|		 AND ISNULL(Departments.OptionOfAssignedAccountingOfGoods, VALUE(Enum.OptionsOfAssignedAccountingOfGoods.EmptyRef))
	|			= VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnitManagers)
	|			THEN ISNULL(Users.Ref, UNDEFINED)
	|		WHEN &Constant_GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|		 AND ISNULL(Departments.OptionOfAssignedAccountingOfGoods, VALUE(Enum.OptionsOfAssignedAccountingOfGoods.EmptyRef))
	|			= VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnit)
	|			THEN ISNULL(Departments.Ref, UNDEFINED)
	|		ELSE UNDEFINED
	|	END AS FinancialAccountingDimension
	|INTO TTFinancialAccountingAnalytics
	|FROM
	|	TTDocumentData_Preliminary AS DocumentData
	|	LEFT JOIN Catalog.BusinessStructure AS Departments
	|		ON DocumentData.Department = Departments.Ref
	|	LEFT JOIN Catalog.SalesOpportunitiesToCustomer AS SalesOpportunities
	|		ON DocumentData.SalesOpportunity = SalesOpportunities.Ref
	|	LEFT JOIN Catalog.Users AS Users
	|		ON DocumentData.Manager = Users.Ref
	|	LEFT JOIN Catalog.AnalyticalInventoryGroups AS AnalyticalInventoryGroups
	|		ON CASE WHEN DocumentData.ThereIsRequestField_ProductsGroup
	|			THEN DocumentData.ProductsGroup
	|			ELSE UNDEFINED
	|		  END = AnalyticalInventoryGroups.Ref
	|";
	
	ReflectionParameters.TTTemplateTexts.Insert("TTFinancialAccountingAnalytics", QueryTextTempTable);
	
EndProcedure

Procedure AddQueryTextAccountingPolicies(ReflectionParameters)
	
	QueryTextTempTable =
	"SELECT DISTINCT
	|	DocumentData.Organization AS Organization,
	|	CASE WHEN DocumentData.Organization.ParentCompany = VALUE(Catalog.Companies.EmptyRef)
	|		THEN DocumentData.Organization
	|		ELSE DocumentData.Organization.ParentCompany
	|	END AS ParentCompany,
	|	DocumentData.Period AS Period
	|INTO TTDocumentOrganization
	|FROM
	|	TTDocumentData_Preliminary AS DocumentData
	|";
	
	If ReflectionParameters.MediumSlipIsUsed And ReflectionParameters.ThereIsReversal Then

		QueryTextTempTable = QueryTextTempTable + "
		|UNION
		|" + "
		|SELECT DISTINCT
		|	DocumentData.Organization AS Organization,
		|	CASE WHEN DocumentData.Organization.ParentCompany = VALUE(Catalog.Companies.EmptyRef)
		|		THEN DocumentData.Organization
		|		ELSE DocumentData.Organization.ParentCompany
		|	END AS ParentCompany,
		|	DocumentData.Period AS Period
		|FROM
		|	TTReversalDataCost AS DocumentData
		|
		|UNION
		|
		|SELECT DISTINCT
		|	DocumentData.Organization AS Organization,
		|	CASE WHEN DocumentData.Organization.ParentCompany = VALUE(Catalog.Companies.EmptyRef)
		|		THEN DocumentData.Organization
		|		ELSE DocumentData.Organization.ParentCompany
		|	END AS ParentCompany,
		|	DocumentData.PeriodOfPrimaryRegisteredRecords AS Period
		|FROM
		|	TTReversalDataCost AS DocumentData
		|";
		
	EndIf;
	
	If ThereIsDataTableField(ReflectionParameters, "CorCompany") Then
		
		QueryTextTempTable = QueryTextTempTable + "
		|UNION
		|" + "
		|SELECT DISTINCT
		|	DocumentData.CorCompany AS Organization,
		|	CASE WHEN DocumentData.CorCompany.ParentCompany = VALUE(Catalog.Companies.EmptyRef)
		|		THEN DocumentData.CorCompany
		|		ELSE DocumentData.CorCompany.ParentCompany
		|	END AS ParentCompany,
		|	DocumentData.Period AS Period
		|FROM
		|	TTDocumentData_Preliminary AS DocumentData
		|";
		
	EndIf;

	QueryTextTempTable = QueryTextTempTable + "
	|INDEX BY
	|	ParentCompany";
	
	ReflectionParameters.TTTemplateTexts.Insert("TTDocumentOrganization", QueryTextTempTable);
	
	QueryTextTempTable =
	"SELECT
	|	DocumentAnalysis.Organization AS Organization,
	|	DocumentAnalysis.ParentCompany AS ParentCompany,
	|	DocumentAnalysis.Period AS Period,
	|	MAX(AccountingPolicies.Period) AS PolicyPeriod,
	|	MAX(TaxationSystemSettings.Period) AS SetupPeriod
	|INTO TTPeriodsOfAccountingPoliciesOfOrganizations
	|FROM
	|	TTDocumentOrganization AS DocumentAnalysis
	|		LEFT JOIN InformationRegister.FinancialAccountingPolicy AS AccountingPolicies
	|			ON DocumentAnalysis.ParentCompany = AccountingPolicies.Organization
	|		LEFT JOIN InformationRegister.TaxationSystemSettings AS TaxationSystemSettings
	|			ON DocumentAnalysis.ParentCompany = TaxationSystemSettings.Organization
	|WHERE
	|	AccountingPolicies.Period <= ENDOFPERIOD(DocumentAnalysis.Period, MONTH)
	|
	|GROUP BY
	|	DocumentAnalysis.Organization,
	|	DocumentAnalysis.ParentCompany,
	|	DocumentAnalysis.Period
	|
	|INDEX BY
	|	PolicyPeriod,
	|	ParentCompany
	|";
	
	ReflectionParameters.TTTemplateTexts.Insert("TTPeriodsOfAccountingPoliciesOfOrganizations", QueryTextTempTable);
	
	QueryTextTempTable =
	"SELECT
	|	T.Organization AS Organization,
	|	T.Period AS Period,
	|	ISNULL(AccountingPolicies.InventoryValuationMethod, UNDEFINED) AS InventoryValuationMethod,
	|	CASE
	|		WHEN ISNULL(AccountingPolicies.InventoryValuationMethod, UNDEFINED) = VALUE(Enum.InventoryValuationMethods.FIFORollingValuation)
	|			THEN TRUE
	|			ELSE FALSE
	|	END AS FIFORollingValuation,
	|	CASE
	|		WHEN ISNULL(AccountingPolicies.InventoryValuationMethod, UNDEFINED) = VALUE(Enum.InventoryValuationMethods.MovingAverage)
	|			THEN TRUE
	|			ELSE FALSE
	|	END AS MediumSlipValuation,
	|	CASE
	|		WHEN ISNULL(AccountingPolicies.InventoryValuationMethod, UNDEFINED) = VALUE(Enum.InventoryValuationMethods.FIFORollingValuation)
	|			THEN VALUE(Enum.WaysToCalculateInventoryCost.ByFIFO)
	|		WHEN ISNULL(AccountingPolicies.InventoryValuationMethod, UNDEFINED) = VALUE(Enum.InventoryValuationMethods.AveragePerMonth)
	|			THEN VALUE(Enum.WaysToCalculateInventoryCost.ByMonthlyAverage)
	|		WHEN ISNULL(AccountingPolicies.InventoryValuationMethod, UNDEFINED) = VALUE(Enum.InventoryValuationMethods.MovingAverage)
	|			THEN VALUE(Enum.WaysToCalculateInventoryCost.ByMovingAverage)
	|			ELSE UNDEFINED
	|	END AS CostDefiningMethod,
	|	ISNULL(AccountingPolicies.ItemizeVariancesByLinesOfBusiness, FALSE) AS ItemizeVariancesByLinesOfBusiness,
	|	ISNULL(AccountingPolicies.ItemizeVariancesByBusinessUnits, FALSE) AS ItemizeVariancesByBusinessUnits,
	|	ISNULL(AccountingPolicies.ItemizeVariancesByWarehousesStorageLocations, FALSE) AS ItemizeVariancesByWarehousesStorageLocations,
	|	ISNULL(TaxationSystemSettings.PayerOfAdditionalIncomeTaxFromHydrocarbonProductionAIT, FALSE) AS PayerOfAdditionalIncomeTaxFromHydrocarbonProductionAIT
	|INTO TTAccountingPoliciesOfOrganizations
	|FROM
	|	TTPeriodsOfAccountingPoliciesOfOrganizations AS T
	|		LEFT JOIN InformationRegister.FinancialAccountingPolicy AS AccountingPolicies
	|			ON T.ParentCompany = AccountingPolicies.Organization
	|			AND T.PolicyPeriod = AccountingPolicies.Period
	|		LEFT JOIN InformationRegister.TaxationSystemSettings AS TaxationSystemSettings
	|			ON T.ParentCompany = TaxationSystemSettings.Organization
	|			AND T.SetupPeriod = TaxationSystemSettings.Period
	|INDEX BY
	|	Organization";
	
	ReflectionParameters.TTTemplateTexts.Insert("TTAccountingPoliciesOfOrganizations", QueryTextTempTable);
	
EndProcedure

Procedure AddTextOfRequestAccountingSection(ReflectionParameters)
	
	QueryTextTempTable =
	"SELECT
	|	DocumentData.RecNo AS RecNo,
	// Accounting section
	|	CASE
	|		WHEN NOT DocumentData.ThereIsRequestField_InventoryOwnerAttribute
	|			THEN UNDEFINED
	// New accounting of goods received from the giver
	|		WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory IN (VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider),
	|			VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
	|			VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
	|			THEN 
	|				CASE
	//					The peculiarity of the document is the recording of storage products - it makes a write-off from the accounting section...Co-formationdescription
	|					WHEN DocumentData.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.RecogniseAsExpensesAssets)
	|					  AND DocumentData.BusinessOperation IN(
	|							VALUE(Enum.BusinessTransactions.ProviderGoodsWriteOffAtTheExpenseOfProvider),
	|							VALUE(Enum.BusinessTransactions.ProviderGoodsWriteOffAsExpenses))
	|						THEN
	|							CASE
	|								WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider)
	|									THEN VALUE(Enum.SectionsOfInventoryCostAccounting.MaterialsReceivedForSubcontractingToRegisterWriteOff)
	|									ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.VendorManagedInventoryToRegisterWriteOff)
	|							END
	//					In a warehouse or in a division
	|					WHEN DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Warehouse)
	|						OR DocumentData.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department)
	|						THEN
	|							CASE WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider)
	|								THEN VALUE(Enum.SectionsOfInventoryCostAccounting.MaterialsReceivedForProcessing)
	|								ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping)
	|							END
	//					Transfer of giveaway goods to the processor 2.5 (sub-processing)
	|					WHEN ISNULL(DocumentData.CatItemKeysContractTypeOfContract, UNDEFINED) = VALUE(Enum.ContractTypes.TransferToTolling2_5)
	|						THEN
	|							CASE WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider)
	|								THEN VALUE(Enum.SectionsOfInventoryCostAccounting.MaterialsReceivedForSubcontractingTransferredToPartners)
	|								ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.VendorManagedInventoryTransferredToPartners)
	|							END
	|				END
	|		WHEN ISNULL(DocumentData.CatItemKeysContractTypeOfContract, UNDEFINED) IN (VALUE(Enum.ContractTypes.WithCustomer),
	|				VALUE(Enum.ContractTypes.SalesViaCommissionAgent))
	|			AND DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitReceivedByCommissionAgent)
	|		WHEN ISNULL(DocumentData.CatItemKeysContractTypeOfContract, UNDEFINED) = VALUE(Enum.ContractTypes.SalesViaCommissionAgent)
	|			AND DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.OwnGoods)
	|		THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitTransferredToCommissionAgent)
	//		Implementation without transfer of ownership is of the Contract type - implementation, but the Contract is specified in the analytics
	|		WHEN ISNULL(DocumentData.CatItemKeysContractTypeOfContract, UNDEFINED) = VALUE(Enum.ContractTypes.WithCustomer)
	|			AND DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.OwnGoods)
	|		THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransit)
	|		WHEN ISNULL(DocumentData.CatItemKeysContractTypeOfContract, UNDEFINED) = VALUE(Enum.ContractTypes.WithConsignee)
	|			AND DocumentData.InventoryOwnerAttributeIsTypeOfInventory = VALUE(Enum.InventoryTypes.OwnGoods)
	|		THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent)
	|		WHEN ISNULL(DocumentData.CatItemKeysContractTypeOfContract, UNDEFINED) = VALUE(Enum.ContractTypes.WithConsignee)
	|			AND DocumentData.InventoryOwnerAttribute <> VALUE(Catalog.InventoryKinds.EmptyRef)
	//		As a rule, this is the type of inventory = Commission goods
	|		THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		ELSE UNDEFINED
	|	END AS Settlement_AccountingSection,
	|
	// Cor. accounting section
	|	CASE
	|		WHEN NOT DocumentData.ThereIsRequestField_CorInventoryOwnerAttribute
	|			THEN UNDEFINED
	// New accounting of goods received from the giver
	//		Feature of the document repurchase of accepted store goods:
	//		- the expenditure movement is made by the operation of writing off to other parties
	//		- incoming - external receipt
	//		- for a semi-finished product, there may be a book value that should be attributed to the incoming movement,
	//		  so you need a cor. Accounting section in the expense (determined by the same rules as the Accounting section in the parish - already for your own goods)
	//		- for other toll goods, you do not need to link the expenditure and incoming movement
	|		WHEN DocumentData.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.ExpensesToOtherProductionLots)
	|			AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.RedemptionOfProviderGoods)
	|			THEN CASE
	|				WHEN DocumentData.InventoryOwnerAttributeIsTypeOfInventory IN (VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider),
	|					VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
	|				THEN VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
	|				ELSE UNDEFINED
	|				END
	|		WHEN DocumentData.CorInventoryOwnerAttributeTypeOfInventory IN (VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider),
	|			VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
	|			VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
	|		THEN CASE
	//			In a warehouse or in a division
	|			WHEN DocumentData.CorOfInventoryLocationAttributeTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Warehouse)
	|				OR DocumentData.CorOfInventoryLocationAttributeTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department)
	|			THEN CASE
	|				WHEN DocumentData.CorInventoryOwnerAttributeTypeOfInventory = VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider)
	|				THEN VALUE(Enum.SectionsOfInventoryCostAccounting.MaterialsReceivedForProcessing)
	|				ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedForRespSafekeeping)
	|				END
	//			Transfer of giveaway goods to the processor 2.5 (sub-processing)
	|			WHEN ISNULL(DocumentData.CorAnalyticsContractTypeOfContract, UNDEFINED) = VALUE(Enum.ContractTypes.TransferToTolling2_5)
	|			THEN CASE
	|				WHEN DocumentData.CorInventoryOwnerAttributeTypeOfInventory = VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider)
	|				THEN VALUE(Enum.SectionsOfInventoryCostAccounting.MaterialsReceivedForSubcontractingTransferredToPartners)
	|				ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.VendorManagedInventoryTransferredToPartners)
	|				END
	|			END
	|		WHEN ISNULL(DocumentData.CorAnalyticsContractTypeOfContract, UNDEFINED) IN (VALUE(Enum.ContractTypes.WithCustomer),
	|				VALUE(Enum.ContractTypes.SalesViaCommissionAgent))
	|			AND DocumentData.CorInventoryOwnerAttributeTypeOfInventory = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitReceivedByCommissionAgent)
	|		WHEN ISNULL(DocumentData.CorAnalyticsContractTypeOfContract, UNDEFINED) = VALUE(Enum.ContractTypes.SalesViaCommissionAgent)
	|			AND DocumentData.CorInventoryOwnerAttributeTypeOfInventory = VALUE(Enum.InventoryTypes.OwnGoods)
	|		THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransitTransferredToCommissionAgent)
	//		Implementation without transfer of ownership is of the Contract type - implementation, but the Contract is specified in the analytics
	|		WHEN ISNULL(DocumentData.CorAnalyticsContractTypeOfContract, UNDEFINED) = VALUE(Enum.ContractTypes.WithCustomer)
	|			AND DocumentData.CorInventoryOwnerAttributeTypeOfInventory = VALUE(Enum.InventoryTypes.OwnGoods)
	|		THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsInTransit)
	|		WHEN ISNULL(DocumentData.CorAnalyticsContractTypeOfContract, UNDEFINED) = VALUE(Enum.ContractTypes.WithConsignee)
	|			AND DocumentData.CorInventoryOwnerAttributeTypeOfInventory = VALUE(Enum.InventoryTypes.OwnGoods)
	|		THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent)
	|		WHEN ISNULL(DocumentData.CorAnalyticsContractTypeOfContract, UNDEFINED) = VALUE(Enum.ContractTypes.WithConsignee)
	|			AND DocumentData.CorInventoryOwnerAttribute <> VALUE(Catalog.InventoryKinds.EmptyRef)
	//		As a rule, this is the type of inventory = Commission goods
	|		THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		ELSE UNDEFINED
	|	END AS Settlement_CorAccountingSection
	|INTO TTAccountingSections
	|FROM
	|	TTDocumentData_Preliminary AS DocumentData
	|";
	
	ReflectionParameters.TTTemplateTexts.Insert("TTAccountingSections", QueryTextTempTable);
	
EndProcedure

Procedure AddQueryTextForAITRecognitionSettings(ReflectionParameters)
	
	QueryTextTempTable = CalculationOfCostLocalization.AITSettingsQueryText(
			"TTDocumentData_Preliminary", 
			"CalculationOfCostOfCarryingOutDocuments_AddQueryTextOfAITRecognitionSettings");
	
	Query = ReflectionParameters.Query; //Query
	
	If Not Query.Parameters.Property("Organization") Then
		
		QueryTextTempTable = StrReplace(QueryTextTempTable,
			"&Organization",
			"SELECT TTDocumentOrganization.Organization FROM TTDocumentOrganization AS TTDocumentOrganization");
		
	EndIf;
	
	ReflectionParameters.TTTemplateTexts.Insert("AITExpenseRecognitionSettings", QueryTextTempTable);
	
EndProcedure

Procedure AddMotionGenerationRequestText(ReflectionParameters)
	
	RegisterName = ReflectionParameters.RegisterName;
	TypesOfDocumentOperations = ReflectionParameters.RegistersForReflection[RegisterName].TypesOfDocumentOperations;
	RegisterDescription = CalculationOfCostCached.GenerateCaseDescription("AccumulationRegister." + RegisterName);
	SumFields_ = New Structure(StrReplace(RegisterDescription.SelectionFieldsOfNonemptyMotions, "%1", ""));
	
	RequestColumns = New Structure;
	ArrayOfRequestColumns = New Array;
	ColumnsOfOperations = New Map;
	
	// Fill in the list of all columns of all cost operations
	For Each CurDocumentOperation In TypesOfDocumentOperations Do
		
		CurOperationColumns = New Structure;
		
		TempTableName = "TTOperation_" + Common.EnumerationValueName(CurDocumentOperation.Key);
		QueryText = ReflectionParameters.TTTemplateTexts[TempTableName];
		
		Columns = CalculationOfCostCached.RequestColumns(QueryText);
		
		For Each CurrentColumn In Columns Do
			
			CurOperationColumns.Insert(CurrentColumn);
			
			If Not RequestColumns.Property(CurrentColumn) Then
				RequestColumns.Insert(CurrentColumn);
				ArrayOfRequestColumns.Add(CurrentColumn);
			EndIf;
			
		EndDo;
		
		ColumnsOfOperations.Insert(CurDocumentOperation.Key, CurOperationColumns);
		
	EndDo;
	
	MissingSumFields = New Structure;
	
	If ReflectionParameters.MediumSlipIsUsed Then
	
		PossibleSumFields = New Structure(SumFieldsOfAverageSliding());
		For Each KeyAndValue In PossibleSumFields Do
			If Not RequestColumns.Property(KeyAndValue.Key) Then
				MissingSumFields.Insert(KeyAndValue.Key);
			EndIf;
		EndDo;
		
	EndIf;
	
	QueryText = "";
	
	For Each CurDocumentOperation In TypesOfDocumentOperations Do
		
		FieldText = "";
		CurOperationColumns = ColumnsOfOperations[CurDocumentOperation.Key];
		
		For Each CurrentColumn In ArrayOfRequestColumns Do
			
			If CurOperationColumns.Property(CurrentColumn) Then
				
				FieldText = FieldText + ?(FieldText = "", "", ",") + "
					|	T." + CurrentColumn + " AS " + CurrentColumn;
				
			Else
				
				If SumFields_.Property(CurrentColumn) Then
					FieldText = FieldText + ?(FieldText = "", "", ",") + "
						|	0 AS " + CurrentColumn;
				Else
					FieldText = FieldText + ?(FieldText = "", "", ",") + "
						|	UNDEFINED AS " + CurrentColumn;
				EndIf;
				
			EndIf;
			
		EndDo;

		If ReflectionParameters.MediumSlipIsUsed Then
			
			For Each KeyAndValue In MissingSumFields Do
				FieldText = FieldText + ?(FieldText = "", "", ",") + "
					|	0 AS " + KeyAndValue.Key;
			EndDo;

			FieldText = FieldText + ?(FieldText = "", "", ",") + "
				|	&CurrentSessionDate AS CostCalculationDate";
			
		EndIf;
		
		If ReflectionParameters.MediumSlipIsUsed And QueryText = "" Then
			QueryTextTemplate2 = 
			"SELECT
			|	&QueryFields
			|INTO TTDocumentOFOperation 
			|FROM
			|	#TempTableName AS T";
		Else
			
			QueryTextTemplate2 = 
			"SELECT
			|	&QueryFields
			|FROM
			|	#TempTableName AS T";
			
		EndIf;
		
		TempTableName = "TTOperation_" + Common.EnumerationValueName(CurDocumentOperation.Key);
		
		QueryTextTemplate2 = StrReplace(QueryTextTemplate2, "#TempTableName", TempTableName);
		QueryTextTemplate2 = StrReplace(QueryTextTemplate2, "&QueryFields", TrimAll(FieldText));
			
		QueryText = QueryText
			+ ?(QueryText = "", "", "
			|
			|UNION ALL
			|
			|")
			+ QueryTextTemplate2;
		
	EndDo;
	
	If ReflectionParameters.MediumSlipIsUsed Then
		
		For Each KeyAndValue In MissingSumFields Do
			ArrayOfRequestColumns.Add(KeyAndValue.Key);
			RequestColumns.Insert(KeyAndValue.Key);
		EndDo;
		
		ArrayOfRequestColumns.Add("CostCalculationDate");
		RequestColumns.Insert("CostCalculationDate");
		
		ReflectionParameters.Insert("ArrayOfRequestColumns", ArrayOfRequestColumns); // all columns of the data sample request and document iteration
		ReflectionParameters.Insert("RequestColumns", RequestColumns); // similarly, but in the form of a structure
		
		QueryText = QueryText + "
		|INDEX BY
		|	ItemsLocationAttributes";
		
		ReflectionParameters.TTTemplateTexts.Insert("TTDocumentOFOperation", QueryText);
		
	Else
		ReflectionParameters.ReflectionTemplateTexts.Insert(RegisterName, QueryText);
	EndIf;
	
EndProcedure

Procedure SetAdditionalRequestParameters(ReflectionParameters)
	
	DateEmpty = Date(1,1,1);
	
	SetRequestParameterConstant(ReflectionParameters, "BatchAccountingVersion22", True);
	SetRequestParameterConstant(ReflectionParameters, "DateOfMigrationToBatchAccounting22", DateEmpty);
	
	SetRequestParameterConstant(ReflectionParameters, "KeepManagementRecordsOfOrganizations", True);
	SetRequestParameterConstant(ReflectionParameters, "StartDateOfManagementAccountingOfOrganizations", DateEmpty);
	
	SetRequestParameterConstant(ReflectionParameters, "KeepRecordsOfInventoryCostByAssignments", False);
	SetRequestParameterConstant(ReflectionParameters, "CostAccountingByAssignmentValidFrom", DateEmpty);
	
	SetRequestParameterConstant(ReflectionParameters, "GenerateInventoryOwnerAttributesByFinancialAccountingGroups", False);
	SetRequestParameterConstant(ReflectionParameters, "GenerateInventoryOwnerAttributesBySalesOpportunities", False);
	SetRequestParameterConstant(ReflectionParameters, "GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers", False);
	SetRequestParameterConstant(ReflectionParameters, "AnalyticalAccountingByProductsGroups", False);
	
	SetRequestParameterConstant(ReflectionParameters, "UseVATAccounting", False);
	SetRequestParameterConstant(ReflectionParameters, "UseAITAccounting", False);
	SetRequestParameterConstant(ReflectionParameters, "StartDateOfAITAccounting", DateEmpty);
	// Set the values of other parameters
	ReflectionParameters.Query.SetParameter("CurrentSessionDate", CurrentSessionDate());
	ReflectionParameters.Query.SetParameter("DoNotControlSequence",
		CalculationOfCostCached.ValuesOfTechnologicalParameters().DoNotControlSequenceAtMediumSlip);
	
EndProcedure

Procedure SetRequestParameterConstant(ReflectionParameters, ConstantName, DefaultValue)
	
	ParameterName = "Constant_" + ConstantName;
	
	If Metadata.Constants.Find(ConstantName) = Undefined Then
		ConstantValue = DefaultValue;
	Else
		ConstantValue = Constants[ConstantName].Get();
	EndIf;
	
	ReflectionParameters.Query.SetParameter(ParameterName, ConstantValue);
	
EndProcedure
	
// Generates the text of the request for the selection of line codes for batch accounting analytics.
// 
// Parameters:
//  DocumentName - String - document name
//  TabularSectionNames - String - Names of the tabular parts of the document
//  NameOfAnalyticsProps - String - The name of the item accounting analytics detail
// 
// Returns:
//  String - Query text
// 
Function RequestTextStringCodesForBatchAccountingAnalytics(DocumentName, TabularSectionNames, NameOfAnalyticsProps = "ItemsLocationAttributes") Export
	
	// A separate function is used for the document Receipt of services in the subdivision. A separate function is used for the text Query tableanalytic of the Accounting of Parties()
	// to obtain line codes, which is located in the module of the manager of the document receipt of services in the subdivision.
	
	SampleRequestTemplate =
	"SELECT
	|	&TabularSectionName AS TabularSectionName,
	|	T.NameOfAnalyticsProps.Products AS Products,
	|	T.NameOfAnalyticsProps.Characteristic AS Characteristic,
	|	T.NameOfAnalyticsProps.Series AS Series,
	|	(CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN T.NameOfAnalyticsProps.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef) END) AS Purpose,
	|	T.NameOfAnalyticsProps.StorageLocation AS StorageLocation,
	|	MAX(T.LineNumber) AS LineNumber, // Line number for the same type of analytics
	|	SUM(1) AS RowsCount
	|INTO TTDocumentProducts
	|FROM
	|	TheTableNameOfTheDocument AS T
	|WHERE
	|	T.Ref = &Ref
	|GROUP BY
	|	T.NameOfAnalyticsProps.Products,
	|	T.NameOfAnalyticsProps.CHARACTERISTIC,
	|	T.NameOfAnalyticsProps.Series,
	|	(CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN T.NameOfAnalyticsProps.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef) END),
	|	T.NameOfAnalyticsProps.StorageLocation
	|";
	
	SampleRequestTemplate = StrReplace(SampleRequestTemplate, "NameOfAnalyticsProps", NameOfAnalyticsProps);
	
	QueryTextOfSelectionIsSummarized = "
	|SELECT
	|	T.TabularSectionName AS TabularSectionName,
	|	T.Products AS Products,
	|	T.Characteristic AS Characteristic,
	|	SUM(T.RowsCount) AS RowsCount
	|INTO ItemOfTTDocumentIsSummarized
	|FROM
	|	TTDocumentProducts AS T
	|GROUP BY
	|	T.TabularSectionName,
	|	T.Products,
	|	T.Characteristic
	|";
	
	// The Line code field is filled in if there is more than one line in the document with the same nomenclature and characteristics,
	// but different series, assignments, or storage locations.
	// For all lines with the same nomenclature, characteristics, series, warehouse and purpose, one
	// common line code is filled in to form one common batch for all such lines.
	// Checking the filling of the line code in the batch accounting analytics is performed in the procedure to fix the problem of movement in the documents()
	// of the general module of the calculation of the cost of data preparation.
	// This is used to generate separate batches via item accounting analytics keys.
	// The allocation of individual batches is necessary to obtain correct data from the register "Detailing the cost of batches of goods". 
	ResultRequestTemplate = "
	|SELECT
	|	&TabularSectionName AS TabularSectionName,
	|	T.LineNumber AS LineNumber,
	|	CASE WHEN Totals.RowsCount > 1
	|	 AND Totals.RowsCount <> ResultsInDetail.RowsCount
	|		THEN ResultsInDetail.LineNumber
	|		ELSE 0
	|	END AS RowCode
	|INTO TTLineCodesForBatchAccountingAnalytics
	|FROM
	|	TheTableNameOfTheDocument AS T
	|	INNER JOIN ItemOfTTDocumentIsSummarized AS Totals
	|		ON T.NameOfAnalyticsProps.Products = Totals.Products
	|		AND T.NameOfAnalyticsProps.CHARACTERISTIC = Totals.Characteristic
	|		AND Totals.TabularSectionName = &TabularSectionName
	|	INNER JOIN TTDocumentProducts AS ResultsInDetail
	|		ON T.NameOfAnalyticsProps.Products = ResultsInDetail.Products
	|		AND T.NameOfAnalyticsProps.CHARACTERISTIC = ResultsInDetail.Characteristic
	|		AND T.NameOfAnalyticsProps.Series = ResultsInDetail.Series
	|		AND (T.NameOfAnalyticsProps.Purpose = ResultsInDetail.Purpose
	|			OR NOT &KeepRecordsOfInventoryCostByAssignments)
	|		AND T.NameOfAnalyticsProps.StorageLocation = ResultsInDetail.StorageLocation
	|		AND ResultsInDetail.TabularSectionName = &TabularSectionName
	|WHERE
	|	T.Ref = &Ref
	|";
	
	ResultRequestTemplate = StrReplace(ResultRequestTemplate, "NameOfAnalyticsProps", NameOfAnalyticsProps);
	
	StructureTabularParts = New Structure(TabularSectionNames);
	QueryTextSamples = "";
	QueryTextResults_1 = "";
	
	For Each KeyAndValue In StructureTabularParts Do
		
		TableName = KeyAndValue.Key;
		FullTableName = Metadata.Documents[DocumentName].FullName() + "." + TableName;
		
		SubqueryText = StrReplace(SampleRequestTemplate, "&TabularSectionName", """" + TableName + """");
		SubqueryText = StrReplace(SubqueryText, "TheTableNameOfTheDocument", FullTableName);
		
		If ValueIsFilled(QueryTextSamples) Then
			SubqueryText = StrReplace(SubqueryText, "INTO TTDocumentProducts", "");
			QueryTextSamples = QueryTextSamples + "
			|
			|UNION ALL
			|
			|";
		EndIf;
		
		QueryTextSamples = QueryTextSamples + SubqueryText;
		
		SubqueryText = StrReplace(ResultRequestTemplate, "&TabularSectionName", """" + TableName + """");
		SubqueryText = StrReplace(SubqueryText, "TheTableNameOfTheDocument", FullTableName);
		
		If ValueIsFilled(QueryTextResults_1) Then
			SubqueryText = StrReplace(SubqueryText, "INTO TTLineCodesForBatchAccountingAnalytics", "");
			QueryTextResults_1 = QueryTextResults_1 + "
			|
			|UNION ALL
			|
			|";
		EndIf;
		
		QueryTextResults_1 = QueryTextResults_1 + SubqueryText;
		
	EndDo;
	
	QueryText = QueryTextSamples + "
		|;
		|" + QueryTextOfSelectionIsSummarized + "
		|;
		|" + QueryTextResults_1 + "
		|;
		|
		|";
	
	Return QueryText;
	
EndFunction

Procedure FillInFieldTextsByCase(RegisterDescription, ReflectionParameters)
	
	NonSummableFields = New Array;
	NonSummableFields.Add("RowCode");
	
	ArrayOfRequestInitializationFields = New Array;
	ArrayOfSelectionFieldsNumeric = New Array;
	ArrayOfSelectionFieldsNotNumeric = New Array;
	ArrayOfTypedFields = New Array;
	
	ArrayOfSelectionFieldsNotNumeric.Add("T.OperationNumber AS OperationNumber");
	ArrayOfSelectionFieldsNotNumeric.Add("T.CostAccountingTransaction AS CostAccountingTransaction");
	ArrayOfSelectionFieldsNotNumeric.Add("T.DocumentBusinessTransaction AS DocumentBusinessTransaction");
	// Fields from the Document data table
	ArrayOfSelectionFieldsNotNumeric.Add("T.InventoryOwnerAttributeIsTypeOfInventory AS InventoryOwnerAttributeIsTypeOfInventory");
	ArrayOfSelectionFieldsNotNumeric.Add("T.TypeOfInventoryOwnerAttributeOwnerOfItem AS TypeOfInventoryOwnerAttributeOwnerOfItem");
	ArrayOfSelectionFieldsNotNumeric.Add("T.CorAnalyticsContractTypeOfContract AS CorAnalyticsContractTypeOfContract");
	ArrayOfSelectionFieldsNotNumeric.Add("T.CorInventoryLocationSAttributesStorageAreaShopFloorStockroom AS CorInventoryLocationSAttributesStorageAreaShopFloorStockroom");
	ArrayOfSelectionFieldsNotNumeric.Add("T.CorOfInventoryLocationAttributeTypeOfStorageLocation AS CorOfInventoryLocationAttributeTypeOfStorageLocation");
	ArrayOfSelectionFieldsNotNumeric.Add("T.CorInventoryOwnerAttributeTypeOfInventory AS CorInventoryOwnerAttributeTypeOfInventory");
	ArrayOfSelectionFieldsNotNumeric.Add("T.CorInventoryOwnerAttributeOwnerOfItem AS CorInventoryOwnerAttributeOwnerOfItem");
	// Fields from the analytics of the nomenclature
	ArrayOfSelectionFieldsNotNumeric.Add("T.InventoriedLocationAttributeAnalysisPurposeLineOfBusiness AS InventoriedLocationAttributeAnalysisPurposeLineOfBusiness");
	ArrayOfSelectionFieldsNotNumeric.Add("T.CatItemKeysContractTypeOfContract AS CatItemKeysContractTypeOfContract");
	ArrayOfSelectionFieldsNotNumeric.Add("T.CatItemKeysWarehouseTerritoryShopFloorStockroom AS CatItemKeysWarehouseTerritoryShopFloorStockroom");
	ArrayOfSelectionFieldsNotNumeric.Add("T.CatKeysOfItemTypeOfStorageLocation AS CatKeysOfItemTypeOfStorageLocation");
	ArrayOfSelectionFieldsNotNumeric.Add("T.CatProductsTypeOfProducts AS CatProductsTypeOfProducts");
	ArrayOfSelectionFieldsNotNumeric.Add("T.AnalysisOfAccountingForProductsProducts AS AnalysisOfAccountingForProductsProducts");
	ArrayOfSelectionFieldsNotNumeric.Add("T.AnalysisOfAccountingProductsCharacteristics AS AnalysisOfAccountingProductsCharacteristics");
	ArrayOfSelectionFieldsNotNumeric.Add("T.ProductAccountingAnalyticsStorageLocation AS ProductAccountingAnalyticsStorageLocation");
	ArrayOfSelectionFieldsNotNumeric.Add("T.CatItemOfTraceableItem AS CatItemOfTraceableItem");
	
	ArrayOfTypedFields.Add("T.OperationNumber AS OperationNumber");
	ArrayOfTypedFields.Add("T.CostAccountingTransaction AS CostAccountingTransaction");
	
	For Each FieldDetails In RegisterDescription.FieldTable Do
		
		FieldText = "T." + FieldDetails.Name + " AS " + FieldDetails.Name;
		If RegisterDescription.RegisterFields.Property(FieldDetails.Name) Then
			ArrayOfRequestInitializationFields.Add(FieldText);
		Else
			ArrayOfRequestInitializationFields.Add("UNDEFINED" + " AS " + FieldDetails.Name);
		EndIf;
		
		ArrayOfRequestInitializationFields.Add("FALSE AS ThereIsRequestField_" + FieldDetails.Name);
		
		If FieldDetails.Type.Types().Count() = 1 And FieldDetails.Type.Types()[0] = Type("Number") And NonSummableFields.Find(FieldDetails.Name) = Undefined Then
			ArrayOfSelectionFieldsNumeric.Add(FieldText);
		Else
			ArrayOfSelectionFieldsNotNumeric.Add(FieldText);
		EndIf;
		
		TextOfTypedField = TextOfTypedField(FieldDetails.Name, FieldDetails.Type);
		TextOfTypedField = ?(TextOfTypedField = Undefined, FieldText, TextOfTypedField);
		ArrayOfTypedFields.Add(TextOfTypedField);
		
		ArrayOfTypedFields.Add("T.ThereIsRequestField_" + FieldDetails.Name + " AS ThereIsRequestField_" + FieldDetails.Name);
		ArrayOfSelectionFieldsNotNumeric.Add("T.ThereIsRequestField_" + FieldDetails.Name + " AS ThereIsRequestField_" + FieldDetails.Name);
		
	EndDo;
	
	ArrayOfRequestInitializationFields.Add("0 AS OperationNumber");
	ArrayOfRequestInitializationFields.Add("VALUE(Enum.CostAccountingTransactions.EmptyRef) AS CostAccountingTransaction");
	
	// Additional field
	If ReflectionParameters.MetadataOfDocument.Attributes.Find("BusinessOperation") <> Undefined Then
		ArrayOfTypedFields.Add("CAST(T.Ref AS Document." + ReflectionParameters.MetadataOfDocument.Name + ").BusinessOperation AS DocumentBusinessTransaction");
	Else
		ArrayOfTypedFields.Add("T.BusinessOperation AS DocumentBusinessTransaction");
	EndIf;
	
	RegisterDescription.Insert("TextOfRequestInitializationFields", StrConcat(ArrayOfRequestInitializationFields, "," + Chars.LF + Chars.Tab));
	RegisterDescription.Insert("TextFieldsTyped", StrConcat(ArrayOfTypedFields, "," + Chars.LF + Chars.Tab));
	RegisterDescription.Insert("TextOfMainSelectionField", StrConcat(ArrayOfSelectionFieldsNotNumeric, "," + Chars.LF + Chars.Tab));
	RegisterDescription.Insert("TextSelectionFieldsAreNumeric", StrConcat(ArrayOfSelectionFieldsNumeric, "," + Chars.LF + Chars.Tab));
	
EndProcedure

Function QueryTextTTDocumentDataPreliminary(RegisterName, RegisterDescription)
	
	QueryText = "";
	
	// Let's assemble a schema for a data sample pooling request.
	QuerySchema = New QuerySchema;
	
	QueryText = 
	"SELECT TOP 0
	|	&QueryFields
	|FROM
	|	#RegisterName AS T";
	
	QueryText = StrReplace(QueryText, "#RegisterName", "AccumulationRegister" + "." + RegisterName);
	QueryText = StrReplace(QueryText, "&QueryFields", RegisterDescription.TextOfRequestInitializationFields);
	
	QuerySchema.SetQueryText(QueryText);
	
	CurPackageRequest = QuerySchema.QueryBatch.Get(0); //QuerySchemaSelectQuery
	QueryOperators  = CurPackageRequest.Operators;
	RequestColumns    = CurPackageRequest.Columns;
	ColumnsCount = CurPackageRequest.Columns.Count();
	
	QueryNumber = 0;
	
	For Each CircuitDescription In RegisterDescription.DocumentQuerySchemes Do
		
		QueryNumber = QueryNumber + 1;
		
		QueryBatch = CircuitDescription.QuerySchema.QueryBatch; // QuerySchemaQueryBatch
		CurPackageRequest = QueryBatch.Get(0); //QuerySchemaSelectQuery
		SubqueryOperator = CurPackageRequest.Operators[0];
		SubqueryColumns  = CurPackageRequest.Columns;
		
		CurOperator_ = QueryOperators.Add(SubqueryOperator);
		CurOperator_.SelectedFields.Clear();
		
		ColumnNumber = 0;
		
		For Each FieldDetails In RegisterDescription.FieldTable Do
			
			SubqueryColumn = SubqueryColumns.Find(FieldDetails.Name);
			
			// Cur field value
			If SubqueryColumn <> Undefined Then
				RequestColumns.Get(ColumnNumber).Fields.Set(QueryNumber, SubqueryColumn.Fields[0]);
			Else
				CurOperator_.SelectedFields.Add("UNDEFINED", ColumnNumber);
			EndIf;
			
			ColumnNumber = ColumnNumber + 1;
			// The value of the field "There is a help_<Cur field>"
			CurOperator_.SelectedFields.Add(?(SubqueryColumn = Undefined, "FALSE", "TRUE"), ColumnNumber);
			ColumnNumber = ColumnNumber + 1;
			
		EndDo;
		
		CurOperator_.SelectedFields.Add(TrimAll(QueryNumber), ColumnNumber);
		
		ColumnNumber = ColumnNumber + 1;
		CurOperator_.SelectedFields.Add("VALUE(Enum.CostAccountingTransactions." + Common.EnumerationValueName(CircuitDescription.OperationKind) + ")", ColumnNumber);
		
	EndDo;
	
	While RequestColumns.Count() > ColumnsCount Do
		RequestColumns.Delete(RequestColumns.Count() - 1);
	EndDo;
	
	QueryText = QuerySchema.GetQueryText();
	QueryText = StrReplace(QueryText, "NULL,", "UNDEFINED,");
	QueryText = StrReplace(QueryText, "null,", "UNDEFINED,");
	
	QueryTextTempTable =
		"SELECT
		|	RECORDAUTONUMBER() AS RecNo,
		// Fields from the Document data table
		|	ISNULL(CatInventoryKinds.InventoryType, VALUE(Enum.InventoryTypes.EmptyRef)) AS InventoryOwnerAttributeIsTypeOfInventory,
		|	ISNULL(CatInventoryKinds.GoodsOwner, UNDEFINED) AS TypeOfInventoryOwnerAttributeOwnerOfItem,
		|	ISNULL(T.CorItemsLocationAttributes.Contract.ContractType, VALUE(Enum.ContractTypes.EmptyRef)) AS CorAnalyticsContractTypeOfContract,
		|	ISNULL(T.CorItemsLocationAttributes.WarehouseArea.ShopFloorStockroom, FALSE) AS CorInventoryLocationSAttributesStorageAreaShopFloorStockroom,
		|	ISNULL(T.CorItemsLocationAttributes.StorageType, VALUE(Enum.StorageLocationTypes.EmptyRef)) AS CorOfInventoryLocationAttributeTypeOfStorageLocation,
		|	ISNULL(CorCatTypesOfStocks.InventoryType, VALUE(Enum.InventoryTypes.EmptyRef)) AS CorInventoryOwnerAttributeTypeOfInventory,
		|	ISNULL(CorCatTypesOfStocks.GoodsOwner, UNDEFINED) AS CorInventoryOwnerAttributeOwnerOfItem,
		// Fields from the analytics of the nomenclature
		|	ISNULL(CatProductListKeys.Purpose.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)) AS InventoriedLocationAttributeAnalysisPurposeLineOfBusiness,
		|	ISNULL(CatProductListKeys.Contract.ContractType, VALUE(Enum.ContractTypes.EmptyRef)) AS CatItemKeysContractTypeOfContract,
		|	ISNULL(CatProductListKeys.WarehouseArea.ShopFloorStockroom, FALSE) AS CatItemKeysWarehouseTerritoryShopFloorStockroom,
		|	ISNULL(CatProductListKeys.StorageType, VALUE(Enum.StorageLocationTypes.EmptyRef)) AS CatKeysOfItemTypeOfStorageLocation,
		|	ISNULL(CatProductListKeys.Products, VALUE(Catalog.Products.EmptyRef)) AS AnalysisOfAccountingForProductsProducts,
		|	ISNULL(CatProductListKeys.Characteristic, VALUE(Catalog.ItemsCharacteristics.EmptyRef)) AS AnalysisOfAccountingProductsCharacteristics,
		|	ISNULL(CatProductListKeys.StorageLocation, UNDEFINED) AS ProductAccountingAnalyticsStorageLocation,
		|	ISNULL(CatProducts.ItemsType, VALUE(Enum.ItemsTypes.EmptyRef)) AS CatProductsTypeOfProducts,
		|	ISNULL(CatProducts.TracedGoods, FALSE) AS CatItemOfTraceableItem,
		|	&TextFieldsTyped
		|INTO TTDocumentData_Preliminary
		|FROM
		|	#QueryText AS T
		|
		|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS CatProductListKeys
		|		ON CatProductListKeys.Ref = T.ItemsLocationAttributes
		|	LEFT JOIN Catalog.Products AS CatProducts
		|		ON CatProducts.Ref = CatProductListKeys.Products
		|	LEFT JOIN Catalog.InventoryKinds AS CatInventoryKinds
		|		ON CatInventoryKinds.Ref = T.InventoryOwnerAttribute
		|	LEFT JOIN Catalog.InventoryKinds AS CorCatTypesOfStocks
		|		ON CorCatTypesOfStocks.Ref = T.CorInventoryOwnerAttribute";
	
	QueryTextTempTable = StrReplace(QueryTextTempTable, "&TextFieldsTyped", TrimAll(RegisterDescription.TextFieldsTyped));
	QueryTextTempTable = StrReplace(QueryTextTempTable, "#QueryText", "(" + QueryText + ")");
	QueryTextTempTable = QueryTextTempTable + "
		|INDEX BY
		|	ItemsLocationAttributes
		|";
	
	Return QueryTextTempTable;
	
EndFunction

Function QueryTextTTDocumentData(RegisterDescription)
	
	QueryText =
		"SELECT
		|	&TextSelectionFieldsAreNotNumeric,
		|
		// Fields from the table inanalyticsaccountcountingreferences
		|	TTProductAnalytics.ItemsLocationAttributes AS AnalyticsOfItemInventoryLocationAttributeTT,
		|	TTProductAnalytics.CommitteeProductAccountingAnalysis AS CommitteeSInventoryLocationAttributeAnalyticsTTItemTypeOfCommitteeSInventoryTypeOfCommitteeTypeOfCommitteeTypeOfCommitteeTypeOfCommitteeTypeOfCommitteeTypeOfCommitteeTypeOfCommittee,
		|	TTProductAnalytics.AnalysisOfAccountingProductsInitial AS InitialInventoryLocationAttributeTTAnalyticsForItemTypesIsOriginalOne,
		|	TTCorAnalyticsProducts.ItemsLocationAttributes AS TTCorItemAnalyticsOfInventoryLocationAttribute,
		|	TTCorAnalyticsProducts.CommitteeProductAccountingAnalysis AS TTCorAnalyticsOfItemInventoryLocationAttributeCommittee,
		|	TTCorAnalyticsProducts.AnalysisOfAccountingProductsInitial AS TTCorAnalyticsItemInventoryLocationAttributeSource,
		|	TTProductAnalytics.AssignmentType AS InventoryLocationAttributeIsOriginalDestinationTypeOfDestination,
		// Fields from the analytics box of the nomenclature
		|	CatBoxItemKeys.WarehouseArea.ShopFloorStockroom AS CatBoxItemKeysWarehouseAreaShopFloorStockroom,
		|	CatBoxItemKeys.StorageType AS CatBoxItemKeysTypeOfStorageLocation,
		|	CatCorNomenclature.ItemsType AS CatBoxItemTypeOfItem,
		// Fields from organizations and accounting policies
		|	OrganizationCor.Ref  AS CorCompanyLink,
		|	AccountingPoliciesOfOrganizations_.InventoryValuationMethod AS AccountingPoliciesInventoryValuationMethod,
		|	AccountingPoliciesOfOrganizations_.FIFORollingValuation AS FIFOAccountingPoliciesRollingValuation,
		|	AccountingPoliciesOfOrganizations_.MediumSlipValuation AS AccountingPoliciesOfOrganizationsAverageSlidingValuation,
		|	AccountingPoliciesOfOrganizations_.CostDefiningMethod AS AccountingPoliciesWayToDetermineCost,
		|	AccountingPoliciesOfOrganizations_.PayerOfAdditionalIncomeTaxFromHydrocarbonProductionAIT AS AccountingPoliciesAITPayer,
		|	AccountingPoliciesOfOrganizations_.ItemizeVariancesByLinesOfBusiness AS AccountingPoliciesDetailDeviationsInAreasOfActivity,
		|	AccountingPoliciesOfOrganizations_.ItemizeVariancesByBusinessUnits AS AccountingPoliciesDetailDeviationsByDivision,
		|	AccountingPoliciesOfOrganizations_.ItemizeVariancesByWarehousesStorageLocations AS AccountingPoliciesDetailDeviationsByWarehouse,
		|	CorAccountingPoliciesOfOrganizations.InventoryValuationMethod AS CorAccountingPoliciesInventoryValuationMethod,
		|	CorAccountingPoliciesOfOrganizations.FIFORollingValuation AS CorAccountingPoliciesFIFORollingValuation,
		|	CorAccountingPoliciesOfOrganizations.MediumSlipValuation AS CorAccountingPoliciesOfOrganizationsAverageSlidingValuation,
		|	CorAccountingPoliciesOfOrganizations.PayerOfAdditionalIncomeTaxFromHydrocarbonProductionAIT AS CorAccountingPoliciesAITPayer,
		// Accounting Sections
		|	AccountingSections.Settlement_AccountingSection AS Settlement_AccountingSection,
		|	AccountingSections.Settlement_CorAccountingSection AS Settlement_CorAccountingSection,
		// Financial Accounting Analytics
		|	TTFinancialAccountingAnalytics.FinancialAccountingDimension AS Estimated_FinancialAccountingDimension,
		|	TTCorOfFinancialAccountingControllingsAttribute.FinancialAccountingDimension AS Settlement_CorControllingAttributeOfFinancialAccounting,
		|
		|	&TextSelectionFieldsAreNumeric
		|INTO TTDocumentData_
		|FROM
		|	#DocumentData AS DocumentData
		// nomenclature analytics
		|	LEFT JOIN TTReplacementProductAccountingAnalyst AS TTProductAnalytics
		|		ON DocumentData.ItemsLocationAttributes = TTProductAnalytics.AnalysisOfAccountingProductsInitial
		|		AND DocumentData.InventoryOwnerAttribute = TTProductAnalytics.InventoryOwnerAttribute
		|	LEFT JOIN TTFinancialAccountingAnalytics AS TTFinancialAccountingAnalytics
		|		ON DocumentData.SalesOpportunity = TTFinancialAccountingAnalytics.SalesOpportunity
		|		AND DocumentData.Manager = TTFinancialAccountingAnalytics.Manager
		|		AND DocumentData.Department = TTFinancialAccountingAnalytics.Department
		|		AND DocumentData.ProductsGroup = TTFinancialAccountingAnalytics.ProductsGroup
		|		AND DocumentData.CatProductsTypeOfProducts = TTFinancialAccountingAnalytics.ItemsType
		// Cor. analytics of the nomenclature
		|	LEFT JOIN TTReplacementProductAccountingAnalyst AS TTCorAnalyticsProducts
		|		ON DocumentData.CorItemsLocationAttributes = TTCorAnalyticsProducts.AnalysisOfAccountingProductsInitial
		|		AND DocumentData.CorInventoryOwnerAttribute = TTCorAnalyticsProducts.InventoryOwnerAttribute
		|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS CatBoxItemKeys
		|		ON CatBoxItemKeys.Ref = TTCorAnalyticsProducts.ItemsLocationAttributes
		|	LEFT JOIN Catalog.Products AS CatCorNomenclature
		|		ON CatCorNomenclature.Ref = CatBoxItemKeys.Products
		|	LEFT JOIN TTFinancialAccountingAnalytics AS TTCorOfFinancialAccountingControllingsAttribute
		|		ON DocumentData.SalesOpportunity = TTCorOfFinancialAccountingControllingsAttribute.SalesOpportunity
		|		AND DocumentData.Manager = TTCorOfFinancialAccountingControllingsAttribute.Manager
		|		AND DocumentData.Department = TTCorOfFinancialAccountingControllingsAttribute.Department
		|		AND DocumentData.ProductsGroup = TTCorOfFinancialAccountingControllingsAttribute.ProductsGroup
		|		AND CatCorNomenclature.ItemsType = TTCorOfFinancialAccountingControllingsAttribute.ItemsType
		// Organizations and accounting policies
		|	LEFT JOIN Catalog.Companies AS OrganizationCor
		|		ON DocumentData.CorCompany = OrganizationCor.Ref
		|	LEFT JOIN TTAccountingPoliciesOfOrganizations AS CorAccountingPoliciesOfOrganizations
		|		ON DocumentData.CorCompany = CorAccountingPoliciesOfOrganizations.Organization
		|		AND DocumentData.Period = CorAccountingPoliciesOfOrganizations.Period
		|	LEFT JOIN TTAccountingPoliciesOfOrganizations AS AccountingPoliciesOfOrganizations_
		|		ON DocumentData.Organization = AccountingPoliciesOfOrganizations_.Organization
		|		AND DocumentData.Period = AccountingPoliciesOfOrganizations_.Period
		// Accounting Sections
		|	LEFT JOIN TTAccountingSections AS AccountingSections
		|		ON &ConditionConnectionToAccountingSections
		|";
	
	QueryText = QueryText + "
		|INDEX BY
		|	CostAccountingTransaction,
		|	BusinessOperation
		|";
	
	QueryText = StrReplace(QueryText, "&TextSelectionFieldsAreNotNumeric", TrimAll(RegisterDescription.TextOfMainSelectionField));
	QueryText = StrReplace(QueryText, "&TextSelectionFieldsAreNumeric", TrimAll(RegisterDescription.TextSelectionFieldsAreNumeric));
	QueryText = StrReplace(QueryText, "T.", "DocumentData.");
	// When converting the table #data document by the mechanism of the alias of the data document table changes to T, but not in the connection section
	QueryText = StrReplace(QueryText, "&ConditionConnectionToAccountingSections", "T.RecNo = AccountingSections.RecNo");
	
	Return QueryText;
	
EndFunction

Function QueryTextData(RegisterDescription)
	
	QueryText = "SELECT
		|	&TextOfMainSelectionField,
		|	&TextSelectionFieldsAreNumeric
		|FROM
		|	TTDocumentData_Preliminary AS T
		|";
	
	QueryText = StrReplace(QueryText, "&TextOfMainSelectionField", TrimAll(RegisterDescription.TextOfMainSelectionField));
	QueryText = StrReplace(QueryText, "&TextSelectionFieldsAreNumeric", TrimAll(RegisterDescription.TextSelectionFieldsAreNumeric));
	
	Return QueryText;
	
EndFunction

Function TextOfTypedField(FieldName, DescriptionOfFieldType)
	
	Text = Undefined;
	
	If DescriptionOfFieldType.Types().Count() <> 1 Then
		Return Text;
	EndIf;
	
	PrimitiveTypes = New TypeDescription("Boolean, Date, Number, String, UUID");
	FieldType = DescriptionOfFieldType.Types()[0];
	
	If Not PrimitiveTypes.ContainsType(FieldType) Then
		
		MetadataForType = Metadata.FindByType(FieldType);
		
		If MetadataForType <> Undefined Then
			Text = "CASE
				|		WHEN VALUETYPE(T." + FieldName + ") = TYPE(" + MetadataForType.FullName() + ")
				|		THEN T." + FieldName + "
				|		ELSE VALUE(" + MetadataForType.FullName() + ".EmptyRef)
				|	END AS " + FieldName;
		EndIf;
		
	Else
		
		If FieldType = Type("Date") Then
			Text = "CAST(CASE
				|		WHEN VALUETYPE(T." + FieldName + ") = TYPE(DATE)
				|		THEN T." + FieldName + "
				|		ELSE DATETIME(1,1,1)
				|	END AS DATE) AS " + FieldName;
		ElsIf FieldType = Type("Number") Then
			
			If DescriptionOfFieldType.NumberQualifiers.Digits = 0 Then
				NumberFormat_ = "31,3";
			Else
				NumberFormat_ = Format(DescriptionOfFieldType.NumberQualifiers.Digits, "NZ=0; NG=") + ","
					+ Format(DescriptionOfFieldType.NumberQualifiers.FractionDigits, "NZ=0; NG=");
			EndIf;
			
			Text = "CAST(CASE
				|		WHEN VALUETYPE(T." + FieldName + ") = TYPE(NUMBER)
				|		THEN T." + FieldName + "
				|		ELSE 0
				|	END AS NUMBER (" + NumberFormat_ + ")) AS " + FieldName;
			
		ElsIf FieldType = Type("Boolean") Then
			Text = "CASE
				|		WHEN VALUETYPE(T." + FieldName + ") = TYPE(BOOLEAN)
				|		THEN T." + FieldName + "
				|		ELSE FALSE
				|	END AS " + FieldName;
		EndIf;
		
	EndIf;
	
	Return Text;
	
EndFunction

#EndRegion

#Region TextsAccountingOnMediumSlipBasis

Procedure AddQueryTextCalculationAverageSlidingCost(ReflectionParameters)
	
	// Composition of sum fields
	PossibleSumFields = New Structure(SumFieldsOfAverageSliding());
	SumFieldsOfAverageSliding = New Structure;
	
	For Each KeyAndValue In PossibleSumFields Do
		If ReflectionParameters.RequestColumns.Property(KeyAndValue.Key) Then
			SumFieldsOfAverageSliding.Insert(KeyAndValue.Key);
		EndIf;
	EndDo;
	
	// Attributes that affect the composition of the request package
	ThereIsDocumentSource = ReflectionParameters.RequestColumns.Property("DocumentSource");
	ThereIsCorLineOfBusiness = ReflectionParameters.RequestColumns.Property("CorLineOfBusiness");
	ThereIsSetupOfAccountingAccounts = ReflectionParameters.RequestColumns.Property("GLAccountSettings");
	ThereIsExpenseItemWriteOff = ReflectionParameters.RequestColumns.Property("ExpenseItemOfWriteOff");
	ThereIsIncomeItem = ReflectionParameters.RequestColumns.Property("IncomeItem");
	ThereIsItemOfAssetsLiabilities = ReflectionParameters.RequestColumns.Property("AssetAndLiabilityItem");
	ThereIsAccountingAnalyticsForPartners = ReflectionParameters.RequestColumns.Property("AccountingDimensionByPartners");
	ThereIsSalesOrder = ReflectionParameters.RequestColumns.Property("SalesOrder");
	ThereIsDivision = ReflectionParameters.RequestColumns.Property("Department");
	ThereIsCorOrganization = ReflectionParameters.RequestColumns.Property("CorCompany");
	
	ReflectionParameters.Insert("ThereIsDocumentSource", ThereIsDocumentSource);
	ReflectionParameters.Insert("ThereIsCorLineOfBusiness", ThereIsCorLineOfBusiness);
	ReflectionParameters.Insert("ThereIsSetupOfAccountingAccounts", ThereIsSetupOfAccountingAccounts);
	ReflectionParameters.Insert("ThereIsExpenseItemWriteOff", ThereIsExpenseItemWriteOff);
	ReflectionParameters.Insert("ThereIsIncomeItem", ThereIsIncomeItem);
	ReflectionParameters.Insert("ThereIsItemOfAssetsLiabilities", ThereIsItemOfAssetsLiabilities);
	ReflectionParameters.Insert("ThereIsAccountingAnalyticsForPartners", ThereIsAccountingAnalyticsForPartners);
	ReflectionParameters.Insert("ThereIsSalesOrder", ThereIsSalesOrder);
	ReflectionParameters.Insert("ThereIsDivision", ThereIsDivision);
	ReflectionParameters.Insert("ThereIsCorOrganization", ThereIsCorOrganization);
	
	TypesOfDocumentOperations = ReflectionParameters.RegistersForReflection[ReflectionParameters.RegisterName].TypesOfDocumentOperations; // Map
	ThereAreDisposalsAtFixedCost =
		(TypesOfDocumentOperations.Get(Enums.CostAccountingTransactions.DisposalAtFixedCost) <> Undefined);
	ThereIsMove =
		(TypesOfDocumentOperations.Get(Enums.CostAccountingTransactions.Move) <> Undefined);
	ThereIsWriteOffToOtherParties =
		(TypesOfDocumentOperations.Get(Enums.CostAccountingTransactions.ExpensesToOtherProductionLots) <> Undefined);
		
	ReflectionParameters.Insert("ThereAreDisposalsAtFixedCost", ThereAreDisposalsAtFixedCost);
	ReflectionParameters.Insert("ThereIsMove", ThereIsMove);
	ReflectionParameters.Insert("ThereIsWriteOffToOtherParties", ThereIsWriteOffToOtherParties);
	
	#Region TemplatesForQueryTexts
	
	// for the &field of the average sliding query to the source
	// The &Sign field takes the values 1 for calculating the average sliding cost of disposal, and -1 for calculating the cost of Storno Registered Record.
	TemplateForSumFieldBasedOnAverageValueOfSource = "
		|	CAST(
		|		&Character * (CASE
		|			WHEN ISNULL(Source.Count, 0) = 0
		|				THEN 0
		|			WHEN T.Count = Source.Count
		|				THEN Source.NameOfFieldAmount
		|			ELSE CAST(T.Count * (Source.NameOfFieldAmount / Source.Count) AS NUMBER (31,2)) END
		|		- (CASE WHEN T.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.DisposalAtFixedCost)
		|			AND ISNULL(Source.Count, 0) <> 0
		// When combining tables of different operations, it may turn out that the numeric field will have the type Undefined (if there is no such field in one of the operations)
		|			AND VALUETYPE(T.NameOfFieldAmount) = TYPE(NUMBER)
		|				THEN CAST(T.NameOfFieldAmount AS NUMBER (31,2))
		|				ELSE 0 END)) AS NUMBER (31,2)) AS NameOfFieldAmount";
	
	TemplateOfSumFieldIsMidSlipSample = "
	// The cost for the "By cor. Registered Records" method is always determined from the Amount table. The sum of the expenditure RegisteredRecorded one-to-one 
	// goes into the incoming Registered Recorded.
	// For other methods, if the cost is determined in the source table (for example, by a sliding average), then the cost from the source table is saved.
	// If the cost is not determined, then it is determined from the calculation according to the Amount table.    
		|	CAST(CASE
		|		WHEN T.CostDefiningMethod = VALUE(Enum.WaysToCalculateInventoryCost.ByCorRecord)
		|			THEN Amounts.NameOfFieldAmount
		|		WHEN T.NameOfFieldAmount <> 0 THEN T.NameOfFieldAmount
		|		WHEN T.Count = Amounts.Count OR Amounts.Count = 0
		|			THEN Amounts.NameOfFieldAmount
		|			ELSE CAST(T.Count * (Amounts.NameOfFieldAmount / Amounts.Count) AS NUMBER (31,2))
		|	  	END AS NUMBER (31,2)) AS NameOfFieldAmount";
	
	TextOfRequestFieldWithDimension = ""; // for &Fields with Grouping
	TextOfDimensionRequestField = ""; // for &The Grouping field
	StructureDifferingFields = New Structure("CorItemsLocationAttributes, CorAnalysisOfAccountingProductsInitial, DocumentRegisterRecords, CostCalculationDate");
	
	TextOfFieldIsBasedOnAverageValueOfSource = "";  // for &The field of the query is averagely sliding to the source
	TextOfFieldIsBasicOnMediumSlip = ""; // for &The fields are the main ones
	TextOfFieldIsMediumSlipSelection = ""; // for &The field of the Average Sliding Sampling query
	
	UnusedMeasurementsOnMediumSlip = New Structure;
	// The "Batch" and "Batch accounting analytics" fields in the "Unfactured deliveries" section are always filled in.
	// For goods, the Accounting section is determined by the type of inventory, for works and services - by the Accounting section defined in the document. 
	UnusedMeasurementsOnMediumSlip.Insert("Lot", "
	|	CASE
	|		WHEN T.AccountingSection IN (
	|				VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries),
	|				VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress))
	|		 OR VALUETYPE(T.Lot) = TYPE(Catalog.ProductionLots)
	|			THEN T.Lot
	|		ELSE UNDEFINED
	|	END");
	UnusedMeasurementsOnMediumSlip.Insert("LotVendorAttributes", "
	|	CASE
	|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries)
	|			THEN T.LotVendorAttributes
	|		ELSE VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)
	|	END");
	UnusedMeasurementsOnMediumSlip.Insert("FinancialAccountingDimension", "
	|	CASE
	|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
	|		 OR VALUETYPE(T.Lot) = TYPE(Catalog.ProductionLots)
	|			THEN T.FinancialAccountingDimension
	|		ELSE UNDEFINED
	|	END");
	UnusedMeasurementsOnMediumSlip.Insert("VATActivityType", "
	|	CASE
	|		WHEN T.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress)
	|		 OR VALUETYPE(T.Lot) = TYPE(Catalog.ProductionLots)
	|			THEN T.VATActivityType
	|		ELSE VALUE(Enum.VATTaxationTypes.EmptyRef)
	|	END");
	UnusedMeasurementsOnMediumSlip.Insert("CorVATActivityTypes", "
	|	CASE
	|		WHEN T.CorAccountingSection IN (
	|				VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef),
	|				VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress))
	|			THEN T.CorVATActivityTypes
	|		ELSE VALUE(Enum.VATTaxationTypes.EmptyRef)
	|	END");
	UnusedMeasurementsOnMediumSlip.Insert("CorControllingAttributes", "
	|	CASE
	|		WHEN T.CorAccountingSection IN (
	|				VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef),
	|				VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress))
	|			THEN T.CorControllingAttributes
	|		ELSE UNDEFINED
	|	END");
	
	For Each CurrentColumn In ReflectionParameters.ArrayOfRequestColumns Do
		
		If SumFieldsOfAverageSliding.Property(CurrentColumn) Or CurrentColumn = "Count" Then

			TextOfRequestFieldWithDimension = TextOfRequestFieldWithDimension + ?(TextOfRequestFieldWithDimension = "", "", ",") + "
				|	SUM(T." + CurrentColumn + ") AS " + CurrentColumn;
			
		ElsIf StructureDifferingFields.Property(CurrentColumn) Then

			TextOfRequestFieldWithDimension = TextOfRequestFieldWithDimension + ?(TextOfRequestFieldWithDimension = "", "", ",") + "
				|	MAX(T." + CurrentColumn + ") AS " + CurrentColumn;
			
		Else

			TextOfRequestFieldWithDimension = TextOfRequestFieldWithDimension + ?(TextOfRequestFieldWithDimension = "", "", ",") + "
				|	T." + CurrentColumn + " AS " + CurrentColumn;
			TextOfDimensionRequestField = TextOfDimensionRequestField + ?(TextOfDimensionRequestField = "", "", ",") + "
				|	T." + CurrentColumn;
			
		EndIf;
		
		If UnusedMeasurementsOnMediumSlip.Property(CurrentColumn) Then
			
			TextOfFieldIsBasicOnMediumSlip = TextOfFieldIsBasicOnMediumSlip + ?(TextOfFieldIsBasicOnMediumSlip = "", "", ",") + "
				|	CASE WHEN T.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
				|		THEN " + UnusedMeasurementsOnMediumSlip[CurrentColumn] + "
				|		ELSE T." + CurrentColumn + "
				|	END AS " + CurrentColumn;
			
			TextOfFieldIsMediumSlipSelection = TextOfFieldIsMediumSlipSelection + ?(TextOfFieldIsMediumSlipSelection = "", "", ",") + "
				|	CASE WHEN T.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
				|		THEN " + UnusedMeasurementsOnMediumSlip[CurrentColumn] + "
				|		ELSE T." + CurrentColumn + "
				|	END AS " + CurrentColumn;
			
			TextOfFieldIsBasedOnAverageValueOfSource = TextOfFieldIsBasedOnAverageValueOfSource + ?(TextOfFieldIsBasedOnAverageValueOfSource = "", "", ",") + "
				|	T." + CurrentColumn + " AS " + CurrentColumn;
			
		ElsIf SumFieldsOfAverageSliding.Property(CurrentColumn) Then
			
			TextOfFieldIsBasedOnAverageValueOfSource = TextOfFieldIsBasedOnAverageValueOfSource + ?(TextOfFieldIsBasedOnAverageValueOfSource = "", "", ",")
				+ StrReplace(TemplateForSumFieldBasedOnAverageValueOfSource, "NameOfFieldAmount", CurrentColumn);
			
			TextOfFieldIsMediumSlipSelection = TextOfFieldIsMediumSlipSelection + ?(TextOfFieldIsMediumSlipSelection = "", "", ",")
				+ StrReplace(TemplateOfSumFieldIsMidSlipSample, "NameOfFieldAmount", CurrentColumn);
				
			TextOfFieldIsBasicOnMediumSlip = TextOfFieldIsBasicOnMediumSlip + ?(TextOfFieldIsBasicOnMediumSlip = "", "", ",") + "
				|	T." + CurrentColumn + " AS " + CurrentColumn;
			
		Else
			
			TextOfFieldIsBasedOnAverageValueOfSource = TextOfFieldIsBasedOnAverageValueOfSource + ?(TextOfFieldIsBasedOnAverageValueOfSource = "", "", ",") + "
				|	T." + CurrentColumn + " AS " + CurrentColumn;
			
			TextOfFieldIsMediumSlipSelection = TextOfFieldIsMediumSlipSelection + ?(TextOfFieldIsMediumSlipSelection = "", "", ",") + "
				|	T." + CurrentColumn + " AS " + CurrentColumn;
			
			TextOfFieldIsBasicOnMediumSlip = TextOfFieldIsBasicOnMediumSlip + ?(TextOfFieldIsBasicOnMediumSlip = "", "", ",") + "
				|	T." + CurrentColumn + " AS " + CurrentColumn;
			
		EndIf;
		
	EndDo;
	
	#EndRegion
	
	#Region AddQueryTextAverageSlidingCost
	
	QueryText =
	"SELECT DISTINCT
	|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	T.AccountingSection AS AccountingSection,
	|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	T.Organization AS Organization
	|INTO TTSelectionBalanceMediumSlip
	|FROM
	|	TTDocumentOFOperation AS T
	|WHERE
	|	T.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
	|	AND T.RecordType = VALUE(AccumulationRecordType.Expense)
	|
	|UNION
	|
	|SELECT DISTINCT
	|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	T.AccountingSection AS AccountingSection,
	|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	T.Organization AS Organization
	|FROM
	|	TTOfRegisteredRecordedReversal AS T
	|
	|INDEX BY
	|	ItemsLocationAttributes
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	T.Organization,
	|	T.FinRecordID,
	|	T.Period
	|INTO TTSelectionIds
	|FROM
	|	TTDocumentOFOperation AS T
	|WHERE
	|	T.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
	|	AND T.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND T.FinRecordID <> UNDEFINED
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.ItemsLocationAttributes,
	|	T.AccountingSection,
	|	T.InventoryOwnerAttribute,
	|	T.Organization,
	|	T.FinRecordID,
	|	T.Period,
	|	SUM(T.Count) AS Count,
	|	SUM(T.Cost) AS Cost,
	|	SUM(T.CostExcludingVAT) AS CostExcludingVAT,
	|	SUM(T.OffBalanceCost) AS OffBalanceCost,
	|	SUM(T.LocalCost) AS LocalCost,
	|	SUM(T.OffBalanceCostLocal) AS OffBalanceCostLocal,
	|	SUM(T.CostMan) AS CostMan
	|INTO TTCostPriceBalance
	|FROM
	|(SELECT
	|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	T.AccountingSection AS AccountingSection,
	|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	T.Organization AS Organization,
	|	UNDEFINED AS FinRecordID,
	|	UNDEFINED AS Period,
	|	T.CountBalance AS Count,
	|	T.CostBalance AS Cost,
	|	T.CostExcludingVATBalance AS CostExcludingVAT,
	|	T.OffBalanceCostBalance AS OffBalanceCost,
	|	T.LocalCostBalance AS LocalCost,
	|	T.OffBalanceCostLocalBalance AS OffBalanceCostLocal,
	|	T.CostManBalance AS CostMan
	|FROM
	|	AccumulationRegister.InventoryCost.Balance(,
	|		(ItemsLocationAttributes, AccountingSection, InventoryOwnerAttribute, Organization)
	|			IN (SELECT T.ItemsLocationAttributes, T.AccountingSection, T.InventoryOwnerAttribute, T.Organization FROM TTSelectionBalanceMediumSlip AS T)
	|		) AS T
	|WHERE
	|	T.CountBalance <> 0
	|	OR (T.CostBalance <> 0 OR T.LocalCostBalance <> 0 OR T.OffBalanceCostBalance <> 0 OR T.OffBalanceCostLocalBalance <> 0)
	|	OR &DoNotControlSequence
	|
	|UNION ALL
	|
	|SELECT
	|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	T.AccountingSection AS AccountingSection,
	|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	T.Organization AS Organization,
	|	UNDEFINED AS FinRecordID,
	|	UNDEFINED AS Period,
	|	T.Count AS Count,
	|	T.Cost AS Cost,
	|	T.CostExcludingVAT AS CostExcludingVAT,
	|	T.OffBalanceCost AS OffBalanceCost,
	|	T.LocalCost AS LocalCost,
	|	T.OffBalanceCostLocal AS OffBalanceCostLocal,
	|	T.CostMan AS CostMan
	|FROM
	|	AccumulationRegister.InventoryCost AS T
	|	INNER JOIN TTSelectionBalanceMediumSlip AS Filter
	|		ON T.ItemsLocationAttributes = Filter.ItemsLocationAttributes
	|		AND T.AccountingSection = Filter.AccountingSection
	|		AND T.InventoryOwnerAttribute = Filter.InventoryOwnerAttribute
	|		AND T.Organization = Filter.Organization
	|WHERE
	|	T.Recorder = &Ref
	|	AND (T.Count <> 0
	|		OR T.ReversingEntry
	|		OR T.BusinessOperation IN(
	|			VALUE(Enum.BusinessTransactions.GoodsValueVarianceIncome),
	|			VALUE(Enum.BusinessTransactions.GoodsValueVarianceExpenses)))
	|	AND NOT T.LotCalculation
	|	AND NOT T.CalculationOfCost
	|	AND T.CostDefiningMethod = VALUE(Enum.WaysToCalculateInventoryCost.ByMovingAverage)
	|	AND &DoNotControlSequence
	|
	|UNION ALL
	|
	|SELECT
	|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	T.AccountingSection AS AccountingSection,
	|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	T.Organization AS Organization,
	|	CASE
	// If the cost is not filled in in the Registered Records due to an error or due to the lack of Balances, then we do not fill in the ID of the FIN record and
	// the period so that the amount in the Registered Records can be added to the Balance to calculate the correct price when re-checking the document.
	|		WHEN T.Cost = 0 AND T.CostExcludingVAT = 0 AND T.OffBalanceCost = 0
	|		 AND T.LocalCost = 0 AND T.OffBalanceCostLocal = 0 AND T.CostMan = 0
	|			THEN UNDEFINED
	|		WHEN IDs.FinRecordID IS NULL
	// There is no fin ID in the new document Register Records. records that are in the old Registered Records.
	// In this case, the old Registered Records are added to the "free Balances".
	|			THEN UNDEFINED
	|		WHEN T.BusinessOperation IN(
	|	  			VALUE(Enum.BusinessTransactions.GoodsValueVarianceIncome),
	|	  			VALUE(Enum.BusinessTransactions.GoodsValueVarianceExpenses))
	|			THEN T.RowID
	|		ELSE T.FinRecordID
	|	END AS FinRecordID,
	|	CASE
	|		WHEN T.Cost = 0 AND T.CostExcludingVAT = 0 AND T.OffBalanceCost = 0
	|		 AND T.LocalCost = 0 AND T.OffBalanceCostLocal = 0 AND T.CostMan = 0
	|			THEN UNDEFINED
	|		WHEN IDs.FinRecordID IS NULL
	|			THEN UNDEFINED
	|		ELSE T.Period
	|	END AS Period,
	|	CASE WHEN NOT T.ReversingEntry THEN 1 ELSE -1 END * T.Count AS Count,
	|	CASE WHEN NOT T.ReversingEntry THEN 1 ELSE -1 END * T.Cost AS Cost,
	|	CASE WHEN NOT T.ReversingEntry THEN 1 ELSE -1 END * T.CostExcludingVAT AS CostExcludingVAT,
	|	CASE WHEN NOT T.ReversingEntry THEN 1 ELSE -1 END * T.OffBalanceCost AS OffBalanceCost,
	|	CASE WHEN NOT T.ReversingEntry THEN 1 ELSE -1 END * T.LocalCost AS LocalCost,
	|	CASE WHEN NOT T.ReversingEntry THEN 1 ELSE -1 END * T.OffBalanceCostLocal AS OffBalanceCostLocal,
	|	CASE WHEN NOT T.ReversingEntry THEN 1 ELSE -1 END * T.CostMan AS CostMan
	|FROM
	|	AccumulationRegister.InventoryCost AS T
	|	INNER JOIN TTSelectionBalanceMediumSlip AS Filter
	|		ON T.ItemsLocationAttributes = Filter.ItemsLocationAttributes
	|		AND T.AccountingSection = Filter.AccountingSection
	|		AND T.InventoryOwnerAttribute = Filter.InventoryOwnerAttribute
	|		AND T.Organization = Filter.Organization
	|	LEFT JOIN TTSelectionIds AS IDs
	|		ON T.FinRecordID = IDs.FinRecordID
	|		AND T.Organization = IDs.Organization
	|		AND T.Period = IDs.Period
	|WHERE
	|	T.Recorder = &Ref
	|	AND (T.Count <> 0
	|		OR T.ReversingEntry
	|		OR T.BusinessOperation IN(
	|			VALUE(Enum.BusinessTransactions.GoodsValueVarianceIncome),
	|			VALUE(Enum.BusinessTransactions.GoodsValueVarianceExpenses)))
	|	AND NOT T.LotCalculation
	|	AND NOT T.CalculationOfCost
	|
	|UNION ALL
	|
	// The expense of Registered Records is storno formed by the Balance of the cost for the purposes of calculating the average sliding.
	// The arrival is storno not taken into account in the calculation of the Balance of the Registered Recorded movements, because in the presence of Registered Recorded Expense, the cost
	// of incoming Registered Recorded movements is calculated by the cost of the expenditure Registered Recorded movements.
	// If the document has only a Storno of Registered Recorded traffic, then deviations from the current Balance are calculated for such Registered Recorded traffic,
	// so the cost of storno of Registered Recorded traffic is not included in the cost of the current Balance.
	|SELECT
	|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	T.AccountingSection AS AccountingSection,
	|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	T.Organization AS Organization,
	|	UNDEFINED AS FinRecordID,
	|	UNDEFINED AS Period,
	|	-T.Count AS Count,
	|	-T.Cost AS Cost,
	|	-T.CostExcludingVAT AS CostExcludingVAT,
	|	-T.OffBalanceCost AS OffBalanceCost,
	|	-T.LocalCost AS LocalCost,
	|	-T.OffBalanceCostLocal AS OffBalanceCostLocal,
	|	-T.CostMan AS CostMan
	|FROM
	|	TTReversalDataCost AS T
	|	INNER JOIN TTSelectionBalanceMediumSlip AS Filter
	|		ON T.ItemsLocationAttributes = Filter.ItemsLocationAttributes
	|		AND T.AccountingSection = Filter.AccountingSection
	|		AND T.InventoryOwnerAttribute = Filter.InventoryOwnerAttribute
	|		AND T.Organization = Filter.Organization
	|WHERE
	|	T.RecordType = VALUE(AccumulationRecordType.Expense)	
	|
	|) AS T
	|GROUP BY
	|	T.ItemsLocationAttributes,
	|	T.AccountingSection,
	|	T.InventoryOwnerAttribute,
	|	T.Organization,
	|	T.FinRecordID,
	|	T.Period
	|
	|INDEX BY
	|	ItemsLocationAttributes
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	T.AccountingSection AS AccountingSection,
	|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	T.Organization AS Organization,
	|	T.FinRecordID AS FinRecordID,
	|	T.Period AS Period
	|INTO TTCostIdentifiers
	|FROM
	|	TTCostPriceBalance AS T
	|WHERE
	|	T.FinRecordID <> UNDEFINED
	|
	|INDEX BY
	|	ItemsLocationAttributes
	|";
	
	ReflectionParameters.TTTemplateTexts.Insert("TTCostPriceBalance", QueryText);
	
	#EndRegion
	
	#Region AddQueryTextForCalculatingCostBasedOnAverageSliding
	
	// For Registered Records on new lines of the document, the cost is determined by the Balance of the cost.
	// For Registered Records on lines that this document already had, the cost is determined by its old Registered Records.
	QueryText =
	"SELECT
	|	1 AS SourceCode,
	|	FALSE AS ThisIsReverseTransaction,
	|	&RequestFieldsBasedOnAverageMovingAverageOfSource
	|INTO TTOfRegisteredRecordedCalculationOfAverageSlip
	|FROM
	|	TTDocumentOFOperation AS T
	|	LEFT JOIN TTCostPriceBalance AS Source
	|		ON T.ItemsLocationAttributes = Source.ItemsLocationAttributes
	|		AND T.AccountingSection = Source.AccountingSection
	|		AND T.InventoryOwnerAttribute = Source.InventoryOwnerAttribute
	|		AND T.Organization = Source.Organization
	|		AND Source.FinRecordID = UNDEFINED
	|	LEFT JOIN TTCostIdentifiers AS IDs
	|		ON T.ItemsLocationAttributes = IDs.ItemsLocationAttributes
	|		AND T.AccountingSection = IDs.AccountingSection
	|		AND T.InventoryOwnerAttribute = IDs.InventoryOwnerAttribute
	|		AND T.Organization = IDs.Organization
	|		AND T.FinRecordID = IDs.FinRecordID
	|		AND T.Period = IDs.Period
	|WHERE
	|	T.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
	|		AND (T.CostDefiningMethod = VALUE(Enum.WaysToCalculateInventoryCost.ByMovingAverage)
	|			OR T.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.DisposalAtFixedCost))
	|	AND IDs.FinRecordID IS NULL
	|
	|UNION ALL
	|
	|SELECT
	|	2 AS SourceCode,
	|	FALSE AS ThisIsReverseTransaction,
	|	&RequestFieldsBasedOnAverageMovingAverageOfSource
	|FROM
	|	TTDocumentOFOperation AS T
	|	INNER JOIN TTCostPriceBalance AS Source
	|		ON T.ItemsLocationAttributes = Source.ItemsLocationAttributes
	|		AND T.AccountingSection = Source.AccountingSection
	|		AND T.InventoryOwnerAttribute = Source.InventoryOwnerAttribute
	|		AND T.Organization = Source.Organization
	|		AND T.FinRecordID = Source.FinRecordID
	|		AND T.Period = Source.Period
	|WHERE
	|	T.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
	|		AND (T.CostDefiningMethod = VALUE(Enum.WaysToCalculateInventoryCost.ByMovingAverage)
	|			OR T.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.DisposalAtFixedCost))
	|
	|UNION ALL
	|
	|SELECT
	|	3 AS SourceCode,
	|	TRUE AS ThisIsReverseTransaction,
	|	&TextOfFieldOnAverageSlidingStorno
	|FROM
	|	TTOfRegisteredRecordedReversal AS T
	|	LEFT JOIN TTCostPriceBalance AS Source
	|		ON T.ItemsLocationAttributes = Source.ItemsLocationAttributes
	|		AND T.AccountingSection = Source.AccountingSection
	|		AND T.InventoryOwnerAttribute = Source.InventoryOwnerAttribute
	|		AND T.Organization = Source.Organization
	|		AND Source.FinRecordID = UNDEFINED
	|	LEFT JOIN TTCostIdentifiers AS IDs
	|		ON T.ItemsLocationAttributes = IDs.ItemsLocationAttributes
	|		AND T.AccountingSection = IDs.AccountingSection
	|		AND T.InventoryOwnerAttribute = IDs.InventoryOwnerAttribute
	|		AND T.Organization = IDs.Organization
	|		AND T.FinRecordID = IDs.FinRecordID
	|		AND T.Period = IDs.Period
	|WHERE
	|	IDs.FinRecordID IS NULL
	|
	|UNION ALL
	|
	|SELECT
	|	4 AS SourceCode,
	|	TRUE AS ThisIsReverseTransaction,
	|	&TextOfFieldOnAverageSlidingStorno
	|FROM
	|	TTOfRegisteredRecordedReversal AS T
	|	INNER JOIN TTCostPriceBalance AS Source
	|		ON T.ItemsLocationAttributes = Source.ItemsLocationAttributes
	|		AND T.AccountingSection = Source.AccountingSection
	|		AND T.InventoryOwnerAttribute = Source.InventoryOwnerAttribute
	|		AND T.Organization = Source.Organization
	|		AND T.FinRecordID = Source.FinRecordID
	|		AND T.Period = Source.Period
	|" + "INDEX BY
	|	ItemsLocationAttributes
	|";
	
	TextOfFieldOnAverageSlidingStorno = StrReplace(TextOfFieldIsBasedOnAverageValueOfSource, "T.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.DisposalAtFixedCost)", "TRUE");
	
	QueryText = StrReplace(QueryText, "&RequestFieldsBasedOnAverageMovingAverageOfSource", StrReplace(TrimAll(TextOfFieldIsBasedOnAverageValueOfSource), "&Character", "1"));
	QueryText = StrReplace(QueryText, "&TextOfFieldOnAverageSlidingStorno", StrReplace(TrimAll(TextOfFieldOnAverageSlidingStorno), "&Character", "-1"));
	
	ReflectionParameters.TTTemplateTexts.Insert("TTOfRegisteredRecordedCalculationOfAverageSlip", QueryText);
	
	#EndRegion
	
	If ThereIsDocumentSource Then
		
	#Region AddQueryTextCostBasedOnRegisteredRecordsOfSourceDocument
	
	QueryText =
	"SELECT DISTINCT
	|	T.DocumentSource,
	|	T.CorItemsLocationAttributes AS ItemsLocationAttributes,
	|	T.CorInventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	T.Organization AS Organization
	|INTO TTSelectionDocumentsSourcesMediumSlip
	|FROM
	|	TTDocumentOFOperation AS T
	|WHERE
	|	T.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
	|	AND T.DocumentSource <> UNDEFINED
	|
	|INDEX BY
	|	DocumentSource
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Recorder AS DocumentSource,
	|	T.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	T.Organization AS Organization,
	|	&Department,
	|	&ExpenseItemOfWriteOff,
	|	&DimensionOfExpenses,
	|	SUM(T.Count) AS Count,
	|	SUM(T.Cost) AS Cost,
	|	SUM(T.CostExcludingVAT) AS CostExcludingVAT,
	|	SUM(T.OffBalanceCost) AS OffBalanceCost,
	|	SUM(T.LocalCost) AS LocalCost,
	|	SUM(T.OffBalanceCostLocal) AS OffBalanceCostLocal,
	|	SUM(T.CostMan) AS CostMan
	|INTO TTCostOfSourceDocument
	|FROM
	|	AccumulationRegister.InventoryCost AS T
	|	INNER JOIN TTSelectionDocumentsSourcesMediumSlip AS Filter
	|		ON T.Recorder = Filter.DocumentSource
	|		AND T.ItemsLocationAttributes = Filter.ItemsLocationAttributes
	|		AND T.InventoryOwnerAttribute = Filter.InventoryOwnerAttribute
	|		AND T.Organization = Filter.Organization
	|GROUP BY
	|	T.Recorder,
	|	T.ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute,
	|	T.Organization,
	|	&AccountingDimensionByPartners,
	|	&SalesOrder,
	|	&Department,
	|	&ExpenseItemOfWriteOff,
	|	&DimensionOfExpenses
	|HAVING
	|	SUM(T.Count) <> 0
	|	OR SUM(T.Cost) <> 0
	|	OR SUM(T.CostExcludingVAT) <> 0
	|	OR SUM(T.OffBalanceCost) <> 0
	|	OR SUM(T.LocalCost) <> 0
	|	OR SUM(T.OffBalanceCostLocal) <> 0
	|	OR SUM(T.CostMan) <> 0
	|
	|INDEX BY
	|	ItemsLocationAttributes
	|";
	
	If ReflectionParameters.ThereIsExpenseItemWriteOff Then
		QueryText = StrReplace(QueryText, "&ExpenseItemOfWriteOff", "T.ExpenseItemOfWriteOff");
		QueryText = StrReplace(QueryText, "&DimensionOfExpenses", "T.DimensionOfExpenses");
	Else
		QueryText = StrReplace(QueryText, "&ExpenseItemOfWriteOff", "VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)");
		QueryText = StrReplace(QueryText, "&DimensionOfExpenses", "UNDEFINED");
	EndIf;
	
	If ReflectionParameters.ThereIsAccountingAnalyticsForPartners Then
		QueryText = StrReplace(QueryText, "&AccountingDimensionByPartners", "T.AccountingDimensionByPartners");
	Else
		QueryText = StrReplace(QueryText, "&AccountingDimensionByPartners", "VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef)");
	EndIf;
	
	If ReflectionParameters.ThereIsSalesOrder Then
		QueryText = StrReplace(QueryText, "&SalesOrder", "T.SalesOrder");
	Else
		QueryText = StrReplace(QueryText, "&SalesOrder", "UNDEFINED");
	EndIf;
	
	If ReflectionParameters.ThereIsDivision Then
		QueryText = StrReplace(QueryText, "&Department", "T.Department");
	Else
		QueryText = StrReplace(QueryText, "&Department", "VALUE(Catalog.BusinessStructure.EmptyRef)");
	EndIf;
	
	ReflectionParameters.TTTemplateTexts.Insert("TTCostOfSourceDocument", QueryText);
	
	#EndRegion
	
	#Region AddQueryTextOfCostCalculationForSourceDocument
	
	QueryText =
	"SELECT
	|	&RequestFieldsBasedOnAverageMovingAverageOfSource
	|INTO TTOfRegisteredRecordedCalculationAccordingToSourceDocument
	|FROM
	|	TTDocumentOFOperation AS T
	|	LEFT JOIN TTCostOfSourceDocument AS Source
	|		ON T.DocumentSource = Source.DocumentSource
	|		AND T.CorItemsLocationAttributes = Source.ItemsLocationAttributes
	|		AND T.CorInventoryOwnerAttribute = Source.InventoryOwnerAttribute
	|		AND T.Organization = Source.Organization
	|		AND &ConnectionByAdditionalFields
	|WHERE
	|	T.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
	|		AND (T.CostDefiningMethod = VALUE(Enum.WaysToCalculateInventoryCost.BySourceDocumentRegisterRecords)
	|			OR T.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.DisposalAtFixedCost))
	|";
	
	TextConnection_ = "";
	
	SourceDocumentFields = New Structure;
	SourceDocumentFields.Insert("Department", 			 "Catalog.BusinessStructure");
	SourceDocumentFields.Insert("ExpenseItemOfWriteOff", 	 "ChartOfCharacteristicTypes.ExpenseItems");
	SourceDocumentFields.Insert("DimensionOfExpenses", 		 "UNDEFINED");
	
	For Each KeyAndValue In SourceDocumentFields Do
		
		If ReflectionParameters.RequestColumns.Property(KeyAndValue.Key) Then
			
			TypeName = KeyAndValue.Value;
			
			If TypeName = "UNDEFINED" Then
				
				TextConnection_ = TextConnection_ + ?(TextConnection_ = "", "", Chars.LF + "
					|		AND ") + "T." + KeyAndValue.Key + " = Source."+ KeyAndValue.Key;
				
			Else

				TextConnection_ = TextConnection_ + ?(TextConnection_ = "", "", Chars.LF + "
					|		AND ") + "CASE
					|  			WHEN VALUETYPE(T." + KeyAndValue.Key + ") = TYPE(" + TypeName + ")
					|				THEN T." + KeyAndValue.Key + "
					|				ELSE VALUE(" + TypeName + ".EmptyRef)
					|		END = Source."+ KeyAndValue.Key;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	QueryText = StrReplace(QueryText, "&ConnectionByAdditionalFields", ?(TextConnection_ = "", "TRUE", TrimAll(TextConnection_)));
	QueryText = StrReplace(QueryText, "&RequestFieldsBasedOnAverageMovingAverageOfSource", StrReplace(TrimAll(TextOfFieldIsBasedOnAverageValueOfSource), "&Character", "1"));
	
	ReflectionParameters.TTTemplateTexts.Insert("TTOfRegisteredRecordedCalculationAccordingToSourceDocument", QueryText);
	
	#EndRegion
	
	EndIf;

	If ThereAreDisposalsAtFixedCost Or ReflectionParameters.ThereIsReversal Then
		
	#Region AddQueryTextForCalculatingCostDeviations
	
	QueryText =
	"SELECT
	|	CASE WHEN T.Count >= 0 THEN 1 ELSE -1 END AS Character,
	|	T.ThisIsReverseTransaction,
	|	&RequestFieldsWithGrouping
	|INTO TTOfRegisteredRecordedDeviationsInCostPreliminary
	|FROM
	|	TTOfRegisteredRecordedCalculationOfAverageSlip AS T
	|WHERE
	|	(T.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.DisposalAtFixedCost)
	|		OR T.ThisIsReverseTransaction)
	// For the Accounting sections "Output" and "Work in progress", the cost is calculated at the end of the month,
	// so for these sections it is not necessary to calculate deviations when carrying out documents.
	|	AND NOT T.AccountingSection IN (
	|		VALUE(Enum.SectionsOfInventoryCostAccounting.ProductsRelease),
	|		VALUE(Enum.SectionsOfInventoryCostAccounting.WorkInProgress))
	|GROUP BY
	|	CASE WHEN T.Count >= 0 THEN 1 ELSE -1 END,
	|	T.ThisIsReverseTransaction,
	|	&GroupingRequestFields
	|";

	If ThereIsDocumentSource Then
		
		QueryText = QueryText + "
		|UNION ALL
		|";
		
		QueryText = QueryText + "
		|SELECT
		|	CASE WHEN T.Count >= 0 THEN 1 ELSE -1 END AS Character,
		|	FALSE AS ThisIsReverseTransaction,
		|	&RequestFieldsWithGrouping
		|FROM
		|	TTOfRegisteredRecordedCalculationAccordingToSourceDocument AS T
		|WHERE
		|	T.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.DisposalAtFixedCost)
		|GROUP BY
		|	CASE WHEN T.Count >= 0 THEN 1 ELSE -1 END,
		|	&GroupingRequestFields
		|";
		
	EndIf;
	
	QueryText = QueryText + "
	|INDEX BY
	|	ItemsLocationAttributes
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
	QueryText = QueryText +
	"SELECT
	// Deviations in cost are always reflected by Registering Recorded Expenses to ensure double entry with 
	// the registers "Other income" and "Other expenses". 
	|	(CASE
	|		WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt) THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE T.RecordType END) AS RecordType,
	// Deviations in cost are calculated, so the Storno feature is not set.
	|	FALSE AS ReversingEntry,
	|	FALSE AS ThisIsReverseTransaction,
	|	FALSE AS TheseAreOtherExpenses,
	|	CASE WHEN IncomeItems.Ref IS NULL
	|		THEN VALUE(ChartOfCharacteristicTypes.IncomeItems.GoodsValueVariance)
	|		ELSE IncomeItems.Ref
	|	END AS IncomeItem,
	|	CASE WHEN IncomeItems.Ref IS NULL
	|		THEN DimensionOfProductItem.Products
	|		ELSE &DimensionOfRevenue
	|	END AS DimensionOfRevenue,
	|	UNDEFINED AS ExpenseItemOfWriteOff,
	|	UNDEFINED AS DimensionOfExpenses,
	|	VALUE(Enum.BusinessTransactions.GoodsValueVarianceIncome) AS BusinessOperation,
	|	VALUE(Catalog.BusinessTransactionsSettings.GoodsValueVarianceIncome) AS BusinessTransactionSetting,
	|	CASE WHEN T.RowID IN ("""", UNDEFINED)
	|		THEN T.FinRecordID
	|		ELSE T.RowID
	|	END AS FinRecordID,
	|	CASE WHEN T.FinRecordID IN ("""", UNDEFINED)
	|		THEN T.RowID
	|		ELSE T.FinRecordID
	|	END AS RowID,
	|	&Ref AS DocumentRegisterRecords,
	|	&RevenueRequestFields
	|INTO TTOfRegisteredRecordedDeviationsInCost
	|FROM
	|	TTOfRegisteredRecordedDeviationsInCostPreliminary AS T
	|	LEFT JOIN ChartOfCharacteristicTypes.IncomeItems AS IncomeItems
	|		ON &IncomeItem = IncomeItems.Ref
	|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionOfProductItem
	|		ON T.ItemsLocationAttributes = DimensionOfProductItem.Ref
	|WHERE
	|	(&TermsOfAmountIncome)
	|
	|UNION ALL
	|
	|SELECT
	// Deviations in cost are always reflected by Registering Recorded Expenses to ensure double entry with 
	// the registers "Other income" and "Other expenses". 
	|	(CASE
	|		WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt) THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE T.RecordType END) AS RecordType,
	// Deviations in cost are calculated, so the Storno feature is not set.
	|	FALSE AS ReversingEntry,
	|	FALSE AS ThisIsReverseTransaction,
	|	TRUE AS TheseAreOtherExpenses,
	|	UNDEFINED AS IncomeItem,
	|	UNDEFINED AS DimensionOfRevenue,
	|	CASE WHEN ExpenseItems.Ref IS NULL
	|		THEN VALUE(ChartOfCharacteristicTypes.ExpenseItems.GoodsValueVariance)
	|		ELSE ExpenseItems.Ref
	|	END AS ExpenseItemOfWriteOff,
	|	CASE WHEN ExpenseItems.Ref IS NULL
	|		THEN DimensionOfProductItem.Products
	|		ELSE &DimensionOfExpenses
	|	END AS DimensionOfExpenses,
	|	VALUE(Enum.BusinessTransactions.GoodsValueVarianceExpenses) AS BusinessOperation,
	|	VALUE(Catalog.BusinessTransactionsSettings.GoodsValueVarianceExpenses) AS BusinessTransactionSetting,
	|	CASE WHEN T.RowID IN ("""", UNDEFINED)
	|		THEN T.FinRecordID
	|		ELSE T.RowID
	|	END AS FinRecordID,
	|	CASE WHEN T.FinRecordID IN ("""", UNDEFINED)
	|		THEN T.RowID
	|		ELSE T.FinRecordID
	|	END AS RowID,
	|	&Ref AS DocumentRegisterRecords,
	|	&RequestFieldsExpenses
	|FROM
	|	TTOfRegisteredRecordedDeviationsInCostPreliminary AS T
	|	LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|		ON &ExpenseItemOfWriteOff = ExpenseItems.Ref
	|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionOfProductItem
	|		ON T.ItemsLocationAttributes = DimensionOfProductItem.Ref
	|WHERE
	|	(&TermsOfAmountExpenses)
	|";
	
	If ReflectionParameters.ThereIsExpenseItemWriteOff Then
		QueryText = StrReplace(QueryText, "&ExpenseItemOfWriteOff", "T.ExpenseItemOfWriteOff");
		QueryText = StrReplace(QueryText, "&DimensionOfExpenses", "T.DimensionOfExpenses");
	Else
		QueryText = StrReplace(QueryText, "&ExpenseItemOfWriteOff", "UNDEFINED");
		QueryText = StrReplace(QueryText, "&DimensionOfExpenses", "DimensionOfProductItem.Products");
	EndIf;
	If ReflectionParameters.ThereIsIncomeItem Then
		QueryText = StrReplace(QueryText, "&IncomeItem", "T.IncomeItem");
		QueryText = StrReplace(QueryText, "&DimensionOfRevenue", "T.DimensionOfRevenue");
	Else
		QueryText = StrReplace(QueryText, "&IncomeItem", "UNDEFINED");
		QueryText = StrReplace(QueryText, "&DimensionOfRevenue", "DimensionOfProductItem.Products");
	EndIf;
	
	// List of fields used in the request
	Redefined_Fields = New Structure("IncomeItem, DimensionOfRevenue, ExpenseItemOfWriteOff, DimensionOfExpenses, DocumentRegisterRecords,
		|BusinessOperation, BusinessTransactionSetting, FinRecordID, RowID,
		|RecordType, ReversingEntry");
	
	TemplateForAmountRevenueField  = "
		|	CASE
		|		WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN CASE
		|				WHEN T.NameOfFieldAmount > 0 THEN -T.NameOfFieldAmount
		|				ELSE 0 END
		|		ELSE CASE
		|			WHEN T.Character * T.NameOfFieldAmount < 0 THEN T.NameOfFieldAmount
		|			ELSE 0 END
		|		END AS NameOfFieldAmount";
	TemplateForAmountFieldExpenses = "
		|	CASE
		|		WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN CASE
		|				WHEN T.NameOfFieldAmount < 0 THEN -T.NameOfFieldAmount
		|				ELSE 0 END
		|		ELSE CASE
		|			WHEN T.Character * T.NameOfFieldAmount > 0 THEN T.NameOfFieldAmount
		|			ELSE 0 END
		|		END AS NameOfFieldAmount";
	// Other income includes the amount of increase in cost:
	// - Register Recorded Receipt with a plus sign
	// - Registered Recorded Expense with a minus sign
	// For the Registered Records, the conditions are Storno reversed in order to reverse the previously recorded other income.
	// In addition to calculating deviations for Storno Registered Recorded Receipts, because there are no deviations when registering items and there is
	// no need to cancel other income. 
	TemplateForAmountRevenueCondition  = "
		|	CASE
		|		WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN CASE
		|				WHEN T.NameOfFieldAmount > 0 THEN -T.NameOfFieldAmount
		|				ELSE 0 END
		|		ELSE CASE
		|			WHEN T.Character * T.NameOfFieldAmount < 0 THEN T.NameOfFieldAmount
		|			ELSE 0 END
		|		END <> 0";
	// Other expenses include the amount of cost reduction:
	// - Register Recorded Arrival with a minus sign
	// - Registered Recorded Expense with a plus sign
	// The conditions for Registering Records are Storno reversed in order to cancel previously recorded other expenses.
	// In addition to calculating deviations for Storno Registered Recorded arrivals, because there are no deviations when registering goods and there is
	// no need to cancel other expenses.
	TemplateForAmountConditionExpenses = "
		|	CASE
		|		WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN CASE
		|				WHEN T.NameOfFieldAmount < 0 THEN -T.NameOfFieldAmount
		|				ELSE 0 END
		|		ELSE CASE
		|			WHEN T.Character * T.NameOfFieldAmount > 0 THEN T.NameOfFieldAmount
		|			ELSE 0 END
		|		END <> 0";
	
	RegisterDescription = CalculationOfCostCached.GenerateCaseDescription("AccumulationRegister." + ReflectionParameters.RegisterName);
	NumericFields = New Structure(StrReplace(RegisterDescription.SelectionFieldsOfNonemptyMotions, "%1", "")); // all numeric register fields
	
	TextOfRevenueRequestField = ""; // for &Field Requests
	TextOfExpensesRequestField = ""; // for &Field Requests
	TextOfRevenueRequestCondition = ""; // for &ConditiOnssuMmeeds
	RequestConditionTextExpenses = ""; // for &conditionalsummy Expenses
	
	For Each CurrentColumn In ReflectionParameters.ArrayOfRequestColumns Do
		
		If Redefined_Fields.Property(CurrentColumn) Then
			Continue;
			
		ElsIf SumFieldsOfAverageSliding.Property(CurrentColumn) Then
			
			TextOfRevenueRequestField = TextOfRevenueRequestField + ?(TextOfRevenueRequestField = "", "", ",")
				+ StrReplace(TemplateForAmountRevenueField, "NameOfFieldAmount", CurrentColumn);
			
			TextOfExpensesRequestField = TextOfExpensesRequestField + ?(TextOfExpensesRequestField = "", "", ",")
				+ StrReplace(TemplateForAmountFieldExpenses, "NameOfFieldAmount", CurrentColumn);
			
			TextOfRevenueRequestCondition = TextOfRevenueRequestCondition + ?(TextOfRevenueRequestCondition = "", "", Chars.LF + "	OR ")
				+ StrReplace(TemplateForAmountRevenueCondition, "NameOfFieldAmount", CurrentColumn);
			
			RequestConditionTextExpenses = RequestConditionTextExpenses + ?(RequestConditionTextExpenses = "", "", Chars.LF + "	OR ")
				+ StrReplace(TemplateForAmountConditionExpenses, "NameOfFieldAmount", CurrentColumn);
			
		ElsIf NumericFields.Property(CurrentColumn) Then
			
			TextOfRevenueRequestField = TextOfRevenueRequestField + ?(TextOfRevenueRequestField = "", "", ",") + "
				|	0 AS " + CurrentColumn;
			
			TextOfExpensesRequestField = TextOfExpensesRequestField + ?(TextOfExpensesRequestField = "", "", ",") + "
				|	0 AS " + CurrentColumn;
			
		Else
			
			TextOfRevenueRequestField = TextOfRevenueRequestField + ?(TextOfRevenueRequestField = "", "", ",") + "
				|	T." + CurrentColumn + " AS " + CurrentColumn;
			
			TextOfExpensesRequestField = TextOfExpensesRequestField + ?(TextOfExpensesRequestField = "", "", ",") + "
				|	T." + CurrentColumn + " AS " + CurrentColumn;
			
		EndIf;
		
	EndDo;
	
	QueryText = StrReplace(QueryText, "&RequestFieldsWithGrouping", TrimAll(TextOfRequestFieldWithDimension));
	QueryText = StrReplace(QueryText, "&GroupingRequestFields",   TrimAll(TextOfDimensionRequestField));
	QueryText = StrReplace(QueryText, "&RevenueRequestFields",    TrimAll(TextOfRevenueRequestField));
	QueryText = StrReplace(QueryText, "&RequestFieldsExpenses",   TrimAll(TextOfExpensesRequestField));
	QueryText = StrReplace(QueryText, "&TermsOfAmountIncome",   TrimAll(TextOfRevenueRequestCondition));
	QueryText = StrReplace(QueryText, "&TermsOfAmountExpenses",  TrimAll(RequestConditionTextExpenses));
	
	ReflectionParameters.TTTemplateTexts.Insert("TTOfRegisteredRecordedDeviationsInCost", QueryText);
	
	#EndRegion

	EndIf;

	#Region AddQueryTextOfRegisteredRecordWithCost

	QueryText =
	"SELECT
	|	1 AS SourceCode,
	|	FALSE AS ReversingEntry,
	|	&RequestFieldsAreBasic
	|INTO TTTotalRegisteredRecordsOfInventoryCosts
	|FROM
	|	TTDocumentOFOperation AS T
	|WHERE
	|	T.InventoryValuationMethod <> VALUE(Enum.InventoryValuationMethods.MovingAverage)
	|	OR T.CostDefiningMethod = VALUE(Enum.WaysToCalculateInventoryCost.FromDocument)
	|	OR T.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.DisposalAtFixedCost)
	|
	|UNION ALL
	|
	|SELECT
	|	2 AS SourceCode,
	|	T.ThisIsReverseTransaction AS ReversingEntry,
	|	&RequestFieldsAreBasic
	|FROM
	|	TTOfRegisteredRecordedCalculationOfAverageSlip AS T
	|WHERE
	|	T.CostDefiningMethod = VALUE(Enum.WaysToCalculateInventoryCost.ByMovingAverage)
	|	AND T.BusinessOperation <> VALUE(Enum.BusinessTransactions.ExpensingToProductionLots)
	|	AND NOT T.ThisIsReverseTransaction
	|
	|UNION ALL
	|
	|SELECT
	|	3 AS SourceCode,
	|	Amounts.ThisIsReverseTransaction AS ReversingEntry,
	|	&FieldsOfAverageSlipSamplingQuery
	|FROM
	|	TTDocumentOFOperation AS T
	|	LEFT JOIN TTOfRegisteredRecordedCalculationOfAverageSlip AS Amounts
	|		ON T.Organization = &OrganizationConditions
	|		AND T.FinRecordID = Amounts.FinRecordID
	|		AND T.BusinessTransactionSetting = Amounts.BusinessTransactionSetting
	|		AND T.Period = Amounts.Period
	|		AND NOT Amounts.ThisIsReverseTransaction
	|WHERE
	|	T.CostDefiningMethod = VALUE(Enum.WaysToCalculateInventoryCost.ByCorRecord)
	|
	|UNION ALL
	|
	|SELECT
	|	4 AS SourceCode,
	|	Amounts.ThisIsReverseTransaction AS ReversingEntry,
	|	&FieldsOfAverageSlipSamplingQuery
	|FROM
	|	TTOfRegisteredRecordedCalculationOfAverageSlip AS T
	|	LEFT JOIN TTOfRegisteredRecordedCalculationOfAverageSlip AS Amounts
	|		ON T.Organization = T.Organization
	|		AND T.ItemsLocationAttributes = Amounts.CorItemsLocationAttributes
	|		AND T.InventoryOwnerAttribute = Amounts.CorInventoryOwnerAttribute
	|		AND T.AccountingSection = Amounts.CorAccountingSection
	|		AND NOT Amounts.ThisIsReverseTransaction
	|WHERE
	|	T.CostDefiningMethod = VALUE(Enum.WaysToCalculateInventoryCost.ByMovingAverage)
	|	AND T.BusinessOperation = VALUE(Enum.BusinessTransactions.ExpensingToProductionLots)
	|	AND NOT T.ThisIsReverseTransaction
	|";
	
	If ReflectionParameters.ThereIsCorOrganization Then
		QueryText = StrReplace(QueryText, "&OrganizationConditions", 
			"(CASE WHEN Amounts.CorCompany <> VALUE(Catalog.Companies.EmptyRef)
				|	THEN Amounts.CorCompany ELSE Amounts.Organization END)");
	Else
		QueryText = StrReplace(QueryText, "&OrganizationConditions", "Amounts.Organization");
	EndIf;
	
	If ThereIsDocumentSource Then
		
		QueryText = QueryText  + "
		|UNION ALL
		|";
		
		QueryText = QueryText  + "
		|SELECT
		|	4 AS SourceCode,
		|	FALSE AS ReversingEntry,
		|	&RequestFieldsAreBasic
		|FROM
		|	TTOfRegisteredRecordedCalculationAccordingToSourceDocument AS T
		|WHERE
		|	T.CostDefiningMethod = VALUE(Enum.WaysToCalculateInventoryCost.BySourceDocumentRegisterRecords)
		|";
		
	EndIf;
	
	If ThereAreDisposalsAtFixedCost Or ReflectionParameters.ThereIsReversal Then
		
		QueryText = QueryText  + "
		|UNION ALL
		|";
		
		QueryText = QueryText  + "
		|SELECT
		|	5 AS SourceCode,
		|	T.ThisIsReverseTransaction AS ReversingEntry,
		|	&RequestFieldsAreBasic
		|FROM
		|	TTOfRegisteredRecordedDeviationsInCost AS T
		|";
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "&RequestFieldsAreBasic", TrimAll(TextOfFieldIsBasicOnMediumSlip));
	QueryText = StrReplace(QueryText, "&FieldsOfAverageSlipSamplingQuery", TrimAll(TextOfFieldIsMediumSlipSelection));
	
	ReflectionParameters.TTTemplateTexts.Insert("TTTotalRegisteredRecordsOfInventoryCosts", QueryText);
	
	QueryText =
	"SELECT
	|	T.ReversingEntry,
	|	&RequestFieldsAreBasic
	|FROM
	|	TTTotalRegisteredRecordsOfInventoryCosts AS T
	|";

	QueryText = StrReplace(QueryText, "&RequestFieldsAreBasic", TrimAll(TextOfFieldIsBasicOnMediumSlip));
	
	ReflectionParameters.ReflectionTemplateTexts.Insert(ReflectionParameters.RegisterName, QueryText);
		
	#EndRegion
	
EndProcedure

Procedure AddQueryTextOfRegisteredRecordsRevenueAndCostOfGoodsSold(ReflectionParameters)
	
	// We check whether the document has the Query Text of the revenue register
	QueryIndex = -1;
	OldRequestText = "";
	RegisterName = Metadata.AccumulationRegisters.RevenueAndCOGS.Name;
	
	For Each ListItem In ReflectionParameters.QueryTexts Do

		QueryIndex = QueryIndex + 1;
		If ListItem.Presentation = RegisterName Then
			OldRequestText = ListItem.Value;
			Break;
		EndIf;
		
	EndDo;
	
	If IsBlankString(OldRequestText) Then
		Return; // no RegisteredRecorded revenue
	EndIf;
	
	// Replacing the old query selection with a new query to create a temporary table of movementsreferences
	QueryDetails = CalculationOfCostCached.RequestToGenerateTTFromSelectionRequest(OldRequestText, "RevenueAndCostRegisterRecords");
	
	NewRequestText = QueryDetails.QueryText + "
	|INDEX BY
	|	FinRecordID,
	|	BusinessTransactionSetting";
	
	ReflectionParameters.QueryTexts[QueryIndex].Value = NewRequestText;
	ReflectionParameters.QueryTexts[QueryIndex].Presentation = "RevenueAndCostRegisterRecords";
	
	// Creation of an auxiliary table in the cost of the average sliding for the handle - the amount of the average sliding from the cost
	QueryText = 
	"SELECT
	|	T.Organization,
	|   T.FinRecordID,
	|   T.BusinessTransactionSetting,
	|   SUM(CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt) THEN -1 ELSE 1 END * T.Cost) AS Cost,
	|   SUM(CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt) THEN -1 ELSE 1 END * T.CostExcludingVAT) AS CostExcludingVAT,
	|   SUM(CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt) THEN -1 ELSE 1 END * T.LocalCost) AS LocalCost,
	|   SUM(CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt) THEN -1 ELSE 1 END * T.CostMan) AS CostMan,
	|   SUM(CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt) THEN -1 ELSE 1 END * T.OffBalanceCost) AS OffBalanceCost,
	|   SUM(CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt) THEN -1 ELSE 1 END * T.OffBalanceCostLocal) AS OffBalanceCostLocal
	|INTO CostOfTTIsMediumSlidingForRevenue
	|FROM
	|	TTTotalRegisteredRecordsOfInventoryCosts AS T
	|WHERE
	|	T.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
	|	AND T.CostDefiningMethod IN
	|		(VALUE(Enum.WaysToCalculateInventoryCost.ByMovingAverage),
	|		 VALUE(Enum.WaysToCalculateInventoryCost.BySourceDocumentRegisterRecords))
	|GROUP BY
	|	T.Organization,
	|   T.FinRecordID,
	|   T.BusinessTransactionSetting
	|
	|INDEX BY
	|	FinRecordID,
	|	BusinessTransactionSetting
	|";
	
	ReflectionParameters.TTTemplateTexts.Insert("CostOfTTIsMediumSlidingForRevenue", QueryText);
	
	// Creating a final data sample request for the revenue register
	// If the amounts of the average sliding resource are already filled in in the original request for a sample of data for revenue,
	// then we will leave them, otherwise we will take them from the table with the average Sliding cost for the handle
	QueryText = 
	"SELECT
	|	&RevenueFields
	|FROM
	|	RevenueAndCostRegisterRecords AS T
	|	LEFT JOIN CostOfTTIsMediumSlidingForRevenue AS Amounts
	|		ON T.AccountingDimensionByPartners.Organization = Amounts.Organization
	|		AND T.FinRecordID = Amounts.FinRecordID
	|		AND T.BusinessTransactionSetting = Amounts.BusinessTransactionSetting
	|";
	
	PossibleSumFields = New Structure(SumFieldsOfAverageSliding());
	MissingSumFields = New Structure(SumFieldsOfAverageSliding());
	TextOfRevenueField = "";
	
	For Each FieldName In QueryDetails.Columns Do
		
		If PossibleSumFields.Property(FieldName) Then
			
			MissingSumFields.Delete(FieldName);
			
			TextOfRevenueField = TextOfRevenueField + ?(TextOfRevenueField = "", "", ",
				|	") + "CASE WHEN T." + FieldName + " <> 0 THEN T." + FieldName
				+ " ELSE ISNULL(Amounts." + FieldName + ", 0) END AS " + FieldName;
			
		Else
			TextOfRevenueField = TextOfRevenueField + ?(TextOfRevenueField = "", "", ",
				|	") + "T." + FieldName + " AS " + FieldName;
		EndIf;
		
	EndDo;
	
	For Each KeyAndValue In MissingSumFields Do
		// Adding mid-moving resources that were not included in the original request for data collection for revenue
		TextOfRevenueField = TextOfRevenueField + ?(TextOfRevenueField = "", "", ",
			|	") + "ISNULL(Amounts." + KeyAndValue.Key + ", 0) AS " + KeyAndValue.Key;
		
	EndDo;
	
	QueryText = StrReplace(QueryText, "&RevenueFields", TextOfRevenueField);
	
	ReflectionParameters.ReflectionTemplateTexts.Insert(RegisterName, QueryText);
	
EndProcedure

Procedure AddQueryTextOfRegisteredRecordsOfOtherExpenses(ReflectionParameters)
	
	If Not (ReflectionParameters.ThereIsExpenseItemWriteOff Or ReflectionParameters.ThereIsReversal) Then
		Return;
	EndIf;
	
	#Region CheckingDocumentType
	
	AcceptableDocuments = New Array;

	AcceptableDocuments.Add(Metadata.Documents.OBEntryGoods);
	AcceptableDocuments.Add(Metadata.Documents.InventoryConsumption);
	AcceptableDocuments.Add(Metadata.Documents.ReturnOfGoodsToVendor);
	AcceptableDocuments.Add(Metadata.Documents.WriteOffReportFromCommissionAgent);
	AcceptableDocuments.Add(Metadata.Documents.ReportOnVMIAdjustment);
	AcceptableDocuments.Add(Metadata.Documents.WriteOffOfShippedGoods);
	AcceptableDocuments.Add(Metadata.Documents.CommissionWriteOffReportIntercompany);
	AcceptableDocuments.Add(Metadata.Documents.CustomerInvoiceIntercompany);
	AcceptableDocuments.Add(Metadata.Documents.IntercompanyGoodsReturn);
	AcceptableDocuments.Add(Metadata.Documents.OtherGoodsRecordingAsReceived);
	AcceptableDocuments.Add(Metadata.Documents.WriteOffOfGoodsShortages);
	AcceptableDocuments.Add(Metadata.Documents.GoodsMisgrading);
	AcceptableDocuments.Add(Metadata.Documents.MisgradingOfGoodsAtCustodian);
	AcceptableDocuments.Add(Metadata.Documents.GoodsDamage);
	AcceptableDocuments.Add(Metadata.Documents.DamageAtCustodian);
	AcceptableDocuments.Add(Metadata.Documents.ReversingEntry);
	AcceptableDocuments.Add(Metadata.Documents.SubcontractorReport2_5);
	AcceptableDocuments.Add(Metadata.Documents.BackflushProduction);
	AcceptableDocuments.Add(Metadata.Documents.ProductionCostAllocation);
	
	
	AcceptableDocuments.Add(Metadata.Documents.ReportToMaterialProvider2_5);
	AcceptableDocuments.Add(Metadata.Documents.ConsumptionReportSubcontractingServicesDeliveredIntercompany);
	AcceptableDocuments.Add(Metadata.Documents.ProductionStage2_2);
	If AcceptableDocuments.Find(ReflectionParameters.MetadataOfDocument) = Undefined Then
		Return;
	EndIf;
	
	#EndRegion
	
	#Region TTInitialOtherExpenses
	
	QueryTextTemplate2 =
	"SELECT
	|	T.Period 										AS Period,
	|	VALUE(AccumulationRecordType.Receipt) 			AS RecordType,
	|	ISNULL(OrganizationCor.Ref, T.Organization) 	AS Organization,
	|	&Department 									AS Department,
	|	T.ExpenseItemOfWriteOff 						AS ExpenseItem,
	|	T.DimensionOfExpenses 							AS DimensionOfExpenses,
	|	&LineOfBusiness 						AS LineOfBusiness,
	|	UNDEFINED 									AS VATActivityType,
	|	T.BusinessOperation 		 				AS BusinessOperation,
	|	T.ItemsLocationAttributes 	 				AS ItemsLocationAttributes,
	|	T.FinRecordID 		 				AS FinRecordID,
	|	T.BusinessTransactionSetting 				AS BusinessTransactionSetting,
	|
	|	CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt) THEN -1 ELSE 1 END * T.Cost 				AS AmountIncludingVAT,
	|	CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt) THEN -1 ELSE 1 END * T.CostExcludingVAT 			AS AmountExcludingVAT,
	// When transferring goods to another organization, the Local and upr. amounts are not filled in when the type of source's Registered Records is incoming - we change the sign of the Registered Records (since the Registered Records contain resources with a positive sign and the type of Registered Records arrival).
	|	CASE
	|		WHEN NOT OrganizationCor.Ref IS NULL
	|		THEN 0
	|		WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN -1
	|		ELSE 1
	|	END * T.CostMan AS AmountExcludingVATMan,
	|	CASE
	|		WHEN NOT OrganizationCor.Ref IS NULL
	|		THEN 0
	|		WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN -1
	|		ELSE 1
	|	END * T.LocalCost AS AmountIncludingVATCompl,
	|	CASE
	|		WHEN NOT OrganizationCor.Ref IS NULL
	|		THEN 0
	|		WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		THEN -1
	|		ELSE 1
	|	END * T.LocalCost AS AmountExcludingVATCompl,
	|	0 							AS PermanentDifference,
	|	0 							AS CostTD
	|INTO TTInitialOtherExpensesMediumSlip
	|FROM
	|	NameOfOtherExpensesDataTable AS T
	|	INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|		ON T.ExpenseItemOfWriteOff = ExpenseItems.Ref
	|	LEFT JOIN Catalog.Companies AS OrganizationCor
	|		ON &CorCompany = OrganizationCor.Ref
	|WHERE
	|	T.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
	|	AND (T.Cost <> 0
	|		OR T.CostExcludingVAT <> 0
	|		OR (OrganizationCor.Ref IS NULL
	|			 AND (T.LocalCost <> 0 OR T.CostMan <> 0)
	|			 )
	|	  )
	|	AND &FilterCriterion
	|";
	
	If ReflectionParameters.ThereIsCorLineOfBusiness Then
		QueryTextTemplate2 = StrReplace(QueryTextTemplate2, "&LineOfBusiness", "T.CorLineOfBusiness");
	Else
		QueryTextTemplate2 = StrReplace(QueryTextTemplate2, "&LineOfBusiness", "UNDEFINED");
	EndIf;
	If ReflectionParameters.ThereIsDivision Then
		QueryTextTemplate2 = StrReplace(QueryTextTemplate2, "&Department", "T.Department");
	Else
		QueryTextTemplate2 = StrReplace(QueryTextTemplate2, "&Department", "UNDEFINED");
	EndIf;
	If ReflectionParameters.ThereIsCorOrganization Then
		QueryTextTemplate2 = StrReplace(QueryTextTemplate2, "&CorCompany", "T.CorCompany");
	Else
		QueryTextTemplate2 = StrReplace(QueryTextTemplate2, "&CorCompany", "UNDEFINED");
	EndIf;
	
	//TTOfRegisteredRecordedCalculationOfAverageSlip
	QueryText = StrReplace(QueryTextTemplate2, "NameOfOtherExpensesDataTable", "TTOfRegisteredRecordedCalculationOfAverageSlip");
	QueryText = StrReplace(QueryText, "&FilterCriterion",
		"T.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.RecogniseAsExpensesAssets)");

	//TTOfRegisteredRecordedCalculationAccordingToSourceDocument
	If ReflectionParameters.ThereIsDocumentSource Then

		QueryText = QueryText + "
			|
			|UNION ALL
			|
			|" + StrReplace(QueryTextTemplate2, "INTO TTInitialOtherExpensesMediumSlip", "");
		
		QueryText = StrReplace(QueryText, "NameOfOtherExpensesDataTable", "TTOfRegisteredRecordedCalculationAccordingToSourceDocument");
		QueryText = StrReplace(QueryText, "&FilterCriterion",
			"T.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.RecogniseAsExpensesAssets)");
		
	EndIf;
	
	//TTOfRegisteredRecordedDeviationsInCost
	If ReflectionParameters.ThereAreDisposalsAtFixedCost Or ReflectionParameters.ThereIsReversal Then

		QueryText = QueryText + "
			|
			|UNION ALL
			|
			|" + StrReplace(QueryTextTemplate2, "INTO TTInitialOtherExpensesMediumSlip", "");
		
		QueryText = StrReplace(QueryText, "NameOfOtherExpensesDataTable", "TTOfRegisteredRecordedDeviationsInCost");
		QueryText = StrReplace(QueryText, "&FilterCriterion", "TRUE");
		
	EndIf;
	
	// TTInitialOtherExpensesMediumSlip
	ReflectionParameters.TTTemplateTexts.Insert("TTInitialOtherExpensesMediumSlip", QueryText);
	
	#EndRegion
	
	#Region FormationOfRegisteredRecords
	
	// In the queries generated in the Other Expenses register manager module, the names of the temporary tables used must be replaced.
	// If this is not done, then if the document itself RegistersRecorded in the Other Expenses register, an error of the form "The table already exists" will occur.
	
	// Vtprochier expenditure Medium-slip
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_(,
		ReflectionParameters.DifferentPeriodsInRegisteredRecordsArePossible); // uses in-the-way expenses, generates in-the-way expenses
	
	TemporaryTable = CalculationOfCostCached.QueryTempTables(QueryText);
	
	QueryText = StrReplace(QueryText, "TTInitialOtherExpenses", "TTInitialOtherExpensesMediumSlip");
	
	For Each ListItem In TemporaryTable Do
		QueryText = StrReplace(QueryText, ListItem.Presentation, ListItem.Presentation + "MovingAverage");
	EndDo;
	
	ReflectionParameters.TTTemplateTexts.Insert("TTOtherExpenses_" + "MovingAverage", QueryText);

	// Cor. of Registered Records for other expenses
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses(,
		ReflectionParameters.DifferentPeriodsInRegisteredRecordsArePossible); // uses vtprochieraextensions, generates a selection of Registered Records

	TemporaryTable = CalculationOfCostCached.QueryTempTables(QueryText);
	
	QueryText = StrReplace(QueryText, "TTOtherExpenses_", "TTOtherExpenses_" + "MovingAverage");

	For Each ListItem In TemporaryTable Do
		QueryText = StrReplace(QueryText, ListItem.Presentation, ListItem.Presentation + "_" + "1");
	EndDo;
	
	ReflectionParameters.ReflectionTemplateTexts.Insert(Metadata.AccumulationRegisters.OtherExpenses.Name, QueryText);
	
	#EndRegion
	
EndProcedure

Procedure AddQueryTextOfRegisteredRecordsOtherIncome(ReflectionParameters)
	
	If Not (ReflectionParameters.ThereAreDisposalsAtFixedCost Or ReflectionParameters.ThereIsReversal) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	T.Period 								AS Period,
	|	T.Organization 							AS Organization,
	|	&Department 							AS Department,
	|	T.IncomeItem 						AS IncomeItem,
	|	T.DimensionOfRevenue 						AS DimensionOfRevenue,
	|	&LineOfBusiness 				AS LineOfBusiness,
	|	T.BusinessOperation 		 		AS BusinessOperation,
	|	T.FinRecordID 		 		AS FinRecordID,
	|	T.BusinessTransactionSetting 		AS BusinessTransactionSetting,
	|
	|	CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt) THEN 1 ELSE -1 END * T.Cost 							AS Sum,
	|	CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt) THEN 1 ELSE -1 END * T.LocalCost 						AS SumCompl,
	|	CASE WHEN T.RecordType = VALUE(AccumulationRecordType.Receipt) THEN 1 ELSE -1 END * T.CostMan 							AS SumMan
	|FROM
	|	TTOfRegisteredRecordedDeviationsInCost AS T
	|	INNER JOIN ChartOfCharacteristicTypes.IncomeItems AS IncomeItems
	|		ON T.IncomeItem = IncomeItems.Ref
	|WHERE
	|	T.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
	|	AND (T.Cost <> 0 OR T.LocalCost <> 0 OR T.CostMan <> 0)
	|";
	
	If ReflectionParameters.ThereIsCorLineOfBusiness Then
		QueryText = StrReplace(QueryText, "&LineOfBusiness", "T.CorLineOfBusiness");
	Else
		QueryText = StrReplace(QueryText, "&LineOfBusiness", "UNDEFINED");
	EndIf;
	
	If ReflectionParameters.ThereIsDivision Then
		QueryText = StrReplace(QueryText, "&Department", "T.Department");
	Else
		QueryText = StrReplace(QueryText, "&Department", "UNDEFINED");
	EndIf;
	
	ReflectionParameters.ReflectionTemplateTexts.Insert(Metadata.AccumulationRegisters.OtherIncome.Name, QueryText);
	
EndProcedure

Procedure AddQueryTextOfRegisteredRecordsCorOtherAssetsLiabilities(ReflectionParameters)
	
	If Not ReflectionParameters.ThereIsItemOfAssetsLiabilities Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	T.Period 								AS Period,
	|	VALUE(AccumulationRecordType.Receipt) 	AS RecordType,
	|	T.Organization 							AS Organization,
	|	&Department 							AS Department,
	|	T.AssetAndLiabilityItem 				AS AssetRef,
	|	T.AssetsLiabilitiesDimension 				AS Dimension,
	|	&LineOfBusiness 				AS LineOfBusiness,
	|	T.Cost 							AS Sum
	|FROM
	|	TTOfRegisteredRecordedCalculationOfAverageSlip AS T
	|	INNER JOIN ChartOfCharacteristicTypes.AssetLiabilityItems AS AssetLiabilityItems
	|		ON T.AssetAndLiabilityItem = AssetLiabilityItems.Ref
	|WHERE
	|	T.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.RecogniseAsExpensesAssets)
	|	AND T.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
	|	AND T.Cost <> 0
	|";
	
	If ReflectionParameters.ThereIsDocumentSource Then
		
		QueryText = QueryText + "
		|
		|UNION ALL
		|
		|" + StrReplace(QueryText, "TTOfRegisteredRecordedCalculationOfAverageSlip", "TTOfRegisteredRecordedCalculationAccordingToSourceDocument");
		
	EndIf;
	
	If ReflectionParameters.ThereIsCorLineOfBusiness Then
		QueryText = StrReplace(QueryText, "&LineOfBusiness", "T.CorLineOfBusiness");
	Else
		QueryText = StrReplace(QueryText, "&LineOfBusiness", "UNDEFINED");
	EndIf;
	
	If ReflectionParameters.ThereIsDivision Then
		QueryText = StrReplace(QueryText, "&Department", "T.Department");
	Else
		QueryText = StrReplace(QueryText, "&Department", "UNDEFINED");
	EndIf;
	
	ReflectionParameters.ReflectionTemplateTexts.Insert(Metadata.AccumulationRegisters.OtherAssetsLiabilities.Name, QueryText);
	
EndProcedure

Procedure AddQueryTextOfRegisteredRecordsForOtherAssetsLiabilities(ReflectionParameters)
	
	If Not ReflectionParameters.ThereIsItemOfAssetsLiabilities And Not ReflectionParameters.ThereIsCorOrganization Then
		Return;
	EndIf;
	
	QueryText = "";
	
	If ReflectionParameters.ThereIsItemOfAssetsLiabilities Then
		
		QueryText =
		"SELECT
		|	T.Period 								AS Period,
		|	T.Organization 							AS Organization,
		|	&Department 							AS Department,
		|	T.AssetAndLiabilityItem 				AS AssetRef,
		|	T.AssetsLiabilitiesDimension 				AS Dimension,
		|	&LineOfBusiness 				AS LineOfBusiness,
		|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
		|	&GLAccountSettings 					AS GLAccountSettings,
		|	T.FinRecordID 		 		AS FinRecordID,
		|	T.BusinessTransactionSetting 		AS BusinessTransactionSetting,
		|
		|	T.Cost 							AS AmountIncludingVAT,
		|	T.CostExcludingVAT 						AS AmountExcludingVAT,
		|	T.LocalCost 						AS SumCompl,
		|	T.CostMan 							AS SumMan
		|FROM
		|	TTOfRegisteredRecordedCalculationOfAverageSlip AS T
		|	INNER JOIN ChartOfCharacteristicTypes.AssetLiabilityItems AS AssetLiabilityItems
		|		ON T.AssetAndLiabilityItem = AssetLiabilityItems.Ref
		|WHERE
		|	T.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.RecogniseAsExpensesAssets)
		|	AND T.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|	AND (T.Cost <> 0 OR T.CostExcludingVAT <> 0 OR T.LocalCost <> 0 OR T.CostMan <> 0)
		|";
		
		If ReflectionParameters.ThereIsDocumentSource Then
			
			QueryText = QueryText + "
			|
			|UNION ALL
			|
			|" + StrReplace(QueryText, "TTOfRegisteredRecordedCalculationOfAverageSlip", "TTOfRegisteredRecordedCalculationAccordingToSourceDocument");
			
		EndIf;
		
	EndIf;

	If ReflectionParameters.ThereIsCorOrganization Then
		
		// With a valuation method other than the average sliding Registered Records are formed when calculating the cost
		// in the method of calculating the cost of cost correction.To form a movementprochim activationampassivesquery()
		QueryText = QueryText + ?(QueryText = "", "", "
			|
			|UNION ALL
			|") + "
			// Transfer to a branch (on the sender's side)
			|SELECT
			|	T.Period 								AS Period,
			|	T.Organization 							AS Organization,
			|	&Department 							AS Department,
			|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.BranchOfficeARAPAccounting) AS AssetRef,
			|	T.CorCompany 						AS Dimension,
			|	&LineOfBusiness 				AS LineOfBusiness,
			|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
			|	&GLAccountSettings 					AS GLAccountSettings,
			|	T.FinRecordID 		 		AS FinRecordID,
			|	T.BusinessTransactionSetting 		AS BusinessTransactionSetting,
			|
			|	T.Cost 							AS AmountIncludingVAT,
			|	T.CostExcludingVAT 						AS AmountExcludingVAT,
			|	T.LocalCost 						AS SumCompl,
			|	T.CostMan 							AS SumMan
			|FROM
			|	TTOfRegisteredRecordedCalculationOfAverageSlip AS T
			|WHERE
			|	T.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
			|	AND T.BusinessOperation IN (
			|		VALUE(Enum.BusinessTransactions.TransferOfGoodsBetweenBranchOffices),
			|		VALUE(Enum.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices),
			|		VALUE(Enum.BusinessTransactions.WorkAcceptanceAndTransferBetweenBranchOffices))
			|	AND (T.Cost <> 0 OR T.CostExcludingVAT <> 0 OR T.LocalCost <> 0 OR T.CostMan <> 0)
			|
			|UNION ALL
			|
			// Transfer to a branch (on the recipient's side)
			|SELECT
			|	T.Period 								AS Period,
			|	T.CorCompany						AS Organization,
			|	&Department 							AS Department,
			|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.BranchOfficeARAPAccounting) AS AssetRef,
			|	T.Organization	 						AS Dimension,
			|	&LineOfBusiness 				AS LineOfBusiness,
			|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit) AS DebitCredit,
			|	&GLAccountSettings 					AS GLAccountSettings,
			|	T.FinRecordID 		 		AS FinRecordID,
			|	T.BusinessTransactionSetting 		AS BusinessTransactionSetting,
			|
			|	T.Cost 							AS AmountIncludingVAT,
			|	T.CostExcludingVAT 						AS AmountExcludingVAT,
			|	T.LocalCost 						AS SumCompl,
			|	T.CostMan 							AS SumMan
			|FROM
			|	TTOfRegisteredRecordedCalculationOfAverageSlip AS T
			|WHERE
			|	T.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
			|	AND T.BusinessOperation IN (
			|		VALUE(Enum.BusinessTransactions.TransferOfGoodsBetweenBranchOffices),
			|		VALUE(Enum.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices),
			|		VALUE(Enum.BusinessTransactions.WorkAcceptanceAndTransferBetweenBranchOffices))
			|	AND (T.Cost <> 0 OR T.CostExcludingVAT <> 0 OR T.LocalCost <> 0 OR T.CostMan <> 0)
			|";
		
	EndIf;
	
	If ReflectionParameters.ThereIsCorLineOfBusiness Then
		QueryText = StrReplace(QueryText, "&LineOfBusiness", "T.CorLineOfBusiness");
	Else
		QueryText = StrReplace(QueryText, "&LineOfBusiness", "UNDEFINED");
	EndIf;
	
	If ReflectionParameters.ThereIsSetupOfAccountingAccounts Then
		QueryText = StrReplace(QueryText, "&GLAccountSettings", "T.GLAccountSettings");
	Else
		QueryText = StrReplace(QueryText, "&GLAccountSettings", "UNDEFINED");
	EndIf;
	
	If ReflectionParameters.ThereIsDivision Then
		QueryText = StrReplace(QueryText, "&Department", "T.Department");
	Else
		QueryText = StrReplace(QueryText, "&Department", "UNDEFINED");
	EndIf;
	
	ReflectionParameters.ReflectionTemplateTexts.Insert(Metadata.AccumulationRegisters.OtherAssetsAndLiabilitiesRecords.Name, TrimAll(QueryText));
	
EndProcedure

Procedure AddQueryTextOfRegisteredRecordsItemIncomeExpenses(ReflectionParameters)
	
	QueryTextTemplate2 =
	"SELECT
	|	T.Period 										AS Period,
	|	T.Organization 									AS Organization,
	|	&Department 									AS Department,
	|	T.BusinessOperation 		 				AS BusinessOperation,
	|	T.ItemsLocationAttributes 	 				AS ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute 	 								AS InventoryOwnerAttribute,
	|	InventoryKinds.InventoryType 	 						AS InventoryType,
	|	&LineOfBusiness 						AS LineOfBusinessItems,
	|	&DimensionOfExpenses 	 							AS DimensionOfExpenses,
	|	&DimensionOfRevenue 	 							AS DimensionOfRevenue,
	|	&AssetsLiabilitiesDimension 	 					AS AssetsLiabilitiesDimension,
	|
	|	DimensionOfProductItem.Purpose.LineOfBusiness AS ProductLineOfBusiness,
	|	CASE WHEN DimensionOfProductItem.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
	|		THEN DimensionOfProductItem.Contract.Partner
	|		ELSE DimensionOfProductItem.StorageLocation
	|	END AS Warehouse,
	|	CASE
	|		WHEN VALUETYPE(&ExpenseItemOfWriteOff) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|	  	  AND &ExpenseItemOfWriteOff <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			THEN &ExpenseItemOfWriteOff
	|		WHEN VALUETYPE(&IncomeItem) = TYPE(ChartOfCharacteristicTypes.IncomeItems)
	|	  	  AND &IncomeItem <> VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef)
	|			THEN &IncomeItem
	|			ELSE &AssetAndLiabilityItem
	|	END AS IncomeAndExpenseItem,
	|	CASE
	|		WHEN DimensionOfProductItem.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN DimensionOfProductItem.Products
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN T.InventoryOwnerAttribute
	|			ELSE DimensionOfProductItem.Products
	|	END AS SourceOfProductFinancialAccountingGroup,
	|
	|	T.Cost 			AS Cost,
	|	T.CostExcludingVAT 		AS CostExcludingVAT,
	|	T.LocalCost 		AS LocalCost,
	|	T.CostMan 			AS CostMan
	|FROM
	|	NameOfDataTableIncomeExpenses AS T
	|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionOfProductItem
	|		ON T.ItemsLocationAttributes = DimensionOfProductItem.Ref
	|	LEFT JOIN Catalog.InventoryKinds AS InventoryKinds
	|		ON T.InventoryOwnerAttribute = InventoryKinds.Ref
	|WHERE
	|	T.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
	|	AND (T.Cost <> 0 OR T.CostExcludingVAT <> 0 OR T.LocalCost <> 0 OR T.CostMan <> 0)
	|	AND &FilterCriterion
	|";
	
	If ReflectionParameters.ThereIsCorLineOfBusiness Then
		QueryTextTemplate2 = StrReplace(QueryTextTemplate2, "&LineOfBusiness", "T.CorLineOfBusiness");
	Else
		QueryTextTemplate2 = StrReplace(QueryTextTemplate2, "&LineOfBusiness", "UNDEFINED");
	EndIf;
	
	If ReflectionParameters.ThereIsExpenseItemWriteOff Then
		QueryTextTemplate2 = StrReplace(QueryTextTemplate2, "&ExpenseItemOfWriteOff", "T.ExpenseItemOfWriteOff");
		QueryTextTemplate2 = StrReplace(QueryTextTemplate2, "&DimensionOfExpenses", "T.DimensionOfExpenses");
	Else
		QueryTextTemplate2 = StrReplace(QueryTextTemplate2, "&ExpenseItemOfWriteOff", "UNDEFINED");
		QueryTextTemplate2 = StrReplace(QueryTextTemplate2, "&DimensionOfExpenses", "UNDEFINED");
	EndIf;
	
	If ReflectionParameters.ThereIsIncomeItem Then
		QueryTextTemplate2 = StrReplace(QueryTextTemplate2, "&IncomeItem", "T.IncomeItem");
		QueryTextTemplate2 = StrReplace(QueryTextTemplate2, "&DimensionOfRevenue", "T.DimensionOfRevenue");
	Else
		QueryTextTemplate2 = StrReplace(QueryTextTemplate2, "&IncomeItem", "UNDEFINED");
		QueryTextTemplate2 = StrReplace(QueryTextTemplate2, "&DimensionOfRevenue", "UNDEFINED");
	EndIf;
	
	If ReflectionParameters.ThereIsItemOfAssetsLiabilities Then
		QueryTextTemplate2 = StrReplace(QueryTextTemplate2, "&AssetAndLiabilityItem", "T.AssetAndLiabilityItem");
		QueryTextTemplate2 = StrReplace(QueryTextTemplate2, "&AssetsLiabilitiesDimension", "T.AssetsLiabilitiesDimension");
	Else
		QueryTextTemplate2 = StrReplace(QueryTextTemplate2, "&AssetAndLiabilityItem", "UNDEFINED");
		QueryTextTemplate2 = StrReplace(QueryTextTemplate2, "&AssetsLiabilitiesDimension", "UNDEFINED");
	EndIf;
	
	If ReflectionParameters.ThereIsDivision Then
		QueryTextTemplate2 = StrReplace(QueryTextTemplate2, "&Department", "T.Department");
	Else
		QueryTextTemplate2 = StrReplace(QueryTextTemplate2, "&Department", "UNDEFINED");
	EndIf;
	
	//TTOfRegisteredRecordedCalculationOfAverageSlip
	QueryText = StrReplace(QueryTextTemplate2, "NameOfDataTableIncomeExpenses", "TTOfRegisteredRecordedCalculationOfAverageSlip");
	QueryText = StrReplace(QueryText, "&FilterCriterion",
		"T.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.RecogniseAsExpensesAssets)");

	//TTOfRegisteredRecordedCalculationAccordingToSourceDocument
	If ReflectionParameters.ThereIsDocumentSource Then

		QueryText = QueryText + "
			|
			|UNION ALL
			|
			|" + QueryTextTemplate2;
		
		QueryText = StrReplace(QueryText, "NameOfDataTableIncomeExpenses", "TTOfRegisteredRecordedCalculationAccordingToSourceDocument");
		QueryText = StrReplace(QueryText, "&FilterCriterion",
			"T.CostAccountingTransaction = VALUE(Enum.CostAccountingTransactions.RecogniseAsExpensesAssets)");
		
	EndIf;
	
	//TTOfRegisteredRecordedDeviationsInCost
	If ReflectionParameters.ThereAreDisposalsAtFixedCost Or ReflectionParameters.ThereIsReversal Then

		QueryText = QueryText + "
			|
			|UNION ALL
			|
			|" + QueryTextTemplate2;
		
		QueryText = StrReplace(QueryText, "NameOfDataTableIncomeExpenses", "TTOfRegisteredRecordedDeviationsInCost");
		QueryText = StrReplace(QueryText, "&FilterCriterion", "TRUE");
		
	EndIf;
	
	ReflectionParameters.ReflectionTemplateTexts.Insert(Metadata.AccumulationRegisters.RegisterRecordsProductsIncomeExpenses.Name, QueryText);
	
EndProcedure

Procedure AddQueryTextOfRegisteredRecordsItemItem(ReflectionParameters)
	
	If Not ReflectionParameters.ThereIsMove And Not ReflectionParameters.ThereIsWriteOffToOtherParties Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	T.Period 										AS Period,
	|	T.Organization 									AS Organization,
	|	&Department 									AS Department,
	|	T.BusinessOperation 		 				AS BusinessOperation,
	|	T.ItemsLocationAttributes 	 				AS ItemsLocationAttributes,
	|	T.InventoryOwnerAttribute 	 								AS InventoryOwnerAttribute,
	|	InventoryKinds.InventoryType 	 						AS InventoryType,
	|
	|	DimensionOfProductItem.Purpose.LineOfBusiness AS LineOfBusiness,
	|	CASE WHEN DimensionOfProductItem.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
	|		THEN DimensionOfProductItem.Contract.Partner
	|		ELSE DimensionOfProductItem.StorageLocation
	|	END AS Warehouse,
	|	CASE
	|		WHEN DimensionOfProductItem.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN DimensionOfProductItem.Products
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN T.InventoryOwnerAttribute
	|			ELSE DimensionOfProductItem.Products
	|	END AS SourceOfProductFinancialAccountingGroup,
	|
	|	T.CorItemsLocationAttributes 	 			AS CorItemsLocationAttributes,
	|	T.CorInventoryOwnerAttribute 	 							AS CorInventoryOwnerAttribute,
	|	CorTypesOfStocks.InventoryType 	 					AS CorInventoryType,
	|	&CorCompany 	 							AS CorCompany,
	|
	|	CorAnalysisOfProducts.Purpose.LineOfBusiness AS CorLineOfBusiness,
	|	CASE WHEN CorAnalysisOfProducts.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
	|		THEN CorAnalysisOfProducts.Contract.Partner
	|		ELSE CorAnalysisOfProducts.StorageLocation
	|	END AS CorWarehouseCorCommissionAgentCorBusinessUnit,
	|	CASE
	|		WHEN CorAnalysisOfProducts.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN CorAnalysisOfProducts.Products
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN T.CorInventoryOwnerAttribute
	|			ELSE CorAnalysisOfProducts.Products
	|	END AS CorSourceOfItemsFinancialAccountingGroup,
	|
	|	T.Cost 			AS Cost,
	|	T.CostExcludingVAT 		AS CostExcludingVAT,
	|	T.LocalCost 		AS LocalCost,
	|	T.CostMan 			AS CostMan
	|FROM
	|	TTOfRegisteredRecordedCalculationOfAverageSlip AS T
	|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionOfProductItem
	|		ON T.ItemsLocationAttributes = DimensionOfProductItem.Ref
	|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS CorAnalysisOfProducts
	|		ON T.CorItemsLocationAttributes = CorAnalysisOfProducts.Ref
	|	LEFT JOIN Catalog.InventoryKinds AS InventoryKinds
	|		ON T.InventoryOwnerAttribute = InventoryKinds.Ref
	|	LEFT JOIN Catalog.InventoryKinds AS CorTypesOfStocks
	|		ON T.InventoryOwnerAttribute = CorTypesOfStocks.Ref
	|WHERE
	|	T.CostAccountingTransaction IN
	|		(VALUE(Enum.CostAccountingTransactions.Move),
	|		 VALUE(Enum.CostAccountingTransactions.ExpensesToOtherProductionLots))
	|	AND T.InventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
	|	AND (T.Cost <> 0 OR T.CostExcludingVAT <> 0 OR T.LocalCost <> 0 OR T.CostMan <> 0)
	|";
	
	If ReflectionParameters.ThereIsDivision Then
		QueryText = StrReplace(QueryText, "&Department", "T.Department");
	Else
		QueryText = StrReplace(QueryText, "&Department", "UNDEFINED");
	EndIf;
	
	If ReflectionParameters.ThereIsCorOrganization Then
		QueryText = StrReplace(QueryText, "&CorCompany", "T.CorCompany");
	Else
		QueryText = StrReplace(QueryText, "&CorCompany", "UNDEFINED");
	EndIf;
	
	ReflectionParameters.ReflectionTemplateTexts.Insert(Metadata.AccumulationRegisters.RecordsProductsProducts.Name, QueryText);
	
EndProcedure

Procedure AddQueryTextForDeviationsInCostOfGoods(ReflectionParameters)
	
	ArrayOfRequestTexts = New Array;
	
	// Resource fields used in the request:
	NumericFieldsByString = "AddExpensesForGoods,AdditionalExpensesExcludingVAT,AddExpensesLocal,AddExpensesMan,VATLocal,VATManag,PermanentDifference,CostTD";
	// Delete fields that are not in the document table:
	NumericFields = StrSplit(NumericFieldsByString, ",");
	FieldsToDelete = New Array;
	For Each NumberField In NumericFields Do
		If Not ReflectionParameters.RequestColumns.Property(NumberField) Then
			FieldsToDelete.Add(NumberField);
		EndIf;
	EndDo;
	NumericFields = CommonClientServer.ArraysDifference(NumericFields, FieldsToDelete);
	
	If Not NumericFields.Count() Then
		Return;
	EndIf;
	
	// The conditions for filling in the fields must match the text of the request in the calculation of the cost of data preparation.Fix the problem of movement in documents, the area of deviation in the value of products
	QueryText =
	"SELECT
	|	T.Period 										AS Period,
	|	VALUE(AccumulationRecordType.Receipt) 			AS RecordType,
	|	T.Organization 									AS Organization,
	|	T.AnalysisOfAccountingForProductsProducts		AS Products,
	|	T.AnalysisOfAccountingProductsCharacteristics		AS Characteristic,
	|	T.InventoryOwnerAttribute 									AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN NOT T.AccountingPoliciesDetailDeviationsInAreasOfActivity
	|			THEN VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|			ELSE ISNULL(T.InventoriedLocationAttributeAnalysisPurposeLineOfBusiness,
	|				VALUE(Catalog.LinesOfBusiness.EmptyRef))
	|	END											AS LineOfBusiness,
	|	CASE
	|		WHEN NOT T.AccountingPoliciesDetailDeviationsByDivision
	|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
	|		WHEN T.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Department)
	|			THEN T.ProductAccountingAnalyticsStorageLocation
	|		WHEN T.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.Warehouse)
	|			THEN CAST(T.ProductAccountingAnalyticsStorageLocation AS Catalog.Warehouses).Department
	|		WHEN T.CatKeysOfItemTypeOfStorageLocation = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
	|			THEN CAST(T.ProductAccountingAnalyticsStorageLocation AS Catalog.CounterpartyContracts).Department
	|			ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END 											AS Department,
	|	CASE
	|		WHEN NOT T.AccountingPoliciesDetailDeviationsByWarehouse
	|			THEN UNDEFINED
	|			ELSE T.ProductAccountingAnalyticsStorageLocation
	|	END											AS StorageLocation,
	|	BEGINOFPERIOD(CASE WHEN T.SourceDocumentPeriod = UNDEFINED
	|	  OR T.SourceDocumentPeriod = DATETIME(1,1,1)
	|		THEN T.Period
	|		ELSE T.SourceDocumentPeriod
	|	END, MONTH)									AS VariancePeriod,
	|	T.BusinessOperation 		 				AS BusinessOperation,
	|	T.BusinessTransactionSetting 		 		AS BusinessTransactionSetting,
	|	T.FinRecordID 		 				AS FinRecordID,
	|
	|	&TextNumericFields
	|FROM
	|	TTDocumentData_ AS T
	|WHERE
	|	T.AccountingPoliciesInventoryValuationMethod = VALUE(Enum.InventoryValuationMethods.MovingAverage)
	|	AND NOT (ISNULL(T.InventoryOwnerAttributeIsTypeOfInventory, UNDEFINED) = VALUE(Enum.InventoryTypes.OwnGoodsOfUninvoicedDelivery)
	|		AND BEGINOFPERIOD(T.SourceDocumentPeriod, MONTH) >= BEGINOFPERIOD(T.Period, MONTH))
	|	AND (&ConditionText)";
	
	If Not ReflectionParameters.RequestColumns.Property("SourceDocumentPeriod") Then
		QueryText = StrReplace(QueryText, "SourceDocumentPeriod", "Period");
	EndIf;

	// The main request, the VAT fields are not filled in:
	FieldsToReset = StrSplit("VATLocal,VATManag", ",");
	TextOfMainRequest = ConvertNumericFieldsInQuery(QueryText, NumericFields, FieldsToReset);
	ArrayOfRequestTexts.Add(TextOfMainRequest);
	
	// Request to include VAT in the cost, only the VAT fields are filled in:
	If ReflectionParameters.RequestColumns.Property("VATLocal") Then
		FieldsToReset = CommonClientServer.ArraysDifference(NumericFields, FieldsToReset);
		VATInclusionQueryText = ConvertNumericFieldsInQuery(QueryText, NumericFields, FieldsToReset);
		VATInclusionQueryText = StrReplace(VATInclusionQueryText, "T.FinRecordID", "T.RowID");
		VATInclusionQueryText = StrReplace(VATInclusionQueryText, "T.BusinessTransactionSetting", "VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses)");
		VATInclusionQueryText = StrReplace(VATInclusionQueryText, "VALUE(Enum.InventoryValuationMethods.MovingAverage)", "VALUE(Enum.InventoryValuationMethods.MovingAverage)
		|	AND T.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
		|	AND &GenerateVATChargedWhenIncludingInCost
		|	AND VALUETYPE(T.Lot) <> TYPE(Catalog.ProductionLots)
		|");
		If ReflectionParameters.DifferentPeriodsInRegisteredRecordsArePossible Then
			VATInclusionQueryText = StrReplace(VATInclusionQueryText, "TTDocumentData_ AS T", "TTDocumentData_ AS T
			|	INNER JOIN TTParametersOfBatchAccountingForConducting AS Parameters
			|	ON Parameters.Period = BEGINOFPERIOD(T.Period, MONTH)
			|		AND Parameters.Organization = T.Organization");
			VATInclusionQueryText = StrReplace(VATInclusionQueryText, "&GenerateVATChargedWhenIncludingInCost", "Parameters.GenerateVATChargedWhenIncludingInCost");
		EndIf;
		ArrayOfRequestTexts.Add(VATInclusionQueryText);
	EndIf;
	
	QueryText = StrConcat(ArrayOfRequestTexts, TMCommonUse.QuerySeparatorInJoin());

	ReflectionParameters.ReflectionTemplateTexts.Insert(Metadata.AccumulationRegisters.GoodsCostVariances.Name, QueryText);
	
EndProcedure

Function ConvertNumericFieldsInQuery(RequestSourceText, NumericFields, FieldsToReset)
	
	ReplacingFieldInFinalRequest = New Map;
	ReplacingFieldInFinalRequest.Insert("AddExpensesForGoods",			"CostVariancesIncludingVAT");
	ReplacingFieldInFinalRequest.Insert("AdditionalExpensesExcludingVAT",	"CostVariancesExcludingVAT");
	ReplacingFieldInFinalRequest.Insert("AddExpensesLocal",		"CostVariancesLocal");
	ReplacingFieldInFinalRequest.Insert("AddExpensesMan", 		"CostVariancesMgmt");
	
	FieldArray = New Array;
	ArrayOfConditions = New Array;
	
	For Each NumberField In NumericFields Do
		
		FieldAlias = ?(ReplacingFieldInFinalRequest.Get(NumberField) = Undefined, NumberField, ReplacingFieldInFinalRequest.Get(NumberField));
		Simple = ?(FieldsToReset.Find(NumberField) = Undefined, "T." + NumberField, "0");
		FieldArray.Add(StrTemplate("%1 AS %2", Simple, FieldAlias));
		If Simple <> "0" Then
			ArrayOfConditions.Add(StrTemplate("%1 <> 0", Simple));
		EndIf;
		
	EndDo;
	
	TextNumericFields = StrConcat(FieldArray, "," + Chars.LF + Chars.Tab);
	ConditionText = StrConcat(ArrayOfConditions, Chars.LF + Chars.Tab + Chars.Tab + " " + "OR" + " ");
	
	QueryText = StrReplace(RequestSourceText, "&TextNumericFields", TextNumericFields);
	If Not IsBlankString(ConditionText) Then
		QueryText = StrReplace(QueryText, "&ConditionText", ConditionText);
	Else
	// If there are no numeric fields in the request, then it makes no sense to execute such a request.
		QueryText = StrReplace(QueryText, "&ConditionText", "FALSE");
	EndIf;
	
	Return QueryText;
	
EndFunction

Function SumFieldsOfAverageSliding() Export
	
	Return "Cost, CostExcludingVAT, LocalCost, CostMan, OffBalanceCost, OffBalanceCostLocal";
	
EndFunction

#EndRegion

#Region OtherItems

Procedure CheckFieldsOfDataFetchRequest(ReflectionParameters, OperationDescription, ParsingRequestSchema)
	
	For Each Sources In ParsingRequestSchema.QueryDetails.Operators[0].Sources Do
		If Lower(Sources.Source.Alias) = Lower("DocumentTable") Then
			DocumentName = Sources.Source.TableName;
			Break;
		EndIf;
	EndDo;
	
	DocumentTableIsSpecifiedAndMatchesReflectedDocuments = DocumentName <> Undefined
		And Lower(ReflectionParameters.MetadataOfDocument.FullName()) <> Lower(DocumentName)
		And Lower("DocumentDataHeader") <> Lower(DocumentName);
	
	StructureOfOperationField = New Structure;
	RequestFieldStructure  = New Structure;
	
	For Each LongDesc In OperationDescription.Fields Do
		StructureOfOperationField.Insert(LongDesc.Name, LongDesc.Additional);
	EndDo;
	
	For Each LongDesc In ParsingRequestSchema.RequestColumns Do
		RequestFieldStructure.Insert(LongDesc.Key);
	EndDo;
	
	TextOfOperationField = "";
	RequestFieldText = "";
	
	For Each LongDesc In StructureOfOperationField Do
		If Not RequestFieldStructure.Property(LongDesc.Key) And Not LongDesc.Value Then
			TextOfOperationField = TextOfOperationField + ?(TextOfOperationField = "", "", ", ") + LongDesc.Key;
		EndIf;
	EndDo;
	
	For Each LongDesc In RequestFieldStructure Do
		If Not StructureOfOperationField.Property(LongDesc.Key) Then
			RequestFieldText = RequestFieldText + ?(RequestFieldText = "", "", ", ") + LongDesc.Key;
		EndIf;
	EndDo;
	
	If ValueIsFilled(RequestFieldText)
	 Or ValueIsFilled(TextOfOperationField)
	 Or DocumentTableIsSpecifiedAndMatchesReflectedDocuments Then
		Common.MessageToUser(NStr("vi = 'Lỗi khi chuẩn bị dữ liệu cho giao dịch';
									|ru = 'Ошибка в подготовке данных для операции';
									|en = 'An error occurred upon preparing the transaction data'; fa = 'An error occurred upon preparing the transaction data';
									|it = 'Errore durante la preparazione dei dati per l''operazione';
									|pl = 'Błąd w przygotowaniu dany dla operacji';
									|tr = 'İşlem için veri hazırlanırken hata'") + ": " + ParsingRequestSchema.OperationKind);
	EndIf;
	
	If ValueIsFilled(RequestFieldText) Then
		Common.MessageToUser(
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Các trường thừa trong truy vấn chọn dữ liệu của giao dịch ""%1"" để kết chuyển chứng từ: ""%2""';
					|ru = 'Лишние поля в запросе выборки данных операции ""%1"" для проведения документа: ""%2""';
					|en = 'Extra fields in the ""%1"" operation dataset query for document posting: ""%2""'; fa = 'Extra fields in the ""%1"" operation dataset query for document posting: ""%2""';
					|it = 'Campi extra nella richiesta di esempio di dati di operazione ""%1"" per la pubblicazione del documento: ""%2""';
					|pl = 'Zbędne pola w zapytaniu selekcji danych operacji ""%1"" do zatwierdzenia dokumentu: ""%2""';
					|tr = 'Belge yürütme için ""%1"" işlem verisi örnekleme talebindeki gereksiz alanlar: ""%2""'"),
				OperationDescription.OperationKind,
				RequestFieldText));
	EndIf;
	
	If ValueIsFilled(TextOfOperationField) Then
		Common.MessageToUser(
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không đủ trường cần thiết trong truy vấn chọn dữ liệu cho giao dịch ""%1"" để kết chuyển chứng từ: ""%2""';
					|ru = 'Не хватает обязательных полей в запросе выборки данных операции ""%1"" для проведения документа: ""%2""';
					|en = 'Required fields are missing in the ""%1"" operation dataset query for document posting: ""%2""'; fa = 'Required fields are missing in the ""%1"" operation dataset query for document posting: ""%2""';
					|it = 'Non bastano i campi obbligatori nella richiesta di esempio di dati dell''operazione ""%1"" per la pubblicazione del documento: ""%2""';
					|pl = 'Nie wystarcza pól obowiązkowych w zapytaniu selekcji danych operacji ""%1"" do zatwierdzenia dokumentu: ""%2""';
					|tr = 'Belge kaydı için ""%1"" işleminin veri örneklemesi talebinde eksik zorunlu alanlar: ""%2""'"),
				OperationDescription.OperationKind,
				TextOfOperationField));
	EndIf;
	
	If DocumentTableIsSpecifiedAndMatchesReflectedDocuments Then
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không trùng tên chứng từ ""%1"" với bảng truy vấn chính ""%2""';
				|ru = 'Не совпадает имя документа ""%1"" с основной таблицей запроса ""%2""';
				|en = 'The document name ""%1"" does not match the main query table ""%2""'; fa = 'The document name ""%1"" does not match the main query table ""%2""';
				|it = 'Il nome del documento ""%1"" non corrisponde alla tabella principale della richiesta ""%2""';
				|pl = 'Nie odpowiada nazwa dokumentu ""%1"" z podstawową tabelą zapytania ""%2""';
				|tr = 'Belge adı ""%1"", ana sorgu tablosu ""%2"" ile eşleşmiyor'"),
			ReflectionParameters.MetadataOfDocument.Name,
			DocumentName);
			
		Common.MessageToUser(ErrorText);
		
	EndIf;
	
EndProcedure

Function ObjectManagerByRef(Document)
	
	ManagerOfDocument = Common.ObjectManagerByRef(Document);
	
	
	Return ManagerOfDocument;
	
EndFunction

Function AllRegisterFields(RegisterMetadata)
	
	RegisterFields = New Structure;
	
	For Each MetaField In RegisterMetadata.Dimensions Do
		RegisterFields.Insert(MetaField.Name);
	EndDo; 
		
	For Each MetaField In RegisterMetadata.Resources Do
		RegisterFields.Insert(MetaField.Name);
	EndDo; 
	
	For Each MetaField In RegisterMetadata.Attributes Do
		RegisterFields.Insert(MetaField.Name);
	EndDo; 
	
	For Each MetaField In RegisterMetadata.StandardAttributes Do
		RegisterFields.Insert(MetaField.Name);
	EndDo; 
	
	Return RegisterFields;
	
EndFunction

#EndRegion

#EndRegion

// Embedding in a document:
// Add the Batch Accounting area to the end of the Holding area
// Add to the procedure area
//	- Description of the inventory of the cost of the property
//	- Set additional parameters of the operation to account for the cost of the property
//	- To form additional tables of the operation of accounting for the cost of the property
//	- Description
// 	 of the operation of the accounting of the cost (for examples of filling in the texts of procedures, see, for example, in the document of the implementation of the services)
// Add a call to the calculation of the cost of the documents. Reflect the mechanism of accounting for the cost of the cost in the procedure of the given documentation for the examination
