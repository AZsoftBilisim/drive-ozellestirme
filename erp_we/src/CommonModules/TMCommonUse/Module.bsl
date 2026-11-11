
#Region Public

#Region MethodsForAutoFillingInDocumentDetails

// Deprecated. The general purpose function should be used.DescriptionThe number (Bit depth, Bit depth = 0, number sign = Indeterminate)
// is a utility function designed to get a description of the types of numbers, a given bit depth.
// 
// Parameters:
//  Digits - Number - number bit depth
//  FractionDigits - Number - Bit depth of the fractional part.
//  Nonnegative - Boolean - if True, then the numbers are only positive, if False, then any.
//
// Returns:
//  TypeDescription - for a number of the specified bit depth.
//
Function GetDescriptionOfNumberTypes(Digits, FractionDigits, Nonnegative = False) Export
	
	If Nonnegative Then
		Character = AllowedSign.Nonnegative;
	Else
		Character = AllowedSign.Any;
	EndIf;
	
	Return Common.TypeDescriptionNumber(Digits, FractionDigits, Character);

EndFunction // Get a description of the number type()

// A utility function is designed to obtain a description of date types
// 
// Parameters:
//  Var_DateFractions - DateFractions - System enumeration of partial Data.
// 
//  Returns:
//    TypeDescription - 
Function GetDescriptionOfDateTypes(Var_DateFractions) Export

	Return New TypeDescription("Date", , , New DateQualifiers(Var_DateFractions));

EndFunction // Get a description of the typesdates()

// Completes a table of values with rows in another table values
//
// Parameters:
//	Receiver - ValueTable - custom collection to add strings to
//	Source - ValueTable - an arbitrary collection from which the rows to be added are taken
//	FieldsMap - Map - used to fill in fields with different names, 
//										the key contains the name of the receiver field, the value contains the name of the source field.
//	DefaultValues - Structure - values that will be placed in all added rows,
//										the key contains the name of the receiver field.
//
Procedure AddRowsToTable(Receiver, Source, FieldsMap = Undefined, DefaultValues = Undefined) Export

	For Each SourceRow1 In Source Do
		NewRow = Receiver.Add();
		FillPropertyValues(NewRow, SourceRow1);
		If FieldsMap <> Undefined Then
			For Each KeyAndValue In FieldsMap Do
				NewRow[KeyAndValue.Key] = SourceRow1[KeyAndValue.Value];
			EndDo; 
		EndIf; 
		If DefaultValues <> Undefined Then
			FillPropertyValues(NewRow, DefaultValues);
		EndIf;
	EndDo;

EndProcedure

// Fills a column in the value table with consecutive numbers
//
// Parameters:
//	Table - ValueTable - Table of values whose rows should be numbered
//	ColumnNameLineNumbers - String - Name of the column in the value table where the row numbers will be specified
//
Procedure NumberValueTable(Table, ColumnNameLineNumbers) Export

	If Table.Columns.Find(ColumnNameLineNumbers) = Undefined Then
		Table.Columns.Add(ColumnNameLineNumbers, GetDescriptionOfNumberTypes(15, 0));
	EndIf;

	RowsCount = Table.Count() - 1;
	For LineNumber = 0 To RowsCount Do
		Table[LineNumber][ColumnNameLineNumbers] = LineNumber;
	EndDo;

EndProcedure

// Unloads a table of values from the data Formcollection and tabular Part
//
// Parameters:
// 		SourceTable1 - FormDataCollection, TabularSection - Upload source table
// 		Rows - Array -
//             - Structure - Array of rows to upload or selection structure
// 		Columns - String - Comma-separated column names for uploading
// 		ColumnsByValue - Structure of KeyAndValue - Column structure to add to the resulting table:
// 										* Key - String - Name of the new column
// 										* Value - String - The value for substitution in all rows of the new column.
// 		NewColumnNames - Structure of KeyAndValue - Structure with data on column renaming in the resulting table:
// 										* Key - String - The current name of the column
// 										* Value - String - New column name.
//
// Returns:
// 		ValueTable - The table is the result of unloading from the source table with added and renamed columns.
//
Function ExportValuesTable(SourceTable1, Rows = Undefined, Columns = "LineNumber",
			Val ColumnsByValue = Undefined, Val NewColumnNames = Undefined) Export
	
	// Defining default values
	If ColumnsByValue = Undefined Then
		ColumnsByValue = New Structure;
	EndIf;
	If NewColumnNames = Undefined Then
		NewColumnNames = New Structure;
	EndIf;
	
	// Define a list of unloaded columns
	StructureOfOtherColumnNames = New Structure;
	For Each NewName In NewColumnNames Do
		StructureOfOtherColumnNames.Insert(NewName.Value, NewName.Key);
	EndDo;
	ColumnsNames = "";
	ColumnName = "";
	ColumnStructure1 = New Structure(Columns);
	For Each Column In ColumnStructure1 Do
		If Not StructureOfOtherColumnNames.Property(Column.Key, ColumnName) Then
			ColumnName = Column.Key;
		EndIf;
		If Not ColumnsByValue.Property(ColumnName) Then
			ColumnsNames = ColumnsNames + ", " + ColumnName;
		EndIf;
	EndDo;
	
	// Unload from the source table
	If TypeOf(SourceTable1) = Type("ValueTable") Then
		ResultTable2 = SourceTable1.Copy(Rows, Mid(ColumnsNames, 3));
	Else
		ResultTable2 = SourceTable1.Unload(Rows, Mid(ColumnsNames, 3));
	EndIf;
	
	// Add new columns to the result table
	If ColumnsByValue <> Undefined Then
		For Each Column In ColumnsByValue Do
			TypesArray = New Array;
			TypesArray.Add(TypeOf(Column.Value));
			ResultTable2.Columns.Add(Column.Key, New TypeDescription(TypesArray));
			ResultTable2.FillValues(Column.Value, Column.Key);
		EndDo;
	EndIf;
	
	// Rename columns in the result table
	If NewColumnNames <> Undefined Then
		For Each Column In NewColumnNames Do
			ResultTable2.Columns[Column.Key].Name = Column.Value;
		EndDo;
	EndIf;
	
	Return ResultTable2;
	
EndFunction // Unload the table of values()

// Fills in the ID of rows in the value table
//
// Parameters:
//  Table - ValueTable - Table of values whose rows should be numbered
//  ColumnName - String	- Column of the value table where IDs will be filled in.
//  IDType - String - ID type ("Number", " unique Identifier")
//
Procedure AddRowIDToTable(Table, ColumnName = "Id", IDType = "Number") Export

	If IDType = "Number" Then

		If Table.Columns.Find(ColumnName) = Undefined Then
			Table.Columns.Add(ColumnName, New TypeDescription("Number", New NumberQualifiers(15, 0, AllowedSign.Nonnegative)));
		EndIf;
		
		For LineNumber = 0 To Table.Count() - 1 Do
			Table[LineNumber][ColumnName] = LineNumber + 1;
		EndDo;
		
	ElsIf IDType = "UUID" Then
		
		If Table.Columns.Find(ColumnName) = Undefined Then
			Table.Columns.Add(ColumnName, New TypeDescription("UUID"));
		EndIf;
		
		For LineNumber = 0 To Table.Count() - 1 Do
			Table[LineNumber][ColumnName] = New UUID;
		EndDo;
		
	ElsIf IDType = "String" Then
		
		If Table.Columns.Find(ColumnName) = Undefined Then
			Table.Columns.Add(ColumnName, Common.StringTypeDetails(36));
		EndIf;
		
		For LineNumber = 0 To Table.Count() - 1 Do
			Table[LineNumber][ColumnName] = String(New UUID);
		EndDo;
		
	EndIf;

EndProcedure

// The procedure writes to the log and tells the user if this is an error message 
// Parameters:
//   LogParameters - Structure - parameters for recording in the registration Log:
//       		* EventGroup_ - String - prefix for the log event name
//       		* Metadata - MetadataObject - metadata to write to the log
//       		* Data - Arbitrary - data to write to the log
//   LogLevel - EventLogLevel - Log level
//   EventName - String  - event name (the event is recorded in the event log in the Event Group format.Event Name)
//   Comment - String - comment about the event
//   ErrorInfo - ErrorInfo -
//	                    - String - Information about the error, which also needs to be documented in the log comments.
//
Procedure LogReportToUser(LogParameters, LogLevel, EventName, Val Comment = "", ErrorInfo = Undefined) Export
	
	If TypeOf(ErrorInfo) = Type("ErrorInfo") Then
		If Comment = "" Then
			MessageToUserText = ErrorProcessing.BriefErrorDescription(ErrorInfo);
			Comment = ErrorProcessing.DetailErrorDescription(ErrorInfo);
		Else
			MessageToUserText = Comment + Chars.LF + ErrorProcessing.BriefErrorDescription(ErrorInfo);
			Comment = Comment + Chars.LF + ErrorProcessing.DetailErrorDescription(ErrorInfo);
		EndIf;
	Else
		If TypeOf(ErrorInfo) = Type("String")
			And Not IsBlankString(ErrorInfo) Then
			If Comment = "" Then
				Comment = ErrorInfo;
			Else
				Comment = Comment + Chars.LF + ErrorInfo;
			EndIf;
		EndIf;
		MessageToUserText = Comment;
	EndIf;
	
	// Log 
	SetPrivilegedMode(True);
	WriteLogEvent(
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1';
				|ru = '%1';
				|en = '%1'; fa = '%1';
				|it = '%1';
				|pl = '%1';
				|tr = '%1'", Common.DefaultLanguageCode()),
			LogParameters.EventGroup_ + ?(EventName = "", "", "." + EventName)),
		LogLevel,
		LogParameters.Metadata,
		LogParameters.Data,
		Comment);
	SetPrivilegedMode(False);
	
	If LogLevel = EventLogLevel.Error
		Or LogLevel = EventLogLevel.Warning Then
		
		Common.MessageToUser(TrimAll(MessageToUserText), LogParameters.Data);
	EndIf;
	
EndProcedure

// Returns the data key for substitution in the message to the user
// The data key is needed for group processing of objects . if it is set,
// the object form will open when the user clicks on the message.
//
//	Parameters:
//		Object - DocumentObject - 
//             - CatalogObject - 
//             - ChartOfCharacteristicTypesObject - The object to get the data key for.
//	
//	Returns:
//		CatalogRef, DocumentRef, ChartOfCharacteristicTypesRef -
//
Function DataKeyForMessageToUser(Object) Export
	
	DataKey = Undefined;
	XMLTypeOf = XMLTypeOf(Object); 
	
	If XMLTypeOf <> Undefined Then
		ValueTypeAsString = XMLTypeOf.TypeName;
		If StrFind(ValueTypeAsString, "Object.") > 0 Then
			DataKey = Object.Ref;
		EndIf;
	EndIf;
	
	Return DataKey;
	
EndFunction

// Called from the subscription to fill in the object's Requisits
// Checks whether the form details associated with functional options are filled in
// Use Multiple Organizations, Use Multiple Warehouses, Use Multiple Currencies.
//
//	Parameters:
//		Object - DocumentObject -
//			   - CatalogObject - object to fill in
//		FillingData - Arbitrary - fill-in data 
//		StandardProcessing - Boolean - Flag for standard event handling
//	
//	Returned value
//		Link - a link to an information database object.
//
Procedure Filling(Object, FillingData, StandardProcessing) Export
	
	// Skip the processing to ensure that the form is received when passing the "AutoTest" parameter.
	If FillingData = "AutoTest_2" Then
		Return;
	EndIf;
	
	BaseVersion = GetFunctionalOption("BaseVersion");
	
	If Not GetFunctionalOption("UseMultipleCompanies")
		And TMCommonUseClientServer.HasObjectAttribute(Object, "Organization")
		And Not ValueIsFilled(Object.Organization) Then
		Object.Organization = SettingsValueCached.GetDefaultOrganization(Object.Organization);
		If Not ValueIsFilled(Object.Organization) Then
			
			Query = New Query(
			"SELECT ALLOWED TOP 2
			|	Companies.Ref
			|FROM
			|	Catalog.Companies AS Companies");
			
			If Query.Execute().Select().Count() = 2 Then
				Raise NStr("vi = 'Không thể điền trường ""Doanh nghiệp"". Trong cơ sở thông tin đã nhập nhiều doanh nghiệp.
				|Hãy bật sử dụng tùy chọn ""Danh mục và quản trị""-""Tập đoàn""-""Nhiều doanh nghiệp""!';
				|ru = 'Не удалось заполнить поле ""Организация"". В информационной базе введено несколько организаций.
				|Включите опцию ""НСИ и администрирование""-""Предприятие""-""Несколько организаций""!';
				|en = 'Cannot fill in the ""Company"" field. Several companies are entered in the infobase.
				|Select ""Master data and settings"" - ""Enterprise"" - ""Multiple companies"".'; fa = 'Cannot fill in the ""Company"" field. Several companies are entered in the infobase.
				|Select ""Master data and settings"" - ""Enterprise"" - ""Multiple companies"".';
				|it = 'Non è stato possibile compilare il campo ""Azienda"". Nel database sono inserite alcune azienda, 
				| attivare l''opzione ""dati principali e impostazioni"" - ""impresa"" - ""alcune aziende""!';
				|pl = 'Nie udało się wypełnić pola ""Firma"". W bazie informacyjnej wprowadzono kilka firm.
				|Włącz opcję ""Ustawienia""-""Przedsiębiorstwo""-""Kilka firm""!';
				|tr = '""İş yeri"" alanı doldurulamadı. Infobase''e birden fazla iş yeri girilmiştir.
				|""Master veri ve yönetim""-""İşletme""-""Birden fazla iş yerleri"" seçeneğini aç!'");
			ElsIf BaseVersion Then
				Raise NStr("vi = 'Không thể điền trường ""Doanh nghiệp"". Có thể là, trong cơ sở thông tin chưa nhập doanh nghiệp nào!
				|Để tùy chỉnh, cần chuyển đến phân hệ ""Doanh nghiệp của tôi""-""Thông tin về doanh nghiệp"".';
				|ru = 'Не удалось заполнить поле ""Организация"". Возможно, в информационной базе не введено ни одной организации!
				|Для настройки необходимо перейти в раздел ""Моя организация""-""Сведения об организации"".';
				|en = 'Cannot fill in the Company field. Perhaps, there are no companies entered in the infobase.
				|To configure it, go to ""My company"".'; fa = 'Cannot fill in the Company field. Perhaps, there are no companies entered in the infobase.
				|To configure it, go to ""My company"".';
				|it = 'Non è stato possibile compilare il campo ""Azienda"". Probabilmente, nell''infobase non è inserita alcuna azienda!
				|Per l''impostazione è necessario passare alla sezione ""La mia azienda""-""Informazioni sull''azienda"".';
				|pl = 'Nie udało się wypełnić pole ""Firma"". Możliwe, że do bazy informacyjnej nie wprowadzono żadnej firmy!
				|W celu ustawienia należy przejść do rozdziału ""Moja firma""-""Informacje o firmie"".';
				|tr = '""İş yeri"" alanı doldurulamadı. Muhtemelen infobase''e hiçbir iş yeri girilmedi!
				|Ayarlamak için ""İş yerim"" - ""İş yeri bilgileri"" bölümüne gidilmesi gerekir.'");
			Else
				Raise NStr("vi = 'Không thể điền trường ""Doanh nghiệp"". Có thể là trong cơ sở thông tin chưa nhập doanh nghiệp nào!
				|Để tùy chỉnh, cần chuyển đến phân hệ ""Danh mục và quản trị"" - ""Thông tin về công ty"" - ""Thông tin về doanh nghiệp"".';
				|ru = 'Не удалось заполнить поле ""Организация"". Возможно, в информационной базе не введено ни одной организации!
				|Для настройки необходимо перейти в раздел ""НСИ и администрирование""-""Сведения о предприятии""-""Сведения об организации"".';
				|en = 'Cannot fill in the Company field. Perhaps, there are no companies entered in the infobase.
				|To configure it, go to ""Master data and settings"" – ""Enterprise information"" – ""Company information"".'; fa = 'Cannot fill in the Company field. Perhaps, there are no companies entered in the infobase.
				|To configure it, go to ""Master data and settings"" – ""Enterprise information"" – ""Company information"".';
				|it = 'Non è stato possibile compilare il campo ""Azienda"". Probabilmente nel database non è inserita alcuna azienda!
				| Per le impostazioni passare alla sezione ""dati principali e impostazioni"" - ""impresa"" - ""alcune aziende"".';
				|pl = 'Nie udało się wypełnić pole ""Firma"". Możliwe, że do bazy informacyjnej nie wprowadzono żadnej firmy!
				|W celu ustawienia należy przejść do rozdziału ""Ustawienia""-""Informacje o przedsiębiorstwie""-""Informacje o firmie"".';
				|tr = '""İş yeri"" alanı doldurulamadı. Muhtemelen infobase''e hiçbir iş yeri girilmedi!
				|Ayarlar için ""Master veri ve yönetim""-""İşletme bilgileri""-""İş yeri bilgileri"" bölümüne geçmeniz gerekmektedir.'");
			EndIf;
			
		EndIf;
	EndIf;
	
	If Not GetFunctionalOption("UseSeveralWarehouses")
		And TMCommonUseClientServer.HasObjectAttribute(Object, "Warehouse")
		And Not ValueIsFilled(Object.Warehouse) Then
		Object.Warehouse = SettingsValueCached.GetDefaultWarehouse(Object.Warehouse);
		If Not ValueIsFilled(Object.Warehouse) Then
			
			Query = New Query(
			"SELECT ALLOWED TOP 2
			|	Warehouses.Ref
			|FROM
			|	Catalog.Warehouses AS Warehouses");
			
			If Query.Execute().Select().Count() = 2 Then
				If BaseVersion Then
					Raise NStr("vi = 'Không thể điền trường ""Kho bãi"". Trong cơ sở thông tin đã nhập nhiều kho bãi.
					|Hãy bật sử dụng tùy chọn ""Tùy chỉnh""-""Kho bãi""-""Nhiều kho""!';
					|ru = 'Не удалось заполнить поле ""Склад"". В информационной базе введено несколько складов.
					|Включите опцию ""Настройки""-""Склад""-""Несколько складов""!';
					|en = 'Cannot fill in the Warehouse field. Several warehouses are entered in the infobase.
					|In the ""Settings"" - ""Warehouse"" section, select the ""Multiple warehouses"" check box.'; fa = 'Cannot fill in the Warehouse field. Several warehouses are entered in the infobase.
					|In the ""Settings"" - ""Warehouse"" section, select the ""Multiple warehouses"" check box.';
					|it = 'Non è stato possibile compilare il campo ""Magazzino"". Nell''infobase sono inseriti diversi magazzini.
					|Attivare l''opzione ""Impostazioni""-""Magazzino""-""Diversi magazzini""!';
					|pl = 'Nie udało się wypełnić pola ""Magazyn"". W bazie informacyjnej wprowadzono kilka magazynów.
					|Włącz opcję ""Ustawienia""-""Magazyn""-""Kilka magazynów""!';
					|tr = '""Ambar"" alanı doldurulamadı. Infobase''e birden fazla ambar girildi.
					| ""Ayarlar""-""Ambar""-""Birden fazla ambar"" seçeneğini etkinleştir!'");
				Else
					Raise NStr("vi = 'Không thể điền trường ""Kho bãi"". Trong cơ sở thông tin đã nhập nhiều kho.
					|Hãy bật sử dụng tùy chọn ""Danh mục và quản trị""-""Kho bãi và giao nhận""-""Nhiều kho""!';
					|ru = 'Не удалось заполнить поле ""Склад"". В информационной базе введено несколько складов.
					|Включите опцию ""НСИ и администрирование""-""Склад и доставка""-""Несколько складов""!';
					|en = 'Cannot fill in the Warehouse field. Several warehouses are entered in the infobase.
					|In the ""Master data and settings"" - ""Warehouse and delivery"" section, select the ""Multiple warehouses"" check box.'; fa = 'Cannot fill in the Warehouse field. Several warehouses are entered in the infobase.
					|In the ""Master data and settings"" - ""Warehouse and delivery"" section, select the ""Multiple warehouses"" check box.';
					|it = 'Non è stato possibile compilare il campo ""magazzino"". Nel database sono inseriti alcuni magazzini, 
					| attivare l''opzione ""dati principali e impostazioni"" - ""impresa"" - ""alcune aziende""!';
					|pl = 'Nie udało się wypełnić pole ""Magazyn"". Do bazy informacyjnej wprowadzono kilka magazynów,
					|Włącz opcję ""Ustawienia""-""Magazyn i dostawa""-""Kilka magazynów""!';
					|tr = 'Ambar alanı doldurulamadı. Infobase''e birkaç ambar girildi.
					|""Master veri ve yönetim""-""Ambar ve teslimat""-""Birden fazla ambar"" seçeneğini etkinleştir!'");
				EndIf;
			Else
				If BaseVersion Then
					Raise NStr("vi = 'Không thể điền trường ""Kho bãi"". Có thể là, trong cơ sở thông tin chưa nhập kho bãi nào.
					|Để tùy chỉnh, cần chuyển đến phân hệ ""Tùy chỉnh""-""Kho bãi"".';
					|ru = 'Не удалось заполнить поле ""Склад"". Возможно, в информационной базе не введено ни одного склада.
					|Для настройки необходимо перейти в раздел ""Настройки""-""Склад"".';
					|en = 'Cannot fill in the ""Warehouse"" field. Perhaps, there are no warehouses entered into the infobase.
					| To configure it, go to ""Settings"" - ""Warehouse"".'; fa = 'Cannot fill in the ""Warehouse"" field. Perhaps, there are no warehouses entered into the infobase.
					| To configure it, go to ""Settings"" - ""Warehouse"".';
					|it = 'Non è stato possibile compilare il campo ""Magazzino"". Probabilmente, nell''infobase non è inserito alcun magazzino.
					|Per l''impostazione è necessario passare alla sezione ""Impostazioni""-""Magazzino"".';
					|pl = 'Nie udało się wypełnić pola ""Magazyn"". Możliwe, że w bazie informacyjnej nie wprowadzono żadnego magazynu.
					|Dla ustawienia należy przejść do rozdziału ""Ustawienia""-""Magazyn"".';
					|tr = 'Ambar alanı doldurulamadı. Infobase''e herhangi bir ambar girilmemiş olabilir.
					|Ayarlamak için ""Ayarlar"" - ""ambar "" bölümüne gidilmesi gerekir.'");
				Else
					Raise NStr("vi = 'Không thể điền trường ""Kho bãi"". Có thể là, trong cơ sở thông tin chưa nhập kho bãi nào.
					|Để tùy chỉnh, cần chuyển đến phân hệ ""Danh mục và quản trị""-""Thông tin về tập đoàn""-""Tùy chỉnh kế toán kho"".';
					|ru = 'Не удалось заполнить поле ""Склад"". Возможно, в информационной базе не введено ни одного склада.
					|Для настройки необходимо перейти в раздел ""НСИ и администрирование""-""Сведения о предприятии""-""Настройка складского учета"".';
					|en = 'Cannot fill in the ""Warehouse"" field. Probably no warehouses are registered in the infobase.
					|To fix this issue, go to ""Master data and settings"" – ""Enterprise information"" – ""Configure warehouse accounting"".'; fa = 'Cannot fill in the ""Warehouse"" field. Probably no warehouses are registered in the infobase.
					|To fix this issue, go to ""Master data and settings"" – ""Enterprise information"" – ""Configure warehouse accounting"".';
					|it = 'Non è stato possibile compilare i campo ""magazzino"". Probabilmente nel database non è inserito alcun magazzino
					| Per le impostazioni passare alla sezione ""dati principali e impostazioni"" - ""impresa"" - ""alcune aziende"".';
					|pl = 'Nie udało się wypełnić pola ""Magazyn"". Możliwe, że do bazy informacyjnej nie wprowadzono żadnego magazynu.
					|W celu ustawienia należy przejść do rozdziału ""Ustawienia""-""Dane o przedsiębiorstwie""-""Ustawienia ewidencji magazynowej"".';
					|tr = '""Ambar"" alanı doldurulamadı. Infobase''e herhangi bir ambar girilmemiş olabilir.
					|Ayarlamak için ""Master veri ve yönetim"" - ""İşletme bilgileri"" - ""Stok muhasebesi ayarları"" bölümüne gidilmesi gerekir.'");
				EndIf;
			EndIf;
			
		EndIf;
	EndIf;
	
	If Not GetFunctionalOption("UseMultipleCurrencies")
		And TMCommonUseClientServer.HasObjectAttribute(Object, "Currency")
		And Not ValueIsFilled(Object.Currency) Then
		Object.Currency = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting(Object.Currency);
		If Not ValueIsFilled(Object.Currency) Then
			If BaseVersion Then
				Raise NStr("vi = 'Không thể điền trường ""Tiền tệ"". Cần điền tiền tệ kế toán quản trị.
				|Để tùy chỉnh, cần chuyển đến phân hệ ""Doanh nghiệp của tôi""-""Tùy chỉnh""-""Tùy chỉnh chung""-""Tiền tệ"".';
				|ru = 'Не удалось заполнить поле ""Валюта"". Необходимо заполнить валюту управленческого учета.
				|Для настройки необходимо перейти в раздел ""Моя организация""-""Настройки""-""Общие настройки""-""Валюты"".';
				|en = 'Cannot fill in the ""Currency"" field. Fill in management accounting currency.
				|To configure it, go to ""My company"" - ""Settings"" - ""General settings"" - ""Currencies"".'; fa = 'Cannot fill in the ""Currency"" field. Fill in management accounting currency.
				|To configure it, go to ""My company"" - ""Settings"" - ""General settings"" - ""Currencies"".';
				|it = 'Non è stato possibile compilare il campo ""Valuta"". È necessario compilare la valuta di contabilità gestionale.
				|Per l''impostazione è necessario passare alla sezione ""La mia azienda""-""Impostazione""-""Impostazione generale""-""Valute"".';
				|pl = 'Nie udało się wypełnić pola ""Waluta"". Należy wypełnić walutę ewidencji zarządczej.
				|W celu ustawienia należy przejść do rozdziału ""Moja firma""-""Ustawienia""-""Ustawienia ogólne""-""Waluty"".';
				|tr = '""Para Birimi"" alanı doldurulamadı. Yönetim muhasebesinin para birimini doldurmak gerekir.
				|Ayarlamak için ""İş yerim""-""Ayarlar""-""Genel Ayarlar""-""Para Birimleri"" bölümüne gidilmesi gerekir.'");
			Else
				Raise NStr("vi = 'Không thể điền trường ""Tiền tệ"". Cần điền tiền tệ kế toán quản trị.
				|Để tùy chỉnh, cần chuyển đến phân hệ ""Danh mục và quản trị""-""Tập đoàn""-""Tiền tệ"".';
				|ru = 'Не удалось заполнить поле ""Валюта"". Необходимо заполнить валюту управленческого учета.
				|Для настройки необходимо перейти в раздел ""НСИ и администрирование""-""Предприятие""-""Валюты"".';
				|en = 'Cannot fill in the ""Currency"" field. Fill in management accounting currency.
				|To set it up, go to ""Master data and settings"" - ""Enterprise"" - ""Currencies"".'; fa = 'Cannot fill in the ""Currency"" field. Fill in management accounting currency.
				|To set it up, go to ""Master data and settings"" - ""Enterprise"" - ""Currencies"".';
				|it = 'Impossibile compilare il campo ""Valuta"". È necessario compilare la valuta della contabilità gestionale, 
				|Per l''impostazione è necessario passare alla sezione ""Informazioni di riferimento e amministrazione""-""Impresa""-""Valute"".';
				|pl = 'Nie udało się wypełnić pola ""Waluta"". Należy wypełnić walutę ewidencji zarządczej,
				|W celu ustawienia należy przejść do rozdziału ""Ustawienia""- -""Przedsiębiorstwo""-""Waluty"".';
				|tr = '""Para Birimi"" alanı doldurulamadı. Yönetim muhasebesinin para birimini doldurmak gerekir.
				|Ayarlamak için ""Master veri ve yönetim"" - ""İş yeri"" - ""Para Birimleri"" bölümüne gidilmesi gerekir.'");
			EndIf;
		EndIf;
	EndIf;
	
	If Not GetFunctionalOption("UseMultipleCurrencies")
		And TMCommonUseClientServer.HasObjectAttribute(Object, "ARAPCurrency")
		And Not ValueIsFilled(Object.ARAPCurrency) Then
		Object.ARAPCurrency = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting(Object.ARAPCurrency);
		If Not ValueIsFilled(Object.ARAPCurrency) Then
			If BaseVersion Then
				Raise NStr("vi = 'Không thể điền trường ""Tiền tệ hạch toán công nợ"". Cần điền tiền tệ kế toán quản trị.
				|Để tùy chỉnh, cần chuyển đến phân hệ ""Doanh nghiệp của tôi""-""Tùy chỉnh""-""Tùy chỉnh chung""-""Tiền tệ"".';
				|ru = 'Не удалось заполнить поле ""Валюта взаиморасчетов"". Необходимо заполнить валюту управленческого учета.
				|Для настройки необходимо перейти в раздел ""Моя организация""-""Настройки""-""Общие настройки""-""Валюты"".';
				|en = 'Cannot fill in the ""AR/AP currency"" field. Fill in management accounting currency.
				|To configure it, go to ""My company"" - ""Settings"" - ""General settings"" - ""Currencies"".'; fa = 'Cannot fill in the ""AR/AP currency"" field. Fill in management accounting currency.
				|To configure it, go to ""My company"" - ""Settings"" - ""General settings"" - ""Currencies"".';
				|it = 'Non è stato possibile compilare il campo ""Valuta dei conti reciproci"". È necessario compilare la valuta di contabilità gestionale.
				|Per l''impostazione è necessario passare alla sezione ""La mia azienda""-""Impostazioni""-""Impostazioni generali""-""Valute"".';
				|pl = 'Nie udało się wypełnić pola ""Waluta rozliczeń wzajemnych"". Należy wypełnić walutę ewidencji zarządczej.
				|W celu ustawienia należy przejść do rozdziału ""Moja firma""-""Ustawienia""-""Ustawienia ogólne""-""Waluty"".';
				|tr = '""Ödeme para birimi"" alanı doldurulamadı. Yönetim muhasebesinin para birimini doldurmak gerekir.
				|Ayarlamak için ""İş yerim"" - ""Ayarlar"" - ""Genel ayarlar"" - ""Para birimleri"" bölümüne gidilmesi gerekir.'");
			Else
				Raise NStr("vi = 'Không thể điền trường ""Tiền tệ hạch toán công nợ"". Cần điền tiền tệ kế toán quản trị.
				|Để tùy chỉnh, cần chuyển đến phân hệ ""Danh mục và quản trị""-""Tập đoàn""-""Tiền tệ"".';
				|ru = 'Не удалось заполнить поле ""Валюта взаиморасчетов"". Необходимо заполнить валюту управленческого учета.
				|Для настройки необходимо перейти в раздел ""НСИ и администрирование""-""Предприятие""-""Валюты"".';
				|en = 'Cannot fill in the ""AR/AP currency"" field. Fill in management accounting currency.
				|To set it up, go to ""Master data and settings"" - ""Enterprise"" - ""Currencies"".'; fa = 'Cannot fill in the ""AR/AP currency"" field. Fill in management accounting currency.
				|To set it up, go to ""Master data and settings"" - ""Enterprise"" - ""Currencies"".';
				|it = 'Impossibile compilare il campo ""Valuta dei conti reciproci"". È necessario compilare la valuta della contabilità di gestione, 
				|Per l''impostazione è necessario passare alla sezione ""Informazioni di riferimento e amministrazione""-""Impresa""-""Valute"".';
				|pl = 'Nie udało się wypełnić pola ""Waluta rozliczeń wzajemnych"". Należy wypełnić walutę ewidencji zarządczej.
				|W celu ustawienia należy przejść do rozdziału ""Ustawienia""- -""Przedsiębiorstwo""-""Waluty"".';
				|tr = '""Ödeme para birimi"" alanı doldurulamadı. Yönetim muhasebesinin para birimini doldurmak gerekir.
				|Ayarlamak için ""Master veri ve yönetim"" - ""İş yeri"" - ""Para Birimleri"" bölümüne gidilmesi gerekir.'");
			EndIf;
		EndIf;
	EndIf;
	
	If Not GetFunctionalOption("UseMultipleCashAccounts")
		And TMCommonUseClientServer.HasObjectAttribute(Object, "CashAccount")
		And Not ValueIsFilled(Object.CashAccount) Then
		
		If TMCommonUseClientServer.HasObjectAttribute(Object, "AdditionalProperties")
			And Object.AdditionalProperties.Property("NeedToFillInCashRegisterWhenUsingMultipleCashRegistersIsFalse") 
			And Not Object.AdditionalProperties.NeedToFillInCashRegisterWhenUsingMultipleCashRegistersIsFalse Then
			// You do not need to fill out the cash register if the "Use as many cash registers" option is not enabled.
		Else
			
			ParametersStructure = CashServer.DefaultParametersForFillingInCheckout();
			ParametersStructure.CashAccount 			= Object.CashAccount;
			Object.CashAccount = SettingsValueCached.GetOrganizationSDefaultSalesRegister(ParametersStructure);
			If Not ValueIsFilled(Object.CashAccount) Then
				
				Query = New Query(
				"SELECT ALLOWED TOP 2
				|	CashAccounts.Ref
				|FROM
				|	Catalog.CashAccounts AS CashAccounts
				|WHERE
				|	NOT CashAccounts.DeletionMark");
				
				If Query.Execute().Select().Count() = 2 Then
					If BaseVersion Then
						Raise NStr("vi = 'Không thể điền trường ""Quỹ tiền mặt"". Trong cơ sở thông tin đã nhập nhiều quỹ tiền mặt.
						|Hãy bật sử dụng tùy chọn ""Doanh nghiệp của tôi""-""Tùy chỉnh""-""Tùy chỉnh chung""-""Nhiều quỹ tiền mặt""!';
						|ru = 'Не удалось заполнить поле ""Касса"". В информационной базе введено несколько касс.
						|Включите опцию ""Моя организация""-""Настройки""-""Общие настройки""-""Несколько касс""!';
						|en = 'Cannot fill in the ""Cash account"" field. Several cash accounts are entered in the infobase,
						|Select """"My company"" - ""Settings"" - ""General settings"" - ""Several cash accounts"".'; fa = 'Cannot fill in the ""Cash account"" field. Several cash accounts are entered in the infobase,
						|Select """"My company"" - ""Settings"" - ""General settings"" - ""Several cash accounts"".';
						|it = 'Non è stato possibile compilare il campo ""Cassa"". Nell''infobase sono inserite diverse casse.
						|Attivare l''opzione ""La mia azienda""-""Impostazioni""-""Impostazioni generali""-""Alcune casse""!';
						|pl = 'Nie udało się wypełnić pola ""Kasa"". W bazie informacyjnej wprowadzono kilka kas.
						|Włącz opcję ""Moja firma""-""Ustawienia""-""Ustawienia ogólne""-""Kilka kas""!';
						|tr = '""Kasa"" alanı doldurulamadı. Infobase''e birkaç kasa girildi.
						|""İş yerim"" - ""Ayarlar"" - ""Genel ayarlar"" - ""Birkaç kasa"" seçeneğini etkinleştir!'");
					Else
						Raise NStr("vi = 'Không thể điền trường ""Quỹ tiền mặt"". Trong cơ sở thông tin đã nhập nhiều quỹ tiền mặt.
						|Hãy bật sử dụng tùy chọn ""Danh mục và quản trị""-""Ngân quỹ""-""Nhiều quỹ tiền mặt""!';
						|ru = 'Не удалось заполнить поле ""Касса"". В информационной базе введено несколько касс.
						|Включите опцию ""НСИ и администрирование""-""Казначейство""-""Несколько касс""!';
						|en = 'Cannot fill in the ""Cash account"" field. Several cash accounts are entered in the infobase,
						|Select ""Master data and settings"" - ""Treasury"" - ""Several cash accounts"".'; fa = 'Cannot fill in the ""Cash account"" field. Several cash accounts are entered in the infobase,
						|Select ""Master data and settings"" - ""Treasury"" - ""Several cash accounts"".';
						|it = 'Non è stato possibile compilare il campo ""Cassa"". Nel database sono inserite alcune casse, 
						| attivare l''opzione ""dati principali e impostazioni"" - ""tesoro"" - ""alcune casse""!';
						|pl = 'Nie udało się wypełnić pola ""Каsa"". Do bazy informacyjnej wprowadzono kilka kas,
						|Włącz opcję ""Ustawienia""-""Środki pieniężne""-""Kilka kas""!';
						|tr = '""Kasa"" alanı doldurulamadı. Infobase''e birkaç kasa girildi.
						|""Master veri ve yönetim"" - ""Hazine"" - ""Birkaç kasa"" seçeneğini etkinleştir!'");
					EndIf;
				Else
					If BaseVersion Then
						Raise NStr("vi = 'Không thể điền trường ""Quỹ tiền mặt"". Có thể là, trong cơ sở thông tin chưa điền quỹ tiền mặt nào!
						|Để tùy chỉnh, cần chuyển đến phân hệ ""Doanh nghiệp của tôi""-""Tùy chỉnh""-""Tùy chỉnh chung""-""Tùy chỉnh quỹ tiền mặt"".';
						|ru = 'Не удалось заполнить поле ""Касса"". Возможно, в информационной базе не введено ни одной кассы!
						|Для настройки необходимо перейти в раздел ""Моя организация""-""Настройки""-""Общие настройки""-""Настройка кассы"".';
						|en = 'Cannot fill in the Cash account field. Perhaps, there are no companies entered in the infobase.
						|To configure it, go to ""My company"" - ""Settings"" - ""General settings"" - ""Cash account settings"".'; fa = 'Cannot fill in the Cash account field. Perhaps, there are no companies entered in the infobase.
						|To configure it, go to ""My company"" - ""Settings"" - ""General settings"" - ""Cash account settings"".';
						|it = 'Non è stato possibile compilare il campo ""Cassa"". Probabilmente, nell''infobase non è inserita alcuna cassa!
						|Per l''impostazione è necessario passare alla sezione ""La mia azienda""-""Impostazioni""-""Impostazioni generali""-""Impostazione di cassa"".';
						|pl = 'Nie udało się wypełnić pola ""Kasa"". Możliwe, że do bazy informacyjnej nie wprowadzono żadnej kasy!
						|W celu ustawienia należy przejść do rozdziału ""Moja firma""-""Ustawienia ogólne""-""Ustawienia kasy"".';
						|tr = '""Kasa"" alanı doldurulamadı. Infobase''e tek bir kasa girilmemiş olabilir!
						|Ayarlamak için ""İş yerim"" - ""Ayarlar"" - ""Genel ayarlar"" - ""Kasa ayarları"" bölümüne gidilmesi gerekir.'");
					Else
						Raise NStr("vi = 'Không thể điền trường ""Quỹ tiền mặt"". Có thể là trong cơ sở thông tin chưa nhập quỹ tiền mặt nào!
						|Để tùy chỉnh, cần chuyển đến phân hệ ""Danh mục và quản trị"" - ""Thông tin về công ty"" - ""Tùy chỉnh quỹ tiền mặt"".';
						|ru = 'Не удалось заполнить поле ""Касса"". Возможно, в информационной базе не введено ни одной кассы!
						|Для настройки необходимо перейти в раздел ""НСИ и администрирование""-""Сведения о предприятии""-""Настройка кассы"".';
						|en = 'Cannot fill in the ""Cash account"" field. Probably no cash accounts are registered in the infobase.
						|To fix this issue, go to ""Master data and settings"" – ""Enterprise information"" – ""Cash account settings"".'; fa = 'Cannot fill in the ""Cash account"" field. Probably no cash accounts are registered in the infobase.
						|To fix this issue, go to ""Master data and settings"" – ""Enterprise information"" – ""Cash account settings"".';
						|it = 'Non è stato possibile compilare i campo ""cassa"". Probabilmente nel database non è inserito alcuna cassa
						| Per le impostazioni passare alla sezione ""dati principali e impostazioni"" - ""informazioni sull''impresa"" - ""Impostazioni di cassa"".';
						|pl = 'Nie udało się wypełnić pole ""Касса"". Możliwe, że do bazy informacyjnej nie wprowadzono żadnej kasy!
						|W celu ustawienia należy przejść do rozdziału ""НСИ и администрирование""-""Сведения о предприятии""-""Настройка кассы"".';
						|tr = '""Kasa"" alanı doldurulamadı. Infobase''e tek bir kasa girilmemiş olabilir!
						|Ayarlamak için ""Master veri ve yönetim"" - ""İşletme bilgileri"" - ""Kasa ayarları"" bölümüne gidilmesi gerekir.'");
					EndIf;
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If Not GetFunctionalOption("UseMultipleBankAccounts")
		And TMCommonUseClientServer.HasObjectAttribute(Object, "BankAccount")
		And Not ValueIsFilled(Object.BankAccount) Then
		
		If TMCommonUseClientServer.HasObjectAttribute(Object, "AdditionalProperties")
			And Object.AdditionalProperties.Property("NeedToFillOutAccountWhenFOUseMultipleAccountsIsFalse") 
			And Not Object.AdditionalProperties.NeedToFillOutAccountWhenFOUseMultipleAccountsIsFalse Then
			// It is not required to fill out a current account when the option "Use multiple accounts" is not enabled.
		Else
			
			Object.BankAccount = CashServer.GetOrganizationSDefaultBankAccount( ,
				Object.BankAccount);
			
			If Not ValueIsFilled(Object.BankAccount) Then
				
				Query = New Query(
				"SELECT ALLOWED TOP 2
				|	CompaniesBankAccounts.Ref
				|FROM
				|	Catalog.CompaniesBankAccounts AS CompaniesBankAccounts");
				
				If Query.Execute().Select().Count() = 2 Then
					If BaseVersion Then
						Raise NStr("vi = 'Không thể điền trường ""Tài khoản ngân hàng"". Trong cơ sở thông tin đã nhập nhiều tài khoản ngân hàng của doanh nghiệp.
						|Hãy bật sử dụng tùy chọn ""Doanh nghiệp của tôi""-""Tùy chỉnh""-""Tùy chỉnh chung""-""Nhiều tài khoản ngân hàng""!';
						|ru = 'Не удалось заполнить поле ""Банковский счет"". В информационной базе введено несколько банковских счетов организаций.
						|Включите опцию ""Моя организация""-""Настройки""-""Общие настройки""-""Несколько банковских счетов""!';
						|en = 'Cannot fill in the ""Bank account"" field. Several bank accounts are entered in the Infobase.
						|Enable option  ""My company"" - ""Settings"" - ""General settings"" - ""Several bank accounts"".'; fa = 'Cannot fill in the ""Bank account"" field. Several bank accounts are entered in the Infobase.
						|Enable option  ""My company"" - ""Settings"" - ""General settings"" - ""Several bank accounts"".';
						|it = 'Non è stato possibile compilare il campo ""Conto corrente"". Nell''infobase sono inseriti diversi conti corrente dell''azienda.
						|Attivare l''opzione ""La mia azienda""-""Impostazioni""-""Impostazioni generali""-""Alcuni conti corrente""!';
						|pl = 'Nie udało się wypełnić pola ""Rachunek bankowy"". W bazie informacyjnej wprowadzono kilka rachunków bankowych firm.
						|Włącz opcję ""Moja firma""-""Ustawienia""-""Ustawienia ogólne""-""Kilka rachunków bankowych""!';
						|tr = '""Banka hesabı"" alanı doldurulamadı. Infobase''e iş yerlerinin çeşitli banka hesapları girildi.
						|""İş yerim"" - ""Ayarlar"" - ""Genel ayarlar"" - ""Birden fazla banka hesabı"" seçeneğini etkinleştir!'");
					Else
						Raise NStr("vi = 'Không thể điền trường ""Tài khoản ngân hàng"". Trong cơ sở thông tin đã nhập nhiều tài khoản ngân hàng của doanh nghiệp.
						|Hãy bật sử dụng tùy chọn ""Danh mục và quản trị""-""Ngân quỹ""-""Nhiều tài khoản ngân hàng""!';
						|ru = 'Не удалось заполнить поле ""Банковский счет"". В информационной базе введено несколько банковских счетов организаций.
						|Включите опцию ""НСИ и администрирование""-""Казначейство""-""Несколько банковских счетов""!';
						|en = 'Cannot fill in the ""Bank account"" field. Several bank accounts are entered in the Infobase.
						|Enable option ""Master data and settings"" - ""Treasury"" - ""Several bank accounts"".'; fa = 'Cannot fill in the ""Bank account"" field. Several bank accounts are entered in the Infobase.
						|Enable option ""Master data and settings"" - ""Treasury"" - ""Several bank accounts"".';
						|it = 'Non è stato possibile compilare il campo ""Conto bancario"". Nel database informatico sono presenti più conti bancari delle società,
						|Abilitare l''opzione ""dati principali e impostazioni"" - ""Tesoro"" - "" più conti bancari""!';
						|pl = 'Nie udało się wypełnić pole ""Банковский счет"". Do bazy informacyjnej wprowadzono kilka rachunków bankowych firm.
						|Włącz opcję  ""НСИ и администрирование""-""Казначейство""-""Несколько банковских счетов""!';
						|tr = '""Banka hesabı"" alanı doldurulamadı. Infobase''e  iş yerlerinin çeşitli banka hesapları girildi.
						|""Master veri ve yönetim"" - ""Hazine"" - ""Birkaç banka hesabı"" seçeneğini etkinleştir!'");
					EndIf;
				Else
					If BaseVersion Then
						Raise NStr("vi = 'Không thể điền trường ""Tài khoản ngân hàng"". Có thể là, trong cơ sở thông tin chưa nhập tài khoản ngân hàng nào của doanh nghiệp!
						|Để tùy chỉnh, cần chuyển đến phân hệ ""Doanh nghiệp của tôi""-""Tùy chỉnh""-""Tùy chỉnh chung""-""Tùy chỉnh tài khoản ngân hàng"".';
						|ru = 'Не удалось заполнить поле ""Банковский счет"". Возможно, в информационной базе не введено ни одного банковского счета организации!
						|Для настройки необходимо перейти в раздел ""Моя организация""-""Настройки""-""Общие настройки""-""Настройка банковского счета"".';
						|en = 'Cannot fill in the ""Bank account"" field. Probably no company bank accounts are registered in the infobase. 
						|To configure it, go to ""My company"" - ""Settings"" - ""General settings"" - ""Set up bank account"".'; fa = 'Cannot fill in the ""Bank account"" field. Probably no company bank accounts are registered in the infobase. 
						|To configure it, go to ""My company"" - ""Settings"" - ""General settings"" - ""Set up bank account"".';
						|it = 'Non è stato possibile compilare il campo ""Conto corrente"". Probabilmente, nell''infobase non è inserito alcun conto corrente dell''azienda!
						|Per l''impostazione è necessario passare alla sezione ""La mia azienda""-""Impostazioni""-""Impostazioni generali""-""Impostazione di conto corrente"".';
						|pl = 'Nie udało się wypełnić pola ""Rachunek bankowy"". Możliwe, że w bazie informacyjnej nie wprowadzono żadnego rachunku bankowego firmy!
						|W celu ustawienia należy przejść do rozdziału ""Moja firma""-""Ustawienia""-""Ustawienia ogólne""-""Ustawienia rachunku bankowego"".';
						|tr = '""Banka hesabı"" alanı doldurulamadı. Infobase''e iş yerine ait bir banka hesabı girilmemiş olabilir!
						|Ayarlamak için ""İş yerim"" - ""Ayarlar"" - ""Genel ayarlar"" - ""Banka hesabı ayarları"" bölümüne gidilmesi gerekir.'");
					Else
						Raise NStr("vi = 'Không thể điền trường ""Tài khoản ngân hàng"". Có thể, là trong cơ sở thông tin chưa nhập tài khoản ngân hàng nào của doanh nghiệp!
						|Để tùy chỉnh, cần chuyển đến phân hệ ""Danh mục và quản trị"" - ""Thông tin về công ty"" - ""Tùy chỉnh tài khoản ngân hàng"".';
						|ru = 'Не удалось заполнить поле ""Банковский счет"". Возможно, в информационной базе не введено ни одного банковского счета организации!
						|Для настройки необходимо перейти в раздел ""НСИ и администрирование""-""Сведения о предприятии""-""Настройка банковского счета"".';
						|en = 'Cannot fill in the ""Bank account"" field. Probably no company bank accounts are registered in the infobase. 
						|To fix this issue, go to ""Master data and settings"" – ""Enterprise information"" – ""Set up bank account"".'; fa = 'Cannot fill in the ""Bank account"" field. Probably no company bank accounts are registered in the infobase. 
						|To fix this issue, go to ""Master data and settings"" – ""Enterprise information"" – ""Set up bank account"".';
						|it = 'Non è stato possibile compilare i campo ""conto bancario"". Probabilmente nel database non è inserito alcun conto bancario
						| Per le impostazioni passare alla sezione ""dati principali e impostazioni"" - ""informazioni sull''impresa"" - ""impostazione del conto bancario"".';
						|pl = 'Nie udało się wypełnić pole ""Банковский счет"". Możliwe, że do bazy informacyjnej nie wprowadzono żadnego rachunku bankowego firmy!
						|W celu ustawienia należy przejść do rozdziału """"НСИ и администрирование""-""Сведения о предприятии""-""Настройка банковского счета"".';
						|tr = '""Banka hesabı"" alanı doldurulamadı. Infobase''e iş yerine ait bir banka hesabı girilmemiş olabilir!
						|Ayarlamak için ""Master veri ve yönetim"" - ""İşletme bilgileri"" - ""Banka hesabı ayarları"" bölümüne gidilmesi gerekir.'");
					EndIf;
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Fills the unique identifier of the payment
//
// Parameters:
// 	Object - DocumentObject - Document for filling in the unique payment ID
//
// Returns:
// 	String -
Function GetUniquePaymentID(Object) Export
	
	Prefix = GetPrefixForUIP(Object.Ref);
	Date = Format(Object.Date, "DF=yyMM");
	Number = StrReplace(Object.Number, "-", "");
	Code = String(Prefix) + String(Date) + String(Number);
	WIN = GetUniquePaymentIDWithCheckDigit(Code);
	
	Return WIN;
	
EndFunction

// The function returns changes to the document relative to the one recorded in the database
// 
// Parameters:
// 	Object - DocumentObject - The document whose modification needs to be analyzed.
// 	ExceptionAttributes - Structure - The structure of the names of Attributes (including the Attributes of the table parts), the change of which does not need to be checked.
// 	TabularPartsOfException - Structure - Structure of names of table parts that do not need to be checked for changes.
// 	CheckConducted - Boolean - True if you want to check if the change in the attribute has been carried out.
//
// Returns:
// 	Structure - Contains changes to the object:
// 				* Attributes - ValueTable - Table Of Changed Details:
//	                                              * Name - String - 
//	                                              * NewValue - Arbitrary -
//											      * PreviousValue2 - Arbitrary - 
// 				* TabularSections - Structure - Changed table parts
Function DocumentChanges(Object, ExceptionAttributes = Undefined, TabularPartsOfException = Undefined, CheckConducted = False) Export
	
	Result = New Structure;
	
	If ExceptionAttributes = Undefined Then
		ExceptionAttributes = New Structure;
	EndIf;
	
	If TabularPartsOfException = Undefined Then
		TabularPartsOfException = New Structure;
	EndIf;
	
	MetadataOfDocument = Object.Metadata(); 
	
	FullName = MetadataOfDocument.FullName();
	
	stringOfUnlimitedLength_ = New TypeDescription("String", , , , New StringQualifiers(0));
	
	DocumentAttributes = New Structure;
	DocumentAttributes.Insert("Date");
	If CheckConducted Then
		DocumentAttributes.Insert("Posted");
	EndIf;
	
	For Each Attribute In MetadataOfDocument.Attributes Do
		If StrFind(Attribute.Name, "Delete") = 1 Then
			Continue;
		EndIf;
		If Attribute.Type = stringOfUnlimitedLength_ Then
			Continue;
		EndIf;
		If ExceptionAttributes.Property(Attribute.Name) Then
			Continue;
		EndIf;
		DocumentAttributes.Insert(Attribute.Name);
	EndDo;
	
	TabularPartsOfDocument = New Structure;
	For Each TabularSection In MetadataOfDocument.TabularSections Do
		If StrFind(TabularSection.Name, "Delete") = 1 Then
			Continue;
		EndIf;
		If TabularPartsOfException.Property(TabularSection.Name) Then
			Continue;
		EndIf;
		TabularSectionAttributes = New Structure;
		For Each Attribute In TabularSection.Attributes Do
			If StrFind(Attribute.Name, "Delete") = 1
				Or Attribute.Type = stringOfUnlimitedLength_
				Or ExceptionAttributes.Property(Attribute.Name) Then
				Continue;
			EndIf;
			TabularSectionAttributes.Insert(Attribute.Name);
		EndDo;
		TabularPartsOfDocument.Insert(TabularSection.Name, TabularSectionAttributes);
	EndDo;
	
	If CheckConducted Then
		QueryText= "SELECT
			|	Table.Ref AS Ref";
	Else
		QueryText= "SELECT
			|	Table.Posted AS Posted";
	EndIf;
		
	TemplateProps = ",
		|	Table.%1 AS %1";
		
	For Each Attribute In DocumentAttributes Do
		QueryText = QueryText + StrTemplate(TemplateProps, Attribute.Key); 
	EndDo;
	
	PlaceTemplate = "
	|FROM
	|	%1 AS Table
	|WHERE
	|	Table.Ref = &Ref
	|";
	QueryText = QueryText + StrTemplate(PlaceTemplate, FullName);
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Ref", Object.Ref); 
	
	Selection = Query.Execute().Select();
	Selection.Next(); 
	
	TableOfChangedDetails = New ValueTable;
	TableOfChangedDetails.Columns.Add("Name");
	TableOfChangedDetails.Columns.Add("NewValue");
	TableOfChangedDetails.Columns.Add("PreviousValue2");
	For Each Attribute In DocumentAttributes Do
		
		If Selection[Attribute.Key] <> Object[Attribute.Key]
			Or CheckConducted
				And Attribute.Key = "Posted"
				And (Object.AdditionalProperties.DocumentsPosting.DocumentProperties.WriteMode = DocumentWriteMode.UndoPosting
						And Selection[Attribute.Key] = True
					Or	Object.AdditionalProperties.DocumentsPosting.DocumentProperties.WriteMode = DocumentWriteMode.Posting
						And Selection[Attribute.Key] = False) Then
							
			NewRow = TableOfChangedDetails.Add();
			NewRow.Name = Attribute.Key;
			NewRow.NewValue = Object[Attribute.Key];
			NewRow.PreviousValue2 = Selection[Attribute.Key];
		EndIf;
		
	EndDo;
	
	If TableOfChangedDetails.Count() > 0 Then
		Result.Insert("Attributes", TableOfChangedDetails);
	EndIf;
	
	For Each TabularSection In TabularPartsOfDocument Do
		
		QueryText = "SELECT
		|	Table.LineNumber AS LineNumber";
		TemplateProps = ",
		|	Table.%1 AS %1";
		For Each Attribute In TabularSection.Value Do
			QueryText = QueryText + StrTemplate(TemplateProps, Attribute.Key);
		EndDo;
		
		PlaceTemplate = "
		|INTO NewTable%1
		|FROM
		|	&%1 AS Table
		|;
		|
		|////////////////////////////
		|";
		QueryText = QueryText + StrTemplate(PlaceTemplate, TabularSection.Key);
		
		TextOfAssociationIsNew =
		"SELECT
		|	Table.LineNumber AS LineNumber";
		
		TextOfAssociationIsOld =
		"SELECT
		|	-Table.LineNumber AS LineNumber";
		
		TemplateProps = ",
		|	Table.%1 AS %1";
		For Each Attribute In TabularSection.Value Do
			TextOfAssociationIsNew  = TextOfAssociationIsNew + StrTemplate(TemplateProps, Attribute.Key);
			TextOfAssociationIsOld = TextOfAssociationIsOld + StrTemplate(TemplateProps, Attribute.Key);
		EndDo;
		
		TemplateFromNew = "
		|FROM
		|	NewTable%1 AS Table";
		TextOfAssociationIsNew = TextOfAssociationIsNew + StrTemplate(TemplateFromNew, TabularSection.Key);
		
		TemplateFromOld = "
		|FROM
		|	%1.%2 AS Table
		|WHERE
		|	Table.Ref = &Ref";
		TextOfAssociationIsOld = TextOfAssociationIsOld + StrTemplate(TemplateFromOld, FullName, TabularSection.Key);
		
		QueryText = QueryText + 
		"SELECT
		|	SUM(NestedQuery.LineNumber) AS LineNumber";
		TemplateProps = ",
		|	NestedQuery.%1 AS %1";
		For Each Attribute In TabularSection.Value Do
			QueryText  = QueryText + StrTemplate(TemplateProps, Attribute.Key);
		EndDo;
		QueryText = QueryText + "
		|FROM 
		|(" 
		+ Chars.LF + TextOfAssociationIsNew 
		+ Chars.LF + " UNION ALL "
		+ Chars.LF + TextOfAssociationIsOld + ") AS NestedQuery
		|
		|GROUP BY";
		
		GroupTemplate_ = "
		|	NestedQuery.%1,";
		For Each Attribute In TabularSection.Value Do
			QueryText  = QueryText + StrTemplate(GroupTemplate_, Attribute.Key);
		EndDo;
		QueryText = QueryText + "TRUE
		|HAVING 
		|	SUM(NestedQuery.LineNumber) <> 0";
		
		Query = New Query;
		Query.Text = QueryText;
		Query.SetParameter("Ref", Object.Ref);
		Query.SetParameter(TabularSection.Key, Object[TabularSection.Key]);
		
		QueryResult = Query.Execute();
		If Not QueryResult.IsEmpty() Then
			If Not Result.Property("TabularSections") Then
				Result.Insert("TabularSections", New Structure);
			EndIf;
			Result.TabularSections.Insert(TabularSection.Key, QueryResult.Unload());
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Clears the "Document ID" attribute and the "Record ID" and "Line ID" columns in the tabular parts of the document.
//
// Parameters:
// 	Document - DocumentObject - Document with the ID to clear
// 	NamesOfTS - String - The names of the PM in which you need to clear the IDs separated by commas
// 	FindTSByMetadata - Boolean - The necessity of finding the composition of treated PM metadata if the list is not passed as a parameter to Iments
//
Procedure ClearDocumentIDs(Document, NamesOfTS = "", FindTSByMetadata = False) Export
	
	MetadataOfDocument = Document.Metadata();
	
	If Not IsBlankString(NamesOfTS) Then
		ArrayTS = StrSplit(NamesOfTS, ",", False);
	ElsIf FindTSByMetadata Then
		ArrayTS = New Array();
		For Each TSMetadata In MetadataOfDocument.TabularSections Do
			If TSMetadata.Attributes.Find("RowID") <> Undefined
			 Or TSMetadata.Attributes.Find("FinRecordID") <> Undefined Then
				ArrayTS.Add(TSMetadata.Name);
			EndIf;
		EndDo;
	Else
		ArrayTS = New Array();
	EndIf;
	
	//document ID
	If MetadataOfDocument.Attributes.Find("DocumentID") <> Undefined Then
		Document.DocumentID = "";
	EndIf;
	
	//Ids of PM lines
	For Each TSName In ArrayTS Do
		TSMetadata = MetadataOfDocument.TabularSections[TSName];
		AttributeName = "FinRecordID";
		
		If TSMetadata.Attributes.Find(AttributeName) = Undefined Then
			AttributeName = "RowID";
		EndIf;

		TabularSection = Document[TSName];
		
		For Each TableRow In TabularSection Do
			TableRow[AttributeName] = "";
		EndDo;
	EndDo;
	
EndProcedure

// Fills in the "Document ID" attribute and the "Record ID" and "Line ID" columns in the tabular parts of the document with the values of the unique identifiers.
//
// Parameters:
// 	Document - DocumentObject - New document to write with the ID
// 	NamesOfTS - String - The names of the PM in which you need to fill in the IDs, separated by commas
// 	FindTSByMetadata - Boolean - The necessity of finding the composition of treated PM metadata if the list is not passed as a parameter to Iments
//
Procedure FillInDocumentIDs(Document, NamesOfTS = "", FindTSByMetadata = False) Export
	
	MetadataOfDocument = Document.Metadata();
	
	If Not IsBlankString(NamesOfTS) Then
		ArrayTS = StrSplit(NamesOfTS, ",", False);
	ElsIf FindTSByMetadata Then
		ArrayTS = New Array();
		For Each TSMetadata In MetadataOfDocument.TabularSections Do
			If TSMetadata.Attributes.Find("RowID") <> Undefined
			 Or TSMetadata.Attributes.Find("FinRecordID") <> Undefined Then
				ArrayTS.Add(TSMetadata.Name);
			EndIf;
		EndDo;
	Else
		ArrayTS = New Array();
	EndIf;
	
	Uniqueness = New Map;
	
	//document ID
	If MetadataOfDocument.Attributes.Find("DocumentID") <> Undefined Then
		If Not ValueIsFilled(Document.DocumentID) Then
			Document.DocumentID = String(New UUID);
		EndIf;
		Uniqueness.Insert(Document.DocumentID, Document.DocumentID);
	EndIf;
	
	//Ids of PM lines
	For Each TSName In ArrayTS Do
		TSMetadata = MetadataOfDocument.TabularSections[TSName];
		AttributeName = "FinRecordID";
		
		If TSMetadata.Attributes.Find(AttributeName) = Undefined Then
			AttributeName = "RowID";
		EndIf;

		TabularSection = Document[TSName];
		
		For Each TableRow In TabularSection Do
			If Not ValueIsFilled(TableRow[AttributeName])
				Or Uniqueness[TableRow[AttributeName]] <> Undefined Then
				// The ID in the row is not filled in OR the ID has been encountered before
				TableRow[AttributeName] = String(New UUID);
			EndIf;
			Uniqueness.Insert(TableRow[AttributeName], TableRow[AttributeName]);
		EndDo;
	EndDo;
	
EndProcedure

// Fills in the passed value table column with the passed name with unique identifiers.
// If a column with this name does not exist, it adds it to the table of values.
//
// Parameters:
// 	TableOfValues - ValueTable - table of values being processed
// 	ColumnName - String - name of the column to fill in
//
Procedure AddIdentifiersToValueTable(TableOfValues, ColumnName = "FinRecordID") Export
	
	TableColumns1 = TableOfValues.Columns;
	
	If TableColumns1.Find(ColumnName) = Undefined Then
		TableColumns1.Add(ColumnName, Common.StringTypeDetails(36));
	EndIf;
	
	For Each TableRow In TableOfValues Do
		TableRow[ColumnName] = String(New UUID);
	EndDo;
	
EndProcedure

// Adds a column with the passed name and unique identifiers to the specified temporary table
//
// Parameters:
// 	TableName - String - name of the temporary table
// 	TempTablesManager - TempTablesManager - contains a temporary table that can be modified
// 	ColumnName - String - The name of the column with the ID that you want to add
//
Procedure AddIDsToTemporaryTable(TableName, TempTablesManager, ColumnName = "RowID") Export
	
	FieldsOfOriginalTemporaryTable = New Array;
	FieldsOfNewTemporaryTable = New Array;
	
	TemporaryTableColumns = TempTablesManager.Tables[TableName].Columns; // QueryTempTableColumns - 
	For Each Column In TemporaryTableColumns Do
		If Column.Name <> ColumnName Then
			Field = StrTemplate("%1.%2 AS %2", TableName, Column.Name);
			FieldsOfOriginalTemporaryTable.Add(Field);
			FieldsOfNewTemporaryTable.Add(Field);
		EndIf;
	EndDo;
	
	If TemporaryTableColumns.Find("RecNo") = Undefined Then
		FieldsOfOriginalTemporaryTable.Add("RECORDAUTONUMBER() AS RecNo");	
	EndIf;
	
	FieldsOfNewTemporaryTable.Add(StrTemplate("IDsTable.Id AS %1", ColumnName));
	
	QueryText = "
	|SELECT
	|	&FieldsOfOriginalTemporaryTable
	|INTO TableName_Prepared
	|FROM
	|	TableName AS TableName
	|INDEX BY
	|	RecNo
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TableName
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableName_Prepared.RecNo AS RecNo
	|FROM
	|	TableName_Prepared AS TableName_Prepared
	|";
	
	Separator = ",
	|";
	
	QueryText = StrReplace(QueryText, "TableName", TableName);
	QueryText = StrReplace(QueryText, "&FieldsOfOriginalTemporaryTable", StrConcat(FieldsOfOriginalTemporaryTable, Separator));
			
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Results = Query.ExecuteBatch();
	
	IDsTable = Results[Results.UBound()].Unload();
	AddIdentifiersToValueTable(IDsTable, "Id");
	
	QueryText = "
	|SELECT
	|	IDsTable.RecNo AS RecNo,
	|	IDsTable.Id AS Id
	|INTO IDsTable
	|FROM
	|	&IDsTable AS IDsTable
	|INDEX BY
	|	RecNo
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&FieldsOfNewTemporaryTable
	|INTO TableName
	|FROM
	|	TableName_Prepared AS TableName
	|	LEFT JOIN
	|		IDsTable AS IDsTable
	|	ON
	|		TableName.RecNo = IDsTable.RecNo
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TableName_Prepared
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 
	|DROP IDsTable
	|";
	
	QueryText = StrReplace(QueryText, "TableName", TableName);
	QueryText = StrReplace(QueryText, "&FieldsOfNewTemporaryTable", StrConcat(FieldsOfNewTemporaryTable, Separator));
			
	Query.Text = QueryText;
	Query.SetParameter("IDsTable", IDsTable);
	Query.Execute();
	
EndProcedure

// Returns the number of records in the temporary table
// 
// Parameters:
// 	TempTablesManager - TempTablesManager - 
// 	TempTableName - String -
// 	
// Returns:
// 	Number - Number of records
//
Function TemporaryTableSize(TempTablesManager, TempTableName) Export

	Query = New Query;
	Query.TempTablesManager = TempTablesManager;

	Query.Text = 
	"SELECT
	|	COUNT(*) AS RowsCount
	|FROM
	|	&TableName AS T";
	Query.Text = StrReplace(Query.Text, "&TableName", TempTableName);

	Selection = Query.Execute().Select();
	Selection.Next();

	Return Selection.RowsCount;

EndFunction

#EndRegion

#Region ProceduresAndFunctionsForObtainingDataPresentation

// Returns a string representation of the document to display in messages.
//
// Parameters:
//	Ref - DocumentRef - link to the document
//	Number - String - document number
//	Date - Date - Document date
//
// Returns:
//	String - presentation of the document
Function GetDocumentPresentation(Ref, Number, Date) Export
	
	Return
		Ref.Metadata().Synonym
		+ ?(ValueIsFilled(Number), " " + Number, "")
		+ ?(ValueIsFilled(Date), " " + NStr("vi = 'ngày';
											|ru = 'от';
											|en = 'dated'; fa = 'مورخ';
											|it = 'del';
											|pl = 'dated';
											|tr = 'itibaren'") + " " + Format(Date,"DLF=D"), "");
	
EndFunction

// Forms a representation of the search result by line.
// 
// Parameters:
//  Description - String - name.
//  SearchString - String - search bar.
// 
// Returns:
//  FormattedString - Representation of the search result by line.
//
Function PresentationOfSearchResultsByString(Description, SearchString) Export

	PosStart = StrFind(Upper(Description), Upper(SearchString));
	If PosStart <> 0 Then
		
		TextLength = StrLen(SearchString);
		PresentationLength = StrLen(Description);
		
		RepresentationOfTheReference = 
			New FormattedString(
				?(PosStart <> 1, Left(Description, PosStart - 1), ""),
				New FormattedString(Mid(Description, PosStart, TextLength), New Font(,, True), StyleColors.TextColorReportTitleInTaxi),
				?(PresentationLength > (PosStart + TextLength - 1) , Mid(Description, PosStart + TextLength), ""));
				
									
	Else
		
		RepresentationOfTheReference = Description;
		
	EndIf; 

	Return RepresentationOfTheReference;
	
EndFunction

#EndRegion

#Region OtherProceduresAndFunctions_

// Returns the object's metadata by the full name of the metadata object. Business process route points are not processed.
//
// Parameters:
//  FullName - String - The full name of the metadata object, for example, " Reference.Organizations".
//
// Returns:
//  MetadataObject -
// 
Function ObjectMetadataByFullName(FullName) Export
	
	NameParts = StringFunctionsClientServer.SplitStringIntoSubstringsArray(FullName, ".");
	
	MOClass = NameParts[0];
	MetadataObjectName1   = NameParts[1];
	
	If      Upper(MOClass) = "EXCHANGEPLAN" Then
		Return Metadata.ExchangePlans[MetadataObjectName1];
		
	ElsIf Upper(MOClass) = "CATALOG" Then
		Return Metadata.Catalogs[MetadataObjectName1];
		
	ElsIf Upper(MOClass) = "DOCUMENT" Then
		Return Metadata.Documents[MetadataObjectName1];
		
	ElsIf Upper(MOClass) = "DOCUMENTJOURNAL" Then
		Return Metadata.DocumentJournals[MetadataObjectName1];
		
	ElsIf Upper(MOClass) = "ENUM" Then
		Return Metadata.Enums[MetadataObjectName1];
		
	ElsIf Upper(MOClass) = "REPORT" Then
		Return Metadata.Reports[MetadataObjectName1];
		
	ElsIf Upper(MOClass) = "DATAPROCESSOR" Then
		Return Metadata.DataProcessors[MetadataObjectName1];
		
	ElsIf Upper(MOClass) = "CHARTOFCHARACTERISTICTYPES" Then
		Return Metadata.ChartsOfCharacteristicTypes[MetadataObjectName1];
		
	ElsIf Upper(MOClass) = "CHARTOFACCOUNTS" Then
		Return Metadata.ChartsOfAccounts[MetadataObjectName1];
		
	ElsIf Upper(MOClass) = "CHARTOFCALCULATIONTYPES" Then
		Return Metadata.ChartsOfCalculationTypes[MetadataObjectName1];
		
	ElsIf Upper(MOClass) = "INFORMATIONREGISTER" Then
		Return Metadata.InformationRegisters[MetadataObjectName1];
		
	ElsIf Upper(MOClass) = "ACCUMULATIONREGISTER" Then
		Return Metadata.AccumulationRegisters[MetadataObjectName1];
		
	ElsIf Upper(MOClass) = "ACCOUNTINGREGISTER" Then
		Return Metadata.AccountingRegisters[MetadataObjectName1];
		
	ElsIf Upper(MOClass) = "CALCULATIONREGISTER" Then
		Return Metadata.CalculationRegisters[MetadataObjectName1];
		
	ElsIf Upper(MOClass) = "BUSINESSPROCESS" Then
		Return Metadata.BusinessProcesses[MetadataObjectName1];
		
	ElsIf Upper(MOClass) = "TASK" Then
		Return Metadata.Tasks[MetadataObjectName1];
		
	ElsIf Upper(MOClass) = "CONSTANT" Then
		Return Metadata.Constants[MetadataObjectName1];
		
	ElsIf Upper(MOClass) = "SEQUENCE" Then
		Return Metadata.Sequences[MetadataObjectName1];
		
	ElsIf Upper(MOClass) = "COMMONMODULE" Then
		Return Metadata.CommonModules[MetadataObjectName1];
		
	Else
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Kiểu không xác định của đối tượng metadata (%1)';
				|ru = 'Неизвестный тип объекта метаданных (%1)';
				|en = 'Unknown type of metadata object (%1)'; fa = 'Unknown type of metadata object (%1)';
				|it = 'Tipo di oggetto di metadati sconosciuto (%1)';
				|pl = 'Nieznany typ obiektu metadanych (%1)';
				|tr = 'Metaveri (%1) nesnesinin bilinmeyen türü'"), MOClass);
	EndIf;
	
EndFunction

// Checks the completeness of the verified details.
//
// Parameters:
// 		Object - DocumentObject, CatalogObject - the object being checked.
// 		ArrayOfVerifiedDetails - Array of String - Array of verified Bank details.
//
// Returns:
// 		Boolean - True if the value of at least one of the props is not filled in, otherwise False.
//
Function CheckObjectDetails(Object, ArrayOfVerifiedDetails) Export
	
	Var VerifiableTSDetails;
	Cancel = False;
	
	// Getting Object metadata
	ObjectMetadata = Object.Ref.Metadata();
	
	// Creating a structure of standard details
	StandardAttributes = New Structure;
	For Each Attribute In ObjectMetadata.StandardAttributes Do
		StandardAttributes.Insert(Attribute.Name, ?(ValueIsFilled(Attribute.Presentation()), Attribute.Presentation(), Attribute.Name));
	EndDo;
	
	// Creating a structure for storing the names of table parts and verifiable details in them.
	// 		Key - Name of the table part
	// 		Value - Array - Array of strings, details of this table part for verification.
	TabularSections = New Structure;
	
	// Creating templates for error messages about incomplete details and details of table parts.
	PropsErrorPattern = NStr("vi = 'Trường ""%AttributeName%"" chưa điền';
							|ru = 'Поле ""%AttributeName%"" не заполнено';
							|en = '""%AttributeName%"" is required'; fa = '""%AttributeName%"" is required';
							|it = 'Il campo ""%AttributeName%"" non è compilato';
							|pl = 'Nie wypełniono pola ""%AttributeName%""';
							|tr = '""%AttributeName%"" alanı doldurulmadı'");
	TSErrorPattern = NStr("vi = 'Không một dòng nào được nhập vào danh sách ""%AttributeName%""';
							|ru = 'Не введено ни одной строки в список ""%AttributeName%""';
							|en = 'No line is entered into the ""%AttributeName%"" list'; fa = 'No line is entered into the ""%AttributeName%"" list';
							|it = 'Non è inserita alcuna riga nell''elenco ""%AttributeName%""';
							|pl = 'Nie wprowadzono żadnego wiersza do listy ""%AttributeName%""';
							|tr = '""%AttributeName%"" listesine hiç bir satır girilmedi'");
	TSPropsErrorPattern = NStr("vi = 'Chưa điền cột ""%AttributeName%"" trong dòng %LineNumber% danh sách ""%TabularSectionName%""';
								|ru = 'Не заполнена колонка ""%AttributeName%"" в строке %LineNumber% списка ""%TabularSectionName%""';
								|en = 'Column ""%AttributeName%"" in line %LineNumber% of the ""%TabularSectionName%"" list is not filled in'; fa = 'Column ""%AttributeName%"" in line %LineNumber% of the ""%TabularSectionName%"" list is not filled in';
								|it = 'Colonna ""%AttributeName%"" nella riga %LineNumber% dell''elenco""%TabularSectionName%"" non compilata';
								|pl = 'Nie wypełniono kolumny ""%AttributeName%"" w wierszu %LineNumber% listy ""%TabularSectionName%""';
								|tr = '""%TabularSectionName%"" listesinin %LineNumber% satırındaki ""%AttributeName%"" sütunu doldurulmadı'");
	
	// Checking the details of the object and filling in the structure according to the details of the table parts.
	For Each Attribute In ArrayOfVerifiedDetails Do
		
		PointPosition = StrFind(Attribute,".");
		
		If PointPosition > 0 Then // If the details of the table part are specified
			
			StringLength       = StrLen(Attribute);
			TabularSectionName = Left(Attribute, PointPosition-1);
			AttributeName      = Right(Attribute, StringLength - PointPosition);
			
			// Saving the checked details of the tabular part to the structure
			If Not TabularSections.Property(TabularSectionName, VerifiableTSDetails) Then
				VerifiableTSDetails = New Array;
				TabularSections.Insert(TabularSectionName, VerifiableTSDetails);
			EndIf;
			VerifiableTSDetails.Add(AttributeName);
			
		Else // If the object's details are specified
			
			If Not ValueIsFilled(Object[Attribute]) Then
				
				If ObjectMetadata.Attributes.Find(Attribute) <> Undefined Then // If the name of the props is specified
					ErrorText = StrReplace(PropsErrorPattern, "%AttributeName%",
						ObjectMetadata.Attributes[Attribute].Synonym);
				ElsIf StandardAttributes.Property(Attribute) Then // If the name of the standard props is specified
					ErrorText = StrReplace(PropsErrorPattern, "%AttributeName%",
						StandardAttributes[Attribute]);
				Else // If the name of the table part is specified
					ErrorText = StrReplace(TSErrorPattern, "%AttributeName%",
						ObjectMetadata.TabularSections[Attribute].Synonym);
				EndIf;
				
				CommonClientServer.MessageToUser(
					ErrorText,
					Object,
					Attribute,
					,
					Cancel);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	// Checking the details in the tabular parts
	For Each TabularSection In TabularSections Do
		
		TabularSectionName = TabularSection.Key;
		ObjectTabularSection = Object[TabularSection.Key];
		AttributesArray = TabularSection.Value;
		TabularSectionMetadata = ObjectMetadata.TabularSections[TabularSectionName];
		
		// Cycle through all rows of the table part.
		For Each LineOfATabularSection In ObjectTabularSection Do
			
			// Cycle through all the checked details for the current tabular part.
			For Each AttributeName In AttributesArray Do
				
				If Not ValueIsFilled(LineOfATabularSection[AttributeName]) Then
					
					ErrorText = StrReplace(TSPropsErrorPattern, "%AttributeName%", TabularSectionMetadata.Attributes[AttributeName].Synonym);
					ErrorText = StrReplace(ErrorText, "%LineNumber%", Format(LineOfATabularSection.LineNumber, "NG=0"));
					ErrorText = StrReplace(ErrorText, "%TabularSectionName%", TabularSectionMetadata.Synonym);
					
					CommonClientServer.MessageToUser(
						ErrorText,
						Object,
						CommonClientServer.PathToTabularSection(TabularSectionName, LineOfATabularSection.LineNumber, AttributeName),
						,
						Cancel);
					
				EndIf;
				
			EndDo;
			
		EndDo;
		
	EndDo;
	
	ArrayOfVerifiedDetails.Clear();
	
	Return Cancel;
	
EndFunction // Check the completion of the object's requestions()

// Checks compliance of the document organization with the business transaction.
//
// Parameters:
// 	DocumentObject - DocumentObject - object being checked
//	Cancel - Boolean - Write failure flag
//
Procedure CheckCorrectnessOfIndicationOfBusinessOperation(DocumentObject, Cancel) Export
	
	If DocumentObject.Organization = Catalogs.Companies.ManagementCompany
	   And (DocumentObject.BusinessOperation = Enums.BusinessTransactions.SaleToCustomerLocalAccounting
	 Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorLocal) Then
	 
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trong chứng từ không thể chỉ ra giao dịch %1 và doanh nghiệp quản lý';
				|ru = 'В документе нельзя указывать операцию %1 и управленческую организацию';
				|en = 'You cannot specify operation %1 and management company in the document'; fa = 'You cannot specify operation %1 and management company in the document';
				|it = 'Nel documento non si deve indicare l''operazione %1 e l''azienda di gestione';
				|pl = 'W dokumencie nie można wskazywać operację %1 i firmę zarządczą';
				|tr = '%1 işlemi ve yönetim muhasebesi belgede belirtilmemeli'"),
			DocumentObject.BusinessOperation);
		CommonClientServer.MessageToUser(
			Text,
			DocumentObject,
			"BusinessOperation",
			,
			Cancel);
	 
	EndIf;
	
EndProcedure // Check the correctness of the designation of the economic operation()

// Deprecated. Checks the fullness of the Attributes being checked. Use a common designationout.Check the ability of the water base with parameters.
//
// Parameters:
// 	Document - DocumentRef - The document on the basis of which the input is made
// 	Status - EnumRef - Status of the document that is used for entering data
// 	ThereAreErrorsPosted - Boolean - If True-the document on the basis of which the input is made is not held
// 	ThereAreErrorsStatus   - Boolean - If True, the document that is used for input has an incorrect status
// 	ArrayOfValidStatuses - Array - Array of valid statuses
// 	AgreementIsAvailableToExternalUser - Boolean - If True, the document on the basis of which the input is performed has an agreement accessible to an external user.
// 	Interrupt execution - Boolean - If True, then an exception will be thrown if there is an error, if False, then a message is simply displayed.
//
Procedure CheckPossibilityOfEnteringBasedOn(Document,
	                                           Status = Undefined,
	                                           ThereAreErrorsPosted = False,
	                                           ThereAreErrorsStatus = False,
	                                           ArrayOfValidStatuses = Undefined,
	                                           AgreementIsAvailableToExternalUser = Undefined) Export
	
	CheckParameters = ParametersForCheckingPossibilityOfEnteringBasedOn();
	CheckParameters.Status = Status;
	CheckParameters.ThereAreErrorsPosted = ThereAreErrorsPosted;
	CheckParameters.ThereAreErrorsStatus = ThereAreErrorsStatus;
	CheckParameters.ArrayOfValidStatuses = ArrayOfValidStatuses;
	CheckParameters.AgreementIsAvailableToExternalUser = AgreementIsAvailableToExternalUser;
	
	CheckPossibilityOfInputBasedOnParameters(Document, CheckParameters);
	
EndProcedure // Check the possibility of a Water base()

// Checks the completeness of the verified details.
// 
// Parameters:
//  Document - DocumentRef - The document on the basis of which the input is made
//  CheckParameters - See ParametersForCheckingPossibilityOfEnteringBasedOn
Procedure CheckPossibilityOfInputBasedOnParameters(Document, CheckParameters) Export
	
	If CheckParameters.ThereAreErrorsPosted Then
		
		ErrorText = NStr("vi = 'Chưa kết chuyển chứng từ %Document%. Cấm nhập trên cơ sở chứng từ chưa kết chuyển.';
						|ru = 'Документ %Document% не проведен. Ввод на основании непроведенного документа запрещен.';
						|en = 'Document %Document% is not posted. Generation from unposted documents is not allowed.'; fa = 'Document %Document% is not posted. Generation from unposted documents is not allowed.';
						|it = 'Il documento %Document% non è stato registrato. L''immissione in base al documento non registrato è proibita.';
						|pl = 'Dokument %Document% nie jest zaksięgowany. Wprowadzanie na podstawie niezaksięgowanego dokumentu jest zakazane.';
						|tr = '%Document% belgesi kaydedilmedi. Kaydedilmemiş belgeye dayalı giriş yasaktır.'");
		ErrorText = StrReplace(ErrorText, "%Document%", Document);
		
		If CheckParameters.InterruptExecution Then
			Raise ErrorText;
		Else
			Common.MessageToUser(ErrorText);
		EndIf;
	EndIf;
	
	If CheckParameters.ThereAreErrorsStatus Then
		
		If Not ValueIsFilled(CheckParameters.ArrayOfValidStatuses) Then
			ErrorText = NStr("vi = 'Chứng từ %Document% ở trạng thái ""%Status%"". Cấm nhập trên cơ sở.';
							|ru = 'Документ %Document% находится в статусе ""%Status%"". Ввод на основании запрещен.';
							|en = 'Document %Document% is in the ""%Status%"" status. Generation from base documents in this status is not allowed.'; fa = 'Document %Document% is in the ""%Status%"" status. Generation from base documents in this status is not allowed.';
							|it = 'Il documento%Document% si trova nello stato ""%Status%"". L''inserimento sulla base è vietato.';
							|pl = 'Dokument %Document% ma status ""%Status%"". Wprowadzenie na podstawie jest zabronione.';
							|tr = '%Document% belgesi, ""%Status%"" durumunda. Gerekçeye dayalı giriş yasaktır.'");
		ElsIf TypeOf(CheckParameters.ArrayOfValidStatuses) = Type("Array") Then
			
			If CheckParameters.ArrayOfValidStatuses.Count() = 1 Then
				ErrorText = NStr("vi = 'Chứng từ %Document% có trạng thái ""%Status%"". Cho phép nhập trên cơ sở chỉ ở trạng thái ""%StringOfAcceptableStatuses%"".';
								|ru = 'Документ %Document% находится в статусе ""%Status%"". Ввод на основании разрешен только в статусе ""%StringOfAcceptableStatuses%"".';
								|en = 'Document %Document% is in the ""%Status%"" status. Generation is only allowed from base documents in %StringOfAcceptableStatuses% status.'; fa = 'Document %Document% is in the ""%Status%"" status. Generation is only allowed from base documents in %StringOfAcceptableStatuses% status.';
								|it = 'Il documento %Document% si trova nello stato ""%Status%"". L''inserimento sulla base è permesso solo nello stato ""%StringOfAcceptableStatuses%"".';
								|pl = 'Dokument %Document% ma status ""%Status%"". Wprowadzenie na podstawie jest dozwolone tylko w statusie ""%StringOfAcceptableStatuses%"".';
								|tr = '%Document% belgesi, ""%Status%"" durumundadır. Gerekçeye dayalı girişe yalnızca ""%StringOfAcceptableStatuses%"" durumunda izin verilir.'");
				ErrorText = StrReplace(ErrorText, "%StringOfAcceptableStatuses%", CheckParameters.ArrayOfValidStatuses[0]);
			Else
				ErrorText = NStr("vi = 'Chứng từ %Document% có trạng thái ""%Status%"". Cho phép lập trên cơ sở với trạng thái ""%StringOfAcceptableStatuses%"".';
								|ru = 'Документ %Document% находится в статусе ""%Status%"". Ввод на основании разрешен только в статусах ""%StringOfAcceptableStatuses%"".';
								|en = 'Document %Document% is in the ""%Status%"" status. Generation is only allowed from base documents in %StringOfAcceptableStatuses% statuses.'; fa = 'Document %Document% is in the ""%Status%"" status. Generation is only allowed from base documents in %StringOfAcceptableStatuses% statuses.';
								|it = 'Il documento %Document% si trova nello stato ""%Status%"". L''inserimento sulla base è permesso solo negli stati ""%StringOfAcceptableStatuses%"".';
								|pl = 'Dokument %Document% ma status ""%Status%"". Wprowadzenie na podstawie jest dozwolone tylko przy statusach ""%StringOfAcceptableStatuses%"".';
								|tr = '%Document% belgesi, ""%Status%"" durumundadır. Gerekçeye dayalı girişe yalnızca ""%StringOfAcceptableStatuses%"" durumlarında izin verilir.'");
				ErrorText = StrReplace(ErrorText, "%StringOfAcceptableStatuses%", StrConcat(CheckParameters.ArrayOfValidStatuses, """, """));
			EndIf;
			
		EndIf;
		
		ErrorText = StrReplace(ErrorText, "%Document%", Document);
		ErrorText = StrReplace(ErrorText, "%Status%",   CheckParameters.Status);
		
		If CheckParameters.InterruptExecution Then
			Raise ErrorText;
		Else
			Common.MessageToUser(ErrorText);
		EndIf;
		
	EndIf;
	
	If TMCommonUseClientServer.AnExternalUserIsAuthorized() And Not CheckParameters.AgreementIsAvailableToExternalUser = True Then
		
		ErrorText = NStr("vi = 'Không sử dụng được thỏa thuận của chứng từ %Document% khi tự phục vụ. Cấm nhập trên cơ sở.';
						|ru = 'Соглашение документа %Document% недоступно для работы при самообслуживании. Ввод на основании запрещен.';
						|en = 'Self-Service Workplace doesn''t have access to the agreement for %Document%. You cannot generate the document.'; fa = 'Self-Service Workplace doesn''t have access to the agreement for %Document%. You cannot generate the document.';
						|it = 'L''accordo del documento %Document%  non è disponibile per il lavoro individuale. Inserimento sulla base vietato.';
						|pl = 'Umowa dokumentu %Document% jest niedostępna do pracy podczas samoobsługi. Wprowadzenie na podstawie jest zabronione.';
						|tr = '%Document% belge sözleşmesi, self servis çalışma alanı için mevcut değil. Gerekçeye dayalı giriş yasaktır.'");
		ErrorText = StrReplace(ErrorText, "%Document%", Document);
		
		If CheckParameters.InterruptExecution Then
			Raise ErrorText;
		Else
			Common.MessageToUser(ErrorText);
		EndIf;
		
	EndIf;
	
	If DocumentCorrection.IsThereFixOrReverse(Document) Then
		
		ErrorText = NStr("vi = 'Đã hủy chứng từ %Document%. Cấm nhập trên cơ sở.';
						|ru = 'Документ %Document% аннулирован. Ввод на основании запрещен.';
						|en = 'Document %Document% has been canceled. Generation is not allowed.'; fa = 'Document %Document% has been canceled. Generation is not allowed.';
						|it = 'Documento %Document% è stato annullato. Non è consentito inserimento basato questo documento.';
						|pl = 'Dokument %Document% został anulowany. Wprowadzenie na podstawie jest zabronione.';
						|tr = '%Document% belgesi kaldırıldı. Gerekçeye dayalı giriş yasaktır.'");
		ErrorText = StrReplace(ErrorText, "%Document%", Document);
		
		If CheckParameters.InterruptExecution Then
			Raise ErrorText;
		Else
			Common.MessageToUser(ErrorText);
		EndIf;
		
	EndIf;
	
EndProcedure // Check the possibility of a Water base()

// Parameters for checking the possibility of input based on.
//
// Returns:
//  Structure:
//  * Status - EnumRef - Status of the document that is used for entering data
//  * ThereAreErrorsPosted - Boolean - If True-the document on the basis of which the input is made is not held
//  * ThereAreErrorsStatus   - Boolean - If True, the document that is used for input has an incorrect status
//  * ArrayOfValidStatuses - Array - Array of valid statuses
//  * AgreementIsAvailableToExternalUser - Boolean - If True, the document on the basis of which the input is made has an agreement available to an external user.
//  * InterruptExecution - Boolean - If True, then an exception will be thrown if there is an error, if False, then a message is simply displayed.
//
Function ParametersForCheckingPossibilityOfEnteringBasedOn() Export
	
	CheckParameters = New Structure;
	CheckParameters.Insert("Status", Undefined);
	CheckParameters.Insert("ThereAreErrorsPosted", False);
	CheckParameters.Insert("ThereAreErrorsStatus", False);
	CheckParameters.Insert("ArrayOfValidStatuses", Undefined);
	CheckParameters.Insert("AgreementIsAvailableToExternalUser", Undefined);
	CheckParameters.Insert("InterruptExecution", True);
	
	Return CheckParameters;
	
EndFunction

// Checks whether a document can be entered based on an order for a business transaction.
//
// Parameters:
//	DocumentBasis	- DocumentRef - the document that the input is based on.
//	DocumentName		- String - name of the document that valid operations are defined for.
//	BusinessOperation- EnumRef.BusinessTransactions	- business operation of the document 
//											on the basis of which the input is made.
//	PresentationOfDocument - String - 
//	                       - Undefined - Presentation of the document in the information database.
//
Procedure CheckPossibilityOfEnteringBasedOnOperation(DocumentBasis,
							DocumentName,
							BusinessOperation,
							PresentationOfDocument = Undefined) Export
	
	DocumentOperations = PermissibleBusinessOperationsOfDocument(DocumentName);
	
	If DocumentOperations.Find(BusinessOperation) = Undefined Then
		DocumentSynonym = ?(ValueIsFilled(PresentationOfDocument),
					PresentationOfDocument,
					Metadata.Documents[DocumentName].Synonym);
		
		ErrorText = NStr("vi = 'Không thể thực hiện chứng từ ""%1"" trên cơ sở đơn %2 với thao tác ""%3"".';
						|ru = 'Невозможно оформить документ ""%1"" на основании распоряжения %2 с операцией ""%3"".';
						|en = 'Cannot register the ""%1"" document based on the %2 reference with the ""%3"" operation.'; fa = 'Cannot register the ""%1"" document based on the %2 reference with the ""%3"" operation.';
						|it = 'Impossibile formalizzare il documento ""%1"" sulla base di riferimento %2 con operazione ""%3"".';
						|pl = 'Nie można sporządzić dokument ""%1"" na podstawie zamówienia %2 z operacją ""%3"".';
						|tr = '""%1"" belgesini ""%3"" işlemiyle %2 siparişe göre düzenlemek mümkün değil.'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText,
											DocumentSynonym,
											DocumentBasis,
											BusinessOperation);
		
		Raise ErrorText;
	EndIf;
	
	
EndProcedure

// Checks the completeness of the verified details.
//
// Parameters:
// Document                            - DocumentRef - The document on the basis of which the input is made
// ThereAreErrorsPosted                  - Boolean - If True-the document on the basis of which the input is made is not held
// ThereAreErrorsToReturnMultiTurnContainer - Boolean - If True-according to the document on the basis of which the input is made,
//                                                the container is not refundable.
//
Procedure CheckPossibilityOfEnteringOnBasisOfRedemptionOfContainers(Document, ThereAreErrorsPosted, ThereAreErrorsToReturnMultiTurnContainer) Export
	
	If ThereAreErrorsPosted Then
		
		ErrorText = NStr("vi = 'Chứng từ %Document% chưa kết chuyển. Lập trên cơ sở bị cấm.';
						|ru = 'Документ %Document% не проведен. Ввод на основании непроведенного документа запрещен.';
						|en = 'Document %Document% is not posted. Generation from unposted documents is not allowed.'; fa = 'Document %Document% is not posted. Generation from unposted documents is not allowed.';
						|it = 'Il documento %Document% non è stato registrato. L''immissione in base al documento non registrato è proibita.';
						|pl = 'Dokument %Document% nie jest zaksięgowany. Wprowadzanie na podstawie niezaksięgowanego dokumentu jest zakazane.';
						|tr = '%Document% belgesi kaydedilmedi. Kaydedilmemiş belgeye dayalı giriş yasaktır.'");
		ErrorText = StrReplace(ErrorText, "%Document%", Document);
	
		Raise ErrorText;
		
	ElsIf ThereAreErrorsToReturnMultiTurnContainer Then
		
		ErrorText = NStr("vi = 'Trong chứng từ %Document% không có dấu hiệu trả lại bao bì nhiều lượt. Nhập vào trên cơ sở bị cấm.';
						|ru = 'В документе %Document% не стоит признак возврата многооборотной тары. Ввод на основании запрещен.';
						|en = 'Document %Document% contains no indication whether the reusable packaging has been returned. Generation from such base documents is not allowed.'; fa = 'Document %Document% contains no indication whether the reusable packaging has been returned. Generation from such base documents is not allowed.';
						|it = 'Nel documento  %Document% non è presente il segno di restituzione dell''imballaggio restituibile. Inserimento sulla base vietato.';
						|pl = 'W dokumencie %Document% nie ma oznaki zwrotu tary do wielokrotnego użytku. Wprowadzenie na podstawie jest zabronione.';
						|tr = '%Document% belgesi, yeniden kullanılabilir ambalajın iade bayrağına sahip değil. Gerekçeye dayalı giriş yasaktır.'");
		ErrorText = StrReplace(ErrorText, "%Document%", Document);
	
		Raise ErrorText;
		
	EndIf;
	
EndProcedure

// Checks the completeness of the verified details.
//
// Parameters:
// ThereAreErrorsTypical  - Boolean - If True-the agreement on the basis of which the input is made-standard
// TheseAreAgencyServices  - Boolean - If True-the agreement on the basis of which the input is made - the agreement on
//                                the provision of Agency services.
//
Procedure CheckPossibilityOfEnteringOnBasisOfAgreement(ThereAreErrorsTypical = False, TheseAreAgencyServices = False) Export
	
	If ThereAreErrorsTypical Then
		
		ErrorText = NStr("vi = 'Nhập vào dựa trên một thỏa thuận tiêu chuẩn với khách hàng đều bị cấm.';
						|ru = 'Ввод на основании типового соглашения с клиентом запрещен.';
						|en = 'Cannot generate documents from a standard customer agreement.'; fa = 'Cannot generate documents from a standard customer agreement.';
						|it = 'L''inserimento basato sul contratto standard con il cliente è proibito.';
						|pl = 'Wprowadzenie na podstawie typowej umowy z klientem jest zabronione.';
						|tr = 'Standart satış koşullarına dayalı giriş yasaktır.'");
	
		Raise ErrorText;
		
	EndIf;
	
	If TheseAreAgencyServices Then
		
		ErrorText = NStr("vi = 'Nhập vào dựa trên một thỏa thuận mô hình cho việc cung cấp dịch vụ đại lý đều bị cấm.';
						|ru = 'Ввод на основании типового соглашения по оказанию агентских услуг запрещен.';
						|en = 'Cannot generate documents from a standard agent service agreement.'; fa = 'Cannot generate documents from a standard agent service agreement.';
						|it = 'L''inserimento basato sul contratto standard sulla fornitura di servizi di agenzia è proibito.';
						|pl = 'Wprowadzenie na podstawie typowej umowy świadczenia usług agencyjnych jest zabronione.';
						|tr = 'Aracı hizmetlerinin sağlanması için bir standart satış koşullarına dayalı giriş yasaktır.'");
	
		Raise ErrorText;
		
	EndIf;
	
EndProcedure // Check the feasibility of the Agreement()

// Checks the completeness of the verified details.
//
// Parameters:
// 	Partner - CatalogRef.Partners - Partner from the sale transaction.
//
Procedure CheckPossibilityOfEnteringOnBasisOfSaleTransaction(Partner) Export
	
	If Not ValueIsFilled(Partner) Then
		
		ErrorText = NStr("vi = 'Khách hàng không được chỉ định trong giao dịch, nhập trên cơ sở bị cấm.';
						|ru = 'В сделке не указан клиент, ввод на основании запрещен.';
						|en = 'No customer is specified in the sales opportunity. Generation from such base document is not allowed.'; fa = 'No customer is specified in the sales opportunity. Generation from such base document is not allowed.';
						|it = 'Nella transazione non è indicato il cliente, inserimento sulla base vietato.';
						|pl = 'W umowie nie jest wskazany klient, wprowadzenie na podstawie jest zabronione.';
						|tr = 'Satış fırsatında müşteri belirtilmedi, girişe dayalı olarak yasaktır.'");
	
		Raise ErrorText;
		
	EndIf;
	
EndProcedure // Check the possibility of a water base for the sale()

// Sets or resets the Matched flag for the directory.
// Called from the procedure Before writing the document.
//
// Parameters:
// 	CatalogObject - CatalogObject - The directory where you need to change the Agreed flag
// 	StatusNotAgreed - EnumRef - The status of the document in which the flag is Matched should be reset.
//
Procedure ChangeCatalogConsistencyFlag(CatalogObject, Val StatusNotAgreed = Undefined) Export
	
	// The directory has no status
	If StatusNotAgreed = Undefined Then
		
		If Not CatalogObject.Approved Then
			CatalogObject.Approved = True;
		EndIf;
		
	// The directory has a status in which the conducted directory is not coordinated
	Else
		
		If CatalogObject.Status = StatusNotAgreed And CatalogObject.Approved Then
			CatalogObject.Approved = False;
		ElsIf CatalogObject.Status <> StatusNotAgreed And Not CatalogObject.Approved Then
			CatalogObject.Approved = True;
		EndIf;
		
	EndIf;
	
EndProcedure // Change the sign of the Right-hand man()

// Sets or resets the Agreed flag for the document.
// Called from the procedure Before writing the document.
//
// Parameters:
// 	DocumentObject - DocumentObject - Document where you need to change the Agreed flag
// 	WriteMode - DocumentWriteMode - The recording mode of the document
// 	StatusNotAgreed - EnumRef -  The status of the document in which the flag is Matched should be reset.
//
Procedure ChangeDocumentConsistencyAttribute(DocumentObject, Val WriteMode, Val StatusNotAgreed = Undefined) Export
	
	If WriteMode = DocumentWriteMode.Write
	 Or WriteMode = DocumentWriteMode.UndoPosting Then
		
		If DocumentObject.Approved Then
			DocumentObject.Approved = False;
		EndIf;
		
	ElsIf WriteMode = DocumentWriteMode.Posting Then
		
		// The document has no status
		If StatusNotAgreed = Undefined Then
		
			If Not DocumentObject.Approved Then
				DocumentObject.Approved = True;
			EndIf;
			
		// The document has a status from the array in which the document is not approved
		ElsIf TypeOf(StatusNotAgreed) = Type("Array") Then
			
			If DocumentObject.Approved Then
				
				For Each CurStatus In StatusNotAgreed Do
					
					If DocumentObject.Status = CurStatus Then
						
						DocumentObject.Approved = False;
						Break;
						
					EndIf;
					
				EndDo;
				
			Else
				
				DocumentApproved = True;
				
				For Each CurStatus In StatusNotAgreed Do
					
					If DocumentObject.Status = CurStatus Then
						DocumentApproved = False;
					EndIf;
					
				EndDo;
				
				If DocumentApproved Then
					DocumentObject.Approved = True;
				EndIf;
				
			EndIf;
			
		// The document has a status in which the document has not been approved
		Else
			
			If DocumentObject.Status = StatusNotAgreed And DocumentObject.Approved Then
				DocumentObject.Approved = False;
			ElsIf DocumentObject.Status <> StatusNotAgreed And Not DocumentObject.Approved Then
				DocumentObject.Approved = True;
			EndIf;
			
		EndIf;

	EndIf;
	
EndProcedure // Change the sign of the agreement of the document()

// Configures the connected equipment in the form, sets the Use connected equipment in the form flag.
// 
// Parameters:
//   Form - ClientApplicationForm - A form where you need to configure the connected hardware.
//   PrefixesOfFormElements - String - 
//	                        - Array of String - PrefixesOfFormElements
//
Procedure CustomizePeripherals(Form, PrefixesOfFormElements = "Goods") Export
	
	TypesOfConnectedEquipment = PeripheralsTMCached.TypesOfConnectedEquipment();
	
	Form.UsePeripherals = UsePeripherals(TypesOfConnectedEquipment);
	
	ThereIsTSD  =
		TypesOfConnectedEquipment <> Undefined
		And TypesOfConnectedEquipment.Find(Enums.PeripheralTypes.PortableDataCollectionTerminal) <> Undefined;
	ThereAreScales =
		TypesOfConnectedEquipment <> Undefined
		And TypesOfConnectedEquipment.Find(Enums.PeripheralTypes.DigitalRetailScales) <> Undefined;
		
	If ValueIsFilled(PrefixesOfFormElements) Then
		ArrayPrefixesOfFormElements = StringFunctionsClientServer.SplitStringIntoSubstringsArray(PrefixesOfFormElements, ",");
	Else
		ArrayPrefixesOfFormElements = New Array;
		ArrayPrefixesOfFormElements.Add(PrefixesOfFormElements);
	EndIf;
	
	For Each Prefix In ArrayPrefixesOfFormElements Do
		
		TMCommonUseClientServer.SetFormItemProperty(
			Form.Items,
			Prefix + "ImportDataFromPDT",
			"Visible",
			Form.UsePeripherals And ThereIsTSD);
		
		TMCommonUseClientServer.SetFormItemProperty(
			Form.Items,
			Prefix + "UploadVTSDData",
			"Visible",
			Form.UsePeripherals And ThereIsTSD);
		
		TMCommonUseClientServer.SetFormItemProperty(
			Form.Items,
			Prefix + "GetWeight",
			"Visible",
			Form.UsePeripherals And ThereAreScales);
		
	EndDo;
	
EndProcedure

// Checks that the "Use connected hardware" feature is enabled, whether the hardware is configured, and whether the user is logged in.
// 
// Parameters:
// 	TypesOfConnectedEquipment - EnumRef.PeripheralTypes - 
//
// Returns:
// 	Boolean - 
Function UsePeripherals(TypesOfConnectedEquipment = Undefined) Export
	
	UsePeripherals = GetFunctionalOption("UsePeripherals");
	UserLoggedIn 			 = TypeOf(Users.AuthorizedUser()) = Type("CatalogRef.Users");
	
	If TypesOfConnectedEquipment = Undefined Then
		TypesOfConnectedEquipment = PeripheralsTMCached.TypesOfConnectedEquipment();
	EndIf;
	
	Return
		UsePeripherals
		And UserLoggedIn
		And TypesOfConnectedEquipment <> Undefined
		And TypesOfConnectedEquipment.Count() > 0;
												 
EndFunction

// Returns a list of users who have the roles specified as a parameter
//
// Parameters:
// 		RolesArray - Array of String - array with role names
// 		CurUserPresentation - String - view of the current user.
// 
//	Returns:
//		ValueList of CatalogRef.Users -
//
Function UsersWithAvailableRoles(RolesArray, CurUserPresentation = Undefined) Export
	
	UsersList = New ValueList;
	If CurUserPresentation = Undefined Then
		CurUserPresentation = NStr("vi = '<Chứng từ của tôi>';
									|ru = '<Мои документы>';
									|en = '<My documents>'; fa = '<My documents>';
									|it = '<i miei documenti>';
									|pl = '<Моje dokumenty>';
									|tr = '<Belgelerim>'");
	EndIf;
	
	// Request to get a list of all users. It is executed in privileged mode.
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	AccessGroupProfilesRoles.Ref AS Ref
	|INTO AccessGroupProfiles
	|FROM
	|	Catalog.AccessGroupProfiles.Roles AS AccessGroupProfilesRoles
	|WHERE
	|	AccessGroupProfilesRoles.Role.Name IN(&RolesArray)
	|
	|GROUP BY
	|	AccessGroupProfilesRoles.Ref
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(UserGroupsComposition.User, AccessGroups_Users.User) AS User
	|FROM
	|	Catalog.AccessGroups.Users AS AccessGroups_Users
	|		LEFT JOIN Catalog.UserGroups.Content AS UserGroupsComposition
	|		ON AccessGroups_Users.User = UserGroupsComposition.Ref
	|WHERE
	|	AccessGroups_Users.Ref.Profile IN
	|			(SELECT
	|				AccessGroupProfiles.Ref
	|			FROM
	|				AccessGroupProfiles AS AccessGroupProfiles)
	|
	|GROUP BY
	|	ISNULL(UserGroupsComposition.User, AccessGroups_Users.User)";
	
	Query.SetParameter("RolesArray", RolesArray);
	
	ArrayOfAllUsers = Query.Execute().Unload().UnloadColumn("User");
	
	SetPrivilegedMode(False);
	
	// Request for a list of "allowed" users
	Query.Text =
	"SELECT ALLOWED
	|	Users.Ref AS User
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	Users.Ref IN(&UsersArray)
	|	AND Users.DeletionMark = FALSE
	|	AND Users.Invalid = FALSE
	|
	|ORDER BY
	|	Users.Description";
	Query.SetParameter("UsersArray", ArrayOfAllUsers);
	
	CurrentUser = Users.CurrentUser();
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		If CurrentUser = Selection.User Then
			UsersList.Insert(0, Selection.User, CurUserPresentation);
		Else
			UsersList.Add(Selection.User);
		EndIf;
	EndDo;
	
	Return UsersList;
	
EndFunction

// Returns a list of users who have the right to change the metadata object
//
// Parameters:
// 		MetadataObject - MetadataObject - Metadata object that access rights are checked for
// 		CurUserPresentation - String - view of the current user.
// 
//	Returns:
//		ValueList of CatalogRef.Users
//
Function GetListOfUsersWithRightToAdd(MetadataObject, CurUserPresentation = Undefined) Export
	
	MetadataObjectName = MetadataObject.FullName();
	RolesArray = UserRightsCached.NamesOfRolesWithRightToAdd(MetadataObjectName);
	
	If Not ValueIsFilled(RolesArray) Then
		Return New ValueList;
	EndIf;
	
	Return UsersWithAvailableRoles(RolesArray, CurUserPresentation);;
	
EndFunction

// Returns an array with unique values from a table column
//
// Parameters:
//  Table			 - ValueTable -
//					 - FormDataStructure - 
//  ColumnName		 - String -
//  FilterParameters	 - Structure - 
// 
// Returns:
// 	Array -
//
Function UniqueValuesFromTableColumn(Table, ColumnName, FilterParameters = Undefined) Export
	
	If TypeOf(Table) = Type("ValueTable") Then
		ProcessedTable = Table.Copy(FilterParameters, ColumnName);
	Else
		ProcessedTable = Table.Unload(FilterParameters, ColumnName);
	EndIf;
		
	ProcessedTable.GroupBy(ColumnName);
	Return ProcessedTable.UnloadColumn(0);
	
EndFunction

// Deletes the specified rows from the table
// 
// Parameters:
//	Table - ValueTable - table being processed
//	        - FormDataCollection - table being processed
//	Rows  - Array of ValueTableRow - Array of rows to delete
//	        - Array of FormDataCollectionItem - Array of rows to delete
//
Procedure DeleteTableRows(Table, Rows) Export
	
	For Each TableRow In Rows Do
		Table.Delete(TableRow);
	EndDo;
	
EndProcedure

// Deletes rows from the value table based on the passed selection.
// 
// Parameters:
//	Table 			  - ValueTable - table being processed
//	TheStructureOfTheSearch 	  - Structure - structure of string search, see the description of the method for finding the value table string
//	DeleteItemsIncludedInSelection - Boolean - if you specify False, all rows that are not included in the selection will be deleted.
//
Procedure FindAndDeleteRowsInValueTable(Table, TheStructureOfTheSearch, DeleteItemsIncludedInSelection = True) Export
	
	Rows = Table.FindRows(TheStructureOfTheSearch);
	
	If Not DeleteItemsIncludedInSelection Then
		
		If Rows.Count() = Table.Count() Then
			Return; // nothing to delete
		ElsIf Rows.Count() = 0 Then
			Table.Clear();
		Else
			
			LinesToDelete = New Array;
			
			For Each TableRow In Table Do
				
				If Rows.Find(TableRow) = Undefined Then
					LinesToDelete.Add(TableRow); // the string is not included in the transmitted selection
				EndIf;
				
			EndDo;
			
			DeleteTableRows(Table, LinesToDelete);
			
		EndIf;
		
	Else
		
		If Rows.Count() = 0 Then
			Return; // nothing to delete
		ElsIf Rows.Count() = Table.Count() Then
			Table.Clear();
		Else
			DeleteTableRows(Table, Rows);
		EndIf;
		
	EndIf;
	
EndProcedure

// The function checks whether there is a matching for the specified role in the information register "Task Performers".
//
// Parameters:
//	RoleUnderReview - CatalogRef.PerformerRoles - Element of the executor Roles directory.
// 
// Returns:
// 	Boolean -
Function CheckReconcilingBusinessProcess(RoleUnderReview) Export
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	TaskPerformers.Performer AS ThereIsPerformer
		|FROM
		|	InformationRegister.TaskPerformers AS TaskPerformers
		|WHERE
		|	TaskPerformers.PerformerRole =&PerformerRole";

	Query.SetParameter("PerformerRole", RoleUnderReview);
	Result = Query.Execute();
	SelectionDetailRecords = Result.Select();

	If SelectionDetailRecords.Next() Then
		Return True;
	Else
		Return False;
	EndIf;
EndFunction // Check the matching Business process()

// The function decomposes the passed array of links according to the types of these links.
//
//	Parameters:
//		ReferencesArrray - Array of AnyRef - an array of references to objects of the information base
//  Returns:
//		Map - The correspondence of types to links.
//			The key is the full name of the link type.
//	        The value is an array Of any link - links of this type.
//
Function MatchingArraysByObjectType(ReferencesArrray) Export
	
	MapTypes = New Map;
	
	For Each Object In ReferencesArrray Do
		
		ObjectType = Object.Metadata().FullName();
		CurObjectType_ = MapTypes.Get(ObjectType); // Array - 
		
		If CurObjectType_ = Undefined Then
			MapTypes.Insert(ObjectType, New Array);
			CurObjectType_ = MapTypes.Get(ObjectType);
		EndIf;
		CurObjectType_.Add(Object);
		
	EndDo;
	
	Return MapTypes;
	
EndFunction

// Returns the difference between two dates (in days)
//
// Parameters:
//  StartDate 		- Date - start date of the period
//  EndDate	- Date - end date of the period.
//  Periodicity	- EnumRef.Periodicity - Periodicity.
//
// Returns:
//   Number	 - the number of days between two dates.
//
Function DateDiff(StartDate, EndDate, Periodicity) Export
	
	SecondsPerMinute = 60;
	MinutesPerHour = 60;
	HoursPerDay = 24;
	
	If Periodicity = Enums.Periodicity.Year Then
		Return Year(EndDate) - Year(StartDate);
		
	ElsIf Periodicity = Enums.Periodicity.HalfYear Then
		Return ?(Month(EndDate)>6, 2, 1) - ?(Month(StartDate)>6, 2, 1) + 2*(Year(EndDate) - Year(StartDate));
		
	ElsIf Periodicity = Enums.Periodicity.Quarter Then
		Return Int(Month(BegOfQuarter(EndDate))/3) - Int(Month(BegOfQuarter(StartDate))/3) + 4*(Year(EndDate) - Year(StartDate));
		
	ElsIf Periodicity = Enums.Periodicity.Month Then
		Return Month(EndDate) - Month(StartDate) + 12*(Year(EndDate) - Year(StartDate));
		
	ElsIf Periodicity = Enums.Periodicity.TenDays Then
		Return Int((EndDate - StartDate)/(10 * SecondsPerMinute*MinutesPerHour*HoursPerDay));
		
	ElsIf Periodicity = Enums.Periodicity.Week Then
		Return Int((BegOfWeek(EndDate) - BegOfWeek(StartDate))/(7 * SecondsPerMinute*MinutesPerHour*HoursPerDay));
		
	ElsIf Periodicity = Enums.Periodicity.Day Then
		Return (EndDate - StartDate)/(SecondsPerMinute*MinutesPerHour*HoursPerDay);
		
	EndIf;
	
EndFunction

// Returns an array of days included in the period.
//
// Parameters:
//   StartDate - Date
//   EndDate - Date
//
// Returns:
//   Array of Date - Days of the period.
//
Function ArrayOfDatesFromPeriod(StartDate, EndDate) Export
	Result = New Array;
	
	CurrentDay = BegOfDay(StartDate);
	While CurrentDay <= EndDate Do
		Result.Add(CurrentDay);
		CurrentDay = CurrentDay + 86400;
	EndDo;
	
	Return Result;
EndFunction

// Checks the use of the object
//
// Parameters:
//  Parameters		- Structure - contains an object that you want to check for usage
//  StorageAddress	- String - address of the storage where the verification result will be placed.
//
Procedure CheckObjectUsage(Parameters, StorageAddress) Export
	
	ThereAreRefs = CommonServerCall.RefsToObjectFound(Parameters.Object);
	
	PutToTempStorage(ThereAreRefs, StorageAddress);
	
EndProcedure

// Returns the collection key that has the specified value.
//
// Parameters:
// 	Collection - Structure -
// 	          - Map -
//	          - FixedStructure -
//	          - FixedMap -
//  Value - Arbitrary - Specified value
//
// Returns:
//  String - 
Function CollectionKeyByValue(Collection, Value) Export
	
	For Each KeyAndValue In Collection Do
		If KeyAndValue.Value = Value Then
			Return KeyAndValue.Key;
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

// Returns a collection where keys and values are swapped.
//
// Parameters:
// 	Collection - Structure, Map, FixedStructure, FixedMap -
// 	
// Returns:
//  Structure, Map, FixedStructure, FixedMap -
Function ChangeCollectionKeyAndValue(Collection) Export
	
	If TypeOf(Collection) = Type("Structure") Or TypeOf(Collection) = Type("FixedStructure") Then
		NewCollection = New Structure;
	ElsIf TypeOf(Collection) = Type("Map") Or TypeOf(Collection) = Type("FixedMap") Then
		NewCollection = New Map;
	Else
		Return Undefined;
	EndIf;
	
	For Each KeyAndValue In Collection Do
		NewCollection.Insert(KeyAndValue.Value, KeyAndValue.Key);
	EndDo;
	
	If TypeOf(Collection) = Type("FixedStructure") Then
		NewCollection = New FixedStructure(NewCollection);
	ElsIf TypeOf(Collection) = Type("FixedMap") Then
		NewCollection = New FixedMap(NewCollection);
	EndIf;
	
	Return NewCollection;
	
EndFunction

// Returns the number of documents in words.
//
// Parameters:
//  DocumentsCount - Number - number of documents.
//
// Returns:
//  String - The number of documents in words.
//
Function NumberOfDocumentsInWords(DocumentsCount) Export
	
	QuantityInWords = NumberInWords(
		DocumentsCount,
		NStr("vi = 'НП = Истина; НД = Ложь; ДП = Ложь;';
			|ru = 'SN = Истина; FN = Ложь; FS = Ложь;';
			|en = 'SN = True; FN = False; FS = False;'; fa = 'SN = True; FN = False; FS = False;';
			|it = 'НП = Vero; НД = falso; ДП = falso;';
			|pl = 'SN = Prawda; FN = Falsz; FS = Falsz;';
			|tr = 'SN = True; FN = False; FS = False;'"),
		NStr("vi = 'chứng từ,chứng từ,chứng từ,m,,,,,0';
			|ru = 'документ,документа,документов,м,,,,,0';
			|en = 'document, documents,,,0'; fa = 'document, documents,,,0';
			|it = 'Documento, documenti, documenti м,,,,,0';
			|pl = 'dokument,dokumentu,dokumentów,м,,,,,0';
			|tr = 'belge,belge,belgeler,,,,,,0'"));
	
	Pos = StrFind(QuantityInWords, NStr("vi = 'chứng từ';
										|ru = 'документ';
										|en = 'document'; fa = 'document';
										|it = 'documento';
										|pl = 'dokument';
										|tr = 'belge'"));
	If Pos <> 0 Then
		QuantityInWords = Mid(QuantityInWords, Pos);
	EndIf;
	
	QuantityInWords = String(DocumentsCount) + " " + Lower(QuantityInWords);
	
	Return QuantityInWords;
	
EndFunction

// Returns a description of types by the passed type
// 
// Parameters:
//	Type - Type - Value type
//
// Returns:
//	TypeDescription - a description of the types created based on the passed type.
//
Function DescriptionOfTypesByType(Type) Export
	TypesArray = New Array;
	TypesArray.Add(Type);
	
	TypeDescription = New TypeDescription(TypesArray);
	
	Return TypeDescription;
EndFunction

// Returns a table of values based on an array of structures
// 
// Parameters:
//	StructuresArray - Array of Structure - The array of structures that will be converted to tables of values.
//										   The structure properties of the first array element determine the composition of columns in the resulting table.
//
// Returns:
//	ValueTable - a table of values created from an array of structures.
// 
Function ArrayToValueTable(StructuresArray) Export
	Table = New ValueTable;
	// Let's create columns based on the first array structure
	If TypeOf(StructuresArray) = Type("Array")
		And StructuresArray.Count() <> 0 Then
		FirstStructure = StructuresArray[0];
		For Each Property In FirstStructure Do 
			Table.Columns.Add(Property.Key, DescriptionOfTypesByType(TypeOf(Property.Value)));
		EndDo;
		
		For Each Structure In StructuresArray Do 
			NewRow = Table.Add();
			FillPropertyValues(NewRow, Structure);
		EndDo;
	EndIf;
	
	Return Table;
EndFunction

// Returns a table of values based on matching structures.
// The structure properties of the first matching element determine the composition of columns in the resulting table.
// 
// Parameters:
// 	 Map - Map - Matching structures that will be converted to a table of values, where:
// 			* Key - Arbitrary - is one of the columns in the value table
// 			* Value - Structure - The structure that you want to convert to a table of values
// 
// Returns:
// 	 ValueTable
//
Function MatchingToTableOfValues(Map) Export
	
	Table = New ValueTable;
	// Let's create columns based on the first matching structure
	If TypeOf(Map) = Type("Map")
		And Map.Count() > 0 Then
		For Each KeyAndValue In Map Do 
			FirstStructure = KeyAndValue.Value;
			Break;
		EndDo;
		Table.Columns.Add("Key", DescriptionOfTypesByType(TypeOf(KeyAndValue.Key)));
		For Each Property In FirstStructure Do 
			Table.Columns.Add(Property.Key, DescriptionOfTypesByType(TypeOf(Property.Value)));
		EndDo;
		
		For Each KeyAndValue In Map Do 
			NewRow = Table.Add();
			NewRow.Key = KeyAndValue.Key;
			FillPropertyValues(NewRow, KeyAndValue.Value);
		EndDo;
	EndIf;
	
	Return Table;
	
EndFunction

// Returns object metadata by the full name of the metadata object
//
// Parameters:
//  StringMetadata - String - The full path to the prop metadata as in the metadata tree.
//                       Example: "Documents.Receipt of non-cash monetary funds.Tabular parts.Decryption of the payment.Attributes.Order"
//                               "Accumulation registers.calculationsclientamiposrocam.Measurements.Object of accounts".
//
// Returns:
//  MetadataObject - 
//
Function MetadataByName(StringMetadata) Export
	
	Return PropertyOfMetadata(Metadata, StrSplit(StringMetadata, "."));
	
EndFunction

// Returns True if debugging mode is enabled.
//
// Returns:
// 	 Boolean -
Function DebugMode() Export
	
	SetPrivilegedMode(True);
	DebugMode = Common.DebugMode()
		Or Constants.DebugMode.Get();
	SetPrivilegedMode(False);
	
	Return DebugMode;
	
EndFunction

// Sets the delete tag and generates a list of error messages about setting the delete tag for documents.
//
// Parameters:
//  References - Array of DocumentRef - list of documents.
// 
// Returns:
//   Structure - See CommonClientServer.AddUserError
//
Function SetMarkForDeletingDocuments(References) Export

	Var ErrorList;
	TextIsNotBlocked = NStr("vi = '%1 - không thể đánh dấu chứng từ để xóa, có lẽ chứng từ này đang được chỉnh sửa bởi người dùng khác.';
							|ru = '%1 - не удалось пометить на удаление документ, возможно документ редактируется другим пользователем.';
							|en = '%1 - cannot mark the document for deletion, maybe, the document is being edited by another user.'; fa = '%1 - cannot mark the document for deletion, maybe, the document is being edited by another user.';
							|it = '%1 - non è stato possibile contrassegnare per l''eliminazione il documento. Probabilmente un altro utente lo sta modificando.';
							|pl = '%1 - nie udało się zaznaczyć do usunięcia dokument, możliwie, że dokument jest edytowany przez innego użytkownika.';
							|tr = '%1 - belge silinmek üzere işaretlenemedi, belge başka bir kullanıcı tarafından düzenleniyor olabilir.'");

	For Each Ref In References Do
		DocumentObject = Ref.GetObject();
		If DocumentObject = Undefined Then
			Continue;
		EndIf;
		If DocumentObject.DeletionMark Then
			Continue;
		EndIf;
		
		Try
			DocumentObject.Lock();
		Except
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(TextIsNotBlocked, TrimAll(Ref)); 
			CommonClientServer.AddUserError(ErrorList, Undefined, ErrorText, Undefined);
			Continue;
			
		EndTry;
		
		DocumentObject.SetDeletionMark(True);
	EndDo;
	Return ErrorList;

EndFunction

// Before attempting to delete a document directly, it sets
// a mark for deletion, which allows you to work
// out the mechanisms provided in the document.
// Generates a list of messages about successful deletion of documents, or
// about errors that do not allow deleting documents.
//
// Parameters:
//  RemovalLinks - Array of DocumentRef - List of created documents.
//  ArrayOfExcludedObjects - Undefined, Array of MetadataObject - A list of metadata objects, if there are references
//  to them in the objects being deleted, the deletion is canceled.
// 
// Returns:
//   Undefined, Structure - Contains a list of messages. The composition of the keys is defined in the General Purpose function of the Clientserver.Add an error to the user.
//
Function DeleteDocuments(RemovalLinks, ArrayOfExcludedObjects = Undefined) Export
	
	ErrorList = Undefined;
	
	If RemovalLinks.Count() = 0 Then
		Return ErrorList;
	EndIf;
	
	TextLinksAreAvailable  = NStr("vi = 'Không thể xóa chứng từ %1 vì nó được tham chiếu trong %2.';
									|ru = 'Не удалось удалить документ %1, так как на него имеются ссылки в %2.';
									|en = 'Cannot delete document %1 because it is referenced in %2.'; fa = 'Cannot delete document %1 because it is referenced in %2.';
									|it = 'Non è stato possibile eliminare il documento %1, in quanto vi sono riferimenti al documento in %2.';
									|pl = 'Nie udało się usunąć dokumentu %1, ponieważ nie ma do niego odnośnika w %2.';
									|tr = '%2''de bağlantı gösterildiği için %1 belgesi silinemedi.'");
	TextMarked        = NStr("vi = '%1 - được đánh dấu để xóa.';
							|ru = '%1 - помечен на удаление.';
							|en = '%1 - marked for deletion.'; fa = '%1 - marked for deletion.';
							|it = '%1 - contrassegnato per l''eliminazione.';
							|pl = '%1 - jest zaznaczony do usunięcia.';
							|tr = '%1 - silinmek üzere işaretlendi.'");
	TextDeleted         = NStr("vi = '%1 - đã xóa.';
								|ru = '%1 - удален.';
								|en = '%1 - deleted.'; fa = '%1 - deleted.';
								|it = '%1 - eliminato.';
								|pl = '%1 - został usunięty.';
								|tr = '%1 - silindi.'");
	TextIsNotBlocked = NStr("vi = '%1 - không thể đánh dấu chứng từ để xóa, có lẽ chứng từ này đang được chỉnh sửa bởi người dùng khác.';
							|ru = '%1 - не удалось пометить на удаление документ, возможно документ редактируется другим пользователем.';
							|en = '%1 - cannot mark the document for deletion, maybe, the document is being edited by another user.'; fa = '%1 - cannot mark the document for deletion, maybe, the document is being edited by another user.';
							|it = '%1 - non è stato possibile contrassegnare per l''eliminazione il documento. Probabilmente un altro utente lo sta modificando.';
							|pl = '%1 - nie udało się zaznaczyć do usunięcia dokument, możliwie, że dokument jest edytowany przez innego użytkownika.';
							|tr = '%1 - belge silinmek üzere işaretlenemedi, belge başka bir kullanıcı tarafından düzenleniyor olabilir.'");
	
	ArrayOfMetadataObjectNames = New Array();
	For Each DocumentForDeletion In RemovalLinks Do
		MetadataObjectName = DocumentForDeletion.Metadata().FullName();
		If ArrayOfMetadataObjectNames.Find(MetadataObjectName) = Undefined Then
			ArrayOfMetadataObjectNames.Add(MetadataObjectName);
		EndIf;
	EndDo;
	MetadataObjectNames = StrConcat(ArrayOfMetadataObjectNames, ",");
	
	Registers = TMCommonUseCached.MeasurementMetadataInformationRegisters(MetadataObjectNames, True);
	
	OrderAssignments = OrderAssignments(RemovalLinks);
	CommonClientServer.SupplementArray(RemovalLinks, OrderAssignments);
	
	SetPrivilegedMode(True);
	
	ListOfLinks = FindByRef(RemovalLinks);
	
	TotalRows = ListOfLinks.Count();
	For Counter = 1 To TotalRows Do
		Ref = ListOfLinks[TotalRows - Counter];
		
		If Ref[0] = Ref[1]
			Or ThisIsSlaveInformationRegisterEntry(Ref[1], Registers)
			Or (TypeOf(ArrayOfExcludedObjects) = Type("Array")
				And ThisIsRecordOfExcludedObject(Ref[1], ArrayOfExcludedObjects)) Then
			
			ListOfLinks.Delete(Ref);
			
		EndIf;
		
	EndDo;
	
	MarkForDeletion = New Array();
	
	TotalRows = ListOfLinks.Count();
	For Counter = 1 To TotalRows Do
		Ref = ListOfLinks[TotalRows - Counter];
		
		IndexOf = RemovalLinks.Find(Ref[1]);
		If IndexOf = Undefined Then
			
			If MarkForDeletion.Find(Ref[0]) = Undefined Then
				
				MarkForDeletion.Add(Ref[0]);
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(TextLinksAreAvailable, TrimAll(Ref[0]), TrimAll(Ref[1])); 
				CommonClientServer.AddUserError(ErrorList, Undefined, ErrorText, Undefined);
				
			EndIf;
			
			ListOfLinks.Delete(Ref);
			
		EndIf;
		
	EndDo;
	
	ProcessingCompleted = False;
	While Not ProcessingCompleted Do
		
		ProcessingCompleted = True;
		
		TotalRows = ListOfLinks.Count();
		For Counter = 1 To TotalRows Do
			Ref = ListOfLinks[TotalRows - Counter];
			
			If MarkForDeletion.Find(Ref[0]) <> Undefined Then
				
				If MarkForDeletion.Find(Ref[1]) = Undefined Then
					
					MarkForDeletion.Add(Ref[1]);
					
				EndIf;
				
				ListOfLinks.Delete(Ref);
				ProcessingCompleted = False;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	For Each Ref In RemovalLinks Do
		
		DocumentObject = Ref.GetObject();
		If DocumentObject = Undefined Then
			Continue;
		EndIf;
		
		Try
			DocumentObject.Lock();
		Except
			
			If MarkForDeletion.Find(Ref) = Undefined Then
				MarkForDeletion.Add(Ref);
			EndIf;
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(TextIsNotBlocked, TrimAll(Ref)); 
			CommonClientServer.AddUserError(ErrorList, Undefined, ErrorText, Undefined);
			Continue;
			
		EndTry;
		
		DocumentObject.SetDeletionMark(True);
		If MarkForDeletion.Find(Ref) <> Undefined Then
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(TextMarked, TrimAll(Ref));
			CommonClientServer.AddUserError(ErrorList, Undefined, ErrorText, Undefined);
			
		EndIf;
		
	EndDo;
	
	For Each Ref In MarkForDeletion Do
		
		IndexOf = RemovalLinks.Find(Ref);
		If IndexOf <> Undefined Then
			RemovalLinks.Delete(IndexOf);
		EndIf;
		
	EndDo;
	
	For Each Ref In RemovalLinks Do
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(TextDeleted, TrimAll(Ref)); 
		CommonClientServer.AddUserError(ErrorList, Undefined, ErrorText, Undefined);
		
	EndDo;
	
	DeleteObjects(RemovalLinks, False);
	
	SetPrivilegedMode(False);
	
	Return ErrorList;
	
EndFunction

// Returns data from the first record of the query result as a structure.
// 
// Parameters:
//  QueryResult - QueryResult - the result of the request containing the data to be processed.
// 
// Returns:
//  Structure - the structure with the result.
//
Function FirstLineOfQueryResultInStructure(Val QueryResult) Export

	Result = New Structure;
	For Each Column In QueryResult.Columns Do
		Result.Insert(Column.Name);
	EndDo;

	If QueryResult.IsEmpty() Then
		Return Result;
	EndIf;

	Selection = QueryResult.Select();
	Selection.Next();

	FillPropertyValues(Result, Selection);

	Return Result;

EndFunction

// Returns a structure with keys corresponding to columns in the value table.
// Values in the structure are filled in with field values from the passed table row.
//
// Parameters:
//	CurrentRow - ValueTableRow -
//
// Returns:
//	Structure -
//
Function ConvertTableRowToStructure(CurrentRow) Export
	
	Result = New Structure;
	
	For Each Column In CurrentRow.Owner().Columns Do
		Result.Insert(Column.Name, CurrentRow[Column.Name]);
	EndDo;
	
	Return Result;
	
EndFunction

// Sets request parameters from the passed structure.
//
// Parameters:
//	Query - Query - request to set parameters for
//	QueryOptions - Structure - structure with set request parameters.
//
Procedure SetRequestParameters(Query, QueryOptions) Export
	
	If Not ValueIsFilled(QueryOptions) Then
		Return;
	EndIf;
	
	For Each KeyAndValue In QueryOptions Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
EndProcedure

// Gets the layout in metadata and returns it
//
// Parameters:
//  TemplateNameOrAddress - String - the full name of the layout. For example, A Document.Implementationsservices.Datareschartsreferences 
// 
// Returns:
//  SpreadsheetDocument, TextDocument, DataCompositionSchema -
//
Function TemplateByName(TemplateNameOrAddress) Export
	
	PointPosition_ = StrFind(TemplateNameOrAddress, ".",,,2);
	
	If PointPosition_ = 0 Then
		PointPosition_ = StrFind(TemplateNameOrAddress, ".",,,1);
		
		TemplateName    = Right(TemplateNameOrAddress, StrLen(TemplateNameOrAddress) - PointPosition_); 
		Result = GetCommonTemplate(TemplateName);
	Else
		ManagerName = Left(TemplateNameOrAddress, PointPosition_);
		TemplateName    = Right(TemplateNameOrAddress, StrLen(TemplateNameOrAddress) - PointPosition_); 
		
		ObjectManager = Common.ObjectManagerByFullName(ManagerName);
		
		Result = ObjectManager.GetTemplate(TemplateName);
	EndIf;
	
	Return Result;
	
EndFunction

// Collapse the table part of the object
// By default, all numeric columns are included in the summation columns. The numeric columns
// that should be included in the grouping columns should be listed in the grouping Columns parameter.
// You don't need to list non-numeric columns in the grouping Column.
// 
// Parameters:
//  Object - DocumentObject - 
//	       - CatalogObject - 
//		   - ChartOfCharacteristicTypesObject - 
//         - ExchangePlanObject - An object containing a tabular part 
//  TSName			   - String - the name of the table that you want to roll
//  GroupingColumns - Array of String -
//                     - String - An array of strings with the names of numeric columns or a string with names separated by commas
//  						      that need to be included in grouping columns, not summation.
//
Procedure CollapseTablePart(Object, TSName, Val GroupingColumns = Undefined) Export
	
	If GroupingColumns = Undefined Then
		GroupingColumns = New Array;
	ElsIf TypeOf(GroupingColumns) = Type("String") Then
		GroupingColumns = StrSplit(GroupingColumns, ",", False);
	EndIf;
	
	TotalingColumns = New Array;
	
	MetadataOfDocument = Object.Metadata();
	
	For Each Column In MetadataOfDocument.TabularSections[TSName].Attributes Do
		If TypeOf(Column.Type.AdjustValue()) = Type("Number") Then
			If GroupingColumns.Find(Column.Name)  = Undefined Then
				TotalingColumns.Add(Column.Name);
			EndIf;
		Else
			GroupingColumns.Add(Column.Name);	
		EndIf;
	EndDo;
	
	TabularSection = Object[TSName]; // TabularSection - 
	TabularSection.GroupBy(StrConcat(GroupingColumns, ","), StrConcat(TotalingColumns,","));
	
EndProcedure

// Checks whether the function matches the passed selection
//
// Parameters:
//  Ref	 - AnyRef -
//  Filter	 - Structure of KeyAndValue - Where:
//  			* Key - String - The name of the props
//  			* Value - Arbitrary - a prop value, or an array of prop values
// 
// Returns:
//  Boolean 
//
Function LinkMatchesSelection(Ref, Filter) Export
	
	AttributesNames = New Array;
	
	For Each KeyValue In Filter Do
		
		AttributesNames.Add(KeyValue.Key);
		
	EndDo;

	AttributesValues = Common.ObjectAttributesValues(Ref, StrConcat(AttributesNames, ","));
	
	For Each KeyValue In Filter Do
		
		AttributeValue = AttributesValues[KeyValue.Key];
		
		If TypeOf(KeyValue.Value) = Type("Array")
			Or TypeOf(KeyValue.Value) = Type("FixedArray") Then
			
			If KeyValue.Value.Find(AttributeValue) = Undefined Then
				Return False;
			EndIf;
			
		ElsIf KeyValue.Value <> AttributeValue Then
			
			Return False;
			
		EndIf;
		
	EndDo;
	
	Return True;
	
EndFunction

// Checks whether the operations of the document being created correspond to the order operation.
//
// Parameters:
//	DirectLink    - DocumentRef - link to the order that is used to create the document.
//	DocumentName          - String      - name of the document that valid operations are defined for.
//	BusinessOperation - EnumRef.BusinessTransactions - business operation that is being checked for
//
// Returns:
//	Boolean - True, it is possible to create a document based on an order.
//
Function CheckOrderOperation(DirectLink, DocumentName, BusinessOperation = Undefined) Export
	
	ValidOperations = PermissibleBusinessOperationsOfDocument(DocumentName);
	
	If ValueIsFilled(BusinessOperation) Then
		DocumentOperation_ = BusinessOperation;
	Else
		DocumentOperation_  = Common.ObjectAttributeValue(DirectLink, "BusinessOperation");
	EndIf;
	
	If ValidOperations.Find(DocumentOperation_) = Undefined Then
		StringPattern = NStr("vi = 'Không thể thực hiện chứng từ ""%1"" trên cơ sở đơn %2 với thao tác ""%3"".';
							|ru = 'Невозможно оформить документ ""%1"" на основании распоряжения %2 с операцией ""%3"".';
							|en = 'Cannot register the ""%1"" document based on the %2 reference with the ""%3"" operation.'; fa = 'Cannot register the ""%1"" document based on the %2 reference with the ""%3"" operation.';
							|it = 'Impossibile formalizzare il documento ""%1"" sulla base di riferimento %2 con operazione ""%3"".';
							|pl = 'Nie można sporządzić dokument ""%1"" na podstawie zamówienia %2 z operacją ""%3"".';
							|tr = '""%1"" belgesini ""%3"" işlemiyle %2 siparişe göre düzenlemek mümkün değil.'");
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(StringPattern,
											Metadata.Documents[DocumentName].Synonym,
											DirectLink,
											DocumentOperation_);
		
		CommonClientServer.MessageToUser(MessageText,DirectLink);
		
		Return False;
	Else
		Return True;
	EndIf;
	
EndFunction

// Returns an array with business operations that are allowed for the document by functional options.
//
// Parameters:
//	DocumentName - String - name of the document that valid operations are defined for
//
// Returns:
//	Array of EnumRef.BusinessTransactions -
//
Function PermissibleBusinessOperationsOfDocument(DocumentName) Export
	
	Query = New Query;
	Query.SetParameter("EmptyRefValue", Documents[DocumentName].EmptyRef());
	
	Query.Text = 
	"SELECT
	|	ISNULL(BusinessTransactionsSettingsFunctionalOptions.FunctionalOptionName, """") AS FunctionalOptionName,
	|	BusinessTransactionsSettingsDocuments.Ref.BusinessOperation                     AS BusinessOperation
	|FROM
	|	Catalog.BusinessTransactionsSettings.Documents AS BusinessTransactionsSettingsDocuments
	|		INNER JOIN Catalog.MetadataObjectIDs AS MetadataObjectIDs
	|		ON (BusinessTransactionsSettingsDocuments.MetadataObjectID = MetadataObjectIDs.Ref)
	|			AND (MetadataObjectIDs.EmptyRefValue = &EmptyRefValue)
	|
	|		LEFT JOIN Catalog.BusinessTransactionsSettings.FunctionalOptions AS BusinessTransactionsSettingsFunctionalOptions
	|		ON (BusinessTransactionsSettingsDocuments.Ref = BusinessTransactionsSettingsFunctionalOptions.Ref)
	|
	|ORDER BY
	|	FunctionalOptionName";
	
	Selection = Query.Execute().Select();
	
	ValidOperations = New ValueList;
	
	While Selection.NextByFieldValue("FunctionalOptionName") Do
		
		FullNameFO = StrTemplate("FunctionalOption.%1", Selection.FunctionalOptionName);
		ThereIsFO = ValueIsFilled(Selection.FunctionalOptionName)
			And Metadata.FindByFullName(FullNameFO) <> Undefined;
		If Not ThereIsFO
			Or GetFunctionalOption(Selection.FunctionalOptionName) Then
			
			While Selection.Next() Do
				If ValidOperations.FindByValue(Selection.BusinessOperation) = Undefined Then
					ValidOperations.Add(Selection.BusinessOperation);
				EndIf;
			EndDo;
			
		EndIf;
		
	EndDo;
	
	ValidOperations.SortByValue();
	
	Return ValidOperations.UnloadValues();
	
EndFunction

// Returns a description of the money field type.
//
// Parameters:
//  FieldSign - AllowedSign - acceptable sign of the money field (Any by default)
//
// Returns:
//  TypeDescription - Description of the money field type
//
Function MoneyFieldTypeDescription(FieldSign = Undefined) Export
	
	Return CurrencyRateOperations.MoneyFieldTypeDescription(FieldSign);
	
EndFunction

// Returns a description of the type of quantitative field.
//
// Parameters:
//  FieldSign - AllowedSign - acceptable sign of the quantitative field (Any by default)
//
// Returns:
//  TypeDescription - Description Of The Quantitative Field Type
//
Function DescriptionOfQuantitativeFieldType(Val FieldSign = Undefined) Export
	
	If FieldSign = Undefined Then
		FieldSign = AllowedSign.Any;
	EndIf;
	
	Return New TypeDescription("Number", New NumberQualifiers(15, 3, FieldSign));
	
EndFunction

// Returns the bit depth of the description of the money field type.
//
// Parameters:
//  FieldSign - AllowedSign	 - acceptable sign of the money field (Any by default)
// 
// Returns:
//  Structure - Keys:
// 		* Digits - Number -
//		* FractionDigits - Number -
//
Function BitDepthOfMoneyField(FieldSign = Undefined) Export
	
	Result = New Structure("Digits, FractionDigits");
	FillPropertyValues(Result, MoneyFieldTypeDescription(FieldSign).NumberQualifiers);
	
	Return Result;
	
EndFunction
 
// Returns the General object localization module by the full name of the metadata object.
//
// Parameters:
//  FullName - String - full name of the metadata object. Example: "Directory.Companies".
//
// Returns:
//  CommonModule - the general module of object localization.
//
Function GetLocalizationModule(FullName) Export
	NameOfLocalizationModule = "";
	NameParts = StrSplit(FullName, ".");
	If NameParts.Count() > 1 Then
		NameOfLocalizationModule = NameParts[1] + "Localization";
	Else
		NameOfLocalizationModule = FullName + "Localization";
	EndIf;
	GeneralLocalizationModule = Undefined;
	
	If Metadata.CommonModules.Find(NameOfLocalizationModule) <> Undefined Then
		GeneralLocalizationModule = Eval(NameOfLocalizationModule); // Calculating in a secure mode is not required, because the check is reliable.
	EndIf;
	
	If TypeOf(GeneralLocalizationModule) = Type("CommonModule") Then
		Return GeneralLocalizationModule
	Else
		Return Undefined
	EndIf
	
EndFunction

// Returns an array of unique values from a table column
//
// Parameters:
//  Table    - ValueTable - 
//	           - FormDataCollection - the table from which to select data
//  ColumnName - String - name of the column in the value table to select values from.
// 
// Returns:
//  Array of Arbitrary - A set of unique values.
//
Function UnloadColumnValues(Table, ColumnName) Export
	
	If TypeOf(Table) = Type("ValueTable") Then
		TableCopy_ = Table.Copy(, ColumnName);
	Else
		TableCopy_ = Table.Unload(, ColumnName);
	EndIf;
	
	TableCopy_.GroupBy(ColumnName);
	
	Return TableCopy_.UnloadColumn(0);
	
EndFunction

// Returns workplace parameters depending on the set selections for operations and document types.
//
// Parameters:
//  TableBusinessTransactionsAndDocumentTypes - ValueTable - table describing the metadata used in the workplace
//  DefaultFormAssignmentKey	 - String - a parameter that defines a section of the workplace, for example, " internal Traffic"
//  DefaultFormTitle		 - String - the default workplace title, for example, "Internal product movement".
// 
// Returns:
//  Structure - Contains keys:
//		* PurposeUseKey - String -
//		* WorkplaceTitle - String -
//
Function WorkplaceData(TableBusinessTransactionsAndDocumentTypes, DefaultFormAssignmentKey, DefaultFormTitle) Export
	
	SelectedBusinessTransactionsAndDocumentTypes = TableBusinessTransactionsAndDocumentTypes.Copy(New Structure("Filter",True),
		"PurposeUseKey,WorkplaceTitle");
	SelectedBusinessTransactionsAndDocumentTypes.GroupBy("PurposeUseKey,WorkplaceTitle");
	
	WorkplaceData = New Structure("PurposeUseKey,WorkplaceTitle",
		DefaultFormAssignmentKey, DefaultFormTitle);
		
	If SelectedBusinessTransactionsAndDocumentTypes.Count() = 1 Then
		If ValueIsFilled(SelectedBusinessTransactionsAndDocumentTypes[0].PurposeUseKey) Then
			WorkplaceData.PurposeUseKey = SelectedBusinessTransactionsAndDocumentTypes[0].PurposeUseKey;	
		EndIf;
		If ValueIsFilled(SelectedBusinessTransactionsAndDocumentTypes[0].WorkplaceTitle) Then
			WorkplaceData.WorkplaceTitle = SelectedBusinessTransactionsAndDocumentTypes[0].WorkplaceTitle;	
		EndIf;			
	EndIf;
	
	Return WorkplaceData;
	
EndFunction

// Adds columns to the value table
// 
// Parameters:
// 	Object - ValueTable, ValueTree - object to add columns to
// 	Columns - String - comma-separated column names.
Procedure AddColumns(Object, Columns) Export
	
	ColumnsArray1 = StrSplit(Columns, ",", False);
	For Each Column In ColumnsArray1 Do
		Object.Columns.Add(TrimAll(Column));
	EndDo;
	
EndProcedure

// Adds an entry to the value table
// 
// Parameters:
// 	Table - ValueTable - table of values to add the record to
// 	Value1 - Arbitrary - the value to be inserted in the corresponding column in the order in which it appears.
// 	Value2 - Arbitrary - the value to be inserted in the corresponding column in the order in which it appears.
// 	Value3 - Arbitrary - the value to be inserted in the corresponding column in the order in which it appears.
// 	Value4 - Arbitrary - the value to be inserted in the corresponding column in the order in which it appears.
// 	Value5 - Arbitrary - the value to be inserted in the corresponding column in the order in which it appears.
// 	Value6 - Arbitrary - the value to be inserted in the corresponding column in the order in which it appears.
// 	Value7 - Arbitrary - the value to be inserted in the corresponding column in the order in which it appears.
// 	Value8 - Arbitrary - the value to be inserted in the corresponding column in the order in which it appears.
// 	Value9 - Arbitrary - the value to be inserted in the corresponding column in the order in which it appears.
Procedure AddRecord(Table, Value1, Value2=Undefined, Value3=Undefined,
	Value4=Undefined, Value5=Undefined, Value6=Undefined, Value7=Undefined,
	Value8=Undefined, Value9=Undefined) Export
	
	NewRecord1 = Table.Add();
	NewRecord1[0] = Value1;
	If Value2 <> Undefined Then
		NewRecord1[1] = Value2;
	EndIf; 
	If Value3 <> Undefined Then
		NewRecord1[2] = Value3;
	EndIf;
	If Value4 <> Undefined Then
		NewRecord1[3] = Value4;
	EndIf;
	If Value5 <> Undefined Then
		NewRecord1[4] = Value5;
	EndIf;
	If Value6 <> Undefined Then
		NewRecord1[5] = Value6;
	EndIf;
	If Value7 <> Undefined Then
		NewRecord1[6] = Value7;
	EndIf;
	If Value8 <> Undefined Then
		NewRecord1[7] = Value8;
	EndIf;
	If Value9 <> Undefined Then
		NewRecord1[8] = Value9;
	EndIf;

EndProcedure

// Checks that the platform version used is not lower than the specified one.
//
// Parameters:
//	Version - String - platform version number.
//
// Returns:
//	Boolean - True if the version used is not younger than the one specified in the Version parameter.
//
Function PlatformVersionNotLowerThanSpecified(Version) Export
	
	SystemInfo = New SystemInfo;
	
	Return (CommonClientServer.CompareVersions(SystemInfo.AppVersion, Version) >= 0);
	
EndFunction

#Region SynchnonizationOfKeys

// Creates a list of key details in the key directory.
// If the directory is mapped to the information register used to search for the key,
// the key details correspond to changes in this information register.
//
// Parameters:
//  RegisterMetadata	- MetadataObjectInformationRegister -
// 
// Returns:
//  Map -
//
Function KeyDetailsOfKeyCatalogForInformationRegister(RegisterMetadata) Export
	
	Result = New Map;
	
	For Each Dimension In RegisterMetadata.Dimensions Do
		
		Result.Insert(Dimension.Name);	
		
	EndDo;
	
	Return Result;
	
EndFunction

// Prepares the object's additional Properties property for use by the procedure
// General purpose out.Sync keys. Must be called in the event Before writing the object.
//
// Parameters:
//  Object - DocumentObject -
//	       - CatalogObject - the object to be synchronized with the keys 
//  Parameters - Map of KeyAndValue - Where:
//		* Key - String - Full name of the key object to synchronize the object with. 
//				For Example, A Reference Book.Lucasentertainment
//				In the key Manager module, the export function Keyrequizits must be declared,
//				which returns a match with the names of the details that determine the uniqueness of the key.
//		* Value - Structure of KeyAndValue - Where:
//						** Key - String - Name of the item's details
//						** Value - String - name of the key detail. If empty, the Key is used.
//					- String -  the list of details separated by commas. The names of the object's details must match the names of the key's details 
Procedure PrepareDataForKeySynchronization(Object, Parameters) Export
	
	Object.AdditionalProperties.Insert("IsNew", Object.IsNew());
	
	ObjectMetadata = Object.Metadata();
		
	
	ReceivedDetails          = New Structure;
	KeySynchronizationSettings = New Map;
	EmptyPropsValues     = New Structure;
	
	For Each KeyValue In Parameters Do
		
		NormalizedDescriptionOfProps = New Structure;
		
		If TypeOf(KeyValue.Value) = Type("String") Then
			CurDetails_ = StrSplit(KeyValue.Value, ",");
			
			For Each ArrRow In CurDetails_ Do
				AttributeName = TrimAll(ArrRow);
				CheckUsageOfPropsGetEmptyValue(Object, ObjectMetadata, AttributeName, EmptyPropsValues);
				
				If EmptyPropsValues[AttributeName] <> "NotUsed" Then 
					ReceivedDetails.Insert(AttributeName,AttributeName);
					NormalizedDescriptionOfProps.Insert(AttributeName, AttributeName);
				EndIf;
				
			EndDo;
			
		ElsIf TypeOf(KeyValue.Value) = Type("Structure") Then
			For Each CurDetails_ In KeyValue.Value Do
				
				AttributeName = CurDetails_.Key;
				CheckUsageOfPropsGetEmptyValue(Object, ObjectMetadata, AttributeName, EmptyPropsValues);
				
				If EmptyPropsValues[AttributeName] <> "NotUsed" Then 
					
					ReceivedDetails.Insert(AttributeName, AttributeName);
					
					If ValueIsFilled(CurDetails_.Value) Then
						NormalizedDescriptionOfProps.Insert(AttributeName, CurDetails_.Value);
					Else
						NormalizedDescriptionOfProps.Insert(AttributeName, AttributeName);
					EndIf;
					
				EndIf;
				
			EndDo;
		Else
			ExceptionText = NStr("vi = 'Loại mô tả chi tiết không được hỗ trợ được đồng bộ hóa với khóa %KeyName%';
								|ru = 'Не поддерживаемый тип описания реквизитов, синхронизируемых с ключем %KeyName%';
								|en = 'Not supported type of description of attributes synchronized with the %KeyName% key'; fa = 'Not supported type of description of attributes synchronized with the %KeyName% key';
								|it = 'Tipo di descrizione del requisito sincronizzabile con la chiave  %KeyName% non supportato';
								|pl = 'Nieobsługiwany typ opisu szczegółów zsynchronizowany z kluczem %KeyName%';
								|tr = '%KeyName% anahtarıyla senkronize edilen desteklenmeyen öznitelik ayrıntılar tipi'");
			ExceptionText = StrReplace(ExceptionText, "%KeyName%", KeyValue.Key);
			Raise ExceptionText;
		EndIf;	
		
		KeySynchronizationSettings.Insert(KeyValue.Key, NormalizedDescriptionOfProps); 
		
	EndDo;
	
	Object.AdditionalProperties.Insert("KeySynchronizationSettings", KeySynchronizationSettings);
	
	If Object.AdditionalProperties.IsNew Then
		
		For Each KeyValue In ReceivedDetails Do
			Object.AdditionalProperties.Insert(KeyValue.Key + "BeforeRecording", EmptyPropsValues[KeyValue.Key]);
		EndDo;
		
	Else
		
		ValuesOfBankingDetailsBeforeRecording = Common.ObjectAttributesValues(Object.Ref, ReceivedDetails);
		
		For Each KeyValue In ValuesOfBankingDetailsBeforeRecording Do
			Object.AdditionalProperties.Insert(KeyValue.Key + "BeforeRecording", KeyValue.Value);
		EndDo;
		
	EndIf;
	
EndProcedure

// Returns the value of the "before recording" attribute stored in the additional properties using the method See PrepareDataForKeySynchronization.
// 
// Parameters:
// 	AttributeName - String - Name of the item's details
// 	AdditionalProperties - Structure - Additional object properties
//
// Returns:
// 	Arbitrary - the value of the props before recording
Function ValueOfPropsBeforeWritingFromAdditionalProperties(AttributeName, AdditionalProperties) Export
	
	PropertyName = AttributeName + "BeforeRecording";
	If AdditionalProperties.Property(PropertyName) Then
		Return AdditionalProperties[PropertyName];
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// Returns:
// 	Structure - LongDesc:
// * ObjectManager - CatalogManager -
// * KeyPropsToCreate - Undefined -
// * KeyAttributes - Structure -
// * ChangedBankingDetails_1 - Structure -
// * FullName - String -
Function KeyDetails()
	
	KeyDetails = New Structure;
	KeyDetails.Insert("FullName", "");
	KeyDetails.Insert("ChangedBankingDetails_1", New Structure);
	KeyDetails.Insert("KeyAttributes", New Structure);
	KeyDetails.Insert("KeyPropsToCreate", Undefined); // if you need to create a key, here is the name of the key props
	KeyDetails.Insert("ObjectManager", Undefined); // if you need to create a key, here is the name of the key props
	
	Return KeyDetails;
	
EndFunction

// Returns:
// Map of KeyAndValue - Where:
// 			* Key - String - 
// 			* Value - See KeyDetails
Function KeysToUpdate()
	Return New Map()
EndFunction

// Synchronizes the values of the object's details with the keys.
// Must be called in the event when writing an object. At
// the same time, the General purpose Out procedure must be called in the event before Writing this object.Prepare data for key synchronization.
//
// If there is only one key detail in the key, the existence of the key is checked, and if there is no key, it is created.
//
// Parameters:
//  Object - DocumentObject - 
//	       - CatalogObject - the object to be synchronized with the keys 
//
Procedure SyncKeys(Object) Export
	
	KeySynchronizationSettings = Object.AdditionalProperties.KeySynchronizationSettings;
	KeysToUpdate = KeysToUpdate(); // The key is the name of the object, the value is the structure with the changed Attributes
	
	For Each SynchronizationParameter In KeySynchronizationSettings Do
		
		KeyDetails = KeyDetails();
		
		KeyDetails.FullName = SynchronizationParameter.Key;
		
		KeyDetails.ObjectManager = Common.ObjectManagerByFullName(KeyDetails.FullName);
		
		KeyCatalogMetadata = Metadata.FindByFullName(KeyDetails.FullName); // MetadataObjectCatalog - 
		
		KeyAttributes = KeyDetails.ObjectManager.KeyAttributes();
		
		For Each AttributeName In KeyAttributes Do
			AttributeMetadata = KeyCatalogMetadata.Attributes.Find(AttributeName.Key);
			
			If AttributeMetadata = Undefined Then
				
				For Each StandardAttribute In KeyCatalogMetadata.StandardAttributes Do
					If StandardAttribute.Name = AttributeName.Key Then
						AttributeMetadata = StandardAttribute;
						Break;
					EndIf;
				EndDo;
				
				If AttributeMetadata = Undefined Then
					ExceptionText = NStr("vi = 'Đối với khóa %KeyName%, không tìm thấy thuộc tính khóa %NameProps%. Lỗi trong mô tả chi tiết chính';
										|ru = 'Для ключа %KeyName% ключевой реквизит %NameProps% не найден. Ошибка в описании ключевых реквизитов';
										|en = 'The %KeyName% key attribute for the %NameProps% key is not found. An error occurred in the key attributes description'; fa = 'The %KeyName% key attribute for the %NameProps% key is not found. An error occurred in the key attributes description';
										|it = 'Per la chiave %KeyName% non è stato trovato il requisito chiave %NameProps% . Errore nella descrizione dei requisiti chiave';
										|pl = 'Dla klucza %KeyName% kluczowy atrybut %NameProps% nie znaleziono. Błąd w opisie kluczowych atrybutów';
										|tr = '%KeyName% anahtarı için, %NameProps% anahtar özniteliği bulunamadı. Önemli özniteliklerin ayrıntılarında hata'");
					ExceptionText = StrReplace(ExceptionText, "%KeyName%", KeyDetails.FullName);
					ExceptionText = StrReplace(ExceptionText, "%NameProps%", AttributeName.Key);
					Raise ExceptionText;
				EndIf;	
				
			EndIf;	
			
			KeyDetails.KeyAttributes.Insert(AttributeName.Key, AttributeMetadata);
			
		EndDo;
		
		If KeyDetails.KeyAttributes.Count() = 0 Then
			ExceptionText = NStr("vi = 'Đối với khóa %KeyName% không đặt chi tiết chính';
								|ru = 'Для ключа %KeyName% не заданы ключевые реквизиты';
								|en = 'Key attributes are not specified for the %KeyName% key'; fa = 'Key attributes are not specified for the %KeyName% key';
								|it = 'Per la chiave %KeyName% non sono indicati i requisiti chiave';
								|pl = 'Dla klucza %KeyName% nie podano kluczowych atrybutów';
								|tr = '%KeyName% anahtarı için anahtar gereksinimleri ayarlanmadı'");
			ExceptionText = StrReplace(ExceptionText, "%KeyName%", KeyDetails.FullName);
			Raise ExceptionText;
		ElsIf KeyDetails.KeyAttributes.Count() = 1 Then
			// If there is only one key detail, then the key must be generated when creating the directory element
			For Each AttributeName In KeyDetails.KeyAttributes Do
				// According to the index in accordance with the first element can not be obtained, therefore such a cycle
				KeyDetails.KeyPropsToCreate = AttributeName.Key;
			EndDo;
		EndIf;
		
		If Object.AdditionalProperties.IsNew Then
			
			If KeyDetails.KeyPropsToCreate <> Undefined Then
				
				For Each AttributeDetails In SynchronizationParameter.Value Do
					KeyDetails.ChangedBankingDetails_1.Insert(AttributeDetails.Key, AttributeDetails.Value);	
				EndDo;
				
				KeysToUpdate.Insert(KeyDetails.FullName, KeyDetails);
				
			EndIf;
						
		Else
			
			ThereAreChangedDetails = False;
			
			For Each AttributeDetails In SynchronizationParameter.Value Do
				
				ValueOfPropsBeforeRecording = ValueOfPropsBeforeWritingFromAdditionalProperties(AttributeDetails.Key, Object.AdditionalProperties);
				PropsChanged = Object[AttributeDetails.Key] <> ValueOfPropsBeforeRecording;
				
				If PropsChanged Then
					ThereAreChangedDetails = True;
					KeyDetails.ChangedBankingDetails_1.Insert(AttributeDetails.Key, AttributeDetails.Value);
				ElsIf KeyDetails.KeyPropsToCreate <> Undefined Then
					// If you need to create a key in its absence, then you need to have all the details, not just the changed ones
					// At the same time, if nothing has changed at all in the directory, but we will not read the key table in vain -
					// in this case, the description of the key will not be added later to the update key.
					KeyDetails.ChangedBankingDetails_1.Insert(AttributeDetails.Key, AttributeDetails.Value);
				EndIf;
				
			EndDo;
			
			If ThereAreChangedDetails Then 
				KeysToUpdate.Insert(KeyDetails.FullName, KeyDetails);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If KeysToUpdate.Count() = 0 Then
		Return;
	EndIf;
	
	QueryTextTemplate2 =
	"SELECT
	|	Keys.Ref AS Ref,
	|	&ConditionsForChangingBankingDetails AS DetailsChanged_
	|FROM
	|	FullTableName AS Keys
	|WHERE
	|	(&KeySearchCriteria)
	|	AND (&ConditionsForChangingBankingDetails
	|		OR (&ConditionForChangingDeleteTag)
	|		OR &CreateIfMissing)";
	
	CatalogValueType = TypeOf(Object.Ref);
	
	Block = New DataLock;
	Query = New Query;
	
	KeyRequestTexts = New Array;
	RequestNumberKeyObjectName = New Map;
	Counter = 0;
	
	For Each UpdateKey In KeysToUpdate Do
		
		KeyDetails = UpdateKey.Value;
		
		KeySearchCriteria = New Array;
		ConditionsForChangingBankingDetails = New Array;
		ConditionForChangingDeleteTag = New Array;
		
		For Each AttributeName In KeyDetails.KeyAttributes Do
			
			If AttributeName.Value.Type.ContainsType(CatalogValueType) Then
				KeySearchCriteria.Add("Keys." + AttributeName.Value.Name + " = &Ref ");
				// All key details must be added to the lock fields
				LockItem = Block.Add(KeyDetails.FullName); 
				LockItem.SetValue(AttributeName.Value.Name, Object.Ref);
			EndIf;
			
		EndDo;
			
		If KeySearchCriteria.Count() = 0 Then
			ExceptionText = NStr("vi = 'Danh mục %CatalogName% không hiển thị %KeyName% (chuyển giá trị %Value%)';
								|ru = 'Справочник %CatalogName% не отражается в ключе %KeyName% (передано значение %Value%)';
								|en = 'The %CatalogName% catalog is not recorded in the %KeyName% key (the %Value% value passed)'; fa = 'The %CatalogName% catalog is not recorded in the %KeyName% key (the %Value% value passed)';
								|it = 'La directory %CatalogName% non è riflessa nella chiave %KeyName% (valore trasferito %Value%)';
								|pl = 'Katalog %CatalogName% nie jest odzwierciedlany w kluczu %KeyName% (przekazano wartość %Value%)';
								|tr = '%CatalogName% katalogu, %KeyName% anahtarına yansıtılmıyor (%Value% değeri iletildi)'");
			ExceptionText = StrReplace(ExceptionText, "%CatalogName%", Metadata.FindByType(CatalogValueType).FullName());
			ExceptionText = StrReplace(ExceptionText, "%KeyName%", KeyDetails.FullName);
			ExceptionText = StrReplace(ExceptionText, "%Value%", String(Object.Ref));
			
			Raise ExceptionText;
		EndIf;
		
		For Each AttributeDetails In KeyDetails.ChangedBankingDetails_1 Do
			
			If AttributeDetails.Key = "DeletionMark"
				And KeyDetails.KeyPropsToCreate = Undefined Then
				// The key must be marked for deletion if at least one value from the key details
				// is marked for deletion.
				// The behavior is as follows:
				//	- we mark the directory element for deletion
				//	      - we mark all keys that have not yet been marked for deletion
				//  - remove the deletion mark from the directory element
				//        - if the key has been marked for deletion, then we remove it if all the values of the key details are not marked for deletion
				// At the same time, if the correspondence of the key-directory is one to one, then we check the deletion mark
				// in the same way with all other details
				
				If Object.DeletionMark Then
					ConditionForChangingDeleteTag.Add("NOT Keys.DeletionMark ");
				Else
					ConditionForChangingDeleteTag.Add("Keys.DeletionMark ");
					
					For Each AttributeName In KeyDetails.KeyAttributes Do
						
						ThereIsLinkMarkedDelete = False;
						TypesOfPropsValues = AttributeName.Value.Type.Types();
						
						For Each AttributeValueType In TypesOfPropsValues Do
							If Common.IsReference(AttributeValueType)
								And Not Common.IsEnum(Metadata.FindByType(AttributeValueType)) Then
								
								ThereIsLinkMarkedDelete = True;
								Break;
								
							EndIf;
						EndDo;		
						
						If ThereIsLinkMarkedDelete Then
							ConditionForChangingDeleteTag.Add("NOT ISNULL(Keys." + AttributeName.Key + ".DeletionMark, FALSE) ");
						EndIf;
						
					EndDo;
					
				EndIf;
				
			Else
				ConditionsForChangingBankingDetails.Add(" Keys." + AttributeDetails.Value + " <> &" + AttributeDetails.Key + " ");
				Query.SetParameter(AttributeDetails.Key, Object[AttributeDetails.Key]);
			EndIf;
			
		EndDo;
		
		QueryText = StrReplace(QueryTextTemplate2, "FullTableName", KeyDetails.FullName); 
		QueryText = StrReplace(QueryText, "&KeySearchCriteria", StrConcat(KeySearchCriteria, " OR ")); 
		
		If ConditionForChangingDeleteTag.Count() = 0
			And ConditionsForChangingBankingDetails.Count() = 0 Then
			ExceptionText = NStr("vi = 'Lỗi thuật toán đồng bộ %KeyName% giá trị %Value% từ danh mục %CatalogName%';
								|ru = 'Ошибка в алгоритме синхронизации с ключем %KeyName% значения %Value% из справочника %CatalogName%';
								|en = 'An error occurred in the algorithm of synchronization with the %KeyName% key of the %Value% value from the %CatalogName% catalog'; fa = 'An error occurred in the algorithm of synchronization with the %KeyName% key of the %Value% value from the %CatalogName% catalog';
								|it = 'Errore nell''algoritmo di sincronizzazione con la chiave %KeyName% del valore %Value% dalla directory %CatalogName%';
								|pl = 'Błąd w algorytmie synchronizacji z kluczem %KeyName% wartości %Value% z katalogu %CatalogName%';
								|tr = '%CatalogName% katalogundan %Value% değerinin %KeyName% anahtarıyla senkronizasyon algoritmasında hata'");
			ExceptionText = StrReplace(ExceptionText, "%CatalogName%", Metadata.FindByType(CatalogValueType).FullName());
			ExceptionText = StrReplace(ExceptionText, "%KeyName%", KeyDetails.FullName);
			ExceptionText = StrReplace(ExceptionText, "%Value%", String(Object.Ref));
			
			Raise ExceptionText;
		EndIf;
		
		If ConditionForChangingDeleteTag.Count() > 0 Then
			QueryText = StrReplace(QueryText, "&ConditionForChangingDeleteTag", StrConcat(ConditionForChangingDeleteTag, " And "));
		Else
			QueryText = StrReplace(QueryText, "&ConditionForChangingDeleteTag", "FALSE");
		EndIf;
		
		If ConditionsForChangingBankingDetails.Count() > 0 Then
			QueryText = StrReplace(QueryText, "&ConditionsForChangingBankingDetails", StrConcat(ConditionsForChangingBankingDetails, " OR "));
		Else
			QueryText = StrReplace(QueryText, "&ConditionsForChangingBankingDetails", "FALSE");
		EndIf;	
			
		If KeyDetails.KeyPropsToCreate <> Undefined Then
			QueryText = StrReplace(QueryText, "&CreateIfMissing", "TRUE");
		Else
			QueryText = StrReplace(QueryText, "&CreateIfMissing", "FALSE");
		EndIf;
		
		KeyRequestTexts.Add(QueryText);
		RequestNumberKeyObjectName.Insert(Counter, KeyDetails.FullName); 
		
		Counter = Counter + 1;
		
	EndDo;
	
	Query.SetParameter("Ref", Object.Ref);
	Query.Text = StrConcat(KeyRequestTexts, Common.QueryBatchSeparator());
	
	SetPrivilegedMode(True);
	Block.Lock();
	QueryResults = Query.ExecuteBatch();
	
	For IndexOf = 0 To QueryResults.UBound() Do
		
		KeyDetails = KeysToUpdate[RequestNumberKeyObjectName.Get(IndexOf)]; // See KeyDetails
		QueryResult = QueryResults[IndexOf];
		
		If QueryResult.IsEmpty() Then
			
			If KeyDetails.KeyPropsToCreate <> Undefined Then
				
				If StrFind(Upper(KeyDetails.FullName), "DOCUMENT.") <> 0 Then
					KeyObject_ = KeyDetails.ObjectManager.CreateDocument();
					KeyObject_.Date = CurrentSessionDate();
				Else
					KeyObject_ = KeyDetails.ObjectManager.CreateItem();
				EndIf;
				
				KeyObject_[KeyDetails.KeyPropsToCreate] = Object.Ref;
				
				For Each Attribute In KeyDetails.ChangedBankingDetails_1 Do
					KeyObject_[Attribute.Value] = Object[Attribute.Key];
				EndDo;
				
				KeyObject_.AdditionalProperties.Insert("SyncingKeyWithValue");
				KeyObject_.Write();
				
			Else
				Continue;
			EndIf;
			
		Else
			
			SelectionFromRequest = QueryResult.Select();
			While SelectionFromRequest.Next() Do
				KeyObject_ = SelectionFromRequest.Ref.GetObject();
				For Each Attribute In KeyDetails.ChangedBankingDetails_1 Do
					KeyObject_[Attribute.Value] = Object[Attribute.Key];
				EndDo;
				
				KeyObject_.AdditionalProperties.Insert("SyncingKeyWithValue");
				KeyObject_.Write();
			EndDo;
			
		EndIf;
		
	EndDo;
	SetPrivilegedMode(False);
	
EndProcedure

#EndRegion

#Region TableSearch

// Numbers rows in the value table. The Ordinal number column is used for numbering.
// If a column with this name is not present in the passed table, it will be added.
//
// Parameters:
//  Table	- ValueTable - a table whose rows will be numbered.
//
Procedure AddSequenceNumberOfRowsToTable(Table) Export
	
	NumberValueTable(Table, "SequenceNumber");
	
EndProcedure

// Fills in the value of the Ordinal number column in a new row of the value table,
// the rows of which are numbered (See AddSequenceNumberOfRowsToTable)
// .
//
// Parameters:
//  Table		 - ValueTable - a table with numbered rows.
//  NewRow	 - ValueTableRow - the line where you need to fill in the sequence number.
//
Procedure FillInSequenceNumberInNewLine(Table, NewRow) Export
	
	NewRow.SequenceNumber = Table.Count() + 1;
	
EndProcedure

// Searches for rows in the table of values while preserving their order.
//
// Parameters:
//  Table				 - ValueTable - the table to search in.
//  SearchCondition		 - Structure - the search condition of the rows.
//  LinesAreNumbered	 - Boolean - True if the table rows were previously numbered
//		(See AddSequenceNumberOfRowsToTable).
// 
// Returns:
//  Array - found strings.
//
Function FindRowsWithPreservingOrder(Table, SearchCondition, LinesAreNumbered = False) Export
	
	FoundRows = Table.FindRows(SearchCondition);
	
	If FoundRows.Count() > 1 Then
		
		If LinesAreNumbered Then
			
			Result = ArrangeNumberedRows(Table, FoundRows);
			
		Else
			
			Result = ArrangeNonNumberedRows(Table, FoundRows);
			
		EndIf;
		
	Else
		
		Result = FoundRows;
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

// Returns the values of requisites transferred to the links, if the link is empty - returns the default value 
// for each type of requisite.
//
// Parameters:
//	Ref - DocumentRef - link to the information base object.
//	Attributes	 - String -
//	             - Array of String - the names of the props separated by commas or an array of the names of the props.
//
// Returns:
//	Structure - a structure whose properties are the reference details of the information base object,
//							and the values are the values of the reference details.
//
Function DefaultValuesForItemDetails(Ref, Attributes) Export
	
	If ValueIsFilled(Ref) Then
		Result = Common.ObjectAttributesValues(Ref, Attributes);
	Else
		If TypeOf(Attributes) = Type("String") Then 
			Result = New Structure(Attributes);
		ElsIf TypeOf(Attributes) = Type("Array") Then
			Result = New Structure(StrConcat(Attributes, ","));
		Else
			ExceptionText = NStr("vi = 'Loại tham số ""Mục tin"" không hợp lệ';
								|ru = 'Неверный тип параметра ""Реквизиты""';
								|en = 'Invalid type of ""Attributes"" parameter'; fa = 'Invalid type of ""Attributes"" parameter';
								|it = 'Tipo di parametro ""Requisiti"" non corretto';
								|pl = 'Nieprawidłowy typ parametru ""Rekwizyty""';
								|tr = 'Yanlış ""Öznitelikler"" parametresi tipi'");
			Raise ExceptionText;
		EndIf;
		
		ObjectMetadata = Metadata.FindByType(TypeOf(Ref)); // MetadataObjectDocument - 
		
		If ObjectMetadata = Undefined Then
			ExceptionText = NStr("vi = 'Giá trị được truyền không phải là một liên kết';
								|ru = 'Переданное значение не является ссылкой';
								|en = 'The transferred value is not a reference'; fa = 'The transferred value is not a reference';
								|it = 'Valore trasmesso non è un link';
								|pl = 'Wysłana wartość nie jest odnośnikiem';
								|tr = 'Transfer edilen değer bağlantı değil'");
			Raise ExceptionText;
		EndIf;
		
		For Each KeyValue In Result Do
			
			AttributeMetadata = ObjectMetadata.Attributes.Find(KeyValue.Key);
			
			If AttributeMetadata = Undefined Then
				
				For Each StandardAttribute In  ObjectMetadata.StandardAttributes Do
					If StandardAttribute.Name = KeyValue.Key Then
						AttributeMetadata = StandardAttribute;
						Break;
					EndIf;
				EndDo;
				
				If AttributeMetadata = Undefined Then 
					
					ExceptionText = NStr("vi = 'Mục tin %AttributeName% không tim thấy';
										|ru = 'Реквизит %AttributeName% не найден';
										|en = 'Attribute %AttributeName% is not found'; fa = 'Attribute %AttributeName% is not found';
										|it = 'Il requisito %AttributeName% non trovato';
										|pl = 'Rekwizyt %AttributeName% nie został znaleziony';
										|tr = '%AttributeName% özniteliği bulunamadı'");
					ExceptionText = StrReplace(ExceptionText, "%AttributeName%", KeyValue.Key);
					Raise ExceptionText;
				EndIf;
				
			EndIf;
			
			Result[KeyValue.Key] = AttributeMetadata.Type.AdjustValue();	
			
		EndDo;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Parameters:
// 	Ref - See Common.ObjectAttributeValue.Ref
// 	AttributeName - See Common.ObjectAttributeValue.AttributeName
// Returns:
//  Boolean - the value of the Attribute read from the information base by reference to the object
//  		See Common.ObjectAttributeValue.If the received value is not of the Boolean type, 
//  		the False value is returned.
//
Function ValueOfBooleanObjectSProps(Ref, AttributeName) Export
	SetPrivilegedMode(True);
	Result = Common.ObjectAttributeValue(Ref, AttributeName);
	If TypeOf(Result) <> Type("Boolean") Then
		Result = False;
	EndIf;
	SetPrivilegedMode(False);	
	Return Result
EndFunction

// Bypasses the details and standard details of the metadata object and creates a structure with the same fields.
//
// Parameters:
//	MetadataObject - MetadataObject - the metadata object used as the source for copying properties.
//
// Returns:
//	Structure - a structure whose properties are the details of the copy source.
//
Function StructureWithMetadataObjectProperties(MetadataObject) Export
	
	StructureWithMetadataObjectProperties = New Structure;
	
	For Each Attribute In MetadataObject.Attributes Do
		StructureWithMetadataObjectProperties.Insert(Attribute.Name, Attribute.Type.AdjustValue());
	EndDo;
	
	For Each Attribute In MetadataObject.StandardAttributes Do
		StructureWithMetadataObjectProperties.Insert(Attribute.Name, Attribute.Type.AdjustValue());
	EndDo;
	
	Return StructureWithMetadataObjectProperties;
	
EndFunction

// Get the maximum date of documents of the same type.
// 
// Parameters:
//  DocumentsArray - Array of DocumentRef - Array of documents of the same type
// 
// Returns:
//  Date - maximum date of documents if a non-empty array was passed and the current session date if empty
Function GetMaximumDateOfDocuments(DocumentsArray) Export
	
	MaxDate = CurrentSessionDate();

	If DocumentsArray.Count() = 0 Then
		Return MaxDate;
	EndIf;
	
	QueryText = "SELECT
	|	MAX(Document.Date) AS Date
	|FROM
	|	&FullMetadataObjectName AS Document
	|WHERE
	|	Document.Ref IN (&DocumentsArray)";
	
	QueryText = StrReplace(QueryText, "&FullMetadataObjectName", DocumentsArray[0].Metadata().FullName());
	
	Query = New Query;
	Query.Text = QueryText;
	
	Query.SetParameter("DocumentsArray", DocumentsArray);

	Result = Query.Execute().Unload();
	
	If Result.Count() Then
		MaxDate = Result[0].Date;
	EndIf;
	
	Return MaxDate;
	
EndFunction

// Stops code execution for a specified time.
// It can only be used in a background task.
//
// Parameters:
//  Seconds - Number - waiting time in seconds.
//
Procedure Pause(Seconds) Export
	
	CurrentInfobaseSession1 = GetCurrentInfoBaseSession();
	BackgroundJob = CurrentInfobaseSession1.GetBackgroundJob();
	
	If BackgroundJob = Undefined Then
		MethodName = "TMCommonUse.Pause";
		WriteLogEvent(
			NStr("vi = 'Lỗi thực hiện';
				|ru = 'Ошибка выполнения';
				|en = 'Runtime error'; fa = 'خطای زمان اجرا';
				|it = 'Errore nell''esecuzione';
				|pl = 'Błąd wykonania';
				|tr = 'Uygulama hatası'"), 
			EventLogLevel.Error, 
			, 
			, 
			StrTemplate(NStr("vi = '%1 chỉ cho phép sử dụng trong nhiệm vụ nền.';
							|ru = '%1 разрешается использовать только в фоновом задании.';
							|en = 'You can use %1 only in a background job.'; fa = 'You can use %1 only in a background job.';
							|it = '%1 разрешается использовать только в фоновом задании.';
							|pl = 'You can use %1 only in a background job.';
							|tr = '%1 yalnızca bir arka plan işinde kullanılabilir.'"), MethodName));
		Parameters = New Array;
		Parameters.Add(Seconds);
		BackgroundJob = BackgroundJobs.Execute("TMCommonUse.Pause", Parameters);
	EndIf;
		
	BackgroundJob.WaitForExecutionCompletion(Seconds);
	
EndProcedure

#EndRegion

#Region FormSettings

// Sets parameters for the form's contextual functional options.
//
// Parameters:
// 	Form - ClientApplicationForm - 
// 	SetupParameters - Structure -
//
Procedure ConfigureFormByParameters(Form, SetupParameters) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	QueryText = 
	"SELECT
	|	FormSettings.Ref
	|FROM
	|	Catalog.ParametersOfContextFunctionalOptions AS FormSettings
	|WHERE
	|	TRUE";
	
	For Each SettingParameter In SetupParameters Do
	
		QueryText = QueryText + " 
		|	AND FormSettings." + SettingParameter.Key + " = &" + SettingParameter.Key;
		Query.SetParameter(SettingParameter.Key, SettingParameter.Value);
	
	EndDo;
	
	Query.Text = QueryText;
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		
		Setting = Selection.Ref;
		
	Else
		
		CatalogObject = Catalogs.ParametersOfContextFunctionalOptions.CreateItem();
		
		FillPropertyValues(CatalogObject, SetupParameters);
		
		CatalogObject.Write();
		
		Setting = CatalogObject.Ref;
		
	EndIf;
	
	SetPrivilegedMode(False);
	
	Form.SetFormFunctionalOptionParameters(New Structure("FormSettingsItem", Setting));
	
EndProcedure

// Parameters:
// 	Form - ClientApplicationForm - 
// 	NameOfFOOfUseOfPPD - String -
//
Procedure InitializeFormDetailsForFullTextSearch(Form, NameOfFOOfUseOfPPD) Export
	
	Form.FileInfobase      = Common.FileInfobase();
	Form.UseFullTextSearch = GeneralPurposeTMServerCall.FullTextSearchIsUsed(NameOfFOOfUseOfPPD);
	
	If Form.UseFullTextSearch Then
			
		Form.FullTextSearchIndexIsUpToDate = FullTextSearchServer.SearchIndexIsRelevant();
		
	EndIf;
	
EndProcedure

// Saves the data necessary for the operation of the mechanism in the details of the form's cache data.
// 
// Parameters:
// 	Form - ClientApplicationForm - Form
// 	MechanismName - String - The name of the mechanism that stores the data
// 	DataToCache - Arbitrary - Cached data
//
Procedure SaveEngineDataToFormCache(Form, MechanismName, DataToCache) Export
	
	If Not CommonClientServer.HasAttributeOrObjectProperty(Form, "MechanismDataCache") Then
		AttributesToBeAdded = New Array;
		AttributesToBeAdded.Add(New FormAttribute("MechanismDataCache", New TypeDescription("Undefined")));
		Form.ChangeAttributes(AttributesToBeAdded);
		Form.MechanismDataCache = New Structure;
	EndIf;
	Form.MechanismDataCache.Insert(MechanismName, DataToCache);
	
EndProcedure

// Removes the duplicate array elements.
//
// Parameters:
// 	Array - Array - 
//	DoNotUseUndefined - Boolean - 
// 
// Returns:
// 	Array - The original array, but without duplicate elements
//
Function DeleteDuplicateElementsFromArray(Array, DoNotUseUndefined = False) Export
	
	CatalogsTypesDetails  = Catalogs.AllRefsType(); 
	DocumentsTypesDetails    = Documents.AllRefsType(); 
	CCTTypesDetails          = ChartsOfCharacteristicTypes.AllRefsType(); 
	ChartsOfAccountsTypesDetails  = ChartsOfAccounts.AllRefsType(); 
	ChartsOfCalculationsTypesDetails = ChartsOfCalculationTypes.AllRefsType(); 
	
	If TypeOf(Array) = Type("Array") Then 
		
		AlreadyInArray 		   = New Map; 
		WasUndefined 	   = False;
		ArrayElementsCount = Array.Count(); 
		
		For ReverseIndex = 1 To ArrayElementsCount Do 
			
			ArrayElement = Array[ArrayElementsCount - ReverseIndex]; 
			ElementType    = TypeOf(ArrayElement); 
			
			If ArrayElement = Undefined Then
				
				If WasUndefined Or DoNotUseUndefined Then
					Array.Delete(ArrayElementsCount - ReverseIndex); 
				Else
					WasUndefined = True;
				EndIf;
				
				Continue;
				
			ElsIf CatalogsTypesDetails.ContainsType(ElementType) 
			 Or DocumentsTypesDetails.ContainsType(ElementType) 
			 Or CCTTypesDetails.ContainsType(ElementType) 
			 Or ChartsOfAccountsTypesDetails.ContainsType(ElementType) 
			 Or ChartsOfCalculationsTypesDetails.ContainsType(ElementType) Then 
				
				ElementID = String(ArrayElement.UUID()); 
				
			Else 
				
				ElementID = ArrayElement; 
				
			EndIf; 
			
			If AlreadyInArray[ElementID] = True Then 
				Array.Delete(ArrayElementsCount - ReverseIndex); 
			Else 
				AlreadyInArray[ElementID] = True; 
			EndIf; 
			
		EndDo;      
		
	EndIf;
	
	Return Array;
	
EndFunction

// The function returns the key representation
// Parameters:
//	KeyValue						- Key
//
// Returns:
//	String - Representation of the key.
//
Function KeyPresentation_(KeyValue) Export
	
	If String(Key._1) = String(KeyValue) Then
		Return "1";
	ElsIf String(Key._2) = String(KeyValue) Then
		Return "2";
	ElsIf String(Key._3) = String(KeyValue) Then
		Return "3";
	ElsIf String(Key._4) = String(KeyValue) Then
		Return "4";
	ElsIf String(Key._5) = String(KeyValue) Then
		Return "5";
	ElsIf String(Key._6) = String(KeyValue) Then
		Return "6";
	ElsIf String(Key._7) = String(KeyValue) Then
		Return "7";
	ElsIf String(Key._8) = String(KeyValue) Then
		Return "8";
	ElsIf String(Key._9) = String(KeyValue) Then
		Return "9";
	ElsIf String(Key.Num0) = String(KeyValue) Then
		Return "Num 0";
	ElsIf String(Key.Num1) = String(KeyValue) Then
		Return "Num 1";
	ElsIf String(Key.Num2) = String(KeyValue) Then
		Return "Num 2";
	ElsIf String(Key.Num3) = String(KeyValue) Then
		Return "Num 3";
	ElsIf String(Key.Num4) = String(KeyValue) Then
		Return "Num 4";
	ElsIf String(Key.Num5) = String(KeyValue) Then
		Return "Num 5";
	ElsIf String(Key.Num6) = String(KeyValue) Then
		Return "Num 6";
	ElsIf String(Key.Num7) = String(KeyValue) Then
		Return "Num 7";
	ElsIf String(Key.Num8) = String(KeyValue) Then
		Return "Num 8";
	ElsIf String(Key.Num9) = String(KeyValue) Then
		Return "Num 9";
	ElsIf String(Key.NumAdd) = String(KeyValue) Then
		Return "Num +";
	ElsIf String(Key.NumDecimal) = String(KeyValue) Then
		Return "Num .";
	ElsIf String(Key.NumDivide) = String(KeyValue) Then
		Return "Num /";
	ElsIf String(Key.NumMultiply) = String(KeyValue) Then
		Return "Num *";
	ElsIf String(Key.NumSubtract) = String(KeyValue) Then
		Return "Num -";
	Else
		Return String(KeyValue);
	EndIf;
	
EndFunction

// The function returns the key representation
// Parameters:
//	Shortcut	 - Shortcut - Keyboard shortcut to create a view for
//	WithoutBrackets - Boolean - Flag indicating that the view should be formed without parentheses.
//
// Returns:
//	String - Keyboard shortcut representation.
//
Function KeyboardShortcutPresentation(Shortcut, WithoutBrackets = False) Export
	
	If Shortcut.Key = Key.None Then
		Return "";
	EndIf;
	
	Description = ?(WithoutBrackets, "", "(");
	If Shortcut.Ctrl Then
		Description = Description + "Ctrl+"
	EndIf;
	If Shortcut.Alt Then
		Description = Description + "Alt+"
	EndIf;
	If Shortcut.Shift Then
		Description = Description + "Shift+"
	EndIf;
	Description = Description + KeyPresentation_(Shortcut.Key) + ?(WithoutBrackets, "", ")");
	
	Return Description;
	
EndFunction

// Sets the page form Display property to No if only one bookmark is actually displayed
// Parameters:
//  PageItem  - FormGroup - the page that determines whether bookmarks should be displayed.
//
Procedure DeleteBookmarksIfThereIsOnlyOnePage(PageItem) Export
	
	If PageItem.ChildItems.Count() = 1 Then
		PageItem.PagesRepresentation = FormPagesRepresentation.None;
	Else
		NumberOfVisiblePages = 0;
		For Each SubordinatePage In PageItem.ChildItems Do
			
			If NumberOfVisiblePages > 1 Then
				Break;
			EndIf;
			
			For Each PageElement In SubordinatePage.ChildItems Do
				
				If PageElement.Visible Then
					NumberOfVisiblePages = NumberOfVisiblePages + 1;
					Break;
				EndIf;
				
			EndDo;
			
		EndDo;
		
		If NumberOfVisiblePages = 1 Then
			PageItem.PagesRepresentation = FormPagesRepresentation.None;
		EndIf;
		
	EndIf;
	
EndProcedure

// There may be broken links in the user settings. The procedure checks that the links are not broken, and if so
// , replaces these links with empty ones. If the procedure is called in the event pre-bootingdannyhiznadjustments on the Server - you can
// clear the links in the loaded settings themselves. If the pre - loaded settings are already applied
// to the form details in the server, and you need to clean them.
//
// Parameters:
//  Settings	 - Structure, Map -
//  Form		 - ClientApplicationForm, Undefined - if the form is passed, the details are cleared, if Undefined, the settings are cleared 
//
Procedure ClearFormSettingsOrDetailsFromNonexistentLinks(Settings, Form = Undefined) Export
	
	If Form <> Undefined Then
		ObjectToClear = Form;
	Else
		ObjectToClear = Settings;
	EndIf;
	
	If TypeOf(Settings) = Type("Structure")
		Or TypeOf(Settings) = Type("Map") Then
		
		For Each KeyValue In Settings Do
			
			If IsBlankString(KeyValue.Key) Then
				Continue;
			EndIf;
			
			ValueType = TypeOf(ObjectToClear[KeyValue.Key]);
			
			If Common.IsReference(ValueType)
				And Not Common.RefExists(ObjectToClear[KeyValue.Key]) Then
				TypeDescription = New TypeDescription(CommonClientServer.ValueInArray(ValueType));
				ObjectToClear[KeyValue.Key] = TypeDescription.AdjustValue();
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure

// Returns the structure of the changed parameters
// 
// Parameters:
// 	ParameterStructureIsNew - Structure - Structure of the mechanism parameters before changing the key details.
// 	ParameterStructureIsOld - Structure - Structure of the mechanism parameters after changing the key details.
// Returns:
// 	Structure -
Function ChangedParameters(ParameterStructureIsNew, ParameterStructureIsOld) Export
	
	Result = New Structure();
	
	If TypeOf(ParameterStructureIsNew) <> Type("Structure") Or TypeOf(ParameterStructureIsOld) <> Type("Structure") Then
		Return Result;
	EndIf;
	
	For Each KeyAndValue In ParameterStructureIsNew Do
		
		If TypeOf(KeyAndValue.Value) = Type("Array")
			Or TypeOf(KeyAndValue.Value) = Type("Structure") Then
			Continue;
		EndIf;
		
		If KeyAndValue.Value <> ParameterStructureIsOld[KeyAndValue.Key] Then
			Result.Insert(KeyAndValue.Key, ParameterStructureIsOld[KeyAndValue.Key] );
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#Region FillingInTabularPartsOfDocument

// The procedure checks duplicates of rows in the table part
//
// Parameters:
//  Object				 - DocumentObject, ClientApplicationForm - document object or form being checked
//  TSName				 - String			 - name of the table part to check
//  KeyDetailsOfTS	 - Array -
//	                     - String - array of the names of the details by which the uniqueness of the string is determined
//	                     - Structure - The key is the name of the Attribute, the value is the Presentation of the Attribute
//  Cancel				 - Boolean			 - failure to continue the operation.
//  PresentationOfTS		 - String			 - if not specified, the view will be obtained from the metadata.
//  SpecifyLineNumbers - Boolean			 - specifies whether to display the line number in the error message.
//
Procedure CheckForDuplicatesOfTSStrings(Object, TSName, KeyDetailsOfTS, Cancel, PresentationOfTS = "", SpecifyLineNumbers = True) Export
	
	ValueTypeKeyDetailsTS = TypeOf(KeyDetailsOfTS);
	PresentationOfAttributeFromSynonym = True;
	
	If ValueTypeKeyDetailsTS = Type("String") Then
		KeyAttributes = StrSplit(KeyDetailsOfTS, ",");
	ElsIf ValueTypeKeyDetailsTS = Type("Structure") Then
		
		PresentationOfAttributeFromSynonym = False;
		KeyAttributes = New Array;
		For Each NameAndPresentationOfProps In KeyDetailsOfTS Do
			
			KeyAttributes.Add(NameAndPresentationOfProps.Key);
			
		EndDo;
		
	Else
		KeyAttributes = KeyDetailsOfTS;
	EndIf;
	
	DataKey = DataKeyForMessageToUser(Object);
	
	ThisIsForm = False;
	If TypeOf(Object) = Type("ClientApplicationForm") Then
		ThisIsForm = True;
	Else
		ObjectMetadata = Object.Metadata();
		If IsBlankString(PresentationOfTS) Then
			PresentationOfTS = ObjectMetadata.TabularSections[TSName].Synonym;
		EndIf;
	EndIf;
	
	ArrayOfRowsOfSelectionField = New Array;
	ArrayOfConnectionFieldStrings = New Array;
	ArrayOfRowsOfUploadField = New Array;
	ArrayOfDuplicateMessageLines = New Array;
	
	For Each ArrRow In KeyAttributes Do
		ArrayOfRowsOfSelectionField.Add(StrTemplate("CheckTable.%1", ArrRow));
		ArrayOfConnectionFieldStrings.Add(StrTemplate("CheckTable.%1 = DuplicateLines.%1", ArrRow));
		ArrayOfRowsOfUploadField.Add(ArrRow);
		If PresentationOfAttributeFromSynonym Then
			AttributeRepresentation = ?(ThisIsForm, "",ObjectMetadata.TabularSections[TSName].Attributes[ArrRow].Synonym);
		Else
			AttributeRepresentation = ?(ThisIsForm, "", KeyDetailsOfTS[ArrRow]);
		EndIf;
		ArrayOfDuplicateMessageLines.Add(StrTemplate("""%1""", AttributeRepresentation));
	EndDo;	
	
	SelectionFieldText = StrConcat(ArrayOfRowsOfSelectionField, "," + Chars.LF);
	ConnectionFieldText = StrConcat(ArrayOfConnectionFieldStrings, Chars.LF + "And" + " ");
	TextOfUploadField = StrConcat(ArrayOfRowsOfUploadField, ",");
	TextForReportingDuplicates =  StrConcat(ArrayOfDuplicateMessageLines, ",");
	
	QueryText =
	"SELECT 
	|	CheckTable.LineNumber,
	|	&SelectionFields1
	|INTO CheckTable
	|FROM
	|	&CheckTable AS CheckTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(CheckTable.LineNumber) AS LineNumber,
	|	SUM(1) AS DuplicateCount,
	|	&SelectionFields1
	|INTO DuplicateLines
	|FROM
	|	CheckTable AS CheckTable
	|
	|GROUP BY 
	|	&SelectionFields1
	|
	|HAVING
	|	SUM(1) > 1
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CheckTable.LineNumber,
	|	DuplicateLines.LineNumber AS FirstRow,
	|	&SelectionFields1
	|FROM
	|	CheckTable AS CheckTable
	|		INNER JOIN DuplicateLines AS DuplicateLines
	|		ON CheckTable.LineNumber <> DuplicateLines.LineNumber 
	|			AND &ConnectionFields";
	QueryText = StrReplace(QueryText, "&SelectionFields1", SelectionFieldText);
	QueryText = StrReplace(QueryText, "&ConnectionFields", ?(ConnectionFieldText = "", "TRUE", ConnectionFieldText));
	
	Query = New Query(QueryText);
	Query.SetParameter("CheckTable",Object[TSName].Unload(,"LineNumber," + TextOfUploadField));
	
	Selection = Query.Execute().Select();
	
	If ThisIsForm Then
		If SpecifyLineNumbers Then
			If KeyAttributes.Count() = 1 Then
				MessageTemplate = NStr("vi = 'Trong dòng %LineNumber% danh sách ""%PresentationOfTS%"" so với dòng %FirstRow% bị lặp lại giá trị ""%RepeatableValue%"" trong trường khóa.';
										|ru = 'В строке %LineNumber% списка ""%PresentationOfTS%"" по сравнению со строкой %FirstRow% повторяется значение ""%RepeatableValue%"" в ключевом поле.';
										|en = 'In line %LineNumber% of the %PresentationOfTS% list, compared to line %FirstRow% the %RepeatableValue% value is repeated in the key field.'; fa = 'In line %LineNumber% of the %PresentationOfTS% list, compared to line %FirstRow% the %RepeatableValue% value is repeated in the key field.';
										|it = 'Nella stringa %LineNumber% dell''elenco ""%PresentationOfTS%"" in confronto alla stringa %FirstRow% viene ripetuto il valore ""%RepeatableValue%"" nel campo chiave.';
										|pl = 'W wierszu %LineNumber% listy ""%PresentationOfTS%"" w porównaniu z wierszem %FirstRow% jest powtarzana wartość ""%RepeatableValue%"" w polu kluczowym.';
										|tr = '""%PresentationOfTS%"" listesinin %LineNumber% satırında, %FirstRow% satırıyla karşılaştırıldığında, anahtar alanındaki ""%RepeatableValue%"" değeri tekrarlanır.'");
			Else
				MessageTemplate = NStr("vi = 'Trong dòng %LineNumber% danh sách ""%PresentationOfTS%"" so với dòng %FirstRow% bị lặp lại tổ hợp giá trị ""%RepeatableValue%"" trong các trường khóa.';
										|ru = 'В строке %LineNumber% списка ""%PresentationOfTS%"" по сравнению со строкой %FirstRow% повторяется сочетание значений ""%RepeatableValue%"" в ключевых полях.';
										|en = 'In line %LineNumber% of the %PresentationOfTS% list, compared to line %FirstRow% the %RepeatableValue% value combination is repeated in key fields.'; fa = 'In line %LineNumber% of the %PresentationOfTS% list, compared to line %FirstRow% the %RepeatableValue% value combination is repeated in key fields.';
										|it = 'Nella stringa %LineNumber% dell''elenco ""%PresentationOfTS%"" in confronto alla stringa %FirstRow% viene ripetuta la combinazione di valori ""%RepeatableValue%"" nei campi chiave.';
										|pl = 'W wierszu %LineNumber% listy ""%PresentationOfTS%"" w porównaniu z wierszem %FirstRow% jest powtarzana kombinacja wartości ""%RepeatableValue%"" w polach kluczowych.';
										|tr = '""%PresentationOfTS%"" listesinin %LineNumber% satırında, %FirstRow% satırına kıyasla anahtar alanlarda ""%RepeatableValue%"" değerlerinin bileşimi tekrarlanır.'");
			EndIf;
		Else
			If KeyAttributes.Count() = 1 Then
				MessageTemplate = NStr("vi = 'Trong danh sách ""%PresentationOfTS%"" bị lặp lại giá trị ""%RepeatableValue%"" trong trường khóa.';
										|ru = 'В списке ""%PresentationOfTS%"" повторяется значение ""%RepeatableValue%"" в ключевом поле.';
										|en = 'In the %PresentationOfTS% list, the %RepeatableValue% value is repeated in the key field.'; fa = 'In the %PresentationOfTS% list, the %RepeatableValue% value is repeated in the key field.';
										|it = 'Nell''elenco ""%PresentationOfTS%"" viene ripetuto il valore ""%RepeatableValue%"" nel campo chiave.';
										|pl = 'Na liście ""%PresentationOfTS%"" powtarza się wartość ""%RepeatableValue%"" w polu kluczowym.';
										|tr = '""%PresentationOfTS%"" listesi, anahtar alanında ""%RepeatableValue%"" değerleri tekrarlanıyor.'");
			Else
				MessageTemplate = NStr("vi = 'Trong danh sách ""%PresentationOfTS%"" bị lặp lại tổ hợp giá trị ""%RepeatableValue%"" trong các trường khóa.';
										|ru = 'В списке ""%PresentationOfTS%"" повторяется сочетание значений ""%RepeatableValue%"" в ключевых полях.';
										|en = 'In the %PresentationOfTS% list, the %RepeatableValue% value combination is repeated in key fields.'; fa = 'In the %PresentationOfTS% list, the %RepeatableValue% value combination is repeated in key fields.';
										|it = 'Nell''elenco ""%PresentationOfTS%"" viene ripetuta la combinazione di valori ""%RepeatableValue%"" nei campi chiave.';
										|pl = 'Na liście ""%PresentationOfTS%"" powtarza się kombinacja wartości ""%RepeatableValue%"" w polach kluczowych.';
										|tr = '""%PresentationOfTS%"" listesi, anahtar alanlardaki %RepeatableValue% değerlerinin bileşimi tekrarlanıyor.'");
			EndIf;
		EndIf;
	Else
		If SpecifyLineNumbers Then
			If KeyAttributes.Count() = 1 Then
				MessageTemplate = NStr("vi = 'Trong dòng %LineNumber% của danh sách ""%PresentationOfTS%%"" so với dòng %FirstRow% giá trị ""%RepeatableValue%"" trong các trường %FieldsNames1% được lặp lại.';
										|ru = 'В строке %LineNumber% списка ""%PresentationOfTS%"" по сравнению со строкой %FirstRow% повторяется значение ""%RepeatableValue%"" в полях %FieldsNames1%.';
										|en = 'In line %LineNumber% of the ""%PresentationOfTS%"" list compared to line %FirstRow% the ""%RepeatableValue%"" value is repeated in fields %FieldsNames1%.'; fa = 'In line %LineNumber% of the ""%PresentationOfTS%"" list compared to line %FirstRow% the ""%RepeatableValue%"" value is repeated in fields %FieldsNames1%.';
										|it = 'Nella riga  %LineNumber% dell''elenco""%PresentationOfTS%"" a confronto con la riga %FirstRow% si ripete il valore  ""%RepeatableValue%""nei campi%FieldsNames1%.';
										|pl = 'W wierszu %LineNumber% listy ""%PresentationOfTS%"" w porównaniu z wierszem %FirstRow% jest powtarzana wartość ""%RepeatableValue%"" w polach %FieldsNames1%.';
										|tr = '""%PresentationOfTS%"" listesinin %LineNumber% satırında, %FirstRow% satırıyla karşılaştırıldığında, %FieldsNames1% alanlarındaki ""%RepeatableValue%"" değeri tekrarlanıyor.'");
			Else
				MessageTemplate = NStr("vi = 'Trong dòng %LineNumber% của danh sách ""%PresentationOfTS%"" so với dòng %FirstRow% sự kết hợp của các giá trị ""%RepeatableValue%"" trong các trường %FieldsNames1% được lặp lại.';
										|ru = 'В строке %LineNumber% списка ""%PresentationOfTS%"" по сравнению со строкой %FirstRow% повторяется сочетание значений ""%RepeatableValue%"" в полях %FieldsNames1%.';
										|en = 'In line %LineNumber% of the ""%PresentationOfTS%"" list compared to line %FirstRow% the ""%RepeatableValue%"" value combination is repeated in the %FieldsNames1% fields.'; fa = 'In line %LineNumber% of the ""%PresentationOfTS%"" list compared to line %FirstRow% the ""%RepeatableValue%"" value combination is repeated in the %FieldsNames1% fields.';
										|it = 'Nella riga %LineNumber% списка ""%PresentationOfTS%"" a confronto con la riga %FirstRow% si ripete il valore ""%RepeatableValue%"" nei campi %FieldsNames1%.';
										|pl = 'W wierszu %LineNumber% listy ""%PresentationOfTS%"" w porównaniu z wierszem %FirstRow% jest powtarzana kombinacja wartości ""%RepeatableValue%"" w polach %FieldsNames1%.';
										|tr = '""%PresentationOfTS%"" listesinin %LineNumber% satırında, %FirstRow%satırına kıyasla, %FieldsNames1% alanlarındaki ""%RepeatableValue%"" değerlerinin birleşimi tekrarlanır.'");
			EndIf;
		Else
			If KeyAttributes.Count() = 1 Then
				MessageTemplate = NStr("vi = 'Trong danh sách ""%PresentationOfTS%"" giá trị lặp lại ""%RepeatableValue%"" tại trường %FieldsNames1%.';
										|ru = 'В списке ""%PresentationOfTS%"" повторяется значение ""%RepeatableValue%"" в поле %FieldsNames1%.';
										|en = 'In the ""%PresentationOfTS%"" list, the ""%RepeatableValue%"" value is repeated in field %FieldsNames1%.'; fa = 'In the ""%PresentationOfTS%"" list, the ""%RepeatableValue%"" value is repeated in field %FieldsNames1%.';
										|it = 'Nell''elenco ""%PresentationOfTS%"" si ripete il valore ""%RepeatableValue%"" nel campo  %FieldsNames1%.';
										|pl = 'W liście ""%PresentationOfTS%"" jest powtarzana wartość ""%RepeatableValue%"" w polu %FieldsNames1%.';
										|tr = '""%PresentationOfTS%"" listesinde, %FieldsNames1% alanındaki ""%RepeatableValue%"" değeri tekrarlanıyor.'");
			Else
				MessageTemplate = NStr("vi = 'Trong danh sách ""%PresentationOfTS%"" giá trị lặp lại ""%RepeatableValue%"" tại trường %FieldsNames1%.';
										|ru = 'В списке ""%PresentationOfTS%"" повторяется сочетание значений ""%RepeatableValue%"" в полях %FieldsNames1%.';
										|en = 'In the ""%PresentationOfTS%"" list, the ""%RepeatableValue%"" value combination is repeated in fields %FieldsNames1%.'; fa = 'In the ""%PresentationOfTS%"" list, the ""%RepeatableValue%"" value combination is repeated in fields %FieldsNames1%.';
										|it = 'Nell''elenco ""%PresentationOfTS%"" si ripete la combinazione di valori ""%RepeatableValue%"" nei campi %FieldsNames1%.';
										|pl = 'W liście ""%PresentationOfTS%"" jest powtarzana kombinacja wartości ""%RepeatableValue%"" w polach %FieldsNames1%.';
										|tr = '""%PresentationOfTS%"" listesinde, %FieldsNames1% alanlarındaki ""%RepeatableValue%"" değerlerinin bileşimi tekrarlanır.'");
			EndIf;
		EndIf;
	EndIf;

	While Selection.Next() Do
		
		MessageText =  StrReplace(MessageTemplate, "%PresentationOfTS%", PresentationOfTS);
		MessageText =  StrReplace(MessageText, "%LineNumber%", Selection.LineNumber);
		MessageText =  StrReplace(MessageText, "%FirstRow%", Selection.FirstRow);
		MessageText =  StrReplace(MessageText, "%FieldsNames1%", TextForReportingDuplicates);
		
		RepeatableValue = "";
		
		For Each ArrRow In KeyAttributes Do
			ValuePresentation = TrimAll(String(Selection[ArrRow]));
			If ValueIsFilled(ValuePresentation) Then
				RepeatableValue = RepeatableValue + Selection[ArrRow] + "/";
			EndIf;
		EndDo;
		
		RepeatableValue = Left(RepeatableValue, StrLen(RepeatableValue) - 1);
		
		MessageText =  StrReplace(MessageText, "%RepeatableValue%", RepeatableValue);
		
		If SpecifyLineNumbers Then
			Field = CommonClientServer.PathToTabularSection(TSName, Selection.LineNumber, "LineNumber");
		Else
			Field = TSName;
		EndIf;
		
		CommonClientServer.MessageToUser(MessageText,DataKey,Field,"Object",Cancel);
		
	EndDo;
EndProcedure

// The procedure fills in the values of the details of the table part by structure
//
// Parameters:
// 		DataCollection - FormDataCollection - Table part
// 		AttributesStructure1 - Structure - Key - name of the activity flag's props. Value - a string listing dependent details.
//
Procedure FillInDuplicateDependentPropsInCollection(DataCollection, AttributesStructure1) Export
	
	// Getting a sample field template for a duplicate props value
	// 		If the activity flag is TRUE, copy the value from the props
	// 		Otherwise, fill it with an empty value.
	SampleFieldTemplate = 
	"	CASE WHEN Collection.%FlagName% = TRUE
	|		THEN Collection.%AttributeName%
	|		ELSE 0
	|	END AS %AttributeName%%FlagName%";
	
	ArrayOfSelectionFields = New Array; 
	ArrayOfUploadFields = New Array;
	ArrayOfUploadFields.Add("LineNumber");
	For Each FlagProps In AttributesStructure1 Do
		ArrayOfUploadFields.Add(FlagProps.Key);
		DependentDetails = New Structure(FlagProps.Value);
		For Each DependentAttribute In DependentDetails Do
			SelectionField = StrReplace(SampleFieldTemplate, "%FlagName%", FlagProps.Key);
			SelectionField = StrReplace(SelectionField, "%AttributeName%", DependentAttribute.Key);
			ArrayOfSelectionFields.Add(SelectionField);
			ArrayOfUploadFields.Add(DependentAttribute.Key + ", " + DependentAttribute.Key + FlagProps.Key);
		EndDo;
	EndDo;
	
	QueryText =
	"SELECT
	|	Collection.LineNumber,
	|	&SelectionFields1
	|INTO TTCollection
	|FROM &DataCollection AS Collection;
	|
	|SELECT *
	|FROM TTCollection AS TTCollection
	|ORDER BY LineNumber";
	QueryText = StrReplace(QueryText, "&SelectionFields1", StrConcat(ArrayOfSelectionFields, "," + Chars.LF));
	
	Query = New Query(QueryText);
	Query.SetParameter("DataCollection", DataCollection.Unload( , StrConcat(ArrayOfUploadFields, ",")));
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		FillPropertyValues(DataCollection[Selection.LineNumber-1], Selection, , "LineNumber");
	EndDo;
	
EndProcedure // Fill in the Duplicate of the independent Requirements of the Collection()

// The procedure checks whether rows in the table part of the document are undone
// Parameters:
//	Object - DocumentObject - document being checked
//	TSName - String - name of the table part to check
//	NameOfRowCancellationProps - String - name of the Boolean PM prop to be checked.
// 
// Returns:
// 	Boolean - Test result
//
Function AllLinesAreCanceled(Object, TSName, NameOfRowCancellationProps) Export
	
	FilterStructure1 = New Structure(NameOfRowCancellationProps, False);
	NotCancelledRows = Object[TSName].FindRows(FilterStructure1);
	
	Return (NotCancelledRows.Count() = 0);
	
EndFunction

#EndRegion

#Region ControlOfInconsistentChanges

// Sets up a subscription for form element change events.
//
// Parameters:
// 		Form - ClientApplicationForm - the form of the document:
// 							* Object - DocumentObject - Properties:
// 								* Ref - DocumentRef -
// 		ItemsNames - Array of String - array of form element names.
//
Procedure SetSubscriptionForFormElementChangeEvents(Form, ItemsNames) Export
	
	If Not ValueIsFilled(Form.Object.Ref) Then
		Return;
	EndIf;
	
	StructureOfTableFields = New Structure;
	
	TypeManagedForm = Type("ClientApplicationForm");
	FormDataTypeStructure = Type("FormDataStructure");
	TypeFormField = Type("FormField");
	TypeOfFormButton = Type("FormButton");
	FormTypeTable = Type("FormTable");
	
	Items = Form.Items;
	
	EventHandlersForTableParts = New Structure();
	ItemArray = New Array;
	For Each FullElementName In ItemsNames Do
		
		SeparatorPosition = StrFind(FullElementName, ";");
		If SeparatorPosition > 0 Then
			Array = StringFunctionsClientServer.SplitStringIntoSubstringsArray(FullElementName, ";");
			TagName = Array[0];
		Else
			TagName = FullElementName;
		EndIf;
		
		If ItemArray.Find(TagName) <> Undefined Then
			Continue;
		EndIf;
		
		Item = Items.Find(TagName);
		If Item = Undefined Then
			Continue;
		EndIf;
		
		ItemArray.Add(TagName);
		
		If SeparatorPosition > 0 And Array.Count() > 1 Then
			If StrFind(Array[1], ",") > 0 Then
				EventHandlersForTableParts.Insert(TagName, StringFunctionsClientServer.SplitStringIntoSubstringsArray(Array[1], ","));
			Else
				EventHandlersForTableParts.Insert(TagName, Array[1]);
			EndIf;
		EndIf;
		
		ExceptionFields = New Array;
		If SeparatorPosition > 0
			And Array.Count() > 2 Then
			ExceptionFields = StringFunctionsClientServer.SplitStringIntoSubstringsArray(Array[2], ",");
		EndIf;
		
		ProcessNestedFields(Items, Item, ItemArray, StructureOfTableFields, ExceptionFields);
		
	EndDo;
	
	HandlerName_ = "Attachable_EmptyHandler_SetAvailabilityOfItemsByStatusServer";
	If Form.StructureOfActionsControlOfNonAgreedChanges = Undefined Then
		
		Form.StructureOfActionsControlOfNonAgreedChanges = New Structure;
		Form.StructureOfActionsControlOfNonAgreedChanges.Insert("Commands", New Structure);
		Form.StructureOfActionsControlOfNonAgreedChanges.Insert("OnChange", New Structure);
		Form.StructureOfActionsControlOfNonAgreedChanges.Insert("Click", New Structure);
		Form.StructureOfActionsControlOfNonAgreedChanges.Insert("BeforeRowChange", New Structure);
		Form.StructureOfActionsControlOfNonAgreedChanges.Insert("BeforeAddRow", New Structure);
		Form.StructureOfActionsControlOfNonAgreedChanges.Insert("BeforeDeleteRow", New Structure);
		
		Form.StructureOfActionsControlOfNonAgreedChanges.Insert("AlertIsExpected", False);
		Form.StructureOfActionsControlOfNonAgreedChanges.Insert("AttributesValues", New Structure);
		Form.StructureOfActionsControlOfNonAgreedChanges.Insert("DataPath", New Structure);
		Form.StructureOfActionsControlOfNonAgreedChanges.Insert("ChoiceParameterLinks", New Map);
		
		For Each TableName In StructureOfTableFields Do
			
			Names = New Array;
			Form.StructureOfActionsControlOfNonAgreedChanges.AttributesValues.Insert(TableName.Key, New Structure);
			
			For Each TagName In StructureOfTableFields[TableName.Key] Do
				
				Data = Undefined;
				DataPath = Items[TagName].DataPath;
				If ValueIsFilled(DataPath) Then
					
					Position = StrFind(DataPath, ".");
					While Position > 0 Do
						DataPath = Mid(DataPath, Position + 1);
						Position = StrFind(DataPath, ".");
					EndDo;
					Names.Add(DataPath);
					
				EndIf;
				
			EndDo;
			
			For Each Name In Names Do
				Form.StructureOfActionsControlOfNonAgreedChanges.AttributesValues[TableName.Key].Insert(Name);
			EndDo;
			
		EndDo;
		
		NameOfHandlerWhenChanging            = "Attachable_WhenChanging_SetAvailabilityOfItemsByStatusServer";
		NameOfClickHandler                 = "Attachable_Clicking_SetAvailabilityOfItemsByStatusServer";
		NameOfCommandHandler                 = "Attachable_Command_SetAvailabilityOfItemsByStatusServer";
		NameOfHandlerBeforeStartingChange   = "Attachable_BeforeStartingChange_SetAvailabilityOfItemsByStatusServer";
		NameOfHandlerBeforeAdding  = "Attachable_BeforeYouStartAdding_SetAvailabilityOfItemsByStatusServer";
		BeforeDeleteHandlerName          = "Attachable_BeforeDeleting_SetAvailabilityOfItemsByStatusServer";
		
		For Each FullElementName In ItemArray Do
			
			SeparatorPosition = StrFind(FullElementName, ";");
			If SeparatorPosition > 0 Then
				TagName = Left(FullElementName, SeparatorPosition - 1);
			Else
				TagName = FullElementName;
			EndIf;
			
			Item = Items[TagName];
			If Item = Undefined Then
				Continue;
			EndIf;
			
			TypeOfGNPElement = TypeOf(Item);
			
			If TypeOfGNPElement = TypeFormField Then
				
				Action = Item.GetAction("OnChange");
				If ValueIsFilled(Action) And Action <> HandlerName_ Then
					Form.StructureOfActionsControlOfNonAgreedChanges.OnChange.Insert(TagName, Action);
				EndIf;
				
				Data = Undefined;
				DataPath = Item.DataPath;
				If ValueIsFilled(DataPath) Then
					Array = StringFunctionsClientServer.SplitStringIntoSubstringsArray(DataPath, ".");
					Data = Form;
					For Each ArrayRow In Array Do
						TypeOfGNRData = TypeOf(Data);
						If TypeOfGNRData = TypeManagedForm
							Or TypeOfGNRData = FormDataTypeStructure Then
							Data = Data[ArrayRow];
						Else
							Data = Undefined;
							Break;
						EndIf;
					EndDo;
				EndIf;
				
				If Data <> Undefined Then
					Form.StructureOfActionsControlOfNonAgreedChanges.AttributesValues.Insert(TagName, Data);
				EndIf;
				Form.StructureOfActionsControlOfNonAgreedChanges.DataPath.Insert(TagName, DataPath);
				Item.SetAction("OnChange", NameOfHandlerWhenChanging);
				
				If Item.Type = FormFieldType.InputField Then
					For Each RelationshipOfSelectionParameters In Item.ChoiceParameterLinks Do
						If RelationshipOfSelectionParameters.ValueChange = LinkedValueChangeMode.Clear Then
							Array = Form.StructureOfActionsControlOfNonAgreedChanges.ChoiceParameterLinks.Get(RelationshipOfSelectionParameters.DataPath);
							If Array = Undefined Then
								Array = New Array;
								Form.StructureOfActionsControlOfNonAgreedChanges.ChoiceParameterLinks.Insert(RelationshipOfSelectionParameters.DataPath, Array);
							EndIf;
							Array.Add(FullElementName);
						EndIf;
					EndDo;
				EndIf;
				
			ElsIf TypeOfGNPElement = FormTypeTable Then
				
				Actions = Undefined;
				EventHandlersForTableParts.Property(TagName, Actions);
				
				If Not ValueIsFilled(Actions) Or Actions.Find("BeforeAddRow") <> Undefined Then
					Action = Items[TagName].GetAction("BeforeAddRow");
					If ValueIsFilled(Action) And Action <> HandlerName_ Then
						Form.StructureOfActionsControlOfNonAgreedChanges.BeforeAddRow.Insert(TagName, Action);
					EndIf;
					Item.SetAction("BeforeAddRow", NameOfHandlerBeforeAdding);
				EndIf;
				
				If Not ValueIsFilled(Actions) Or Actions.Find("BeforeDeleteRow") <> Undefined Then
					Action = Items[TagName].GetAction("BeforeDeleteRow");
					If ValueIsFilled(Action) And Action <> HandlerName_ Then
						Form.StructureOfActionsControlOfNonAgreedChanges.BeforeDeleteRow.Insert(TagName, Action);
					EndIf;
					Item.SetAction("BeforeDeleteRow", BeforeDeleteHandlerName);
				EndIf;
				
				If Not ValueIsFilled(Actions) Or Actions.Find("BeforeRowChange") <> Undefined Then
					Action = Items[TagName].GetAction("BeforeRowChange");
					If ValueIsFilled(Action) And Action <> HandlerName_ Then
						Form.StructureOfActionsControlOfNonAgreedChanges.BeforeRowChange.Insert(TagName, Action);
					EndIf;
					Item.SetAction("BeforeRowChange", NameOfHandlerBeforeStartingChange);
				EndIf;
				
			ElsIf TypeOfGNPElement = TypeOfFormButton Then
				
				CommandName = Item.CommandName;
				
				If Not ValueIsFilled(CommandName) Then
					Continue;
				EndIf;
				
				If Form.StructureOfActionsControlOfNonAgreedChanges.Commands.Property(CommandName) Then
					Continue;
				EndIf;
				
				FormCommand = Form.Commands[CommandName]; // FormCommand - 
				
				Action = FormCommand.Action;
				If ValueIsFilled(Action) Then
					Form.StructureOfActionsControlOfNonAgreedChanges.Commands.Insert(CommandName, Action);
				EndIf;
				
				FormCommand.Action = NameOfCommandHandler;
				
			ElsIf TypeOfGNPElement = Type("FormDecoration") Then
				
				Action = Item.GetAction("Click");
				If ValueIsFilled(Action) And Action <> HandlerName_ Then
					Form.StructureOfActionsControlOfNonAgreedChanges.Click.Insert(TagName, Action);
				EndIf;
				
				Item.SetAction("Click", NameOfClickHandler);
				
			Else
				Raise NStr("vi = 'Lỗi nội bộ';
							|ru = 'Внутренняя ошибка';
							|en = 'Internal error'; fa = 'Internal error';
							|it = 'Errore interno';
							|pl = 'Błąd wewnętrzny';
							|tr = 'Dahili hata'");
			EndIf;
		EndDo;
		
	Else
		
		If Form.StructureOfActionsControlOfNonAgreedChanges <> Undefined Then
			Form.StructureOfActionsControlOfNonAgreedChanges.AlertIsExpected = False;
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region ConditionalAppearance

// Setting the conditional design for the "Priority" form field
//    depending on its value.
//
// Parameters:
// 		Form - ClientApplicationForm - Contains this form with Attributes:
// 			* Items - FormAllItems - Collection of form elements:
// 				** Priority - FormField - 
//
Procedure SetConditionalAppearanceOfPriority(Form) Export
	
	If Form.FormName = "DataProcessor.SelfServiceWorkplacePartners.Form.OrderGenerationWizard" Then
		PathToPropsPriority = "Priority";
	Else
		PathToPropsPriority = "Object.Priority";
	EndIf;
	
	ConditionalAppearance = Form.ConditionalAppearance;
	FormItems = Form.Items;
	
	//
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();

	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormItems.Priority.Name);

	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToPropsPriority);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Catalogs.Priorities.GetTopPriority();

	ConditionalAppearanceItem.Appearance.SetParameterValue("BackColor", StyleColors.HighPriorityDocument);

	//
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();

	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FormItems.Priority.Name);

	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(PathToPropsPriority);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Catalogs.Priorities.GetLowerPriority();

	ConditionalAppearanceItem.Appearance.SetParameterValue("BackColor", StyleColors.LowDocumentPriority);
	
	//
	Query = New Query(
	"SELECT
	|	Priorities.Ref AS Priority,
	|	Priorities.Color   AS Color
	|FROM
	|	Catalog.Priorities AS Priorities");
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		
		Selection = QueryResult.Select();
		
		While Selection.Next() Do
			
			Item = ConditionalAppearance.Items.Add();

			ItemField = Item.Fields.Items.Add();
			ItemField.Field = New DataCompositionField(FormItems.Priority.Name);

			ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = New DataCompositionField(PathToPropsPriority);
			ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
			ItemFilter.RightValue = Selection.Priority;
			
			Color = Selection.Color; // ValueStorage -
			Item.Appearance.SetParameterValue("TextColor", Color.Get());
			
		EndDo;
		
	EndIf;
	
EndProcedure

// The procedure fills in all subordinate fields (taking into account nesting in groups) in the conditional formatting fields that are being processed
// Example of a call: fill in the recursive field of the conditional Form(Element).Fields, Elements.Goods.Subordinate elements).
//
// Parameters:
//	DataCompositionAppearanceFields	- DataCompositionAppearanceFields -
//	ItemsCollection - FormItems -
//	ExcludingFields - Array -
//	             - String -
//	             - Undefined - the default value is Undefined, an array of names of elements that do not need to be added to the fields being drawn up.
//
Procedure FillInConditionalAppearanceFieldsRecursively(DataCompositionAppearanceFields, ItemsCollection, Val ExcludingFields = Undefined) Export
	
	If TypeOf(ExcludingFields) = Type("String") Then
		ExcludingFields = StringFunctionsClientServer.SplitStringIntoSubstringsArray(ExcludingFields);
	EndIf;
	
	For Each Field In ItemsCollection Do
		If TypeOf(Field) = Type("FormField") Then
			If ExcludingFields = Undefined
				Or ExcludingFields.Find(Field.Name) = Undefined Then
					ItemField = DataCompositionAppearanceFields.Items.Add();
					ItemField.Field = New DataCompositionField(Field.Name);
			EndIf;
		ElsIf TypeOf(Field) = Type("FormGroup")Then	
			FillInConditionalAppearanceFieldsRecursively(DataCompositionAppearanceFields, Field.ChildItems);
		EndIf;
	EndDo;

EndProcedure

// Adds to the form of a conditional element format (blank mark) on the basis of the value of service requisite
// according to the following rule: if the requisite is not filled in and requisite service completed checkbox is set, otherwise cleared.
//
//  Parameters:
//   ConditionalAppearance - DataCompositionConditionalAppearance - conditional form design.
//   TagName - String - name of the element for the conditional design.
//   AttributePath1 - String - the path to the required property, for example, " Object.Products".
//   PathToTrait - String - the path to the service attribute that determines whether to mark an empty value.
//
Procedure SetUncheckBlank(ConditionalAppearance, TagName, AttributePath1, PathToTrait) Export
	
	// Setting the mark.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(TagName);
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField(PathToTrait);
	Filter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField(AttributePath1);
	Filter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	// Removing the mark.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(TagName);
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField(PathToTrait);
	Filter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// Removing the mark.
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(TagName);
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField(AttributePath1);
	Filter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
EndProcedure

#EndRegion

#Region SwitchingInterface

// Setting a set of visible command interface subsystems
//  and settings for all users of the interface view (Taxi / bookmarks).
//
// Parameters:
//  Mode	 - String	 - Interfacestaxi / Interfacversii82-corresponds to a constant that will be set to True.
//
Procedure SetCommandInterfaceMode(Mode) Export
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	// Setting constants
	
	TaxiMode = Upper(Mode) = Upper("TaxiInterface");
	Mode82    = Upper(Mode) = Upper("InterfaceVersion82");
	
	If Not TaxiMode
		And Not Mode82 Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	Constants.InterfaceVersion82.Set(Mode82);
	
	// Setting default settings for all users
	
	AllUsers = InfoBaseUsers.GetUsers(); // Array of InfoBaseUser -
	If AllUsers.Count() > 0 Then
		For Each IBUser In AllUsers Do
			UsersInternal.SetInitialSettings(IBUser.Name);
		EndDo;
	Else
		UsersInternal.SetInitialSettings("");
	EndIf;

EndProcedure

// Procedure-Switching the interface when creating it on the server
//
// Parameters:
//  Form	 - ClientApplicationForm - Form the admin panel.
//
Procedure SwitchingInterfaceWhenCreatingOnServer(Form) Export 

	// Values of form details
	If Constants.InterfaceVersion82.Get() Then
		Form.InterfaceOption = "InterfaceVersion82";
	Else
		Form.InterfaceOption = "TaxiInterface";
	EndIf;
	Form.InterfaceOptionBeforeChange = Form.InterfaceOption;
	
	CurrentMode = Metadata.InterfaceCompatibilityMode;
	Taxi = (CurrentMode = Metadata.ObjectProperties.InterfaceCompatibilityMode.Taxi
		Or CurrentMode = Metadata.ObjectProperties.InterfaceCompatibilityMode.TaxiEnableVersion8_2);
	
	Form.Items.InterfaceOption.ChoiceList.Clear();
	InterfacePresentation82 = NStr("vi = 'Làm thế nào trong các phiên bản trước Quản lý thương mại';
									|ru = 'Как в предыдущих версиях Управления торговлей';
									|en = 'As in the previous Sales Management versions'; fa = 'As in the previous Sales Management versions';
									|it = 'Come nelle versioni precedenti di Gestione commerciale';
									|pl = 'Jak w poprzednich wersjach Zarządzania handlem';
									|tr = 'Ticaret Yönetiminin önceki sürümlerinde olduğu gibi'");
	InterfacePresentation82 = NStr("vi = 'Như trong các phiên bản trước của 1C: ERP';
									|ru = 'Как в предыдущих версиях 1С:ERP';
									|en = 'As in the previous 1C:ERP WE versions'; fa = 'As in the previous 1C:ERP WE versions';
									|it = 'Come nelle versioni precedenti di 1C:ERP';
									|pl = 'Jak w poprzednich wersjach 1С:ERP';
									|tr = '1C:ERP''nin önceki sürümlerinde olduğu gibi'");
	If Taxi Or GetFunctionalOption("BaseVersion") Then
	
		Form.Items.InterfaceOption.ChoiceList.Add("TaxiInterface", NStr("vi = '""Taxi"" (khuyên dùng)';
																		|ru = '""Такси"" (рекомендуется)';
																		|en = 'Taxi (recommended)'; fa = 'Taxi (recommended)';
																		|it = '""Taxi"" (raccomandato)';
																		|pl = '""Taxi"" (zalecane)';
																		|tr = '""Taksi"" (önerilmektedir)'"));
		Form.Items.InterfaceOption.ChoiceList.Add("InterfaceVersion82", InterfacePresentation82);
		
	Else
		
		Form.Items.InterfaceOption.ChoiceList.Add("TaxiInterface", NStr("vi = '""Taxi""';
																		|ru = '""Такси""';
																		|en = '""Taxi""'; fa = '""Taxi""';
																		|it = '""Такси""';
																		|pl = '""Taxi""';
																		|tr = '""Taksi""'"));
		Form.Items.InterfaceOption.ChoiceList.Add("InterfaceVersion82", InterfacePresentation82 + " " + NStr("vi = '(khuyên dùng)';
																											|ru = '(рекомендуется)';
																											|en = '(recommended)'; fa = '(recommended)';
																											|it = '(consigliato)';
																											|pl = '(recommended)';
																											|tr = '(önerilmektedir)'"));
		
	EndIf; 

EndProcedure

#EndRegion

#Region DynamicList

// Restores the settings of a dynamic list is used after changing the query text 
//
// Parameters:
//  List - DynamicList - dynamic list for which you want to restore the settings
//
Procedure RestoreDynamicListSettings(List) Export
	
	List.SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.Full);
	
	OrderAvailableFields = List.Order.OrderAvailableFields;
	
	OrderItems = List.Order.Items;
	IndexOfElements = OrderItems.Count() - 1;
	While IndexOfElements > -1 Do
		
		If OrderAvailableFields.FindField(OrderItems[IndexOfElements].Field) = Undefined Then
			OrderItems.Delete(OrderItems[IndexOfElements]);	
		EndIf;
		
		IndexOfElements = IndexOfElements - 1;
		
	EndDo;	
	
EndProcedure	

#EndRegion

#Region GettingSelectionData

Procedure ProcessingOfSelectionDataAcquisitionBusinessOperations(ChoiceData, Parameters, StandardProcessing) Export
	
	StandardProcessing = False;
	
	AvailableFOS = New Array;
	For Each FederalDistrict In Metadata.FunctionalOptions Do
		AvailableFOS.Add(FederalDistrict.Name);
	EndDo;
	
	QueryText = 
	"SELECT
	|	BusinessTransactionsSettingsFunctionalOptions.FunctionalOptionName,
	|	BusinessTransactionsSettingsFunctionalOptions.Ref.BusinessOperation AS BusinessOperation
	|FROM
	|	Catalog.BusinessTransactionsSettings.FunctionalOptions AS BusinessTransactionsSettingsFunctionalOptions
	|WHERE
	|	BusinessTransactionsSettingsFunctionalOptions.FunctionalOptionName IN(&AvailableFunctionalOptions)
	|
	|ORDER BY
	|	BusinessOperation
	|
	|TOTALS BY
	|	BusinessOperation";
	
	Query = New Query(QueryText);
	Query.SetParameter("AvailableFunctionalOptions", AvailableFOS);
	
	ArrayOfExcludedValues = New Array;
	SelectionByOperations = Query.Execute().Select(QueryResultIteration.ByGroups);
	While SelectionByOperations.Next() Do
		FunctionalOptions = SelectionByOperations.Select();
		AvailableByFederalDistrict = False;
		While FunctionalOptions.Next() Do
			FullNameFO = StrTemplate("FunctionalOption.%1", FunctionalOptions.FunctionalOptionName);
			ThereIsFO = Metadata.FindByFullName(FullNameFO) <> Undefined;
			AvailableByFederalDistrict = Not ThereIsFO
				Or GetFunctionalOption(FunctionalOptions.FunctionalOptionName);
			If AvailableByFederalDistrict Then
				Break;
			EndIf;
		EndDo;
		If Not AvailableByFederalDistrict Then
			ArrayOfExcludedValues.Add(SelectionByOperations.BusinessOperation);
		EndIf;
	EndDo;
	
	If Parameters.Property("IsAccessValueSelection") Then
		QueryText = 
		"SELECT
		|	BusinessTransactionsSettings.BusinessOperation AS Ref
		|FROM
		|	Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
		|WHERE
		|	BusinessTransactionsSettings.UseForAccessRestrictions = FALSE";
		
		Query = New Query(QueryText);
		ForbiddenForSelection = Query.Execute().Unload().UnloadColumn("Ref");
		CommonClientServer.SupplementArray(ArrayOfExcludedValues, ForbiddenForSelection);
	EndIf;
	
	SelectableEnumerationValues(
		"BusinessTransactions",
		ChoiceData,
		Parameters,
		ArrayOfExcludedValues);
	
EndProcedure

Procedure ProcessingOfObtainingDataForSelectingFinancialAccountingCalculationGroup(ChoiceData, Parameters, StandardProcessing) Export
	Catalogs.FinancialAccountingGroupsOfARAP.ConvertSelectionParametersSelection(Parameters.Filter);
EndProcedure

#EndRegion

#Region OperationsWithDocumentJournals

// Returns a table with business operations and document types available by functional options
// and rights.
//
// Parameters:
//	ValueTable - ValueTable -
//	FilterBusinessTransactions - Structure  -
//	FilterDocumentTypes - Structure -
//	PurposeUseKey - String
//
// Returns:
//	ValueTable - Columns:
//		* BusinessOperation - EnumRef.BusinessTransactions - 
//		* MetadataObjectID - CatalogRef.MetadataObjectIDs - 
//		* Filter - Boolean - 
//		* DocumentPresentation - String -
//
Function AvailableBusinessTransactionsAndDocuments(ValueTable, FilterBusinessTransactions, FilterDocumentTypes, PurposeUseKey) Export
	
	ResultTable2 = ValueTable.CopyColumns();
	TableName        = "InformationRegister.DocumentsRegistry";
	
	NotAvailableBusinessTransactions = NotAvailableBusinessTransactions(TableName);
	AuditedBusinessOperations = ValueTable.UnloadColumn("BusinessOperation");
	
	ArrayOfBusinessOperations = ?(NotAvailableBusinessTransactions.Count() = 0,
									AuditedBusinessOperations,
									CommonClientServer.ArraysDifference(AuditedBusinessOperations,
																				NotAvailableBusinessTransactions));
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	BusinessTransactionsSettingsFunctionalOptions.FunctionalOptionName AS FunctionalOptionName,
	|	BusinessTransactionsSettingsFunctionalOptions.Ref.BusinessOperation AS BusinessOperation,
	|	BusinessTransactionsSettingsFunctionalOptions.Ref.UseInDocumentRegistry AS UseInDocumentRegistry
	|FROM
	|	Catalog.BusinessTransactionsSettings.FunctionalOptions AS BusinessTransactionsSettingsFunctionalOptions
	|WHERE
	|	BusinessTransactionsSettingsFunctionalOptions.Ref.BusinessOperation IN(&ArrayOfBusinessOperations)
	|
	|ORDER BY
	|	BusinessOperation
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BusinessTransactionsSettingsDocuments.Ref.BusinessOperation AS BusinessOperation,
	|	BusinessTransactionsSettingsDocuments.LineNumber AS LineNumber,
	|	BusinessTransactionsSettingsDocuments.MetadataObjectID AS MetadataObjectID,
	|	BusinessTransactionsSettingsDocuments.MetadataObjectID.FullName AS FullName,
	|	PRESENTATION(VALUETYPE(BusinessTransactionsSettingsDocuments.MetadataObjectID.EmptyRefValue)) AS Synonym
	|FROM
	|	Catalog.BusinessTransactionsSettings.Documents AS BusinessTransactionsSettingsDocuments
	|WHERE
	|	BusinessTransactionsSettingsDocuments.Ref.BusinessOperation IN(&ArrayOfBusinessOperations)
	|	AND BusinessTransactionsSettingsDocuments.MetadataObjectID <> VALUE(Catalog.MetadataObjectIDs.EmptyRef)
	|TOTALS BY
	|	BusinessOperation";
	
	Query.SetParameter("ArrayOfBusinessOperations", ArrayOfBusinessOperations);
	
	QueryResult = Query.ExecuteBatch();
	SelectionByFunctionalOptions = QueryResult[0].Select();
	SelectionByDocuments = QueryResult[1].Select(QueryResultIteration.ByGroups);
	
	MetadataObjectIDs = QueryResult[1].Unload().UnloadColumn("MetadataObjectID");
	MetadataObjectIDs = CommonClientServer.CollapseArray(MetadataObjectIDs);
	
	If MetadataObjectIDs.Count() = 0 Then
		Raise NStr("vi = 'Không có giao dịch kinh doanh có sẵn để hiển thị. Có lẽ quyền truy cập cho người dùng được gán không chính xác.';
					|ru = 'Нет доступных для отображения хозяйственных операций. Возможно права доступа для пользователя назначены некорректно.';
					|en = 'No business transactions available for display. Access rights may not be correctly assigned to the user.'; fa = 'No business transactions available for display. Access rights may not be correctly assigned to the user.';
					|it = 'Non disponibile per visualizzare transazioni commerciali. Forse i diritti di accesso utente sono assegnati in modo errato.';
					|pl = 'Nie ma dostępnych do wyświetlania operacji gospodarczych. Być może prawa dostępu dla użytkownika zostały przypisane niepoprawnie.';
					|tr = 'Görüntülenecek ticari işlem yok. Belki de kullanıcının erişim hakları yanlış atanmıştır.'");
	EndIf;
	
	// Delete the empty value.
	MetadataObjectIDs.Delete(0);
	RightsByIDs = AccessManagement.RightsByIDs(MetadataObjectIDs);
	

	DocumentAvailabilityByFO = New Map();
	
	While SelectionByDocuments.Next() Do
		
		BusinessOperationIsAvailableByFo = False;
		ThereIsFO = False;
		
		While SelectionByFunctionalOptions.FindNext(New Structure("BusinessOperation", SelectionByDocuments.BusinessOperation)) Do
			
			FullNameFO = StrTemplate("FunctionalOption.%1", SelectionByFunctionalOptions.FunctionalOptionName);
			ThereIsFO = Metadata.FindByFullName(FullNameFO) <> Undefined;
			BusinessOperationIsAvailableByFo = (ThereIsFO
													And GetFunctionalOption(SelectionByFunctionalOptions.FunctionalOptionName))
												Or BusinessOperationIsAvailableByFo;
			
		EndDo;
		SelectionByFunctionalOptions.Reset();
		If ThereIsFO And Not BusinessOperationIsAvailableByFo Then
			Continue;
		EndIf;
		
		Selection = SelectionByDocuments.Select();
		
		While Selection.Next() Do
			
			MetadataObjectIDRights = RightsByIDs.Get(Selection.MetadataObjectID);
			If MetadataObjectIDRights = Undefined
				Or Not MetadataObjectIDRights.Read Then
				Continue;
			EndIf;
			
			DocumentName = StrSplit(Selection.FullName,".")[1];
			MetadataObject = Metadata.Documents[DocumentName];
			
			DocumentIsAvailableByFO = DocumentAvailabilityByFO.Get(MetadataObject);
				
			If DocumentIsAvailableByFO = Undefined Then
				DocumentIsAvailableByFO = MetadataObjectAvailableByFunctionalOptions(MetadataObject);
				DocumentAvailabilityByFO.Insert(MetadataObject, DocumentIsAvailableByFO);
			EndIf;
			
			If DocumentIsAvailableByFO Then
				
				Filter = New Structure("BusinessOperation, FullDocumentName", Selection.BusinessOperation, Selection.FullName);
				FoundRows = ValueTable.FindRows(Filter);
				For Each String In FoundRows Do
					NewRow = ResultTable2.Add();
					FillPropertyValues(NewRow, String);
					NewRow.MetadataObjectID = Selection.MetadataObjectID;
					NewRow.DocumentPresentation = 
						?(Not IsBlankString(String.DocumentPresentation), String.DocumentPresentation, Selection.Synonym);
					NewRow.AccessRightInsert = MetadataObjectIDRights.Create;
					NewRow.AccessRightUpdate = MetadataObjectIDRights.Update;
				EndDo;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	If FilterBusinessTransactions.Count() = 0
		And FilterDocumentTypes.Count() = 0 Then
		If PurposeUseKey = "" Then
			ResultTable2.FillValues(True, "Filter");
		Else
			For Each String In ResultTable2 Do
				If String.PurposeUseKey = PurposeUseKey Then 
					String.Filter = True;
				EndIf;
			EndDo;
		EndIf;
	Else
		ThereAreEconomicOperationsForSelection = False;
		For Each String In ResultTable2 Do
			If FilterBusinessTransactions.FindByValue(String.BusinessOperation) <> Undefined
				And FilterDocumentTypes.FindByValue(String.MetadataObjectID) <> Undefined Then
				String.Filter = True;
				ThereAreEconomicOperationsForSelection = True;
			EndIf;
		EndDo;
		If Not ThereAreEconomicOperationsForSelection Then
			ResultTable2.FillValues(True, "Filter");
		EndIf;
	EndIf;
	FillInSelectionsAccordingToTableOfBusinessTransactionsAndDocumentTypes(ResultTable2, FilterBusinessTransactions, FilterDocumentTypes);
	
	Return ResultTable2;
	
EndFunction

// Sets the conditional design of the Counterparty field in the journal.
//
// Parameters:
// 	Form - ClientApplicationForm - 
//  FieldName - String - 
//  FieldDataPath - String - 
//
Procedure SetConditionalAppearanceOfFieldWithDocumentRegistryKey(Form, FieldName, FieldDataPath) Export
	
	//
	ConditionalAppearanceItem = Form.ConditionalAppearance.Items.Add();

	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FieldName);

	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(FieldDataPath);
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	EmptyLinkKeys = New ValueList;
	EmptyLinkKeys.LoadValues(TMCommonUseCached.ValuesOfEmptyDocumentRegistryKeys());
	ItemFilter.RightValue = EmptyLinkKeys;

	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", "");
	
EndProcedure

// Function - data on the barcode of the printed form
//
// Parameters:
//	Barcode - String - Barcode
//  BusinessTransactionsAndDocuments	 - 	ValueTable -  table with the column "Full document name"
//  HasMainTable - Boolean - Indicates that the dynamic list has the main table installed
// 
// Returns:
//  Undefined, Structure -
//
Function BarcodeDataOfPrintedForm(Barcode, BusinessTransactionsAndDocuments, HasMainTable = True) Export 
	
	TableOfOperationOverhead = TMCommonUse.SelectedBusinessOperationsAndDocuments(BusinessTransactionsAndDocuments);
	
	DocumentNames = TableOfOperationOverhead.UnloadColumn("FullDocumentName");
	
	BlankRefsArray = New Array();
	
	For Each DocumentName In DocumentNames Do
		EmptyRef = PredefinedValue(DocumentName+".EmptyRef");
		BlankRefsArray.Add(EmptyRef);
	EndDo;
	
	BlankRefsArray = CommonClientServer.CollapseArray(BlankRefsArray);
	
	References = BarcodingOfPrintForms.GetLinkFromBarcodeOfTabularDocument(Barcode, BlankRefsArray);
	
	BarcodeData = Undefined;
	If References.Count() > 0 Then
		
		BarcodeData = New Structure("Ref,RecordKey");
		BarcodeData.Ref = References[0];
		
		If HasMainTable Then
			QueryText =
			"SELECT
			|	DocumentsRegistry.RefType AS RefType,
			|	DocumentsRegistry.BusinessOperation AS BusinessOperation,
			|	DocumentsRegistry.IBDocumentDate AS IBDocumentDate,
			|	DocumentsRegistry.RecordID AS RecordID,
			|	DocumentsRegistry.Organization AS Organization,
			|	DocumentsRegistry.Partner AS Partner,
			|	DocumentsRegistry.StorageLocation AS StorageLocation,
			|	DocumentsRegistry.Counterparty AS Counterparty,
			|	DocumentsRegistry.Department AS Department,
			|	DocumentsRegistry.Ref AS Ref,
			|	DocumentsRegistry.RecordSeparator AS RecordSeparator
			|FROM
			|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
			|WHERE
			|	DocumentsRegistry.Ref = &Ref";
		Else
			QueryText =
			"SELECT
			|	DocumentsRegistry.RefType AS RefType,
			|	DocumentsRegistry.BusinessOperation AS BusinessOperation,
			|	DocumentsRegistry.IBDocumentDate AS Date,
			|	DocumentsRegistry.RecordID AS RecordID
			|FROM
			|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
			|WHERE
			|	DocumentsRegistry.Ref = &Ref";
		EndIf;
		
		Query = New Query(QueryText);
		Query.SetParameter("Ref", References[0]);
		
		Result = Query.Execute();
		If Not Result.IsEmpty() Then
			FoundRow = Result.Unload()[0];
			StructureOfKeyFields = Common.ValueTableRowToStructure(FoundRow);
			If HasMainTable Then
				BarcodeData.RecordKey = InformationRegisters.DocumentsRegistry.CreateRecordKey(StructureOfKeyFields);
			Else
				BarcodeData.RecordKey = New DynamicListRowKey(StructureOfKeyFields);
			EndIf;
		EndIf;
		
	EndIf;
	
	Return BarcodeData;
	
EndFunction

// Fills in selections according to the table of household operations and types of documents.
// 
// Parameters:
//  TableOfValuesAvailable - ValueTable - 
//  FilterBusinessTransactions - ValueList -
//  FilterDocumentTypes - ValueList -
Procedure FillInSelectionsAccordingToTableOfBusinessTransactionsAndDocumentTypes(TableOfValuesAvailable, FilterBusinessTransactions, FilterDocumentTypes) Export
	
	FilterStructure1 = New Structure("Filter", True);
	VTBusinessTransactionsAndDocumentTypes = TableOfValuesAvailable.Copy(FilterStructure1, "BusinessOperation,MetadataObjectID");
	
	VTBusinessTransactions = VTBusinessTransactionsAndDocumentTypes.Copy(,"BusinessOperation");
	VTBusinessTransactions.GroupBy("BusinessOperation");
	FilterBusinessTransactions.LoadValues(VTBusinessTransactions.UnloadColumn("BusinessOperation"));
	
	VTBusinessTransactionsAndDocumentTypes.GroupBy("MetadataObjectID");
	FilterDocumentTypes.LoadValues(VTBusinessTransactionsAndDocumentTypes.UnloadColumn("MetadataObjectID"));
	
EndProcedure

// Adjusts the composition of document management teams 
//
// Parameters:
//  ParametersStructure	 - See TMCommonUse.StructureOfSettingsForDocumentManagementButtons
//
Procedure ConfigureDocumentManagementButtons(ParametersStructure) Export
	
	Form 												= ParametersStructure.Form; // ClientApplicationForm - 
	NameOfTableOfBusinessOperationsAndDocuments 			= ParametersStructure.NameOfTableOfBusinessOperationsAndDocuments;
	NameOfCopyButton 								= ParametersStructure.NameOfCopyButton;
	NameOfCopyContextMenuButton 				= ParametersStructure.NameOfCopyContextMenuButton;
	ChangeButtonName 									= ParametersStructure.ChangeButtonName;
	NameOfChangeContextMenuButton 					= ParametersStructure.NameOfChangeContextMenuButton;
	ButtonNamePost 									= ParametersStructure.ButtonNamePost;
	NameOfHoldContextMenuButton 					= ParametersStructure.NameOfHoldContextMenuButton;
	NameOfCancelEventButton 							= ParametersStructure.NameOfCancelEventButton;
	NameOfCancelButtonIsContextMenu 			= ParametersStructure.NameOfCancelButtonIsContextMenu;
	NameOfMarkDeleteButton 					= ParametersStructure.NameOfMarkDeleteButton;
	ButtonNameMarkDeleteContextMenu 	= ParametersStructure.ButtonNameMarkDeleteContextMenu;
	NameOfCreateGroup 									= ParametersStructure.NameOfCreateGroup;
	GroupNameCreateContext							= ParametersStructure.GroupNameCreateContext;
	ElementPrefix									= ParametersStructure.ElementPrefix;
	
	AccessRightInsert = False;
	AccessRightUpdate  = False;
	
	PickedRows = Form[NameOfTableOfBusinessOperationsAndDocuments].FindRows(New Structure("Filter", True));
	
	For Each String In PickedRows Do
		
		If AccessRightInsert And AccessRightUpdate Then 
			Break;
		EndIf;
		
		AccessRightInsert = ?(String.AccessRightInsert, True, AccessRightInsert);
		AccessRightUpdate  = ?(String.AccessRightUpdate, True, AccessRightUpdate);
		
	EndDo;
	
	CommonClientServer.SetFormItemProperty(
		Form.Items, NameOfCreateGroup, "Visible", AccessRightInsert);
	CommonClientServer.SetFormItemProperty(
		Form.Items, GroupNameCreateContext, "Visible", AccessRightInsert);
	
	CommonClientServer.SetFormItemProperty(
		Form.Items, NameOfCopyButton, "Visible", AccessRightInsert);
	CommonClientServer.SetFormItemProperty(
		Form.Items, NameOfCopyContextMenuButton, "Visible", AccessRightInsert);
	
	CommonClientServer.SetFormItemProperty(
		Form.Items, ChangeButtonName, "Visible", AccessRightUpdate);
	CommonClientServer.SetFormItemProperty(
		Form.Items, NameOfChangeContextMenuButton, "Visible", AccessRightUpdate);
	CommonClientServer.SetFormItemProperty(
		Form.Items, ButtonNamePost, "Visible", AccessRightUpdate);
	CommonClientServer.SetFormItemProperty(
		Form.Items, NameOfHoldContextMenuButton, "Visible", AccessRightUpdate);
	CommonClientServer.SetFormItemProperty(
		Form.Items, NameOfCancelEventButton, "Visible", AccessRightUpdate);
	CommonClientServer.SetFormItemProperty(
		Form.Items, NameOfCancelButtonIsContextMenu, "Visible", AccessRightUpdate);
	CommonClientServer.SetFormItemProperty(
		Form.Items, NameOfMarkDeleteButton, "Visible", AccessRightUpdate);
	CommonClientServer.SetFormItemProperty(
		Form.Items, ButtonNameMarkDeleteContextMenu, "Visible", AccessRightUpdate);
	
	VisibilityOfCreateGroup = CommonClientServer.FormItemPropertyValue(Form.Items, NameOfCreateGroup, "Visible");
	
	If VisibilityOfCreateGroup <> Undefined And VisibilityOfCreateGroup Then
		GenerateCreationCommands_(ParametersStructure);
	EndIf;
	
EndProcedure

// Returns the structure of settings for document management buttons.
// 
// Returns:
//  Structure - Properties:
//		* Form - ClientApplicationForm - this should contain the managed form where the buttons are configured
//		* NameOfTableOfBusinessOperationsAndDocuments - String - name of the form's props, which is a tabular part and stores the household items. transactions, and documents of the workplace
//		* NameOfCopyButton - String - name of the form element (Copy buttons)
//		* ChangeButtonName - String - the name of the form element (buttons to Change)
//		* ButtonNamePost - String - name of the form element (Buttons))
//		* NameOfCancelEventButton - String - name of the form element (undo button))
//		* NameOfMarkDeleteButton - String - name of the form element (set placemark buttons))
//		* NameOfCreateGroup - String - name of the form element (Create group)
//		* MaximumNumberOfCommandsPerSubmenu - Number - maximum number of commands in the submenu
//		* CreateSubmenuTitle - String - allows you to define the title of the "Create" submenu
//
Function StructureOfSettingsForDocumentManagementButtons() Export 
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("Form");
	ParametersStructure.Insert("NameOfTableOfBusinessOperationsAndDocuments", "BusinessTransactionsAndDocuments");
	ParametersStructure.Insert("NameOfCopyButton");
	ParametersStructure.Insert("NameOfCopyContextMenuButton");
	ParametersStructure.Insert("ChangeButtonName");
	ParametersStructure.Insert("NameOfChangeContextMenuButton");
	ParametersStructure.Insert("ButtonNamePost");
	ParametersStructure.Insert("NameOfHoldContextMenuButton");
	ParametersStructure.Insert("NameOfCancelEventButton");
	ParametersStructure.Insert("NameOfCancelButtonIsContextMenu");
	ParametersStructure.Insert("NameOfMarkDeleteButton");
	ParametersStructure.Insert("ButtonNameMarkDeleteContextMenu");
	ParametersStructure.Insert("NameOfCreateGroup", "CreateGroupGenerated");
	ParametersStructure.Insert("GroupNameCreateContext", "CreateGroupGeneratedByContext");
	ParametersStructure.Insert("ElementPrefix", "");
	ParametersStructure.Insert("MaximumNumberOfCommandsPerSubmenu", 7);
	ParametersStructure.Insert("CreateSubmenuTitle", "");
	
	Return ParametersStructure;
		
EndFunction

// Forms the selection label.
// 
// Parameters:
//  HelpTextFilter - FormattedString -
//  BusinessTransactionsAndDocuments - FormDataCollection -
//  FilterDocumentTypes - ValueList - 
//  FilterBusinessTransactions - ValueList - 
Procedure FormInscriptionSelection(HelpTextFilter, BusinessTransactionsAndDocuments, FilterDocumentTypes, FilterBusinessTransactions) Export
	
	ArrayOfLabelLines = New Array();
	
	ThereAreSelections = BusinessTransactionsAndDocuments.FindRows(New Structure("Filter",False)).Count() > 0;
	If ThereAreSelections Then
		
		LabelText = NStr("vi = 'Hiển thị %NumberOfBusinessTransactions% theo %DocumentsCount%';
						|ru = 'Показаны %NumberOfBusinessTransactions% по %DocumentsCount%';
						|en = '%NumberOfBusinessTransactions% shown by %DocumentsCount%'; fa = '%NumberOfBusinessTransactions% shown by %DocumentsCount%';
						|it = 'Mostrati %NumberOfBusinessTransactions% per %DocumentsCount%';
						|pl = 'Pokazane są %NumberOfBusinessTransactions% wg %DocumentsCount%';
						|tr = '%DocumentsCount% göre %NumberOfBusinessTransactions% gösteriliyor'");
		
		NumberOfBusinessTransactions = StringFunctionsClientServer.NumberInDigitsUnitOfMeasurementInWords(FilterBusinessTransactions.Count(),NStr("vi = 'giao dịch, giao dịch, giao dịch';
																																					|ru = 'хоз. операция, хоз. операции, хоз. операций';
																																					|en = 'business transaction, business transactions, business transactions'; fa = 'business transaction, business transactions, business transactions';
																																					|it = 'Operazone commerciale, Operazioni commerciali, operazioni commerciali';
																																					|pl = 'operacja gosp., operacje gosp., operacji gosp.';
																																					|tr = 'ticari işlem, ticari işlemler, ticari işlemlerin'"));
		LabelText = StrReplace(LabelText,"%NumberOfBusinessTransactions%", NumberOfBusinessTransactions);
		NumberOfDocumentTypes = StringFunctionsClientServer.NumberInDigitsUnitOfMeasurementInWords(FilterDocumentTypes.Count(),NStr("vi = 'chứng từ,chứng từ,chứng từ';
																																	|ru = 'документу, документам, документам';
																																	|en = 'document, documents, documents'; fa = 'document, documents, documents';
																																	|it = 'Documento, documenti, documenti';
																																	|pl = 'dokumentowi, dokumentom, dokumentom';
																																	|tr = 'belgeye, belgelere, belgelere'"));
		LabelText = StrReplace(LabelText,"%DocumentsCount%", NumberOfDocumentTypes);
		
		ArrayOfLabelLines.Add(LabelText);
		
		ArrayOfLabelLines.Add("  ");
		
		ArrayOfLabelLines.Add(New FormattedString(NStr("vi = 'Tùy chỉnh';
														|ru = 'Настроить';
														|en = 'Set up'; fa = 'تنظیم';
														|it = 'Impostare';
														|pl = 'Set up';
														|tr = 'Ayarla'"),,,,"ConfigureFilter"));
		
	Else
		
		ArrayOfLabelLines.Add(NStr("vi = 'Hiển thị tất cả chứng từ';
									|ru = 'Показаны все документы журнала';
									|en = 'All log documents are shown'; fa = 'All log documents are shown';
									|it = 'Mostrati tutti i documento del registro';
									|pl = 'Są pokazane wszystkie dokumenty dziennika';
									|tr = 'Tüm belgeler görüntüleniyor'"));
		ArrayOfLabelLines.Add("  ");
		ArrayOfLabelLines.Add(New FormattedString(NStr("vi = 'Tùy chỉnh';
														|ru = 'Настроить';
														|en = 'Set up'; fa = 'تنظیم';
														|it = 'Impostare';
														|pl = 'Set up';
														|tr = 'Ayarla'"),,,,"ConfigureFilter"));
		
	EndIf;
	
	HelpTextFilter = New FormattedString(ArrayOfLabelLines);
	
EndProcedure

// Processes the multilingual row of the column value table additionally from the document registry
//
// Parameters:
//  ColumnName - String - Column name
//  Table - Assignment tables
//
Procedure ProcessMultilingualColumnOfTableOfValues(Table, ColumnName = "More") Export
	
	If Table.Columns.Find(ColumnName) = Undefined Then
		Return;
	EndIf;
	
	For Each String In Table Do
		ColumnValue = String[ColumnName]; // String -
		If IsBlankString(ColumnValue) Then
			Continue;
		EndIf;
		If StringAsNstr(ColumnValue) Then
			String[ColumnName] = NStr(ColumnValue);
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region MethodsOfWorkingWithRequest

// Executes the request by forming the request text from the list of request text. 
// 
// Parameters:
// 	Query - Query - Request.
// 	QueryTexts - ValueList - The value contains the text of the query, the view contains the name of the request.
// 	AddSeparator - Boolean - Add a request packet separator.
// 	DestroyCreatedTemporaryTables - Boolean - Destroy the created temporary tables
// 	
// Returns:
// 	Undefined, Array - query result.
Function ExecuteBatchOfRequests(Query, QueryTexts, AddSeparator = True, DestroyCreatedTemporaryTables = False) Export
	
	Results = New Array;
	
	QueryTextArray 	 = New Array;
	ArrayOfTablesToDestroy = New Array;
	
	DebugMode = Common.DebugMode();
	CloseTemporaryTableManager = False;
	If DebugMode And Query.TempTablesManager = Undefined Then
		Query.TempTablesManager = New TempTablesManager; 
		CloseTemporaryTableManager = True;
	EndIf;
	
	RunPerformanceMeasurements = PerformanceMonitorServerCallCached.RunPerformanceMeasurements();
	
	If DebugMode And RunPerformanceMeasurements Then
		MetadataObjectName = "";
		If Query.Parameters.Property("Ref") Then
			If TypeOf(Query.Parameters.Ref) = Type("Array") Then
				MetadataObjectName = Query.Parameters.Ref[0].Metadata().FullName();
			Else
				MetadataObjectName = Query.Parameters.Ref.Metadata().FullName();
			EndIf;
		EndIf;
	EndIf;
	
	For Each QueryText In QueryTexts Do
		
		// Made for the convenience of debugging.
		If DebugMode Then
			
			Query.Text = QueryText.Value;
			
			If RunPerformanceMeasurements And ValueIsFilled(MetadataObjectName) And ValueIsFilled(QueryText.Presentation) Then
				BeginTime = PerformanceMonitor.StartTimeMeasurement();
				KeyOperation = MetadataObjectName + "." + "QueryPackage." + QueryText.Presentation;
				QueryPackage = Query.ExecuteBatch();
				PerformanceMonitor.EndTimeMeasurement(KeyOperation, BeginTime,,, True);
			Else
				QueryPackage = Query.ExecuteBatch();
			EndIf;
			
			CommonClientServer.SupplementArray(Results, QueryPackage);
			
		Else
			
			If ValueIsFilled(QueryText.Presentation) Then
				QueryTextArray.Add("// " + QueryText.Presentation);
			EndIf; 
			
			QueryTextArray.Add(QueryText.Value + ?(AddSeparator, Common.QueryBatchSeparator(), ""));
			
		EndIf;
		
		If DestroyCreatedTemporaryTables
		 And ValueIsFilled(QueryText.Presentation)
		 And StrFind(Upper(QueryText.Value), "INTO") <> 0 Then
			ArrayOfTablesToDestroy.Add(QueryText.Presentation);
		EndIf;
		
	EndDo;
		
	For Each NameOfTableToDelete In ArrayOfTablesToDestroy Do
		
		If DebugMode Then
			
			Query.Text = StrTemplate("DROP %1", NameOfTableToDelete);
			Results.Add(Query.Execute());
			
		Else
			
			QueryTextArray.Add("DROP " + NameOfTableToDelete + Common.QueryBatchSeparator());
			
		EndIf;
		
	EndDo;
	
	If QueryTextArray.Count() > 0 Then
		
		Query.Text = StrConcat(QueryTextArray, Chars.LF);
		Results = Query.ExecuteBatch();
		
	EndIf;
	
	If CloseTemporaryTableManager Then
		Query.TempTablesManager.Close();
	EndIf;
	
	Return Results;
	
EndFunction

// Generates a batch of queries and returns the result of each query as a table of values.
//
// Parameters:
//	Query			- Query - a request whose parameters are pre-set.
//	QueryTexts	- ValueList - the list shows the text of the query and their names.
//	ResultTraversal - QueryResultIteration - option to bypass the query result.
//	AddSeparator - Boolean - add a separator between queries from the query Text
//	DestroyCreatedTemporaryTables - Boolean - add destruction of temporary tables created in query Text
//										To be destroyed, the table must be given a name in the query Text.
//
// Returns:
//   Structure   - the structure in which the resulting tables are placed.
//
Function UploadResultsOfQuery(Query,
								 	QueryTexts,
									ResultTraversal = Undefined,
									AddSeparator = False,
									DestroyCreatedTemporaryTables = False) Export
	
	Tables = New Structure;
	
	// Initialization of the crawling option of the query result.
	If ResultTraversal = Undefined Then
		ResultTraversal = QueryResultIteration.Linear;
	EndIf;
	
	Results = ExecuteBatchOfRequests(Query, QueryTexts, AddSeparator, DestroyCreatedTemporaryTables);
	
	If Results <> Undefined Then
		
		// Putting query results in tables.
		For Each QueryText In QueryTexts Do
			TableName = QueryText.Presentation;
			If Not IsBlankString(TableName) Then // table name
				Result = Results[QueryTexts.IndexOf(QueryText)];
				If Result <> Undefined Then
					QueryTable = Result.Unload(ResultTraversal);
					Tables.Insert(TableName, QueryTable);
				EndIf;
			EndIf;

		EndDo;
		
	EndIf;
	
	Return Tables;
	
EndFunction

// Generates a batch of requests and returns the result of each request as the result of the request.
//
// Parameters:
//	Query			- Query - a request whose parameters are pre-set.
//	QueryTexts	- ValueList - the list shows the text of the query and their names.
//	AddSeparator - Boolean - add a separator between queries from the query Text
//	DestroyCreatedTemporaryTables - Boolean - add destruction of temporary tables created in query Text
//										To be destroyed, the table must be given a name in the query Text.
//
// Returns:
// 	Structure of KeyAndValue - Contains: 
// 		* Key - String - Request Name
//		* Value - QueryResult - query result
//
Function GetQueryResults(Query,
								 	QueryTexts,
									AddSeparator = True,
									DestroyCreatedTemporaryTables = False) Export
	
	QueryResults = New Structure;

	Results = ExecuteBatchOfRequests(Query, QueryTexts, AddSeparator, DestroyCreatedTemporaryTables);

	If Results = Undefined Then
		Return QueryResults;
	EndIf;
			
	ResultIndex = -1;
	For Each QueryText In QueryTexts Do
		
		TableName = QueryText.Presentation;
		QueryPackage = StrSplit(TrimAll(QueryText.Value), ";", False);
		ResultIndex = ResultIndex + QueryPackage.Count(); 

		If Not IsBlankString(TableName) Then
			Result = Results[ResultIndex];
			QueryResults.Insert(TableName, Result);
		EndIf;

	EndDo;
	
	Return QueryResults;

EndFunction

// Returns the structure of the speed limits by register
//
// Parameters:
//  RegisterName - String - Name of the accumulation register.
//  Filters      - String - Selections of the virtual turnover table for which you want to get borders.
//  Parameters   - Structure - Request parameters for selection of the virtual table.
//
// Returns:
//  Structure - Border structure with properties:
//  	* MinDate - Date - The initial boundary of the momentum.
//  	* MaxDate - Date - The end boundary of the momentum.
//
Function BoundariesOfRegisterTurns(RegisterName, Filters, Parameters) Export
	
	// Without default selection by the Activity field, because there is no index
	// for it, which is why the query can be executed for an unacceptably long time.
	QueryText = 
	"SELECT
	|	MIN(Table.Period)  AS MinDate,
	|	MAX(Table.Period) AS MaxDate
	|FROM
	|	&TableName AS Table
	|WHERE
	|	&Filter";
	QueryText = StrReplace(QueryText, "&TableName", "AccumulationRegister." + RegisterName);
	QueryText = StrReplace(QueryText, "&Filter", ?(IsBlankString(Filters), "TRUE", Filters));
	
	Query = New Query(QueryText);
	For Each Parameter In Parameters Do
		Query.SetParameter(Parameter.Key, Parameter.Value);
	EndDo;
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	BoundaryStructure = New Structure;
	If Selection.Next() And ValueIsFilled(Selection.MinDate) Then
		BoundaryStructure.Insert("MinDate", Selection.MinDate);
		BoundaryStructure.Insert("MaxDate", Selection.MaxDate);
	Else
		BoundaryStructure.Insert("MinDate", '00010101');
		BoundaryStructure.Insert("MaxDate", '39991231');
	EndIf;
	
	Return BoundaryStructure;
	
EndFunction

// Deprecated. General purpose should be used.Delimiterpackage of queries.
// Returns the delimiter text to insert between the request package texts.
//
// Returns:
//  String - separator text.
//
Function RequestSeparatorInPacket_() Export
	
	Return "
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
EndFunction

// Returns the delimiter text to insert between the combined query texts.
//
// Parameters:
//  OnlyUniqueOnes - Boolean - indicates that only unique records should be selected when merging.
//
// Returns:
//  String - separator text.
//
Function QuerySeparatorInJoin(OnlyUniqueOnes = False) Export
	
	If OnlyUniqueOnes Then
		Return "
		|
		|UNION
		|
		|";
	Else
		Return "
		|
		|UNION ALL
		|
		|";
	EndIf;
	
EndFunction

//Adds a selection setting for queries to the collection 
//
// Parameters:
//  Filter               - Map of Structure - collection of selection settings
//  LeftValue       - String       - left selection value in queries
//  RightValue      - String       - right-the value of the selection in queries
//  TypeOfRequestComparison - String       - query comparison type, by default: "In"
//
Procedure AddSelectionItemToCollection(Filter, LeftValue, RightValue, TypeOfRequestComparison = "") Export
	
	TMCommonUseClientServer.AddSelectionItemToCollection(Filter, LeftValue, RightValue, TypeOfRequestComparison);
	
EndProcedure

// Adds the key details of the order to the selection collection
// 
// Parameters:
// 	KeyAttributes - Array
// 	Filter - Map
//
Procedure AddSelectionBasedOnKeyOrderDetails(KeyAttributes, Filter) Export
	
	For Each CurProps In KeyAttributes Do
		
		AddSelectionItemToCollection(
			Filter,
			"TableOfOrders." + CurProps,
			"&" + CurProps,
			"=");
		
	EndDo;
	
EndProcedure

// Generates the text of the query conditions for the selection collection
// 
// Parameters:
// 	Filter - Map
// Returns:
// 	String
//
Function SelectionTextBySelectionCollection(Filter) Export
	
	FilterText1 = "TRUE";
	
	If TypeOf(Filter) = Type("Structure")
		Or TypeOf(Filter) = Type("Map") Then
		
		For Each CurrFilter In Filter Do
			
			LeftValue = "(" + CurrFilter.Key + ") ";
			
			If TypeOf(CurrFilter.Value) = Type("Structure")
				Or TypeOf(CurrFilter.Value) = Type("Map") Then
				TypeOfRequestComparison = CommonClientServer.StructureProperty(CurrFilter.Value, "ComparisonType", "In");
				RightValue = CommonClientServer.StructureProperty(CurrFilter.Value, "RightValue", "TRUE");
			Else
				TypeOfRequestComparison = "In";
				RightValue = "&" + CurrFilter.Value;
			EndIf;
			
			FilterText1 =
				FilterText1 + " And "
				+ LeftValue
				+ TypeOfRequestComparison
				+ " (" + RightValue + ")";
				
		EndDo;
		
	EndIf;
	
	Return FilterText1;
	
EndFunction

// Generates the text of the request to receive data from the tabular part of the document
// 
// Parameters:
// 	Ref - AnyRef
// 	TSName - String
// 	DataFromInformationSecurity - Boolean - a flag that determines where the data of the tabular part will be received from - from the IB, or from the query parameter
// 	IndexFields - String, Array - the list of fields for which the index of the temporary table will be built
// 	FieldNameCanceled - String
// Returns:
// 	String - the text of the request to receive data from the tabular part of the document
//
Function RequestTextObjectTSData(Ref, TSName, DataFromInformationSecurity, IndexFields = "", FieldNameCanceled = "Canceled") Export
	
	QueryText =
	"SELECT
	|	&SelectionFields1
	|INTO TSName
	|FROM
	|	TextDataSource AS TabularSection
	|WHERE
	|	&FilterByReference_
	|	AND &IsCanceled
	|";
	
	TabularSection = Ref.Metadata().TabularSections[TSName];
	SelectionFields1    = New Array;
	IsCanceled   = False;
	
	FieldPattern = "TabularSection.%1 AS %2";
	For Each CurProps In TabularSection.StandardAttributes Do
		SelectionFields1.Add(StrTemplate(FieldPattern, CurProps.Name, CurProps.Name));
	EndDo;
	
	For Each CurProps In TabularSection.Attributes Do
		
		If CurProps.Name = FieldNameCanceled Then
			IsCanceled = True;
		EndIf;
		
		SelectionFields1.Add(StrTemplate(FieldPattern, CurProps.Name, CurProps.Name));
		
	EndDo;
	
	TextDataSource = "&" + TSName;
	LinkSelectionText = "TRUE";
	
	If DataFromInformationSecurity Then
		TextDataSource = StrTemplate(TextDataSource, ProcessingOfFormulas.FullNameOfDataTable(TabularSection));
		LinkSelectionText = "TabularSection.Ref IN(&Ref)";
	EndIf;
	
	TextIsCanceled = "TRUE";
	If IsCanceled Then
		TextIsCanceled = "NOT TabularSection.Canceled";
	EndIf;
	
	QueryText = StrReplace(QueryText, "TextDataSource", TextDataSource);
	QueryText = StrReplace(QueryText, "&FilterByReference_",      LinkSelectionText);
	QueryText = StrReplace(QueryText, "TSName",               TSName);
	QueryText = StrReplace(QueryText, "&SelectionFields1", StrConcat(SelectionFields1, "," + Chars.LF));
	QueryText = StrReplace(QueryText, "&IsCanceled", TextIsCanceled);
	
	If TypeOf(IndexFields) = Type("Array") Then
		IndexFields = StrConcat(IndexFields, ",");
	EndIf;
	
	If ValueIsFilled(IndexFields) Then
		QueryText =
			QueryText + Chars.LF +
			"INDEX BY
			|" + IndexFields;
	EndIf;
	
	Return QueryText;
	
EndFunction

// Generates the Query Text for retrieving data from the value table. In this case, untyped columns will be excluded from processing.
// 
// Parameters:
// 	Table - ValueTable - the original table of values
// 	TempTableName - String - name of the temporary table being generated
// 	IndexFields - String, Array - the list of fields for which the index of the temporary table will be built
// Returns:
// 	String - Query Text for getting data from the value table
//
Function QueryTextDataFromValueTable(Table, TempTableName, IndexFields = "") Export
	
	QueryText =
	"SELECT
	|	&SelectionFields1
	|INTO TempTableName
	|FROM
	|	&TempTableName AS Table
	|";
	
	SelectionFields1 = New Array;
	
	FieldPattern = "Table.%1 AS %1";
	For Each Column In Table.Columns Do
		If ValueIsFilled(Column.ValueType) Then
			SelectionFields1.Add(StringFunctionsClientServer.SubstituteParametersToString(FieldPattern, Column.Name));
		EndIf;
	EndDo;
	
	QueryText = StrReplace(QueryText, "TempTableName", TempTableName);
	QueryText = StrReplace(QueryText, "&SelectionFields1", StrConcat(SelectionFields1, "," + Chars.LF + Chars.Tab));
	
	If TypeOf(IndexFields) = Type("Array") Then
		IndexFields = StrConcat(IndexFields, "," + Chars.LF + Chars.Tab);
	EndIf;
	
	If ValueIsFilled(IndexFields) Then
		QueryText = QueryText + Chars.LF +
			"INDEX BY
			|" + IndexFields;
	EndIf;
	
	Return QueryText;
	
EndFunction

// Structure of parameters for the formation of the text of the request for orders invoices
// 
// Returns:
//  Structure - LongDesc:
//		* NamesOfInvoiceDetails - Structure -
//		* Filter - Map -
//		* TTName - String -
//		* GenerateTT - Boolean -
//
Function ParametersOfRequestTextForOrdersInvoices() Export
	
	Result = New Structure;
	Result.Insert("GenerateTT", False);
	Result.Insert("TTName", "WaybillOrders");
	Result.Insert("Filter", New Map);
	
	Return Result;
	
EndFunction

// Generates a list of temporary tables.
//
// Parameters:
//  TempTablesManager	 - TempTablesManager	 - the temporary table Manager whose tables you want to get.
// 
// Returns:
//  Array - Temporary tables located in the manager.
//
Function ListOfTemporaryTables(TempTablesManager) Export

	ListOfTemporaryTables = New Array;
	
	For Each Table In TempTablesManager.Tables Do
		ListOfTemporaryTables.Add(Table.FullName);
	EndDo; 
	
	Return ListOfTemporaryTables;

EndFunction

// Destroys temporary tables of the temporary table Manager.
//
// Parameters:
//  TempTablesManager	 - TempTablesManager	 - a temporary table Manager whose tables need to be destroyed.
//  TablesList - String, Array of String - names of temporary tables to destroy, separated by commas. If the parameter is not set - all tables.
//  ExcludingTables	- String, Array of String - the names of temporary tables to be left, separated by commas.
//
Procedure DestroyTemporaryTables(TempTablesManager, TablesList = Undefined, ExcludingTables = Undefined) Export
	
	If ExcludingTables <> Undefined Then
		ArrayOfExcludedTables = ?(TypeOf(ExcludingTables) = Type("Array"), ExcludingTables, StrSplit(ExcludingTables, ","));
	Else
		ArrayOfExcludedTables = New Array();
	EndIf;
	
	If TablesList <> Undefined Then
		ArrayOfTables = ?(TypeOf(TablesList) = Type("Array"), TablesList, StrSplit(TablesList, ","));
	Else
		ArrayOfTables = New Array();
		For Each Table In TempTablesManager.Tables Do
			If ArrayOfExcludedTables.Find(Table.FullName) = Undefined Then
				ArrayOfTables.Add(Table.FullName);
			EndIf;
		EndDo;
	EndIf;
	
	If ArrayOfTables.Count() > 0 Then
		QueryText = "";
		For Each TableName In ArrayOfTables Do
			QueryText = QueryText + "DROP " + TableName + "; ";
		EndDo;
		Query = New Query(QueryText);
		Query.TempTablesManager = TempTablesManager;
		Query.Execute();
	EndIf;
	
EndProcedure

// Query text converter with temporary tables - if there is a field, it is selected, if not, the text
// is replaced with the default value. In the text of the request, the field should be in the form of &textfields & tablefields_
// (it starts with "&Text Field", then the name of the query data source table, then the actual field name and "_").
//
// Parameters:
//	TempTablesManager	 - TempTablesManager -Manager of temporary query tables.
//	QueryText			 - String - the text of the request in which the conversion is performed.
//	ReplacementText				 - String - the replaced text of the request.
//	TableName				 - String - the name of the temporary table for which the text conversion is being performed.
//	FieldName					 - String - the name of the field that it checks for in the temporary table.
//	SampleText	 - String - expression of the field selection in the query text. The default value is an empty string.
//										If the value is not specified, the table name is selected.Field name.
//	DefaultValueText - String - the default value of the field. If not specified, then the default value is "UNDEFINED".
//
Procedure ReplaceMissingTTFieldsInQueryText(TempTablesManager,
													QueryText,
													ReplacementText,
													TableName,
													FieldName,
													SampleText = "",
													DefaultValueText = "UNDEFINED") Export
	
	TempTable = TempTablesManager.Tables[TableName]; // QueryTempTable -
	
	If TempTable.Columns.Find(FieldName) <> Undefined Then
		QueryText = StrReplace(QueryText,
									ReplacementText,
									?(IsBlankString(SampleText),
										TableName + "." + FieldName,
										SampleText));
	Else
		QueryText = StrReplace(QueryText,
									ReplacementText,
									DefaultValueText);
	EndIf;
	
EndProcedure

// The converter of the query text, the data source of which is a table of values.
// If there is a field, it is selected, if not, the text is replaced with the default value.
// In the query text, the field should be in the form of a &textfield_name (it starts with "&Textfields", then the name
// of the query data source table, then the actual field name and "_").
//
// Parameters:
//	Table					 - ValueTable, TabularSection - the data source table for the query text.
//	QueryText			 - String - the text of the request in which the conversion is performed.
//	ReplacementText				 - String - the replaced text of the request.
//	TableName				 - String - the name of the data source table in the query for which the text conversion is performed.
//	FieldName					 - String - the name of the field that it checks for in the value table.
//	SampleText	 - String - expression of the field selection in the query text. The default value is an empty string.
//										If the value is not specified, the table name is selected.Field name.
//	DefaultValueText - String - the default value of the field. If not specified, then the default value is "UNDEFINED".
//
Procedure ReplaceMissingValueTableFieldsInQueryText(Val Table,
																QueryText,
																ReplacementText,
																TableName,
																FieldName,
																SampleText = "",
																DefaultValueText = "UNDEFINED") Export
	
	If TypeOf(Table) <> Type("ValueTable") Then
		Table = Table.UnloadColumns();
	EndIf;
	
	If Table.Columns.Find(FieldName) <> Undefined Then
		QueryText = StrReplace(QueryText,
									ReplacementText,
									?(IsBlankString(SampleText),
										TableName + "." + FieldName,
										SampleText));
	Else
		QueryText = StrReplace(QueryText,
									ReplacementText,
									DefaultValueText);
	EndIf;
	
EndProcedure

// Generates the text of the amount distribution in the request.
// 
// Parameters:
//  NameOfAmountField - String - Name of the field containing the amount to distribute
//  NameOfBaseField - String - Name of the field containing the distribution coefficient
//  NameOfAccumulatedDatabaseField - String - Name of the field containing the sum of the coefficients of the previous lines
//  NameOfDatabaseAmountField - String - Name of the field containing the sum of all coefficients
// 
// Returns:
//  String - Amount Distribution Text
Function AmountDistributionText(NameOfAmountField, NameOfBaseField = Undefined, NameOfAccumulatedDatabaseField = Undefined, NameOfDatabaseAmountField = Undefined) Export

	If NameOfBaseField = Undefined Then
		NameOfBaseField = "ISNULL(WaysToReflectExpenses.Base, 0)";
	EndIf;
	
	If NameOfAccumulatedDatabaseField = Undefined Then
		NameOfAccumulatedDatabaseField = "ISNULL(WaysToReflectExpenses.BaseAccumulated, 0)";
	EndIf;
	
	If NameOfDatabaseAmountField = Undefined Then
		NameOfDatabaseAmountField = "ISNULL(WaysToReflectExpenses.BaseAmount, 0)";
	EndIf;
	
	QueryText =	
	"	CASE
	|		WHEN (&BaseAmount_Pattern) = 0
	|			THEN 0
	|		ELSE (CAST(&Sum_Pattern
	|				* (&AccumulatedDatabase_Template + &Base_Template) 
	|					/ &BaseAmount_Pattern AS NUMBER(31,2)))
	|			- (CAST(&Sum_Pattern * &AccumulatedDatabase_Template / &BaseAmount_Pattern AS NUMBER(31,2)))
	|	END";
	
	QueryText = StrReplace(QueryText, "&BaseAmount_Pattern", NameOfDatabaseAmountField);
	QueryText = StrReplace(QueryText, "&Sum_Pattern", NameOfAmountField);
	QueryText = StrReplace(QueryText, "&AccumulatedDatabase_Template", NameOfAccumulatedDatabaseField);
	QueryText = StrReplace(QueryText, "&Base_Template", NameOfBaseField);
	
	Return QueryText;

EndFunction

#EndRegion

#Region GlobalSearch

// Finds documents in the document registry and complements the global search result.
// 
// Parameters:
//  SearchString - String - the string that the user entered
//  SearchResult - GlobalSearchResult - augmented search result
Procedure FindDocumentInRegistry(SearchString, SearchResult) Export
	
	Words = StrSplit(SearchString, " ", False);
	
	CombineDateAndTime(Words);
	
	If Words.Count() > 3 Then
		DocumentDate = DateFromString(Words.Get(Words.UBound()));
// Name Number from Date
		If ValueIsFilled(DocumentDate) Then
			If (Upper(Words.Get(Words.UBound() - 1)) = NStr("vi = 'NGÀY';
															|ru = 'ОТ';
															|en = 'DATED'; fa = 'DATED';
															|it = 'DEL';
															|pl = 'DATED';
															|tr = 'İTİBAREN'")
				Or Upper(Words.Get(Words.UBound() - 1)) = "DATED") Then
				WordsOfTitle = New Array;
				For IndexOf = 0 To Words.UBound() - 3 Do
					WordsOfTitle.Add(Words.Get(IndexOf));
				EndDo;
				DocumentName3 = StrConcat(WordsOfTitle, " ");
				For Each MetadataObject In Metadata.Documents Do
					If Upper(MetadataObject.Synonym) = Upper(DocumentName3) Then
						RefType = Common.MetadataObjectID("Document." + MetadataObject.Name);
						Break;
					EndIf;
				EndDo;
				SelectDocumentsFromRegistry(SearchResult, Words.Get(Words.UBound() - 2), RefType,
					DocumentName3, DocumentDate);
			EndIf;
		Else
// Name Number
			FindDocumentInRegistryByNameAndNumber(Words, SearchResult)
		EndIf;
	ElsIf Words.Count() = 3 Then
		DocumentDate = DateFromString(Words.Get(Words.UBound()));
		If ValueIsFilled(DocumentDate) Then
			If (Upper(Words.Get(Words.UBound() - 1)) = NStr("vi = 'NGÀY';
															|ru = 'ОТ';
															|en = 'DATED'; fa = 'DATED';
															|it = 'DEL';
															|pl = 'DATED';
															|tr = 'İTİBAREN'")
				Or Upper(Words.Get(Words.UBound() - 1)) = "DATED") Then
// Number from Date
				SelectDocumentsFromRegistry(SearchResult, Words.Get(0), , , DocumentDate);
			EndIf;
		Else
// Name Number
			FindDocumentInRegistryByNameAndNumber(Words, SearchResult)
		EndIf;
	ElsIf Words.Count() = 2 Then
// Name Number
		FindDocumentInRegistryByNameAndNumber(Words, SearchResult)
	ElsIf Words.Count() = 1 And StringContainsDigit(Words.Get(0)) Then
// Number
		SelectDocumentsFromRegistry(SearchResult, Words.Get(0));
	EndIf;
	
EndProcedure

#EndRegion

#Region StringOperations

// Forms the beginning of the line in accordance with the platform search
// 
// Parameters:
//  InitialString - String - Which needs to be issued
//  SearchString - String - Defines the number of characters that need to be formatted. 
//  	If the beginning of the source line, case-insensitive, does not contain a search string, then registration is not performed.
// 
// Returns:
//  FormattedString - The Decorated Line
Function RowToMarkBeginningOfLineWithLayout(InitialString, SearchString) Export
	
	CountOfCharacters = StrLen(SearchString);
	PartBeingProcessed = Left(InitialString, CountOfCharacters);
	
	If Upper(PartBeingProcessed) <> Upper(SearchString) Then
		
		Return New FormattedString(InitialString);
		
	EndIf;
	
	PartBeingProcessed = New FormattedString(PartBeingProcessed, StyleFonts.BoldFont, StyleColors.AccentColor);
	UnformedPart = Mid(InitialString, CountOfCharacters + 1);
	
	DecoratedLine = New FormattedString(PartBeingProcessed, UnformedPart);
	
	Return DecoratedLine;
	
EndFunction
#EndRegion

#Region MathematicalFunctions

// Performs a proportional distribution of the amount according
// to the specified distribution coefficients.
//
// Parameters:
//  AmountToDistribute - Number  - the amount to distribute, if the amount is 0, it is returned Undefined;
//                                 If you pass in a negative calculation in the module after inversion of the signs of the result.
//  Coefficients        - Array of Number - The distribution coefficients can be positive or negative
//  Accuracy            - Number  - rounding precision in the distribution. Optional.
//
// Returns:
//  Array of Number - an array of dimension equal to the array of coefficients contains
//           sums in accordance with the weight of the coefficient (from the array of coefficients).
//           In case it is impossible to distribute,
//           then it will be returned Undefined.
//
// Example:
//
//	Coefficients = New Array;
//	Coefficients.Add(-1);
//	Coefficients.Add(2);
//	Result = General purpose.Distribute the sum of the disproportionately different sign coefficients(1, Coefficients); // Result = [-1, 2].
//
Function DistributeSumProportionallyToCoefficientsOfDifferentSigns(Val AmountToDistribute, Val Coefficients, Val Accuracy = 2) Export
	
	If Not ValueIsFilled(AmountToDistribute) Then
		Return Undefined;
	EndIf;
	
	If Coefficients.Count() = 0 Then
		// The value of the Coefficients parameter is invalid
		// Expected: at least one coefficient will be set.
		Return Undefined;
	EndIf;
	
	MaxCoefficientIndex = 0;
	MaxCoefficient = 0;
	CoefficientsSum = 0;
	
	For IndexOf = 0 To Coefficients.Count() - 1 Do
		
		ZoomRatio = Coefficients[IndexOf];
		
		If MaxCoefficient < ZoomRatio
			Or MaxCoefficient = 0 Then
			
			MaxCoefficient = ZoomRatio;
			MaxCoefficientIndex = IndexOf;
			
		EndIf;
		
		CoefficientsSum = CoefficientsSum + ZoomRatio;
		
	EndDo;
	
	If CoefficientsSum = 0 Then
		// Invalid value for the Coefficients parameter
		// Expected: the total sum of the coefficients is not zero
		Return Undefined;
	EndIf;
	
	Result = New Array(Coefficients.Count());
	
	DistributedAmount = 0;
	
	For IndexOf = 0 To Coefficients.Count() - 1 Do
		Result[IndexOf] = Round(AmountToDistribute * Coefficients[IndexOf] / CoefficientsSum, Accuracy, 1);
		DistributedAmount = DistributedAmount + Result[IndexOf];
	EndDo;
	
	CombinedInaccuracy = AmountToDistribute - DistributedAmount;
	
	// The rounding errors are attributed to the coefficient with the maximum weight.
	If ValueIsFilled(CombinedInaccuracy) Then
		Result[MaxCoefficientIndex] = Result[MaxCoefficientIndex] + CombinedInaccuracy;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region ObsoleteProceduresAndFunctions

// Deprecated. You should use a general purpose.Delete Table rows
// Deletes the specified rows from the value table.
// 
// Parameters:
//	Table - ValueTable - table being processed
//	Rows  - Array of ValueTableRow - Array of rows to delete
//
Procedure DeleteRowsInValueTable(Table, Rows) Export
	
	For Each TableRow In Rows Do
		Table.Delete(TableRow);
	EndDo;
	
EndProcedure

#EndRegion

// Returns a representation of the passed object.
//
// Parameters:
//	ParameterObject - String - 
//	               - MetadataObject - object to get a view of
//
// Returns:
//	String - Representation of objects
//
Function ObjectPresentation(ParameterObject) Export
	
	If ParameterObject = Undefined Then
		Return "";
	EndIf;
	ObjectMetadata = ?(TypeOf(ParameterObject) = Type("String"), Metadata.FindByFullName(ParameterObject), ParameterObject);
	
	Presentation = New Structure("ObjectPresentation");
	FillPropertyValues(Presentation, ObjectMetadata);
	If Not IsBlankString(Presentation.ObjectPresentation) Then
		Return Presentation.ObjectPresentation;
	EndIf;
	
	Return ObjectMetadata.Presentation();
	
EndFunction

// The software performs a recursive copy of the form elements.
// The new elements will be bound to the same data as the original ones.
// For new elements, the same event handlers will be connected as for the original ones.
//
// Parameters:
// 	Form - ClientApplicationForm - The form to copy elements to.
// 	Source - FormGroup - The group whose subordinate elements need to be copied.
// 	Receiver - FormGroup - The group to which you want to add new items.
// 	Postfix - String - The Postfix that will be added to the names of new elements.
//
Procedure CopyFormElementsRecursively(Form, Source, Receiver, Postfix) Export
	
	CopiedPropertiesOfFormElements = CopiedPropertiesOfFormElements();
	CopiedEventHandlers = CopiedFormElementHandlers();
	
	For Each SubordinateItem In Source.ChildItems Do
		
		ElementType = TypeOf(SubordinateItem);
		
		NewItem = Form.Items.Add(
							SubordinateItem.Name + Postfix,
							TypeOf(SubordinateItem),
							Receiver);
		
		CopiedElementProperties = CopiedPropertiesOfFormElements[ElementType];
		If CopiedElementProperties = Undefined Then
			FillPropertyValues(NewItem, SubordinateItem);
		Else
			For Each ItemProperty In CopiedElementProperties Do
				If Not CommonClientServer.HasAttributeOrObjectProperty(SubordinateItem, ItemProperty) Then
					Continue;
				EndIf;
				If SubordinateItem[ItemProperty] = ""
						Or SubordinateItem[ItemProperty] = Undefined Then
					Continue;
				EndIf;
				NewItem[ItemProperty] = SubordinateItem[ItemProperty];
			EndDo;
		EndIf;
		
		CopiedElementHandlers = CopiedEventHandlers[ElementType];
		If CopiedElementHandlers <> Undefined Then
			For Each EventName In CopiedElementHandlers Do
				ProcedureName = SubordinateItem.GetAction(EventName);
				If ProcedureName <> "" Then
					NewItem.SetAction(EventName, ProcedureName);
				EndIf;
			EndDo;
		EndIf;
		
		If ElementType = Type("FormTable") Then
			CopyFormElementsRecursively(
				Form, SubordinateItem.CommandBar, NewItem.CommandBar, Postfix);
		EndIf;
		
		If ElementType = Type("FormGroup")
				Or ElementType = Type("FormTable") Then
			CopyFormElementsRecursively(
				Form, SubordinateItem, NewItem, Postfix);
		EndIf;
		
	EndDo;
	
EndProcedure

// Disables verification of filling in Bank details.
// 
// Parameters:
// 	ItemDetailsParameters - Array of See TMCommonUseClientServer.NewParameterForObjectDetails - Parameters of Bank details.
// 	NotCheckedAttributeArray - Array of String - 
Procedure DisableVerificationOfObjectDetails(ItemDetailsParameters, NotCheckedAttributeArray) Export

	If ItemDetailsParameters = Undefined Then
		Return;
	EndIf;
	
	For Each AttributeParameters In ItemDetailsParameters Do
		
		If (AttributeParameters.Property = "Visible"
					Or AttributeParameters.Property = "MarkIncomplete"
					Or AttributeParameters.Property = "AutoMarkIncomplete")
				And AttributeParameters.Value = False 
			Or AttributeParameters.Property = "OnlyViewWithoutBlankMark"
				And AttributeParameters.Value = True
			Or AttributeParameters.Property = "OnlyViewWithoutBlankMarkWithoutClearing"
				And AttributeParameters.Value = True
			Or AttributeParameters.Property = "ReadOnly"
				And AttributeParameters.Value = True Then
				
			NotCheckedAttributeArray.Add(AttributeParameters.AttributeName);
		EndIf;
		
	EndDo;
	
EndProcedure

// Sets a managed table lock.
//
// Parameters:
//  ParametersStructure 		- Structure - The structure of the blocking parameters. Required parameter.
//								It must contain the properties:
//								of the "Table name" - the string is the name of the table on which the lock is applied.
//									For example: "Advance report"
//								Optional properties:
//								"Table type" - Row - the type of table on which the lock is applied.
//									The lock space consists of a table type and a table name.
//									For example: "Document"
//									Default value: "Accumulation register"
//								"Lock mode" - Data Lock mode - imposed lock mode.
//									Default value: Data blocking mode.
//								The exclusive "data source" is the data source for blocking.
//									A value of any type supported by the data source property of the lock element,
//									as well as the "Temporary Table Manager" type, can be passed.
//									If the structure does not have this property, locks through the use of the Data source() are not imposed.
//								"Temporary Table name" is the string name of the temporary table of the temporary table manager, which serves as the data source for the lock.
//									It must be specified if the temporary table manager is passed to the procedure as the data source.
//  CollectionOfLockValues	- Structure, Map - describes the lock values imposed using Set Value().
//									Key - lock field - <String or (for matching only) The plan of the viewcharacteristicslink>,
//										The planviewcharacteristicslink is used to block the accounting register by the type of subconto.
//									Value - blocked value - <Arbitrary type>.
//									If passed Undefined or if the collection does not contain a single element -
//									locks by the Set Value() method are not imposed.
//  SourceDescriptionCollection	- Structure, Map - describes the lock values imposed by using the Data Source().
//									Key - lock field - <String or (for matching only) The plan of the viewcharacteristicslink>,
//										The planviewcharacteristicslink is used to lock the accounting register by the type of subconto.
//									The value is a field of the data source table - <Row>.
//									If passed Undefined or if the collection does not contain a single element -
//									locks by using the Data Source() method are not imposed.
//
Procedure SetManagedLock(ParametersStructure, CollectionOfLockValues = Undefined, SourceDescriptionCollection = Undefined) Export

	If Not TypeOf(ParametersStructure) = Type("Structure") Then
		Return;
	EndIf;

	UseLockValues = CollectionOfLockValues <> Undefined
		And (TypeOf(CollectionOfLockValues) = Type("Structure")
			Or TypeOf(CollectionOfLockValues) = Type("Map"))
		And CollectionOfLockValues.Count() > 0;

	UseDataSource     = SourceDescriptionCollection <> Undefined
		And (TypeOf(SourceDescriptionCollection) = Type("Structure")
			Or TypeOf(SourceDescriptionCollection) = Type("Map"))
		And SourceDescriptionCollection.Count() > 0
		And ParametersStructure.Property("DataSource");

	If Not UseLockValues And Not UseDataSource Then
		Return;
	EndIf;

	Block = New DataLock;

	TableType = ?(ParametersStructure.Property("TableType"), ParametersStructure.TableType, "AccumulationRegister");
	TableName = ParametersStructure.TableName;
	LockSpace = TableType  + "." + TableName;
	LockItem = Block.Add(LockSpace);

	LockMode = ?(ParametersStructure.Property("LockMode"), ParametersStructure.LockMode, DataLockMode.Exclusive);
	LockItem.Mode = LockMode;

	If UseLockValues Then

		For Each CollectionItem In CollectionOfLockValues Do

			LockItem.SetValue(CollectionItem.Key, CollectionItem.Value);

		EndDo;

	EndIf;

	If UseDataSource Then

		DataSource = ParametersStructure.DataSource;

		If TypeOf(DataSource) = Type("TempTablesManager") Then

			Query = New Query;
			Query.TempTablesManager = DataSource;
			QueryText = "";
			For Each CollectionItem In SourceDescriptionCollection Do
				QueryText = QueryText + ",
				|	Tab." + CollectionItem.Value;
			EndDo;
			QueryText = Mid(QueryText, 2);
			Query.Text = 
			"SELECT DISTINCT
			|	&QueryText
			|FROM
			|	&TempTableName AS Tab";
			
			Query.Text = StrReplace(Query.Text, "&QueryText", QueryText);
			Query.Text = StrReplace(Query.Text, "&TempTableName", ParametersStructure.TempTableName);
			
			Result    = Query.Execute();

			LockItem.DataSource = Result;

		Else

			LockItem.DataSource = DataSource;

		EndIf;

		For Each CollectionItem In SourceDescriptionCollection Do

			LockItem.UseFromDataSource(CollectionItem.Key, CollectionItem.Value);

		EndDo;

	EndIf;
	
	Block.Lock(); //@skip-warning Call this procedure is wrapped by an attempt

EndProcedure

// Compares the specified tables line by line.
//
// Parameters:
//	Table1 			   - ValueTable - table 1
//	Table2 			   - ValueTable - table 2
//	ColumnsMustMatch - Boolean - if True, the columns must be identical.
//
// Returns:
//	String 			- if the columns should match = True and the columns of the tables are different; the description of the differences in the columns
//	of the assignment tables is returned - in all other cases; contains only different rows of tables No. 1 and No. 2
//		the composition of the columns of the table - common columns of tables No. 1 and No. 2
//		the service column "Counter of the rows of equalizable tables" contains a number other than 0:
//			if the counter > 0, then the row it occurs in table No. 1 by the specified number of times more
//			if the counter is < 0, then the row occurs in table #2 for the specified number of times more.
//
Function CompareValueTables(Table1, Table2, ColumnsMustMatch = True) Export
	
	DescriptionOfDifferencesInColumns = New Array;
	CommonColumns = New Array;
	
	// Let's check the columns of Table1 in Table2
	For Each CurrentColumn In Table1.Columns Do
		
		If Table2.Columns.Find(CurrentColumn.Name) = Undefined Then
			
			// Column only in Table1
			DescriptionOfDifferencesInColumns.Add(
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Cột chỉ có trong bảng số 1: ""%1""';
						|ru = 'Колонка присутствует только в таблице №1: ""%1""';
						|en = 'Column exists only in table No.1: ""%1""'; fa = 'Column exists only in table No.1: ""%1""';
						|it = 'La colonna è presente solo nella tabella №1: ""%1""';
						|pl = 'Kolumna istnieje tylko w tabeli nr1: ""%1""';
						|tr = 'Sütun yalnızca tablo №1''de mevcut: ""%1""'"),
					CurrentColumn.Name));
			
		Else
			
			// General column
			CommonColumns.Add(CurrentColumn.Name);
			
		EndIf;
		
	EndDo;
	
	// Let's check the columns of Table2 in Table1
	For Each CurrentColumn In Table2.Columns Do
		
		If Table1.Columns.Find(CurrentColumn.Name) = Undefined Then
			
			// Column only in Table2
			DescriptionOfDifferencesInColumns.Add(
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Cột chỉ có trong bảng số 2: ""%1""';
						|ru = 'Колонка присутствует только в таблице №2: ""%1""';
						|en = 'Column exists only in table No.2: ""%1""'; fa = 'Column exists only in table No.2: ""%1""';
						|it = 'La colonna è presente solo nella tabella №2: ""%1""';
						|pl = 'Kolumna istnieje tylko w tabeli nr2: ""%1""';
						|tr = 'Sütun yalnızca tablo №1''de mevcut: ""%1""'"),
					CurrentColumn.Name));
			
		EndIf;
		
	EndDo;
	
	If ColumnsMustMatch And DescriptionOfDifferencesInColumns.Count() > 0 Then
		Return StrConcat(DescriptionOfDifferencesInColumns, Chars.LF);
	EndIf;
	
	RowCommonColumns = StrConcat(CommonColumns, ", ");
	
	// Let's combine tables 1 and 2.
	// At the same time, we will write the number 1 for the 1st and -1 for the 2nd table in the service column "Counter of the rows of equalizable tables".
	TableOfDifferences = Table1.Copy(, RowCommonColumns);
	
	TableOfDifferences.Columns.Add("RowCounterForComparedTables", New TypeDescription("Number"));
	TableOfDifferences.FillValues(1, "RowCounterForComparedTables");
	
	For Each TableRow In Table2 Do
		
		NewRow = TableOfDifferences.Add();
		FillPropertyValues(NewRow, TableRow);
		
		NewRow.RowCounterForComparedTables = -1;
		
	EndDo;
	
	// Collapse the rows of the merged table.
	// The rows in which the counter of the rowed tables <> 0 are the differences of Tables 1 and 2.
	// We will return only the different strings.
	
	TableOfDifferences.GroupBy(RowCommonColumns, "RowCounterForComparedTables");
	
	FindAndDeleteRowsInValueTable(
		TableOfDifferences,
		New Structure("RowCounterForComparedTables", 0));
	
	Return TableOfDifferences;
	
EndFunction

// Returns the names of the main printed forms or electronic documents that were generated from the documents
//
// Parameters:
//  References - AnyRef
//         - Array of DefinedType.ObjectWithDefaultPrintForms - objects for which it is necessary
//                                                                        to obtain the name of printed forms.
//
// Returns:
//  Map of KeyAndValue - Compliance of documents and titles for printing:
//       * Key     - DefinedType.ObjectWithDefaultPrintForms - link to the document.
//       * Value - String, Undefined - A Presentation for printing.
//
Function NamesOfElectronicDocumentsOrBasicPrintedForms(Val References) Export
	
	ParameterType = TypeOf(References);
	If ParameterType <> Type("Array") And ParameterType <> Type("FixedArray") Then
		References = CommonClientServer.ValueInArray(References);
	EndIf;
	
	PresentationsOfDocuments = New Map;
	For Each Ref In References Do
		PresentationsOfDocuments.Insert(Ref, Undefined);
	EndDo;
	
	If GetFunctionalOption("DisplayNamesOfOutgoingDocumentsInReconciliationStatementsAndTaxInvoices") Then
		CommonLocalization.WhenReceivingNamesOfPrintedMainPrintingForms(References, PresentationsOfDocuments);
		
		RefsForSearching = New Array;
		For Each Item In PresentationsOfDocuments Do
			If Not ValueIsFilled(Item.Value) Then
				RefsForSearching.Add(Item.Key);
			EndIf;
		EndDo;
		
		GeneratedPrintingForms = PrintManagement.DescriptionsOfGeneratedDefaultPrintForms(RefsForSearching);
		For Each Ref In RefsForSearching Do
			PresentationsOfDocuments[Ref] = GeneratedPrintingForms[Ref];
		EndDo;
	EndIf;
	
	Return PresentationsOfDocuments;
	
EndFunction

#Region OverridableGeneralPurposeFunctions

// See CommonOverridable.OnDefineSubordinateObjects
Procedure OnDefineSubordinateObjects(SubordinateObjects) Export
	
	SubordinateObject = SubordinateObjects.Add();
	SubordinateObject.SubordinateObject = Metadata.Catalogs.InventoryLocationAttributeKeys;
	SubordinateObject.LinksFields = Catalogs.InventoryLocationAttributeKeys.KeyAttributes();
	SubordinateObject.OnSearchForReferenceReplacement = "Catalogs.InventoryLocationAttributeKeys";
	SubordinateObject.RunReferenceReplacementsAutoSearch = True;
	
	SubordinateObject = SubordinateObjects.Add();
	SubordinateObject.SubordinateObject = Metadata.Catalogs.KeysOfSetAccountingDimension;
	SubordinateObject.LinksFields = Catalogs.KeysOfSetAccountingDimension.KeyAttributes();
	SubordinateObject.OnSearchForReferenceReplacement = "Catalogs.KeysOfSetAccountingDimension";
	SubordinateObject.RunReferenceReplacementsAutoSearch = True;
	
	SubordinateObject = SubordinateObjects.Add();
	SubordinateObject.SubordinateObject = Metadata.Catalogs.DimensionKeysOfAccountingByPartners;
	SubordinateObject.LinksFields = Catalogs.DimensionKeysOfAccountingByPartners.KeyAttributes();
	SubordinateObject.OnSearchForReferenceReplacement = "Catalogs.DimensionKeysOfAccountingByPartners";
	SubordinateObject.RunReferenceReplacementsAutoSearch = True;
	
	SubordinateObject = SubordinateObjects.Add();
	SubordinateObject.SubordinateObject = Metadata.Catalogs.Assignments;
	SubordinateObject.LinksFields = Catalogs.Assignments.KeyAttributes();
	SubordinateObject.OnSearchForReferenceReplacement = "Catalogs.Assignments";
	SubordinateObject.RunReferenceReplacementsAutoSearch = True;
	
	SubordinateObject = SubordinateObjects.Add();
	SubordinateObject.SubordinateObject = Metadata.Catalogs.ARAPObjects;
	SubordinateObject.LinksFields = Catalogs.ARAPObjects.KeyAttributes();
	SubordinateObject.OnSearchForReferenceReplacement = "Catalogs.ARAPObjects";
	SubordinateObject.RunReferenceReplacementsAutoSearch = True;
	
	SubordinateObject = SubordinateObjects.Add();
	SubordinateObject.SubordinateObject = Metadata.Catalogs.DocumentRegistryKeys;
	SubordinateObject.LinksFields = Catalogs.DocumentRegistryKeys.KeyAttributes();
	SubordinateObject.OnSearchForReferenceReplacement = "Catalogs.DocumentRegistryKeys";
	SubordinateObject.RunReferenceReplacementsAutoSearch = True;
	
	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		SubordinateObject = SubordinateObjects.Add();
		SubordinateObject.SubordinateObject = Metadata.Catalogs.Counterparties;
		SubordinateObject.LinksFields = "Partner";
		SubordinateObject.RunReferenceReplacementsAutoSearch = True;
	EndIf;
	
	
EndProcedure

#EndRegion

// See SearchAndReplaceDuplicatesMasterDataOverridable.WhenSearchingForMasterDataDuplicates
Procedure WhenSearchingForMasterDataDuplicates(PairsOfTakes, Rule) Export
	
	IDCounterparties = Common.MetadataObjectID("Catalog.Counterparties");
	MetadataObjectOfRule = Common.ObjectAttributeValue(Rule, "MetadataObject");
	
	If MetadataObjectOfRule = IDCounterparties
		And Not GetFunctionalOption("UsePartnersAndCounterparties") Then
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	DuplicatesTable.Ref AS Ref,
		|	DuplicatesTable.Ref1 AS Ref1
		|INTO TT
		|FROM
		|	&DuplicatesTable AS DuplicatesTable
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Counterparties.Partner AS Ref,
		|	Counterparties1.Partner AS Ref1
		|FROM
		|	TT AS TT
		|		LEFT JOIN Catalog.Counterparties AS Counterparties
		|		ON TT.Ref = Counterparties.Ref
		|		LEFT JOIN Catalog.Counterparties AS Counterparties1
		|		ON TT.Ref1 = Counterparties1.Ref";
		Query.SetParameter("DuplicatesTable", PairsOfTakes);
		
		PairsOfTakes = Query.Execute().Unload();
		
	EndIf;
	
EndProcedure

// See SearchAndReplaceDuplicatesMasterDataOverridable.CheckPossibilityOfReplacingDuplicates
Procedure CheckPossibilityOfReplacingDuplicates(ReplacementPairs, ImpossibleReplacements, Type) Export
	
	TypesOfAuthorizationObject = Metadata.DefinedTypes.ExternalUser.Type;
	If TypesOfAuthorizationObject.ContainsType(Type) Then
		Query = New Query;
		Query.Text =
		"SELECT
		|	ExternalUsers.AuthorizationObject AS AuthorizationObject,
		|	ExternalUsers.Ref AS ExternalUser
		|FROM
		|	Catalog.ExternalUsers AS ExternalUsers
		|WHERE
		|	AuthorizationObject IN (&Filter)";
		
		Filter = New Array;
		For Each KeyAndValue In ReplacementPairs Do
			Filter.Add(KeyAndValue.Key);
		EndDo;
		Query.SetParameter("Filter", Filter);
		
		QueryResult = Query.Execute();
		Selection = QueryResult.Select();
		While Selection.Next() Do
			ErrorDescription = ImpossibleReplacements.Add();
			ErrorDescription.ErrorObject = Selection.ExternalUser;
			ErrorDescription.Ref = Selection.AuthorizationObject;
			ErrorText = StrTemplate(
				NStr("ru = 'Партнер %1 связан с внешним пользователем. Перед заменой партнера необходимо удалить внешнего пользователя.';
					|vi = 'The %1 partner is connected to an external user. Before replacing the partner, delete the external user.';
					|en = 'The %1 partner is connected to an external user. Before replacing the partner, delete the external user.'; fa = 'The %1 partner is connected to an external user. Before replacing the partner, delete the external user.';
					|it = 'The %1 partner is connected to an external user. Before replacing the partner, delete the external user.';
					|pl = 'The %1 partner is connected to an external user. Before replacing the partner, delete the external user.';
					|tr = 'İş ortağı %1 harici bir kullanıcıyla bağlantılı. İş ortağını değiştirmeden önce harici kullanıcının silinmesi gerekir.'"),
				Selection.AuthorizationObject);
			ErrorDescription.ErrorText = ErrorText;
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region ProceduresAndFunctionsForSettingStatusesForArrayOfDocuments

// Returns a matching array of document types
//
// Parameters:
// 		ReferencesArrray - Array of DocumentRef - Array of links.
//
// Returns:
// 		Map - The key is the document type, the Value is an array of links to documents.
//
Function DecomposeArrayOfReferencesByType(ReferencesArrray) Export
	
	MapTypes = New Map;
	
	For Counter = 0 To ReferencesArrray.Count() -1 Do
		
		RefType = TypeOf(ReferencesArrray[Counter]);
		Array = MapTypes[RefType];
		If Array = Undefined Then
			Array = New Array;
			MapTypes.Insert(RefType, Array);
		EndIf;
		Array.Add(ReferencesArrray[Counter]);
		
	EndDo;
	
	Return MapTypes;
	
EndFunction // DecomposeArrayOfReferencesByType

#EndRegion

#Region MethodsForWorkingWithObjectDetails

// Allows you to determine whether the details of the table part of the object include the details with the passed name.
//
// Parameters:
//  AttributeName - String - String name of the required attribute.
//  ObjectMetadata - MetadataObject - description of the metadata of the object whose details are being searched.
//  TabSectionName  - String - String name of the table part of the object that is being searched for.
//
// Returns:
//  Boolean - True, they found a prop with that name, False - they didn't find it.
//
Function ThereArePropsForPartOfObject(AttributeName, ObjectMetadata, TabSectionName) Export

	TabPart = ObjectMetadata.TabularSections.Find(TabSectionName);

	If TabPart = Undefined Then // there is no such tab. parts
		Return False;
	EndIf;
	
	Return TabPart.Attributes.Find(AttributeName) <> Undefined;
	
EndFunction

#EndRegion

#Region ReplacingLinksOnInformationBase

// Replaces links in the information database.
//
// Parameters:
//	ReplacementPairs - Map - the keys contain the replaced values contain substitutes
//	Exceptions - Array - optional, values of the object Metadata type that cannot be replaced in instances.
//
Procedure ReplaceReferences(ReplacementPairs, Exceptions = Undefined) Export
	SetPrivilegedMode(True);
	
	English = Metadata.ObjectProperties.ScriptVariant.English;
	RegisteredRecordsWithExtdimensionName = ?(Metadata.ScriptVariant = English, ".RecordsWithExtDimensions", ".RecordsWithExtDimensions");
	
	If Exceptions = Undefined Then
		Exceptions = New Array;
	EndIf;
	
	// [referencing object](.Metadata, .Substitutions[(.Substituted, .Substitute)], .Types of substitutable[]).
	ReplacementIndex = ReplacementIndex(ReplacementPairs);
	CacheOfFields = New Map;
	// We bypass the index and completely replace all the references to be replaced in each object key.
	For Each ReplacementNode In ReplacementIndex Do
		Ref = ReplacementNode.Key;
		NodeMetadata = ReplacementNode.Value.Metadata; // MetadataObject - 
		Substitutions_3 = ReplacementNode.Value.Substitutions_3;
		TypesOfReplacements = ReplacementNode.Value.TypesOfReplacements;
		
		If Exceptions.Find(NodeMetadata) <> Undefined Then
			Continue;
		EndIf;
		
		If ThisIsReferencedMetadataObject(NodeMetadata) Then
			// any reference object
			DataObject = Ref.GetObject();
			If DataObject <> Undefined Then
				FullName = NodeMetadata.FullName();
				FieldsNames = NamesOfFieldsWithTypes(CacheOfFields, FullName, TypesOfReplacements, "Ref, Ref");
				ReplaceValues(DataObject, FieldsNames, Substitutions_3);
				// tab parts of the object
				ReplaceInTwoParts(
					CacheOfFields, NodeMetadata.TabularSections, DataObject, FullName, Substitutions_3, TypesOfReplacements, Exceptions);
				// standard tab parts of plans
				If Metadata.ChartsOfAccounts.Contains(NodeMetadata) Or Metadata.ChartsOfCalculationTypes.Contains(NodeMetadata) Then
					ReplaceInTwoParts(
						CacheOfFields, NodeMetadata.StandardTabularSections, DataObject, FullName, Substitutions_3, TypesOfReplacements, Exceptions);
				EndIf;
				// we write the object itself
				WriteData(DataObject);
				DataObject = Undefined;
			EndIf;
		ElsIf Metadata.Constants.Contains(NodeMetadata) Then
			// values in constants
			Constant = Constants[NodeMetadata.Name];
			Constant.Set(NewValue(Constant.Get(), Substitutions_3));
		ElsIf Metadata.InformationRegisters.Contains(NodeMetadata) Then
			// non-object tables
			FieldsNames = NamesOfFieldsWithTypes(CacheOfFields, NodeMetadata.FullName(), TypesOfReplacements);
			Filters = InformationRegisterSelections(NodeMetadata, Ref);
			Set = RecordSet(InformationRegisters[NodeMetadata.Name], Filters);
			
			Table = Set.Unload();
			Set.Clear();
			WriteData(Set);

			ReplaceValues(Table[0], FieldsNames, Substitutions_3);
			For Each FieldName In FieldsNames Do
				If Not Filters.Property(FieldName) Then
					Continue;
				EndIf;
				FilterElement = Set.Filter[FieldName]; // FilterItem - 
				FilterElement.Set(NewValue(Filters[FieldName], Substitutions_3));
			EndDo;
			Set.Load(Table);
			WriteData(Set);
		EndIf;
		// processing document movements
		If Metadata.Documents.Contains(NodeMetadata) Then
			For Each Movement In NodeMetadata.RegisterRecords Do
				Additional_Table = "";
				If Exceptions.Find(Movement) <> Undefined Then
					Continue;
				EndIf;
				If Metadata.AccumulationRegisters.Contains(Movement) Then
					Register = AccumulationRegisters[Movement.Name];
				ElsIf Metadata.InformationRegisters.Contains(Movement) Then
					Register = InformationRegisters[Movement.Name];
				ElsIf Metadata.AccountingRegisters.Contains(Movement) Then
					Additional_Table = RegisteredRecordsWithExtdimensionName;
					Register = AccountingRegisters[Movement.Name];
				ElsIf Metadata.CalculationRegisters.Contains(Movement) Then
					Register = CalculationRegisters[Movement.Name];
				EndIf;
				ReplaceInSubordinateRegister(CacheOfFields, Register, Ref, Movement.FullName() + Additional_Table, Substitutions_3, TypesOfReplacements);
			EndDo;
			// processing sequences involving a document
			For Each Movement In Metadata.Sequences Do
				If Exceptions.Find(Movement) <> Undefined Then
					Continue;
				EndIf;
				If Movement.Documents.Contains(NodeMetadata) Then
					ReplaceInSubordinateRegister(
						CacheOfFields, Sequences[Movement.Name], Ref, Movement.FullName(), Substitutions_3, TypesOfReplacements);
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
EndProcedure

// Building a match of the form [referencing object] (.Metadata,. Substitutions[(.Substitutable,. Substitute)],. types of Substitutable[])
// as a result, we present the results of the search for links in the index with the key object containing the substituted links.
//
Function ReplacementIndex(ReplacementPairs)
	
	ReferenceList = New Array;
	For Each Pair In ReplacementPairs Do
		ReferenceList.Add(Pair.Key);
	EndDo;
	SearchResults = FindByRef(ReferenceList);
	// (.Link: original link; .Data: referencing object; .Metadata: metadata of the referring object).
	
	ReplacementIndex = New Map;
	For Each Result In SearchResults Do
		ReplacementNode = ReplacementIndex[Result.Data];
		If Undefined = ReplacementNode Then
			ReplacementNode =
				New Structure("Metadata, Substitutions_3, TypesOfReplacements", Result.Metadata, New Array, New Array);
			ReplacementIndex.Insert(Result.Data, ReplacementNode);
		EndIf;

		ReplacementNode.Substitutions_3.Add(
			New Structure("Replaceable_, Substitute_", Result.Ref, ReplacementPairs[Result.Ref]));

		TypeOfReplacement = TypeOf(Result.Ref);
		If Undefined = ReplacementNode.TypesOfReplacements.Find(TypeOfReplacement) Then
			ReplacementNode.TypesOfReplacements.Add(TypeOfReplacement);
		EndIf;
	EndDo;
	
	Return ReplacementIndex;
EndFunction

// Parameters:
// 	CacheOfFields - Map -
// 	TableDescriptions_ - Array of MetadataObjectTabularSection - 
// 	Object - DocumentObject, CatalogObject - 
// 	NameOfMainTable - String - LongDesc
// 	Substitutions_3 - Map -
// 	TypesOfReplacements - Array of Type -
// 	Exceptions - Array, Undefined -
Procedure ReplaceInTwoParts(CacheOfFields, TableDescriptions_, Object, NameOfMainTable, Substitutions_3, TypesOfReplacements, Exceptions)
	For Each LongDesc In TableDescriptions_ Do
		If Exceptions.Find(LongDesc) <> Undefined Then
			Continue;
		EndIf;
		FieldsNames = NamesOfFieldsWithTypes(CacheOfFields, NameOfMainTable + "." + LongDesc.Name, TypesOfReplacements, "Ref, Ref");
		For Each TableLine In Object[LongDesc.Name] Do
			ReplaceValues(TableLine, FieldsNames, Substitutions_3);
		EndDo;
	EndDo;
EndProcedure

Procedure ReplaceInSubordinateRegister(CacheOfFields, RegisterManager, Ref, RegisterTableName, Substitutions_3, TypesOfReplacements)
	FieldsNames = NamesOfFieldsWithTypes(CacheOfFields, RegisterTableName, TypesOfReplacements, "Recorder, Recorder");
	Set = RecordSet(RegisterManager, New Structure("Recorder", Ref));
	ValueReplaced = False;
	For Each Record In Set Do
		ReplaceValues(Record, FieldsNames, Substitutions_3, ValueReplaced);
	EndDo;
	WriteData(Set, ValueReplaced);
EndProcedure

Function NamesOfFieldsWithTypes(CacheOfTableFields, TableName, DataTypes, ExceptionNames = "")
	
	FieldsNames  = New Array;
	Exceptions  = New Structure(ExceptionNames);
	TableFields = CacheOfTableFields.Get(TableName);
	
	If TableFields = Undefined Then
		
	    TableFields = New Array;
		
	    QuerySchema = New QuerySchema;
	    QuerySchema.SetQueryText(
			StrReplace("SELECT * FROM TheSampleTable AS T WHERE FALSE", "TheSampleTable", TableName));
		
		For Each QueryColumn In QuerySchema.QueryBatch[0].Columns Do
	        If TypeOf(QueryColumn) = Type("QuerySchemaColumn") Then
	            TableFields.Add(
					New Structure("Name,ValueType", QueryColumn.Alias, QueryColumn.ValueType));
	        EndIf; 
	    EndDo;
		
	    CacheOfTableFields.Insert(TableName, TableFields);
		
	EndIf;
	
	For Each Field In TableFields Do
		
		If Exceptions.Property(Field.Name) Then
			Continue;
		EndIf;
		
		For Each DataType In DataTypes Do
			If Field.ValueType.ContainsType(DataType) And FieldsNames.Find(Field.Name) = Undefined Then
				FieldsNames.Add(Field.Name);
			EndIf;
		EndDo;
		
	EndDo;
	
    Return FieldsNames;
	
EndFunction

Procedure ReplaceValues(Data, FieldsNames, Substitutions_3, Replaced = False)
	For Each FieldName In FieldsNames Do
		NewValue = NewValue(Data[FieldName], Substitutions_3);
		If NewValue <> Data[FieldName] Then;
			Replaced = True;
			Data[FieldName] = NewValue;
		EndIf;
	EndDo;
EndProcedure

Function NewValue(PreviousValue2, Substitutions_3)
	For Each Replacement In Substitutions_3 Do
		If PreviousValue2 = Replacement.Replaceable_ Then
			Return Replacement.Substitute_;
		EndIf;
	EndDo;
	Return PreviousValue2;
EndFunction

Procedure WriteData(Data, Forcibly = False)
	If Data.Modified() Or Forcibly Then
		Data.DataExchange.Load = True;
		Data.Write();
	EndIf;
EndProcedure

// Parameters:
// 	RegisterMetadata - MetadataObjectInformationRegister -
// 	Record - InformationRegisterRecordInformationRegisterName -
// Returns:
// 	Structure - 
//  
Function InformationRegisterSelections(RegisterMetadata, Record)
	Filters = New Structure;
	If RegisterMetadata.InformationRegisterPeriodicity <> Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical Then
		Filters.Insert("Period", Record.Period);
	EndIf;
	For Each Dimension In RegisterMetadata.Dimensions Do
		Filters.Insert(Dimension.Name, Record[Dimension.Name]);
	EndDo;
	Return Filters;
EndFunction

// Parameters:
// 	RegisterManager - InformationRegisterManager - 
// 	                 - AccumulationRegistersManager - 
// 	Filters - Structure - LongDesc:
// 					* Period - Date -
// Returns:
// 	InformationRegisterRecordSet, AccumulationRegisterRecordSet -
//
Function RecordSet(RegisterManager, Filters)
	
	Set = RegisterManager.CreateRecordSet();
	For Each Filter In Filters Do
		FilterElement = Set.Filter[Filter.Key]; // FilterItem - 
		FilterElement.Set(Filter.Value);
	EndDo;
	Set.Read();
	Return Set;
EndFunction

Function ThisIsReferencedMetadataObject(MetadataObject)
	Return Metadata.Catalogs.Contains(MetadataObject)
		Or Metadata.Documents.Contains(MetadataObject)
		Or Metadata.Enums.Contains(MetadataObject)
		Or Metadata.ChartsOfCharacteristicTypes.Contains(MetadataObject)
		Or Metadata.ChartsOfAccounts.Contains(MetadataObject)
		Or Metadata.ChartsOfCalculationTypes.Contains(MetadataObject)
		Or Metadata.BusinessProcesses.Contains(MetadataObject)
		Or Metadata.Tasks.Contains(MetadataObject)
		Or Metadata.ExchangePlans.Contains(MetadataObject);
EndFunction

#EndRegion

#Region MethodsForDebuggingAndTesting

// Show a random selection of data in the debugger
// Example:
//	General purpose.Request to perform upload("Select * from Catalog.Currencies where Currencies.Code = &Code", New Structure("Code", "810"))
//
// Parameters:
// 	QueryText - String - 
// 	QueryOptions - Structure -
// 	TempTablesManager - TempTablesManager -
//
// Returns:
// 	ValueTable - 
Function ExecuteUploadRequest(QueryText, QueryOptions = Undefined, TempTablesManager = Undefined) Export
	
	Query = New Query(QueryText);
	
	If TempTablesManager <> Undefined Then
		Query.TempTablesManager = TempTablesManager;
	EndIf;
	
	If ValueIsFilled(QueryOptions) Then
		For Each Parameter In QueryOptions Do
			Query.SetParameter(Parameter.Key, Parameter.Value);
		EndDo;
	EndIf;
	
	Return Query.Execute().Unload();
	
EndFunction

// Show a temporary table from the temporary table Manager.
// Used for viewing temporary tables in the debugger.
// Example of a function call:
//	General purpose Out.Show A Time Table(Query, " Product Table")
//
// Parameters:
// 	TemporaryTableManagerOrQuery - TempTablesManager - 
//	                                 - Query -
//  TempTableName - String - 
//
// Returns:
// 	ValueTable - Temporary table data
//
Function ShowTemporaryTable(TemporaryTableManagerOrQuery, TempTableName) Export
	
	CloseTemporaryTableManager = False;
	
	If TypeOf(TemporaryTableManagerOrQuery) = Type("Query") Then
		If TemporaryTableManagerOrQuery.TempTablesManager = Undefined Then
			TempTablesManager = New TempTablesManager;
			CloseTemporaryTableManager = True;
			TemporaryTableManagerOrQuery.TempTablesManager = TempTablesManager; 
		Else
			TempTablesManager = TemporaryTableManagerOrQuery.TempTablesManager;
		EndIf;
		TemporaryTableManagerOrQuery.Execute();
	Else
		TempTablesManager = TemporaryTableManagerOrQuery;
	EndIf; 
	
	QueryText = 
	"SELECT
	|	*
	|FROM
	|	&TempTable";
	QueryText = StrReplace(QueryText, "&TempTable", TempTableName);
	
	TableData = ExecuteUploadRequest(QueryText,, TempTablesManager);
	
	If CloseTemporaryTableManager Then
		TempTablesManager.Close();
		TemporaryTableManagerOrQuery.TempTablesManager = Undefined;
	EndIf; 
	
	Return TableData;
	
EndFunction


// LongDesc
// 
// Parameters:
// 	FullFileName	- String	- full file path
// Returns:
// 	SpreadsheetDocumentFileType - the file type of the tabular document corresponding to the passed value
Function GetFileTypeOfTabularDocumentByItsFullName(FullFileName) Export
	
	MatchingExtensionToFileType = New Map();
	MatchingExtensionToFileType.Insert(".DOCX",	SpreadsheetDocumentFileType.DOCX);
	MatchingExtensionToFileType.Insert(".HTML",	SpreadsheetDocumentFileType.HTML);
	MatchingExtensionToFileType.Insert(".ODS",		SpreadsheetDocumentFileType.ODS);
	MatchingExtensionToFileType.Insert(".PDF",		SpreadsheetDocumentFileType.PDF);
	MatchingExtensionToFileType.Insert(".TXT",		SpreadsheetDocumentFileType.TXT);
	MatchingExtensionToFileType.Insert(".XLS",		SpreadsheetDocumentFileType.XLS);
	MatchingExtensionToFileType.Insert(".XLSX",	SpreadsheetDocumentFileType.XLSX);
	
	File = New File(FullFileName);
	FileType = MatchingExtensionToFileType.Get(Upper(File.Extension));
	
	Return ?(FileType = Undefined, SpreadsheetDocumentFileType.MXL, FileType);

EndFunction

// Converts a table of values to a table document and saves it to a file.
//
// Parameters:
//  Table									 - ValueTable	 - custom table of values
//  FullFileName							 - String			 - full name of the file to save, with the extension.
//  ApplyAppearance								 - Boolean			 - see the description of the parameter in the General Purpose function.Tabular documentationsreferences
//  TablePartMetadataForHeadings	 - MetadataObjectTabularSection, Undefined - see the description
//																		of the parameter in the General Purpose function.Tabular documentationsreferences
// 
// Returns:
//  String - the text of the error message or an empty string if the recording was completed successfully.
//
// Examples:
// 	General purpose.Save the Value table in the file(Table, "c:\temp\table.mxl")
//  General purpose.Save the Value table in the file(General purpose).Show the time table(MW, "Table"), "c:\temp\table.mxl")
//
Function SaveTableOfValuesToFile(Table, FullFileName, ApplyAppearance = False, TablePartMetadataForHeadings = Undefined) Export
	
	UnloadingTable = TabularDocumentFromTableOfValues(Table, ApplyAppearance, TablePartMetadataForHeadings);
	
	// Save the tabular document to a file
	ErrorText = "";
	Try
		UnloadingTable.Write(FullFileName, GetFileTypeOfTabularDocumentByItsFullName(FullFileName));
	Except
		ErrorText = DetailErrorDescription(ErrorInfo());
	EndTry;
	
	Return ErrorText;
	
EndFunction

// Returns a table of values representation as a table document
//
// Parameters:
//  Table	- ValueTable -
//  ApplyAppearance - Boolean - if TRUE is passed, then
//							an empty line is added in front of the header,
//							the header is highlighted in the background color, otherwise in bold,
//							the column width is set to the width of the header, otherwise the default width,
//							the properties of the table document are set to only View = True,display the grid = False, Display headings = False.
//  TablePartMetadataForHeadings - MetadataObjectTabularSection -
//	                                      - Undefined -
//  											if metadata is transmitted, then synonyms of fields from metadata are displayed in the table header
//                                              . if a column of the table of values is not found, it is not displayed in a tabular document
//                                              . if metadata is not transmitted, then column headers from the table of values are shown in the header,
//                                              	if there are no headers, column names are shown.
// 
// Returns:
//   SpreadsheetDocument -
//
Function TabularDocumentFromTableOfValues(Table, ApplyAppearance = False, TablePartMetadataForHeadings = Undefined) Export
	
	UnloadingTable = New SpreadsheetDocument; // table of values converted to mxl
	
	If ApplyAppearance Then
		LineNumber  = 2;
	Else
		LineNumber  = 1;
	EndIf;	
		
	ColumnNumber = 0;
	
	// Let's form the header of the tabular document - output the names of the columns of the table of values
	For Each CurColumn In Table.Columns Do
		
		ColumnNumber = ColumnNumber + 1;
		
		Area = UnloadingTable.Area(LineNumber, ColumnNumber, LineNumber, ColumnNumber);
		If TablePartMetadataForHeadings = Undefined Then 
			Area.Text = ?(ValueIsFilled(CurColumn.Title), CurColumn.Title, CurColumn.Name);
		Else
			Attribute = TablePartMetadataForHeadings.Attributes.Find(CurColumn.Name);
			If Attribute = Undefined Then
				Area.ColumnWidth = 1;
				Continue;
			Else
				Area.Text = Attribute.Synonym;
			EndIf;
		EndIf;
		Area.BottomBorder  = New Line(SpreadsheetDocumentCellLineType.Solid, 1);
		Area.TopBorder = New Line(SpreadsheetDocumentCellLineType.Solid, 1);
		Area.LeftBorder  = New Line(SpreadsheetDocumentCellLineType.Solid, 1);
		Area.RightBorder = New Line(SpreadsheetDocumentCellLineType.Solid, 1);
		
		If ApplyAppearance Then
			Area.BackColor = StyleColors.TotalsGroupBackground;	
			Area.ColumnWidth = StrLen(Area.Text);
		Else
			Area.Font    = New Font(Area.Font,,, True); 
		EndIf;
		
	EndDo;
	
	// Output the rows of the table of values
	For Each CurrRow In Table Do
		
		LineNumber = LineNumber + 1;
		ColumnNumber = 0;
		
		For Each CurColumn In Table.Columns Do
			ColumnNumber = ColumnNumber + 1;
			
			If TablePartMetadataForHeadings <> Undefined Then 
				Attribute = TablePartMetadataForHeadings.Attributes.Find(CurColumn.Name);
				If Attribute = Undefined Then
					Continue;
				EndIf;
			EndIf;	
			
			Area = UnloadingTable.Area(LineNumber, ColumnNumber, LineNumber, ColumnNumber);
			Area.Text         = String(CurrRow[CurColumn.Name]);
			Area.BottomBorder  = New Line(SpreadsheetDocumentCellLineType.Solid, 1);
			Area.TopBorder = New Line(SpreadsheetDocumentCellLineType.Solid, 1);
			Area.LeftBorder  = New Line(SpreadsheetDocumentCellLineType.Solid, 1);
			Area.RightBorder = New Line(SpreadsheetDocumentCellLineType.Solid, 1);
			
		EndDo;
		
	EndDo;
	
	UnloadingTable.FixedTop = 1;
	UnloadingTable.FixedLeft  = 1;
	
	If ApplyAppearance Then
		
		UnloadingTable.ReadOnly      = True;
		UnloadingTable.ShowGrid     = False;
		UnloadingTable.ShowHeaders = False;
		
	EndIf;
	
	Return UnloadingTable;
	
EndFunction

// Reads a table of values from a table document.
// Placing the table of values in a text document can be performed by the Save Table of Values File() function.
// The first row of the table should contain the names of the columns of the table of values,
// in the remaining rows - the values in the corresponding cells of the table of values.
// Example of a function call:
// 	General purpose.Get the Value table of the file("c:\temp\table.mxl").
//
// Parameters:
//	FullFileName - String - full name of the file to read, with the extension.
//
// Returns:
//	String 			- if an error occurred while reading the file, the error message text is returned;
//	Value tables - if there were no errors, the read table of values is returned.
//
Function GetTableOfValuesFromFile(FullFileName) Export
	
	UnloadingTable = New SpreadsheetDocument; // table of values converted to mxl
	
	// Let's read the file.
	Try
		UnloadingTable.Read(FullFileName);
	Except
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể đọc bảng giá trị từ tệp ""%1"":
				|%2';
				|ru = 'Невозможно прочитать таблицу значений из файла ""%1"":
				|%2';
				|en = 'Cannot read table of values from the ""%1"" file:
				|%2'; fa = 'Cannot read table of values from the ""%1"" file:
				|%2';
				|it = 'Impossibile leggere la tabella dei valori dal file ""%1"":
				|%2';
				|pl = 'Nie można przeczytać tabelę wartości z pliku ""%1"":
				|%2';
				|tr = '""%1"" dosyasındaki değerler tablosu okunamıyor:
				|%2'"),
			FullFileName,
			ErrorInfo());
		
		Return ErrorText;
		
	EndTry;
	
	Table = New ValueTable;
	
	If UnloadingTable.TableHeight = 0 Or UnloadingTable.TableWidth = 0 Then
		Return Table;
	EndIf;
	
	// Let's create columns of the table of values.
	LineNumber = 1;
	
	// The column names should be listed in the first row of the table.
	// If a text is specified in the cell of the first row that is not suitable for the column name of the table of values, then we will return an error message.
	For ColumnNumber = 1 To UnloadingTable.TableWidth Do
		
		Area = UnloadingTable.Area(LineNumber, ColumnNumber, LineNumber, ColumnNumber);
		CellText = TrimAll(Area.Text);
		
		Try
			Table.Columns.Add(CellText, New TypeDescription("String"));
		Except
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể đọc bảng giá trị từ tệp ""%1"":
					|tên cột của bảng giá trị không hợp lệ: ""%2""';
					|ru = 'Невозможно прочитать таблицу значений из файла ""%1"":
					|недопустимое имя колонки таблицы значений: ""%2""';
					|en = 'Cannot read the value table from the ""%1"" file:
					|invalid column name of the value table: ""%2""'; fa = 'Cannot read the value table from the ""%1"" file:
					|invalid column name of the value table: ""%2""';
					|it = 'Impossibile leggere la tabella dei valori dal file ""%1"":
					| Nome della colonna della tabella dei valori non disponibile: ""%2""';
					|pl = 'Nie można przeczytać tabelę wartości z pliku ""%1"":
					|niedopuszczalna nazwa kolumny tabeli wartości: ""%2""';
					|tr = '""%1"" dosyasından değer tablosu okunamıyor:
					|geçersiz değer tablosu sütun adı: ""%2""'"),
				FullFileName,
				CellText);
			
			Return ErrorText;
			
		EndTry;
		
	EndDo;
	
	For LineNumber = 2 To UnloadingTable.TableHeight Do
		
		NewRow = Table.Add();
		
		For ColumnNumber = 1 To UnloadingTable.TableWidth Do
			
			Area = UnloadingTable.Area(LineNumber, ColumnNumber, LineNumber, ColumnNumber);
			CellText = TrimAll(Area.Text);
			
			NewRow[Table.Columns[ColumnNumber - 1].Name] = CellText;
			
		EndDo;
		
	EndDo;
	
	Return Table;
	
EndFunction

#EndRegion

#Region SystemDefineConfigurationBehavior

// Checks whether the conditions for opening the basic version of the configuration in Enterprise mode are met.
//
// Returns:
// 	Boolean - If the current configuration version is not the base version, then the value True is returned.
//           If the current configuration version is basic, then the value True is returned.
//	         If the IS is deployed in the file version and runs in single-user mode.
//
Function ItIsPossibleToStartBasicVersion() Export
	
	If Not StandardSubsystemsServer.IsBaseConfigurationVersion() Then
		Return True; // OK: This is not a basic version
	EndIf;
	
	If Not Common.FileInfobase(InfoBaseConnectionString()) Then
		Return False; // not a file IB
	EndIf;
	
	InfobaseSessions = GetInfoBaseSessions();
	CurrentSessionNumber		 = InfoBaseSessionNumber();
	BannedApps	 = ",1CV8,1CV8C,WebClient,WSConnection,COMConnection,";
	
	For Each IBSession In InfobaseSessions Do
		
		If IBSession.SessionNumber = CurrentSessionNumber Then
			Continue;
		ElsIf StrFind(BannedApps, "," + IBSession.ApplicationName + ",") > 0 Then
			Return False; // other 1C sessions are open:Enterprises
		EndIf;
		
	EndDo;
	
	Return True; // OK: This is a file IS in single-user mode
	
EndFunction

#EndRegion

#Region Versioning

// Returns whether versioning is used for the specified metadata object.
//
// Parameters:
//  FullObjectName - String - full path to the metadata object. For Example, " Directory.Nomenclature".
//
// Returns:
//  Boolean -
//
Function UseObjectVersioning(FullObjectName) Export
	
 	Id = Common.MetadataObjectID(FullObjectName);	
	Return GetFunctionalOption("UseObjectVersioning",
		New Structure("VersionizedObjectType", Id));
		
EndFunction	

// Enables versioning for the specified metadata object.
//
// Parameters:
//  FullObjectName - String - full path to the metadata object. For Example, " Directory.Nomenclature".
//	VersioningMode - String - the name of the enumeration value Variationsonatheme.
//
// Returns:
//  Boolean - True if versioning was enabled for the specified object.
//
Function EnableObjectVersioning(FullObjectName, VersioningMode = "VersionizeOnWrite")
	
	VersioningIsEnabled = False;
	
	EnumerationIsVersioningOption = Enums.ObjectsVersioningOptions[VersioningMode];
	
	If Not UseObjectVersioning(FullObjectName) Then
		
		ObjectsVersioning.SaveObjectVersioningConfiguration(FullObjectName, EnumerationIsVersioningOption);
		VersioningIsEnabled = True;
		
	EndIf;
	
	Return VersioningIsEnabled;
	
EndFunction

// Enables versioning for the specified metadata objects.
//
// Parameters:
//	Objects - Map
//  	Key-String - the full path to the metadata object. For Example, " Directory.Nomenclature".
//		Value-String-name of the value of the enumeration of object versioning Options.
//
// Returns:
//  Boolean - True if versioning was enabled for at least one of the specified objects.
//
Function EnableObjectsVersioning(Objects) Export
	
	VersioningIsEnabled = False;
	
	For Each KeyAndValue In Objects Do
		VersioningIsEnabled =
			EnableObjectVersioning(KeyAndValue.Key, KeyAndValue.Value)
			Or VersioningIsEnabled;
	EndDo;
	
	Return VersioningIsEnabled;
	
EndFunction

#EndRegion

#Region Constants

// Returns the composition of a set of constants.
//
// Parameters:
//	Set - ConstantsSet -
//
// Returns:
//  Structure -
//		The key is the name of a constant from the set.
//
Function GetStructureOfSetOfConstants(Set) Export
	
	Result = New Structure;
	
	For Each MetaConstant In Metadata.Constants Do
		If TMCommonUseClientServer.HasObjectAttribute(Set, MetaConstant.Name) Then
			Result.Insert(MetaConstant.Name);
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Enums

// Retrieves the selection list for the specified enumeration.
//
// Parameters:
//	EnumerationName 	- String - the name of the enumeration as specified in the Configurator.
//	ChoiceData 		- ValueList - auto-generated list of choice enumeration.
//	Parameters 			- Structure - For more information, see the processing of the received selection
//	ExcludedValues - Array - enumeration values that are not included in the selection list.
//
Procedure SelectableEnumerationValues(EnumerationName, ChoiceData, Parameters = Undefined, ExcludedValues = Undefined) Export
	
	If Parameters = Undefined Then
		Parameters = New Structure;
		Parameters.Insert("Filter", New Structure);
		Parameters.Insert("SearchString", "");
	EndIf;
	
	StringSearchMethod = SearchStringModeOnInputByString.AnyPart;
	If Parameters.Property("SearchStringModeOnInputByString") Then
		StringSearchMethod = Parameters.SearchStringModeOnInputByString;
	EndIf;
	
	ChoiceData = New ValueList; // Result
	
	Query = New Query;
	QueryText =
	"SELECT
	|	EnumValues.Ref AS Ref,
	|	PRESENTATION(EnumValues.Ref) AS Presentation
	|FROM
	|	&Table AS EnumValues
	|WHERE
	|	NOT EnumValues.Ref IN (&ExcludedValues)
	|	AND &FilterByReference_
	|
	|ORDER BY
	|	EnumValues.Order";
	
	If ExcludedValues = Undefined Then
		Query.SetParameter("ExcludedValues", New Array);
	Else
		Query.SetParameter("ExcludedValues", ExcludedValues);
	EndIf;
	
	If Parameters.Filter.Property("Ref") Then
		QueryText = StrReplace(QueryText, "&FilterByReference_", "EnumValues.Ref IN (&FilterByReference_)");
		Query.SetParameter("FilterByReference_", Parameters.Filter.Ref);
	Else
		QueryText = StrReplace(QueryText, "&FilterByReference_", "TRUE");
	EndIf;
	
	Query.Text = StrReplace(QueryText, "&Table", "Enum." + EnumerationName);
	
	Selection = Query.Execute().Select();
	
	ThereIsSelectionByLine = ValueIsFilled(Parameters.SearchString);
	SearchString = ?(ThereIsSelectionByLine, Lower(Parameters.SearchString), "");
	
	While Selection.Next() Do
			
		If ThereIsSelectionByLine Then
			
			PresentationForSearching = Lower(Selection.Presentation);
			
			If StringSearchMethod = SearchStringModeOnInputByString.Begin
				And StrStartsWith(PresentationForSearching, SearchString) Then
				
				Presentation = StrFindAndHighlightByAppearance(
					Selection.Presentation,
					SearchString);
					
			ElsIf StringSearchMethod = SearchStringModeOnInputByString.AnyPart
				And StrFind(PresentationForSearching, SearchString) > 0 Then
				
				Presentation = Selection.Presentation;	
					
			Else // Line selection failed
				
				Continue;
			
			EndIf;
			 
		Else
			
			Presentation = Selection.Presentation;
		
		EndIf;
		
		ChoiceData.Add(Selection.Ref, Presentation);
		
	EndDo;
	
EndProcedure

#EndRegion

#Region ContactInformation

// Updates the values of the CI fields from its representation.
//
//  Parameters:
//		Presentation - String - Ki representation
//		FieldValues - String - service information, values of CI fields
//		CIType - EnumRef.ContactInformationTypes - type of contact information
//
Procedure FillInValuesOfCIFieldsOnPresentation(Presentation, FieldValues, CIType = Undefined) Export
	
	If CIType = Undefined Then
		CIType = Enums.ContactInformationTypes.Address;
	EndIf;
	
	If ContactsManager.ContactInformationPresentation(FieldValues) = Presentation Then
		Return;
	EndIf;
	
	// Let's save the comment from the old field values.
	Comment = TrimAll(ContactsManager.ContactInformationComment(FieldValues));
	
	// Let's form the values of the CI fields according to the representation.
	FieldValues = ContactsManager.ContactsByPresentation(Presentation,	CIType);
	
	If ValueIsFilled(Comment) Then
		// We will return the comment back.
		ContactsManager.SetContactInformationComment(FieldValues, Comment);
	EndIf;
	
EndProcedure

#EndRegion

#Region AdditionalAttributesAndInfo

// Service. Returns sets of additional details and information available in these configuration settings.
//
// Returns:
//	Array of CatalogRef.AdditionalAttributesAndInfoSets -
//
Function AvailableAdditionalDetailsAndInformation() Export
	
	AvailableProperties = New Array;
	
	RelationshipsBetweenIfoProperties = TMCommonUseCached.RelationshipsBetweenBankingDetailsAndFunctionalOptions();
	
	For Each KeyAndValue In RelationshipsBetweenIfoProperties Do
		
		If Not ValueIsFilled(KeyAndValue.Value) Then
			
			// This set is optional. properties do not depend on the FO
			AvailableProperties.Add(KeyAndValue.Key);
			
		Else
			
			ParentFOS = New Structure(KeyAndValue.Value);
			
			For Each CurFO In ParentFOS Do
				If GetFunctionalOption(CurFO.Key) Then
					// At least one FO is included, on which this set of add-ons depends. properties
					AvailableProperties.Add(KeyAndValue.Key);
					Break;
				EndIf;
			EndDo;
			
		EndIf;
		
	EndDo;
	
	Return AvailableProperties;
	
EndFunction

#EndRegion

#Region Subsystems

// Adds a subsystem to the collection.
//
// Parameters:
//	Collection - Array - 
//	          - ValueList - collection where the subsystem is added from metadata
//	SubsystemName - String - name of the subsystem. Subordinate subsystems are separated by".", the service words "Subsystem" or "Subsystems" do not need to be specified.
//	Presentation - String - subsystem view (for a list of values).
//
Procedure AddSubsystemToCollection(Collection, SubsystemName, Presentation = "") Export
	
	Subsystem = SubsystemByName(SubsystemName);
	If Subsystem = Undefined Then
		Return; // there is no such subsystem in metadata
	EndIf;
	
	If ValueIsFilled(Presentation) Then
		Collection.Add(Subsystem, Presentation);
	Else
		Collection.Add(Subsystem);
	EndIf;
	
EndProcedure

// Returns metadata of the subsystem by its name.
//
// Parameters:
//	SubsystemName - String - subsystem name
//		subordinate subsystems are separated by".", the service words " Subsystem "or" Subsystems " do not need to be specified.
//
// Returns:
//	MetadataObject - subsystem metadata or Undefined if a subsystem with that name does not exist.
//
Function SubsystemByName(SubsystemName) Export
	
	FullSubsystemName = Mid(StrReplace("." + SubsystemName, ".", ".Subsystem."), 2);;
	
	Return Metadata.FindByFullName(FullSubsystemName);
	
EndFunction

#EndRegion

#Region GlobalSearch

Procedure CombineDateAndTime(Words)
	
	LastWord = Words.Get(Words.UBound()); 
	If StrLen(LastWord) = 8 And Mid(LastWord, 3, 1) = ":" And Mid(LastWord, 6, 1) = ":" Then
		Words[Words.UBound() - 1] = Words[Words.UBound() - 1] + " " + Words.Get(Words.UBound());
		Words.Delete(Words.UBound());
	EndIf;

EndProcedure

Procedure FindDocumentInRegistryByNameAndNumber(Words, SearchResult)
	
	WordsOfTitle = New Array;
	For IndexOf = 0 To Words.UBound() - 1 Do
		WordsOfTitle.Add(Words.Get(IndexOf));
	EndDo;
	DocumentNumber = Words.Get(Words.UBound());
	If StringFunctionsClientServer.OnlyNumbersInString(StrConcat(WordsOfTitle))
		Or Not StringContainsDigit(DocumentNumber) Then
		Return;
	EndIf;
	
	DocumentName3 = StrConcat(WordsOfTitle, " ");
	For Each MetadataObject In Metadata.Documents Do
		If Upper(MetadataObject.Synonym) = Upper(DocumentName3) Then
			RefType = Common.MetadataObjectID("Document." + MetadataObject.Name);
			Break;
		EndIf;
	EndDo;
	
	SelectDocumentsFromRegistry(SearchResult, DocumentNumber, RefType, DocumentName3);
	
EndProcedure

Function StringContainsDigit(String)
	
	If StrFind(String, "0") > 0 Or StrFind(String, "1") > 0 Or StrFind(String, "2") > 0
		Or StrFind(String, "3") > 0 Or StrFind(String, "4") > 0 Or StrFind(String, "5") > 0
		Or StrFind(String, "6") > 0 Or StrFind(String, "7") > 0 Or StrFind(String, "8") > 0
		Or StrFind(String, "9") > 0 Then
			Return True;
	EndIf;
	Return False;
	
EndFunction

Procedure SelectDocumentsFromRegistry(SearchResult, Number, Type=Undefined, Description=Undefined,
	Date=Undefined)

	Query = New Query;
	QueryTextInternalDocument = "SELECT TOP 10 ALLOWED
	|	DocumentsRegistry.Ref,
	|	DocumentsRegistry.IBDocumentDate
	|FROM
	|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|WHERE
	|	&ConditionType
	|	AND &ConditionDocumentDate
	|	AND DocumentsRegistry.IBDocumentNumber = &DocumentNumber";

	RequestTextExternalDocument = "SELECT TOP 10
	|	DocumentsRegistry.Ref,
	|	DocumentsRegistry.IBDocumentDate 
	|FROM
	|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|WHERE
	|	&ConditionName_
	|	AND &ExternalDocumentDateCondition
	|	AND DocumentsRegistry.SourceDocumentNumber = &DocumentNumber";
	
	If ValueIsFilled(Type) Then
		Query.Text = QueryTextInternalDocument;
		Query.Text = StrReplace(Query.Text, "&ConditionType", "DocumentsRegistry.RefType = &RefType");
		Query.SetParameter("RefType", Type);
	Else
		If ValueIsFilled(Description) Then
			Query.Text = RequestTextExternalDocument;
			Query.Text = StrReplace(Query.Text, "10" , "10 ALLOWED")
		Else
			Query.Text = QueryTextInternalDocument + QuerySeparatorInJoin()
							+ RequestTextExternalDocument;
		EndIf;
		Query.Text = StrReplace(Query.Text, "&ConditionType", "TRUE");
	EndIf;
	Query.Text = Query.Text + "
		|ORDER BY
		|	DocumentsRegistry.IBDocumentDate DESC";
	Query.SetParameter("DocumentNumber", Number);
	If ValueIsFilled(Description) Then
		Query.Text = StrReplace(Query.Text, "&ConditionName_",
			"DocumentsRegistry.SourceDocumentName LIKE &DocumentName3"); // @Query-part-1
		Query.SetParameter("DocumentName3", Description);
	Else
		Query.Text = StrReplace(Query.Text, "&ConditionName_", "TRUE");
	EndIf;
	If ValueIsFilled(Date) Then
		Query.Text = StrReplace(Query.Text, "&ConditionDocumentDate",
			"DocumentsRegistry.IBDocumentDate >= BEGINOFPERIOD(&DocumentDate, DAY)
		|	AND DocumentsRegistry.IBDocumentDate <= ENDOFPERIOD(&DocumentDate, DAY)");
		Query.Text = StrReplace(Query.Text, "&ExternalDocumentDateCondition",
			"DocumentsRegistry.SourceDocumentDate >= BEGINOFPERIOD(&DocumentDate, DAY)
		|	AND DocumentsRegistry.SourceDocumentDate <= ENDOFPERIOD(&DocumentDate, DAY)");
		Query.SetParameter("DocumentDate", Date);
	Else
		Query.Text = StrReplace(Query.Text, "&ConditionDocumentDate", "TRUE");
		Query.Text = StrReplace(Query.Text, "&ExternalDocumentDateCondition", "TRUE");
	EndIf;
	If ValueIsFilled(Type) And ValueIsFilled(Number) And ValueIsFilled(Date) Then
		Query.Text = StrReplace(Query.Text, "10", "1");
	EndIf;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		NewItem = New GlobalSearchResultItem(
			Selection.Ref, String(Selection.Ref), PictureLib.DataSearch);
		SearchResult.Add(NewItem);
	EndDo;
	
EndProcedure

Function DateFromString(String)
	
	If StrLen(String) <= 10 Then // there is no time
		String = String + " 00:00:00"
	EndIf;
	
	Try
		Return Date(String);
	Except
		Return Undefined
	EndTry;
	
EndFunction

// Determines whether the string is in the form of a string Nstr
// 
// Parameters:
//  RowToValidate - String - string to check
// 
// Returns:
//  Boolean - String in the form of n page
//
Function StringAsNstr(Val RowToValidate) Export
	
	RowToValidate = StrReplace(RowToValidate, " ", "");
	
	MatchesOptions = New Array;
	For Each Language In Metadata.Languages Do
		MatchesOptions.Add(Language.LanguageCode + "=");
	EndDo;
	
	For Each MatchOption In MatchesOptions Do
		If StrFind(RowToValidate, MatchOption) > 0 Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

#EndRegion

#Region Other

Procedure ProcessNestedFields(FormItems, FormItem, ItemArray, Structure, ExceptionFields)
	
	TypeOfGNPFormElement = TypeOf(FormItem);
	
	If TypeOfGNPFormElement = Type("FormTable")
		Or TypeOfGNPFormElement = Type("FormGroup") Then
		If TypeOfGNPFormElement = Type("FormTable") Then
			TagName = FormItem.Name;
			Structure.Insert(TagName, New Array);
			ProcessFormTableFields(FormItems, FormItem, Structure[TagName], ExceptionFields);
		EndIf;
		For Each Item In FormItem.ChildItems Do
			Name = Item.Name;
			SubordinateItem = FormItems[Name];
			GNPTypeSubordinateElement = TypeOf(SubordinateItem);
			If GNPTypeSubordinateElement = Type("FormField") Then
				If ItemArray.Find(Name) <> Undefined
					Or ExceptionFields.Find(Name) <> Undefined Then
					Continue;
				EndIf;
				ItemArray.Add(Name);
			ElsIf GNPTypeSubordinateElement = Type("FormGroup") Then
				ProcessNestedFields(FormItems, SubordinateItem, ItemArray, Structure, ExceptionFields);
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

Procedure ProcessFormTableFields(FormItems, FormItem, ItemArray, ExceptionFields)
	
	TypeOfGNPFormElement = TypeOf(FormItem);
	
	If TypeOfGNPFormElement = Type("FormTable")
		Or TypeOfGNPFormElement = Type("FormGroup") Then
		For Each Item In FormItem.ChildItems Do
			SubordinateItem = FormItems[Item.Name];
			GNPTypeSubordinateElement = TypeOf(SubordinateItem);
			If GNPTypeSubordinateElement = Type("FormField") Then
				If ItemArray.Find(Item.Name) <> Undefined
					Or ExceptionFields.Find(Item.Name) <> Undefined Then
					Continue;
				EndIf;
				ItemArray.Add(Item.Name);
			ElsIf GNPTypeSubordinateElement = Type("FormGroup") Then
				ProcessFormTableFields(FormItems, SubordinateItem, ItemArray, ExceptionFields);
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

// The function returns the configuration ID.
// The ID must not exceed 8 characters in length.
//
// Returns:
// 	String -
Function ConfigurationID() Export
	Return "UP2"; // in the 1C configuration:ERP
	Return "KA2"; // in the KA2 configuration
	Return "UT11" + ?(StandardSubsystemsServer.IsBaseConfigurationVersion(), "Basic", ""); // in the UT11 configuration
	
EndFunction

Function GetPrefixForUIP(Ref)

	Map = New Map();
	Map.Insert("CounterpartyContracts",				NStr("vi = 'HỢP ĐỒNG';
															|ru = 'ДОГ';
															|en = 'CONT'; fa = 'CONT';
															|it = 'AC';
															|pl = 'CONT';
															|tr = 'SÖZ'", Common.DefaultLanguageCode()));
	Map.Insert("CustomerInvoiceServices",				NStr("vi = 'BIÊN BẢN';
																|ru = 'АКТ';
																|en = 'CustInvServ'; fa = 'CustInvServ';
																|it = 'ALE';
																|pl = 'CustInvServ';
																|tr = 'TUTANAK'", Common.DefaultLanguageCode()));
	Map.Insert("ReturnOfGoodsToVendor",			NStr("vi = 'NKV';
														|ru = 'НКВ';
														|en = 'VendReturn'; fa = 'VendReturn';
														|it = 'RAF';
														|pl = 'VendReturn';
														|tr = 'VendReturn'", Common.DefaultLanguageCode()));
	Map.Insert("ReturnablePackagingRedemptionByCustomer",		NStr("vi = 'NK';
																		|ru = 'НК';
																		|en = 'CustomInv'; fa = 'CustomInv';
																		|it = 'VAS';
																		|pl = 'CustomInv';
																		|tr = 'NK'", Common.DefaultLanguageCode()));
	Map.Insert("SalesOrder",						NStr("vi = 'ZK';
														|ru = 'ЗК';
														|en = 'SO'; fa = 'SO';
														|it = 'OC';
														|pl = 'SO';
														|tr = 'MS'", Common.DefaultLanguageCode()));
	Map.Insert("RequestForReturnOfGoodsFromCustomer",	NStr("vi = 'ZKV';
																|ru = 'ЗКВ';
																|en = 'RetReq'; fa = 'RetReq';
																|it = 'RRAC';
																|pl = 'RetReq';
																|tr = 'MMİT'", Common.DefaultLanguageCode()));
	Map.Insert("ConsignmentReportFromCustomer",					NStr("vi = 'Đồng ý';
																		|ru = 'ОК';
																		|en = 'ConsigneeRep'; fa = 'ConsigneeRep';
																		|it = 'RCc';
																		|pl = 'ConsigneeRep';
																		|tr = 'Tamam'", Common.DefaultLanguageCode()));
	Map.Insert("WriteOffReportFromCommissionAgent",			NStr("vi = 'OKS';
																	|ru = 'ОКС';
																	|en = 'ConsStockLost'; fa = 'ConsStockLost';
																	|it = 'RCsS';
																	|pl = 'ConsStockLost';
																	|tr = 'KDKR'", Common.DefaultLanguageCode()));
	Map.Insert("ConsignmentReportToVendor",						NStr("vi = 'OKT';
																		|ru = 'ОКТ';
																		|en = 'ConsRep'; fa = 'ConsRep';
																		|it = 'RCt';
																		|pl = 'ConsRep';
																		|tr = 'KB'", Common.DefaultLanguageCode()));
	Map.Insert("CommissionReportIntercompany",	NStr("vi = 'OKO';
														|ru = 'ОКО';
														|en = 'CommRep'; fa = 'CommRep';
														|it = 'RCO';
														|pl = 'CommRep';
														|tr = 'KAKR'", Common.DefaultLanguageCode()));
	Map.Insert("CustomerInvoice",				NStr("vi = 'NK';
														|ru = 'НК';
														|en = 'CustomInv'; fa = 'CustomInv';
														|it = 'VAS';
														|pl = 'CustomInv';
														|tr = 'NK'", Common.DefaultLanguageCode()));
	Map.Insert("CustomerInvoiceServicesAndAssets",		NStr("vi = 'NK';
																|ru = 'НК';
																|en = 'CustomInv'; fa = 'CustomInv';
																|it = 'VAS';
																|pl = 'CustomInv';
																|tr = 'NK'", Common.DefaultLanguageCode()));
	Map.Insert("CustomerInvoiceIntercompany",	NStr("vi = 'NK';
														|ru = 'НК';
														|en = 'CustomInv'; fa = 'CustomInv';
														|it = 'VAS';
														|pl = 'CustomInv';
														|tr = 'NK'", Common.DefaultLanguageCode()));
	Map.Insert("CustomerCommercialInvoice",				NStr("vi = 'HÓA ĐƠN';
																|ru = 'СЧ';
																|en = 'CommInv'; fa = 'CommInv';
																|it = 'CPC';
																|pl = 'CommInv';
																|tr = 'MÖF'", Common.DefaultLanguageCode()));
	Map.Insert("InvoiceIssued",				NStr("vi = 'HÓA ĐƠN';
													|ru = 'СФ';
													|en = 'TaxInv'; fa = 'صورت‌حساب مالیاتی';
													|it = 'FE';
													|pl = 'TaxInv';
													|tr = 'FT'", Common.DefaultLanguageCode()));
	Map.Insert("BankAccountIssue",	NStr("vi = 'TT';
											|ru = 'ПП';
											|en = '#'; fa = '#';
											|it = 'ПП';
											|pl = '#';
											|tr = 'PP'", Common.DefaultLanguageCode()));
	Map.Insert("MaterialProviderOrder2_5",					NStr("vi = 'ZKD';
																	|ru = 'ЗКД';
																	|en = 'MatProvOrder'; fa = 'MatProvOrder';
																	|it = 'RAC';
																	|pl = 'MatProvOrder';
																	|tr = 'TSS'", Common.DefaultLanguageCode()));
	Return Map[Ref.Metadata().Name];
	
EndFunction

Function GetUniquePaymentIDWithCheckDigit(Code,Move = Undefined)
	
	If Move = Undefined Then
		Move = 0;
	EndIf;
	
	CorrespondenceStructure = StructureOfCorrespondencesOfLettersAndNumbers();
	
	NumericString = "0123456789";	
	DischargeWeight = 1+Move;
	Result = 0;
	// Replacement of service characters in the code.
	StringOfLetters = "АБВГДЕЖЗИКЛМНОПРСТУФХЦЧШЩЭЮЯЪЫЬABCDEFGHIJKLMNOPQRSTUVWXYZ"; //@NON-NLS
	NewCode_ = "";
	For Indus = 1 To StrLen(Code) Do
		Try
			CodeSymbol = Upper(Mid(Code,Indus,1));
		Except
			CodeSymbol = Mid(Code,Indus,1);
		EndTry;
		If StrFind(NumericString,CodeSymbol)=0 And StrFind(StringOfLetters,CodeSymbol)=0 Then
			NewCode_ = NewCode_ + "0";
		Else
			NewCode_ = NewCode_ + CodeSymbol;
		EndIf;
	EndDo;
	Code = NewCode_;
	//End Substitutions_3
	If StrLen(Code)<19 Then
		CodeString = StringFunctionsClientServer.SupplementString(Code,19,"0","Right");
	Else
		CodeString = Left(Code,19);
	EndIf;
	
	For Indus = 1 To 19 Do 
		CodeSymbol = Mid(CodeString,Indus,1);
		If StrFind(NumericString,CodeSymbol)>0 Then
			Value = Number(CodeSymbol);
		ElsIf CorrespondenceStructure.Property(Upper(CodeSymbol)) Then
			Value = CorrespondenceStructure[CodeSymbol]%10;			
		EndIf;		
		Result = Result + DischargeWeight*Value;
		
		DischargeWeight = DischargeWeight + 1;
		If DischargeWeight = 11 Then
			DischargeWeight = 1;
		EndIf;
	EndDo;
	
	CheckDigit = Result % 11;
	
	If CheckDigit = 10 Then
		If Move = 0 Then
			Return GetUniquePaymentIDWithCheckDigit(Code,2);
		Else
			CheckDigit = 0;
		EndIf;
	EndIf;
	
	FullCode = CodeString+String(CheckDigit);
	
	Return FullCode;
	
EndFunction

Function StructureOfCorrespondencesOfLettersAndNumbers()
	
	CorrespondenceStructure = New Structure();
	
	CorrespondenceStructure.Insert("А", 1);   //@NON-NLS
	CorrespondenceStructure.Insert("Б", 2);   //@NON-NLS
	CorrespondenceStructure.Insert("В", 3);   //@NON-NLS
	CorrespondenceStructure.Insert("Г", 4);   //@NON-NLS
	CorrespondenceStructure.Insert("Д", 5);   //@NON-NLS
	CorrespondenceStructure.Insert("Е", 6);   //@NON-NLS
	CorrespondenceStructure.Insert("Ж", 7);   //@NON-NLS
	CorrespondenceStructure.Insert("З", 8);   //@NON-NLS
	CorrespondenceStructure.Insert("И", 9);   //@NON-NLS
	CorrespondenceStructure.Insert("К", 10);  //@NON-NLS
	CorrespondenceStructure.Insert("Л", 11);  //@NON-NLS
	CorrespondenceStructure.Insert("М", 12);  //@NON-NLS
	CorrespondenceStructure.Insert("Н", 13);  //@NON-NLS
	CorrespondenceStructure.Insert("О", 14);  //@NON-NLS
	CorrespondenceStructure.Insert("П", 15);  //@NON-NLS
	CorrespondenceStructure.Insert("Р", 16);  //@NON-NLS
	CorrespondenceStructure.Insert("С", 17);  //@NON-NLS
	CorrespondenceStructure.Insert("Т", 18);  //@NON-NLS
	CorrespondenceStructure.Insert("У", 19);  //@NON-NLS
	CorrespondenceStructure.Insert("Ф", 20);  //@NON-NLS
	CorrespondenceStructure.Insert("Х", 21);  //@NON-NLS
	CorrespondenceStructure.Insert("Ц", 22);  //@NON-NLS
	CorrespondenceStructure.Insert("Ч", 23);  //@NON-NLS
	CorrespondenceStructure.Insert("Ш", 24);  //@NON-NLS
	CorrespondenceStructure.Insert("Щ", 25);  //@NON-NLS
	CorrespondenceStructure.Insert("Э", 26);  //@NON-NLS
	CorrespondenceStructure.Insert("Ю", 27);  //@NON-NLS
	CorrespondenceStructure.Insert("Я", 28);  //@NON-NLS
	CorrespondenceStructure.Insert("Ъ", 33);  //@NON-NLS
	CorrespondenceStructure.Insert("Ы", 36);  //@NON-NLS
	CorrespondenceStructure.Insert("Ь", 46);  //@NON-NLS
	CorrespondenceStructure.Insert("A", 1);   //@NON-NLS
	CorrespondenceStructure.Insert("B", 3);   //@NON-NLS
	CorrespondenceStructure.Insert("C", 17);  //@NON-NLS
	CorrespondenceStructure.Insert("D", 29);  //@NON-NLS
	CorrespondenceStructure.Insert("E", 6);   //@NON-NLS
	CorrespondenceStructure.Insert("F", 30);  //@NON-NLS
	CorrespondenceStructure.Insert("G", 31);  //@NON-NLS
	CorrespondenceStructure.Insert("H", 13);  //@NON-NLS
	CorrespondenceStructure.Insert("I", 32);  //@NON-NLS
	CorrespondenceStructure.Insert("J", 33);  //@NON-NLS
	CorrespondenceStructure.Insert("K", 10);  //@NON-NLS
	CorrespondenceStructure.Insert("L", 34);  //@NON-NLS
	CorrespondenceStructure.Insert("M", 12);  //@NON-NLS
	CorrespondenceStructure.Insert("N", 35);  //@NON-NLS
	CorrespondenceStructure.Insert("O", 14);  //@NON-NLS
	CorrespondenceStructure.Insert("P", 16);  //@NON-NLS
	CorrespondenceStructure.Insert("Q", 36);  //@NON-NLS
	CorrespondenceStructure.Insert("R", 37);  //@NON-NLS
	CorrespondenceStructure.Insert("S", 38);  //@NON-NLS
	CorrespondenceStructure.Insert("T", 18);  //@NON-NLS
	CorrespondenceStructure.Insert("U", 39);  //@NON-NLS
	CorrespondenceStructure.Insert("V", 40);  //@NON-NLS
	CorrespondenceStructure.Insert("W", 41);  //@NON-NLS
	CorrespondenceStructure.Insert("X", 21);  //@NON-NLS
	CorrespondenceStructure.Insert("Y", 19);  //@NON-NLS
	CorrespondenceStructure.Insert("Z", 42);  //@NON-NLS
	
	Return CorrespondenceStructure;
	
EndFunction

// Returns a collapsed copy of the table
//
// Parameters:
//  Table					 - ValueTable - source table
//  GroupingColumns		 - String - The names of the columns that you want to group the rows.
//  AdditionalAnalytics	 - String - The names of the columns that you want to group the rows, if they exist in the source table.
//  TotalingColumns		 - String - The names of the columns that needs to sum values.
// 
// Returns:
//  ValueTable - collapsed copy of the value table
//
Function CollapsedCopyOfTable(Table, Val GroupingColumns, Val AdditionalAnalytics = Undefined, Val TotalingColumns = Undefined) Export
	
	If AdditionalAnalytics <> Undefined Then
		
		CompositionOfDOPAnalyst = StrSplit(AdditionalAnalytics, ",", False);
		
		For IndexOf = -CompositionOfDOPAnalyst.UBound() To 0 Do
			ColumnName = TrimAll(CompositionOfDOPAnalyst[-IndexOf]);
			If Table.Columns.Find(ColumnName) <> Undefined Then
				Continue;
			EndIf;
			CompositionOfDOPAnalyst.Delete(-IndexOf);
		EndDo;
		
		If CompositionOfDOPAnalyst.Count() <> 0 Then
			GroupingColumns = GroupingColumns + "," + StrConcat(CompositionOfDOPAnalyst, ",");
		EndIf;
		
	EndIf;
	
	If TotalingColumns <> Undefined Then
		NewColumnComposition = GroupingColumns + "," + TotalingColumns;
	Else
		NewColumnComposition = GroupingColumns;
	EndIf;
	
	If TypeOf(Table) <> Type("ValueTable") Then
		TempTable = Table.Unload(, NewColumnComposition);
	Else
		TempTable = Table.Copy(, NewColumnComposition);
	EndIf;
	
	TempTable.GroupBy(GroupingColumns, TotalingColumns);
	
	Return TempTable;
	
EndFunction

// Returns a table of values with data from the value tree
//
// Parameters:
//  DataTree - ValueTree - tree with data
//  Level		 - Number - the level of the tree where the required data is located (numbering from 0). If not passed, 
//						   data from all the last levels of branches will be returned.
//
// Returns:
//  ValueTable - contains tree data.
//
Function TreeData(DataTree, Level = Undefined) Export
	
	ReturnTable = New ValueTable;
	For Each Column In DataTree.Columns Do
		ReturnTable.Columns.Add(Column.Name, Column.ValueType);
	EndDo;
	
	TreeRows = DataTree.Rows;
	
	FillTableRecursively(ReturnTable, TreeRows, Level, 0);
	
	Return ReturnTable;

EndFunction

Procedure FillTableRecursively(ValueTable, TreeRows, DesiredLevel, CurrentLevel)
	
	For Each String In TreeRows Do

		If TypeOf(TreeRows) = Type("ValueTreeRowCollection") Then
			Substrings = String.Rows;
		ElsIf TypeOf(TreeRows) = Type("FormDataTreeItemCollection") Then
			Substrings = String.GetItems();
		EndIf;
		
		If DesiredLevel = CurrentLevel 
			Or (DesiredLevel = Undefined And Substrings.Count() = 0) Then
			NewString = ValueTable.Add();
			FillPropertyValues(NewString, String);
		Else
			FillTableRecursively(ValueTable, Substrings, DesiredLevel, CurrentLevel + 1);
		EndIf;
		
	EndDo;
	
EndProcedure

// Returns the properties of the last task.
//
// Parameters:
//  Job - ScheduledJob - the string of the unique identifier of the schedule task.
//          - Structure - Contains the key:
//          	* Id - CatalogRef.JobsQueue - 
//
// Returns:
//  Structure - Keys:
//	      * StartDate - Date -
//	      * CompletedOn - Date -
//	      * DatePlan - Date -
// 	      * State - BackgroundJobState -
//
Function GetStateOfLastJob(Job) Export
	
	JobProperties = New Structure("StartDate, CompletedOn, DatePlan, State");
	
	If Common.DataSeparationEnabled() Then
		
		CatalogItem = Common.ObjectAttributesValues(Job.Id, "BeginDateOfTheLastLaunch, EndDateOfTheLastLaunch, ScheduledStartTime, JobState");
		
		JobProperties.StartDate = CatalogItem.BeginDateOfTheLastLaunch;
		JobProperties.CompletedOn = CatalogItem.EndDateOfTheLastLaunch;
		JobProperties.DatePlan = CatalogItem.ScheduledStartTime;
		JobProperties.State = CatalogItem.JobState;
		
	Else
		
		ScheduledJobsInternal.RaiseIfNoAdministrationRights();
		SetPrivilegedMode(True);
		
		ScheduledJobID = ?(TypeOf(Job) = Type("ScheduledJob"), String(Job.UUID), Job);
		Filter = New Structure;
		Filter.Insert("ScheduledJobID", ScheduledJobID);
		Filter.Insert("GetLastScheduledJobBackgroundJob");
		BackgroundJobPropertyTable = ScheduledJobsInternal.BackgroundJobsProperties(Filter);
		BackgroundJobPropertyTable.Sort("End Asc");
		
		If BackgroundJobPropertyTable.Count() = 0 Then
			RegTaskProperties = Undefined;
		ElsIf Not ValueIsFilled(BackgroundJobPropertyTable[0].End) Then
			RegTaskProperties = BackgroundJobPropertyTable[0];
		Else
			RegTaskProperties = BackgroundJobPropertyTable[BackgroundJobPropertyTable.Count()-1];
		EndIf;
		
		If RegTaskProperties <> Undefined Then
		
			JobProperties.StartDate = RegTaskProperties.Begin;
			JobProperties.CompletedOn = RegTaskProperties.End;
			JobProperties.State = RegTaskProperties.State;
		
		EndIf;
		
	EndIf;
	
	Return JobProperties;
	
EndFunction

Function PropertyOfMetadata(ObjectMetadata, NameParts, IndexOf = 0)
	
	Name = NameParts[IndexOf];
	Property = ObjectMetadata[Name];
	If IndexOf < NameParts.UBound() Then
		Property = PropertyOfMetadata(Property, NameParts, IndexOf+1);
	EndIf;
	Return Property;
	
EndFunction

// Checks that the passed type is primitive
//
// Parameters:
//  TypeToCheck - Type - 
// 
// Returns:
//  Boolean -
//
Function IsPrimitiveType(TypeToCheck) Export
	
	If TypeToCheck = Type("Undefined")
		Or TypeToCheck = Type("Boolean")
		Or TypeToCheck = Type("String")
		Or TypeToCheck = Type("Number")
		Or TypeToCheck = Type("Date")
		Or TypeToCheck = Type("UUID") Then
		
		Return True;
		
	Else
		
		Return False;
		
	EndIf;
	
EndFunction

// The representation of the object metadata
//
// Parameters:
//  ObjectMetadata - MetadataObject -
// 
// Returns:
//  String -
//
Function ObjectPresentationByMetadata(ObjectMetadata) Export
		
	If Not IsBlankString(ObjectMetadata.ObjectPresentation) Then
		Return ObjectMetadata.ObjectPresentation;
	Else
		Return ObjectMetadata.Synonym;
	EndIf;
	
EndFunction

// Gets a warehouse that can be used by default
// If the warehouse could not be identified and several warehouses are not used, the user will receive a message.
// 
// Returns:
//   CatalogRef.Warehouses - 
//
Function GetCheckWarehouseByDefault() Export

	DefaultWarehouse = SettingsValueCached.GetDefaultWarehouse();
	
	If Not ValueIsFilled(DefaultWarehouse)
		And Not GetFunctionalOption("UseSeveralWarehouses") Then
		
		Query = New Query(
		"SELECT ALLOWED TOP 2
		|	Warehouses.Ref
		|FROM
		|	Catalog.Warehouses AS Warehouses");
		
		If Query.Execute().Select().Count() = 2 Then
			Raise NStr("vi = 'Không thể xác định kho bãi, bởi vì trong cơ sở thông tin đã nhập nhiều kho bãi,
			|Hãy bật tùy chọn ""Danh mục và quản trị"" - ""Kho bãi và vận chuyển"" - ""Nhiều kho bãi""!';
			|ru = 'Не удалось определить склад, т.к. в информационной базе введено несколько складов,
			|Включите опцию ""НСИ и администрирование""-""Склад и доставка""-""Несколько складов""!';
			|en = 'Cannot determine a warehouse as several warehouses are entered in the infobase.
			|In the ""Master data and settings"" - ""Warehouse and delivery"" section, select the ""Multiple warehouses"" check box.'; fa = 'Cannot determine a warehouse as several warehouses are entered in the infobase.
			|In the ""Master data and settings"" - ""Warehouse and delivery"" section, select the ""Multiple warehouses"" check box.';
			|it = 'Non è stato possibile definire il magazzino, poiché nel database sono inseriti alcuni magazzini, 
			| attivare l''opzione ""dati principali e impostazioni"" - ""magazzino e consegna"" - ""alcuni magazzini""!';
			|pl = 'Nie udało się określić magazyn, ponieważ w bazie informacyjnej wprowadzono kilka magazynów,
			|Włącz opcję ""Ustawienia""-""Magazyn i dostawa""-""Kilka magazynów""!';
			|tr = 'Infobase''e birden fazla ambar girildiği için ambar tanımlanamadı,
			| ""Master veri ve yönetim""-""Ambar ve Teslimat""-""Birden fazla ambar"" seçeneğini etkinleştir!'");
		Else
			Raise NStr("vi = 'Không thể xác định kho bãi. Có thể là trong cơ sở thông tin chưa nhập kho bãi nào
			|Để tùy chỉnh, cần chuyển đến phân hệ ""Danh mục và quản trị"" - ""Thông tin về công ty"" - ""Tùy chỉnh kế toán kho bãi"".';
			|ru = 'Не удалось определить склад. Возможно, в информационной базе не введено ни одного склада
			|Для настройки необходимо перейти в раздел ""НСИ и администрирование""-""Сведения о предприятии""-""Настройка складского учета"".';
			|en = 'Cannot identify a warehouse. Probably no warehouses are registered in the infobase.
			|To fix this issue, go to ""Master data and settings"" – ""Enterprise information"" – ""Configure warehouse accounting"".'; fa = 'Cannot identify a warehouse. Probably no warehouses are registered in the infobase.
			|To fix this issue, go to ""Master data and settings"" – ""Enterprise information"" – ""Configure warehouse accounting"".';
			|it = 'Non è stato possibile indicare un magazzino. Probabilmente nel database non è inserito alcun magazzino
			| Per le impostazioni passare alla sezione ""dati principali e impostazioni"" - ""informazioni sull''impresa"" - ""impostazioni della contabilità di magazzino"".';
			|pl = 'Nie udało się określić magazyn. Możliwe, że do bazy informacyjnej nie wprowadzono żadnego magazynu
			|W celu ustawienia należy przejść do rozdziału ""Ustawienia""-""Dane o przedsiębiorstwie""-""Ustawienia ewidencji magazynowej"".';
			|tr = 'Ambar tanımlanamadı. Muhtemelen infobase''e hiçbir ambar girilmedi
			|Ayarlar için ""Master veri ve yönetim""-""İşletme bilgileri""-""Stok muhasebe ayarları"" bölümüne gidilmeli.'");
		EndIf;
		
	EndIf;

	Return DefaultWarehouse
	
EndFunction

// We set the conditional registration for the field of the form "Variantformations" in the document customs Declaration,
//    depending on its value.
//
// Parameters:
// 		List - ClientApplicationForm - Contains this form.
//
Procedure EstablishConditionalAppearanceVariantOfCCDDesign(List) Export
	
	ConditionalAppearance = List.ConditionalAppearance;
	
	//
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();

	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("RegistrationOption");

	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RegistrationOption");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.RegisterCCDThroughBroker;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = 'Qua môi giới';
																		|ru = 'Брокером';
																		|en = 'Broker'; fa = 'کارگزار';
																		|it = 'Dal broker';
																		|pl = 'Przez brokera';
																		|tr = 'Komisyoncu'"));
	
	//
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();

	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("RegistrationOption");

	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RegistrationOption");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BusinessTransactions.RegisterCCDUnassisted;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = 'Tự làm';
																		|ru = 'Самостоятельно';
																		|en = 'Independently'; fa = 'به‌طور مستقل';
																		|it = 'Autonomamente';
																		|pl = 'Samodzielnie';
																		|tr = 'Bağımsız'"));
	
EndProcedure

// Parameters:
// 	Ref - DocumentRef - 
// 	Registers - See TMCommonUseCached.MeasurementMetadataInformationRegisters
Function ThisIsSlaveInformationRegisterEntry(Ref, Registers)
	
	For Each Item In Registers Do
		If TypeOf(Ref) = Type("InformationRegisterRecordKey." + Item.Name) Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

Function ThisIsRecordOfExcludedObject(Ref, Objects)
	
	For Each Item In Objects Do
		FullName = Item.FullName();
		
		MetadataKind = "";
		If StrFind(FullName, "Catalog.") Then
			MetadataKind = "CatalogRef";
		ElsIf StrFind(FullName, "Document.") Then
			MetadataKind = "DocumentRef";
		ElsIf StrFind(FullName, "InformationRegister.") Then
			MetadataKind = "InformationRegisterRecordKey";
		Else
			Return False;
		EndIf;
		
		If TypeOf(Ref) = Type(MetadataKind + "." + Item.Name) Then
			Return True;
		Else
			Return False;
		EndIf;
		
	EndDo;
	
EndFunction

Function OrderAssignments(AnArrayOfOrders)
	
	Query = New Query();
	Query.Text =
		"SELECT
		|	Table.Ref AS Ref
		|FROM
		|	Catalog.Assignments AS Table
		|WHERE
		|	Table.OrderDocument IN(&AnArrayOfOrders)";
	Query.SetParameter("AnArrayOfOrders", AnArrayOfOrders);
	Return Query.Execute().Unload().UnloadColumn("Ref");
	
EndFunction

// Transfers a file from the previous owner to the new one
//
// Parameters:
//	FileOwner - AnyRef - link to the new file owner object
//	PropsReceiver - CatalogRef -
//	                 - CatalogRef.PartnersAttachedFiles - The value of the receiver variable of the link to the new file
//	SourceProps - CatalogRef -
//	                 - CatalogRef.PartnersAttachedFiles - The value of the source variable of the link to the new file
//	CreateNewFileLink - Boolean - specifies whether to create a file with a new link or use the current one.
//
Procedure CopyAttachedFile_(FileOwner, PropsReceiver, SourceProps, CreateNewFileLink = True) Export
	SourceFile1 = FilesOperations.FileData(SourceProps, New UUID, True);
	
	Parameters = New Structure;
	Parameters.Insert("Author", Users.CurrentUser());
	Parameters.Insert("FilesOwner", FileOwner);
	Parameters.Insert("BaseName", SourceFile1.Description);
	Parameters.Insert("ExtensionWithoutPoint", SourceFile1.Extension);
	Parameters.Insert("ModificationTimeUniversal", SourceFile1.UniversalModificationDate);
	
	CatalogName = FilesOperationsInternal.FileStoringCatalogName(FileOwner,, Undefined);
	
	PropsReceiver = FilesOperations.AppendFile(
		Parameters,
		SourceFile1.RefToBinaryFileData,,
		Common.ObjectAttributeValue(SourceProps, "LongDesc"),
		?(CreateNewFileLink, 
			Undefined, 
			Catalogs[CatalogName].GetRef(SourceProps.UUID())
		)
	);
EndProcedure

// Returns the hash sum of the passed object
//
// Parameters:
//	SerializableObject - Arbitrary - an object that can be serialized. Otherwise, an exception will be thrown.
//	TypeOfHashFunction - HashFunction - one type of hash function is CRC32, MD5, SHA1, SHA256.
//
// Returns:
//  String - hash sum in the form of a string.
//
Function HashSumOfSerializableObject(SerializableObject, TypeOfHashFunction) Export
	SerializedString = Common.ValueToXMLString(SerializableObject);
	
	DataHashing = New DataHashing(TypeOfHashFunction);
	DataHashing.Append(SerializedString);
	HashSum = StrReplace(DataHashing.HashSum, " ", "");
	
	Return HashSum;
EndFunction

// Returns the hash sum of the passed object
//
// Parameters:
//	InitialString - String - the string that will be used to build the hash. Otherwise, an exception will be thrown.
//	TypeOfHashFunction - HashFunction - one type of hash function is CRC32, MD5, SHA1, SHA256.
//
// Returns:
//  String - hash sum in the form of a string.
//
Function HashSumOfString(InitialString, TypeOfHashFunction) Export
	If Not TypeOf(InitialString) = Type("String") Then
		Raise NStr("vi = 'Loại nguồn nhận dữ liệu không hợp lệ.';
					|ru = 'Недопустимый тип источника получения данных.';
					|en = 'Invalid type of data receipt source.'; fa = 'Invalid type of data receipt source.';
					|it = 'Tipo di origine dati non valido.';
					|pl = 'Niedopuszczalny typ źródła pobierania danych.';
					|tr = 'Veri alım kaynağının kabul edilemeyecek türü'");
	EndIf;
	
	DataHashing = New DataHashing(TypeOfHashFunction);
	DataHashing.Append(InitialString);
	HashSum = StrReplace(DataHashing.HashSum, " ", "");
	
	Return HashSum;
EndFunction

Procedure CheckUsageOfPropsGetEmptyValue(Object, ObjectMetadata, AttributeName, EmptyPropsValues)
	
	If EmptyPropsValues.Property(AttributeName) Then
		Return;
	EndIf;
	
	AttributeMetadata = ObjectMetadata.Attributes.Find(AttributeName);
	
	If AttributeMetadata = Undefined Then
		
		For Each StandardAttribute In ObjectMetadata.StandardAttributes Do
			If StandardAttribute.Name = AttributeName Then
				AttributeMetadata = StandardAttribute;
				Break;
			EndIf;
		EndDo;
		
		If AttributeMetadata = Undefined Then
			ExceptionText = NStr("vi = 'Mục tin %AttributeName% không tìm thấy trong %OjectName%. Lỗi trong mô tả các tham số đồng bộ hóa với các khóa.';
								|ru = 'Реквизит %AttributeName% не найден в %OjectName%. Ошибка в описании параметров синхронизации с ключами.';
								|en = 'The%AttributeName% attribute is not found in the %OjectName%. An error occurred in description of parameters of synchronization with keys.'; fa = 'The%AttributeName% attribute is not found in the %OjectName%. An error occurred in description of parameters of synchronization with keys.';
								|it = 'Requisito %AttributeName% non trovato in %OjectName%. Errore di descrizione dei parametri di sincronizzazione con le chiavi.';
								|pl = 'Atrybut %AttributeName% nie znaleziony w %OjectName%. Błąd w opisie parametrów synchronizacji z kluczami.';
								|tr = '%AttributeName% özniteliği, %OjectName% içinde bulunamadı. Anahtar senkronizasyon parametrelerinin ayrıntılarında hata.'");
			ExceptionText = StrReplace(ExceptionText, "%AttributeName%", AttributeName);
			ExceptionText = StrReplace(ExceptionText, "%OjectName%", ObjectMetadata.FullName());
			Raise ExceptionText;
		EndIf;
		
	Else
		
		If (Common.IsCatalog(ObjectMetadata)
			Or Common.IsChartOfCharacteristicTypes(ObjectMetadata))
			And (ObjectMetadata.Hierarchical
			And ObjectMetadata.HierarchyType = Metadata.ObjectProperties.HierarchyType.HierarchyFoldersAndItems) Then
			
			If AttributeMetadata.Use <> Metadata.ObjectProperties.AttributeUse.ForFolderAndItem Then
				
				If (Object.IsFolder
					And AttributeMetadata.Use = Metadata.ObjectProperties.AttributeUse.ForItem)
					Or (Not Object.IsFolder
					And AttributeMetadata.Use = Metadata.ObjectProperties.AttributeUse.ForFolder) Then
					
					EmptyPropsValues.Insert(AttributeName, "NotUsed");
					Return;
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	EmptyPropsValues.Insert(AttributeName,	AttributeMetadata.Type.AdjustValue()); 
		
EndProcedure

// Performs convolution of a set of register entries.
//
// Parameters:
// 	Set - AccumulationRegisterRecordSet, InformationRegisterRecordSet - 
// 	SortingIsRequired - Boolean - Is it required to sort the set before recording by dimensions.
//
Procedure CollapseRecordSet(Set, SortingIsRequired = False) Export
	
	RegisterEntries_ = Set.Unload();
	
	AllColumns = New Array();
	For Each Column In RegisterEntries_.Columns Do
		AllColumns.Add(Column.Name);
	EndDo;
	
	Resources = New Array();
	SelectionOfEmptyResources = New Structure();
	For Each Resource In Set.Metadata().Resources Do
		Resources.Add(Resource.Name);
		SelectionOfEmptyResources.Insert(Resource.Name, 0);
	EndDo;
	
	GroupColumns = TMCommonUseClientServer.ArrayDifferences(AllColumns, Resources);
	GroupColumns.Delete(GroupColumns.Find("LineNumber"));
	
	RowGroupingColumns = StrConcat(GroupColumns, ", ");
	RowSummationColumns = StrConcat(Resources, ", ");
	
	RegisterEntries_.GroupBy(RowGroupingColumns, RowSummationColumns);
	
	For Each RecordingWithEmptyResources In RegisterEntries_.FindRows(SelectionOfEmptyResources) Do
		RegisterEntries_.Delete(RecordingWithEmptyResources);
	EndDo;
	
	If SortingIsRequired Then
		ObjectOfComparison = New CompareValues;
		RegisterEntries_.Sort(RowGroupingColumns, ObjectOfComparison);
	EndIf;
	Set.Load(RegisterEntries_);
	
EndProcedure

// Checks whether the passed type is marked for deletion in future releases.
//
// Parameters:
// 	ObjectType - Type
//
// Returns:
//  Boolean -
//
Function ObjectToDelete(ObjectType) Export
	
	MetadataObject = Metadata.FindByType(ObjectType);
	If MetadataObject = Undefined Then
		Return False;
	Else 
		Return StrStartsWith(MetadataObject.Name, "Delete");    
	EndIf;
EndFunction

#EndRegion

#Region OperationsWithDocumentJournals 

// Array of document managers used in the passed array of business operations.
//
// Parameters:
//  AvailableBusinessTransactionsAndDocuments - Array - 
// 
// Returns:
//  Array -
//
Function DocumentManagersUsed(AvailableBusinessTransactionsAndDocuments) Export 
	
	TableOfOperationOverhead = SelectedBusinessOperationsAndDocuments(AvailableBusinessTransactionsAndDocuments);
	
	MetadataOfDocuments = TableOfOperationOverhead.UnloadColumn("DocumentMetadataObject"); // Array of MetadataObject -
	
	ArrayOfManagers = New Array();
	
	For Each String In MetadataOfDocuments Do
		Name = String.Name;
		ManagerOfDocument = Common.ObjectManagerByFullName(Name);
		ArrayOfManagers.Add(ManagerOfDocument);
	EndDo;
	
	ArrayOfManagers = CommonClientServer.CollapseArray(ArrayOfManagers);
	
	Return ArrayOfManagers;
	
EndFunction

// Array of document types used in the passed array of business operations.
//
// Parameters:
//  BusinessTransactionsAndDocuments - Array - 
//  Filter 						- Structure - The structure of the selection table Opionionated.
// 
// Returns:
//   Array of String -
//
Function FullDocumentNamesUsed(BusinessTransactionsAndDocuments, Filter = Undefined) Export 
	
	FullNamesOfDocuments = New Array();
	
	TableOfOperationOverhead = SelectedBusinessOperationsAndDocuments(BusinessTransactionsAndDocuments);
		
	If Filter <> Undefined Then
		FoundRows = TableOfOperationOverhead.FindRows(Filter);
		
		For Each String In FoundRows Do
			FullNamesOfDocuments.Add(String.FullDocumentName);
		EndDo;
	Else
		
		FullNamesOfDocuments = TableOfOperationOverhead.UnloadColumn("FullDocumentName");
		
	EndIf;
	
	FullNamesOfDocuments = CommonClientServer.CollapseArray(FullNamesOfDocuments);
	
	Return FullNamesOfDocuments;
	
EndFunction

// Returns a table with selected selections for households. operations and documents
//
// Parameters:
//  AvailableBusinessTransactionsAndDocuments - ValueTable	 - unloading the table from the details of the form economic Operationidocuments.
// 
// Returns:
//  ValueTable - 
//
Function SelectedBusinessOperationsAndDocuments(AvailableBusinessTransactionsAndDocuments) Export  
	
	SelectedTable = AvailableBusinessTransactionsAndDocuments.CopyColumns();
	
	Filter = New Structure();
	Filter.Insert("Filter", True);
	
	FoundRows = AvailableBusinessTransactionsAndDocuments.FindRows(Filter);
	
	For Each FoundRow In FoundRows Do
		String = SelectedTable.Add();
		FillPropertyValues(String, FoundRow);
	EndDo;
	
	Return SelectedTable;
	
EndFunction

// Selected business operations
//
// Parameters:
//  BusinessTransactionsAndDocuments	 - FormDataCollection - List of form values with available utilities. operations.
// 
// Returns:
//  Array - 
//
Function DedicatedBusinessOperations(BusinessTransactionsAndDocuments) Export 
	
	ArrayOfBusinessTransactions = New Array();
	
	ArrayOfSelectedRows = BusinessTransactionsAndDocuments.FindRows(New Structure("Filter", True));	
	
	For Each String In ArrayOfSelectedRows Do
		ArrayOfBusinessTransactions.Add(String.BusinessOperation);
	EndDo;
	
	// An empty array means no selection. The absence of selection is equivalent to all the selected elements.
	If ArrayOfBusinessTransactions.Count() = 0 Then
		ArrayOfBusinessTransactions = BusinessTransactionsAndDocuments.UnloadColumn("BusinessOperation");
	EndIf;
	
	Return ArrayOfBusinessTransactions;
	
EndFunction

// The procedure is to Remove the sub-elements of the form
//
// Parameters:
//  Form			 - ClientApplicationForm - form to delete elements from
//  FormItem	 - FormTable, FormGroup - the form element whose subordinate elements you want to delete
//  DeleteCommands	 - Boolean - 
//
Procedure DeleteSubordinateElementsOfFormElement(Form, FormItem, DeleteCommands = False) Export 
	
	ItemsToDelete_1 = New Array();
	CommonClientServer.SupplementArray(ItemsToDelete_1, FormItem.ChildItems);
	For ElementIndex = 0 To ItemsToDelete_1.Count() - 1 Do
		
		Item = ItemsToDelete_1[ElementIndex];
		
		If TypeOf(Item) = Type("FormGroup") Then
			DeleteSubordinateElementsOfFormElement(Form, Item, DeleteCommands);
		ElsIf TypeOf(Item) = Type("FormButton")
			And DeleteCommands Then			
			DeleteCommand_ = Form.Commands.Find(Item.CommandName);
			If DeleteCommand_ <> Undefined Then
				Form.Commands.Delete(DeleteCommand_);
			EndIf;
		EndIf;
		
		Form.Items.Delete(Item);
		
	EndDo;
	
EndProcedure

// Adds status change buttons to the form group
//
// Parameters:
//  Form - ClientApplicationForm - 
//  SetStatusList - FormGroup - The group of the form where the status change buttons should be placed.
//
Procedure SetListOfStatuses(Form, SetStatusList) Export
		
	// Clearing items in case of reinitialization of the status list
	DeleteSubordinateElementsOfFormElement(Form, SetStatusList);
	
	Form.CorrespondenceOfCommandsToStatuses.Clear();
	
	Statuses_Document = New ValueTable();
	Statuses_Document.Columns.Add("DocumentName", 			New TypeDescription("String"));
	Statuses_Document.Columns.Add("DocumentSynonym", 		New TypeDescription("String"));
	Statuses_Document.Columns.Add("StatusPresentation", 	New TypeDescription("String"));
	Statuses_Document.Columns.Add("StatusValueName", 	New TypeDescription("String"));
	Statuses_Document.Columns.Add("Status");
	
	MatchingOperations_ = SelectedBusinessOperationsAndDocuments(Form.BusinessTransactionsAndDocuments.Unload());
		
	MatchingOperations_.GroupBy("FullDocumentName, StatusesAreUsed, AccessRightUpdate");
	
	For Each MapRow In MatchingOperations_ Do
		
		If MapRow.StatusesAreUsed And MapRow.AccessRightUpdate Then
			ManagerOfDocument = Common.ObjectManagerByFullName(MapRow.FullDocumentName);
			DocumentStatuses = ManagerOfDocument.DocumentStatusesThatCanBeChangedFromList();
			ObjectMetadata = ObjectMetadataByFullName(MapRow.FullDocumentName);
			For Each RowStatus In DocumentStatuses Do
				DocumentStatusString = Statuses_Document.Add();
				DocumentStatusString.DocumentName = ObjectMetadata.Name;
				DocumentStatusString.DocumentSynonym = ObjectMetadata.Synonym;
				DocumentStatusString.Status = RowStatus.Status;
				DocumentStatusString.StatusPresentation = RowStatus.StatusPresentation;
				DocumentStatusString.StatusValueName = Common.EnumerationValueName(RowStatus.Status);
			EndDo;
		EndIf;
		
	EndDo;
	
	For IndexOf = 0 To Statuses_Document.Count() - 1 Do
		
		DocumentStatusString = Statuses_Document[IndexOf];
		
		UniqueButtonName = DocumentStatusString.DocumentName + IndexOf;
		
		If Form.Commands.Find(UniqueButtonName) = Undefined Then
			Command = Form.Commands.Add(UniqueButtonName);
			Command.Action = "Attachable_SetStatus";
		EndIf;
		
		Button = Form.Items.Add(UniqueButtonName, Type("FormButton"), SetStatusList);
		Button.Title = DocumentStatusString.DocumentSynonym + ": " + DocumentStatusString.StatusPresentation;
		Button.CommandName = UniqueButtonName;
		
		CommandMatchingString = Form.CorrespondenceOfCommandsToStatuses.Add();
		CommandMatchingString.CommandName = UniqueButtonName;
		CommandMatchingString.Status = DocumentStatusString.Status;
		CommandMatchingString.StatusPresentation = DocumentStatusString.StatusPresentation;
		CommandMatchingString.StatusValueName = DocumentStatusString.StatusValueName;
		CommandMatchingString.DocumentString = DocumentStatusString.DocumentName;
		
	EndDo;
	
EndProcedure

// Returns the template table for insertion of the descriptions of the statuses for log documents.
// 
// Returns:
//  ValueTable - table with columns:
//		*Status - EnumRef - link to the document status
//		*StatusPresentation - String - status view; specified if you want to redefine the status synonym.
//
Function TableOfStatusesToChangeFromList() Export 
	
	Table = New ValueTable;
	Table.Columns.Add("Status");
	Table.Columns.Add("StatusPresentation", New TypeDescription("String"));
	
	Return Table;
	
EndFunction

// Adds a row to a previously created table
//
// Parameters:
//  Table				 - See TableOfStatusesToChangeFromList
//  Status				 - EnumRef	 - See TableOfStatusesToChangeFromList.
//  StatusPresentation	 - String				 - See TableOfStatusesToChangeFromList.
//
Procedure AddRowToTableOfStatusesToChangeFromList(Table, Status, Val StatusPresentation = "") Export
	
	NewRow = Table.Add();
	NewRow.Status = Status;
	If Not ValueIsFilled(StatusPresentation) Then 
		StatusPresentation = String(Status);
	EndIf;
	NewRow.StatusPresentation = StatusPresentation;
		
EndProcedure

// Returns an array of metadata objects for the business Operationsidocuments table
//
// Parameters:
//  BusinessTransactionsAndDocuments - ValueTable -
//	                                - FormDataCollection - table with columns "Full document name" and "Selection"
//  Filter							- Structure - structure of additional selections, the keys of which should be columns in the table economic Operationidocuments.
// 
// Returns:
//  Array - an array of metadata objects.
//
Function MetadataObjectsFromBusinessTransactionsAndDocuments(BusinessTransactionsAndDocuments, Filter = Undefined) Export
	
	FilterStructure1 = New Structure("Filter",True);
	If Filter <> Undefined Then
		CommonClientServer.SupplementStructure(FilterStructure1, Filter);
	EndIf;
	FoundRows = BusinessTransactionsAndDocuments.FindRows(FilterStructure1);
	ProcessedNames = New Map;
	MetadataObjects = New Array;
	For Each Page1 In FoundRows Do
		If ProcessedNames.Get(Page1.FullDocumentName) = Undefined Then
			ProcessedNames.Insert(Page1.FullDocumentName, Page1.FullDocumentName);
			ObjectMetadata = Metadata.FindByFullName(Page1.FullDocumentName);
			MetadataObjects.Add(ObjectMetadata);
		EndIf;
	EndDo;
	Return MetadataObjects;
	
EndFunction

Function CreateHyperlinkToDesign(BusinessTransactionsAndDocuments, GenerationParameters, Title = "") Export
	
	RowsArray = New Array;
	RowsArray.Add(?(IsBlankString(Title), NStr("vi = 'Để lập:';
												|ru = 'К оформлению:';
												|en = 'To register:'; fa = 'To register:';
												|it = 'In formalizzazione:';
												|pl = 'Do sporządzenia:';
												|tr = 'Düzenlenecek'"), Title) + " ");
	
	FilterStructure1 = New Structure("Filter", True);
	HyperlinkCalculationManagers = BusinessTransactionsAndDocuments.Copy(FilterStructure1, "HyperlinkCalculationManagerForRegistration");
	
	HyperlinkCalculationManagers.GroupBy("HyperlinkCalculationManagerForRegistration");
	HyperlinkCalculationManagers = HyperlinkCalculationManagers.UnloadColumn("HyperlinkCalculationManagerForRegistration");
	
	For Each HyperlinkCalculationManager In HyperlinkCalculationManagers Do
		If HyperlinkCalculationManager = "" Then
			Continue;
		EndIf;
		
		GenerationParameters.Insert("BusinessTransactionsAndDocuments",BusinessTransactionsAndDocuments);
		ObjectManager = ?(Metadata.CommonModules.Find(HyperlinkCalculationManager) <> Undefined,
							Common.CommonModule(HyperlinkCalculationManager),
							Common.ObjectManagerByFullName(HyperlinkCalculationManager));
		Hyperlink = ObjectManager.CreateHyperlinkToDesign(GenerationParameters);
		
		If TypeOf(Hyperlink) <> Type("Array") Then 
			Hyperlink = CommonClientServer.ValueInArray(Hyperlink);
		EndIf;
		
		For Each CurrentHyperlink In Hyperlink Do 
			If ValueIsFilled(CurrentHyperlink) Then
				If RowsArray.Count()>1 Then
					RowsArray.Add("; ");
				EndIf;
				RowsArray.Add(CurrentHyperlink);
			EndIf;
		EndDo;
		
	EndDo;
	
	If RowsArray.Count() = 1 Then
		Return Undefined
	Else
		Return New FormattedString(RowsArray)
	EndIf;
	
EndFunction

Function CreateHyperlinkSeeAlsoIn(ArrayCalculationManagersSeeAlsoInWork, GenerationParameters, Title = "") Export
	
	TitleLine_ = ?(IsBlankString(Title),
		NStr("vi = 'Xem thêm';
			|ru = 'См. также:';
			|en = 'See also:'; fa = 'همچنین ببینید:';
			|it = 'Vedi anche:';
			|pl = 'Zob. także:';
			|tr = 'Ayrıca bakınız:'"),
		Title) + " ";
	
	RowsArray = New Array;
	RowsArray.Add(TitleLine_);
		
	For Each CalculationManagerSeeAlsoInProgress In ArrayCalculationManagersSeeAlsoInWork Do
		If CalculationManagerSeeAlsoInProgress = "" Then
			Continue;
		EndIf;
		
		Hyperlink = Common.ObjectManagerByFullName(CalculationManagerSeeAlsoInProgress).CreateHyperlinkSeeAlsoIn(GenerationParameters);
		
		If ValueIsFilled(Hyperlink) Then
			If RowsArray.Count()>1 Then
				RowsArray.Add("; ");
			EndIf;
			RowsArray.Add(Hyperlink);
		EndIf;
	EndDo;
	
	If RowsArray.Count() = 1 Then
		Return Undefined
	Else
		Return New FormattedString(RowsArray)
	EndIf;
	
EndFunction

// Returns an array of business operations of the transmitted document types
// that are reflected in the document registry and are not disabled by the FO.
//
// Parameters:
//  DocumentTypes - Array of Type - array of types.
// 
// Returns:
//  Array of EnumRef.BusinessTransactions - 
//
Function BusinessTransactionsReflectedInRegister(DocumentTypes) Export
	
	ArrayOfIdentifiers = New Array;
	ArrayOfBusinessOperations = New Array;
	
	For Each ArrRow In DocumentTypes Do
		If Common.IsReference(ArrRow) Then
			MetadataObject = Metadata.FindByType(ArrRow);
			If MetadataObjectAvailableByFunctionalOptions(MetadataObject) Then
				ArrayOfIdentifiers.Add(Common.MetadataObjectID(MetadataObject));
			EndIf;
		EndIf;
	EndDo;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ISNULL(BusinessTransactionsSettingsFunctionalOptions.FunctionalOptionName, """") AS FunctionalOptionName,
	|	BusinessTransactionsSettingsDocuments.Ref.BusinessOperation AS BusinessOperation
	|FROM
	|	Catalog.BusinessTransactionsSettings.Documents AS BusinessTransactionsSettingsDocuments
	|		LEFT JOIN Catalog.BusinessTransactionsSettings.FunctionalOptions AS BusinessTransactionsSettingsFunctionalOptions
	|		ON BusinessTransactionsSettingsFunctionalOptions.Ref = BusinessTransactionsSettingsDocuments.Ref
	|WHERE
	|	BusinessTransactionsSettingsDocuments.MetadataObjectID IN(&ArrayOfIdentifiers)
	|	AND BusinessTransactionsSettingsDocuments.Ref.UseInDocumentRegistry
	|
	|ORDER BY
	|	BusinessOperation";
	
	Query.SetParameter("ArrayOfIdentifiers", ArrayOfIdentifiers);
	
	CurBusinessTransaction = Undefined;
	BusinessTransactionAdded = False;
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		If CurBusinessTransaction <> Selection.BusinessOperation Then 
			BusinessTransactionAdded = False;
			CurBusinessTransaction = Selection.BusinessOperation; 
		EndIf;
		
		FullNameFO = StrTemplate("FunctionalOption.%1", Selection.FunctionalOptionName);
		ThereIsFO = Metadata.FindByFullName(FullNameFO) <> Undefined;
		
		If Not BusinessTransactionAdded  
			And (Not ThereIsFO
			Or GetFunctionalOption(Selection.FunctionalOptionName)) Then
			
			BusinessTransactionAdded = True;
			ArrayOfBusinessOperations.Add(Selection.BusinessOperation);
			
		EndIf;
		
	EndDo;
	
	Return ArrayOfBusinessOperations; 
	
EndFunction

// Sets the selection in the dynamic list on measurements, which are stored in the registry keys documents.
//
// Parameters:
//  List			 - DynamicList - 
//  FilterName		 - String -
//  FilterValues	 - CatalogRef -
//	                 - ValueList - selection values, which, if necessary,
//						are converted into document registry keys.
//
Procedure SetByDimensionWithKeys(List, FilterName, FilterValues) Export
	
	ToSearchForKeys = New ValueTable;
	ToSearchForKeys.Columns.Add("Ref", Metadata.Catalogs.DocumentRegistryKeys.Attributes.Key.Type);
	
	SelectionValuesForInstallation = New ValueList;
	
	If TypeOf(FilterValues) = Type("ValueList") Then
		For Each ListItem In FilterValues Do
			If ValueIsFilled(ListItem.Value) Then
				If TypeOf(ListItem.Value) = Type("CatalogRef.DocumentRegistryKeys") Then
					SelectionValuesForInstallation.Add(ListItem.Value);
				Else
					NewRow = ToSearchForKeys.Add();
					NewRow.Ref = ListItem.Value;
				EndIf;
			EndIf;
		EndDo;
	ElsIf ValueIsFilled(FilterValues) Then
		If TypeOf(FilterValues) = Type("CatalogRef.DocumentRegistryKeys") Then
			SelectionValuesForInstallation.Add(FilterValues);
		Else
			NewRow = ToSearchForKeys.Add();
			NewRow.Ref = FilterValues;
		EndIf;
	EndIf;
	
	If ToSearchForKeys.Count() > 0  Then
		Query = New Query;
		Query.Text =
		"SELECT
		|	Keys.Ref AS Ref
		|INTO TTKeys
		|FROM
		|	&Keys AS Keys
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TTKeys.Ref AS LinkValue,
		|	DocumentRegistryKeys.Ref AS KeyRef
		|FROM
		|	TTKeys AS TTKeys
		|		LEFT JOIN Catalog.DocumentRegistryKeys AS DocumentRegistryKeys
		|		ON TTKeys.Ref = DocumentRegistryKeys.Key";
				
		Query.SetParameter("Keys", ToSearchForKeys);
		
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do
			
			If ValueIsFilled(Selection.KeyRef) Then
				SelectionValuesForInstallation.Add(Selection.KeyRef);
			ElsIf Common.IsSubordinateDIBNode() Then
				
				MessageText = NStr("vi = 'Đối với giá trị ""%Value%"" không tìm thấy khóa. Liên hệ với quản trị.';
									|ru = 'Для значения ""%Value%"" не найден ключ реестра документов. Обратитесь к администратору.';
									|en = 'For the value ""%Value%"" the document registry key was not found. Please contact the administrator.'; fa = 'For the value ""%Value%"" the document registry key was not found. Please contact the administrator.';
									|it = 'Per il valore""%Value%"" non è trovata la chiave del registro dei documenti.Rivolgetevi all''amministratore.';
									|pl = 'Dla wartości ""%Value%"" nie znaleziono kluczu rejestru dokumentów. Zwróć się do administratora.';
									|tr = '""%Value%"" değeri için belge kayıt defteri anahtarı bulunamadı. Yöneticiyle iletişime geç.'");
				MessageText = StrReplace(MessageText, "%Value%", Selection.LinkValue);
				
				Raise MessageText;
			Else
				
				Catalogs.DocumentRegistryKeys.CreateUpdateRegistryKeys(,Selection.LinkValue);
				
				Query = New Query;
				Query.Text =
				"SELECT
				|	DocumentRegistryKeys.Ref AS KeyRef
				|FROM
				|	Catalog.DocumentRegistryKeys AS DocumentRegistryKeys
				|WHERE
				|	DocumentRegistryKeys.Key = &Key";
				Query.SetParameter("Key", Selection.LinkValue); 
				
				SingleKeySelection = Query.Execute().Select();
				SingleKeySelection.Next();
				
				SelectionValuesForInstallation.Add(SingleKeySelection.KeyRef);
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		FilterName,
		SelectionValuesForInstallation,
		DataCompositionComparisonType.InList,
		,
		SelectionValuesForInstallation.Count() > 0);
	
EndProcedure

// Table template for describing documents created from workspaces
// 
// Returns:
// 	ValueTable - LongDesc:
// * BusinessOperation - EnumRef.BusinessTransactions -
// * MetadataObjectID - CatalogRef.MetadataObjectIDs -
// * Filter - Boolean -
// * DocumentPresentation - String -
// * FullDocumentName - String -
// * StatusesAreUsed - Boolean -
// * PurposeUseKey - String -
// * AccessRightInsert - Boolean -
// * AccessRightUpdate - Boolean -
// * WorkplaceTitle - String -
// * WorkplaceItemNames - String -
// * HyperlinkCalculationManagerForRegistration - String -
// * AddButtonCreate - Boolean -
// * DocumentType - Type -
Function NewTableBusinessOperationsAndDocuments() Export

	Result = New ValueTable;
	Result.Columns.Add("BusinessOperation", New TypeDescription("EnumRef.BusinessTransactions"));
	Result.Columns.Add("MetadataObjectID", New TypeDescription("CatalogRef.MetadataObjectIDs"));
	Result.Columns.Add("Filter", New TypeDescription("Boolean"));
	Result.Columns.Add("DocumentPresentation", New TypeDescription("String",,,,New StringQualifiers(0)));
	Result.Columns.Add("FullDocumentName", New TypeDescription("String",,,,New StringQualifiers(0)));
	Result.Columns.Add("StatusesAreUsed", New TypeDescription("Boolean"));
	Result.Columns.Add("PurposeUseKey", New TypeDescription("String",,,,New StringQualifiers(0)));
	Result.Columns.Add("AccessRightInsert", New TypeDescription("Boolean"));
	Result.Columns.Add("AccessRightUpdate", New TypeDescription("Boolean"));
	Result.Columns.Add("WorkplaceTitle", New TypeDescription("String",,,,New StringQualifiers(0)));
	Result.Columns.Add("WorkplaceItemNames", New TypeDescription("String",,,,New StringQualifiers(0)));
	Result.Columns.Add("HyperlinkCalculationManagerForRegistration", New TypeDescription("String",,,,New StringQualifiers(0)));
	Result.Columns.Add("AddButtonCreate", New TypeDescription("Boolean"));
	Result.Columns.Add("DocumentType", New TypeDescription("Type"));
	
	Return Result;
	
EndFunction

// Subscription handler prepare data for syncing the key before Recording
//
// Parameters:
// 	Object - CatalogObject - 
//  Cancel - Boolean - 
//	
Procedure PrepareDataForKeySynchronizationBeforeWrite(Object, Cancel) Export
	
	If Object.DataExchange.Load Then
		Return;
	EndIf;
	
	Parameters = New Map;
	
	If TypeOf(Object) = Type("CatalogObject.Persons") Then
		Parameters.Insert("Catalog.DocumentRegistryKeys", "DeletionMark,Description,TIN");
	Else
		ExceptionText = NStr("vi = 'Đối với đối tượng %ObjectType%, các tham số đồng bộ hóa với các khóa không được mô tả.';
							|ru = 'Для объекта %ObjectType% не описаны параметры синхронизации с ключами.';
							|en = 'Parameters of synchronization with keys are not described for the %ObjectType% object.'; fa = 'Parameters of synchronization with keys are not described for the %ObjectType% object.';
							|it = 'Per l''oggetto %ObjectType% non sono descritti i parametri di sincronizzazione con le chiavi.';
							|pl = 'Dla obiektu %ObjectType% parametry synchronizacji z kluczami nie są opisane.';
							|tr = '%ObjectType% nesnesi için, anahtarlarla senkronizasyon parametreleri açıklanmadı.'");
		ExceptionText = StrReplace(ExceptionText, "%ObjectType%", Metadata.FindByType(Object).FullName());
		Raise ExceptionText;
	EndIf;
	
	PrepareDataForKeySynchronization(Object, Parameters);
	
EndProcedure

// The subscription handler synchronizes the Addressee recordingkey
// 
// Parameters:
// 	Object - CatalogObject - 
//  Cancel - Boolean - 
//	
Procedure ToSynchronizeKeysWithDirectoryEntry(Object, Cancel) Export
	
	If Object.DataExchange.Load Then
		Return;
	EndIf;
	
	SyncKeys(Object);
	
EndProcedure

// Returns the values of the business operations available to the user by the access group for the information database object.
//
// Parameters:
//	TableName - String - full name of the database object, for example, " data Register.Registry of documents".
//
// Returns:
//	Array of EnumRef.BusinessTransactions - 
//
Function AvailableBusinessTransactions(TableName) Export
	
	Return TMCommonUseCached.AvailableBusinessTransactions(TableName);
	
EndFunction

// Returns the values of business operations that are not available to the user by access group for the information database object.
//
// Parameters:
//	TableName - String - full name of the database object, for example, " data Register.Registry of documents".
//
// Returns:
//	Array of EnumRef.BusinessTransactions - 
//
Function NotAvailableBusinessTransactions(TableName)
	
	NotAvailableBusinessTransactions = New Array;
	AvailableBusinessTransactions   = AvailableBusinessTransactions(TableName);
	
	If AvailableBusinessTransactions <> Undefined Then
		Query = New Query;
		Query.Text = 
		"SELECT
		|	BusinessTransactionsSettings.BusinessOperation AS BusinessOperation
		|FROM
		|	Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
		|WHERE
		|	NOT BusinessTransactionsSettings.IsFolder
		|	AND NOT BusinessTransactionsSettings.DeletionMark
		|	AND BusinessTransactionsSettings.UseForAccessRestrictions
		|	AND NOT BusinessTransactionsSettings.BusinessOperation IN(&PermittedBusinessOperations)";
		
		Query.SetParameter("PermittedBusinessOperations", AvailableBusinessTransactions);
		
		QueryResult = Query.Execute();
		NotAvailableBusinessTransactions = QueryResult.Unload().UnloadColumn("BusinessOperation");
	EndIf;
	
	Return NotAvailableBusinessTransactions;
	
EndFunction

// Replaces the source of the Link field and the fields being reversed by the document in the text of the request for a dynamic list based on the information register. The document
// Register substitutes an EXPRESSION construct that specifies the document types passed to the Document type parameter.
// 
// Parameters:
//  ListFormElement - FormDataCollection - A form element associated with a dynamic list.
//  DocumentTypes - FormDataCollection, Array of String, String - types of documents
//  AliasOfDocumentRegistry - String - Alias of the Information register table of the Document register in the dynamic list request  
Procedure ReplaceLinkFieldWithExpressByDocumentTypeConstruct(ListFormElement, DocumentTypes = Undefined, AliasOfDocumentRegistry = Undefined) Export
	
	Form 							= ListFormElement.Parent;
	TypeClientApplicationForm	= Type("ClientApplicationForm");
	
	While TypeOf(Form) <> TypeClientApplicationForm Do
		Form = Form.Parent;
	EndDo;
	DynamicList 				= Form[ListFormElement.DataPath];
	
	ListProperties 					= Common.DynamicListPropertiesStructure();
	SelectedDocumentTypes = New Array;
	If DocumentTypes = Undefined Then
		FullNamesOfDocuments = New Array;
		ListFilter = DynamicList.Filter;// DataCompositionFilter 
		For Each FilterElement In ListFilter.Items Do
			If TypeOf(FilterElement) = Type("DataCompositionFilterItem") And FilterElement.Use Then
				If FilterElement.LeftValue = New DataCompositionField("RefType") Then
					For Each Item In FilterElement.RightValue Do
						SelectedDocumentTypes.Add(New Structure("DocumentType, FullDocumentName", TypeOf(Item.Value.EmptyRefValue), Item.Value.FullName));
						FullNamesOfDocuments.Add(Item.Value.FullName);
					EndDo;
					Break;
				EndIf;
			EndIf;
		EndDo;
	Else
		If TypeOf(DocumentTypes) = Type("FormDataCollection") Then
			FullNamesOfDocuments 		= FullDocumentNamesUsed(DocumentTypes.Unload());
		ElsIf TypeOf(DocumentTypes) = Type("String") Then
			FullNamesOfDocuments		= CommonClientServer.ValueInArray(DocumentTypes);
		Else
			FullNamesOfDocuments 		= DocumentTypes;
		EndIf;
		FullNamesOfDocuments.Add("Document.ReversingEntry");
	EndIf;

	FillPropertyValues(ListProperties, DynamicList);
	
	If Not ValueIsFilled(AliasOfDocumentRegistry) Then
		AliasOfDocumentRegistry 		= ?(StrFind(ListProperties.QueryText, "AS DocumentsRegistryOverridable"),
											"DocumentsRegistryOverridable", "DocumentsRegistry");
	EndIf;
	AdditionalProperties 			= DynamicList.SettingsComposer.Settings.AdditionalProperties;
	DereferenceAdded 		= AdditionalProperties.Property("DereferencingLink")
										And Not StrFind(DynamicList.QueryText, AliasOfDocumentRegistry + ".Ref AS Ref,");
										
	ReplacementUnit 						= ?(DereferenceAdded, 
										AdditionalProperties.DereferencingLink, AliasOfDocumentRegistry + ".Ref");
	DesignTemplate 				= "SELECT CASE WHEN &LinkField REFS DocumentRef.SalesOrder"; // @query-part-1
	DesignTemplate 				= StrReplace(DesignTemplate, "SELECT CASE ", ""); // @Query-part-1
	DereferenceToExpress 		= New Array();
	
	For Each DocumentType_1 In FullNamesOfDocuments Do
		DereferenceToExpress.Add(StrReplace(DesignTemplate, "DocumentRef.SalesOrder", DocumentType_1) + Chars.LF
			+ " THEN CAST(&LinkField AS " + DocumentType_1 + ") "); // @query-part-1
	EndDo;
	
	If FullNamesOfDocuments.Count() Then
		TypesOfDocumentsDereference 	= StrConcat(DereferenceToExpress, Chars.LF);
		Dereference 				= "(CASE " + TypesOfDocumentsDereference + " END)"; 
		Dereference 				= StrReplace(Dereference,
											"&LinkField", 
											AliasOfDocumentRegistry + ".Ref");
		
		ListProperties.QueryText 	= StrReplace(ListProperties.QueryText, 
											ReplacementUnit + " AS Ref,", 
											Dereference + " AS Ref,");
			
		ListProperties.QueryText 	= StrReplace(ListProperties.QueryText, 
											ReplacementUnit + ".* AS Ref,", 
											Dereference + ".* AS Ref,");
		AdditionalProperties.Insert("DereferencingLink", 
			StringFunctionsClientServer.SubstituteParametersToString(Dereference, AliasOfDocumentRegistry));
	EndIf;
	
	// Dereference of the field being reversed Document       
	TypesOfCorrectionDocuments = Metadata.DefinedTypes.CorrectedDocuments.Type.Types();  
	If Not SelectedDocumentTypes.Count() Then
		If TypeOf(DocumentTypes) = Type("FormDataCollection") Then
			SelectedDocumentTypes = SelectedBusinessOperationsAndDocuments(DocumentTypes.Unload());
			If SelectedDocumentTypes.Columns.Find("DocumentType") = Undefined Then
				SelectedDocumentTypes.Columns.Add("DocumentType");
				For Each String In SelectedDocumentTypes Do
					DocumentType = Type(StrReplace(String.FullDocumentName,"Document","DocumentRef"));
					String.DocumentType = DocumentType;
				EndDo;
			EndIf;
			SelectedDocumentTypes.GroupBy("DocumentType, FullDocumentName");
		ElsIf TypeOf(DocumentTypes) = Type("String")  Then
			SelectedDocumentTypes = New Array;      
			DocumentType = Type(StrReplace(DocumentTypes,"Document.","DocumentRef."));
			SelectedDocumentTypes.Add(New Structure("DocumentType, FullDocumentName", DocumentType, DocumentTypes))
		Else
			SelectedDocumentTypes = New Array;
			If Not DocumentTypes = Undefined Then
				For Each Item In DocumentTypes Do
					DocumentType = Type(StrReplace(Item,"Document.","DocumentRef."));
					SelectedDocumentTypes.Add(New Structure("DocumentType, FullDocumentName", DocumentType, Item))
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	FullNamesOfCorrectionDocuments = New Array;
	For Each String In SelectedDocumentTypes Do
		If TypesOfCorrectionDocuments.Find(String.DocumentType) <> Undefined Then 
			FullNamesOfCorrectionDocuments.Add(String.FullDocumentName);
		EndIf;
	EndDo;
	
	If Not FullNamesOfCorrectionDocuments.Count() Then    
		FullDocumentName = Metadata.FindByType(TypesOfCorrectionDocuments[0]).FullName();
		FullNamesOfCorrectionDocuments.Add(FullDocumentName);
	EndIf;        
	
	DereferenceAdded 		= AdditionalProperties.Property("DereferenceOfCorrectedDocuments")
										And Not StrFind(DynamicList.QueryText, "ELSE " + AliasOfDocumentRegistry + ".ReversedDocument");
	ReplacementUnit 						= ?(DereferenceAdded, 
										AdditionalProperties.DereferenceOfCorrectedDocuments, AliasOfDocumentRegistry + ".ReversedDocument");

	DereferenceToExpress 		= New Array();
	
	For Each DocumentType_1 In FullNamesOfCorrectionDocuments Do
		DereferenceToExpress.Add(StrReplace(DesignTemplate, "DocumentRef.SalesOrder", DocumentType_1) + Chars.LF
			+ " THEN CAST(&LinkField AS " + DocumentType_1 + ") "); // @query-part-1
	EndDo;
	
	TypesOfDocumentsAreDereferenceden 	= StrConcat(DereferenceToExpress, Chars.LF);
	Dereference 				= "(CASE " + TypesOfDocumentsAreDereferenceden + " END)"; 
	Dereference					 = StrReplace(Dereference,
										"&LinkField", 
										AliasOfDocumentRegistry + ".ReversedDocument");

    ListProperties.QueryText		= StrReplace(ListProperties.QueryText,
										"ELSE " + ReplacementUnit,
										"ELSE " + Dereference);
	
	ListProperties.QueryText 	= StrReplace(ListProperties.QueryText,
										"&LinkField", 
										AliasOfDocumentRegistry + ".ReversedDocument");
	
	Common.SetDynamicListProperties(ListFormElement, ListProperties);
	
	AdditionalProperties.Insert("DereferenceOfCorrectedDocuments", 
		StringFunctionsClientServer.SubstituteParametersToString(Dereference, AliasOfDocumentRegistry));
EndProcedure

// Checks the availability of the referenced data object by the set values of the functional options.
// 
// Parameters:
//  MetadataObject - MetadataObject - a reference metadata object, such as Metadata.Catalogs.Currencies
// 
// Returns:
//  Boolean - Indicates whether the item is available.
Function MetadataObjectAvailableByFunctionalOptions(MetadataObject)
	
	FullName = MetadataObject.FullName();
	EmptyObjectRef = Common.ObjectManagerByFullName(FullName).EmptyRef();
	
	DataCompositionSchema = New DataCompositionSchema;

	DataSource = DataCompositionSchema.DataSources.Add();
	DataSource.Name = "TestRequest";
	DataSource.DataSourceType = "Local";
	
	DataCompositionSchemaDataSetObject = DataCompositionSchema.DataSets.Add(
		Type("DataCompositionSchemaDataSetQuery"));
	DataCompositionSchemaDataSetObject.Name = "DataSet";
	DataCompositionSchemaDataSetObject.DataSource = "TestRequest";
	
	DataCompositionSchemaDataSetObject.Query = "SELECT TRUE AS Field";
	
	Field = DataCompositionSchemaDataSetObject.Fields.Add(Type("DataCompositionSchemaDataSetField"));
	Field.DataPath = "Field";
	
	Parameter = DataCompositionSchema.Parameters.Add();
	Parameter.Name = FullName;
	Parameter.ValueType = New TypeDescription(
		CommonClientServer.ValueInArray(TypeOf(EmptyObjectRef)));
	
	MainOption = DataCompositionSchema.SettingVariants[0].Settings; // DataCompositionSettings

	CustomSetting = MainOption.DataParameters.Items.Add();
	CustomSetting.UserSettingID = New UUID();
	CustomSetting.Parameter = New DataCompositionParameter(FullName);
	
	SettingsComposer = New DataCompositionSettingsComposer;
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(DataCompositionSchema));
	SettingsComposer.LoadSettings(MainOption);
	
	Return SettingsComposer.UserSettings.Items.Count() <> 0;
	
EndFunction

#EndRegion

#Region AddRemoveCreateButtonsInDocumentLogs

Procedure GenerateCreationCommands_(ParametersStructure) 
	
	Form = ParametersStructure.Form;
	
	GroupNameStructure = New Structure;
	GroupNameStructure.Insert(ParametersStructure.NameOfCreateGroup, False); // False, because the group is not contextual
	If ValueIsFilled(ParametersStructure.GroupNameCreateContext) Then
		GroupNameStructure.Insert(ParametersStructure.GroupNameCreateContext, True); // True, because the context group
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	CAST(Table.Order AS NUMBER(10, 0)) AS Order,
	|	CAST(Table.MetadataObjectID AS Catalog.MetadataObjectIDs) AS MetadataObjectID,
	|	CAST(Table.BusinessOperation AS Enum.BusinessTransactions) AS BusinessOperation,
	|	CAST(Table.DocumentPresentation AS STRING(250)) AS DocumentPresentation,
	|	CAST(Table.ButtonGroup AS STRING(100)) AS ButtonGroup,
	|	CAST(Table.PlaceInSubmenu AS BOOLEAN) AS PlaceInSubmenu
	|INTO Table
	|FROM
	|	&Table AS Table
	|WHERE
	|	Table.Filter
	|	AND Table.AddButtonCreate
	|	AND Table.AccessRightInsert
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Order 								AS Order,
	|	Table.MetadataObjectID 			AS MetadataObjectID,
	|	Table.BusinessOperation 					AS BusinessOperation,
	|	PRESENTATION(Table.BusinessOperation) 	AS BusinessTransactionSynonym,
	|	Table.DocumentPresentation 					AS DocumentPresentation,
	|	Table.ButtonGroup 							AS ButtonGroup,
	|	Table.PlaceInSubmenu 						AS PlaceInSubmenu
	|FROM
	|	Table AS Table";
	
	TableOfBusinessTransactionsAndDocuments = Form[ParametersStructure.NameOfTableOfBusinessOperationsAndDocuments].Unload(); // ValueTable - 
	
	If TableOfBusinessTransactionsAndDocuments.Columns.Find("Order") = Undefined Then
		TableOfBusinessTransactionsAndDocuments.Columns.Add("Order",
			New TypeDescription("Number", New NumberQualifiers(10, 0)));
	EndIf;
	If TableOfBusinessTransactionsAndDocuments.Columns.Find("ButtonGroup") = Undefined Then
		TableOfBusinessTransactionsAndDocuments.Columns.Add("ButtonGroup",
			New TypeDescription("String", , New StringQualifiers(100)));
	EndIf;
	If TableOfBusinessTransactionsAndDocuments.Columns.Find("PlaceInSubmenu") = Undefined Then
		TableOfBusinessTransactionsAndDocuments.Columns.Add("PlaceInSubmenu",
			New TypeDescription("Boolean"));
		TableOfBusinessTransactionsAndDocuments.FillValues(True, "PlaceInSubmenu");
	EndIf;
	
	Query.SetParameter("Table", TableOfBusinessTransactionsAndDocuments);
	
	DocumentsTable = Query.Execute().Unload();
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	CAST(Table.MetadataObjectID AS Catalog.MetadataObjectIDs) AS MetadataObjectID,
	|	CAST(Table.BusinessOperation AS Enum.BusinessTransactions) AS BusinessOperation,
	|	CAST(Table.DocumentPresentation AS STRING(250)) AS DocumentPresentation,
	|	CAST(Table.BusinessTransactionSynonym AS STRING(500)) AS BusinessTransactionSynonym,
	|	CAST(Table.ButtonGroup AS STRING(100)) AS ButtonGroup,
	|	CAST(Table.PlaceInSubmenu AS BOOLEAN) AS PlaceInSubmenu,
	|	CAST(Table.Order AS NUMBER(10, 0)) AS Order
	|INTO Table
	|FROM
	|	&Table AS Table
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	COUNT(DocumentsCount.MetadataObjectID) AS Count
	|FROM
	|	(SELECT DISTINCT
	|		Table.MetadataObjectID AS MetadataObjectID
	|	FROM
	|		Table AS Table) AS DocumentsCount
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	COUNT(NumberOfBusinessOperations.BusinessOperation) AS Count
	|FROM
	|	(SELECT DISTINCT
	|		Table.BusinessOperation AS BusinessOperation
	|	FROM
	|		Table AS Table) AS NumberOfBusinessOperations
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.MetadataObjectID AS MetadataObjectID,
	|	Table.BusinessOperation AS BusinessOperation,
	|	Table.MetadataObjectID.Synonym AS Synonym,
	|	CASE 
	|		WHEN Table.DocumentPresentation <> """"
	|			THEN Table.DocumentPresentation
	|		ELSE Table.MetadataObjectID.Synonym
	|	END AS DocumentPresentation,
	|	Table.MetadataObjectID.Name AS Name,
	|	Table.MetadataObjectID.FullName AS FullDocumentName,
	|	Table.ButtonGroup AS ButtonGroup,
	|	Table.PlaceInSubmenu AS PlaceInSubmenu
	|FROM
	|	Table AS Table
	|
	|ORDER BY
	|	Order,
	|	Synonym,
	|	BusinessTransactionSynonym
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.MetadataObjectID AS MetadataObjectID,
	|	Table.BusinessOperation AS BusinessOperation,
	|	Table.Order AS Order,
	|	Table.MetadataObjectID.Synonym AS Synonym,
	|	CASE 
	|		WHEN Table.DocumentPresentation <> """"
	|			THEN Table.DocumentPresentation
	|		ELSE Table.MetadataObjectID.Synonym
	|	END AS DocumentPresentation,
	|	Table.MetadataObjectID.Name AS DocumentName,
	|	Table.MetadataObjectID.FullName AS FullDocumentName,
	|	Table.ButtonGroup AS ButtonGroup,
	|	Table.PlaceInSubmenu AS PlaceInSubmenu
	|FROM
	|	Table AS Table
	|
	|ORDER BY
	|	Order,
	|	Synonym,
	|	BusinessTransactionSynonym
	|
	|TOTALS 
	|	MAX(Synonym),
	|	MAX(DocumentPresentation),
	|	MAX(ButtonGroup),
	|	MAX(Order),
	|	MAX(PlaceInSubmenu)
	|BY
	|	MetadataObjectID";
	
	Query.SetParameter("Table", DocumentsTable);
	ResultsArray = Query.ExecuteBatch();
	
	DocumentsCount = 0;
	SampleNumberOfDocuments = ResultsArray[1].Select();
	If SampleNumberOfDocuments.Next() Then 
		DocumentsCount = SampleNumberOfDocuments.Count;
	EndIf;
	
	NumberOfBusinessTransactions = 0;
	SampleNumberOfBusinessTransactions = ResultsArray[2].Select();
	If SampleNumberOfBusinessTransactions.Next() Then 
		NumberOfBusinessTransactions = SampleNumberOfBusinessTransactions.Count;
	EndIf;
	
	For Each GroupContextName In GroupNameStructure Do
		
		NameOfCreateGroup 			= GroupContextName.Key;
		AddingToContextMenu 	= GroupContextName.Value;
		
		Prefix = ParametersStructure.ElementPrefix + ?(AddingToContextMenu, "Context", "");
		
		GroupCreate = Form.Items[NameOfCreateGroup];
	
		DeleteCreationCommands(Form, GroupCreate, NameOfCreateGroup);
		
		MatchingTeamGroups = New Map;
		MatchingTeamGroups.Insert("", GroupCreate);
		
		If DocumentsCount = 1 And NumberOfBusinessTransactions = 1 Then
			
			Selection = ResultsArray[3].Select();
			If Selection.Next() Then   
				ButtonPlacement = ButtonPlacement("", Form, NameOfCreateGroup, Prefix, MatchingTeamGroups);
				AddCommandWithButton(Form, NameOfCreateGroup, ButtonPlacement, NStr("vi = 'Tạo mới';
																					|ru = 'Создать';
																					|en = 'Create'; fa = 'ایجاد';
																					|it = 'Creare';
																					|pl = 'Create';
																					|tr = 'Oluştur'"), Selection, Prefix, GroupCreate.ChildItems.Count() = 0);
			EndIf;
					
		ElsIf DocumentsCount = 1 And NumberOfBusinessTransactions > 1 Then
			
			Selection = ResultsArray[3].Select();
			While Selection.Next() Do
				ButtonPlacement = ButtonPlacement(Selection.ButtonGroup, Form, NameOfCreateGroup, Prefix, MatchingTeamGroups);
				AddCommandWithButton(Form, NameOfCreateGroup, ButtonPlacement, Selection.BusinessOperation, Selection, Prefix);			
			EndDo;
			
		ElsIf DocumentsCount <= ParametersStructure.MaximumNumberOfCommandsPerSubmenu
		 	And NumberOfBusinessTransactions = 1 Then
			
			Selection = ResultsArray[3].Select();
			While Selection.Next() Do
				ButtonPlacement = ButtonPlacement(Selection.ButtonGroup, Form, NameOfCreateGroup, Prefix, MatchingTeamGroups);
				AddCommandWithButton(Form, NameOfCreateGroup, ButtonPlacement, Selection.DocumentPresentation, Selection, Prefix);
			EndDo;
			
		ElsIf DocumentsCount <= ParametersStructure.MaximumNumberOfCommandsPerSubmenu
		 	And NumberOfBusinessTransactions > 1 Then
			
			Tree = ResultsArray[4].Unload(QueryResultIteration.ByGroupsWithHierarchy);
			
			For Each LineDocument In Tree.Rows Do
				
				If LineDocument.Rows.Count() = 1 Then
					
					ButtonPlacement = ButtonPlacement(
						LineDocument.ButtonGroup, 
						Form, 
						NameOfCreateGroup, 
						Prefix, 
						MatchingTeamGroups);
					
					AddCommandWithButton(
						Form, 
						NameOfCreateGroup, 
						ButtonPlacement, 
						LineDocument.DocumentPresentation, 
						LineDocument.Rows[0], 
						Prefix);
					
				Else
					
					If LineDocument.PlaceInSubmenu Then
						
						ButtonPlacement = AddGroupOfButtons(
							Form, 
							NameOfCreateGroup, 
							LineDocument.DocumentName, 
							LineDocument.DocumentPresentation, 
							Prefix);
					Else
						
						ButtonPlacement = ButtonPlacement(
							LineDocument.ButtonGroup, 
							Form, 
							NameOfCreateGroup, 
							Prefix, 
							MatchingTeamGroups);
							
					EndIf;
					
					For Each String In LineDocument.Rows Do
						
						AddCommandWithButton(
							Form, 
							NameOfCreateGroup, 
							ButtonPlacement, 
							String.BusinessOperation, 
							String, 
							Prefix);
							
					EndDo;
					
				EndIf;
				
			EndDo;
			
		ElsIf Form.FilterDocumentTypes.Count() > ParametersStructure.MaximumNumberOfCommandsPerSubmenu Then
			
			AddCommandWithButtonToOpenSelectionForm(Form, NameOfCreateGroup, Prefix);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function AddGroupOfButtons(Form, NameOfCreateGroup, NameOfNewGroup, NewGroupHeader, Prefix)
	
	Item = Form.Items.Add(Prefix + "Group" + "Create_" + TrimAll(NameOfNewGroup), Type("FormGroup"), Form.Items[NameOfCreateGroup]);
	Item.Title = TrimAll(NewGroupHeader);
	Return Item;
	
EndFunction

Function AddCommandWithButton(Form, NameOfCreateGroup, Parent, ButtonTitle, CurrentTableRow, Prefix, OnePin = False)
	
	MetadataOfDocument = Metadata.FindByFullName(CurrentTableRow.FullDocumentName);
	
	EnumerationValueName = XMLString(CurrentTableRow.BusinessOperation);
	DocumentMetadataName = MetadataOfDocument.Name;
	
	If OnePin Then
		Form.Items[NameOfCreateGroup].Type = FormGroupType.ButtonGroup;
	Else
		Form.Items[NameOfCreateGroup].Type = FormGroupType.Popup;
		Form.Items[NameOfCreateGroup].Picture = PictureLib.CreateListItem;
	EndIf;
	
	CommandName = Prefix + "Create___" + EnumerationValueName + "___" + DocumentMetadataName;
	Command = Form.Commands.Add(CommandName);
	Command.Action = "Attachable_CreateDocument";
	Command.Title = TrimAll(ButtonTitle);
	If OnePin Then 
		Command.Representation = ButtonRepresentation.PictureAndText;
		Command.Picture = PictureLib.CreateListItem;
	EndIf;
	
	Item = Form.Items.Add(CommandName, Type("FormButton"), Parent);
	Item.CommandName = CommandName;
	Return Item;
	
EndFunction

Function AddCommandWithButtonToOpenSelectionForm(Form, NameOfCreateGroup, Prefix)
	
	Form.Items[NameOfCreateGroup].Type = FormGroupType.ButtonGroup;
	
	CommandName = Prefix + "Create_" + "DocumentViaSelectionForm";
	Command = Form.Commands.Add(CommandName);
	Command.Action = "Attachable_CreateDocumentViaSelectionForm";
	Command.Title = NStr("vi = 'Tạo...';
						|ru = 'Создать...';
						|en = 'Create...'; fa = 'Create...';
						|it = 'Creare...';
						|pl = 'Create...';
						|tr = 'Oluştur...'");
	Command.Representation = ButtonRepresentation.PictureAndText;
	Command.Picture = PictureLib.CreateListItem;
	
	Item = Form.Items.Add(CommandName, Type("FormButton"), Form.Items[NameOfCreateGroup]);
	Item.CommandName = CommandName;
	Return Item;
	
EndFunction

Procedure DeleteCreationCommands(Form, Parent, NameOfCreateGroup)
	
	// If the parent is not the root group and it is not created programmatically, then you do not need to delete anything.
	If Parent <> Form.Items[NameOfCreateGroup] 
		And StrFind(Parent.Name, "Create_") = 0 Then
		Return;
	EndIf;
	
	If TypeOf(Parent) = Type("FormGroup") Then 
		
		Count = Parent.ChildItems.Count();
		
		For IndexOf = 1 To Count Do
			DeleteCreationCommands(Form, Parent.ChildItems.Get(0), NameOfCreateGroup);
		EndDo;
		
	ElsIf TypeOf(Parent) = Type("FormButton") Then 
		Form.Commands.Delete(Form.Commands.Find(Parent.Name));
	EndIf;
	
	If StrFind(Parent.Name, "Create_") <> 0 Then 
		Form.Items.Delete(Parent);
	EndIf;
	
EndProcedure

Function ButtonPlacement(ButtonGroupName, Form, NameOfCreateGroup, Prefix, MatchingTeamGroups)
	
	ButtonGroup = MatchingTeamGroups.Get(TrimAll(ButtonGroupName));
	If ButtonGroup = Undefined Then
		ButtonGroup = AddGroupOfButtons(Form, NameOfCreateGroup, ButtonGroupName, NameOfCreateGroup, Prefix);	
		ButtonGroup.Type = FormGroupType.ButtonGroup;
		MatchingTeamGroups.Insert(TrimAll(ButtonGroupName), ButtonGroup);
	EndIf;
	
	Return ButtonGroup;
	
EndFunction

#EndRegion

#Region TableSearch

Function ArrangeNumberedRows(Table, RowsArray)
	
	RowsAreOrdered = ArrayOfNumberedRowsIsOrdered(RowsArray);
	
	If RowsAreOrdered Then
		
		Result = RowsArray;
		
	Else
		
		SortTable = New ValueTable;
		SortTable.Columns.Add("String", New TypeDescription("ValueTableRow"));
		SortTable.Columns.Add("SequenceNumber", New TypeDescription("Number", New NumberQualifiers));
		
		For IndexOf = 0 To RowsArray.UBound() Do
			
			String = RowsArray[IndexOf];
			
			NewRow = SortTable.Add();
			NewRow.String = String;
			NewRow.SequenceNumber = String.SequenceNumber;
			
		EndDo;
		
		SortTable.Sort("SequenceNumber ASC");
		
		Result = New Array;
		For IndexOf = 0 To SortTable.Count()-1 Do
			
			Result.Add(SortTable[IndexOf].String);
			
		EndDo;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function ArrayOfNumberedRowsIsOrdered(RowsArray)
	
	Result = True;
	
	MaxIndex_ = RowsArray.UBound();
	
	PreviousString = RowsArray[MaxIndex_];
	For Cnt = 1 To MaxIndex_ Do
		
		CurrentRow = RowsArray[MaxIndex_-Cnt];
		If CurrentRow.SequenceNumber > PreviousString.SequenceNumber Then
			Result = False;
			Break;
		EndIf;
		
		PreviousString = CurrentRow;
		
	EndDo;
	
	Return Result;
	
EndFunction

Function ArrangeNonNumberedRows(Table, RowsArray)
	
	IndexTable = IndexesOfNonNumberedRows(Table, RowsArray);
	RowsAreOrdered = IndexTableIsOrdered(IndexTable);
	
	If RowsAreOrdered Then
		
		Result = RowsArray;
		
	Else
		
		IndexTable.Sort("TableIndex ASC");
		
		Result = New Array;
		For IndexOf = 0 To IndexTable.Count()-1 Do
			
			Result.Add(IndexTable[IndexOf].String);
			
		EndDo;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function IndexesOfNonNumberedRows(Table, RowsArray)
	
	Result = New ValueTable;
	Result.Columns.Add("String", New TypeDescription("ValueTableRow"));
	Result.Columns.Add("TableIndex", New TypeDescription("Number", New NumberQualifiers));
	
	For IndexOf = 0 To RowsArray.UBound() Do
		
		String = RowsArray[IndexOf];
		
		NewRow = Result.Add();
		NewRow.String = String;
		NewRow.TableIndex = Table.IndexOf(String);
		
	EndDo;
	
	Return Result;
	
EndFunction

Function IndexTableIsOrdered(IndexTable)
	
	Result = True;
	
	PreviousString = IndexTable[0];
	For IndexOf = 1 To IndexTable.Count()-1 Do
		
		CurrentRow = IndexTable[IndexOf];
		If CurrentRow.TableIndex < PreviousString.TableIndex Then
			Result = False;
			Break;
		EndIf;
		
		PreviousString = CurrentRow;
		
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#Region CopyingFormElements

Function CopiedPropertiesOfFormElements()
	
	Result = New Map;
	
	FormFieldProperties = New Array;
	FormFieldProperties.Add("Type");
	FormFieldProperties.Add("CheckBoxType");
	FormFieldProperties.Add("Title");
	FormFieldProperties.Add("TitleLocation");
	FormFieldProperties.Add("AutoMaxHeight");
	FormFieldProperties.Add("AutoMaxWidth");
	FormFieldProperties.Add("AutoMarkIncomplete");
	FormFieldProperties.Add("VerticalAlign");
	FormFieldProperties.Add("VerticalAlignInGroup");
	FormFieldProperties.Add("Visible");
	FormFieldProperties.Add("ChooseType");
	FormFieldProperties.Add("ChoiceFoldersAndItems");
	FormFieldProperties.Add("MarkNegatives");
	FormFieldProperties.Add("Height");
	FormFieldProperties.Add("TitleHeight");
	FormFieldProperties.Add("ChoiceListHeight");
	FormFieldProperties.Add("CellHyperlink");
	FormFieldProperties.Add("HorizontalAlign");
	FormFieldProperties.Add("HorizontalAlignInGroup");
	FormFieldProperties.Add("FooterHorizontalAlign");
	FormFieldProperties.Add("HeaderHorizontalAlign");
	FormFieldProperties.Add("VerticalAlign");
	FormFieldProperties.Add("VerticalAlignInGroup");
	FormFieldProperties.Add("VerticalStretch");
	FormFieldProperties.Add("Enabled");
	FormFieldProperties.Add("MultiLine");
	FormFieldProperties.Add("Wrap");
	FormFieldProperties.Add("ReadOnly");
	FormFieldProperties.Add("Width");
	FormFieldProperties.Add("Font");
	FormFieldProperties.Add("TitleFont");
	FormFieldProperties.Add("FooterFont");
	FormFieldProperties.Add("Width");
	FormFieldProperties.Add("TitleFont");
	FormFieldProperties.Add("FooterFont");
	FormFieldProperties.Add("ShowInFooter");
	FormFieldProperties.Add("ShowInHeader");
	FormFieldProperties.Add("DataPath");
	FormFieldProperties.Add("FooterDataPath");
	FormFieldProperties.Add("ChoiceParameters");
	FormFieldProperties.Add("ChoiceParameterLinks");
	FormFieldProperties.Add("AutoMaxHeight");
	FormFieldProperties.Add("MaxWidth");
	FormFieldProperties.Add("AutoMaxWidth");
	FormFieldProperties.Add("MaxHeight");
	Result.Insert(Type("FormField"), FormFieldProperties);
	
	ShapeGroupProperties = New Array();
	ShapeGroupProperties.Add("Type");
	ShapeGroupProperties.Add("Title");
	ShapeGroupProperties.Add("TitleDataPath");
	ShapeGroupProperties.Add("ShowTitle");
	ShapeGroupProperties.Add("Visible");
	ShapeGroupProperties.Add("Enabled");
	ShapeGroupProperties.Add("ReadOnly");
	ShapeGroupProperties.Add("United");
	ShapeGroupProperties.Add("Behavior");
	ShapeGroupProperties.Add("Representation");
	ShapeGroupProperties.Add("ThroughAlign");
	ShapeGroupProperties.Add("Group");
	ShapeGroupProperties.Add("ShowInHeader");
	ShapeGroupProperties.Add("HorizontalAlignInGroup");
	ShapeGroupProperties.Add("HeaderHorizontalAlign");
	ShapeGroupProperties.Add("Width");
	ShapeGroupProperties.Add("Height");
	ShapeGroupProperties.Add("VerticalStretch");
	ShapeGroupProperties.Add("HorizontalStretch");
	ShapeGroupProperties.Add("ItemsAndTitlesAlign");
	ShapeGroupProperties.Add("Picture");
	ShapeGroupProperties.Add("SourceOfCommands");
	Result.Insert(Type("FormGroup"), ShapeGroupProperties);
	
	PropertiesOfShapeTable = New Array();
	PropertiesOfShapeTable.Add("Title");
	PropertiesOfShapeTable.Add("DataPath");
	PropertiesOfShapeTable.Add("TitleLocation");
	PropertiesOfShapeTable.Add("Visible");
	PropertiesOfShapeTable.Add("Enabled");
	PropertiesOfShapeTable.Add("ReadOnly");
	PropertiesOfShapeTable.Add("DefaultControl");
	PropertiesOfShapeTable.Add("ChoiceMode");
	PropertiesOfShapeTable.Add("MultipleChoice");
	PropertiesOfShapeTable.Add("ChangeRowSet");
	PropertiesOfShapeTable.Add("ChangeRowOrder");
	PropertiesOfShapeTable.Add("Header");
	PropertiesOfShapeTable.Add("Footer");
	PropertiesOfShapeTable.Add("RowPictureDataPath");
	PropertiesOfShapeTable.Add("RowsPicture");
	PropertiesOfShapeTable.Add("Width");
	PropertiesOfShapeTable.Add("Height");
	PropertiesOfShapeTable.Add("AutoMaxHeight");
	PropertiesOfShapeTable.Add("MaxWidth");
	PropertiesOfShapeTable.Add("AutoMaxWidth");
	PropertiesOfShapeTable.Add("MaxHeight");
	PropertiesOfShapeTable.Add("HorizontalStretch");
	PropertiesOfShapeTable.Add("VerticalStretch");
	Result.Insert(Type("FormTable"), PropertiesOfShapeTable);
	
	FormCommandProperties = New Array();
	FormCommandProperties.Add("Type");
	FormCommandProperties.Add("Title");
	FormCommandProperties.Add("Visible");
	FormCommandProperties.Add("Enabled");
	FormCommandProperties.Add("OnlyInAllActions");
	FormCommandProperties.Add("Representation");
	FormCommandProperties.Add("DefaultButton");
	FormCommandProperties.Add("DefaultControl");
	FormCommandProperties.Add("Check");
	FormCommandProperties.Add("Width");
	FormCommandProperties.Add("Height");
	FormCommandProperties.Add("AutoMaxHeight");
	FormCommandProperties.Add("MaxWidth");
	FormCommandProperties.Add("AutoMaxWidth");
	FormCommandProperties.Add("MaxHeight");
	FormCommandProperties.Add("HorizontalAlignInGroup");
	FormCommandProperties.Add("VerticalAlignInGroup");
	FormCommandProperties.Add("HorizontalStretch");
	FormCommandProperties.Add("VerticalStretch");
	FormCommandProperties.Add("CommandName");
	FormCommandProperties.Add("CommandBar");
	Result.Insert(Type("FormButton"), FormCommandProperties);
	
	Return Result;
	
EndFunction

Function CopiedFormElementHandlers()
	
	Result = New Map;
	
	FormFieldProperties = New Array;
	FormFieldProperties.Add("OnChange");
	FormFieldProperties.Add("StartListChoice");
	FormFieldProperties.Add("Clearing");
	FormFieldProperties.Add("Tuning");
	FormFieldProperties.Add("Opening");
	FormFieldProperties.Add("ChoiceProcessing");
	FormFieldProperties.Add("AutoComplete");
	FormFieldProperties.Add("TextEditEnd");
	FormFieldProperties.Add("StartChoice");
	FormFieldProperties.Add("EditTextChange");
	FormFieldProperties.Add("Creating");
	Result.Insert(Type("FormField"), FormFieldProperties);
	
	ShapeGroupProperties = New Array();
	ShapeGroupProperties.Add("OnCurrentPageChange");
	Result.Insert(Type("FormGroup"), ShapeGroupProperties);
	
	PropertiesOfShapeTable = New Array();
	PropertiesOfShapeTable.Add("Selection");
	PropertiesOfShapeTable.Add("ValueChoice");
	PropertiesOfShapeTable.Add("OnActivateRow");
	PropertiesOfShapeTable.Add("OnActivateField");
	PropertiesOfShapeTable.Add("OnActivateCell");
	PropertiesOfShapeTable.Add("BeforeAddRow");
	PropertiesOfShapeTable.Add("BeforeRowChange");
	PropertiesOfShapeTable.Add("BeforeDeleteRow");
	PropertiesOfShapeTable.Add("OnStartEdit");
	PropertiesOfShapeTable.Add("BeforeEditEnd");
	PropertiesOfShapeTable.Add("OnEditEnd");
	PropertiesOfShapeTable.Add("ChoiceProcessing");
	PropertiesOfShapeTable.Add("BeforeExpand");
	PropertiesOfShapeTable.Add("BeforeCollapse");
	PropertiesOfShapeTable.Add("AfterDeleteRow");
	PropertiesOfShapeTable.Add("OnCurrentParentChange");
	PropertiesOfShapeTable.Add("OnChange");
	PropertiesOfShapeTable.Add("NewWriteProcessing");
	PropertiesOfShapeTable.Add("DragStart");
	PropertiesOfShapeTable.Add("DragCheck");
	PropertiesOfShapeTable.Add("DragEnd");
	PropertiesOfShapeTable.Add("Drag");
	Result.Insert(Type("FormTable"), PropertiesOfShapeTable);
	
	FormCommandProperties = New Array();
	Result.Insert(Type("FormButton"), FormCommandProperties);
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion
