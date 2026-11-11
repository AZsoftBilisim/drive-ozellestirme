#Region Public

// Performs processing of several rows of the collection in accordance with the operations listed in the action structure.
// When the method is executed, the data required for processing by a single request is pre-received.
// It should be used when it is required to process some rows of the table part, to preform an array 
// of rows of the table part and pass it to the String collection parameter, 
// specifying in the TAB part parameter the table part to which the elements of this array belong.
//
// Parameters:
//	RowsCollection - Array of FormDataCollectionItem, ValueTableRow- A collection that costs in 
//					and is the data source for processing. Based on this collection, a 
//					temporary table will be formed in the data source. The data of the received temporary table should be used to describe
//					the texts of the request for obtaining data necessary for processing all processed rows in the method
//					Complete the textsquestions of data sources. The collection must contain all the necessary columns,
//					the data from which will participate in data retrieval requests.
// StructureOfActions - Structure - Actions to be performed on the line. The name of the action is stored in the keys 
//					, and arbitrary data necessary for processing is stored in the values.
//	TabPart - FormDataCollection - The table part to which the processed rows from the parameter belong 
//				Collectionstrings. It is used to determine the composition of columns when forming a temporary table in 
//				a request for obtaining data on actions performed on an array of processed rows.
//	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure ProcessTSStrings(RowsCollection, StructureOfActions, TabPart, CachedValues = Undefined) Export
	
	#Region CheckingParameters 
	
	If Not RowsCollection.Count() Or Not StructureOfActions.Count() Then
		Return;
	EndIf;
	
	If CachedValues = Undefined 
		Or Not CachedValues.Count() Then
			CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	EndIf;
	
	// In the passed array of strings for processing, there may be strings that no longer exist in
	// the collection to which they belong. We delete such strings from the processed array of strings
	If Not CachedValues.Property("ProcessingSingleLine") Then
		LinesToDelete = New Array;
		For Each String In RowsCollection Do
			If TabPart.IndexOf(String) = -1 Then
				LinesToDelete.Add(String);
			EndIf;
		EndDo;
		
		For Each RowToDelete In LinesToDelete Do
			While RowsCollection.Find(RowToDelete) <> Undefined Do
				RowsCollection.Delete(RowsCollection.Find(RowToDelete));
			EndDo;
		EndDo;
				
		If Not RowsCollection.Count() Then
			Return;
		EndIf;
	EndIf;
	
	#EndRegion 
	
	#Region InitializingProcessingOfCollectionRows
	
	CachedValues.Insert("CollectionProcessing");
	
	If Not CachedValues.Property("ReadableFields") Then
		BatchProcessingOfTablePartClientServer.FieldsOfActionLine(
			RowsCollection[0], StructureOfActions, CachedValues);
	EndIf;
	
	DependentHandlers = DependentTSStringHandlers(StructureOfActions, CachedValues);
	ThereAreDependentHandlers = DependentHandlers.Count();
	
	Parameters = New Structure();
	Parameters.Insert("StructureOfActions", StructureOfActions);
	
	#EndRegion
	
	#Region ProcessingCollectionRows
	
	RowsCount = RowsCollection.Count();
	Counter = 0;
	ProcessedCollection = Undefined;
	
	While Counter < RowsCount Do
		
		CounterCurrentServing = 0;
		CurPortion = New Array;
		
		While CounterCurrentServing < 1000
			And Counter < RowsCount Do
			
				CurPortion.Add(RowsCollection[Counter]);
				CounterCurrentServing = CounterCurrentServing + 1;
				Counter = Counter + 1;
					
		EndDo;
			
		NumberOfRowsPerServing = CurPortion.Count();
			
		CachedValues.Delete("InitializationIsComplete");
		Parameters.Insert("RowsCollection", CurPortion);
		FirstLineOfCollection = CurPortion[0];
		
		If Not ThereAreDependentHandlers Then
			
			CachedValues.Insert("ThereAreDependentHandlers", False);
			
			ProcessedCollection = GetTableByCollection(CurPortion, TabPart, CachedValues);
		
			InitializeBatchProcessing(FirstLineOfCollection,
				StructureOfActions,
				CachedValues,
				ProcessedCollection,
				FirstLineOfCollection);
			
			ExecuteStringProcessingCode(Parameters, CachedValues, NumberOfRowsPerServing);
			
		Else
			
			CachedValues.Insert("ThereAreDependentHandlers", True);
			
			// Forming a queue for the execution of handlers in accordance with the described dependencies
			StructureOfActionsOrder = New Structure();
			
			For Each Handler In DependentHandlers Do
				StructureOfActionsOrder.Insert(Handler.Key, Handler.Value.Queue);
			EndDo;
			
			// Until the last queue is reached, a list of actions is generated.
			// A request is being made to get data only for them.
			CurrentQueue = 1;
			ProcessingCompleted = False;
			
			While Not ProcessingCompleted Do
				
				ProcessingCompleted = True;
				SkippedActions = New Structure();
				
				For Each ActionWithOrder In StructureOfActionsOrder Do
					If ActionWithOrder.Value = CurrentQueue Then
						ProcessingCompleted = False;
					Else
						SkippedActions.Insert(ActionWithOrder.Key, StructureOfActions[ActionWithOrder.Key]);
					EndIf;
				EndDo;
				
				CurrentQueue = CurrentQueue + 1;
				
				If ProcessingCompleted
					And SkippedActions.Count() = StructureOfActionsOrder.Count() Then
					Break;
				EndIf;
				
				CachedValues.Insert("SkippedActions", SkippedActions);
				CachedValues.Delete("InitializationIsComplete");
				
				// In order for the second and subsequent queues to process the result of the actions of the previous
				// queues, it is required to recreate the table of values for the processed collection
				// and transfer the processing result to a temporary table in the data source
				If CachedValues.Property("ProcessingSingleLine") Then
					If ProcessedCollection <> Undefined Then
						FillPropertyValues(ProcessedCollection[0], FirstLineOfCollection);
					Else
						ProcessedCollection = TableOfValuesForCurrentRow(
							FirstLineOfCollection,
							StructureOfActions,
							CachedValues);
					EndIf;
				Else
					ProcessedCollection = GetTableByCollection(
						CurPortion, TabPart, CachedValues);
				EndIf;
					
				InitializeBatchProcessing(
					FirstLineOfCollection,
					StructureOfActions,
					CachedValues,
					ProcessedCollection,
					FirstLineOfCollection);
			
				ExecuteStringProcessingCode(Parameters, CachedValues, NumberOfRowsPerServing);
					
				If CachedValues.Property("ProcessingSingleLine") Then
					For Each Column In CachedValues.CollectionColumns Do
						If CommonClientServer.HasAttributeOrObjectProperty(FirstLineOfCollection, Column.Name)
							And FirstLineOfCollection[Column.Name] = Null Then
								FirstLineOfCollection[Column.Name] = Undefined;
						EndIf;
					EndDo;
				EndIf
			EndDo;
		EndIf;
	EndDo;
	
	#EndRegion
	
	#Region ClearingServiceData
	
	RemoveUnsupportedTypesOnClient(CachedValues);
	ClearServiceCache(CachedValues);
	ClearActionParameters(StructureOfActions);
	
	If TypeOf(TabPart) = Type("ValueTable")
		And TabPart.Columns.Find("IdOfTTRow") <> Undefined Then
			TabPart.Columns.Delete("IdOfTTRow");
	EndIf;
	
	#EndRegion
	
EndProcedure

// Performs processing of one row of the collection in accordance of operations listed in the action structure.
// When the method is executed, the data required for processing by a single request is pre-received.
// It should be used in cases where processing does not take place in a cycle, for example, when filling in the VAT Rate when
// changing the nomenclature in the tabular part.
//
// Parameters:
//	CurrentRow - Structure, FormDataCollectionItem, ValueTableRow, DocumentObject, ClientApplicationForm -
//					the data that needs to be processed in accordance with the structure of the data.
//	StructureOfActions - See ProcessTSStrings.StructureOfActions.
//	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//	Collection -See ProcessTSStrings.TabPart.
//
Procedure ProcessTSString(CurrentRow, StructureOfActions, CachedValues, Collection = Undefined) Export
	
	If Not StructureOfActions.Count() Then
		Return;
	EndIf;
	
	If CachedValues = Undefined 
		Or Not CachedValues.Count() Then
			CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	EndIf;
		
	If TypeOf(CurrentRow) = Type("Structure") And Not CurrentRow.Property("LineNumber") Then 
		DeleteLineNumber = True
	Else
		DeleteLineNumber = False;
	EndIf;
	
	CachedValues.Insert("ProcessingSingleLine");
	
	TKInOneLine = TableOfValuesForCurrentRow(CurrentRow, StructureOfActions, CachedValues);
	StringInArray = CommonClientServer.ValueInArray(CurrentRow);
	
	ProcessTSStrings(StringInArray, StructureOfActions, TKInOneLine, CachedValues);
	RemoveUnsupportedTypesOnClient(CachedValues);
	CachedValues.Delete("InitializationIsComplete");
	CachedValues.Delete("MethodsForImplementation");
	
	If TypeOf(CurrentRow) = Type("Structure") Then
		CurrentRow.Delete("IdOfTTRow");
	EndIf;
	If DeleteLineNumber Then
		CurrentRow.Delete("LineNumber");
	EndIf;

EndProcedure

// Performs processing of the entire collection according of operations listed in the action structure.
// When the method is executed, the data required for processing by a single request is pre-received.
//
// Parameters:
//	TabularSection - FormDataCollection, ValueTable, TabularSection - The collection being processed.
//	StructureOfActions - See ProcessTSStrings.StructureOfActions.
//	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure TreatTS(TabularSection, StructureOfActions, CachedValues = Undefined) Export
	
	ProcessTSStrings(TabularSection, StructureOfActions, TabularSection, CachedValues);
	
EndProcedure

// Adds a description of the query text to get all the necessary data needed to process rows in the table part.
//
// Parameters:
//	QueryDetails - See QueryDetails
//	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//	
Procedure AddDataSource(QueryDetails, CachedValues) Export
	
	If Not CachedValues.Property("ExternalDescriptionOfRequest") Then
		CachedValues.Insert("ExternalDescriptionOfRequest", QueryDetails());
	EndIf;
	
	For Each QueryText In QueryDetails.QueriesTexts Do
		CachedValues.ExternalDescriptionOfRequest.QueriesTexts.Add(QueryText.Value, QueryText.Presentation);
	EndDo;
	
	CommonClientServer.SupplementStructure(CachedValues.ExternalDescriptionOfRequest.QueryOptions, QueryDetails.QueryOptions);
	
EndProcedure

// Checks if there is a column in the collection being processed.
//
// Parameters:
//	ColumnName - String - Name of the column to check for.
//	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
// Returns:
//  Boolean - Indicates whether there is a column in the collection being processed.
//
Function ThereIsColumnInDataSource(ColumnName, CachedValues) Export
	
	Return CommonClientServer.HasAttributeOrObjectProperty(
				CachedValues.CurrentRowInCollection,
				ColumnName);
	
EndFunction

// Returns the type of column in the collection being processed.
//
// Parameters:
//	ColumnName - String - The name of the column that will be added to the temporary table based on the entire collection.
//	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
// Returns:
//  TypeDescription - Type DescriptionThe type of column in the collection being processed.
//
Function ColumnTypeInDataSource(ColumnName, CachedValues) Export
	
	If ThereIsColumnInDataSource(ColumnName, CachedValues) Then
		Return TMCommonUse.DescriptionOfTypesByType(TypeOf(CachedValues.CurrentRowInCollection[ColumnName]));
	EndIf;
	
EndFunction

// Returns the description of the request required to get the necessary data for processing collection rows. 
//
// Returns:
//	Structure:
//		* QueriesTexts - ValueList of String - Query texts, the result of which will return 
//				all the necessary data for string processing. The text of the request should be placed in the value.
//				In the request name view, it should be passed to the Source name parameter when using
//				the Data processing method.
//		* QueryOptions - Structure - Request package parameters. The structure keys contain the names of the parameters
//				that are used in the request, in the values of the parameter values passed to the request.
//					* DataSource - ValueTable - The collection being processed, converted to a table of values. 
//		* AddlColumns       - Structure - Description of additional columns.
//		* PrivilegedMode - Boolean - Indicates whether privileged mode should be set before executing the request.
//
Function QueryDetails() Export
	
	QueryDetails = New Structure();
	QueryDetails.Insert("QueriesTexts", New ValueList());
	QueryDetails.Insert("QueryOptions", New Structure("DataSource"));
	QueryDetails.Insert("AddlColumns", New Structure());
	QueryDetails.Insert("PrivilegedMode", False);
	
	Return QueryDetails;
	
EndFunction

// Returns the data required to process the Cur row of the table part.
//
// Parameters:
//	SourceName - String - The name of the table in the query that is described in the additextextsquery of data sourcesreferences
//	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
// Returns:
//	ValueTable, Undefined - Query result with selection based on the query name and the currently processed string:
//
Function DataForStringProcessing(SourceName, CachedValues) Export
	
	Result = Undefined;
	CurrentRowInCollection = CachedValues.CurrentRowInCollection;
	If CachedValues.DataForProcessing <> Undefined
		And CachedValues.DataForProcessing.Property(SourceName) Then
			
			If CachedValues.Property("ProcessingSingleLine") Then
				Result = CachedValues.DataForProcessing[SourceName];
			Else
				PathToRowId = CachedValues.PathToRowId; 
				If PathToRowId = "GetID" Then
					RowID = CurrentRowInCollection.GetID();
				Else
					RowID = CurrentRowInCollection[PathToRowId];
				EndIf;
				
				FilterByLine = New Structure("IdOfTTRow", String(RowID));
				FoundRows = CachedValues.DataForProcessing[SourceName].Copy(FilterByLine);
			
				Result = ?(FoundRows.Count(), FoundRows, Undefined);
			EndIf;
		
	EndIf;
	
	If Result = Undefined Then
	
		FieldValues = New Array;
		For Each Column In CachedValues.CollectionColumns Do
			If CommonClientServer.HasAttributeOrObjectProperty(
					CurrentRowInCollection, Column.Name) Then
				FieldValues.Add(Column.Name + ":	" + CurrentRowInCollection[Column.Name]);
			EndIf;
		EndDo;
		
		LineDataInText = StrConcat(FieldValues, Chars.LF);
		ErrorText = StrTemplate(NStr("vi = 'Không thể lấy dữ liệu trong quá trình xử lý hàng loạt các dòng của phần bảng
										|Không có dữ liệu cho dòng có ID ""%1"" theo bảng ""%2"".
										|
										|Dữ liệu của dòng đang được xử lý:
										|
										|%3';
										|ru = 'Не удалось получить данные при пакетной обработке строк табличной части
										|Отсутствуют данные для строки с идентификатором ""%1"" по таблице ""%2"".
										|
										|Данные обрабатываемой строки:
										|
										|%3';
										|en = 'Cannot get data during batch processing of table rows
										|There is no data for the row with ID ""%1"" for the %2 table.
										|
										|Data of the processed row:
										|
										|%3'; fa = 'Cannot get data during batch processing of table rows
										|There is no data for the row with ID ""%1"" for the %2 table.
										|
										|Data of the processed row:
										|
										|%3';
										|it = 'Не удалось получить данные при пакетной обработке строк табличной части
										|Отсутствуют данные для строки с идентификатором ""%1"" по таблице ""%2"".
										|
										|Данные обрабатываемой строки:
										|
										|%3';
										|pl = 'Cannot get data during batch processing of table rows
										|There is no data for the row with ID ""%1"" for the %2 table.
										|
										|Data of the processed row:
										|
										|%3';
										|tr = 'Не удалось получить данные при пакетной обработке строк табличной части
										|Отсутствуют данные для строки с идентификатором ""%1"" по таблице ""%2"".
										|
										|Данные обрабатываемой строки:
										|
										|%3'"),
										RowID, SourceName, LineDataInText);
		
		If Common.DebugMode() Then
			Raise ErrorText;
		Else
			WriteLogEvent(
				NStr("vi = 'Xử lý hàng loạt các dòng trong phần dạng bảng.';
					|ru = 'Пакетная обработка строк в табличной части.';
					|en = 'Batch processing of rows in the table.'; fa = 'Batch processing of rows in the table.';
					|it = 'Пакетная обработка строк в табличной части.';
					|pl = 'Batch processing of rows in the table.';
					|tr = 'Tablodaki satırların toplu işlenmesi.'", Common.DefaultLanguageCode()),
				EventLogLevel.Error,,,
				ErrorText);
		EndIf;
	
	EndIf;
		
	Return Result;
	
EndFunction

// Checks whether an action needs to be performed with a string, based on the presence of an action in the action structure and the dependency
// of handlers. Sets the values of the passed parameters from the action to the Parameter variable.
// 
// Parameters:
//  ActionName - String - The name of the action to be performed on the line, for example, "Fill in the Seconds".
//  StructureOfActions - See ProcessTSStrings.StructureOfActions.
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//  Parameters - Arbitrary - Additional parameters required to process the string with the current action.
// 
// Returns:
//  Boolean - Indicates whether the action needs to be performed.
//
Function YouNeedToPerformAction(ActionName, StructureOfActions, CachedValues, Parameters = Undefined) Export
	
	Actions = StrSplit(ActionName, ",");
		
	For Each Action In Actions Do
		If StructureOfActions.Property(Action, Parameters) Then
			If CachedValues.Property("SkippedActions") Then
				If Not CachedValues.SkippedActions.Property(Action) Then
					Return True;
				EndIf;
			Else
				Return True;
			EndIf;
		EndIf;
	EndDo;
	
	Return False;
		
EndFunction

// Description of additional columns that will be filled in programmatically. Data in columns is required for more convenient
// processing of rows, rather than transferring logic to the DBMS side.
//
// Parameters:
//  QueryDetails - See QueryDetails
//  ColumnName - String - The name of the column to add to the temporary table with the collection being processed.
//  TypeDetails - TypeDescription - The type of column to add.
//
Procedure AddDataSourceColumns(QueryDetails, ColumnName, TypeDetails) Export
	
	QueryDetails.AddlColumns.Insert(ColumnName, TypeDetails);

EndProcedure

// Procedure-Checks that the key for filling in service details is supported
//
// Parameters:
//  ActionKey - String	 - the key to check.
// 
// Returns:
//  Boolean - The key for filling in service details is supported
Function KeyForFillingInServiceDetailsIsSupported(ActionKey) Export
	Return TemplateForActionKeySelectionField(ActionKey, True) <> Undefined;
EndFunction

// Converts a collection row to a table part.
//
// Parameters:
//  CollectionRow - String of Value tables, dataformelementcollection
//  StructureOfActions - See ProcessTSStrings.StructureOfActions
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
// Returns:
//  ValueTable
//
Function TableOfValuesForCurrentRow(CollectionRow, StructureOfActions, CachedValues) Export
	
	If Not TypeOf(CollectionRow) = Type("Structure") Then
		Line1_3 =
			BatchProcessingOfTablePartClientServer.GetCurLine(
				CollectionRow, StructureOfActions, CachedValues);
	Else
		Line1_3 = CollectionRow;
		If Not Line1_3.Property("LineNumber") Then
			Line1_3.Insert("LineNumber", 0);
		EndIf;
	EndIf;
	
	For Each Property In Line1_3 Do
		If Not CommonClientServer.HasAttributeOrObjectProperty(CollectionRow, Property.Key)
				And Property.Key <> "LineNumber" Then
					Line1_3.Delete(Property.Key);
		EndIf;;
	EndDo;
		
	SourceTable1 = New ValueTable();
	
	TypeForValueIsUndefined = New Array;
	TypeForValueIsUndefined.Add(Type("Number"));
	TypeForValueIsUndefined.Add(Type("Boolean"));
	
	TypeDescription = New TypeDescription(TypeForValueIsUndefined);
	
	For Each Property In Line1_3 Do
		If Not Property.Value = Undefined Then
			If TypeOf(Property.Value) = Type("String") Then
				StringTypeDetails = New TypeDescription("String",,,,
					New StringQualifiers(1024, AllowedLength.Variable));
				SourceTable1.Columns.Add(
					Property.Key,
					StringTypeDetails);
			Else
				SourceTable1.Columns.Add(
					Property.Key,
					TMCommonUse.DescriptionOfTypesByType(TypeOf(Property.Value)));
			EndIf;
		Else
			SourceTable1.Columns.Add(
				Property.Key,
				TypeDescription);
		EndIf;
	EndDo;
		
	FillPropertyValues(SourceTable1.Add(), Line1_3);
	
	Return SourceTable1;
	
EndFunction

// Clear the service cache.
// 
// Parameters:
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure ClearServiceCache(CachedValues) Export
	
	CacheToDelete = New Array(); 
	CacheToDelete.Add("DataForProcessing");
	CacheToDelete.Add("ThereAreDependentHandlers");
	CacheToDelete.Add("EditableFields");
	CacheToDelete.Add("InitializationIsComplete");
	CacheToDelete.Add("SingleLineProcessingCode");
	CacheToDelete.Add("CollectionWithCollectionWithCompositeType");
	CacheToDelete.Add("CollectionColumns");
	CacheToDelete.Add("MethodsForImplementation");
	CacheToDelete.Add("UnsupportedFieldsInRequest");
	CacheToDelete.Add("TabularPartIsBeingProcessed");
	CacheToDelete.Add("CollectionProcessing");
	CacheToDelete.Add("ProcessingSingleLine");
	CacheToDelete.Add("DescriptionOfFieldsByAction");
	CacheToDelete.Add("SkippedActions");
	CacheToDelete.Add("TSFieldStructureIsComplete");
	CacheToDelete.Add("CurrentRow");
	CacheToDelete.Add("CurrentRowInCollection");
	CacheToDelete.Add("ReadableFields");

	For Each Cache In CacheToDelete Do
		CachedValues.Delete(Cache);
	EndDo;
	
EndProcedure

#EndRegion

#Region Internal

// Updates parameters for calling methods for processing a row in the table part.
// 
// Parameters:
//  Parameters - Structure:
//  	* CurrentRow - See BatchProcessingOfTablePartServer.ProcessTSStrings
//  	* CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//  	* Counter - Number - Sequence number of the processed row in the collection.
//
Procedure UpdateCurrentLine(Parameters) Export
	
	Parameters.Insert("CurrentRow", Parameters.RowsCollection[Parameters.Counter]);
	Parameters.CachedValues.Insert("CurrentRowInCollection", Parameters.CurrentRow);
	Parameters.Counter = Parameters.Counter + 1;
	
EndProcedure

#Region StringHandlers

#Region ProceduresAndFunctionsOfFillingInServiceDetailsForProductRange

// Converts the action structure to be used in Gettextquestionservice_requisitamtch ()
// to calculate the required fields in a single query across the entire collection.
//
// Parameters:
// 		StructureOfActions - Structure - Structure with actions for getting service details.
//
Procedure NormalizeActions(StructureOfActions) Export
	
	Suffix = Undefined;
	If StructureOfActions.Property("RecalculateWeightVolume", Suffix)
		And TypeOf(Suffix) <> Type("Structure") Then
		NumberOfPackages = BatchProcessingOfTablePartClientServer.QuantityWithSuffix(Suffix).NumberOfPackages;
		StructureOfActions.Insert("RecalculateWeightVolume",
									New Structure(NumberOfPackages + ",Products,Package", "Weight,VolumeM3"));
	EndIf;
	
EndProcedure

// Returns the text of the selection request for the item's service details
//
// Parameters:
// 		StructureOfActions - Structure - Structure with names of service details as fields
// 		DatabaseStructure - Structure - Structure with additional data.
//
// Returns:
// 		String - a string with the request text.
//
Function GetRequestTextUsingServiceDetailsOfTS(StructureOfActions, DatabaseStructure, BatchProcessing = False) Export
	
	QueryTemplate = "";
	
	// Formation of a template for a temporary table query by nomenclature
	If BatchProcessing Then
		QueryTemplate = "
		|SELECT
		|	Table.IdOfTTRow AS IdOfTTRow, &SELECTText
		|INTO TTTableOfProducts
		|FROM
		|	&DataCollection AS Table;";
	Else
		QueryTemplate = "
		|SELECT
		|	CAST(Table.LineNumber AS NUMBER) AS LineNumber,
		|	TRUE AS IdOfTTRow, &SELECTText
		|INTO TTTableOfProducts
		|FROM
		|	&DataCollection AS Table;";
	EndIf;
	
	SelectTemplate_ = ",
	|	Table.%FieldName% AS %FieldName%";
	TemplateSelectProducts = ",
	|	CAST(Table.%FieldName% AS Catalog.Products) AS %FieldName%";
	
	SELECTText = "";
	For Each Field In DatabaseStructure.SourceStructure_1 Do
		If Field.Key = "Package" Then
			SELECTText = SELECTText + ",
			|	CAST(Table.Package AS Catalog.PackagesAndUnitsOfMeasure) AS Package";
		ElsIf Field.Key = "Purpose" Then
			SELECTText = SELECTText + ",
			|	CAST(Table.Purpose AS Catalog.Assignments) AS Purpose";
		ElsIf StrStartsWith(Field.Key, "Products") Then
			SELECTText = SELECTText + StrReplace(TemplateSelectProducts, "%FieldName%", Field.Key);
		Else
			SELECTText = SELECTText + StrReplace(SelectTemplate_, "%FieldName%", Field.Key);
		EndIf;
	EndDo;
	QueryTemplate = StrReplace(QueryTemplate, ", &SELECTText", SELECTText);
	
	// Main Sample Request Template
	If BatchProcessing Then
		PartOfRequestTemplate = "
		|///////////////////////////////////////////////////////////////////
		|SELECT
		|	TTTableOfProducts.IdOfTTRow AS IdOfTTRow, &SELECTText
		|FROM
		|	TTTableOfProducts AS TTTableOfProducts";
	Else
		
		PartOfRequestTemplate = "
		|///////////////////////////////////////////////////////////////////
		|SELECT
		|	TTTableOfProducts.LineNumber AS LineNumber, 
		|	TTTableOfProducts.IdOfTTRow AS IdOfTTRow, &SELECTText
		|FROM
		|	TTTableOfProducts AS TTTableOfProducts
		|
		|ORDER BY
		|	LineNumber";
	EndIf;
	
	BatchProcessingOfTablePartServerLocalization.WhenDefiningRequestTemplateUsingServiceDetailsOfTS(
		PartOfRequestTemplate, StructureOfActions, BatchProcessing);
		
	QueryTemplate = QueryTemplate + PartOfRequestTemplate;
	// Formation of the main selection request fields
	SELECTText = "";
	For Each Action In StructureOfActions Do
		If Not ActionException(Action) Then
			SelectTemplate_ = TemplateForActionKeySelectionField(Action.Key);
			If SelectTemplate_ <> Undefined Then
				For Each Field In Action.Value Do
					If ValueIsFilled(Field.Value) Then
						SELECTText = SELECTText + StrReplace(StrReplace(SelectTemplate_, "%ReplacementValue%", Field.Value), "%Key%", Field.Key);
					EndIf;
				EndDo;
			EndIf;
		 EndIf;
	EndDo;
	
	Return StrReplace(QueryTemplate, ", &SELECTText", SELECTText);
	
EndFunction

// Returns the structure of additional information for getting service details
//
// Parameters:
// 		StructureOfActions - Structure - Structure with actions for getting service details.
//
// Returns:
// 		Structure
//
Function DescriptionOfAdditionalInformation(StructureOfActions) Export
	
	SourceStructure_1 = New Structure;
	FieldDetailsString = "";
	UploadDetailsString = "";
	
	For Each Action In StructureOfActions Do
		If ValueIsFilled(Action.Value) 
				And Not ActionException(Action) Then
			For Each Field In Action.Value Do
				If Not SourceStructure_1.Property(Field.Key) Then
					SourceStructure_1.Insert(Field.Key);
					UploadDetailsString = UploadDetailsString + ", " + Field.Key;
				EndIf;
				If ValueIsFilled(Field.Value) Then
					FieldDetailsString = FieldDetailsString + ", " + Field.Value;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
	Return New Structure(
		"SourceStructure_1, DetailsOfFillingInForm, UploadDetails",
		SourceStructure_1,
		Mid(FieldDetailsString, 2), // Cut off the first character of the string, because it is a comma
		UploadDetailsString);
	
EndFunction

#EndRegion

Procedure FillInHSCodeForProductsInTSLine(CurrentRow, StructureOfActions, CachedValues = Undefined) Export
	
	Var VATTaxation;

	StructureOfActions.Property("FillInHSCode", VATTaxation);
	If VATTaxation = Enums.VATTaxationTypes.ExportSale 
		Or VATTaxation = Undefined Then
		CurrentRow.FEACNCode = DataForStringProcessing(
									"HSCodeByItem", CachedValues)[0].FEACNCode;
	Else
		CurrentRow.FEACNCode = Catalogs.FEACN.EmptyRef();
	EndIf;
	
EndProcedure

Procedure FillInFlagForWhetherThereIsProductSoldJointly(String, Actions, CachedValues) Export
	
	DataForProcessing = DataForStringProcessing("ProductsSoldTogether", CachedValues); 
	If Not DataForProcessing = Undefined Then
		String.IndexGoodsSoldTogether = ?(DataForProcessing[0].ItemIsSoldJointly, 1, 0);
	EndIf;
	
EndProcedure

//@skip-check org.eclipse.xtext.diagnostics.Diagnostic.Syntax
Procedure FillInBidNDSVLineTS(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var StructureOfActionParameters;
	Var SpecifiedVATRate;
	Var OutgoingDocument;
	
	StructureOfActions.Property("FillInVATRate", StructureOfActionParameters);
		
	If StructureOfActionParameters.Property("BusinessOperation") Then
		BusinessOperation = StructureOfActionParameters.BusinessOperation;
	Else
		BusinessOperation = Enums.BusinessTransactions.EmptyRef();
	EndIf;
	
	If SalesServer.BusinessTransactionWithRateWithoutVAT(BusinessOperation) Then
		CurrentRow.VATRate = Catalogs.VATRates.EXCLUDINGVAT;
	Else
		
		If StructureOfActionParameters.VATTaxationAtTabularPart Then
			VATTaxation = CurrentRow.VATTaxation;
		Else
			VATTaxation = StructureOfActionParameters.VATTaxation;
		EndIf;
		
		Date = StructureOfActionParameters.Date;
		CachedValues.Insert("CompanyForVATRate", StructureOfActionParameters.Organization);

		Products = Undefined;
		If CommonClientServer.HasAttributeOrObjectProperty(CurrentRow, "Products") Then
			Products = CurrentRow.Products;
		EndIf;
		
		If StructureOfActionParameters.Property("ByShipmentDate") 
			And StructureOfActionParameters.ByShipmentDate
			And CommonClientServer.HasAttributeOrObjectProperty(CurrentRow, "DateOfShipment")
			And ValueIsFilled(CurrentRow.DateOfShipment) Then
			Date = CurrentRow.DateOfShipment;
		EndIf;
		
		CachedValues.Property("OutgoingDocument", OutgoingDocument);
		If OutgoingDocument = Undefined Then
			If StructureOfActionParameters.Property("InitializingIncomingDocument") Then 
				CachedValues.Insert("OutgoingDocument", Not StructureOfActionParameters.InitializingIncomingDocument);
			Else
				CachedValues.Insert("OutgoingDocument", False);
			EndIf;
		EndIf;
		
		StructureOfActionParameters.Property("SpecifiedVATRate", SpecifiedVATRate);
		CurrentRow.VATRate = VATAccountingERP.VATRateByItemAndTaxationInBatches(
			Products, VATTaxation, Date, CachedValues, SpecifiedVATRate);
		
		If Not ValueIsFilled(CurrentRow.VATRate)
				And ValueIsFilled(SpecifiedVATRate) Then

				If CachedValues.CurrentVATRates = Undefined Then
					FillInCurrentVATRatesCachedValues(StructureOfActionParameters, CachedValues);
				EndIf;
				CurrentVATRates = CachedValues.CurrentVATRates; //Array
				If CurrentVATRates.Find(SpecifiedVATRate) = Undefined Then
					Return;
				EndIf;
				CurrentRow.VATRate = SpecifiedVATRate;

		EndIf;

		If Not ValueIsFilled(CurrentRow.VATRate)
			And ValueIsFilled(SpecifiedVATRate) Then

			If CachedValues.CurrentVATRates = Undefined Then
				FillInCurrentVATRatesCachedValues(StructureOfActionParameters, CachedValues);
			EndIf;
			CurrentVATRates = CachedValues.CurrentVATRates; //Array
			If CurrentVATRates.Find(SpecifiedVATRate) = Undefined Then
				Return;
			EndIf;
			CurrentRow.VATRate = SpecifiedVATRate;

		EndIf;
		
	EndIf;
	
EndProcedure

Procedure FillInVATRateSuffixInTSLine(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var StructureOfActionParameters;
	Var OutgoingDocument;
	
	StructureOfActions.Property("FillInVATRateSuffix", StructureOfActionParameters);
	
	VATTaxation = StructureOfActionParameters.VATTaxation;
	Date = StructureOfActionParameters.Date;
	CachedValues.Insert("CompanyForVATRate", StructureOfActionParameters.Organization);
	
	Products = Undefined;
	If CommonClientServer.HasAttributeOrObjectProperty(CurrentRow, "Products") Then
		Products = CurrentRow.Products;
	EndIf;
	
	If StructureOfActionParameters.Property("ByShipmentDate") 
		And StructureOfActionParameters.ByShipmentDate
		And CommonClientServer.HasAttributeOrObjectProperty(CurrentRow, "DateOfShipment")
		And ValueIsFilled(CurrentRow.DateOfShipment) Then
		Date = CurrentRow.DateOfShipment;
	EndIf;
	
	CachedValues.Property("OutgoingDocument", OutgoingDocument);
	If OutgoingDocument = Undefined Then
		If StructureOfActionParameters.Property("InitializingIncomingDocument") Then 
			CachedValues.Insert("OutgoingDocument", Not StructureOfActionParameters.InitializingIncomingDocument);
		Else
			CachedValues.Insert("OutgoingDocument", False);
		EndIf;
	EndIf;
	
	Suffix = "";
	If StructureOfActionParameters.Property("Suffix", Suffix) 
		And Not ValueIsFilled(Suffix) Then
		Suffix = "";
	EndIf;
	RateWithSuffix = BatchProcessingOfTablePartClientServer.RateWithSuffix(Suffix);
	
	CurrentRow[RateWithSuffix.VATRate] = VATAccountingERP.VATRateByItemAndTaxationInBatches(
			Products, VATTaxation, Date, CachedValues);
	
EndProcedure

Procedure FillInVATRateByPriceTypeInTSLine(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var StructureOfActionParameters;
	
	StructureOfActions.Property("FillInVATRateByPriceType", StructureOfActionParameters);
	FillInVATRateBasedOnPriceTypeOfCurrentLine("VATRate", CurrentRow, StructureOfActionParameters, CachedValues, True);
	
EndProcedure

Procedure FillInVATRateSuffixByPriceTypeInTSLine(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var StructureOfActionParameters;
	
	StructureOfActions.Property("FillInVATRateSuffixByPriceType", StructureOfActionParameters);
		
	If ValueIsFilled(StructureOfActionParameters.Suffix) Then

		RateWithSuffix = BatchProcessingOfTablePartClientServer.RateWithSuffix(StructureOfActionParameters.Suffix);
		FillInVATRateBasedOnPriceTypeOfCurrentLine(RateWithSuffix.VATRate, CurrentRow, StructureOfActionParameters, CachedValues, False);

	EndIf;
	
EndProcedure

Procedure RecalculatePriceWithVAT(CurrentRow, StructureOfActions, CachedValues = Undefined) Export
	
	Var StructureOfActionParameters;
	Var VATRate;
	
	StructureOfActions.Property("RecalculatePriceWithVAT", StructureOfActionParameters);
		
	If StructureOfActionParameters = Undefined
	 Or StructureOfActionParameters.Property("VATRate", VATRate) = False Then
		VATRate = CurrentRow.VATRate;
	EndIf;
	
	VATPercentage = 0;
	DataForProcessing = DataForStringProcessing(
								"VATRateByRate", CachedValues);

	If DataForProcessing <> Undefined Then
		VATPercentage = DataForProcessing[0].Rate1;
	EndIf;
	
	CurrentRow.Price = CurrentRow.Price * (VATPercentage + 100)/100;
	
EndProcedure

Procedure AdjustNDSRateInPMLine(CurrentRow, StructureOfActions, CachedValues) Export 
	
	Var StructureOfActionParameters;
	Var ToReturnReusablePackage;
	Var ItemsType;
	Var OutgoingDocument;
	
	If StructureOfActions.Property("AdjustVATRate", StructureOfActionParameters) Then
		
		StructureOfActionParameters.Property("ToReturnReusablePackage", ToReturnReusablePackage);
		
		If StructureOfActionParameters.VATTaxationAtTabularPart Then
			VATTaxation = CurrentRow.VATTaxation;
		Else
			VATTaxation = StructureOfActionParameters.VATTaxation;
		EndIf;
		Date = StructureOfActionParameters.Date;
		
		If StructureOfActionParameters.Property("ByShipmentDate") 
			And StructureOfActionParameters.ByShipmentDate
			And CommonClientServer.HasAttributeOrObjectProperty(CurrentRow, "DateOfShipment")
			And ValueIsFilled(CurrentRow.DateOfShipment) Then
			Date = CurrentRow.DateOfShipment;
		EndIf;
		
		CachedValues.Property("OutgoingDocument", OutgoingDocument);
		If OutgoingDocument = Undefined Then
			If StructureOfActionParameters.Property("InitializingIncomingDocument") Then 
				CachedValues.Insert("OutgoingDocument", Not StructureOfActionParameters.InitializingIncomingDocument);
			Else
				CachedValues.Insert("OutgoingDocument", False);
			EndIf;
		EndIf;
				
		CachedValues.Insert("CompanyForVATRate", StructureOfActionParameters.Organization);
		
		Products = Undefined;
		If CommonClientServer.HasAttributeOrObjectProperty(CurrentRow, "Products") Then
			Products = CurrentRow.Products;
		EndIf;
		
		If ToReturnReusablePackage Then
			
			If CommonClientServer.HasAttributeOrObjectProperty(CurrentRow, "ItemsType") Then
				ItemsType = CurrentRow.ItemsType;
			ElsIf ValueIsFilled(Products) Then
				ItemsType = BatchProcessingOfTablePartServer.DataForStringProcessing(
					"ItemTypes_Packaging", CachedValues)[0].ItemsType;
			EndIf;
			
		EndIf;
		
		If ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage") Then
			VATRate = PredefinedValue("Catalog.VATRates.EXCLUDINGVAT");
		Else

			CheckRelevance = True;
			
			If CurrentRow.VATRate = PredefinedValue("Catalog.VATRates.EXCLUDINGVAT")
				And VATTaxation = PredefinedValue("Enum.VATTaxationTypes.SaleIsSubjectToVAT")
				And StructureOfActionParameters.FillingOnBasisOfCopying = False
				And Not StructureOfActionParameters.InitializingIncomingDocument Then
					CheckRelevance = False;
			EndIf;
			
			If CheckRelevance Then
				If DataForStringProcessing("RelevanceOfVATRate", CachedValues)[0].Relevant_ Then
					Return;
				EndIf;
			EndIf;
			
			VATRate = VATAccountingERP.VATRateByItemAndTaxationInBatches(
				Products, VATTaxation, Date, CachedValues);

		EndIf;
		
		If CurrentRow.VATRate <> VATRate Then
			
			CurrentRow.VATRate = VATRate;
			
			ProcessedRows = CachedValues.ProcessedRows; //Array
			ProcessedRows.Add(CurrentRow);
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure FillInItemCostAnalysisOfProductRange(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var StructureOfActionParameters;
	
	StructureOfActions.Property("FillInItemCostAnalysisOfProductRange", StructureOfActionParameters);
		
	IncomeAndExpensesServer.FillInArticleAndAnalyticsOfItemExpensesInBatches(
		CurrentRow, 
		StructureOfActionParameters,
		CachedValues);
	
EndProcedure

Procedure RecalculateAmountTakingIntoAccountRoundingErrorInTSLine(CurrentRow, StructureOfActions, CachedValues) Export
	
	Error_ = Undefined;
	ErrorsByLines = New Map;
	ActionParameters = Undefined;
	
	StructureOfActions.Property("RecalculateAmountTakingIntoAccountRoundingError", ActionParameters);
	If TypeOf(ActionParameters) = Type("Number") Then
		CurrentRow.Sum = CurrentRow.Sum + ActionParameters;
	ElsIf ActionParameters.Property("ErrorsByLines", ErrorsByLines) Then
		Error_ = ErrorsByLines.Get(CurrentRow);
		Error_ = ?(Error_ = Undefined, 0, Error_);
		CurrentRow.Sum = CurrentRow.Sum + Error_;
	ElsIf ActionParameters.Property("Error_", Error_) Then
		CurrentRow.Sum = CurrentRow.Sum + Error_;
	EndIf;
	
EndProcedure

Procedure RecalculateAmountOfNDSVInTSLine(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var StructureOfActionParameters;
	
	StructureOfActions.Property("RecalculateVATAmount", StructureOfActionParameters);
		
	VATTaxation = Undefined;
	StructureOfActionParameters.Property("VATTaxation", VATTaxation);
	CurPercentVAT = Undefined;
	
	VATRate = Undefined;
	If Not (StructureOfActionParameters <> Undefined And StructureOfActionParameters.Property("VATRate", VATRate)) Then
		BidData = DataForStringProcessing("VATRateByRate", CachedValues);
		If Not BidData = Undefined Then
			CurPercentVAT = BidData[0].Rate1;
		Else
			CurPercentVAT = 0;
		EndIf;
	EndIf;
	
	If CachedValues.Property("PercentOfVATRates")
		And CurPercentVAT = Undefined Then
		CurPercentVAT = CachedValues.PercentOfVATRates[VATRate];
	Else
		CachedValues.Insert("PercentOfVATRates", New Map);
	EndIf;

	If CurPercentVAT = Undefined Then
		CurPercentVAT = VATAccountingERPClientServer.ValueOfVATRate(VATRate);
		CachedValues.PercentOfVATRates.Insert(VATRate, CurPercentVAT);
	EndIf;
	
	CurrentRow.VATAmount = VATAccountingERPClientServer.CalculateVATAmount(CurrentRow.Sum,
																	CurPercentVAT,
																	StructureOfActionParameters.PriceIncludesVAT,
																	VATTaxation);
	
EndProcedure

Procedure RecalculateAmountOfVATSuffixInTSLine(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var StructureOfActionParameters;
		
	StructureOfActions.Property("RecalculateVATAmountSuffix", StructureOfActionParameters);
	
	VATTaxation = Undefined;
	StructureOfActionParameters.Property("VATTaxation", VATTaxation);
	
	Suffix = "";
	
	If StructureOfActionParameters.Property("Suffix", Suffix)
		And Not ValueIsFilled(Suffix) Then
		Suffix = "";
	EndIf;
	
	SumWithSuffix = BatchProcessingOfTablePartClientServer.SumWithSuffix(Suffix);
	
	BidData = DataForStringProcessing("VATRateSuffix", CachedValues);
	If Not BidData = Undefined Then
		VATRateByRate = BidData[0].Rate1;
	Else
		VATRateByRate = 0;
	EndIf;
	
	CurrentRow[SumWithSuffix.VATAmount] = VATAccountingERPClientServer.CalculateVATAmount(
		CurrentRow[SumWithSuffix.Sum],
		VATRateByRate,
		StructureOfActionParameters.PriceIncludesVAT,
		VATTaxation);

EndProcedure

Procedure RecalculateSaleAmountByAmountWithVAT(CurrentRow, StructureOfActions, CachedValues = Undefined) Export
	
	CurrentRow.SalesAmount = CurrentRow.AmountIncludingVAT;

EndProcedure

Procedure ClearExpenseAnalytics_(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var StructureOfActionParameters;
	
	StructureOfActions.Property("ClearExpenseAnalytics_", StructureOfActionParameters);
	IncomeAndExpensesServer.ClearExpenseAnalyticsItemInBatches(CurrentRow, StructureOfActionParameters, CachedValues);
	
EndProcedure

Procedure InitializeArticleAndAnalyticsAfterAddingLine(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var StructureOfActionParameters;
	
	StructureOfActions.Property("InitializeArticleAndAnalyticsAfterAddingLine", StructureOfActionParameters);
	IncomeAndExpensesServer.InitializeArticleAndAnalyticsAfterAddingLineInBatches(CurrentRow, StructureOfActionParameters, CachedValues);
	
EndProcedure

Procedure FillInTheDefaultAccountSetting(CurrentRow, StructureOfActions, CachedValues) Export
	Var StructureOfActionParameters;
	
	StructureOfActions.Property("FillInTheDefaultAccountSetting", StructureOfActionParameters);
	GLAccountSettingsServer.FillInDefaultAccountingAccountSettingsInBatches(
		CurrentRow,
		StructureOfActionParameters,
		CachedValues);
	Return; // The UT handler is empty
	
EndProcedure

// It is used to fill in the service Attributes of the document form ""Warehouse mandatory"".
// The Attribute is used to set the blank mark in the Warehouse field.
// In the tab line. parts, if the warehouse is indicated line by line, or in the header, if the warehouse is indicated in the header of the document.
// Mark the blank field in the document header if the conditions are met in at least one line of the document. 
// The blank mark is set if all the following conditions are met at the same time:
// - the Canceled attribute is not set in the line (if there is a cancellation attribute in the line)
// - the item type is ""Product"" or ""Multi-turn container"" (not a service or a job).
// In general, the mark is not filled in always when the blank field should be
// checked for filling out the document. And data from the field is needed for movements on PH Stocks and needs.
//
// Parameters:
//  CurrentRow - Structure - a structure with the properties of a document string.
//  Actions - Structure - structure with actions to be performed.
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure WhenChangingProductType(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var ActionParameters;
	
	StructureOfActions.Property("WhenChangingProductType", ActionParameters);
	
	If ActionParameters.Property("IsCanceled") And ActionParameters.IsCanceled Then
		Canceled = ActionParameters.IsCanceled And CurrentRow.Canceled;
	Else
		Canceled = False;
	EndIf;
	
	If ActionParameters.Property("ThereIsWriteOffForExpenses") And ActionParameters.ThereIsWriteOffForExpenses Then
		ToExpenseAs = CurrentRow.ToExpenseAs;
	Else
		ToExpenseAs = False;
	EndIf;
	
	ThisIsWork = ActionParameters.ThereAreWorks
		And (CurrentRow.ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5")
			Or CurrentRow.ItemsType = PredefinedValue("Enum.ItemsTypes.OperationService"));
	
	CurrentRow.WarehouseIsRequired = ?(ValueIsFilled(CurrentRow.ItemsType) And Not (ThisIsWork Or Canceled Or ToExpenseAs), 1, 0);
	
EndProcedure

// Fills in the following Attributes in the tab line. parts of the document: 
// - Support options (the "Action" field in the form of a document)
// - Separately
// Works only if the item is specified in the line.
// If the Separate Purchase/sale flag is set in the item, then for items with the Product and Work types, fill in the following:
//  Support options - To ensure that the flag is Separate - cocking.
// For items with the Multi-turn container and Service type, fill in the following:
//  The support option is not to provide, the flag Separately resets.
// If the Separate purchase/sale flag is not set in the item, then for items with Product types, the Multi-turn container should be filled in like this: 
//  Support option - To ensure that the flag is Separate - resets.
// For items with the Work, Service type, fill in the following:
//  The support option is not to provide, the flag Separately resets.
// There are special cases of filling in separate documents:
// a) In the giver's order - it is considered that the separate purchase sale flag is always set in the nomenclature
// b) In the customer's order / refund request, when the option "Order from the warehouse and under the order"
//    is set, the Separate Purchase Sale flag is considered to be set in any of the following cases:
//    - the flag Separate purchase sale is set in the nomenclature.
//    - the flag Separate purchase sale is set in the agreement.
//    - hoz. operation of the document Delivery under the principal.
// c) In the customer's order / refund request, when the "Order from warehouse" option is set
//    , the Separate Purchase and Sale flag is always reset, and the security option is filled
//    in based on the Status of the document and the type of item:
//    - in the Status For shipment / For shipment, Closed, Completed, set to Ship
//    - in Reserve Status / In the reserve it is set to reserve in a warehouse for goods and containers, Not to provide for Works and Services
//    - Statuses Under approval / On approval, For refund, Rejected is set Not to provide
// d) In the customer's order / refund request, if the order was created with the "Order as invoice" option set, the Do Not provide is set and the flag is separately reset
// . e) In Sales Management, OZON works as in the customer's order in the Status For shipment.
// f) The sales assistant works as in the customer's order (there is a Status in the assistant settings, there is an Agreement in the assistant header),
//    but there is a special case when a special "Simplified" mode is enabled in the assistant settings.
//    The flag is separately cocked or reset according to the rules of the customer's order.
//    The security option is determined depending on the selected security option in the assistant settings.
//    - if Ship is in the settings, then Ship is set for all types of items
//    - if you Reserve in a warehouse in the settings, then Reserve in a warehouse is set for items with the type of Goods and Containers
//      , Do Not provide for Services, set To secure for Work (if the flag is separately wound up) and Do Not provide if the flag is separately reset. 
//    - if you Reserve as received in the settings, then Reserve as received for items with the type of Goods and Containers
//      , Do Not provide for Services, set To Secure for Work (if the flag is separately wound up) and Do Not provide if the flag is separately reset.
//    - if in the settings To the provision, then for the item with the type of Goods and Containers is set to the provision,
//      for Services, it is set Not to provide, for Works it is set To provide (if the flag is separately wound up) and Not to provide if the flag is separately reset.
//    - if you do not provide in the settings, then Do Not provide for all types of items.
//
// Parameters:
//  CurrentRow - Structure - structure with the string properties of the document.
//  Actions - Structure - the structure with the actions that you want to produce.
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure CheckSoftwareInSalesDocument(CurrentRow, Actions, CachedValues) Export
	
	Var ActionParameters;
	If Actions.Property("CheckSoftwareInSalesDocument", ActionParameters) Then
		
		DataForProcessing = DataForStringProcessing("ProvisionInDocuments", CachedValues);
		FillingData = DataForProcessing[0];
		If Not ValueIsFilled(FillingData.Products) Then
			Return;
		EndIf;
		
		ItemsType = FillingData.ItemsType;
		If ItemsType = Enums.ItemsTypes.OwnGoods Then
			PropertyName = "OwnGoods";
		ElsIf ItemsType = Enums.ItemsTypes.Work_5 Then
			PropertyName = "Work_5";
		ElsIf ItemsType = Enums.ItemsTypes.OperationService Then
			PropertyName = "OperationService";
		ElsIf ItemsType = Enums.ItemsTypes.ReusablePackage Then
			PropertyName = "Tara";
		EndIf;
		
		// Filling in the security option.
		SecurityOptionAndFlagSeparately = ActionParameters.SecurityOptionAndFlagSeparately;
		
		If SecurityOptionAndFlagSeparately = Undefined Then
			
			OptionAndFlagAreTemporary = ProvisionInDocumentsClientServer.ProvisionOptionAndFlagAreSeparateByDefault(
				FillingData.AssignedPurchaseSale);
			
			SupplyOption = OptionAndFlagAreTemporary[PropertyName].SupplyOption;
			WithAssignment = OptionAndFlagAreTemporary[PropertyName].WithAssignment;
			
		ElsIf SecurityOptionAndFlagSeparately[PropertyName].WithAssignment = Undefined Then // the case when the provision option is overridden and the flag is not.
			
			OptionAndFlagAreTemporary = ProvisionInDocumentsClientServer.ProvisionOptionAndFlagAreSeparateByDefault(
				FillingData.AssignedPurchaseSale);
			SupplyOption = SecurityOptionAndFlagSeparately[PropertyName].SupplyOption;
			WithAssignment = OptionAndFlagAreTemporary[PropertyName].WithAssignment;
			If PropertyName = "Work_5" Then
				If WithAssignment And SupplyOption = Enums.SupplyOptions.NotRequired Then
					SupplyOption = Enums.SupplyOptions.ToSupply
				ElsIf Not WithAssignment And SupplyOption = Enums.SupplyOptions.ToSupply Then
					SupplyOption = Enums.SupplyOptions.NotRequired;
				EndIf;
			EndIf;
			
		Else
			
			SupplyOption = SecurityOptionAndFlagSeparately[PropertyName].SupplyOption;
			WithAssignment = SecurityOptionAndFlagSeparately[PropertyName].WithAssignment;
			
		EndIf;
		
		CurrentRow.SupplyOption = SupplyOption;
		CurrentRow.WithAssignment = WithAssignment;
		
	EndIf;
	
EndProcedure

// Used for:
// 
// 1) Filling in the service Attributes of the form of the document "Warehouse obligatory".
// The Attribute is used to set the blank mark in the Warehouse field.
// In the tab line. parts, if the warehouse is indicated line by line, or in the header, if the warehouse is indicated in the header of the document.
// Mark the blank field in the document header if the conditions are met in at least one line of the document. 
// The blank mark is set when all the following conditions are met at the same time:
// - the Canceled attribute is not set in the line (if there is a cancellation attribute in the line)
// - item type "Goods" or "Multi-turn container"
// - security option (field "Action" in line tab.parts) has one of the following values:
//     a) "Ship"
//     b) "Reserve in stock"
//     c) "To be secured" only if the document in the Cur Status (Status field in the document) makes movements
//        in the Inventory and requirements lines with the action "To be secured" (ready to be secured).
//     d) "Reserve as received", only if the document in the Cur (Status field in the document) makes movements 
//        in the Inventory and Needs PH lines with the action "Reserve as received" (ready to provide).
// In general, the mark is not filled in always when the blank field should be
// checked for filling out the document. And data from the field is needed for movements on PH Stocks and needs.
// The "ready for provision" conditions depend on the Status of the document and are specified in the request text in the procedure
// Available settings and embedding parameters in the Document Manager module. 
//
// 2) Filling in the service Attributes of the form "The shipping date is required"
// The Attributes are used to set the blank mark in the "Shipment Date" field (the field may be called differently).
// This is the same field that is used for document movements, by measuring the Date of the event (Date of Shipment)
// in PH Stocks and Needs.
// The blank mark is placed in the tab line. parts, if the date of shipment is indicated line by line, or in the header,
// if the date of shipment is the same for the entire document.
// Mark the blank field in the document header if the conditions are met in at least one line of the document. 
// The blank mark is set when all the following conditions are met at the same time:
// - the Canceled attribute is not set in the line (if there is a cancellation attribute in the line)
// - the security option (the "Action" field in the tab line.parts) "Ship"
// - the document is in the Status in which the order for shipment is issued
// PH Goods for shipment. 
// In general, the mark is not filled in always when the blank field should be
// checked for filling out the document. And data from the field is needed for movements along the PH of Goods for shipment.
// The "ready for shipment" conditions depend on the Status of the document and are specified in the request text in the procedure
// Available settings and embedding parameters in the Document Manager module.
//
// Parameters:
//  CurrentRow - Structure - structure with the string properties of the document.
//  Actions - Structure - the structure with the actions that you want to produce.
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure WhenChangingTypeOfProductOrSoftwareOption(CurrentRow, Actions, CachedValues) Export
	
	DataForProcessing = DataForStringProcessing("ProvisionInDocuments", CachedValues); 
	FillPropertyValues(CurrentRow, DataForProcessing[0], "DateOfShipmentRequired_,WarehouseIsRequired");
	
EndProcedure

// The action must be called when any of the following fields in the document line are changed:
// Nomenclature, Characteristics, Warehouse (for goods and containers) /Subdivision (for work), Purpose, Packaging, Separately
// The action calculates the column is available for the specified product and packaging analytics according to the data of the security registers.
// There are special cases for documents of the type "Order to the processor", "Order to the processor by stages", Processing "Editing the sequence of stages"
// In these cases, fields such as Division, Warehouse, Assignment can be taken not from the Cur tabular part but in another tabular part of the document. 
// Also, in these cases, in the document, the user can change the string binding to a specific shipment order, for example, a production stage.
// And since not only the free Balance is taken into account in the Available column, but also the reserve distributed according to the order with the Reserve action as received,
// then changing the order tied to the line causes a change in the value in the Available column.
//
// Parameters:
//  CurrentRow - Structure - structure with the string properties of the document.
//  Actions - Structure - the structure with the actions that you want to produce.
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure FillInAvailableColumn(CurrentRow, Actions, CachedValues) Export
	
	Var ActionParameters;
	
	Actions.Property("FillInAvailableColumn", ActionParameters);
		
	If Actions.Property("CheckNeedToUpdateColumnIsAvailable")
			And Actions.CheckNeedToUpdateColumnIsAvailable.UpdateColumnAvailable Then
		Return;
	EndIf;
	
	DataForProcessing = DataForStringProcessing("ProvisionInDocuments", CachedValues); 
	
	ProvisionInDocumentsServer.YouCanUpdateColumnWhenProcessingRowOfTablePartInBatches(
		CurrentRow,
		DataForProcessing,
		ActionParameters);
		
EndProcedure

// The action must be called ON changing any of the following fields in the document line:
// Nomenclature, Characteristics, Warehouse (for goods and containers) /Subdivision (for work), Purpose, Packaging, Separately.
//
// Parameters:
//  CurrentRow - Structure - structure with the string properties of the document.
//  Actions - Structure - the structure with the actions that you want to produce.
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure FillInCheckQualityDateOfQualityConfirmation(CurrentRow, Actions, CachedValues) Export
	
	DataForProcessing = DataForStringProcessing("FillInCheckQualityDateOfQualityConfirmation", CachedValues);
	QualityControl.FillInCheckQualityDateOfQualityConfirmation(CurrentRow, DataForProcessing[0],
		Actions);
	
EndProcedure

// The action must be called ON changing any of the fields in the document line that causes the Controlled Party field to change.
//
// Parameters:
//  CurrentRow - Structure - structure with the string properties of the document.
//  Actions - Structure - the structure with the actions that you want to produce.
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure FillInUnblockableDateOfQualityConfirmation(CurrentRow, Actions, CachedValues) Export
	
	DataForProcessing = DataForStringProcessing("FillInUnblockableDateOfQualityConfirmation", CachedValues);
	QualityControl.FillInUnblockableDateOfQualityConfirmation(CurrentRow, DataForProcessing[0],
		Actions);
	
EndProcedure

// The action must be called ON changing any of the fields in the document line that causes the sender's controlled party field to change.
//
// Parameters:
//  CurrentRow - Structure - structure with the string properties of the document.
//  Actions - Structure - the structure with the actions that you want to produce.
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure FillInSenderSControlledLotReference(CurrentRow, Actions, CachedValues) Export
	
	DataForProcessing = DataForStringProcessing("FillInSenderSControlledLotReference", CachedValues);
	QualityControl.FillInSenderSControlledLotReference(CurrentRow, DataForProcessing[0],
		Actions);
	
EndProcedure

// Called in cases when the security option changes in the line, including when the nomenclature changes, etc.
// Monitors situations when the provision option "Ship" or "Reserve in stock" has been set in the line.
// Or replaced this security option with any other. Such a change leads to the need to recalculate the column Available
// for this nomenclature and characteristics in the document. There are two possible cases:
// 1) There is another line of the same nomenclature and characteristics in the document, then the column update Available
//     must be performed in the document by a separate contextual server call, after performing all actions of the action structure
//     on all processed lines.
// 2) Such a nomenclature and characteristic in the document is only in the Cur line. In this case, to update the column
//    in the action structure, the action Fill In column is not available must be added. It will update the column Available
//    in the Cur row being processed.
//
// Parameters:
//  CurrentRow - Structure - structure with the string properties of the document.
//  Actions - Structure - the structure with the actions that you want to produce.
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure CheckNeedToUpdateColumnIsAvailable(CurrentRow, Actions, CachedValues) Export
	
	Var ActionParameters;
	Actions.Property("CheckNeedToUpdateColumnIsAvailable", ActionParameters);
	ProvisionInDocumentsServer.CheckNeedToUpdateColumnIsAvailable(CurrentRow, ActionParameters);
	
EndProcedure

// Called in cases when duplicates of the item and characteristics appear in the document. For example, when splitting lines with the command over the TS "Split lines".
// The action updates the service data that the action will need to check if the update column is available.
// Since the logic of this action is tied to the presence or absence in the document of two lines with the same nomenclature.
// The action RefreshcAshNomenclature does not need to be called if at least one of the following conditions is met:
//  - the action Check if the column needs to be updated is called.
//  - The Document servicerproviding method is called.Refresh Column is not available (updating column is available in the entire table part).
// Since in both cases, the service data for duplicates of the nomenclature and characteristics will be updated anyway. 
//
// Parameters:
//  CurrentRow - Structure - structure with the string properties of the document.
//  Actions - Structure - the structure with the actions that you want to produce.
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure UpdateProductCache_(CurrentRow, Actions, CachedValues) Export
	
	Var ActionParameters;
	Actions.Property("UpdateProductCache_", ActionParameters);
	ProvisionInDocumentsServer.UpdateProductCache_(CurrentRow, ActionParameters);
	
EndProcedure

// Used in the sales assistant.
// Fills in the Attributes of the Security option in the tabular part of the document with the value Ship
// If the line specifies the Order option + Implementation or Order + Transfer to the custodian. 
// It also fills in Ship if the "One security option" setting is disabled in the assistant
// and the Ship by one date flag is set and the shipment date "Today" is specified.
//
// Parameters:
//  CurrentRow - Structure - structure with the string properties of the document.
//  Actions - Structure - the structure with the actions that you want to produce.
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure FillInShipForOrderPlusImplementationOption(CurrentRow, Actions, CachedValues) Export
	
	Var ActionParameters;
	Actions.Property("FillInShipForOrderPlusImplementationOption", ActionParameters);
		
	If ActionParameters = True 
			Or CurrentRow.RegistrationOption = Enums.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice
			Or CurrentRow.RegistrationOption = Enums.OptionsOfRegisteringSalesDocuments.OrderTransfer Then
				CurrentRow.SupplyOption = Enums.SupplyOptions.Ship;
	EndIf;
	
EndProcedure

// Fills in the column "Quantity by RNPT" in the Cur line. The calculation is based on:
// 1. The value of the column "Quantity".
// 2. Conversion factor, which is calculated in the context of:
//		A. Organization.
//		B. Analysis of inventory items: Nomenclature, Characteristics, Warehouse (Storage location).
//		B. CCD number (RNPT).
// According to the specified section, entries are searched in:
//		A. RN Goods of the organization,
//		B. RN Goods transferred to the commission,
//		B. RN Goods for the preparation of reports to the committee,
//		G. RN Goods for the preparation of reports to the committee on purchases.
// The calculation is performed on the found records:
// Coefficient = Quantity / Quantity;
// If there is no record, and /or the CCD Number (RNPT) is passed empty, the coefficient is set to "1",
// i.e. "Quantity according to RNPT" is equated to "Quantity".
//
// Typical scenario:
// 10 pieces of goods were received, the user indicated the CCD number (RNPT)
// and changed the value in the "Quantity according to RNPT" field from 10 to 20.
// The user enters the following document with the same product and CCD (RNPT), enters the quantity.
// The system has read from memory that the coefficient = 2, and automatically sets
// the value in the column "Quantity according to RNPT" as "Quantity" * 2.
//
// Parameters:
//  CurrentRow - Structure - structure with the string properties of the document.
//  Actions - Structure - the structure with the actions that you want to produce.
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure RecalculateQuantityByRNPTVAndTS(CurrentRow, Actions, CachedValues) Export
	
	PropertyName = "RecalculateQuantityByRNPT";
	GetProductBatchIDInternalCoefficient(CurrentRow, Actions, CachedValues, PropertyName);
	
EndProcedure

// Fills in the column "Quantity according to RNPT" (another column name is supported) in the Cur line.
// The calculation is based on:
// 1. The value of the column "Quantity" (another column name is supported).
// 2. Conversion factor, which is calculated in the context of:
//		A. Organization.
//		B. Analysis of inventory items: Nomenclature, Characteristics, Warehouse (Storage location).
//		B. CCD number (RNPT).
// According to the specified section, entries are searched in:
//		A. RN Goods of the organization,
//		B. RN Goods transferred to the commission,
//		B. RN Goods for the preparation of reports to the committee,
//		G. RN Goods for the preparation of reports to the committee on purchases.
// The calculation is performed on the found records:
// Coefficient = Quantity / Quantity;
// If there is no record, and /or the CCD Number (RNPT) is passed empty, the coefficient is set to "1",
// i.e. "Quantity according to RNPT" is equated to "Quantity".
//
// Typical scenario:
// 10 pieces of goods were received, the user indicated the CCD number (RNPT)
// and changed the value in the "Quantity according to RNPT" field from 10 to 20.
// The user enters the following document with the same product and CCD (RNPT), enters the quantity.
// The system has read from memory that the coefficient = 2, and automatically sets
// the value in the column "Quantity according to RNPT" as "Quantity" * 2.
//
// Parameters:
//  CurrentRow - Structure - structure with the string properties of the document.
//  Actions - Structure - the structure with the actions that you want to produce.
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure RecalculateQuantityByRnptSuffixInTSLine(CurrentRow, Actions, CachedValues) Export
	
	PropertyName = "RecalculateQuantityByRNPTSuffix";
	GetProductBatchIDInternalCoefficient(CurrentRow, Actions, CachedValues, PropertyName);
	
EndProcedure

Procedure FillInServiceDetailsForProductInLineTS(CurrentRow, StructureOfActions, CachedValues) Export
	
	StructureOfFillingActions = ProductsServer.ActionsForFillingInDetailsOfItem(StructureOfActions);
	
	If StructureOfFillingActions.Count() <> 0 Then
		ProductsServer.FillInServiceDetailsForItemInBatchStructure(CurrentRow, StructureOfFillingActions, CachedValues);
	EndIf;
	
EndProcedure

Procedure FillInOrderWarehouseAttributeInTSLine(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var ActionParameters;
	
	StructureOfActions.Property("FillInOrderWarehouseAttribute", ActionParameters);
	
	CheckDate = CurrentSessionDate();
	NameOfAttributeField = "UseWarehouseManagemantSystemForGoodsSurplusesShortages";
	
	If TypeOf(ActionParameters) = Type("Structure")
		And ActionParameters.Property("NameOfAttributeField") Then
		NameOfAttributeField = ActionParameters.NameOfAttributeField;
	EndIf;
	
	If TypeOf(ActionParameters) = Type("Structure")
		And ActionParameters.Property("CheckDate") Then
		CheckDate = ActionParameters.CheckDate;
	EndIf;
	
	WarehouseDetails = DataForStringProcessing("FlagOfOrderWarehouse", CachedValues)[0];
	
	CurrentRow[NameOfAttributeField] = ValueIsFilled(WarehouseDetails.UseWarehouseManagemantSystemForGoodsSurplusesShortages)
								And WarehouseDetails.UseWarehouseManagemantSystemForGoodsSurplusesShortages
								And WarehouseDetails.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages <> Undefined
								And WarehouseDetails.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages <= CheckDate;
	
EndProcedure

Procedure FillInServiceDetailsForPurposeInLineTS(CurrentRow, StructureOfActions, CachedValues) Export

	Result = DataForStringProcessing("ServiceDetailsForPurpose", CachedValues)[0];
	FillPropertyValues(CurrentRow, Result);

EndProcedure

Procedure FillInCountryOfOriginOfProduct(CurrentRow, StructureOfActions, CachedValues) Export
	
	Result = DataForStringProcessing("CountryOfOriginOfProduct", CachedValues)[0];
	FillPropertyValues(CurrentRow, Result);
	
EndProcedure

Procedure CheckFillWarehouse(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var ActionParameters;
	
	If Not StructureOfActions.Property("CheckFillWarehouse", ActionParameters) Then
		Return;
	EndIf;
	
	WarehouseGroup_ = False;
	If ActionParameters.Property("WarehouseGroup_") Then
		WarehouseGroup_ = ActionParameters.WarehouseGroup_;
	EndIf;
	
	WarehouseFieldName = "Warehouse";
	If TypeOf(ActionParameters) = Type("Structure")
		And ActionParameters.Property("WarehouseFieldName") Then
		WarehouseFieldName = ActionParameters.WarehouseFieldName;
	EndIf;
	
	ToExpenseAs = False;
	If TypeOf(ActionParameters) = Type("Structure")
		And ActionParameters.Property("NameOfChargeToExpensesField") And ActionParameters.NameOfChargeToExpensesField <> "" Then
		ToExpenseAs = CurrentRow[ActionParameters.NameOfChargeToExpensesField];
	EndIf;
	
	DataForProcessing = DataForStringProcessing("CheckFillWarehouse", CachedValues)[0];
	
	ItemOrReusablePackaging =
		DataForProcessing.ItemsType = PredefinedValue("Enum.ItemsTypes.OwnGoods")
			Or DataForProcessing.ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage");
			
	DefaultWarehouse = PredefinedValue("Catalog.Warehouses.EmptyRef");
	
	If ValueIsFilled(CurrentRow.Products)
		And ItemOrReusablePackaging
		And Not ToExpenseAs
		And TypeOf(ActionParameters) = Type("Structure") Then
			If ActionParameters.Property("DefaultWarehouse") Then
				DefaultWarehouse = ActionParameters.DefaultWarehouse;
			ElsIf ActionParameters.Property("DefaultWarehouseFromCurrentLine") Then
				DefaultWarehouse = CurrentRow[WarehouseFieldName];
			EndIf;
	EndIf;
	
	If WarehouseGroup_
		And ItemOrReusablePackaging Then
		
		// Checking for the warehouse's entry into the hierarchy of the warehouse group
		If ValueIsFilled(CurrentRow[WarehouseFieldName])
			And ActionParameters.Property("WarehouseGroupLink")
			And ValueIsFilled(ActionParameters.WarehouseGroupLink)
			And (DataForProcessing.ClearWarehouse
				Or ToExpenseAs) Then
				CurrentRow[WarehouseFieldName] = PredefinedValue("Catalog.Warehouses.EmptyRef");
			Return;
		EndIf;
		
		If ValueIsFilled(CurrentRow.Products) Then
			Return;
		EndIf;
		
	EndIf;
	
	CurrentRow[WarehouseFieldName] = DefaultWarehouse;
	
EndProcedure


// Fills in the service flag of the department owner is available.
// The flag is raised if the line does not specify the giving purpose.
// If the flag is cocked, the "Product Owner" field becomes editable.
// If the flag is reset, the value of the "Product Owner" field is additionally cleared.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure FillInProductOwnerIsAvailable(CurrentRow, StructureOfActions, CachedValues) Export
	
	If Not StructureOfActions.Property("FillInProductOwnerIsAvailable") Then
		Return;
	EndIf;
	
	DataForProcessing = DataForStringProcessing("FINISHEDProductOwnerIsAvailable", CachedValues);
	
	CurrentRow.FINISHEDProductOwnerIsAvailable = DataForProcessing[0].FINISHEDProductOwnerIsAvailable;
	
	If Not CurrentRow.FINISHEDProductOwnerIsAvailable Then
		CurrentRow.ProductOwner = Undefined;
	EndIf;
	
EndProcedure

// Fills in the specification in a line based on the selected item, characteristic, division, and date.
//
// Parameters:
//  CurrentRow		 - Structure - data of the processed string.
//  StructureOfActions	 - Structure - describes actions, where the Key is the name of the action, and The value is the Structure - parameters of the action.
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure CheckFillSpecification(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var FillParameters;
	
	StructureOfActions.Property("CheckFillSpecification", FillParameters);
	
	FieldName = FillParameters.FieldNameSpecification;
	
	If ValueIsFilled(CurrentRow.Products) Then
		If TMCommonUseClientServer.HasObjectAttribute(CurrentRow, "ItemVariantsAreUsed")
			And CurrentRow.ItemVariantsAreUsed = True
			And Not ValueIsFilled(CurrentRow.Characteristic) Then
			Return;
		EndIf;
		
		SpecificationData = ProductDataManagementServerCall.ProductSpecification(
												FillParameters.ProductData,
												FillParameters.BOMSelectionParameters);
		
		If SpecificationData <> Undefined Then
			CurrentRow[FieldName] = SpecificationData.BillOfMaterials;
		Else
			CurrentRow[FieldName] = Undefined;
		EndIf;
	Else
		CurrentRow[FieldName] = Undefined;
	EndIf;
	
EndProcedure

// The Recipient fills in the field depending on the direction of the issue.
// If the issue is in the division, then the division of the parameters.
// If it is released to a warehouse, then it is a workshop storeroom by default, or a single warehouse (if the FO of several warehouses is disabled).
// If you write it off as expenses, then an empty link to the expense item.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure FillOutRecipientInDirectionOfIssue(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var ActionParameters;
	
	If Not StructureOfActions.Property("FillOutRecipientInDirectionOfIssue", ActionParameters) Then
		Return;
	EndIf;
	
	If CurrentRow.DirectionOfProductionIssue =
			PredefinedValue("Enum.BusinessTransactions.ProductsReleaseToBusinessUnit") Then
		
		If Not ValueIsFilled(CurrentRow.Recipient)
			Or TypeOf(CurrentRow.Recipient) <> Type("CatalogRef.BusinessStructure") Then
			CurrentRow.Recipient = ActionParameters.Department;
		EndIf;
		
	ElsIf CurrentRow.DirectionOfProductionIssue = 
				PredefinedValue("Enum.BusinessTransactions.ProductsReleaseToWarehouse") Then
		
		If ActionParameters.Property("UseSeveralWarehouses")
			And ActionParameters.UseSeveralWarehouses Then
			
			If Not ValueIsFilled(CurrentRow.Recipient) Then
				DataForProcessing = DataForStringProcessing("RecipientInDirectionOfIssue", CachedValues);
				If Not DataForProcessing = Undefined
					And DataForProcessing.Count() Then
					CurrentRow.Recipient = DataForProcessing[0].ShopFloorStockroom;
				EndIf;
			EndIf;
			
		Else
			CurrentRow.Recipient = ActionParameters.DefaultWarehouse;
		EndIf;
		
	ElsIf CurrentRow.DirectionOfProductionIssue =
				PredefinedValue("Enum.BusinessTransactions.GoodsConsumptionOnDemand") Then
		
		If TypeOf(CurrentRow.Recipient) = Type("CatalogRef.Warehouses")
			Or TypeOf(CurrentRow.Recipient) = Type("CatalogRef.BusinessStructure") Then
			CurrentRow.Recipient = 
				PredefinedValue("ChartOfCharacteristicTypes.ExpenseItems.EmptyRef");
		EndIf;
		
	EndIf;
	
EndProcedure

// Fills in the service flag of the shop floor.
// The flag is raised if the line is not charged to expenses and the Warehouse field indicates a workshop storeroom.
// If the flag is cocked, then, depending on the parameters, the Unit in the row with the value specified in the warehouse can be filled in.
// If the document has rounding mechanisms, then the service field you need to round is filled in with the inverse value of the Shop Floor flag.
//
// Parameters:
//	CurrentRow - Structure - structure with the string properties of the document.
//	StructureOfActions - Structure - the structure with the actions that you want to produce.
//	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure FillInShopPantryAttribute(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var FillParameters;
	
	If CommonClientServer.HasAttributeOrObjectProperty(CurrentRow, "ToExpenseAs")
		And CurrentRow.ToExpenseAs Then
		Return;
	EndIf;
	
	If Not StructureOfActions.Property("FillInShopPantryAttribute", FillParameters) Then
		Return;
	EndIf;
	
	FillInTheDepartment = False;
	If FillParameters <> Undefined
		And FillParameters.Property("FillInTheDepartment") Then
		FillInTheDepartment = FillParameters.FillInTheDepartment;
	EndIf;
	
	DataForProcessing = DataForStringProcessing("ShopFloorStockroomAttribute", CachedValues);
	If Not DataForProcessing = Undefined Then
		
		CurrentRow.ShopFloorStockroom = DataForProcessing[0].ShopFloorStockroom;
		
		If FillInTheDepartment And CurrentRow.ShopFloorStockroom Then
			CurrentRow.Department = DataForProcessing[0].Department;
		EndIf;
		
	EndIf;
	
	If CommonClientServer.HasAttributeOrObjectProperty(CurrentRow, "MustBeRoundOff") Then
		CurrentRow.MustBeRoundOff = Not CurrentRow.ShopFloorStockroom;
	EndIf;
	
EndProcedure
Procedure FillInCountryOfOriginForCCDNumber(CurrentRow, StructureOfActions, CachedValues = Undefined) Export
	
	CurrentRow.OriginCountry = DataForStringProcessing("CountryOfOriginByCCDNumber", CachedValues)[0].OriginCountry;
	
EndProcedure

Procedure FillInCCDNumberType(CurrentRow, StructureOfActions, CachedValues = Undefined) Export
	
	CurrentRow.CCDNumberType = DataForStringProcessing("CCDNumberType", CachedValues)[0].CCDNumberType;
	
EndProcedure

Procedure FillInTrafficFlagForWarehouseRegisters(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var FieldName;
	
	StructureOfActions.Property("FillInTrafficFlagForWarehouseRegisters", FieldName);
	DataForStringProcessing = DataForStringProcessing("SignOfRegisteringRecordsByWarehouseRegisters", CachedValues)[0];
	CurrentRow[FieldName] = DataForStringProcessing.RecordsInWarehouseRegisters;
	
EndProcedure

Procedure FillInServiceContent(CurrentRow, StructureOfActions, CachedValues = Undefined) Export
	
	Var StructureOfActionParameters;
	StructureOfActions.Property("FillInContent", StructureOfActionParameters);
		
	FillInForAllServices = Undefined;
	StructureOfActionParameters.Property("FillInForAllServices", FillInForAllServices);
	ProcessingServicesOfTollFreeRawMaterials = Undefined;
	If ValueIsFilled(CurrentRow.Products) And FillInForAllServices <> Undefined Then
	
		DataForStringProcessing = DataForStringProcessing("ServiceContent", CachedValues)[0];
			
		If FillInForAllServices
			And DataForStringProcessing.ItemsType <> Enums.ItemsTypes.OwnGoods 
			And DataForStringProcessing.ItemsType <> Enums.ItemsTypes.ReusablePackage Then
			
			CurrentRow.Content = ProductsClientServer.PresentationOfProductsForPrinting(
				DataForStringProcessing.ProductFullName, 
				DataForStringProcessing.CharacteristicFullName);
			
		ElsIf Not FillInForAllServices
			And (DataForStringProcessing.SaleRegistrationOption = Enums.SalesRegistrationOptions.CustomerInvoiceServices
			Or DataForStringProcessing.SaleRegistrationOption = Enums.SalesRegistrationOptions.DeedOfTransfer) Then
			
			CurrentRow.Content = ProductsClientServer.PresentationOfProductsForPrinting(
				DataForStringProcessing.ProductFullName, 
				DataForStringProcessing.CharacteristicFullName);
		ElsIf StructureOfActionParameters.Property("ProcessingServicesOfTollFreeRawMaterials", ProcessingServicesOfTollFreeRawMaterials)
			And ProcessingServicesOfTollFreeRawMaterials = True Then
			
			CurrentRow.Content = ProductsClientServer.PresentationOfProductsForPrinting(
				DataForStringProcessing.ProductFullName, 
				DataForStringProcessing.CharacteristicFullName);
		Else
			CurrentRow.Content = "";
		EndIf;
		
	Else
		CurrentRow.Content = "";
	EndIf;
		
EndProcedure

Procedure CheckGetConfigurationOption(CurrentRow, StructureOfActions, CachedValues) Export

	If ValueIsFilled(CurrentRow.Products) Then
		
		ResultStructureAffiliation = DataForStringProcessing(
													"BelongingOfConfigurationOptionToItemCharacteristic",
													CachedValues)[0];
		
		If Not ResultStructureAffiliation.BelongsToProductDescription = True Then
			
			ResultStructureAffiliation = DataForStringProcessing("MainConfigurationOption", CachedValues)[0];
			
			CurrentRow.ProductKit = ResultStructureAffiliation.MainConfigurationOption;
		
		EndIf;
		
	ElsIf Not ValueIsFilled(CurrentRow.Characteristic) And CurrentRow.ItemVariantsAreUsed Then 
		
		CurrentRow.ProductKit = Undefined;
		
	EndIf;

EndProcedure

Procedure FillInDataOnPurchaseDocumentInReportToPurchasingCommittee(CurrentRow, StructureOfActions, CachedValues) Export
	
	CurrentRow.Vendor = Undefined;
	CurrentRow.PurchaseDocumentType = New TypeDescription("Undefined");
	
	If Not CurrentRow.DocumentAcquisitions = Undefined Then
		
		CurrentRow.Vendor = DataForStringProcessing("DataOnPurchaseDocument", CachedValues)[0].Counterparty;
		
		TypesArray = New Array;
		TypesArray.Add(TypeOf(CurrentRow.DocumentAcquisitions));
		CurrentRow.PurchaseDocumentType = New TypeDescription(TypesArray);
		
	EndIf;
	
EndProcedure

// Calculates the share of the cost of output products. It works if the document uses one of the following
// options for allocating costs for output products: by planned cost, by weight, by volume.
//
Procedure CheckFillInCostShare(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var CostAllocationParameters;
	
	StructureOfActions.Property("CheckFillInCostShare", CostAllocationParameters);
	
	If ProductionClientServer.ShareOfCostIsCalculated(CurrentRow, CostAllocationParameters) Then
		
		CalculationResult2 = Undefined;
		
		If ValueIsFilled(CurrentRow.Products) Then
			DataForProcessing = DataForStringProcessing("CostShares", CachedValues);
			CalculationResult2 = ?(DataForProcessing = Undefined,
				ProductionClientServer.StructureOfShareValueFields(),
				DataForProcessing[0]);
		Else
			CalculationResult2 = ProductionClientServer.StructureOfShareValueFields();
		EndIf;
		
		ProductionClientServer.FillInCostFractionInLine(CurrentRow, CalculationResult2);
		
	EndIf;
	
EndProcedure

// Fills in the Attributes of the tabular part of the Security at the production stage: Support options, Warehouse, Separately.
// 
// Security option: for the nomenclature with the type of Work, it is set Not to provide, in other cases To provide.
// Warehouse: filled in according to the nomenclature support scheme and the stage division.
// Separately: the flag is received
//  - manufactured semi-finished products
//  - nomenclature with the flag Separate purchase
//  - giving materials
//  - order materials with the flag Separate provision of materials.
// 
// Through the action parameters, you can disable filling in some fields, as well as fill in all lines 
// with one predefined value.
//
Procedure CheckSoftwareInProductionPhase(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var ActionParameters;
	
	StructureOfActions.Property("CheckSoftwareInProductionPhase", ActionParameters);
	
	If CurrentRow.Produced
		And CurrentRow.ItemsType = Enums.ItemsTypes.ReusablePackage Then
		CurrentRow.Produced = False;
	EndIf;
	
	AlwaysFillIn = Not ActionParameters.FillInOnlyEmpty;
	
	SecurityParameters = DataForStringProcessing("SecurityParametersInProductionPhase", CachedValues);
	If SecurityParameters <> Undefined Then
		
		If ActionParameters.FillInSecurityOption Then
			If ValueIsFilled(ActionParameters.SupplyOption) Then
				CurrentRow.SupplyOption = ActionParameters.SupplyOption;
			ElsIf AlwaysFillIn Or Not ValueIsFilled(CurrentRow.SupplyOption) Then
				CurrentRow.SupplyOption = SecurityParameters[0].SupplyOption;
			EndIf;
		EndIf;
		
		If ActionParameters.FillInTheWarehouse Then
			If ValueIsFilled(ActionParameters.Warehouse) Then
				CurrentRow.Warehouse = ActionParameters.Warehouse;
			Else
				FillInAccordingToSecurityData = AlwaysFillIn
					Or Not ValueIsFilled(CurrentRow.Warehouse);
				HasLimit = ActionParameters.WarehouseOnlyHasItsOwnShopFloorStockroom
					And Not SecurityParameters[0].ThisIsStoreroomOfCurrentUnit;
				
				If FillInAccordingToSecurityData And Not HasLimit Then
					CurrentRow.Warehouse = SecurityParameters[0].Warehouse;
				EndIf;
			EndIf;
		EndIf;
		
		If ActionParameters.FillInSeparately Then
			If ValueIsFilled(ActionParameters.WithAssignment) Then
				CurrentRow.WithAssignment = ActionParameters.WithAssignment;
			Else
				// The Fill-in-only-empty parameter does not work separately because it cannot
				// be reliably established that the value is not filled in (the False value can be set consciously)
				CurrentRow.WithAssignment = SecurityParameters[0].WithAssignment Or CurrentRow.Produced;
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

// Fills the warehouse based on the scheme of providing the nomenclature and subdivision of the document.
// The action parameters pass the name of the Warehouse Attribute in the calling object.
//
Procedure CheckFillProductionWarehouse(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var ActionParameters;
	
	If CommonClientServer.HasAttributeOrObjectProperty(CurrentRow, "ToExpenseAs")
		And CurrentRow.ToExpenseAs Then
		Return;
	EndIf;
	
	StructureOfActions.Property("CheckFillProductionWarehouse", ActionParameters);
	
	FillParameters = DataForStringProcessing("FillingParametersOfProductionWarehouse", CachedValues);
	If FillParameters <> Undefined Then
		
		FieldList = StrSplit(ActionParameters.WarehouseFieldName, ",");
		For Each WarehouseFieldName In FieldList Do
			CurrentRow[WarehouseFieldName] = FillParameters[0].Warehouse;
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure SetFlagForUsingPlannedCostInTSLine(CurrentRow, StructureOfActions, CachedValues) Export

	Var ActionParameters;
	
	If Not StructureOfActions.Property("SetFlagForUsingPlannedCost", ActionParameters) Then
		Return;
	EndIf;

	AccountingPolicyParameters = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate(
		"FinancialAccountingPolicy",
		ActionParameters.Organization,
		CurrentRow.ProductionDate);
	
	If Not AccountingPolicyParameters = Undefined Then
		CurrentRow.UseTargetCost = AccountingPolicyParameters.ProductCostingByPlannedCost;
	EndIf;

EndProcedure

// Fills in the planned / actual production date of the item in the stage
//
// Parameters:
//  CurrentRow		 - Structure - data of the processed string.
//  StructureOfActions	 - Structure - describes actions, where the Key is the name of the action, and The value is the Structure - parameters of the action.
//  CachedValues - Structure - saved values of parameters used during processing.
//
Procedure FillInProductionDate(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var FillParameters;
	
	If Not StructureOfActions.Property("FillInProductionDate", FillParameters) Then
		Return;
	EndIf;
	
	If CurrentRow.Canceled Then
		CurrentRow.ProductionDate = '00010101';
		Return;
	EndIf;
	
	If CurrentRow.Manufactured Then
		EventDate = FillParameters.ActualProductionDate;
		If Not ValueIsFilled(EventDate) Then
			EventDate = CurrentSessionDate();
		EndIf;
	Else
		EventDate = FillParameters.PlannedProductionDate;
	EndIf;
	
	CurrentRow.ProductionDate = BegOfDay(EventDate);
	
EndProcedure
// Fills in the type of price and the price of the transfer of products to the giver.
//
// 1. The type of the price of the transfer of products to the giver is determined by default (the only type of price in the Catalog is the type of price
// 	with the "Use when transferring products to the giver" attribute).
//
// 2. If the type of prices is found, then the price in the line is calculated according to the selected type of prices and recalculated
// 	at the rate of the transferred currency on the date of the document, taking into account the packaging factor (for goods).
//
// Parameters:
// 	CurrentRow - Structure - current row of the table part.
// 	StructureOfActions - See ProcessTSStrings.StructureOfActions.
// 	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure FillInPriceOfTransferringProductsToGiver(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var ActionParameters;
	
	StructureOfActions.Property("FillInPriceOfTransferringProductsToGiver", ActionParameters);
	
	DataForProcessing = DataForStringProcessing("FillInPriceOfTransferringProductsToGiver", CachedValues);
	If DataForProcessing <> Undefined Then
		
		CurrentRow.Price = DataForProcessing[0].Price;
		CurrentRow.PriceKind = DataForProcessing[0].PriceKind;
		
	EndIf;

EndProcedure

// Fills in the issue price of the item in the row of the tabular part according to the type of prices passed in the action parameters.
//
// If the Produced attribute is set in the line and the planned cost of manufactured products is used,
// then the product price is calculated according to the type of prices specified in the action parameters and recalculated
// at the rate of the transferred currency as of the document date, taking into account the packaging coefficient (for goods).
//
// Parameters:
// 	CurrentRow - Structure - current row of the table part.
// 	StructureOfActions - See ProcessTSStrings.StructureOfActions.
// 	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure CheckFillIssuePrice(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var ActionParameters;
	
	StructureOfActions.Property("CheckFillIssuePrice", ActionParameters);
	
	DataForProcessing = DataForStringProcessing("CheckFillIssuePrice", CachedValues);
	If DataForProcessing <> Undefined Then
		
		If Not CurrentRow.Manufactured
			Or Not ValueIsFilled(CurrentRow.Products) Then
			
			CurrentRow.Price = 0;
			
		Else
		
			If CurrentRow.Property("UseTargetCost")
				And Not CurrentRow.UseTargetCost Then
				
				CurrentRow.Price = 0;
				CurrentRow.Sum = 0;
				
			Else
				CurrentRow.Price = DataForProcessing[0].Price;
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure FillInSubdivisionInTSLine(CurrentRow, StructureOfActions, CachedValues) Export

	Var ActionParameters;
	
	If Not StructureOfActions.Property("FillInSubdivisionInTSLine", ActionParameters) Then
		Return;
	EndIf;
	
	ResetDivision = False;
	If TypeOf(ActionParameters) = Type("Structure")
		And ActionParameters.Property("ThereIsWriteOffForExpenses") Then
		ResetDivision = Not CurrentRow.ToExpenseAs
			And (CurrentRow.ItemsType = PredefinedValue("Enum.ItemsTypes.OwnGoods")
			Or CurrentRow.ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage")
			Or CurrentRow.AssignmentType = PredefinedValue("Enum.AssignmentTypes.DeliveryForPrincipal"));			
	EndIf;
	
	TypesList = SalesServer.TypesOfNomenclatureWithUnitAnalytics();
	If TypesList.FindByValue(CurrentRow.ItemsType) = Undefined
		Or ResetDivision Then
		CurrentRow.Department = PredefinedValue("Catalog.BusinessStructure.EmptyRef");
	Else
		CurrentRow.Department = ActionParameters.Department;
	EndIf;

EndProcedure

// Fills in the service details "Divergence of orders" in the line
//
// Parameters:
//  CurrentRow		 - Structure - data of the processed string.
//  StructureOfActions	 - Structure - describes actions, where the Key is the name of the action,
//  														   The value - Structure - activity settings.
//  CachedValues - Structure - saved values of parameters used during processing.
//
Procedure FillInDiscrepancyAttributeOrder(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var FillParameters;
	
	If Not StructureOfActions.Property("FillInDiscrepancyAttributeOrder", FillParameters) Then
		Return;
	EndIf;

	OrdersServer.FillInDiscrepancyAttributeOrder(CurrentRow, FillParameters, CachedValues);
	
EndProcedure

Procedure FillOutSellerSForm(CurrentRow, StructureOfActions, CachedValues = Undefined) Export
	
	Var ActionStructureParameter;
	
	If StructureOfActions.Property("FillOutSellerSForm", ActionStructureParameter)
		And Not ValueIsFilled(CurrentRow.Seller) Then
		
			CurrentRow.Seller = ActionStructureParameter.Seller;

	EndIf;
	
EndProcedure

Procedure SetFlagForFillingInTextDescription(CurrentRow, StructureOfActions, CachedValues = Undefined) Export
	
	CurrentRow.ForFillingInDescriptionText = Not ValueIsFilled(CurrentRow.Products);
	
EndProcedure

Procedure FillInCurrentVATRatesCachedValues(ActionStructure, CachedValues) Export
	
	VATTaxation = ActionStructure.VATTaxation;
	Date = ActionStructure.Date;
	Organization = ActionStructure.Organization;
	If ActionStructure.Property("BusinessOperation") Then
		BusinessOperation = ActionStructure.BusinessOperation;
	Else
		BusinessOperation = Enums.BusinessTransactions.EmptyRef();
	EndIf;
	
	If SalesServer.BusinessTransactionWithRateWithoutVAT(BusinessOperation) Then
		
		CurrentVATRates = New Array();
		CurrentVATRates.Add(Catalogs.VATRates.EXCLUDINGVAT);
		CachedValues.CurrentVATRates = CurrentVATRates;
		
	Else
	
		Query = New Query;
		Query.Text = 
		"SELECT
		|	VATRatesTypesOfVATTaxation.Ref AS VATRate
		|FROM
		|	Catalog.VATRates.VATTaxationTypes AS VATRatesTypesOfVATTaxation
		|WHERE
		|	VATRatesTypesOfVATTaxation.VATTaxationType = &VATTaxationType
		|	AND (VATRatesTypesOfVATTaxation.Ref.Country = &Country
		|			OR VATRatesTypesOfVATTaxation.Ref.Country = &EmptyCountry)
		|	AND (VATRatesTypesOfVATTaxation.Ref.BeginOfPeriod <= &Date
		|			OR VATRatesTypesOfVATTaxation.Ref.BeginOfPeriod = DATETIME(1, 1, 1))
		|	AND (ENDOFPERIOD(VATRatesTypesOfVATTaxation.Ref.EndOfPeriod, DAY) >= &Date
		|			OR VATRatesTypesOfVATTaxation.Ref.EndOfPeriod = DATETIME(1, 1, 1))
		|
		|GROUP BY
		|	VATRatesTypesOfVATTaxation.Ref";
		
		Query.SetParameter("VATTaxationType", VATTaxation);
		Query.SetParameter("Date", ?(ValueIsFilled(Date), Date, CurrentSessionDate()));
		Query.SetParameter("Country", SettingsValueClientServerCached.CountryOfOrganizationRegistration(Organization));
		Query.SetParameter("EmptyCountry", Catalogs.WorldCountries.EmptyRef());
		
		QueryResult = Query.Execute();
		
		If QueryResult.IsEmpty() Then
			CachedValues.CurrentVATRates = New Array;
		EndIf;
		
		CachedValues.CurrentVATRates = QueryResult.Unload().UnloadColumn("VATRate");
		
	EndIf;
	
EndProcedure

Procedure CheckFillInPriceTypeInTSLine(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var StructureOfActionParameters;
	StructureOfActions.Property("CheckFillInPriceView", StructureOfActionParameters);
	
	ColumnNamePriceType = "PriceKind";
	If TypeOf(StructureOfActionParameters.PriceKind) = Type("String")
				And ValueIsFilled(StructureOfActionParameters.PriceKind) Then
			ColumnNamePriceType = StructureOfActionParameters.PriceKind;
	EndIf;
	
	CurrentRow[ColumnNamePriceType]= DataForStringProcessing("TypesOfPrices", CachedValues)[0].PriceKind;
	
EndProcedure

Procedure FillInAddressStorageAttribute(CurrentRow, StructureOfActions, CachedValues) Export
	
	CurrentRow.UseBinLocationWarehousing = 
		DataForStringProcessing("WhetherBinLocationSystemIsAddressBasedStorage", CachedValues)[0].UseBinLocationWarehousing;
	
EndProcedure

Procedure FillInAttributeAcceptedByCNU(CurrentRow, StructureOfActions, CachedValues) Export
	
	CurrentRow.AcceptedByTheKNU =
		DataForStringProcessing("AttributeIsAcceptedByCNU", CachedValues)[0].EnteredInTaxAccounting;
	
EndProcedure

Procedure FillInGTINInLine(CurrentRow, Actions, CachedValues = Undefined) Export
	
	Var ActionStructureParameter;
	
	Actions.Property("FillInGTINInLine", ActionStructureParameter);
	AddLeadingZeros_ = False;
	If ActionStructureParameter <> Undefined Then
		AddLeadingZeros_ = ActionStructureParameter.AddLeadingZeros_;
	EndIf;
	
	DataForProcessing = DataForStringProcessing("TTTableOfBarcodes",CachedValues);
	If DataForProcessing = Undefined Then
		Return;
	EndIf;
	
	CorrectGTINS = New Array;
	
	For Each Item In DataForProcessing Do
		
		GTIN = Item.GTIN;
		If EquipmentManagerClientServer.CheckCorrectGTIN(GTIN) Then
			If AddLeadingZeros_ Then
				GTIN = Right("000000" + GTIN, 14);
			EndIf;
			CorrectGTINS.Add(GTIN);
		EndIf;
		
	EndDo;
	
	If CorrectGTINS.Find(CurrentRow.GTIN) <> Undefined Then
		
		Return;
		
	ElsIf CorrectGTINS.Count() = 1 Then
		
		CurrentRow.GTIN = CorrectGTINS[0];
		
	ElsIf CorrectGTINS.Count() > 1 Then
		
		CurrentRow.GTIN = "";
		
	EndIf;
	
EndProcedure
	
Procedure FillInSpaceUsageAttribute(CurrentRow, StructureOfActions, CachedValues = Undefined) Export
	
	CurrentRow.UseWarerooms =
		DataForStringProcessing("IndicationOfUseOfPremises", CachedValues)[0].UseWarerooms;
		
EndProcedure

Procedure FillRoom(CurrentRow, StructureOfActions, CachedValues = Undefined) Export
	
	If Not ValueIsFilled(CurrentRow.Premise) Then
		DataForProcessing = DataForStringProcessing("FillRoom", CachedValues);
		CurrentRow.Premise = DataForProcessing[0].Premise;
	EndIf;
	
EndProcedure

Procedure FillInDirectionOfActivity(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var ActionParameters;

	StructureOfActions.Property("FillInDirectionOfActivity", ActionParameters);

	LinesOfBusinessServer.FillInLineOfBusinessInBatch(
		CurrentRow, StructureOfActions, CachedValues, ActionParameters);

EndProcedure

// Fills in the sale price (Price) in the row of the table part.
//
// 1. The type of price is selected according to the following algorithm:
// 	1) If the action parameter of the price type is passed, then the action parameters.View prices;
// 	2) otherwise, the field value of the Cur line is the current line.View prices.
//
// 2. The price in the line is calculated according to the selected type of prices and recalculated at the rate of the transferred currency on the date of the document
// 	, taking into account the packaging factor (for goods).
//
// Parameters:
// 	CurrentRow - Structure - current row of the table part.
// 	StructureOfActions - See ProcessTSStrings.StructureOfActions.
// 	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure FillInSalePrice(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var ActionParameters;
	
	StructureOfActions.Property("FillInSalePrice", ActionParameters);
	
	LineData = DataForStringProcessing("FillInSalePrice", CachedValues);
	If LineData <> Undefined Then
		
		NameOfPriceField = CommonClientServer.StructureProperty(ActionParameters, "NameOfPriceField", "Price");
		
		Result = LineData[0];
		If ValueIsFilled(Result.Price) Then
			CurrentRow[NameOfPriceField] = Result.Price;
		ElsIf ValueIsFilled(Result.PriceKind) Then
			CurrentRow[NameOfPriceField] = 0;
		EndIf;
		
	EndIf;
	
EndProcedure

// Fills in the sale price by assortment (Price) in the row of the table part.
//
// 1. The type of price is selected from the register of information Assortment as of the date of the document according to the nomenclature from the line
// 	and the planning object (warehouse or store format) passed in the Warehouse action parameter.
//
// 2. The price in the line is calculated according to the selected type of prices and recalculated at the rate of the transferred currency on the date of the document
// 	, taking into account the packaging factor (for goods).
//
// Parameters:
// 	CurrentRow - Structure - current row of the table part.
// 	StructureOfActions - See ProcessTSStrings.StructureOfActions.
// 	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure FillInSalePriceByProductRange(CurrentRow, StructureOfActions, CachedValues) Export
	
	LineData = DataForStringProcessing("FillInSalePriceByProductRange", CachedValues);
	If LineData <> Undefined Then
		CurrentRow.Price = LineData[0].Price;
	EndIf;
	
EndProcedure

// Checks the entry of the product in the row in the assortment of the transferred store.
// 
// For the item specified in the item line for the transferred planning object (warehouse or store format)
// , an indication of the ability to specify the product in the document is obtained from the Assortment information register as of the document date.
// If there is no such possibility (the product is prohibited for purchase or sale), an informational
// message is displayed and the item in the line is cleared.
//
// Parameters:
// 	CurrentRow - Structure - current row of the table part.
// 	StructureOfActions - See ProcessTSStrings.StructureOfActions.
// 	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure CheckRowAssortment(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var ActionParameters; // See ProductRangeClientServer.AssortmentVerificationParameters
	
	StructureOfActions.Property("CheckRowAssortment", ActionParameters);
	
	LineData = DataForStringProcessing("CheckRowAssortment", CachedValues);
	If LineData <> Undefined Then
		
		Result = LineData[0];
		If Result.ControlProductRange
			And Not Result[ActionParameters.NameOfAssortmentResource] Then
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(ActionParameters.MessageText, Result.Products);
			Common.MessageToUser(
				MessageText,
				ActionParameters.Ref,
				CommonClientServer.PathToTabularSection("Object.Goods", CurrentRow.LineNumber, "Products"),,
				False);
				
			If Not ActionParameters.AllowAdding Then
				CurrentRow.Products = Catalogs.Products.EmptyRef();
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Fills in the sales conditions (type of prices, Price, delivery time) in the row of the table part according
// to the Agreement passed in the parameters.
//
// 1. The type of price is selected according to the following algorithm:
// 	1) if a price is assigned to the product in the terms of the sales agreement, then the Catalog.Vidytsen.Empty Link;
// 	2) if the type of price is assigned to the product in terms of sales, then the parameters of the action.Agreement.Products.View prices;
// 	3) if the price group of the product is assigned a type of price in the sales conditions, then the action parameters.Agreement.Price groups.Vidtsen;
// 	4) if the type of price in clauses 1.1-1.3 has not been determined, then the type of prices from the agreement header are the Action parameters.Agreement.Vidtsen.
//
// 2. If the price is not determined in clause 1.1, then it is calculated according to the selected type of prices and recalculated at the rate
// 	of the transferred currency on the date of the document, taking into account the packaging coefficient (for goods).
// 3. The delivery time is calculated for the goods if it is assigned to the goods in the line in the sales terms of the agreement.
//
// Parameters:
// 	CurrentRow - Structure - current row of the table part.
// 	StructureOfActions - See ProcessTSStrings.StructureOfActions.
// 	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure FillIn_TermsOfSales(CurrentRow, StructureOfActions, CachedValues) Export
	
	LineData = DataForStringProcessing("FillIn_TermsOfSales", CachedValues);
	ThereIsPriceTypeField = ThereIsColumnInDataSource("PriceKind", CachedValues);
	If LineData <> Undefined Then
		
		Result = LineData[0];
		CurrentRow.Price = Round(Result.Price, 2);
		
		If ThereIsPriceTypeField Then
			
			If ValueIsFilled(Result.PriceKind) Then
				CurrentRow.PriceKind = Result.PriceKind;
			Else
				CurrentRow.PriceKind = Catalogs.TypesOfPrices.EmptyRef();
			EndIf;
			
		EndIf;
		
		If ThereIsColumnInDataSource("DeliveryPeriodDays", CachedValues)
			And CommonClientServer.HasAttributeOrObjectProperty(Result, "DeliveryPeriodDays") Then
			CurrentRow.DeliveryPeriodDays = Result.DeliveryPeriodDays;
		EndIf;
		
	EndIf;
	
EndProcedure

// Fills in the conditions of retail sales (type of price, Price) in the row of the table part according to the passed parameter of the object of storage of sales conditions.
//
// 1. The type of price is selected according to the following algorithm:
// 	1) if the object of storage of sales conditions is a warehouse, then it is calculated by priority:
// 		a) the object of storage of sales conditions.Individual Prices;
// 		b) Object of storage of sales conditions.Retail prices.
// 	2) if the object of storage of sales conditions is the format of the store, then it is calculated according to the priority
// 		of a) the object of storage of sales conditions.Individual Prices;
// 		b) Object of storage of sales conditions.Retail prices.
//
// 2. The price is calculated according to the selected type of prices and recalculated at the rate of the transferred currency
// 	on the date of the document, taking into account the packaging factor (for goods).
//
// Parameters:
// 	CurrentRow - Structure - current row of the table part.
// 	StructureOfActions - See ProcessTSStrings.StructureOfActions.
// 	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure FillInRetailSalesTermsAndConditions(CurrentRow, StructureOfActions, CachedValues) Export
	
	LineData = DataForStringProcessing("FillInRetailSalesTermsAndConditions", CachedValues);
	If LineData <> Undefined Then
		
		Result = LineData[0];
		
		CurrentRow.Price = Result.Price;
		
		If ThereIsColumnInDataSource("PriceKind", CachedValues) Then
			CurrentRow.PriceKind = Result.PriceKind;
		EndIf;
		
	EndIf;
	
EndProcedure

// Fills in the partner's nomenclature (partner's nomenclature) in the row of the table part.
//
// 1. If a defective item is specified in the line
// 	, then the corresponding item with the New quality is taken as the value for the search.
// 2. The partner nomenclature is searched by the found value. The option is selected with priority:
// 	1) The partner's nomenclature, already filled in the line, with the appropriate Attribute values {Nomenclature, Characteristics, Packaging};
// 	2) the found variant of the nomenclature of partners, existing in a single copy,
// 		with the appropriate values of the Attributes {Nomenclature, Characteristics, Packaging}.
//
// Parameters:
// 	CurrentRow - Structure - current row of the table part.
// 	StructureOfActions - See ProcessTSStrings.StructureOfActions.
// 	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure FillInProductNameOfProductPartner(CurrentRow, StructureOfActions, CachedValues) Export
	
	LineData = DataForStringProcessing("FillInProductNameOfProductPartner", CachedValues);
	If LineData <> Undefined Then
		
		CurrentRow.PartnerProducts = LineData[0].PartnerProducts;
		
	EndIf;
	
EndProcedure

// Fills in the Attributes of the product (Nomenclature, Characteristics, Packaging) according to the partner's nomenclature in the row of the table part.
// If a defective product is indicated in the line, but the same new one is indicated in the selected partner item,
// then the Attributes are not filled in.
//
// Parameters:
// 	CurrentRow - Structure - current row of the table part.
// 	StructureOfActions - See ProcessTSStrings.StructureOfActions.
// 	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure FillInTheItemByThePartnerSItem(CurrentRow, StructureOfActions, CachedValues) Export
	
	LineData = DataForStringProcessing("FillInTheItemByThePartnerSItem", CachedValues);
	If LineData <> Undefined Then
		
		Result = LineData[0];
		
		If Result.YouNeedToFillInProductList Then
			CurrentRow.Products = Result.Products;
		EndIf;
		
		If Result.CharacteristicsMustBeRefilled Then
			
			CurrentRow.Characteristic = Result.Characteristic;
			CurrentRow.ItemVariantsAreUsed = Result.ItemVariantsAreUsed;
			
		EndIf;
		
		If Result.NeedToReFillPackages Then
			
			CurrentRow.Package = Result.Package;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Checks that the item specified in the line of the partner's item matches the item and the partner,
// and also checks its uniqueness.
// If duplicates are found, it issues an information message with an error to the user.
//
// Parameters:
// 	CurrentRow - Structure - current row of the table part.
// 	StructureOfActions - See ProcessTSStrings.StructureOfActions.
// 	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure CheckMatchedPartnerProducts(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var ActionParameters;
	
	StructureOfActions.Property("CheckMatchedPartnerProducts", ActionParameters);
	
	UsePartnersProducts = False;
	If Not ActionParameters.Property("UsePartnersProducts", UsePartnersProducts) Then
		
		ActionParameters.Insert("UsePartnersProducts",
			GetFunctionalOption("UsePartnersProducts"));
			
		UsePartnersProducts = ActionParameters.UsePartnersProducts;
		
	EndIf;
	
	If Not UsePartnersProducts Then
		Return;
	ElsIf Not ValueIsFilled(CurrentRow.Products) Then
		Return;
	EndIf;
	
	LineData = DataForStringProcessing("CheckMatchedPartnerProducts", CachedValues)[0];
	If ValueIsFilled(CurrentRow.Products)
		And LineData.NumberOfPartnerProducts > 0 Then
		
		If ValueIsFilled(CurrentRow.Characteristic) Then
			
			ErrorText = StrTemplate(
				NStr("vi = 'Đã so sánh mặt hàng khác của nhà cung cấp  (%3) với mặt hàng ""%1"" có đặc tính ""%2""';
					|ru = 'Номенклатуре ""%1"" с характеристикой ""%2"" уже сопоставлена другая номенклатура поставщика (%3)';
					|en = 'Another vendor part number (%3) is already mapped to the ""%1"" item with the ""%2"" variant'; fa = 'Another vendor part number (%3) is already mapped to the ""%1"" item with the ""%2"" variant';
					|it = 'Номенклатуре ""%1"" с характеристикой ""%2"" уже сопоставлена другая номенклатура поставщика (%3)';
					|pl = 'Another vendor part number (%3) is already mapped to the ""%1"" item with the ""%2"" variant';
					|tr = '""%2"" özelliğine sahip ""%1"" öğe artık başka bir tedarikçinin öğesi ile eşleştirilmiştir (%3)'"),
				CurrentRow.Products,
				CurrentRow.Characteristic,
				LineData.NumberOfPartnerProducts);
			
		Else
			
			ErrorText = StrTemplate(
				NStr("vi = 'Đã so sánh mặt hàng khác của nhà cung cấp (%2) với mặt hàng ""%1""';
					|ru = 'Номенклатуре ""%1"" уже сопоставлена другая номенклатура поставщика (%2)';
					|en = 'Another vendor part number (%2) is already mapped to the ""%1"" item'; fa = 'Another vendor part number (%2) is already mapped to the ""%1"" item';
					|it = 'Номенклатуре ""%1"" уже сопоставлена другая номенклатура поставщика (%2)';
					|pl = 'Another vendor part number (%2) is already mapped to the ""%1"" item';
					|tr = '""%1"" öğesi hali hazırda başka bir tedarikçinin öğesi ile eşleştirilmiş (%2)'"),
				CurrentRow.Products,
				LineData.NumberOfPartnerProducts);
			
		EndIf;
		
		Common.MessageToUser(
			ErrorText,
			ActionParameters.Ref,
			CommonClientServer.PathToTabularSection(
				"Object.Goods",
				CurrentRow.LineNumber,
				"Products"));
		
	EndIf;
	
EndProcedure

// Checks the correctness of the indication of the series for the item in the row of the table part.
// Fills in the Status of the series indication for the item in the row of the table part according to the passed parameters of the series indication.
// 
// Parameters:
// 	CurrentRow - Structure - current row of the table part.
// 	StructureOfActions - Structure - valid actions for the table part.
// 	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure CheckSeriesCalculateStatus(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var ActionParameters;
	
	If StructureOfActions.Property("CheckSeriesCalculateStatus", ActionParameters) Then
	
		SeriesSpecificationParameters = ActionParameters.SeriesSpecificationParameters;
		
		FieldsStructure = New Structure;
		FieldsStructure.Insert("SpecifyBatches", False);
		
		LineData = DataForStringProcessing("ToCalculateStatus", CachedValues)[0];
		
		CheckingBatch = DataForStringProcessing("CheckBatch", CachedValues)[0];
		If CheckingBatch.DifferentOwnersOfSeriesAndProducts Then
			LineData.BatchesIndicationStatus = 0;
		EndIf;
		
		If LineData.BatchesIndicationStatus = Null Then
			Return;
		EndIf;
		
		If LineData.BatchesIndicationStatus <> Undefined Then
			
			If SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Count() = 0 Then
				FieldsStructure.Insert("BatchesIndicationStatus", LineData.BatchesIndicationStatus);
			Else
				
				For Each NameOfStatusField In SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication Do
					FieldsStructure.Insert(NameOfStatusField, LineData[NameOfStatusField]);
				EndDo;
				
			EndIf;
			
		EndIf;
		
		FieldsStructure.SpecifyBatches = True;
		
		If ProductsClientServer.InThisStatusOfSeriesWHGoodsAreIndicated(
			LineData.BatchesIndicationStatus,
			SeriesSpecificationParameters)
			Or Not ValueIsFilled(CurrentRow.BatchesIndicationStatus) Then
			SourceOfFilling = LineData;
		Else
			SourceOfFilling = CurrentRow;
		EndIf;
		
		If SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Count() = 0 Then
			FieldsStructure.BatchesIndicationStatus = SourceOfFilling.BatchesIndicationStatus;
		Else
			
			For Each NameOfStatusField In SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication Do
				FieldsStructure[NameOfStatusField] = SourceOfFilling[NameOfStatusField];
			EndDo;
			
		EndIf;
		
		If ProductsClientServer.NoSeriesAreSpecifiedInThisStatus(
			LineData.BatchesIndicationStatus,
			SeriesSpecificationParameters) Then
			
			FieldsStructure.SpecifyBatches = False;
			
			If SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Count() = 0 Then
				FieldsStructure.Insert("Series", Catalogs.ItemsBatches.EmptyRef());
			Else
				
				MatchesSeriesFieldNameToStatusOfSeriesIndication =
					SeriesSpecificationParameters.MatchesSeriesFieldNameToStatusOfSeriesIndication; // Map -
				
				For Each NameOfStatusField In SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication Do
					
					If NameOfStatusField = "BatchesIndicationStatus" Then
						FieldNameSeries = "Series";
					Else
						FieldNameSeries = MatchesSeriesFieldNameToStatusOfSeriesIndication.Get(NameOfStatusField);
					EndIf;
					
					If FieldNameSeries <> Undefined Then
						FieldsStructure.Insert(FieldNameSeries, Catalogs.ItemsBatches.EmptyRef());
					EndIf;
					
				EndDo;
				
			EndIf;
			
		EndIf;
		
		FillPropertyValues(CurrentRow, FieldsStructure);
		
	EndIf;
	
EndProcedure

Procedure CheckBatchByOwner(CurrentRow, StructureOfActions, CachedValues) Export
	
	LineData = DataForStringProcessing("CheckBatchByOwner", CachedValues);
	
	If LineData <> Undefined Then
		Result = LineData[0];
		
		If Result.DifferentOwnersOfSeriesAndProducts Then
			CurrentRow.Series = Catalogs.ItemsBatches.EmptyRef();
		EndIf;
		
		If ThereIsColumnInDataSource("SeriesAreUsed", CachedValues) Then
			CurrentRow.SeriesAreUsed = Result.SeriesAreUsed;
		EndIf;
	EndIf;
	
EndProcedure

// Checks the correctness of specifying the characteristics for the item in the row of the table part.
// In case of non-compliance of the characteristics with the selected product, it clears it.
// If the action structure contains the action "Fill in the characteristicunecachievement of the product",
// then a search and substitution of a characteristic identical to the characteristic of the original product will be performed.
//
// Parameters:
// 	CurrentRow - Structure - current row of the table part.
// 	StructureOfActions - See ProcessTSStrings.StructureOfActions.
// 	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure CheckCharacteristicsByOwner(CurrentRow, StructureOfActions, CachedValues) Export
	
	LineData = DataForStringProcessing("CheckCharacteristicsByOwner", CachedValues);
	If LineData <> Undefined Then
		
		Result = LineData[0];
		
		CurrentRow.Characteristic = Result.Characteristic;
		
		If ThereIsColumnInDataSource("ItemVariantsAreUsed", CachedValues) Then
			CurrentRow.ItemVariantsAreUsed = Result.ItemVariantsAreUsed;
		EndIf;
		
	EndIf;
	
	If StructureOfActions.Property("FillInDescriptionOfPoorQualityProduct") Then
		
		LineData = DataForStringProcessing("FillInDescriptionOfPoorQualityProduct", CachedValues);
		If LineData <> Undefined
			And LineData[0].ItemUsageCharacteristics = Enums.ItemVariantsUsageOptions.SpecialForItems Then
			
			If ValueIsFilled(LineData[0].Characteristic) Then
				CurrentRow.Characteristic = LineData[0].Characteristic;
			Else
				CurrentRow.Characteristic = Catalogs.ItemsCharacteristics.EmptyRef();
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Checks the correctness of specifying the packaging for the item in the row of the table part.
// If the package does not match the selected product, it cleans it.
// If the action structure contains the action "To fill in the packaging of a non-quality product",
// then a search and substitution of packaging identical to the packaging of the original product will be performed.
//
// Parameters:
// 	CurrentRow - Structure - current row of the table part.
// 	StructureOfActions - See ProcessTSStrings.StructureOfActions.
// 	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure CheckFillPackageByOwner(CurrentRow, StructureOfActions, CachedValues) Export
	
	LineData = DataForStringProcessing("CheckFillPackageByOwner", CachedValues);
	If Not LineData[0].VerificationIsSuccessful Then
		
		If StructureOfActions.Property("FillInPackagingOfLowQualityGoods") Then
			
			LineData = DataForStringProcessing("FillInPackagingOfLowQualityGoods", CachedValues);
			If LineData <> Undefined Then
				
				FoundPackaging = LineData[0].Package;
				If ValueIsFilled(FoundPackaging)
					Or Not LineData[0].ThisIsIndividualSet Then
					CurrentRow.Package = FoundPackaging;
				Else
					CurrentRow.Package = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
				EndIf;
				
			Else
				
				CurrentRow.Package = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
				
			EndIf;
			
		Else
			
			CurrentRow.Package = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Fills in the purchase price (Price) in the row of the table part.
//
// 1. The type of price is selected according to the following algorithm:
// 	1) If the action parameter of the supplier type is passed, then the Action parameters.Type of Supplier Price;
// 	2) if the Agreement action parameter is passed, then the Action parameters.Agreement.Type of Supplier price;
// 	3) if there is a Type of supplier field in the line, then the current line.Type of Supplier price,
// 	4) otherwise Catalog.Types of supplier prices.Empty link.
//
// 2. The price in the line is calculated according to the selected type of prices and recalculated at the rate of the transferred currency on the date of the document
// 	, taking into account the packaging coefficient (for goods).
//
// Parameters:
// 	CurrentRow - Structure - current row of the table part.
// 	StructureOfActions - See ProcessTSStrings.StructureOfActions.
// 	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure FillInPurchasePrice(CurrentRow, StructureOfActions, CachedValues) Export
	
	LineData = DataForStringProcessing("FillInPurchasePrice", CachedValues);
	If LineData <> Undefined Then
		
		CurrentRow.Price = LineData[0].Price;
		
	EndIf;
	
EndProcedure

// Fills in the terms of purchase (type of supplier, Price) in the row of the table part according
// to the values of the Agreement and type of Supplier passed in the action parameters.
//
// 1. The type of price is selected according to the following algorithm:
// 	1) If the line has a Supplier type field, it is filled in with the value of the action parameter.Agreement.The type of the supplier's price,
// 		and the type of prices you are looking for is equal to the parameters of the action.Agreement.Type of Supplier price;
// 	2) if the action parameter of the supplier's price type is passed, then the desired price type is equal to the Action parameter.Type of Supplier price;
// 	3) if there is no Supplier type field in the line, and the Supplier type parameter is not passed,
// 		then the Catalog value is taken.Types of supplier prices.Empty link.
//
// 2. The price in the line is calculated according to the selected type of prices and recalculated at the rate of the transferred currency on the date of the document
// 	, taking into account the packaging factor (for goods).
//
// Parameters:
// 	CurrentRow - Structure - current row of the table part.
// 	StructureOfActions - See ProcessTSStrings.StructureOfActions.
// 	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure FillInTermsOfPurchase(CurrentRow, StructureOfActions, CachedValues) Export
	
	LineData = DataForStringProcessing("FillInTermsOfPurchase", CachedValues);
	If LineData <> Undefined Then
		
		Result = LineData[0];
		
		If ThereIsColumnInDataSource("VendorPriceKind", CachedValues) Then
			CurrentRow.VendorPriceKind = Result.VendorPriceKind;
		EndIf;
		
		CurrentRow.Price = Result.Price;
		
	EndIf;
	
EndProcedure

// Fills in the Balance of the goods (quantity of packings Account, quantity of packings Fact) in the register of
// goods organizations with the exception of the movement of the specified document (action parameter Registrar) in the row of the tabular part
// according to the values passed in the action parameters Warehouse, Organization and Time.
//
// 1. The item accounting analytics key is selected according to the item and characteristic from the line, as well
// 	as with the transferred value Warehouse as a storage location.
// 2. According to the transferred Organization and the received keys in the Accumulation register
// 	of the organizations' goods, the Balance at the time of the transfer is calculated according to the resource Quantity, except for the movements of the transferred document.
//
// Parameters:
// 	CurrentRow - Structure - current row of the table part.
// 	StructureOfActions - See ProcessTSStrings.StructureOfActions.
// 	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure FillInAccountingQuantityOfProductItem(CurrentRow, StructureOfActions, CachedValues) Export
	
	LineData = DataForStringProcessing("FillInAccountingQuantityOfProductItem", CachedValues);
	If LineData <> Undefined Then
		
		Result = LineData[0];
		CurrentRow.NumberOfPackagesAccounting = Result.Count;
		CurrentRow.NumberOfPackagesReal = Result.Count;
		
	EndIf;

EndProcedure

// Calculates the number of packages of goods (quantity of packages) in the row of the tabular part based
// on the number of units of goods and the specified package.
//
// Parameters:
// 	CurrentRow - Structure - current row of the table part.
// 	StructureOfActions - See ProcessTSStrings.StructureOfActions.
// 	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure RecalculateNumberOfPackages(CurrentRow, StructureOfActions, CachedValues) Export
	
	LineData = DataForStringProcessing("RecalculateNumberOfPackages", CachedValues);
	If LineData <> Undefined Then
		
		Result = LineData[0];
		CurrentRow[Result.FieldNameNumberOfPackages] = Result.Count;
		
	Else
		
		ExceptionText = NStr("vi = 'Khi cố gắng tính toán lại số lượng theo %UnitOfMeasurement% dung lượng bit cho phép bị vượt quá.';
							|ru = 'При попытке пересчета количества в %UnitOfMeasurement% превышена допустимая разрядность.';
							|en = 'While trying to recalculate the amount in %UnitOfMeasurement%, the allowable capacity is exceeded.'; fa = 'While trying to recalculate the amount in %UnitOfMeasurement%, the allowable capacity is exceeded.';
							|it = 'Durante il tentativo di ricalcolo della quantità di %UnitOfMeasurement%  si è verificato il superamento della capacità di cifre consentita.';
							|pl = 'Podczas próby przeliczenia ilości w %UnitOfMeasurement% została przekroczona dopuszczalna ilość pozycji.';
							|tr = 'Miktarı %UnitOfMeasurement%''a dönüştürmeye çalışırken, izin verilen bit genişliği kapasitesi aşıldı.'");
		ExceptionText = StrReplace(ExceptionText, "%UnitOfMeasurement%", CurrentRow.Package);
		
		CurrentRow.Count = 0;
		CurrentRow.NumberOfPackages = 0;
		CurrentRow.Package = PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef");
		
		Raise ExceptionText;
		
	EndIf;

EndProcedure

// Calculates the number of packages of goods in the row of the table part based
// on the number of units of goods and the specified package. Used for fields with suffixes.
//
// Parameters:
// 	CurrentRow - Structure - current row of the table part.
// 	StructureOfActions - See ProcessTSStrings.StructureOfActions.
// 	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure RecalculateNumberOfSuffixPacks(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var ActionParameters;
	
	StructureOfActions.Property("RecalculateNumberOfSuffixPacks", ActionParameters);
	
	LineData = DataForStringProcessing("RecalculateNumberOfSuffixPacks", CachedValues);
	If LineData <> Undefined Then
		
		Result = LineData[0];
		CurrentRow[Result.FieldNameNumberOfPackages] = Result.Count;
		
	Else
		
		RecalculationParameters = BatchProcessingOfTablePartClientServer.NormalizeUnitConversionParametersSuffix(Undefined, ActionParameters);
		QuantityWithSuffix = BatchProcessingOfTablePartClientServer.QuantityWithSuffix(RecalculationParameters.Suffix);
		
		ExceptionText = NStr("vi = 'Khi cố gắng tính toán lại số lượng theo %UnitOfMeasurement% dung lượng bit cho phép bị vượt quá.';
							|ru = 'При попытке пересчета количества в %UnitOfMeasurement% превышена допустимая разрядность.';
							|en = 'While trying to recalculate the amount in %UnitOfMeasurement%, the allowable capacity is exceeded.'; fa = 'While trying to recalculate the amount in %UnitOfMeasurement%, the allowable capacity is exceeded.';
							|it = 'Durante il tentativo di ricalcolo della quantità di %UnitOfMeasurement%  si è verificato il superamento della capacità di cifre consentita.';
							|pl = 'Podczas próby przeliczenia ilości w %UnitOfMeasurement% została przekroczona dopuszczalna ilość pozycji.';
							|tr = 'Miktarı %UnitOfMeasurement%''a dönüştürmeye çalışırken, izin verilen bit genişliği kapasitesi aşıldı.'");
		ExceptionText = StrReplace(ExceptionText, "%UnitOfMeasurement%", CurrentRow.Package);
		
		CurrentRow[QuantityWithSuffix.Count] = 0;
		CurrentRow[QuantityWithSuffix.NumberOfPackages] = 0;
		CurrentRow.Package = PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef");
		
		Raise ExceptionText;
		
	EndIf;

EndProcedure

// Calculates the number of packages of goods in the row of the tabular part based
// on the specified package, its weight and the total weight of the goods.
//
// Parameters:
// 	CurrentRow - Structure - current row of the table part.
// 	StructureOfActions - See ProcessTSStrings.StructureOfActions.
// 	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure RecalculateNumberOfPackagesByWeight(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var ActionParameters;
	
	StructureOfActions.Property("RecalculateNumberOfPackagesByWeight", ActionParameters);
	
	LineData = DataForStringProcessing("RecalculateNumberOfPackagesByWeight", CachedValues);
	If LineData <> Undefined Then
		
		Result = LineData[0];
		CurrentRow[Result.FieldNameQuantity] = Result.Count;
		CurrentRow[Result.FieldNameNumberOfPackages] = Result.NumberOfPackages;
		
		UnitVolume_ = Result.FactorVolume;
		If CurrentRow.PackageVolume * UnitVolume_ <> 0 Then
			
			CurrentRow.VolumeM3 = Result.NumberOfPackages
				* Round(CurrentRow.PackageVolume / UnitVolume_, 11, RoundMode.Round15as20);
			
		Else
			CurrentRow.VolumeM3 = 0;
		EndIf;
		
	Else
		
		RecalculationParameters = BatchProcessingOfTablePartClientServer.NormalizeUnitConversionParametersSuffix(
			Undefined,
			ActionParameters);
		
		QuantityWithSuffix = BatchProcessingOfTablePartClientServer.QuantityWithSuffix(RecalculationParameters.Suffix);
		
		CurrentRow[QuantityWithSuffix.Count] = 0;
		CurrentRow[QuantityWithSuffix.NumberOfPackages] = 0;
		CurrentRow.VolumeM3 = 0;
		
	EndIf;
	
EndProcedure

// Calculates the number of packages of goods in the row of the tabular part based
// on the specified package, its volume and the total volume of the goods.
//
// Parameters:
// 	CurrentRow - Structure - current row of the table part.
// 	StructureOfActions - See ProcessTSStrings.StructureOfActions.
// 	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure RecalculateNumberOfPackagesByVolume(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var ActionParameters;
	
	StructureOfActions.Property("RecalculateNumberOfPackagesByVolume", ActionParameters);
	
	LineData = DataForStringProcessing("RecalculateNumberOfPackagesByVolume", CachedValues);
	If LineData <> Undefined Then
		
		Result = LineData[0];
		CurrentRow[Result.FieldNameQuantity] = Result.Count;
		CurrentRow[Result.FieldNameNumberOfPackages] = Result.NumberOfPackages;
		
		UnitWeight_ = Result.FactorWeight;
		If CurrentRow.PackageWeight * UnitWeight_ <> 0 Then
			
			CurrentRow.Weight = Result.NumberOfPackages
				* Round(CurrentRow.PackageWeight / UnitWeight_, 11, RoundMode.Round15as20);
			
		Else
			CurrentRow.Weight = 0;
		EndIf;
		
	Else
		
		RecalculationParameters = BatchProcessingOfTablePartClientServer.NormalizeUnitConversionParametersSuffix(
			Undefined,
			ActionParameters);
		
		QuantityWithSuffix = BatchProcessingOfTablePartClientServer.QuantityWithSuffix(RecalculationParameters.Suffix);
		
		CurrentRow[QuantityWithSuffix.Count] = 0;
		CurrentRow[QuantityWithSuffix.NumberOfPackages] = 0;
		CurrentRow.Weight = 0;
		
	EndIf;
	
EndProcedure

// Returns data about the package.
// 
// Parameters:
//  Products - CatalogRef.Products - The nomenclature for which you want to get the packing coefficient.
//  Package - CatalogRef.PackagesAndUnitsOfMeasure - The package for which you want to get the packing coefficient.
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
// 
// Returns:
//  See Catalogs.PackagesAndUnitsOfMeasure.CoefficientWeightVolumeOtherPackingDetails
//
Function PackingInformation(Products, Package, CachedValues) Export 
	
	PackingInformation = Catalogs.PackagesAndUnitsOfMeasure.CoefficientWeightVolumeOtherPackingDetails(Package, Products, , False);
	
	CoefficientKey = BatchProcessingOfTablePartClientServer.PackingCacheKey(Products, Package);
	
	CachedValues.PackingFactors.Insert(CoefficientKey,	New Structure("ZoomRatio, NeedToRoundUpQuantity",
																							PackingInformation.ZoomRatio,
																							PackingInformation.NeedToRoundUpQuantity));
	CachedValues.VolumeOfPackages.Insert(CoefficientKey, 			PackingInformation.Weight);
	CachedValues.PackageWeight_.Insert(CoefficientKey, 			PackingInformation.VolumeM3);
	
	Return PackingInformation;
	
EndFunction

// Procedure called from the handler of the "Nomenclature" item in the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - current row of the table part.
//	StructureOfActions - Structure - valid actions for the table part.
//	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure ProductsOnChangeOverridable(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var ActionParameters;
	
	StructureOfActions.Property("ProductsOnChangeOverridable", ActionParameters);
	ConfigurationModificationOverridable.ProductsOnChangeOverridable(CurrentRow,
		ActionParameters, CachedValues);
	
EndProcedure

// Procedure that is called from the handler of the "Characteristics" attribute of the table part of the document.
//
// Parameters:
//	CurrentRow - Structure - current row of the table part.
//	StructureOfActions - Structure - valid actions for the table part.
//	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure CharacteristicOnChangeOverridable(CurrentRow, StructureOfActions, CachedValues) Export
	
	Var ActionParameters;
	
	StructureOfActions.Property("CharacteristicOnChangeOverridable", ActionParameters);
	ConfigurationModificationOverridable.CharacteristicOnChangeOverridable(CurrentRow,ActionParameters,CachedValues);
	
EndProcedure

Procedure FillInExcisableItemAttribute(CurrentRow, StructureOfActions, CachedValues) Export
	
	ExcisableGoodsAccounting.FillInExcisableItemInBatch(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

Procedure RecalculateExciseTaxAmountInTSLine(CurrentRow, StructureOfActions, CachedValues) Export
	
	ExcisableGoodsAccounting.RecalculateExciseTaxAmountInBatches(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

Procedure FillInInvoiceSettingsPresentation(CurrentRow, StructureOfActions, CachedValues = Undefined) Export
	Var StructureOfActionParameters;
	
	If StructureOfActions.Property("FillInInvoiceSettingsPresentation", StructureOfActionParameters) Then
		GLAccountSettingsServer.FillInInvoiceSettingsPresentation(CurrentRow, StructureOfActionParameters);
	EndIf;
	Return; // The UT handler is empty
	
EndProcedure

// Fills in the agreement in the table part
//
// Parameters:
//	CurrentRow - Structure - current row of the table part.
//	StructureOfActions - Structure - valid actions for the table part.
//	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure FillInDefaultSupplierAgreement(CurrentRow, StructureOfActions, CachedValues) Export
	
	CurrentRow.Terms = DataForStringProcessing("ParametersOfSupplierAgreements", CachedValues)[0].Terms;
	
EndProcedure 

// Fills in the service Attributes of the agreement in the table part
//
// Parameters:
//	CurrentRow - Structure - current row of the table part.
//	StructureOfActions - Structure - valid actions for the table part.
//	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure FillInAttributesAccordingToSupplierSAgreement(CurrentRow, StructureOfActions, CachedValues) Export
	
	FillPropertyValues(CurrentRow,
		DataForStringProcessing("FillInAttributesAccordingToSupplierSAgreement", CachedValues)[0]);
	
EndProcedure 

// Fills in the number of supplier agreements in the table part
//
// Parameters:
//	CurrentRow - Structure - current row of the table part.
//	StructureOfActions - Structure - valid actions for the table part.
//	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure FillInNumberOfSupplierAgreements(CurrentRow, StructureOfActions, CachedValues) Export
	
	CurrentRow.NumberOfAgreements = DataForStringProcessing("ParametersOfSupplierAgreements", CachedValues)[0].NumberOfAgreements;
	
EndProcedure


// Fills in the counterparty in the table part
//
// Parameters:
//	CurrentRow - Structure - current row of the table part.
//	StructureOfActions - Structure - valid actions for the table part.
//	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure FillInPartnerSDefaultCounterparty(CurrentRow, StructureOfActions, CachedValues) Export
	
	CurrentRow.Counterparty = DataForStringProcessing("FillInPartnerSDefaultCounterparty", CachedValues)[0].Counterparty;
	
EndProcedure

// Fills in the Contract in the table part
//
// Parameters:
//	CurrentRow - Structure - current row of the table part.
//	StructureOfActions - Structure - valid actions for the table part.
//	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure FillInDefaultContract(CurrentRow, StructureOfActions, CachedValues) Export
	
	CurrentRow.Contract = DataForStringProcessing("FillInDefaultContract", CachedValues)[0].Contract;
	
EndProcedure

// Fills in the business of operation in the tabular part from the agreement or Contract.
//
// Parameters:
//	CurrentRow - Structure - current row of the table part.
//	StructureOfActions - Structure - valid actions for the table part.
//	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure CompleteOfOperationAccordingToAgreementContract(CurrentRow, StructureOfActions, CachedValues) Export
	
	CurrentRow.BusinessOperation = 
		DataForStringProcessing("CompleteOfOperationAccordingToAgreementContract", CachedValues)[0].BusinessOperation;
	
EndProcedure

Procedure FillInPresentationOfTermsOfPurchase(CurrentRow, StructureOfActions, CachedValues) Export
	
	RefsPresentations = DataForStringProcessing("FillInPresentationOfTermsOfPurchase", CachedValues)[0];
	CurrentRow.PresentationOfTermsOfPurchase = BatchProcessingOfTablePartClientServer.PresentationOfTermsOfPurchase(
		RefsPresentations.Partner,
		CurrentRow.Sum,
		CurrentRow.AmountIncludingVAT);
	
EndProcedure

Procedure CheckBarcodeRegistration(CurrentRow, StructureOfActions, CachedValues) Export
	
	LineData = DataForStringProcessing("CheckBarcodeRegistration", CachedValues);
	
	If LineData <> Undefined Then
		Result = LineData[0];
		
		CurrentRow.Registered = Result.Registered;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

// Description of collection string handlers:
// 
// Parameters:
//  StringHandlers - ValueList of String - Contains the correspondence of the action on the string and the method.
//
Procedure WhenAddingCollectionLineHandlers(StringHandlers) Export
	
	// The handlers will be executed in the order of the lines below
	InventoryInOperationServer.AddMethodsToBatchExecution(StringHandlers);
	RebatesServer.WhenAddingCollectionLineHandlers(StringHandlers);
	
	StringHandlers.Add("CheckRowAssortment",
		"BatchProcessingOfTablePartServer.CheckRowAssortment");
	
	StringHandlers.Add("FillInTheItemByThePartnerSItem",
		"BatchProcessingOfTablePartServer.FillInTheItemByThePartnerSItem");
	
	StringHandlers.Add("FillInProductNameOfProductPartner",
		"BatchProcessingOfTablePartServer.FillInProductNameOfProductPartner");
		
	StringHandlers.Add("CheckMatchedPartnerProducts",
		"BatchProcessingOfTablePartServer.CheckMatchedPartnerProducts");
	
	StringHandlers.Add("FillInProductTypeAttribute_",
		"BatchProcessingOfTablePartServer.FillInServiceDetailsForProductInLineTS");
	
	StringHandlers.Add("FillInProductTypeAttribute",
		"BatchProcessingOfTablePartServer.FillInServiceDetailsForProductInLineTS");
	
	StringHandlers.Add("FillInUnitOfMeasurementAttribute",
		"BatchProcessingOfTablePartServer.FillInServiceDetailsForProductInLineTS");
	
	StringHandlers.Add("FillInMeasuredValueTypeAttribute",
		"BatchProcessingOfTablePartServer.FillInServiceDetailsForProductInLineTS");
	
	StringHandlers.Add("FillPackageWeight",
		"BatchProcessingOfTablePartServer.FillInServiceDetailsForProductInLineTS");
	
	StringHandlers.Add("FillPackageVolume",
		"BatchProcessingOfTablePartServer.FillInServiceDetailsForProductInLineTS");
	
	StringHandlers.Add("FillInUnitOfWeight",
		"BatchProcessingOfTablePartServer.FillInServiceDetailsForProductInLineTS");
	
	StringHandlers.Add("FillInVolumeUnit",
		"BatchProcessingOfTablePartServer.FillInServiceDetailsForProductInLineTS");
	
	StringHandlers.Add("NumberOfPackagesPerUnitOfWeight",
		"BatchProcessingOfTablePartServer.FillInServiceDetailsForProductInLineTS");
	
	StringHandlers.Add("FillInArticleAttribute",
		"BatchProcessingOfTablePartServer.FillInServiceDetailsForProductInLineTS");
	
	StringHandlers.Add("FillInCodeAttribute",
		"BatchProcessingOfTablePartServer.FillInServiceDetailsForProductInLineTS");
	
	StringHandlers.Add("FillInDescriptionAttribute",
		"BatchProcessingOfTablePartServer.FillInServiceDetailsForProductInLineTS");
	
	StringHandlers.Add("FillInFeatureAttribute",
		"BatchProcessingOfTablePartServer.FillInServiceDetailsForProductInLineTS");
	
	StringHandlers.Add("FillInCCDTrackingAttribute",
		"BatchProcessingOfTablePartServer.FillInServiceDetailsForProductInLineTS");
	
	StringHandlers.Add("FillInRnptTrackingAttribute",
		"BatchProcessingOfTablePartServer.FillInServiceDetailsForProductInLineTS");
	
	StringHandlers.Add("FillInFeatureThisIsService",
		"BatchProcessingOfTablePartServer.FillInServiceDetailsForProductInLineTS");
	
	StringHandlers.Add("FillInUnitOfMeasurementOfFEA",
		 "BatchProcessingOfTablePartServer.FillInServiceDetailsForProductInLineTS");

	StringHandlers.Add("FillInSalesOptionAttribute",
		"BatchProcessingOfTablePartServer.FillInServiceDetailsForProductInLineTS");
	
	StringHandlers.Add("FillInSeriesAttribute",
		"BatchProcessingOfTablePartServer.FillInServiceDetailsForProductInLineTS");
	
	StringHandlers.Add("RecalculateWeightVolume",
		"BatchProcessingOfTablePartServer.FillInServiceDetailsForProductInLineTS");
	
	StringHandlers.Add("CheckCharacteristicsByOwner",
		"BatchProcessingOfTablePartServer.CheckCharacteristicsByOwner");
	
	StringHandlers.Add("CheckFillPackageByOwner",
		"BatchProcessingOfTablePartServer.CheckFillPackageByOwner");
	
	StringHandlers.Add("FillInCCDNumberType",
		"BatchProcessingOfTablePartServer.FillInCCDNumberType");
	
	StringHandlers.Add("FillInWriteOFFAttributeForExpensesAndDivision",
		"BatchProcessingOfTablePartClientServer.FillInWriteOFFAttributeForExpensesAndDivision");
	
	StringHandlers.Add("CheckFillWarehouse",
		"BatchProcessingOfTablePartServer.CheckFillWarehouse");
	
	StringHandlers.Add("FillInOrderWarehouseAttribute",
		"BatchProcessingOfTablePartServer.FillInOrderWarehouseAttributeInTSLine");
	StringHandlers.Add("CheckFillProductionWarehouse",
		"BatchProcessingOfTablePartServer.CheckFillProductionWarehouse");
	StringHandlers.Add("CheckSoftwareInSalesDocument",
		"BatchProcessingOfTablePartServer.CheckSoftwareInSalesDocument");
	
	StringHandlers.Add("FillInShipForOrderPlusImplementationOption",
		"BatchProcessingOfTablePartServer.FillInShipForOrderPlusImplementationOption");
	StringHandlers.Add("CheckFillSpecification",
		"BatchProcessingOfTablePartServer.CheckFillSpecification");
	StringHandlers.Add("CheckSoftwareInProductionPhase",
		"BatchProcessingOfTablePartServer.CheckSoftwareInProductionPhase");
	StringHandlers.Add("FillInReleaseDirection",
		"BatchProcessingOfTablePartClientServer.FillInReleaseDirection");
	
	StringHandlers.Add("FillOutRecipientInDirectionOfIssue",
		"BatchProcessingOfTablePartServer.FillOutRecipientInDirectionOfIssue");
	
	StringHandlers.Add("FillInShopPantryAttribute",
		"BatchProcessingOfTablePartServer.FillInShopPantryAttribute");
	StringHandlers.Add("RecalculateQuantityDoNotShip",
		"BatchProcessingOfTablePartClientServer.RecalculateQuantityDoNotShipToTSLine");
	
	StringHandlers.Add("FillInGTINInLine",
		"BatchProcessingOfTablePartServer.FillInGTINInLine");
	
	StringHandlers.Add("RecalculateNumberOfPackagesAfterFact",
		"BatchProcessingOfTablePartClientServer.RecalculateNumberOfPackagesAfterFactInTSLine");
	
	StringHandlers.Add("RecalculateNumberOfPackagesFactByPackages",
		"BatchProcessingOfTablePartClientServer.RecalculateNumberOfPackagesFactByPackagesInPMLine");
	
	StringHandlers.Add("RecalculateNumberOfSuffixPacksFromDeviation",
		"BatchProcessingOfTablePartClientServer.RecalculateNumberOfSuffixPacksFromDeviationInTSString");
	
	StringHandlers.Add("RecalculateNumberOfUnits",
		"BatchProcessingOfTablePartClientServer.RecalculateNumberOfUnitsInTSString");
	
	StringHandlers.Add("RecalculateNumberOfSuffixUnits",
		"BatchProcessingOfTablePartClientServer.RecalculateNumberOfSuffixUnitsInTSString");
	
	StringHandlers.Add("RecalculateQuantityByRNPT",
		"BatchProcessingOfTablePartServer.RecalculateQuantityByRNPTVAndTS");
	
	StringHandlers.Add("RecalculateQuantityByRNPTSuffix",
		"BatchProcessingOfTablePartServer.RecalculateQuantityByRnptSuffixInTSLine");
		
	StringHandlers.Add("RecalculateNumberOfPackages",
		"BatchProcessingOfTablePartServer.RecalculateNumberOfPackages");
	
	StringHandlers.Add("RecalculateNumberOfSuffixPacks",
		"BatchProcessingOfTablePartServer.RecalculateNumberOfSuffixPacks");
	
	StringHandlers.Add("RecalculateAmountOfDeviation",
		"BatchProcessingOfTablePartClientServer.RecalculateAmountOfDeviation");
		
	StringHandlers.Add("RecalculateNumberOfPackagesByWeight",
		"BatchProcessingOfTablePartServer.RecalculateNumberOfPackagesByWeight");
	
	StringHandlers.Add("RecalculateNumberOfPackagesByVolume",
		"BatchProcessingOfTablePartServer.RecalculateNumberOfPackagesByVolume");
	
	StringHandlers.Add("FillInExcisableItemAttribute",
		"BatchProcessingOfTablePartServer.FillInExcisableItemAttribute");
	
	StringHandlers.Add("RecalculateExciseTaxAmount",
		"BatchProcessingOfTablePartServer.RecalculateExciseTaxAmountInTSLine");
	
	StringHandlers.Add("RecalculateWeightVolume",
		"BatchProcessingOfTablePartClientServer.RecalculateWeightVolumeInTSString");
	
	StringHandlers.Add("FillInPriceView",
		"BatchProcessingOfTablePartClientServer.FillInPriceTypeInTSLine");
	
	StringHandlers.Add("RecalculatePricePerPackage",
		"BatchProcessingOfTablePartClientServer.RecalculatePricePerPackageInTSLine");
	
	StringHandlers.Add("RecalculatePricePerPackageSuffix",
		"BatchProcessingOfTablePartClientServer.RecalculatePricePerPackageSuffixInLineTS");
	
	StringHandlers.Add("RecalculateOrderPricePerPackage",
		"BatchProcessingOfTablePartClientServer.RecalculateOrderPricePerPackageInTSLine");
	
	StringHandlers.Add("CheckFillInPriceView",
		"BatchProcessingOfTablePartServer.CheckFillInPriceTypeInTSLine");
		
	StringHandlers.Add("FillInSalePrice",
		"BatchProcessingOfTablePartServer.FillInSalePrice");
	
	StringHandlers.Add("FillInSalePriceByProductRange",
		"BatchProcessingOfTablePartServer.FillInSalePriceByProductRange");
	
	StringHandlers.Add("FillInDefaultSupplierAgreement",
		"BatchProcessingOfTablePartServer.FillInDefaultSupplierAgreement");
	
	StringHandlers.Add("FillInAttributesAccordingToSupplierSAgreement",
		"BatchProcessingOfTablePartServer.FillInAttributesAccordingToSupplierSAgreement");
	
	StringHandlers.Add("FillInNumberOfSupplierAgreements",
		"BatchProcessingOfTablePartServer.FillInNumberOfSupplierAgreements");
	
	StringHandlers.Add("FillInPartnerSDefaultCounterparty",
		"BatchProcessingOfTablePartServer.FillInPartnerSDefaultCounterparty");
	
	StringHandlers.Add("FillInDefaultContract",
		"BatchProcessingOfTablePartServer.FillInDefaultContract");
	
	StringHandlers.Add("CompleteOfOperationAccordingToAgreementContract",
		"BatchProcessingOfTablePartServer.CompleteOfOperationAccordingToAgreementContract");
	
	StringHandlers.Add("FillInVATTaxationPurchases",
		"VATAccountingERP.CompleteTaxationOfVATPurchasesInBatch");
	
	StringHandlers.Add("FillInPurchasePrice",
		"BatchProcessingOfTablePartServer.FillInPurchasePrice");
	
	StringHandlers.Add("FillIn_TermsOfSales",
		"BatchProcessingOfTablePartServer.FillIn_TermsOfSales");
	
	StringHandlers.Add("FillInTermsOfServiceSales",
		"BatchProcessingOfTablePartServer.FillIn_TermsOfSales");
		
	StringHandlers.Add("FillInRetailSalesTermsAndConditions",
		"BatchProcessingOfTablePartServer.FillInRetailSalesTermsAndConditions");
	
	StringHandlers.Add("FillInTermsOfPurchase",
		"BatchProcessingOfTablePartServer.FillInTermsOfPurchase");
	StringHandlers.Add("FillInProductionDate",
		"BatchProcessingOfTablePartServer.FillInProductionDate");
	
	StringHandlers.Add("SetFlagForUsingPlannedCost",
		"BatchProcessingOfTablePartServer.SetFlagForUsingPlannedCostInTSLine");
		
	StringHandlers.Add("CheckFillIssuePrice",
		"BatchProcessingOfTablePartServer.CheckFillIssuePrice");
	StringHandlers.Add("FillInPriceOfTransferringProductsToGiver",
		"BatchProcessingOfTablePartServer.FillInPriceOfTransferringProductsToGiver");
	StringHandlers.Add("AdjustVATRate",
		"BatchProcessingOfTablePartServer.AdjustNDSRateInPMLine");
	
	StringHandlers.Add("FillInVATRate",
		"BatchProcessingOfTablePartServer.FillInBidNDSVLineTS");
	
	StringHandlers.Add("FillInVATRateSuffix",
		"BatchProcessingOfTablePartServer.FillInVATRateSuffixInTSLine");
		
	StringHandlers.Add("FillInVATRateByPriceType",
		"BatchProcessingOfTablePartServer.FillInVATRateByPriceTypeInTSLine");
	
	StringHandlers.Add("FillInVATRateSuffixByPriceType",
		"BatchProcessingOfTablePartServer.FillInVATRateSuffixByPriceTypeInTSLine");
	
	VATAccountingLocalization.WhenAddingCollectionLineHandlers(StringHandlers);
	
	RetailSalesLocalization.WhenAddingCollectionLineHandlers(StringHandlers);
	
	StringHandlers.Add("FillInHSCode",
		"BatchProcessingOfTablePartServer.FillInHSCodeForProductsInTSLine");
	
	StringHandlers.Add("RecalculatePriceWithVAT",
		"BatchProcessingOfTablePartServer.RecalculatePriceWithVAT");
	
	StringHandlers.Add("FillInVATRateForReturnableContainers",
		"BatchProcessingOfTablePartClientServer.FillInVATRateOfReturnableContainerInLineTS");
	
	StringHandlers.Add("RecalculateAmountOfManualDiscount",
		"BatchProcessingOfTablePartClientServer.RecalculateAmountOfManualDiscountInTSLine");
	
	StringHandlers.Add("RecalculateAmountOfAutomaticDiscount",
		"BatchProcessingOfTablePartClientServer.RecalculateAmountOfAutomaticDiscountInTSLine");
	
	StringHandlers.Add("RecalculatePercentageOfManualDiscount",
		"BatchProcessingOfTablePartClientServer.RecalculatePercentageOfManualDiscountInTSLine");
	
	StringHandlers.Add("FillInSpaceInTSLine",
		"BatchProcessingOfTablePartClientServer.FillInSpaceInTSLine");
	StringHandlers.Add("RecalculateAmountOfServiceOrderGiver",
		"BatchProcessingOfTablePartClientServer.RecalculateAmountOfServiceInLineTSOrderGiver");
	
	StringHandlers.Add("RecalculateGiverSOrderAmount",
		"BatchProcessingOfTablePartClientServer.RecalculateAmountInLineTSOrderGiver");
	StringHandlers.Add("RecalculateAmount",
		"BatchProcessingOfTablePartClientServer.RecalculateAmountInTSLine");
	
	StringHandlers.Add("RecalculateSuffixAmount",
		"BatchProcessingOfTablePartClientServer.RecalculateSumOfSuffixInTSString");
	
	StringHandlers.Add("RecalculateAmountOfDiscrepancy",
		"BatchProcessingOfTablePartClientServer.RecalculateAmountInTSLineOfDiscrepancy");
	
	StringHandlers.Add("RecalculatePriceDiscountByAmountInSales",
		"BatchProcessingOfTablePartClientServer.RecalculateDiscountPriceByAmountInSalesInTSLine");
	
	StringHandlers.Add("RecalculatePriceDiscountForAmountInPurchases",
		"BatchProcessingOfTablePartClientServer.RecalculateDiscountPriceByAmountInPurchasesInTSLine");
	
	StringHandlers.Add("RecalculatePriceByAmount",
		"BatchProcessingOfTablePartClientServer.RecalculatePriceByAmountInTSLine");
	StringHandlers.Add("RecalculatePriceByAmountOfGiverSOrder",
		"BatchProcessingOfTablePartClientServer.RecalculatePriceByAmountInTSLineOfGiverSOrder");
	StringHandlers.Add("RecalculateSaleAmountByAmountWithVAT",
		"BatchProcessingOfTablePartServer.RecalculateSaleAmountByAmountWithVAT");
	
	StringHandlers.Add("RecalculateSalePriceBySaleAmount",
		"BatchProcessingOfTablePartClientServer.RecalculateSalePriceBySaleAmountInTSLine");
	
	StringHandlers.Add("RecalculateAmountTakingIntoAccountAutomaticDiscount",
		"BatchProcessingOfTablePartClientServer.RecalculateAmountTakingIntoAccountAutomaticDiscountInTSLine");
	
	StringHandlers.Add("RecalculateAmountTakingIntoAccountManualDiscount",
		"BatchProcessingOfTablePartClientServer.RecalculateAmountTakingIntoAccountManualDiscountInTSLine");
	
	StringHandlers.Add("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints",
		"BatchProcessingOfTablePartClientServer.RecalculateAmountTakingIntoAccountDiscountWithBonusPointsInTSLine");
	
	StringHandlers.Add("RecalculateAmountTakingIntoAccountRoundingError",
		"BatchProcessingOfTablePartServer.RecalculateAmountTakingIntoAccountRoundingErrorInTSLine");
	
	StringHandlers.Add("RecalculateVATAmount",
		"BatchProcessingOfTablePartServer.RecalculateAmountOfNDSVInTSLine");
	
	StringHandlers.Add("RecalculateVATAmountSuffix",
		"BatchProcessingOfTablePartServer.RecalculateAmountOfVATSuffixInTSLine");
	
	StringHandlers.Add("RecalculateAmountWithVAT",
		"BatchProcessingOfTablePartClientServer.RecalculateSumOfSNDSInTSLine");
	
	StringHandlers.Add("RecalculateSumWithVATSuffix",
		"BatchProcessingOfTablePartClientServer.RecalculateSumWithVATSuffixInTSString");
	
	StringHandlers.Add("RecalculateAmountWithoutVAT",
		"BatchProcessingOfTablePartClientServer.RecalculateAmountWithoutNDSVToTSLine");
	
	StringHandlers.Add("RecalculateLocalAmount",
		"BatchProcessingOfTablePartClientServer.RecalculateLocalSumInTSLine");
	
	StringHandlers.Add("RecalculatePDAmount",
		"BatchProcessingOfTablePartClientServer.RecalculateSumOfPRVAndTS");
	
	StringHandlers.Add("RecalculateAmountTa",
		"BatchProcessingOfTablePartClientServer.RecalculateSumOfNuvInTSLine");
	
	StringHandlers.Add("RecalculateAmountOfTD",
		"BatchProcessingOfTablePartClientServer.RecalculateAmountOfVRVTS");
	
	StringHandlers.Add("RecalculateLocalVAT",
		"BatchProcessingOfTablePartClientServer.RecalculateLocalVATInTSLine");
	
	StringHandlers.Add("RecalculateSaleAmount",
		"BatchProcessingOfTablePartClientServer.RecalculateSaleAmountInTSLine");
	
	StringHandlers.Add("RecalculateVATSalesAmount",
		"BatchProcessingOfTablePartClientServer.RecalculateAmountOfSaleOfNDSVToTSLine");
	
	StringHandlers.Add("ClearRewardAmount",
		"BatchProcessingOfTablePartClientServer.ClearRewardAmountInTSLine");
	
	StringHandlers.Add("SetActive",
		"BatchProcessingOfTablePartClientServer.SetStringActivity");
	StringHandlers.Add("CheckFillInCostShare",
		"BatchProcessingOfTablePartServer.CheckFillInCostShare");
	
	StringHandlers.Add("RecalculateCostShare",
		"BatchProcessingOfTablePartClientServer.RecalculateFractionOfCostInTSLine");
	StringHandlers.Add("FillInDefaultStorageLocationType",
		"BatchProcessingOfTablePartClientServer.FillInDefaultStorageLocationType");
	
	StringHandlers.Add("CheckCompleteConfigurationOptionByOwner",
		"BatchProcessingOfTablePartServer.CheckGetConfigurationOption");
	
	StringHandlers.Add("FillInDiscrepancyFlag",
		"BatchProcessingOfTablePartClientServer.FillInDiscrepancyFlag");
	
	StringHandlers.Add("RecalculateNumberOfPackagesDeviation",
		"BatchProcessingOfTablePartClientServer.RecalculateNumberOfPackagesDeviation");
	
	StringHandlers.Add("FillExcessSpoilageFlag",
		"BatchProcessingOfTablePartClientServer.FillExcessSpoilageFlag");
	
	StringHandlers.Add("ClearAmountOfSettlements",
		"BatchProcessingOfTablePartClientServer.ClearAmountOfSettlementsInTSLine");
	
	StringHandlers.Add("ClearAmountOfSettlementsSuffix",
		"BatchProcessingOfTablePartClientServer.ClearSumOfMutualSettlementsSuffixInTSLine");
	
	StringHandlers.Add("SetVATAmountLocalMans",
		"BatchProcessingOfTablePartClientServer.SetVATAmountOfLocalManInTSLine");
	
	StringHandlers.Add("RecalculateVATAmountOfShipment",
		"BatchProcessingOfTablePartClientServer.RecalculateVATAmountOfShipmentInTSLine");
	
	StringHandlers.Add("ClearAutomaticDiscount",
		"BatchProcessingOfTablePartClientServer.ClearAutomaticDiscountInTSLine");
	
	StringHandlers.Add("FillInContent",
		"BatchProcessingOfTablePartServer.FillInServiceContent");
	
	StringHandlers.Add("FillInItemCostAnalysisOfProductRange",
		"BatchProcessingOfTablePartServer.FillInItemCostAnalysisOfProductRange");
	
	StringHandlers.Add("ClearExpenseAnalytics_",
		"BatchProcessingOfTablePartServer.ClearExpenseAnalytics_");
	
	StringHandlers.Add("InitializeArticleAndAnalyticsAfterAddingLine",
		"BatchProcessingOfTablePartServer.InitializeArticleAndAnalyticsAfterAddingLine");
	
	StringHandlers.Add("FillInTheDefaultAccountSetting",
		"BatchProcessingOfTablePartServer.FillInTheDefaultAccountSetting");
	
	StringHandlers.Add("FillInInvoiceSettingsPresentation",
		"BatchProcessingOfTablePartServer.FillInInvoiceSettingsPresentation");
	
	StringHandlers.Add("FillInForm",
		"BatchProcessingOfTablePartClientServer.FillInForm");
	
	StringHandlers.Add("FillRoom",
		"BatchProcessingOfTablePartServer.FillRoom");
	
	StringHandlers.Add("FillOutSellerSForm",
		"BatchProcessingOfTablePartServer.FillOutSellerSForm");
	
	StringHandlers.Add("FillInAccountingQuantityOfProductItem",
		"BatchProcessingOfTablePartServer.FillInAccountingQuantityOfProductItem");
	
	StringHandlers.Add("FillInFlagForWhetherThereIsProductSoldJointly",
		"BatchProcessingOfTablePartServer.FillInFlagForWhetherThereIsProductSoldJointly");
	
	StringHandlers.Add("FillInNoReturnContainerAttribute",
		"BatchProcessingOfTablePartClientServer.FillInNoReturnContainerAttribute");
	
	StringHandlers.Add("FillInCanceledWithoutReturnableContainerAttribute",
		"BatchProcessingOfTablePartClientServer.FillInCanceledWithoutReturnableContainerAttribute");
	
	StringHandlers.Add("FillInActivityWithoutReturnableContainerAttribute",
		"BatchProcessingOfTablePartClientServer.FillInActivityWithoutReturnableContainerAttribute");
	
	StringHandlers.Add("FillInDuplicateDependentDetails",
		"BatchProcessingOfTablePartClientServer.FillInDuplicateDependentDetails");
	
	StringHandlers.Add("FillInSenderSControlledLotReference",
		"BatchProcessingOfTablePartServer.FillInSenderSControlledLotReference");
	
	StringHandlers.Add("CheckSeriesCalculateStatus",
		"BatchProcessingOfTablePartServer.CheckSeriesCalculateStatus");
	
	StringHandlers.Add("CheckBatchByOwner",
		"BatchProcessingOfTablePartServer.CheckBatchByOwner");
	
	StringHandlers.Add("CheckBarcodeRegistration",
		"BatchProcessingOfTablePartServer.CheckBarcodeRegistration");
	
	StringHandlers.Add("RecalculateAmountOverOrder",
		"BatchProcessingOfTablePartClientServer.RecalculateAmountInExcessOfOrderInTSLine");
	
	StringHandlers.Add("SetFlagForFillingInTextDescription",
		"BatchProcessingOfTablePartServer.SetFlagForFillingInTextDescription");
	
	StringHandlers.Add("FillInOptionToReflectImplementationAdjustment",
		"BatchProcessingOfTablePartClientServer.FillInOptionToReflectImplementationAdjustment");
	
	StringHandlers.Add("ProductsOnChangeOverridable",
		"BatchProcessingOfTablePartServer.ProductsOnChangeOverridable");
	
	StringHandlers.Add("CharacteristicOnChangeOverridable",
		"BatchProcessingOfTablePartServer.CharacteristicOnChangeOverridable");
	
	StringHandlers.Add("FillInAttributeAcceptedByCNU",
		"BatchProcessingOfTablePartServer.FillInAttributeAcceptedByCNU");
	
	StringHandlers.Add("FillInAddressStorageAttribute",
		"BatchProcessingOfTablePartServer.FillInAddressStorageAttribute");
	
	StringHandlers.Add("FillInSpaceUsageAttribute",
		"BatchProcessingOfTablePartServer.FillInSpaceUsageAttribute");
	
	StringHandlers.Add("RecalculateDiscrepanciesAfterShipment",
		"BatchProcessingOfTablePartClientServer.FillDiscrepanciesAfterShipment");
	
	StringHandlers.Add("RecalculateDiscrepanciesAfterAcceptance",
		"BatchProcessingOfTablePartClientServer.FillInDiscrepanciesAfterAcceptance");
	
	StringHandlers.Add("RecalculateDiscrepancies",
		"BatchProcessingOfTablePartClientServer.FillInTheDiscrepancies");
	
	StringHandlers.Add("FlagForAcceptanceComment",
		"BatchProcessingOfTablePartClientServer.FillInAcceptanceCommentFlag");
	
	StringHandlers.Add("FlagForShipmentComment",
		"BatchProcessingOfTablePartClientServer.FillInSignForShipmentComment");
	
	StringHandlers.Add("FlagForComment",
		"BatchProcessingOfTablePartClientServer.FillInFlagForComments");
	
	StringHandlers.Add("FillInPlaceAttributeThatRequiresProcessing",
		"BatchProcessingOfTablePartClientServer.FillInItemLocationAttributeProcessingRequired");
	
	StringHandlers.Add("FillInTrafficFlagForWarehouseRegisters",
		"BatchProcessingOfTablePartServer.FillInTrafficFlagForWarehouseRegisters");
	
	StringHandlers.Add("WhenChangingTypeOfProductOrSoftwareOption",
		"BatchProcessingOfTablePartServer.WhenChangingTypeOfProductOrSoftwareOption");
	
	StringHandlers.Add("WhenChangingProductType",
		"BatchProcessingOfTablePartServer.WhenChangingProductType");
	
	StringHandlers.Add("FillInServiceDetailsForPurpose",
		"BatchProcessingOfTablePartServer.FillInServiceDetailsForPurposeInLineTS");
	
	StringHandlers.Add("CheckFillAssignment",
		"BatchProcessingOfTablePartClientServer.CheckFillAssignmentInLineTS");
	
	StringHandlers.Add("FillFlagSeparatelyAsIntended",
		"BatchProcessingOfTablePartClientServer.FillFlagSeparatelyAsIntended");
	StringHandlers.Add("FillInPurposeOfProvisionInProductionPhase",
		"BatchProcessingOfTablePartClientServer.FillInPurposeOfProvisionInProductionPhase");
	
	StringHandlers.Add("FillInAssignmentInProductionPhase",
		"BatchProcessingOfTablePartClientServer.FillInAssignmentInProductionPhase");
	StringHandlers.Add("WhenChangingDestination",
		"BatchProcessingOfTablePartClientServer.WhenChangingAssignmentInTSLine");
	
	StringHandlers.Add("FillInCountryOfOriginForCCDNumber",
		"BatchProcessingOfTablePartServer.FillInCountryOfOriginForCCDNumber");
	
	StringHandlers.Add("FillInCountryOfOriginOfProduct",
		"BatchProcessingOfTablePartServer.FillInCountryOfOriginOfProduct");
	
	StringHandlers.Add("FillInMethodForDeterminingCost",
		"BatchProcessingOfTablePartClientServer.FillInMethodForDeterminingCost");
	
	StringHandlers.Add("FillInCostDeterminationMethodWithLine",
		"BatchProcessingOfTablePartClientServer.FillInCostDeterminationMethodWithLine");
	StringHandlers.Add("CheckFillCommunicationKeySpecifications",
		"BatchProcessingOfTablePartClientServer.CheckFillCommunicationKeySpecifications");
	
	StringHandlers.Add("FillInActionForRecyclableMaterials",
		"BatchProcessingOfTablePartClientServer.FillInActionForRecyclableMaterialsInTSLine");
	
	StringHandlers.Add("FillInProductOwnerIsAvailable",
		"BatchProcessingOfTablePartServer.FillInProductOwnerIsAvailable");
	StringHandlers.Add("FillInDirectionOfActivity",
		"BatchProcessingOfTablePartServer.FillInDirectionOfActivity");
	
	StringHandlers.Add("FillInSubdivisionInTSLine",
		"BatchProcessingOfTablePartServer.FillInSubdivisionInTSLine");
	
	StringHandlers.Add("CheckNeedToUpdateColumnIsAvailable",
		"BatchProcessingOfTablePartServer.CheckNeedToUpdateColumnIsAvailable");
	
	StringHandlers.Add("FillInAvailableColumn",
		"BatchProcessingOfTablePartServer.FillInAvailableColumn");
	
	StringHandlers.Add("UpdateProductCache_",
		"BatchProcessingOfTablePartServer.UpdateProductCache_");
	
	StringHandlers.Add("FillInDataOnPurchaseDocumentInReportToPurchasingCommittee",
		"BatchProcessingOfTablePartServer.FillInDataOnPurchaseDocumentInReportToPurchasingCommittee");
	
	StringHandlers.Add("FillInDiscrepancyAttributeOrder",
		"BatchProcessingOfTablePartServer.FillInDiscrepancyAttributeOrder");
	
	StringHandlers.Add("RecalculateAmountWithoutVATLocal",
		"BatchProcessingOfTablePartClientServer.RecalculateAmountWithoutVATLocalInTSLine");
	
	StringHandlers.Add("RecalculateAmountWithoutVATMan",
		"BatchProcessingOfTablePartClientServer.RecalculateAmountWithoutVATManInTSLine");
	
	StringHandlers.Add("RecalculateAmountWithoutVATLocalSuffix",
		"BatchProcessingOfTablePartClientServer.RecalculateAmountWithoutVATLocalSuffixInTSLine");
	
	StringHandlers.Add("RecalculateAmountWithoutVATManSuffix",
		"BatchProcessingOfTablePartClientServer.RecalculateAmountWithoutVATManSuffixInTSLine");
	
	StringHandlers.Add("FillInPresentationOfTermsOfPurchase",
		"BatchProcessingOfTablePartServer.FillInPresentationOfTermsOfPurchase");
	
	StringHandlers.Add("FillInCheckQualityDateOfQualityConfirmation",
		"BatchProcessingOfTablePartServer.FillInCheckQualityDateOfQualityConfirmation");
		
	StringHandlers.Add("FillInUnblockableDateOfQualityConfirmation",
		"BatchProcessingOfTablePartServer.FillInUnblockableDateOfQualityConfirmation");
		
	BatchProcessingOfTablePartServerLocalization.WhenAddingCollectionLineHandlers(StringHandlers);
	
EndProcedure

// Description of the query texts that need to be executed to get all the necessary data required for 
// string processing.
// 
// Parameters:
//  Actions - See ProcessTSStrings.StructureOfActions.
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure AddQueryTextsOfDataSources(Actions, CachedValues)
	
	Var ActionParameters;
	
	QueryDetails = CachedValues.QueryDetails; // See QueryDetails()
	
	// Supplied query texts to get all the necessary data for processing strings for the minimum number of requests.
	IncomeAndExpensesServer.AddQueryTextToArticleDetails(Actions, QueryDetails, CachedValues);
	IncomeAndExpensesServer.AddQueryTextToItemCostAnalyticsByDefault(Actions, QueryDetails, CachedValues);
	IncomeAndExpensesServer.AddAcceptedToQueryTextAttribute(Actions, QueryDetails, CachedValues);
	
	PurchasesServer.CompleteQueryTextOfCountryOfOriginByCCDNumber(Actions, QueryDetails, CachedValues);
	PurchasesServer.AddQueryTextToCCDNumberType(Actions, QueryDetails, CachedValues);
	PurchasesServer.CompleteQueryTextAndFillInParametersOfSupplierSAgreements(Actions, QueryDetails, CachedValues);
	PurchasesServer.CompleteQueryTextAndFillInAttributesAccordingToSupplierSAgreement(Actions, QueryDetails, CachedValues);
	PurchasesServer.CompleteQueryTextAndFillInDefaultContract(Actions, QueryDetails, CachedValues);
	PurchasesServer.CompleteQueryTextAndCompleteOperationOfOperationAccordingToAgreementContract(Actions, QueryDetails, CachedValues);
	PurchasesServer.CompleteQueryTextAndFillInPresentationOfTermsOfPurchase(Actions, QueryDetails, CachedValues);
	GLAccountSettingsServer.AddQueryTextsToDefaultAccountSettings(Actions,
		QueryDetails, CachedValues);
	ProductsSoldTogether.CompleteQueryTextToGetDataOnItemSoldJointly(Actions, 
		QueryDetails, CachedValues);
	
	ProductsServer.CompleteQueryTextDetailsForItem(Actions, QueryDetails, CachedValues);
	ProductsServer.AddQueryTextToServiceContent(Actions, QueryDetails, CachedValues);
	ProductsServer.AddQueryTextToCountryOfOriginOfItem(Actions, QueryDetails, CachedValues);
	ProductsServer.AddItemBarcodesToQueryText(Actions, QueryDetails, CachedValues);
	ProductsServer.SupplementQueryTextWithHSCodeByItem(Actions, QueryDetails, CachedValues);
	
	
	SalesServer.CompleteQueryTextWithDataOnPurchaseDocument(Actions, QueryDetails, CachedValues);
	SalesServer.CompleteTextFillingInPriceType(Actions, QueryDetails, CachedValues);
	
	WarehousesServer.CompleteQueryTextCheckFillOutWarehouse(Actions, QueryDetails, CachedValues);
	WarehousesServer.AddQueryTextForRegisteredRecordsOfWarehouseRegister(Actions, QueryDetails, CachedValues);
	WarehousesServer.AddOrderWarehouseAttributeToQueryText(Actions, QueryDetails, CachedValues);
	WarehousesServer.CompleteQueryTextUseBinLocationSystem(Actions, QueryDetails, CachedValues);
	WarehousesServer.AddQueryTextToUseStorageFacilities(Actions, QueryDetails, CachedValues);
	WarehousesServer.CompleteQueryTextAndFillInRoom(Actions, QueryDetails, CachedValues);
	
	InventoryInOperationServer.AddDescriptionOfBatchProcessingRequestTS(Actions, QueryDetails, CachedValues);
	
	VATAccountingERP.CompleteQueryTextVATRateForItemList(Actions, QueryDetails, CachedValues);
	VATAccountingERP.CompleteQueryTextRateAtVATRate(Actions, QueryDetails, CachedValues);
	VATAccountingERP.AddSuffixToQueryTextVATRate(Actions, QueryDetails, CachedValues);
	VATAccountingERP.CompleteQueryTextVATRateByPriceType(Actions, QueryDetails, CachedValues);
	
	ProvisionInDocumentsServer.BatchProcessingToSupplementDataSourceOfSoftwareInDocuments(
		Actions,
		QueryDetails,
		CachedValues);
	
	QualityControl.BatchProcessingToSupplementDataSourceQualityControl(Actions, QueryDetails,
		CachedValues);
	
	AccountingForTraceableGoodsLocalization.AddQueryTextsOfDataSources(Actions,
		QueryDetails,
		CachedValues);
		
	Catalogs.ProductKitConfigurations.CompleteQueryTextOfItemConfigurationOption(
		Actions,
		QueryDetails,
		CachedValues);
	
	InternalSubcontractingServer.CompleteQueryTextProductOwnerIsAvailable(Actions, QueryDetails, CachedValues);
	ProductionServer.CompleteQueryTextRecipientInDirectionOfIssue(Actions, QueryDetails, CachedValues);
	ProductionServer.AddShopFloorStockroomAttributeToQueryText(Actions, QueryDetails, CachedValues);
	ProductionServer.CompleteQueryTextCheckFillInCostFractionInBatches(Actions, QueryDetails, CachedValues);
	AssignmentsServer.AddQueryTextDetailsForIntendedPurpose(Actions, QueryDetails, CachedValues);
	ProductionSupply.CompleteQueryTextCheckFillInSupplyAtProductionStageInBatches(Actions, QueryDetails, CachedValues);
	ProductionSupply.CompleteQueryTextCheckFillOutProductionWarehouse(Actions, QueryDetails, CachedValues);
	EnterprisePricesFillingServer.CompleteQueryTextAndFillInPriceOfTransferringManufacturedProductsToGiver(Actions, QueryDetails, CachedValues);
	EnterprisePricesFillingServer.CompleteQueryTextCheckFillInIssuePrice(Actions, QueryDetails, CachedValues);

	EnterprisePricesFillingServer.CompleteQueryTextAndFillInSalesPrice(Actions, QueryDetails, CachedValues);
	
	ProductRangeServer.CompleteQueryTextAndFillInSalesPriceByProductRange(Actions, QueryDetails, CachedValues);
	ProductRangeServer.CompleteQueryTextCheckProductRangeOfLine(Actions, QueryDetails, CachedValues);
	
	SalesServer.CompleteQueryTextAndFillInSalesConditions(Actions, QueryDetails, CachedValues);
	
	RetailSales.CompleteQueryTextAndFillInTermsOfRetailSales(Actions, QueryDetails, CachedValues);
	
	LinesOfBusinessServer.CompleteQueryTextLineOfBusinessForIntendedPurpose(Actions, QueryDetails, CachedValues);
	
	PartnersProductsServer.CompleteQueryTextAndFillInPartnerSItemItem(Actions, QueryDetails, CachedValues);
	PartnersProductsServer.CompleteQueryTextAndFillInItemAccordingToPartnerSItem(Actions, QueryDetails, CachedValues);
	PartnersProductsServer.CompleteQueryTextCheckMatchedPartnerItem(Actions, QueryDetails, CachedValues);
	
	PartnersAndCounterparties.CompleteQueryTextAndFillInDefaultPartnerSCounterparty(Actions, QueryDetails, CachedValues);
	
	ProductsServer.CompleteQueryTextCheckCorrectnessFillInCharacteristicsAndPackagingUnits(Actions, QueryDetails, CachedValues);
	ProductsServer.CompleteQueryTextAndFillInAccountingNumberOfItems(Actions, QueryDetails, CachedValues);
	ProductsServer.AddQueryTextRecalculateNumberOfPackagingUnits(Actions, QueryDetails, CachedValues);
	ProductsServer.AddToQueryTextRecalculateNumberOfPackagingUnitsSuffix(Actions, QueryDetails, CachedValues);
	ProductsServer.SupplementQueryTextRecalculateNumberOfPackagingUnitsByWeight(Actions, QueryDetails, CachedValues);
	ProductsServer.SupplementQueryTextRecalculateNumberOfPackagingUnitsByVolume(Actions, QueryDetails, CachedValues);
	ProductsServer.CompleteQueryTextCheckBatchCalculateStatus(Actions, QueryDetails, CachedValues);
	ProductsServer.CompleteQueryTextCheckBatchByOwner(Actions, QueryDetails, CachedValues);
	
	PartnerPricesFillingServer.CompleteQueryTextAndFillInPurchasePrice(Actions, QueryDetails, CachedValues);
	PartnerPricesFillingServer.CompleteQueryTextAndFillInPurchaseConditions(Actions, QueryDetails, CachedValues);
	
	RebatesServer.AddQueryTextsOfDataSources(Actions, QueryDetails, CachedValues);
	
	InformationRegisters.ItemsBarcodes.CompleteQueryTextCheckBarcodeRegistration(Actions, QueryDetails, CachedValues);
	
	ExcisableGoodsAccounting.CompleteQueryTextAndFillInExcisableItemAttribute(Actions, QueryDetails, CachedValues);
	ExcisableGoodsAccounting.AddQueryTextAndRecalculateExciseTaxAmount(Actions, QueryDetails, CachedValues);
	
	BatchProcessingOfTablePartServerLocalization.AddQueryTextsOfDataSources(Actions, QueryDetails, CachedValues);
	
	DataSourceTable = QueryDetails.QueryOptions.DataSource; // ValueTable -
	
	For Each AdditionalColumn In QueryDetails.AddlColumns Do
		DataSourceTable.Columns.Add(AdditionalColumn.Key, AdditionalColumn.Value);
	EndDo;
	
EndProcedure

// Software filling of additional columns is used when it is more difficult to get data in a request than programmatically. 
Procedure FillInAdditionalColumns(StructureOfActions, CachedValues)
	
	ProcessedCollection = CachedValues.QueryDetails.QueryOptions.DataSource;
		
	VATAccountingERP.FillInDateOfBidReceiptColumn(ProcessedCollection, StructureOfActions, CachedValues);
	VATAccountingERP.FillInPriceTypeColumn(ProcessedCollection, StructureOfActions, CachedValues);
	
EndProcedure

Function DependentTSStringHandlers(StructureOfActions, CachedValues)

	ReadableFields = CachedValues.ReadableFields;
	EditableFields = CachedValues.EditableFields;
	
	MethodsForImplementation = MethodsForImplementation(StructureOfActions, CachedValues);
	
	HandlersQueue = New ValueList;
	
	For Each MethodForExecution In MethodsForImplementation Do
		
		HandlerName = MethodForExecution.DataProcessor;
		HandlerDetails = DescriptionOfTSStringHandler();
		QueueDescription = HandlersQueue.Add(HandlerDetails, HandlerName);
		If ReadableFields.Property(HandlerName) Then
			QueueDescription.Value.ReadableFields = ReadableFields[HandlerName];
		EndIf;
		
		If EditableFields.Property(HandlerName) Then
			QueueDescription.Value.EditableFields = EditableFields[HandlerName];
		EndIf;
		
	EndDo;
	
	ThereAreDependentHandlers = False;
	
	// The procedure for working on a string is described in the method for adding processing a StringCollection
	For Each Handler In HandlersQueue Do
		
		Counter = HandlersQueue.IndexOf(Handler);
		HandlerDetails = Handler.Value;
		
		// Dependency analysis is performed from later Actions to earlier Ones
		While Counter > 0 Do
			Counter = Counter - 1;
			HandlerBeingAnalyzed = HandlersQueue[Counter].Value;
			
			// If a previously executed handler changes the data, then for a later 
			// one we set the queue to one more
			For Each ReadableField In HandlerDetails.ReadableFields Do
				If HandlerBeingAnalyzed.EditableFields.Property(ReadableField.Key)
					And HandlerDetails.Queue <= HandlerBeingAnalyzed.Queue Then
						HandlerDetails.Queue = HandlerBeingAnalyzed.Queue + 1;
						
						HandlerDetails.SlaveHandlers.Insert(
							HandlersQueue[Counter].Presentation, HandlerBeingAnalyzed);
							
						HandlerBeingAnalyzed.DependentHandlers.Insert(
							Handler.Presentation);
							
						ThereAreDependentHandlers = True;
				EndIf;
			EndDo;
			
			// If the handlers modify the same data, then their queue must either be the same
			// either the later one has a longer queue than the earlier one
			For Each FieldsToChange In HandlerDetails.EditableFields Do
				If HandlerBeingAnalyzed.EditableFields.Property(FieldsToChange.Key)
					And HandlerDetails.Queue < HandlerBeingAnalyzed.Queue Then
						HandlerDetails.Queue = HandlerBeingAnalyzed.Queue;
				EndIf;
			EndDo;
			
		EndDo;
		
	EndDo;
	
	QueueOfHandlersByStructure = New Structure;
	
	For Each Handler In HandlersQueue Do
		QueueOfHandlersByStructure.Insert(Handler.Presentation, Handler.Value);
	EndDo;
	
	Return ?(ThereAreDependentHandlers, QueueOfHandlersByStructure, New Structure);
	
EndFunction

Function MethodsForImplementation(StructureOfActions, CachedValues)

	ComplianceWithVT = BatchProcessingOfTablePartCached.MethodsForImplementation();
	VTActionStructure = ComplianceWithVT.Copy(New Array()); 
	CopyOfActionStructure = New Structure;
	For Each KeyValue In StructureOfActions Do
		CopyOfActionStructure.Insert(KeyValue.Key);
	EndDo;
	
	For Each Action In CopyOfActionStructure Do
		
		If CachedValues.Property("SkippedActions")
			And CachedValues.SkippedActions.Property(Action.Key) Then
				Continue;
		EndIf;
		
		FoundRows = ComplianceWithVT.FindRows(New Structure("DataProcessor", Action.Key));
		For Each DataProcessor In FoundRows Do
			 FillPropertyValues(VTActionStructure.Add(), DataProcessor);
		EndDo;
	EndDo;
	
	VTActionStructure.Sort("Order");
	
	Return VTActionStructure;
	
EndFunction

Procedure AddTempTableByCollection(QueryDetails, Collection, CachedValues)
	
	SourceTable1 = New ValueTable();
	
	If TypeOf(Collection) = Type("ValueTable") Then
		
			If Collection.Columns.Find("IdOfTTRow") = Undefined Then
				
				Collection.Columns.Add("IdOfTTRow", 
					New TypeDescription("String", New StringQualifiers(36)));
					
				If Not CachedValues.Property("ProcessingSingleLine") Then
					
					For Each CollectionRow In Collection Do
						CollectionRow.IdOfTTRow = String(New UUID());
					EndDo;
					
					CachedValues.Insert("PathToRowId", "IdOfTTRow");
				EndIf;
				
			EndIf;
			
			SourceTable1 = Collection.Copy();
			
	ElsIf TypeOf(Collection) = Type("FormDataCollection")
		Or IsTabularSection(Collection) Then
				
		SourceTable1 = FormDataIsCollectionInTableOfValues(
				Collection, CachedValues);

	EndIf;
	
	QueryText =
		"SELECT
		|	* 
		|INTO
		|	TTDataSource
		|FROM
		|	&DataSource AS NestedQuery
		|INDEX BY
		|	IdOfTTRow";
		
	QueryDetails.QueriesTexts.Insert(0, QueryText);
	QueryDetails.QueryOptions.Insert("DataSource", SourceTable1);
	
	DeleteUnsupportedTypesInRequest(QueryDetails, CachedValues);
	
EndProcedure

Procedure RemoveUnsupportedTypesOnClient(CachedValues)
	
	CachedValues.Delete("DataForProcessing");
	CachedValues.Delete("QueryDetails");
	CachedValues.Delete("ExternalDescriptionOfRequest");
	CachedValues.Delete("CurrentRowInCollection");
	
	For Each KeyValue In CachedValues Do
		If TypeOf(KeyValue.Value) = Type("ValueTable") Then
			CachedValues.Delete(KeyValue.Key);
		EndIf;
	EndDo;
	
EndProcedure

Procedure DeleteUnsupportedTypesInRequest(QueryDetails, CachedValues)
	
	ProcessedTable = QueryDetails.QueryOptions.DataSource; // ValueTable
		
	If Not CachedValues.Property("UnsupportedFieldsInRequest") Then
		ColumnsToDelete = New Array();
		UnsupportedTypes = New Array();
		UnsupportedTypes.Add(Type("ValueList"));
		UnsupportedTypes.Add(Type("StandardPeriod"));
		UnsupportedTypes.Add(Type("TypeDescription"));
		For Each Column In ProcessedTable.Columns Do
			For Each UnsupportedType In UnsupportedTypes Do
				If Column.ValueType.Types().Find(UnsupportedType) <> Undefined 
					Or Not Column.ValueType.Types().Count()
					Or Column.ValueType = Undefined 
					Or Column.ValueType = New TypeDescription() Then
						ColumnsToDelete.Add(Column.Name);
				EndIf;
			EndDo;
		EndDo;
		CachedValues.Insert("UnsupportedFieldsInRequest", ColumnsToDelete);
	Else
		ColumnsToDelete = CachedValues.UnsupportedFieldsInRequest;
	EndIf;
	
	For Each ColumnToDelete_ In ColumnsToDelete Do
		If ProcessedTable.Columns.Find(ColumnToDelete_) <> Undefined Then
			ProcessedTable.Columns.Delete(ColumnToDelete_);
		EndIf;
	EndDo;
	
EndProcedure

Procedure CheckDependencyOfHandlers(HandlerDependentItem, HandlerMaster, DependencyDescriptions, Chain)
	
	If Not DependencyDescriptions.Property(HandlerDependentItem) Then
		Return;
	EndIf;
	
	IndexInChain = Chain.Find(HandlerMaster);
	
	If IndexInChain <> Undefined Then
		
		ChainWithLooping = New Array();
		For Counter = IndexInChain To Chain.Count() - 1 Do
			ChainWithLooping.Add(Chain[Counter]);
		EndDo;
		
		ChainWithLooping.Add(HandlerMaster);
		DescriptionOfLooping = StrConcat(ChainWithLooping, Chars.LF + Char(11107) + Chars.LF);
		
		MessageText = NStr("vi = 'Đã thiết lập sai cơ chế xử lý hàng loạt dòng phần bảng.
									|Đã tìm thấy tính chu kỳ trong mô tả phần phụ thuộc giữa các hàm sự kiện của dòng:
									|
									|%1';
									|ru = 'Некорректно встроен механизм пакетной обработки строк табличных частей.
									|Обнаружена цикличность в описании зависимостей между обработчиками строк:
									|
									|%1';
									|en = 'The tool for batch processing of table rows is built in incorrectly.
									|Cycling is found in descriptions of dependencies between row handlers:
									|
									|%1'; fa = 'The tool for batch processing of table rows is built in incorrectly.
									|Cycling is found in descriptions of dependencies between row handlers:
									|
									|%1';
									|it = 'Некорректно встроен механизм пакетной обработки строк табличных частей.
									|Обнаружена цикличность в описании зависимостей между обработчиками строк:
									|
									|%1';
									|pl = 'The tool for batch processing of table rows is built in incorrectly.
									|Cycling is found in descriptions of dependencies between row handlers:
									|
									|%1';
									|tr = 'Tablo satırlarının toplu olarak işlenmesi mekanizması hatalı bir şekilde oluşturuldu.
									|Satır işleyicileri arasındaki bağlılıkların açıklamasında döngüsellik tespit edildi:
									|
									|%1'");
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
							MessageText,
							DescriptionOfLooping);
		
		Raise MessageText;
	EndIf;
	
	If DependencyDescriptions.Property(HandlerMaster) Then
		For Each DescriptionOfDependencies In DependencyDescriptions[HandlerMaster] Do
			If DependencyDescriptions.Property(DescriptionOfDependencies) Then
				Chain.Add(HandlerMaster);
				CheckDependencyOfHandlers(HandlerMaster,
					DescriptionOfDependencies, DependencyDescriptions, Chain);
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

Function IsTabularSection(Collection)
	
	ValueType = TypeOf(Collection);
	ValueTypeAsString = Upper(StrReplace(String(ValueType)," ",""));
	
	DocumentReferenceType = Type("DocumentTabularSection.RegisterAdjustment.RegistersTable");
	ReferenceDocumentTypeIsString = Upper(StrReplace(String(DocumentReferenceType)," ",""));
	DocumentSeparatorPosition = StrFind(ReferenceDocumentTypeIsString,":")-1;
	
	CatalogReferenceType = Type("CatalogTabularSection.Companies.ContactInformation");
	CatalogReferenceTypeIsString = Upper(StrReplace(String(CatalogReferenceType)," ",""));
	DirectorySeparatorPosition = StrFind(CatalogReferenceTypeIsString,":")-1;
	
	TypeProcessingReference = Type("DataProcessorTabularSection.EDIWithBanks.BankAccounts");
	TypeStringProcessingReference = Upper(StrReplace(String(TypeProcessingReference)," ",""));
	PositionOfProcessingSeparator = StrFind(TypeStringProcessingReference,":")-1;
	
	IsTabularSection = Left(ValueTypeAsString, DocumentSeparatorPosition) = Left(ReferenceDocumentTypeIsString, DocumentSeparatorPosition)
					Or Left(ValueTypeAsString, DirectorySeparatorPosition) = Left(CatalogReferenceTypeIsString, DirectorySeparatorPosition)
					Or Left(ValueTypeAsString, PositionOfProcessingSeparator) = Left(TypeStringProcessingReference, PositionOfProcessingSeparator);
	
	Return IsTabularSection;
	
EndFunction

Function FormDataIsCollectionInTableOfValues(Collection, CachedValues, Rows = Undefined)
	
	SourceTable1 = Collection.Unload(Rows);
	SourceTable1.Columns.Add("IdOfTTRow",
		New TypeDescription("String", New StringQualifiers(36)));
	
	If SourceTable1.Columns.Find("LineNumber") = Undefined 
		Or TypeOf(Collection) = Type("FormDataCollection") Then
			Counter = 0;
			SourceOfIdentifiers = ?(Rows = Undefined, Collection, Rows);
			For Each CollectionRow In SourceOfIdentifiers Do
				SourceTable1[Counter].IdOfTTRow = String(CollectionRow.GetID());
				Counter = Counter + 1;
			EndDo;
			CachedValues.Insert("PathToRowId", "GetID");
	Else
		SourceTable1.LoadColumn(
			Collection.Unload(Rows, "LineNumber").UnloadColumn("LineNumber"), "IdOfTTRow");
			
		CachedValues.Insert("PathToRowId", "LineNumber");
	EndIf;
	
	Return SourceTable1;
	
EndFunction

Function GetTableByCollection(RowsCollection, TabPart, CachedValues)
	
	Var ValueTable;
	
	If TabPart = Undefined
		Or TabPart = RowsCollection Then
		ValueTable = RowsCollection;
	ElsIf IsTabularSection(TabPart)
		Or TypeOf(TabPart) = Type("FormDataCollection") Then
		CachedValues.Insert("TabularPartIsBeingProcessed");
			
		If TypeOf(RowsCollection[0]) = Type("Structure") Then
			ValueTable = TabPart.Unload(New Array);
			ValueTable.Columns.Add(
				"IdOfTTRow", New TypeDescription(
					"String", New StringQualifiers(36)));
			
			For Each CollectionRow In RowsCollection Do
				NewRow = ValueTable.Add();
				FillPropertyValues(NewRow, CollectionRow);
				NewRow.IdOfTTRow = CollectionRow.LineNumber;
			EndDo;
			
		Else
			ValueTable = FormDataIsCollectionInTableOfValues(
				TabPart, CachedValues, RowsCollection);
		EndIf;
			
	ElsIf TypeOf(TabPart) = Type("ValueTable") Then
		If CachedValues.Property("ProcessingSingleLine") Then
			FillPropertyValues(TabPart[0], RowsCollection[0]);
			ValueTable = TabPart;
		Else
			CachedValues.Insert("TabularPartIsBeingProcessed");
			
			If TabPart.Columns.Find("IdOfTTRow") = Undefined Then
				
				TabPart.Columns.Add("IdOfTTRow", 
					New TypeDescription("String", New StringQualifiers(36)));
				
				For Each CollectionRow In TabPart Do
					CollectionRow.IdOfTTRow = String(New UUID());
				EndDo;
				
			EndIf;
			ValueTable = TabPart.Copy(RowsCollection);
			CachedValues.Insert("PathToRowId", "IdOfTTRow");
		EndIf;
	EndIf;
		
	Return ValueTable;
	
EndFunction

Function DescriptionOfTSStringHandler()
	
	HandlerDetails = New Structure;
	HandlerDetails.Insert("Queue", 1);
	HandlerDetails.Insert("ReadableFields", New Structure);
	HandlerDetails.Insert("EditableFields", New Structure);
	HandlerDetails.Insert("DependentHandlers", New Structure);
	HandlerDetails.Insert("SlaveHandlers", New Structure);
	
	Return HandlerDetails;
	
EndFunction

Procedure InitializeBatchProcessing(CurrentRow, StructureOfActions, CachedValues, RowsCollection, CurrentRowInCollection)
	
	// Remove it after completing the embedding tasks
	If RowsCollection = Undefined
		Or CurrentRowInCollection = Undefined Then
		 Raise NStr("vi = 'Cơ chế xử lý hàng loạt các dòng của phần bảng được xây dựng không chính xác.
										|Các tham số bắt buộc chứa giá trị Không xác định.';
										|ru = 'Некорректно встроен механизм пакетной обработки строк табличных частей.
										|В обязательных параметрах передано значение Неопределено.';
										|en = 'The tool for batch processing of table rows is built in incorrectly.
										|The Undefined value is passed in the required parameters.'; fa = 'The tool for batch processing of table rows is built in incorrectly.
										|The Undefined value is passed in the required parameters.';
										|it = 'Некорректно встроен механизм пакетной обработки строк табличных частей.
										|В обязательных параметрах передано значение Неопределено.';
										|pl = 'The tool for batch processing of table rows is built in incorrectly.
										|The Undefined value is passed in the required parameters.';
										|tr = 'Tablo satırlarının toplu işlenme mekanizması hatalı oluşturulmuştur.
										|Tanımlanmamış değeri, zorunlu parametrelerde geçer.'");
	EndIf;
	
	CachedValues.Insert("CurrentRowInCollection", CurrentRowInCollection);
	CachedValues.Insert("CurrentRow", CurrentRow);
	
	If Not CachedValues.Property("InitializationIsComplete")
		Or Not CachedValues.Property("MethodsForImplementation") Then
			
		If Not CachedValues.Property("ReadableFields") Then
			BatchProcessingOfTablePartClientServer.FieldsOfActionLine(
				CurrentRow, StructureOfActions, CachedValues);
		EndIf;
			
		If Not CachedValues.Property("ThereAreDependentHandlers") Then
			CachedValues.Insert("ThereAreDependentHandlers",
				DependentTSStringHandlers(StructureOfActions, CachedValues).Count());
		EndIf;
		
		If CachedValues.ThereAreDependentHandlers
			And Not CachedValues.Property("CollectionProcessing") Then
				MethodName = "BatchProcessingOfTablePartServer.ProcessTSStrings";
				ExceptionText = StrTemplate(NStr("vi = 'Cơ chế xử lý hàng loạt các dòng phần bảng đã được xây dựng không chính xác.
										|Trong cấu trúc thao tác đã chỉ định các thao tác độc lập với nhau.
										|Để xử lý các dòng tập hợp trong trường hợp này, cần sử dụng phương thức 
										|%1, chỉ truyền các dòng cần xử lý vào tham số.';
										|ru = 'Некорректно встроен механизм пакетной обработки строк табличных частей.
										|В структуре действий указаны зависимые друг от друга действия.
										|Для обработки строк коллекции в такой ситуации следует использовать метод 
										|%1, передав в параметры только строки, требующие обработки.';
										|en = 'The tool for batch processing of table rows is built in incorrectly.
										|The action structure contains actions that depend on each other.
										|To process the collection rows in this case, use the 
										|%1 method, passing only rows that require processing to the parameters.'; fa = 'The tool for batch processing of table rows is built in incorrectly.
										|The action structure contains actions that depend on each other.
										|To process the collection rows in this case, use the 
										|%1 method, passing only rows that require processing to the parameters.';
										|it = 'Некорректно встроен механизм пакетной обработки строк табличных частей.
										|В структуре действий указаны зависимые друг от друга действия.
										|Для обработки строк коллекции в такой ситуации следует использовать метод 
										|%1, передав в параметры только строки, требующие обработки.';
										|pl = 'The tool for batch processing of table rows is built in incorrectly.
										|The action structure contains actions that depend on each other.
										|To process the collection rows in this case, use the 
										|%1 method, passing only rows that require processing to the parameters.';
										|tr = 'Tablo satırlarının toplu olarak işlenmesi mekanizması hatalı bir şekilde oluşturuldu.
										|Eylemlerin yapısı birbirine bağlı eylemleri gösterir.
										|Bu durumda koleksiyon satırlarının işlenmesi için parametrelere sadece işlenmesi gereken satırları geçirerek 
										|%1 yöntemini kullanmalısınız.'"), MethodName);
				Raise ExceptionText;
		EndIf;
			
		CachedValues.Insert("MethodsForImplementation", MethodsForImplementation(StructureOfActions, CachedValues));
		
		QueryDetails = QueryDetails();
		
		CachedValues.Insert("QueryDetails", QueryDetails);
		
		// Creating a temporary data source table
		AddTempTableByCollection(QueryDetails, RowsCollection, CachedValues);
		
		// Adding queries by mechanisms that process strings from common modules
		AddQueryTextsOfDataSources(StructureOfActions, CachedValues);
		
		// Adding queries by mechanisms that process strings from the embed location
		If CachedValues.Property("ExternalDescriptionOfRequest") Then
				For Each QueryText In CachedValues.ExternalDescriptionOfRequest.QueriesTexts Do
					CachedValues.QueryDetails.QueriesTexts.Add(QueryText.Value, QueryText.Presentation);
				EndDo;
			
			CommonClientServer.SupplementStructure(CachedValues.QueryDetails.QueryOptions,
																CachedValues.ExternalDescriptionOfRequest.QueryOptions);
		EndIf;
		
		If IsTabularSection(RowsCollection) Then
			CachedValues.Insert("TabularPartIsBeingProcessed");
		EndIf;
		
		FillInAdditionalColumns(StructureOfActions, CachedValues);
		
		Query = New Query();
		CommonClientServer.SupplementStructure(Query.Parameters, QueryDetails.QueryOptions);
		
		If QueryDetails.QueriesTexts.Count() > 1 Then
			If Not PrivilegedMode() And QueryDetails.PrivilegedMode Then
				SetPrivilegedMode(True);
			EndIf;
			
			Try
				Tables = TMCommonUse.UploadResultsOfQuery(Query, QueryDetails.QueriesTexts, ,True, True);
			Except
				
				MessageText = NStr("ru = 'Не удалось выполнить пакетную обработку строк таблицы.
					|Подробности см. в журнале регистрации.';
					|vi = 'Cannot perform batch processing of table rows.
					|For more information, see the event log.';
					|en = 'Cannot perform batch processing of table rows.
					|For more information, see the event log.'; fa = 'Cannot perform batch processing of table rows.
					|For more information, see the event log.';
					|it = 'Cannot perform batch processing of table rows.
					|For more information, see the event log.';
					|pl = 'Cannot perform batch processing of table rows.
					|For more information, see the event log.';
					|tr = 'Tablo satırlarının toplu işlenmesi tamamlanamadı. 
					| Ayrıntılar için olay günlüğüne bakın.'");
				
				ErrorText = StrTemplate(NStr(
						"ru = 'Не удалось выполнить пакетную обработку строк таблицы.
						|Выполняемые действия:
						|%1
						|По причине:
						|%2.';
						|vi = 'Cannot perform batch processing of table rows.
						|Actions performed:
						|%1
						|Reason:
						|%2.';
						|en = 'Cannot perform batch processing of table rows.
						|Actions performed:
						|%1
						|Reason:
						|%2.'; fa = 'Cannot perform batch processing of table rows.
						|Actions performed:
						|%1
						|Reason:
						|%2.';
						|it = 'Cannot perform batch processing of table rows.
						|Actions performed:
						|%1
						|Reason:
						|%2.';
						|pl = 'Cannot perform batch processing of table rows.
						|Actions performed:
						|%1
						|Reason:
						|%2.';
						|tr = 'Tablo satırlarının toplu işlenmesi tamamlanamadı. 
						|  Yürütülen eylemler: 
						|%1
						| Nedeni: 
						|%2.'", Common.DefaultLanguageCode()),
						StrConcat(CachedValues.MethodsForImplementation.UnloadColumn("DataProcessor"), Chars.LF),
						ErrorProcessing.DetailErrorDescription(ErrorInfo()));
				
				WriteLogEvent(
					"BatchProcessingOfTablePartServer.InitializeBatchProcessing", 
					EventLogLevel.Error,,,
					ErrorText);
				
				Raise MessageText;
				
			EndTry;
			
			If QueryDetails.PrivilegedMode Then
				SetPrivilegedMode(False);
			EndIf;
			
			For Each Table In Tables Do
				If Table.Value.Columns.Find("IdOfTTRow") <> Undefined Then
					Table.Value.Indexes.Add("IdOfTTRow");
				EndIf;
			EndDo;
			
			CachedValues.Insert("DataForProcessing", Tables);
		Else
			CachedValues.Insert("DataForProcessing", Undefined);
		EndIf;
		
		VTForCollection = CachedValues.QueryDetails.QueryOptions.DataSource; // ValueTable
			
		CachedValues.Insert("CollectionColumns", VTForCollection.Columns);
		CachedValues.Delete("QueryDetails");
		CachedValues.Delete("ExternalDescriptionOfRequest");
		
		// creating a template of the code text for processing one line
		
		LinesOfCodeForOneLine = New Array();
	
		For Each ActionMethod In CachedValues.MethodsForImplementation Do
			// Checking for an action in the list of actions is needed to perform an action based on a condition, depending 
			// on the row data. For an action that does not need to be performed on a specific line, it will be removed
			// from the action structure
			If StructureOfActions.Property(ActionMethod.DataProcessor)
				And LinesOfCodeForOneLine.Find(ActionMethod.Method) = Undefined Then
					LinesOfCodeForOneLine.Add(ActionMethod.Method);
			EndIf;
		EndDo;
		
		SingleLineProcessingCode = StrConcat(LinesOfCodeForOneLine, Chars.LF);
		
		CachedValues.Insert("SingleLineProcessingCode", SingleLineProcessingCode);
		CachedValues.Insert("InitializationIsComplete");
	
	EndIf;
	
EndProcedure

Function CurrentLineReplacementCode()
	
	LinesOfCode = New Array();
	LinesOfCode.Add("BatchProcessingOfTablePartServer.UpdateCurrentLine");
	LinesOfCode.Add("(");
	LinesOfCode.Add("Parameters");
	LinesOfCode.Add(");");
	
	Return StrConcat(LinesOfCode);

EndFunction

Procedure ExecuteStringProcessingCode(Parameters, CachedValues, NumberOfRowsInCollection = 1)
	
	Code_ToExecute = New Array();
		
	Parameters.Insert("CachedValues", CachedValues);
	Parameters.Insert("Counter", 0);
	
	StringProcessingCode = CachedValues.SingleLineProcessingCode;
	CurrentLineReplacementCode = CurrentLineReplacementCode();
	
	If Parameters.CachedValues.Property("CollectionProcessing") Then
		For Counter = 0 To NumberOfRowsInCollection - 1 Do
			Code_ToExecute.Add(CurrentLineReplacementCode);
			Code_ToExecute.Add(StringProcessingCode);
		EndDo;
	Else
		Code_ToExecute.Add(StringProcessingCode);
	EndIf;
	
	Algorithm = StrConcat(Code_ToExecute, Chars.LF);
	Common.ExecuteInSafeMode(Algorithm, Parameters);
	
EndProcedure

Procedure ClearActionParameters(StructureOfActions)
	
	ActionsForClearingParameters = ActionsForClearingParameters();
	
	For Each Action In ActionsForClearingParameters Do
		If StructureOfActions.Property(Action) Then
			StructureOfActions.Delete(Action);
			StructureOfActions.Insert(Action);
		EndIf;
	EndDo;
	
EndProcedure

Function ActionsForClearingParameters()
	
	Actions = New Array;
	
	Actions.Add("RecalculateAmountTakingIntoAccountRoundingError");
	
	Return Actions;
	
EndFunction

#Region StringHandlers

Procedure GetProductBatchIDInternalCoefficient(CurrentRow, Actions, CachedValues, PropertyName)

	Var RecalculationParameters;
	If Actions.Property(PropertyName, RecalculationParameters) Then
		
		FieldNameQuantity = "Count";
		NameOfQuantityFieldAccordingToRNPT = "QuantityByGBRN";
		If RecalculationParameters.Property("FieldNamesWithSuffix")
			And ValueIsFilled(RecalculationParameters.FieldNamesWithSuffix) Then
			
			If RecalculationParameters.FieldNamesWithSuffix.Property("Count") Then
				FieldNameQuantity = RecalculationParameters.FieldNamesWithSuffix.Count;
			EndIf;
			If RecalculationParameters.FieldNamesWithSuffix.Property("QuantityByGBRN") Then
				NameOfQuantityFieldAccordingToRNPT = RecalculationParameters.FieldNamesWithSuffix.QuantityByGBRN;
			EndIf;
			
		EndIf;
		
		If CurrentRow.AccountingForTheRNPTIsMaintained Then
			If Actions.Property("FillInCCDNumberType") Then
				If CurrentRow.CCDNumberType = PredefinedValue("Enum.CCDNumberTypes.KitRNPT") Then
					CurrentRow[NameOfQuantityFieldAccordingToRNPT] = CurrentRow[FieldNameQuantity];
				EndIf;
			Else
				DataForProcessing = DataForStringProcessing("CalculationOfQuantityByProductBatchID", CachedValues); 
				If Not DataForProcessing = Undefined Then
					ZoomRatio = DataForProcessing[0].ZoomRatio;
					CurrentRow[NameOfQuantityFieldAccordingToRNPT] = CurrentRow[FieldNameQuantity] * ZoomRatio;
				EndIf;
			EndIf;
		Else
			CurrentRow[NameOfQuantityFieldAccordingToRNPT] = 0;
		EndIf;
		
	EndIf;
EndProcedure

Procedure FillInVATRateBasedOnPriceTypeOfCurrentLine(NameOfVATRateColumn, CurrentRow, StructureOfActionParameters, CachedValues, DisplayMessage) Export
	
	Var ItemsType;
	Var CompanyForVATRate;
	Var OutgoingDocument;
	
	If Not StructureOfActionParameters.UsePriceManagementSystem25 Then
		Return;
	EndIf;
	
	BusinessOperation = StructureOfActionParameters.BusinessOperation;
	If SalesServer.BusinessTransactionWithRateWithoutVAT(BusinessOperation) Then
		CurrentRow[NameOfVATRateColumn] = Catalogs.VATRates.EXCLUDINGVAT;
		Return;
	EndIf;

	VATTaxation = StructureOfActionParameters.VATTaxation;
	If Not ValueIsFilled(VATTaxation) Then
		Return;
	EndIf;
	
	Products = Undefined;
	If CommonClientServer.HasAttributeOrObjectProperty(CurrentRow, "Products") Then
		Products = CurrentRow.Products;
	EndIf;

	If Not ValueIsFilled(Products) Then
		Return;
	EndIf;
	
	If StructureOfActionParameters.ToReturnReusablePackage Then
			
		If CommonClientServer.HasAttributeOrObjectProperty(CurrentRow, "ItemsType") Then
			ItemsType = CurrentRow.ItemsType;
		ElsIf ValueIsFilled(Products) Then
			ItemsTypes = CachedValues.ItemsTypes;
			ItemsType = ItemsTypes.Get(Products);
		EndIf;
		
		If ItemsType = PredefinedValue("Enum.ItemsTypes.ReusablePackage") Then
			
			CurrentRow[NameOfVATRateColumn] = Catalogs.VATRates.EXCLUDINGVAT;
			Return;
			
		EndIf;
	EndIf;
	
	CachedValues.Property("CompanyForVATRate", CompanyForVATRate);
	If CompanyForVATRate = Undefined Then
		CachedValues.Insert("CompanyForVATRate", StructureOfActionParameters.Organization);
	EndIf;
	
	CachedValues.Property("OutgoingDocument", OutgoingDocument);
	If OutgoingDocument = Undefined Then
		If StructureOfActionParameters.Property("InitializingIncomingDocument") Then 
			CachedValues.Insert("OutgoingDocument", Not StructureOfActionParameters.InitializingIncomingDocument);
		Else
			CachedValues.Insert("OutgoingDocument", False);
		EndIf;
	EndIf;
	
	StructurePriceType = VATAccountingERP.VATRateByPriceTypeInBatches(CachedValues);
	If Not ValueIsFilled(StructurePriceType) Then
		
		If Not ValueIsFilled(CurrentRow[NameOfVATRateColumn]) Then
			
			VATRate = VATAccountingERP.VATRateByItemAndTaxationInBatches(
					Products, VATTaxation, StructureOfActionParameters.Date, CachedValues);
			
			VATAccountingERP.FillInVATRateOfCurrentLineInBatches(CurrentRow, VATRate, NameOfVATRateColumn, CachedValues);
			
		EndIf;
		
		Return;
	EndIf;
	
	If Not StructurePriceType.SpecifyVATRate Then
		
		If Not VATTaxation = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT Then
			
			VATRate = VATAccountingERP.VATRateByItemAndTaxationInBatches(
					Products, VATTaxation, StructureOfActionParameters.Date, CachedValues);
			
			VATAccountingERP.FillInVATRateOfCurrentLineInBatches(CurrentRow, VATRate, NameOfVATRateColumn, CachedValues);
			
		EndIf;
				
		Return;
	EndIf;
		
	If Not StructurePriceType.CharacteristicFilledIn Then
		Return;
	EndIf;
	
	ErrorText = "";
	
	If Not CachedValues.Property("UseMultiCountryAccounting") Then
		CachedValues.Insert("UseMultiCountryAccounting", GetFunctionalOption("UseMultiCountryAccounting"));
	EndIf;
	
	If ValueIsFilled(StructurePriceType.VATRate) Then
		
		If (VATTaxation = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT
				And Not StructurePriceType.VATRate = Catalogs.VATRates.EXCLUDINGVAT)
			Or StructurePriceType.ExportSalesError Then
				
			ErrorText = NStr("ru = 'Ставка НДС установленная для вида цены, не соответствует указанному в документе налогообложению.';
							|vi = 'The VAT rate set for the price type does not match the taxation specified in the document.';
							|en = 'The VAT rate set for the price type does not match the taxation specified in the document.'; fa = 'The VAT rate set for the price type does not match the taxation specified in the document.';
							|it = 'The VAT rate set for the price type does not match the taxation specified in the document.';
							|pl = 'The VAT rate set for the price type does not match the taxation specified in the document.';
							|tr = 'Fiyat türü için belirlenen KDV oranı, belgede belirtilen vergilendirme ile uyuşmuyor.'");
			
		Else
			
			VATAccountingERP.FillInVATRateOfCurrentLineInBatches(CurrentRow, StructurePriceType.VATRate, NameOfVATRateColumn, CachedValues);
			
			If CachedValues.UseMultiCountryAccounting Then
				
				If ValueIsFilled(StructureOfActionParameters.CountryOfOrganizationRegistration)
						And Not StructurePriceType.Country = StructureOfActionParameters.CountryOfOrganizationRegistration Then
					ErrorText = NStr("ru = 'Страна в виде цен не соответствует стране регистрации организации.';
									|vi = 'The country in the price type does not match the company''s country of registration.';
									|en = 'The country in the price type does not match the company''s country of registration.'; fa = 'The country in the price type does not match the company''s country of registration.';
									|it = 'The country in the price type does not match the company''s country of registration.';
									|pl = 'The country in the price type does not match the company''s country of registration.';
									|tr = 'Fiyat türündeki ülke, iş yerinin kayıtlı olduğu ülkeyle uyuşmuyor.'");
				EndIf;
				
			EndIf;
			
		EndIf;
		
	Else
		If StructurePriceType.SpecifyVATRate Then
			ErrorText = StrTemplate(
				NStr("ru = 'На %1 не установлена Ставка НДС для выбранного вида цен.';
					|vi = 'The VAT rate for the selected price type is not set as of %1.';
					|en = 'The VAT rate for the selected price type is not set as of %1.'; fa = 'The VAT rate for the selected price type is not set as of %1.';
					|it = 'The VAT rate for the selected price type is not set as of %1.';
					|pl = 'The VAT rate for the selected price type is not set as of %1.';
					|tr = 'Seçilen fiyat türü için KDV oranı %1 kapsamında ayarlanmadı.'"),
				Format(StructureOfActionParameters.Date, NStr("vi = 'ДФ=''dd MMMM yyyy''';
																|ru = 'ДФ=''dd MMMM yyyy''';
																|en = 'DF=''MMMM dd yyyy'''; fa = 'DF=''MMMM dd yyyy''';
																|it = 'DF=''dd MMMM yyyy''';
																|pl = 'DF=''dd MMMM rrrr''';
																|tr = 'DF=''dd MMMM yyyy'''")));
		EndIf;
	EndIf;
	
	If DisplayMessage And ValueIsFilled(ErrorText)  Then
		
		If VATTaxation = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT Then
			CurrentRow[NameOfVATRateColumn] = Catalogs.VATRates.EXCLUDINGVAT;
		Else
			CurrentRow[NameOfVATRateColumn] = Catalogs.VATRates.EmptyRef();
		EndIf;
		
		PriceKind = StructurePriceType.PriceKind;
		If BatchProcessingOfTablePartServer.ThereIsColumnInDataSource("PriceKind", CachedValues)
			And ValueIsFilled(CurrentRow.PriceKind) Then
			PriceKind = CurrentRow.PriceKind;
		EndIf;
	
		TemplateText = StrTemplate(
				NStr("ru = 'Номенклатуру ""%1"" по виду цен ""%2"" продавать нельзя.';
					|vi = 'Cannot sell the ""%1"" item by the ""%2"" price type.';
					|en = 'Cannot sell the ""%1"" item by the ""%2"" price type.'; fa = 'Cannot sell the ""%1"" item by the ""%2"" price type.';
					|it = 'Cannot sell the ""%1"" item by the ""%2"" price type.';
					|pl = 'Cannot sell the ""%1"" item by the ""%2"" price type.';
					|tr = '""%1"" öğesi, ""%2"" fiyat türünde satılamaz.'") + " ",
				CurrentRow.Products,
				PriceKind);
				
		If BatchProcessingOfTablePartServer.ThereIsColumnInDataSource("LineNumber", CachedValues) Then
		
			TemplateText = StrTemplate(
				NStr("ru = 'В строке %1 - номенклатуру ""%2"" по виду цен ""%3"" продавать нельзя.';
					|vi = 'Cannot sell the ""%2"" item in line %1 by the ""%3"" price type.';
					|en = 'Cannot sell the ""%2"" item in line %1 by the ""%3"" price type.'; fa = 'Cannot sell the ""%2"" item in line %1 by the ""%3"" price type.';
					|it = 'Cannot sell the ""%2"" item in line %1 by the ""%3"" price type.';
					|pl = 'Cannot sell the ""%2"" item in line %1 by the ""%3"" price type.';
					|tr = '%1 satırındaki ""%2"" öğesi ""%3"" fiyat türünde satılamaz.'") + " ",
				CurrentRow.LineNumber,
				CurrentRow.Products,
				PriceKind);
				
		EndIf;
		
		Common.MessageToUser(TemplateText + ErrorText);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsOfFillingInServiceDetailsForProductRange

// Returns the selection field template that matches the specified action key
//
// Parameters:
//  ActionKey						 - String	 - String name of the key actions
//  OnlyCheckSupportedKeys	 - Boolean - indicates whether the action key is supported.
// 
// Returns:
//  String, Undefined - The query field template string.
//
Function TemplateForActionKeySelectionField(ActionKey, OnlyCheckSupportedKeys = False)
	
	TemplateLocalization = "";
	BatchProcessingOfTablePartServerLocalization.WhenDefiningSampleFieldTemplateByActionKey(ActionKey, TemplateLocalization);
	If ValueIsFilled(TemplateLocalization) Then
		Return TemplateLocalization;
	EndIf;
	
	If ActionKey = "FillInProductTypeAttribute_" Then
		Return ",
		|	TTTableOfProducts.%Key%.ItemsType AS %ReplacementValue%";
	EndIf;
	
	If ActionKey = "FillInProductTypeAttribute" Then
		Return ",
		|	TTTableOfProducts.%Key%.ProductKind AS %ReplacementValue%";
	EndIf;
	
	If ActionKey = "FillInUnitOfMeasurementAttribute" Then
		Return ",
		|	TTTableOfProducts.%Key%.UnitOfMeasure AS %ReplacementValue%";
	EndIf;
	
	If ActionKey = "FillInMeasuredValueTypeAttribute" Then
		Return ",
		|	TTTableOfProducts.%Key%.UnitOfMeasure.MeasuredValueType AS %ReplacementValue%";
	EndIf;
	
	If ActionKey = "FillPackageWeight" Then
		QueryText = ",
		|	CASE WHEN TTTableOfProducts.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|		THEN &QueryTextPackageWeight
		|	ELSE &QueryTextItemWeight
		|	END AS PackageWeight";
		
		QueryText = StrReplace(QueryText,
			"&QueryTextPackageWeight",
			Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight("TTTableOfProducts.Package","TTTableOfProducts.Products", False));
		QueryText = StrReplace(QueryText,
			"&QueryTextItemWeight",
			Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight("TTTableOfProducts.Products.UnitOfMeasure","TTTableOfProducts.Products", False));
		Return QueryText
	EndIf;
	
	If ActionKey = "FillPackageVolume" Then
		QueryText = ",
		|	CASE WHEN TTTableOfProducts.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|		THEN &QueryTextPackageVolume
		|	ELSE &QueryTextTheVolumeOfTheItem
		|	END AS PackageVolume";
		
		QueryText = StrReplace(QueryText,
			"&QueryTextPackageVolume",
			Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume("TTTableOfProducts.Package","TTTableOfProducts.Products", False));
		QueryText = StrReplace(QueryText,
			"&QueryTextTheVolumeOfTheItem",
			Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume("TTTableOfProducts.Products.UnitOfMeasure","TTTableOfProducts.Products", False));
		Return QueryText
	EndIf;
	
	If ActionKey = "FillInUnitOfWeight" Then
		Return ",
		|	CASE WHEN TTTableOfProducts.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Package)
		|		THEN TTTableOfProducts.Package.WeightUnitOfMeasure
		|	ELSE TTTableOfProducts.Products.WeightUnitOfMeasure
		|	END AS UnitOfMeasureForWeight";
	EndIf;
	
	If ActionKey = "FillInVolumeUnit" Then
		Return ",
		|	CASE WHEN TTTableOfProducts.Package.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Package)
		|		THEN TTTableOfProducts.Package.VolumeUnitOfMeasure
		|	ELSE TTTableOfProducts.Products.VolumeUnitOfMeasure
		|	END AS UnitOfMeasureForVolume";
	EndIf;
	
	If ActionKey = "RecalculateWeightVolume" Then
		QueryText = ",
		|	TTTableOfProducts.%Key% * &QueryTextPackageWeight / 
		|	CASE
		|		WHEN TTTableOfProducts.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|			OR TTTableOfProducts.Package.MeasuredValueType <> VALUE(Enum.TypesOfMeasuredValues.Package)
		|			AND ISNULL(TTTableOfProducts.Products.WeightUnitOfMeasure.Denominator, 0) <> 0
		|			THEN CAST(TTTableOfProducts.Products.WeightUnitOfMeasure.Numerator / TTTableOfProducts.Products.WeightUnitOfMeasure.Denominator AS NUMBER(27, 11))
		|		ELSE 1
		|	END AS Weight,
		|	TTTableOfProducts.%Key% * &QueryTextPackageVolume /
		|	CASE
		|		WHEN TTTableOfProducts.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|			OR TTTableOfProducts.Package.MeasuredValueType <> VALUE(Enum.TypesOfMeasuredValues.Package)
		|			AND ISNULL(TTTableOfProducts.Products.VolumeUnitOfMeasure.Denominator, 0) <> 0
		|			THEN CAST(TTTableOfProducts.Products.VolumeUnitOfMeasure.Numerator / TTTableOfProducts.Products.VolumeUnitOfMeasure.Denominator AS NUMBER(27, 11))
		|	ELSE 1
		|	END AS VolumeM3";
		QueryText = StrReplace(QueryText, "&QueryTextPackageWeight",
			Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight(
				"TTTableOfProducts.Package",
				"TTTableOfProducts.Products",
				False));
		QueryText = StrReplace(QueryText, "&QueryTextPackageVolume",
			Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume(
				"TTTableOfProducts.Package",
				"TTTableOfProducts.Products",
				False));
		
		Return QueryText;
	EndIf;
	
	If ActionKey = "RecalculateNumberOfPackages" Then
		QueryText = ",
		|	TTTableOfProducts.%Key% / ISNULL(&QueryTextPackagingFactor, 1) AS %ReplacementValue%";
		
		QueryText = StrReplace(QueryText, "&QueryTextPackagingFactor",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
				"TTTableOfProducts.Package",
				"TTTableOfProducts.Products"));
		
		Return QueryText;
	EndIf;

	If ActionKey = "FillInArticleAttribute" Then
		Return ",
		|	TTTableOfProducts.%Key%.SKU AS %ReplacementValue%";
	EndIf;

	If ActionKey = "FillInCodeAttribute" Then
		Return ",
		|	TTTableOfProducts.%Key%.Code AS %ReplacementValue%";
	EndIf;

	If ActionKey = "FillInDescriptionAttribute" Then
		Return ",
		|	TTTableOfProducts.%Key%.LongDesc AS %ReplacementValue%";
	EndIf;

	If ActionKey = "FillInSalesOptionAttribute" Then
		Return ",
		|	TTTableOfProducts.%Key%.SaleRegistrationOption AS %ReplacementValue%";
	EndIf;
	
	If ActionKey = "FillInFeatureAttribute" Then
		Return ",
		|	CASE WHEN TTTableOfProducts.%Key%.UseVariants IN (VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
		|																			VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind),
		|																			VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems))
		|		THEN TRUE ELSE FALSE
		|	END AS %ReplacementValue%";
	EndIf;
	
	If ActionKey = "FillInCCDTrackingAttribute" Then
		Return ",
		|	ISNULL(TTTableOfProducts.%Key%.KeepRecordsByCCD, FALSE) AS %ReplacementValue%";
	EndIf;
	
	If ActionKey = "FillInRnptTrackingAttribute" Then
		Return ",
		|	ISNULL(TTTableOfProducts.%Key%.TracedGoods, FALSE)
		|		AND ISNULL(TTTableOfProducts.%Key%.KeepRecordsByCCD, FALSE) AS %ReplacementValue%";
	EndIf;
	
	If ActionKey = "FillInUnitOfMeasurementOfFEA" Then
		Return ",
		|	TTTableOfProducts.%Key%.FEACNUnitOfMeasure AS %ReplacementValue%";
	EndIf;
	
	If ActionKey = "FillInFeatureThisIsService" Then
		Return ",
		|	CASE WHEN TTTableOfProducts.%Key%.ItemsType NOT IN
		|		(VALUE(Enum.ItemsTypes.OwnGoods),VALUE(Enum.ItemsTypes.ReusablePackage))
		|		THEN TRUE ELSE FALSE
		|	END AS %ReplacementValue%";
	EndIf;
	
	If ActionKey = "FillInSeriesAttribute" Then
		Return ",
		|	TTTableOfProducts.%Key%.ProductKind.KeepAccountingByBatch AS %ReplacementValue%";
	EndIf;
	
	If TypeOf(ActionKey) = Type("String")
		And Not OnlyCheckSupportedKeys Then
		QueryText =
			",
			|	TTTableOfProducts.%Key%.%FieldName% AS %ReplacementValue%";
		Return StrReplace(QueryText, "%FieldName%", ActionKey);
	EndIf;
	
	Return Undefined;
	
EndFunction

// Returns the RNPT coefficients for the specified Organization and the list of products.
//
// Parameters:
//	ExcludedDocument - DocumentRef - a document whose movements are excluded when calculating the coefficient for the RNPT.
//	Organization - CatalogRef.Companies - the organization for which the RNPT coefficients are calculated.
//	Goods - ValueTable - a table containing information about products.
//	CachedValues - Structure - saved values of parameters used in data processing.
//	Terms - CatalogRef.TermsOfSale - the agreement for which the coefficients on the RNPT are calculated.
//	
// Returns:
//	ValueTable - See AccountingForTraceableGoodsLocalization.GetCoefficientsOfTraceableGoods
//
Function GetRnptCoefficient(ExcludedDocument, Organization, Goods, CachedValues, Terms = Undefined) Export
	
	Coefficients =
		AccountingForTraceableGoodsLocalization.GetCoefficientsOfTraceableGoods(
			ExcludedDocument,
			Organization,
			Goods,
			Terms);
	
	Return Coefficients;
	
EndFunction

Function ActionException(Action)
	
	ExceptionsToActions = New Array();
	ExceptionsToActions.Add("MethodsForImplementation");
	ExceptionsToActions.Add("NumberOfActions");
	ExceptionsToActions.Add("FillInVATRateByPriceType");
	
	Return Not ExceptionsToActions.Find(Action.Key) = Undefined;
	
EndFunction

#EndRegion

#EndRegion
