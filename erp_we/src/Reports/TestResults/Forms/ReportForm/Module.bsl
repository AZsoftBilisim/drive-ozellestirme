#Region Private

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If ValueIsFilled(Parameters.PathToFile) Then
		Items.FileName.Visible = False;
		Report.StorageAddress = Parameters.PathToFile;
		InitializeLayout();
		Items.FieldSettingsGroup.Visible = Items.CustomField.ChoiceList.Count() > 1;
		Items.FilerByRegister.Visible = Items.FilerByRegister.ChoiceList.Count() > 1;
	EndIf;
EndProcedure

&AtClient
Procedure FileNameStartChoice(Item, ChoiceData, StandardProcessing)
	FileDialog = New FileDialog(FileDialogMode.Open);
	
	FileDialog.Filter = NStr("vi = 'Tệp kết quả so sánh (* .xml; *. Txt) | * .xml; *. Txt';
							|ru = 'Файл результатов сравнения (*.xml;*.txt)|*.xml;*.txt';
							|en = 'Comparison result file (*.xml;*.txt)|*.xml;*.txt'; fa = 'Comparison result file (*.xml;*.txt)|*.xml;*.txt';
							|it = 'File dei risultati di comparazione (*.xml;*.txt)|*.xml;*.txt';
							|pl = 'Plik wyników porównania (*.xml;*.txt)|*.xml;*.txt';
							|tr = 'Karşılaştırma sonuçları dosyası (*.xml;*.txt)|*.xml;*.txt'");
	
	FileDialog.Title = Title;
	FileDialog.Preview = False;
	FileDialog.DefaultExt = "xml";
	FileDialog.FilterIndex = 0;
	FileDialog.FullFileName = Item.EditText;
	FileDialog.CheckFileExistence = False;
	
	CallbackDescription = New CallbackDescription("FileNameCompletionOfSelection", ThisObject);
	FileDialog.Show(CallbackDescription);
	
EndProcedure

&AtClient
Procedure FileNameCompletionOfSelection(SelectedFiles, AdditionalParameters) Export
	If SelectedFiles <> Undefined Then
		FullFileName = SelectedFiles[0];
		CallbackDescription = New CallbackDescription(
			"AfterPutFile", ThisObject);
		BeginPutFile(CallbackDescription,,
			FullFileName,  False,
			UUID);
	EndIf;
EndProcedure

&AtClient
Procedure AfterPutFile(Result, Address, SelectedFileName, AdditionalParameters) Export  
	
	Report.StorageAddress = Address;
	InitializeLayout();
	FileName = SelectedFileName;
	Items.FieldSettingsGroup.Visible = Items.CustomField.ChoiceList.Count() > 1;
	Items.FilerByRegister.Visible = Items.FilerByRegister.ChoiceList.Count() > 1;
	
EndProcedure

&AtServer
Procedure InitializeLayout()
	
	DataCompositionSchema = New DataCompositionSchema;
	SettingsComposer = Report.SettingsComposer;
	
	Source = DataCompositionSchema.DataSources.Add();
	Source.Name = "LocalDatabase";
	Source.ConnectionString = "";
	Source.DataSourceType = "Local";
	
	DataCompositionSettings = DataCompositionSchema.DefaultSettings;
	ExternalDataSets = New Structure();
	
	PathToFile = GetTempFileName("xml");
	
	ReportFile = GetFromTempStorage(Report.StorageAddress);  // BinaryData
	ReportFile.Write(PathToFile);
	Read = New XMLReader;
	Read.OpenFile(PathToFile);
	ObjectName = Undefined;
	
	RecorderDocuments = New ValueTable;
	RecorderDocuments.Columns.Add("DocumentRecorder");
	
	CustomFields = New Structure;
	
	While Read.Read() Do
		If ValueIsFilled(Read.Value) Then
			Try
				ReadingValue = Common.ValueFromXMLString(Read.Value);
			Except
				Continue;
			EndTry;
			If (Read.NamespaceContext.Depth = 3 Or Read.NamespaceContext.Depth = 4) And TypeOf(ReadingValue) = Type("String") Then // this is a metadata object, we form a grouping and a table based on it.
				MetadataObject = ReadingValue;
				MetadataCollection = Metadata.FindByFullName(MetadataObject);
				RecorderFieldName = Testing.NameOfRegisterRegistrarField(MetadataCollection);
				If Testing.RegistersWithServiceRegistrar().Find(MetadataObject) <> Undefined Then
					RecorderFieldName = "DocumentRecorder";
				ElsIf Metadata.InformationRegisters.Contains(MetadataCollection) 
					And MetadataCollection.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.Independent Then
					RecorderFieldName = "Lot";
				EndIf;
				ArrayOfObjectStrings = StringFunctionsClientServer.SplitStringIntoSubstringsArray(MetadataObject, ".");
				ObjectName = ArrayOfObjectStrings.Get(1);
				
				If DataCompositionSchema.DataSets.Find(ObjectName) <> Undefined Then // already added to the scheme
					DataSet = DataCompositionSchema.DataSets[ObjectName];
					Continue;
				EndIf;
				
				// each metadata object is a new separate data set for the SCD.
				DataSet = DataCompositionSchema.DataSets.Add(Type("DataCompositionSchemaDataSetObject"));
				DataSet.Name = ObjectName;
				DataSet.ObjectName = ObjectName;
				DataSet.DataSource = "LocalDatabase";
				
				// grouping tables by metadata objects: one object is one table.
				Table = DataCompositionSettings.Structure.Add(Type("DataCompositionTable"));
				Table.Name = ObjectName;
				
				DataCompositionSettings.OutputParameters.SetParameterValue("ResourcesAutoPosition", DataCompositionResourcesAutoPosition.DontUse);
				TableHeading = Table.OutputParameters.FindParameterValue(New DataCompositionParameter("Title"));
				If TableHeading <> Undefined Then
					TableHeading.Value = "Table: " + MetadataObject;
					TableHeading.Use = True;
				EndIf;
				
				Rows = Table.Rows.Add();
				Rows.OutputParameters.SetParameterValue("ResourcesAutoPosition", DataCompositionResourcesAutoPosition.DontUse);
				
				FieldDimensionLogger = Rows.Selection.Items.Add(Type("DataCompositionSelectedField"));
				FieldDimensionLogger.Field = New DataCompositionField(ObjectName + "_" + RecorderFieldName);
				FieldDimensionLogger.Use = True;
				
				LoggerGrouping = Rows.GroupFields.Items.Add(Type("DataCompositionGroupField"));
				LoggerGrouping.Field = New DataCompositionField(ObjectName + "_" + RecorderFieldName);
				LoggerGrouping.Use = True;
				
				DeltaGrouping = Rows.Structure.Add();
				
				LoggerSelectionField = DeltaGrouping.Selection.Items.Add(Type("DataCompositionSelectedField"));
				LoggerSelectionField.Field = New DataCompositionField(ObjectName + "_" + RecorderFieldName);
				LoggerSelectionField.Use = True;
				
				DeltaDimensionField = DeltaGrouping.GroupFields.Items.Add(Type("DataCompositionGroupField"));
				DeltaDimensionField.Field = New DataCompositionField(ObjectName + "_" + RecorderFieldName);
				DeltaDimensionField.Use = True;
				// we will define the grouping fields later
				
				DetailedRecords = DeltaGrouping.Structure.Add();
				DetailedRecords.Name = DeltaGrouping.Name + "_DetailedRecords";
				DetailedRecords.Use = True;
				// we will define the grouping fields later
				
			ElsIf (Read.NamespaceContext.Depth = 4 Or Read.NamespaceContext.Depth = 5) And ObjectName <> Undefined And TypeOf(ReadingValue) = Type("ValueTable") Then // these are records, we output them to the table.
				
				Set = ReadingValue;
				If Set.Columns.Find("Recorder") = Undefined Then
					Set.Columns.Add("Recorder");
				EndIf;
				
				For Each Column In Set.Columns Do
					
					FieldName = "" + ObjectName + "_" + Column.Name;
					
					If DataSet.Fields.Find(FieldName) <> Undefined Then // already there in the scheme, no need to add
						Continue;
					EndIf;
					
					Field             = DataSet.Fields.Add(Type("DataCompositionSchemaDataSetField"));
					Field.Title   = Column.Name;
					Field.Field        = Column.Name;
					Field.DataPath = FieldName;
					Field.ValueType = Column.ValueType;
					
					MaxWidth = Field.Appearance.FindParameterValue(New DataCompositionParameter("MaxWidth"));
					If MaxWidth <> Undefined Then
						MaxWidth.Value = 15;
						MaxWidth.Use = True;
					EndIf;
					
					If Column.ValueType.ContainsType(Type("Number")) Then // we create a calculated field and calculate the delta of old and new records.
						
						CalculatedDataPathField = ObjectName + "_Calculated_" + Column.Name;
						If DataCompositionSchema.CalculatedFields.Find(CalculatedDataPathField) <> Undefined Then
							Continue;
						EndIf;
						FieldToEval = DataCompositionSchema.CalculatedFields.Add();
						FieldToEval.DataPath = ObjectName + "_Calculated_" + Column.Name;
						Template = "CASE WHEN %MetadataObject%_TypeOfTestRecord = ""OriginalRecords"" THEN -%FieldName% ELSE %FieldName% END";
						FieldToEval.Expression = StrReplace(Template, "%FieldName%", FieldName);
						FieldToEval.Expression = StrReplace(FieldToEval.Expression, "%MetadataObject%", ObjectName);
						FieldToEval.ValueType = Column.ValueType;
						FieldToEval.Title = Column.Name;
						FieldToEval.Appearance.SetParameterValue("MarkNegatives", True);
						FieldToEval.Appearance.SetParameterValue("MaxWidth", 15);
						
						TotalField = DataCompositionSchema.TotalFields.Add();
						TotalField.DataPath = FieldToEval.DataPath;
						TotalField.Expression = "SUM(" + FieldToEval.DataPath + ")";
						TotalField.Groups.Add(ObjectName + "_" + RecorderFieldName);
						
						ValueField = DataCompositionSchema.TotalFields.Add();
						ValueField.DataPath = FieldToEval.DataPath;
						ValueField.Expression = FieldName;
						ValueField.Groups.Add(ObjectName + "_TypeOfTestRecord");
						
						FieldName = FieldToEval.DataPath;
						
						LoggerDimensionField = Rows.Selection.Items.Add(Type("DataCompositionSelectedField"));
						LoggerDimensionField.Field = New DataCompositionField(FieldName);
						
						DeltaDimensionField = DeltaGrouping.Selection.Items.Add(Type("DataCompositionSelectedField"));
						DeltaDimensionField.Field = New DataCompositionField(FieldName);
					Else
						
						// For each column, we determine how many times it occurs in divergences (for different data sets)
						// . We make available for configuration only those columns that occur in several sets (more than 1).
						If CustomFields.Property(Column.Name) Then
							CustomFields[Column.Name] = CustomFields[Column.Name] + 1;
						Else
							CustomFields.Insert(Column.Name, 1);
						EndIf;
						
						If Column.Name <> "TypeOfTestRecord" And Column.Name <> RecorderFieldName Then // add to the grouping by delta
							DeltaDimensionField = DeltaGrouping.GroupFields.Items.Add(Type("DataCompositionGroupField"));
							DeltaDimensionField.Field = New DataCompositionField(FieldName);
							DeltaDimensionField.Use = True;

							DeltaDimensionField = DeltaGrouping.Selection.Items.Add(Type("DataCompositionSelectedField"));
							DeltaDimensionField.Field = New DataCompositionField(FieldName);
						EndIf;
						If Column.Name <> RecorderFieldName Then // output to detailed records
							DetailedRecordsGroupingField = DetailedRecords.GroupFields.Items.Add(Type("DataCompositionGroupField"));
							DetailedRecordsGroupingField.Field = New DataCompositionField(FieldName);
							DetailedRecordsGroupingField.Use = True;
						EndIf;
					EndIf;
					If Column.Name <> RecorderFieldName And Column.Name <> "RegisterName" And Column.Name <> "FullRegisterName" Then // add to the grouping by delta
						DetailedRecordsGroupingField = DetailedRecords.Selection.Items.Add(Type("DataCompositionSelectedField"));
						DetailedRecordsGroupingField.Field = New DataCompositionField(FieldName);
					EndIf;
					If Column.Name <> "TypeOfTestRecord" Then 
						OrderField_ = DetailedRecords.Order.Items.Add(Type("DataCompositionOrderItem"));
						OrderField_.Field = New DataCompositionField(FieldName);
						OrderField_.Use = True;
						OrderField_.OrderType = DataCompositionSortDirection.Asc;
					EndIf;
				EndDo;
				ExternalDataSets.Insert(ObjectName, Set);
				CommonClientServer.SupplementTableFromArray(RecorderDocuments, Set.UnloadColumn(RecorderFieldName), "DocumentRecorder");
			EndIf;
		EndIf;
	EndDo;
		
	RecorderDocuments.GroupBy("DocumentRecorder");
	Report.RecorderDocuments.Load(RecorderDocuments);
	List = Items.FilterByRecorderDocument.ChoiceList;
	List.LoadValues(RecorderDocuments.UnloadColumn("DocumentRecorder"));
	For Each ListItem In List Do
		ListItem.Presentation = String(ListItem.Value);
	EndDo;
	
	Items.CustomField.ChoiceList.Clear();
	Items.CustomField.ChoiceList.Add("NoSettings", NStr("vi = 'Không có tùy chỉnh';
														|ru = 'Без настройки';
														|en = 'Not configured'; fa = 'پیکربندی نشده';
														|it = 'Senza impostazione';
														|pl = 'Bez ustawienia';
														|tr = 'Ayarsız'"));
	For Each StructureItem In CustomFields Do
		If StructureItem.Value > 1 Or DataCompositionSchema.DataSets.Count() = 1 Then
			Items.CustomField.ChoiceList.Add(StructureItem.Key);
		EndIf;
	EndDo;
	Report.CustomField = "NoSettings"; // we set the default value.
	
	Items.FilerByRegister.ChoiceList.Clear();
	If DataCompositionSchema.DataSets.Count() > 1 Then
		Items.FilerByRegister.ChoiceList.Add("NoFilter", NStr("vi = 'Không lọc';
																|ru = 'Без отбора';
																|en = 'No filter'; fa = 'بدون فیلتر';
																|it = 'Senza selezione';
																|pl = 'Brak selekcji';
																|tr = 'Filtresiz'"));
		For Each DataSet In DataCompositionSchema.DataSets Do
			Items.FilerByRegister.ChoiceList.Add(DataSet.Name);
		EndDo;
	Else
		Items.FilerByRegister.ChoiceList.Add("OneRegister", NStr("vi = 'Một biểu ghi';
																|ru = 'Один регистр';
																|en = 'One register'; fa = 'یک رجیستر';
																|it = 'Один регистр';
																|pl = 'One register';
																|tr = 'Tek kayıt'"));
	EndIf;
	Report.FilerByRegister = "NoFilter"; // we set the default value.
	
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(DataCompositionSchema));
	SettingsComposer.LoadSettings(DataCompositionSettings);
	
	Report.SettingsComposer = SettingsComposer;
	
	DataCompositionSettings = SettingsComposer.GetSettings();
	
	TemplateComposer = New DataCompositionTemplateComposer;
	Var_48_Template = TemplateComposer.Execute(DataCompositionSchema, DataCompositionSettings);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(Var_48_Template, ExternalDataSets);
	
	Read.Close(); // releasing the file
	DeleteFiles(PathToFile);
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, StandardProcessing)
	If Exit Then
		Return;
	EndIf;
	DeleteTemporaryFilesOnServer();
EndProcedure

&AtServer
Procedure DeleteTemporaryFilesOnServer()
	If ValueIsFilled(Report.PathToFile) Then
		DeleteFiles(Report.PathToFile);
	EndIf;
EndProcedure

&AtClient
Procedure ResultDetailProcessing(Item, Details, StandardProcessing, AdditionalParameters)
	StandardProcessing = False;
	DecryptionResult_ = ResultDetailProcessingServer(Details);
	
	MessageText = NStr("vi = 'Trình bày: %Presentation% || Giá trị: %Value% || Kiểu: %Type%';
						|ru = 'Представление: %Presentation% || Значение: %Value% || Тип: %Type%';
						|en = 'Presentation: %Presentation% || Value: %Value% || Type: %Type%'; fa = 'Presentation: %Presentation% || Value: %Value% || Type: %Type%';
						|it = 'Visualizzazione: %Presentation% || Valore: %Value% || Tipo: %Type%';
						|pl = 'Prezentacja: %Presentation% || Wartość: %Value% || Typ: %Type%';
						|tr = 'Sunum: %Presentation% || Değer: %Value% || Tip: %Type%'");
	MessageText = StrReplace(MessageText, "%Presentation%", String(DecryptionResult_.Value));
	MessageText = StrReplace(MessageText, "%Type%", String(TypeOf(DecryptionResult_.Value)));
	
	If DecryptionResult_.IsEnum Then
		MessageText = StrReplace(MessageText, "%Value%", DecryptionResult_.EnumerationValueName);
	ElsIf DecryptionResult_.IsReference Then
		MessageText = StrReplace(MessageText, "%Value%", String(DecryptionResult_.Value.UUID())); 
	Else
		MessageText = StrReplace(MessageText, "%Value%", String(DecryptionResult_.Value)); 
	EndIf;
	
	If DecryptionResult_.IsReference Then
		CommonClientServer.MessageToUser(MessageText,DecryptionResult_.Value);
		If ValueIsFilled(DecryptionResult_.Value) Then
			ShowValue(Undefined, DecryptionResult_.Value);
		EndIf;
	Else
		CommonClientServer.MessageToUser(MessageText);
	EndIf;
	
EndProcedure

&AtServer
Function ResultDetailProcessingServer(Details)
	DecryptingData = GetFromTempStorage(DetailsData); // DataCompositionDetailsData
	Value =  DecryptingData.Items[Details].GetFields()[0].Value;
	
	DecryptionResult_ = New Structure;
	
	IsReference = Common.IsReference(TypeOf(Value));
	DecryptionResult_.Insert("IsReference", IsReference);
	DecryptionResult_.Insert("Value", Value);
	
	If IsReference
		And Common.IsEnum(Value.Metadata()) Then
		DecryptionResult_.Insert("IsEnum", True);
		DecryptionResult_.Insert("EnumerationValueName", Common.EnumerationValueName(Value));
	Else
		DecryptionResult_.Insert("IsEnum", False);
		DecryptionResult_.Insert("EnumerationValueName","");
	EndIf;		
	
	Return DecryptionResult_;
EndFunction

&AtClient
Procedure FilterByRecorderDocumentAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) And ValueIsFilled(Item.ChoiceList) Then
		StandardProcessing = False;
		ChoiceData = New ValueList;
	
		For Each ListItem In Item.ChoiceList Do
			If StrFind(ListItem.Presentation, Text) Then
				ChoiceData.Add(ListItem.Value, ListItem.Presentation);
			EndIf;
		EndDo;
	EndIf;
		
EndProcedure

&AtClient
Procedure FilterByRecorderDocumentChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	Report.FilterByRecorderDocument = ValueSelected;
	
EndProcedure

&AtClient
Procedure FilterByRecorderDocumentClearing(Item, StandardProcessing)
	Report.FilterByRecorderDocument = Undefined;
EndProcedure

&AtClient
Procedure CustomFieldOnChange(Item)
	Items.FieldSetup.Visible = Report.CustomField <> "NoSettings";
EndProcedure

#EndRegion
