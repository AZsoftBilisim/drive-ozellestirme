#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Defines settings for initial filling of directory items
//
// Parameters:
//  Settings - Structure - initial filling settings
//
Procedure OnSetUpInitialItemsFilling(Settings) Export
	Settings.OnInitialItemsFilling = True;
EndProcedure

// Called when the directory is initially filled in.
//
// Parameters:
//  LanguagesCodes - Array of String- list of configuration languages. Relevant for multilingual configurations.
//  Items - ValueTable - fill-in data. The composition of columns corresponds to the set
//                                 of reference book details.
//  TabularSections - Structure - Key - the name of the table part of the object
//                               Value - Uploading the values of the empty table part to the table.
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export
	
	CreateOrUpdatePredefinedElement(
		Metadata.Catalogs.MasterDataDuplicateSearchRules.Predefined.Counterparties_TINKPPMatches);
	CreateOrUpdatePredefinedElement(
		Metadata.Catalogs.MasterDataDuplicateSearchRules.Predefined.Counterparties_ContactDetaiMatchesAndTINIsNotFilledIn);
	CreateOrUpdatePredefinedElement(
		Metadata.Catalogs.MasterDataDuplicateSearchRules.Predefined.Counterparties_SameNameAndContactDetails);
	CreateOrUpdatePredefinedElement(
		Metadata.Catalogs.MasterDataDuplicateSearchRules.Predefined.Counterparties_BankAccountNumberMatches);
	CreateOrUpdatePredefinedElement(
		Metadata.Catalogs.MasterDataDuplicateSearchRules.Predefined.Counterparties_RegistrationOrTaxNumberOfNonResidentMatches);
	CreateOrUpdatePredefinedElement(
		Metadata.Catalogs.MasterDataDuplicateSearchRules.Predefined.Products_BySettingUniquenessOfTypeOfItem);
	CreateOrUpdatePredefinedElement(
		Metadata.Catalogs.MasterDataDuplicateSearchRules.Predefined.Products_NameMatches);
	CreateOrUpdatePredefinedElement(
		Metadata.Catalogs.MasterDataDuplicateSearchRules.Predefined.Partners_ContactDetailsMatch);
	CreateOrUpdatePredefinedElement(
		Metadata.Catalogs.MasterDataDuplicateSearchRules.Predefined.Partners_NameMatches);
	CreateOrUpdatePredefinedElement(
		Metadata.Catalogs.MasterDataDuplicateSearchRules.Predefined.ItemsCharacteristics_BySettingUniquenessOfItemType);
	CreateOrUpdatePredefinedElement(
		Metadata.Catalogs.MasterDataDuplicateSearchRules.Predefined.ItemsCharacteristics_NameMatches);
	
EndProcedure

// Generate a request based on the rule.
// 
// Parameters:
//  Rule - CatalogRef.MasterDataDuplicateSearchRules - Duplicate search rule
//  OnlyNewTakes - Boolean - Only New Takes
//  Objects - Array of AnyRef - An array of Master Data links to limit the search area for duplicates
// 
// Returns:
//  Query - A request generated using the Master Data duplicate search rule
Function GenerateRequestBasedOnRule(Rule, OnlyNewTakes = True, Objects = Undefined) Export
	RuleDetails = Common.ObjectAttributesValues(Rule, "Query, Overridable_1");
	RequestStructure = RuleDetails.Query.Get();
	Overridable_1 = RuleDetails.Overridable_1;
	If Overridable_1 Then
		Query = SearchAndReplaceDuplicatesMasterDataOverridable.GenerateRequestBasedOnRule(Rule, OnlyNewTakes, Objects);
	Else
		If TypeOf(RequestStructure) <> Type("Structure") Then
			Common.MessageToUser(StrTemplate(NStr("ru = 'В шаблоне %1 отсутствует текст запроса поиска дублей';
													|vi = 'The duplicate search query text is missing in the %1 template';
													|en = 'The duplicate search query text is missing in the %1 template'; fa = 'The duplicate search query text is missing in the %1 template';
													|it = 'The duplicate search query text is missing in the %1 template';
													|pl = 'The duplicate search query text is missing in the %1 template';
													|tr = '%1 şablonunda yinelenen öğe arama sorgu metni bulunmuyor'"),Rule));
			Return "";
		EndIf;
		If Not ValueIsFilled(RequestStructure.QueryText)  Then
			Common.MessageToUser(StrTemplate(NStr("ru = 'В шаблоне %1 отсутствует текст запроса поиска дублей';
													|vi = 'The duplicate search query text is missing in the %1 template';
													|en = 'The duplicate search query text is missing in the %1 template'; fa = 'The duplicate search query text is missing in the %1 template';
													|it = 'The duplicate search query text is missing in the %1 template';
													|pl = 'The duplicate search query text is missing in the %1 template';
													|tr = '%1 şablonunda yinelenen öğe arama sorgu metni bulunmuyor'"),Rule));
			Return "";
		EndIf;
		Query = New Query;
		If RequestStructure.Property("QueryOptions")
			And TypeOf(RequestStructure.QueryOptions) = Type("ValueStorage") Then
			QueryOptions = RequestStructure.QueryOptions.Get();
			For Each ParameterString In QueryOptions Do
				Query.SetParameter(ParameterString.Name, ParameterString.Value);
			EndDo;
		EndIf;
		
		QueriesTexts = New Array;
		QuerySchema = New QuerySchema;
		
		QuerySchema.SetQueryText(RequestStructure.QueryText);
		If QuerySchema.QueryBatch.Count() > 1 Then
			TemplatePackage = Undefined;
			For Each Package In QuerySchema.QueryBatch Do
				If TypeOf(Package) = Type("QuerySchemaSelectQuery") 
					And Package.PlacementTable = "" Then
					TemplatePackage = Package;
					Break;
				EndIf;
			EndDo;
		Else
			TemplatePackage = QuerySchema.QueryBatch[0];
		EndIf;
		TemplatePackage.PlacementTable = "TT_Rule";
		If Objects <> Undefined Then
			Query.SetParameter("Objects", Objects);
			For Each SelectionOperator In TemplatePackage.Operators Do
				For Each Field In SelectionOperator.SelectedFields Do
					SelectionOperator.Filter.Add(StrTemplate("%1 IN (&Objects)",String(Field)));
				EndDo;
			EndDo;
		EndIf;
		TemplatePackage.Columns[0].Alias = "Ref";
		TemplatePackage.Columns[1].Alias = "Ref1";
		QueriesTexts.Add(QuerySchema.GetQueryText());

		QueryTextRegistered = New Array;
		QueryTextRegistered.Add(
		"SELECT
		|	Table.Original AS Duplicate1
		|INTO RegisteredDuplicates
		|FROM
		|	InformationRegister.MasterDataDuplicates AS Table
		|WHERE
		|	Table.Original IN(&TableForCheckingOccurrences)
		|
		|UNION
		|
		|SELECT
		|	Table.Duplicate1
		|FROM
		|	InformationRegister.MasterDataDuplicates AS Table
		|WHERE
		|	Table.Duplicate1 IN(&TableForCheckingOccurrences)");
		
		If OnlyNewTakes Then
			QueryTextRegistered.Add( 
			"SELECT 
			|	Table.Duplicate1 
			|FROM
			|	InformationRegister.MasterDataDuplicatesToConfirm AS Table
			|WHERE
			|	Table.Duplicate1 IN (&TableForCheckingOccurrences)");
		EndIf;
		QueryTextRegistered = StrConcat(QueryTextRegistered, 
		"
		|
		|UNION
		|
		|");
		
		TablesForCheckingOccurrences = New Array;
		Template = 
		"SELECT DISTINCT 
		|	TT_Rule.Ref
		|FROM 
		|	TT_Rule";
		For Each Field In TemplatePackage.Columns Do
			TablesForCheckingOccurrences.Add(StrReplace(Template, "Ref", Field.Alias));
		EndDo;
		TablesForCheckingOccurrencesOfRow = StrConcat(TablesForCheckingOccurrences, " UNION ");
		QueryTextRegistered = StrReplace(QueryTextRegistered, 
					"&TableForCheckingOccurrences",
					TablesForCheckingOccurrencesOfRow);
		QueriesTexts.Add(QueryTextRegistered);
		
		QueryTextSelection = 
		"SELECT DISTINCT
		|	Table.Ref,
		|	Table.Ref1
		|FROM
		|	TT_Rule AS Table
		|WHERE
		|	NOT Table.Ref IN (
		|		SELECT DISTINCT
		|			RegisteredDuplicates.Duplicate1
		|		FROM RegisteredDuplicates AS RegisteredDuplicates)
		|	AND NOT Table.Ref1 IN (
		|		SELECT DISTINCT
		|			RegisteredDuplicates.Duplicate1
		|		FROM RegisteredDuplicates AS RegisteredDuplicates)";
		QueriesTexts.Add(QueryTextSelection);
		
		QueryText = StrConcat(QueriesTexts, "
		|
		|;
		|
		|");
		
		Query.Text = QueryText;
	EndIf;
	Return Query;
EndFunction

#EndRegion

#Region Private

// Creates or updates a predefined directory item
//
// Parameters:
//  PredefinedItem - MetadataObjectCatalog - Predefined element
//
Procedure CreateOrUpdatePredefinedElement(PredefinedItem) Export
	
	TagName = PredefinedItem.Name;
	Ref = Catalogs.MasterDataDuplicateSearchRules[TagName];
	
	If Ref.IsEmpty() Then
		Object = Catalogs.MasterDataDuplicateSearchRules.CreateItem();
	Else
		Object = Ref.GetObject();
	EndIf;
	
	If Object <> Undefined Then
		Object.PredefinedDataName = TagName;
		Object.Description = PredefinedItem.Synonym;
		FillInSuppliedRule(Object);
		Try
			Object.Write();
		Except
			Info_Error = ErrorInfo();
			WriteLogEvent(
				NStr("ru = 'Заполнение предопределенных элементов';
					|vi = 'Populate predefined items';
					|en = 'Populate predefined items'; fa = 'Populate predefined items';
					|it = 'Compilazione degli elementi predefiniti';
					|pl = 'Wypełnienie predefiniowanych elementów';
					|tr = 'Önceden tanımlanan öğelerin doldurulması'", Common.DefaultLanguageCode()),
				EventLogLevel.Error,
				,
				,
				StrTemplate(NStr("ru = 'Ошибка при сохранении предопределенного элемента %1: %2';
								|vi = 'An error occurred when saving the predefined %1 item: %2';
								|en = 'An error occurred when saving the predefined %1 item: %2'; fa = 'An error occurred when saving the predefined %1 item: %2';
								|it = 'An error occurred when saving the predefined %1 item: %2';
								|pl = 'An error occurred when saving the predefined %1 item: %2';
								|tr = 'Önceden tanımlı %1 öğesi kaydedilirken hata oluştu: %2'",
					Common.DefaultLanguageCode()), TagName, ErrorProcessing.DetailErrorDescription(Info_Error)));
		EndTry;
	EndIf;
	
EndProcedure

// Fills in the supplied duplicate search rule from the update handler and when restoring 
// the rule from the element form.
//
// Parameters:
//  Object - CatalogObject.MasterDataDuplicateSearchRules - Rule Object
//
Procedure FillInSuppliedRule(Object) Export
	
	SearchAndReplaceDuplicatesMasterDataOverridable.FillInSuppliedRule(Object);
	
EndProcedure

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Catalogs.MasterDataDuplicateSearchRules.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.27.24";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("6ea64a13-b0e3-47ef-ae0a-fd56db0a7ef1");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Catalogs.MasterDataDuplicateSearchRules.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("ru = 'Обновление справочника ""Правила поиска дублей НСИ"":';
								|vi = 'Update the ""Master data duplicate search rules"" catalog:';
								|en = 'Update the ""Master data duplicate search rules"" catalog:'; fa = 'Update the ""Master data duplicate search rules"" catalog:';
								|it = 'Update the ""Master data duplicate search rules"" catalog:';
								|pl = 'Update the ""Master data duplicate search rules"" catalog:';
								|tr = '""Master veri yinelenen öğe arama kuralları"" kataloğunun güncellenmesi:'"));
	ListOfDescriptions.Add(NStr("ru = '- Заполнение поставляемых правил поиска дублей';
								|vi = '- Fill in the built-in duplicate search rules';
								|en = '- Fill in the built-in duplicate search rules'; fa = '- Fill in the built-in duplicate search rules';
								|it = '- Fill in the built-in duplicate search rules';
								|pl = '- Fill in the built-in duplicate search rules';
								|tr = '- Sağlanan yinelenen öğe arama kurallarının doldurulması'"));
	
	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Catalogs.MasterDataDuplicateSearchRules.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Catalogs.MasterDataDuplicateSearchRules.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Catalogs.MasterDataDuplicateSearchRules.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");

EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = EmptyRef().Metadata().FullName();
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
		
	Query = New Query;
	Query.Text = 
	"SELECT
	|	MasterDataDuplicateSearchRules.Ref AS Ref,
	|	MasterDataDuplicateSearchRules.Overridable_1 AS Overridable_1,
	|	MasterDataDuplicateSearchRules.IsChanged AS IsChanged,
	|	MasterDataDuplicateSearchRules.Query AS Query
	|FROM
	|	Catalog.MasterDataDuplicateSearchRules AS MasterDataDuplicateSearchRules
	|WHERE
	|	MasterDataDuplicateSearchRules.Predefined";
	
	DataForProcessing_ = New Array;
	Selection = Query.Execute().Select();
	Overridable_ = New Array;
	Overridable_.Add(Catalogs.MasterDataDuplicateSearchRules.Catalog_Products_BySettingUniquenessOfTypeOfItem);
	Overridable_.Add(Catalogs.MasterDataDuplicateSearchRules.Catalog_ItemsCharacteristics_BySettingUniquenessOfItemType);
	While Selection.Next() Do
		If Not Overridable_.Find(Selection.Ref) = Undefined Then
			If Not Selection.Overridable_1 Then
				DataForProcessing_.Add(Selection.Ref);
			EndIf;
			Continue;
		EndIf;
		
		QueryText = "";
		SavedRequest = Selection.Query.Get();
		If ValueIsFilled(SavedRequest) Then
			QueryText = SavedRequest.QueryText;
		EndIf;
		
		If Selection.IsChanged Or QueryText <> "" Then
			Continue;
		EndIf;
		DataForProcessing_.Add(Selection.Ref);
	EndDo;
	
	InfobaseUpdate.MarkForProcessing(Parameters, DataForProcessing_);
	
EndProcedure

// The update handler
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters 
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	Parameters.ProcessingCompleted = False;
	
	FullObjectName = EmptyRef().Metadata().FullName();
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		
		Parameters.ProcessingCompleted =
			InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
		Return;
		
	EndIf;
	
	ObjectsProcessed = 0;
	BadData = New Array;
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("ru = 'Не удалось обработать справочник ""Правила поиска дублей НСИ"" по обработчику:';
								|vi = 'Cannot process the ""Master data duplicate search rules"" catalog by the handler:';
								|en = 'Cannot process the ""Master data duplicate search rules"" catalog by the handler:'; fa = 'Cannot process the ""Master data duplicate search rules"" catalog by the handler:';
								|it = 'Cannot process the ""Master data duplicate search rules"" catalog by the handler:';
								|pl = 'Cannot process the ""Master data duplicate search rules"" catalog by the handler:';
								|tr = '""Master veri yinelenen öğe arama kuralları"" kataloğu işleyici tarafından işlenemedi:'"));
	ListOfDescriptions.Add(NStr("ru = '- Заполнение поставляемых правил поиска дублей';
								|vi = '- Fill in the built-in duplicate search rules';
								|en = '- Fill in the built-in duplicate search rules'; fa = '- Fill in the built-in duplicate search rules';
								|it = '- Fill in the built-in duplicate search rules';
								|pl = '- Fill in the built-in duplicate search rules';
								|tr = '- Sağlanan yinelenen öğe arama kurallarının doldurulması'"));
	Query = New Query;
	Query.Text = 
	"SELECT
	|	DataForUpdate.Ref AS Ref
	|INTO TT
	|FROM
	|	&DataForUpdate AS DataForUpdate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT.Ref AS Ref,
	|	MasterDataDuplicateSearchRules.DataVersion AS DataVersion
	|FROM
	|	TT AS TT
	|		LEFT JOIN Catalog.MasterDataDuplicateSearchRules AS MasterDataDuplicateSearchRules
	|			ON TT.Ref = MasterDataDuplicateSearchRules.Ref";
	
	Query.SetParameter("DataForUpdate", UpdatedData);
	
	Catalog = Query.Execute().Select();
	
	While Catalog.Next() Do
		
		ExceptionReason = Undefined;
		Recommendation = "";
		
		BeginTransaction();
		
		Try
			
			ExceptionReason = "Block";
			
			Block = New DataLock;
			
			LockItem = Block.Add(FullObjectName);
			LockItem.SetValue("Ref", Catalog.Ref);
			LockItem.Mode = DataLockMode.Exclusive;
			
			Block.Lock();
			
			CatalogObject = InfobaseUpdateTM.CheckGetObject(
				Catalog.Ref, Catalog.DataVersion, Parameters.Queue); // CatalogObject
			
			ExceptionReason = "BadData";
			Recommendation = NStr("ru = 'Проверьте данные справочника вручную.';
									|vi = 'Check the catalog data manually.';
									|en = 'Check the catalog data manually.'; fa = 'Check the catalog data manually.';
									|it = 'Проверьте данные справочника вручную.';
									|pl = 'Check the catalog data manually.';
									|tr = 'Dizin verilerini manuel olarak kontrol edin.'");
			
			If CatalogObject <> Undefined Then
				
				SearchAndReplaceDuplicatesMasterDataOverridable.FillInSuppliedRule(CatalogObject);
				
			EndIf;
			
			ExceptionReason = "Record";
			
			If CatalogObject.Modified() Then
				InfobaseUpdate.WriteData(CatalogObject);
			Else
				InfobaseUpdate.MarkProcessingCompletion(Catalog.Ref);
			EndIf;
			
			ObjectsProcessed = ObjectsProcessed + 1;
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Catalog.Ref);
			
			If ExceptionReason = "BadData" Then
				
				IssueDetails = InfobaseUpdateTM.DataProblem(
					Catalog.Ref, Recommendation, ErrorInfo());
					BadData.Add(IssueDetails);
				
			ElsIf ExceptionReason <> "Block" Then
				
				InfobaseUpdateTM.RecordBadData(
					BadData, ObjectsProcessed, Parameters);
				Raise StrConcat(ListOfDescriptions, Chars.LF);
				
			EndIf;
			
		EndTry;
		
	EndDo;
	
	If BadData.Count() > 0 Then
		InfobaseUpdateTM.RecordBadData(BadData, ObjectsProcessed, Parameters);
	EndIf;
	
	Parameters.ProcessingCompleted =
		InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);

EndProcedure

#EndRegion

#EndRegion

#EndIf
