#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Calculates the maximum series number that is already used for the item type
// or is already specified in the "series Table"value Table.
//
// Parameters:
//	ProductKind - CatalogRef.ItemKinds - the type of item that the series number is being searched for.
//
// Returns:
//   Number - serial number 
//
Function CalculateMaximumSeriesNumber(ProductKind)  Export 
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	ItemsBatches.Number
	|FROM
	|	Catalog.ItemsBatches AS ItemsBatches
	|WHERE
	|	ItemsBatches.ProductKind = &ProductKind
	|	AND NOT ItemsBatches.DeletionMark
	|	AND ItemsBatches.Number LIKE ""[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]""
	|
	|ORDER BY
	|	Number DESC";
	
	Query.SetParameter("ProductKind", ProductKind);
	Result = Query.Execute();
	If Result.IsEmpty() Then
		CodeValueAsNumber = 0;
	Else
		Selection = Result.Select();
		Selection.Next();

		DescriptionOfNumberType = New TypeDescription("Number");
		CodeValueAsNumber = DescriptionOfNumberType.AdjustValue(Selection.Number);
	EndIf;
	
	Return CodeValueAsNumber;
	
EndFunction

// Returns a table of missing serial numbers in the specified range.
//
// Parameters:
//	ProductKind - CatalogRef.ItemKinds - type of item to search for serial numbers for
//	InitialNumber - Number - starting number of the range
//	EndNumber - Number - starting number of the range
//	Count - Number - required number of missing numbers.
//
// Returns:
//   ValueTable - series
//		The series is a reference link.Series Nomenclature
//		Line Number
//
Function GenerateSeriesNumbersInRange(ProductKind, InitialNumber, EndNumber, Count) Export
	
	TableOfNumbers = New ValueTable;
	TableOfNumbers.Columns.Add("Number", New TypeDescription("String"));
	
	CurInitialNumber = InitialNumber;
	PortionSize = 10000; // the range of rooms can be very large, we will look for available rooms in small portions
	
	While CurInitialNumber <= EndNumber Do
		
		PortionNumbers = GetSeriesNumbersInRange(
			ProductKind,
			CurInitialNumber,
			Min(CurInitialNumber + PortionSize, EndNumber),
			False);
		
		For Each CurrRow In PortionNumbers Do
			
			TableOfNumbers.Add().Number = CurrRow.Number;
			If TableOfNumbers.Count() = Count Then
				Break;
			EndIf;
			
		EndDo;
		
		If TableOfNumbers.Count() = Count Then
			Break;
		EndIf;
		
		CurInitialNumber = CurInitialNumber + PortionSize;
		
	EndDo;
	
	Return TableOfNumbers;
	
EndFunction

// Returns a table of serial numbers in the specified range.
//
// Parameters:
//	ProductKind - CatalogRef.ItemKinds - type of item to search for serial numbers for
//	InitialNumber - Number - starting number of the range
//	EndNumber - Number - starting number of the range
//	FilterExistingOnes - Boolean - selection of existing / missing serial numbers; Undefined - no selection.
//
// Returns:
//   ValueTable - series
//		The series is a reference link.Series Nomenclature
//		Line Number
//
Function GetSeriesNumbersInRange(ProductKind, InitialNumber, EndNumber, FilterExistingOnes = Undefined) Export
	
	TableOfNumbers = New ValueTable;
	TableOfNumbers.Columns.Add("Number", New TypeDescription("String"));
	
	For BatchNumber = InitialNumber To EndNumber Do
		TableOfNumbers.Add().Number = Format(BatchNumber, "ND=8; NLZ=; NG=");
	EndDo;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	CAST(T.Number AS STRING(8)) AS Number
	|INTO TTNumbers
	|FROM
	|	&TableOfNumbers AS T
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Series,
	|	SetOfSeries.Number
	|FROM
	|	(SELECT
	|		ItemsBatches.Ref AS Series,
	|		TTNumbers.Number AS Number,
	|		CASE
	|			WHEN ItemsBatches.Ref IS NULL 
	|				THEN FALSE
	|			ELSE TRUE
	|		END AS Exists
	|	FROM
	|		TTNumbers AS TTNumbers
	|			LEFT JOIN Catalog.ItemsBatches AS ItemsBatches
	|			ON TTNumbers.Number = ItemsBatches.Number
	|				AND (ItemsBatches.ProductKind = &ProductKind)
	|				AND (NOT ItemsBatches.DeletionMark)) AS SetOfSeries
	|WHERE
	|	(&FilterExistingOnes = UNDEFINED
	|			OR SetOfSeries.Exists = &FilterExistingOnes)
	|
	|ORDER BY
	|	SetOfSeries.Number";
	
	Query.SetParameter("TableOfNumbers", 	TableOfNumbers);
	Query.SetParameter("ProductKind", 	ProductKind);
	Query.SetParameter("FilterExistingOnes", FilterExistingOnes);
	
	Result = Query.Execute().Unload();
	
	Return Result;
	
EndFunction

// Returns the names of attributes, which should not appear in the list of details of the processing Gruposeincentivos.
//
//	Returns:
//		Array - an array of the names of the details.
//
Function AttributesToSkipInBatchProcessing() Export
	
	NotAttributesToEdit = New Array;
	NotAttributesToEdit.Add("Number");
	
	Return NotAttributesToEdit;
	
EndFunction


// Returns an empty series object obtained in privileged mode. Used for 
// universal mechanisms.
//
// Parameters:
//	ProductKind	 - CatalogRef.ItemKinds - the item type that is the owner of the new item 
//															in the 'item Series' reference list.
//
// Returns:
//	CatalogObject.ItemsBatches - a new element of the 'Series of Nomenclature' directory.
//
Function EmptyObject(ProductKind) Export
	
	SetPrivilegedMode(True);
	
	EmptyBatch_ = Catalogs.ItemsBatches.CreateItem();
	EmptyBatch_.ProductKind = ProductKind;
	
	SetPrivilegedMode(False);
	
	Return EmptyBatch_;
	
EndFunction

#EndRegion

#EndIf

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	ProductsServerCall.ProductSeriesSelectionDataAcquisitionProcessing(ChoiceData, Parameters, StandardProcessing);
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#EndIf
#EndIf