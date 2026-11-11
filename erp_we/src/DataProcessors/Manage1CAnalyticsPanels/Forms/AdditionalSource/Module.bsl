#Region Variables

&AtClient
Var ToFormPresentation;

&AtClient
Var NameOfUnsetParameterField;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Property = Undefined;
	Parameters.Property("Id", Property);
	
	If Property <> Undefined Then
		Id = Parameters["Id"];
		ReadObject();
		Parameters.Property("Copy", Property);
		If Property <> Undefined Then
			Id = String(New UUID());
		EndIf;
	Else
		Id = String(New UUID());
		Name = "";
	EndIf;
	
	Property = Undefined;
	Parameters.Property("Name", Property);
	
	If Property <> Undefined Then
		Name = Parameters["Name"];
		Presentation = CreatePresentation(Name);
	EndIf;
	
	If Parameters.Property("ExistingNames") Then
		ExistingNames = Parameters.ExistingNames;
	EndIf;
	
	If Parameters.Property("ServerFormat") Then
		ServerFormat = Parameters.ServerFormat;
	EndIf;
	
EndProcedure 

&AtClient
Procedure OnOpen(Cancel) 
	
	UniqueKey = Id;
	Title = Name;
	ToFormPresentation = (Presentation = CreatePresentation(Name));
	NameOfUnsetParameterField = NStr("vi = 'Chưa xác định';
									|ru = 'Не задано';
									|en = 'Not specified'; fa = 'مشخص نشده';
									|it = 'Non impostato';
									|pl = 'Nie określono';
									|tr = 'Ayarlanmadı'");
	If ServerFormat >= 2 Then
		Try
			FillInVirtualTablesFromQueryOnServer(NameOfUnsetParameterField);
		Except
			CommonClient.MessageToUser(NStr("vi = 'Không thể điền bảng ảo';
											|ru = 'Не удалось заполнить виртуальные таблицы';
											|en = 'Cannot fill virtual tables'; fa = 'Cannot fill virtual tables';
											|it = 'Не удалось заполнить виртуальные таблицы';
											|pl = 'Cannot fill virtual tables';
											|tr = 'Sanal tablolar doldurulamadı'"));
		EndTry;
	EndIf;
	
EndProcedure 

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not Modified Then 
		Return;
	EndIf;
	
	Cancel = True;
	If Not Exit Then
		Notification = New CallbackDescription("AfterConfirmingSave", ThisObject);
		ShowQueryBox(Notification, NStr("vi = 'Dữ liệu nguồn bổ sung đã thay đổi. Lưu các thay đổi?';
										|ru = 'Данные дополнительного источника изменены. Сохранить изменения?';
										|en = 'Additional source data is changed. Do you want to save the changes?'; fa = 'Additional source data is changed. Do you want to save the changes?';
										|it = 'Данные дополнительного источника изменены. Сохранить изменения?';
										|pl = 'Additional source data is changed. Do you want to save the changes?';
										|tr = 'Ek kaynağın verileri değiştirildi. Değişiklikler kaydedilsin mi?'"),
		QuestionDialogMode.YesNoCancel);
	EndIf; 
	
EndProcedure 

&AtClient
Procedure AfterConfirmingSave(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		WriteDownAndCloseForm();
	ElsIf Result = DialogReturnCode.No Then
		Modified = False;
		Close();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers  

&AtClient
Procedure NameOnChange(Item)
	
	If ToFormPresentation Then
		Presentation = CreatePresentation(Name);
	Else
		ToFormPresentation = (Presentation = CreatePresentation(Name));
	EndIf;
	
EndProcedure 

&AtClient
Procedure PresentationOnChange(Item)
	
	ToFormPresentation = (Presentation = CreatePresentation(Name)); 
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersFields

&AtClient
Procedure FieldsWhenLineIsActivated(Item)
	
	If Item.CurrentData = Undefined Then
		Return;
	EndIf;
	If CanBeDimension(Item.CurrentData.Type) Then
		Items.Fields.ChildItems.FieldsRole.ReadOnly = False;
	Else
		Items.Fields.ChildItems.FieldsRole.ReadOnly = True;
	EndIf;
	
EndProcedure

#EndRegion 

#Region FormTableItemsEventHandlersVirtualTables

&AtClient
Procedure VirtualTablesSelection(Item, RowSelected, Field, StandardProcessing)
	
	ParameterFieldSelectionList = ParameterFieldSelectionList(QueryText, NameOfUnsetParameterField);
	OpenOptionFieldSelectionForm(RowSelected, ParameterFieldSelectionList);
	
EndProcedure

#EndRegion 

#Region FormCommandsEventHandlers 

&AtClient
Procedure Write(Command)
	
	If IsBlankString(QueryText) Then
		ShowMessageBox( , NStr("ru = 'Текст запроса отсутствует';
								|vi = 'The request text is missing';
								|en = 'The request text is missing'; fa = 'The request text is missing';
								|it = 'The request text is missing';
								|pl = 'The request text is missing';
								|tr = 'Sorgu metni yoktur'"));
		Return;
	EndIf;
	
	If ServerFormat < 2 And RequestContainsParametersOfVirtualTables(QueryText) Then
		Raise NStr("vi = 'Phiên bản server 1C:Analytics không hỗ trợ làm việc với tham số bảng ảo. Hãy cập nhật phiên bản server 1C:Analytics.';
					|ru = 'Версия сервера 1С:Аналитики не поддерживает работу с параметрами виртуальных таблиц. Обновите версию сервера 1С:Аналитики.';
					|en = 'The 1C:Analytics server version does not support virtual table parameters. Update the 1C:Analytics server.'; fa = 'The 1C:Analytics server version does not support virtual table parameters. Update the 1C:Analytics server.';
					|it = 'Версия сервера 1С:Аналитики не поддерживает работу с параметрами виртуальных таблиц. Обновите версию сервера 1С:Аналитики.';
					|pl = 'The 1C:Analytics server version does not support virtual table parameters. Update the 1C:Analytics server.';
					|tr = '1C:Analytics sunucusu sürümü sanal tablo parametreleriyle çalışmayı desteklemiyor. 1C:Analytics sunucusu sürümünü güncelleyin.'");
	EndIf;
	
	AdditionalParameters = New Structure("Close", False);
	If ServerFormat >= 2 Then
		FillInVirtualTablesFromQueryOnServer(NameOfUnsetParameterField);
		SaveAfterCheckingParameters(AdditionalParameters);
	Else
		If CheckFields() Then
			SaveWithFieldsFilledIn(AdditionalParameters);
		EndIf;
	EndIf; 
	
EndProcedure

&AtClient
Procedure WriteAndClose(Command)
	
	WriteDownAndCloseForm();
	
EndProcedure

&AtClient
Procedure FillInFieldsFromRequest(Command)
	
	FillInQueryTextFields();
	
EndProcedure 

&AtClient
Procedure FillInTablesFromQuery(Command)
	
	If ServerFormat >= 2 Then
		FillInVirtualTablesFromQueryOnServer(NameOfUnsetParameterField)
	Else
		Raise NStr("vi = 'Phiên bản server 1C:Analytics không hỗ trợ làm việc với tham số bảng ảo. Hãy cập nhật phiên bản server 1C:Analytics.';
					|ru = 'Версия сервера 1С:Аналитики не поддерживает работу с параметрами виртуальных таблиц. Обновите версию сервера 1С:Аналитики.';
					|en = 'The 1C:Analytics server version does not support virtual table parameters. Update the 1C:Analytics server.'; fa = 'The 1C:Analytics server version does not support virtual table parameters. Update the 1C:Analytics server.';
					|it = 'Версия сервера 1С:Аналитики не поддерживает работу с параметрами виртуальных таблиц. Обновите версию сервера 1С:Аналитики.';
					|pl = 'The 1C:Analytics server version does not support virtual table parameters. Update the 1C:Analytics server.';
					|tr = '1C:Analytics sunucusu sürümü sanal tablo parametreleriyle çalışmayı desteklemiyor. 1C:Analytics sunucusu sürümünü güncelleyin.'");
	EndIf; 
	
EndProcedure

&AtClient
Procedure OpenQueryBuilder(Command)
	
	#If ThinClient Or ThinClient Or WebClient Then
		
	If IsBlankString(QueryText) Then
		QueryWizard = New QueryWizard();
	Else
		QueryWizard = New QueryWizard(QueryText);
	EndIf;
	CallbackDescription = New CallbackDescription("AfterClosingQueryConstructor", ThisObject);
	QueryWizard.Show(CallbackDescription);
	
	#EndIf
	
EndProcedure 

&AtClient
Procedure Delete(Command) 
	
	Notification = New CallbackDescription("AfterConfirmationOfDeletion", ThisObject, Id);
	ShowQueryBox(Notification, StrTemplate(NStr("vi = 'Xóa ''%1''?';
												|ru = 'Удалить ''%1''?';
												|en = 'Delete %1?'; fa = 'Delete %1?';
												|it = 'Удалить ''%1''?';
												|pl = 'Delete %1?';
												|tr = '''%1'' silinsin mi?'"), Name),
	QuestionDialogMode.YesNo);
	
EndProcedure 

&AtClient
Procedure SetParameterField(Command) 
	
	If ServerFormat >= 2 Then
		CurrentRow = Items.VirtualTables.CurrentRow;
		If CurrentRow <> Undefined Then
			ParameterFieldSelectionList = ParameterFieldSelectionList(QueryText, NameOfUnsetParameterField);
			OpenOptionFieldSelectionForm(CurrentRow, ParameterFieldSelectionList)
		EndIf;
	Else
		Raise NStr("vi = 'Phiên bản server 1C:Analytics không hỗ trợ làm việc với tham số bảng ảo. Hãy cập nhật phiên bản server 1C:Analytics.';
					|ru = 'Версия сервера 1С:Аналитики не поддерживает работу с параметрами виртуальных таблиц. Обновите версию сервера 1С:Аналитики.';
					|en = 'The 1C:Analytics server version does not support virtual table parameters. Update the 1C:Analytics server.'; fa = 'The 1C:Analytics server version does not support virtual table parameters. Update the 1C:Analytics server.';
					|it = 'Версия сервера 1С:Аналитики не поддерживает работу с параметрами виртуальных таблиц. Обновите версию сервера 1С:Аналитики.';
					|pl = 'The 1C:Analytics server version does not support virtual table parameters. Update the 1C:Analytics server.';
					|tr = '1C:Analytics sunucusu sürümü sanal tablo parametreleriyle çalışmayı desteklemiyor. 1C:Analytics sunucusu sürümünü güncelleyin.'");
	EndIf;  
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ReadObject()
	
	Transformation_ = ConvertingFieldRoles(True);
	
	AdditionalSource = DataProcessors.Manage1CAnalyticsPanels.AdditionalSourcesFromScheme(Id);
	Data = JSONValue(AdditionalSource.Get("data"));
	
	Fields.Clear();
	If Data <> Undefined Then
		Name = UndefinedInEmptyLine(Data.Get("name"));
		Presentation = UndefinedInEmptyLine(Data.Get("synonym"));
		QueryText = UndefinedInEmptyLine(Data.Get("query"));
		If Data.Get("fields")<>Undefined Then
			For Each Field In Data.Get("fields") Do
				String = Fields.Add();
				String.Name = Field.Key;
				String.Presentation = UndefinedInEmptyLine(Field.Value.Get("synonym"));
				String.Role = UndefinedInEmptyLine(Transformation_.Get(UndefinedInEmptyLine(Field.Value.Get("role"))));
				String.Type = TypeBPresentation(UndefinedInEmptyLine(Field.Value.Get("type")));
			EndDo;
		EndIf;
	Else
		Name = "";
		Presentation = "";
		QueryText = "";
	EndIf;  
	
EndProcedure

&AtServer
Procedure SaveAtServer(NameOfUnsetParameterField)
	
	FieldRoles = ConvertingFieldRoles(False); 
	
	SourceData = New Map();
	SourceData.Insert("name", Name);
	SourceData.Insert("synonym", Presentation);
	SourceData.Insert("query", QueryText);
	
	FieldsToSave = New Map();
	For Each Field In Fields Do
		MatchingField = New Map();
		MatchingField.Insert("synonym", Field.Presentation);
		MatchingField.Insert("role", FieldRoles.Get(Field.Role));
		MatchingField.Insert("type", PresentationInType(Field.Type));
		FieldsToSave.Insert(Field.Name, MatchingField);
	EndDo;
	SourceData.Insert("fields", FieldsToSave);
	
	ParamsToSave = New Map();
	For Each Table In VirtualTables Do
		If Not IsBlankString(Table.FieldOfParameters) And Table.FieldOfParameters <> NameOfUnsetParameterField Then
			Parameter = New Map();
			Parameter.Insert("type", "virtualTableParameter");
			ParamsToSave.Insert(Table.FieldOfParameters, Parameter);
		EndIf;
	EndDo;
	If ParamsToSave.Count() Then
		SourceData.Insert("parameters", ParamsToSave);
	EndIf;
	
	AdditionalSource = New Map();
	AdditionalSource.Insert("id", Id);
	AdditionalSource.Insert("type", "additional-datasource");
	AdditionalSource.Insert("owner", "");
	AdditionalSource.Insert("data", ValueToJSON(SourceData));
	If ServerFormat >= 2 Then
		AdditionalSource.Insert("version", 2);
	EndIf;
	
	DataProcessors.Manage1CAnalyticsPanels.WriteSchema(ValueToJSON(AdditionalSource));
	
	Modified = False; 
	
EndProcedure

&AtClient
Function CheckFields()
	
	If StrLen(Name) = 0 Then
		Raise NStr("vi = 'Tên không được để trống';
					|ru = 'Имя не должно быть пустым';
					|en = 'The name cannot be empty'; fa = 'The name cannot be empty';
					|it = 'Имя не должно быть пустым';
					|pl = 'The name cannot be empty';
					|tr = 'Ad kısmı boş olmamalıdır'");
	EndIf;
	
	If StrFind(Name, " ") <> 0 Then
		Raise NStr("vi = 'Sai tên. Tên phải bao gồm một từ, bắt đầu bằng một chữ cái và không chứa dấu cách hoặc ký tự đặc biệt ngoại trừ ""_""';
					|ru = 'Неверное имя. Имя должно состоять из одного слова, начинаться с буквы и не содержать пробелов и специальных символов кроме ""_""';
					|en = 'Incorrect name. The name must consist of one word, start with a letter, contain no spaces and special characters apart from ""_""'; fa = 'Incorrect name. The name must consist of one word, start with a letter, contain no spaces and special characters apart from ""_""';
					|it = 'Неверное имя. Имя должно состоять из одного слова, начинаться с буквы и не содержать пробелов и специальных символов кроме ""_""';
					|pl = 'Incorrect name. The name must consist of one word, start with a letter, contain no spaces and special characters apart from ""_""';
					|tr = 'Geçersiz ad. Ad, tek bir kelimeden oluşmalı, harfle başlamalı ve ""_"" dışında boşluk veya özel karakter içermemelidir'");
	EndIf;
	
	Try
		NameVerificationStructure = New Structure();
		NameVerificationStructure.Insert(Name, "");
	Except
		Raise NStr("vi = 'Sai tên. Tên phải bao gồm một từ, bắt đầu bằng một chữ cái và không chứa dấu cách hoặc ký tự đặc biệt ngoại trừ ""_""';
					|ru = 'Неверное имя. Имя должно состоять из одного слова, начинаться с буквы и не содержать пробелов и специальных символов кроме ""_""';
					|en = 'Incorrect name. The name must consist of one word, start with a letter, contain no spaces and special characters apart from ""_""'; fa = 'Incorrect name. The name must consist of one word, start with a letter, contain no spaces and special characters apart from ""_""';
					|it = 'Неверное имя. Имя должно состоять из одного слова, начинаться с буквы и не содержать пробелов и специальных символов кроме ""_""';
					|pl = 'Incorrect name. The name must consist of one word, start with a letter, contain no spaces and special characters apart from ""_""';
					|tr = 'Geçersiz ad. Ad, tek bir kelimeden oluşmalı, harfle başlamalı ve ""_"" dışında boşluk veya özel karakter içermemelidir'");
	EndTry;
	
	For Each Item In ExistingNames Do
		If Name = Item.Value Then
			Raise NStr("vi = 'Tên nguồn bổ sung không phải là duy nhất';
						|ru = 'Имя дополнительного источника не уникально';
						|en = 'The additional source name is not unique'; fa = 'The additional source name is not unique';
						|it = 'Имя дополнительного источника не уникально';
						|pl = 'The additional source name is not unique';
						|tr = 'Ek kaynağın adı benzersiz değil'");
		EndIf;
	EndDo;
	
	Return True; 
	
EndFunction

&AtClient
Procedure SaveWithFieldsFilledIn(AdditionalParameters)
	
	QueryFields = ParseRequestOnClient(QueryText);
	
	If QueryFields.Count() <> Fields.Count() Then
		FillInQueryTextFields();
	EndIf;
	
	For Each String In Fields Do
		Field = Undefined;
		For Each TheQueryBox In QueryFields Do
			If TheQueryBox.Name = String.Name Then
				Field = TheQueryBox.Type;
				Break;
			EndIf;
		EndDo;
		If TypeBPresentation(UndefinedInEmptyLine(Field)) <> String.Type Then
			FillInQueryTextFields();
			Break;
		EndIf;
	EndDo;
	
	SaveAtServer(NameOfUnsetParameterField);
	If FormOwner <> Undefined Then
		Notify("DownloadAdditionalSource", Id, FormOwner);
	EndIf;
	If AdditionalParameters.Close Then
		Close();
	Else
		Title = Name;
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterClosingQueryConstructor(QueryTextOfConstructor, AdditionalParameters) Export
	
	If QueryTextOfConstructor <> Undefined Then
		QueryText = QueryTextOfConstructor;
		If ServerFormat >= 2 Then
			FillInVirtualTablesFromQueryOnServer(NameOfUnsetParameterField);
		EndIf;
		Modified = True;
	EndIf; 
	
EndProcedure

&AtServerNoContext
Function ParseRequest(QueryText)
	
	TypesOfMatching = New Map();
	TypesOfMatching.Insert(Type("Null"), "null");
	TypesOfMatching.Insert(Type("Undefined"), "null");
	TypesOfMatching.Insert(Type("Boolean"), "boolean");
	TypesOfMatching.Insert(Type("String"), "string");
	TypesOfMatching.Insert(Type("Number"), "number");
	TypesOfMatching.Insert(Type("Date"), "date");
	
	FieldArray = New Array();
	QuerySchema = New QuerySchema();
	QuerySchema.SetQueryText(QueryText);
	RequestColumns = QuerySchema.QueryBatch[QuerySchema.QueryBatch.Count()-1].Columns;
	For Each Column In RequestColumns Do
		Types_Array = New Array();
		For Each FieldType In Column.ValueType.Types() Do
			MetadataObject = Metadata.FindByType(FieldType);
			If MetadataObject = Undefined Then
				Types_Array.Add(?(TypesOfMatching[FieldType] = Undefined, FieldType, TypesOfMatching[FieldType]));
			Else
				Types_Array.Add(MetadataObject.FullName());
			EndIf;
		EndDo;
		Field = New Structure();
		Field.Insert("Name", Column.Alias);
		Field.Insert("Type", StrConcat(Types_Array, ","));
		FieldArray.Add(Field);
	EndDo; 
	
	Return FieldArray;
	
EndFunction

&AtClientAtServerNoContext
Function ConvertingFieldRoles(UserPresentation1) 
	
	Dimension_Value = NStr("vi = 'Chiều đo';
							|ru = 'Измерение';
							|en = 'Dimension'; fa = 'بُعد';
							|it = 'Измерение';
							|pl = 'Dimension';
							|tr = 'Boyut'");
	FactValue = NStr("vi = 'Thực tế';
					|ru = 'Факт';
					|en = 'Actual'; fa = 'واقعی';
					|it = 'Факт';
					|pl = 'Actual';
					|tr = 'Gerçek'");
	FieldRoles = New Map();
	If UserPresentation1 Then
		FieldRoles.Insert("dimension", Dimension_Value);
		FieldRoles.Insert("measure", FactValue);
	Else
		FieldRoles.Insert(Dimension_Value, "dimension");
		FieldRoles.Insert(FactValue, "measure");
	EndIf;
	
	Return FieldRoles;
	
EndFunction

&AtClient
Function ParseRequestOnClient(QueryText) 
	
	Try
		Return ParseRequest(QueryText);
	Except
		If ErrorInfo().Cause <> Undefined Then
			Raise NStr("vi = 'Lỗi trong truy vấn';
						|ru = 'Ошибка в запросе';
						|en = 'Error in the query'; fa = 'Error in the query';
						|it = 'Ошибка в запросе';
						|pl = 'Error in the query';
						|tr = 'Sorguda hata'")
				+ Chars.LF + ErrorInfo().Cause.Description;
		Else 
			Raise ErrorInfo().Description;
		EndIf;
	EndTry; 
	
EndFunction

&AtClientAtServerNoContext
Function CreatePresentation(Name)
	
	Result = Undefined;
	Figure = Undefined;
	
	For Position = 1 To StrLen(Name) Do
		Char = Mid(Name, Position, 1);
		If Result = Undefined Then
			Result = Char;
		ElsIf CharCode(Char) >= 48 And CharCode(Char) <= 57 Then
			If Figure = True Then
				Result = Result + Char;
			Else
				Result = Result + " " + Char;
				Figure = True;
			EndIf;
		ElsIf Upper(Char) = Char Then
			Result = Result + " " + Lower(Char);
			Figure = False;
		Else
			Figure = False;
			Result = Result + Char;
		EndIf;
	EndDo; 
	
	Return Result;
	
EndFunction

&AtClient
Function CanBeDimension(Type)
	
	Return Type = "Number" Or Type = "Number";
	
EndFunction

&AtClient
Procedure AfterConfirmationOfDeletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		DeleteAdditionalSourceOnServer(AdditionalParameters);
		If FormOwner <> Undefined Then
			Notify("DownloadAdditionalSource", Undefined, FormOwner);
		EndIf;
		Modified = False;
		Close();
	EndIf;
	
EndProcedure

&AtServer
Procedure DeleteAdditionalSourceOnServer(Id)
	
	DataProcessors.Manage1CAnalyticsPanels.DeleteSchema(Id);
	
EndProcedure

&AtServer
Procedure FillInVirtualTablesFromQueryOnServer(NameOfUnsetParameterField)
	
	VirtualTables.Clear();
	If Not IsBlankString(QueryText) Then
		
		QuerySchema = New QuerySchema();
		QuerySchema.SetQueryText(QueryText);
		
		If QuerySchema.QueryBatch.Count() Then
			QueryBatch = QuerySchema.QueryBatch.Get(0);
			If TypeOf(QueryBatch) = Type("QuerySchemaSelectQuery") Then
				ParseQueryToSelectQueryScheme(QueryBatch, NameOfUnsetParameterField)
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure ParseQueryToSelectQueryScheme(QuerySchemaSelectQuery, NameOfUnsetParameterField, AliasOfNestedRequest = "")
	
	For Each Operator In QuerySchemaSelectQuery.Operators Do 
		For Each SourceOperator In Operator.Sources Do
			Source = SourceOperator.Source;
			
			If TypeOf(Source) = Type("QuerySchemaTable") Then
				
				If Source.DataCompositionParameters.Count() And ThisIsSupportedVirtualTable(Source.TableName) Then
					VirtualTableRow = VirtualTables.Add();
					VirtualTableRow.TableName = Source.TableName;
					VirtualTableRow.TableAlias = Source.Alias;
					VirtualTableRow.AliasOfNestedRequest = AliasOfNestedRequest;
					
					Position = 1;
					For Each Parameter In Source.DataCompositionParameters Do 
						If Position > 3 Then
							Break;
						EndIf;
						
						If TypeOf(Parameter) = Type("QuerySchemaTableParameter") Then
							VirtualTableRow["Parameter" + Position] = Parameter.Expression;
							Position = Position + 1;
						EndIf;
					EndDo;
					
					// Setting the value of the field parameters
					NameOfFirstParameter = VirtualTableRow.Parameter1;
					If Not IsBlankString(NameOfFirstParameter) And NameOfFirstParameter <> "(&_)" Then
						VirtualTableRow.FieldOfParameters = ComponentOfParameterNameField(NameOfFirstParameter);
					ElsIf NameOfFirstParameter = "(&_)" Then
						VirtualTableRow.FieldOfParameters = NameOfUnsetParameterField;
					Else
						VirtualTableRow.FieldOfParameters = "";
					EndIf;
					
				EndIf;
				
			ElsIf TypeOf(Source) = Type("QuerySchemaNestedQuery") Then
				ParseQueryToSelectQueryScheme(Source.Query, NameOfUnsetParameterField, Source.Alias)
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Function ComponentOfParameterNameField(ParameterName)
	
	SeparatorPosition = StrFind(ParameterName, "_", SearchDirection.FromEnd);
	If SeparatorPosition <> 0 Then
		Return Mid(ParameterName, 3, SeparatorPosition - 3);
	Else
		Return "";
	EndIf;
	
EndFunction

&AtClientAtServerNoContext
Function PostfixOfParameterName(ParameterName)
	
	SeparatorPosition = StrFind(ParameterName, "_", SearchDirection.FromEnd);
	If SeparatorPosition <> 0 Then
		Return Mid(ParameterName, SeparatorPosition, StrLen(ParameterName) - SeparatorPosition);
	Else
		Return "";
	EndIf; 
	
EndFunction

&AtServer
Procedure SetVirtualTableParameters(VirtualTablesRowIds, FieldOfParameters, NameOfUnsetParameterField)
	
	Var Table;
	
	VirtualTablesDataRows = VirtualTables.FindByID(VirtualTablesRowIds);
	TableName = VirtualTablesDataRows.TableName;
	TableAlias = VirtualTablesDataRows.TableAlias;
	AliasOfNestedRequest = VirtualTablesDataRows.AliasOfNestedRequest;
	
	QuerySchema = New QuerySchema();
	QuerySchema.SetQueryText(QueryText);
	
	If QuerySchema.QueryBatch.Count() Then
		QueryBatch = QuerySchema.QueryBatch.Get(0);
		If TypeOf(QueryBatch) = Type("QuerySchemaSelectQuery") Then
			FindVirtualTableOfQuerySchema(QueryBatch, TableName, TableAlias, AliasOfNestedRequest, Table);
		EndIf;
	EndIf;
	
	If Table = Undefined Then
		Raise NStr("vi = 'Không tìm thấy bảng ảo trong nội dung truy vấn:';
					|ru = 'Виртуальная таблица не найдена в тексте запроса:';
					|en = 'The virtual table is not found in the query text:'; fa = 'The virtual table is not found in the query text:';
					|it = 'Виртуальная таблица не найдена в тексте запроса:';
					|pl = 'The virtual table is not found in the query text:';
					|tr = 'Sanal tablo, sorgu metninde bulunamadı:'") 
		+ Chars.LF + TableName + " " + TableAlias;
	EndIf;
	
	ThisIsEmptyParameter = (FieldOfParameters = NameOfUnsetParameterField);
	
	ParameterName1 = ?(ThisIsEmptyParameter, "(&_)", "(&" + FieldOfParameters + "_BeginOfPeriod)");
	ParameterName2 = ?(ThisIsEmptyParameter, "(&_)", "(&" + FieldOfParameters + "_EndOfPeriod)");
	ParameterName3 = ?(ThisIsEmptyParameter, "(&_)", "(&" + FieldOfParameters + "_Periodicity)");
	
	ParameterName1Eng = ?(ThisIsEmptyParameter, "(&_)", "(&" + FieldOfParameters + "_BeginOfPeriod)");
	ParameterName2Eng = ?(ThisIsEmptyParameter, "(&_)", "(&" + FieldOfParameters + "_EndOfPeriod)");
	ParameterName3Eng = ?(ThisIsEmptyParameter, "(&_)", "(&" + FieldOfParameters + "_Periodicity)");
	
	TableNameParts = StrSplit(TableName, ".", False);
	
	If TableNameParts.Count() Then
		VirtualTableType = TableNameParts.Get(TableNameParts.Count() - 1);
		
		If VirtualTableType = "Balance" Then
			Table.DataCompositionParameters[0].Expression = New QuerySchemaExpression(ParameterName2);
			
			VirtualTablesDataRows.Parameter1 = ParameterName2;
			
		ElsIf VirtualTableType = "Balance" Then
			Table.DataCompositionParameters[0].Expression = New QuerySchemaExpression(ParameterName2Eng);
			
			VirtualTablesDataRows.Parameter1 = ParameterName2Eng;
			
		ElsIf VirtualTableType = "RecordsWithExtDimensions" Then
			Table.DataCompositionParameters[0].Expression = New QuerySchemaExpression(ParameterName1);
			Table.DataCompositionParameters[1].Expression = New QuerySchemaExpression(ParameterName2);
			
			VirtualTablesDataRows.Parameter1 = ParameterName1;
			VirtualTablesDataRows.Parameter2 = ParameterName2;
			
		ElsIf VirtualTableType = "RecordsWithExtDimensions" Then
			Table.DataCompositionParameters[0].Expression = New QuerySchemaExpression(ParameterName1Eng);
			Table.DataCompositionParameters[1].Expression = New QuerySchemaExpression(ParameterName2Eng);
			
			VirtualTablesDataRows.Parameter1 = ParameterName1Eng;
			VirtualTablesDataRows.Parameter2 = ParameterName2Eng;
			
		ElsIf VirtualTableType = "Turnovers" Or VirtualTableType = "BalanceAndTurnovers" Or VirtualTableType = "DrCrTurnovers" Then
			Table.DataCompositionParameters[0].Expression = New QuerySchemaExpression(ParameterName1);
			Table.DataCompositionParameters[1].Expression = New QuerySchemaExpression(ParameterName2);
			Table.DataCompositionParameters[2].Expression = New QuerySchemaExpression(ParameterName3);
			
			VirtualTablesDataRows.Parameter1 = ParameterName1;
			VirtualTablesDataRows.Parameter2 = ParameterName2;
			VirtualTablesDataRows.Parameter3 = ParameterName3;
			
		ElsIf VirtualTableType = "Turnovers" Or VirtualTableType = "BalanceAndTurnovers" Or VirtualTableType = "DrCrTurnovers" Then
			Table.DataCompositionParameters[0].Expression = New QuerySchemaExpression(ParameterName1Eng);
			Table.DataCompositionParameters[1].Expression = New QuerySchemaExpression(ParameterName2Eng);
			Table.DataCompositionParameters[2].Expression = New QuerySchemaExpression(ParameterName3Eng);
			
			VirtualTablesDataRows.Parameter1 = ParameterName1Eng;
			VirtualTablesDataRows.Parameter2 = ParameterName2Eng;
			VirtualTablesDataRows.Parameter3 = ParameterName3Eng;
			
		ElsIf VirtualTableType = "SliceFirst" Then
			Table.DataCompositionParameters[0].Expression = New QuerySchemaExpression(ParameterName1);
			
			VirtualTablesDataRows.Parameter1 = ParameterName1;
			
		ElsIf VirtualTableType = "SliceFirst" Then
			Table.DataCompositionParameters[0].Expression = New QuerySchemaExpression(ParameterName1Eng);
			
			VirtualTablesDataRows.Parameter1 = ParameterName1Eng;
			
		ElsIf VirtualTableType = "SliceLast" Then
			Table.DataCompositionParameters[0].Expression = New QuerySchemaExpression(ParameterName2);
			
			VirtualTablesDataRows.Parameter1 = ParameterName2;
			
		ElsIf VirtualTableType = "SliceLast" Then
			Table.DataCompositionParameters[0].Expression = New QuerySchemaExpression(ParameterName2Eng);
			
			VirtualTablesDataRows.Parameter1 = ParameterName2Eng;
			
		Else
			Raise NStr("vi = 'Không thể thiết lập tham số cho bảng:';
						|ru = 'Не удалось установить параметры для таблицы:';
						|en = 'Cannot set the table parameters:'; fa = 'Cannot set the table parameters:';
						|it = 'Не удалось установить параметры для таблицы:';
						|pl = 'Cannot set the table parameters:';
						|tr = 'Tablo için parametreler yapılandırılamadı:'") + Chars.LF + TableName;
		EndIf;
		
		VirtualTablesDataRows.FieldOfParameters = FieldOfParameters;
		
	Else
		Raise NStr("vi = 'Không thể thiết lập tham số cho bảng:';
					|ru = 'Не удалось установить параметры для таблицы:';
					|en = 'Cannot set the table parameters:'; fa = 'Cannot set the table parameters:';
					|it = 'Не удалось установить параметры для таблицы:';
					|pl = 'Cannot set the table parameters:';
					|tr = 'Tablo için parametreler yapılandırılamadı:'") + Chars.LF + TableName;
	EndIf;
	
	QueryText = QuerySchema.GetQueryText()
	
EndProcedure

&AtServerNoContext
Procedure FindVirtualTableOfQuerySchema(SelectionRequest, TableName, TableAlias, RequiredAliasForNestedRequest, Result, CurAliasOfNestedRequest = "")
	
	For Each Operator In SelectionRequest.Operators Do 
		For Each SourceOperator In Operator.Sources Do
			Source = SourceOperator.Source;
			If TypeOf(Source) = Type("QuerySchemaTable") Then
				If Source.DataCompositionParameters.Count() And ThisIsSupportedVirtualTable(TableName) Then
					If Source.TableName = TableName And Source.Alias = TableAlias And CurAliasOfNestedRequest = RequiredAliasForNestedRequest Then
						Result = Source;
						Return;
					EndIf;
				EndIf;
			ElsIf TypeOf(Source) = Type("QuerySchemaNestedQuery") Then
				FindVirtualTableOfQuerySchema(Source.Query, TableName, TableAlias, RequiredAliasForNestedRequest, Result, Source.Alias);
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

&AtServerNoContext
Function ThisIsSupportedVirtualTable(TableName)
	
	If StrEndsWith(TableName, ".Balance")
		Or StrEndsWith(TableName, ".Balance")
		
		Or StrEndsWith(TableName, ".Turnovers")
		Or StrEndsWith(TableName, ".Turnovers")
		
		Or StrEndsWith(TableName, ".BalanceAndTurnovers")
		Or StrEndsWith(TableName, ".BalanceAndTurnovers")
		
		Or StrEndsWith(TableName, ".SliceFirst")
		Or StrEndsWith(TableName, ".SliceFirst")
		
		Or StrEndsWith(TableName, ".SliceLast")
		Or StrEndsWith(TableName, ".SliceLast")
		
		Or StrEndsWith(TableName, ".RecordsWithExtDimensions")
		Or StrEndsWith(TableName, ".RecordsWithExtDimensions")
		
		Or StrEndsWith(TableName, ".DrCrTurnovers")
		Or StrEndsWith(TableName, ".DrCrTurnovers") Then
		
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

&AtClient
Procedure OpenOptionFieldSelectionForm(VirtualTablesRowIds, ParameterFieldSelectionList, AdditionalParameters = Undefined)
	
	VirtualTablesDataRows = VirtualTables.FindByID(VirtualTablesRowIds);
	TableAlias = VirtualTablesDataRows.TableAlias;
	If IsBlankString(TableAlias) Then
		TableAlias = VirtualTablesDataRows.TableName;
	EndIf;
	
	ValueOfParameterField = VirtualTablesDataRows.FieldOfParameters;
	
	AdditionalNotificationParameters = New Structure();
	AdditionalNotificationParameters.Insert("VirtualTablesRowIds", VirtualTablesRowIds);
	
	If AdditionalParameters <> Undefined Then
		AdditionalNotificationParameters.Insert("Save", True);
		AdditionalNotificationParameters.Insert("Close", AdditionalParameters.Close);
		AdditionalNotificationParameters.Insert("ParameterFieldSelectionList", ParameterFieldSelectionList);
	EndIf;
	
	CallbackDescription = New CallbackDescription("AfterClosingOptionFieldSelectionForm", ThisObject, AdditionalNotificationParameters);
	
	FormParameters = New Structure("TableAlias, ParameterFieldSelectionList, ValueOfParameterField", TableAlias, ParameterFieldSelectionList, ValueOfParameterField);
	
	OpenForm("DataProcessor.Manage1CAnalyticsPanels.Form.SelectParameterField", FormParameters, ThisObject,,,, CallbackDescription, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AfterClosingOptionFieldSelectionForm(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		SetVirtualTableParameters(AdditionalParameters.VirtualTablesRowIds, Result, NameOfUnsetParameterField);
		Modified = True;
	EndIf;
	
	If AdditionalParameters.Property("Save") Then
		SaveAfterCheckingParameters(AdditionalParameters, AdditionalParameters.ParameterFieldSelectionList);
	EndIf;
	
EndProcedure

&AtServerNoContext
Function ParameterFieldSelectionList(QueryText, NameOfUnsetParameterField)
	
	ListOfParameterFields = New ValueList();
	
	QuerySchema = New QuerySchema();
	QuerySchema.SetQueryText(QueryText);
	
	If QuerySchema.QueryBatch.Count() Then
		QueryBatch = QuerySchema.QueryBatch.Get(0);
		If TypeOf(QueryBatch) = Type("QuerySchemaSelectQuery") Then
			For Each Column In QueryBatch.Columns Do
				If Column.ValueType.ContainsType(Type("Date")) Then
					ListOfParameterFields.Add(Column.Alias);
				EndIf;
			EndDo; 
		EndIf;
	EndIf;
	
	ListOfParameterFields.Add(NameOfUnsetParameterField);
	
	Return ListOfParameterFields;
	
EndFunction

&AtClient
Procedure SaveAfterCheckingParameters(AdditionalParameters, ParameterFieldSelectionList = Undefined)
	
	If ParameterFieldSelectionList = Undefined Then
		ParameterFieldSelectionList = ParameterFieldSelectionList(QueryText, NameOfUnsetParameterField);
	EndIf;
	
	// Checking empty parameters
	For Each String In VirtualTables Do
		If Not String.Checked And IsBlankString(String.FieldOfParameters) And IsBlankString(String.Parameter1) Then
			OpenOptionFieldSelectionForm(String.GetID(), ParameterFieldSelectionList, AdditionalParameters);
			String.Checked = True;
			Return;
		EndIf;
	EndDo;
	
	// Checking parameter names
	Postfixes = SupportedPostfixes();
	For Each String In VirtualTables Do
		If Not IsBlankString(String.Parameter1) And String.Parameter1 <> "(&_)" Then
			CheckParameterName(String.Parameter1, ParameterFieldSelectionList, Postfixes);
		EndIf;
		If Not IsBlankString(String.Parameter2) And String.Parameter2 <> "(&_)" Then
			CheckParameterName(String.Parameter2, ParameterFieldSelectionList, Postfixes);
		EndIf;
		If Not IsBlankString(String.Parameter3) And String.Parameter3 <> "(&_)" Then
			CheckParameterName(String.Parameter3, ParameterFieldSelectionList, Postfixes);
		EndIf;
	EndDo;
	
	// Checking for unsupported normal parameters
	CheckForUsualParameters(QueryText);
	
	// Save
	AdditionalParameters = New Structure("Close", AdditionalParameters.Close);
	If CheckFields() Then
		SaveWithFieldsFilledIn(AdditionalParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckParameterName(ParameterName, ParameterFieldSelectionList, Postfixes)
	
	FieldName = ComponentOfParameterNameField(ParameterName);
	Postfix = PostfixOfParameterName(ParameterName);
	
	If IsBlankString(FieldName) Or Postfixes.Find(Postfix) = Undefined Then
		Parameter = StrReplace(ParameterName, "&", "");
		Parameter = StrReplace(Parameter, "(", "");
		Parameter = StrReplace(Parameter, ")", "");
		Raise StrTemplate(NStr("vi = 'Sai tên tham số của bảng ảo: %1';
								|ru = 'Некорректное имя параметра виртуальной таблицы: %1';
								|en = 'Incorrect name of the virtual table parameter: %1'; fa = 'Incorrect name of the virtual table parameter: %1';
								|it = 'Некорректное имя параметра виртуальной таблицы: %1';
								|pl = 'Incorrect name of the virtual table parameter: %1';
								|tr = 'Geçersiz sanal tablo parametresi adı: %1'"), Parameter);
	EndIf;
	
	If ParameterFieldSelectionList.FindByValue(FieldName) = Undefined Then
		Raise StrTemplate(NStr("vi = 'Không có trường tham số của bảng ảo trong thành phần trường truy vấn: %1';
								|ru = 'Поле параметра виртуальной таблицы отсутствует в составе полей запроса: %1';
								|en = 'The virtual table parameter field is missing in the list of query fields: %1'; fa = 'The virtual table parameter field is missing in the list of query fields: %1';
								|it = 'Поле параметра виртуальной таблицы отсутствует в составе полей запроса: %1';
								|pl = 'The virtual table parameter field is missing in the list of query fields: %1';
								|tr = 'Sorgu alanlarının içeriğinde sanal tablo parametresi alanı yoktur: %1'"), FieldName);
	EndIf; 
	
EndProcedure

&AtServerNoContext
Procedure CheckForUsualParameters(QueryText)
	
	QuerySchema = New QuerySchema();
	QuerySchema.SetQueryText(QueryText);
	
	If QuerySchema.QueryBatch.Count() Then
		QueryBatch = QuerySchema.QueryBatch.Get(0);
		If TypeOf(QueryBatch) = Type("QuerySchemaSelectQuery") Then
			CheckUsualParametersInRequestToSelectRequestSchema(QueryBatch)
		EndIf;
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure CheckUsualParametersInRequestToSelectRequestSchema(SelectionRequest)
	
	For Each Operator In SelectionRequest.Operators Do 
		For Each SourceOperator In Operator.Sources Do
			Source = SourceOperator.Source;
			If TypeOf(Source) = Type("QuerySchemaTable") Then
				If Source.Parameters.Count() Then 
					For Each Parameter In Source.Parameters Do
						ParameterValue = String(Parameter.Expression);
						If StrStartsWith(ParameterValue, "&") Then
							Raise StrTemplate(NStr("vi = 'Định dạng tham số bảng ảo không được hỗ trợ: %1';
													|ru = 'Неподдерживаемый формат параметра виртуальной таблицы: %1';
													|en = 'Unsupported format of the virtual table parameter: %1'; fa = 'Unsupported format of the virtual table parameter: %1';
													|it = 'Неподдерживаемый формат параметра виртуальной таблицы: %1';
													|pl = 'Unsupported format of the virtual table parameter: %1';
													|tr = 'Desteklenmeyen sanal tablo parametresi formatı: %1'"), StrReplace(ParameterValue, "&", ""));
						EndIf;
					EndDo;
				EndIf;
			ElsIf TypeOf(Source) = Type("QuerySchemaNestedQuery") Then
				CheckUsualParametersInRequestToSelectRequestSchema(Source.Query);
			EndIf;
		EndDo;
	EndDo; 
	
EndProcedure

&AtClient
Function SupportedPostfixes()
	
	Postfixes = New Array();
	Postfixes.Add("_BeginOfPeriod");
	Postfixes.Add("_EndOfPeriod");
	Postfixes.Add("_Periodicity");
	Postfixes.Add("_BeginOfPeriod");
	Postfixes.Add("_EndOfPeriod");
	Postfixes.Add("_Periodicity");
	
	Return Postfixes; 
	
EndFunction

&AtServerNoContext
Function RequestContainsParametersOfVirtualTables(QueryText)
	
	Contains = False;
	
	QuerySchema = New QuerySchema();
	QuerySchema.SetQueryText(QueryText);
	
	If QuerySchema.QueryBatch.Count() Then
		QueryBatch = QuerySchema.QueryBatch.Get(0);
		If TypeOf(QueryBatch) = Type("QuerySchemaSelectQuery") Then
			FindVirtualTableParameters(QueryBatch, Contains)
		EndIf;
	EndIf;
	
	Return Contains;
	
EndFunction

&AtServerNoContext
Procedure FindVirtualTableParameters(SelectionRequest, Contains)
	
	For Each Operator In SelectionRequest.Operators Do 
		For Each SourceOperator In Operator.Sources Do
			Source = SourceOperator.Source;
			
			If TypeOf(Source) = Type("QuerySchemaTable") Then
				
				If Source.DataCompositionParameters.Count() Then
					For Each Parameter In Source.DataCompositionParameters Do 
						If TypeOf(Parameter) = Type("QuerySchemaTableParameter") And Not IsBlankString(Parameter.Expression) Then
							Contains = True;
							Return;
						EndIf;
					EndDo;
				EndIf;
				
				If Source.Parameters.Count() Then 
					For Each Parameter In Source.Parameters Do
						If TypeOf(Parameter) = Type("QuerySchemaTableParameter") And StrStartsWith(Parameter.Expression, "&") Then
							Contains = True;
							Return;
						EndIf;
					EndDo;
				EndIf;
				
			ElsIf TypeOf(Source) = Type("QuerySchemaNestedQuery") Then
				FindVirtualTableParameters(Source.Query, Contains);
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

&AtServer
Function UndefinedInEmptyLine(Value)
	
	Return ?(Value = Undefined, "", Value);
	
EndFunction

&AtClientAtServerNoContext
Function TypeBPresentation(Value) 
	
	Map = New Map();
	Map.Insert("null", String(Type("Undefined")));
	Map.Insert("boolean", String(Type("Boolean")));
	Map.Insert("string", String(Type("String")));
	Map.Insert("number", String(Type("Number")));
	Map.Insert("date", String(Type("Date"))); 
	Array = New Array();
	For Each Term In StrSplit(Value, ",", False) Do
		Result = Map[Term];
		Array.Add(?(Result = Undefined, Term, Result));
	EndDo;
	
	Return StrConcat(Array, ","); 
	
EndFunction

&AtClientAtServerNoContext
Function PresentationInType(Value)
	
	Map = New Map();
	Map.Insert(String(Type("Null")), "null");
	Map.Insert(String(Type("Undefined")), "null");
	Map.Insert(String(Type("Boolean")), "boolean");
	Map.Insert(String(Type("String")), "string");
	Map.Insert(String(Type("Number")), "number");
	Map.Insert(String(Type("Date")), "date"); 
	Array = New Array();
	For Each Term In StrSplit(Value, ",", False) Do
		Result = Map[Term];
		Array.Add(?(Result = Undefined, Term, Result));
	EndDo;
	
	Return StrConcat(Array, ",");
	
EndFunction

&AtServer
Function JSONValue(JSONString)
	
	If JSONString = "" Then
		Return Undefined;
	EndIf;
	JSONReader = New JSONReader();
	JSONReader.SetString(JSONString);
	Return ReadJSON(JSONReader, True); 
	
EndFunction

&AtServer
Function ValueToJSON(Value)
	
	JSONWriter = New JSONWriter();
	JSONWriter.SetString(New JSONWriterSettings(JSONLineBreak.None));
	WriteJSON(JSONWriter, Value);
	Return JSONWriter.Close();
	
EndFunction

&AtClient
Procedure FillInQueryTextFields()
	
	New_Fields = ParseRequestOnClient(QueryText); //Array
	Transformation_ = ConvertingFieldRoles(True);
	ConversionIsReversed = ConvertingFieldRoles(False);
	OldFields = New Map();
	For Each Field In Fields Do
		Field_Structure = New Structure();
		Field_Structure.Insert("Presentation", Field.Presentation);
		Field_Structure.Insert("Role", ConversionIsReversed.Get(Field.Role));
		OldFields.Insert(Field.Name, Field_Structure);
	EndDo;
	
	Fields.Clear();
	For Each Field In New_Fields Do //Structure
		String = Fields.Add();
		String.Name = Field.Name;
		String.Type = TypeBPresentation(Field.Type);
		
		OldField = OldFields.Get(String.Name);
		If OldField <> Undefined Then
			String.Presentation = OldField.Presentation;
			String.Role = OldField.Role;
		Else
			String.Presentation = CreatePresentation(String.Name);
			String.Role = "measure";
		EndIf;
		If CanBeDimension(String.Type) Then
			String.Role = Transformation_.Get(String.Role);
		Else
			String.Role = Transformation_.Get("dimension");
		EndIf;
	EndDo; 
	
EndProcedure 

&AtClient
Procedure WriteDownAndCloseForm()
	
	If IsBlankString(QueryText) Then
		ShowMessageBox( , NStr("ru = 'Текст запроса отсутствует';
								|vi = 'The request text is missing';
								|en = 'The request text is missing'; fa = 'The request text is missing';
								|it = 'The request text is missing';
								|pl = 'The request text is missing';
								|tr = 'Sorgu metni yoktur'"));
		Return;
	EndIf;
	
	If ServerFormat < 2 And RequestContainsParametersOfVirtualTables(QueryText) Then
		Raise NStr("vi = 'Phiên bản server 1C:Analytics không hỗ trợ làm việc với tham số bảng ảo. Hãy cập nhật phiên bản server 1C:Analytics.';
					|ru = 'Версия сервера 1С:Аналитики не поддерживает работу с параметрами виртуальных таблиц. Обновите версию сервера 1С:Аналитики.';
					|en = 'The 1C:Analytics server version does not support virtual table parameters. Update the 1C:Analytics server.'; fa = 'The 1C:Analytics server version does not support virtual table parameters. Update the 1C:Analytics server.';
					|it = 'Версия сервера 1С:Аналитики не поддерживает работу с параметрами виртуальных таблиц. Обновите версию сервера 1С:Аналитики.';
					|pl = 'The 1C:Analytics server version does not support virtual table parameters. Update the 1C:Analytics server.';
					|tr = '1C:Analytics sunucusu sürümü sanal tablo parametreleriyle çalışmayı desteklemiyor. 1C:Analytics sunucusu sürümünü güncelleyin.'");
	EndIf;
	
	AdditionalParameters = New Structure("Close", True);
	If ServerFormat >= 2 Then
		FillInVirtualTablesFromQueryOnServer(NameOfUnsetParameterField);
		SaveAfterCheckingParameters(AdditionalParameters);
	Else
		If CheckFields() Then
			SaveWithFieldsFilledIn(AdditionalParameters);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion