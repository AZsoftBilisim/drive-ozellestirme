//@strict-types

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	FillInListOfBankingDetails();
	SetCurTreeLine();
	SetConditionalAppearance();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAttributesOfItemSProperties

&AtClient
Procedure AttributesOfItemSPropertiesSelection(Item, RowSelected, Field, StandardProcessing)
	
	CompleteSelection();
	
EndProcedure

&AtClient
Procedure AttributesOfItemSPropertiesOnActivateRow(Item)
	
	CurrentData = Items.AttributesOfItemSProperties.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CommentTextGeneralAttributes = NStr("vi = 'Mục tin bổ sung đối với tất cả dạng mặt hàng';
										|ru = 'Дополнительный реквизит для всех видов номенклатуры';
										|en = 'Additional attribute for all item kinds'; fa = 'Additional attribute for all item kinds';
										|it = 'Additional attribute for all item kinds';
										|pl = 'Additional attribute for all item kinds';
										|tr = 'Her öğe türü için ek öznitelik'");
	TemplateAdditionalAttributesOneTypeOfItem = NStr("vi = 'Mục tin bổ sung của dạng mặt hàng ""%1""';
													|ru = 'Дополнительный реквизит вида номенклатуры ""%1""';
													|en = 'Additional attribute of the ""%1"" item kind'; fa = 'Additional attribute of the ""%1"" item kind';
													|it = 'Additional attribute of the ""%1"" item kind';
													|pl = 'Additional attribute of the ""%1"" item kind';
													|tr = '""%1"" öğe türünün ek özniteliği'");
	TemplateAdditionalAttributesSeveralTypesOfNomenclature = NStr("vi = 'Mục tin bổ sung thuộc %1 %2 mặt hàng';
																	|ru = 'Дополнительный реквизит входит в %1 %2 номенклатуры';
																	|en = 'An additional attribute is included in %1 %2 item'; fa = 'An additional attribute is included in %1 %2 item';
																	|it = 'An additional attribute is included in %1 %2 item';
																	|pl = 'An additional attribute is included in %1 %2 item';
																	|tr = 'Ek öznitelik, öğe %1 %2 kapsamındadır'");
	
	RowData = AttributesOfItemSProperties.FindByID(CurrentData.GetID());
	NumberOfTypesOfNomenclature = RowData.NumberOfTypesOfNomenclature;
	IsAdditionalAttribute = RowData.AdditionalAttribute;
	
	CommentText1 = NStr("vi = 'Mục tin đối với tất cả dạng mặt hàng';
						|ru = 'Реквизит для всех видов номенклатуры';
						|en = 'Attribute for all item kinds'; fa = 'Attribute for all item kinds';
						|it = 'Attribute for all item kinds';
						|pl = 'Attribute for all item kinds';
						|tr = 'Her öğe türü için öznitelik'");
	
	If IsAdditionalAttribute Then
		
		If NumberOfTypesOfNomenclature > 1 Then
			
			NumerationItemOptions = NStr("vi = 'dạng,dạng,dạng,,,,,,0';
										|ru = 'вид,вида,видов,,,,,,0';
										|en = 'kind, kinds,,,,,,0'; fa = 'kind, kinds,,,,,,0';
										|it = 'kind, kinds,,,,,,0';
										|pl = 'kind, kinds,,,,,,0';
										|tr = 'türü,türü,türü,,,,,,0'");
			NumberInWords = NumberInWords(NumberOfTypesOfNomenclature,, NStr("vi = ',,,,,,,,0';
																			|ru = ',,,,,,,,0';
																			|en = ',,,,,,,,0'; fa = ',,,,,,,,0';
																			|it = ',,,,,,,,0';
																			|pl = ',,,,,,,,0';
																			|tr = ',,,,,,,,0'"));
			SubjectAndNumberInWords = NumberInWords(NumberOfTypesOfNomenclature,, NumerationItemOptions);
			LineTypesOfNomenclature = StrReplace(SubjectAndNumberInWords, NumberInWords, "");
			
			CurPattern_ = TemplateAdditionalAttributesSeveralTypesOfNomenclature ;
			CommentText1 = StringFunctionsClientServer.SubstituteParametersToString(
				CurPattern_,
				Format(NumberOfTypesOfNomenclature, "NG="),
				LineTypesOfNomenclature);
			
		ElsIf NumberOfTypesOfNomenclature = 1 Then
			
			CurPattern_ = TemplateAdditionalAttributesOneTypeOfItem;
			CommentText1 = StringFunctionsClientServer.SubstituteParametersToString(
				CurPattern_,
				RowData.PresentationOfTypeOfNomenclature);
			
		Else
			
			CommentText1 = CommentTextGeneralAttributes;
			
		EndIf;
		
	EndIf;
	
	Items.Comment.Title = CommentText1;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectAttributes(Command)
	
	CompleteSelection();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure CompleteSelection()
	
	Result = Undefined;
	CurrentData = Items.AttributesOfItemSProperties.CurrentData;
	
	If CurrentData <> Undefined Then
		
		RowData = AttributesOfItemSProperties.FindByID(CurrentData.GetID());
		Result = New Structure;
		Result.Insert("IDOfAttribute", RowData.IDOfAttribute);
		Result.Insert("AttributeRepresentation", RowData.AttributeRepresentation);
		
	EndIf;
	
	Close(Result);
	
EndProcedure

&AtServer
Procedure FillInListOfBankingDetails()
	
	AttributeTree = FormAttributeToValue("AttributesOfItemSProperties");
	
	ProductProperties_ = Parameters.ProductProperties_;
	For Each CurListItem In ProductProperties_ Do
		
		NewRow = AttributeTree.Rows.Add();
		IDOfAttribute = CurListItem.Value; // String
		NewRow.IDOfAttribute = IDOfAttribute;
		NewRow.AttributeRepresentation = CurListItem.Presentation;
		
	EndDo;
	
	If GetFunctionalOption("UseAdditionalAttributesAndInfo") Then
		
		AdditionalAttributes = AdditionalAttributesByTypeOfNomenclature();
		
		If AdditionalAttributes.Count() > 0 Then
			
			FillInListOfAdditionalAttributesOfProperties(AttributeTree, AdditionalAttributes);
			
		EndIf;
		
	EndIf;
	
	ValueToFormAttribute(AttributeTree, "AttributesOfItemSProperties");
	
EndProcedure

&AtServerNoContext
Procedure FillInListOfAdditionalAttributesOfProperties(AttributeTree, AdditionalAttributesByTypeOfNomenclature)
	
	AdditionalAttributes = AdditionalAttributesByTypeOfNomenclature.Copy();
	Columns = "IDForFormulas, Shared, AttributeRepresentation, ValueType";
	AdditionalAttributes.GroupBy(Columns);
	
	PrefixOfTypeOfCharacteristics = "";
	MetadataCharacteristics_ = Metadata.ChartsOfCharacteristicTypes.AdditionalAttributesAndInfo;
	PropertiesOfCharacteristics = ProcessingOfFormulasCached.PropertiesOfSupportedFeatureSources();
	PropertiesDetails = PropertiesOfCharacteristics.Find(MetadataCharacteristics_, "SourceMetadata");
	If PropertiesDetails <> Undefined Then
		PrefixOfTypeOfCharacteristics = PropertiesDetails.PropertyTypePrefix;
	EndIf;
	
	IdTemplate = "{%1%2}";
	TypesOfItemProperties = Metadata.DefinedTypes.RebateItemPropertyTypes.Type;
	
	For Each CurrentAttribute In AdditionalAttributes Do
		
		If Not RebatesServer.AllowedValueTypeForItemProperty(
			CurrentAttribute.ValueType,
			TypesOfItemProperties) Then
			
			Continue;
			
		EndIf;
		
		NewRow = AttributeTree.Rows.Add();
		FillPropertyValues(NewRow, CurrentAttribute);
		NewRow.AdditionalAttribute = True;
		
		Id = CurrentAttribute.IDForFormulas;
		FullAttributeId = StrTemplate(IdTemplate, PrefixOfTypeOfCharacteristics, Id);
		
		NewRow.AttributeRepresentation = CurrentAttribute.AttributeRepresentation;
		NewRow.IDOfAttribute = FullAttributeId;
		
		Filter = New Structure;
		Filter.Insert("IDForFormulas", Id);
		FoundRows = AdditionalAttributesByTypeOfNomenclature.FindRows(Filter);
		NumberOfRowsFound = FoundRows.Count();
		
		If NumberOfRowsFound = 1 Then
			
			NewRow.PresentationOfTypeOfNomenclature = FoundRows[0].PresentationOfTypeOfNomenclature;
			If Not IsBlankString(NewRow.PresentationOfTypeOfNomenclature) Then
				NewRow.NumberOfTypesOfNomenclature = 1;
			EndIf;
			
		Else
			
			NewRow.NumberOfTypesOfNomenclature = NumberOfRowsFound;
			For Each CurLineOfForm In FoundRows Do
				
				NewLineByType = NewRow.Rows.Add();
				FillPropertyValues(NewLineByType, NewRow);
				NewLineByType.PresentationOfTypeOfNomenclature = CurLineOfForm.PresentationOfTypeOfNomenclature;
				NewLineByType.NumberOfTypesOfNomenclature = 1;
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Returns:
//  ValueTable - Table of additional Attributes of item information:
// * IDForFormulas - String - 
// * Shared - Boolean - 
// * PresentationOfTypeOfNomenclature - String 
// * AttributeRepresentation - String
// * ValueType - TypeDescription
//
&AtServer
Function AdditionalAttributesByTypeOfNomenclature()
	
	SetPrivilegedMode(True);
	SharedSet = PropertyManager.PropertiesSetByName("Catalog_Products_Overall");
	
	Query = New Query;
	QueryText =
	"SELECT
	|	ItemKinds.PropertiesSet AS PropertiesSet,
	|	ItemKinds.Presentation AS PresentationOfTypeOfNomenclature
	|INTO TT_PropertiesSets
	|FROM
	|	Catalog.ItemKinds AS ItemKinds
	|WHERE
	|	NOT ItemKinds.DeletionMark
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_PropertiesSets.PresentationOfTypeOfNomenclature AS PresentationOfTypeOfNomenclature,
	|	AdditionalAttributesOfSet.Property AS Property,
	|	FALSE AS Shared
	|INTO VT_PropertiesOfTypesOfNomenclature
	|FROM
	|	TT_PropertiesSets AS TT_PropertiesSets
	|		INNER JOIN Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes AS
	|			AdditionalAttributesOfSet
	|		ON TT_PropertiesSets.PropertiesSet = AdditionalAttributesOfSet.Ref
	|		INNER JOIN Catalog.AdditionalAttributesAndInfoSets AS AdditionalAttributesAndInfoSets
	|		ON TT_PropertiesSets.PropertiesSet = AdditionalAttributesAndInfoSets.Ref
	|		AND AdditionalAttributesAndInfoSets.Used
	|WHERE
	|	NOT AdditionalAttributesOfSet.DeletionMark
	|
	|UNION ALL
	|
	|SELECT
	|	"""",
	|	AdditionalAttributesOfSet.Property,
	|	TRUE
	|FROM
	|	Catalog.AdditionalAttributesAndInfoSets.AdditionalAttributes AS AdditionalAttributesOfSet
	|		INNER JOIN Catalog.AdditionalAttributesAndInfoSets AS AdditionalAttributesAndInfoSets
	|		ON AdditionalAttributesOfSet.Ref = AdditionalAttributesAndInfoSets.Ref
	|		AND AdditionalAttributesAndInfoSets.Used
	|WHERE
	|	AdditionalAttributesOfSet.Ref = &SharedSet
	|	AND NOT AdditionalAttributesOfSet.DeletionMark
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VT_PropertiesOfTypesOfNomenclature.PresentationOfTypeOfNomenclature AS PresentationOfTypeOfNomenclature,
	|	&ExpressionIDForFormulas AS IDForFormulas,
	|	AdditionalAttributesAndInfo.Presentation AS AttributeRepresentation,
	|	VT_PropertiesOfTypesOfNomenclature.Shared AS Shared,
	|	AdditionalAttributesAndInfo.ValueType AS ValueType
	|FROM
	|	VT_PropertiesOfTypesOfNomenclature AS VT_PropertiesOfTypesOfNomenclature
	|		INNER JOIN ChartOfCharacteristicTypes.AdditionalAttributesAndInfo AS AdditionalAttributesAndInfo
	|		ON VT_PropertiesOfTypesOfNomenclature.Property = AdditionalAttributesAndInfo.Ref
	|WHERE
	|	NOT AdditionalAttributesAndInfo.DeletionMark";
	
	ExpressionIDForFormulas = StringFunctionsClientServer.SubstituteParametersToString(
		"AdditionalAttributesAndInfo.%1",
		ProcessingOfFormulas.IdFieldForAdditionalBankingDetails());
	
	QueryText = StrReplace(QueryText, "&ExpressionIDForFormulas", ExpressionIDForFormulas);
	Query.Text = QueryText; 
	Query.SetParameter("SharedSet", SharedSet);
	Return Query.Execute().Unload();
	
EndFunction

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	SetDesignAttributesForAllTypesOfItems();
	SetDesignAttributesForSeveralTypesOfItems();
	
EndProcedure 

&AtServer
Procedure SetDesignAttributesForAllTypesOfItems()
	
	TextForEveryone = NStr("vi = 'đối với tất cả';
							|ru = 'для всех';
							|en = 'for all'; fa = 'for all';
							|it = 'for all';
							|pl = 'for all';
							|tr = 'tümü için'");
	DataLayoutSelectionElementType = Type("DataCompositionFilterItem");
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field =
		New DataCompositionField(Items.AttributesOfItemSPropertiesPresentationOfTypeOfNomenclature.Name);
	
	ItemFilter = Item.Filter.Items.Add(DataLayoutSelectionElementType);
	ItemFilter.LeftValue =
		New DataCompositionField("AttributesOfItemSProperties.PresentationOfTypeOfNomenclature");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(DataLayoutSelectionElementType);
	ItemFilter.LeftValue =
		New DataCompositionField("AttributesOfItemSProperties.NumberOfTypesOfNomenclature");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text", TextForEveryone);
	
EndProcedure

&AtServer
Procedure SetDesignAttributesForSeveralTypesOfItems()
	
	DataLayoutSelectionElementType = Type("DataCompositionFilterItem");
	Item = ConditionalAppearance.Items.Add();
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field =
		New DataCompositionField(Items.AttributesOfItemSPropertiesPresentationOfTypeOfNomenclature.Name);
	
	ItemFilter = Item.Filter.Items.Add(DataLayoutSelectionElementType);
	ItemFilter.LeftValue =
		New DataCompositionField("AttributesOfItemSProperties.PresentationOfTypeOfNomenclature");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(DataLayoutSelectionElementType);
	ItemFilter.LeftValue =
		New DataCompositionField("AttributesOfItemSProperties.NumberOfTypesOfNomenclature");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = 1;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'nhiều';
													|ru = 'несколько';
													|en = 'several'; fa = 'several';
													|it = 'several';
													|pl = 'several';
													|tr = 'birden fazla'"));
	
EndProcedure

&AtServer
Procedure SetCurTreeLine()
	
	IDOfAttribute = Parameters.IDOfAttribute;
	If IsBlankString(IDOfAttribute) Then
		Return;
	EndIf;
	
	For Each Item In AttributesOfItemSProperties.GetItems() Do
		
		If Item.IDOfAttribute = IDOfAttribute Then
			
			Items.AttributesOfItemSProperties.CurrentRow = Item.GetID();
			Break;
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion