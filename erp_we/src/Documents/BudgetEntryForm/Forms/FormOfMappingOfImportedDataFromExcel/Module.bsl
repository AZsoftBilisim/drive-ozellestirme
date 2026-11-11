
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	ResultAddress = Parameters.ResultAddress;
	TableID = Parameters.TableID;
	
	BudgetInstanceParameters = GetFromTempStorage(Parameters.BudgetProfileDisplayParameters);
	TableColumns = BudgetInstanceParameters.TableColumns;
	
	// columns of the current table
	ColumnStructure1 = TableColumns[Parameters.TableID];
	ColumnsByDimension = Parameters.ColumnsByDimension;
	
	ItemsToAdd1 = New Array;
	ColumnsToAdd = New Array;
	Documents.BudgetEntryForm.CalculateBudgetListItemsToAdd(ItemsToAdd1,
		ColumnsToAdd,
		ColumnsByDimension);
	
	// structure with field keys of the current column
	StructureAnalogDecryption = New Structure;
	ParametersForAddingColumns = Documents.BudgetEntryForm.TemplateForParametersForAddingColumnsToBudgetList();
	ParametersForAddingColumns.ItemsToAdd1 = ItemsToAdd1;
	ParametersForAddingColumns.ColumnsToAdd = ColumnsToAdd;
	ParametersForAddingColumns.ColumnsByDimension = ColumnsByDimension;
	ParametersForAddingColumns.ColumnStructure1 = ColumnStructure1;
	ParametersForAddingColumns.StructureAnalogDecryption = StructureAnalogDecryption;
	Documents.BudgetEntryForm.AddBudgetListColumnsByTable(ParametersForAddingColumns);
		
	Documents.BudgetEntryForm.ReflectChangesToBudgetListColumnsOnForm(ThisObject, ItemsToAdd1, ColumnsToAdd);
	
	EditedListColumns = StrConcat(ColumnsByDimension.Dimensions, ",");
	
	MaximumNumberOfColumns = ColumnsByDimension.Dimensions.Count() + StructureAnalogDecryption.Count();
	DataFileAddress = Parameters.DataFileAddress;
	FileExtention  = Parameters.FileExtention;
	ArrayOfValues   = ArrayOfFileValuesToUpload(DataFileAddress, FileExtention, MaximumNumberOfColumns);
	
	TreeDepth = BudgetReportingDisplayServer.TreeDepth(ColumnStructure1.Rows) + 1;
	
	MatchingValueIndices = New Map;
	
	For String = TreeDepth To ArrayOfValues[0].UBound() Do
		
		Column = 0;
		NewRow = BudgetEditList.Add();
		
		MappingStructure = New Structure;
		
		For Each Dimension In ColumnsByDimension.Dimensions Do
			If Column > ArrayOfValues.UBound() Then
				Value = Undefined;
			Else
				Value = ArrayOfValues[Column][String];
			EndIf;
			
			MappingStructure.Insert(Dimension, Value);
			
			Column = Column + 1;
		EndDo;
		
		NewRow.RowIndex = BudgetEditList.IndexOf(NewRow);
		MatchingValueIndices.Insert(NewRow.RowIndex, MappingStructure);
		
		For Each KeyAndValue In StructureAnalogDecryption Do
			If Column > ArrayOfValues.UBound() Then
				NewRow[KeyAndValue.Key] = Undefined;
			EndIf;
			
			Value = ArrayOfValues[Column][String];
			If KeyAndValue.Value.Property("IndicatorName") And KeyAndValue.Value.IndicatorName = "Value"
				And ColumnsByDimension.ColumnSettings.TypesOfMetricValues.Get(KeyAndValue.Value.Column)
				= "VATRate" Then
				NewRow[KeyAndValue.Key] = Catalogs.VATRates.FindByDescription(Value, True);
			Else
				NewRow[KeyAndValue.Key] = Value;
			EndIf;
			
			Column = Column + 1;
		EndDo;
		
	EndDo;
	
	CompareDownloadDataWithInformationSecurityData(ColumnsByDimension, MatchingValueIndices);
	
	LoadingElements = New Array; // Array of FormAttribute -
	ElementAddresses = New Structure;
	For Cnt = 0 To ColumnsByDimension.Dimensions.UBound() Do
		
		DimensionName = ColumnsByDimension.Dimensions[Cnt];
		ParametersForCreatingInputList =
			ColumnsByDimension.ColumnSettings[DimensionName].ParametersForCreatingInputList;
		ItemParameters = Documents.BudgetEntryForm.ParametersOfValueEntryElementInUserSLanguage(
			ParametersForCreatingInputList);
		Item = New FormAttribute("DownloadValue_" + DimensionName,
				New TypeDescription("String"),,
				ItemParameters.Title);
		LoadingElements.Add(Item);
		ElementAddresses.Insert("DownloadValue_" + DimensionName, "Group" + (Cnt % 3))
		
	EndDo;
	
	ChangeAttributes(LoadingElements);
	For Each Item In LoadingElements Do
		Address = ElementAddresses[Item.Name];
		FormItem = Items.Add(Item.Name, Type("FormField"), Items[Address]);
		FormItem.DataPath = Item.Name;
		FormItem.Border = New Border(ControlBorderType.Single, 1);
	EndDo;
	
	AddressOfImportCompliance = PutToTempStorage(MatchingValueIndices, UUID);
	
	ColumnNamePeriod = Undefined;
	For Each Dimension In ColumnsByDimension.Dimensions Do
		
		If BudgetReportingClientServer.ThisIsPeriodField(Dimension) Then
			ColumnNamePeriod = Dimension;
		EndIf;
		
	EndDo;
	
	If ColumnNamePeriod = Undefined Then
		PeriodDoesNotCorrespondToTheBudgetPeriod = False;
	Else
		PeriodsList = BudgetEditList.Unload(,ColumnNamePeriod);
		PeriodsList.GroupBy(ColumnNamePeriod);
		PeriodsList.Sort(ColumnNamePeriod);
		If PeriodsList.Count() Then
			MinimumPeriod = PeriodsList[0][ColumnNamePeriod];
			MaximumPeriod = PeriodsList[PeriodsList.Count() - 1][ColumnNamePeriod];
			If Not (MinimumPeriod >= Parameters.BeginOfPeriod
					And MaximumPeriod <= Parameters.PeriodEnding) Then
				PeriodDoesNotCorrespondToTheBudgetPeriod = True;
				ImportedDataPeriod = NStr("vi = 'Kỳ dữ liệu kết nhập (%1) không tương ứng với kỳ ngân sách (%2).
													|Sẽ không kết nhập các dòng có kỳ không thuộc kỳ ngân sách.
													|Tiếp tục?';
													|ru = 'Период загружаемых данных (%1) не соответствует периоду бюджета (%2).
													|Строки, период которых не входит в период бюджета загружены не будут.
													|Продолжить?';
													|en = 'Imported data period (%1) does not correspond to budget period (%2).
													|Lines whose period is not included in the budget period will not be imported.
													|Continue?'; fa = 'Imported data period (%1) does not correspond to budget period (%2).
													|Lines whose period is not included in the budget period will not be imported.
													|Continue?';
													|it = 'Il periodo dei dati in caricamento (%1) non corrisponde al periodo del budget (%2). 
													|Le righe con il periodo che non fa parte del periodo del budget non verranno scaricate.
													|Continuare?';
													|pl = 'Okres pobieranych danych (%1) nie odpowiada okresowi budżetu (%2).
													|Wiersze, których okres nie został uwzględniony w okresie budżetowym, nie zostaną pobrane.
													|Kontynuować?';
													|tr = 'İndirilen verilerin dönemi (%1) bütçe dönemi ile uyuşmuyor (%2).
													|Dönemleri bütçe dönemine girilmeyen satırlar indirilmeyecek.
													|Devam edilsin mi?'");
				
				ImportedDataPeriod = StringFunctionsClientServer.SubstituteParametersToString(
					ImportedDataPeriod,
					Format(MinimumPeriod, "DLF=D") + "-" + Format(MaximumPeriod, "DLF=D"),
					Format(Parameters.BeginOfPeriod, "DLF=D") + "-" + Format(Parameters.PeriodEnding, "DLF=D"));
			EndIf;
		EndIf;
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If PeriodDoesNotCorrespondToTheBudgetPeriod Then
		AttachIdleHandler("ShowPeriodDiscrepancyIssue", 0.2, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure LineDisplayOptionOnChange(Item)
	
	Items.BudgetEditList.RowFilter = Undefined;
	
	If LineDisplayOption = 1 Then
		Items.BudgetEditList.RowFilter = New FixedStructure("ToImport", False);
	EndIf;
	
EndProcedure

&AtClient
Procedure BudgetEditListToImportOnChange(Item)
	
	CurrentData = Items.BudgetEditList.CurrentData;
	
	If CurrentData.ToImport Then
		Columns = StringFunctionsClientServer.SplitStringIntoSubstringsArray(EditedListColumns);
		For Each Dimension In Columns Do
			ChoiceList = Items[Dimension].ChoiceList;
			If Not ChoiceList.Count() Then
				Continue;
			EndIf;
			
			If ChoiceList.FindByValue(CurrentData[Dimension]) = Undefined Then
				FormItem = Items[Dimension]; // FormField -
				CurrentData.ToImport = False;
				WarningText = NStr("vi = 'Trong cột ""%1"" chưa chọn đúng giá trị';
									|ru = 'В колонке ""%1"" выбрано неверное значение';
									|en = 'Incorrect value is selected in column ""%1""'; fa = 'Incorrect value is selected in column ""%1""';
									|it = 'Nella colonna ""%1"" è stato selezionato un valore errato';
									|pl = 'Wybrano nieprawidłową wartość w kolumnie ""%1""';
									|tr = 'Sütun ""%1"" de yanlış değer seçili'");
				WarningText = StringFunctionsClientServer.SubstituteParametersToString(WarningText, FormItem.Title);
				ShowMessageBox(, WarningText);
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	ConfigureStringDisplayOptions();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersBudgetEditList

&AtClient
Procedure BudgetEditListOnActivateRow(Item)
	
	CurrentData = Item.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	FieldsStructure = GetFromTempStorage(AddressOfImportCompliance)[CurrentData.RowIndex];
	
	For Each KeyAndValue In FieldsStructure Do
		ThisObject["DownloadValue_" + KeyAndValue.Key] = KeyAndValue.Value;
	EndDo;
	
EndProcedure

&AtClient
Procedure BudgetEditListAfterDeleteRow(Item)
	
	ConfigureStringDisplayOptions();
	
EndProcedure

&AtClient
Procedure BudgetEditListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CloseForms(Command)
	
	Close();
	
EndProcedure

&AtClient
Procedure MoveToDocument(Command)
	
	Filter = New Structure("ToImport", False);
	RowsWithUnmappedData = BudgetEditList.FindRows(Filter);
	
	Cancel = (RowsWithUnmappedData.Count() > 0);
	
	If Cancel Then
		MessageTemplate = NStr("vi = 'Không phải tất cả các hàng được khớp.';
								|ru = 'Не все строки сопоставлены';
								|en = 'Not all lines are mapped'; fa = 'Not all lines are mapped';
								|it = 'Non tutte le righe sono state mappate';
								|pl = 'Nie wszystkie wiersze zostały zestawione';
								|tr = 'Tüm satırlar eşleştirilmedi'");
		ShowMessageBox(, MessageTemplate);
		Return;
	EndIf;
	
	Close();
	PlaceDataInTemporaryStorageOnServer();
	NotifyChoice(ResultAddress);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

&AtClient
Procedure Attachable_BudgetEditingListMainColumnForChanges(Command)
	
	EditListWhenChangingOnServer();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ShowPeriodDiscrepancyIssue()
	
	ClosingNotification1 = New CallbackDescription("WhenOpeningFragment", ThisObject);
	ShowQueryBox(ClosingNotification1, ImportedDataPeriod, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure WhenOpeningFragment(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.No Then
		Close();
	EndIf;

EndProcedure

&AtServer
Procedure EditListWhenChangingOnServer()
	
	MatchingValueIndices = GetFromTempStorage(AddressOfImportCompliance);
	
	ColumnsArray1 = StringFunctionsClientServer.SplitStringIntoSubstringsArray(EditedListColumns);
	Column = Items.BudgetEditList.CurrentItem.Name;
	String = Items.BudgetEditList.CurrentRow;
	If ColumnsArray1.Find(Column) = Undefined Then
		Return;
	EndIf;
	
	LoadingString = BudgetEditList[String];
	MappingStructure = MatchingValueIndices[LoadingString.RowIndex];
	SearchName = MappingStructure[Column];
	
	For Each ListLine In BudgetEditList Do
		If LoadingString = ListLine Then
			Continue;
		EndIf;
		MappingStructure = MatchingValueIndices[ListLine.RowIndex];
		If Not ValueIsFilled(MappingStructure[Column]) Then
			Continue;
		EndIf;
		If MappingStructure[Column] = SearchName Then
			ListLine[Column] = LoadingString[Column];
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure CompareDownloadDataWithInformationSecurityData(ColumnsByDimension, MatchingValueIndices)
	
	Dimensions = ColumnsByDimension.Dimensions;
	ColumnSettings = ColumnsByDimension.ColumnSettings;
	
	ValueSearchSettingsTable = New ValueTable;
	ValueSearchSettingsTable.Columns.Add("SearchString", New TypeDescription("String",, New StringQualifiers(1024)));
	ValueSearchSettingsTable.Columns.Add("Type");
	
	For Each LoadingString In BudgetEditList Do
		
		LoadingString.ToImport = True;
		
		MappingStructure = MatchingValueIndices[LoadingString.RowIndex];
		For Each Dimension In Dimensions Do
			
			DownloadableAnalytics = MappingStructure[Dimension];
			
			If Not ValueIsFilled(DownloadableAnalytics) Then
				Continue;
			EndIf;
			
			For Each Type In ColumnSettings[Dimension].ValueType.Types() Do
				If Type = Type("Date") Then
					Continue;
				EndIf;
				NewRow = ValueSearchSettingsTable.Add();
				NewRow.SearchString = TrimAll(DownloadableAnalytics);
				NewRow.Type = Type;
			EndDo;
			
		EndDo;
		
	EndDo;
	
	DifferentTypes = CommonClientServer.CollapseArray(ValueSearchSettingsTable.UnloadColumn("Type"));
	
	TextOfTemporaryTables = "";
	SelectionText = "";
	Query = New Query;
	
	For Each Type In DifferentTypes Do
		
		DifferentNames = ValueSearchSettingsTable.Copy(New Structure("Type", Type));
		DifferentNames.GroupBy("SearchString");
		
		ObjectMetadata = Metadata.FindByType(Type); // MetadataObjectCatalog, MetadataObjectDocument -
		FullName = ObjectMetadata.FullName();
		TempTableName = "Filter_" + StrReplace(FullName, ".", "");
		
		Separator = "
		|;
		|
		|///////////////////////////////////////////////////////////////
		|";
		
		TemporaryTableText = "SELECT
		|	SearchTable.SearchString AS SearchString
		|INTO #TempTableName
		|FROM
		|	&TempTableName AS SearchTable";
		
		TemporaryTableText = StrReplace(TemporaryTableText, "#TempTableName", TempTableName);
		TemporaryTableText = StrReplace(TemporaryTableText, "&TempTableName", "&" + TempTableName);
		
		TextOfTemporaryTables = TextOfTemporaryTables + TemporaryTableText + Separator;
		
		Query.SetParameter(TempTableName, DifferentNames);
		
		If Not Documents.AllRefsType().ContainsType(Type) Then
			FieldArray = CommonClientServer.ValueInArray("Description");
		Else
			FieldArray = CommonClientServer.ValueInArray("Number");
		EndIf;
		If ObjectMetadata.Attributes.Find("DescriptionFull") <> Undefined Then
			FieldArray.Add("DescriptionFull");
		EndIf;
		
		For Each Field In ObjectMetadata.InputByString Do
			If FieldArray.Find(Field.Name) = Undefined Then
				FieldArray.Add(Field.Name);
			EndIf;
		EndDo;
		
		For Each Field In FieldArray Do
			
			MergeText = "
			|
			|UNION ALL
			|
			|";
			
			TableText = "SELECT
			|	FilterTable_.SearchString AS SearchString,
			|	Table.Ref AS Ref,
			|	&TableField_ AS Description
			|FROM
			|	&TempTableName AS FilterTable_
			|		INNER JOIN #FullTableName AS Table
			|		ON (&TableField_ = FilterTable_.SearchString)";		
			
			For Cnt = 0 To ObjectMetadata.StandardAttributes.Count()-1 Do
				If ObjectMetadata.StandardAttributes[Cnt].Name = "IsFolder" Then
					TableText = TableText + "
					|	AND NOT Table.IsFolder";
					Break;
				EndIf;
			EndDo;
			
			TableText = StrReplace(TableText, "&TableField_", "Table." + Field);
			TableText = StrReplace(TableText, "&TempTableName", TempTableName);
			TableText = StrReplace(TableText, "#FullTableName", FullName);
			
			SelectionText = SelectionText + ?(ValueIsFilled(SelectionText), MergeText, "") + TableText; 
			
		EndDo;
	
	EndDo;
	
	QueryText = TextOfTemporaryTables + SelectionText;
	If Not IsBlankString(QueryText) Then
		Query.Text = QueryText;
		SearchResult = Query.Execute().Unload();
	Else
		SearchResult = New ValueTable;
		SearchResult.Columns.Add("SearchString");
		SearchResult.Columns.Add("Ref");
		SearchResult.Columns.Add("Description");
	EndIf;
	SearchResult.Indexes.Add("SearchString");
	
	For Each LoadingString In BudgetEditList Do
		
		LoadingString.ToImport = True;
		
		MappingStructure = MatchingValueIndices[LoadingString.RowIndex];
		For Each Dimension In Dimensions Do
			
			DownloadableAnalytics = MappingStructure[Dimension];
			
			If Not ValueIsFilled(DownloadableAnalytics) Then
				Continue;
			EndIf;
			
			If BudgetReportingClientServer.ThisIsPeriodField(Dimension) Then
				LoadingString[Dimension] = DownloadableAnalytics;
				Continue;
			EndIf;
			
			SearchKey = TrimAll(DownloadableAnalytics);
			
			FoundItems1 = SearchResult.FindRows(New Structure("SearchString", SearchKey));
			TableOfSuitableNames = New ValueTable;
			TableOfSuitableNames.Columns.Add("Ref");
			TableOfSuitableNames.Columns.Add("ConditionalSimilarityPercentage");
			
			NameYouAreLookingFor = TrimAll(DownloadableAnalytics);
			For Each FoundRow In FoundItems1 Do
				
				If Items[Dimension].ChoiceList.Count() Then
					ChoiceList = Items[Dimension].ChoiceList;
					If ChoiceList.FindByValue(FoundRow.Ref) = Undefined Then
						Continue;
					EndIf;
				EndIf;
				
				NewRow = TableOfSuitableNames.Add();
				NewRow.Ref = FoundRow.Ref;
				
				ComparisonString = TrimAll(FoundRow.Description);
				If ComparisonString = NameYouAreLookingFor Then
					NewRow.ConditionalSimilarityPercentage = 100;
					Continue;
				EndIf;
				
				If Not StrLen(ComparisonString) Then
					Continue;
				EndIf;
				
				NewRow.ConditionalSimilarityPercentage = StrLen(NameYouAreLookingFor) / StrLen(ComparisonString) * 100;
				
				If BudgetReportingClientServer.LeftPartOfNameMatches(ComparisonString, NameYouAreLookingFor) Then
					NewRow.ConditionalSimilarityPercentage = Min(NewRow.ConditionalSimilarityPercentage + 10, 99);
				EndIf;
			EndDo;
			
			TableOfSuitableNames.Sort("ConditionalSimilarityPercentage DESC");
			If TableOfSuitableNames.Count()
				And TableOfSuitableNames[0].ConditionalSimilarityPercentage > 70 Then
				
				LoadingString[Dimension] = TableOfSuitableNames[0].Ref;
				Continue;
				
			EndIf;
			
			LoadingString.ToImport = False;
			
		EndDo;
		
	EndDo;
	
	ConfigureStringDisplayOptions();
	
EndProcedure

&AtServer
Procedure ConfigureStringDisplayOptions()
	
	ChoiceList = Items.LineDisplayOption.ChoiceList;
	ChoiceList.Clear();
	
	Presentation = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Tất cả (%1)';
			|ru = 'Все (%1)';
			|en = 'All (%1)'; fa = 'All (%1)';
			|it = 'Tutti (%1)';
			|pl = 'Wszytskie (%1)';
			|tr = 'Tümü (%1)'"), 
		BudgetEditList.Count());
		
	ChoiceList.Add(0, Presentation); 
	
	RowsHaveUnmappedData = BudgetEditList.FindRows(New Structure("ToImport", False));
	Presentation = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Chưa so sánh (%1)';
			|ru = 'Несопоставленные (%1)';
			|en = 'Unmapped (%1)'; fa = 'Unmapped (%1)';
			|it = 'Non mappati (%1)';
			|pl = 'Niedopasowane (%1)';
			|tr = 'Eşleşmeyenler (%1)'"), 
		RowsHaveUnmappedData.Count());
		
	ChoiceList.Add(1, Presentation);
	
EndProcedure

&AtClient
Procedure SelectAllCommand(Command)
	
	For Each LoadingString In BudgetEditList Do
		LoadingString.ToImport = True;
	EndDo;
	
	ConfigureStringDisplayOptions();
	
EndProcedure

&AtClient
Procedure ClearAllIetmsCommand(Command)
	
	For Each LoadingString In BudgetEditList Do
		LoadingString.ToImport = False;
	EndDo;
	
	ConfigureStringDisplayOptions();
	
EndProcedure

&AtServer
Procedure PlaceDataInTemporaryStorageOnServer()
	
	Table = BudgetEditList.Unload();
	ConvolutionString = "";
	SummationString = "";
	For Each Column In Table.Columns Do
		If StrFind(Column.Name, "Note") Then
			Continue;
		EndIf;
		If StrFind(EditedListColumns, Column.Name) Then
			ConvolutionString = ConvolutionString + ?(IsBlankString(ConvolutionString), "", ",") + Column.Name;
		Else
			SummationString = SummationString + ?(IsBlankString(SummationString), "", ",") + Column.Name;
		EndIf;
	EndDo;
	
	Table.GroupBy(ConvolutionString, SummationString);
	
	Result = New Structure("BudgetEditList,
								|TableID",
								Table,
								TableID);
	
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

&AtServerNoContext
Function ArrayOfFileValuesToUpload(DataFileAddress, FileExtention, NumberOfColumnsByBudgetStructure)
	
	ArrayOfValues = New Array; // Array of Array -
	For ColumnNumber = 1 To NumberOfColumnsByBudgetStructure Do
		ArrayOfValues.Add(New Array);
	EndDo;
	
	TempFileName = GetTempFileName(FileExtention);
	BinaryData = GetFromTempStorage(DataFileAddress); // BinaryData -
	BinaryData.Write(TempFileName);
	BinaryData = Undefined;
	DeleteFromTempStorage(DataFileAddress);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	Try
		SpreadsheetDocument.Read(TempFileName, SpreadsheetDocumentValuesReadingMode.Value);
	Except
		ErrorText = NStr("vi = 'Không thể đọc tệp đã chọn do %1';
						|ru = 'Не удалось прочитать выбранный файл по причине %1';
						|en = 'Cannot read the file. Reason: %1'; fa = 'Cannot read the file. Reason: %1';
						|it = 'Non è stato possibile leggere il file selezionato a causa di %1';
						|pl = 'Nie udało się odczytać wybrany plik z powodu%1';
						|tr = 'Seçilen dosya %1 sebebinden dolayı okunamadı'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorText,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
		Common.MessageToUser(ErrorText);
		Return ArrayOfValues;
	EndTry;
	
	FirstColumnNumber = 0;
	FirstRowNumber = 0;
	
	MaximumNumberOfEmptyColumns = 10;
	MaximumNumberOfEmptyLines   = 10;
	
	// Search for the first filled cell from the upper-left corner.
	CurrentRowNumber1 = 0;
	EmptyLines = 0;
	While FirstRowNumber = 0 Do
		If EmptyLines >= MaximumNumberOfEmptyLines Then
			Break;
		EndIf;
		
		EmptyColumns = 0;
		CurrentRowNumber1 = CurrentRowNumber1 + 1;
		CurrentColumnNumber1 = 0;
		
		While FirstRowNumber = 0 Do
			If EmptyColumns >= MaximumNumberOfEmptyColumns Then
				Break;
			EndIf;
			
			CurrentColumnNumber1 = CurrentColumnNumber1 + 1;
			
			AreaName = StringFunctionsClientServer.SubstituteParametersToString(
				"R%1C%2",
				Format(CurrentRowNumber1, "NZ=0; NG=0"),
				Format(CurrentColumnNumber1, "NZ=0; NG=0"));
			Value = SpreadsheetDocument.Area(AreaName).Text;
			If Not ValueIsFilled(Value) Then
				EmptyColumns = EmptyColumns + 1;
				Continue;
			Else
				If FirstColumnNumber = 0 Then
					FirstColumnNumber = CurrentColumnNumber1;
					FirstRowNumber  = CurrentRowNumber1;
					Break;
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	
	If Not FirstRowNumber = 0 Then
		// Search for the last line.
		// The number of readable columns is known.
		CurrentRowNumber1    = FirstRowNumber;
		
		EmptyLines = 0;
		
		While True Do
			
			ThereIsValueByLine = False;
			ValuesByLine = New Map;
			For IndexCurColumns = 0 To NumberOfColumnsByBudgetStructure-1 Do
				CurrentColumnNumber1 = FirstColumnNumber + IndexCurColumns;
				AreaName = StringFunctionsClientServer.SubstituteParametersToString(
					"R%1C%2",
					Format(CurrentRowNumber1, "NZ=0; NG=0"),
					Format(CurrentColumnNumber1, "NZ=0; NG=0"));
				Area = SpreadsheetDocument.Area(AreaName);
				Value = ?(Area.ContainsValue, Area.Value, Area.Text);
				If ValueIsFilled(Value) Then
					ThereIsValueByLine = True;
				EndIf;
				
				// Adding columns to the corresponding array.
				ValuesByLine.Insert(IndexCurColumns, Value);
			EndDo;
			
			If Not ThereIsValueByLine Then
				EmptyLines = EmptyLines + 1;
			Else
				EmptyLines = 0;
				For Each ColumnIndexAndValue In ValuesByLine Do
					ArrayOfValues[ColumnIndexAndValue.Key].Add(ColumnIndexAndValue.Value);
				EndDo;
			EndIf;
			
			If EmptyLines >= MaximumNumberOfEmptyLines Then
				Break;
			EndIf;
			
			CurrentRowNumber1 = CurrentRowNumber1 + 1;
			
		EndDo;
	EndIf;
	
	Try
		DeleteFiles(TempFileName);
	Except
		
		LanguageCode = Common.DefaultLanguageCode();
		LREvent = NStr("vi = 'Lập ngân sách';
						|ru = 'Бюджетирование';
						|en = 'Budgeting'; fa = 'بودجه‌بندی';
						|it = 'Budgeting';
						|pl = 'Budżetowanie';
						|tr = 'Bütçeleme'", LanguageCode) + "." + NStr("vi = 'Xóa tệp kết nhập dữ liệu tạm thời';
																		|ru = 'Удаление временного файла загрузки данных';
																		|en = 'Deleting temporary data import file'; fa = 'Deleting temporary data import file';
																		|it = 'Cancellazione del file temporaneo di importazione dati';
																		|pl = 'Usunięcie pliku tymczasowego pobierania danych';
																		|tr = 'Geçici veri içe aktarma dosyalarının silinmesi'", LanguageCode);
		ErrorText = NStr("vi = 'Không thể xóa tệp tải dữ liệu tạm thời do %1';
						|ru = 'Не удалось удалить временный файл загрузки данных по причине %1';
						|en = 'Cannot delete temporary data import file. Reason: %1'; fa = 'Cannot delete temporary data import file. Reason: %1';
						|it = 'Non è stato possibile eliminare il file temporaneo di caricamento dati a causa di %1';
						|pl = 'Nie udało się usunąć czasowy plik pobrania danych z powodu %1';
						|tr = 'Geçici içe aktarma dosyası %1 sebebiyle silinemedi'", LanguageCode);
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorText,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		WriteLogEvent(LREvent, EventLogLevel.Error, , , ErrorText);
	EndTry;
	
	Return ArrayOfValues;
	
EndFunction

#EndRegion
