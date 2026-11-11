#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

// Returns the text of a hint for item tracking features.
//
// Parameters:
//	AccountingFeature - EnumRef.ItemAccountingFeatures	 - feature of the given item.
//
// Returns:
//	String - a hint on the specifics of the inventory accounting.
//
Function HintOnAccountingForProducts(AccountingFeature) Export
	
	ToolTipText = "";
	
	If AccountingFeature = Enums.ItemAccountingFeatures.PerformedBySellerCompany Then
		ToolTipText = NStr("vi = 'Dịch vụ được thực hiện bởi doanh nghiệp chúng ta và được bán bởi doanh nghiệp này.';
							|ru = 'Услуга выполняется собственной организацией, продается ей же.';
							|en = 'Service is provided by own company, the service is sold by it.'; fa = 'Service is provided by own company, the service is sold by it.';
							|it = 'Il servizio viene prestato dall''azienda propria e venduto da essa.';
							|pl = 'Usługa jest wykonywana przez własną firmę, sprzedawana jest własnej firm.';
							|tr = 'Hizmet, özel iş yeri tarafından gerçekleştirilir ve aynı iş yeri tarafından satılır.'");
	ElsIf AccountingFeature = Enums.ItemAccountingFeatures.PerformedByCompanyOnAgencyBasis Then
		ToolTipText = NStr("vi = 'Dịch vụ được thực hiện bởi doanh nghiệp chúng ta (người bán ký gửi) và được bán theo hợp đồng đại lý. ';
							|ru = 'Услуга выполняется собственной организацией (принципалом), продается по агентскому договору.';
							|en = 'Service is provided by own company (principal), the service is sold under an agency agreement.'; fa = 'Service is provided by own company (principal), the service is sold under an agency agreement.';
							|it = 'Il servizio viene prestato dall''azienda propria (committente), si vende in base al contratto di agenzia.';
							|pl = 'Usługa jest wykonywana przez własną firmę (zleceniodawcę), sprzedawana na podstawie umowy agencyjnej.';
							|tr = 'Hizmet, bir acentelik sözleşmesi kapsamında satılan özel iş yeri (yönetici) tarafından gerçekleştirilir.'");
	ElsIf AccountingFeature = Enums.ItemAccountingFeatures.PerformedByPartner Then
		ToolTipText = NStr("vi = 'Dịch vụ được thực hiện bởi đối tác ngoài (người bán ký gửi) và được bán theo hợp đồng đại lý.';
							|ru = 'Услуга выполняется сторонним исполнителем (принципалом), продается по агентскому договору.';
							|en = 'Service is provided by an external assignee (principal), the service is sold under an agency agreement.'; fa = 'Service is provided by an external assignee (principal), the service is sold under an agency agreement.';
							|it = 'Il servizio viene prestato da un esecutore esterno (committente), si vende in base al contratto di agenzia.';
							|pl = 'Usługa jest wykonywana przez zewnętrznego wykonawcę (zleceniodawcę), sprzedawana na podstawie umowy agencyjnej.';
							|tr = 'Hizmet, bir acentelik sözleşmesi kapsamında satılan üçüncü taraf yüklenici (yönetici) tarafından gerçekleştirilir.'");
	EndIf;
	
	ProductsLocalization.HintOnAccountingForProducts(ToolTipText, AccountingFeature);
	
	Return ToolTipText;
	
EndFunction

// Relationship between accounting features and functional options. If the link is not specified, the accounting feature is hidden by default.
//
// Returns:
//	Map
//	 * Key-Enum Link.Osobennostyami.
//	 * Value - String - names of functional options separated by commas, option values are combined by And.
//
Function RelationshipOfFeaturesOfAccountingForIFIS() Export
	
	RelationshipOfFeaturesOfAccountingForIFIS = New Map;
	
	RelationshipOfFeaturesOfAccountingForIFIS.Insert(Enums.ItemAccountingFeatures.PerformedBySellerCompany, "UseAgentServiceSale");
	RelationshipOfFeaturesOfAccountingForIFIS.Insert(Enums.ItemAccountingFeatures.PerformedByCompanyOnAgencyBasis, "UseAgentServiceSale,UseMultipleCompanies");
	RelationshipOfFeaturesOfAccountingForIFIS.Insert(Enums.ItemAccountingFeatures.PerformedByPartner, "UseAgentServiceSale");
	
	ProductsLocalization.RelationshipOfFeaturesOfAccountingForIFIS(RelationshipOfFeaturesOfAccountingForIFIS);
	
	Return RelationshipOfFeaturesOfAccountingForIFIS;
	
EndFunction

// Returns True if the item accounting features are enabled
//
// Parameters:
//  FilterItemsType - EnumRef.ItemsTypes, Undefined - Selection by type of nomenclature.
//  	If the pass is Undefined, the check will be performed for all types of items.
// 
// Returns:
//  Boolean - returns True if the FO is enabled.
Function OneOfFeaturesIsIncluded(FilterItemsType = Undefined) Export
	
	AvailableAccountingFeatures = SelectionDataByItemType(FilterItemsType);
	
	UsedByAllMeans = New Array;
	UsedByAllMeans.Add(WithoutAccountingFeatures);
	
	For Each Used_ByAllMeans In UsedByAllMeans Do
		ListItem = AvailableAccountingFeatures.FindByValue(Used_ByAllMeans);
		If ListItem = Undefined Then
			Continue; // Not used for this type of item
		EndIf;
		AvailableAccountingFeatures.Delete(ListItem);
	EndDo;
	
	Return ValueIsFilled(AvailableAccountingFeatures);
	
EndFunction

// Updates the accounting feature value when the item type changes.
// If the accounting feature value is still available for the specified type, the accounting feature value does not change.
// Otherwise, the accounting feature is filled with the default value.
// 
// Parameters:
//  ItemsType - EnumRef.ItemsTypes - Defines the available accounting features
//  AccountingFeature - EnumRef.ItemAccountingFeatures - the value that needs to be filled in
Procedure ProcessItemTypeChanges(ItemsType, AccountingFeature) Export
	
	ValueIsAvailable = ValueIsFilled(AccountingFeature)
		And SelectionDataByItemType(ItemsType).FindByValue(AccountingFeature) <> Undefined;
	
	If ValueIsAvailable Then
		Return;
	EndIf;
	
	If ItemsType = Enums.ItemsTypes.OperationService Then
		AccountingFeature = PerformedBySellerCompany;
	Else
		AccountingFeature = WithoutAccountingFeatures;
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	ItemsType = Undefined;
	If Not Parameters.Filter.Property("ItemsType", ItemsType) Then
		Return;
	EndIf;
		
	StandardProcessing = False;
	EnumValues = EmptyRef().Metadata().EnumValues;
	FunctionalOptions = Metadata.FunctionalOptions;
	
	AccessibilityTexts = New Array;
	TextsOfNames = New Array; // For case-insensitive sorting and selection by row
	
	SelectionPattern = "VALUE(Enum.ItemAccountingFeatures.%1)
	|			THEN %2";
	
	AliasesOfConstantsUsed = New Array;
	ValuesUsed = New Map;
	// Used unconditionally:
	ValuesUsed.Insert(WithoutAccountingFeatures);
	
	// Used when F.O. is enabled.:
	CommonClientServer.SupplementMap(ValuesUsed, RelationshipOfFeaturesOfAccountingForIFIS());
	
	For Each KeyAndValue In ValuesUsed Do
		
		MetadataOfEnumerationValue = EnumValues[IndexOf(KeyAndValue.Key)]; 
		EnumerationValueName = MetadataOfEnumerationValue.Name;
		ValueConditions = New Array;
		
		FunctionalOptionsByString = KeyAndValue.Value;
		If ValueIsFilled(FunctionalOptionsByString) Then
			
			For Each FunctionalOptionName In StrSplit(KeyAndValue.Value, ",") Do

				ConstantName = FunctionalOptions[FunctionalOptionName].Location.Name;
				ValueConditions.Add(StrTemplate("Constant%1.Value", ConstantName));
				
				AliasesOfConstantsUsed.Add(StrTemplate("Constant.%1 AS Constant%1", ConstantName));
			EndDo;
		
		Else // Unconditional use:
			ValueConditions.Add("TRUE");
		EndIf;
		
		NameText = MetadataOfEnumerationValue.Presentation();
		NameText = StrReplace(NameText, """", """"""); // Escaping quotes
		NameText = StrTemplate("""%1""", NameText); // Adding quotation marks
		NameText = StrTemplate(SelectionPattern, EnumerationValueName, NameText);
		TextsOfNames.Add(NameText);
		
		AccessibilityText = StrTemplate(SelectionPattern, EnumerationValueName, StrConcat(ValueConditions, " And "));
		AccessibilityTexts.Add(AccessibilityText);
		
	EndDo;
	
	SelectionPattern = 
	"CASE ItemAccountingFeatures.Ref
	|		WHEN %1
	|		ELSE
	|			FALSE
	|		END";
	SelectionSeparator = "
	|		WHEN ";
	
	NameText = StrTemplate(SelectionPattern, StrConcat(TextsOfNames, SelectionSeparator));
	AccessibilityTexts = StrTemplate(SelectionPattern, StrConcat(AccessibilityTexts, SelectionSeparator));
	
	Query = New Query;
	QueryText =
	"SELECT
	|	ItemAccountingFeatures.Ref AS Ref,
	|	&Description AS Description,
	|	CASE ItemAccountingFeatures.Ref
	|		WHEN VALUE(Enum.ItemAccountingFeatures.WithoutAccountingFeatures)
	|			THEN -2
	|		WHEN VALUE(Enum.ItemAccountingFeatures.PerformedBySellerCompany)
	|			THEN -1
	|		ELSE 0
	|	END AS OutputPriority
	|FROM
	|	Enum.ItemAccountingFeatures AS ItemAccountingFeatures,
	|	Constants AS SourcesOfConstants
	|WHERE
	|	&FilterByFunctionalOptions
	|	AND &FilterByLine
	|	AND CASE
	|		WHEN ItemAccountingFeatures.Ref IN (&FeaturesOfServiceAccounting)
	|			THEN VALUE(Enum.ItemsTypes.OperationService)
	|		ELSE VALUE(Enum.ItemsTypes.OwnGoods)
	|	END IN (&ItemsType)
	|
	|ORDER BY
	|	OutputPriority,
	|	Description";
	
	Query.SetParameter("ItemsType", ItemsType);
	Query.SetParameter("FeaturesOfServiceAccounting", FeaturesOfServiceAccounting());
	ThereIsSelectionByLine = Not IsBlankString(Parameters.SearchString);
	If ThereIsSelectionByLine Then
		Query.SetParameter("SearchString", Parameters.SearchString + "%");
		QueryText = StrReplace(QueryText, "&FilterByLine", "&Description LIKE &SearchString");
	Else
		Query.SetParameter("FilterByLine", True);
	EndIf;
	
	AliasesOfConstantsUsed = CommonClientServer.CollapseArray(AliasesOfConstantsUsed);
	AliasesOfConstantsUsed = StrConcat(AliasesOfConstantsUsed, ",
	|	");
		
	QueryText = StrReplace(QueryText, "Constants AS SourcesOfConstants", AliasesOfConstantsUsed);
	QueryText = StrReplace(QueryText, "&FilterByFunctionalOptions", AccessibilityTexts);
	QueryText = StrReplace(QueryText, "&Description", NameText);
	
	ChoiceData = New ValueList;
	
	Query.Text = QueryText;
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		ItemPresentation = Selection.Description;
		If ThereIsSelectionByLine Then
			ItemPresentation = TMCommonUse.RowToMarkBeginningOfLineWithLayout(ItemPresentation, Parameters.SearchString);
		EndIf;
		
		ChoiceData.Add(Selection.Ref, ItemPresentation);
		
	EndDo;

EndProcedure

#EndRegion

#Region Private

Function SelectionDataByItemType(FilterItemsType)

	If FilterItemsType = Undefined Then
		FilterItemsType = New Array;
		For Each EnumerationElement In Enums.ItemsTypes Do
			FilterItemsType.Add(EnumerationElement);
		EndDo;
	EndIf;

	Filter = New Structure;
	Filter.Insert("ItemsType", FilterItemsType);

	SelectionDataParameters = New Structure;
	SelectionDataParameters.Insert("SearchString", "");
	SelectionDataParameters.Insert("Filter", Filter);
	ChoiceData = Enums.ItemAccountingFeatures.GetChoiceData(SelectionDataParameters);
	
	Return ChoiceData;
	
EndFunction

// Returns a list of features of service accounting.
// 
// Returns:
//   Array of EnumRef.ItemAccountingFeatures - List of features of service accounting.
//
Function FeaturesOfServiceAccounting() Export
	
	ReturnValue = New Array;
	ReturnValue.Add(PerformedBySellerCompany);
	ReturnValue.Add(PerformedByCompanyOnAgencyBasis);
	ReturnValue.Add(PerformedByPartner);
	
	Return ReturnValue;
	
EndFunction

#EndRegion

#EndIf
#EndIf

