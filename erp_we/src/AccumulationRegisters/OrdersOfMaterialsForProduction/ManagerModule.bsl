#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Supply

// Receives the quantity issued by invoices for orders.
// 
// Parameters:
// 	FilterTable - ValueTable - A table with the "Link" and "codebreak" fields, the rows must be unique.
// 	FilterByDimensions - Structure - the structure key defines the name of the dimension to be selected for,
//  									and the structure value defines the desired value.
// 	ExcludeOrder - Boolean - Flag that excludes the order from the list of issued invoices.
// Returns:
// 	ValueTable - A table with the fields "Link", "Code strings", "Quantity". For each pair, the Order-line code contains
//					the quantity issued by invoices.
Function TableDecorated(FilterTable, FilterByDimensions = Undefined, ExcludeOrder = False) Export

	QueryText =
		"SELECT
		|	Table.Ref    AS Ref,
		|	Table.RowCode AS RowCode
		|INTO TTSelection
		|FROM
		|	&FilterTable AS Table
		|WHERE
		|	Table.RowCode > 0
		|;
		|
		|////////////////////////////////////////
		|SELECT
		|	Filter.RowCode AS RowCode,
		|	Filter.Ref    AS Ref,
		|	MAX(OrderRegister.Products)   AS Products,
		|	MAX(OrderRegister.Characteristic) AS Characteristic,
		|	MAX(OrderRegister.Warehouse)          AS Warehouse,
		|	MAX(OrderRegister.Series)          AS Series,
		|	SUM(OrderRegister.ToRegister) AS Count
		|FROM
		|	TTSelection AS Filter
		|		INNER JOIN AccumulationRegister.OrdersOfMaterialsForProduction AS OrderRegister
		|		ON OrderRegister.ReferenceOrder = Filter.Ref
		|		 AND OrderRegister.RowCode = Filter.RowCode
		|		 AND OrderRegister.RecordType = VALUE(AccumulationRecordType.Expense)
		|		 AND OrderRegister.ToRegister <> 0
		|		 AND OrderRegister.Active
		|		 AND &FilterOverridable
		|GROUP BY
		|	Filter.Ref, Filter.RowCode";
	
	Query = New Query(QueryText);
	Query.SetParameter("FilterTable", FilterTable);
	
	Filter = New Array;
	If ExcludeOrder Then
		Filter.Add("OrderRegister.ReferenceOrder <> OrderRegister.Recorder");
	EndIf;
	If ValueIsFilled(FilterByDimensions) Then
		For Each KeyValue In FilterByDimensions Do
			Query.SetParameter(KeyValue.Key, KeyValue.Value);
			Filter.Add("OrderRegister." + KeyValue.Key + " IN(&" + KeyValue.Key + ")");
		EndDo;
	EndIf;
	
	Query.Text =
		StrReplace(
			Query.Text,
			"&FilterOverridable",
			?(ValueIsFilled(Filter), StrConcat(Filter, " And "), "TRUE"));
	
	SetPrivilegedMode(True);
	Table = Query.Execute().Unload();
	SetPrivilegedMode(False);
	Table.Indexes.Add("Ref, RowCode");
	
	Return Table;
	
EndFunction

#EndRegion

// The text of the request receives the balance of the resources Fordesign and Ordered
// The remainder is supplemented with movements made by the invoice specified in the logger parameter.
//
// Parameters:
//  TempTableName	 - String - Put the result in a temporary table with the specified name.
//  FilterByDimensions	 - Map - Key-left value: single field or fields separated by commas,
//										  and value-Structure-1. Key: "Comparison view"; Value-String-comparison operator in the request
//																	2. Key: "Rightvalue"; Value-String-a single field with an ampersand or a query to a table.
//  Expression			 - String - A condition for the HAVING by resources section.
//  								For example, a string of the form "Co-form <> 0" will be converted in the query text to:
//  								AMOUNT(Set.Co-registration) <> 0.
// 
// Returns:
//  String - Query text
//
Function QueryTextBalance(TempTableName = "", FilterByDimensions = Undefined, Expression = "") Export
	
	QueryText = 
	"SELECT
	|	Set.ReferenceOrder       AS ReferenceOrder,
	|	Set.Products       AS Products,
	|	Set.Characteristic     AS Characteristic,
	|	Set.RowCode          AS RowCode,
	|	Set.Series              AS Series,
	|	Set.Warehouse              AS Warehouse,
	|	Set.Recipient         AS Recipient,
	|	Set.Purpose         AS Purpose,
	|	Set.AssignmentSender AS AssignmentSender,
	|	SUM(Set.Ordered)    AS Ordered,
	|	SUM(Set.ToRegister) AS ToRegister
	|INTO TTName
	|FROM(
	|	SELECT
	|		Table.ReferenceOrder       AS ReferenceOrder,
	|		Table.Products       AS Products,
	|		Table.Characteristic     AS Characteristic,
	|		Table.RowCode          AS RowCode,
	|		Table.Series              AS Series,
	|		Table.Warehouse              AS Warehouse,
	|		Table.Recipient         AS Recipient,
	|		Table.Department      AS Department,
	|		Table.Purpose         AS Purpose,
	|		Table.AssignmentSender AS AssignmentSender,
	|		Table.OrderedBalance    AS Ordered,
	|		Table.ToRegisterBalance AS ToRegister
	|	FROM
	|		AccumulationRegister.OrdersOfMaterialsForProduction.Balance(, 
	|		&SelectionByMeasurementsRegister
	|			) AS Table
	|
	|	UNION ALL
	|
	|	SELECT
	|		Table.ReferenceOrder   AS ReferenceOrder,
	|		Table.Products   AS Products,
	|		Table.Characteristic AS Characteristic,
	|		Table.RowCode      AS RowCode,
	|		Table.Series          AS Series,
	|		Table.Warehouse          AS Warehouse,
	|		Table.Recipient     AS Recipient,
	|		Table.Department  AS Department,
	|		Table.Purpose     AS Purpose,
	|		Table.AssignmentSender AS AssignmentSender,
	|		Table.Ordered       AS Ordered,
	|		Table.ToRegister    AS ToRegister
	|	FROM
	|		AccumulationRegister.OrdersOfMaterialsForProduction AS Table
	|	WHERE
	|		Active
	|		AND Recorder = &Recorder
	|		AND RecordType = VALUE(AccumulationRecordType.Expense)
	|		AND &SelectionByMeasurementsOfStorno
	|	) AS Set
	|
	|GROUP BY
	|	Set.ReferenceOrder,
	|	Set.Products,
	|	Set.Characteristic,
	|	Set.RowCode,
	|	Set.Series,
	|	Set.Purpose,
	|	Set.AssignmentSender,
	|	Set.Warehouse,
	|	Set.Recipient
	|";
	
	If Not IsBlankString(Expression) Then
		
		If StrFind(Expression, "ToRegister") <> 0 Then
			Expression = StrReplace(Expression, "ToRegister", "SUM(Set.ToRegister)");
		EndIf;
		
		If StrFind(Expression, "Ordered") <> 0 Then
			Expression = StrReplace(Expression, "Ordered", "SUM(Set.Ordered)");
		EndIf;
		
		QueryText =
			QueryText +
			"
			|HAVING
			|	" + Expression;
		
	EndIf;
	
	QueryText =
		StrReplace(
			QueryText,
			"INTO TTName",
			?(IsBlankString(TempTableName), "","INTO " + TempTableName));
	
	If Not IsBlankString(TempTableName) Then
		QueryText = QueryText + 
			"
			|
			|INDEX BY
			|	ReferenceOrder, RowCode";
	EndIf;
	
	TextOfSelectionByMeasurements = "TRUE";
	If ValueIsFilled(FilterByDimensions) Then
		For Each KeyValue In FilterByDimensions Do
			
			LeftValue  		= KeyValue.Key;
			TypeOfRequestComparison = KeyValue.Value.ComparisonType;
			RightValue 		= KeyValue.Value.RightValue;
			
			TextOfSelectionByMeasurements =
			TextOfSelectionByMeasurements
			+ " And " + "(" + LeftValue + ") " + TypeOfRequestComparison + " (" + RightValue + ")";
			
		EndDo;
	EndIf;
	
	QueryText = StrReplace(QueryText, "&SelectionByMeasurementsRegister", TextOfSelectionByMeasurements);
	QueryText = StrReplace(QueryText, "&SelectionByMeasurementsOfStorno",  TextOfSelectionByMeasurements);
	
	Return QueryText;
	
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(ReferenceOrder.Organization)
	|	AND ValueAllowed(Warehouse)
	|	AND ValueAllowed(ReferenceOrder.Department)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#EndIf