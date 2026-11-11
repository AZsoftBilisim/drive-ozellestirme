#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Receives the excise tax rate for the category of excisable items valid on the specified date.
//
// Parameters:
//  Category - CatalogRef.ExcisableGoodsCategories
//  Date - Date, Undefined - The date when the bid was up to date. If the value passed is Undefined,
//  							the last bid will be received.
//
// Returns:
//  Structure:
//   * Period - Date - start date of the bid application
//   * DateTo - Date - end date of bid application
//   * Rate1 - Number - value of the recorded bet
//   * NumberOfPeriods - Number - the number of recorded periods.
//
Function BidByCategoryAsOfDate(Category, Date = Undefined) Export
	
	Result = New Structure;
	Result.Insert("Period", '00010101');
	Result.Insert("DateTo", '00010101');
	Result.Insert("Rate1", 0);
	Result.Insert("NumberOfPeriods", 0);
	
	Query = New Query;
	Query.SetParameter("Date", Date);
	Query.SetParameter("Category", Category);
	Query.Text =
	"SELECT
	|	BidTable.Period AS Period,
	|	BidTable.Rate1 AS Rate1
	|INTO TableOfCurrentRates
	|FROM
	|	InformationRegister.RatesOfExcisableGoodsCategories.SliceLast(&Date, ExcisableGoodsCategory = &Category) AS BidTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Period AS Period
	|INTO TableOfBidHistory
	|FROM
	|	InformationRegister.RatesOfExcisableGoodsCategories AS Table
	|WHERE
	|	Table.ExcisableGoodsCategory = &Category
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BidTable.Period AS Period,
	|	BidTable.Rate1 AS Rate1
	|FROM
	|	TableOfCurrentRates AS BidTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DATEADD(BEGINOFPERIOD(Table.Period, DAY), SECOND, -1) AS DateTo
	|FROM
	|	TableOfBidHistory AS Table
	|WHERE
	|	Table.Period > &Date
	|
	|ORDER BY
	|	Table.Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	COUNT(1) AS NumberOfPeriods
	|FROM
	|	TableOfBidHistory AS TableOfBidHistory";
	
	QueryResult = Query.ExecuteBatch();
	
	If Not QueryResult[2].IsEmpty() Then
		Selection = QueryResult[2].Select();
		Selection.Next();
		FillPropertyValues(Result, Selection);
	EndIf;
	
	If Not QueryResult[3].IsEmpty() Then
		Selection = QueryResult[3].Select();
		Selection.Next();
		FillPropertyValues(Result, Selection);
	EndIf;
	
	If Not QueryResult[4].IsEmpty() Then
		Selection = QueryResult[4].Select();
		Selection.Next();
		FillPropertyValues(Result, Selection);
	EndIf;
	
	Return Result;
	
EndFunction

// Sets the excise tax rate for the category of excisable items as of the specified date.
//
// Parameters:
//  Category - CatalogRef.ExcisableGoodsCategories
//  Rate1 - Number
//  Date - Date - The start date of the bet.
//
Procedure SetBidByCategory(Category, Rate1, Date) Export
	
	Record = CreateRecordManager();
	Record.Period = Date;
	Record.ExcisableGoodsCategory = Category;
	Record.Rate1 = Rate1;
	Record.Write();
	
EndProcedure

#EndRegion

#EndIf
