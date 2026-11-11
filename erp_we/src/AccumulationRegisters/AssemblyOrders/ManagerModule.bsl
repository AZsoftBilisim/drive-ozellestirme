#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Supply

// Receives the quantity issued by invoices for orders.
//
// Parameters:
//  FilterTable		 - ValueTable	 - A table with the "Link" and "codebreak" fields, the rows must be unique.
//  FilterByDimensions	 - Structure - the structure key defines the name of the dimension to be selected for,
//  									and the structure value defines the desired value.
//  ExcludeOrder		 - Boolean - Flag that excludes the order from the list of issued invoices.
// 
// Returns:
//  ValueTable - A table with the fields "Link", "Code strings", "Quantity". For each pair, the Order-line code contains
//  the quantity issued by invoices.
//
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
		|	MAX(OrderRegister.Products)        AS Products,
		|	MAX(OrderRegister.Characteristic)      AS Characteristic,
		|	MAX(OrderRegister.ByAssemblyDisassemblyOrder.Warehouse) AS Warehouse,
		|	MAX(OrderRegister.Series)               AS Series,
		|	SUM(OrderRegister.ToRegister)            AS Count
		|FROM
		|	TTSelection AS Filter
		|		INNER JOIN AccumulationRegister.AssemblyOrders AS OrderRegister
		|		ON OrderRegister.ByAssemblyDisassemblyOrder = Filter.Ref
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
		Filter.Add("OrderRegister.ByAssemblyDisassemblyOrder <> OrderRegister.Recorder");
	EndIf;
	If ValueIsFilled(FilterByDimensions) Then
		For Each KeyValue In FilterByDimensions Do
			Query.SetParameter(KeyValue.Key, KeyValue.Value);
			Filter.Add("OrderRegister." + KeyValue.Key + " IN(&" + KeyValue.Key + ")");
		EndDo;
	EndIf;
	If ValueIsFilled(Filter) Then
		Query.Text = StrReplace(Query.Text, "&FilterOverridable", StrConcat(Filter, " And "));
	Else
		Query.Text = StrReplace(Query.Text, "&FilterOverridable", "TRUE");
	EndIf;
	
	SetPrivilegedMode(True);
	Table = Query.Execute().Unload();
	SetPrivilegedMode(False);
	Table.Indexes.Add("Ref, RowCode");
	
	Return Table;
	
EndFunction

#EndRegion

#Region States1

// Returns the request text for calculating the quantity of the product that remains to be assembled/disassembled.
// 
// Returns:
//  String - Query text
//
Function TemporaryTableOrderBalances() Export
	
	QueryText =
		"SELECT
		|	Table.ByAssemblyDisassemblyOrder   AS ReferenceOrder,
		|	Table.OrderedBalance AS QuantityOrderedInStorageUnits
		|INTO TTOrderBalances
		|FROM
		|	AccumulationRegister.AssemblyOrders.Balance(, ByAssemblyDisassemblyOrder IN(&AnArrayOfOrders)) AS Table";
	
	Return QueryText;
	
EndFunction

#EndRegion

// The text of the request receives the balance of the resources Fordesign and Ordered
// The remainder is supplemented with movements made by the invoice specified in the logger parameter.
//
// Parameters:
//  TempTableName	 - String - Put the result in a temporary table with the specified name.
// 
// Returns:
//  String - Query text
//
Function QueryTextBalance(TempTableName) Export
	
	QueryText =
	"SELECT
	|	Set.ByAssemblyDisassemblyOrder      AS ByAssemblyDisassemblyOrder,
	|	Set.Products       AS Products,
	|	Set.Characteristic     AS Characteristic,
	|	Set.RowCode          AS RowCode,
	|	Set.Series              AS Series,
	|	Set.AssemblyType          AS AssemblyType,
	|	SUM(Set.Ordered)    AS Ordered,
	|	SUM(Set.ToRegister) AS ToRegister
	|INTO TableNameOverridable
	|FROM(
	|	SELECT
	|		Table.ByAssemblyDisassemblyOrder      AS ByAssemblyDisassemblyOrder,
	|		Table.Products       AS Products,
	|		Table.Characteristic     AS Characteristic,
	|		Table.RowCode          AS RowCode,
	|		Table.Series              AS Series,
	|		Table.AssemblyType          AS AssemblyType,
	|		Table.OrderedBalance    AS Ordered,
	|		Table.ToRegisterBalance AS ToRegister
	|	FROM
	|		AccumulationRegister.AssemblyOrders.Balance(, ByAssemblyDisassemblyOrder IN(&References)) AS Table
	|
	|	UNION ALL
	|
	|	SELECT
	|		Table.ByAssemblyDisassemblyOrder  AS ByAssemblyDisassemblyOrder,
	|		Table.Products   AS Products,
	|		Table.Characteristic AS Characteristic,
	|		Table.RowCode      AS RowCode,
	|		Table.Series          AS Series,
	|		Table.AssemblyType      AS AssemblyType,
	|		Table.Ordered       AS Ordered,
	|		Table.ToRegister    AS ToRegister
	|	FROM
	|		AccumulationRegister.AssemblyOrders AS Table
	|	WHERE
	|		Table.Active
	|			AND Table.Recorder = &Recorder
	|			AND Table.RecordType = VALUE(AccumulationRecordType.Expense)
	|			AND Table.ByAssemblyDisassemblyOrder IN(&References)
	|	) AS Set
	|
	|GROUP BY
	|	Set.ByAssemblyDisassemblyOrder,
	|	Set.Products,
	|	Set.Characteristic,
	|	Set.RowCode,
	|	Set.Series,
	|	Set.AssemblyType
	|HAVING
	|	SUM(Set.ToRegister) <> 0
	|INDEX BY
	|	ByAssemblyDisassemblyOrder, RowCode";
	
	QueryText = StrReplace(QueryText, "TableNameOverridable", TempTableName);
	
	Return QueryText;
	
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowRead
	|WHERE
	|	ObjectReadingAllowed(ByAssemblyDisassemblyOrder)
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	ObjectUpdateAllowed(ByAssemblyDisassemblyOrder)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Private

#Region InfobaseUpdate

#EndRegion

#EndRegion

#EndIf