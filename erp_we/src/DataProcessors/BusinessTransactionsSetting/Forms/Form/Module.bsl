
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	// Matching enumeration values to string value names
	MapTypes = New Map;
	EnumValues = Metadata.Enums.AccountingDataTypes.EnumValues;
	MapTypes.Insert(Enums.AccountingDataTypes.EmptyRef(), "");
	For Each Value In EnumValues Do
		Name = Value.Name;
		MapTypes.Insert(Enums.AccountingDataTypes[Name], Name);
	EndDo;
	AccountingDataTypeAsAString = New FixedMap(MapTypes);
	
	// Matching enumeration values to string value names
	MapTypes = New Map;
	EnumValues = Metadata.Enums.IndicatorsOfAnalyticalRegisters.EnumValues;
	MapTypes.Insert(Enums.IndicatorsOfAnalyticalRegisters.EmptyRef(), "");
	For Each Value In EnumValues Do
		Name = Value.Name;
		MapTypes.Insert(Enums.IndicatorsOfAnalyticalRegisters[Name], Name);
	EndDo;
	RegisterIndicatorsAsAString = New FixedMap(MapTypes);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	ElementShapeParameters = New Structure;
	ElementShapeParameters.Insert("ManualSetting");
	ElementShapeParameters.Insert("Key", RowSelected);
	
	OpenForm("Catalog.BusinessTransactionsSettings.ObjectForm", ElementShapeParameters, ThisObject); 
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure GenerateHandlerCode(Command)
	
	GenerateHandlerCodeOnServer();
	
	TextDoc = New TextDocument;
	TextDoc.SetText(OneCCode.GetText());
	TextDoc.Show("OnInitialItemsFilling");
	
EndProcedure

&AtClient
Procedure FillInPredefinedElements(Command)
	
	FillInSettingsOnServer();
	
EndProcedure

&AtClient
Procedure GenerateCodeForSelectedItems(Command)
	
	SelectedItems = Items.List.SelectedRows;
	GenerateHandlerCodeOnServer(SelectedItems);
	
	TextDoc = New TextDocument;
	TextDoc.SetText(OneCCode.GetText());
	TextDoc.Show("OnInitialItemsFilling");
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure GenerateHandlerCodeOnServer(OperationSettings = Undefined)
	
	PredefinedSettings_ = PredefinedItemsSettings(OperationSettings);
	RegisterIndicators = RegisterIndicators();
	RelatedDocuments = RelatedDocuments();
	FunctionalOptions = FunctionalOptions();
	OneCCode.Clear();
	
	If OperationSettings = Undefined Then
		OneCCode.AddLine("Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export" + Chars.LF);
		OneCCode.AddLine("	DefaultLanguageCode = Common.DefaultLanguageCode();" + Chars.LF);
	EndIf;
	TabularSections = New Structure;
	TabularSections.Insert("RegisterIndicators", RegisterIndicators);
	TabularSections.Insert("Documents", RelatedDocuments);
	TabularSections.Insert("FunctionalOptions", FunctionalOptions);
	AddElementCode(PredefinedSettings_, TabularSections);
	
	If OperationSettings = Undefined Then
		OneCCode.AddLine("EndProcedure");
	EndIf;
	
EndProcedure

&AtServer
Procedure AddElementCode(Parent, TabularSections, Indent = "	")
	
	DoubleBackslash = "//";
	For Each Item In Parent.Rows Do
		
		If Item.IsFolder Then
			OneCCode.AddLine(StrTemplate("%1#Area %2", Indent, Item.ID));
			OneCCode.AddLine(StrTemplate("%1Item = Items.Add();  %2 see. TSStringOfPrepaidItem", Indent, DoubleBackslash));
			OneCCode.AddLine(StrTemplate("%1Item.PredefinedDataName = ""%2"";", Indent, Item.ID));
			If ValueIsFilled(Item.Parent) Then
				OneCCode.AddLine(StrTemplate("%1Item.Parent = Catalogs.BusinessTransactionsSettings.%2;", Indent, Item.ParentID));
			EndIf;
			OneCCode.AddLine(StrTemplate("%1NationalLanguageSupportServer.FillMultilanguageAttribute(Item, ""Description"", ""ru = '%2'"", LanguagesCodes); %3 @NStr-2" + Chars.LF, Indent, Item.Description, DoubleBackslash));
			AddElementCode(Item, TabularSections, Chars.Tab + Indent);
			OneCCode.AddLine(StrTemplate("%1#EndRegion %2%3" + Chars.LF, Indent, DoubleBackslash, Item.ID));
			Continue;
		EndIf;
		
		OneCCode.AddLine(StrTemplate("%1#Area %2", Indent, Item.ID));
		OneCCode.AddLine(StrTemplate("%1Item = Items.Add(); %2 see. TSStringOfPrepaidItem", Indent, DoubleBackslash));
		OneCCode.AddLine(StrTemplate("%1Item.PredefinedDataName = ""%2"";", Indent, Item.ID));
		OneCCode.AddLine(StrTemplate("%1Item.Parent = Catalogs.BusinessTransactionsSettings.%2;", Indent, Item.ParentID));
		ElementDescription = StrReplace(Item.Description,"""","""""");
		OneCCode.AddLine(StrTemplate("%1NationalLanguageSupportServer.FillMultilanguageAttribute(Item, ""Description"", ""ru = '%2'"", LanguagesCodes); %3 @NStr-2", Indent, ElementDescription, DoubleBackslash));
		OneCCode.AddLine(StrTemplate("%1Item.DataSource = ""%2"";", Indent, Item.DataSource));
		DataSourcePresentation = StrReplace(Item.DataSourcePresentation,"""","""""");
		If IsBlankString(DataSourcePresentation) Then
			OneCCode.AddLine(StrTemplate("%1Item.DataSourcePresentation = """";", Indent));
		Else
			OneCCode.AddLine(StrTemplate("%1Item.DataSourcePresentation = NStr(""ru = '%2'"", DefaultLanguageCode);", Indent, DataSourcePresentation));
		EndIf;
		
		LongDesc = StrTemplate("%1Item.LongDesc = """";", Indent);
		If Not IsBlankString(Item.LongDesc) Then
			LongDesc = StrTemplate("%1Item.LongDesc = NStr(""ru = '%2'"", DefaultLanguageCode);", Indent, StrReplace(Item.LongDesc,"""",""""""));
		EndIf;
		OneCCode.AddLine(LongDesc);
		
		Receipt = StrTemplate("%1Item.Receipt = Undefined;", Indent);
		If ValueIsFilled(Item.Receipt) Then
			Receipt = StrTemplate("%1Item.Receipt = Enums.AccountingDataTypes.%2;", Indent, AccountingDataTypeAsAString[Item.Receipt]);
		EndIf;
		OneCCode.AddLine(Receipt);
		
		Expense = StrTemplate("%1Item.Expense = Undefined;", Indent);
		If ValueIsFilled(Item.Expense) Then
			Expense = StrTemplate("%1Item.Expense = Enums.AccountingDataTypes.%2;", Indent, AccountingDataTypeAsAString[Item.Expense]);
		EndIf;
		OneCCode.AddLine(Expense);
		
		OneCCode.AddLine(StrTemplate("%1Item.BusinessOperation = Enums.BusinessTransactions.%2;", Indent, Item.BusinessOperation));
		OneCCode.AddLine(StrTemplate("%1Item.UseInBudgeting = %2;", Indent, Item.UseInBudgeting));
		OneCCode.AddLine(StrTemplate("%1Item.UseInFinancialAccounting = %2;", Indent, Item.UseInFinancialAccounting));
		OneCCode.AddLine(StrTemplate("%1Item.UseForSelection = %2;", Indent, Item.UseForSelection));
		OneCCode.AddLine(StrTemplate("%1Item.UseInDocumentRegistry = %2;", Indent, Item.UseInDocumentRegistry));
		OneCCode.AddLine(StrTemplate("%1Item.UseForAccessRestrictions = %2;", Indent, Item.UseForAccessRestrictions));

		Filter = New Structure("Ref", Item.Ref);
		ThereAreIndicators = (Boolean(Item.UseInFinancialAccounting) Or Boolean(Item.UseInBudgeting)) 
			And Not IsBlankString(Item.DataSource);
		If ThereAreIndicators Then
			OneCCode.AddLine("");
			OneCCode.AddLine(StrTemplate("%1%2++ NOT UT", Indent, DoubleBackslash));
			OneCCode.AddLine(StrTemplate("%1AddSourceMetrics(Item, TabularSections, Item.DataSource);", Indent));
			OneCCode.AddLine(StrTemplate("%1%2-- NOT UT", Indent, DoubleBackslash));
		EndIf;

		RelatedDocuments = TabularSections.Documents.FindRows(Filter);
		If RelatedDocuments.Count() > 0 Then
			If Not ThereAreIndicators Then
				OneCCode.AddLine("");
			EndIf;
			OneCCode.AddLine(StrTemplate("%1Item.Documents = TabularSections.Documents.Copy();", Indent));
			For Each Document In RelatedDocuments Do
				OneCCode.AddLine(StrTemplate("%1Document = Metadata.Documents.Find(""%2"");", Indent, Document.DocumentName));
				OneCCode.AddLine(StrTemplate("%1If Document <> Undefined Then", Indent));
				OneCCode.AddLine(StrTemplate("	%1TSItem = Item.Documents.Add();", Indent));
				OneCCode.AddLine(StrTemplate("	%1TSItem.DocumentName = Document.Name;", Indent));
				OneCCode.AddLine(
					StrTemplate("	%1FoundRef = Common.MetadataObjectID(Document.FullName());",
								Indent));
				OneCCode.AddLine(StrTemplate("	%1TSItem.MetadataObjectID = FoundRef;", Indent));
				OneCCode.AddLine(StrTemplate("%1EndIf;", Indent));
			EndDo;
		EndIf;
		
		FunctionalOptions = TabularSections.FunctionalOptions.FindRows(Filter);
		If FunctionalOptions.Count() > 0 Then
			If RelatedDocuments.Count() > 0 Or (Not ThereAreIndicators And RelatedDocuments.Count() = 0) Then
				OneCCode.AddLine("");
			EndIf;
			OneCCode.AddLine(StrTemplate("%1Item.FunctionalOptions = TabularSections.FunctionalOptions.Copy();", Indent));
			For Each Option In FunctionalOptions Do
				OneCCode.AddLine(StrTemplate("%1TSItem = Item.FunctionalOptions.Add();", Indent));
				OneCCode.AddLine(StrTemplate("%1TSItem.FunctionalOptionName = ""%2"";", Indent, Option.FunctionalOptionName));
			EndDo;
		EndIf;
		
		OneCCode.AddLine(StrTemplate("%1#EndRegion %2%3" + Chars.LF, Indent, DoubleBackslash, Item.ID));
		
	EndDo;
	
EndProcedure


// LongDesc
// 
// Returns:
// 	ValueTree - LongDesc:
// 	 *Ref - CatalogRef.BusinessTransactionsSettings - 
// 	 *PredefinedDataName - String -
// 	 *Description - String -
// 	 *LongDesc - String -
// 	 *DataSource - String -
// 	 *DataSourcePresentation - String -
// 	 *Receipt - EnumRef.AccountingDataTypes - 
// 	 *Expense - EnumRef.AccountingDataTypes - 
// 	 *PredefinedDataName - String -
// 	 *UseInBudgeting - String -
// 	 *UseInFinancialAccounting - String -
// 	 *UseForSelection - String -
// 	 *UseInDocumentRegistry - String -
// 	 *UseForAccessRestrictions - String - 
// 	 *IsFolder - Boolean -
&AtServer
Function PredefinedItemsSettings(OperationSettings = Undefined)
	
	QueryText = 
	"SELECT
	|	Settings.Ref AS Ref,
	|	ISNULL(Settings.Parent.PredefinedDataName,"""") AS ParentID,
	|	Settings.PredefinedDataName AS ID,
	|	Settings.Description AS Description,
	|	Settings.LongDesc AS LongDesc,
	|	Settings.DataSource AS DataSource,
	|	Settings.DataSourcePresentation AS DataSourcePresentation,
	|	Settings.Receipt AS Receipt,
	|	Settings.Expense AS Expense,
	|	Settings.PredefinedDataName AS BusinessOperation,
	|	CASE
	|		WHEN Settings.UseInBudgeting
	|			THEN ""True""
	|		ELSE ""False""
	|	END AS UseInBudgeting,
	|	CASE
	|		WHEN Settings.UseInFinancialAccounting
	|			THEN ""True""
	|		ELSE ""False""
	|	END AS UseInFinancialAccounting,
	|	CASE
	|		WHEN Settings.UseForSelection
	|			THEN ""True""
	|		ELSE ""False""
	|	END AS UseForSelection,
	|	CASE
	|		WHEN Settings.UseInDocumentRegistry
	|			THEN ""True""
	|		ELSE ""False""
	|	END AS UseInDocumentRegistry,
	|	CASE
	|		WHEN Settings.UseForAccessRestrictions
	|			THEN ""True""
	|		ELSE ""False""
	|	END AS UseForAccessRestrictions,
	|	Settings.IsFolder AS IsFolder
	|FROM
	|	Catalog.BusinessTransactionsSettings AS Settings
	|WHERE
	|	Settings.Predefined
	|	AND NOT Settings.DeletionMark
	|	AND &FilterByRefs
	|
	|ORDER BY
	|	Settings.Description HIERARCHY";
	
	Query = New Query;
	If OperationSettings = Undefined Then
		Query.SetParameter("FilterByRefs", True);
	Else
		QueryText = StrReplace(QueryText,"&FilterByRefs","(Settings.Ref IN (&FilterByRefs) OR Settings.Parent IN (&FilterByRefs))");
		Query.SetParameter("FilterByRefs", OperationSettings);
	EndIf;
	Query.Text = QueryText;
	
	Return Query.Execute().Unload(QueryResultIteration.ByGroupsWithHierarchy);
	
EndFunction

&AtServer
Function RegisterIndicators()
	
	Query = New Query(
	"SELECT
	|	RegisterIndicators.Ref AS Ref,
	|	RegisterIndicators.Ref.PredefinedDataName AS OwnerID,
	|	RegisterIndicators.Factor AS Factor,
	|	CASE
	|		WHEN RegisterIndicators.Use
	|			THEN ""True""
	|		ELSE ""False""
	|	END AS Use
	|FROM
	|	Catalog.BusinessTransactionsSettings.RegisterIndicators AS RegisterIndicators
	|WHERE
	|	NOT RegisterIndicators.Ref.IsFolder
	|	AND RegisterIndicators.Ref.Predefined
	|	AND NOT RegisterIndicators.Ref.DeletionMark");
	
	Return Query.Execute().Unload();
	
EndFunction

&AtServer
Function RelatedDocuments()
	
	Query = New Query(
	"SELECT
	|	RelatedDocuments.Ref AS Ref,
	|	RelatedDocuments.Ref.PredefinedDataName AS OwnerID,
	|	ISNULL(MetadataIDs.Name, """") AS DocumentName,
	|	ISNULL(MetadataIDs.Synonym, """") AS PresentationOfDocument
	|FROM
	|	Catalog.BusinessTransactionsSettings.Documents AS RelatedDocuments
	|		LEFT JOIN Catalog.MetadataObjectIDs AS MetadataIDs
	|		ON (RelatedDocuments.MetadataObjectID = MetadataIDs.Ref)
	|WHERE
	|	NOT RelatedDocuments.Ref.IsFolder
	|	AND RelatedDocuments.Ref.Predefined
	|	AND NOT RelatedDocuments.Ref.DeletionMark");
	
	Return Query.Execute().Unload();
	
EndFunction

&AtServer
Function FunctionalOptions()
	
	Query = New Query(
	"SELECT
	|	FederalDistrict.Ref AS Ref,
	|	FederalDistrict.Ref.PredefinedDataName AS OwnerID,
	|	FederalDistrict.FunctionalOptionName AS FunctionalOptionName
	|FROM
	|	Catalog.BusinessTransactionsSettings.FunctionalOptions AS FederalDistrict
	|WHERE
	|	NOT FederalDistrict.Ref.IsFolder
	|	AND FederalDistrict.Ref.Predefined
	|	AND NOT FederalDistrict.Ref.DeletionMark");
	
	Return Query.Execute().Unload();
	
EndFunction

&AtServer
Procedure FillInSettingsOnServer()
	
	Catalogs.BusinessTransactionsSettings.FillInPredefinedSettingsForBusinessOperations();
	
EndProcedure

#EndRegion