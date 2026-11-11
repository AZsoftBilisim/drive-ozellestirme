#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		
		If FillingData.Property("ResultAddress") Then
			AllocationResult = GetFromTempStorage(FillingData.ResultAddress);
		Else
			AllocationResult = FillingData;
		EndIf;
		
		If AllocationResult.Property("HeaderAttributes") Then
			FillPropertyValues(ThisObject, AllocationResult.HeaderAttributes);
		EndIf;
		
		If AllocationResult.Property("MaterialsAndWorks")
			And Not AllocationResult.MaterialsAndWorks = Undefined Then
			MaterialsAndWorks.Load(AllocationResult.MaterialsAndWorks);
		EndIf;
		
		If AllocationResult.Property("LaborCosts")
			And Not AllocationResult.LaborCosts = Undefined Then
			LaborCosts.Load(AllocationResult.LaborCosts);
		EndIf;
		
		If AllocationResult.Property("OtherExpenses")
			And Not AllocationResult.OtherExpenses = Undefined Then
			OtherExpenses.Load(AllocationResult.OtherExpenses);
		EndIf;
	ElsIf TypeOf(FillingData) = Type("DocumentRef.InitialWIPBalancesByBusinessUnits") Then
		FillInBasedOnInitialBalancesOfUnfinishedProductionByDivision(FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef." + Metadata().Name) Then
		
		DocumentCorrection.FillInCorrection(ThisObject, FillingData);
		
	EndIf;
	
	InitializeDocument(FillingData);
	
	ItemsAndDimensionsSelectionParameters = Documents.WIPOpeningBalancesByProductionLots.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	FillParameters = Documents.WIPOpeningBalancesByProductionLots.ParametersForFillingInVATActivities(ThisObject);
	VATAccountingERP.FillInTypeOfActivityVAT(VATActivityType, FillParameters);
	
	WIPOpeningBalancesByProductionLotsLocalization.Filling(
		ThisObject,
		FillingData,
		FillingText,
		StandardProcessing);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	
	InitializeDocument();
	
	WIPOpeningBalancesByProductionLotsLocalization.OnCopy(
		ThisObject,
		CopiedObject);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	CostsServer.CheckUseOfBatchAccounting22(ThisObject, Date, Cancel);
	
	#Region Table_MaterialsAndWorks
	
	ParametersForCheckingCharacteristics			= ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
	ParametersForCheckingCharacteristics.TSName	= "MaterialsAndWorks";
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(
		ThisObject,
		NotCheckedAttributeArray,
		Cancel,
		ParametersForCheckingCharacteristics);
	
	SeriesSpecificationParameters =
		ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.WIPOpeningBalancesByProductionLots);
	
	ProductsServer.CheckSeriesCompletion(
		ThisObject,
		SeriesSpecificationParameters,
		Cancel,
		NotCheckedAttributeArray);
	
	QuantityVerificationParameters			= ProductsServer.ParametersForCheckingFillingQuantity();
	QuantityVerificationParameters.TSName	= "MaterialsAndWorks";
	ProductsServer.CheckQuantityFilling(
		ThisObject,
		CheckedAttributes,
		Cancel,
		QuantityVerificationParameters);
	
	#EndRegion
	
	#Region Table_OtherExpenses
	
	#Region ReviewArticlesAndAnalytics
	
	ItemsAndDimensionsSelectionParameters = Documents.WIPOpeningBalancesByProductionLots.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
		
	#EndRegion
	
	#Region CheckingRulesForAssigningToIssue

	NotCheckedAttributeArray.Add("OtherExpenses.RuleOfCostAllocatingToProductionLotsMan");
	NotCheckedAttributeArray.Add("OtherExpenses.RuleOfCostAllocatingToProductionLotsLocal");
	
	Query = New Query;
	Query.Text = 
		"SELECT DISTINCT
		|	ExpenseItems.Ref AS ExpenseItem,
		|	CASE
		|		WHEN ExpenseItems.CostAllocationOptionManag IN (
		|				VALUE(Enum.CostAllocationOptions.ToProductionCosts),
		|				VALUE(Enum.CostAllocationOptions.ToProductionCostDirect))
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS CheckManRule,
		|	CASE
		|		WHEN ExpenseItems.CostAllocationOptionLocal IN (
		|				VALUE(Enum.CostAllocationOptions.ToProductionCosts),
		|				VALUE(Enum.CostAllocationOptions.ToProductionCostDirect))
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS CheckLocalRule
		|FROM
		|	ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
		|WHERE
		|	ExpenseItems.Ref IN(&ExpenseItems)";
	
	Query.SetParameter("ExpenseItems", OtherExpenses.UnloadColumn("ExpenseItem"));
	
	DetailsOfExpenditureItems = Query.Execute().Unload();
	DetailsOfExpenditureItems.Indexes.Add("ExpenseItem");
	
	MessageTemplate = NStr("vi = 'Trong dòng %LineNumber% của danh sách ""Chi phí khác"", chưa điền trường ""%FieldName%"".';
							|ru = 'В строке %LineNumber% списка ""Прочие расходы"" не заполнено поле ""%FieldName%"".';
							|en = '""%FieldName%"" in line %LineNumber% of the list ""Other expenses"" is required.'; fa = '""%FieldName%"" in line %LineNumber% of the list ""Other expenses"" is required.';
							|it = 'Nella riga %LineNumber% dell''elenco ""Прочие расходы"" non è compilato il campo ""%FieldName%"".';
							|pl = 'W wierszu %LineNumber% listy ""Pozostałe rozchody"" nie jest wypełnione pole ""%FieldName%"".';
							|tr = '""Diğer giderler"" listesinin %LineNumber% satırında ""%FieldName%"" alanı doldurulmadı.'");
	DataKey = TMCommonUse.DataKeyForMessageToUser(ThisObject);
	
	For Each CurRow In OtherExpenses Do
		
		MessageText = StrReplace(MessageTemplate, "%LineNumber%", CurRow.LineNumber);
		
		ArticleDetails_1 = DetailsOfExpenditureItems.Find(CurRow.ExpenseItem);
		If ArticleDetails_1 = Undefined Then
			Continue;
		EndIf;
		
		If ArticleDetails_1.CheckManRule
			And Not ValueIsFilled(CurRow.RuleOfCostAllocatingToProductionLotsMan) Then
			
			ErrorMessage = StrReplace(MessageText, "%FieldName%", NStr("vi = 'Quy tắc phân bổ xuất xưởng (qt.)';
																		|ru = 'Правило отнесения на выпуск (упр.)';
																		|en = 'Rule of allocating to release (mgmt)'; fa = 'قاعده تسهیم به تولید (مدیریت)';
																		|it = 'Regola dell''attribuzione al rilascio (ges.)';
																		|pl = 'Zasada przydzielania do wyprodukowania (zarz.)';
																		|tr = 'Üretim için ilişkilendirme kuralı (yerel muhasebe.)'"));
			Field = CommonClientServer.PathToTabularSection("OtherExpenses", CurRow.LineNumber, "RuleOfCostAllocatingToProductionLotsMan");
			Common.MessageToUser(ErrorMessage, DataKey , Field, "Object", Cancel);
			
		EndIf;
		
		If ArticleDetails_1.CheckLocalRule
			And Not ValueIsFilled(CurRow.RuleOfCostAllocatingToProductionLotsLocal) Then
			
			ErrorMessage = StrReplace(MessageText, "%FieldName%", NStr("vi = 'Quy tắc phân bổ xuất xưởng (pq.)';
																		|ru = 'Правило отнесения на выпуск (регл.)';
																		|en = 'Rule of allocating to release (local)'; fa = 'قاعده تسهیم به تولید (محلی)';
																		|it = 'Regola dell''attribuzione al rilascio (reg.)';
																		|pl = 'Zasada przydzielania do wyprodukowania (reg.)';
																		|tr = 'Üretim için ilişkilendirme kuralı (yerel muhasebe.)'"));
			Field = CommonClientServer.PathToTabularSection("OtherExpenses", CurRow.LineNumber, "RuleOfCostAllocatingToProductionLotsLocal");
			Common.MessageToUser(ErrorMessage, DataKey , Field, "Object", Cancel);
			
		EndIf;
		
	EndDo;
	
	#EndRegion
	
	#EndRegion
	
	#Region VATVerification
	
	CheckParameters = VATAccountingERP.ParametersForCheckingDocumentFillingByTypeOfActivity();
	CheckParameters.TabularSectionName						= "OtherExpenses";
	CheckParameters.BankingDetailsNameExpenseItem			= "ExpenseItem";
	CheckParameters.ExpenseAnalystDetailsName			= "DimensionOfExpenses";
	
	VATAccountingERP.CheckCompletionOfDocumentByTypeOfVATActivity(
		ThisObject,
		VATActivityType,
		CheckParameters,
		Cancel);
	
	#EndRegion
	
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	If Not Cancel And TMCommonUse.CheckObjectDetails(ThisObject, CheckedAttributes) Then
		Cancel = True;
	EndIf;
	
	WIPOpeningBalancesByProductionLotsLocalization.FillCheckProcessing(
		ThisObject,
		Cancel,
		CheckedAttributes);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If DocumentsPosting.DocumentProperties(ThisObject).IsNew Then
		GetNewObjectRef();
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.WIPOpeningBalancesByProductionLots.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	For Each CostLine In OtherExpenses Do
		
		If Not ValueIsFilled(CostLine.RuleOfCostAllocatingToProductionLotsLocal) Then
			
			CostLine.AmountTemporaryDifferences = 0;
			CostLine.AmountPermanentDifferences = 0;
			CostLine.SumCompl = 0;
			
		EndIf;
		
		If Not ValueIsFilled(CostLine.RuleOfCostAllocatingToProductionLotsMan) Then
			CostLine.Sum = 0;
		EndIf;
		
	EndDo;
	
	DocumentAmount =
		MaterialsAndWorks.Total("Sum")
		+ LaborCosts.Total("Sum")
		+ OtherExpenses.Total("Sum");
	
	// Processing the change of details
	If Not IsNew() Then
		PreviousValues1 = Common.ObjectAttributesValues(Ref, "DeletionMark");
		AdditionalProperties.Insert("DeletionMarkBeforeRecording", PreviousValues1.DeletionMark);
	Else
		AdditionalProperties.Insert("DeletionMarkBeforeRecording", False);
	EndIf;
	
	If WriteMode = DocumentWriteMode.Posting Then
		FillInAnalyticsKeys();
		FillStockTypes(Cancel);
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "MaterialsAndWorks,LaborCosts,OtherExpenses");
	
	WIPOpeningBalancesByProductionLotsLocalization.BeforeWrite(
		ThisObject,
		Cancel,
		WriteMode,
		PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	WIPOpeningBalancesByProductionLotsLocalization.OnWrite(
		ThisObject,
		Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	WIPOpeningBalancesByProductionLotsLocalization.Posting(
		ThisObject,
		Cancel,
		PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	WIPOpeningBalancesByProductionLotsLocalization.UndoPosting(
		ThisObject,
		Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region FillType

Procedure InitializeDocument(FillingData = Undefined)
	
	If Not ValueIsFilled(Date) Then
		Date = CurrentSessionDate();
	EndIf;
	
	Organization		= SettingsValueCached.GetDefaultOrganization(Organization);
	PriceKind			= Catalogs.TypesOfPrices.TypeOfPricePlannedCostOfInventory(PriceKind);
	EmployeeResponsible	= Users.CurrentUser();
	
EndProcedure

#Region InputOnBasis

Procedure FillInBasedOnInitialBalancesOfUnfinishedProductionByDivision(Basis) Export
	
	DocumentBasis = Basis;
	
	DetailsOfFoundation = Common.ObjectAttributesValues(
		Basis,
		"Organization, Department, Date, LineOfBusiness");
	
	FillPropertyValues(ThisObject, DetailsOfFoundation);
	
	AllocationResult = Documents.InitialWIPBalancesByBusinessUnits.DistributeInitialBalancesAmongProductionBatches(Basis);
	
	If AllocationResult.Property("MaterialsAndWorks")
		And Not AllocationResult.MaterialsAndWorks = Undefined Then
		MaterialsAndWorks.Load(AllocationResult.MaterialsAndWorks);
	EndIf;
	
	If AllocationResult.Property("LaborCosts")
		And Not AllocationResult.LaborCosts = Undefined Then
		LaborCosts.Load(AllocationResult.LaborCosts);
	EndIf;
	
	If AllocationResult.Property("OtherExpenses")
		And Not AllocationResult.OtherExpenses = Undefined Then
		OtherExpenses.Load(AllocationResult.OtherExpenses);
	EndIf;
	
EndProcedure
#EndRegion

Procedure FillInAnalyticsKeys()
	
	PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(
		Enums.BusinessTransactions.OBEntryProductionLotCosts,
		Department,
		Department,
		Undefined);
	
	FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
	FieldsNames.Insert("Purpose",			"Purpose");
	FieldsNames.Insert("Series",				"Series");
	FieldsNames.Insert("BatchesIndicationStatus",	"BatchesIndicationStatus");
	FieldsNames.Insert("ProductCostElement",	"ProductCostElement");
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(MaterialsAndWorks, PlacesOfAccounting, FieldsNames);
	
EndProcedure

#Region InventoryKinds

Procedure FillStockTypes(Cancel)
	
	SetPrivilegedMode(True);
	
	TempTablesManager = TemporaryDocumentDataTables();
	InventoriesServer.FillStockTypesByDefault(TempTablesManager, MaterialsAndWorks);
	
EndProcedure

// The function creates a temporary data table of the document.
//
// Returns:
//	TempTablesManager - temporary table manager.
//
Function TemporaryDocumentDataTables() Export
	
	Query = New Query("
	|SELECT
	|	TableOfGoods.LineNumber	AS LineNumber,
	|	TableOfGoods.Products	AS Products,
	|	TableOfGoods.InventoryOwnerAttribute	AS InventoryOwnerAttribute
	|INTO TTOriginalProductTable
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|WHERE
	|	TableOfGoods.InventoryOwnerAttribute = VALUE(Catalog.InventoryKinds.EmptyRef)
	|	OR &RefillInventoryKinds
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber									AS LineNumber,
	|	TableOfGoods.Products									AS Products,
	|	CASE
	|		WHEN &Posted
	|			THEN TableOfGoods.InventoryOwnerAttribute
	|		ELSE VALUE(Catalog.InventoryKinds.EmptyRef)
	|	END														AS CurViewOfStocks,
	|	FALSE														AS ThisIsReusablePackage,
	|	&Organization AS Organization,
	|	VALUE(Enum.BusinessTransactions.OBEntryProductionLotCosts) AS BusinessOperation,
	|	VALUE(Enum.InventoryTypes.OwnGoods)					AS InventoryType,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef)	AS Terms,
	|	VALUE(Catalog.Counterparties.EmptyRef)				AS Counterparty,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef)		AS Contract,
	|	VALUE(Catalog.Currencies.EmptyRef)					AS Currency,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef)	AS VATTaxation,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef)	AS TaxationOfOrganization,
	|	UNDEFINED												AS GoodsOwner,
	|	VALUE(Catalog.VendorPriceTypes.EmptyRef)		AS PriceKind
	|INTO OriginalProductTable
	|FROM
	|	TTOriginalProductTable AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTOriginalProductTable
	|");
	
	TempTablesManager = New TempTablesManager;
	Query.TempTablesManager = TempTablesManager;
	
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("TableOfGoods", MaterialsAndWorks);
	Query.SetParameter("Posted", Posted);
	
	InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);
	InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject, Query);
	
	Query.Execute();
	
	Return TempTablesManager;
	
EndFunction

#EndRegion

#EndRegion

#EndRegion

#EndIf