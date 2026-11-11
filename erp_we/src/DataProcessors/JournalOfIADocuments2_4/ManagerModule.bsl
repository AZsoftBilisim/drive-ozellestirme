#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
EndProcedure

#EndRegion

#Region Private

// 
// Parameters:
//  Parameters - Structure - 
// 
// Returns:
//  FormattedString - The data of the workplace
Function WorkplaceData(Parameters) Export

	Hyperlink = Undefined;
	
	HyperLinkAcceptanceForAccounting = Undefined;
	
	If AccessRight("InteractiveInsert", Metadata.Documents.IntangibleAssetsInitialRecognition2_4)
		Or AccessRight("InteractiveInsert", Metadata.Documents.IntangibleAssetImprovement) Then
		
		HyperLinkAcceptanceForAccounting = HyperLinkAcceptanceForAccounting(Parameters);
		
		Hyperlink = New FormattedString(NStr("vi = 'Cần lập:';
											|ru = 'К оформлению:';
											|en = 'To register:'; fa = 'To register:';
											|it = 'In formalizzazione:';
											|pl = 'Do sporządzenia:';
											|tr = 'Düzenlenecek:'"), " ", HyperLinkAcceptanceForAccounting);
	
	EndIf;
		
	Return Hyperlink;
	
EndFunction

Function HyperLinkAcceptanceForAccounting(Parameters)

	ListOfRequests = New Array;
	
	QueryText = 
	"SELECT ALLOWED
	|	AvailableArticles.Ref AS Ref
	|INTO AvailableArticles
	|
	|FROM
	|	ChartOfCharacteristicTypes.ExpenseItems AS AvailableArticles
	|WHERE
	|	AvailableArticles.ExpensesOccur = VALUE(Enum.ExpenseTypes.CalculationOfNonCurrentAssetsVAlue)
	|	AND (AvailableArticles.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|		OR AvailableArticles.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|		OR AvailableArticles.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost))
	|	AND AvailableArticles.IntangibleAssetsAndRDExpenses
	|	
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	OtherExpenses.DimensionOfExpenses AS IntangibleAsset
	|INTO OtherExpenses
	|FROM
	|	AccumulationRegister.OtherExpenses.Balance(
	|			,
	|			(Organization = &Organization
	|					OR &Organization = VALUE(Catalog.Companies.EmptyRef))
	|				AND ExpenseItem IN (
	|					SELECT
	|						AvailableArticles.Ref
	|					FROM
	|				 		AvailableArticles)
	|			) AS OtherExpenses
	|WHERE
	|	(OtherExpenses.SumManBalance > 0
	|		OR OtherExpenses.SumManBalance > 0)
	|
	|INDEX BY
	|	IntangibleAsset";
	ListOfRequests.Add(QueryText);

	QueryText = IntangibleAssetsInitialRecognitionLocalization.QueryTextIAAcceptedForAccounting();
	If QueryText = Undefined Then
		QueryText = 
		"SELECT ALLOWED
		|	IntangibleAssetsAccountingProcedureManagementAccounting.IntangibleAsset AS IntangibleAsset
		|
		|INTO IntangibleAssetsAccountingProcedureManagementAccounting
		|
		|FROM
		|	InformationRegister.IntangibleAssetsAccountingProcedureManagementAccounting.SliceLast(
		|			&Date,
		|			IntangibleAsset IN (
		|				SELECT
		|					OtherExpenses.IntangibleAsset
		|				FROM
		|					OtherExpenses AS OtherExpenses)) AS IntangibleAssetsAccountingProcedureManagementAccounting
		|WHERE
		|	IntangibleAssetsAccountingProcedureManagementAccounting.State = VALUE(Enum.IntangibleAssetsStates.PostedInFinancialAccounting)
		|
		|INDEX BY
		|	IntangibleAsset	
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	IABookkeepingProcedureBookkeepingAndTaxAccounting.IntangibleAsset AS IntangibleAsset
		|
		|INTO IABookkeepingProcedureBookkeepingAndTaxAccounting
		|
		|FROM
		|	InformationRegister.IABookkeepingProcedureBookkeepingAndTaxAccounting.SliceLast(
		|			&Date,
		|			IntangibleAsset IN (
		|				SELECT
		|					OtherExpenses.IntangibleAsset
		|				FROM
		|					OtherExpenses AS OtherExpenses)) AS IABookkeepingProcedureBookkeepingAndTaxAccounting
		|
		|WHERE
		|	IABookkeepingProcedureBookkeepingAndTaxAccounting.BUState = VALUE(Enum.IntangibleAssetsStates.PostedInFinancialAccounting)
		|
		|INDEX BY
		|	IntangibleAsset	
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	IntangibleAssets.Ref AS IntangibleAsset
		|
		|INTO IAAcceptedForAccounting
		|
		|FROM
		|	Catalog.IntangibleAssets AS IntangibleAssets
		|
		|		INNER JOIN IntangibleAssetsAccountingProcedureManagementAccounting AS IntangibleAssetsAccountingProcedureManagementAccounting
		|		ON IntangibleAssetsAccountingProcedureManagementAccounting.IntangibleAsset = IntangibleAssets.Ref
		|
		|		INNER JOIN IABookkeepingProcedureBookkeepingAndTaxAccounting AS IABookkeepingProcedureBookkeepingAndTaxAccounting
		|		ON IABookkeepingProcedureBookkeepingAndTaxAccounting.IntangibleAsset = IntangibleAssets.Ref
		|	
		|INDEX BY
		|	IntangibleAsset";
	EndIf;
	ListOfRequests.Add(QueryText);
	
	QueryText =
	"SELECT TOP 1
	|	1
	|FROM
	|	OtherExpenses AS OtherExpenses
	|WHERE
	|	NOT TRUE IN (
	|			SELECT TOP 1
	|				TRUE
	|			FROM
	|				IAAcceptedForAccounting AS IAAcceptedForAccounting
	|			WHERE
	|				IAAcceptedForAccounting.IntangibleAsset = OtherExpenses.IntangibleAsset)";
	ListOfRequests.Add(QueryText);
	
	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	
	Query = New Query(QueryText);
	Query.SetParameter("Date", '000101010000');
	Query.SetParameter("Organization", Parameters.Organization);
	
	Result = Query.Execute();
	
	HyperlinkText = NStr("vi = 'Tiếp nhận vào kế toán';
						|ru = 'Принятие к учету';
						|en = 'Recognition'; fa = 'شناسایی';
						|it = 'Presa in considerazione';
						|pl = 'Przyjęcie do ewidencji';
						|tr = 'Muhasebeleştirme'");
	If Result.IsEmpty() Then
		ColorOfHyperlink = StyleColors.EmptyTableField;
	Else
		ColorOfHyperlink = Undefined;
	EndIf;
	
	Hyperlink = New FormattedString(HyperlinkText,, ColorOfHyperlink,, "#Recognition");
	
	Return Hyperlink;
	
EndFunction

// Generates a formatted string for displaying a hyperlink
// 
// Parameters:
// 	Parameters - Array of Structure, ValueTable -
// 	
// Returns:
//  FormattedString - The data of the workplace
Function CreateHyperlinkToBackgroundTaskLayout(Parameters) Export
	
	ToRegister = TMCommonUse.CreateHyperlinkToDesign(Parameters[0], Parameters[1]);
	Return ToRegister;
	
EndFunction

#EndRegion

#EndIf