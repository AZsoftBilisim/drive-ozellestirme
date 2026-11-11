
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.CopyingValue.Overridable_1 Then
		ErrorText = NStr("ru = 'Копирование правила по настройкам уникальности недопустимо';
						|vi = 'Copying the rule by uniqueness settings is not allowed';
						|en = 'Copying the rule by uniqueness settings is not allowed'; fa = 'Copying the rule by uniqueness settings is not allowed';
						|it = 'Copying the rule by uniqueness settings is not allowed';
						|pl = 'Copying the rule by uniqueness settings is not allowed';
						|tr = 'Benzersizlik ayarlarına göre kuralın kopyalanmasına izin verilmiyor'");
		Common.MessageToUser(ErrorText,,,,Cancel);
	EndIf;
	FillInDirectoryIds();
	
	SearchAndReplaceDuplicatesMasterDataOverridable.MasterDataDuplicateSearchRules_WhenCreatingAtServer(ThisObject, Cancel);
	
	FormControl();
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	RequestIsCorrect = CheckRequestAtServer(False);
	If Object.Active And Not RequestIsCorrect Then
		Common.MessageToUser(NStr("ru = 'Правило не может быть активным. Некорректный запрос';
									|vi = 'The rule cannot be active. Incorrect query';
									|en = 'The rule cannot be active. Incorrect query'; fa = 'The rule cannot be active. Incorrect query';
									|it = 'The rule cannot be active. Incorrect query';
									|pl = 'The rule cannot be active. Incorrect query';
									|tr = 'Kural aktif olamaz. Geçersiz sorgu'"),CurrentObject, ,QueryText, Cancel);
	EndIf;
	RequestStructure = New Structure;
	RequestStructure.Insert("QueryText", QueryText.GetText());
	RequestStructure.Insert("QueryOptions", New ValueStorage(QueryOptions.Unload(), New Deflation(9)));
	CurrentObject.Query = New ValueStorage(RequestStructure, New Deflation(9));
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	Notify("RecordedRule");
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	RequestStructure = CurrentObject.Query.Get();
	If TypeOf(RequestStructure) = Type("Structure") Then
		QueryText.SetText(RequestStructure.QueryText);
		If RequestStructure.Property("QueryOptions") Then
			QueryOptions.Load(RequestStructure.QueryOptions.Get());
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure QueryTextOnChange(Item)
	Modified = True; 
	Object.IsChanged = True;
	FormControl();
EndProcedure

&AtClient
Procedure MetadataObjectAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	Filter = New Structure;
	Filter.Insert("Ref", CatalogIds.UnloadValues());
	DataGetParameters.Filter = Filter;
EndProcedure

&AtClient
Procedure MetadataObjectStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	StandardProcessing = False;
	CompositionSettings = New DataCompositionSettings;  
	FilterElement = CompositionSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("Ref");
	FilterElement.ComparisonType = DataCompositionComparisonType.InListByHierarchy;
	FilterElement.RightValue = HierarchyGroups();
	FilterElement.Use = True;
	
	FormParameters = New Structure;
	FormParameters.Insert("FixedSettings", CompositionSettings);
	FormParameters.Insert("ChoiceMode", True);
	OpenForm("Catalog.MetadataObjectIDs.ChoiceForm", FormParameters,Item);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure GenerateReport(Command)
	If Modified Then 
		ShowQueryBox(New CallbackDescription("GenerateReportCompletion", ThisObject), 
			NStr("ru = 'Для продолжения необходимо записать. Продолжить?';
				|vi = 'To continue, save the changes. Continue?';
				|en = 'To continue, save the changes. Continue?'; fa = 'To continue, save the changes. Continue?';
				|it = 'To continue, save the changes. Continue?';
				|pl = 'To continue, save the changes. Continue?';
				|tr = 'Devam etmek için yazılması gerekir. Devam edilsin mi?'"), 
			QuestionDialogMode.YesNo);
	Else
		OpenReport();
	EndIf;
EndProcedure

&AtClient
Procedure QueryWizard(Command)
	OpenQueryBuilder();
EndProcedure

&AtClient
Procedure ClearRequestParameters(Command)
	QueryOptions.Clear();
EndProcedure

&AtClient
Procedure RequestParameters_ToFillIn(Command)
	If QueryOptions.Count() Then
		QueryText = NStr("ru = 'Таблица параметров будет очищена. Продолжить?';
						|vi = 'The parameter table will be cleared. Continue?';
						|en = 'The parameter table will be cleared. Continue?'; fa = 'The parameter table will be cleared. Continue?';
						|it = 'The parameter table will be cleared. Continue?';
						|pl = 'The parameter table will be cleared. Continue?';
						|tr = 'Parametreler tablosu temizlenecek. Devam edilsin mi?'");
		ShowQueryBox(New CallbackDescription("ContinueFillingInParameters", ThisObject),
					QueryText,
					QuestionDialogMode.YesNo,
					,
					,
					NStr("ru = 'Заполнение параметров запроса';
						|vi = 'Populate query parameters';
						|en = 'Populate query parameters'; fa = 'Populate query parameters';
						|it = 'Populate query parameters';
						|pl = 'Populate query parameters';
						|tr = 'Sorgu parametrelerini doldurma'"));
	Else
		ReadQueryParameters();
	EndIf;
EndProcedure

&AtClient
Procedure CheckRequest(Command)
	CheckRequestAtServer();
EndProcedure

&AtClient
Procedure ShowDuplicatesByRule(Command)
	If Not ValueIsFilled(Object.Ref) Then
		ShowQueryBox(New CallbackDescription("ShowDuplicatesByRuleCompletion", ThisObject), 
			NStr("ru = 'Правило поиска еще не записано. Записать?';
				|vi = 'The search rule is not yet saved. Save?';
				|en = 'The search rule is not yet saved. Save?'; fa = 'The search rule is not yet saved. Save?';
				|it = 'The search rule is not yet saved. Save?';
				|pl = 'The search rule is not yet saved. Save?';
				|tr = 'Arama kuralı henüz yazılmadı. Yazılsın mı?'"), QuestionDialogMode.YesNo);
	Else
		OpenForm("InformationRegister.MasterDataDuplicatesToConfirm.Form.ListForm", New Structure("Source", Object.Ref));
	EndIf;
EndProcedure

&AtClient
Procedure FindAndRecordDoubles(Command)
	If Modified Then
		ShowQueryBox(New CallbackDescription("FindAndRecordTakesAfterRecording", ThisObject),
			NStr("ru = 'Правило еще не записано. Записать?';
				|vi = 'The rule is not yet saved. Save?';
				|en = 'The rule is not yet saved. Save?'; fa = 'The rule is not yet saved. Save?';
				|it = 'The rule is not yet saved. Save?';
				|pl = 'The rule is not yet saved. Save?';
				|tr = 'Kural henüz yazılmadı. Yazılsın mı?'"),
			QuestionDialogMode.YesNo,,,,);
	Else
		FindAndRecordDuplicatesCheck();
	EndIf;
EndProcedure

&AtClient
Procedure RestoreSuppliedRequest(Command)
	ShowQueryBox(New CallbackDescription("RestoreSuppliedRequestContinued", ThisObject), 
		NStr("ru = 'Восстановить запрос в исходное состояние?';
			|vi = 'Recover the query to its original state?';
			|en = 'Recover the query to its original state?'; fa = 'Recover the query to its original state?';
			|it = 'Recover the query to its original state?';
			|pl = 'Recover the query to its original state?';
			|tr = 'Sorgu başlangıç durumuna geri yüklensin mi?'"),
		QuestionDialogMode.YesNo,
		,
		,
		NStr("ru = 'Сброс запроса';
			|vi = 'Reset query';
			|en = 'Reset query'; fa = 'Reset query';
			|it = 'Reset query';
			|pl = 'Reset query';
			|tr = 'Sorgu sıfırlama'"));
EndProcedure

#EndRegion

#Region Private

&AtServer
Function TextOfSuppliedRequest()
	Return SearchAndReplaceDuplicatesMasterDataOverridable.QueryTextOfSuppliedRule(Object.Ref);
EndFunction

&AtServer
Function HierarchyGroups()
	Groups = New Array;
	Groups.Add(Catalogs.MetadataObjectIDs.FindByDescription("Catalogs"));
	Groups.Add(Catalogs.MetadataObjectIDs.FindByDescription("Plans kindsof features"));
	Return Groups;
EndFunction

&AtClient
Procedure FindAndRecordTakesAfterRecording(Response, AdditionalParameters) Export
	If Response = DialogReturnCode.Yes Then
		Write();
		FindAndRecordDuplicatesCheck();
	EndIf;
EndProcedure

&AtClient
Procedure FindAndRecordDuplicatesCheck()
	RequestIsCorrect = CheckRequestAtServer(False);
	If Not RequestIsCorrect Then
		CommonClient.MessageToUser(NStr("ru = 'Невозможно найти дубли. Некорректный запрос';
										|vi = 'Cannot find duplicates. Incorrect query';
										|en = 'Cannot find duplicates. Incorrect query'; fa = 'Cannot find duplicates. Incorrect query';
										|it = 'Cannot find duplicates. Incorrect query';
										|pl = 'Cannot find duplicates. Incorrect query';
										|tr = 'Yinelenen kopyalar bulunamadı. Geçersiz sorgu'"));
		Return;
	EndIf;
	ThereAreDuplicatesAccordingToRule = CheckExistenceOfDuplicates(Object.Ref);
	QueryText = NStr("ru = 'По данному правилу ранее были зарегистрированы дубли. 
				|При повторном поиске все ранее найденные дубли будут удалены. Продолжить?';
				|vi = 'Duplicates were previously registered according to this rule.
				|If you repeat the search, all previously found duplicates will be deleted. Continue?';
				|en = 'Duplicates were previously registered according to this rule.
				|If you repeat the search, all previously found duplicates will be deleted. Continue?'; fa = 'Duplicates were previously registered according to this rule.
				|If you repeat the search, all previously found duplicates will be deleted. Continue?';
				|it = 'Duplicates were previously registered according to this rule.
				|If you repeat the search, all previously found duplicates will be deleted. Continue?';
				|pl = 'Duplicates were previously registered according to this rule.
				|If you repeat the search, all previously found duplicates will be deleted. Continue?';
				|tr = 'Bu kurala göre daha önce yinelenen öğeler kaydedilmiş. 
				|Tekrar arama yapıldığında daha önce bulunan tüm yinelenen öğeler silinecek. Devam edilsin mi?'");
	If ThereAreDuplicatesAccordingToRule Then
		ShowQueryBox(New CallbackDescription("FindAndRecordDoublesCompletion", ThisObject),
					QueryText,
					QuestionDialogMode.YesNo,
					,,,);
	Else
		FindAndRecordDoublesServer();
		Notify("UpdateWorkplaceDeleteMasterDataDuplicates");
		ShowUserNotification(NStr("ru = 'Дубли найдены и записаны';
									|vi = 'Duplicates are found and saved';
									|en = 'Duplicates are found and saved'; fa = 'Duplicates are found and saved';
									|it = 'Duplicates are found and saved';
									|pl = 'Duplicates are found and saved';
									|tr = 'Yinelenen öğeler bulundu ve kaydedildi'"));
	EndIf;
EndProcedure

&AtClient
Procedure FindAndRecordDoublesCompletion(Response, AdditionalParameters) Export
	If Response = DialogReturnCode.Yes Then
		FindAndRecordDoublesServer();
		Notify("UpdateWorkplaceDeleteMasterDataDuplicates");
		ShowUserNotification(NStr("ru = 'Дубли найдены и записаны';
									|vi = 'Duplicates are found and saved';
									|en = 'Duplicates are found and saved'; fa = 'Duplicates are found and saved';
									|it = 'Duplicates are found and saved';
									|pl = 'Duplicates are found and saved';
									|tr = 'Yinelenen öğeler bulundu ve kaydedildi'"));
	EndIf;
EndProcedure

&AtClient
Procedure ShowDuplicatesByRuleCompletion(Response, AdditionalParameters) Export
	If Response = DialogReturnCode.Yes Then
		Write();
		OpenForm("InformationRegister.MasterDataDuplicatesToConfirm.Form.ListForm", New Structure("Source", Object.Ref));
	EndIf;
EndProcedure

&AtClient
Procedure GenerateReportCompletion(Response, AdditionalParameters) Export
	If Response = DialogReturnCode.Yes Then
		Write();
		OpenReport();
	EndIf;
EndProcedure

&AtClient
Procedure ContinueFillingInParameters(Response, AdditionalParameters) Export
	If Response = DialogReturnCode.Yes Then
		QueryOptions.Clear();
		ReadQueryParameters();
	EndIf;
EndProcedure

&AtClient
Procedure OpenQueryBuilder()

#If Not MobileClient Then
	QueryWizard = New QueryWizard;
	If Not IsBlankString(QueryText.GetText()) Then
		QueryWizard.Text = QueryText.GetText();
	EndIf;
	AdditionalParameters = New Structure("QueryTextBeforeEditing",QueryText.GetText());
	
    Try
		QueryWizard.Show(New CallbackDescription("AfterEditingRequest", ThisObject, AdditionalParameters));
	Except
		CommonClient.MessageToUser(ErrorDescription());
	EndTry;
#EndIf
	
EndProcedure

&AtClient
Procedure AfterEditingRequest(Text, AdditionalParameters) Export
	If Not IsBlankString(Text) Then
		If Not AdditionalParameters.QueryTextBeforeEditing = Text Then
			QueryText.SetText(Text);
			ReadQueryParameters();
			Object.IsChanged = True;
			Modified = True;
			FormControl();
		EndIf;
	Else
		Modified = False;
	EndIf;
EndProcedure

&AtServer
Procedure ReadQueryParameters()
	
	Query = New Query;
	Query.Text = QueryText.GetText();
	If IsBlankString(Query.Text) Then
		Return;
	EndIf;
	QueryParametersDescription = Query.FindParameters();
	
	For Each StrParameters In QueryParametersDescription Do
		ReadParameter = AddingNewParameter(StrParameters);
		
		ParameterFound = False;
		For IndexOf = 0 To QueryOptions.Count() - 1 Do
			If Lower(QueryOptions.Get(IndexOf).Name) = Lower(ReadParameter.Name) Then 
				ParameterFound = True;
			EndIf;
		EndDo;
		If Not ParameterFound Then
			AddParameterToForm(ReadParameter);
		EndIf;

	EndDo;
	
EndProcedure

&AtServer
Procedure AddParameterToForm(StructureParameter)
	
	Value 	= StructureParameter.Value;
	Type			= TypeNameFromValue(Value);
	
	// Basic Attributes.
	Item							= QueryOptions.Add();
	Item.Id			= New UUID;
	Item.Name						= StructureParameter.Name;
	Item.Type						= Type;
	Item.Value				= Value;
	
	// Uniform Attributes.
	Item.TypeInForm 				= String(TypeOf(Value));
	
EndProcedure	

&AtServer
Function AddingNewParameter(CurrentReadParameter)
	
	ParameterItem = New Structure("Name, Type, Value", CurrentReadParameter.Name);

	AvailableTypes = CurrentReadParameter.ValueType.Types();
	If AvailableTypes.Count()=0 Then
		ParameterItem.Type = "String";
		ParameterItem.Value = ValueToStringInternal("");
		Return ParameterItem;
	EndIf;

	Array = New Array;
	Array.Add(AvailableTypes.Get(0) );
	NewTypesDetails = New TypeDescription(Array);
	
	Value = NewTypesDetails.AdjustValue(Undefined);
	
	AddedTypesList = New ValueList;
	GenerateListOfTypes(AddedTypesList);
	
	Flag = False;
	TypePresentationString = String(TypeOf(Value));
	For Each ListItem In AddedTypesList Do
		If ListItem.Presentation = TypePresentationString Then
			Flag = True;
			Break;
		EndIf;
	EndDo;
	
	ParameterItem.Type = ?(Flag, TypePresentationString, XMLType(TypeOf(Value)).TypeName);
	ParameterItem.Value = Value;
	
	Return ParameterItem;
	
EndFunction
	
&AtServer
Function GenerateListOfTypes(AddedTypesList = Undefined)
	
	Array = New Array;
	Array.Add(Common.AllRefsTypeDetails());
	Array.Add(Type("TypeDescription"));
	
	AvailableDataTypes = New TypeDescription(Array);
	
	TypesArray = AvailableDataTypes.Types();
	
	NotPrimitiveTypes = New ValueList;
	NotPrimitiveTypes.LoadValues(TypesArray);
	NotPrimitiveTypes.SortByValue(SortDirection.Asc);
	
	TypesList = New ValueList;
	TypesList.Add("String", NStr("vi = 'Xâu ký tự';
								|ru = 'Строка';
								|en = 'String'; fa = 'رشته';
								|it = 'Riga';
								|pl = 'String';
								|tr = 'Satır'"));
	TypesList.Add("Number", NStr("vi = 'Số';
								|ru = 'Число';
								|en = 'Number'; fa = 'شماره';
								|it = 'Numero';
								|pl = 'Number';
								|tr = 'Sayı'"));
	TypesList.Add("Date", NStr("vi = 'Ngày';
								|ru = 'Дата';
								|en = 'Date'; fa = 'تاریخ';
								|it = 'Data';
								|pl = 'Date';
								|tr = 'Tarih'"));
	TypesList.Add("Boolean", NStr("vi = 'Boolean';
									|ru = 'Булево';
									|en = 'Boolean'; fa = 'بولی';
									|it = 'Variabile booleana';
									|pl = 'Boolean';
									|tr = 'Boolean'"));
	TypesList.Add("Boundary", NStr("ru = 'Граница';
									|vi = 'Border';
									|en = 'Border'; fa = 'کادر';
									|it = 'Border';
									|pl = 'Border';
									|tr = 'Sınır'"));
	TypesList.Add("PointInTime", NStr("ru = 'Момент времени';
										|vi = 'Point in time';
										|en = 'Point in time'; fa = 'نقطه زمانی';
										|it = 'Momento di tempo';
										|pl = 'Moment czasu';
										|tr = 'Belirli bir nokta'"));
	TypesList.Add("ValueList", NStr("ru = 'Список значений';
									|vi = 'Value list';
									|en = 'Value list'; fa = 'فهرست مقادیر';
									|it = 'Elenco di valori';
									|pl = 'Lista wartości';
									|tr = 'Değer listesi'"));
	TypesList.Add("ValueTable", NStr("ru = 'Таблица значений';
									|vi = 'Value table';
									|en = 'Value table'; fa = 'Value table';
									|it = 'Value table';
									|pl = 'Value table';
									|tr = 'Değer tablosu'"));
	
	AddedTypesList = New ValueList;
	AddedTypesList = TypesList.Copy();
	
	For Each Page1 In NotPrimitiveTypes Do
		TypeValue 		= XMLType(Page1.Value).TypeName;
		TypePresentation 	= String(Page1.Value);
		TypesList.Add(TypeValue, TypePresentation);
	EndDo;
	
	Return TypesList;
	
EndFunction

&AtServer
Function TypeNameFromValue(Value)
	
	ValueType = TypeOf(Value);
	If ValueType = Type("String") Or ValueType = Type("Undefined") Then
		TypeName = "String";
	ElsIf ValueType = Type("Number") Then
		TypeName = "Number";
	ElsIf ValueType = Type("Boolean") Then
		TypeName = "Boolean";
	ElsIf ValueType = Type("Date") Then
		TypeName = "Date";
	ElsIf ValueType = Type("PointInTime") Then
		TypeName = "PointInTime";
	ElsIf ValueType = Type("FixedArray") Then
		TypeName = "FixedArray";
	ElsIf ValueType = Type("ValueTable") Then
		TypeName = "ValueTable";
	ElsIf ValueType = Type("Structure") Then
		TypeName = "Structure";
	ElsIf ValueType = Type("Map") Then
		TypeName = "Map";
	Else
		TypeName = XMLType(TypeOf(Value)).TypeName;
	EndIf;
	
	Return TypeName;
	
EndFunction

&AtServer
Function CheckRequestAtServer(DisplayMessagesToUser = True)
	
	If Object.Overridable_1 Then
		Return True;
	EndIf;

	QuerySchema = New QuerySchema;
	RequiredTypeOfKeyFields = TypeOf(Common.ObjectAttributeValue(Object.MetadataObject,"EmptyRefValue"));
	Try
		QuerySchema.SetQueryText(QueryText.GetText());
		NumberOfPackages_ = 0;
		RequestPackageForAnalysis = QuerySchema.QueryBatch[0];
		For Each Package In QuerySchema.QueryBatch Do
			If TypeOf(Package) = Type("QuerySchemaSelectQuery") And IsBlankString(Package.PlacementTable) Then
				NumberOfPackages_ = NumberOfPackages_ + 1;
				RequestPackageForAnalysis = Package;
			EndIf;
		EndDo;
		If NumberOfPackages_ > 1 Then
			Raise NStr("ru = 'В пакете запросов не должно быть больше одного запроса';
						|vi = 'The query package must not contain more than one query';
						|en = 'The query package must not contain more than one query'; fa = 'The query package must not contain more than one query';
						|it = 'The query package must not contain more than one query';
						|pl = 'The query package must not contain more than one query';
						|tr = 'Sorgu paketinde birden fazla sorgu olmamalıdır'");
		EndIf;
		NumberOfKeyFields = 0;
		For Each Field In RequestPackageForAnalysis.Columns Do
			If Field.ValueType.ContainsType(RequiredTypeOfKeyFields) Then
				NumberOfKeyFields = NumberOfKeyFields + 1;
			EndIf;
		EndDo;
		If NumberOfKeyFields < 2 Or RequestPackageForAnalysis.Columns.Count() > 2 Then
			ErrorText = StrTemplate(NStr("ru = 'В запросе должно быть только 2 поля с типом %1';
										|vi = 'The query must contain only 2 fields with the %1 type';
										|en = 'The query must contain only 2 fields with the %1 type'; fa = 'The query must contain only 2 fields with the %1 type';
										|it = 'The query must contain only 2 fields with the %1 type';
										|pl = 'The query must contain only 2 fields with the %1 type';
										|tr = 'Sorguda %1 tipinde yalnızca 2 alan olmalıdır'"), String(RequiredTypeOfKeyFields));
			Raise ErrorText;
		EndIf;
		If DisplayMessagesToUser Then
			Common.MessageToUser(NStr("ru = 'Запрос корректный';
										|vi = 'Correct request';
										|en = 'Correct request'; fa = 'Correct request';
										|it = 'Correct request';
										|pl = 'Correct request';
										|tr = 'Sorgu doğrudur'"));
		EndIf;
	Except
		If DisplayMessagesToUser Then
			Common.MessageToUser(ErrorDescription());
		EndIf;
		Return False;
	EndTry;
	Return True;
EndFunction

&AtClient
Procedure OpenReport()
	
	ReportParameters = New Structure;
	ReportParameters.Insert("Rule", Object.Ref);
	ReportParameters.Insert("GenerateOnOpen", True);
	
	OpenForm("Report.MasterDataDuplicateReport.ObjectForm", ReportParameters);
	 
EndProcedure

&AtServer
Procedure FillInDirectoryIds()
	Query = New Query;
	Query.Text = 
	"SELECT
	|	MetadataObjectIDs.Ref AS Ref
	|FROM
	|	Catalog.MetadataObjectIDs AS MetadataObjectIDs
	|WHERE
	|	MetadataObjectIDs.Parent IN (&Parents)";
	Query.SetParameter("Parents", HierarchyGroups());
	CatalogIds.LoadValues(Query.Execute().Unload().UnloadColumn("Ref"));
EndProcedure

&AtClient
Procedure RestoreSuppliedRequestContinued(Response, AdditionalParameters) Export
	If Response = DialogReturnCode.Yes Then
		RestoreSuppliedRequestAtServer();
	EndIf;
EndProcedure

&AtServer
Procedure RestoreSuppliedRequestAtServer()
	QueryText.SetText(TextOfSuppliedRequest());
	Object.IsChanged = False;
	Modified = True;
	FormControl();
EndProcedure

&AtServer
Procedure FormControl()
	If Not Common.IsMobileClient() Then
		Items.ButtonRequestGroup.Visible = Not Common.DataSeparationEnabled();
		Items.ButtonRequestGroup.Visible = Not Object.Overridable_1;
	Else
		Items.ButtonRequestGroup.Visible = False;
	EndIf; 		
	Items.QueryText.Visible = Not Common.DataSeparationEnabled();
	Items.QueryText.Visible = Not Object.Overridable_1;
	SetVisibilityOfQueryRecovery();
EndProcedure

&AtServerNoContext
Function CheckExistenceOfDuplicates(Rule)
	Query = New Query;
	Query.Text = 
	"SELECT
	|	COUNT(DISTINCT MasterDataDuplicatesToConfirm.Duplicate1) AS DuplicateCount
	|FROM
	|	InformationRegister.MasterDataDuplicatesToConfirm AS MasterDataDuplicatesToConfirm
	|WHERE
	|	MasterDataDuplicatesToConfirm.Source = &Rule";
	Query.SetParameter("Rule", Rule);
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		ThereAreDuplicates = Selection.DuplicateCount > 0;
	Else
		ThereAreDuplicates = False;
	EndIf;
	
	Return ThereAreDuplicates;
	
EndFunction

&AtServer
Procedure FindAndRecordDoublesServer()
	SearchAndReplaceDuplicatesMasterData.ExecuteSearchForMasterDataDuplicates(Object.Ref);
EndProcedure

&AtServer
Procedure SetVisibilityOfQueryRecovery()
	SuppliedRequestHasBeenChanged = TextOfSuppliedRequest() <> QueryText.GetText();
	Items.RestoreSuppliedRequest.Visible =  Not Common.DataSeparationEnabled() 
				And Object.Predefined
				And Not Object.Overridable_1
				And SuppliedRequestHasBeenChanged;
EndProcedure

#EndRegion