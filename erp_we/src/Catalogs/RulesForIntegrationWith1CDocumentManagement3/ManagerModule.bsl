#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns all integration rules that were not marked for deletion.
//
// Returns:
//   ValueTable:
//     * Ref - CatalogRef.RulesForIntegrationWith1CDocumentManagement3 - the rule.
//     * ObjectPresentationDM - String - representation of the object BEFORE.
//     * ObjectPresentationIS - String - representation of the IP object.
//     * ObjectTypeDM - String - the object type is UP TO.
//     * ObjectTypeIS - String - the type of IP object.
//     * DocumentKindDM - String - Presentation of the document type BEFORE.
//     * DocumentKindDMID - String - id of the document type BEFORE.
//
Function AllIntegrationRules() Export
	
	Query = New Query(
		"SELECT
		|	RulesForIntegrationWith1CDocumentManagement3.Ref AS Ref,
		|	RulesForIntegrationWith1CDocumentManagement3.ObjectPresentationDM AS ObjectPresentationDM,
		|	RulesForIntegrationWith1CDocumentManagement3.ObjectPresentationIS AS ObjectPresentationIS,
		|	RulesForIntegrationWith1CDocumentManagement3.ObjectTypeDM AS ObjectTypeDM,
		|	RulesForIntegrationWith1CDocumentManagement3.ObjectTypeIS AS ObjectTypeIS,
		|	RulesForIntegrationWith1CDocumentManagement3.DocumentKindDM AS DocumentKindDM,
		|	RulesForIntegrationWith1CDocumentManagement3.DocumentKindDMID AS DocumentKindDMID
		|FROM
		|	Catalog.RulesForIntegrationWith1CDocumentManagement3 AS RulesForIntegrationWith1CDocumentManagement3
		|WHERE
		|	RulesForIntegrationWith1CDocumentManagement3.DeletionMark = FALSE");
	
	Return Query.Execute().Unload();
	
EndFunction

// Returns a list of expressions in the built-in language that need to be pre-executed on the DO side,
// for later filling in objects on the IC side.
//
// Parameters:
//   RulesForAnalysis - Array of CatalogRef.RulesForIntegrationWith1CDocumentManagement3 - integration rules.
//
// Returns:
//   ValueTable:
//     * Ref - CatalogRef.RulesForIntegrationWith1CDocumentManagement3
//     * id - String
//     * ComputedExpression - String
//     * Table - String
//     * ThisIsTable - Boolean
//     * SourceTableName - String
//
Function ExpressionsToExecuteOnSideDM(RulesForAnalysis) Export
	
	Query = New Query(
		"SELECT
		|	AttributeFillingRulesIS.Ref AS Ref,
		|	AttributeFillingRulesIS.id AS id,
		|	AttributeFillingRulesIS.ComputedExpression AS ComputedExpression,
		|	AttributeFillingRulesIS.Table AS Table,
		|	AttributeFillingRulesIS.ThisIsTable AS ThisIsTable,
		|	ISNULL(RulesForFillingInParentIPAttributes.AttributeNameObjectDM, """") AS SourceTableName
		|FROM
		|	Catalog.RulesForIntegrationWith1CDocumentManagement3.AttributeFillingRulesIS AS AttributeFillingRulesIS
		|		LEFT JOIN Catalog.RulesForIntegrationWith1CDocumentManagement3.AttributeFillingRulesIS AS RulesForFillingInParentIPAttributes
		|		ON AttributeFillingRulesIS.Ref = RulesForFillingInParentIPAttributes.Ref
		|			AND AttributeFillingRulesIS.Table = RulesForFillingInParentIPAttributes.AttributeNameObjectIS
		|			AND (RulesForFillingInParentIPAttributes.ThisIsTable)
		|WHERE
		|	AttributeFillingRulesIS.Variant = VALUE(Enum.VariantsOfTheRulesForFillingInAttributes.ScriptExpression)
		|	AND AttributeFillingRulesIS.PlaceWhereExpressionIsExecuted = VALUE(Enum.PlacesWhereExpressionsOnBuiltInLanguageAreExecuted.OnDocumentManagementSide)
		|	AND AttributeFillingRulesIS.Ref IN(&RulesForAnalysis)");
	Query.SetParameter("RulesForAnalysis", RulesForAnalysis);
	
	Return Query.Execute().Unload();
	
EndFunction

// Fills in the IC object by the XDTO object.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   ObjectToFillInIS - Arbitrary - the IS object to be filled in.
//   XDTODataObject - XDTODataObject - the object BEFORE, the source of the fill data.
//   IntegrationRule - CatalogRef.RulesForIntegrationWith1CDocumentManagement3 - integration rule for
//     filling in the IP object.
//   RefreshEnabled - Boolean - fill in only Attributes with Update = True.
//   RequiresRecheck - Boolean - True if the change requires rechecking.
//
// Returns:
//   Boolean - True if the object has been modified, and False otherwise.
//
Function FillInICObjectByXDTOObject(Proxy, ObjectToFillInIS, XDTODataObject, IntegrationRule, RefreshEnabled = False,
		RequiresRecheck = False) Export
	
	ObjectModified = False;
	UpdatedTableParts = New Map;
	
	ObjectMetadata = ObjectToFillInIS.Metadata();
	FullNameOfIPObject = ObjectMetadata.FullName();
	
	CheckingForCrossChecking = RefreshEnabled
		And Common.IsDocument(ObjectMetadata)
		And ObjectMetadata.Posting = Metadata.ObjectProperties.Posting.Allow
		And ObjectToFillInIS.Posted;
	
	AllowedWithoutReposting =
		Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.AllowedWithoutReposting;
	AllowedWithReposting =
		Enums.ModeOfChangingPostedDocumentBy1CDocumentManagementData.AllowedWithReposting;
	
	// The redefined module can override the rule settings, allowing the change without rechecking.
	UpdatedBankingDetails = New Array;
	IntegrationWith1CDocumentManagementCoreOverridable.WhenDeterminingUpdatedDetailsOfConductedDocument(
		FullNameOfIPObject,
		UpdatedBankingDetails);
	
	ContextOfFillingInRule = ContextOfFillingInRule(
		ObjectToFillInIS,
		XDTODataObject,
		IntegrationRule,
		FullNameOfIPObject);
	
	For Each AttributeData In ContextOfFillingInRule.ObjectAttributesIS Do
		// The method of integration1sdocumentovorotbazovyfunctionality.The details
		// of the IC object sorts the Attributes of the IC object in the order required to load the data. Objects that have an owner should
		// be loaded after their owner is loaded. For example, you can start loading the contact person and the Contract
		// only after the counterparty is loaded.
		
		If ValueIsFilled(AttributeData.Table) Then
			// We load the Attributes of the tabular part into the fill-in tabletable.
			Continue;
		EndIf;
		
		FilterParameters = New Structure;
		FilterParameters.Insert("AttributeNameObjectIS", AttributeData.Name);
		FilterParameters.Insert("ThisIsTable", AttributeData.ThisIsTable);
		FilterParameters.Insert("Table", AttributeData.Table);
		If RefreshEnabled Then
			FilterParameters.Insert("ShouldUpdate", True);
		EndIf;
		
		FoundRulesForBankingDetails = ContextOfFillingInRule.AttributeFillingRulesIS.FindRows(
			FilterParameters); // See Catalog.RulesForIntegrationWith1CDocumentManagement3.AttributeFillingRulesIS
		If FoundRulesForBankingDetails.Count() = 0 Then
			Continue;
		EndIf;
		PropsRule = FoundRulesForBankingDetails[0];
		
		If CheckingForCrossChecking Then
			If PropsRule.ModeOfChangingTheDataOfThePostedDocument = AllowedWithReposting Then
				ChangeMode = AllowedWithReposting;
				
			ElsIf PropsRule.ModeOfChangingTheDataOfThePostedDocument = AllowedWithoutReposting
					Or UpdatedBankingDetails.Find(PropsRule.AttributeNameObjectIS) <> Undefined Then
				ChangeMode = AllowedWithoutReposting;
				
			Else
				// Modification is prohibited.
				Continue;
				
			EndIf;
		Else
			ChangeMode = AllowedWithoutReposting;
		EndIf;
		
		If PropsRule.ThisIsTable Then
			// Fill in the tabular part of the IP object.
			ICObjectTable = ObjectToFillInIS[PropsRule.AttributeNameObjectIS];
			UpdatedTableParts.Insert(PropsRule.AttributeNameObjectIS, ICObjectTable.Unload());
			FillInTableAccordingToRule(Proxy, ICObjectTable, PropsRule, ContextOfFillingInRule);
			
		ElsIf PropsRule.IsAdditionalAttributeIS Then
			// Fill in the additional Attributes of the IP object.
			TheStructureOfTheSearch = New Structure("Property", PropsRule.AdditionalAttributeIS);
			StringsOfProps = ObjectToFillInIS.AdditionalAttributes.FindRows(TheStructureOfTheSearch);
			If StringsOfProps.Count() = 0 Then
				ObjectModified = True;
				PropsString = ObjectToFillInIS.AdditionalAttributes.Add();
				PropsString.Property = PropsRule.AdditionalAttributeIS;
			Else
				PropsString = StringsOfProps[0];
			EndIf;
			
			PreviousValue = PropsString.Value;
			
			FillInAttributesAccordingToRule(
				Proxy,
				PropsString.Value,
				PropsRule,
				AttributeData,
				ContextOfFillingInRule);
			
			If PropsString.Value <> PreviousValue Then
				If ChangeMode = AllowedWithoutReposting Then
					ObjectModified = True;
				ElsIf ChangeMode = AllowedWithReposting Then
					ObjectModified = True;
					RequiresRecheck = True;
				EndIf;
			EndIf;
			
		ElsIf PropsRule.Table = "" Then
			// Fill in the Attributes of the IP object.
			// We skip the Attributes of the tabular part, fill them in the Fill-in-the-table method.
			PreviousValue = ObjectToFillInIS[PropsRule.AttributeNameObjectIS];
			
			FillInAttributesAccordingToRule(
				Proxy,
				ObjectToFillInIS[PropsRule.AttributeNameObjectIS],
				PropsRule,
				AttributeData,
				ContextOfFillingInRule);
			
			If ObjectToFillInIS[PropsRule.AttributeNameObjectIS] <> PreviousValue Then
				If ChangeMode = AllowedWithoutReposting Then
					ObjectModified = True;
				ElsIf ChangeMode = AllowedWithReposting Then
					ObjectModified = True;
					RequiresRecheck = True;
				EndIf;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	For Each TabularSection In UpdatedTableParts Do
		ObjectModified = (ObjectModified
			Or (ValueToStringInternal(TabularSection.Value) <>
				ValueToStringInternal(ObjectToFillInIS[TabularSection.Key].Unload())));
	EndDo;
	
	Return ObjectModified;
	
EndFunction

// Generates an instruction that helps you write an expression in the embedded language.
//
// Parameters:
//   Parameters - See Catalogs.RulesForIntegrationWith1CDocumentManagement3.ParametersOfExpressionInEmbeddedLanguage
//   ObjectAttributesBefore - See Catalogs.RulesForIntegrationWith1CDocumentManagement3.ObjectAttributesBefore
//
// Returns:
//   String - instructions in HTML format.
//
Function ExpressionInstruction(Parameters, ObjectAttributesBefore = Undefined) Export
	
	ArrayInstructions = New Array;
	
	ArrayInstructions.Add(
		"<html>
		|<style type=""text/css"">
		|	body {
		|		overflow:    auto;
		|		margin-top:  12px;
		|		margin-left: 20px;
		|		font-family: MS Shell Dlg, Microsoft Sans Serif, sans-serif;
		|		font-size:   8pt;}
		|	table {
		|		width:       450px;
		|		font-family: MS Shell Dlg, Microsoft Sans Serif, sans-serif;
		|		font-size:   8pt;}
		|	td {vertical-align: top;}
		|	p {
		|		margin-top: 7px;}
		|	.pointer { cursor: pointer; }
		|</style>
		|<body>");
	
	ArrayInstructions.Add("<p>");
	
	DescriptionIS = IntegrationWith1CDocumentManagementCore.AbbreviatedNameOfConfiguration();
	
	If Parameters.ThisIsConditionOfApplicabilityWhenUnloading Or Parameters.ThisIsConditionOfApplicabilityWhenLoading Then
		ArrayInstructions.Add(StrTemplate(
			NStr("ru = 'Выражение на встроенном языке 1С:Предприятия определяет применимость правила при создании объекта %1 на основании объекта %2.
				|Результат вычисления должен присваиваться свойству <b>Результат</b> переменной <b>Параметры</b>.
				|Значение <b>Истина</b> говорит о применимости правила, <b>Ложь</b> - о неприменимости.
				|Место выполнения выражения: на стороне %3.';
				|vi = 'An expression in the 1C:Enterprise language determines the applicability of the rule when creating object %1 based on object %2.
				|The calculation result must be assigned to the <b>Result</b> property of the <b>Parameters</b> variable.
				|<b>True</b> means the rule is applicable, <b>False</b> means it is not applicable.
				|Expression execution location: on %3 side.';
				|en = 'An expression in the 1C:Enterprise language determines the applicability of the rule when creating object %1 based on object %2.
				|The calculation result must be assigned to the <b>Result</b> property of the <b>Parameters</b> variable.
				|<b>True</b> means the rule is applicable, <b>False</b> means it is not applicable.
				|Expression execution location: on %3 side.'; fa = 'An expression in the 1C:Enterprise language determines the applicability of the rule when creating object %1 based on object %2.
				|The calculation result must be assigned to the <b>Result</b> property of the <b>Parameters</b> variable.
				|<b>True</b> means the rule is applicable, <b>False</b> means it is not applicable.
				|Expression execution location: on %3 side.';
				|it = 'An expression in the 1C:Enterprise language determines the applicability of the rule when creating object %1 based on object %2.
				|The calculation result must be assigned to the <b>Result</b> property of the <b>Parameters</b> variable.
				|<b>True</b> means the rule is applicable, <b>False</b> means it is not applicable.
				|Expression execution location: on %3 side.';
				|pl = 'An expression in the 1C:Enterprise language determines the applicability of the rule when creating object %1 based on object %2.
				|The calculation result must be assigned to the <b>Result</b> property of the <b>Parameters</b> variable.
				|<b>True</b> means the rule is applicable, <b>False</b> means it is not applicable.
				|Expression execution location: on %3 side.';
				|tr = '1C:Enterprise yerleşik dilindeki ifade, bir %1 nesnesinin, bir %2 nesnesine dayalı olarak oluşturulması sırasında kuralın uygulanabilir olup olmadığını belirler. 
				|Hesaplamanın sonucu, <b>Parametreler</b> değişkeninin <b>Sonuç</b> özelliğine atanmalıdır.
				|<b>Doğru</b> değeri kuralın uygulanabilir olduğunu, <b>Yanlış</b> ise uygulanabilir olmadığını gösterir. 
				|İfadenin yürütüldüğü yer: %3 tarafı.'"),
			?(Parameters.ThisIsConditionOfApplicabilityWhenUnloading, NStr("ru = '1С:Документооборота';
																			|vi = '1C:Document Management';
																			|en = '1C:Document Management'; fa = '1C:Document Management';
																			|it = '1C:Document Management';
																			|pl = '1C:Document Management';
																			|tr = '1C:Document Management''in'"), DescriptionIS),
			?(Parameters.ThisIsConditionOfApplicabilityWhenUnloading, DescriptionIS, NStr("ru = '1С:Документооборота';
																							|vi = '1C:Document Management';
																							|en = '1C:Document Management'; fa = '1C:Document Management';
																							|it = '1C:Document Management';
																							|pl = '1C:Document Management';
																							|tr = '1C:Document Management''in'")),
			DescriptionIS));
	Else
		ArrayInstructions.Add(StrTemplate(
			NStr("vi = 'Kết quả tính toán biểu thức bằng ngôn ngữ hệ thống 1C:Enterprise
				|cần gán thuộc tính %1 cho biến %2.';
				|ru = 'Результат вычисления выражения на встроенном языке 1С:Предприятия
				|должен присваиваться свойству %1 переменной %2.';
				|en = 'Result of the expression evaluation in 1C:Enterprise
				|language should be assigned to the %1 property of the %2 variable.'; fa = 'Result of the expression evaluation in 1C:Enterprise
				|language should be assigned to the %1 property of the %2 variable.';
				|it = 'Il risultato del calcolo dell''espressione nel linguaggio integrato di 1C:Enterprise
				|deve essere assegnato alla proprietà %1 modificata da %2.';
				|pl = 'Wynik obliczenia w języku wbudowanym 1С:Enterprise
				|powinien być przypisywany według właściwości %1 zmiennej %2.';
				|tr = '1C:Enterprise
				|yerleşik dilindeki ifadenin hesaplanmasının sonucu, değişkenin özelliğine %1tanımlanmalıdır %2.'"),
			"<b>Result</b>",
			"<b>Parameters</b>"));
		ArrayInstructions.Add(" ");
	EndIf;
	
	If (Parameters.ThisIsConditionOfApplicabilityWhenUnloading And Not ValueIsFilled(Parameters.ObjectTypeIS))
			Or (Parameters.ThisIsConditionOfApplicabilityWhenLoading And Not ValueIsFilled(Parameters.ObjectTypeDM)) Then
		Return StrConcat(ArrayInstructions);
	EndIf;
	
	If Parameters.ThisIsTableLoadingRule Then
		ArrayInstructions.Add(
			StrTemplate(
				NStr("vi = 'Để điền bảng kết quả, cần có kiểu %1 với các cột:';
					|ru = 'Для заполнения таблицы результат должен иметь тип %1 с колонками:';
					|en = 'To fill in the table, the result must have the %1 type with the columns:'; fa = 'To fill in the table, the result must have the %1 type with the columns:';
					|it = 'Per la compilazione della tabella, il risultato deve avere tipo %1 con le colonne:';
					|pl = 'W celu wypełnienia tabeli wynik powinien mieć typ %1 z kolumnami:';
					|tr = 'Tabloyu doldurmak için sonucun sütun türünde %1 olması gerekir:'"),
			"<b>ValueTable</b>"));
		ArrayInstructions.Add("</p><table>");
		
		ArrayInstructions.Add("<tr><td>");
		ArrayInstructions.Add("<b>");
		ArrayInstructions.Add(NStr("vi = 'Tên mục tin';
									|ru = 'Имя реквизита';
									|en = 'Attribute name'; fa = 'نام ویژگی';
									|it = 'Nome del requisito';
									|pl = 'Nazwa atrybutu';
									|tr = 'Öznitelik adı'"));
		ArrayInstructions.Add("</b></td>");
		
		ArrayInstructions.Add("<td><b>");
		ArrayInstructions.Add(NStr("vi = 'Đồng nghĩa';
									|ru = 'Синоним';
									|en = 'Synonym'; fa = 'مترادف';
									|it = 'Sinonimo';
									|pl = 'Synonym';
									|tr = 'Eş anlamlı'"));
		ArrayInstructions.Add("</b></td>");
		ArrayInstructions.Add("</tr>");
		
		ObjectMetadata = Metadata.FindByFullName(Parameters.ObjectTypeIS);
		For Each Item In ObjectMetadata.TabularSections[Parameters.AttributeNameObjectIS].Attributes Do
			ArrayInstructions.Add("<tr><td>");
			ArrayInstructions.Add(Item.Name);
			ArrayInstructions.Add("</td>");
			ArrayInstructions.Add("<td>");
			ArrayInstructions.Add(Item.Synonym);
			ArrayInstructions.Add("</td></tr>");
		EndDo;
		
		ArrayInstructions.Add("</table>");
	EndIf;
	
	If Parameters.CurCurrentLineIsAvailable Then
		ArrayInstructions.Add("<p>");
		ArrayInstructions.Add(StrTemplate(
			NStr("vi = 'Thông qua thuộc tính %2 biến %3 có thể liên kết dữ liệu dòng hiện tại của phần bảng nguồn ""%1"", từ đó
			|điền phần bảng đích.';
			|ru = 'К данным текущей строки табличной части источника""%1"", из которой выполняется
			|заполнение табличной части приемника, можно обращаться через свойство %2 переменной %3.';
			|en = 'You can access data of the current row of the ""%1"" source table, from which the destination table
			|is filled, using the %2property of the %3variable.'; fa = 'You can access data of the current row of the ""%1"" source table, from which the destination table
			|is filled, using the %2property of the %3variable.';
			|it = 'I dati della riga corrente della tabella dell''origine ""%1"", dalla quale vengono compilate 
			| le parti tabellari del destinatario, sono accessibili tramite la proprietà %2 della variabile %3.';
			|pl = 'Do danych bieżącego wiersza sekcji tabelarycznej źródła""%1"", z której jest wykonywane
			|wypełnienie sekcji tabelarycznej odbiornika, można zwracać się przez właściwość %2 zmiennej %3.';
			|tr = 'Değişken özelliği ile hedef tablo bölümünün""%1"", doldurulduğu kaynak
			| tablo bölümünün mevcut satırının verilerine %2 erişilebilir %3.'"),
				Parameters.SourceTable2,
				"<b>CurrentRow</b>",
				"<b>Parameters</b>"));
	EndIf;
	
	ArrayInstructions.Add("<p>");
	ArrayInstructions.Add(NStr("vi = 'Với đối tượng';
								|ru = 'К объекту';
								|en = 'To object'; fa = 'To object';
								|it = 'All''oggetto';
								|pl = 'Do obiektu';
								|tr = 'Nesneye'"));
	ArrayInstructions.Add(" ");
	
	If Parameters.ThisIsAttributeLoadingRule
			Or Parameters.ThisIsTableLoadingRule
			Or Parameters.ThisIsConditionOfApplicabilityWhenLoading Then
		ArrayInstructions.Add(NStr("ru = '1С:Документооборота';
									|vi = '1C:Document Management';
									|en = '1C:Document Management'; fa = '1C:Document Management';
									|it = '1C:Document Management';
									|pl = '1C:Document Management';
									|tr = '1C:Document Management''in'"));
	Else
		ArrayInstructions.Add(DescriptionIS);
	EndIf;
	
	ArrayInstructions.Add(" ");
	ArrayInstructions.Add(
		StrTemplate(
			NStr("vi = 'có thể truy cập thông qua thuộc tính %1 biến %2.';
				|ru = 'можно обращаться через свойство %1 переменной %2.';
				|en = 'using the %1 property of the %2 variable.'; fa = 'using the %1 property of the %2 variable.';
				|it = 'using the %1 property of the %2 variable.';
				|pl = 'using the %1 property of the %2 variable.';
				|tr = '%2 değişkeninin %1 özelliği aracılığıyla erişilebilir.'"),
			"<b>Source</b>",
			"<b>Parameters</b>"));
	ArrayInstructions.Add("</p>");
	
	AddCollapsibleGroup(ArrayInstructions, True);
	ArrayInstructions.Add("<summary class=""pointer""><u><b>");
	ArrayInstructions.Add(NStr("vi = 'Chi tiết nguồn';
								|ru = 'Реквизиты источника';
								|en = 'Source attributes '; fa = 'ویژگی‌های مبدأ';
								|it = 'Requisiti della fonte';
								|pl = 'Dane płatnicze źródła';
								|tr = 'Kaynak öznitelikleri'"));
	ArrayInstructions.Add("</b></u></summary>");
	ArrayInstructions.Add("<blockquote><pre>");
	
	OutputOfIPObjectAttributes = False;
	If Parameters.ThisIsAttributeLoadingRule Or Parameters.ThisIsTableLoadingRule Then
		If Parameters.PlaceWhereExpressionIsExecuted = Enums.PlacesWhereExpressionsOnBuiltInLanguageAreExecuted.OnIntegratedSystemSide Then
			SourceAttributes = ObjectAttributesBefore(Parameters.ObjectTypeDM, Parameters.DocumentKindDMID, False);
			SourceAttributes.Sort("AdditionalAttribute5, ThisIsTable, Name");
		ElsIf Parameters.PlaceWhereExpressionIsExecuted = Enums.PlacesWhereExpressionsOnBuiltInLanguageAreExecuted.OnDocumentManagementSide Then
			Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
			Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMGetObjectMetadataRequest");
			
			Query.objectType = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMType");
			Query.objectType.xdtoClassName = Parameters.ObjectTypeDM;
			Query.objectType.presentation = Parameters.ObjectTypeDM;
			
			ObjectMetadata = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
			IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, ObjectMetadata);
			
			SourceAttributes = StructureOfTableOfAttributesTO();
			
			For Each MetadataProps In ObjectMetadata.attributes Do
				NewRow = SourceAttributes.Add();
				NewRow.Name = MetadataProps.name;
				NewRow.Presentation = MetadataProps.synonym;
				If StringFunctionsClientServer.IsUUID(MetadataProps.name) Then
					NewRow.AdditionalAttribute5 = True;
					NewRow.AdditionalAttribute5ID = MetadataProps.name;
				EndIf;
			EndDo;
			
			For Each MetadataTable In ObjectMetadata.tabularSections Do
				NewRow = SourceAttributes.Add();
				NewRow.Name = MetadataTable.name;
				NewRow.TableForSorting = MetadataTable.name;
				NewRow.Presentation = MetadataTable.synonym;
				NewRow.ThisIsTable = True;
				
				For Each MetadataProps In MetadataTable.attributes Do
					NewRow = SourceAttributes.Add();
					NewRow.Name = MetadataProps.name;
					NewRow.Presentation = MetadataProps.synonym;
					NewRow.Table = MetadataTable.name;
					NewRow.TableForSorting = MetadataTable.name;
				EndDo;
			EndDo;
			SourceAttributes.Sort("AdditionalAttribute5, TableForSorting, ThisIsTable DESC, Name");
		Else
			Raise NStr("ru = 'Не указано место выполнения выражения';
						|vi = 'Expression execution location is not specified';
						|en = 'Expression execution location is not specified'; fa = 'Expression execution location is not specified';
						|it = 'Expression execution location is not specified';
						|pl = 'Expression execution location is not specified';
						|tr = 'İfade yürütme yeri belirtilmedi'");
		EndIf;
	ElsIf Parameters.ThisIsConditionOfApplicabilityWhenUnloading Then
		SourceAttributes = IntegrationWith1CDocumentManagementCore.ObjectAttributesIS(
			Parameters.ObjectTypeIS,
			True);
		SourceAttributes.Sort("IsAdditionalAttributeIS, ThisIsTable, Name");
		OutputOfIPObjectAttributes = True;
	ElsIf Parameters.ThisIsConditionOfApplicabilityWhenLoading Then
		If ObjectAttributesBefore = Undefined Then
			SourceAttributes = ObjectAttributesBefore(Parameters.ObjectTypeDM, Parameters.DocumentKindDMID, False);
		Else
			SourceAttributes = ObjectAttributesBefore;
		EndIf;
		SourceAttributes.Sort("AdditionalAttribute5, ThisIsTable, Name");
	Else
		Raise NStr("ru = 'Не указан тип выражения';
					|vi = 'Expression type is not specified';
					|en = 'Expression type is not specified'; fa = 'Expression type is not specified';
					|it = 'Expression type is not specified';
					|pl = 'Expression type is not specified';
					|tr = 'İfade türü belirtilmedi'");
	EndIf;
	
	DisplayTableOfAttributes(ArrayInstructions, Parameters, SourceAttributes, OutputOfIPObjectAttributes);
	
	If (Parameters.ThisIsAttributeLoadingRule Or Parameters.ThisIsTableLoadingRule)
			And Parameters.PlaceWhereExpressionIsExecuted = Enums.PlacesWhereExpressionsOnBuiltInLanguageAreExecuted.OnIntegratedSystemSide Then
		
		ArrayInstructions.Add("<p>");
		ArrayInstructions.Add(NStr("vi = 'Với đối tượng';
									|ru = 'К объекту';
									|en = 'To object'; fa = 'To object';
									|it = 'All''oggetto';
									|pl = 'Do obiektu';
									|tr = 'Nesneye'"));
		ArrayInstructions.Add(" ");
		
		If ValueIsFilled(DescriptionIS) Then
			ArrayInstructions.Add(DescriptionIS);
		Else
			ArrayInstructions.Add(NStr("vi = 'hệ thống được tích hợp';
										|ru = 'интегрированной системы';
										|en = 'of the integrated system'; fa = 'of the integrated system';
										|it = 'del sistema integrato';
										|pl = 'systemu zintegrowanego';
										|tr = 'entegre sistemin'"));
		EndIf;
		
		ArrayInstructions.Add(" ");
		ArrayInstructions.Add(
			StrTemplate(
				NStr("vi = 'có thể truy cập thông qua thuộc tính %1 biến %2.';
					|ru = 'можно обращаться через свойство %1 переменной %2.';
					|en = 'using the %1 property of the %2 variable.'; fa = 'using the %1 property of the %2 variable.';
					|it = 'using the %1 property of the %2 variable.';
					|pl = 'using the %1 property of the %2 variable.';
					|tr = '%2 değişkeninin %1 özelliği aracılığıyla erişilebilir.'"),
				"<b>Receiver</b>",
				"<b>Parameters</b>"));
		ArrayInstructions.Add("</p>");
		
		AddCollapsibleGroup(ArrayInstructions, True);
		ArrayInstructions.Add("<summary class=""pointer""><u><b>");
		ArrayInstructions.Add(NStr("vi = 'Chi tiết đích';
									|ru = 'Реквизиты приемника';
									|en = 'Destination attributes'; fa = 'Destination attributes';
									|it = 'Destination attributes';
									|pl = 'Destination attributes';
									|tr = 'Alıcının öznitelikleri'"));
		ArrayInstructions.Add("</b></u></summary>");
		ArrayInstructions.Add("<blockquote><pre>");
		
		AttributesReceiver = IntegrationWith1CDocumentManagementCore.ObjectAttributesIS(
			Parameters.ObjectTypeIS,
			True);
		AttributesReceiver.Columns.Add("AdditionalAttribute5", New TypeDescription("Boolean"));
		AttributesReceiver.Sort("IsAdditionalAttributeIS, ThisIsTable, Name");
		
		DisplayTableOfAttributes(ArrayInstructions, Parameters, AttributesReceiver, True);
		
	EndIf;
	
	ArrayInstructions.Add("</body></html>");
	
	Return StrConcat(ArrayInstructions);
	
EndFunction

// Constructor of a structure that describes the context for executing an expression in an embedded language.
//
// Returns:
//   Structure:
//     * XDTODataObject - XDTODataObject - the object BEFORE, the source of the fill data.
//                  - Undefined - there is no specific source.
//     * ObjectIS - Arbitrary - data receiver.
//                - Undefined - a specific receiver is missing.
//     * SourceTable1 - String - the name of the table from which the download will be performed. It is used to fill in the
//          Attributes of the table, if the "From the object table..." option is configured for the table itself.
//     * DocumentKindDMID - String - ID of the document type that is the source.
//
Function ContextOfExpressionInEmbeddedLanguage() Export
	
	ContextOfExpression = New Structure;
	ContextOfExpression.Insert("XDTODataObject", Undefined);
	ContextOfExpression.Insert("ObjectIS", Undefined);
	ContextOfExpression.Insert("SourceTable1", "");
	ContextOfExpression.Insert("DocumentKindDMID", "");
	
	Return ContextOfExpression;
	
EndFunction

// Updates the rule representation according to the representations of objects and key details.
//
// Parameters:
//   IntegrationRule - CatalogObject.RulesForIntegrationWith1CDocumentManagement3 - integration rule for
//     filling in the IP object.
//
Procedure RefreshPresentation(IntegrationRule) Export
	
	// Let's assemble a representation of the IP object.
	IntegrationRule.ObjectPresentationIS = "";
	IntegrationRule.ObjectPresentationISWithKeyFields = "";
	
	ArrayIsCompleteRepresentationOfICObject = New Array;
	
	ConsumerObject = Metadata.FindByFullName(IntegrationRule.ObjectTypeIS);
	If ConsumerObject <> Undefined Then
		IntegrationRule.ObjectPresentationIS = ?(ConsumerObject.Synonym = "",
			ConsumerObject.Name,
			ConsumerObject.Synonym);
		
		ArrayIsCompleteRepresentationOfICObject.Add(IntegrationRule.ObjectPresentationIS);
		
		// Let's add the key details to the presentation.
		If Not IntegrationRule.UseApplicabilityConditionWhenExporting Then
			For Each KeyAttribute In IntegrationRule.KeyAttributesIS Do
				PresentationOfKeyAttributes = PresentationOfKeyAttributes(KeyAttribute);
				If PresentationOfKeyAttributes <> "" Then
					ArrayIsCompleteRepresentationOfICObject.Add(PresentationOfKeyAttributes);
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	IntegrationRule.ObjectPresentationISWithKeyFields = StrConcat(ArrayIsCompleteRepresentationOfICObject, ", ");
	
	If TrimAll(IntegrationRule.Comment) <> "" Then
		// The comment should not be included in the representation of the objectis, but should be included in the name.
		ArrayIsCompleteRepresentationOfICObject.Add(TrimAll(IntegrationRule.Comment));
	EndIf;
	
	// Let's put together a Presentation of the object BEFORE.
	ArrayRepresentationOfObjectDM = New Array;
	ArrayRepresentationOfObjectDM.Add(IntegrationRule.ObjectPresentationDM);
	
	If Not IntegrationRule.UseApplicabilityConditionWhenImporting Then
		For Each KeyAttribute In IntegrationRule.KeyAttributesDM Do
			If KeyAttribute.Name = "documentType" Then
				Continue;
			EndIf;
			PresentationOfKeyAttributes = PresentationOfKeyAttributes(KeyAttribute);
			If PresentationOfKeyAttributes <> "" Then
				ArrayRepresentationOfObjectDM.Add(PresentationOfKeyAttributes);
			EndIf;
		EndDo;
	EndIf;
	
	IntegrationRule.RepresentationOfDMObjectWithKeyAttributes = StrConcat(ArrayRepresentationOfObjectDM, ", ");
	
	// Let's collect the name.
	IntegrationRule.Description = StrTemplate("%1 - %2",
		StrConcat(ArrayIsCompleteRepresentationOfICObject, ", "),
		IntegrationRule.RepresentationOfDMObjectWithKeyAttributes);
	
EndProcedure

// Returns a selection of integration rules with selection by type and type of object BEFORE,
// but without selection by key Attributes.
//
// Parameters:
//   ObjectTypeDM - String - the type of object BEFORE specified in the rules.
//   DocumentKindDMID - String - filled in if the object BEFORE is a document.
//
// Returns:
//   QueryResultSelection:
//     * Ref - CatalogRef.RulesForIntegrationWith1CDocumentManagement3
//     * RepresentationOfDMObjectWithKeyAttributes - String
//     * ObjectPresentationISWithKeyFields - String
//     * Comment - String
//     * ObjectTypeDM - String
//     * ObjectTypeIS - String
//     * PresentationOfTheDocumentType - String
//     * IDOfDocumentType - String
//     * UseApplicabilityConditionWhenExporting - Boolean
//     * ApplicabilityConditionOnExport - String
//     * UseApplicabilityConditionWhenImporting - Boolean
//     * ApplicabilityConditionOnImport - String
//     * KeyAttributesDM - QueryResultSelection
//
Function CommonSetOfIntegrationRules(ObjectTypeDM, DocumentKindDMID = "") Export
	
	Query = New Query(
		"SELECT
		|	RulesForIntegrationWith1CDocumentManagement3.Ref AS Ref,
		|	RulesForIntegrationWith1CDocumentManagement3.RepresentationOfDMObjectWithKeyAttributes AS RepresentationOfDMObjectWithKeyAttributes,
		|	CAST(RulesForIntegrationWith1CDocumentManagement3.ObjectPresentationISWithKeyFields AS STRING(1024)) AS ObjectPresentationISWithKeyFields,
		|	RulesForIntegrationWith1CDocumentManagement3.Comment AS Comment,
		|	RulesForIntegrationWith1CDocumentManagement3.ObjectTypeDM AS ObjectTypeDM,
		|	RulesForIntegrationWith1CDocumentManagement3.ObjectTypeIS AS ObjectTypeIS,
		|	RulesForIntegrationWith1CDocumentManagement3.DocumentKindDM AS PresentationOfTheDocumentType,
		|	RulesForIntegrationWith1CDocumentManagement3.DocumentKindDMID AS IDOfDocumentType,
		|	RulesForIntegrationWith1CDocumentManagement3.UseApplicabilityConditionWhenExporting AS UseApplicabilityConditionWhenExporting,
		|	RulesForIntegrationWith1CDocumentManagement3.ApplicabilityConditionOnExport AS ApplicabilityConditionOnExport,
		|	RulesForIntegrationWith1CDocumentManagement3.UseApplicabilityConditionWhenImporting AS UseApplicabilityConditionWhenImporting,
		|	RulesForIntegrationWith1CDocumentManagement3.ApplicabilityConditionOnImport AS ApplicabilityConditionOnImport,
		|	RulesForIntegrationWith1CDocumentManagement3.KeyAttributesDM.(
		|		Name AS Name,
		|		AttributeValue AS AttributeValue,
		|		AttributeValueID AS AttributeValueID,
		|		AttributeValueType AS AttributeValueType,
		|		IsAdditionalAttributeDM AS IsAdditionalAttributeDM
		|	) AS KeyAttributesDM
		|FROM
		|	Catalog.RulesForIntegrationWith1CDocumentManagement3 AS RulesForIntegrationWith1CDocumentManagement3
		|WHERE
		|	NOT RulesForIntegrationWith1CDocumentManagement3.DeletionMark
		|	AND RulesForIntegrationWith1CDocumentManagement3.ObjectTypeDM = &ObjectTypeDM
		|	AND RulesForIntegrationWith1CDocumentManagement3.DocumentKindDMID = &DocumentKindDMID
		|
		|ORDER BY
		|	ObjectPresentationISWithKeyFields");
	Query.SetParameter("ObjectTypeDM", ObjectTypeDM);
	Query.SetParameter("DocumentKindDMID", DocumentKindDMID);
	
	Return Query.Execute().Select();
	
EndFunction

// Returns the details of the object TO the specified type, possibly with refinement to the type of document.
//
// Parameters:
//   ObjectTypeDM - String - the name of the Document Flow object type XDTO.
//   DocumentKindDMID - String - ID of the document type. Filled in if the object type BEFORE is equal to DMDocument.
//   GetAll - Boolean - allows you to return all possible Attributes, regardless of
//     the type of Document management object.
//   Settings_View - XDTODataObject - an implicitly returned value containing the document type settings.
//   AdditionalRequests - Array of XDTODataObject - a list of additional queries that need
//     to be executed in a package with other 1C queries for optimization purposes:Document management.
//   ResponsesToAdditionalRequests - Array of XDTODataObject - an implicit return value, a list of responses to additional requests.
//
// Returns:
//   See Catalogs.RulesForIntegrationWith1CDocumentManagement3.StructureOfTableOfAttributesTO
//
Function ObjectAttributesBefore(ObjectTypeDM, DocumentKindDMID, GetAll, Settings_View = Undefined,
		AdditionalRequests = Undefined, ResponsesToAdditionalRequests = Undefined) Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	PackageQueries = New Array;
	InitialRequestNumber = 0;
	
	If AdditionalRequests <> Undefined Then
		PackageQueries = Common.CopyRecursive(AdditionalRequests);
		InitialRequestNumber = PackageQueries.Count();
	EndIf;
	
	// General settings.
	FieldsReceived = New Array;
	FieldsReceived.Add("additionalProperties");
	FieldsReceived.Add("accessLevelEnabled");
	FieldsReceived.Add("activityMatterEnabled");
	FieldsReceived.Add("foldersEnabled");
	FieldsReceived.Add("organizationEnabled");
	FieldsReceived.Add("statusEnabled");
	FieldsReceived.Add("projectsEnabled");
	PackageQueries.Add(
		IntegrationWith1CDocumentManagementCore.GetNewObjectRequest(
			Proxy,
			ObjectTypeDM,
			FieldsReceived,
			DocumentKindDMID));
	
	If IntegrationWith1CDocumentManagement3.IsDocumentBefore3(ObjectTypeDM) Then
		If Not ValueIsFilled(DocumentKindDMID) Then
			PackageQueries.Add(
				IntegrationWith1CDocumentManagementCore.GetNewObjectRequest(
					Proxy,
					"DMDocumentType"));
		Else
			// Together with the type settings, we get the settings for the type of document.
			DocumentKindDM = New Structure("ID, Type", DocumentKindDMID, "DMDocumentType");
			Query = IntegrationWith1CDocumentManagementCore.GetRequestObjects(
				Proxy,
				CommonClientServer.ValueInArray(DocumentKindDM));
			PackageQueries.Add(Query);
		EndIf;
		
		ResponseToPackageRequests = IntegrationWith1CDocumentManagementCore.ExecuteBatchRequest(
			Proxy,
			PackageQueries,
			True);
		
		TypesSettings = ResponseToPackageRequests.responses[InitialRequestNumber];
		
		ResultOfSettingView = ResponseToPackageRequests.responses[InitialRequestNumber + 1];
		If IntegrationWith1CDocumentManagementCore.ValidateType(
				Proxy, ResultOfSettingView, "DMDocumentType") Then
			Settings_View = ResultOfSettingView;
		Else
			Settings_View = ResultOfSettingView.objects[0];
		EndIf;
	Else
		// We will receive only the type settings.
		ResponseToPackageRequests = IntegrationWith1CDocumentManagementCore.ExecuteBatchRequest(
			Proxy,
			PackageQueries,
			True);
		
		TypesSettings = ResponseToPackageRequests.responses[InitialRequestNumber];
	EndIf;
	
	If AdditionalRequests <> Undefined Then
		ResponsesToAdditionalRequests = New Array;
		For IndexOf = 0 To AdditionalRequests.UBound() Do
			ResponseToAdditionalRequest = ResponseToPackageRequests.responses[IndexOf];
			ResponsesToAdditionalRequests.Add(ResponseToAdditionalRequest);
		EndDo;
	EndIf;
	
	If IntegrationWith1CDocumentManagementCore.PropertySet(
			TypesSettings, "additionalProperties") Then
		AddAttributes = TypesSettings.additionalProperties;
	Else
		AddAttributes = New Array;
	EndIf;
	
	Attributes = StructureOfTableOfAttributesTO();
	
	// Document
	If IntegrationWith1CDocumentManagement3.IsDocumentBefore3(ObjectTypeDM) Then
		
		CounterpartiesOrPartiesAreUsed = (Settings_View.correspondentEnabled = True
			Or (Settings_View.partiesEnabled = True And Settings_View.isAPaymentRequest <> True));
		ThisIsNotCorrespondence = (Settings_View.isIncoming <> True And Settings_View.isOutgoing <> True);
		
		TypeSide = New ValueList;
		TypeSide.Add("DMEmployee", NStr("vi = 'Nhân viên';
										|ru = 'Сотрудники';
										|en = 'Employees'; fa = 'کارکنان';
										|it = 'Сотрудники';
										|pl = 'Employees';
										|tr = 'Çalışanlar'"));
		TypeSide.Add("DMCorrespondent", NStr("vi = 'Đối tác';
											|ru = 'Контрагенты';
											|en = 'Counterparties'; fa = 'طرف‌حساب‌ها';
											|it = 'Контрагенты';
											|pl = 'Counterparties';
											|tr = 'Cari hesaplar'"));
		TypeSide.Add("DMOrganization", NStr("vi = 'Doanh nghiệp';
											|ru = 'Организации';
											|en = 'Companies'; fa = 'شرکت‌ها';
											|it = 'Организации';
											|pl = 'Companies';
											|tr = 'İş yerleri'"));
		
		TypeContactPersonOfParty = New ValueList;
		TypeContactPersonOfParty.Add("DMEmployee", NStr("vi = 'Nhân viên';
														|ru = 'Сотрудники';
														|en = 'Employees'; fa = 'کارکنان';
														|it = 'Сотрудники';
														|pl = 'Employees';
														|tr = 'Çalışanlar'"));
		TypeContactPersonOfParty.Add("DMContactPerson", NStr("vi = 'Người liên hệ';
															|ru = 'Контактные лица';
															|en = 'Contact persons'; fa = 'اشخاص تماس';
															|it = 'Persone di contatto';
															|pl = 'Osoby kontaktowe';
															|tr = 'İrtibat kişileri'"));
		
		// type of document.
		AddAttribute(Attributes, "documentType", NStr("vi = 'Dạng chứng từ';
														|ru = 'Вид документа';
														|en = 'Document kind'; fa = 'نوع سند';
														|it = 'Tipologia di documento';
														|pl = 'Rodzaj dokumentu';
														|tr = 'Belge türü'"), "DMDocumentType", True, "DocumentKind");
		
		// General Attributes.
		AddAttribute(Attributes, "name", NStr("vi = 'Tên gọi';
												|ru = 'Наименование';
												|en = 'Name'; fa = 'نام';
												|it = 'Наименование';
												|pl = 'Name';
												|tr = 'Tanım'"), "String", True, "Description");
		AddAttribute(Attributes, "title", NStr("vi = 'Tiêu đề';
												|ru = 'Заголовок';
												|en = 'Title'; fa = 'عنوان';
												|it = 'Заголовок';
												|pl = 'Title';
												|tr = 'Başlık'"), "String", True, "Title");
		AddAttribute(Attributes, "summary", NStr("vi = 'Nội dung';
												|ru = 'Содержание';
												|en = 'Content'; fa = 'محتوا';
												|it = 'Содержание';
												|pl = 'Content';
												|tr = 'İçerik'"), "String",, "Content");
		AddAttribute(Attributes, "regNumber", NStr("vi = 'Số đăng ký';
													|ru = 'Регистрационный номер';
													|en = 'Registration number'; fa = 'شماره ثبت';
													|it = 'Numero di registrazione';
													|pl = 'Numer rejestracyjny';
													|tr = 'Kayıt numarası'"), "String",, "RegistrationNumber");
		AddAttribute(Attributes, "regDate", NStr("vi = 'Ngày đăng ký';
												|ru = 'Дата регистрации';
												|en = 'Registration date'; fa = 'تاریخ ثبت';
												|it = 'Data di registrazione';
												|pl = 'Data rejestracji';
												|tr = 'Kayıt tarihi'"), "Date",, "RegistrationDate");
		AddAttribute(Attributes, "author", NStr("vi = 'Người soạn';
												|ru = 'Подготовил';
												|en = 'Prepared by'; fa = 'تهیه‌شده توسط';
												|it = 'Подготовил';
												|pl = 'Prepared by';
												|tr = 'Hazırlayan'"), "DMEmployee",, "Prepared");
		AddAttribute(Attributes, "subdivision", NStr("vi = 'Bộ phận';
													|ru = 'Подразделение';
													|en = 'Business unit'; fa = 'Business unit';
													|it = 'Подразделение';
													|pl = 'Dział';
													|tr = 'Departman'"), "DMSubdivision",, "Department");
		AddAttribute(Attributes, "comment", NStr("vi = 'Ghi chú';
												|ru = 'Комментарий';
												|en = 'Comment'; fa = 'توضیحات';
												|it = 'Комментарий';
												|pl = 'Uwagi';
												|tr = 'Yorum'"), "String",, "Comment");
		AddAttribute(Attributes, "responsible", NStr("vi = 'Người chịu trách nhiệm';
													|ru = 'Ответственный';
													|en = 'Person responsible'; fa = 'شخص مسئول';
													|it = 'Ответственный';
													|pl = 'Osoba odpowiedzialna';
													|tr = 'Sorumlu'"), "DMEmployee",, "EmployeeResponsible");
		AddAttribute(Attributes, "deletionMark", NStr("vi = 'Đánh dấu xóa';
														|ru = 'Пометка удаления';
														|en = 'Deletion mark'; fa = 'علامت حذف';
														|it = 'Пометка удаления';
														|pl = 'Zaznaczenie usunięcia';
														|tr = 'Silme işareti'"), "Boolean");
		
		// Other Attributes.
		If GetAll Or Settings_View.performanceDateEnabled = True Then
			AddAttribute(Attributes, "performanceDate", NStr("vi = 'Thời hạn thực hiện';
															|ru = 'Срок исполнения';
															|en = 'Due date'; fa = 'تاریخ سررسید';
															|it = 'Tempo di esecuzione';
															|pl = 'Data realizacji';
															|tr = 'Son tarih'"), "Date",, "TaskDueDate");
		EndIf;
		If GetAll Or TypesSettings.accessLevelEnabled = True Then
			AddAttribute(Attributes, "accessLevel", NStr("vi = 'Độ mật';
														|ru = 'Гриф доступа';
														|en = 'Access label '; fa = 'Access label ';
														|it = 'Dicitura di accesso';
														|pl = 'Poziom dostępu';
														|tr = 'Erişim etiketi'"), "DMAccessLevel", True, "AccessBar");
		EndIf;
		If GetAll Or TypesSettings.activityMatterEnabled = True Then
			AddAttribute(Attributes, "activityMatter", NStr("vi = 'Vấn đề nghiệp vụ';
															|ru = 'Вопрос деятельности';
															|en = 'Activity issue'; fa = 'موضوع فعالیت';
															|it = 'Problema di attività';
															|pl = 'Kwestia działalności';
															|tr = 'Faaliyet sorusu'"), "DMActivityMatter", True, "QuestionOfActivity");
		EndIf;
		If GetAll Or TypesSettings.projectsEnabled = True Then
			AddAttribute(Attributes, "project", NStr("vi = 'Dự án';
													|ru = 'Проект';
													|en = 'Project'; fa = 'پروژه';
													|it = 'Проект';
													|pl = 'Project';
													|tr = 'Proje'"), "DMProject",, "Project");
		EndIf;
		If GetAll Or TypesSettings.foldersEnabled = True Then
			AddAttribute(Attributes, "folder", NStr("vi = 'Thư mục';
													|ru = 'Папка';
													|en = 'Folder'; fa = 'پوشه';
													|it = 'Папка';
													|pl = 'Folder';
													|tr = 'Klasör'"), "DMDocumentFolder", True, "Folder");
		EndIf;
		
		// States.
		If GetAll Or TypesSettings.statusEnabled = True Then
			If IntegrationWith1CDocumentManagementCore.PropertySet(Settings_View, "actionTypes") Then
				For Each ActionKindXDTO In Settings_View.actionTypes Do
					AddAttribute(
						Attributes,
						StrTemplate("status_%1", StrReplace(ActionKindXDTO.objectID.id, "-", "_")),
						StrTemplate(NStr("vi = 'Trạng thái thao tác ""%1""';
										|ru = 'Состояние действия ""%1""';
										|en = 'State of the %1 action'; fa = 'State of the %1 action';
										|it = 'Состояние действия ""%1""';
										|pl = 'State of the %1 action';
										|tr = '""%1"" işleminin durumu'"), ActionKindXDTO.name),
						"DMDocumentStatus",,,
						False);
				EndDo;
			Else
				AddAttribute(Attributes, "statusApproval", NStr("vi = 'Trạng thái thống nhất';
																|ru = 'Состояние согласования';
																|en = 'Approval state '; fa = 'وضعیت تأیید';
																|it = 'Stato omologazione';
																|pl = 'Status uzgodnienia';
																|tr = 'Onay durumu'"), "DMDocumentStatus",,, False);
				AddAttribute(Attributes, "statusConfirmation", NStr("vi = 'Trạng thái phê duyệt';
																	|ru = 'Состояние утверждения';
																	|en = 'Confirmation state'; fa = 'Confirmation state';
																	|it = 'Stato conferma';
																	|pl = 'Status zatwierdzenia';
																	|tr = 'Onay durumu'"), "DMDocumentStatus",,, False);
				AddAttribute(Attributes, "statusPerformance", NStr("vi = 'Trạng thái thực hiện';
																	|ru = 'Состояние исполнения';
																	|en = 'Execution state'; fa = 'Execution state';
																	|it = 'Stato esecuzione';
																	|pl = 'Status wykonania';
																	|tr = 'Yürütme durumu'"), "DMDocumentStatus",,, False);
				AddAttribute(Attributes, "statusRegistration", NStr("vi = 'Trạng thái đăng ký';
																	|ru = 'Состояние регистрации';
																	|en = 'Registration state'; fa = 'Registration state';
																	|it = 'Stato registrazione';
																	|pl = 'Status rejestracji';
																	|tr = 'Kayıt durumu'"), "DMDocumentStatus",,, False);
				AddAttribute(Attributes, "statusSigning", NStr("vi = 'Trạng thái ký';
																|ru = 'Состояние подписания';
																|en = 'Signature state'; fa = 'وضعیت امضا';
																|it = 'Stato firma';
																|pl = 'Status podpisania';
																|tr = 'İmza durumu'"), "DMDocumentStatus",,, False);
				If IntegrationWith1CDocumentManagementCore.PropertyExists(
						TypesSettings, "statusAcquaintance") Then
					AddAttribute(Attributes, "statusAcquaintance", NStr("vi = 'Trạng thái tham khảo';
																		|ru = 'Состояние ознакомления';
																		|en = 'Preview state'; fa = 'Preview state';
																		|it = 'Stato riconoscimento';
																		|pl = 'Status zapoznania się';
																		|tr = 'Tanışma durumu'"), "DMDocumentStatus",,, False);
				ElsIf IntegrationWith1CDocumentManagementCore.PropertyExists(
						TypesSettings, "statusExamination") Then
					AddAttribute(Attributes, "statusExamination", NStr("vi = 'Trạng thái tham khảo';
																		|ru = 'Состояние ознакомления';
																		|en = 'Preview state'; fa = 'Preview state';
																		|it = 'Stato riconoscimento';
																		|pl = 'Status zapoznania się';
																		|tr = 'Tanışma durumu'"), "DMDocumentStatus",,, False);
				EndIf;
			EndIf;
		EndIf;
		
		// Contractor.
		If GetAll Or CounterpartiesOrPartiesAreUsed Then
			Title = NStr("vi = 'Đối tác';
						|ru = 'Контрагент';
						|en = 'Counterparty'; fa = 'طرف حساب';
						|it = 'Контрагент';
						|pl = 'Counterparty';
						|tr = 'Cari hesap'");
			Required = False; // It will be mandatory to fill in the counterparty in the tabular part
			
			If Settings_View.isIncoming = True Then
				Title = NStr("vi = 'Người gửi';
							|ru = 'Отправитель';
							|en = 'Sender'; fa = 'فرستنده';
							|it = 'Отправитель';
							|pl = 'Nadawca';
							|tr = 'Gönderici'");
				Required = True;
			ElsIf Settings_View.isOutgoing = True Then
				Title = NStr("vi = 'Người nhận';
							|ru = 'Получатель';
							|en = 'Customer'; fa = 'مشتری';
							|it = 'Получатель';
							|pl = 'Odbiorca';
							|tr = 'Alıcı'");
				Required = True;
			EndIf;
			
			AddAttribute(Attributes, "correspondent", Title, "DMCorrespondent", Required, "Counterparty");
		EndIf;
		
		// Contact person
		If GetAll Or (CounterpartiesOrPartiesAreUsed And ThisIsNotCorrespondence) Then
			AddAttribute(Attributes, "contactPerson", NStr("vi = 'Người liên hệ';
															|ru = 'Контактное лицо';
															|en = 'Contact person'; fa = 'شخص تماس';
															|it = 'Contatto';
															|pl = 'Osoba do kontaktu';
															|tr = 'İrtibat kişisi'"), "DMContactPerson",, "ContactPerson");
		EndIf;
		
		// recipient.
		If GetAll Or Settings_View.isAPaymentRequest = True Then
			AddAttribute(Attributes, "recipient", NStr("vi = 'Người nhận';
														|ru = 'Получатель';
														|en = 'Recipient'; fa = 'گیرنده';
														|it = 'Получатель';
														|pl = 'Recipient';
														|tr = 'Alıcı'"), TypeSide, True,, False);
		EndIf;
		
		// The table part is Counterparties.
		If GetAll
				Or (Settings_View.correspondentEnabled = True And ThisIsNotCorrespondence) Then
			AddTable(Attributes, "correspondentRows.rows", NStr("vi = 'Đối tác';
																|ru = 'Контрагенты';
																|en = 'Counterparties'; fa = 'طرف‌حساب‌ها';
																|it = 'Контрагенты';
																|pl = 'Kontrahenci';
																|tr = 'Cari hesaplar'"));
			AddTableDetails(Attributes,
				"correspondentRows.rows", "correspondent", NStr("vi = 'Đối tác';
																|ru = 'Контрагент';
																|en = 'Counterparty'; fa = 'طرف حساب';
																|it = 'Контрагент';
																|pl = 'Kontrahent';
																|tr = 'Cari hesap'"), "DMCorrespondent", True);
			AddTableDetails(Attributes,
				"correspondentRows.rows", "contact", NStr("vi = 'Người liên hệ';
															|ru = 'Контактное лицо';
															|en = 'Contact person'; fa = 'شخص تماس';
															|it = 'Contatto';
															|pl = 'Osoba do kontaktu';
															|tr = 'İrtibat kişisi'"), "DMContactPerson");
			AddTableDetails(Attributes,
				"correspondentRows.rows",
				"signedFromTheCorrespondent", NStr("vi = 'Đã ký từ đối tác';
													|ru = 'Подписал от контрагента';
													|en = 'Signed on behalf of a counterparty'; fa = 'امضاشده از طرف طرف حساب';
													|it = 'Firmato dalla controparte';
													|pl = 'Podpisał od kontrahenta';
													|tr = 'Cari hesaptan imzalandı'"), "DMContactPerson");
		EndIf;
		
		// Organization.
		If GetAll Or Settings_View.organizationEnabled = True Then
			If Settings_View.isAPaymentRequest = True Then
				Title = NStr("vi = 'Người nộp';
							|ru = 'Плательщик';
							|en = 'Payer'; fa = 'پرداخت‌کننده';
							|it = 'Плательщик';
							|pl = 'Payer';
							|tr = 'Ödeyen'");
			Else
				Title = NStr("vi = 'Doanh nghiệp';
							|ru = 'Организация';
							|en = 'Company'; fa = 'Company';
							|it = 'Организация';
							|pl = 'Firma';
							|tr = 'İş yeri'");
			EndIf;
			
			AddAttribute(Attributes, "organization", Title, "DMOrganization", True, "Organization");
		EndIf;
		
		// External number and date.
		If GetAll Or Settings_View.externalNumberEnabled = True Then
			AddAttribute(Attributes, "externalNumber", NStr("vi = 'Số người nhận';
															|ru = '№ получателя';
															|en = 'Recipient No.'; fa = 'شماره گیرنده';
															|it = '№ destinatario';
															|pl = 'nr odbiorcy';
															|tr = 'Alıcı №'"), "String");
			AddAttribute(Attributes, "externalDate", NStr("vi = 'Ngày người nhận';
															|ru = 'Дата получателя';
															|en = 'Recipient date '; fa = 'تاریخ گیرنده';
															|it = 'Data destinatario';
															|pl = 'Data odbioru';
															|tr = 'Alıcı tarihi'"), "Date");
		EndIf;
		
		// The amount.
		If GetAll Or Settings_View.sumEnabled = True Then
			AddAttribute(Attributes, "sum", NStr("vi = 'Tổng số';
												|ru = 'Сумма';
												|en = 'Amount'; fa = 'مبلغ';
												|it = 'Сумма';
												|pl = 'Wartość';
												|tr = 'Tutar'"), "Number",, "Sum");
			AddAttribute(Attributes, "VAT", NStr("vi = 'Trong đó, thuế GTGT';
												|ru = 'В т.ч. НДС';
												|en = 'Including VAT'; fa = 'با احتساب مالیات بر ارزش افزوده';
												|it = 'Iva inclusa';
												|pl = 'w tym VAT';
												|tr = 'KDV dahil'"), "Number",, "VATAmount");
			AddAttribute(Attributes, "currency", NStr("vi = 'Tiền tệ';
														|ru = 'Валюта';
														|en = 'Currency'; fa = 'ارز';
														|it = 'Валюта';
														|pl = 'Currency';
														|tr = 'Para birimi'"), "DMCurrency",, "Currency");
		EndIf;
		
		// Signed from the counterparty.
		If GetAll Or Settings_View.isIncoming = True Then
			AddAttribute(Attributes, "signerFromTheCorrespondent", NStr("vi = 'Người ký';
																		|ru = 'Подписал';
																		|en = 'Signed by'; fa = 'امضاشده توسط';
																		|it = 'Подписал';
																		|pl = 'Signed by';
																		|tr = 'İmzaladı'"), "DMContactPerson",, "SignedFromCounterparty");
		EndIf;
		
		// Addressee.
		Show = GetAll;
		ValueType = "DMEmployee";
		If Settings_View.isIncoming = True Then
			Show = True;
			ValueType = "DMEmployee";
			IsRequired = False;
		ElsIf Settings_View.isOutgoing = True Then
			Show = True;
			ValueType = "DMContactPerson";
			IsRequired = False;
		ElsIf Settings_View.addresseeEnabled = True Then
			Show = True;
			ValueType = "DMEmployee";
			IsRequired = True;
		EndIf;
		If Show Then
			AddAttribute(Attributes, "addressee", NStr("vi = 'Người nhận';
														|ru = 'Адресат';
														|en = 'Addressee'; fa = 'مخاطب';
														|it = 'Адресат';
														|pl = 'Addressee';
														|tr = 'Alıcı'"), ValueType, IsRequired, "Addressee");
		EndIf;
		
		// Delivery.
		Show = GetAll;
		If Settings_View.isIncoming = True Then
			Show = True;
			Title = NStr("vi = 'Cách nhận';
						|ru = 'Способ получения';
						|en = 'Receipt method'; fa = 'روش دریافت';
						|it = 'Metodo di ricezione';
						|pl = 'Sposób odbioru';
						|tr = 'Alma yöntemi'");
		ElsIf Settings_View.isOutgoing = True Then
			Show = True;
			Title = NStr("vi = 'Cách gửi';
						|ru = 'Способ отправки';
						|en = 'Sending method'; fa = 'روش ارسال';
						|it = 'Metodo di spedizione';
						|pl = 'Sposób wysyłki';
						|tr = 'Gönderme yöntemi'");
		EndIf;
		If Show Then
			AddAttribute(Attributes, "deliveryMethod", Title, "DMDeliveryMethod");
		EndIf;
		
		// Sending.
		If GetAll Or Settings_View.isOutgoing = True Then
			AddAttribute(Attributes, "sent", NStr("vi = 'Đã gửi';
													|ru = 'Отправлен';
													|en = 'Sent'; fa = 'ارسال‌شده';
													|it = 'Отправлен';
													|pl = 'Sent';
													|tr = 'Gönderildi'"), "Boolean");
			AddAttribute(Attributes, "sendDate", NStr("vi = 'Ngày gửi';
														|ru = 'Дата отправки';
														|en = 'Date sent'; fa = 'تاریخ ارسال';
														|it = 'Data di spedizione';
														|pl = 'Data wysłania';
														|tr = 'Gönderilme tarihi'"), "Date");
		EndIf;
		
		// Expiration date.
		If GetAll Or Settings_View.durationEnabled = True Then
			AddAttribute(Attributes,
				"beginDate", NStr("vi = 'Ngày có hiệu lực';
									|ru = 'Дата начала действия';
									|en = 'Certificate start date'; fa = 'تاریخ شروع گواهی';
									|it = 'Data di inizio validità';
									|pl = 'Data rozpoczęcia działania';
									|tr = 'Geçerlilik başlangıç tarihi'"), "Date",, "ValidityStartDate");
			AddAttribute(Attributes,
				"endDate", NStr("vi = 'Ngày kết thúc hiệu lực';
								|ru = 'Дата окончания действия';
								|en = 'Certificate end date'; fa = 'تاریخ پایان گواهی';
								|it = 'Data di fine validità';
								|pl = 'Data wygaśnięcia';
								|tr = 'Geçerlilik bitiş tarihi'"), "Date",, "ValidityEndDate");
			AddAttribute(Attributes,
				"openEnded", NStr("vi = 'Không thời hạn';
									|ru = 'Бессрочный';
									|en = 'Permanent'; fa = 'دائمی';
									|it = 'Бессрочный';
									|pl = 'Permanent';
									|tr = 'Süresiz'"), "Boolean",, "Permanent");
			AddAttribute(Attributes,
				"prolongationProcedure", NStr("vi = 'Trình tự gia hạn';
												|ru = 'Порядок продления';
												|en = 'Extension procedure'; fa = 'رویه تمدید';
												|it = 'Ordine di proroga';
												|pl = 'Tryb przedłużenia';
												|tr = 'Uzatma prosedürü'"), "DMProlongationProcedure",, "ExtensionProcedure");
		EndIf;
		
		// Amounts under DDS items.
		If GetAll Or Settings_View.cashFlowDetailsEnabled = True Then
			AddTable(Attributes, "cashFlowRows.rows", NStr("vi = 'Dạng lưu chuyển tiền tệ';
															|ru = 'Статьи движения денежных средств';
															|en = 'Cash flow items'; fa = 'اقلام جریان وجوه نقد';
															|it = 'Voci flusso di denaro';
															|pl = 'Pozycje przepływów środków pieniężnych';
															|tr = 'Nakit akışı öğeleri'"));
			AddTableDetails(Attributes, "cashFlowRows.rows", "item", NStr("vi = 'Dạng';
																			|ru = 'Статья';
																			|en = 'Item'; fa = 'قلم';
																			|it = 'Статья';
																			|pl = 'Pozycja';
																			|tr = 'Kalem'"), "DMCashFlowItem", True);
			AddTableDetails(Attributes, "cashFlowRows.rows", "total", NStr("vi = 'Tổng số';
																			|ru = 'Сумма';
																			|en = 'Amount'; fa = 'مبلغ';
																			|it = 'Сумма';
																			|pl = 'Wartość';
																			|tr = 'Tutar'"), "Number");
			AddTableDetails(Attributes, "cashFlowRows.rows", "VAT", NStr("vi = 'Thuế GTGT';
																		|ru = 'Сумма НДС';
																		|en = 'VAT amount'; fa = 'مبلغ مالیات بر ارزش افزوده';
																		|it = 'Importo IVA';
																		|pl = 'Wartość VAT';
																		|tr = 'KDV tutarı'"), "Number");
		EndIf;
		
		// The tabular part of the Goods.
		If GetAll Or Settings_View.productRowsEnabled = True Then
			AddTable(Attributes, "productRows.rows", NStr("vi = 'Hàng hóa và dịch vụ';
															|ru = 'Товары и услуги';
															|en = 'Goods and services'; fa = 'کالاها و خدمات';
															|it = 'Articoli e servizi';
															|pl = 'Towary i usługi';
															|tr = 'Ürünler ve hizmetler'"));
			AddTableDetails(Attributes,
				"productRows.rows", "product", NStr("vi = 'Hàng hóa, dịch vụ';
													|ru = 'Товар, услуга';
													|en = 'Good, service'; fa = 'کالا، خدمت';
													|it = 'Articolo, servizio';
													|pl = 'Towar, usługa';
													|tr = 'Ürün, hizmet'"), "DMProduct");
			AddTableDetails(Attributes,
				"productRows.rows", "price", NStr("vi = 'Đơn giá';
													|ru = 'Цена';
													|en = 'Price'; fa = 'قیمت';
													|it = 'Цена';
													|pl = 'Cena';
													|tr = 'Fiyat'"), "Number");
			AddTableDetails(Attributes,
				"productRows.rows", "quantity", NStr("vi = 'Số lượng';
													|ru = 'Количество';
													|en = 'Quantity'; fa = 'مقدار';
													|it = 'Количество';
													|pl = 'Ilość';
													|tr = 'Miktar'"), "Number");
			AddTableDetails(Attributes,
				"productRows.rows", "measurementUnit", NStr("vi = 'Đơn vị tính';
															|ru = 'Единица измерения';
															|en = 'Unit of measure'; fa = 'واحد اندازه‌گیری';
															|it = 'Unità di misura';
															|pl = 'Jednosta miary';
															|tr = 'Ölçü birimi'"), "DMMeasurementUnit");
			If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("3.0.16.33") Then
				AddTableDetails(Attributes,
					"productRows.rows", "VATRateUniversal", NStr("vi = 'Thuế suất GTGT';
																|ru = 'Ставка НДС';
																|en = 'VAT rate'; fa = 'نرخ مالیات بر ارزش افزوده';
																|it = 'Aliquota IVA';
																|pl = 'Stawka VAT';
																|tr = 'KDV oranı'"), "DMVATRateUniversal");
			Else
				AddTableDetails(Attributes,
					"productRows.rows", "VATRate", NStr("vi = 'Thuế suất GTGT';
														|ru = 'Ставка НДС';
														|en = 'VAT rate'; fa = 'نرخ مالیات بر ارزش افزوده';
														|it = 'Aliquota IVA';
														|pl = 'Stawka VAT';
														|tr = 'KDV oranı'"), "DMVATRate");
			EndIf;
			AddTableDetails(Attributes,
				"productRows.rows", "VAT", NStr("vi = 'Thuế GTGT';
												|ru = 'Сумма НДС';
												|en = 'VAT amount'; fa = 'مبلغ مالیات بر ارزش افزوده';
												|it = 'Importo IVA';
												|pl = 'Wartość VAT';
												|tr = 'KDV tutarı'"), "Number");
			AddTableDetails(Attributes,
				"productRows.rows", "total", NStr("vi = 'Tổng số';
													|ru = 'Сумма';
													|en = 'Amount'; fa = 'مبلغ';
													|it = 'Сумма';
													|pl = 'Wartość';
													|tr = 'Tutar'"), "Number");
		EndIf;
		
		// The tabular part of the Side.
		If GetAll Or (Settings_View.partiesEnabled = True And Settings_View.isAPaymentRequest <> True) Then
			AddTable(Attributes, "partyRows.rows", NStr("vi = 'Các bên';
														|ru = 'Стороны';
														|en = 'Parties'; fa = 'طرفین';
														|it = 'Стороны';
														|pl = 'Parties';
														|tr = 'Taraflar'"));
			AddTableDetails(Attributes,
				"partyRows.rows", "comment", NStr("vi = 'Ghi chú';
													|ru = 'Комментарий';
													|en = 'Comment'; fa = 'توضیحات';
													|it = 'Комментарий';
													|pl = 'Komentarz';
													|tr = 'Yorum'"), "String");
			AddTableDetails(Attributes,
				"partyRows.rows", "contact", NStr("vi = 'Người liên hệ';
													|ru = 'Контактное лицо';
													|en = 'Contact person'; fa = 'شخص تماس';
													|it = 'Contatto';
													|pl = 'Osoba do kontaktu';
													|tr = 'İrtibat kişisi'"), TypeContactPersonOfParty);
			AddTableDetails(Attributes,
				"partyRows.rows", "description", NStr("vi = 'Tên gọi của bên';
														|ru = 'Наименование стороны';
														|en = 'Party name'; fa = 'Party name';
														|it = 'Denominazione parti';
														|pl = 'Nazwa strony';
														|tr = 'Taraf tanımı'"), "DMPartyName");
			AddTableDetails(Attributes,
				"partyRows.rows", "party", NStr("vi = 'Bên';
												|ru = 'Сторона';
												|en = 'Party'; fa = 'طرف';
												|it = 'Сторона';
												|pl = 'Strona';
												|tr = 'Taraf'"), TypeSide, True);
			AddTableDetails(Attributes,
				"partyRows.rows", "setBy", NStr("vi = 'Đã cài đặt';
												|ru = 'Установил';
												|en = 'Installed by'; fa = 'Installed by';
												|it = 'Установил';
												|pl = 'Ustawił';
												|tr = 'Ayarladı'"), "DMEmployee");
			AddTableDetails(Attributes,
				"partyRows.rows", "signatureDate", NStr("vi = 'Ngày ký';
														|ru = 'Дата подписи';
														|en = 'Date signed'; fa = 'تاریخ امضا';
														|it = 'Data della firma';
														|pl = 'Data podpisu';
														|tr = 'İmza tarihi'"), "Date");
			AddTableDetails(Attributes,
				"partyRows.rows", "signed", NStr("vi = 'Đã ký';
												|ru = 'Подписан';
												|en = 'Signed'; fa = 'امضاشده';
												|it = 'Подписан';
												|pl = 'Signed';
												|tr = 'İmzalandı'"), "Boolean");
			AddTableDetails(Attributes,
				"partyRows.rows", "signedBy", NStr("vi = 'Người ký';
													|ru = 'Подписал';
													|en = 'Signed by'; fa = 'امضاشده توسط';
													|it = 'Подписал';
													|pl = 'Signed by';
													|tr = 'İmzaladı'"), TypeContactPersonOfParty);
		EndIf;
		
	// Contractor.
	ElsIf ObjectTypeDM = "DMCorrespondent" Then
		
		AddAttribute(Attributes, "name", NStr("vi = 'Tên gọi';
												|ru = 'Наименование';
												|en = 'Name'; fa = 'نام';
												|it = 'Наименование';
												|pl = 'Name';
												|tr = 'Tanım'"), "String", True, "Description");
		AddAttribute(Attributes, "legalPrivatePerson", NStr("vi = 'Dạng đối tác';
															|ru = 'Вид контрагента';
															|en = 'Counterparty type'; fa = 'نوع طرف حساب';
															|it = 'Tipo del contraente';
															|pl = 'Rodzaj kontrahenta';
															|tr = 'Cari hesap türü'"), "DMLegalPrivatePerson", True, "LegalEntityIndividual");
		AddAttribute(Attributes, "inn", NStr("vi = 'MST';
											|ru = 'ИНН';
											|en = 'TIN'; fa = 'شناسه مالیاتی';
											|it = 'ИНН';
											|pl = 'NIP';
											|tr = 'VKN'"), "String",, "TIN");
		AddAttribute(Attributes, "kpp", NStr("vi = 'Mã chi nhánh';
											|ru = 'КПП';
											|en = 'KPP'; fa = 'KPP';
											|it = 'КПП';
											|pl = 'KPE (Kod Przyczyny wniesienia do Ewidencji)';
											|tr = 'KPP'"), "String",, "CRTR");
		AddAttribute(Attributes, "okpo", NStr("vi = 'Mã doanh nghiệp';
												|ru = 'Код по ОКПО';
												|en = 'OKPO code'; fa = 'کد OKPO';
												|it = 'Codice secondo il classificatore russo di imprese e organizzazioni';
												|pl = 'Kod wg OKVED';
												|tr = 'OKPO kodu'"), "String",, "NCBOCode");
		AddAttribute(Attributes, "comment", NStr("vi = 'Ghi chú';
												|ru = 'Комментарий';
												|en = 'Comment'; fa = 'توضیحات';
												|it = 'Комментарий';
												|pl = 'Uwagi';
												|tr = 'Yorum'"), "String",, "Comment");
		AddAttribute(Attributes, "fullName", NStr("vi = 'Tên đầy đủ';
													|ru = 'Полное наименование';
													|en = 'Full name'; fa = 'نام کامل';
													|it = 'Nome completo';
													|pl = 'Pełna nazwa';
													|tr = 'Tam tanım'"), "String",, "DescriptionFull");
		AddAttribute(Attributes, "privatePerson", NStr("vi = 'Cá nhân';
														|ru = 'Физическое лицо';
														|en = 'Individual'; fa = 'شخص حقیقی';
														|it = 'Persona fisica';
														|pl = 'Osoba fizyczna';
														|tr = 'Gerçek kişi'"), "DMPrivatePerson",, "Person");
		AddAttribute(Attributes, "responsible", NStr("vi = 'Người chịu trách nhiệm';
													|ru = 'Ответственный';
													|en = 'Person responsible'; fa = 'شخص مسئول';
													|it = 'Ответственный';
													|pl = 'Osoba odpowiedzialna';
													|tr = 'Sorumlu'"), "DMEmployee",, "EmployeeResponsible");
		AddAttribute(Attributes, "deletionMark", NStr("vi = 'Đánh dấu xóa';
														|ru = 'Пометка удаления';
														|en = 'Deletion mark'; fa = 'علامت حذف';
														|it = 'Пометка удаления';
														|pl = 'Zaznaczenie usunięcia';
														|tr = 'Silme işareti'"), "Boolean");
		
	// The event.
	ElsIf ObjectTypeDM = "DMMeeting" Then
		
		AddAttribute(Attributes, "name", NStr("vi = 'Tên gọi';
												|ru = 'Наименование';
												|en = 'Name'; fa = 'نام';
												|it = 'Наименование';
												|pl = 'Name';
												|tr = 'Tanım'"), "String", True, "Description");
		AddAttribute(Attributes, "type", NStr("vi = 'Dạng sự kiện';
												|ru = 'Вид мероприятия';
												|en = 'Event type'; fa = 'نوع رویداد';
												|it = 'Tipo di evento';
												|pl = 'Rodzaj wydarzenia';
												|tr = 'Etkinlik türü'"), "DMMeetingType", True, "TypeOfEvent");
		
		If GetAll Or TypesSettings.accessLevelEnabled = True Then
			AddAttribute(Attributes, "accessLevel", NStr("vi = 'Độ mật';
														|ru = 'Гриф доступа';
														|en = 'Access label '; fa = 'Access label ';
														|it = 'Dicitura di accesso';
														|pl = 'Poziom dostępu';
														|tr = 'Erişim etiketi'"), "DMAccessLevel", True, "AccessBar");
		EndIf;
		
		If GetAll Or TypesSettings.foldersEnabled = True Then
			AddAttribute(Attributes, "folder", NStr("vi = 'Thư mục';
													|ru = 'Папка';
													|en = 'Folder'; fa = 'پوشه';
													|it = 'Папка';
													|pl = 'Folder';
													|tr = 'Klasör'"), "DMMeetingFolder", True, "Folder");
		EndIf;
		
		OrganizerType = New ValueList;
		OrganizerType.Add("DMEmployee", NStr("vi = 'Nhân viên';
											|ru = 'Сотрудники';
											|en = 'Employees'; fa = 'کارکنان';
											|it = 'Сотрудники';
											|pl = 'Employees';
											|tr = 'Çalışanlar'"));
		OrganizerType.Add("DMCorrespondent", NStr("vi = 'Đối tác';
													|ru = 'Контрагенты';
													|en = 'Counterparties'; fa = 'طرف‌حساب‌ها';
													|it = 'Контрагенты';
													|pl = 'Counterparties';
													|tr = 'Cari hesaplar'"));
		AddAttribute(Attributes, "calledBy", NStr("vi = 'Người tổ chức';
													|ru = 'Организатор';
													|en = 'Organizer'; fa = 'سازمان‌دهنده';
													|it = 'Организатор';
													|pl = 'Organizer';
													|tr = 'Organizatör'"), OrganizerType, True, "Organizer");
		
		TypeChairman = New ValueList;
		TypeChairman.Add("DMEmployee", NStr("vi = 'Nhân viên';
											|ru = 'Сотрудники';
											|en = 'Employees'; fa = 'کارکنان';
											|it = 'Сотрудники';
											|pl = 'Employees';
											|tr = 'Çalışanlar'"));
		TypeChairman.Add("DMCorrespondent", NStr("vi = 'Đối tác';
												|ru = 'Контрагенты';
												|en = 'Counterparties'; fa = 'طرف‌حساب‌ها';
												|it = 'Контрагенты';
												|pl = 'Counterparties';
												|tr = 'Cari hesaplar'"));
		TypeChairman.Add("DMContactPerson", NStr("vi = 'Người liên hệ';
												|ru = 'Контактные лица';
												|en = 'Contact persons'; fa = 'اشخاص تماس';
												|it = 'Persone di contatto';
												|pl = 'Osoby kontaktowe';
												|tr = 'İrtibat kişileri'"));
		AddAttribute(Attributes, "chairPerson", NStr("vi = 'Người chủ trì';
													|ru = 'Председатель';
													|en = 'Chairperson'; fa = 'رئیس';
													|it = 'Председатель';
													|pl = 'Chairperson';
													|tr = 'Başkan'"), TypeChairman,, "Chairman");
		
		TypeSecretary = New ValueList;
		TypeSecretary.Add("DMEmployee", NStr("vi = 'Nhân viên';
											|ru = 'Сотрудники';
											|en = 'Employees'; fa = 'کارکنان';
											|it = 'Сотрудники';
											|pl = 'Employees';
											|tr = 'Çalışanlar'"));
		TypeSecretary.Add("DMCorrespondent", NStr("vi = 'Đối tác';
													|ru = 'Контрагенты';
													|en = 'Counterparties'; fa = 'طرف‌حساب‌ها';
													|it = 'Контрагенты';
													|pl = 'Counterparties';
													|tr = 'Cari hesaplar'"));
		TypeSecretary.Add("DMContactPerson", NStr("vi = 'Người liên hệ';
													|ru = 'Контактные лица';
													|en = 'Contact persons'; fa = 'اشخاص تماس';
													|it = 'Persone di contatto';
													|pl = 'Osoby kontaktowe';
													|tr = 'İrtibat kişileri'"));
		AddAttribute(Attributes, "secretary", NStr("vi = 'Thư ký';
													|ru = 'Секретарь';
													|en = 'Secretary'; fa = 'Secretary';
													|it = 'Секретарь';
													|pl = 'Secretary';
													|tr = 'Sekreter'"), TypeSecretary,, "Secretary");
		
		AddAttribute(Attributes, "comment", NStr("vi = 'Ghi chú';
												|ru = 'Комментарий';
												|en = 'Comment'; fa = 'توضیحات';
												|it = 'Комментарий';
												|pl = 'Uwagi';
												|tr = 'Yorum'"), "String",, "Comment");
		AddAttribute(Attributes, "description", NStr("vi = 'Mô tả cuộc họp';
													|ru = 'Описание мероприятия';
													|en = 'Event description'; fa = 'Event description';
													|it = 'Descrizione evento';
													|pl = 'Opis wydarzenia';
													|tr = 'Etkinlik ayrıntıları'"), "String",, "LongDesc");
		
		AddAttribute(Attributes, "startDate", NStr("vi = 'Ngày và giờ bắt đầu';
													|ru = 'Дата и время начала';
													|en = 'Date and time of beginning'; fa = 'Date and time of beginning';
													|it = 'Data e ora di inizio';
													|pl = 'Data i czas początku';
													|tr = 'Başlangıç tarihi ve saati'"), "Date",, "StartDate");
		AddAttribute(Attributes, "endDate", NStr("vi = 'Ngày và giờ kết thúc';
												|ru = 'Дата и время окончания';
												|en = 'Date and time of completion'; fa = 'Date and time of completion';
												|it = 'Data e ora di fine';
												|pl = 'Data i czas zakończenia';
												|tr = 'Bitiş tarihi ve saati'"), "Date",, "EndDate");
		
		AddAttribute(Attributes, "organization", NStr("vi = 'Doanh nghiệp';
														|ru = 'Организация';
														|en = 'Company'; fa = 'Company';
														|it = 'Организация';
														|pl = 'Company';
														|tr = 'İş yeri'"), "DMOrganization",, "Organization");
		AddAttribute(Attributes, "place", NStr("vi = 'Địa điểm tiến hành';
												|ru = 'Место проведения';
												|en = 'Location'; fa = 'مکان';
												|it = 'Luogo svolgimento';
												|pl = 'Miejsce przeprowadzenia';
												|tr = 'Konum'"), "String",, "Venue");
		AddAttribute(Attributes, "project", NStr("vi = 'Dự án';
												|ru = 'Проект';
												|en = 'Project'; fa = 'پروژه';
												|it = 'Проект';
												|pl = 'Project';
												|tr = 'Proje'"), "DMProject",, "Project");
		
		// The tabular part of the program
		AddTable(Attributes, "agenda", NStr("vi = 'Chương trình';
											|ru = 'Программа';
											|en = 'Application'; fa = 'برنامه';
											|it = 'Программа';
											|pl = 'Application';
											|tr = 'Uygulama'"));
		AddTableDetails(Attributes, "agenda", "employee", NStr("vi = 'Người thực hiện';
																|ru = 'Исполнитель';
																|en = 'Assignee'; fa = 'Assignee';
																|it = 'Исполнитель';
																|pl = 'Assignee';
																|tr = 'Atanan'"), "DMEmployee");
		AddTableDetails(Attributes,
			"agenda", "role", NStr("vi = 'Vai trò người thực hiện';
									|ru = 'Роль исполнителя';
									|en = 'Assignee''s role'; fa = 'نقش مجری';
									|it = 'Ruolo dell''esecutore';
									|pl = 'Rola wykonawcy';
									|tr = 'Atanan rolü'"), "DMBusinessProcessExecutorRole");
		AddTableDetails(Attributes,
			"agenda", "mainAddressingItem", NStr("vi = 'Đối tượng đánh địa chỉ chính người thực hiện';
												|ru = 'Основной объект адресации исполнителя';
												|en = 'Main business object for the assignee'; fa = 'Main business object for the assignee';
												|it = 'Oggetto principale di indirizzamento dell''esecutore';
												|pl = 'Podstawowy obiekt adresacji wykonawcy';
												|tr = 'Atanan adresleme ana nesnesi'"), "DMMainAddressingObject");
		AddTableDetails(Attributes,
			"agenda", "secondaryAddressingItem", NStr("vi = 'Đối tượng đánh địa chỉ bổ sung người thực hiện';
														|ru = 'Дополнительный объект адресации исполнителя';
														|en = 'Additional business object for the assignee'; fa = 'Additional business object for the assignee';
														|it = 'Oggetto aggiuntivo di indirizzamento dell''esecutore';
														|pl = 'Dodatkowy obiekt adresacji wykonawcy';
														|tr = 'Atanan adresleme ek nesnesi'"), "DMSecondaryAddressingObject");
		AddTableDetails(Attributes,
			"agenda", "number", NStr("vi = 'Số mục';
									|ru = 'Номер пункта';
									|en = 'Point number'; fa = 'Point number';
									|it = 'Numero del punto';
									|pl = 'Numer punktu';
									|tr = 'Madde numarası'"), "Number");
		AddTableDetails(Attributes,
			"agenda", "description", NStr("vi = 'Nội dung';
											|ru = 'Содержание';
											|en = 'Content'; fa = 'محتوا';
											|it = 'Содержание';
											|pl = 'Content';
											|tr = 'İçerik'"), "String");
		AddTableDetails(Attributes,
			"agenda", "comment", NStr("vi = 'Ghi chú';
										|ru = 'Комментарий';
										|en = 'Comment'; fa = 'توضیحات';
										|it = 'Комментарий';
										|pl = 'Komentarz';
										|tr = 'Yorum'"), "String");
		AddTableDetails(Attributes,
			"agenda", "decisionIsNecessary", NStr("vi = 'Cần đưa ra quyết định';
													|ru = 'Требует принятия решения';
													|en = 'Requires a decision'; fa = 'Requires a decision';
													|it = 'RIchiede una decisione';
													|pl = 'Wymaga podjęcia decyzji';
													|tr = 'Karar gerektiriyor'"), "Boolean");
		AddTableDetails(Attributes,
			"agenda", "estimatedDuration", NStr("vi = 'Thời gian dự tính (giây)';
												|ru = 'Время план (секунд)';
												|en = 'Planned time (seconds)'; fa = 'Planned time (seconds)';
												|it = 'Tempo pianificato (secondi)';
												|pl = 'Czas plan (sekund)';
												|tr = 'Zaman plan (saniye)'"), "Number");
		AddTableDetails(Attributes,
			"agenda", "duration", NStr("vi = 'Thời gian thực tế (giây)';
										|ru = 'Время факт (секунд)';
										|en = 'Actual time (seconds)'; fa = 'Actual time (seconds)';
										|it = 'Tempo effettivo (secondi)';
										|pl = 'Czas fakt (sekund)';
										|tr = 'Zaman gerçekleşen (saniye)'"), "Number");
		AddTableDetails(Attributes,
			"agenda", "startDate", NStr("vi = 'Ngày và giờ bắt đầu';
										|ru = 'Дата и время начала';
										|en = 'Date and time of beginning'; fa = 'Date and time of beginning';
										|it = 'Data e ora di inizio';
										|pl = 'Data i czas początku';
										|tr = 'Başlangıç tarihi ve saati'"), "Date");
		AddTableDetails(Attributes,
			"agenda", "endDate", NStr("vi = 'Ngày và giờ kết thúc';
										|ru = 'Дата и время окончания';
										|en = 'Date and time of completion'; fa = 'Date and time of completion';
										|it = 'Data e ora di fine';
										|pl = 'Data i czas zakończenia';
										|tr = 'Bitiş tarihi ve saati'"), "Date");
		
		// Table part Participants
		AddTable(Attributes, "attendees", NStr("vi = 'Người tham gia';
												|ru = 'Участники';
												|en = 'Participants'; fa = 'شرکت‌کنندگان';
												|it = 'Участники';
												|pl = 'Participants';
												|tr = 'Katılımcılar'"));
		AddTableDetails(Attributes,
			"attendees", "absent", NStr("vi = 'Vắng mặt';
										|ru = 'Отсутствовал';
										|en = 'Absent'; fa = 'Absent';
										|it = 'Отсутствовал';
										|pl = 'Absent';
										|tr = 'Katılmadı'"), "Boolean");
		AddTableDetails(Attributes,
			"attendees", "invitationStatus", NStr("vi = 'Trạng thái mời họp';
													|ru = 'Состояние приглашения';
													|en = 'Invitation state'; fa = 'Invitation state';
													|it = 'Stato di invito';
													|pl = 'Status zaproszenia';
													|tr = 'Davet durumu'"), "DMInvitationStatus");
		AddTableDetails(Attributes,
			"attendees", "mainAddressingObject", NStr("vi = 'Đối tượng đánh địa chỉ chính người tham gia';
														|ru = 'Основной объект адресации участника';
														|en = 'The main business object for the participant'; fa = 'The main business object for the participant';
														|it = 'Oggetto principale di indirizzamento del partecipante';
														|pl = 'Podstawowy obiekt adresacji uczestnika';
														|tr = 'Katılımcı adresleme ana nesne'"), "DMMainAddressingObject");
		AddTableDetails(Attributes,
			"attendees", "obligatory", NStr("vi = 'Bắt buộc có mặt';
											|ru = 'Явка обязательна';
											|en = 'Attendance is compulsory'; fa = 'حضور الزامی است';
											|it = 'Partecipazione obbligatoria';
											|pl = 'Obecność jest konieczna';
											|tr = 'Katılım gerekli'"), "Boolean");
		AddTableDetails(Attributes,
			"attendees", "role", NStr("vi = 'Vai trò người thực hiện';
										|ru = 'Роль исполнителя';
										|en = 'Assignee''s role'; fa = 'نقش مجری';
										|it = 'Ruolo dell''esecutore';
										|pl = 'Rola wykonawcy';
										|tr = 'Atanan rolü'"), "DMBusinessProcessExecutorRole");
		AddTableDetails(Attributes,
			"attendees", "secondaryAddressingObject", NStr("vi = 'Đối tượng đánh địa chỉ bổ sung người tham gia';
															|ru = 'Дополнительный объект адресации участника';
															|en = 'Additional business object for the participant'; fa = 'Additional business object for the participant';
															|it = 'Oggetto aggiuntivo di indirizzamento del partecipante';
															|pl = 'Dodatkowy obiekt adresacji uczestnika';
															|tr = 'Katılımcı adresleme ek nesnesi'"), "DMSecondaryAddressingObject");
		AddTableDetails(Attributes,
			"attendees", "employee", NStr("vi = 'Người sử dụng';
											|ru = 'Пользователь';
											|en = 'User'; fa = 'کاربر';
											|it = 'Пользователь';
											|pl = 'User';
											|tr = 'Kullanıcı'"), "DMEmployee");
		
		// The tabular part of the State
		AddTable(Attributes, "statuses", NStr("vi = 'Trạng thái';
												|ru = 'Состояния';
												|en = 'State'; fa = 'وضعیت';
												|it = 'Состояния';
												|pl = 'State';
												|tr = 'Durumlar'"));
		AddTableDetails(Attributes,
			"statuses", "objectID.ID", NStr("vi = 'Tình trạng';
											|ru = 'Состояние';
											|en = 'State'; fa = 'وضعیت';
											|it = 'Состояние';
											|pl = 'State';
											|tr = 'Durum'"), "String");
		
	EndIf;
	
	// Additional properties.
	For Each AdditionalProperty1 In AddAttributes Do
		
		If Not IntegrationWith1CDocumentManagementCore.PropertySet(AdditionalProperty1, "propertyValueTypes") Then
			Continue;
		EndIf;
		
		Types = New ValueList;
		For Each TypeDetails In AdditionalProperty1.propertyValueTypes Do
			If TypeDetails.xdtoClassName = "integer" Then
				ValueType = "Number";
			ElsIf TypeDetails.xdtoClassName = "boolean" Then
				ValueType = "Boolean";
			ElsIf TypeDetails.xdtoClassName = "string" Then
				ValueType = "String";
			ElsIf TypeDetails.xdtoClassName = "date" Then
				ValueType = "Date";
			Else
				ValueType = TypeDetails.xdtoClassName;
			EndIf;
			Types.Add(ValueType, TypeDetails.presentation);
		EndDo;
		
		AddAdditionalProps(
			Attributes,
			AdditionalProperty1.name,
			Types,
			AdditionalProperty1.objectID.ID,
			AdditionalProperty1.objectID.type);
		
	EndDo;
	
	Return Attributes;
	
EndFunction

// Constructor of a structure that describes the parameters of an expression in the embedded language.
//
// Returns:
//  Structure:
//     * ThisIsAttributeLoadingRule - Boolean - this is an expression for filling in the Attributes of the IP object.
//     * ThisIsTableLoadingRule - Boolean - this is an expression for filling in the table of the IC object.
//     * ThisIsConditionOfApplicabilityWhenUnloading - Boolean - this is an expression that defines the applicability of the rule
//         when uploading objects to the DO.
//     * ThisIsConditionOfApplicabilityWhenLoading - Boolean - this is an expression that defines the applicability of the rule
//         when loading objects from BEFORE.
//     * ObjectTypeDM - String - name of the object type BEFORE.
//     * DocumentKindDMID - String - id of the document type BEFORE.
//     * ObjectTypeIS - String - name of the IP object type.
//     * AttributeNameObjectIS - String - name of the IP object Attribute to be filled in.
//     * CurCurrentLineIsAvailable - Boolean - True if a row of the table part is filled in in the context of the expression.
//     * SourceTable2 - String - the name of the tabular part that is the source of filling
//         in the tabular part of the IP object.
//     * PlaceWhereExpressionIsExecuted - EnumRef.PlacesWhereExpressionsOnBuiltInLanguageAreExecuted - indicates
//         on the side of which system (BEFORE or AFTER) the expression will be executed.
//
Function ParametersOfExpressionInEmbeddedLanguage() Export
	
	ExpressionParameters = New Structure;
	
	ExpressionParameters.Insert("ThisIsAttributeLoadingRule", False);
	ExpressionParameters.Insert("ThisIsTableLoadingRule", False);
	ExpressionParameters.Insert("ThisIsConditionOfApplicabilityWhenUnloading", False);
	ExpressionParameters.Insert("ThisIsConditionOfApplicabilityWhenLoading", False);
	ExpressionParameters.Insert("ObjectTypeDM", "");
	ExpressionParameters.Insert("DocumentKindDMID", "");
	ExpressionParameters.Insert("ObjectTypeIS", "");
	ExpressionParameters.Insert("AttributeNameObjectIS", "");
	ExpressionParameters.Insert("CurCurrentLineIsAvailable", False);
	ExpressionParameters.Insert("SourceTable2", "");
	ExpressionParameters.Insert("PlaceWhereExpressionIsExecuted",
		Enums.PlacesWhereExpressionsOnBuiltInLanguageAreExecuted.OnIntegratedSystemSide);
	
	Return ExpressionParameters;
	
EndFunction

// Checks the expression in the built-in language used to fill in the details when receiving data from BEFORE.
//
// Parameters:
//   ComputedExpression - String - expression in the built-in language.
//   PlaceWhereExpressionIsExecuted - EnumRef.PlacesWhereExpressionsOnBuiltInLanguageAreExecuted - specifies
//     exactly where the expression should be executed in the embedded language, on the DO side or on the IC side.
//   ObjectTypeDM - String - 1C object type:Document flow.
//   ObjectTypeIS - String - the type of the integrated system object.
//   ContextOfExpression - See Catalogs.RulesForIntegrationWith1CDocumentManagement3.ContextOfExpressionInEmbeddedLanguage
//   ThisIsTable - Boolean - this is an expression for filling the table.
//
Procedure CheckLoadingRuleExpression(ComputedExpression, PlaceWhereExpressionIsExecuted, ObjectTypeDM,
		ObjectTypeIS, ContextOfExpression, ThisIsTable = False) Export
	
	If TrimAll(ComputedExpression) = "" Or Not ValueIsFilled(PlaceWhereExpressionIsExecuted) Then
		Return;
	EndIf;
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	If PlaceWhereExpressionIsExecuted = Enums.PlacesWhereExpressionsOnBuiltInLanguageAreExecuted.OnIntegratedSystemSide Then
		
		If ContextOfExpression.XDTODataObject = Undefined Then
			ContextOfExpression.XDTODataObject = IntegrationWith1CDocumentManagementCore.NewObjectBefore(
				Proxy,
				ObjectTypeDM,,,
				ContextOfExpression.DocumentKindDMID);
		EndIf;
		
		If ContextOfExpression.ObjectIS = Undefined Then
			ContextOfExpression.ObjectIS = IntegrationWith1CDocumentManagementCore.NewIPObject(ObjectTypeIS);
		EndIf;
		
		CurrentRow = Undefined;
		If ContextOfExpression.SourceTable1 <> "" Then
			StringParts1 = StrSplit(ContextOfExpression.SourceTable1, ".");
			URIOfNamespaceOfWorkflowWebService =
				IntegrationWith1CDocumentManagementCore.URIOfNamespaceOfWorkflowWebService();
			XDTOObjectType = Proxy.XDTOFactory.Packages.Get(
				URIOfNamespaceOfWorkflowWebService).Get(ObjectTypeDM);
			
			If StringParts1.Count() = 1 Then
				RowType = XDTOObjectType.Properties.Get(StringParts1[0]).Type.Name;
				
			ElsIf StringParts1.Count() = 2 Then
				RowType = XDTOObjectType.Properties.Get(StringParts1[0]).Type.Properties.Get(StringParts1[1]).Type.Name;
				
			Else
				RowType = "";
				
			EndIf;
			
			If RowType <> "" Then
				CurrentRow = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, RowType);
			EndIf;
		EndIf;
		
		Result = IntegrationWith1CDocumentManagement3.ResultOfExpressionInEmbeddedLanguage(
			ComputedExpression,
			ContextOfExpression.XDTODataObject,
			ContextOfExpression.ObjectIS,
			CurrentRow);
		If ThisIsTable And TypeOf(Result) <> Type("ValueTable") Then
			Raise StrTemplate(
				NStr("vi = 'Để điền bảng, kết quả cần có kiểu %1';
					|ru = 'Для заполнения таблицы результат должен иметь тип %1';
					|en = 'To fill the table, the result must have the %1 type'; fa = 'To fill the table, the result must have the %1 type';
					|it = 'Для заполнения таблицы результат должен иметь тип %1';
					|pl = 'To fill the table, the result must have the %1 type';
					|tr = 'Tabloyu doldurmak için sonucun sütun türünde %1 olması gerekir'"),
				"ValueTable");
		EndIf;
		
	ElsIf PlaceWhereExpressionIsExecuted = Enums.PlacesWhereExpressionsOnBuiltInLanguageAreExecuted.OnDocumentManagementSide Then
		
		Query = IntegrationWith1CDocumentManagementCore.CreateObject(
			Proxy, "DMCheckExpressionOnBuiltInLanguageRequest");
		Query.expressionOnBuiltInLanguage = ComputedExpression;
		If IntegrationWith1CDocumentManagementCore.PropertyExists(Query, "forTabularSection") Then
			Query.forTabularSection = ThisIsTable;
		EndIf;
		Query.tabularSectionName = ContextOfExpression.SourceTable1;
		
		Query.objectType = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMType");
		Query.objectType.xdtoClassName = ObjectTypeDM;
		Query.objectType.presentation = ObjectTypeDM;
		
		ResultOfCheckingExpression = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
		IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, ResultOfCheckingExpression);
		
	EndIf;
	
EndProcedure

// Checks the expression in the built-in language used to check the applicability of the rule when transferring data to the DO.
//
// Parameters:
//   ComputedExpression - String - expression in the built-in language.
//   ObjectTypeIS - String - the type of the integrated system object.
//
Procedure CheckApplicabilityConditionExpressionWhenUploading(ComputedExpression, ObjectTypeIS) Export
	
	If TrimAll(ComputedExpression) = "" Then
		Return;
	EndIf;
	
	ObjectIS = IntegrationWith1CDocumentManagementCore.NewIPObject(ObjectTypeIS);
	
	Result = IntegrationWith1CDocumentManagement3.ResultOfExpressionInEmbeddedLanguage(ComputedExpression, ObjectIS);
	
	ResultType = TypeOf(Result);
	If ResultType <> Type("Boolean") Then
		Raise StrTemplate(
			NStr("ru = 'Результат выражения условия применимости правила имеет тип ""%1"", а должен иметь тип ""Булево"".';
				|vi = 'The result of the expression for the rule applicability condition has the ""%1"" type, but it should be of the ""Boolean"" type.';
				|en = 'The result of the expression for the rule applicability condition has the ""%1"" type, but it should be of the ""Boolean"" type.'; fa = 'The result of the expression for the rule applicability condition has the ""%1"" type, but it should be of the ""Boolean"" type.';
				|it = 'The result of the expression for the rule applicability condition has the ""%1"" type, but it should be of the ""Boolean"" type.';
				|pl = 'The result of the expression for the rule applicability condition has the ""%1"" type, but it should be of the ""Boolean"" type.';
				|tr = 'Kural uygulanabilirlik koşulu ifadesinin sonucu ""%1"" türündedir, ancak ""Boolean"" türünde olmalıdır.'"),
			ResultType);
	EndIf;
	
EndProcedure

// Checks the expression in the built-in language used to check the applicability of the rule when retrieving data from BEFORE.
//
// Parameters:
//   ComputedExpression - String - expression in the built-in language.
//   ObjectTypeDM - String - 1C object type:Document flow.
//   ContextOfExpression - See Catalogs.RulesForIntegrationWith1CDocumentManagement3.ContextOfExpressionInEmbeddedLanguage
//
Procedure CheckApplicabilityConditionExpressionWhenLoading(ComputedExpression, ObjectTypeDM,
		ContextOfExpression) Export
	
	If TrimAll(ComputedExpression) = "" Then
		Return;
	EndIf;
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	XDTODataObject = IntegrationWith1CDocumentManagementCore.NewObjectBefore(
		Proxy,
		ObjectTypeDM,,,
		ContextOfExpression.DocumentKindDMID);
	
	Result = IntegrationWith1CDocumentManagement3.ResultOfExpressionInEmbeddedLanguage(ComputedExpression, XDTODataObject);
	
	ResultType = TypeOf(Result);
	If ResultType <> Type("Boolean") Then
		Raise StrTemplate(
			NStr("ru = 'Результат выражения условия применимости правила имеет тип ""%1"", а должен иметь тип ""Булево"".';
				|vi = 'The result of the expression for the rule applicability condition has the ""%1"" type, but it should be of the ""Boolean"" type.';
				|en = 'The result of the expression for the rule applicability condition has the ""%1"" type, but it should be of the ""Boolean"" type.'; fa = 'The result of the expression for the rule applicability condition has the ""%1"" type, but it should be of the ""Boolean"" type.';
				|it = 'The result of the expression for the rule applicability condition has the ""%1"" type, but it should be of the ""Boolean"" type.';
				|pl = 'The result of the expression for the rule applicability condition has the ""%1"" type, but it should be of the ""Boolean"" type.';
				|tr = 'Kural uygulanabilirlik koşulu ifadesinin sonucu ""%1"" türündedir, ancak ""Boolean"" türünde olmalıdır.'"),
			ResultType);
	EndIf;
	
EndProcedure

// Checks the integration rule.
//
// Parameters:
//   IntegrationRule - CatalogObject.RulesForIntegrationWith1CDocumentManagement3 - integration rule for
//     filling in the IP object.
//
Procedure ToCheckRule(IntegrationRule) Export
	
	If Not ValueIsFilled(IntegrationRule.ObjectTypeDM) Then
		Raise NStr("vi = 'Chưa đặt kiểu đối tượng 1C:Document Management';
					|ru = 'Не задан тип объекта 1С:Документооборот';
					|en = '1C:Document Management object type is not specified'; fa = '1C:Document Management object type is not specified';
					|it = 'Tipo di oggetto 1C:Document Management non impostato';
					|pl = 'Nie zadano typu obiektu 1C:Document Management';
					|tr = '1C:Document Management nesnesinin türü ayarlanmadı'");
	EndIf;
	
	AttributesOfTheCurrentDocumentKindDM = ObjectAttributesBefore(
		IntegrationRule.ObjectTypeDM,
		IntegrationRule.DocumentKindDMID,
		False);
	
	AllMapItemDetailsUpTo = ObjectAttributesBefore(
		IntegrationRule.ObjectTypeDM,
		IntegrationRule.DocumentKindDMID,
		True);
	
	ObjectAttributesIS = IntegrationWith1CDocumentManagementCore.ObjectAttributesIS(
		IntegrationRule.ObjectTypeIS);
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	XDTODataObject = IntegrationWith1CDocumentManagementCore.NewObjectBefore(
		Proxy,
		IntegrationRule.ObjectTypeDM,,,
		IntegrationRule.DocumentKindDMID);
	ObjectIS = IntegrationWith1CDocumentManagementCore.NewIPObject(IntegrationRule.ObjectTypeIS);
	
	ErrorList = New Array;
	
	CheckTheAttributeFillingRulesIS(
		IntegrationRule,
		ObjectIS,
		XDTODataObject,
		ObjectAttributesIS,
		AttributesOfTheCurrentDocumentKindDM,
		AllMapItemDetailsUpTo,
		ErrorList);
	
	If IntegrationRule.UseApplicabilityConditionWhenExporting Then
		If TrimAll(IntegrationRule.ApplicabilityConditionOnExport) = "" Then
			ErrorList.Add(
				NStr("ru = 'Не заполнено произвольное выражение, определяющее применимость правила при выгрузке объектов в 1С:Документооборот';
					|vi = 'The custom expression that determines the applicability of the rule when exporting objects to 1C:Document Management is not filled in';
					|en = 'The custom expression that determines the applicability of the rule when exporting objects to 1C:Document Management is not filled in'; fa = 'The custom expression that determines the applicability of the rule when exporting objects to 1C:Document Management is not filled in';
					|it = 'The custom expression that determines the applicability of the rule when exporting objects to 1C:Document Management is not filled in';
					|pl = 'The custom expression that determines the applicability of the rule when exporting objects to 1C:Document Management is not filled in';
					|tr = 'Nesnelerin 1C:Document Management''a dışa aktarımı sırasında kuralın uygulanabilirliğini belirleyen serbest ifade doldurulmadı'"));
		Else
			Try
				CheckApplicabilityConditionExpressionWhenUploading(
					IntegrationRule.ApplicabilityConditionOnExport,
					IntegrationRule.ObjectTypeIS);
			Except
				ExceptionText = ErrorProcessing.BriefErrorDescription(ErrorInfo());
				ErrorList.Add(
					StrTemplate(
						NStr("ru = 'Ошибка в условии применимости правила для выгрузки объектов в 1С:Документооборот:
							|Не удалось выполнить выражение на встроенном языке по причине:
							|%1';
							|vi = 'An error in the rule applicability condition for exporting objects to 1C:Document Management:
							|Cannot execute the expression in 1C:Enterprise language due to:
							|%1';
							|en = 'An error in the rule applicability condition for exporting objects to 1C:Document Management:
							|Cannot execute the expression in 1C:Enterprise language due to:
							|%1'; fa = 'An error in the rule applicability condition for exporting objects to 1C:Document Management:
							|Cannot execute the expression in 1C:Enterprise language due to:
							|%1';
							|it = 'An error in the rule applicability condition for exporting objects to 1C:Document Management:
							|Cannot execute the expression in 1C:Enterprise language due to:
							|%1';
							|pl = 'An error in the rule applicability condition for exporting objects to 1C:Document Management:
							|Cannot execute the expression in 1C:Enterprise language due to:
							|%1';
							|tr = 'Nesnelerin 1C:Document Management''a dışa aktarımı için kural uygulanabilirlik koşulunda hata: 
							| Yerleşik dildeki ifade şu nedenle yürütülemedi:
							|%1'"),
						ExceptionText));
			EndTry;
		EndIf;
	EndIf;
	
	If IntegrationRule.UseApplicabilityConditionWhenImporting Then
		If TrimAll(IntegrationRule.ApplicabilityConditionOnImport) = "" Then
			ErrorList.Add(
				NStr("ru = 'Не заполнено произвольное выражение, определяющее применимость правила при загрузке объектов из 1С:Документооборота';
					|vi = 'The custom expression that determines the applicability of the rule when importing objects from 1C:Document Management is not filled in';
					|en = 'The custom expression that determines the applicability of the rule when importing objects from 1C:Document Management is not filled in'; fa = 'The custom expression that determines the applicability of the rule when importing objects from 1C:Document Management is not filled in';
					|it = 'The custom expression that determines the applicability of the rule when importing objects from 1C:Document Management is not filled in';
					|pl = 'The custom expression that determines the applicability of the rule when importing objects from 1C:Document Management is not filled in';
					|tr = 'Nesnelerin 1C:Document Management''tan içe aktarımı sırasında kuralın uygulanabilirliğini belirleyen serbest ifade doldurulmadı'"));
		Else
			ContextOfExpression = ContextOfExpressionInEmbeddedLanguage();
			ContextOfExpression.DocumentKindDMID = IntegrationRule.DocumentKindDMID;
			Try
				CheckApplicabilityConditionExpressionWhenLoading(
					IntegrationRule.ApplicabilityConditionOnImport,
					IntegrationRule.ObjectTypeDM,
					ContextOfExpression);
			Except
				ExceptionText = ErrorProcessing.BriefErrorDescription(ErrorInfo());
				ErrorList.Add(
					StrTemplate(
						NStr("ru = 'Ошибка в условии применимости правила для загрузки объектов из 1С:Документооборота:
							|Не удалось выполнить выражение на встроенном языке по причине:
							|%1';
							|vi = 'An error in the rule applicability condition for importing objects from 1C:Document Management:
							|Cannot execute the expression in 1C:Enterprise language due to:
							|%1';
							|en = 'An error in the rule applicability condition for importing objects from 1C:Document Management:
							|Cannot execute the expression in 1C:Enterprise language due to:
							|%1'; fa = 'An error in the rule applicability condition for importing objects from 1C:Document Management:
							|Cannot execute the expression in 1C:Enterprise language due to:
							|%1';
							|it = 'An error in the rule applicability condition for importing objects from 1C:Document Management:
							|Cannot execute the expression in 1C:Enterprise language due to:
							|%1';
							|pl = 'An error in the rule applicability condition for importing objects from 1C:Document Management:
							|Cannot execute the expression in 1C:Enterprise language due to:
							|%1';
							|tr = 'Nesnelerin 1C:Document Management''tan içe aktarımı için kural uygulanabilirlik koşulunda hata:
							|Yerleşik dildeki ifade şu nedenle yürütülemedi:
							|%1'"),
						ExceptionText));
			EndTry;
		EndIf;
	EndIf;
	
	CheckAvailabilityForDuplicates(IntegrationRule, ErrorList);
	
	If ErrorList.Count() > 0 Then
		Raise StrConcat(ErrorList, Chars.LF + Chars.LF);
	EndIf;
	
EndProcedure

// Using the link to the rule for uploading data to the DO, it searches for related integration rules in the IP. Returns True if
// available, and False if there are no related integration rules.
//
// Parameters:
//   Message - XDTODataObject - an XDTO object of type DMILRelatedIntegrationRulesExistenceRequest.
//
// Returns:
//   XDTODataObject - an XDTO object of type DMILRelatedIntegrationRulesExistenceResponse or DMError.
//
Function RelatedIntegrationRulesExist(Message) Export
	
	Try
		
		Query = New Query(
			"SELECT TOP 1
			|	RulesForIntegrationWith1CDocumentManagement3.Ref AS Ref
			|FROM
			|	Catalog.RulesForIntegrationWith1CDocumentManagement3 AS RulesForIntegrationWith1CDocumentManagement3
			|WHERE
			|	RulesForIntegrationWith1CDocumentManagement3.DMDataLoadingRule = &DMDataLoadingRule
			|	AND NOT RulesForIntegrationWith1CDocumentManagement3.DeletionMark");
		Query.SetParameter("DMDataLoadingRule", Message.relatedDataLoadingRule);
		
		Response = IntegrationWith1CDocumentManagement3.CreateBIDObject("DMILRelatedIntegrationRulesExistenceResponse");
		Response.exist = Not Query.Execute().IsEmpty();
		
	Except
		
		Response = IntegrationWith1CDocumentManagement3.DescriptionOfXDTOError(
			NStr("vi = 'Lỗi khi tìm kiếm quy tắc tích hợp liên quan';
				|ru = 'Ошибка при поиске связанных правил интеграции';
				|en = 'An error occurred when looking for related integration rules'; fa = 'An error occurred when looking for related integration rules';
				|it = 'Errore durante la ricerca di regole di integrazione collegate';
				|pl = 'Błąd podczas wyszukiwania powiązanych reguły integracji';
				|tr = 'İlgili entegrasyon kuralları aranırken hata'"),
			IntegrationWith1CDocumentManagement3.GetErrorDescription(ErrorInfo()));
		
	EndTry;
	
	Return Response;
	
EndFunction

// Creates an associated integration rule for the data loading rule in the UP TO.
//
// Parameters:
//   Message - XDTODataObject - an XDTO object of type DMILCreateRelatedIntegrationRuleExistenceRequest.
//
// Returns:
//   XDTODataObject - an XDTO object of type DMOK or DMError.
//
Function CreateRelatedIntegrationRule(Message) Export
	
	Try
		
		Response = IntegrationWith1CDocumentManagement3.CreateBIDObject("DMILOK");
		
		RuleObject_ = CreateItem();
		RuleObject_.Fill(Undefined);
		
		RuleObject_.DMDataLoadingRule = Message.relatedDataLoadingRule;
		RuleObject_.DocumentKindDM = Message.documentTypeDM;
		RuleObject_.DocumentKindDMID = Message.documentTypeDMID;
		RuleObject_.ObjectTypeDM = Message.objectTypeDM;
		RuleObject_.ObjectPresentationDM = Message.objectNameDM;
		
		RuleObject_.ObjectTypeIS = Message.objectTypeIS;
		RuleObject_.ObjectPresentationIS = Metadata.FindByFullName(RuleObject_.ObjectTypeIS).Presentation();
		
		If IntegrationWith1CDocumentManagement3.IsDocumentBefore3(RuleObject_.ObjectTypeDM)
				And ValueIsFilled(RuleObject_.DocumentKindDMID) Then
			NewRow = RuleObject_.KeyAttributesDM.Add();
			NewRow.Name = "documentType";
			NewRow.AttributeValue = RuleObject_.DocumentKindDM;
			NewRow.AttributeValueID = RuleObject_.DocumentKindDMID;
			NewRow.AttributeValueType = "DMDocumentType";
		EndIf;
		
		RuleObject_.Write();
		
	Except
		
		Response = IntegrationWith1CDocumentManagement3.DescriptionOfXDTOError(
			NStr("vi = 'Lỗi khi tạo quy tắc tích hợp';
				|ru = 'Ошибка при создании правила интеграции';
				|en = 'An error occurred when creating an integration rule'; fa = 'An error occurred when creating an integration rule';
				|it = 'Errore durante la creazione delle regole di integrazione';
				|pl = 'Błąd podczas utworzenia reguły integracji';
				|tr = 'Entegrasyon kuralları oluşturulurken hata'"),
			IntegrationWith1CDocumentManagement3.GetErrorDescription(ErrorInfo()));
		
	EndTry;
	
	Return Response;
	
EndFunction

// Returns the structure of the table of Attributes of the object BEFORE.
//
// Returns:
//   ValueTable:
//     * Name - String
//     * Presentation - String
//     * Type - ValueList of String
//     * AdditionalAttribute5 - Boolean
//     * AdditionalAttribute5ID - String
//     * AdditionalAttribute5Type - String
//     * Mandatory - Boolean
//     * ThisIsTable - Boolean
//     * Table - String
//     * TableForSorting - String
//     * NameOfAttributeOfVDO - String
//     * ThisIsMainAttribute - Boolean
//
Function StructureOfTableOfAttributesTO() Export
	
	Attributes = New ValueTable;
	Attributes.Columns.Add("Name", New TypeDescription("String"));
	Attributes.Columns.Add("Presentation", New TypeDescription("String"));
	Attributes.Columns.Add("Type", New TypeDescription("ValueList"));
	Attributes.Columns.Add("AdditionalAttribute5", New TypeDescription("Boolean"));
	Attributes.Columns.Add("AdditionalAttribute5ID", New TypeDescription("String"));
	Attributes.Columns.Add("AdditionalAttribute5Type", New TypeDescription("String"));
	Attributes.Columns.Add("Mandatory", New TypeDescription("Boolean"));
	Attributes.Columns.Add("ThisIsTable", New TypeDescription("Boolean"));
	Attributes.Columns.Add("Table", New TypeDescription("String"));
	Attributes.Columns.Add("TableForSorting", New TypeDescription("String"));
	Attributes.Columns.Add("NameOfAttributeOfVDO", New TypeDescription("String"));
	Attributes.Columns.Add("ThisIsMainAttribute", New TypeDescription("Boolean"));
	
	Return Attributes;
	
EndFunction

#EndRegion

#Region Private

#Region FillingInIPObjects

// Returns the data of the IP object Attributes.
//
// Parameters:
//   ObjectAttributesIS - See IntegrationWith1CDocumentManagementCore.ObjectAttributesIS
//   AttributeNameObjectIS - String - name of the IP object Attribute to be filled in.
//   ObjectTableNameIS - String - name of the IP object table to be filled in.
//   ObjectToFillInIS - Arbitrary - the IP object being filled in. Required to generate a message in case
//     of an error.
//
// Returns:
//   ValueTableRow - table row from the method
//     Integration1sdocumentobase functionality.The details of the objectis.
//
Function AttributeData(ObjectAttributesIS, AttributeNameObjectIS, ObjectTableNameIS, ObjectToFillInIS)
	
	LineAttributeData = ObjectAttributesIS.FindRows(
		New Structure("Name, Table", AttributeNameObjectIS, ObjectTableNameIS));
	If LineAttributeData.Count() = 1 Then
		AttributeData = LineAttributeData[0];
	Else
		If ObjectTableNameIS = "" Then
			Raise StrTemplate(
				NStr("vi = 'Trong metadata đối tượng ""%1"" không thể tìm thấy mục tin có tên ""%2""';
					|ru = 'В метаданных объекта ""%1"" не удалось найти реквизит с именем ""%2""';
					|en = 'Cannot find an attribute with the ""%2"" name in the ""%1"" object metadata'; fa = 'Cannot find an attribute with the ""%2"" name in the ""%1"" object metadata';
					|it = 'В метаданных объекта ""%1"" не удалось найти реквизит с именем ""%2""';
					|pl = 'W metadanych obiektu ""%1"" nie udało się znaleźć atrybutu o nazwie ""%2""';
					|tr = '""%1"" nesne meta verilerinde ""%2"" adı ile öznitelik bulunamadı'"),
				ObjectToFillInIS,
				AttributeNameObjectIS);
		Else
			Raise StrTemplate(
				NStr("vi = 'Trong metadata đối tượng ""%1"" không thể tìm thấy mục tin của bảng ""%2"" có tên ""%3""';
					|ru = 'В метаданных объекта ""%1"" не удалось найти реквизит таблицы ""%2"" с именем ""%3""';
					|en = 'Cannot find the ""%2"" table attribute with the ""%3"" name in the ""%1"" object metadata'; fa = 'Cannot find the ""%2"" table attribute with the ""%3"" name in the ""%1"" object metadata';
					|it = 'В метаданных объекта ""%1"" не удалось найти реквизит таблицы ""%2"" с именем ""%3""';
					|pl = 'W metadanych obiektu ""%1"" nie udało się znaleźć atrybutu tabeli ""%2"" o nazwie ""%3""';
					|tr = '""%1"" nesne meta verilerinde ""%3"" adı ile ""%2"" tablo özniteliği bulunamadı'"),
				ObjectToFillInIS,
				ObjectTableNameIS,
				AttributeNameObjectIS);
		EndIf;
	EndIf;
	
	Return AttributeData;
	
EndFunction

// Reads the property value from the XDTO object. By default, the value is obtained by the name of the property.
// The exception is obtaining the status of the document and the parties to the request for payment.
//
// Parameters:
//   XDTODataObject - XDTODataObject - the object BEFORE, the source of the fill data.
//   ValueToFillIn - See IntegrationWith1CDocumentManagementCore.ValueForFillingInAttributesOfIPObject
//   IsRequestForPayment - Boolean - The document BEFORE is a payment request.
//
Procedure FillInPropertyValueFromAttributeOfXDTOObject(XDTODataObject, ValueToFillIn, IsRequestForPayment)
	
	If IsRequestForPayment And ValueToFillIn.PropertyName = "recipient" Then
		ValueToFillIn.PropertyValue = ApplicationPartyForXDTOPayment(
			XDTODataObject,
			"recipient",
			ValueToFillIn.ObjectTypeDM);
		
	ElsIf StrFind(ValueToFillIn.PropertyName, "status_") = 1 Then
		ActionKindID = StrReplace(Right(ValueToFillIn.PropertyName, 36), "_", "-");
		If IntegrationWith1CDocumentManagementCore.PropertySet(
				XDTODataObject, "statusByActionTypeRows") Then
			For Each RowStatus In XDTODataObject.statusByActionTypeRows.rows Do
				If RowStatus.actionType.objectID.ID = ActionKindID Then
					ValueToFillIn.PropertyValue = RowStatus.status;
					ValueToFillIn.ObjectTypeDM = "DMDocumentStatus";
					If IntegrationWith1CDocumentManagementCore.PropertySet(
							RowStatus, "statusPresentation") Then
						ValueToFillIn.PresentationForSearching = RowStatus.statusPresentation;
					EndIf;
					Break;
				EndIf;
			EndDo;
		EndIf;
		
	Else
		ValueToFillIn.PropertyValue = XDTODataObject[ValueToFillIn.PropertyName];
		ValueToFillIn.ObjectTypeDM = XDTODataObject.Type().Properties.Get(ValueToFillIn.PropertyName).Type.Name;
		
	EndIf;
	
EndProcedure

// Fills in the Attributes of the IP object from the value of the XDTO object property.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   Attribute - Arbitrary - The Attribute of the IP object to be filled in.
//   ValueToFillIn - See IntegrationWith1CDocumentManagementCore.ValueForFillingInAttributesOfIPObject
//   PropsRule - ValueTableRow - rule for filling in Attributes. The TS line of the rule for filling in the requesitovis.
//   AttributeData - ValueTableRow - table row from the method
//     Integration1sdocumentobase functionality.The details of the objectis.
//   ObjectToFillInIS - Arbitrary - the IS object to be filled in.
//   LineNumber - Number - It is passed when a certain row in the object table is filled in.
//
Procedure FillInAttributesFromPropertyValue(Proxy, Attribute, ValueToFillIn, PropsRule,
		AttributeData, ObjectToFillInIS, LineNumber = Undefined)
	
	Context = IntegrationWith1CDocumentManagementCore.ContextForFillingInAttributesOfIPObject();
	Context.ObjectToFillInIS = ObjectToFillInIS;
	Context.AttributeNameObjectIS = PropsRule.AttributeNameObjectIS;
	Context.IsAdditionalAttributeIS = PropsRule.IsAdditionalAttributeIS;
	Context.AdditionalAttributeIS = PropsRule.AdditionalAttributeIS;
	
	If PropsRule.IsAdditionalAttributeIS Then
		DescriptionOfPropsTypesIS = Common.ObjectAttributeValue(
			PropsRule.AdditionalAttributeIS,
			"ValueType");
	Else
		DescriptionOfPropsTypesIS = AttributeData.Type;
	EndIf;
	ObjectAttributeTypeIS = IntegrationWith1CDocumentManagementCore.SuitableType(
		DescriptionOfPropsTypesIS.Types(),
		ValueToFillIn.PropertyValue,
		TypeOf(Attribute));
	
	For Each RelationshipOfSelectionParameters In AttributeData.ChoiceParameterLinks Do
		SplitPath = StrSplit(RelationshipOfSelectionParameters.DataPath, ".");
		If SplitPath.Count() = 2 And SplitPath[0] = AttributeData.Table Then
			While ObjectToFillInIS[AttributeData.Table].Count() - 1 < LineNumber Do
				ObjectToFillInIS[AttributeData.Table].Add();
			EndDo;
			String = ObjectToFillInIS[AttributeData.Table][LineNumber];
			Context.ChoiceParameters[RelationshipOfSelectionParameters.Name] = String[SplitPath[1]];
		ElsIf SplitPath.Count() = 1 Then
			Context.ChoiceParameters[RelationshipOfSelectionParameters.Name] = ObjectToFillInIS[SplitPath[0]];
		Else
			// Other data path options are not supported.
			Continue;
		EndIf;
	EndDo;
	ValueToFillIn.Owner = Context.ChoiceParameters["Filter.Owner"];
	
	If PropsRule.IsAdditionalAttributeIS
			And (ObjectAttributeTypeIS = Type("CatalogRef.ObjectsPropertiesValues")
				Or ObjectAttributeTypeIS = Type("CatalogRef.ObjectPropertyValueHierarchy")) Then
		ValueToFillIn.Owner = PropsRule.AdditionalAttributeIS;
	EndIf;
	
	If IntegrationWith1CDocumentManagementCore.ThisIsObjectValue(
			Proxy, ValueToFillIn.PropertyValue) Then
		
		ValueToFillIn.NameToSearch = ValueToFillIn.PropertyValue.name;
		ValueToFillIn.ObjectIDDM = ValueToFillIn.PropertyValue.objectID.ID;
		ValueToFillIn.ObjectTypeDM = ValueToFillIn.PropertyValue.objectID.type;
		ValueToFillIn.PresentationForSearching = ValueToFillIn.PropertyValue.objectID.presentation;
		ValueToFillIn.ExternalObject = ValueToFillIn.PropertyValue.externalObject;
		
	ElsIf TypeOf(ValueToFillIn.PropertyValue) = Type("String") Then
		
		If IsBlankString(ValueToFillIn.NameToSearch) Then
			ValueToFillIn.NameToSearch = ValueToFillIn.PropertyValue;
		EndIf;
		If IsBlankString(ValueToFillIn.PresentationForSearching) Then
			ValueToFillIn.PresentationForSearching = ValueToFillIn.PropertyValue;
		EndIf;
		
	ElsIf TypeOf(ValueToFillIn.PropertyValue) = Type("Number")
			Or TypeOf(ValueToFillIn.PropertyValue) = Type("Date") Then
		
		If IsBlankString(ValueToFillIn.NameToSearch) Then
			ValueToFillIn.NameToSearch = String(ValueToFillIn.PropertyValue);
		EndIf;
		
	EndIf;
	
	Attribute = IntegrationWith1CDocumentManagementCore.ValueOfAttributeOfIPObjectByValueToFillIn(
		ObjectAttributeTypeIS,
		ValueToFillIn,
		Context);
	
EndProcedure

// Fills in the Attributes according to the filling rule specified in the integration rules.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   Attribute - Arbitrary - The Attribute of the IP object to be filled in.
//   PropsRule - ValueTableRow - rule for filling in Attributes. The TS line of the rule for filling in the requesitovis.
//   AttributeData - ValueTableRow - table row from the method
//     Integration1sdocumentobase functionality.The details of the objectis.
//   ContextOfFillingInRule - See ContextOfFillingInRule
//   LineNumber - Number - It is passed when a certain row in the object table is filled in.
//   CurrentRow - Arbitrary - It is passed as a context for an expression in the embedded language, to fill
//     in the Attributes of a row in the table part.
//
Procedure FillInAttributesAccordingToRule(Proxy, Attribute, PropsRule, AttributeData, ContextOfFillingInRule,
		LineNumber = Undefined, CurrentRow = Undefined)
	
	XDTODataObject = ContextOfFillingInRule.XDTODataObject; // XDTODataObject
	ValueToFillIn = IntegrationWith1CDocumentManagementCore.ValueForFillingInAttributesOfIPObject();
	ValueToFillIn.ObjectTypeXDTO = XDTODataObject.Type().Name;
	ValueToFillIn.PropertyName = PropsRule.AttributeNameObjectDM;
	
	If PropsRule.Variant = OptionValue_() Then
		// From the specified value.
		Attribute = PropsRule.AttributeValueIS;
		
	ElsIf PropsRule.Variant = OptionProps() Then
		// From the object's props TO.
		
		If Not PropsRule.IsAdditionalAttributeDM Then
			
			If LineNumber = Undefined Then
				// Filling in the Attributes of the object BEFORE.
				FillInPropertyValueFromAttributeOfXDTOObject(
					XDTODataObject,
					ValueToFillIn,
					ContextOfFillingInRule.IsRequestForPayment);
				
			Else
				// Fill in the Attributes of the tabular part of the object BEFORE.
				SplitRow = StrSplit(PropsRule.AttributeNameObjectDM, ".", False);
				
				If SplitRow.Count() = 1 Then // "property"
					FillInPropertyValueFromAttributeOfXDTOObject(
						XDTODataObject,
						ValueToFillIn,
						ContextOfFillingInRule.IsRequestForPayment);
					
				ElsIf SplitRow.Count() = 2 Then // "the list.property"
					XDTOList = XDTODataObject[SplitRow[0]];
					ValueToFillIn.PropertyValue = XDTOList[LineNumber][SplitRow[1]];
					
				ElsIf SplitRow.Count() = 3 Then // "the list.list.property"
					XDTOList = XDTODataObject[SplitRow[0]][SplitRow[1]];
					ValueToFillIn.PropertyValue = XDTOList[LineNumber][SplitRow[2]];
					
				Else
					Raise StrTemplate(
						NStr("vi = 'Trong quy tắc tích hợp đã chỉ ra tên mục tin nguồn dữ liệu điền không hợp lệ: %1';
							|ru = 'В правилах интеграции указано недопустимое имя реквизита-источника данных заполнения: %1';
							|en = 'Integration rules specify an invalid data source attribute name: %1'; fa = 'Integration rules specify an invalid data source attribute name: %1';
							|it = 'Nelle regole di integrazione è indicato un nome non disponibile dell''attributo-fonte dei dati di compilazione: %1';
							|pl = 'W regułach integracji podano niedopuszczalną nazwę atrybutu-źródła danych wypełnienia: %1';
							|tr = 'Entegrasyon kurallarında, doldurma verilerinin öznitelik kaynağının geçersiz adı belirtildi: %1'"),
						PropsRule.AttributeNameObjectDM);
				EndIf;
				
			EndIf;
			
		Else
			// This is an additional Attribute TO.
			
			For Each String In XDTODataObject.additionalProperties Do
				If String.objectID.ID = PropsRule.AdditionalAttributeDMID
						And String.objectID.type = PropsRule.AdditionalAttributeDMType Then
					If String.propertySimpleValue <> Undefined Then
						ValueToFillIn.PropertyValue = String.propertySimpleValue;
					ElsIf String.propertyObjectValue <> Undefined Then
						ValueToFillIn.PropertyValue = String.propertyObjectValue;
					EndIf;
					Break;
				EndIf;
			EndDo;
			
		EndIf;
		
		FillInAttributesFromPropertyValue(
			Proxy,
			Attribute,
			ValueToFillIn,
			PropsRule,
			AttributeData,
			ContextOfFillingInRule.ObjectToFillInIS,
			LineNumber);
		
	// From an expression in the embedded language.
	ElsIf PropsRule.Variant = VariantExpression() Then
		
		If PropsRule.PlaceWhereExpressionIsExecuted =
				Enums.PlacesWhereExpressionsOnBuiltInLanguageAreExecuted.OnDocumentManagementSide Then
			
			// The expression has already been executed on the side BEFORE, its result is in the incoming data.
			If LineNumber = Undefined Then
				// Filling in the Attributes of the object BEFORE.
				XDTODataValue = ValueFromIncomingData(
					XDTODataObject.expressionResultsForAttributes, PropsRule.id);
			Else
				// Fill in the Attributes of the tabular part of the object BEFORE.
				XDTOTable = ValueFromIncomingData(
					XDTODataObject.expressionResultsForTabularSections, PropsRule.id);
				If XDTOTable = Undefined Then
					XDTODataValue = Undefined;
				Else
					XDTODataValue = XDTOTable.rows[LineNumber].attributes[0];
				EndIf;
			EndIf;
			
			If XDTODataValue = Undefined Then
				Return;
				
			ElsIf IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataValue, "error") Then
				Raise XDTODataValue.error;
				
			ElsIf IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataValue, "value") Then
				ValueToFillIn.PropertyValue = XDTODataValue.value;
				FillInAttributesFromPropertyValue(
					Proxy,
					Attribute,
					ValueToFillIn,
					PropsRule,
					AttributeData,
					ContextOfFillingInRule.ObjectToFillInIS,
					LineNumber);
				
			EndIf;
			
		ElsIf PropsRule.PlaceWhereExpressionIsExecuted =
				Enums.PlacesWhereExpressionsOnBuiltInLanguageAreExecuted.OnIntegratedSystemSide Then
			
			// It is required to execute the expression in the embedded language.
			ResultOfExpression = IntegrationWith1CDocumentManagement3.ResultOfExpressionInEmbeddedLanguage(
				PropsRule.ComputedExpression,
				XDTODataObject,
				ContextOfFillingInRule.ObjectToFillInIS,
				CurrentRow);
			If ResultOfExpression <> Undefined Then
				If PropsRule.IsAdditionalAttributeIS Then
					DescriptionOfPropsTypesIS = Common.ObjectAttributeValue(
						PropsRule.AdditionalAttributeIS,
						"ValueType");
				Else
					DescriptionOfPropsTypesIS = AttributeData.Type;
				EndIf;
				FillInAttributesForResultOfExpressionInEmbeddedLanguage(
					Attribute,
					ResultOfExpression,
					DescriptionOfPropsTypesIS,
					PropsRule,
					ContextOfFillingInRule.ObjectToFillInIS);
			EndIf;
			
		Else
			Raise NStr("vi = 'Chưa đặt nơi thực hiện biểu thức bằng ngôn ngữ hệ thống.';
						|ru = 'Не задано место выполнения выражения на встроенном языке.';
						|en = 'Location of executing the expression in 1C:Enterprise language is not specified.'; fa = 'Location of executing the expression in 1C:Enterprise language is not specified.';
						|it = 'Luogo di esecuzione dell''espressione in linguaggio integrato non impostato.';
						|pl = 'Nie zadano miejsca wykonania wyrażenia w języku wbudowanym.';
						|tr = 'Yerleşik dildeki ifadenin yürütüldüğü yer belirtilmedi.'");
			
		EndIf;
		
	EndIf;
	
EndProcedure

// In the case when an expression in the built-in language returns the name or synonym
// of the enumeration value, the procedure fills in the object's props with the corresponding value.
// If the type of the props is not an enumeration, the props will be filled in with the transmitted result.
//
// Parameters:
//   Attribute - Arbitrary - The Attribute of the IP object to be filled in.
//   ResultOfExpression - Arbitrary - the result of executing an expression in the embedded language.
//   DescriptionOfPropsTypesIS - TypeDescription - description of the types of Attributes to fill in.
//   PropsRule - ValueTableRow - rule for filling in Attributes. The TS line of the rule for filling in the requesitovis.
//   ObjectToFillInIS - Arbitrary - the IS object to be filled in.
//
Procedure FillInAttributesForResultOfExpressionInEmbeddedLanguage(Attribute, ResultOfExpression,
		DescriptionOfPropsTypesIS, PropsRule, ObjectToFillInIS)
	
	ResultType = TypeOf(ResultOfExpression);
	TypeOfEnumeration = Undefined;
	ResultTypeCorrespondsToTypeOfIPAttribute = False;
	For Each ObjectAttributeTypeIS In DescriptionOfPropsTypesIS.Types() Do
		If ObjectAttributeTypeIS = ResultType Then
			ResultTypeCorrespondsToTypeOfIPAttribute = True;
		EndIf;
		If Common.IsReference(ObjectAttributeTypeIS)
				And Common.IsEnum(Metadata.FindByType(ObjectAttributeTypeIS)) Then
			TypeOfEnumeration = ObjectAttributeTypeIS;
		EndIf;
	EndDo;
	
	If ResultType = Type("String") And Not IsBlankString(ResultOfExpression) And TypeOfEnumeration <> Undefined Then
		ValueToFillIn = IntegrationWith1CDocumentManagementCore.ValueForFillingInAttributesOfIPObject();
		ValueToFillIn.PropertyValue = ResultOfExpression;
		ValueToFillIn.NameToSearch = ResultOfExpression;
		Context = IntegrationWith1CDocumentManagementCore.ContextForFillingInAttributesOfIPObject();
		Context.ObjectToFillInIS = ObjectToFillInIS;
		Context.AttributeNameObjectIS = PropsRule.AttributeNameObjectIS;
		Context.IsAdditionalAttributeIS = PropsRule.IsAdditionalAttributeIS;
		Context.AdditionalAttributeIS = PropsRule.AdditionalAttributeIS;
		Attribute = IntegrationWith1CDocumentManagementCore.ValueOfAttributeOfIPObjectByValueToFillIn(
			TypeOfEnumeration,
			ValueToFillIn,
			Context);
	Else
		If ResultTypeCorrespondsToTypeOfIPAttribute Then
			Attribute = ResultOfExpression;
		Else
			Attribute = Undefined;
			ErrorText = StrTemplate(
				NStr("vi = 'Kiểu kết quả biểu thức bằng ngôn ngữ hệ thống không tương ứng với kiểu mục tin.
					|Kiểu mục tin: %1.
					|Kiểu kết quả biểu thức: %2.
					|Kết quả biểu thức bằng ngôn ngữ hệ thống:
					|%3';
					|ru = 'Тип результата выражения на встроенном языке не соответствует типу реквизита.
					|Тип реквизита: %1.
					|Тип результата выражения: %2.
					|Результат выражения на встроенном языке:
					|%3';
					|en = 'The expression result type in 1C:Enterprise language does not match the attribute type.
					|Attribute type: %1.
					|Expression result type: %2.
					|Expression result in 1C:Enterprise language:
					|%3'; fa = 'The expression result type in 1C:Enterprise language does not match the attribute type.
					|Attribute type: %1.
					|Expression result type: %2.
					|Expression result in 1C:Enterprise language:
					|%3';
					|it = 'Тип результата выражения на встроенном языке не соответствует типу реквизита.
					|Тип реквизита: %1.
					|Тип результата выражения: %2.
					|Результат выражения на встроенном языке:
					|%3';
					|pl = 'The expression result type in 1C:Enterprise language does not match the attribute type.
					|Attribute type: %1.
					|Expression result type: %2.
					|Expression result in 1C:Enterprise language:
					|%3';
					|tr = 'Yerleşik dildeki ifadenin sonuç türü öznitelik türü ile eşleşmiyor. 
					|Öznitelik türü: %1.
					| İfade sonuç türü: %2.
					| Katıştırılmış dildeki ifadenin sonucu: 
					|%3'"),
				Common.TypePresentationString(ObjectAttributeTypeIS),
				Common.TypePresentationString(ResultType),
				String(ResultOfExpression));
			IntegrationWith1CDocumentManagementCore.WriteError(ErrorText,, PropsRule.Ref);
		EndIf;
	EndIf;
	
EndProcedure

// Fills in the rows of the table according to the integration rule.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   Table - TabularSection - the tabular part of the IP object that needs to be filled in.
//   RulesForFillingInLines - Array of ValueTableRow - rule for filling in table rows.
//   RowsCount - Number - the total number of rows in the table.
//   ContextOfFillingInRule - See ContextOfFillingInRule
//   SourceTable2 - XDTOList - a table from the BEFORE object that is the source of the filling data.
//                    - Undefined - if the rows are filled not from the table from the object BEFORE.
//
Procedure FillInRowsOfTableAccordingToRule(Proxy, Table, RulesForFillingInLines, RowsCount,
		ContextOfFillingInRule, SourceTable2)
	
	For LineNumber = 0 To RowsCount - 1 Do
		NewRow = Table.Add();
		For Each PropsRule In RulesForFillingInLines Do
			AttributeData = AttributeData(
				ContextOfFillingInRule.ObjectAttributesIS,
				PropsRule.AttributeNameObjectIS,
				PropsRule.Table,
				ContextOfFillingInRule.ObjectToFillInIS);
			FillInAttributesAccordingToRule(
				Proxy,
				NewRow[PropsRule.AttributeNameObjectIS],
				PropsRule,
				AttributeData,
				ContextOfFillingInRule,
				LineNumber,
				?(SourceTable2 = Undefined, Undefined, SourceTable2[LineNumber]));
		EndDo;
	EndDo;
	
EndProcedure

// Fills in the table according to the filling rule specified in the integration rules.
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   Table - TabularSection - the tabular part of the IP object that needs to be filled in.
//   TableRule - ValueTableRow - rule for filling in the table. The TS line of the rule for filling in the requesitovis.
//   ContextOfFillingInRule - See ContextOfFillingInRule
//
Procedure FillInTableAccordingToRule(Proxy, Table, TableRule, ContextOfFillingInRule)
	
	Table.Clear();
	
	XDTODataObject = ContextOfFillingInRule.XDTODataObject;
	ObjectToFillInIS = ContextOfFillingInRule.ObjectToFillInIS;
	ObjectAttributesIS = ContextOfFillingInRule.ObjectAttributesIS; // See IntegrationWith1CDocumentManagementCore.ObjectAttributesIS
	AttributeFillingRulesIS = ContextOfFillingInRule.AttributeFillingRulesIS; // ValueTable
	
	If TableRule.Variant = VariantExpression() Then
		
		If TableRule.PlaceWhereExpressionIsExecuted =
				Enums.PlacesWhereExpressionsOnBuiltInLanguageAreExecuted.OnDocumentManagementSide Then
			// The expression has already been executed on the side BEFORE, its result is in the incoming data.
			XDTOTable = ValueFromIncomingData(
				XDTODataObject.expressionResultsForTabularSections,
				TableRule.id);
			If XDTOTable <> Undefined Then
				For LineNumber = 0 To XDTOTable.rows.Count() - 1 Do
					XDTORow = XDTOTable.rows[LineNumber];
					NewRow = Table.Add();
					
					FilterTableAttributes = New Structure("Table", TableRule.AttributeNameObjectIS);
					For Each Attribute In ObjectAttributesIS.FindRows(FilterTableAttributes) Do
						XDTODataValue = ValueFromIncomingData(XDTORow.attributes, Attribute.Name);
						If IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataValue, "error") Then
							Raise XDTODataValue.error;
							
						ElsIf IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataValue, "value") Then
							ValueToFillIn =
								IntegrationWith1CDocumentManagementCore.ValueForFillingInAttributesOfIPObject();
							ValueToFillIn.ObjectTypeXDTO = XDTODataObject.Type().Name;
							ValueToFillIn.PropertyName = TableRule.AttributeNameObjectDM;
							ValueToFillIn.PropertyValue = XDTODataValue.value;
							FillInAttributesFromPropertyValue(
								Proxy,
								NewRow[Attribute.Name],
								ValueToFillIn,
								TableRule,
								AttributeData(
									ObjectAttributesIS,
									XDTODataValue.name,
									TableRule.AttributeNameObjectIS,
									ObjectToFillInIS),
								ObjectToFillInIS,
								LineNumber);
							
						EndIf;
					EndDo;
				EndDo;
			EndIf;
			
		ElsIf TableRule.PlaceWhereExpressionIsExecuted =
				Enums.PlacesWhereExpressionsOnBuiltInLanguageAreExecuted.OnIntegratedSystemSide Then
			// It is required to execute the expression in the embedded language.
			ResultOfExpression = IntegrationWith1CDocumentManagement3.ResultOfExpressionInEmbeddedLanguage(
				TableRule.ComputedExpression,
				XDTODataObject,
				ObjectToFillInIS); // ValueTable
			TableColumns1 = Table.Unload().Columns; // ValueTableColumnCollection
			For Each String In ResultOfExpression Do
				NewRow = Table.Add();
				For Each Column In ResultOfExpression.Columns Do
					If ValueIsFilled(String[Column.Name]) And Column.Name <> "LineNumber" Then
						If TableColumns1.Find(Column.Name) = Undefined Then
							Raise StrTemplate(NStr("vi = 'Lỗi điền bảng %1từ biểu mẫu bằng ngôn ngữ hệ thống.
									|Trong bảng không có cột %2 trong khi cột này được kết quả biểu thức trả về.';
									|ru = 'Ошибка заполнения таблицы %1 из выражения на встроенном языке.
									|В таблице отсутствует колонка %2, которую возвращает результат выражения.';
									|en = 'Error filling in the %1 table from an expression in 1C:Enterprise language.
									|The table does not have the %2 column, which returns the expression result.'; fa = 'Error filling in the %1 table from an expression in 1C:Enterprise language.
									|The table does not have the %2 column, which returns the expression result.';
									|it = 'Error filling in the %1 table from an expression in 1C:Enterprise language.
									|The table does not have the %2 column, which returns the expression result.';
									|pl = 'Error filling in the %1 table from an expression in 1C:Enterprise language.
									|The table does not have the %2 column, which returns the expression result.';
									|tr = 'Gömülü dildeki ifadeden %1 tablosu doldurulurken hata oluştu.
									|Tabloda ifadenin sonucunu döndüren %2 sütunu eksik.'"),
								TableRule.AttributeNameObjectIS,
								Column.Name);
						EndIf;
						FillInAttributesForResultOfExpressionInEmbeddedLanguage(
							NewRow[Column.Name],
							String[Column.Name],
							TableColumns1.Find(Column.Name).ValueType,
							TableRule,
							ObjectToFillInIS);
					EndIf;
				EndDo;
			EndDo;
			
		Else
			Raise NStr("vi = 'Chưa đặt nơi thực hiện biểu thức bằng ngôn ngữ hệ thống.';
						|ru = 'Не задано место выполнения выражения на встроенном языке.';
						|en = 'Location of executing the expression in 1C:Enterprise language is not specified.'; fa = 'Location of executing the expression in 1C:Enterprise language is not specified.';
						|it = 'Luogo di esecuzione dell''espressione in linguaggio integrato non impostato.';
						|pl = 'Nie zadano miejsca wykonania wyrażenia w języku wbudowanym.';
						|tr = 'Yerleşik dildeki ifadenin yürütüldüğü yer belirtilmedi.'");
			
		EndIf;
		
	Else
		
		RulesForFillingInLines = New Array;
		
		FilterTableAttributes = New Structure("Table", TableRule.AttributeNameObjectIS);
		For Each Attribute In ObjectAttributesIS.FindRows(FilterTableAttributes) Do
			// String filling rules should be sorted in such a way that
			// objects that have an owner are loaded after their owner is loaded.
			// For example, the unit of measurement with the owner Product should
			// be loaded after the Product itself is loaded.
			FilterParameters = New Structure;
			FilterParameters.Insert("AttributeNameObjectIS", Attribute.Name);
			FilterParameters.Insert("ThisIsTable", False);
			FilterParameters.Insert("Table", TableRule.AttributeNameObjectIS);
			
			FoundRulesForBankingDetails = AttributeFillingRulesIS.FindRows(FilterParameters);
			If FoundRulesForBankingDetails.Count() = 0 Then
				Continue;
			EndIf;
			
			RulesForFillingInLines.Add(FoundRulesForBankingDetails[0]);
		EndDo;
		
		XDTOList = Undefined;
		If TableRule.Variant = OptionProps() Then
			SplitRow = StrSplit(TableRule.AttributeNameObjectDM, ".", False);
			If SplitRow.Count() = 1 Then
				XDTOList = XDTODataObject[SplitRow[0]];
			Else
				XDTOList = XDTODataObject[SplitRow[0]][SplitRow[1]];
			EndIf;
			RowsCount = XDTOList.Count();
			
		ElsIf TableRule.Variant = TablePropsOption() Then
			RowsCount = 1;
			
		Else
			Return;
			
		EndIf;
		
		FillInRowsOfTableAccordingToRule(
			Proxy,
			Table,
			RulesForFillingInLines,
			RowsCount,
			ContextOfFillingInRule,
			XDTOList);
		
	EndIf;
	
EndProcedure

// Gets the value from the incoming data.
//
// Parameters:
//   List - XDTOList
//   ValueID - String
//
// Returns:
//   XDTODataObject
//   Undefined
//
Function ValueFromIncomingData(List, ValueID)
	
	For Each Item In List Do
		If Item.name = ValueID Then
			Return Item;
		EndIf;
	EndDo;
	
EndFunction

// Constructor of the structure describing the context for filling in the IP object according to the integration rule.
//
// Parameters:
//   ObjectToFillInIS - Arbitrary - the IS object to be filled in.
//   XDTODataObject - XDTODataObject - the object BEFORE, the source of the fill data.
//   IntegrationRule - CatalogRef.RulesForIntegrationWith1CDocumentManagement3 - integration rule for
//     filling in the IP object.
//   FullNameOfIPObject - String - full name of the IP object to be filled in.
//
// Returns:
//   Structure:
//     * IntegrationRule - CatalogRef.RulesForIntegrationWith1CDocumentManagement3 - integration rule for
//         filling in the IP object.
//     * ObjectToFillInIS - Arbitrary - the IS object to be filled in.
//     * ObjectAttributesIS - See IntegrationWith1CDocumentManagementCore.ObjectAttributesIS
//     * XDTODataObject - XDTODataObject - the object BEFORE, the source of the fill data.
//     * IsRequestForPayment - Boolean - The document BEFORE is a payment request.
//     * AttributeFillingRulesIS - ValueTable - table rules rules for filling out requesitovis.
//
Function ContextOfFillingInRule(ObjectToFillInIS, XDTODataObject, IntegrationRule, FullNameOfIPObject)
	
	Context = New Structure;
	Context.Insert("ObjectToFillInIS", ObjectToFillInIS);
	Context.Insert("XDTODataObject", XDTODataObject);
	Context.Insert("IntegrationRule", IntegrationRule);
	
	Context.Insert("IsRequestForPayment", False);
	If IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "documentType")
			And IntegrationWith1CDocumentManagementCore.PropertySet(
				XDTODataObject.documentType, "isAPaymentRequest") Then
		Context.IsRequestForPayment = XDTODataObject.documentType.isAPaymentRequest;
	EndIf;
	
	ObjectAttributesIS = IntegrationWith1CDocumentManagementCore.ObjectAttributesIS(FullNameOfIPObject);
	Context.Insert("ObjectAttributesIS", ObjectAttributesIS);
	
	AttributeFillingRulesIS = Common.ObjectAttributeValue(
		IntegrationRule,
		"AttributeFillingRulesIS").Unload();
	Context.Insert("AttributeFillingRulesIS", AttributeFillingRulesIS);
	
	Return Context;
	
EndFunction

// Receives the party of the request for payment by the predefined name of the party.
//
// Parameters:
//   XDTODataObject - XDTODataObject - the object BEFORE, the source of the fill data.
//   PredefinedPartyName - String - takes the values: "Payer" - payer, "Recipient" - recipient.
//   ObjectTypeDM - String - an implicitly returned value, the name of the object type BEFORE, which is a party.
//
Function ApplicationPartyForXDTOPayment(XDTODataObject, PredefinedPartyName, ObjectTypeDM)
	
	Result = Undefined;
	
	InstalledTSSide = IntegrationWith1CDocumentManagementCore.PropertySet(XDTODataObject, "partyRows");
	
	If InstalledTSSide Then
		For Each XDTOSide In XDTODataObject.partyRows.rows Do
			If IntegrationWith1CDocumentManagementCore.PropertySet(XDTOSide, "paymentRequestParty")
					And Lower(XDTOSide.paymentRequestParty) = Lower(PredefinedPartyName) Then
				Result = XDTOSide.party;
				ObjectTypeDM = XDTOSide.party.objectID.type;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

// Returns the Enumeration value.Options for the right to fill in the requirements.Expression in a built-in language.
//
Function VariantExpression()
	
	Return Enums.VariantsOfTheRulesForFillingInAttributes.ScriptExpression;
	
EndFunction

// Returns the Enumeration value.Options for the right to fill in the requirements.The specified value.
//
Function OptionValue_()
	
	Return Enums.VariantsOfTheRulesForFillingInAttributes.SpecifiedValue;
	
EndFunction

// Returns the Enumeration value.Options for the right to fill in the requirements.The object's props.
//
Function OptionProps()
	
	Return Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute;
	
EndFunction

// Returns the Enumeration value.Options for the right to fill in the requirements.The object's props.
//
Function TablePropsOption()
	
	Return Enums.VariantsOfTheRulesForFillingInAttributes.TableAttribute;
	
EndFunction

// Adds the HTML code for displaying the object's Attributes in the instruction.
//
// Parameters:
//   ArrayInstructions - Array of String - an array for accumulating the HTML code of the instruction.
//   AttributeStructure - Structure - structure containing information about Attributes:
//     * Type - ValueList of String
//   AttributeName - String - name of the prop.
//
Procedure PrintAttributeNameBEFORE(ArrayInstructions, AttributeStructure, AttributeName)
	
	If TypeOf(AttributeStructure.Type) = Type("ValueList")
				And AttributeStructure.Type.Count() > 0
				And Left(AttributeStructure.Type[0], 2) = "DM" Then
			ArrayInstructions.Add("<td><a href=""#");
			ArrayInstructions.Add(AttributeStructure.Type[0]);
			ArrayInstructions.Add(""">");
			ArrayInstructions.Add(AttributeName);
			ArrayInstructions.Add("</a></td>");
		Else
			ArrayInstructions.Add("<td>");
			ArrayInstructions.Add(AttributeName);
			ArrayInstructions.Add("</td>");
		EndIf;
	
EndProcedure

// Adds an example of an expression in the embedded language to the instruction.
//
// Parameters:
//   ArrayInstructions - Array of String - an array for accumulating the HTML code of the instruction.
//   SectionTitle - String - a brief description of the example.
//   ExampleExpression - String - the text of the expression in the embedded language.
//
Procedure OutputExampleExpression(ArrayInstructions, SectionTitle, ExampleExpression)
	
	If ArrayInstructions[ArrayInstructions.UBound()] <> "</details>" Then
		ArrayInstructions.Add("<p>");
	EndIf;
	
	AddCollapsibleGroup(ArrayInstructions, True);
	ArrayInstructions.Add("<summary class=""pointer""><u>");
	ArrayInstructions.Add(SectionTitle);
	ArrayInstructions.Add("</u></summary>");
	ArrayInstructions.Add("<blockquote><pre>");
	ArrayInstructions.Add(ExampleExpression);
	ArrayInstructions.Add("</pre></blockquote>");
	AddCollapsibleGroup(ArrayInstructions, False);
	
EndProcedure

// Adds a list of object Attributes to the instruction.
//
// Parameters:
//   ArrayInstructions - Array of String - an array for accumulating the HTML code of the instruction.
//   Parameters - See Catalogs.RulesForIntegrationWith1CDocumentManagement3.ParametersOfExpressionInEmbeddedLanguage
//   AttributeSet - See Catalogs.RulesForIntegrationWith1CDocumentManagement3.ObjectAttributesBefore
//                    - See IntegrationWith1CDocumentManagementCore.ObjectAttributesIS
//   OutputOfIPObjectAttributes - Boolean - True if the Attributes of the IP object are displayed, False if
//     the Attributes of the DO object are displayed.
//
Procedure DisplayTableOfAttributes(ArrayInstructions, Parameters, AttributeSet, OutputOfIPObjectAttributes = False)
	
	ArrayInstructions.Add("<table>");
	
	ArrayInstructions.Add("<tr><td>");
	ArrayInstructions.Add("<b>");
	ArrayInstructions.Add(NStr("vi = 'Tên mục tin';
								|ru = 'Имя реквизита';
								|en = 'Attribute name'; fa = 'نام ویژگی';
								|it = 'Nome del requisito';
								|pl = 'Nazwa atrybutu';
								|tr = 'Öznitelik adı'"));
	ArrayInstructions.Add("</b></td>");
	
	ArrayInstructions.Add("<td><b>");
	ArrayInstructions.Add(NStr("vi = 'Đồng nghĩa';
								|ru = 'Синоним';
								|en = 'Synonym'; fa = 'مترادف';
								|it = 'Sinonimo';
								|pl = 'Synonym';
								|tr = 'Eş anlamlı'"));
	ArrayInstructions.Add("</b></td>");
	ArrayInstructions.Add("</tr>");
	
	HeaderOfAdditionalBankingDetailsIsDisplayed = False;
	IDOfAdditionalBankingDetails = "00000000-0000-0000-0000-000000000000";
	IdOfApprovalAction = "status_00000000_0000_0000_0000_000000000000";
	ThereAreTables = False;
	
	For Each AttributeStructure In AttributeSet Do
		
		If ValueIsFilled(AttributeStructure.Table)
				Or (Parameters.ThisIsConditionOfApplicabilityWhenLoading And Not AttributeStructure.ThisIsMainAttribute) Then
			Continue;
		EndIf;
		
		If OutputOfIPObjectAttributes Then
			IsAddlAttribute = AttributeStructure.IsAdditionalAttributeIS;
		Else
			IsAddlAttribute = AttributeStructure.AdditionalAttribute5;
		EndIf;
		
		If IsAddlAttribute And Not HeaderOfAdditionalBankingDetailsIsDisplayed Then
			ArrayInstructions.Add("<tr><td>");
			ArrayInstructions.Add("<b>");
			ArrayInstructions.Add(NStr("vi = 'Mục tin bổ sung:';
										|ru = 'Дополнительные реквизиты:';
										|en = 'Additional attributes:'; fa = 'ویژگی‌های تکمیلی:';
										|it = 'Requisiti aggiuntivi:';
										|pl = 'Atrybuty dodatkowe:';
										|tr = 'Ek öznitelikler:'"));
			ArrayInstructions.Add("</b>");
			ArrayInstructions.Add("</tr></td>");
			HeaderOfAdditionalBankingDetailsIsDisplayed = True;
		EndIf;
		
		If AttributeStructure.ThisIsTable Then
			ThereAreTables = True;
			
			ArrayInstructions.Add("<tr><td>");
			ArrayInstructions.Add("<b>");
			ArrayInstructions.Add(StrTemplate(NStr("vi = 'Phần bảng %1';
													|ru = 'Табличная часть %1';
													|en = 'Table %1'; fa = 'Table %1';
													|it = 'Табличная часть %1';
													|pl = 'Część tabelaryczna %1';
													|tr = 'Tablo %1'"), AttributeStructure.Name));
			ArrayInstructions.Add("</b></td>");
			
			ArrayInstructions.Add("<td><b>");
			ArrayInstructions.Add(AttributeStructure.Presentation);
			ArrayInstructions.Add("</b></td>");
			
			ArrayInstructions.Add("</tr>");
			
			TableAttributes = AttributeSet.FindRows(New Structure("Table", AttributeStructure.Name));
			For Each TableAttribute In TableAttributes Do
				ArrayInstructions.Add("<tr>");
				
				PrintAttributeNameBEFORE(ArrayInstructions, TableAttribute, TableAttribute.Name);
				
				ArrayInstructions.Add("<td>");
				ArrayInstructions.Add(TableAttribute.Presentation);
				ArrayInstructions.Add("</td>");
				
				ArrayInstructions.Add("</tr>");
			EndDo;
			Continue;
		EndIf;
		
		If IsAddlAttribute Then
			If OutputOfIPObjectAttributes Then
				IDOfAdditionalBankingDetails = Common.ObjectAttributeValue(
					AttributeStructure.AdditionalAttributeIS,
					"IDForFormulas");
				AttributeName = StrTemplate("ID: ""%1""<br>IDForFormulas: ""%2""</br>",
					AttributeStructure.AdditionalAttributeIS.UUID(),
					IDOfAdditionalBankingDetails);
			Else
				IDOfAdditionalBankingDetails = AttributeStructure.AdditionalAttribute5ID;
				If Parameters.PlaceWhereExpressionIsExecuted = Enums.PlacesWhereExpressionsOnBuiltInLanguageAreExecuted.OnIntegratedSystemSide Then
					AttributeName = StrTemplate("<a href=""#DMAdditionalProperty"">ID: ""%1""</a>", IDOfAdditionalBankingDetails);
				Else
					AttributeName = StrTemplate("ID: ""%1""", IDOfAdditionalBankingDetails);
				EndIf;
			EndIf;
		Else
			AttributeName = AttributeStructure.Name;
		EndIf;
		
		ArrayInstructions.Add("<tr>");
		
		PrintAttributeNameBEFORE(ArrayInstructions, AttributeStructure, AttributeName);
		
		ArrayInstructions.Add("<td>");
		ArrayInstructions.Add(AttributeStructure.Presentation);
		If StrFind(AttributeName, "status_") = 1 And StrFind(AttributeStructure.Presentation, "Approval") > 0 Then
			IdOfApprovalAction = AttributeName;
		EndIf;
		ArrayInstructions.Add("</td>");
		
		ArrayInstructions.Add("</tr>");
		
	EndDo;
	
	ArrayInstructions.Add("</table>");
	
	ArrayInstructions.Add("</pre></blockquote>");
	AddCollapsibleGroup(ArrayInstructions, False);
	
	// Let's output examples of expressions.
	ArrayInstructions.Add("<p>");
	If HeaderOfAdditionalBankingDetailsIsDisplayed Then
		If Parameters.ThisIsConditionOfApplicabilityWhenUnloading Then
			SectionTitle = NStr("vi = 'Ví dụ truy cập đến mục tin bổ sung của nguồn';
								|ru = 'Пример обращения к дополнительным реквизитам источника';
								|en = 'Example of accessing additional source attributes'; fa = 'Example of accessing additional source attributes';
								|it = 'Пример обращения к дополнительным реквизитам источника';
								|pl = 'Example of accessing additional source attributes';
								|tr = 'Ek kaynak özniteliklerine erişim örneği'");
			ExampleExpression =
				"ValueOfAdditionalAttributes = Undefined;
				|For Everyone String From Parameters.Source.AdditionalAttributes Cycle
				|	If String.Property.IDForFormulas = ""IDOfAdditionalBankingDetails"" Then
				|		ValueOfAdditionalAttributes = String.Value;
				|	EndIf;
				|EndOfTheCycle;";
		ElsIf Parameters.ThisIsConditionOfApplicabilityWhenLoading Then
			SectionTitle = NStr("vi = 'Ví dụ truy cập đến mục tin bổ sung của nguồn';
								|ru = 'Пример обращения к дополнительным реквизитам источника';
								|en = 'Example of accessing additional source attributes'; fa = 'Example of accessing additional source attributes';
								|it = 'Пример обращения к дополнительным реквизитам источника';
								|pl = 'Example of accessing additional source attributes';
								|tr = 'Ek kaynak özniteliklerine erişim örneği'");
			ExampleExpression =
				"ValueOfAdditionalAttributes = Undefined;
				|For Everyone XDTOProperty From Parameters.Source.additionalProperties Cycle
				|	If XDTOProperty.objectID.ID = ""IDOfAdditionalBankingDetails"" Then
				|		ValueOfAdditionalAttributes = XDTOProperty.propertySimpleValue;
				|	EndIf;
				|EndOfTheCycle;";
		ElsIf OutputOfIPObjectAttributes Then
			SectionTitle = NStr("ru = 'Пример обращения к дополнительным реквизитам приемника';
								|vi = 'Example of accessing additional destination attributes';
								|en = 'Example of accessing additional destination attributes'; fa = 'Example of accessing additional destination attributes';
								|it = 'Пример обращения к дополнительным реквизитам приемника';
								|pl = 'Example of accessing additional destination attributes';
								|tr = 'Ek kaynak özniteliklerine erişim örneği'");
			ExampleExpression =
				"ValueOfAdditionalAttributes = Undefined;
				|For Everyone String From Parameters.Receiver.AdditionalAttributes Cycle
				|	If String.Property.IDForFormulas = ""IDOfAdditionalBankingDetails"" Then
				|		ValueOfAdditionalAttributes = String.Value;
				|	EndIf;
				|EndOfTheCycle;";
		Else
			SectionTitle = NStr("vi = 'Ví dụ truy cập đến mục tin bổ sung của nguồn';
								|ru = 'Пример обращения к дополнительным реквизитам источника';
								|en = 'Example of accessing additional source attributes'; fa = 'Example of accessing additional source attributes';
								|it = 'Пример обращения к дополнительным реквизитам источника';
								|pl = 'Example of accessing additional source attributes';
								|tr = 'Ek kaynak özniteliklerine erişim örneği'");
			If Parameters.PlaceWhereExpressionIsExecuted = Enums.PlacesWhereExpressionsOnBuiltInLanguageAreExecuted.OnDocumentManagementSide Then
				If Parameters.ThisIsTableLoadingRule Then
					ExampleExpression =
						"ValueOfAdditionalAttributes = Undefined;
						|For Everyone String From Parameters.Source.AdditionalAttributes Cycle
						|	If TrimAll(String.Property.UUID()) = ""IDOfAdditionalBankingDetails"" Then
						|		ValueOfAdditionalAttributes = String.Value;
						|	EndIf;
						|EndOfTheCycle;";
				Else
					ExampleExpression =
						"For Everyone String From Parameters.Source.AdditionalAttributes Cycle
						|	If TrimAll(String.Property.UUID()) = ""IDOfAdditionalBankingDetails"" Then
						|		Parameters.Result = String.Value;
						|	EndIf;
						|EndOfTheCycle;";
				EndIf;
			Else
				If Parameters.ThisIsTableLoadingRule Then
					ExampleExpression =
						"ValueOfAdditionalAttributes = Undefined;
						|For Everyone XDTOProperty From Parameters.Source.additionalProperties Cycle
						|	If XDTOProperty.objectID.ID = ""IDOfAdditionalBankingDetails"" Then
						|		ValueOfAdditionalAttributes = XDTOProperty.propertySimpleValue;
						|	EndIf;
						|EndOfTheCycle;";
				Else
					ExampleExpression =
						"For Everyone XDTOProperty From Parameters.Source.additionalProperties Cycle
						|	If XDTOProperty.objectID.ID = ""IDOfAdditionalBankingDetails"" Then
						|		Parameters.Result = XDTOProperty.propertySimpleValue;
						|	EndIf;
						|EndOfTheCycle;";
				EndIf;
			EndIf;
		EndIf;
		ExampleExpression = StrReplace(ExampleExpression, "IDOfAdditionalBankingDetails", IDOfAdditionalBankingDetails);
		OutputExampleExpression(ArrayInstructions, SectionTitle, ExampleExpression);
	EndIf;
	
	If IdOfApprovalAction <> "status_00000000_0000_0000_0000_000000000000" Then
		SectionTitle = NStr("vi = 'Ví dụ kết nhập trạng thái thống nhất từ 1C:Document Management';
							|ru = 'Пример загрузки статуса согласования из 1С:Документооборота';
							|en = 'Example of importing an approval status from 1C:Document Management'; fa = 'Example of importing an approval status from 1C:Document Management';
							|it = 'Пример загрузки статуса согласования из 1С:Документооборота';
							|pl = 'Example of importing an approval status from 1C:Document Management';
							|tr = '1C:Document Management onay durumunun indirilmesi örneği'");
		ExampleExpression =
			"StateOfApprovalBefore = Parameters.Source.IdOfApprovalAction;
			|If StateOfApprovalBefore = ""Approved"" Then
			|	Parameters.Result = Enums.DemoOfTheCounterpartySContractStatus.Approved;
			|ElsIf StateOfApprovalBefore = ""NotApproved"" Then
			|	Parameters.Result = Enums.DemoOfTheCounterpartySContractStatus.NotApproved;
			|ElsIf StateOfApprovalBefore = ""AwaitingApproval"" Then
			|	Parameters.Result = Enums.DemoOfTheCounterpartySContractStatus.AwaitingApproval;
			|Else
			|	Parameters.Result = Enums.DemoOfTheCounterpartySContractStatus.Project;
			|EndIf;";
		ExampleExpression = StrReplace(ExampleExpression, "IdOfApprovalAction", IdOfApprovalAction);
		OutputExampleExpression(ArrayInstructions, SectionTitle, ExampleExpression);
	EndIf;
	
	If ThereAreTables
			And Not OutputOfIPObjectAttributes
			And Parameters.PlaceWhereExpressionIsExecuted = Enums.PlacesWhereExpressionsOnBuiltInLanguageAreExecuted.OnIntegratedSystemSide Then
		SectionTitle = NStr("vi = 'Ví dụ kết nhập dữ liệu từ phần bảng của 1C:Document Management';
							|ru = 'Пример загрузки данных из табличной части 1С:Документооборота';
							|en = 'Example of importing data from a 1C:Document Management table'; fa = 'Example of importing data from a 1C:Document Management table';
							|it = 'Пример загрузки данных из табличной части 1С:Документооборота';
							|pl = 'Example of importing data from a 1C:Document Management table';
							|tr = '1C:Document Management''ın tablosundan veri yükleme örneği'");
		If Parameters.ThisIsTableLoadingRule Then
			ExampleExpression =
				"Parameters.Result = New ValueTable;
				|Parameters.Result.Columns.Add(""CFItem"");
				|Parameters.Result.Columns.Add(""Sum"");
				|Parameters.Result.Columns.Add(""VATAmount"");
				|TSOfCashFlowArticleHasBeenInstalled = Parameters.Source.Property(""cashFlowRows"")
				|	AND IntegrationWith1CDocumentManagementCore.PropertySet(
				|		Parameters.Source.cashFlowRows,
				|		""rows"");
				|If TSOfCashFlowArticleHasBeenInstalled THEN
				|	RowIndex = 0;
				|	TransferOldData =
				|		(Parameters.Source.cashFlowRows.rows.COUNT() = Parameters.Receiver.Ref.ARAPDetails.COUNT());
				|	FOR Everyone XDTORow FROM Parameters.Source.cashFlowRows.rows Cycle
				|		PaymentDecryptionLine = Parameters.Result.Add();
				|		If TransferOldData THEN
				|			FillPropertyValues(PaymentDecryptionLine, Parameters.Receiver.Ref.ARAPDetails[RowIndex]);
				|		ELSE
				|			PaymentDecryptionLine.Sum = XDTORow.total;
				|			PaymentDecryptionLine.VATAmount = XDTORow.VAT;
				|		EndIf;
				|		PaymentDecryptionLine.CFItem =
				|			IntegrationWith1CDocumentManagementCore.ValueOfAttributeOfIPObjectByValueToFillIn(
				|				TYPE(""CatalogLink._DemoArticlesOfCashRegisterRecords""),
				|				IntegrationWith1CDocumentManagementCore.ValueForFillingInAttributesOfIPObject(
				|					XDTORow.item));
				|		RowIndex = RowIndex + 1;
				|	EndOfTheCycle;
				|EndIf;";
		Else
			ExampleExpression =
				"TSOfCashFlowArticleHasBeenInstalled = Parameters.Source.Property(""cashFlowRows"")
				|	AND IntegrationWith1CDocumentManagementCore.PropertySet(
				|		Parameters.Source.cashFlowRows, ""rows"")
				|	AND Parameters.Source.cashFlowRows.rows.COUNT() > 0;
				|If TSOfCashFlowArticleHasBeenInstalled THEN
				|	ArticleOfTheDDSXDTO = Parameters.Source.cashFlowRows.rows[0].item;
				|	Parameters.Result =
				|		IntegrationWith1CDocumentManagementCore.ValueOfAttributeOfIPObjectByValueToFillIn(
				|			TYPE(""CatalogLink._DemoArticlesOfCashRegisterRecords""),
				|			IntegrationWith1CDocumentManagementCore.ValueForFillingInAttributesOfIPObject(
				|				ArticleOfTheDDSXDTO));
				|EndIf;";
		EndIf;
		OutputExampleExpression(ArrayInstructions, SectionTitle, ExampleExpression);
	EndIf;
	
	ArrayInstructions.Add("<p>");
	
EndProcedure

// Adds additional details to the row of the table with filling in the columns specified as parameters.
//
Procedure AddAdditionalProps(Attributes, Presentation, Type, AdditionalAttribute5ID, AdditionalAttribute5Type)
	
	NewRow = Attributes.Add();
	NewRow.Presentation = StrTemplate(NStr("vi = 'Mục tin bổ sung: %1';
											|ru = 'Доп. реквизит: %1';
											|en = 'Additional attribute: %1'; fa = 'Additional attribute: %1';
											|it = 'Additional attribute: %1';
											|pl = 'Additional attribute: %1';
											|tr = 'Ek öznitelik: %1'"), Presentation);
	NewRow.ThisIsMainAttribute = True;
	
	If TypeOf(Type) <> Type("ValueList") Then
		Types = New ValueList;
		Types.Add(Type);
		NewRow.Type = Types;
	Else
		NewRow.Type = Type;
	EndIf;
	
	NewRow.AdditionalAttribute5 = True;
	NewRow.AdditionalAttribute5ID = AdditionalAttribute5ID;
	NewRow.AdditionalAttribute5Type = AdditionalAttribute5Type;
	
EndProcedure

// Adds the props to the row of the table with filling in the columns specified as parameters.
//
Procedure AddAttribute(Attributes, Name, Presentation, Type, Mandatory = False, NameOfAttributeOfVDO = "",
		ThisIsMainAttribute = True)
	
	NewRow = Attributes.Add();
	NewRow.Name = Name;
	NewRow.Presentation = Presentation;
	NewRow.NameOfAttributeOfVDO = NameOfAttributeOfVDO;
	NewRow.ThisIsMainAttribute = ThisIsMainAttribute;
	
	If TypeOf(Type) <> Type("ValueList") Then
		Types = New ValueList;
		Types.Add(Type);
		NewRow.Type = Types;
	Else
		NewRow.Type = Type;
	EndIf;
	
	NewRow.Mandatory = Mandatory;
	
EndProcedure

// Adds the props to the subordinate row of the table, with filling in the columns specified as parameters.
//
Procedure AddTableDetails(Attributes, TableName, Name, Presentation, Type, Mandatory = False)
	
	NewRow = Attributes.Add();
	NewRow.Table = TableName;
	NewRow.Name = Name;
	NewRow.Presentation = Presentation;
	NewRow.ThisIsMainAttribute = False;
	
	If TypeOf(Type) <> Type("ValueList") Then
		Types = New ValueList;
		Types.Add(Type);
		NewRow.Type = Types;
	Else
		NewRow.Type = Type;
	EndIf;
	
	NewRow.Mandatory = Mandatory;
	
EndProcedure

// Adds the opening or closing tag of the collapsible group to the expression statement in the built-in language.
//
// Parameters:
//   ArrayInstructions - Array of String - an array for accumulating the HTML code of the instruction.
//   StartTag - Boolean - indicates whether an opening tag has been added.
//
Procedure AddCollapsibleGroup(ArrayInstructions, StartTag)
	
	If Common.IsLinuxClient() Then
		Return;
	EndIf;
	
	If StartTag Then
		ArrayInstructions.Add("<details>");
	Else
		ArrayInstructions.Add("</details>");
	EndIf;
	
EndProcedure

// Adds a table to a table row with the columns specified as parameters filled in.
//
Procedure AddTable(Attributes, Name, Presentation)
	
	NewRow = Attributes.Add();
	NewRow.ThisIsTable = True;
	NewRow.Name = Name;
	NewRow.Presentation = Presentation;
	NewRow.ThisIsMainAttribute = False;
	
EndProcedure

Function PresentationOfKeyAttributes(KeyAttribute)
	
	If TypeOf(KeyAttribute.AttributeValue) = Type("Boolean")
			Or TypeOf(KeyAttribute.AttributeValue) = Type("Number")
			Or TypeOf(KeyAttribute.AttributeValue) = Type("Date") Then
		Return StrTemplate("%1: %2", KeyAttribute.Presentation, TrimAll(KeyAttribute.AttributeValue));
	Else
		Presentation = TrimAll(KeyAttribute.AttributeValue);
		If Presentation = "" Then
			Presentation = StrTemplate(NStr("ru = '%1: пустое значение';
											|vi = '%1: empty value';
											|en = '%1: empty value'; fa = '%1: empty value';
											|it = '%1: è un valore vuoto';
											|pl = '%1: pusta wartość';
											|tr = '%1: boş değer'"), KeyAttribute.Presentation);
		EndIf;
		Return Presentation;
	EndIf;
	
EndFunction

Procedure CheckAvailabilityForDuplicates(IntegrationRule, ErrorList)
	
	If IntegrationRule.DeletionMark Then
		Return;
	EndIf;
	
	If IntegrationRule.UseApplicabilityConditionWhenExporting Then
		
		Query = New Query(
			"SELECT
			|	RulesForIntegrationWith1CDocumentManagement3.Ref AS Ref,
			|	RulesForIntegrationWith1CDocumentManagement3.ApplicabilityConditionOnExport AS ApplicabilityConditionOnExport
			|FROM
			|	Catalog.RulesForIntegrationWith1CDocumentManagement3 AS RulesForIntegrationWith1CDocumentManagement3
			|WHERE
			|	RulesForIntegrationWith1CDocumentManagement3.Ref <> &Ref
			|	AND RulesForIntegrationWith1CDocumentManagement3.ObjectTypeIS = &ObjectTypeIS
			|	AND NOT RulesForIntegrationWith1CDocumentManagement3.DeletionMark
			|	AND RulesForIntegrationWith1CDocumentManagement3.UseApplicabilityConditionWhenExporting");
		Query.SetParameter("Ref", IntegrationRule.Ref);
		Query.SetParameter("ObjectTypeIS", IntegrationRule.ObjectTypeIS);
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			CurrentExpression = IntegrationWith1CDocumentManagementCore.ExpressionWithoutExtraCharacters(
				IntegrationRule.ApplicabilityConditionOnExport);
			ExistingExpression = IntegrationWith1CDocumentManagementCore.ExpressionWithoutExtraCharacters(
				Selection.ApplicabilityConditionOnExport);
			If CurrentExpression = ExistingExpression Then
				ErrorList.Add(StrTemplate(
					NStr("ru = 'Правило интеграции объекта ""%1"" уже существует.
						|Для создания еще одного правила требуется изменить произвольное выражение на закладке ""Условия применимости для выгрузки объектов в 1С:ДО"".';
						|vi = 'The ""%1"" object integration rule already exists.
						|To create another rule, change the custom expression on the ""Applicability condition for exporting objects to 1C:Document Management"" tab.';
						|en = 'The ""%1"" object integration rule already exists.
						|To create another rule, change the custom expression on the ""Applicability condition for exporting objects to 1C:Document Management"" tab.'; fa = 'The ""%1"" object integration rule already exists.
						|To create another rule, change the custom expression on the ""Applicability condition for exporting objects to 1C:Document Management"" tab.';
						|it = 'The ""%1"" object integration rule already exists.
						|To create another rule, change the custom expression on the ""Applicability condition for exporting objects to 1C:Document Management"" tab.';
						|pl = 'The ""%1"" object integration rule already exists.
						|To create another rule, change the custom expression on the ""Applicability condition for exporting objects to 1C:Document Management"" tab.';
						|tr = '""%1"" nesnesi entegrasyon kuralı zaten mevcut. 
						|Başka bir kural oluşturmak için ""Nesnelerin 1C:DM''ye dışa aktarımı için uygulanabilirlik koşulları"" sekmesindeki serbest ifadeyi değiştirmeniz gerekir.'"),
						IntegrationRule.ObjectPresentationISWithKeyFields));
				Break;
			EndIf;
		EndDo;
		
	Else
		
		KeyAttributesOfIPColumn = "Name, AttributeValue";
		CurrentKeyIPAttributes = IntegrationRule.KeyAttributesIS.Unload(, KeyAttributesOfIPColumn);
		
		Query = New Query(
			"SELECT
			|	RulesForIntegrationWith1CDocumentManagement3.Ref AS Ref,
			|	RulesForIntegrationWith1CDocumentManagement3.KeyAttributesIS AS KeyAttributesIS
			|FROM
			|	Catalog.RulesForIntegrationWith1CDocumentManagement3 AS RulesForIntegrationWith1CDocumentManagement3
			|WHERE
			|	RulesForIntegrationWith1CDocumentManagement3.Ref <> &Ref
			|	AND RulesForIntegrationWith1CDocumentManagement3.ObjectTypeIS = &ObjectTypeIS
			|	AND NOT RulesForIntegrationWith1CDocumentManagement3.DeletionMark");
		Query.SetParameter("Ref", IntegrationRule.Ref);
		Query.SetParameter("ObjectTypeIS", IntegrationRule.ObjectTypeIS);
		Query.Text = StrReplace(
			Query.Text,
			"RulesForIntegrationWith1CDocumentManagement3.KeyAttributesIS",
			StrTemplate("RulesForIntegrationWith1CDocumentManagement3.KeyAttributesIS.(%1)", KeyAttributesOfIPColumn));
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			If Common.IdenticalCollections(CurrentKeyIPAttributes, Selection.KeyAttributesIS.Unload()) Then
				ErrorList.Add(StrTemplate(
					NStr("ru = 'Правило интеграции объекта ""%1"" уже существует.
						|Для создания еще одного правила требуется изменить ключевые реквизиты на закладке ""Условия применимости для выгрузки объектов в 1С:ДО"".';
						|vi = 'The ""%1"" object integration rule already exists.
						|To create another rule, change the key attributes on the ""Applicability condition for exporting objects to 1C:Document Management"" tab.';
						|en = 'The ""%1"" object integration rule already exists.
						|To create another rule, change the key attributes on the ""Applicability condition for exporting objects to 1C:Document Management"" tab.'; fa = 'The ""%1"" object integration rule already exists.
						|To create another rule, change the key attributes on the ""Applicability condition for exporting objects to 1C:Document Management"" tab.';
						|it = 'The ""%1"" object integration rule already exists.
						|To create another rule, change the key attributes on the ""Applicability condition for exporting objects to 1C:Document Management"" tab.';
						|pl = 'The ""%1"" object integration rule already exists.
						|To create another rule, change the key attributes on the ""Applicability condition for exporting objects to 1C:Document Management"" tab.';
						|tr = '""%1"" nesnesi entegrasyon kuralı zaten mevcut.
						|Başka bir kural oluşturmak için ""Nesnelerin 1C:DM''ye dışa aktarımı için uygulanabilirlik koşulları"" sekmesindeki anahtar öznitelikleri değiştirmeniz gerekir.'"),
					IntegrationRule.ObjectPresentationISWithKeyFields));
				Break;
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure CheckTheAttributeFillingRulesIS(IntegrationRule, ObjectIS, XDTODataObject, ObjectAttributesIS,
		AttributesOfTheCurrentDocumentKindDM, AllMapItemDetailsUpTo, ErrorList)
	
	For Each Rule In IntegrationRule.AttributeFillingRulesIS Do
		
		AttributeIS = ObjectAttributesIS.Find(Rule.AttributeNameObjectIS, "Name");
		TableIS = ObjectAttributesIS.Find(Rule.Table, "Name");
		AttributePresentationIS = "";
		AttributeTypePresentationIS = "";
		
		If Rule.ThisIsTable Then
			AttributeTypePresentationIS = NStr("ru = 'таблицы';
												|vi = 'tables';
												|en = 'tables'; fa = 'tables';
												|it = 'tables';
												|pl = 'tables';
												|tr = 'Tablolar'");
			
		ElsIf Rule.IsAdditionalAttributeIS Then
			AttributeTypePresentationIS = NStr("ru = 'доп. реквизита';
												|vi = 'additional attribute';
												|en = 'additional attribute'; fa = 'additional attribute';
												|it = 'additional attribute';
												|pl = 'additional attribute';
												|tr = 'Ek öznitelik'");
			
		ElsIf Not ValueIsFilled(Rule.Table) Then
			AttributeTypePresentationIS = NStr("ru = 'реквизита';
												|vi = 'attribute';
												|en = 'attribute'; fa = 'attribute';
												|it = 'attribute';
												|pl = 'attribute';
												|tr = 'özniteliğin'");
			
		EndIf;
		
		If ValueIsFilled(Rule.Table) Then
			AttributePresentationIS = StrTemplate(NStr("ru = 'реквизита ""%1"" таблицы ""%2""';
														|vi = '""%1"" attribute of the ""%2"" table';
														|en = '""%1"" attribute of the ""%2"" table'; fa = '""%1"" attribute of the ""%2"" table';
														|it = '""%1"" attribute of the ""%2"" table';
														|pl = '""%1"" attribute of the ""%2"" table';
														|tr = '""%1"" özniteliği, ""%2"" tablosu'"),
				?(AttributeIS = Undefined, Rule.AttributeNameObjectIS, AttributeIS.Presentation),
				?(TableIS = Undefined, Rule.Table, TableIS.Presentation));
			
		Else
			AttributePresentationIS = StrTemplate("%1 ""%2""",
				AttributeTypePresentationIS,
				?(AttributeIS = Undefined, Rule.AttributeNameObjectIS, AttributeIS.Presentation));
			
		EndIf;
		
		If Rule.Variant = Enums.VariantsOfTheRulesForFillingInAttributes.ObjectAttribute Then
			
			If Not Rule.IsAdditionalAttributeDM Then
				
				SplitRow = StrSplit(Rule.AttributeNameObjectDM, ".", False);
				If SplitRow.Count() = 1 Then // "property"
					Table = "";
					AttributeName = Rule.AttributeNameObjectDM;
					
				ElsIf SplitRow.Count() = 2 Then // "the list.property"
					Table = "";
					AttributeName = StrTemplate("%1.%2", SplitRow[0], SplitRow[1]);
					
				ElsIf SplitRow.Count() = 3 Then // "the list.list.property"
					Table = StrTemplate("%1.%2", SplitRow[0], SplitRow[1]);
					AttributeName = SplitRow[2];
					
				Else
					ErrorList.Add(
						StrTemplate(
							NStr("ru = 'Ошибка в правиле заполнения %1:
								|Указано недопустимое имя реквизита-источника данных заполнения: %2';
								|vi = 'Filling rule error %1:
								|Invalid filling data attribute name is specified: %2';
								|en = 'Filling rule error %1:
								|Invalid filling data attribute name is specified: %2'; fa = 'Filling rule error %1:
								|Invalid filling data attribute name is specified: %2';
								|it = 'Filling rule error %1:
								|Invalid filling data attribute name is specified: %2';
								|pl = 'Filling rule error %1:
								|Invalid filling data attribute name is specified: %2';
								|tr = 'Doldurma kuralı hatası %1:
								| Geçersiz doldurma veri kaynağı öznitelik adı belirtildi: %2'"),
							AttributePresentationIS,
							Rule.AttributeNameObjectDM));
					Continue;
					
				EndIf;
				
				Filter = New Structure("Name, Table", AttributeName, Table);
				
				FoundRows = AttributesOfTheCurrentDocumentKindDM.FindRows(Filter);
				
				If FoundRows.Count() = 0 Then
					AllDetailsDMProps = AllMapItemDetailsUpTo.FindRows(Filter);
					AllDetailsDMPayment = AllMapItemDetailsUpTo.FindRows(New Structure("Name", Table));
					
					If Rule.ThisIsTable Then
						ErrorList.Add(
							StrTemplate(
								NStr("ru = 'Ошибка в правиле заполнения %1:
									|выбран вариант заполнения из несуществующей таблицы ""%2""';
									|vi = 'Filling rule error %1:
									|filling option is selected from non-existing table ""%2""';
									|en = 'Filling rule error %1:
									|filling option is selected from non-existing table ""%2""'; fa = 'Filling rule error %1:
									|filling option is selected from non-existing table ""%2""';
									|it = 'Filling rule error %1:
									|filling option is selected from non-existing table ""%2""';
									|pl = 'Filling rule error %1:
									|filling option is selected from non-existing table ""%2""';
									|tr = 'Doldurma kuralı hatası %1:
									|Mevcut olmayan ""%2"" tablosundan doldurma seçeneği seçildi'"),
								AttributePresentationIS,
								?(AllDetailsDMProps.Count() = 0,
									Rule.AttributeNameObjectDM,
									AllDetailsDMProps[0].Presentation)));
					Else
						If ValueIsFilled(Table) Then
							ErrorList.Add(
								StrTemplate(
									NStr("ru = 'Ошибка в правиле заполнения %1:
										|выбран вариант заполнения из реквизита ""%2"" несуществующей таблицы ""%3""';
										|vi = 'Filling rule error %1:
										|filling option is selected from the ""%2"" attribute of non-existing table ""%3""';
										|en = 'Filling rule error %1:
										|filling option is selected from the ""%2"" attribute of non-existing table ""%3""'; fa = 'Filling rule error %1:
										|filling option is selected from the ""%2"" attribute of non-existing table ""%3""';
										|it = 'Filling rule error %1:
										|filling option is selected from the ""%2"" attribute of non-existing table ""%3""';
										|pl = 'Filling rule error %1:
										|filling option is selected from the ""%2"" attribute of non-existing table ""%3""';
										|tr = 'Doldurma kuralı hatası %1:
										|Mevcut olmayan ""%3"" tablosundaki ""%2"" özniteliğinden doldurma seçeneği seçildi'"),
									AttributePresentationIS,
									?(AllDetailsDMProps.Count() = 0,
										Rule.AttributeNameObjectDM,
										AllDetailsDMProps[0].Presentation),
									?(AllDetailsDMPayment.Count() = 0,
										Table,
										AllDetailsDMPayment[0].Presentation)));
						Else
							ErrorList.Add(
								StrTemplate(
									NStr("ru = 'Ошибка в правиле заполнения %1:
										|выбран вариант заполнения из несуществующего реквизита ""%2""';
										|vi = 'Filling rule error %1:
										|filling option is selected from non-existing attribute ""%2""';
										|en = 'Filling rule error %1:
										|filling option is selected from non-existing attribute ""%2""'; fa = 'Filling rule error %1:
										|filling option is selected from non-existing attribute ""%2""';
										|it = 'Filling rule error %1:
										|filling option is selected from non-existing attribute ""%2""';
										|pl = 'Filling rule error %1:
										|filling option is selected from non-existing attribute ""%2""';
										|tr = 'Doldurma kuralı hatası %1:
										| Mevcut olmayan ""%2"" özniteliğinden doldurma seçeneği seçildi'"),
									AttributePresentationIS,
									?(AllDetailsDMProps.Count() = 0,
										Rule.AttributeNameObjectDM,
										AllDetailsDMProps[0].Presentation)));
						EndIf;
					EndIf;
				EndIf;
				
			Else // Additional Attributes TO.
				
				Filter = New Structure("AdditionalAttribute5ID, AdditionalAttribute5Type",
					Rule.AdditionalAttributeDMID,
					Rule.AdditionalAttributeDMType);
				FoundRows = AttributesOfTheCurrentDocumentKindDM.FindRows(Filter);
				
				If FoundRows.Count() = 0 Then
					ErrorList.Add(
						StrTemplate(
							NStr("ru = 'Ошибка в правиле заполнения %1:
								|выбран вариант заполнения из несуществующего доп. реквизита ""%2""';
								|vi = 'Filling rule error %1:
								|filling option is selected from non-existing additional attribute ""%2""';
								|en = 'Filling rule error %1:
								|filling option is selected from non-existing additional attribute ""%2""'; fa = 'Filling rule error %1:
								|filling option is selected from non-existing additional attribute ""%2""';
								|it = 'Filling rule error %1:
								|filling option is selected from non-existing additional attribute ""%2""';
								|pl = 'Filling rule error %1:
								|filling option is selected from non-existing additional attribute ""%2""';
								|tr = 'Doldurma kuralı hatası %1:
								| Mevcut olmayan ""%2"" ek özniteliğinden doldurma seçeneği seçildi'"),
							AttributePresentationIS,
							Rule.AdditionalAttributeDMID));
				EndIf;
				
			EndIf;
			
		ElsIf Rule.Variant = Enums.VariantsOfTheRulesForFillingInAttributes.ScriptExpression Then
			
			SourceTable1 = "";
			If ValueIsFilled(Rule.Table) Then
				HigherLineRule = IntegrationRule.AttributeFillingRulesIS.FindRows(
					New Structure("AttributeNameObjectIS, ThisIsTable", Rule.Table, True));
				If HigherLineRule.Count() = 1 Then
					SourceTable1 = HigherLineRule[0].AttributeNameObjectDM;
				EndIf;
			EndIf;
			
			ContextOfExpression = ContextOfExpressionInEmbeddedLanguage();
			ContextOfExpression.XDTODataObject = XDTODataObject;
			ContextOfExpression.ObjectIS = ObjectIS;
			ContextOfExpression.SourceTable1 = SourceTable1;
			
			Try
				CheckLoadingRuleExpression(
					Rule.ComputedExpression,
					Rule.PlaceWhereExpressionIsExecuted,
					IntegrationRule.ObjectTypeDM,
					IntegrationRule.ObjectTypeIS,
					ContextOfExpression,
					Rule.ThisIsTable);
			Except
				ExceptionText = ErrorProcessing.BriefErrorDescription(ErrorInfo());
				ErrorList.Add(
					StrTemplate(
						NStr("ru = 'Ошибка в правиле заполнения %1:
							|Не удалось выполнить выражение на встроенном языке по причине:
							|%2';
							|vi = 'Filling rule error %1:
							|Cannot execute the expression in 1C:Enterprise language due to:
							|%2';
							|en = 'Filling rule error %1:
							|Cannot execute the expression in 1C:Enterprise language due to:
							|%2'; fa = 'Filling rule error %1:
							|Cannot execute the expression in 1C:Enterprise language due to:
							|%2';
							|it = 'Filling rule error %1:
							|Cannot execute the expression in 1C:Enterprise language due to:
							|%2';
							|pl = 'Filling rule error %1:
							|Cannot execute the expression in 1C:Enterprise language due to:
							|%2';
							|tr = 'Doldurma kuralı hatası %1:
							| Yerleşik dildeki ifade şu nedenle yürütülemedi:
							|%2'"),
						AttributePresentationIS,
						ExceptionText));
			EndTry;
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndIf
