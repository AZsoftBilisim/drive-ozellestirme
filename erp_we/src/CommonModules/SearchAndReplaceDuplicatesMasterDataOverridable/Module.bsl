#Region Public

// Rules for searching for Master Data duplicates when creating on the server.
// 
// Parameters:
//  Form - ClientApplicationForm
//  Cancel - Boolean
Procedure MasterDataDuplicateSearchRules_WhenCreatingAtServer(Form, Cancel) Export
	Object = Form.Object;
	Items = Form.Items;
	ThisIsRuleForItemUniquenessSettings = False;
	If Object.Ref = Catalogs.MasterDataDuplicateSearchRules.Catalog_Products_BySettingUniquenessOfTypeOfItem
		Or Object.Ref = Catalogs.MasterDataDuplicateSearchRules.Catalog_ItemsCharacteristics_BySettingUniquenessOfItemType Then 
		ThisIsRuleForItemUniquenessSettings = True;
	EndIf;
	Items.QueryText.Enabled = Not ThisIsRuleForItemUniquenessSettings;
	Items.ButtonRequestGroup.Enabled = Not ThisIsRuleForItemUniquenessSettings;
	Items.DecorationRuleForUniquenessSettings.Visible = ThisIsRuleForItemUniquenessSettings;
	Items.MetadataObject.Enabled = Not Object.Predefined;
EndProcedure

// See Catalogs.MasterDataDuplicateSearchRules.GenerateRequestBasedOnRule
// 
Function GenerateRequestBasedOnRule(Rule, OnlyNewTakes = True, Objects = Undefined) Export
	If Rule = Catalogs.MasterDataDuplicateSearchRules.Catalog_Products_BySettingUniquenessOfTypeOfItem Then
		NameOfTheReferenceTable = "Products";
		NameOfTSAttributesForControl = "AttributesForProductsControl";
	Else
		NameOfTheReferenceTable = "ItemsCharacteristics";
		NameOfTSAttributesForControl = "AttributesForItemVariantsControl";
	EndIf;
	Query = New Query;
	QueryText = 
	"SELECT
	|	ProductKind.Ref AS Ref,
	|	ProductKind.Ref.Description AS Description,
	|	ProductKind.AttributeName AS AttributeName,
	|	ProductKind.Property AS Property
	|FROM
	|	Catalog.ItemKinds.AttributesForProductsControl AS ProductKind
	|WHERE
	|	ProductKind.Uniqueness
	|	AND ProductKind.AttributeName <> ""Barcode""";
	QueryText = StrReplace(QueryText, "AttributesForProductsControl", NameOfTSAttributesForControl);
	Query.Text = QueryText;
	UniquenessControlDetails = Query.Execute().Unload();
	If UniquenessControlDetails.Count() = 0 Then
		Query = New Query;
		Query.Text = 
		"SELECT
		|	UNDEFINED AS Duplicate1,
		|	UNDEFINED AS Ref1,
		|	UNDEFINED AS Code,
		|	UNDEFINED AS Group
		|WHERE
		|	FALSE";
		Return Query;
	EndIf;

	ItemKinds = UniquenessControlDetails.Copy();
	ItemKinds.GroupBy("Ref, Description");
	
	QueryNumber = 1;
	
	QueriesTexts = New Array;
	FinalRequest = New Array;
	IndexOfPropertyParameters = 1;
	Query = New Query;
	For Each ProductKind In ItemKinds Do
		ThereAreUniqueProperties = False;
		TheStructureOfTheSearch = New Structure("Ref", ProductKind.Ref);
		Attributes = UniquenessControlDetails.FindRows(TheStructureOfTheSearch);
		For Each Attribute In Attributes Do
			If ValueIsFilled(Attribute.Property) Then
				ThereAreUniqueProperties = True;
				Break;
			EndIf;
		EndDo;
		If ThereAreUniqueProperties Then
			QueryTextByItemType = 
			"SELECT
			|	Catalog.ProductKind AS ProductKind,
			|	Catalog.Ref AS Ref,
			|	TRUE
			|INTO ItemTypeRequestNumber
			|FROM
			|	Catalog.Products AS Catalog
			|	// Joins
			|WHERE
			|	Catalog.ProductKind = &ItemTypeRequestNumber";
			Joins = New Array;
			IndexOf = 0;
			SelectionFields = New Array;
			For Each Attribute In Attributes Do
				If Not ValueIsFilled(Attribute.Property) Then
					Continue;
				EndIf;
				IndexOf = IndexOf + 1;
				Join = "LEFT JOIN Catalog.Products.AdditionalAttributes AS AdditionalDetailsIndex 
				|	ON Catalog.Ref = AdditionalDetailsIndex.Ref
				|		AND AdditionalDetailsIndex.Property = &PropertyIndexOfPropertyParameters";
				ParameterName = StrTemplate("Property%1", IndexOfPropertyParameters);
				Join = StrReplace(Join, "Products", NameOfTheReferenceTable);
				Join = StrReplace(Join, "&PropertyIndexOfPropertyParameters", "&" + ParameterName);
				Join = StrReplace(Join, "AdditionalDetailsIndex", StrTemplate("AddAttributes%1", IndexOf));
				Joins.Add(Join);
				Query.SetParameter(ParameterName, Attribute.Property);
				IndexOfPropertyParameters = IndexOfPropertyParameters + 1;
				TemplateForSelectionFields = "
				|	AdditionalDetailsIndex.Property AS Property_Index,
				|	AdditionalDetailsIndex.Value AS IndexValue";
				TemplateForSelectionFields = StrReplace(TemplateForSelectionFields, "Property_Index", StrTemplate("Property%1", IndexOf));
				TemplateForSelectionFields = StrReplace(TemplateForSelectionFields, "IndexValue", StrTemplate("Value%1", IndexOf));
				TemplateForSelectionFields = StrReplace(TemplateForSelectionFields, "AdditionalDetailsIndex", StrTemplate("AddAttributes%1", IndexOf)); 
				SelectionFields.Add(TemplateForSelectionFields);
			EndDo;
			ParameterName = StrTemplate("ProductKind%1",QueryNumber);
			QueryTextByItemType = StrReplace(QueryTextByItemType, 
			"TRUE",
			StrConcat(SelectionFields, ",
			|	"));
			QueryTextByItemType = StrReplace(QueryTextByItemType,
			"Products",
			NameOfTheReferenceTable);
			QueryTextByItemType = StrReplace(QueryTextByItemType,
			"ItemTypeRequestNumber",
			ParameterName);
			QueryTextByItemType = StrReplace(QueryTextByItemType,
			"// Joins",
			StrConcat(Joins,"
			|
			|"));
			QueriesTexts.Add(QueryTextByItemType);
			
			TextOfFinalRequest = 
			"SELECT
			|	MasterDataDouble.Ref AS Duplicate1,
			|	MasterDataOriginal.Ref AS Ref1,
			|	UNDEFINED AS Code,
			|	""GroupPresentation"" AS Group
			|FROM
			|	ItemTypeRequestNumber AS MasterDataOriginal
			|		INNER JOIN ItemTypeRequestNumber AS MasterDataDouble
			|		ON NOT MasterDataOriginal.Ref = MasterDataDouble.Ref
			|			AND MasterDataOriginal.Ref.Owner = MasterDataDouble.Ref.Owner
			|			// Joins
			|		LEFT JOIN InformationRegister.MasterDataDuplicates AS MasterDataTakesOriginal
			|		ON MasterDataTakesOriginal.Original = MasterDataOriginal.Ref
			|		LEFT JOIN InformationRegister.MasterDataDuplicates AS TakesMasterDataTake
			|		ON TakesMasterDataTake.Duplicate1 = MasterDataOriginal.Ref
			|		LEFT JOIN InformationRegister.MasterDataDuplicates AS MasterDataTakesOriginal1
			|		ON MasterDataTakesOriginal1.Original = MasterDataDouble.Ref
			|		LEFT JOIN InformationRegister.MasterDataDuplicates AS TakesMasterDataTake1
			|		ON TakesMasterDataTake1.Duplicate1 = MasterDataDouble.Ref
			|		LEFT JOIN InformationRegister.MasterDataDuplicatesToConfirm AS DuplicatesOfNsikconfirmationOriginal
			|		ON DuplicatesOfNsikconfirmationOriginal.Duplicate1 = MasterDataOriginal.Ref
			|			AND &OnlyNewTakes
			|		LEFT JOIN InformationRegister.MasterDataDuplicatesToConfirm AS DoublesNSIKConfirmationDouble
			|		ON DoublesNSIKConfirmationDouble.Duplicate1 = MasterDataDouble.Ref
			|			AND &OnlyNewTakes
			|WHERE
			|	(MasterDataTakesOriginal.Original IS NULL
			|		AND TakesMasterDataTake.Original IS NULL
			|		AND MasterDataTakesOriginal.Duplicate1 IS NULL
			|		AND TakesMasterDataTake.Duplicate1 IS NULL
			|		AND MasterDataTakesOriginal1.Original IS NULL
			|		AND TakesMasterDataTake1.Original IS NULL
			|		AND MasterDataTakesOriginal1.Duplicate1 IS NULL
			|		AND TakesMasterDataTake1.Duplicate1 IS NULL)
			|	AND CASE WHEN
			|		&OnlyNewTakes 
			|	THEN
			|		DuplicatesOfNsikconfirmationOriginal.Duplicate1 IS NULL
			|				AND DoublesNSIKConfirmationDouble.Duplicate1 IS NULL
			|	ELSE TRUE
			|	END
			|	AND TRUE";
			
			Joins = New Array;
			Query.SetParameter("OnlyNewTakes", OnlyNewTakes);
			ConnectionTemplateByBankingDetails = "MasterDataOriginal.Ref.%1 = MasterDataDouble.Ref.%1";
			ConnectionTemplateWithAdditionalAttributes = "
			|	MasterDataOriginal.Property%1 = MasterDataDouble.Property%1
			|	AND MasterDataOriginal.Value%1 = MasterDataDouble.Value%1";
			IndexOf = 0;
			FieldValues = New Array;
			For Each Attribute In Attributes Do
				If Not ValueIsFilled(Attribute.Property) Then
					If Metadata.Catalogs[NameOfTheReferenceTable].Attributes.Find(Attribute.AttributeName) = Undefined Then
						Continue;
					EndIf;
					Joins.Add(StrTemplate(ConnectionTemplateByBankingDetails, Attribute.AttributeName));
				Else
					IndexOf = IndexOf + 1;
					Joins.Add(StrTemplate(ConnectionTemplateWithAdditionalAttributes, IndexOf));
				EndIf;
				FieldValues.Add(String(Attribute.Property));
			EndDo;
			DuplicatesGroup = ProductKind.Description + " (%1)";
			DuplicatesGroup = StrTemplate(DuplicatesGroup, StrConcat(FieldValues, ", "));
			If NameOfTheReferenceTable = "Products" Then
				TextOfFinalRequest = StrReplace(TextOfFinalRequest, 
					"AND MasterDataOriginal.Ref.Owner = MasterDataDouble.Ref.Owner",
					"");
			EndIf;
			TextOfFinalRequest = StrReplace(TextOfFinalRequest, "ItemTypeRequestNumber", ParameterName);
			TextOfFinalRequest = StrReplace(TextOfFinalRequest, "GroupPresentation", DuplicatesGroup);
			TextOfFinalRequest = StrReplace(TextOfFinalRequest, "// Joins", " And " + StrConcat(Joins,"
			|	AND "));
			
			If NameOfTheReferenceTable = "Products" Then
				TextOfFinalRequest = StrReplace(TextOfFinalRequest, "UNDEFINED", "MasterDataOriginal.Ref.Code");
			EndIf;
			If Not Objects = Undefined Then
				Query.SetParameter("Objects", Objects);
				TextOfFinalRequest = StrReplace(TextOfFinalRequest, "TRUE",
				"MasterDataOriginal.Ref IN (&Objects) AND MasterDataDouble.Ref IN (&Objects)");
			EndIf;
			Query.SetParameter(ParameterName, ProductKind.Ref);
			FinalRequest.Add(TextOfFinalRequest);
		Else
			QueryTextByItemType = 
			"SELECT
			|	MasterDataDouble.Ref AS Duplicate1,
			|	MasterDataOriginal.Ref AS Ref1,
			|	UNDEFINED AS Code,
			|	""GroupPresentation"" AS Group
			|FROM
			|	Catalog.Products AS MasterDataOriginal
			|		INNER JOIN Catalog.Products AS MasterDataDouble
			|		ON NOT MasterDataOriginal.Ref = MasterDataDouble.Ref
			|			AND MasterDataOriginal.Ref.Owner = MasterDataDouble.Ref.Owner
			|			// Joins
			|		LEFT JOIN InformationRegister.MasterDataDuplicates AS MasterDataTakesOriginal
			|		ON MasterDataTakesOriginal.Original = MasterDataOriginal.Ref
			|		LEFT JOIN InformationRegister.MasterDataDuplicates AS TakesMasterDataTake
			|		ON TakesMasterDataTake.Duplicate1 = MasterDataOriginal.Ref
			|		LEFT JOIN InformationRegister.MasterDataDuplicates AS MasterDataTakesOriginal1
			|		ON MasterDataTakesOriginal1.Original = MasterDataDouble.Ref
			|		LEFT JOIN InformationRegister.MasterDataDuplicates AS TakesMasterDataTake1
			|		ON TakesMasterDataTake1.Duplicate1 = MasterDataDouble.Ref
			|		LEFT JOIN InformationRegister.MasterDataDuplicatesToConfirm AS DuplicatesOfNsikconfirmationOriginal
			|		ON DuplicatesOfNsikconfirmationOriginal.Duplicate1 = MasterDataOriginal.Ref
			|			AND &OnlyNewTakes
			|		LEFT JOIN InformationRegister.MasterDataDuplicatesToConfirm AS DoublesNSIKConfirmationDouble
			|		ON DoublesNSIKConfirmationDouble.Duplicate1 = MasterDataDouble.Ref
			|			AND &OnlyNewTakes
			|WHERE
			|	MasterDataOriginal.ProductKind = &ItemTypeRequestNumber
			|	AND ((MasterDataTakesOriginal.Original IS NULL
			|		AND TakesMasterDataTake.Original IS NULL
			|		AND MasterDataTakesOriginal.Duplicate1 IS NULL
			|		AND TakesMasterDataTake.Duplicate1 IS NULL
			|		AND MasterDataTakesOriginal1.Original IS NULL
			|		AND TakesMasterDataTake1.Original IS NULL
			|		AND MasterDataTakesOriginal1.Duplicate1 IS NULL
			|		AND TakesMasterDataTake1.Duplicate1 IS NULL)
			|	AND CASE WHEN
			|		&OnlyNewTakes 
			|	THEN
			|		DuplicatesOfNsikconfirmationOriginal.Duplicate1 IS NULL
			|				AND DoublesNSIKConfirmationDouble.Duplicate1 IS NULL
			|	ELSE TRUE
			|	END)
			|	AND TRUE";
			Query.SetParameter("OnlyNewTakes", OnlyNewTakes);
			Joins = New Array;
			QueryTextByItemType = StrReplace(QueryTextByItemType, "Products", NameOfTheReferenceTable);
			FieldValues = New Array;
			For Each Attribute In Attributes Do
				If Metadata.Catalogs[NameOfTheReferenceTable].Attributes.Find(Attribute.AttributeName) = Undefined Then
					Continue;
				Else 
					AttributeMetadata = Metadata.Catalogs[NameOfTheReferenceTable].Attributes[Attribute.AttributeName];
					FieldValues.Add(AttributeMetadata.Synonym);
				EndIf;
				Join = "MasterDataOriginal.Ref = MasterDataDouble.Ref";
				Joins.Add(StrReplace(Join, "Ref", Attribute.AttributeName));
			EndDo;
			DuplicatesGroup = ProductKind.Description + " (%1)";
			DuplicatesGroup = StrTemplate(DuplicatesGroup, StrConcat(FieldValues, ", "));
			QueryTextByItemType = StrReplace(QueryTextByItemType, "GroupPresentation", DuplicatesGroup);
			If NameOfTheReferenceTable = "Products" Then
				QueryTextByItemType = StrReplace(QueryTextByItemType, 
					"AND MasterDataOriginal.Ref.Owner = MasterDataDouble.Ref.Owner",
					"");
				QueryTextByItemType = StrReplace(QueryTextByItemType,
					"UNDEFINED",
					"MasterDataOriginal.Code");
			EndIf;
			Joins = StrConcat(Joins, "
			|		AND ");
			ParameterName = StrTemplate("ProductKind%1", QueryNumber);
			QueryTextByItemType = StrReplace(QueryTextByItemType, "// Joins", "And " + Joins);
			QueryTextByItemType = StrReplace(QueryTextByItemType, "&ItemTypeRequestNumber", "&"+ParameterName);
			FinalRequest.Add(QueryTextByItemType);
			
			Query.SetParameter(ParameterName, ProductKind.Ref);
			If Not Objects = Undefined Then
				Query.SetParameter("Objects", Objects);
				TextOfFinalRequest = StrReplace(TextOfFinalRequest, "TRUE",
				"MasterDataOriginal.Ref IN (&Objects) AND MasterDataDouble.Ref IN (&Objects)");
			EndIf;
		EndIf;
		
		QueryNumber = QueryNumber + 1;
	EndDo;
	FinalRequest = StrConcat(FinalRequest, "
		|
		|	UNION
		|");
	QueriesTexts.Add(FinalRequest);
	QueryText = StrConcat(QueriesTexts, "
	|
	|;
	|");
	Query.Text = QueryText;
	Return Query;
EndFunction

// Fill in the supplied rule.
// 
// Parameters:
//  Object - CatalogRef.MasterDataDuplicateSearchRules
//
Procedure FillInSuppliedRule(Object) Export
	
	If TypeOf(Object) = Type("CatalogRef.MasterDataDuplicateSearchRules") Then
		Object = Object.GetObject();
	EndIf;
	
	If (Object.Ref = Catalogs.MasterDataDuplicateSearchRules.Catalog_Products_BySettingUniquenessOfTypeOfItem 
		Or Object.Ref = Catalogs.MasterDataDuplicateSearchRules.Catalog_ItemsCharacteristics_BySettingUniquenessOfItemType)
		And Not Object.Overridable_1 Then
		Object.Overridable_1 = True;
	EndIf;
	QueryText = QueryTextOfSuppliedRule(Object.Ref);
	LongDesc = DescriptionOfSuppliedRule(Object.Ref);
	Description = NameOfSuppliedRule(Object.Ref);
	Id = MetadataObjectOfSuppliedRule(Object.PredefinedDataName);

	RequestStructure = New Structure;
	RequestStructure.Insert("QueryText", QueryText);
	Object.Query = New ValueStorage(RequestStructure, New Deflation(9));
	Object.MetadataObject = Id;
	Object.LongDesc = LongDesc;
	Object.Description = Description;
EndProcedure

// The Query Text of the supplied rule.
// 
// Parameters:
//  Ref - CatalogRef.MasterDataDuplicateSearchRules - Ref
// 
// Returns:
//  String - The Query Text Of The Supplied Rule
Function QueryTextOfSuppliedRule(Ref) Export
	LanguagesInfo = NationalLanguageSupportServer.LanguagesInfo();
	QueryText = "";
	If Ref = Catalogs.MasterDataDuplicateSearchRules.Catalog_Counterparties_TINKPPMatches Then
		QueryText = QueryText_DuplicateSearchRules_Counterparties_INNKPPMatches();
	ElsIf Ref = Catalogs.MasterDataDuplicateSearchRules.Catalog_Partners_ContactDetailsMatch Then
		QueryText = QueryText_DuplicateSearchRules_Partners_ContactDetailsMatch();
	ElsIf Ref = Catalogs.MasterDataDuplicateSearchRules.Catalog_Counterparties_ContactDetaiMatchesAndTINIsNotFilledIn Then
		QueryText = QueryText_DuplicateSearchRules_Counterparties_ContactDetaiMatchesAndTINIsNotFilledIn();
	ElsIf Ref = Catalogs.MasterDataDuplicateSearchRules.Catalog_Products_NameMatches Then
		QueryText = QueryText_DuplicateSearchRules_ItemList_NameMatches(LanguagesInfo);
	ElsIf Ref = Catalogs.MasterDataDuplicateSearchRules.Catalog_Partners_NameMatches Then
		QueryText = QueryText_DuplicateSearchRules_Partners_NameMatches();
	ElsIf Ref = Catalogs.MasterDataDuplicateSearchRules.Catalog_ItemsCharacteristics_NameMatches Then
		QueryText = QueryText_DuplicateSearchRules_ItemCharacteristics_NameMatches(LanguagesInfo);
	ElsIf Ref = Catalogs.MasterDataDuplicateSearchRules.Catalog_Counterparties_SameNameAndContactDetails Then
		QueryText = QueryText_DuplicateSearchRules_Counterparties_NameAndContactDetailsMatch();
	ElsIf Ref = Catalogs.MasterDataDuplicateSearchRules.Catalog_Counterparties_BankAccountNumberMatches Then
		QueryText = QueryText_DuplicateSearchRules_Counterparties_BankAccountNumberMatches();
	ElsIf Ref = Catalogs.MasterDataDuplicateSearchRules.Catalog_Counterparties_RegistrationOrTaxNumberOfNonResidentMatches Then
		QueryText = QueryText_DuplicateSearchRules_Counterparties_NonResidentRegistrationOrTaxNumberMatches();
	EndIf;
	Return QueryText;
EndFunction

// Name of the supplied rule.
// 
// Parameters:
//  Ref - CatalogRef.MasterDataDuplicateSearchRules - Ref
// 
// Returns:
//  String - Name of The Supplied Rule
Function NameOfSuppliedRule(Ref) Export
	If Ref = Catalogs.MasterDataDuplicateSearchRules.Catalog_Counterparties_TINKPPMatches Then
		Description = NStr("ru = 'Совпадает ИНН';
							|vi = 'TIN matches';
							|en = 'TIN matches'; fa = 'TIN matches';
							|it = 'TIN matches';
							|pl = 'TIN matches';
							|tr = 'VKN eşleşiyor'");
	Else
		Description = Common.ObjectAttributeValue(Ref, "Description");
	EndIf;
	Return Description;
EndFunction

// Description of the supplied rule.
// 
// Parameters:
//  Ref - CatalogRef.MasterDataDuplicateSearchRules - Ref
// 
// Returns:
//  String - Description of The Supplied Rule
Function DescriptionOfSuppliedRule(Ref) Export
	If Ref = Catalogs.MasterDataDuplicateSearchRules.Catalog_Counterparties_TINKPPMatches Then
		LongDesc = NStr("ru = 'Поиск контрагентов одинакового типа с совпадающими ИНН';
						|vi = 'Search for counterparties of the same type with the same TIN';
						|en = 'Search for counterparties of the same type with the same TIN'; fa = 'Search for counterparties of the same type with the same TIN';
						|it = 'Search for counterparties of the same type with the same TIN';
						|pl = 'Search for counterparties of the same type with the same TIN';
						|tr = 'Aynı türdeki cari hesapların, eşleşen   vergi numarası ile aranması'");
	ElsIf Ref = Catalogs.MasterDataDuplicateSearchRules.Catalog_Counterparties_SameNameAndContactDetails Then
		LongDesc = NStr("ru = 'Поиск контрагентов одинакового типа с совпадающим наименованием и совпадающими или отсутсвующими адресами';
						|vi = 'Search for counterparties of the same type with the same description and matching or missing addresses';
						|en = 'Search for counterparties of the same type with the same description and matching or missing addresses'; fa = 'Search for counterparties of the same type with the same description and matching or missing addresses';
						|it = 'Search for counterparties of the same type with the same description and matching or missing addresses';
						|pl = 'Search for counterparties of the same type with the same description and matching or missing addresses';
						|tr = 'Aynı türdeki cari hesapların, eşleşen ada ve eşleşen veya bulunmayan adreslere göre aranması'");
	ElsIf Ref = Catalogs.MasterDataDuplicateSearchRules.Catalog_Counterparties_BankAccountNumberMatches Then
		LongDesc = NStr("ru = 'Поиск контрагентов с одинаковыми номерами банковских счетов';
						|vi = 'Search for counterparties with the same bank account numbers';
						|en = 'Search for counterparties with the same bank account numbers'; fa = 'Search for counterparties with the same bank account numbers';
						|it = 'Search for counterparties with the same bank account numbers';
						|pl = 'Search for counterparties with the same bank account numbers';
						|tr = 'Aynı banka hesap numarasına sahip cari hesapların aranması'");
	ElsIf Ref = Catalogs.MasterDataDuplicateSearchRules.Catalog_Counterparties_RegistrationOrTaxNumberOfNonResidentMatches Then
		LongDesc = NStr("ru = 'Поиск контрагентов-нерезидентов с одинаковым налоговым или регистрационным номером';
						|vi = 'Search for non-resident counterparties with the same tax or registration number';
						|en = 'Search for non-resident counterparties with the same tax or registration number'; fa = 'Search for non-resident counterparties with the same tax or registration number';
						|it = 'Search for non-resident counterparties with the same tax or registration number';
						|pl = 'Search for non-resident counterparties with the same tax or registration number';
						|tr = 'Yerleşik olmayan cari hesapların, aynı vergi veya kayıt numarasına göre aranması'");
	ElsIf Ref = Catalogs.MasterDataDuplicateSearchRules.Catalog_Counterparties_ContactDetaiMatchesAndTINIsNotFilledIn Then
		LongDesc = NStr("ru = 'Поиск контрагентов с совпадающей контактной информацией (адрес, телефон, электронная почта и т.д.) и не заполненным ИНН у одного или обоих контрагентов';
						|vi = 'Search for counterparties with the same contact information (address, phone, e-mail, and other) and empty TIN for one or both counterparties';
						|en = 'Search for counterparties with the same contact information (address, phone, e-mail, and other) and empty TIN for one or both counterparties'; fa = 'Search for counterparties with the same contact information (address, phone, e-mail, and other) and empty TIN for one or both counterparties';
						|it = 'Search for counterparties with the same contact information (address, phone, e-mail, and other) and empty TIN for one or both counterparties';
						|pl = 'Search for counterparties with the same contact information (address, phone, e-mail, and other) and empty TIN for one or both counterparties';
						|tr = 'Eşleşen iletişim bilgilerine (adres, telefon, e-posta vb.) sahip ve bir veya iki cari hesapta vergi numarası doldurulmamış cari hesapların aranması'");
		
	ElsIf Ref = Catalogs.MasterDataDuplicateSearchRules.Catalog_Partners_NameMatches Then
		LongDesc = NStr("ru = 'Поиск партнеров с одинаковым наименованием и отсутствием контактов или совпадающими адресными данными';
						|vi = 'Search for partners with the same description and no contacts or the same address data';
						|en = 'Search for partners with the same description and no contacts or the same address data'; fa = 'Search for partners with the same description and no contacts or the same address data';
						|it = 'Search for partners with the same description and no contacts or the same address data';
						|pl = 'Search for partners with the same description and no contacts or the same address data';
						|tr = 'Aynı ada sahip ve iletişim bilgisi olmayan veya eşleşen adres verilerine sahip iş ortaklarının aranması'");
	ElsIf Ref = Catalogs.MasterDataDuplicateSearchRules.Catalog_Partners_ContactDetailsMatch Then
		LongDesc = NStr("ru = 'Поиск партнеров с совпадающими адресами и телефоном/адресом электронной почты';
						|vi = 'Search for partners with the same addresses and phone/email address';
						|en = 'Search for partners with the same addresses and phone/email address'; fa = 'Search for partners with the same addresses and phone/email address';
						|it = 'Search for partners with the same addresses and phone/email address';
						|pl = 'Search for partners with the same addresses and phone/email address';
						|tr = 'Eşleşen adreslere ve telefon/e-posta adresine sahip iş ortaklarının aranması'");

	ElsIf Ref = Catalogs.MasterDataDuplicateSearchRules.Catalog_Products_NameMatches Then
		LongDesc = NStr("ru = 'Поиск номенклатуры с совпадающим наименованием и другими ключевыми реквизитами (вид, единица измерения и др.)';
						|vi = 'Search for items with the same description and other key attributes (item kind, unit of measure, and so on)';
						|en = 'Search for items with the same description and other key attributes (item kind, unit of measure, and so on)'; fa = 'Search for items with the same description and other key attributes (item kind, unit of measure, and so on)';
						|it = 'Search for items with the same description and other key attributes (item kind, unit of measure, and so on)';
						|pl = 'Search for items with the same description and other key attributes (item kind, unit of measure, and so on)';
						|tr = 'Eşleşen ada ve diğer anahtar özniteliklere (tür, ölçü birimi vb.) sahip ürünlerin aranması'");
	ElsIf Ref = Catalogs.MasterDataDuplicateSearchRules.Catalog_Products_BySettingUniquenessOfTypeOfItem Then
		LongDesc = NStr("ru = 'Поиск дублей номенклатуры по настройкам уникальности вида номенклатуры (для номенклатуры)';
						|vi = 'Search for item duplicates by uniqueness settings of item kind (for items)';
						|en = 'Search for item duplicates by uniqueness settings of item kind (for items)'; fa = 'Search for item duplicates by uniqueness settings of item kind (for items)';
						|it = 'Search for item duplicates by uniqueness settings of item kind (for items)';
						|pl = 'Search for item duplicates by uniqueness settings of item kind (for items)';
						|tr = 'Ürün türü benzersizlik ayarlarına göre ürün yinelenenlerinin aranması (ürünler için)'");
		
	ElsIf Ref = Catalogs.MasterDataDuplicateSearchRules.Catalog_ItemsCharacteristics_NameMatches Then
		LongDesc = NStr("ru = 'Поиск характеристик одной номенклатуры с одинаковым наименованием';
						|vi = 'Search for variants of the same item with the same description';
						|en = 'Search for variants of the same item with the same description'; fa = 'Search for variants of the same item with the same description';
						|it = 'Search for variants of the same item with the same description';
						|pl = 'Search for variants of the same item with the same description';
						|tr = 'Aynı ürünün aynı ada sahip özelliklerinin aranması'");
	ElsIf Ref = Catalogs.MasterDataDuplicateSearchRules.Catalog_ItemsCharacteristics_BySettingUniquenessOfItemType Then
		LongDesc = NStr("ru = 'Поиск дублей характеристик номенклатуры по настройкам уникальности вида номенклатуры (для характеристик номенклатуры)';
						|vi = 'Search for item variant duplicates by uniqueness settings of item kind (for item variants)';
						|en = 'Search for item variant duplicates by uniqueness settings of item kind (for item variants)'; fa = 'Search for item variant duplicates by uniqueness settings of item kind (for item variants)';
						|it = 'Search for item variant duplicates by uniqueness settings of item kind (for item variants)';
						|pl = 'Search for item variant duplicates by uniqueness settings of item kind (for item variants)';
						|tr = 'Öğe türü benzersizlik ayarlarına göre öğe varyantı yinelenenlerinin aranması (öğe özellikleri için)'");
	EndIf;
	
	Return LongDesc;
EndFunction

// Allows you to set a list of subordinate objects and their relationship to the main objects.
// The Attributes of the linked object will be shown as part of the Attributes of the main object in the report on the comparison of duplicates.
//
// Parameters:
//   SubordinateObjectsLinks - ValueTable - table of links See SearchAndReplaceDuplicatesMasterData.RelatedObjects
//
// Example:
//   Connection = Connection of subordinate objects.Add();
//   Communication.Related Object = Metadata.Reference books.Counterparties;
//   Communication.Polesvyazi = "Partner";
//
Procedure WhenDefiningRelatedObjects(SubordinateObjectsLinks) Export
	
	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		Link = SubordinateObjectsLinks.Add();
		Link.LinkedObject = Metadata.Catalogs.Counterparties;
		Link.LinksField = "Partner";
	EndIf;
	
EndProcedure

// By name, it defines the Attributes and table parts that should be excluded from display in the duplicate comparison report.
// For example, it is recommended to hide such service Attributes as the deletion tag and the name of certain data. 
//
// Parameters:
//   ServiceDetails_ - ValueTable - collection for adding restrictions See SearchAndReplaceDuplicatesMasterData.ExceptionsToComparisonDetails
//
Procedure WhenDefiningExceptionsOfDetails(ServiceDetails_) Export
	
	AttributesNames = "DeletionMark,PredefinedDataName,Predefined,Presentations";
	For Each AttributeName In StrSplit(AttributesNames, ", ", False) Do
		Restriction = ServiceDetails_.Add();
		Restriction.Metadata = Metadata.Catalogs.Products;
		Restriction.AttributeName = AttributeName;
	EndDo;
	
	AttributesNames = "DeletionMark,PredefinedDataName,Predefined,Presentations";
	For Each AttributeName In StrSplit(AttributesNames, ", ", False) Do
		Restriction = ServiceDetails_.Add();
		Restriction.Metadata = Metadata.Catalogs.ItemsCharacteristics;
		Restriction.AttributeName = AttributeName;
	EndDo;
	
	AttributesNames = "DeletionMark,PredefinedDataName,Predefined";
	For Each AttributeName In StrSplit(AttributesNames, ", ", False) Do
		Restriction = ServiceDetails_.Add();
		Restriction.Metadata = Metadata.Catalogs.Partners;
		Restriction.AttributeName = AttributeName;
	EndDo;
	
	AttributesNames = "DeletionMark,PredefinedDataName,Predefined,CRTRHistory,NameHistory";
	For Each AttributeName In StrSplit(AttributesNames, ", ", False) Do
		Restriction = ServiceDetails_.Add();
		Restriction.Metadata = Metadata.Catalogs.Counterparties;
		Restriction.AttributeName = AttributeName;
	EndDo;
	
EndProcedure

// Allows you to supplement the props with additional Attributes that are stored in the table parts
// to display them in the report on the comparison of doubles.
//
// Parameters:
//   AdditionalAttributes - ValueTable:
//      *TabularSectionName - String - the name of the table part that is described as the Attribute.
//      *ColumnProps - String - the name of the column in the table part containing the Attribute name.
//      *ValueColumn_ - String - the name of the column in the table part containing the Attribute value.
//
Procedure WhenDeterminingAdditionalDetails(AdditionalAttributes) Export
	
	TabularSectionDetails = AdditionalAttributes.Add();
	TabularSectionDetails.TabularSectionName = "AdditionalAttributes";
	TabularSectionDetails.ColumnProps = "Property";
	TabularSectionDetails.ValueColumn_ = "Value";
	
	TabularSectionDetails = AdditionalAttributes.Add();
	TabularSectionDetails.TabularSectionName = "ContactInformation";
	TabularSectionDetails.ColumnProps = "Kind";
	TabularSectionDetails.ValueColumn_ = "Presentation";
	
EndProcedure

// Allows you to check the possibility of replacing duplicates with originals according to the application rules.
// If it is impossible to replace links in the database for some pair of replacement pairs, because this will disrupt
// the correct operation of any mechanism, then a double from such a pair must be added to the collection of impossible replacements.
// For the convenience of performing checks, the method is called several times to ensure grouping by link type.
//
// Parameters:
//   ReplacementPairs - Map of KeyAndValue - replacement pairs:
//    * Key - CatalogRef,ChartOfCharacteristicTypesRef - duplicate link.
//    * Value - CatalogRef,ChartOfCharacteristicTypesRef - the original link.
//   ImpossibleReplacements - ValueTable - table of impossible replacements:
//    * Ref - CatalogRef,ChartOfCharacteristicTypesRef - duplicate link.
//    * ErrorText - String - error text explaining the reason for the impossibility of replacement.
//    * ErrorObject - AnyRef - an object that contains a link to the duplicate.
//   Type - Type - The type of links in the Substitution parameter.
//
//  Example:
//    For Each Dubloriginal Of The Replacement Param Cycle
//      If it is not possible to replace the Original database (Duplicate Original) Then
//        Impossible to change = Replacement is not possible.Add();
//        It is impossible to change.Link = Duplicate Original.Key;
//        It is impossible to change.Text errors = NStr ("ru = 'It is forbidden to replace the nomenclature with the article 00001'");
//        It is impossible to change.Error Object = Document Link;
//      The end if;
//    The end of the cycle;
//
Procedure CheckPossibilityOfReplacingDuplicates(ReplacementPairs, ImpossibleReplacements, Type) Export
	TMCommonUse.CheckPossibilityOfReplacingDuplicates(ReplacementPairs, ImpossibleReplacements, Type);
EndProcedure

// Makes it possible to process pairs of duplicates after receiving them for a given rule.
//
// Parameters:
//   PairsOfTakes - ValueTable
//      *Reference - a reference link,a plan of types of characteristicslink - a possible double.
//      *Reference1 - a reference link,a plan of types of characteristicslink - a possible double.
//   Rule - CatalogRef.MasterDataDuplicateSearchRules
//
Procedure WhenSearchingForMasterDataDuplicates(PairsOfTakes, Rule) Export
	TMCommonUse.WhenSearchingForMasterDataDuplicates(PairsOfTakes, Rule);
EndProcedure

#EndRegion

#Region Private

#Region SuppliedRulesForFindingDuplicates

Function QueryText_DuplicateSearchRules_Counterparties_INNKPPMatches()
	QueryText = 
	"SELECT
	|	Counterparty.Ref,
	|	Counterparty1.Ref
	|FROM
	|	Catalog.Counterparties AS Counterparty
	|	INNER JOIN Catalog.Counterparties AS Counterparty1
	|	ON Counterparty.Ref < Counterparty1.Ref
	|WHERE
	|	Counterparty.TIN = Counterparty1.TIN
	
	
	|		AND Counterparty.CompanyIndividual = Counterparty1.CompanyIndividual
	|		AND Counterparty.LegalEntityIndividual = Counterparty1.LegalEntityIndividual
	|		AND NOT Counterparty.TIN = """"";
	Return QueryText;
EndFunction

Function QueryText_DuplicateSearchRules_Partners_ContactDetailsMatch()
	QueryText = 
	"SELECT DISTINCT
	|	PartnerCI.Ref AS Ref,
	|	ISNULL(AddressMatches.Ref, ISNULL(PhoneNumberMatches.Ref, EmailMailMatches.Ref)) AS Ref1
	|FROM
	|	Catalog.Partners.ContactInformation AS PartnerCI
	|		LEFT JOIN Catalog.Partners.ContactInformation AS AddressMatches
	|		ON (PartnerCI.Ref < AddressMatches.Ref)
	|			AND PartnerCI.Type = AddressMatches.Type
	|			AND (PartnerCI.Type = VALUE(Enum.ContactInformationTypes.Address))
	|			AND PartnerCI.Presentation = AddressMatches.Presentation
	|			AND PartnerCI.Ref.LegalEntityIndividual = AddressMatches.Ref.LegalEntityIndividual
	|			AND (NOT AddressMatches.Ref IS NULL)
	|		LEFT JOIN Catalog.Partners.ContactInformation AS PhoneNumberMatches
	|		ON (PartnerCI.Ref < PhoneNumberMatches.Ref)
	|			AND PartnerCI.Type = PhoneNumberMatches.Type
	|			AND (PartnerCI.Type = VALUE(Enum.ContactInformationTypes.Phone))
	|			AND PartnerCI.Presentation = PhoneNumberMatches.Presentation
	|			AND PartnerCI.Ref.LegalEntityIndividual = PhoneNumberMatches.Ref.LegalEntityIndividual
	|			AND (NOT PhoneNumberMatches.Ref IS NULL)
	|		LEFT JOIN Catalog.Partners.ContactInformation AS EmailMailMatches
	|		ON (PartnerCI.Ref < EmailMailMatches.Ref)
	|			AND PartnerCI.Type = EmailMailMatches.Type
	|			AND (PartnerCI.Type = VALUE(Enum.ContactInformationTypes.Email))
	|			AND PartnerCI.Presentation = EmailMailMatches.Presentation
	|			AND PartnerCI.Ref.LegalEntityIndividual = PhoneNumberMatches.Ref.LegalEntityIndividual
	|			AND (NOT EmailMailMatches.Ref IS NULL)
	|		LEFT JOIN Catalog.Partners.ContactInformation AS CurrentCIAddress
	|		ON PartnerCI.Ref = CurrentCIAddress.Ref
	|			AND (CurrentCIAddress.Type = VALUE(Enum.ContactInformationTypes.Address))
	|		LEFT JOIN Catalog.Partners.ContactInformation AS CurrentKIEmailMailPhone
	|		ON PartnerCI.Ref = CurrentKIEmailMailPhone.Ref
	|			AND (CurrentKIEmailMailPhone.Type IN (VALUE(Enum.ContactInformationTypes.Email), VALUE(Enum.ContactInformationTypes.Phone)))
	|WHERE
	|	NOT ISNULL(AddressMatches.Ref, ISNULL(PhoneNumberMatches.Ref, EmailMailMatches.Ref)) IS NULL
	|	AND (NOT CurrentCIAddress.Ref IS NULL
	|			OR NOT CurrentKIEmailMailPhone.Ref IS NULL)";
	Return QueryText;
EndFunction

Function QueryText_DuplicateSearchRules_Counterparties_ContactDetaiMatchesAndTINIsNotFilledIn()
	QueryText = 
	"SELECT DISTINCT
	|	Counterparty1.Ref AS Counterparty,
	|	Counterparty2.Ref AS Duplicate1
	|FROM
	|	Catalog.Counterparties AS Counterparty1
	|		INNER JOIN Catalog.Counterparties AS Counterparty2
	|		ON Counterparty1.Ref < Counterparty2.Ref
	|			AND Counterparty1.CompanyIndividual = Counterparty2.CompanyIndividual
	|			AND Counterparty1.LegalEntityIndividual = Counterparty2.LegalEntityIndividual
	|		INNER JOIN Catalog.Counterparties.ContactInformation AS KI1
	|		ON KI1.Ref = Counterparty1.Ref
	|		INNER JOIN Catalog.Counterparties.ContactInformation AS KI2
	|		ON KI2.Ref = Counterparty2.Ref
	|WHERE
	|	(Counterparty1.TIN = """"
	|			OR Counterparty2.TIN = """")
	|	AND (KI1.Type = KI2.Type
	|				AND KI1.Presentation <> """"
	|				AND KI1.Presentation = KI2.Presentation
	|			OR KI1.Type = VALUE(Enum.ContactInformationTypes.Phone)
	|				AND KI2.Type = VALUE(Enum.ContactInformationTypes.Phone)
	|				AND KI1.PhoneNumber <> """"
	|				AND KI1.PhoneNumber = KI2.PhoneNumber
	|			OR KI1.Type = VALUE(Enum.ContactInformationTypes.Email)
	|				AND KI2.Type = VALUE(Enum.ContactInformationTypes.Email)
	|				AND KI1.EMAddress <> """"
	|				AND KI1.EMAddress = KI2.EMAddress)";
	Return QueryText;
EndFunction

Function QueryText_DuplicateSearchRules_ItemList_NameMatches(LanguagesInfo)
	QueryText =
	"SELECT
	|	ProductsPresentations.Ref AS Ref,
	|	ProductsPresentations.DescriptionFull AS DescriptionFull,
	|	Products.ProductKind AS ProductKind,
	|	Products.UnitOfMeasure AS UnitOfMeasure,
	|	Products.Principal AS Principal,
	|	Products.Counterparty AS Counterparty,
	|	Products.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	Products.Quality AS Quality
	|INTO FullNameInDifferentLanguages
	|FROM
	|	Catalog.Products.Presentations AS ProductsPresentations
	|		LEFT JOIN Catalog.Products AS Products
	|		ON (ProductsPresentations.Ref = Products.Ref)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|" +
	"SELECT
	|	Products.Ref AS Ref,
	|	Products1.Ref AS Ref1
	|FROM
	|	Catalog.Products AS Products
	|		INNER JOIN Catalog.Products AS Products1
	|		ON (Products.Ref < Products1.Ref)
	|			AND Products.Description = Products1.Description
	|WHERE	
	|	Products.ProductKind.ItemsType = Products1.ProductKind.ItemsType
	|		AND Products.ProductKind.UseVariants = Products1.ProductKind.UseVariants
	|		AND Products.ProductKind.KeepAccountingByBatch = Products1.ProductKind.KeepAccountingByBatch
	|		AND Products.ProductKind.AccountingFeature = Products1.ProductKind.AccountingFeature
	|		AND Products.UnitOfMeasure = Products1.UnitOfMeasure
	|		AND Products.Principal = Products1.Principal
	|		AND Products.Counterparty = Products1.Counterparty
	|		AND Products.FinancialAccountingGroup = Products1.FinancialAccountingGroup
	|		AND Products.Quality = Products1.Quality
	|
	|UNION
	|
	|SELECT
	|	Products.Ref AS Ref,
	|	Products1.Ref AS Ref1
	|FROM
	|	Catalog.Products AS Products
	|		INNER JOIN Catalog.Products AS Products1
	|		ON (Products.Ref < Products1.Ref)
	|			AND Products.DescriptionLanguage1 = Products1.DescriptionLanguage1
	|WHERE
	|	&IsAdditionalLangUsed1
	|	AND Products.DescriptionLanguage1 <> """"
	|		AND Products.ProductKind.ItemsType = Products1.ProductKind.ItemsType
	|		AND Products.ProductKind.UseVariants = Products1.ProductKind.UseVariants
	|		AND Products.ProductKind.KeepAccountingByBatch = Products1.ProductKind.KeepAccountingByBatch
	|		AND Products.ProductKind.AccountingFeature = Products1.ProductKind.AccountingFeature
	|		AND Products.UnitOfMeasure = Products1.UnitOfMeasure
	|		AND Products.Principal = Products1.Principal
	|		AND Products.Counterparty = Products1.Counterparty
	|		AND Products.FinancialAccountingGroup = Products1.FinancialAccountingGroup
	|		AND Products.Quality = Products1.Quality
	|
	|UNION
	|
	|SELECT
	|	Products.Ref AS Ref,
	|	Products1.Ref AS Ref1
	|FROM
	|	Catalog.Products AS Products
	|		INNER JOIN Catalog.Products AS Products1
	|		ON (Products.Ref < Products1.Ref)
	|			AND Products.DescriptionLanguage2 = Products1.DescriptionLanguage2
	|WHERE
	|	&IsAdditionalLangUsed2
	|	AND Products.DescriptionLanguage2 <> """"
	|		AND Products.ProductKind.ItemsType = Products1.ProductKind.ItemsType
	|		AND Products.ProductKind.UseVariants = Products1.ProductKind.UseVariants
	|		AND Products.ProductKind.KeepAccountingByBatch = Products1.ProductKind.KeepAccountingByBatch
	|		AND Products.ProductKind.AccountingFeature = Products1.ProductKind.AccountingFeature
	|		AND Products.UnitOfMeasure = Products1.UnitOfMeasure
	|		AND Products.Principal = Products1.Principal
	|		AND Products.Counterparty = Products1.Counterparty
	|		AND Products.FinancialAccountingGroup = Products1.FinancialAccountingGroup
	|		AND Products.Quality = Products1.Quality
	|
	|UNION
	|
	|SELECT
	|	Products.Ref AS Ref,
	|	Products1.Ref AS Ref1
	|FROM
	|	FullNameInDifferentLanguages AS Products
	|		INNER JOIN FullNameInDifferentLanguages AS Products1
	|		ON Products.Ref < Products1.Ref
	|			AND Products.DescriptionFull = Products1.DescriptionFull
	|WHERE
	|	Products.ProductKind.ItemsType = Products1.ProductKind.ItemsType
	|	AND Products.ProductKind.UseVariants = Products1.ProductKind.UseVariants
	|	AND Products.ProductKind.KeepAccountingByBatch = Products1.ProductKind.KeepAccountingByBatch
	|	AND Products.ProductKind.AccountingFeature = Products1.ProductKind.AccountingFeature
	|	AND Products.UnitOfMeasure = Products1.UnitOfMeasure
	|	AND Products.Principal = Products1.Principal
	|	AND Products.Counterparty = Products1.Counterparty
	|	AND Products.FinancialAccountingGroup = Products1.FinancialAccountingGroup
	|	AND Products.Quality = Products1.Quality
	|
	|UNION
	|
	|SELECT
	|	Products.Ref AS Ref,
	|	Products1.Ref AS Ref1
	|FROM
	|	Catalog.Products AS Products
	|		INNER JOIN Catalog.Products AS Products1
	|		ON (Products.Ref < Products1.Ref)
	|			AND Products.DescriptionFull = Products1.DescriptionFull
	|WHERE
	|	Products.DescriptionFull <> """"
	|	AND Products.ProductKind.ItemsType = Products1.ProductKind.ItemsType
	|		AND Products.ProductKind.UseVariants = Products1.ProductKind.UseVariants
	|		AND Products.ProductKind.KeepAccountingByBatch = Products1.ProductKind.KeepAccountingByBatch
	|		AND Products.ProductKind.AccountingFeature = Products1.ProductKind.AccountingFeature
	|		AND Products.UnitOfMeasure = Products1.UnitOfMeasure
	|		AND Products.Principal = Products1.Principal
	|		AND Products.Counterparty = Products1.Counterparty
	|		AND Products.FinancialAccountingGroup = Products1.FinancialAccountingGroup
	|		AND Products.Quality = Products1.Quality";
	QueryText = StrReplace(QueryText, "&IsAdditionalLangUsed1",
		?(LanguagesInfo.Used.Language1, "TRUE", "FALSE"));
	QueryText = StrReplace(QueryText, "&IsAdditionalLangUsed2",
		?(LanguagesInfo.Used.Language2, "TRUE", "FALSE"));
	Return QueryText;
EndFunction

Function QueryText_DuplicateSearchRules_Partners_NameMatches()
	QueryText = 
	"SELECT DISTINCT
	|	Partner1.Ref AS Partner,
	|	Partner2.Ref AS Duplicate1
	|FROM
	|	Catalog.Partners AS Partner1
	|		INNER JOIN Catalog.Partners AS Partner2
	|		ON Partner1.Ref < Partner2.Ref
	|			AND Partner1.Description = Partner2.Description
	|			AND Partner1.LegalEntityIndividual = Partner2.LegalEntityIndividual
	|		LEFT JOIN Catalog.Partners.ContactInformation AS KI1
	|		ON KI1.Ref = Partner1.Ref
	|		LEFT JOIN Catalog.Partners.ContactInformation AS KI2
	|		ON KI2.Ref = Partner2.Ref
	|WHERE
	|	(KI1.Ref IS NULL
	|			OR (KI1.Type = VALUE(Enum.ContactInformationTypes.Phone)
	|					AND KI2.Type = VALUE(Enum.ContactInformationTypes.Phone)
	|					AND KI1.PhoneNumber <> """"
	|					AND KI1.PhoneNumber = KI2.PhoneNumber
	|				OR KI1.Type = VALUE(Enum.ContactInformationTypes.Email)
	|					AND KI2.Type = VALUE(Enum.ContactInformationTypes.Email)
	|					AND KI1.EMAddress <> """"
	|					AND KI1.EMAddress = KI2.EMAddress
	|				OR KI1.Type = VALUE(Enum.ContactInformationTypes.Address)
	|					AND KI2.Type = VALUE(Enum.ContactInformationTypes.Address)
	|					AND (KI1.Presentation <> """"
	|							AND KI1.Presentation = KI2.Presentation)))
	|
	|UNION
	|
	|SELECT DISTINCT
	|	Partner1.Ref AS Partner,
	|	Partner2.Ref AS Duplicate1
	|FROM
	|	Catalog.Partners AS Partner1
	|		INNER JOIN Catalog.Partners AS Partner2
	|		ON Partner1.Ref < Partner2.Ref
	|			AND Partner1.DescriptionLanguage1 = Partner2.DescriptionLanguage1
	|			AND Partner1.LegalEntityIndividual = Partner2.LegalEntityIndividual
	|		LEFT JOIN Catalog.Partners.ContactInformation AS KI1
	|		ON KI1.Ref = Partner1.Ref
	|		LEFT JOIN Catalog.Partners.ContactInformation AS KI2
	|		ON KI2.Ref = Partner2.Ref
	|WHERE
	|	Partner1.DescriptionLanguage1 <> """"
	|	AND (KI1.Ref IS NULL
	|			OR (KI1.Type = VALUE(Enum.ContactInformationTypes.Phone)
	|					AND KI2.Type = VALUE(Enum.ContactInformationTypes.Phone)
	|					AND KI1.PhoneNumber <> """"
	|					AND KI1.PhoneNumber = KI2.PhoneNumber
	|				OR KI1.Type = VALUE(Enum.ContactInformationTypes.Email)
	|					AND KI2.Type = VALUE(Enum.ContactInformationTypes.Email)
	|					AND KI1.EMAddress <> """"
	|					AND KI1.EMAddress = KI2.EMAddress
	|				OR KI1.Type = VALUE(Enum.ContactInformationTypes.Address)
	|					AND KI2.Type = VALUE(Enum.ContactInformationTypes.Address)
	|					AND (KI1.Presentation <> """"
	|							AND KI1.Presentation = KI2.Presentation)))
	|
	|UNION
	|
	|SELECT DISTINCT
	|	Partner1.Ref AS Partner,
	|	Partner2.Ref AS Duplicate1
	|FROM
	|	Catalog.Partners AS Partner1
	|		INNER JOIN Catalog.Partners AS Partner2
	|		ON Partner1.Ref < Partner2.Ref
	|			AND Partner1.DescriptionLanguage2 = Partner2.DescriptionLanguage2
	|			AND Partner1.LegalEntityIndividual = Partner2.LegalEntityIndividual
	|		LEFT JOIN Catalog.Partners.ContactInformation AS KI1
	|		ON KI1.Ref = Partner1.Ref
	|		LEFT JOIN Catalog.Partners.ContactInformation AS KI2
	|		ON KI2.Ref = Partner2.Ref
	|WHERE
	|	Partner1.DescriptionLanguage2 <> """"
	|	AND (KI1.Ref IS NULL
	|			OR (KI1.Type = VALUE(Enum.ContactInformationTypes.Phone)
	|					AND KI2.Type = VALUE(Enum.ContactInformationTypes.Phone)
	|					AND KI1.PhoneNumber <> """"
	|					AND KI1.PhoneNumber = KI2.PhoneNumber
	|				OR KI1.Type = VALUE(Enum.ContactInformationTypes.Email)
	|					AND KI2.Type = VALUE(Enum.ContactInformationTypes.Email)
	|					AND KI1.EMAddress <> """"
	|					AND KI1.EMAddress = KI2.EMAddress
	|				OR KI1.Type = VALUE(Enum.ContactInformationTypes.Address)
	|					AND KI2.Type = VALUE(Enum.ContactInformationTypes.Address)
	|					AND (KI1.Presentation <> """"
	|							AND KI1.Presentation = KI2.Presentation)))
	|
	|UNION
	|
	|SELECT DISTINCT
	|	Partner1.Ref AS Partner,
	|	Partner2.Ref AS Duplicate1
	|FROM
	|	Catalog.Partners AS Partner1
	|		INNER JOIN Catalog.Partners AS Partner2
	|		ON Partner1.Ref < Partner2.Ref
	|			AND Partner1.DescriptionFull = Partner2.DescriptionFull
	|			AND Partner1.LegalEntityIndividual = Partner2.LegalEntityIndividual
	|		LEFT JOIN Catalog.Partners.ContactInformation AS KI1
	|		ON KI1.Ref = Partner1.Ref
	|		LEFT JOIN Catalog.Partners.ContactInformation AS KI2
	|		ON KI2.Ref = Partner2.Ref
	|WHERE
	|	Partner1.DescriptionFull <> """"
	|	AND (KI1.Ref IS NULL
	|			OR (KI1.Type = VALUE(Enum.ContactInformationTypes.Phone)
	|					AND KI2.Type = VALUE(Enum.ContactInformationTypes.Phone)
	|					AND KI1.PhoneNumber <> """"
	|					AND KI1.PhoneNumber = KI2.PhoneNumber
	|				OR KI1.Type = VALUE(Enum.ContactInformationTypes.Email)
	|					AND KI2.Type = VALUE(Enum.ContactInformationTypes.Email)
	|					AND KI1.EMAddress <> """"
	|					AND KI1.EMAddress = KI2.EMAddress
	|				OR KI1.Type = VALUE(Enum.ContactInformationTypes.Address)
	|					AND KI2.Type = VALUE(Enum.ContactInformationTypes.Address)
	|					AND (KI1.Presentation <> """"
	|							AND KI1.Presentation = KI2.Presentation)))";
	Return QueryText;
EndFunction

Function QueryText_DuplicateSearchRules_ItemCharacteristics_NameMatches(LanguagesInfo)
	QueryText = 
	"SELECT
	|	ItemsCharacteristics.Ref AS Ref,
	|	ItemsCharacteristics1.Ref AS Ref1
	|FROM
	|	Catalog.ItemsCharacteristics AS ItemsCharacteristics
	|		INNER JOIN Catalog.ItemsCharacteristics AS ItemsCharacteristics1
	|		ON ItemsCharacteristics.Owner = ItemsCharacteristics1.Owner
	|			AND ItemsCharacteristics.Ref < ItemsCharacteristics1.Ref
	|WHERE
	|	(ItemsCharacteristics.Description = ItemsCharacteristics1.Description
	|	OR
	|	(ItemsCharacteristics.DescriptionFull = ItemsCharacteristics1.DescriptionFull
	|		AND NOT ItemsCharacteristics.DescriptionFull = """")
	|	OR
	|	(&IsAdditionalLangUsed1
	|		AND ItemsCharacteristics.DescriptionLanguage1 = ItemsCharacteristics1.DescriptionLanguage1
	|		AND NOT ItemsCharacteristics.DescriptionLanguage1 = """")
	|	OR
	|	(&IsAdditionalLangUsed2
	|		AND ItemsCharacteristics.DescriptionLanguage2 = ItemsCharacteristics1.DescriptionLanguage2
	|		AND NOT ItemsCharacteristics.DescriptionLanguage2 = """")
	|)
	|
	|UNION
	|
	|SELECT
	|	FullNameInDifferentLanguages.Ref AS Ref,
	|	FullNameInDifferentLanguages1.Ref AS Ref1
	|FROM
	|	Catalog.ItemsCharacteristics.Presentations AS FullNameInDifferentLanguages
	|		INNER JOIN Catalog.ItemsCharacteristics.Presentations AS FullNameInDifferentLanguages1
	|		ON FullNameInDifferentLanguages.Ref < FullNameInDifferentLanguages1.Ref
	|			AND FullNameInDifferentLanguages.DescriptionFull = FullNameInDifferentLanguages1.DescriptionFull
	|";
	QueryText = StrReplace(QueryText, "&IsAdditionalLangUsed1",
		?(LanguagesInfo.Used.Language1, "TRUE", "FALSE"));
	QueryText = StrReplace(QueryText, "&IsAdditionalLangUsed2",
		?(LanguagesInfo.Used.Language2, "TRUE", "FALSE"));
	Return QueryText;
EndFunction

Function QueryText_DuplicateSearchRules_Counterparties_NameAndContactDetailsMatch()
	QueryText = 
	"SELECT DISTINCT
	|	Counterparty1.Ref AS Counterparty,
	|	Counterparty2.Ref AS Duplicate1
	|FROM
	|	Catalog.Counterparties AS Counterparty1
	|		INNER JOIN Catalog.Counterparties AS Counterparty2
	|		ON Counterparty1.Ref < Counterparty2.Ref
	|			AND Counterparty1.Description = Counterparty2.Description
	|			AND Counterparty1.CompanyIndividual = Counterparty2.CompanyIndividual
	|			AND Counterparty1.LegalEntityIndividual = Counterparty2.LegalEntityIndividual
	|		LEFT JOIN Catalog.Counterparties.ContactInformation AS KI1
	|		ON KI1.Ref = Counterparty1.Ref
	|		LEFT JOIN Catalog.Counterparties.ContactInformation AS KI2
	|		ON KI2.Ref = Counterparty2.Ref
	|WHERE
	|	(KI1.Ref IS NULL
	|			OR (KI1.Type = VALUE(Enum.ContactInformationTypes.Phone)
	|					AND KI2.Type = VALUE(Enum.ContactInformationTypes.Phone)
	|					AND KI1.PhoneNumber <> """"
	|					AND KI1.PhoneNumber = KI2.PhoneNumber
	|				OR KI1.Type = VALUE(Enum.ContactInformationTypes.Email)
	|					AND KI2.Type = VALUE(Enum.ContactInformationTypes.Email)
	|					AND KI1.EMAddress <> """"
	|					AND KI1.EMAddress = KI2.EMAddress
	|				OR KI1.Type = VALUE(Enum.ContactInformationTypes.Address)
	|					AND KI2.Type = VALUE(Enum.ContactInformationTypes.Address)
	|					AND (KI1.Presentation <> """"
	|							AND KI1.Presentation = KI2.Presentation)))
	|
	|UNION
	|
	|SELECT DISTINCT
	|	Counterparty1.Ref AS Counterparty,
	|	Counterparty2.Ref AS Duplicate1
	|FROM
	|	Catalog.Counterparties AS Counterparty1
	|		INNER JOIN Catalog.Counterparties AS Counterparty2
	|		ON Counterparty1.Ref < Counterparty2.Ref
	|			AND Counterparty1.DescriptionLanguage1 = Counterparty2.DescriptionLanguage1
	|			AND Counterparty1.CompanyIndividual = Counterparty2.CompanyIndividual
	|			AND Counterparty1.LegalEntityIndividual = Counterparty2.LegalEntityIndividual
	|		LEFT JOIN Catalog.Counterparties.ContactInformation AS KI1
	|		ON KI1.Ref = Counterparty1.Ref
	|		LEFT JOIN Catalog.Counterparties.ContactInformation AS KI2
	|		ON KI2.Ref = Counterparty2.Ref
	|WHERE
	|	Counterparty1.DescriptionLanguage1 <> """"
	|	AND (KI1.Ref IS NULL
	|			OR (KI1.Type = VALUE(Enum.ContactInformationTypes.Phone)
	|					AND KI2.Type = VALUE(Enum.ContactInformationTypes.Phone)
	|					AND KI1.PhoneNumber <> """"
	|					AND KI1.PhoneNumber = KI2.PhoneNumber
	|				OR KI1.Type = VALUE(Enum.ContactInformationTypes.Email)
	|					AND KI2.Type = VALUE(Enum.ContactInformationTypes.Email)
	|					AND KI1.EMAddress <> """"
	|					AND KI1.EMAddress = KI2.EMAddress
	|				OR KI1.Type = VALUE(Enum.ContactInformationTypes.Address)
	|					AND KI2.Type = VALUE(Enum.ContactInformationTypes.Address)
	|					AND (KI1.Presentation <> """"
	|							AND KI1.Presentation = KI2.Presentation)))
	|
	|UNION
	|
	|SELECT DISTINCT
	|	Counterparty1.Ref AS Counterparty,
	|	Counterparty2.Ref AS Duplicate1
	|FROM
	|	Catalog.Counterparties AS Counterparty1
	|		INNER JOIN Catalog.Counterparties AS Counterparty2
	|		ON Counterparty1.Ref < Counterparty2.Ref
	|			AND Counterparty1.DescriptionLanguage2 = Counterparty2.DescriptionLanguage2
	|			AND Counterparty1.CompanyIndividual = Counterparty2.CompanyIndividual
	|			AND Counterparty1.LegalEntityIndividual = Counterparty2.LegalEntityIndividual
	|		LEFT JOIN Catalog.Counterparties.ContactInformation AS KI1
	|		ON KI1.Ref = Counterparty1.Ref
	|		LEFT JOIN Catalog.Counterparties.ContactInformation AS KI2
	|		ON KI2.Ref = Counterparty2.Ref
	|WHERE
	|	Counterparty1.DescriptionLanguage2 <> """"
	|	AND (KI1.Ref IS NULL
	|			OR (KI1.Type = VALUE(Enum.ContactInformationTypes.Phone)
	|					AND KI2.Type = VALUE(Enum.ContactInformationTypes.Phone)
	|					AND KI1.PhoneNumber <> """"
	|					AND KI1.PhoneNumber = KI2.PhoneNumber
	|				OR KI1.Type = VALUE(Enum.ContactInformationTypes.Email)
	|					AND KI2.Type = VALUE(Enum.ContactInformationTypes.Email)
	|					AND KI1.EMAddress <> """"
	|					AND KI1.EMAddress = KI2.EMAddress
	|				OR KI1.Type = VALUE(Enum.ContactInformationTypes.Address)
	|					AND KI2.Type = VALUE(Enum.ContactInformationTypes.Address)
	|					AND (KI1.Presentation <> """"
	|							AND KI1.Presentation = KI2.Presentation)))
	|
	|UNION
	|
	|SELECT DISTINCT
	|	Counterparty1.Ref AS Counterparty,
	|	Counterparty2.Ref AS Duplicate1
	|FROM
	|	Catalog.Counterparties AS Counterparty1
	|		INNER JOIN Catalog.Counterparties AS Counterparty2
	|		ON Counterparty1.Ref < Counterparty2.Ref
	|			AND Counterparty1.DescriptionFull = Counterparty2.DescriptionFull
	|			AND Counterparty1.CompanyIndividual = Counterparty2.CompanyIndividual
	|			AND Counterparty1.LegalEntityIndividual = Counterparty2.LegalEntityIndividual
	|		LEFT JOIN Catalog.Counterparties.ContactInformation AS KI1
	|		ON KI1.Ref = Counterparty1.Ref
	|		LEFT JOIN Catalog.Counterparties.ContactInformation AS KI2
	|		ON KI2.Ref = Counterparty2.Ref
	|WHERE
	|	Counterparty1.DescriptionFull <> """"
	|	AND (KI1.Ref IS NULL
	|			OR (KI1.Type = VALUE(Enum.ContactInformationTypes.Phone)
	|					AND KI2.Type = VALUE(Enum.ContactInformationTypes.Phone)
	|					AND KI1.PhoneNumber <> """"
	|					AND KI1.PhoneNumber = KI2.PhoneNumber
	|				OR KI1.Type = VALUE(Enum.ContactInformationTypes.Email)
	|					AND KI2.Type = VALUE(Enum.ContactInformationTypes.Email)
	|					AND KI1.EMAddress <> """"
	|					AND KI1.EMAddress = KI2.EMAddress
	|				OR KI1.Type = VALUE(Enum.ContactInformationTypes.Address)
	|					AND KI2.Type = VALUE(Enum.ContactInformationTypes.Address)
	|					AND (KI1.Presentation <> """"
	|							AND KI1.Presentation = KI2.Presentation)))";
	Return QueryText;
EndFunction

Function QueryText_DuplicateSearchRules_Counterparties_BankAccountNumberMatches()
	QueryText = 
	"SELECT DISTINCT
	|	CounterpartyBankAccounts.Owner AS Owner,
	|	CounterpartyBankAccounts1.Owner AS Owner1
	|FROM
	|	Catalog.CounterpartyBankAccounts AS CounterpartyBankAccounts
	|		INNER JOIN Catalog.CounterpartyBankAccounts AS CounterpartyBankAccounts1
	|		ON CounterpartyBankAccounts.Owner <> CounterpartyBankAccounts1.Owner
	|WHERE
	|	CASE 
	|		WHEN NOT CounterpartyBankAccounts.Bank = VALUE(Catalog.BankClassifier.EmptyRef) 
	|			THEN CounterpartyBankAccounts.Bank = CounterpartyBankAccounts1.Bank
	|		ELSE CounterpartyBankAccounts.BankBIC = CounterpartyBankAccounts1.BankBIC
	|			AND CounterpartyBankAccounts.BankSWIFTCode = CounterpartyBankAccounts1.BankSWIFTCode
	|	END
	|	AND CounterpartyBankAccounts.AccountNumber = CounterpartyBankAccounts1.AccountNumber
	|	AND CounterpartyBankAccounts.Owner REFS Catalog.Counterparties
	|	AND CounterpartyBankAccounts1.Owner REFS Catalog.Counterparties";
	Return QueryText;
EndFunction

Function QueryText_DuplicateSearchRules_Counterparties_NonResidentRegistrationOrTaxNumberMatches()
	QueryText = 
	"SELECT
	|	Counterparties.Ref AS Ref,
	|	Counterparties1.Ref AS Ref1
	|FROM
	|	Catalog.Counterparties AS Counterparties
	|		INNER JOIN Catalog.Counterparties AS Counterparties1
	|		ON Counterparties.Ref < Counterparties1.Ref
	|WHERE
	|	 (Counterparties.TaxNumber <> """"
	|		AND Counterparties1.TaxNumber <> """"
	|		AND Counterparties.TaxNumber = Counterparties1.TaxNumber)
	|	OR (Counterparties.RegistrationNumber <> """"
	|		AND Counterparties1.RegistrationNumber <> """"
	|		AND Counterparties.RegistrationNumber = Counterparties1.RegistrationNumber)
	|	AND Counterparties.LegalEntityIndividual = VALUE(Enum.LegalEntityIndividual.LegalEntityNonResident)
	|	AND Counterparties1.LegalEntityIndividual = VALUE(Enum.LegalEntityIndividual.LegalEntityNonResident)";
	Return QueryText;
EndFunction

#EndRegion

Function MetadataObjectOfSuppliedRule(PredefinedDataName) 
	Map = New Map;
	Map.Insert("Catalog_Products_BySettingUniquenessOfTypeOfItem", "Catalog.Products");
	Map.Insert("Catalog_ItemsCharacteristics_BySettingUniquenessOfItemType", "Catalog.ItemsCharacteristics");
	Map.Insert("Catalog_Counterparties_TINKPPMatches", "Catalog.Counterparties");
	Map.Insert("Catalog_Partners_ContactDetailsMatch", "Catalog.Partners");
	Map.Insert("Catalog_Counterparties_ContactDetaiMatchesAndTINIsNotFilledIn", "Catalog.Counterparties");
	Map.Insert("Catalog_Products_NameMatches", "Catalog.Products");
	Map.Insert("Catalog_Partners_NameMatches", "Catalog.Partners");
	Map.Insert("Catalog_ItemsCharacteristics_NameMatches", "Catalog.ItemsCharacteristics");
	Map.Insert("Catalog_Counterparties_SameNameAndContactDetails", "Catalog.Counterparties");
	Map.Insert("Catalog_Counterparties_BankAccountNumberMatches", "Catalog.Counterparties");
	Map.Insert("Catalog_Counterparties_RegistrationOrTaxNumberOfNonResidentMatches", "Catalog.Counterparties");
	TypeName = Map[PredefinedDataName]; 
	If TypeName = Undefined Then
		Return Undefined;
	EndIf;
	Id = Common.MetadataObjectID(TypeName);
	Return Id;
EndFunction

#EndRegion
