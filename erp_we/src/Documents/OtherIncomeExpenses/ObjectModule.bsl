
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If Not BusinessOperation = Enums.BusinessTransactions.TransferOfOtherExpensesBetweenBranchOffices Then
		NotCheckedAttributeArray.Add("CompanyRecipient");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	ItemsAndDimensionsSelectionParameters = Documents.OtherIncomeExpenses.ItemsAndDimensionsSelectionParameters(BusinessOperation);
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	OtherIncomeExpensesLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

EndProcedure

Procedure Filling(FillingData, StandardProcessing)

	InitializeDocument(FillingData);
	
	If TypeOf(FillingData) = Type("DocumentRef.VendorInvoice") Then
		
		DetailsForFillIn = Common.ObjectAttributesValues(FillingData, "Organization");
		FillPropertyValues(ThisObject, DetailsForFillIn);
		DocumentBasis = FillingData;
		FillInAreasOfActivityForAdmission(FillingData); 
		
	
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.OtherIncomeExpenses.ItemsAndDimensionsSelectionParameters(BusinessOperation);
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);

	OtherIncomeExpensesLocalization.Filling(ThisObject, FillingData, StandardProcessing);

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If Not GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities") Then
		
		For Each CurRow In OtherExpenses Do
			If Not ValueIsFilled(CurRow.AssetAndLiabilityItem) Then
				CurRow.AssetAndLiabilityItem = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceOtherLiabilities;
			EndIf;
		EndDo;
		For Each CurRow In OtherIncome Do
			If Not ValueIsFilled(CurRow.AssetAndLiabilityItem) Then
				CurRow.AssetAndLiabilityItem = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceOtherAssets;
			EndIf;
		EndDo;
		
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.OtherIncome
		Or BusinessOperation = Enums.BusinessTransactions.ReversalOfOtherIncome
		Or BusinessOperation = Enums.BusinessTransactions.IncomeReclassification Then
		OtherExpenses.Clear();
	Else
		OtherIncome.Clear();
	EndIf;
	
	For Each String In OtherExpenses Do
		If Not ValueIsFilled(String.DateRecord) Then
			String.DateRecord = Date;
		EndIf;
	EndDo;
	For Each String In OtherIncome Do
		If Not ValueIsFilled(String.DateRecord) Then
			String.DateRecord = Date;
		EndIf;
	EndDo;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "OtherExpenses,OtherIncome");
	
	//Setting up accounting accounts
	GLAccountSettingsServer.BeforeWrite(ThisObject,
		Documents.OtherIncomeExpenses.AccountingAccountSettings_(BusinessOperation));
	ItemsAndDimensionsSelectionParameters = Documents.OtherIncomeExpenses.ItemsAndDimensionsSelectionParameters(BusinessOperation);
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	OtherIncomeExpensesLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	OtherIncomeExpensesLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	OtherIncomeExpensesLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	OtherIncomeExpensesLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "OtherExpenses,OtherIncome");
	
EndProcedure

#EndRegion

#Region Private

#Region Other

Procedure InitializeDocument(FillingData = Undefined)

	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	Currency = Constants.ManagementAccountingCurrency.Get();
	EmployeeResponsible = Users.CurrentUser();
	
EndProcedure

Procedure FillInAreasOfActivityForAdmission(DocumentInflow)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	OtherExpenses.Department AS DebitBusinessUnit,
	|	OtherExpenses.LineOfBusiness AS CorLineOfBusiness,
	|	OtherExpenses.ExpenseItem AS CorExpenseItem,
	|	OtherExpenses.DimensionOfExpenses AS CorExpenditureDimension,
	|	SUM(OtherExpenses.Sum) AS Sum,
	|	SUM(OtherExpenses.AmountExcludingVAT) AS AmountExcludingVAT,
	|	SUM(OtherExpenses.SumCompl) AS SumCompl,
	|	SUM(OtherExpenses.PermanentDifference) AS PermanentDifference,
	|	SUM(OtherExpenses.CostTD) AS CostTD
	|FROM
	|	AccumulationRegister.OtherExpenses AS OtherExpenses
	|WHERE
	|	OtherExpenses.Recorder = &Ref
	|
	|GROUP BY
	|	OtherExpenses.Department,
	|	OtherExpenses.LineOfBusiness,
	|	OtherExpenses.ExpenseItem,
	|	OtherExpenses.DimensionOfExpenses
	|
	|UNION ALL
	|
	|SELECT
	|	ItemisedExpensesLots.Department,
	|	ItemisedExpensesLots.LineOfBusiness,
	|	ItemisedExpensesLots.ExpenseItem,
	|	ItemisedExpensesLots.DimensionOfExpenses,
	|	SUM(ItemisedExpensesLots.Cost),
	|	SUM(ItemisedExpensesLots.CostExcludingVAT),
	|	SUM(ItemisedExpensesLots.LocalCost),
	|	SUM(ItemisedExpensesLots.PermanentDifference),
	|	SUM(ItemisedExpensesLots.CostTD)
	|FROM
	|	AccumulationRegister.ItemisedExpensesLots AS ItemisedExpensesLots
	|WHERE
	|	ItemisedExpensesLots.Recorder = &Ref
	|	AND (ItemisedExpensesLots.ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|		OR ItemisedExpensesLots.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToInventoryCost))
	|
	|GROUP BY
	|	ItemisedExpensesLots.Department,
	|	ItemisedExpensesLots.LineOfBusiness,
	|	ItemisedExpensesLots.ExpenseItem,
	|	ItemisedExpensesLots.DimensionOfExpenses";
	
	Query.SetParameter("Ref", DocumentInflow);
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		BusinessOperation = Enums.BusinessTransactions.ExpenseReclassification;
		OtherExpenses.Load(QueryResult.Unload());
	Else
		Text = NStr("vi = 'Không có dữ liệu để phân loại lại chi phí';
					|ru = 'Нет данных для реклассификации расходов';
					|en = 'No data for expense reclassification'; fa = 'No data for expense reclassification';
					|it = 'Non ci sono dati per la riclassificazione delle spese';
					|pl = 'Brak danych dla ponownej klasyfikacji wydatków';
					|tr = 'Giderlerin tekrar sınıflandırılmasına dair veri yok'");
		Raise Text;
	EndIf;
	
EndProcedure


#EndRegion

#EndRegion

#EndIf
