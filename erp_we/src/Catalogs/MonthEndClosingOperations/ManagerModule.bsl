#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Defines the configuration for the initial fill of elements
//
// Parameters:
//  Settings - Structure - filling settings:
//   * OnInitialItemFilling - Boolean - if True,
//      the individual filling procedure will be called for each element at the beginning of the element Filling.
Procedure OnSetUpInitialItemsFilling(Settings) Export
	
	Settings.OnInitialItemFilling = True;
	
EndProcedure

// Called when the directory is initially filled in.
//
// Parameters:
//  LanguagesCodes - Array - list of configuration languages. Relevant for multilingual configurations.
//  Items   - ValueTable - fill-in data. The composition of columns corresponds to the set
//                                 of reference book details.
//  TabularSections - Structure - Key - Name of the table part of the object.
//                               Value-Uploads an empty table part to the table of values.
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export

	// The data for filling out the directory is taken from the description of operations for closing the month.
	DescriptionOfClosingStagesOfMonth = DataProcessors.MonthEndClosingOperations.FillInDescriptionOfClosingStagesOfMonth(True);
	
	For Each DescriptionOfClosingStageOfMonth In DescriptionOfClosingStagesOfMonth Do
		Item = Items.Add();
		FillPropertyValues(Item, DescriptionOfClosingStageOfMonth);
		
		Item.PredefinedDataName = Catalogs.MonthEndClosingOperations.GetPredefinedItemName(
			DescriptionOfClosingStageOfMonth.Code);
		Item.Parent =
			PredefinedValue("Catalog.MonthEndClosingOperations." + DescriptionOfClosingStageOfMonth.Parent);
		Item.FollowsStage = DescriptionOfClosingStageOfMonth.FollowsStage;
		NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
			DescriptionOfClosingStageOfMonth.MultilingualName, LanguagesCodes); // @NStr-2
		
		Comment = ?(ValueIsFilled(DescriptionOfClosingStageOfMonth.MultilingualCommentary),
			DescriptionOfClosingStageOfMonth.MultilingualCommentary,
			"en = ''"); // @NStr-1
			
		NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Comment", Comment, LanguagesCodes);
		
		If Not DescriptionOfClosingStageOfMonth.PreviousStages_.Count() Then
			Continue;
		EndIf;

		Item.PreviousStages_ = TabularSections.PreviousStages_.Copy();
		
		For Each PreviousStage_ In DescriptionOfClosingStageOfMonth.PreviousStages_ Do
			
			If Item.PreviousStages_.Find(PreviousStage_) = Undefined Then
				Item.PreviousStages_.Add().MonthClosingOperation =  PreviousStage_;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	// Description of groups of elements
	TableOfStageGroups = DataProcessors.MonthEndClosingOperations.InitializeStageGroupDescriptionTable();
	MonthEndTransactionsServer.FillInDescriptionOfGroupsOfStagesForClosingMonth(TableOfStageGroups);
	
	For Each DescriptionOfMonthClosingGroup In TableOfStageGroups Do
		Item = Items.Add();
		Item.PredefinedDataName = DescriptionOfMonthClosingGroup.Code;
		NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
			DescriptionOfClosingStageOfMonth.MultilingualName, LanguagesCodes); // @NStr-2
	EndDo;

	// Other service elements that are not displayed during the working month
	Query = New Query;
	Query.Text = 
		"SELECT
		|	MonthEndClosingOperations.PredefinedDataName AS PredefinedDataName
		|FROM
		|	Catalog.MonthEndClosingOperations AS MonthEndClosingOperations
		|WHERE
		|	NOT MonthEndClosingOperations.PredefinedDataName IN(&PredefinedData)";
	
	Query.SetParameter("PredefinedData", Items.UnloadColumn("PredefinedDataName"));
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	While SelectionDetailRecords.Next() Do
		Item = Items.Add();
		Item.PredefinedDataName = SelectionDetailRecords.PredefinedDataName;
	EndDo;
	
EndProcedure

// Called when the element being created is initially filled in.
//
// Parameters:
//  Object                  - CatalogObject.Partners - the object to fill in.
//  Data                  - ValueTableRow - fill-in data.
//  AdditionalParameters - Structure - advanced setting.
//
Procedure OnInitialItemFilling(Object, Data, AdditionalParameters) Export
	
	Return;
	
EndProcedure

#Region InterfaceImplementation

// CloudTechnology.ExportImportData

// Returns the directory details that form the natural key for the directory elements.
//
// Returns:
//  Array of String - the names of the Attributes that form the natural key.
//
Function NaturalKeyFields() Export
	
	Result = New Array;
	
	Result.Add("PredefinedDataName");
	
	Return Result;
	
EndFunction

// End CloudTechnology.ExportImportData

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing, Metadata.Catalogs.MonthEndClosingOperations);
	// End StandardSubsystems.Core
	
EndProcedure

#EndIf

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	// StandardSubsystems.Core
	NationalLanguageSupportClientServer.PresentationFieldsGetProcessing(Fields, StandardProcessing);
	// End StandardSubsystems.Core
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	// StandardSubsystems.Core
	NationalLanguageSupportClientServer.PresentationGetProcessing(Data, Presentation, StandardProcessing);
	// End StandardSubsystems.Core
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// Returns unused month closing operations of operations for which there should be no entries in the Month Closing task register.
// 
// Returns:
// Array of CatalogRef.MonthEndClosingOperations - Unused Operations
Function UnusedOperations() Export
	
	Result = New Array;
	
	Return Result; 
	
EndFunction

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Catalogs.MonthEndClosingOperations.ProcessDataForMigrationToNewVersion";
	Handler.Version = "*";
	Handler.ExecutionMode = "Seamless";
	Handler.Id = New UUID("07cd5f88-4bfc-417b-ac20-7e0330993db4");
	Handler.SharedData = True;
	
	Handler.Comment = NStr("vi = 'Điền các mục tin danh mục ""Giao dịch kết chuyển cuối tháng"":';
							|ru = 'Заполнение реквизитов справочника ""Операции закрытия месяца"":';
							|en = 'Fill in the attributes of the ""Month-end closing operations"" catalog:'; fa = 'Fill in the attributes of the ""Month-end closing operations"" catalog:';
							|it = 'Fill in the attributes of the ""Month-end closing operations"" catalog:';
							|pl = 'Fill in the attributes of the ""Month-end closing operations"" catalog:';
							|tr = '""Ay sonu kapama"" kataloğunun özniteliklerinin doldurulması:'");
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Catalogs.MonthEndClosingOperations.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Catalogs.MonthEndClosingOperations.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");

EndProcedure

// The update handler
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters 
//
Procedure ProcessDataForMigrationToNewVersion() Export
	
	ObjectMetadata = CreateItem().Metadata();
	FullObjectName = ObjectMetadata.FullName();

	LanguagesInformationRecords = NationalLanguageSupportServer.LanguagesInfo();
	SettingsOfUpdate = NationalLanguageSupportServer.SettingsPredefinedDataUpdate(ObjectMetadata);
	AttributesToLocalize = AttributesToLocalize(SettingsOfUpdate, LanguagesInformationRecords);
	
	StagesAndGroups = New Array;
	For Each Item In SettingsOfUpdate.PredefinedData Do
		PredefinedItem =
			Common.PredefinedItem("Catalog.MonthEndClosingOperations."
				+ Item.PredefinedDataName);
		If PredefinedItem <> Undefined Then
			StagesAndGroups.Add(Catalogs.MonthEndClosingOperations[Item.PredefinedDataName]);
		EndIf;
	EndDo;
	
	FieldsToUpdate = FieldsToUpdate();
	
	For Each LocalizableAttributes In AttributesToLocalize Do
		FieldsToUpdate = FieldsToUpdate + "," + LocalizableAttributes.Key;
	EndDo;
	
	CatalogData = Common.ObjectsAttributesValues(StagesAndGroups, FieldsToUpdate);

	For Each Stage In SettingsOfUpdate.PredefinedData Do
		Operation = Common.PredefinedItem("Catalog.MonthEndClosingOperations."
			+ Stage.PredefinedDataName);
		
		If Operation <> Undefined Then
			
			StageCatalog = CatalogData.Get(Operation);
			For Each Property In StageCatalog Do
				
				IsAttributeToLocalize = AttributesToLocalize.Get(Property.Key) <> Undefined;
				
				If (IsAttributeToLocalize And StageCatalog[Property.Key] <> Stage[AttributesToLocalize[Property.Key]])
					Or (Not IsAttributeToLocalize And StageCatalog[Property.Key] <> Stage[Property.Key]) Then
					
					BeginTransaction();
					
					Try
						
						Block = New DataLock;
						LockItem = Block.Add(FullObjectName);
						LockItem.SetValue("Ref", Operation);
						LockItem.Mode = DataLockMode.Exclusive;
						Block.Lock();
						
						OperationObject = Operation.GetObject();
						ObjectModified = False;
						
						If OperationObject <> Undefined Then
							If Not OperationObject.IsFolder Then
								FillPropertyValues(OperationObject, Stage, FieldsToUpdate());
								For Each LocalizableAttributes In AttributesToLocalize Do
									OperationObject[LocalizableAttributes.Key] = Stage[LocalizableAttributes.Value];
								EndDo;
							EndIf;
							ObjectModified = True;
						EndIf;
						
						If ObjectModified Then
							InfobaseUpdate.WriteData(OperationObject);
						Else
							InfobaseUpdate.MarkProcessingCompletion(Operation);
						EndIf;
						
						CommitTransaction();
						
					Except
						
						RollbackTransaction();
						InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Operation);
						
					EndTry;
					
					Break;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
EndProcedure

Function FieldsToUpdate()

	Return "PerformedManually,PerformedAtPreliminaryClosingOfMonth,TextExecute,ReadMoreText,
			|OperationalAccounting,LocalAccounting,FinancialAccounting,informational,FollowsStage";

EndFunction

Function AttributesToLocalize(SettingsOfUpdate, LanguagesInformationRecords)
	
	AttributesMatching = New Map;
	
	For Each ObjectAttributeToLocalize In SettingsOfUpdate.ObjectAttributesToLocalize Do
		Name = ObjectAttributeToLocalize.Key;
		AttributesMatching.Insert(Name, Name + "_" + SettingsOfUpdate.DefaultLanguage);

		For Each IsLanguageUsed In LanguagesInformationRecords.Used Do
			If IsLanguageUsed.Value Then
				LanguageCode = LanguagesInformationRecords[IsLanguageUsed.Key];
				AttributesMatching.Insert(Name + IsLanguageUsed.Key, Name + "_" + LanguageCode);
			EndIf;
		EndDo;
	EndDo;
	
	Return AttributesMatching;
	
EndFunction

#EndRegion

#EndRegion

#EndIf