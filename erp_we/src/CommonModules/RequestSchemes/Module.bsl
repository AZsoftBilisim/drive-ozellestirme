
#Region Public

// Returns the query schema based on the value of the passed index in the query batch.
//
// Parameters:
//  QuerySchema - QuerySchema - request schema.
//  IndexOfRequestInPackage - Number - index of the request in the request package. If omitted, the last request in the batch.
//
// Returns:
//  QuerySchemaSelectQuery, QuerySchemaTableDropQuery - the modified text of the request or request.
//
Function RequestRequestPackage(Val QuerySchema, IndexOfRequestInPackage = Undefined) Export
	Var RequestRequestPackage;
	
	QueryBatch = QuerySchema.QueryBatch;
	
	If IndexOfRequestInPackage = Undefined Then
		IndexOfRequestInPackage = QueryBatch.Count() - 1;
	EndIf;
	
	RequestRequestPackage = QueryBatch.Get(IndexOfRequestInPackage);
	
	Return RequestRequestPackage;
EndFunction 

// Adds a new field to the end of the selection section of the passed request
//
// Parameters:
//  Query - String, Query - request text or request.
//  FieldExpression - String - field expression for the selection section.
//  FieldAlias - String - alias of the field for the selection section.
//  IndexOfRequestInPackage - Number - index of the request in the request package. If omitted, the last request in the batch.
//  DCSQueryLanguageExtension - Boolean - True when you need to add an additional field to the section
//  				To SELECT the extensions of the query language CDS.
//  ReplaceExistingField - Boolean - True when you need to add an additional field to the query, even
//  				if it was added earlier. The previous field will be deleted.
//
// Returns:
//  String, Query - the modified text of the request or request.
//
Function AddSelectionFieldToQuery(Val Query, FieldExpression, FieldAlias = "", Val IndexOfRequestInPackage = Undefined, DCSQueryLanguageExtension = False, ReplaceExistingField = False) Export
	
	If TypeOf(Query) = Type("String") Then
		QueryText = Query;
	ElsIf TypeOf(Query) = Type("Query") Then 
		QueryText = Query.Text;
	Else
		Raise NStr("vi = 'Không hợp lệ loại tham số 1';
					|ru = 'Некорректный тип параметра 1';
					|en = 'Incorrect type of parameter 1'; fa = 'Incorrect type of parameter 1';
					|it = 'Tipo del parametro 1 non valido';
					|pl = 'Niepoprawny typ parametru 1';
					|tr = 'Yanlış parametre türü 1'") ;
	EndIf;
	
	QuerySchema = New QuerySchema;
	
	QuerySchema.SetQueryText(QueryText);
	
	ModifiedRequest = RequestRequestPackage(QuerySchema, IndexOfRequestInPackage);
	
	If TypeOf(ModifiedRequest) = Type("QuerySchemaTableDropQuery") Then
		Raise NStr("vi = 'Không thể thêm trường vào yêu cầu hủy bảng.';
					|ru = 'Невозможно добавить поля в запрос уничтожения таблицы.';
					|en = 'Cannot add fields to the table removal query.'; fa = 'Cannot add fields to the table removal query.';
					|it = 'Impossibile aggiungere i campi nella query di eliminazione della tabella.';
					|pl = 'Nie można dodać pól do żądania zniszczenia tabeli.';
					|tr = 'Tablo yıkma isteğine alan eklenemez.'"); 
	EndIf;
	
	Columns = ModifiedRequest.Columns;
	// Checking that the column was added earlier
	ColumnByAlias = Columns.Find(FieldAlias);
	ColumnAlreadyAdded = (ColumnByAlias <> Undefined);
	
	If ColumnAlreadyAdded And ReplaceExistingField Then
		Columns.Delete(Columns.IndexOf(ColumnByAlias));
	EndIf;
	
	For OperatorIndex = 0 To ModifiedRequest.Operators.Count() - 1 Do
		
		For Each Source In ModifiedRequest.Operators[OperatorIndex].Sources Do
			If TypeOf(Source.Source) = Type("QuerySchemaTempTableDescription")
				And Not StrFind(FieldExpression, Source.Source.Alias) = 0 Then
				FieldName = StrReplace(FieldExpression, Source.Source.Alias + ".", "");
				Source.Source.AvailableFields.Add(FieldName);
			EndIf;
		EndDo;
		
		SelectedFields = ModifiedRequest.Operators[OperatorIndex].SelectedFields;
		
		NewField = SelectedFields.Add(FieldExpression);
		
		NewColumn = Columns.Find(NewField);
		If ValueIsFilled(FieldAlias) Then
			NewColumn.Alias = FieldAlias;
		EndIf;
		
		// Only in the first request there can be fields for SKD
		If OperatorIndex = 0 And DCSQueryLanguageExtension Then
			ExpressionContainsParameter = StrFind(FieldExpression, "&");
			
			If ModifiedRequest.DataCompositionSelectionFields.Find(FieldAlias) = Undefined Then
				DCField = ModifiedRequest.DataCompositionSelectionFields.Add(FieldAlias); // QuerySchemaDataCompositionSelectionField -
				DCField.Alias = FieldAlias;
				DCField.UseAttributes = Not ExpressionContainsParameter;
			EndIf;
		EndIf;
		
	EndDo;
	
	// Let's remove the "garbage" of the query scheme
	FieldNumber = 1;
	SubstringYouAreLookingFor = " AS Field" + FieldNumber;
	GarbageFieldFound = StrFind(QueryText, SubstringYouAreLookingFor) > 0;
	While GarbageFieldFound Do 
		QueryText = StrReplace(QueryText, SubstringYouAreLookingFor, "");
		
		FieldNumber = FieldNumber + 1;
		SubstringYouAreLookingFor = " AS Field" + FieldNumber;
		GarbageFieldFound = StrFind(QueryText, SubstringYouAreLookingFor) > 0;
	EndDo;
	
	NewRequestText = QuerySchema.GetQueryText();
	
	If TypeOf(Query) = Type("String") Then
		Query = NewRequestText;
	ElsIf TypeOf(Query) = Type("Query") Then 
		Query.Text = NewRequestText;
	EndIf;
	
	Return Query;
	
EndFunction

// Sets the section to SELECT keywords "FIRST N".
//
// Parameters:
//  Query - String, Query - request text or request.
//  RetrievedRecordsCount - Number - the number of first entries to select.
//  							- Undefined - The keywords "FIRST N" will be excluded from the SELECT section.
//  IndexOfRequestInPackage - Number - index of the request in the request package. If omitted, the last request in the batch.
//
// Returns:
//  String, Query - the modified text of the request or request.
//
Function SetNumberOfRecordsReceived(Val Query, Val RetrievedRecordsCount, Val IndexOfRequestInPackage = Undefined) Export
	
	If TypeOf(Query) = Type("String") Then
		QueryText = Query;
	ElsIf TypeOf(Query) = Type("Query") Then 
		QueryText = Query.Text;
	Else
		Raise NStr("vi = 'Sai kiểu tham số 1';
					|ru = 'Некорректный тип параметра 1';
					|en = 'Incorrect type of parameter 1'; fa = 'Incorrect type of parameter 1';
					|it = 'Tipo del parametro 1 non valido';
					|pl = 'Niepoprawny typ parametru 1';
					|tr = 'Yanlış parametre türü 1'") ;
	EndIf;
	
	QuerySchema = New QuerySchema;
	
	QuerySchema.SetQueryText(QueryText);
	
	ModifiedRequest = RequestRequestPackage(QuerySchema, IndexOfRequestInPackage);
	
	If TypeOf(ModifiedRequest) = Type("QuerySchemaTableDropQuery") Then
		Raise NStr("vi = 'Không thể thêm số lượng bản ghi được chọn vào yêu cầu hủy bảng.';
					|ru = 'Невозможно добавить количество выбираемых записей в запрос уничтожения таблицы.';
					|en = 'Cannot add the number of selected entries to the table removal query.'; fa = 'Cannot add the number of selected entries to the table removal query.';
					|it = 'Impossibile aggiungere il numero di record selezionati alla query di eliminazione della tabella.';
					|pl = 'Nie można dodać ilość wybieranych wpisów do żądania zniszczenia tabeli.';
					|tr = 'Tablo silme sorgusuna seçilebilir kayıt sayısı eklenemiyor.'"); 
	EndIf;
	
	SelectOperator = ModifiedRequest.Operators[0];
	
	SelectOperator.RetrievedRecordsCount = RetrievedRecordsCount;
	
	QueryText = QuerySchema.GetQueryText();
	
	If TypeOf(Query) = Type("String") Then
		Query = QueryText;
	ElsIf TypeOf(Query) = Type("Query") Then 
		Query.Text = QueryText;
	EndIf;
	
	Return Query;
	
EndFunction

// Sets the section to SELECT the keyword "ALLOWED".
//
// Parameters:
//  Query - String, Query - request text or request.
//  SelectAllowed - Boolean - indicates whether to select only allowed entries.
//  			True - the keyword "ALLOWED" will be added to the SELECT section.
//  			False - the keyword "ALLOWED" will be excluded from the SELECT section.
//  IndexOfRequestInPackage - Number - index of the request in the request package. If omitted, the last request in the batch.
//
// Returns:
//  String, Query - the modified text of the request or request.
//
Function SetSelectionOfAllowedRecords(Val Query, Val SelectAllowed, Val IndexOfRequestInPackage = Undefined) Export
	
	If TypeOf(Query) = Type("String") Then
		QueryText = Query;
	ElsIf TypeOf(Query) = Type("Query") Then 
		QueryText = Query.Text;
	Else
		Raise NStr("vi = 'Sai kiểu tham số 1';
					|ru = 'Некорректный тип параметра 1';
					|en = 'Incorrect type of parameter 1'; fa = 'Incorrect type of parameter 1';
					|it = 'Tipo del parametro 1 non valido';
					|pl = 'Niepoprawny typ parametru 1';
					|tr = 'Yanlış parametre türü 1'") ;
	EndIf;
	
	QuerySchema = New QuerySchema;
	
	QuerySchema.SetQueryText(QueryText);
	
	ModifiedRequest = RequestRequestPackage(QuerySchema, IndexOfRequestInPackage);
	
	If TypeOf(ModifiedRequest) = Type("QuerySchemaTableDropQuery") Then
		Raise NStr("vi = 'Không thể thêm số lượng bản ghi được chọn vào yêu cầu hủy bảng.';
					|ru = 'Невозможно добавить количество выбираемых записей в запрос уничтожения таблицы.';
					|en = 'Cannot add the number of selected entries to the table removal query.'; fa = 'Cannot add the number of selected entries to the table removal query.';
					|it = 'Impossibile aggiungere il numero di record selezionati alla query di eliminazione della tabella.';
					|pl = 'Nie można dodać ilość wybieranych wpisów do żądania zniszczenia tabeli.';
					|tr = 'Tablo silme sorgusuna seçilebilir kayıt sayısı eklenemiyor.'"); 
	EndIf;
	
	ModifiedRequest.SelectAllowed = SelectAllowed;
	
	QueryText = QuerySchema.GetQueryText();
	
	If TypeOf(Query) = Type("String") Then
		Query = QueryText;
	ElsIf TypeOf(Query) = Type("Query") Then 
		Query.Text = QueryText;
	EndIf;
	
	Return Query;
	
EndFunction

Function SetSelectionOfAllowedRecordsInEntireRequest(Val Query, Val SelectAllowed) Export
	
	If TypeOf(Query) = Type("String") Then
		QueryText = Query;
	ElsIf TypeOf(Query) = Type("Query") Then 
		QueryText = Query.Text;
	Else
		Raise NStr("vi = 'Sai loại tham số 1';
					|ru = 'Некорректный тип параметра 1';
					|en = 'Incorrect type of parameter 1'; fa = 'Incorrect type of parameter 1';
					|it = 'Tipo del parametro 1 non valido';
					|pl = 'Niepoprawny typ parametru 1';
					|tr = 'Yanlış parametre türü 1'") ;
	EndIf;
	
	QuerySchema = New QuerySchema;
	
	QuerySchema.SetQueryText(QueryText);
	
	QueryBatch = QuerySchema.QueryBatch;
	NumberOfPackages_ = QueryBatch.Count();
	If NumberOfPackages_ > 0 Then
		For IndexOfRequestInPackage = 0 To NumberOfPackages_ - 1 Do
			ModifiedRequest = QueryBatch.Get(IndexOfRequestInPackage);
			If TypeOf(ModifiedRequest) = Type("QuerySchemaTableDropQuery") Then
				Continue;
			EndIf;
			ModifiedRequest.SelectAllowed = SelectAllowed;
		EndDo;
	EndIf;
	
	QueryText = QuerySchema.GetQueryText();
	
	If TypeOf(Query) = Type("String") Then
		Query = QueryText;
	ElsIf TypeOf(Query) = Type("Query") Then 
		Query.Text = QueryText;
	EndIf;
	
	Return Query;
	
EndFunction

// Sets the PLACE keyword and the name of the temporary table in the query text.
//
// Parameters:
//  Query - String, Query - request text or request.
//  TempTableName - String - the name of the temporary table corresponds to the keyword PUT in the query language
//  			. if an empty string is passed, the PLACE section will be removed from the query.
//  IndexOfRequestInPackage - Number - index of the request in the request package. If omitted, the last request in the batch.
//
// Returns:
//  String, Query - the modified text of the request or request.
//
Function SetRoomToTemporaryTable(Val Query, Val TempTableName, Val IndexOfRequestInPackage = Undefined) Export
	
	If TypeOf(Query) = Type("String") Then
		QueryText = Query;
	ElsIf TypeOf(Query) = Type("Query") Then 
		QueryText = Query.Text;
	Else
		Raise NStr("vi = 'Sai loại tham số 1';
					|ru = 'Некорректный тип параметра 1';
					|en = 'Incorrect type of parameter 1'; fa = 'Incorrect type of parameter 1';
					|it = 'Tipo del parametro 1 non valido';
					|pl = 'Niepoprawny typ parametru 1';
					|tr = 'Yanlış parametre türü 1'") ;
	EndIf;
	
	QuerySchema = New QuerySchema;
	
	QuerySchema.SetQueryText(QueryText);
	
	ModifiedRequest = RequestRequestPackage(QuerySchema, IndexOfRequestInPackage);
	
	If TypeOf(ModifiedRequest) = Type("QuerySchemaTableDropQuery") Then
		Raise NStr("vi = 'Không thể thêm tạo mới bảng tạm trong truy vấn hủy bảng.';
					|ru = 'Невозможно добавить создание временной таблицы в запрос уничтожения таблицы.';
					|en = 'Cannot add temporary table creation to the table removal query.'; fa = 'Cannot add temporary table creation to the table removal query.';
					|it = 'Impossibile aggiungere la creazione di una tabella temporanea nella richiesta di eliminazione della tabella.';
					|pl = 'Nie można dodać utworzenia tabeli tymczasowej do zapytania usunięcia tabeli.';
					|tr = 'Tablo silme sorgusuna geçici tablo oluşturma eklenemiyor.'"); 
	EndIf;
	
	ModifiedRequest.PlacementTable = TempTableName;
	
	QueryText = QuerySchema.GetQueryText();
	
	If TypeOf(Query) = Type("String") Then
		Query = QueryText;
	ElsIf TypeOf(Query) = Type("Query") Then 
		Query.Text = QueryText;
	EndIf;
	
	Return Query;
	
EndFunction

// Sets indexing in the query selection.
//
// Parameters:
//  Query - String, Query - request text or request.
//  AliasesOfIndexedFields - String - names of fields to be included in the query index
//  IndexOfRequestInPackage - Number - index of the request in the request package. If omitted, the last request in the batch.
//
// Returns:
//  String, Query - the modified text of the request or request.
//
Function SetIndexingOfQueryFields(Val Query, Val AliasesOfIndexedFields, Val IndexOfRequestInPackage = Undefined) Export
	
	If TypeOf(Query) = Type("String") Then
		QueryText = Query;
	ElsIf TypeOf(Query) = Type("Query") Then 
		QueryText = Query.Text;
	Else
		Raise NStr("vi = 'Sai kiểu tham số 1';
					|ru = 'Некорректный тип параметра 1';
					|en = 'Incorrect type of parameter 1'; fa = 'Incorrect type of parameter 1';
					|it = 'Tipo del parametro 1 non valido';
					|pl = 'Niepoprawny typ parametru 1';
					|tr = 'Yanlış parametre türü 1'") ;
	EndIf;
	
	QuerySchema = New QuerySchema;
	
	QuerySchema.SetQueryText(QueryText);
	
	ModifiedRequest = RequestRequestPackage(QuerySchema, IndexOfRequestInPackage);
	
	If TypeOf(ModifiedRequest) = Type("QuerySchemaTableDropQuery") Then
		Raise NStr("vi = 'Không thể thêm tạo mới bảng tạm trong truy vấn hủy bảng.';
					|ru = 'Невозможно добавить создание временной таблицы в запрос уничтожения таблицы.';
					|en = 'Cannot add temporary table creation to the table removal query.'; fa = 'Cannot add temporary table creation to the table removal query.';
					|it = 'Impossibile aggiungere la creazione di una tabella temporanea nella richiesta di eliminazione della tabella.';
					|pl = 'Nie można dodać utworzenia tabeli tymczasowej do zapytania usunięcia tabeli.';
					|tr = 'Tablo silme sorgusuna geçici tablo oluşturma eklenemiyor.'"); 
	EndIf;
	
	If Not ValueIsFilled(ModifiedRequest.PlacementTable) Then
		Raise NStr("vi = 'Không thể đặt chỉ mục các trường trong truy vấn, mà trong đó chưa đặt bảng tạm.';
					|ru = 'Невозможно установить индексацию полей в запросе, в котором не создается временная таблица.';
					|en = 'Cannot set field indexing in the query in which a temporary table is not generated.'; fa = 'Cannot set field indexing in the query in which a temporary table is not generated.';
					|it = 'Impossibile interrompere l''indicizzazione dei campi nella richiesta in cui non viene creata una tabella temporanea.';
					|pl = 'Nie można ustawić indeksacji pól w zapytaniu, w którym nie jest utworzona tabela tymczasowa.';
					|tr = 'Geçici tablo oluşturmayan sorguda alan endekslem ayarlanamaz.'");
	EndIf;
	
	ModifiedRequest.Index.Clear();
	
	AliasesOfIndexedFields =
		StringFunctionsClientServer.SplitStringIntoSubstringsArray(
			AliasesOfIndexedFields,,,
			True);
	
	For Each CurField In AliasesOfIndexedFields Do
		ModifiedRequest.Index.Add(CurField);
	EndDo;
	
	QueryText = QuerySchema.GetQueryText();
	
	If TypeOf(Query) = Type("String") Then
		Query = QueryText;
	ElsIf TypeOf(Query) = Type("Query") Then 
		Query.Text = QueryText;
	EndIf;
	
	Return Query;
	
EndFunction

// Adds a condition expression to the parameters of virtual tables
//
// Parameters:
//  Query - String, Query - request text or request.
//  ConditionExpression - String - condition expression for the parameters section of the virtual table.
//  IndexOfRequestInPackage - Number - index of the request in the request package. If omitted, the last request in the batch.
//
// Returns:
//  String, Query - the modified text of the request or request.
//
Function AddConditionToRequest(Val Query, ConditionExpression, Val IndexOfRequestInPackage = Undefined) Export
	
	If TypeOf(Query) = Type("String") Then
		QueryText = Query;
	ElsIf TypeOf(Query) = Type("Query") Then 
		QueryText = Query.Text;
	Else
		Raise NStr("vi = 'Sai loại tham số 1';
					|ru = 'Некорректный тип параметра 1';
					|en = 'Incorrect type of parameter 1'; fa = 'Incorrect type of parameter 1';
					|it = 'Tipo del parametro 1 non valido';
					|pl = 'Niepoprawny typ parametru 1';
					|tr = 'Yanlış parametre türü 1'") ;
	EndIf;
	
	If Not TypeOf(ConditionExpression) = Type("String") Then
		QueryText = Query;
		Raise NStr("vi = 'Sai loại tham số 2';
					|ru = 'Некорректный тип параметра 2';
					|en = 'Incorrect type of parameter 2'; fa = 'Incorrect type of parameter 2';
					|it = 'Tipo del parametro 2 non valido';
					|pl = 'Niepoprawny typ parametru 2';
					|tr = 'Yanlış parametre türü 2'") ;
	EndIf;
	
	QuerySchema = New QuerySchema;
	
	QuerySchema.SetQueryText(QueryText);
	
	ModifiedRequest = RequestRequestPackage(QuerySchema, IndexOfRequestInPackage);
	
	If TypeOf(ModifiedRequest) = Type("QuerySchemaTableDropQuery") Then
		Raise NStr("vi = 'Không thể thêm tham số vào bảng hủy truy vấn.';
					|ru = 'Невозможно добавить параметр в запрос уничтожения таблицы.';
					|en = 'Cannot add parameter to the table removal query.'; fa = 'Cannot add parameter to the table removal query.';
					|it = 'Impossibile aggiungere il parametro alla query di eliminazione della tabella.';
					|pl = 'Nie można dodać parametru do żądania zniszczenia tabeli.';
					|tr = 'Tablo silme sorgusuna parametre eklenemiyor.'"); 
	EndIf;
	
	// Substitution of an expression in all sources with parameters
	PartsOfExpression = New Array;
	For Each QueryOperator In ModifiedRequest.Operators Do 
		For Each OperatorSource In QueryOperator.Sources Do
			
			PartsOfExpression.Clear();
			
			Subquery = OperatorSource.Source;
			
			If TypeOf(Subquery) = Type("QuerySchemaNestedQuery") Then
				
				QueryTextSource1 = Subquery.Query.GetQueryText();
				QueryTextSource1 = AddConditionToRequest(QueryTextSource1, ConditionExpression);
				Subquery.Query.SetQueryText(QueryTextSource1);
				
			ElsIf TypeOf(Subquery) = Type("QuerySchemaTable") Then
				
				SourceParameters = Subquery.Parameters;
				ParametersCount = SourceParameters.Count();
				
				If ParametersCount = 0 Then
					Continue;
				EndIf;
				
				// In the RB 3 virtual tables, the parameter from the end is used for measurement conditions.
				If StrStartsWith(OperatorSource.Source.TableName, "AccountingRegister") Then
					LastSourceParameter = SourceParameters[ParametersCount - 3];
				Else
					LastSourceParameter = SourceParameters[ParametersCount - 1];
				EndIf;
				
				OriginalExpression = String(LastSourceParameter.Expression);
				If ValueIsFilled(OriginalExpression) Then
					PartsOfExpression.Add(OriginalExpression);
				EndIf;
				PartsOfExpression.Add(ConditionExpression);
				
				LastSourceParameter.Expression = New QuerySchemaExpression(StrConcat(PartsOfExpression, " And "));
				
			EndIf;
				
		EndDo;
	EndDo;
	
	QueryText = QuerySchema.GetQueryText();
	
	// Let's remove the "garbage" of the query scheme
	For FieldNumber = 1 To 9 Do 
		QueryText = StrReplace(QueryText, " AS Field" + FieldNumber, "");
	EndDo;
	
	If TypeOf(Query) = Type("String") Then
		Query = QueryText;
	ElsIf TypeOf(Query) = Type("Query") Then 
		Query.Text = QueryText;
	EndIf;
	
	Return Query;
	
EndFunction

// Adds ordering fields to the query.
//
// Parameters:
//  Query - String, Query - request text or request.
//  AliasesOfOrderingFields - String - comma-separated names of ordering fields.
//  IndexOfRequestInPackage - Number - index of the request in the request package. If omitted, the last request in the batch.
//
// Returns:
//  String, Query - the modified text of the request or request.
//
Function AddOrderingFieldsToQuery(Val Query, Val AliasesOfOrderingFields, Val IndexOfRequestInPackage = Undefined) Export
	
	If TypeOf(Query) = Type("String") Then
		QueryText = Query;
	ElsIf TypeOf(Query) = Type("Query") Then 
		QueryText = Query.Text;
	Else
		Raise NStr("vi = 'Sai kiểu tham số 1';
					|ru = 'Некорректный тип параметра 1';
					|en = 'Incorrect type of parameter 1'; fa = 'Incorrect type of parameter 1';
					|it = 'Некорректный тип параметра 1';
					|pl = 'Niepoprawny typ parametru 1';
					|tr = 'Yanlış parametre türü 1'") ;
	EndIf;
	
	If Not TypeOf(AliasesOfOrderingFields) = Type("String") Then
		QueryText = Query;
		Raise NStr("vi = 'Sai loại tham số 2';
					|ru = 'Некорректный тип параметра 2';
					|en = 'Incorrect type of parameter 2'; fa = 'Incorrect type of parameter 2';
					|it = 'Некорректный тип параметра 2';
					|pl = 'Niepoprawny typ parametru 2';
					|tr = 'Yanlış parametre türü 2'") ;
	EndIf;
	
	QuerySchema = New QuerySchema;
	
	QuerySchema.SetQueryText(QueryText);
	
	ModifiedRequest = RequestRequestPackage(QuerySchema, IndexOfRequestInPackage);
	
	If TypeOf(ModifiedRequest) = Type("QuerySchemaTableDropQuery") Then
		Raise NStr("vi = 'Không thể thêm tham số vào bảng hủy truy vấn.';
					|ru = 'Невозможно добавить параметр в запрос уничтожения таблицы.';
					|en = 'Cannot add parameter to the table removal query.'; fa = 'Cannot add parameter to the table removal query.';
					|it = 'Невозможно добавить параметр в запрос уничтожения таблицы.';
					|pl = 'Nie można dodać parametru do żądania zniszczenia tabeli.';
					|tr = 'Tablo silme sorgusuna parametre eklenemiyor.'");
	EndIf;
	
	If ValueIsFilled(ModifiedRequest.PlacementTable) Then
		Raise NStr("vi = 'Không thể thêm đặt trình tự vào yêu cầu tạo bảng tạm.';
					|ru = 'Невозможно добавить упорядочивание в запрос формирования временной таблицы.';
					|en = 'Cannot add ordering to a temporary table generation query.'; fa = 'Cannot add ordering to a temporary table generation query.';
					|it = 'Невозможно добавить упорядочивание в запрос формирования временной таблицы.';
					|pl = 'Cannot add ordering to a temporary table generation query.';
					|tr = 'Zamanlı tablo oluşturma sorgusuna parametre eklenemiyor.'");
	EndIf;
	
	ModifiedRequest.Order.Clear();
	
	AliasesOfIndexedFields =
		StringFunctionsClientServer.SplitStringIntoSubstringsArray(
			AliasesOfOrderingFields,,,
			True);
	
	For Each CurField In AliasesOfIndexedFields Do
		ModifiedRequest.Order.Add(CurField);
	EndDo;
	
	QueryText = QuerySchema.GetQueryText();
	
	If TypeOf(Query) = Type("String") Then
		Query = QueryText;
	ElsIf TypeOf(Query) = Type("Query") Then 
		Query.Text = QueryText;
	EndIf;
	
	Return Query;
	
EndFunction

// Adds totals fields to the query.
//
// Parameters:
//  Query - String, Query - request text or request.
//  AliasesOfTotalsFields - String - comma-separated field names of totals.
//  IndexOfRequestInPackage - Number - index of the request in the request package. If omitted, the last request in the batch.
//
// Returns:
//  String, Query - the modified text of the request or request.
//
Function AddTotalsFieldsToQuery(Val Query, Val AliasesOfTotalsFields, Val IndexOfRequestInPackage = Undefined) Export
	
	If TypeOf(Query) = Type("String") Then
		QueryText = Query;
	ElsIf TypeOf(Query) = Type("Query") Then 
		QueryText = Query.Text;
	Else
		Raise NStr("vi = 'Sai loại tham số 1';
					|ru = 'Некорректный тип параметра 1';
					|en = 'Incorrect type of parameter 1'; fa = 'Incorrect type of parameter 1';
					|it = 'Некорректный тип параметра 1';
					|pl = 'Niepoprawny typ parametru 1';
					|tr = 'Yanlış parametre türü 1'") ;
	EndIf;
	
	If Not TypeOf(AliasesOfTotalsFields) = Type("String") Then
		QueryText = Query;
		Raise NStr("vi = 'Sai loại tham số 2';
					|ru = 'Некорректный тип параметра 2';
					|en = 'Incorrect type of parameter 2'; fa = 'Incorrect type of parameter 2';
					|it = 'Некорректный тип параметра 2';
					|pl = 'Niepoprawny typ parametru 2';
					|tr = 'Yanlış parametre türü 2'") ;
	EndIf;
	
	QuerySchema = New QuerySchema;
	
	QuerySchema.SetQueryText(QueryText);
	
	ModifiedRequest = RequestRequestPackage(QuerySchema, IndexOfRequestInPackage);
	
	If TypeOf(ModifiedRequest) = Type("QuerySchemaTableDropQuery") Then
		Raise NStr("vi = 'Không thể thêm tham số vào bảng hủy truy vấn.';
					|ru = 'Невозможно добавить параметр в запрос уничтожения таблицы.';
					|en = 'Cannot add parameter to the table removal query.'; fa = 'Cannot add parameter to the table removal query.';
					|it = 'Невозможно добавить параметр в запрос уничтожения таблицы.';
					|pl = 'Nie można dodać parametru do żądania zniszczenia tabeli.';
					|tr = 'Tablo silme sorgusuna parametre eklenemiyor.'");
	EndIf;
	
	If ValueIsFilled(ModifiedRequest.PlacementTable) Then
		Raise NStr("vi = 'Không thể thêm đặt trình tự vào yêu cầu tạo bảng tạm.';
					|ru = 'Невозможно добавить упорядочивание в запрос формирования временной таблицы.';
					|en = 'Cannot add ordering to a temporary table generation query.'; fa = 'Cannot add ordering to a temporary table generation query.';
					|it = 'Невозможно добавить упорядочивание в запрос формирования временной таблицы.';
					|pl = 'Cannot add ordering to a temporary table generation query.';
					|tr = 'Zamanlı tablo oluşturma sorgusuna parametre eklenemiyor.'");
	EndIf;
	
	ModifiedRequest.Order.Clear();
	
	AliasesOfIndexedFields =
		StringFunctionsClientServer.SplitStringIntoSubstringsArray(
			AliasesOfTotalsFields,,,
			True);
	
	For Each CurField In AliasesOfIndexedFields Do
		ModifiedRequest.TotalExpressions.Add(CurField);
	EndDo;
	
	QueryText = QuerySchema.GetQueryText();
	
	If TypeOf(Query) = Type("String") Then
		Query = QueryText;
	ElsIf TypeOf(Query) = Type("Query") Then 
		Query.Text = QueryText;
	EndIf;
	
	Return Query;
	
EndFunction

// Changes the alias of the field in the text of the transmitted request
//
// Parameters:
//  Query - String, Query - request text or request.
//  FieldAlias - String - the current alias of the field.
//  NewFieldAlias - String - the new alias of the field.
//  IndexOfRequestInPackage - Number - index of the request in the request package. If omitted, the last request in the batch.
//
// Returns:
//  String, Query - the modified text of the request or request.
//
Function ChangeAliasOfSelectionFieldInRequest(Val Query, FieldAlias, NewFieldAlias, Val IndexOfRequestInPackage = Undefined) Export
	
	If TypeOf(Query) = Type("String") Then
		QueryText = Query;
	ElsIf TypeOf(Query) = Type("Query") Then 
		QueryText = Query.Text;
	Else
		Raise NStr("vi = 'Sai kiểu tham số 1';
					|ru = 'Некорректный тип параметра 1';
					|en = 'Incorrect type of parameter 1'; fa = 'Incorrect type of parameter 1';
					|it = 'Tipo del parametro 1 non valido';
					|pl = 'Niepoprawny typ parametru 1';
					|tr = 'Yanlış parametre türü 1'") ;
	EndIf;
	
	QuerySchema = New QuerySchema;
	QuerySchema.SetQueryText(QueryText);
	
	ModifiedRequest = RequestRequestPackage(QuerySchema, IndexOfRequestInPackage);
	
	If TypeOf(ModifiedRequest) = Type("QuerySchemaTableDropQuery") Then
		Raise NStr("vi = 'Không thể thay đổi tên ảo của trường trong truy vấn vi phạm bảng.';
					|ru = 'Невозможно изменить псевдоним поля в запрос уничтожения таблицы.';
					|en = 'Cannot change the field alias in the table removal query.'; fa = 'Cannot change the field alias in the table removal query.';
					|it = 'Impossibile modificare l''alias del campo nella richiesta di eliminazione della tabella.';
					|pl = 'Nie można zmienić pseudonimu pola zapytaniu usunięcia tabeli.';
					|tr = 'Tablo silme sorgusunda alan takma adı değiştirilemiyor.'");
	EndIf;
	
	ColumnToDelete = ModifiedRequest.Columns.Find(NewFieldAlias);
	If Not ColumnToDelete = Undefined Then
		ModifiedRequest.Columns.Delete(ModifiedRequest.Columns.IndexOf(ColumnToDelete));
	EndIf;
	
	QueryColumn = ModifiedRequest.Columns.Find(FieldAlias);
	If Not QueryColumn = Undefined Then
		
		QueryColumn.Alias = NewFieldAlias;
		
		NewRequestText = QuerySchema.GetQueryText();
		
		If TypeOf(Query) = Type("String") Then
			Query = NewRequestText;
		ElsIf TypeOf(Query) = Type("Query") Then 
			Query.Text = NewRequestText;
		EndIf;
		
		Return Query;
		
	Else
		Return Query;
	EndIf;
	
EndFunction

// Adds a new connection to the data source.
//
// Parameters:
//  Query - String, Query - request text or request.
//  SourceAlias - String - alias of the source to attach the table to.
//  IConnectionShort - See IConnectionShort
//  IndexOfRequestInPackage - Number - index of the request in the request package. If omitted, the last request in the batch.
//  ReplaceExistingConnection - Boolean - if True, the existing connection is deleted, if False, an exception is raised.
//
// Returns:
//  String, Query - the modified text of the request or request.
//
Function AddConnectionToRequest(Val Query, SourceAlias, IConnectionShort,
									Val IndexOfRequestInPackage = Undefined, ReplaceExistingConnection = False) Export
	
	If TypeOf(Query) = Type("String") Then
		QueryText = Query;
	ElsIf TypeOf(Query) = Type("Query") Then 
		QueryText = Query.Text;
	Else
		Raise NStr("vi = 'Sai kiểu tham số 1';
					|ru = 'Некорректный тип параметра 1';
					|en = 'Incorrect type of parameter 1'; fa = 'Incorrect type of parameter 1';
					|it = 'Tipo del parametro 1 non valido';
					|pl = 'Niepoprawny typ parametru 1';
					|tr = 'Yanlış parametre türü 1'");
	EndIf;
	
	QuerySchema = New QuerySchema;
	
	QuerySchema.SetQueryText(QueryText);
	
	ModifiedRequest = RequestRequestPackage(QuerySchema, IndexOfRequestInPackage);
	
	If TypeOf(ModifiedRequest) = Type("QuerySchemaTableDropQuery") Then
		Raise NStr("vi = 'Không thể thêm trường trong truy vấn hủy bảng.';
					|ru = 'Невозможно добавить поля в запрос уничтожения таблицы.';
					|en = 'Cannot add fields to the table removal query.'; fa = 'Cannot add fields to the table removal query.';
					|it = 'Impossibile aggiungere i campi nella query di eliminazione della tabella.';
					|pl = 'Nie można dodać pól do żądania zniszczenia tabeli.';
					|tr = 'Tablo yıkma isteğine alan eklenemez.'"); 
	EndIf;
	
	For Each CurOperator In ModifiedRequest.Operators Do
		
		Source = CurOperator.Sources.FindByAlias(SourceAlias);
		If Source = Undefined Then
			
			ExceptionText = NStr("vi = 'Trong truy vấn không có nguồn với tên ảo ""%1""';
								|ru = 'В запросе отсутствует источник с псевдонимом ""%1""';
								|en = 'The query does not contain the ""%1"" alias'; fa = 'The query does not contain the ""%1"" alias';
								|it = 'Nella richiesta manca la fonte con l''alias ""%1""';
								|pl = 'W zapytaniu nie ma źródła z pseudonimem ""%1""';
								|tr = 'Sorguda ""%1"" takma adına sahip kaynak yok'");
			ExceptionText = StrTemplate(ExceptionText, SourceAlias);
			
			Raise ExceptionText;
			
		EndIf;
		
		Join = Source.Joins.FindByName(IConnectionShort.TableDetails.TableName);
		If Not Join = Undefined
			And Not ReplaceExistingConnection Then
			
			ExceptionText = NStr("vi = 'Trong truy vấn đã có liên kết với bảng ""%1""';
								|ru = 'В запросе уже присутствует соединение с таблицей ""%1""';
								|en = 'The query already contains the ""%1"" table connection'; fa = 'The query already contains the ""%1"" table connection';
								|it = 'Nella richiesta vi è già connessione con la tabella ""%1""';
								|pl = 'W zapytaniu jest już połączenie z tabelą ""%1""';
								|tr = 'Sorguda ""%1"" tablosuna artık bağlantı mevcut'");
			ExceptionText = StrTemplate(ExceptionText, IConnectionShort.TableDetails.TableName);
			
			Raise ExceptionText;
			
		ElsIf Not Join = Undefined
			And ReplaceExistingConnection Then
			Source.Joins.Delete(Source.Joins.IndexOf(Join));
		EndIf;
		
		Join = Source.Joins.FindByAlias(IConnectionShort.TableDetails.TableAlias);
		If Not Join = Undefined
			And Not ReplaceExistingConnection Then
			
			ExceptionText = NStr("vi = 'Trong truy vấn đã có liên kết với tên ảo ""%1""';
								|ru = 'В запросе уже присутствует соединение с псевдонимом ""%1""';
								|en = 'The query already contains the ""%1"" alias connection'; fa = 'The query already contains the ""%1"" alias connection';
								|it = 'Nella richiesta vi è già connessione con l''alias ""%1""';
								|pl = 'W zapytaniu jest już połączenie z pseudonimem ""%1""';
								|tr = 'Sorguda ""%1"" takma adıyla artık bağlantı mevcut'");
			ExceptionText = StrTemplate(ExceptionText, IConnectionShort.TableDetails.TableAlias);
			
			Raise ExceptionText;
			
		ElsIf Not Join = Undefined
			And ReplaceExistingConnection Then
			Source.Joins.Delete(Source.Joins.IndexOf(Join));
		EndIf;
		
		ConnectionSource = CurOperator.Sources.FindByName(IConnectionShort.TableDetails.TableName);
		If ConnectionSource = Undefined Then
			
			// If the table is not described in the request, you need to add its description
			If ModifiedRequest.AvailableTables.Find(IConnectionShort.TableDetails.TableName) = Undefined Then
				
				If Not ValueIsFilled(IConnectionShort.TableDetails.TableType) Then
					Raise NStr("vi = 'Chưa đặt kiểu bảng liên kết.';
								|ru = 'Не задан тип присоединяемой таблицы.';
								|en = 'Type of the table to attach is not specified.'; fa = 'Type of the table to attach is not specified.';
								|it = 'Non è indicato il tipo di tabella da unire.';
								|pl = 'Nie zadano typu załączanej tabeli.';
								|tr = 'Eklenecek tablonun türü belirtilmedi.'");
				EndIf;
				
				If IConnectionShort.TableDetails.TableType = Type("QuerySchemaNestedTable") Then
					
					If Not ValueIsFilled(IConnectionShort.TableDetails.QueryText) Then
						Raise NStr("vi = 'Chưa đặt nội dung truy vấn của bảng liên kết.';
									|ru = 'Не задан текст запроса присоединяемой таблицы.';
									|en = 'Query text of the table to attach is not specified.'; fa = 'Query text of the table to attach is not specified.';
									|it = 'Non è indicato il testo di richiesta della tabella da unire.';
									|pl = 'Nie zadano tekstu zapytania załączanej tabeli.';
									|tr = 'Eklenen tabloların sorgu metni belirtilmemiştir.'");
					EndIf;
					
					ConnectionSource =
						CurOperator.Sources.Add(
							IConnectionShort.TableDetails.TableType,
							IConnectionShort.TableDetails.TableAlias);
					
					ConnectionSource.Source.Query.SetQueryText(IConnectionShort.TableDetails.QueryText);
					
				ElsIf IConnectionShort.TableDetails.TableType = Type("QuerySchemaTempTableDescription") Then
					
					If Not ValueIsFilled(IConnectionShort.TableDetails.AvailableFields) Then
						Raise NStr("vi = 'Chưa đặt mô tả các trường của bảng liên kết.';
									|ru = 'Не задано описание полей присоединяемой таблицы.';
									|en = 'Field details of the table to attach are not specified.'; fa = 'Field details of the table to attach are not specified.';
									|it = 'Non è indicata la descrizione dei campi della tabella da unire.';
									|pl = 'Nie zadano opisu pól załączanej tabeli.';
									|tr = 'Eklenen tablonun alanlarının ayrıntıları belirtilmemiştir.'");
					EndIf;
					
					ConnectionSource =
						CurOperator.Sources.Add(
							IConnectionShort.TableDetails.TableType,
							IConnectionShort.TableDetails.TableName,
							IConnectionShort.TableDetails.TableAlias);
					
					For Each CurField In IConnectionShort.TableDetails.AvailableFields Do
						ConnectionSource.Source.AvailableFields.Add(CurField);
					EndDo;
					
				Else
					Raise NStr("vi = 'Đã chỉ ra sai tên bảng liên kết.';
								|ru = 'Указано неправильное имя присоединяемой таблицы.';
								|en = 'Incorrect name of the table to attach is specified.'; fa = 'Incorrect name of the table to attach is specified.';
								|it = 'È indicato un nome errato della tabella da unire.';
								|pl = 'Jest podana niepoprawna nazwa załączanej tabeli.';
								|tr = 'Eklenen tablonun adı yanlış belirtilmiş.'");
				EndIf;
				
			Else
				ConnectionSource =
					CurOperator.Sources.Add(
						IConnectionShort.TableDetails.TableName,
						IConnectionShort.TableDetails.TableAlias);
			EndIf;
			
			ConnectionSource.Joins.Clear();
			
		EndIf;
		
		If Source.Joins.Add(ConnectionSource, IConnectionShort.Condition) Then
			Join = Source.Joins.FindByAlias(IConnectionShort.TableDetails.TableAlias);
			If ValueIsFilled(IConnectionShort.JoinType) Then
				Join.JoinType = IConnectionShort.JoinType;
			EndIf;
		Else
			Raise NStr("vi = 'Không thể thêm kết nối.';
						|ru = 'Не удалось добавить соединение.';
						|en = 'Cannot add the connection.'; fa = 'Cannot add the connection.';
						|it = 'Non è stato possibile aggiungere la connessione.';
						|pl = 'Nie udało się dodać połączenia.';
						|tr = 'Bağlantı eklenemedi.'");
		EndIf;
		
	EndDo;
	
	NewRequestText = QuerySchema.GetQueryText();
	
	If TypeOf(Query) = Type("String") Then
		Query = NewRequestText;
	ElsIf TypeOf(Query) = Type("Query") Then 
		Query.Text = NewRequestText;
	EndIf;
	
	Return Query;
	
EndFunction

// Removes fields from the request.
//
// Parameters:
//  Query - String, Query - request text or request.
//  FieldAliases - String, Array - a string of field aliases separated by commas, or an array of field aliases.
//  IndexOfRequestInPackage - Number - the index of the query in the query package. If not specified, it is deleted in all requests of the package.
//
// Returns:
//  String, Query - the modified text of the request or request.
//
Function RemoveFieldsFromRequest(Val Query, FieldAliases, Val IndexOfRequestInPackage = Undefined) Export
	
	If TypeOf(Query) = Type("String") Then
		QueryText = Query;
	ElsIf TypeOf(Query) = Type("Query") Then 
		QueryText = Query.Text;
	Else
		Raise NStr("vi = 'Sai kiểu tham số 1';
					|ru = 'Некорректный тип параметра 1';
					|en = 'Incorrect type of parameter 1'; fa = 'Incorrect type of parameter 1';
					|it = 'Tipo del parametro 1 non valido';
					|pl = 'Niepoprawny typ parametru 1';
					|tr = 'Yanlış parametre türü 1'") ;
	EndIf;
	
	QuerySchema = New QuerySchema;
	
	QuerySchema.SetQueryText(QueryText);
	
	If TypeOf(FieldAliases) = Type("String") Then
		FieldsToDelete__ = StrSplit(FieldAliases, ",", False);
	Else
		FieldsToDelete__ = FieldAliases;
	EndIf;
	
	If IndexOfRequestInPackage = Undefined Then
		MutableQueries = QuerySchema.QueryBatch;
	Else
		MutableQueries = New Array;
		MutableQueries.Add(RequestRequestPackage(QuerySchema, IndexOfRequestInPackage));
	EndIf;
	
	For Each ModifiedRequest In MutableQueries Do
		
		If TypeOf(ModifiedRequest) = Type("QuerySchemaTableDropQuery") Then
			Continue;
		EndIf;
		
		Columns = ModifiedRequest.Columns;
		
		For Each CurField In FieldsToDelete__ Do
			
			Field = Columns.Find(CurField);
			If Not Field = Undefined Then
				Columns.Delete(Columns.IndexOf(Field));
			EndIf;
			
		EndDo;
		
	EndDo;
	
	NewRequestText = QuerySchema.GetQueryText();
	
	If TypeOf(Query) = Type("String") Then
		Query = NewRequestText;
	ElsIf TypeOf(Query) = Type("Query") Then 
		Query.Text = NewRequestText;
	EndIf;
	
	Return Query;
	
EndFunction

#Region Constructors

// Returns a description of the connection being added.
//
// Parameters:
//  TableDetails - See TableDetails
//  Condition - String - connection condition
//  JoinType - Undefined, QuerySchemaJoinType - connection type
//
// Returns:
//  Structure:
//  *TableDetails - See TableDetails
//  *Condition - String
//  *JoinType - QuerySchemaJoinType
//
Function IConnectionShort(TableDetails, Condition, JoinType = Undefined) Export
	
	LongDesc = New Structure;
	LongDesc.Insert("TableDetails", TableDetails);
	LongDesc.Insert("Condition", Condition);
	LongDesc.Insert("JoinType", JoinType);
	
	Return LongDesc;
	
EndFunction

// Description of the query Schema table
// 
// Parameters:
//  TableType - Type
//  TableName - String
//  TableAlias - String
//  AvailableFields - String, Array of String - available fields
//  QueryText - String
// 
// Returns:
//  Structure - Table Description:
//  *TableType - Type
//  *TableName - String
//  *TableAlias - String
//  *AvailableFields - Array of String
//  *QueryText - String
//
Function TableDetails(TableType, TableName, TableAlias, AvailableFields = Undefined, QueryText = Undefined) Export
	
	LongDesc = New Structure;
	LongDesc.Insert("TableType",       TableType);
	LongDesc.Insert("TableName",       TableName);
	LongDesc.Insert("TableAlias", TableAlias);
	LongDesc.Insert("QueryText",     QueryText);
	
	If TypeOf(AvailableFields) = Type("String") Then
		LongDesc.Insert(
			"AvailableFields",
			StringFunctionsClientServer.SplitStringIntoSubstringsArray(
				AvailableFields, ",", True, True));
	Else
		LongDesc.Insert("AvailableFields", AvailableFields);
	EndIf;
	
	Return LongDesc;
	
EndFunction

// Constructor of the request schema initialized with the request text
//
// Parameters:
//  QueryText - String 
// 
// Returns:
//  QuerySchema
//
Function Create(QueryText) Export
	QuerySchema = New QuerySchema;
	QuerySchema.SetQueryText(QueryText);
	Return QuerySchema;
EndFunction

// Finds the first query in the schema that selects the resulting data (that is, does not create or destroy temporary tables).
// It is assumed that in the future the request will be modified by the methods of this module.
//
// Parameters:
//  Query    - String - request text;
//              It is assumed that the text contains a selection query from a table that does not create a temporary table.
//            - QuerySchema - schema initialized with this request text.
// 
// Returns:
//  Structure - See NewRequestPoint, Undefined - description of the point in the query schema that selects data
//
Function FindResultQuery(Query) Export
	
	QuerySchema = QuerySchema(Query);
	
	For Each QueryDetails In QuerySchema.QueryBatch Do
		
		If TypeOf(QueryDetails) <> Type("QuerySchemaSelectQuery") Then
			Continue;
		EndIf;
		
		If Not IsBlankString(QueryDetails.PlacementTable) Then
			Continue;
		EndIf;
		
		Return NewRequestPoint(QuerySchema, QueryDetails);
		
	EndDo;
	
	Return Undefined;
	
EndFunction

// Sets the field expression of the query operator.
//
// Parameters:
//  RequestPoint - Structure - See NewRequestPoint, description of the point in the request schema.
//                 The point of the query schema must point to a query or query statement.
//                 The point pointing to the operator can be obtained by nititablecupop with an alias.
//                 If the dot does not point to a query operator, then the expression will be set in all query operators.
//  FieldName      - String - name of the request field.
//                 If the field is missing in the request, it will be added.
//  Expression    - String, QuerySchemaExpression - the field expression to be set.
//  ReplaceInstalled - Boolean - False allows you to set only those values
//                 that are not set in the query text (have the equivalent of NULL)
//
// Returns:
//  QuerySchemaColumn - the column in which the expression is set (found by field name or created)
//
Function SetExpression(RequestPoint, FieldName, Expression, ReplaceInstalled = True) Export
	
	If TypeOf(Expression) = Type("QuerySchemaExpression") Then
		QuerySchemaExpression = Expression;
	Else
		QuerySchemaExpression = New QuerySchemaExpression(Expression);
	EndIf;
	
	InstallationOperators = New Array;
	If RequestPoint.Property("Operator") Then
		InstallationOperators.Add(RequestPoint.Operator);
	Else
		InstallationOperators = RequestPoint.Query.Operators;
	EndIf;
	
	Column = RequestPoint.Query.Columns.Find(FieldName);
	StringExpression = String(QuerySchemaExpression);
	
	For Each Operator In InstallationOperators Do
		
		Operators = RequestPoint.Query.Operators; // QuerySchemaOperators
		OperatorIndex = Operators.IndexOf(Operator); 
		
		If Column = Undefined Then
			ColumnIndex = RequestPoint.Query.Columns.Count();
			SelectedFields = Operator.SelectedFields; // QuerySchemaFields
			SelectedFields.Add(StringExpression);
			Column = RequestPoint.Query.Columns[ColumnIndex];
			Column.Alias = FieldName;
		ElsIf Column.Fields[OperatorIndex] = Undefined Or ReplaceInstalled Then
			SetFieldExpression(RequestPoint.Query, Column, Operator, QuerySchemaExpression);
		EndIf;
		
	EndDo;
	
	Return Column;
	
EndFunction

// The constructor of the collection containing the query schema and its individual parts makes it easier to use the query schema.
// The collection is used as a return value and parameter of the module's API methods.
//
// Allows you to bypass the disadvantage of implementing a query scheme in the platform:
// having a link to a schema element, you cannot access the higher elements of the schema;
// Thus, to use the methods of working with the query schema, you need to have all the elements of the schema at hand.
//
// Parameters:
//  Schema    - QuerySchema
//  Query   - QuerySchemaSelectQuery, QuerySchemaTableDropQuery - the query where the Point is positioned
//  Operator - QuerySchemaSelectOperator - query operator that the Point is positioned on
//  Source - QuerySchemaSource - description of the request source where the Point is positioned
//  Table  - QuerySchemaTable, QuerySchemaNestedQuery, QuerySchemaTempTableDescription -
//             the source of the data selected by the request
// 
// Returns:
//  Structure - Structure - see procedure parameters.
//  Some (not passed) items may not be in the collection.
//  Thus, the Point can be positioned on the query as a whole, the query operator,
//  or the specific table from which it selects data.
//
Function NewRequestPoint(Schema, Query, Operator = Undefined, Source = Undefined, Table = Undefined) Export
	
	Context = New Structure;
	
	Context.Insert("Schema",  Schema);
	Context.Insert("Query", Query);
	If Operator <> Undefined Then
		Context.Insert("Operator", Operator);
	EndIf;
	If Source <> Undefined Then
		Context.Insert("Source", Source);
	EndIf;
	If Table <> Undefined Then
		Context.Insert("Table",  Table);
	EndIf;
	
	Return Context;
	
EndFunction

#EndRegion


// Finds a query that generates a temporary table with the specified name.
//
// Parameters:
//  Query    - String - request text;
//              It is assumed that the text contains a selection query that creates a temporary table.
//            - QuerySchema - schema initialized with this request text.
//  TableName - String - name of the table you are looking for
// 
// Returns:
//  Structure - See NewRequestPoint - description of the query schema point that points to the selection query that created the table.
//  Undefined - the query was not found or the table is destroyed during the query
//
Function FindQueryForCreatingTable(Query, TableName) Export
	
	QuerySchema = QuerySchema(Query);
	
	// We bypass from the end in order to correctly process the destruction of tables
	
	NumberOfRequests_ = QuerySchema.QueryBatch.Count();
	For NumberFromEnd = 1 To NumberOfRequests_ Do
		
		QueryIndex = NumberOfRequests_ - NumberFromEnd;
		QueryDetails = QuerySchema.QueryBatch[QueryIndex];
		
		If TypeOf(QueryDetails) = Type("QuerySchemaTableDropQuery") Then
			
			If QueryDetails.TableName = TableName Then
				// The table is destroyed
				Return Undefined;
			EndIf;
			
		ElsIf TypeOf(QueryDetails) = Type("QuerySchemaSelectQuery") Then
			
			If QueryDetails.PlacementTable = TableName Then
				Return NewRequestPoint(QuerySchema, QueryDetails);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return Undefined;
	
EndFunction

#EndRegion

#Region Private

Function QuerySchema(Query)
	
	If TypeOf(Query) = Type("String") Then
		Return Create(Query);
	Else
		Return Query;
	EndIf;
	
EndFunction

// Set the field expression.
// 
// Parameters:
//  Query - QuerySchemaSelectQuery
//  Column - QuerySchemaColumn
//  Operator - QuerySchemaSelectOperator - Operator
//  Expression - QuerySchemaExpression - Expression
Procedure SetFieldExpression(Query, Column, Operator, Val Expression)
	
	OperatorIndex = Query.Operators.IndexOf(Operator);
	
	If Column.Fields[OperatorIndex] = Undefined Then
		ColumnIndex   = Query.Columns.IndexOf(Column);
		Operator.SelectedFields.Add(String(Expression), ColumnIndex);
	Else
		FieldIndex = IndexOfFieldToSelect(Query, Column, Operator);
		If TypeOf(Expression) = Type("String") Then
			Expression = New QuerySchemaExpression(Expression);
		EndIf;
		Operator.SelectedFields.Set(FieldIndex, Expression);
	EndIf;
	
EndProcedure

Function IndexOfFieldToSelect(Query, Column, Operator)
	
	// The collection of selectable fields stores only completed fields,
	// so the index of the selected field may be smaller than the index of the column
	
	If TypeOf(Operator) = Type("Number") Then
		OperatorIndex = Operator;
	Else
		OperatorIndex = Query.Operators.IndexOf(Operator);
	EndIf;
	
	FieldIndex = -1;
	
	For IndexOfPreviousColumn = 0 To Query.Columns.IndexOf(Column) Do
		PreviousColumn = Query.Columns[IndexOfPreviousColumn];
		If PreviousColumn.Fields[OperatorIndex] = Undefined Then
			Continue;
		EndIf;
		FieldIndex = FieldIndex + 1;
	EndDo;
	
	Return FieldIndex;

EndFunction

#EndRegion

