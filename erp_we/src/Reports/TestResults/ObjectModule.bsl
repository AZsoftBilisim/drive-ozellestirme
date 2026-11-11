#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	Var ObjectName;
	
	StandardProcessing = False;
	
	If Not ValueIsFilled(StorageAddress) Then
		Return;
	EndIf;
	
	DataCompositionSchema = New DataCompositionSchema;
		
	Source = DataCompositionSchema.DataSources.Add();
	Source.Name = "LocalDatabase";
	Source.ConnectionString = "";
	Source.DataSourceType = "Local";
	
	DataCompositionSettings = DataCompositionSchema.DefaultSettings;
	ExternalDataSets = New Structure();
	
	DDBuffer = GetBinaryDataBufferFromBinaryData(GetFromTempStorage(StorageAddress));
	Stream = New MemoryStream(DDBuffer);
	Read = New XMLReader;
	Read.OpenStream(Stream);
	
	RegistersWithServiceRegistrar = Testing.RegistersWithServiceRegistrar();
	ReportIsBlank = True;
	
	AdditionalSortingFields = New Array;
	AdditionalSortingFields.Add("RecordType");
	AdditionalSortingFields.Add("CalculationOfCost");
	AdditionalSortingFields.Add("LotCalculation");
	
	While Read.Read() Do
		
		If Not ValueIsFilled(Read.Value) Then
			Continue;
		EndIf;
		
		Try
			ReadingValue = Common.ValueFromXMLString(Read.Value);
		Except
			Continue;
		EndTry;
		
		If (Read.NamespaceContext.Depth = 3 Or Read.NamespaceContext.Depth = 4) And TypeOf(ReadingValue) = Type("String") Then // this is a metadata object, we form a grouping and a table based on it.
			
			MetadataObject = ReadingValue;
			ArrayOfObjectStrings = StringFunctionsClientServer.SplitStringIntoSubstringsArray(MetadataObject, ".");
			ObjectName = ArrayOfObjectStrings.Get(1);
			
			If FilerByRegister <> "OneRegister" And FilerByRegister <> "NoFilter" And FilerByRegister <> ObjectName Then
				Continue;
			EndIf;
			
			MetadataInQuestion = Metadata.FindByFullName(MetadataObject);
			ThereIsCustomField = ThereIsCustomField(MetadataInQuestion);
			
			NameOfRegistrar = "Recorder";
			If Testing.RegistersWithServiceRegistrar().Find(MetadataObject) <> Undefined Then
				NameOfRegistrar = "DocumentRecorder";
			ElsIf Metadata.InformationRegisters.Contains(MetadataInQuestion) 
				And MetadataInQuestion.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.Independent Then
				NameOfRegistrar = "Lot";
			EndIf;
			
			PeriodicRegister_ = Not Metadata.InformationRegisters.Contains(MetadataInQuestion)
				Or MetadataInQuestion.InformationRegisterPeriodicity <> Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical;
			
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
			
			AddFieldToCreate(Rows.Selection, ObjectName + "_" + NameOfRegistrar);
			AddFieldToCreate(Rows.GroupFields, ObjectName + "_" + NameOfRegistrar);
			
			If PeriodicRegister_ Then
				AddFieldToCreate(Rows.GroupFields, ObjectName + "_" + "Period");
				AddFieldToCreate(Rows.Order, ObjectName + "_" + "Period");
			EndIf;
			
			If FieldSetup = 1 And ThereIsCustomField Then
				
				Rows = Rows.Structure.Add();
				
				AddFieldToCreate(Rows.Selection, ObjectName + "_" + CustomField);
				AddFieldToCreate(Rows.GroupFields, ObjectName + "_" + CustomField);
				
			EndIf;
			
			DeltaGrouping = Rows.Structure.Add();
			
			AddFieldToCreate(DeltaGrouping.Selection, ObjectName + "_" + NameOfRegistrar);
			AddFieldToCreate(DeltaGrouping.GroupFields, ObjectName + "_" + NameOfRegistrar);
			
			If FieldSetup = 1 And ThereIsCustomField Then
				
				AddFieldToCreate(DeltaGrouping.Selection, ObjectName + "_" + CustomField);
				AddFieldToCreate(DeltaGrouping.GroupFields, ObjectName + "_" + CustomField);
				
			ElsIf FieldSetup = 2 And ThereIsCustomField Then
				
				AddFieldToCreate(DeltaGrouping.Order, ObjectName + "_" + CustomField);
				
			EndIf;
			
			If PeriodicRegister_ Then
				AddFieldToCreate(DeltaGrouping.Selection, ObjectName + "_" + "Period");
				AddFieldToCreate(DeltaGrouping.GroupFields, ObjectName + "_" + "Period");
			EndIf;
			
			DetailedRecords = DeltaGrouping.Structure.Add();
			DetailedRecords.Name = DeltaGrouping.Name + "_DetailedRecords";
			DetailedRecords.Use = True;
			// we will define the grouping fields later
			
		ElsIf (Read.NamespaceContext.Depth = 4 Or Read.NamespaceContext.Depth = 5) And ObjectName <> Undefined And TypeOf(ReadingValue) = Type("ValueTable") Then // these are records, we output them to the table.
			
			If FilerByRegister <> "OneRegister" And FilerByRegister <> "NoFilter" And FilerByRegister <> ObjectName Then
				Continue;
			EndIf;
			
			Set = ReadingValue;
			If ValueIsFilled(FilterByRecorderDocument) Then
				LinesByLogger = Set.FindRows(New Structure(NameOfRegistrar, FilterByRecorderDocument));
				If LinesByLogger.Count() > 0 Then
					Set = Set.Copy(LinesByLogger,);
				Else
					DataCompositionSchema.DataSets.Delete(DataSet);
					DataCompositionSettings.Structure.Delete(Table);
					Continue;
				EndIf;
			EndIf;
			
			For Each Column In Set.Columns Do
				
				FieldName = "" + ObjectName + "_" + Column.Name;
				If DataSet.Fields.Find(FieldName) <> Undefined Then // already there in the scheme, no need to add
					SetAlreadyAdded = True;
					Continue;
				Else
					SetAlreadyAdded = False;
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
					
					FieldToEval = DataCompositionSchema.CalculatedFields.Add();
					FieldToEval.DataPath = ObjectName + "_Calculated_" + Column.Name;
					Template = "CASE WHEN %MetadataObject%_TypeOfTestRecord = ""RecordsBeforeCalculation"" THEN -%FieldName% ELSE %FieldName% END";
					FieldToEval.Expression = StrReplace(Template, "%FieldName%", FieldName);
					FieldToEval.Expression = StrReplace(FieldToEval.Expression, "%MetadataObject%", ObjectName);
					FieldToEval.ValueType = Column.ValueType;
					FieldToEval.Title = Column.Name;
					FieldToEval.Appearance.SetParameterValue("MarkNegatives", True);
					FieldToEval.Appearance.SetParameterValue("MaxWidth", 15);
					
					TotalField = DataCompositionSchema.TotalFields.Add();
					TotalField.DataPath = FieldToEval.DataPath;
					TotalField.Expression = "SUM(" + FieldToEval.DataPath + ")";
					TotalField.Groups.Add(ObjectName + "_" + NameOfRegistrar);
					If PeriodicRegister_ Then
						TotalField.Groups.Add(ObjectName + "_" + "Period");
					EndIf;
					If FieldSetup = 1 And ThereIsCustomField Then
						TotalField.Groups.Add(ObjectName + "_" + CustomField);
					EndIf;
					
					ValueField = DataCompositionSchema.TotalFields.Add();
					ValueField.DataPath = FieldToEval.DataPath;
					ValueField.Expression = FieldName;
					ValueField.Groups.Add(ObjectName + "_TypeOfTestRecord");
					
					FieldName = FieldToEval.DataPath;
					
					AddFieldToCreate(Rows.Selection, FieldName);
					AddFieldToCreate(DeltaGrouping.Selection, FieldName);
					
				Else
					
					If Column.Name <> "TypeOfTestRecord" And (Column.Name <> CustomField Or FieldSetup <> 1)
						And Column.Name <> NameOfRegistrar And Column.Name <> "Period" Then // add to the grouping by delta
						
						AddFieldToCreate(DeltaGrouping.GroupFields, FieldName);
						AddFieldToCreate(DeltaGrouping.Selection, FieldName);
						
						If AdditionalSortingFields.Find(Column.Name) <> Undefined Then
							AddFieldToCreate(DeltaGrouping.Order, FieldName);
						EndIf;
						
					EndIf;
					
					If Column.Name <> NameOfRegistrar And Column.Name <> "Period" And (Column.Name <> CustomField Or FieldSetup <> 1) Then // output to detailed records
						AddFieldToCreate(DetailedRecords.GroupFields, FieldName);
					EndIf;
					
				EndIf;
				
				If Column.Name <> NameOfRegistrar And Column.Name <> "RegisterName" And Column.Name <> "FullRegisterName" Then // add to the grouping by delta
					If Column.Name = CustomField And FieldSetup = 1 Then
						DetailedRecordsGroupingField = DetailedRecords.Selection.Items.Insert(1, Type("DataCompositionSelectedField"));
					ElsIf Column.Name = "Period" Then
						InsertIndex = ?(FieldSetup = 1, 2, 1);
						DetailedRecordsGroupingField = DetailedRecords.Selection.Items.Insert(InsertIndex, Type("DataCompositionSelectedField"));
					Else
						DetailedRecordsGroupingField = DetailedRecords.Selection.Items.Add(Type("DataCompositionSelectedField"));
					EndIf;
					DetailedRecordsGroupingField.Field = New DataCompositionField(FieldName);
				EndIf;
				
			EndDo;
			
			If SetAlreadyAdded Then
				For Each String In Set Do
					Table = ExternalDataSets[ObjectName]; // ValueTable
					DataString1 = Table.Add();
					FillPropertyValues(DataString1, String);
				EndDo;
			Else
				ExternalDataSets.Insert(ObjectName, Set);
			EndIf;
			
			ReportIsBlank = False;
			
		EndIf;
	EndDo;
	
	SettingsComposer.UserSettings.AdditionalProperties.Insert("ReportIsBlank", ReportIsBlank);
	
	TemplateComposer = New DataCompositionTemplateComposer;
	Var_40_Template = TemplateComposer.Execute(DataCompositionSchema, DataCompositionSettings, DetailsData);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(Var_40_Template, ExternalDataSets, DetailsData);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);

	Read.Close(); // releasing the file
	Stream.Close();

EndProcedure

#EndRegion

#Region Private

Function ThereIsCustomField(MetadataInQuestion)
	
	ThereIsCustomField = MetadataInQuestion.Dimensions.Find(CustomField) <> Undefined;
	ThereIsCustomField = ThereIsCustomField Or MetadataInQuestion.Attributes.Find(CustomField) <> Undefined;
	
	ThisIsBuhRegister = Common.IsAccountingRegister(MetadataInQuestion);
	
	If ThisIsBuhRegister Then
		// Adding an account and a sub-account:
		ArrayOfDimensions_ = New Array;
		ArrayOfDimensions_.Add("AccountDr");
		ArrayOfDimensions_.Add("AccountCr");
		ArrayOfDimensions_.Add("ExtDimensionDr1");
		ArrayOfDimensions_.Add("ExtDimensionCr1");
		ArrayOfDimensions_.Add("ExtDimensionDr2");
		ArrayOfDimensions_.Add("ExtDimensionCr2");
		ArrayOfDimensions_.Add("ExtDimensionDr3");
		ArrayOfDimensions_.Add("ExtDimensionCr3");
		ThereIsCustomField = ThereIsCustomField Or ArrayOfDimensions_.Find(CustomField) <> Undefined;
	EndIf;
	
	Return ThereIsCustomField;
	
EndFunction

Function AddFieldToCreate(CollectionOfGeneratedFields, FieldName)
	
	MatchingFieldTypesToCollectionTypes = New Map;
	MatchingFieldTypesToCollectionTypes.Insert(Type("DataCompositionSelectedFields"), Type("DataCompositionSelectedField"));
	MatchingFieldTypesToCollectionTypes.Insert(Type("DataCompositionGroupFields"), Type("DataCompositionGroupField"));
	MatchingFieldTypesToCollectionTypes.Insert(Type("DataCompositionOrder"), Type("DataCompositionOrderItem"));
	
	FieldType = MatchingFieldTypesToCollectionTypes.Get(TypeOf(CollectionOfGeneratedFields));
	DataCompositionField = CollectionOfGeneratedFields.Items.Add(FieldType);
	DataCompositionField.Field = New DataCompositionField(FieldName);
	DataCompositionField.Use = True;
	Return DataCompositionField;
	
EndFunction

#EndRegion

#EndIf
