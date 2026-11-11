#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If Not Approved
		And Enums.PurchaseRequestStatuses.AgreedUpon(Status)
		And UserRightsCached.ApprovePurchaseRequests() // The author can close the application, but this will not be an agreement.
		And WriteMode = DocumentWriteMode.Posting Then
		// The filling checks are completed, the Status of "approval" is set.
		Approved = True;
	EndIf;
	
	FillInBlankDesiredDatesOfReceipt();
	
	OperationsWithDocumentProtocol.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode);
	
	DocumentAmount = Goods.Unload(New Structure("Canceled", False)).Total("AmountIncludingVAT");
	
	If Not ValueIsFilled(Number) Then
		SetNewNumber();
	EndIf;
		
	If Not ValueIsFilled(Author) And IsNew() Then
		Author = Users.CurrentUser();
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	AttributesNotToCheck = New Array;

	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel);
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,AttributesNotToCheck,Cancel);
	
	// Warehouses are checked only if there are goods/containers
	AttributesNotToCheck.Add("Goods.Warehouse");
	AttributesNotToCheck.Add("Warehouse");
	PurchasesServer.CheckCorrectnessOfPurchaseDocument(ThisObject, Cancel);
	
	AttributesNotToCheck.Add("Goods.Department");
	DescriptionOfUnitInspections = New Map;
	DescriptionOfUnitInspections.Insert(
		Enums.ItemsTypes.OperationService, 
		NStr("vi = 'Chưa chỉ định nơi nhận dịch vụ trong dòng %1 danh sách Hàng hóa';
			|ru = 'Не указан получатель услуг в строке %1 списка Товары';
			|en = 'Service recipient is not specified in line # %1 of the Item list'; fa = 'Service recipient is not specified in line # %1 of the Item list';
			|it = 'Il destinatario di servizi non è specificato nella riga %1 dell''elenco Merci';
			|pl = 'Nie wskazano odiorcy usług w wierszu %1 listy Wiersze pozycji';
			|tr = 'Mal listesinin %1satırında hizmet alıcısı belirtilmemiş'"));
		
	DescriptionOfUnitInspections.Insert(
		Enums.ItemsTypes.Work_5, 
		NStr("vi = 'Chưa chỉ định nơi nhận công việc trong dòng %1 danh sách Hàng hóa';
			|ru = 'Не указан получатель работ в строке %1 списка Товары';
			|en = 'Work recipient is not specified in line #%1 of the Item list'; fa = 'Work recipient is not specified in line #%1 of the Item list';
			|it = 'Il destinatario di lavori non è specificato nella riga %1 dell''elenco Merci';
			|pl = 'Nie wskazano odbiorcy robót w wierszu %1 listy Wiersze pozycji';
			|tr = 'Mal listesinin %1satırında işin alıcısı belirtilmemiş'"));
		
	For Each KeysAndValue In DescriptionOfUnitInspections Do
		InventoriesServer.CheckFillingOfDivisionInTablePart(
			ThisObject,
			CommonClientServer.ValueInArray(KeysAndValue.Key),
			KeysAndValue.Value,
			Cancel);
	EndDo;
	
	UseBDRLimits = Documents.PurchaseRequest.UseBDRLimits();
	MonitorBDRLimits = UseBDRLimits
		And Enums.PurchaseRequestStatuses.AgreedUpon(Status) // The Application Has been Approved
		And PurchaseObjective = Enums.PurchaseObjectives.OwnNeeds;
	
	If Not UseBDRLimits Then
		AttributesNotToCheck.Add("PurchaseObjective");
	EndIf;
	
	If Not MonitorBDRLimits Then
		NamesOfDetailsOfLimitingAnalyst = Documents.PurchaseRequest.NamesOfDetailsOfLimitingAnalyst();
		CommonClientServer.SupplementArray(AttributesNotToCheck, NamesOfDetailsOfLimitingAnalyst);
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);
	
	ItemsAndDimensionsSelectionParameters = Documents.PurchaseRequest.ItemsAndDimensionsSelectionParameters(PurchaseObjective);
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	LimitsByBudgetingDataServer.CheckRelevanceOfRulesForLimitsOnBudgetItems(ThisObject, Cancel);
EndProcedure

Procedure OnCopy(CopiedObject)
	
	Date = CurrentSessionDate();
	Protocol.Clear();
	Comment = Undefined;
	Status = Enums.PurchaseRequestStatuses.AwaitingApproval;
	InitializeDocument(CopiedObject);
	
EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	FillInDataType = TypeOf(FillingData);
	RequiredFillingInStatistics = True;
	
	If FillInDataType = Type("Structure") Then
		FillInSelectionDocument(FillingData);
		RequiredFillingInStatistics = False;
	EndIf;
	
	If RequiredFillingInStatistics Then
		ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	EndIf;
	InitializeDocument(FillingData);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillInSelectionDocument(Val FillingData)
	
	// List of Attributes that cannot be copied from the selection:
	NotDetailsToFillIn = New Array;
	NotDetailsToFillIn.Add("Posted");
	NotDetailsToFillIn.Add("DeletionMark");
	NotDetailsToFillIn.Add("Author");
	NotDetailsToFillIn.Add("Status");
	NotDetailsToFillIn.Add("Performer");
	
	AttributesToExclude = New Array;
	For Each AttributesThatCannotBeFilledIn In NotDetailsToFillIn Do
		If Not FillingData.Property(AttributesThatCannotBeFilledIn) Then
			Continue;
		EndIf;
		
		AttributesToExclude.Add(AttributesThatCannotBeFilledIn);
		
	EndDo;
	
	If ValueIsFilled(AttributesToExclude) Then
		AttributesToExclude = StrConcat(AttributesToExclude, ", ");
	Else
		AttributesToExclude = Undefined;
	EndIf;
	
	FillPropertyValues(ThisObject, FillingData,, AttributesToExclude);
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	If FillingData.Property("Goods") Then
		Goods.Load(FillingData.Goods);
	EndIf;
	
	CheckToFillInReceiptByOneDate();
	
	If FillingData.Property("Goods") Then //Filling out of the "Provision of Needs" processing.
		
		If Not ValueIsFilled(Currency) Then
			Currency = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting(Currency);
		EndIf;
		
		If FillingData.Property("Performer") Then
			Performer = FillingData.Performer;
		EndIf;
		
		Actions = New Structure;
		Actions.Insert("FillInPartnerSDefaultCounterparty", True);
		
		ParametersForFillingOutContract = BatchProcessingOfTablePartClientServer.DefaultContractFillingParameters();
		ParametersForFillingOutContract.Organization = Organization;
		ParametersForFillingOutContract.ARAPCurrency = Currency;
		ParametersForFillingOutContract.ContractType = Documents.PurchaseRequest.AvailableTypesOfContracts();
		Actions.Insert("FillInDefaultContract", ParametersForFillingOutContract);
		
		Actions.Insert("FillInProductNameOfProductPartner", Undefined);
		
		CommonClientServer.SupplementStructure(
			Actions,
			PurchaseRequestClientServer.ActionsOfFillingInVATTaxation(ThisObject),
			True);
		
		GoodsFromSource = FillingData.Goods; // ValueTable
		RecalculateAmountsAtAdjustedVATRates = True;
		If GoodsFromSource.Columns.Find("Price") = Undefined Then
			CommonClientServer.SupplementStructure(Actions, PurchaseRequestClientServer.ActionsToFillInPrice(ThisObject), True);
			RecalculateAmountsAtAdjustedVATRates = False; // The calculation of prices initializes the calculation of amounts.
		Else
			RecalculateAmountsAtAdjustedVATRates = True;
		EndIf;
		
		// We initialize an intermediate table with a guaranteed composition of columns
		//   and supplement it with intermediate calculation columns.
		TableOfGoods = Goods.Unload(); 
		TableOfGoods.Columns.Add("BusinessOperation", New TypeDescription("EnumRef.BusinessTransactions"));
		
		CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
		BatchProcessingOfTablePartServer.TreatTS(TableOfGoods, Actions, CachedValues);
		
		If RecalculateAmountsAtAdjustedVATRates
			And ValueIsFilled(CachedValues.ProcessedRows) Then
			
			BatchProcessingOfTablePartServer.ProcessTSStrings(
				CachedValues.ProcessedRows,
				PurchaseRequestClientServer.ActionsForRecalculatingAmount(PriceIncludesVAT, False, True),
				TableOfGoods,
				CachedValues);
			
		EndIf;
		
		Goods.Load(TableOfGoods);
		
	EndIf;
	
EndProcedure

Procedure InitializeDocument(FillingData)
	
	Author = Users.CurrentUser();
	
	If Not ValueIsFilled(Performer) Then
		Performer = Author;
	EndIf;
	
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	Department = SettingsValueCached.UserDivision(Author, Department);
	Warehouse = SettingsValueCached.GetDefaultWarehouse(Warehouse);
	
	If Not ValueIsFilled(Currency) Then
		Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	EndIf;
	
	If FillingData = Undefined
		Or TypeOf(FillingData) = Type("Structure") And Not FillingData.Property("Goods") Then
		// The document is entered without filling in the PM.
		OneDateReceipt = True;
	EndIf;
		
	If Not Documents.PurchaseRequest.UseBDRLimits() Then
		PurchaseObjective = PurchaseRequestClientServer.DefaultPurchaseTarget();
	EndIf;
	
EndProcedure

Procedure CheckToFillInReceiptByOneDate()

	OneDateReceipt = True;
	If Goods.Count() > 0 Then

		DateOfReceipt = Goods[0].RequestedDeliveryDate;
		
		For Each String In Goods Do

			If String.RequestedDeliveryDate <> DateOfReceipt Then
				OneDateReceipt = False;
			EndIf;
			
		EndDo;

		If OneDateReceipt Then
			RequestedDeliveryDate = DateOfReceipt;
		EndIf;

	EndIf;

EndProcedure

// According to the desired dates of receipt, searches for documents are performed, for example, execution of purchase plans.
Procedure FillInBlankDesiredDatesOfReceipt()
	
	QueriesTexts = New ValueList;
	Query = New Query;
	
	QueryText = 
	"SELECT
	|	Goods.LineNumber AS LineNumber,
	|	&StartDate AS StartDate,
	|	Goods.Terms AS Terms
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|WHERE
	|	Goods.RequestedDeliveryDate = DATETIME(1, 1, 1)";
	Query.SetParameter("Goods", Goods.Unload(, "LineNumber, Terms, RequestedDeliveryDate"));
	Query.SetParameter("StartDate", BegOfDay(CurrentSessionDate()));
	QueriesTexts.Add(QueryText, "Goods");
	
	QueryText =
	"SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.StartDate AS StartDate,
	|	ISNULL(Terms1.ShipmentDueDate, 0) + ISNULL(Terms1.DeliveryTime, 0) AS ShipmentDueDate
	|INTO SearchParameters
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN Catalog.TermsOfPurchaseFromVendors AS Terms1
	|		ON Goods.Terms = Terms1.Ref";
	QueriesTexts.Add(QueryText, "SearchParameters");
	
	QueryText = ProvisionInDocumentsServer.TempTableYearsOfEnterpriseSchedule();
	QueriesTexts.Add(QueryText, "YearsOfEnterpriseSchedule");
	
	QueryText = 
	"SELECT
	|	SearchParameters.LineNumber AS LineNumber,
	|	&DesiredDateOfReceiptIsRedefinable AS RequestedDeliveryDate
	|FROM
	|	SearchParameters AS SearchParameters
	|		INNER JOIN Document.PurchaseRequest AS PurchaseRequest
	|		ON (TRUE)";
	
	Substitutions = ProvisionInDocumentsServer.AddToDateAccordingToEnterpriseCalendar(
		"SearchParameters.StartDate", "SearchParameters.ShipmentDueDate");
	
	QueryText = StrReplace(QueryText,
		"&DesiredDateOfReceiptIsRedefinable",
		Substitutions.Field);
		
	QueryText = QueryText + "
	|		" + Substitutions.Joins;
		
	QueriesTexts.Add(QueryText, "Result");
	
	PackageResult = TMCommonUse.GetQueryResults(Query, QueriesTexts);
	QueryResult = PackageResult.Result; // QueryResult
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		RowOfGoods = Goods.Get(Selection.LineNumber - 1);
		FillPropertyValues(RowOfGoods, Selection);
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
