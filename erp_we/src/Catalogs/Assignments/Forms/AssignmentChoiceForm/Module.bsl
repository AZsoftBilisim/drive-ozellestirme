
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Parameters.Property("Source", Source);
	
	ObjectManager = Common.ObjectManagerByFullName(Parameters.ObjectName);
	
	AssignmentFormTemplate = ObjectManager.AssignmentSelectionFormTemplate(); 
	
	ClearTemplateOfUnusedParameters();
	
	DynamicListParameters = Catalogs.Assignments.GenerateRequestParametersBasedOnTemplateOfAssignmentForm(AssignmentFormTemplate, Parameters);
	
	LoadListOfAvailableColumns();
	DownloadListOfAvailableSelections();
	
	// Determining the current bookmark from several possible ones
	SetTextAndParametersForDynamicListRequest();
	
	CreateListColumns();
	CreateSelectionFlags();
	
	CustomizeForm();

	ConfigurationModificationOverridable.OnCreateAtServer(ThisForm, StandardProcessing, Cancel);

EndProcedure

#EndRegion

#Region EventHandlersForFormElements

// Parameters:
//  Item - FormField - The element for which the action is set. 
&AtClient
Procedure Attachable_ColumnsOfListAreMarkedWhenChanging(Item)
	
	KeyOperationName = StrTemplate("Catalog.Assignments.Form.AssignmentChoiceForm.CheckOnChange.%1", Item.Name);
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True, KeyOperationName);
	
	ColumnsInMarkedWhenChangedListOnServer();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure LoadListOfAvailableColumns()

	For Each DescriptionOfColumns In AssignmentFormTemplate.ColumnDescriptions Do
		
		IncludeInFinalQuery = Catalogs.Assignments.CheckUsageConditions(DescriptionOfColumns.Prefix,
																						DescriptionOfColumns.TermsOfUse_,
																						DynamicListParameters);
		
		IncludeInFinalQuery = IncludeInFinalQuery And Not DescriptionOfColumns.Cancel;
		
		For Each Column In DescriptionOfColumns.Columns Do
			
			Presentation = Column.Presentation;
			If StrFind(Presentation, "%") <> 0 Then
				StartOfSubstring = StrFind(Presentation, "%");
				EndOfSubstring =  StrFind(Presentation, "%", SearchDirection.FromEnd);
				FullSubstring = Mid(Presentation, StartOfSubstring, EndOfSubstring - StartOfSubstring + 1);
				Substring = StrReplace(FullSubstring, "%", "");
				
				If DynamicListParameters.Property(Substring) 
					And ValueIsFilled(DynamicListParameters[Substring]) Then
					Presentation = StrReplace(Presentation, FullSubstring, DynamicListParameters[Substring]);
				Else
					// If the column representation is formed using the parameter value, and this parameter is not set,
					// then we do not show the column (we believe that not all the necessary data has arrived).
					IncludeInFinalQuery = False;
				EndIf;
			EndIf;
			
			NewRow = ListColumns.Add();
			NewRow.ColumnName                    = Column.Value;
			NewRow.Prefix                       = DescriptionOfColumns.Prefix;
			NewRow.Presentation                 = Presentation;
			NewRow.AllowedToUseAColumn = Column.Check And IncludeInFinalQuery;
			
			DefaultColumn = DescriptionOfColumns.DefaultColumns.Find(Column.Value) <> Undefined;
			
			NewRow.SetFilter = DefaultColumn And NewRow.AllowedToUseAColumn;
			NewRow.UserVisibility = DescriptionOfColumns.SpeakersAreNotSwitchedOff.Find(Column.Value) = Undefined;
			
		EndDo;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure DownloadListOfAvailableSelections()
	
	For Each DestinationPattern In AssignmentFormTemplate.AssignmentTemplates Do
		
		IncludeInFinalQuery = Catalogs.Assignments.CheckUsageConditions("",
			DestinationPattern.TermsOfUse_,
			DynamicListParameters,
			DestinationPattern.PathToTheDestinationField);
		
		If Not IncludeInFinalQuery Then
			Continue;
		EndIf;
		
		For Each FilterField In DestinationPattern Do
			
			If ValueIsFilled(FilterField.Value)
				And FilterField.Key <> "TermsOfUse_"
				And FilterField.Key <> "VisibleSelectionsOnForm"
				And FilterField.Key <> "ExcludeRefAssignment"
				And FilterField.Key <> "AssignmentTypes"
				And FilterField.Key <> "PathToTheDestinationField" Then
				
				If FilterField.Key = "LineOfBusiness"
					And (StrFind(FilterField.Value, "Object.") <> 0
						Or StrFind(FilterField.Value, "&") <> 0) Then
					
					If Not DynamicListParameters.Property("LineOfBusiness") 
						Or Not LinesOfBusinessServer.ThisIsLineOfActivityWithSeparationOfGoodsAndWorks(DynamicListParameters.LineOfBusiness) Then
						Continue;
					EndIf;
					
				EndIf;
				
				NewFilter = ListFilters.Add();
				NewFilter.FieldName		= FilterField.Key;
				NewFilter.DataPath	= FilterField.Value;
				NewFilter.Check		= True;
				
				If DestinationPattern.VisibleSelectionsOnForm.Property(FilterField.Key) Then
					NewFilter.VisibilityOnForm = True;
					NewFilter.Presentation = StrTemplate(DestinationPattern.VisibleSelectionsOnForm[FilterField.Key],
						DynamicListParameters[FilterField.Key]);
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure CreateListColumns()
	
	For CurrentIndex = 0 To ListColumns.Count() - 1 Do
		
		Column = ListColumns[CurrentIndex];
		
		If Column.AllowedToUseAColumn Then
			
			ColumnName = Column.Prefix + "_" + Column.ColumnName;
			
			NewListColumn             = Items.Add("List" + ColumnName, Type("FormField"), Items.List);
			NewListColumn.Type         = FormFieldType.LabelField;
			NewListColumn.Title   = Column.Presentation;
			NewListColumn.Format      = "NFD=3";
			NewListColumn.DataPath = "List." + ColumnName;
			
			NewListColumn.AutoMaxWidth = False;
			NewListColumn.MaxWidth     = 14;
			
			If Column.UserVisibility Then
				
				NewFlag             = Items.Add("Flag" + ColumnName, Type("FormField"), Items.ColumnManagementGroup);
				NewFlag.Type         = FormFieldType.CheckBoxField;
				NewFlag.Title   = Column.Presentation;
				NewFlag.DataPath = "ListColumns[" + CurrentIndex + "].SetFilter";
				NewFlag.SetAction("OnChange", "Attachable_ColumnsOfListAreMarkedWhenChanging");
				NewFlag.TitleLocation = FormItemTitleLocation.Right;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure CreateSelectionFlags()
	
	For Each Filter In ListFilters Do
		
		If Filter.VisibilityOnForm Then
			
			NewFlag             = Items.Add("Flag_" + Filter.FieldName, Type("FormField"), Items.ColumnManagementGroup);
			NewFlag.Type         = FormFieldType.CheckBoxField;
			NewFlag.Title   = Filter.Presentation;
			NewFlag.DataPath = "ListFilters[" + ListFilters.IndexOf(Filter) + "].Check";
			NewFlag.SetAction("OnChange", "Attachable_ColumnsOfListAreMarkedWhenChanging");
			NewFlag.TitleLocation = FormItemTitleLocation.Right;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure SetTextAndParametersForDynamicListRequest()
	
	TemporaryTable = New Array();
	QueriesTexts = New Array();
	
	// Creating a list of data source queries
	// The final text includes only those queries whose fields are used
	// For the SELECTION section, the fields present in other queries are counted.
	For Each DescriptionOfColumns In AssignmentFormTemplate.ColumnDescriptions Do
		
		FilterParameters = New Structure();
		FilterParameters.Insert("Prefix", DescriptionOfColumns.Prefix);
		FilterParameters.Insert("SetFilter", True);
		
		FoundColumns = ListColumns.FindRows(FilterParameters);
		
		// It makes sense to execute a query if at least one field is selected from it
		
		IncludeInFinalQuery = False;
		If ListColumns.Count() > 0 And FoundColumns.Count() > 0 Then
			
			IncludeInFinalQuery = Catalogs.Assignments.CheckUsageConditions(DescriptionOfColumns.Prefix,
				DescriptionOfColumns.TermsOfUse_, DynamicListParameters);
			
		EndIf;
		
		If IncludeInFinalQuery Then
			
			RequestTextPrecedingFields = "";
			RequestTextSubsequentFields = "";
			
			FoundColumns = ListColumns.FindRows(New Structure("Prefix", DescriptionOfColumns.Prefix));
			
			MinimumColumnIndex = Undefined;
			MaximumColumnIndex = 0;
			For Each Column In FoundColumns Do
				IndexOf = ListColumns.IndexOf(Column);
				MinimumColumnIndex  = ?(MinimumColumnIndex = Undefined, IndexOf, Min(MinimumColumnIndex, IndexOf));
				MaximumColumnIndex = Max(MaximumColumnIndex, IndexOf);
			EndDo;
			
			// Counting fields present in other queries
			For IndexOf = 0 To MinimumColumnIndex - 1 Do
				Column = ListColumns[IndexOf];
				ColumnName = Column.Prefix + "_" + Column.ColumnName;
				RequestTextPrecedingFields = RequestTextPrecedingFields
					+ Chars.LF + "	0 AS " + ColumnName + ", ";
			EndDo;
			For IndexOf = MaximumColumnIndex + 1 To ListColumns.Count() - 1 Do
				Column = ListColumns[IndexOf];
				ColumnName = Column.Prefix + "_" + Column.ColumnName;
				RequestTextSubsequentFields = RequestTextSubsequentFields
					+ "," + Chars.LF + "	0 AS " + ColumnName;
			EndDo;
		
			QueryText = DescriptionOfColumns.QueryText;
			QueryText = StrReplace(QueryText, "&SelectionFieldsPreceding,", RequestTextPrecedingFields);
			QueryText = StrReplace(QueryText, ",&SelectionFieldsAreSubsequent",    RequestTextSubsequentFields);
			
			QueriesTexts.Add(QueryText);
			If DescriptionOfColumns.TemporaryTable <> Undefined Then
				TemporaryTable.Add(DescriptionOfColumns.TemporaryTable);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If ValueIsFilled(QueriesTexts) Then
		
		QueryText = 
			"SELECT
			|	TheSampleTable.Purpose AS Purpose,
			|	&FieldsSelectedFromNestedQuery
			|INTO TTSelectedAssignments
			|FROM
			|	&QueriesTexts AS TheSampleTable
			|
			|GROUP BY
			|	TheSampleTable.Purpose
			|
			|HAVING
			|	&ConditionFieldsThatHave
			|
			|INDEX BY
			|	Purpose
			|;
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	Assignments.Ref AS Purpose,
			|	&FieldsSelectedFromTemporaryTable
			|FROM
			|	Catalog.Assignments AS Assignments
			|		INNER JOIN TTSelectedAssignments AS Filter
			|		ON Assignments.Ref = Filter.Purpose
			|WHERE
			|	NOT Assignments.DeletionMark
			|		AND &Conditions";
		
		FieldsSelectedFromNestedQuery = New Array;
		FieldsSelectedFromTemporaryTable = New Array;
		ConditionFieldsThatHave = New Array;
		For Each Column In ListColumns Do
			
			ColumnName = Column.Prefix + "_" + Column.ColumnName;
			
			If Column.SetFilter Then
				FieldsSelectedFromNestedQuery.Add("SUM(TheSampleTable." + ColumnName + ") AS " + ColumnName);
				ConditionFieldsThatHave.Add("SUM(TheSampleTable." + ColumnName + ") <> 0 ");
			ElsIf Column.AllowedToUseAColumn Then
				FieldsSelectedFromNestedQuery.Add("0 AS " + ColumnName);
			EndIf;
			
			If Column.SetFilter
				Or Column.AllowedToUseAColumn Then
				FieldsSelectedFromTemporaryTable.Add("Filter." + ColumnName + " AS " + ColumnName);
			EndIf;
			
		EndDo;
		
		QueryText = StrReplace(QueryText, "&FieldsSelectedFromNestedQuery",
			StrConcat(FieldsSelectedFromNestedQuery, "," + Chars.LF + Chars.Tab));
		
		QueryText = StrReplace(QueryText, "&QueriesTexts",
			StrTemplate("(%1)",
				StrConcat(QueriesTexts, TMCommonUse.QuerySeparatorInJoin())));
			
		QueryText = StrReplace(QueryText, "&ConditionFieldsThatHave",
			StrConcat(ConditionFieldsThatHave, Chars.LF + Chars.Tab + "And "));
		
		QueryText = StrReplace(QueryText, "&FieldsSelectedFromTemporaryTable",
			StrConcat(FieldsSelectedFromTemporaryTable, "," + Chars.LF + Chars.Tab));
		
		If TemporaryTable.Count() > 0 Then
			TemporaryTable.Add(QueryText);
			QueryText = StrConcat(TemporaryTable, Common.QueryBatchSeparator());
		EndIf;
		
	Else
		
		QueryText =
			"SELECT
			|	Assignments.Ref AS Purpose
			|	,&SelectionFields1
			|FROM
			|	Catalog.Assignments AS Assignments
			|WHERE
			|	NOT Assignments.DeletionMark
			|		AND &Conditions";
		
		If ValueIsFilled(ListColumns) Then
			
			SelectionFields1 = New Array;
			For Each Column In ListColumns Do
				If Column.AllowedToUseAColumn Then
					SelectionFields1.Add("0 AS " + Column.Prefix + "_" + Column.ColumnName);
				EndIf;
			EndDo;
			
			If ValueIsFilled(SelectionFields1) Then
				QueryText =
					StrReplace(
						QueryText,
						",&SelectionFields1",
						", " +StrConcat(SelectionFields1, "," + Chars.LF + Chars.Tab));
			EndIf;
			
		Else
			QueryText = StrReplace(QueryText, ",&SelectionFields1", "");
		EndIf;
		
	EndIf;
	
	TermsOfAppointment = New Array();
	For Each Filter In ListFilters Do
		If Filter.Check Then
			
			If StrFind(Filter.DataPath, "Object.") <> 0 Then
				Condition = "Assignments." + Filter.FieldName + " = " + "&" + Filter.FieldName
			ElsIf StrFind(Filter.DataPath, "&") <> 0 Then
				Condition = "Assignments." + Filter.FieldName + " IN (" + Filter.DataPath + ")";
			Else
				Condition = "Assignments." + Filter.FieldName + " = (" + Filter.DataPath + ")";
			EndIf;
			TermsOfAppointment.Add(Condition);
			
		EndIf;
	EndDo;
	TermsOfAppointment.Add("Assignments.AssignmentType IN (&AssignmentTypes)");
	Catalogs.Assignments.AddPartnerExclusionCondition(TermsOfAppointment, "Assignments");
	
	SetFilterBySource = ValueIsFilled(Source) And DynamicListParameters.ExcludeRefAssignment;
	
	If SetFilterBySource Then
		TermsOfAppointment.Add("Assignments.OrderDocument <> &Source");
	EndIf;
	
	QueryText = StrReplace(QueryText, "&Conditions",
		StrConcat(TermsOfAppointment, Chars.LF + Chars.Tab + "And "));
	
	ListProperties = Common.DynamicListPropertiesStructure();
	FillPropertyValues(ListProperties, List);
	ListProperties.QueryText = QueryText;
	Common.SetDynamicListProperties(Items.List, ListProperties);
	
	If SetFilterBySource Then
		CommonClientServer.SetDynamicListParameter(List, "Source", Source);
	EndIf;
	
	// Setting the values of the request parameters.
	
	For Each DescriptionOfColumns In AssignmentFormTemplate.ColumnDescriptions Do
		
		For Each DataPath In DescriptionOfColumns.DataPaths Do
			ParameterName = DescriptionOfColumns.Prefix + "_" + DataPath.Key;
			Value = DynamicListParameters[ParameterName];
			CommonClientServer.SetDynamicListParameter(List, ParameterName, Value);
		EndDo;
		
	EndDo;
	
	For Each FilterField In ListFilters Do
		
		If ValueIsFilled(FilterField.DataPath)
			And (StrFind(FilterField.DataPath, "Object.") <> 0
				Or StrFind(FilterField.DataPath, "&") <> 0) Then
			
			TermsOfUseParameters = Catalogs.Assignments.RequestTextAndParametersTermsOfUse("", FilterField.DataPath);
			For Each QueryParameter In TermsOfUseParameters.QueryOptions Do
				ParameterValue = DynamicListParameters[QueryParameter];
				CommonClientServer.SetDynamicListParameter(List, QueryParameter, ParameterValue);
			EndDo;
		EndIf;
		
	EndDo;
	CommonClientServer.SetDynamicListParameter(List, "AssignmentTypes",
		DynamicListParameters.AssignmentTypes);
	
EndProcedure

&AtServer
Procedure CustomizeForm()
	
	CurrentFilters = New Structure("Products, Characteristic, Partner, Contract, LineOfBusiness,
		|Document, AssignmentTypes");
	
	SelectionsOnForm = ListFilters.Unload(New Structure("VisibilityOnForm", True), "FieldName");
	
	// Getting parameter values used as selections.
	// In the future, it is used to display the current selections to the user.
	For Each KeyValue In DynamicListParameters Do
		If TypeOf(KeyValue.Value) = Type("CatalogRef.Products") Then
			CurrentFilters.Products = KeyValue.Value;
		ElsIf TypeOf(KeyValue.Value) = Type("CatalogRef.ItemsCharacteristics") Then
			CurrentFilters.Characteristic = KeyValue.Value;
		ElsIf TypeOf(KeyValue.Value) = Type("CatalogRef.Partners")
			And SelectionsOnForm.Find("Partner") = Undefined Then
			CurrentFilters.Partner = KeyValue.Value;
		ElsIf TypeOf(KeyValue.Value) = Type("CatalogRef.CounterpartyContracts")
			And SelectionsOnForm.Find("Contract") = Undefined Then
			CurrentFilters.Contract = KeyValue.Value;
		ElsIf TypeOf(KeyValue.Value) = Type("CatalogRef.LinesOfBusiness")
			And LinesOfBusinessServer.ThisIsLineOfActivityWithSeparationOfGoodsAndWorks(KeyValue.Value)
			And SelectionsOnForm.Find("LineOfBusiness") = Undefined Then
			CurrentFilters.LineOfBusiness = KeyValue.Value;
		ElsIf StrFind(KeyValue.Key, "_" + "DocumentSalesOfGoodsAndServices") > 0 Then
			CurrentFilters.Document = KeyValue.Value;
		EndIf;
	EndDo;
	CurrentFilters.AssignmentTypes = DynamicListParameters.AssignmentTypes;
	
	// Header formation
	FormTemplate = AssignmentFormTemplate(); 	
	If ValueIsFilled(FormTemplate.Title) Then
		Title = FormTemplate.Title;
	ElsIf ValueIsFilled(CurrentFilters.Products) Then
		Title = NStr("vi = 'Chọn mục đích';
					|ru = 'Выбор назначения';
					|en = 'Select assignment'; fa = 'انتخاب تخصیص';
					|it = 'Selezione di assegnazione';
					|pl = 'Wybór przeznaczenia';
					|tr = 'Atama seçimi'");
		
		Products   = StrReplace(NStr("vi = 'Mặt hàng: %1';
									|ru = 'Номенклатура: %1';
									|en = 'Items: %1'; fa = 'Items: %1';
									|it = 'Articolo: %1';
									|pl = 'Towary: %1';
									|tr = 'Öğe: %1'"),   "%1", CurrentFilters.Products);
		Characteristic = ?(ValueIsFilled(CurrentFilters.Characteristic),
								StrReplace(NStr("vi = 'Đặc tính: %1';
												|ru = 'Характеристика: %1';
												|en = 'Variant: %1'; fa = 'Variant: %1';
												|it = 'Caratteristica: %1';
												|pl = 'Charakterystyka: %1';
												|tr = 'Varyant: %1'"), "%1", CurrentFilters.Characteristic),
								"");
		UnitOfMeasure = Common.ObjectAttributeValue(CurrentFilters.Products, "UnitOfMeasure");
		UnitOfMeasure = StrReplace(NStr("vi = 'Đơn vị chỉnh sửa:%1';
										|ru = 'Ед. изм: %1';
										|en = 'Unit of measure: %1'; fa = 'Unit of measure: %1';
										|it = 'Unità di misura: %1';
										|pl = 'J.m.: %1';
										|tr = 'Ölçü birimi: %1'"), "%1", UnitOfMeasure);
		TextSelection = Products
			+ ?(ValueIsFilled(CurrentFilters.Characteristic), ", " + Characteristic, "")
			+ ", " + UnitOfMeasure;
		
		Title = Title + " (" + TextSelection + ")";
	Else
		Title = NStr("vi = 'Chọn mục đích';
					|ru = 'Выбор назначения';
					|en = 'Select assignment'; fa = 'انتخاب تخصیص';
					|it = 'Selezione di assegnazione';
					|pl = 'Wybór przeznaczenia';
					|tr = 'Atama seçimi'");
	EndIf;
	
	// Formation of an information line in the direction of activity
	SetLabelSelectedDestinations(CurrentFilters);
	
	// Managing the visibility of columns depending on the platoon of selection flags
	For Each Column In ListColumns Do
		
		If Column.AllowedToUseAColumn Then
			ListColumn = Items["List" + Column.Prefix + "_" + Column.ColumnName];
			ListColumn.Visible = Column.SetFilter;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure SetLabelSelectedDestinations(CurrentFilters)
	
	LabelTitle = "";
	If ValueIsFilled(CurrentFilters.LineOfBusiness) And ValueIsFilled(CurrentFilters.Contract) Then
		
		SubstitutionString = NStr("vi = 'Chỉ định lĩnh vực hoạt động %1 theo hợp đồng %2';
									|ru = 'Назначения направления деятельности %1 по договору %2';
									|en = '%1 line of business assignments under the %2 contract'; fa = '%1 line of business assignments under the %2 contract';
									|it = 'Destinazioni del settore delle attività %1 secondo l''accordo %2';
									|pl = 'Przeznaczenia kierunku działalności %1 wg umowy %2';
									|tr = '%2 sözleşmesine göre %1 iş kolu atamaları'");
		LabelTitle = StrTemplate(SubstitutionString, CurrentFilters.LineOfBusiness, CurrentFilters.Contract);
		
	ElsIf ValueIsFilled(CurrentFilters.LineOfBusiness) And ValueIsFilled(CurrentFilters.Partner) Then
		
		If CurrentFilters.AssignmentTypes.Find(Enums.AssignmentTypes.Own) <> Undefined Then
			SubstitutionString = NStr("vi = 'Chỉ định lĩnh vực hoạt động %1 bên nhận gia công %2';
										|ru = 'Назначения направления деятельности %1 переработчика %2';
										|en = 'Assignments of line of business %1 of subcontractor %2'; fa = 'Assignments of line of business %1 of subcontractor %2';
										|it = 'Destinazioni del settore delle attività %1 del subfornitore %2';
										|pl = 'Przeznaczenia kierunku działalności %1 przetwórcy %2';
										|tr = '%2 fason üreticinin %1 iş kolu atamaları'");
		Else
			SubstitutionString = NStr("vi = 'Chỉ định lĩnh vực hoạt động %1 bên đặt gia công %2';
										|ru = 'Назначения направления деятельности %1 давальца %2';
										|en = '%1 line of business assignments of the %2 material provider'; fa = '%1 line of business assignments of the %2 material provider';
										|it = 'Destinazioni del settore delle attività %1 del committente %2';
										|pl = 'Przeznaczenia kierunku działalności %1 właściciela surowca%2';
										|tr = '%2 tedarikçinin %1 iş kolu atamaları'");
		EndIf;
		LabelTitle = StrTemplate(SubstitutionString, CurrentFilters.LineOfBusiness, CurrentFilters.Partner);
		
	ElsIf ValueIsFilled(CurrentFilters.LineOfBusiness) Then
		
		SubstitutionString = NStr("vi = 'Điểm đến %1';
									|ru = 'Назначения направления деятельности %1';
									|en = 'Line of business assignments %1'; fa = 'Line of business assignments %1';
									|it = 'Destinazioni del settore delle attività %1';
									|pl = 'Przeznaczenia kierunku działalności %1';
									|tr = '%1 iş kolu atamaları'");
		LabelTitle = StrTemplate(SubstitutionString, CurrentFilters.LineOfBusiness);
		
	ElsIf ValueIsFilled(CurrentFilters.Contract) Then
		
		SubstitutionString = NStr("vi = 'Chỉ định theo hợp đồng %1';
									|ru = 'Назначения по договору %1';
									|en = 'Assignments under the contract %1'; fa = 'Assignments under the contract %1';
									|it = 'Destinazioni secondo l''accordo %1';
									|pl = 'Przeznaczenia wg umowy %1';
									|tr = '%1 sözleşmesine göre atamalar'");
		LabelTitle = StrTemplate(SubstitutionString, CurrentFilters.Contract);
		
	ElsIf ValueIsFilled(CurrentFilters.Partner) Then
		
		If CurrentFilters.AssignmentTypes.Find(Enums.AssignmentTypes.Own) <> Undefined Then
			SubstitutionString = NStr("vi = 'Chỉ định bên nhận gia công %1';
										|ru = 'Назначения переработчика %1';
										|en = 'Subcontractor assignments %1'; fa = 'Subcontractor assignments %1';
										|it = 'Destinazioni del subfornitore %1';
										|pl = 'Przeznaczenia przetwórcy %1';
										|tr = '%1 fason üretici atamaları'");
		Else
			SubstitutionString = NStr("vi = 'Chỉ định bên đặt gia công %1';
										|ru = 'Назначения давальца %1';
										|en = 'Assignments of the %1 material provider'; fa = 'Assignments of the %1 material provider';
										|it = 'Destinazioni del datore %1';
										|pl = 'Przeznaczenia właściciela surowca %1';
										|tr = '%1 tedarikçi atamaları'");
		EndIf;
		LabelTitle = StrTemplate(SubstitutionString, CurrentFilters.Partner);
		
	EndIf;
	If ValueIsFilled(CurrentFilters.Document) Then
		
		SubstitutionString = NStr("vi = 'Theo dữ liệu chứng từ %1';
									|ru = 'по данным документа %1';
									|en = 'by document data %1'; fa = 'by document data %1';
									|it = 'secondo i dati del documento %1';
									|pl = 'wg danych dokumentu %1';
									|tr = '%1 belgesi verilerine göre'");
		LabelTitle = ?(IsBlankString(LabelTitle), NStr("vi = 'Mục đích';
														|ru = 'Назначения';
														|en = 'Assignments'; fa = 'تخصیص‌ها';
														|it = 'Di destinazioni';
														|pl = 'Przeznaczenia';
														|tr = 'Atamalar'"), LabelTitle)
			+ " " + StrTemplate(SubstitutionString, CurrentFilters.Document);
		
	EndIf;
	
	Items.LabelSelectedAssignments.Visible = Not IsBlankString(LabelTitle);
	Items.LabelSelectedAssignments.Title = LabelTitle;

EndProcedure

&AtServer
Procedure ColumnsInMarkedWhenChangedListOnServer()
	
	SetTextAndParametersForDynamicListRequest();
	
	CustomizeForm();
	
EndProcedure

&AtServer
Procedure ClearTemplateOfUnusedParameters()
	
	NumberOfIndexes = AssignmentFormTemplate.ColumnDescriptions.Count() - 1;
	
	For IndexOf = 0 To NumberOfIndexes Do
		
		CurrentIndex = NumberOfIndexes - IndexOf;
		DescriptionOfColumns = AssignmentFormTemplate.ColumnDescriptions[CurrentIndex];
		If DescriptionOfColumns.PathToTheDestinationField <> Parameters.PathToTheDestinationField Then
			AssignmentFormTemplate.ColumnDescriptions.Delete(CurrentIndex);
		EndIf;
		
	EndDo;
	
EndProcedure

// Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
&AtServer
Function AssignmentFormTemplate()
    Return AssignmentFormTemplate;
EndFunction

#EndRegion
