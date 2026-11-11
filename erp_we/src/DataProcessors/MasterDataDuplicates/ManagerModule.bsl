#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Report

// Generates and returns a report for comparing the data of the found Master Data duplicates.
//
// Parameters:
//   IdOfDuplicates - SeeDataProcessor.MasterDataDuplicates.Form.CompareAndConfirmDuplicates.IdOfDuplicates
//   Duplicates - SeeDataProcessor.MasterDataDuplicates.Form.CompareAndConfirmDuplicates.Duplicates
//   ComparisonOption - SeeDataProcessor.MasterDataDuplicates.Form.CompareAndConfirmDuplicates.OptionOfComparingDoubles
//
// Returns:
//   SpreadsheetDocument - A report with data for comparing duplicates.
//
Function ComparisonReport(IdOfDuplicates, Duplicates, ComparisonOption) Export
	
	FullNameOfComparisonTable = Common.ObjectAttributeValue(IdOfDuplicates, "FullName");
	NameParts = StringFunctionsClientServer.SplitStringIntoSubstringsArray(FullNameOfComparisonTable, ".");
	
	MetadataObjectClass = NameParts[0];
	MetadataObjectName = NameParts[1];
	
	If Upper(MetadataObjectClass) = "CATALOG" Then
		MetadataObject = Metadata.Catalogs[MetadataObjectName];
	ElsIf Upper(MetadataObjectClass) = "CHARTOFCHARACTERISTICTYPES" Then
		MetadataObject =  Metadata.ChartsOfCharacteristicTypes[MetadataObjectName];
	Else
		Return New SpreadsheetDocument();
	EndIf;
	
	// Initializing the report generation context
	Sidewall = New ValueList;
	SynonymousNames = New Map;
	
	AdditionalAttributes = AdditionalAttributes();
	SearchAndReplaceDuplicatesMasterDataOverridable.WhenDeterminingAdditionalDetails(AdditionalAttributes);
	
	ReportGenerationContext = New Structure;
	ReportGenerationContext.Insert("Indexes", IndexesForBuildingReport());
	ReportGenerationContext.Insert("Sidewall", Sidewall);
	ReportGenerationContext.Insert("SynonymousNames", SynonymousNames);
	ReportGenerationContext.Insert("AdditionalAttributes", ConvertTableToMatch(AdditionalAttributes));
	
	AttributesToReport = ReportGenerationContext.Indexes.AttributesToReport;
	TabularPartsInReport = ReportGenerationContext.Indexes.TabularPartsInReport;
	AllAttributesAndValues = ReportGenerationContext.Indexes.AllAttributesAndValues;
	
	// Main data table
	LanguagesInfo = NationalLanguageSupportServer.LanguagesInfo();
	RequestFieldAttributes = RequestFieldAttributes(MetadataObject, ReportGenerationContext, LanguagesInfo);
	ExcludeServiceDetails(RequestFieldAttributes, MetadataObject, ReportGenerationContext);
	
	RaiseDetailsToTopOfList(Sidewall);
	
	Query = New Query;
	
	// Creating a request to receive submissions in different languages
	Joins = "";
	PartsOfViewFields = New Array;
	RepresentationsInDifferentLanguages = MetadataObject.TabularSections.Find("Presentations");
	If RepresentationsInDifferentLanguages <> Undefined Then
		
		TableNumber = 1;
		
		For Each Column In RepresentationsInDifferentLanguages.Attributes Do
			
			ColumnName = Column.Name;
			If StrCompare(ColumnName, "LanguageCode") = 0 Or StrStartsWith(ColumnName, "Delete") Then
				Continue;
			EndIf;
			
			ColumnNameLanguage = ColumnName + "Language1";
			If LanguagesInfo.Used.Language1
				And RequestFieldAttributes.Find(ColumnNameLanguage) = Undefined Then
				
				Joins = Joins + "
					|	LEFT JOIN &FullTableName.Presentations AS DifferentLanguages" + TableNumber + "
					|	On DifferentLanguages" + TableNumber + ".Ref = T.Ref
					|		AND DifferentLanguages" + TableNumber + ".LanguageCode = &LanguageCode1";
				PartsOfViewFields.Add("ISNULL(DifferentLanguages" + TableNumber + "." + ColumnName + ", """") AS " + ColumnNameLanguage);
				Query.SetParameter("LanguageCode1", LanguagesInfo.Language1);
				
				SynonymousNames.Insert(ColumnNameLanguage, Column.Synonym + StrTemplate(" (%1)", LanguagesInfo.Language1));
				Sidewall.Add(ColumnNameLanguage);
				AllAttributesAndValues.Insert(ColumnNameLanguage, New Map);
				
				TableNumber = TableNumber + 1;
			EndIf;
			
			ColumnNameLanguage = ColumnName + "Language2";
			If LanguagesInfo.Used.Language2
				And RequestFieldAttributes.Find(ColumnNameLanguage) = Undefined Then
				
				Joins = Joins + "
					|	LEFT JOIN &FullTableName.Presentations AS DifferentLanguages" + TableNumber + "
					|	On DifferentLanguages" + TableNumber + ".Ref = T.Ref
					|		AND DifferentLanguages" + TableNumber + ".LanguageCode = &LanguageCode2";
				PartsOfViewFields.Add("ISNULL(DifferentLanguages" + TableNumber + "." + ColumnName + ", """") AS " + ColumnNameLanguage);
				Query.SetParameter("LanguageCode2", LanguagesInfo.Language2);
				
				SynonymousNames.Insert(ColumnNameLanguage, Column.Synonym + StrTemplate(" (%1)", LanguagesInfo.Language2));
				Sidewall.Add(ColumnNameLanguage);
				AllAttributesAndValues.Insert(ColumnNameLanguage, New Map);
				
				TableNumber = TableNumber + 1;
			EndIf;
			
		EndDo;
		
		// Processing additional languages from the tabular part of the View
		RequestingLanguageCodes = New Query;
		QueryText=
		"SELECT DISTINCT
		|	Presentations.LanguageCode
		|FROM
		|	&FullTableName.Представления КАК Представления
		|ГДЕ
		|	НЕ Представления.КодЯзыка В (&ИспользуемыеКоды)";
		RequestingLanguageCodes.Text = StrReplace(QueryText, "&FullTableName", FullNameOfComparisonTable);
		
		CodesUsed = New Array;
		For Each Language In LanguagesInfo.Used Do
			LanguageCode = CommonClientServer.StructureProperty(LanguagesInfo, Language.Key, "");
			If LanguageCode <> "" Then
				CodesUsed.Add(LanguageCode);
			EndIf;
		EndDo;
		RequestingLanguageCodes.SetParameter("CodesUsed", CodesUsed);
		Selection = RequestingLanguageCodes.Execute().Select();
		
		LanguageCodeNumber = LanguagesInfo.AdditionalLanguagesCount + 1;
		While Selection.Next() Do
			For Each Column In RepresentationsInDifferentLanguages.Attributes Do
				
				ColumnName = Column.Name;
				If StrCompare(ColumnName, "LanguageCode") = 0 Or StrStartsWith(ColumnName, "Delete") Then
					Continue;
				EndIf;
				
				ColumnNameLanguage = ColumnName + Selection.LanguageCode;
				Joins = Joins + "
					|	LEFT JOIN &FullTableName.Presentations AS DifferentLanguages" + TableNumber + "
					|	On DifferentLanguages" + TableNumber + ".Ref = T.Ref
					|		AND DifferentLanguages" + TableNumber + ".LanguageCode = &LanguageCode" + LanguageCodeNumber;
				PartsOfViewFields.Add("ISNULL(DifferentLanguages" + TableNumber + "." + ColumnName + ", """") AS " + ColumnNameLanguage);
				Query.SetParameter("LanguageCode" + LanguageCodeNumber, Selection.LanguageCode);
				
				SynonymousNames.Insert(ColumnNameLanguage, Column.Synonym + StrTemplate(" (%1)", Selection.LanguageCode));
				Sidewall.Add(ColumnNameLanguage);
				AllAttributesAndValues.Insert(ColumnNameLanguage, New Map);
				
				TableNumber = TableNumber + 1;
				LanguageCodeNumber = LanguageCodeNumber + 1;
			EndDo;
		EndDo;
		
	EndIf;
	
	If PartsOfViewFields.Count() Then
		PresentationFields = StrConcat(PartsOfViewFields, "," + Chars.LF + Chars.Tab);
	Else
		PresentationFields = "";
	EndIf;
	
	QueryText =
	"SELECT
	|	&QueryFields,
	|	&PresentationFields
	|FROM
	|	&FullTableName AS T
	|" + Joins + "
	|WHERE
	|	T.Ref IN(&FilterByRefs)";
	
	If ValueIsFilled(PresentationFields) Then
		QueryText = StrReplace(QueryText, "&PresentationFields", PresentationFields);
	Else
		QueryText = StrReplace(QueryText, "&QueryFields,", "&QueryFields");
		QueryText = StrReplace(QueryText, "&PresentationFields", "");
	EndIf;
	
	QueryFields = "T." + StrConcat(RequestFieldAttributes, "," + Chars.LF + Chars.Tab + "T.");
	QueryText = StrReplace(QueryText, "&QueryFields", QueryFields);
	
	QueryText = StrReplace(QueryText, "&FullTableName", FullNameOfComparisonTable);
	
	Query.Text = QueryText;
	DuplicatesSorted = DuplicatesSorted(Duplicates);
	Query.SetParameter("FilterByRefs", DuplicatesSorted.UnloadColumn("Duplicate1"));
	QueryResult = Query.Execute();
	
	AddContextToMainTable(ReportGenerationContext, QueryResult, MetadataObject);
	
	// Linked table (subordinate Catalog)
	RelatedObjects = SearchAndReplaceDuplicatesMasterData.RelatedObjects();
	SearchAndReplaceDuplicatesMasterDataOverridable.WhenDefiningRelatedObjects(RelatedObjects);
	ObjectsLinks = SearchAndReplaceDuplicatesMasterData.ObjectsLinks();
	
	For Each LinkRow In RelatedObjects Do
		AddObjectRelationships(ObjectsLinks, LinkRow);
	EndDo;
	
	TypeOfCommunicationDetails = TypeOf(Common.ObjectAttributeValue(IdOfDuplicates, "EmptyRefValue"));
	UsedLinks = ObjectsLinks.FindRows(New Structure("AttributeType", TypeOfCommunicationDetails));
	
	If UsedLinks.Count() > 1 Then
		ErrorText = NStr("vi = 'Không thể lập báo cáo về so sánh. Hãy liên hệ với người quản trị.';
						|ru = 'Невозможно сформировать отчет о сравнении. Обратитесь к администратору.';
						|en = 'Cannot generate a comparison report. Contact the administrator.'; fa = 'Cannot generate a comparison report. Contact the administrator.';
						|it = 'Cannot generate a comparison report. Contact the administrator.';
						|pl = 'Cannot generate a comparison report. Contact the administrator.';
						|tr = 'Karşılaştırma raporu oluşturulamıyor. Lütfen yöneticiye başvurun.'");
		MethodName = "SearchAndReplaceDuplicatesMasterDataOverridable.WhenDefiningRelatedObjects";
		ForAdministrator = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Lỗi trong chỉ định liên kết: đã chỉ định một số mục tin để liên kết danh mục trực thuộc. Hãy kiểm tra mức độ đúng đắn điền liên kết trong phương thức %1.';
				|ru = 'Ошибка в указании связей: для связи подчиненного справочника указано несколько реквизитов. Проверьте корректность заполнения связей в методе %1.';
				|en = 'Error in specifying the links: several attributes are specified for the subordinate catalog link. Check that the links in the ""%1"" method are filled in correctly.'; fa = 'Error in specifying the links: several attributes are specified for the subordinate catalog link. Check that the links in the ""%1"" method are filled in correctly.';
				|it = 'Error in specifying the links: several attributes are specified for the subordinate catalog link. Check that the links in the ""%1"" method are filled in correctly.';
				|pl = 'Error in specifying the links: several attributes are specified for the subordinate catalog link. Check that the links in the ""%1"" method are filled in correctly.';
				|tr = 'Bağlantıların belirtilmesinde hata: Alt katalog bağlantısı için birden fazla öznitelik belirtilmiş. %1 yönteminde bağlantıların doğru doldurulduğunu kontrol edin.'"),
				MethodName);
		Raise(ErrorText, , , ForAdministrator);
	EndIf;
	
	If UsedLinks.Count() Then
		
		FullNameOfAdditionalTable = UsedLinks[0].Key;
		LinksField = UsedLinks[0].AttributeName;
		MetadataObject = UsedLinks[0].Metadata;
		
		AttributesOfLinkedRequestField = RequestFieldAttributes(MetadataObject, ReportGenerationContext, LanguagesInfo);
		ExcludeServiceDetails(AttributesOfLinkedRequestField, MetadataObject, ReportGenerationContext);
		
		Query = New Query;
		QueryText =
		"SELECT
		|	&AdditionalTableQueryFields
		|FROM
		|	&FullNameOfAdditionalTable AS T
		|WHERE
		|	&LinksField IN(&SelectionByFieldOfCommunication)
		|TOTALS BY
		|	&LinkFieldTotal";
		
		QueryFields = StrConcat(AttributesOfLinkedRequestField, "," + Chars.LF + Chars.Tab);
		
		QueryText = StrReplace(QueryText, "&AdditionalTableQueryFields", QueryFields);
		QueryText = StrReplace(QueryText, "&FullNameOfAdditionalTable", FullNameOfAdditionalTable);
		QueryText = StrReplace(QueryText, "&LinkFieldTotal", LinksField);
		QueryText = StrReplace(QueryText, "&LinksField", "T." + LinksField);
		Query.Text = QueryText;
		Query.SetParameter("SelectionByFieldOfCommunication", DuplicatesSorted);
		
		QueryResult = Query.Execute();
		AddContextToLinkedTable(ReportGenerationContext, QueryResult, MetadataObject, LinksField);
		
	EndIf;
	
	// Marking duplicate Attributes for highlighting in the report
	Sidewall.FillChecks(True);
	TotalTakes = DuplicatesSorted.Count();
	For Each ListItem In Sidewall Do
		AttributeName = ListItem.Value;
		
		Repeats = AllAttributesAndValues[AttributeName];
		If Repeats = Undefined Then
			Continue;
		EndIf;
		
		For Each Repeat In Repeats Do
			
			RepeatableValue = Repeat.Key;
			RepeatCount = Repeat.Value;
			
			For Each AttributeToReport In AttributesToReport Do
				If AttributeToReport.Value[AttributeName] <> Undefined
					And AttributeToReport.Value[AttributeName].AttributeValue = RepeatableValue Then
						
					AttributeToReport.Value[AttributeName].ValueIsRepeated = (RepeatCount > 1);
				EndIf;
			EndDo;
			
			If RepeatCount = TotalTakes Then
				ListItem.Check = False;
			EndIf;
			
		EndDo;
	EndDo;
	
	ReportGenerationData = New Structure;
	ReportGenerationData.Insert("Sidewall", PrepareSidewall(Sidewall, ComparisonOption));
	ReportGenerationData.Insert("SynonymousNames", SynonymousNames);
	ReportGenerationData.Insert("AttributesToReport", AttributesToReport);
	ReportGenerationData.Insert("TabularPartsInReport", TabularPartsInReport);
	ReportGenerationData.Insert("DuplicatesSorted", DuplicatesSorted);
	
	Return PrepareReport(ReportGenerationData);
	
EndFunction

// Creates and returns a structure with auxiliary indexes for data processing and report construction.
// The index report is based on "Double, Attribute name" and contains the Attribute value and a sign that the value is repeated.
// The index tabular report is based on the "Name of the tabular part, Double", contains the tabular part of the double.
// All Session values The index is based on the "Attribute name, Attribute value", contains the number of repetitions of values.
// The return value describes the final index filling structure.
//
// Returns:
//   Structure:
//      *AttributesToReport - Map of KeyAndValue:
//         **Key - AnyRef - link to the double.
//         **Value - Map of KeyAndValue:
//            ***Key - String - name of the prop.
//            ***Value - Structure of KeyAndValue:
//               ****AttributeValue - Undefined - the value of the props.
//               ****ValueIsRepeated - Boolean - indicates whether the Attribute value is repeated among duplicates.
//
//      *TabularPartsInReport - Map of KeyAndValue:
//         **Key - String - name of the table part.
//         **Value - Map of KeyAndValue:
//            ***Key - AnyRef - link to the double.
//            ***Value - ValueTable - The tabular part.
//   
//      *AllAttributesAndValues - Map of KeyAndValue:
//         **Key - String - name of the prop.
//         **Value - Map of KeyAndValue:
//            ***Key - Undefined - the value of the props.
//            ***Value - Number - the number of repetitions of the Attribute value among duplicates.
//
Function IndexesForBuildingReport()
	
	AttributesToReport = New Map;
	TabularPartsInReport = New Map;
	AllAttributesAndValues = New Map;
	
	Indexes = New Structure;
	Indexes.Insert("AttributesToReport", AttributesToReport);
	Indexes.Insert("TabularPartsInReport", TabularPartsInReport);
	Indexes.Insert("AllAttributesAndValues", AllAttributesAndValues);
	
	Return Indexes;
	
EndFunction

// Returns a table for describing the location of additional Attributes that are stored in table parts.
//
// Returns:
//   ValueTable:
//      *TabularSectionName - String - the name of the table part that is described as the Attribute.
//      *ColumnProps - String - the name of the column in the table part containing the Attribute name.
//      *ValueColumn_ - String - the name of the column in the table part containing the Attribute value.
//
Function AdditionalAttributes()
	
	StringType = Common.StringTypeDetails(150);
	
	Result = New ValueTable;
	Result.Columns.Add("TabularSectionName", StringType);
	Result.Columns.Add("ColumnProps", StringType);
	Result.Columns.Add("ValueColumn_", StringType);
	
	Return Result;
	
EndFunction
	
// Parameters:
//   AdditionalAttributes - SeeAdditionalAttributes
//
// Returns:
//   Map of KeyAndValue
//
Function ConvertTableToMatch(AdditionalAttributes)
	
	Result = New Map;
	
	AdditionalAttributes.Sort("TabularSectionName");
	For Each String In AdditionalAttributes Do
		
		TabularSectionName = String.TabularSectionName;
		ColumnProps = String.ColumnProps;
		ValueColumn_ = String.ValueColumn_;
		
		If Not ValueIsFilled(TabularSectionName)
			Or Not ValueIsFilled(ColumnProps)
			Or Not ValueIsFilled(ValueColumn_) Then
			Continue;
		EndIf;
		
		Result.Insert(TabularSectionName,
			New Structure("AttributeName,AttributeValue", ColumnProps, ValueColumn_));
		
	EndDo;
	
	Return Result;
	
EndFunction

Function RequestFieldAttributes(MetadataObject, ReportGenerationContext, LanguagesInfo)
	
	Result = New Array;
	
	Sidewall = ReportGenerationContext.Sidewall;
	SynonymousNames = ReportGenerationContext.SynonymousNames;
	TabularPartsInReport = ReportGenerationContext.Indexes.TabularPartsInReport;
	AllAttributesAndValues = ReportGenerationContext.Indexes.AllAttributesAndValues;
	AdditionalAttributes = ReportGenerationContext.AdditionalAttributes;
	
	For Each Attribute In MetadataObject.StandardAttributes Do
		Result.Add(Attribute.Name);
		SynonymousNames.Insert(Attribute.Name,
			?(ValueIsFilled(Attribute.Synonym), Attribute.Synonym, Attribute.Name));
	EndDo;
	
	For Each Attribute In MetadataObject.Attributes Do
		Result.Add(Attribute.Name);
		SynonymousNames.Insert(Attribute.Name,
			?(ValueIsFilled(Attribute.Synonym), Attribute.Synonym, Attribute.Name));
	EndDo;
	
	UsedLanguage1 = LanguagesInfo.Used.Language1;
	UsedLanguage2 = LanguagesInfo.Used.Language2;
	
	For Each Attribute In Metadata.CommonAttributes Do
		CommonAttributeContentItem = Attribute.Content.Find(MetadataObject);
		If CommonAttributeContentItem.Use = Metadata.ObjectProperties.CommonAttributeUse.Use Then
			
			AttributeName = Attribute.Name;
			If AttributeName = "DescriptionLanguage1" And UsedLanguage1 Then
				Result.Add(AttributeName);
				SynonymousNames.Insert(AttributeName, StrTemplate(NStr("vi = 'Tên gọi (%1)';
																		|ru = 'Наименование (%1)';
																		|en = 'Name (%1)'; fa = 'Name (%1)';
																		|it = 'Name (%1)';
																		|pl = 'Name (%1)';
																		|tr = 'Name (%1)'"), LanguagesInfo.Language1));
				
			ElsIf AttributeName = "DescriptionLanguage2" And UsedLanguage2 Then
				Result.Add(AttributeName);
				SynonymousNames.Insert(AttributeName, StrTemplate(NStr("vi = 'Tên gọi (%1)';
																		|ru = 'Наименование (%1)';
																		|en = 'Name (%1)'; fa = 'Name (%1)';
																		|it = 'Name (%1)';
																		|pl = 'Name (%1)';
																		|tr = 'Name (%1)'"), LanguagesInfo.Language2));
				
			ElsIf AttributeName = "CommentLanguage1" And UsedLanguage1 Then
				Result.Add(AttributeName);
				SynonymousNames.Insert(AttributeName, StrTemplate(NStr("vi = 'Ghi chú (%1)';
																		|ru = 'Комментарий (%1)';
																		|en = 'Comment (%1)'; fa = 'Comment (%1)';
																		|it = 'Comment (%1)';
																		|pl = 'Comment (%1)';
																		|tr = 'Comment (%1)'"), LanguagesInfo.Language1));
				
			ElsIf AttributeName = "CommentLanguage2" And UsedLanguage2 Then
				Result.Add(AttributeName);
				SynonymousNames.Insert(AttributeName, StrTemplate(NStr("vi = 'Ghi chú (%1)';
																		|ru = 'Комментарий (%1)';
																		|en = 'Comment (%1)'; fa = 'Comment (%1)';
																		|it = 'Comment (%1)';
																		|pl = 'Comment (%1)';
																		|tr = 'Comment (%1)'"), LanguagesInfo.Language2));
				
			EndIf;
			
		EndIf;
	EndDo;
	
	For Each Attribute In Result Do
		Sidewall.Add(Attribute);
	EndDo;
	
	For Each TabularSection In MetadataObject.TabularSections Do
		Result.Add(TabularSection.Name);
		
		If AdditionalAttributes[TabularSection.Name] = Undefined Then
			TabularPartsInReport.Insert(TabularSection.Name, Value_IsEmpty());
			SynonymousNames.Insert(TabularSection.Name, TabularSection.Synonym);
		EndIf;
	EndDo;
	
	For Each AttributeName In Result Do
		AllAttributesAndValues.Insert(AttributeName, New Map);
	EndDo;
		
	Return Result;
	
EndFunction

Procedure ExcludeServiceDetails(RequestFieldAttributes, MetadataObject, ReportGenerationContext)
	
	AttributesExceptions = AttributesExceptions(MetadataObject); 
	Sidewall = ReportGenerationContext.Sidewall;
	SynonymousNames = ReportGenerationContext.SynonymousNames;
	
	For Each Item In AttributesExceptions Do
		Candidate = RequestFieldAttributes.Find(Item);
		
		If Candidate <> Undefined Then
			RequestFieldAttributes.Delete(Candidate);
			
			IndexOf = Sidewall.FindByValue(SynonymousNames[Item]);
			If IndexOf <> Undefined Then
				Sidewall.Delete(IndexOf);
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

Function AttributesExceptions(MetadataObject, TabularSectionName = Undefined)
	
	AttributesExceptions = SearchAndReplaceDuplicatesMasterData.ExceptionsToComparisonDetails();
	SearchAndReplaceDuplicatesMasterDataOverridable.WhenDefiningExceptionsOfDetails(AttributesExceptions);
	
	If TabularSectionName = Undefined Then
		Filter = New Structure("Metadata,TabularSectionName", MetadataObject, "");
	Else
		Filter = New Structure("Metadata,TabularSectionName", MetadataObject, TabularSectionName);
	EndIf;
	Result = AttributesExceptions.Copy(Filter, "AttributeName").UnloadColumn(0);
	
	Return Result;
	
EndFunction

Procedure RaiseDetailsToTopOfList(Sidewall)
	
	AttributesInReverseOrder = "Description,Code,Ref";
	
	For Each AttributeName In StrSplit(AttributesInReverseOrder, ",", False) Do
		AttributeIndex = Sidewall.FindByValue(AttributeName);
		
		If AttributeIndex <> Undefined Then
			Sidewall.Delete(AttributeIndex);
			Sidewall.Insert(0, AttributeName);
		EndIf;
	EndDo;
	
EndProcedure

Function DuplicatesSorted(Duplicates)
	
	Result = New ValueTable;
	Result.Columns.Add("Duplicate1");
	Result.Columns.Add("Order");
	Result.Columns.Add("Status");
	Result.Columns.Add("UsageInstancesCount");
	
	OrderOfStatuses = New Map;
	OrderOfStatuses.Insert(SearchAndReplaceDuplicatesMasterDataClientServer.StatusOriginal(), 1);
	OrderOfStatuses.Insert(SearchAndReplaceDuplicatesMasterDataClientServer.StatusConfirmationRequired(), 2);
	OrderOfStatuses.Insert(SearchAndReplaceDuplicatesMasterDataClientServer.StatusIsNotDouble(), 3);
	OrderOfStatuses.Insert(SearchAndReplaceDuplicatesMasterDataClientServer.StatusDoubleReplace(), 4);
	OrderOfStatuses.Insert(SearchAndReplaceDuplicatesMasterDataClientServer.DoNotDeleteDoubleStatus(), 5);
	
	For Each String In Duplicates Do
		If Not String.Check Then
			Continue;
		EndIf;
		
		NewRow = Result.Add();
		FillPropertyValues(NewRow, String);
		NewRow.Order = OrderOfStatuses[String.Status];
	EndDo;
	
	Result.Sort("Order");
	Return Result;
	
EndFunction

Procedure AddContextToMainTable(ReportGenerationContext, QueryResult, MetadataObject)
	
	Indexes = ReportGenerationContext.Indexes;
	AttributesToReport = Indexes.AttributesToReport;
	TabularPartsInReport = ReportGenerationContext.Indexes.TabularPartsInReport;
	AdditionalAttributes = ReportGenerationContext.AdditionalAttributes;
	
	RequestColumns = QueryResult.Columns;
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		AttributesToReport.Insert(Selection.Ref, New Map);
		
		For Each Column In RequestColumns Do
			ColumnName = Column.Name;
			
			If AdditionalAttributes[ColumnName] <> Undefined Then
				AddIndexesForTabularPart(ReportGenerationContext, Selection, ColumnName, "Ref");
				
			ElsIf TabularPartsInReport[ColumnName] <> Undefined Then
				AddContextToTableParts(TabularPartsInReport, MetadataObject, Selection, ColumnName);
				
			Else
				AddIndexesByLine(Indexes, Selection.Ref, ColumnName, Selection[ColumnName]);
				
			EndIf;
			
		EndDo;
	EndDo;
	
EndProcedure

Procedure AddContextToLinkedTable(ReportGenerationContext, QueryResult, MetadataObject, LinksField)
	
	Indexes = ReportGenerationContext.Indexes;
	TabularPartsInReport = Indexes.TabularPartsInReport;
	AdditionalAttributes = ReportGenerationContext.AdditionalAttributes;
	
	RequestColumns = QueryResult.Columns;
	SelectionGroupingByLinkField = QueryResult.Select(QueryResultIteration.ByGroups);
	
	While SelectionGroupingByLinkField.Next() Do
		
		Selection = SelectionGroupingByLinkField.Select();
		
		If Selection.Next() Then
			LinkRelated = Selection.Ref;
			
			For Each Column In RequestColumns Do
				ColumnName = Column.Name;
				If ColumnName = LinksField Then
					Continue;
				EndIf;
				
				If AdditionalAttributes[ColumnName] <> Undefined Then
					AddIndexesForTabularPart(ReportGenerationContext, Selection, ColumnName, LinksField);
					
				ElsIf TabularPartsInReport[ColumnName] <> Undefined Then
					AddContextToTableParts(TabularPartsInReport, MetadataObject, Selection, ColumnName);
					
				Else
					AddIndexesByLine(Indexes, Selection[LinksField], ColumnName, Selection[ColumnName]);
					
				EndIf;
			EndDo;
			
			MainLink = SelectionGroupingByLinkField[LinksField];
			LinkRelated = Selection.Ref;
			ReplaceOwnerOfTablePart(TabularPartsInReport, MainLink, LinkRelated);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure AddContextToTableParts(TabularPartsInReport, MetadataObject, Selection, ColumnName)
	
	TabularSection = Selection[ColumnName].Unload(); //ValueTable
	If Not TabularSection.Count() Then
		Return;
	EndIf;
	
	AttributesExceptions = AttributesExceptions(MetadataObject, ColumnName);
	CommonClientServer.SupplementArray(
		AttributesExceptions, CommonClientServer.ValueInArray("Ref"), True);
	ColumnsNames = New Array;
	
	For Each Column In TabularSection.Columns Do
		If AttributesExceptions.Find(Column.Name) = Undefined Then
			ColumnsNames.Add(Column.Name);
		EndIf;
	EndDo;
	
	If TabularPartsInReport[ColumnName] = Value_IsEmpty() Then
		TabularPartsInReport[ColumnName] = New Map;
	EndIf;
	
	TabularSection = TabularSection.Copy(, StrConcat(ColumnsNames, ","));
	TabularPartsInReport[ColumnName].Insert(Selection.Ref, TabularSection);
	
EndProcedure

Procedure ReplaceOwnerOfTablePart(TabularPartsInReport, MainLink, LinkRelated)
	
	For Each TabularSection In TabularPartsInReport Do
		If TabularSection.Value = Value_IsEmpty() Then
			Continue;
		EndIf;
		
		For Each ReferencesAndTableParts In TabularSection.Value Do
			
			If ReferencesAndTableParts.Key = LinkRelated Then
				TabularSection.Value.Insert(MainLink, ReferencesAndTableParts.Value);
				TabularSection.Value.Delete(LinkRelated);
			EndIf;
			
		EndDo;
	EndDo;
	
EndProcedure

Procedure AddIndexesForTabularPart(ReportGenerationContext, Selection, TabularSectionName, TabularSectionColumnName)
	
	Indexes = ReportGenerationContext.Indexes;
	AdditionalAttributes = ReportGenerationContext.AdditionalAttributes;
	SynonymousNames = ReportGenerationContext.SynonymousNames;
	Sidewall = ReportGenerationContext.Sidewall;
	
	AllAttributesAndValues = Indexes.AllAttributesAndValues;
	
	ResultOfTSQuery  = Selection[TabularSectionName]; //QueryResult
	TSSampling = ResultOfTSQuery.Select();
	While TSSampling.Next() Do
		
		StoringAttributeName = AdditionalAttributes[TabularSectionName].AttributeName;
		StoringAttributeValue = AdditionalAttributes[TabularSectionName].AttributeValue;
		
		AttributeName = TSSampling[StoringAttributeName];
		If AllAttributesAndValues[AttributeName] = Undefined Then
			AllAttributesAndValues.Insert(AttributeName, New Map);
		EndIf;
		
		AddIndexesByLine(
			Indexes, Selection[TabularSectionColumnName], AttributeName, TSSampling[StoringAttributeValue]);
		
		ListItem = Sidewall.FindByValue(AttributeName);
		If ListItem = Undefined Then
			Sidewall.Add(AttributeName);
		EndIf;
		
		SynonymousNames.Insert(AttributeName, AttributeName);
		
	EndDo;
	
EndProcedure

Procedure AddIndexesByLine(Indexes, Ref, AttributeName, AttributeValue)
	
	ValueAndQuantity = Indexes.AllAttributesAndValues[AttributeName];
	If ValueAndQuantity[AttributeValue] = Undefined Then
		ValueAndQuantity.Insert(AttributeValue, 0);
	EndIf;
	ValueAndQuantity[AttributeValue] = ValueAndQuantity[AttributeValue] + 1;
	
	RepetitionsOfAttributeValues = Indexes.AttributesToReport[Ref];
	If RepetitionsOfAttributeValues[AttributeName] = Undefined
		Or Not ValueIsFilled(RepetitionsOfAttributeValues[AttributeName]) Then
		
		RepetitionsOfAttributeValues.Insert(AttributeName, New Structure("ValueIsRepeated,AttributeValue", False));
		RepetitionsOfAttributeValues[AttributeName].AttributeValue = AttributeValue;
	EndIf;
	
EndProcedure

Procedure AddObjectRelationships(ObjectsLinks, LinkRow)
	
	AttributeName = LinkRow.LinksField;
	NameOfLinkedObject = LinkRow.LinkedObject.FullName();
	ObjectMetadata = LinkRow.LinkedObject;
	
	If CommonClientServer.HasAttributeOrObjectProperty(ObjectMetadata.StandardAttributes, AttributeName) Then
		AttributesCollection = ObjectMetadata.StandardAttributes;
	ElsIf CommonClientServer.HasAttributeOrObjectProperty(ObjectMetadata.Attributes, AttributeName) Then
		AttributesCollection = ObjectMetadata.Attributes;
	Else
		ErrorText = NStr("vi = 'Không thể lập báo cáo về so sánh. Hãy liên hệ với người quản trị.';
						|ru = 'Невозможно сформировать отчет о сравнении. Обратитесь к администратору.';
						|en = 'Cannot generate a comparison report. Contact the administrator.'; fa = 'Cannot generate a comparison report. Contact the administrator.';
						|it = 'Cannot generate a comparison report. Contact the administrator.';
						|pl = 'Cannot generate a comparison report. Contact the administrator.';
						|tr = 'Karşılaştırma raporu oluşturulamıyor. Lütfen yöneticiye başvurun.'");
		MethodName = "SearchAndReplaceDuplicatesMasterDataOverridable.WhenDefiningRelatedObjects"; 
		ForAdministrator = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không tồn tại trường liên kết %1 trong đối tượng metadata %2. Cần mô tả liên kết trong phương thức %2.';
				|ru = 'Не существует поле связи %1 в объекте метаданных %2. Связи должны быть описаны в методе %3.';
				|en = 'The ""%1"" link field does not exist in the ""%2"" metadata object. The links must be described in the %3 method.'; fa = 'The ""%1"" link field does not exist in the ""%2"" metadata object. The links must be described in the %3 method.';
				|it = 'The ""%1"" link field does not exist in the ""%2"" metadata object. The links must be described in the %3 method.';
				|pl = 'The ""%1"" link field does not exist in the ""%2"" metadata object. The links must be described in the %3 method.';
				|tr = '%2 meta veri nesnesinde %1 bağlantı alanı mevcut değil. Bağlantılar %3 yönteminde açıklanmalıdır.'"),
			AttributeName, NameOfLinkedObject, MethodName);
			
		Raise(ErrorText, , , ForAdministrator);
	EndIf;
	
	AttributeTypes = AttributesCollection[AttributeName].Type;
	For Each AttributeType In AttributeTypes.Types() Do
		Record = ObjectsLinks.Add();
		Record.Key = NameOfLinkedObject;
		Record.AttributeType = AttributeType;
		Record.AttributeName = AttributeName;
		Record.Metadata = ObjectMetadata;
	EndDo;
	
EndProcedure

Function PrepareSidewall(Val Sidewall, ComparisonOption)
	
	Result = New ValueList;
	AddItemsByTag(Sidewall, Result, True);
	If ComparisonOption = "All" Then
		AddItemsByTag(Sidewall, Result, False);
	EndIf;
	Return Result;
	
EndFunction

Procedure AddItemsByTag(List, Result, Check)
	
	For Each ListItem In List Do
		If ListItem.Check = Check Then
			FillPropertyValues(Result.Add(), ListItem);
		EndIf;
	EndDo;
	
EndProcedure

#Region ReportOutput

Function PrepareReport(ReportGenerationData)
	
	Sidewall = ReportGenerationData.Sidewall;
	SynonymousNames = ReportGenerationData.SynonymousNames;
	AttributesToReport = ReportGenerationData.AttributesToReport;
	TabularPartsInReport = ReportGenerationData.TabularPartsInReport;
	DuplicatesSorted = ReportGenerationData.DuplicatesSorted;
	
	Result = New SpreadsheetDocument;
	Template = DataProcessors.MasterDataDuplicates.GetTemplate("ComparisonReportTemplate");
	
	ResultContext = New Structure;
	ResultContext.Insert("Result", Result);
	ResultContext.Insert("Template", Template);
	
	// Title
	AddText(ResultContext, "Title", "Put", NStr("vi = 'Mục tin';
												|ru = 'Реквизиты';
												|en = 'Attributes'; fa = 'ویژگی‌ها';
												|it = 'Attributes';
												|pl = 'Attributes';
												|tr = 'Öznitelikler'"));
	AddText(ResultContext, "IsBlankString", "Put");
	
	// Interactive block
	AddText(ResultContext, "StatusFirstColumn", "Put", NStr("vi = 'Trạng thái';
															|ru = 'Статус';
															|en = 'Status'; fa = 'وضعیت';
															|it = 'Status';
															|pl = 'Status';
															|tr = 'Durum'"));
	
	OffsetOfColumn = 3;
	StringOffset = 3;
	For Each String In DuplicatesSorted Do
		Details = New Structure;
		Details.Insert("DecryptionOfStatus");
		Details.Insert("RowNum", StringOffset);
		Details.Insert("ColumnNumber", DuplicatesSorted.IndexOf(String) + OffsetOfColumn);
		Details.Insert("Duplicate1", String.Duplicate1);
		
		AddValue(ResultContext, "StatusNextColumn", "Join", String.Status, Details);
	EndDo;
	
	AddText(ResultContext, "PlacesOfUseFirstColumn", "Put", NStr("vi = 'Nơi sử dụng';
																|ru = 'Мест использования';
																|en = 'Occurrences'; fa = 'موارد یافت‌شده';
																|it = 'Luoghi di utilizzo';
																|pl = 'Miejsc wykorzystywania';
																|tr = 'Kullanım yerleri'"));
	
	For Each String In DuplicatesSorted Do
		Details = New Structure;
		Details.Insert("DecodingPlacesOfUse");
		Details.Insert("Duplicate1", String.Duplicate1);
		
		If ValueIsFilled(String.UsageInstancesCount) Then
			UsageInstances = String.UsageInstancesCount;
		Else
			UsageInstances = NStr("vi = 'Nơi sử dụng';
									|ru = 'Места использования';
									|en = 'Occurrences'; fa = 'موارد یافت‌شده';
									|it = 'Luoghi di utilizzo';
									|pl = 'Miejsca wykorzystywania';
									|tr = 'Kullanım yerleri'");
		EndIf;
		
		AddValue(ResultContext, "PlacesOfUseSubsequentColumn", "Join", UsageInstances, Details);
	EndDo;
	
	AddText(ResultContext, "IsBlankString", "Put");
	
	// Attributes 
	FirstRow = True;
	For Each ListItem In Sidewall Do
		
		AttributeName = ListItem.Value;
		
		If FirstRow Then
			AddText(ResultContext, "HeaderFirstColumn", "Put", NStr("vi = 'Mục tin';
																	|ru = 'Реквизит';
																	|en = 'Attribute'; fa = 'ویژگی';
																	|it = 'Attribute';
																	|pl = 'Attribute';
																	|tr = 'Öznitelik'"));
			Result.StartRowGroup();
		Else
			If ListItem.Check Then
				AddText(ResultContext, "CellFirstColumn", "Put", SynonymousNames[AttributeName]);
			Else
				AddText(ResultContext, "CellIsFirstRepeatingColumn", "Put", SynonymousNames[AttributeName]);
			EndIf;
		EndIf;
		
		For Each String In DuplicatesSorted Do
			DuplicateData = AttributesToReport[String.Duplicate1][AttributeName];
			If DuplicateData = Undefined Then
				AddText(ResultContext, "CellNextColumn", "Join");
				Continue;
			EndIf;
			
			AttributeValue = DuplicateData.AttributeValue;
			
			If FirstRow Then
				AddValue(ResultContext, "HeaderNextColumn", "Join", AttributeValue, AttributeValue);
			Else
				If DuplicateData.ValueIsRepeated Then
					AddText(ResultContext, "CellIsSubsequentRepeatingColumn", "Join", AttributeValue);
				Else
					AddValue(ResultContext, "CellNextColumn", "Join", AttributeValue, AttributeValue);
				EndIf;
			EndIf;
		EndDo;
		
		FirstRow = False;
		
	EndDo;
	
	Result.EndRowGroup();
	
	// Table parts
	For Each TabularSectionData In TabularPartsInReport Do
		
		If TabularSectionData.Value = Value_IsEmpty() Then 
			Continue;
		EndIf;
		
		AddText(ResultContext, "IsBlankString", "Put");
		AddText(ResultContext, "Title", "Put", SynonymousNames[TabularSectionData.Key]);
		
		Result.StartRowGroup();
		
		For Each String In DuplicatesSorted Do
			
			TabularSection = TabularSectionData.Value[String.Duplicate1];
			If TabularSection = Undefined Then
				Continue;
			EndIf;
			
			AddText(ResultContext, "IsBlankString", "Put");
			AddText(ResultContext, "TitleOfTablePart", "Put", String(String.Duplicate1));
			
			// Header of the table part
			FirstColumn = True;
			For Each Column In TabularSection.Columns Do
				If FirstColumn Then
					AddText(ResultContext, "TSHeaderIsFirstColumn", "Put");
					FirstColumn = False;
				Else
					AddText(ResultContext, "TSHeaderIsNextColumn", "Join", Column.Name);
				EndIf;
			EndDo;
			
			// Table part rows
			For Each TSRow In TabularSection Do 
				FirstColumn = True;
				
				For Each Column In TabularSection.Columns Do
					If FirstColumn Then
						AddText(ResultContext, "TSCellIsFirstColumn", "Put", TSRow[Column.Name]);
						FirstColumn = False;
					Else
						AddText(ResultContext, "TSCellIsNextColumn", "Join", TSRow[Column.Name]);
					EndIf;
				EndDo;
			EndDo;
			
		EndDo;
		
		Result.EndRowGroup();
		
	EndDo;
	
	Result.FixedLeft = OffsetOfColumn - 1;
	Result.FixedTop = StringOffset + 3;
	
	Return Result;
	
EndFunction

Procedure AddText(ResultContext, AreaName, OutputMethod, Text = Undefined)
	
	Area = ResultContext.Template.GetArea(AreaName);
	If Text <> Undefined Then
		Area.CurrentArea.Text = Text;
	EndIf;
	OutputArea(ResultContext, Area, OutputMethod);
	
EndProcedure

Procedure AddValue(ResultContext, AreaName, OutputMethod, Value, Details = Undefined)
	
	Area = ResultContext.Template.GetArea(AreaName);
	Area.CurrentArea.Value = Value;
	If Not IsPrimitiveTypeValue(Details) Then
		Area.CurrentArea.Details = Details;
	EndIf;
	OutputArea(ResultContext, Area, OutputMethod);
	
EndProcedure

Procedure OutputArea(ResultContext, Area, OutputMethod)
	
	If OutputMethod = "Put" Then
		ResultContext.Result.Put(Area);
	ElsIf OutputMethod = "Join" Then
		ResultContext.Result.Join(Area);
	EndIf;
	
EndProcedure

// Checks whether the passed value is of a primitive type.
//
// Parameters:
//   Value - Arbitrary - The value being checked
//
// Returns:
//   Boolean - True if the value has a primitive type, otherwise False
//
Function IsPrimitiveTypeValue(Value)
	
	TypeToCheck = TypeOf(Value);
	
	If TypeToCheck = Type("Undefined")
		Or TypeToCheck = Type("Boolean")
		Or TypeToCheck = Type("String")
		Or TypeToCheck = Type("Number")
		Or TypeToCheck = Type("Date")
		Or TypeToCheck = Type("UUID") Then
		
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

#EndRegion

Function Value_IsEmpty()
	Return "IsEmpty";
EndFunction

#EndRegion

#Region ConfirmationOfDuplicates

// Parameters:
//  Duplicates - ValueTable
//  RefType - CatalogRef.MetadataObjectIDs
//  WithVerification - Boolean
// 
// Returns:
//  Structure - Confirm Duplicates:
// * ConfirmationIsPossible - Boolean
// * StatusSelectionErrors - ValueTable:
//   ** ErrorText - String
//   ** Field - String - path to the form element to link the view to.
// * TextOfWarningAboutRepeatedSearch - String
// * TextOfNonconformityWarning - String
//
Function ConfirmDuplicates(Duplicates, RefType, WithVerification = True) Export
	
	Result = New Structure;
	Result.Insert("ConfirmationIsPossible", True);
	Errors = New ValueTable;
	Errors.Columns.Add("ErrorText", New TypeDescription("String"));
	Errors.Columns.Add("Field", New TypeDescription("String"));
	Result.Insert("StatusSelectionErrors", Errors);
	Result.Insert("TextOfWarningAboutRepeatedSearch", "");
	Result.Insert("TextOfNonconformityWarning", "");
	
	VerifyAuthenticityOfDuplicates(Duplicates, Result);
	If Not Result.ConfirmationIsPossible Then
		Return Result;
	EndIf;
	
	If WithVerification Then
		CheckPossibilityOfConfirmingDuplicates(Duplicates, Result);
	EndIf;
	If Not Result.ConfirmationIsPossible Then
		Return Result;
	EndIf;
	
	Original = SearchAndReplaceDuplicatesMasterDataClientServer.StatusOriginal();
	DoubleReplace = SearchAndReplaceDuplicatesMasterDataClientServer.StatusDoubleReplace();
	DoNotDeleteDouble = SearchAndReplaceDuplicatesMasterDataClientServer.DoNotDeleteDoubleStatus();
	ConfirmationRequired = SearchAndReplaceDuplicatesMasterDataClientServer.StatusConfirmationRequired();
	
	Filter = New Structure("Status", Original);
	Originals = Duplicates.FindRows(Filter);
	If Originals.Count() = 1 Then
		OriginalItem = Originals[0].Duplicate1;
	Else
		DuplicatesTable = Duplicates.Unload();
		InformationRegisters.MasterDataDuplicatesToConfirm.DeleteDuplicates(
			DuplicatesTable.UnloadColumn("DuplicatesGroup"),
			DuplicatesTable.UnloadColumn("Duplicate1"));
		Return Result;
	EndIf;
	
	GroupsToDelete = New Array;
	DuplicatesToDelete = New Array;
	ConfirmedDuplicates = InformationRegisters.MasterDataDuplicates.RecordSetTemplate();
	For Each TableRow In Duplicates Do
		
		StatusInLine = TableRow.Status;
		
		If StatusInLine <> ConfirmationRequired Then
			CommonClientServer.SupplementArray(
				GroupsToDelete,
				CommonClientServer.ValueInArray(TableRow.DuplicatesGroup), True);
			CommonClientServer.SupplementArray(
				DuplicatesToDelete,
				CommonClientServer.ValueInArray(TableRow.Duplicate1), True);
		EndIf;
		
		If StatusInLine = DoubleReplace Then
			DuplicateDeletionState = Enums.MasterDataDuplicateDeletionStates.LinkReplacementAndDeletionIsScheduled;
		ElsIf StatusInLine = DoNotDeleteDouble Then
			DuplicateDeletionState = Enums.MasterDataDuplicateDeletionStates.DeletionIsNotScheduled;
		Else
			Continue;
		EndIf;
		
		NewRow = ConfirmedDuplicates.Add();
		FillPropertyValues(NewRow, TableRow);
		NewRow.Original = OriginalItem;
		NewRow.DuplicateDeletionState = DuplicateDeletionState;
		NewRow.RefType = RefType;
		
	EndDo;
	
	NumberOfDuplicatesToDelete = DuplicatesToDelete.Count();
	DuplicateCount = Duplicates.Count();
	If NumberOfDuplicatesToDelete = 0
		Or NumberOfDuplicatesToDelete = DuplicateCount Then
		DuplicatesToDelete = Undefined;
	EndIf;
	If NumberOfDuplicatesToDelete <> DuplicateCount Then
		DuplicatesToDelete = CommonClientServer.ArraysDifference(
			DuplicatesToDelete,
			CommonClientServer.ValueInArray(OriginalItem));
	EndIf;
	
	BeginTransaction();
	Try
		InformationRegisters.MasterDataDuplicates.DeleteDuplicates(Duplicates.Unload(, "Duplicate1"));
		InformationRegisters.MasterDataDuplicates.AddDuplicates(ConfirmedDuplicates);
		InformationRegisters.MasterDataDuplicatesToConfirm.DeleteDuplicates(GroupsToDelete, DuplicatesToDelete);
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Return Result;
	
EndFunction

Procedure VerifyAuthenticityOfDuplicates(Duplicates, Result)
	
	DuplicatesInArray = New Array;
	For Each String In Duplicates Do
		DuplicatesInArray.Add(String.Duplicate1);
	EndDo;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	MasterDataDuplicatesToConfirm.Duplicate1 AS Duplicate1
	|FROM
	|	InformationRegister.MasterDataDuplicatesToConfirm AS MasterDataDuplicatesToConfirm
	|WHERE
	|	MasterDataDuplicatesToConfirm.Duplicate1 IN (&DuplicatesInArray)
	|
	|UNION
	|
	|SELECT
	|	MasterDataDuplicates.Duplicate1
	|FROM
	|	InformationRegister.MasterDataDuplicates AS MasterDataDuplicates
	|WHERE
	|	MasterDataDuplicates.Duplicate1 IN (&DuplicatesInArray)
	|
	|UNION
	|
	|SELECT
	|	MasterDataDuplicates.Original
	|FROM
	|	InformationRegister.MasterDataDuplicates AS MasterDataDuplicates
	|WHERE
	|	MasterDataDuplicates.Original IN (&DuplicatesInArray)";
	Query.SetParameter("DuplicatesInArray", DuplicatesInArray);
	
	ExistingDuplicates = Query.Execute().Select();
	
	If ExistingDuplicates.Count() <> Duplicates.Count() Then
		Result.ConfirmationIsPossible = False;
		Result.TextOfNonconformityWarning = NStr("vi = 'Không thể xác nhận, bởi vì một số bản ghi trùng lặp không còn tồn tại trong cơ sở dữ liệu.
			|Có thể, các bản ghi này đã bị người dùng khác chỉnh sửa hoặc xóa.';
			|ru = 'Подтверждение невозможно: часть дублирующих записей отсутствует в базе данных.
			|Возможно, они были изменены или удалены другим пользователем.';
			|en = 'Confirmation is impossible: some duplicate records are missing from the database.
			|They may have been changed or deleted by another user.'; fa = 'Confirmation is impossible: some duplicate records are missing from the database.
			|They may have been changed or deleted by another user.';
			|it = 'Confirmation is impossible: some duplicate records are missing from the database.
			|They may have been changed or deleted by another user.';
			|pl = 'Confirmation is impossible: some duplicate records are missing from the database.
			|They may have been changed or deleted by another user.';
			|tr = 'Onaylanamıyor: Yinelenen öğelerin bir kısmı veritabanında bulunamadı.
			|Başka bir kullanıcı tarafından değiştirilmiş veya silinmiş olabilir.'");
	EndIf;
	
EndProcedure

// Parameters:
//  Duplicates - ValueTable
//  CheckResult - Structure:
// * ConfirmationIsPossible - Boolean
// * StatusSelectionErrors - ValueTable:
//   ** ErrorText - String
//   ** Field - String
// * TextOfWarningAboutRepeatedSearch - String
// * TextOfNonconformityWarning - String
//
Procedure CheckPossibilityOfConfirmingDuplicates(Duplicates, CheckResult)
	
	If Not StatusesAreSetCorrectly(Duplicates, CheckResult) Then
		Return;
	EndIf;
	
	Original = Undefined;
	DuplicatesToCheck = DuplicatesToCheck(Duplicates, Original);
	Sources = Sources(Duplicates);
	StructureOfWarnings = CheckReFoundOnesByRule(Sources, DuplicatesToCheck, Original);
	If StructureOfWarnings.Count() > 0 Then
		GenerateWarningAboutRepeatedSearch(StructureOfWarnings, CheckResult);
		Return;
	EndIf;
	
	CheckChangedConfirmedStatuses(Duplicates, Original, CheckResult);
	
EndProcedure

Function StatusesAreSetCorrectly(Duplicates, CheckResult)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DuplicatesTable.Duplicate1 AS Duplicate1,
	|	CAST(DuplicatesTable.Status AS STRING(100)) AS Status
	|INTO TTDoubles
	|FROM
	|	&DuplicatesTable AS DuplicatesTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTDoubles.Duplicate1 AS Duplicate1
	|FROM
	|	TTDoubles AS TTDoubles
	|WHERE
	|	TTDoubles.Status = &StatusOriginal
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTDoubles.Duplicate1 AS Duplicate1
	|FROM
	|	TTDoubles AS TTDoubles
	|WHERE
	|	TTDoubles.Status IN (&StatusDoubleReplace, &DoNotDeleteDoubleStatus)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTDoubles.Duplicate1 AS Duplicate1
	|FROM
	|	TTDoubles AS TTDoubles
	|WHERE
	|	TTDoubles.Status = &StatusIsNotDouble
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTDoubles";
	Query.SetParameter("DuplicatesTable", Duplicates.Unload());
	Query.SetParameter("StatusOriginal", SearchAndReplaceDuplicatesMasterDataClientServer.StatusOriginal());
	Query.SetParameter("StatusDoubleReplace", SearchAndReplaceDuplicatesMasterDataClientServer.StatusDoubleReplace());
	Query.SetParameter("DoNotDeleteDoubleStatus", SearchAndReplaceDuplicatesMasterDataClientServer.DoNotDeleteDoubleStatus());
	Query.SetParameter("StatusIsNotDouble", SearchAndReplaceDuplicatesMasterDataClientServer.StatusIsNotDouble());
	
	QueryResult = Query.ExecuteBatch();
	
	SampleOriginal = QueryResult[1].Select();
	If SampleOriginal.Count() = 0 And QueryResult[3].IsEmpty() Then
		NewString = CheckResult.StatusSelectionErrors.Add();
		NewString.ErrorText = NStr("vi = 'Một phần từ trong số danh sách cần được đánh dấu như bản gốc.';
									|ru = 'Один элемент из списка должен быть отмечен как оригинал.';
									|en = 'One item from the list must be marked as an original.'; fa = 'One item from the list must be marked as an original.';
									|it = 'One item from the list must be marked as an original.';
									|pl = 'One item from the list must be marked as an original.';
									|tr = 'Listeden bir öğe orijinal olarak işaretlenmelidir.'");
		NewString.Field = "Duplicates[0].Status";
		CheckResult.ConfirmationIsPossible = False;
		Return False;
	ElsIf SampleOriginal.Count() > 1 Then
		NewString = CheckResult.StatusSelectionErrors.Add();
		NewString.ErrorText = NStr("vi = 'Việc xác nhận bản trùng lặp là có thể chỉ với một bản gốc.';
									|ru = 'Подтверждение дублей возможно только с одним оригиналом.';
									|en = 'You can confirm duplicates with only one original.'; fa = 'You can confirm duplicates with only one original.';
									|it = 'You can confirm duplicates with only one original.';
									|pl = 'You can confirm duplicates with only one original.';
									|tr = 'Yinelenen öğelerin onayı sadece tek bir orijinal ile mümkündür.'");
		NewString.Field = "Duplicates[0].Status";
		CheckResult.ConfirmationIsPossible = False;
		Return False;
	EndIf;
	
	If QueryResult[2].IsEmpty() And QueryResult[3].IsEmpty() Then
		NewString = CheckResult.StatusSelectionErrors.Add();
		NewString.ErrorText = NStr("vi = 'Chưa chọn một bản trùng lặp nào để xác nhận.';
									|ru = 'Не выбрано ни одного дубля для подтверждения.';
									|en = 'No duplicate is selected for confirmation.'; fa = 'No duplicate is selected for confirmation.';
									|it = 'No duplicate is selected for confirmation.';
									|pl = 'No duplicate is selected for confirmation.';
									|tr = 'Onaylanacak hiçbir yinelenen öğe seçilmedi.'");
		NewString.Field = "Duplicates[0].Status";
		CheckResult.ConfirmationIsPossible = False;
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

Function DuplicatesToCheck(Duplicates, Original)
	
	StatusOriginal = SearchAndReplaceDuplicatesMasterDataClientServer.StatusOriginal();
	StatusIsNotDouble = SearchAndReplaceDuplicatesMasterDataClientServer.StatusIsNotDouble();
	
	DuplicatesToCheck = New Array;
	
	For Each String In Duplicates Do
		If String.Status = StatusIsNotDouble Or String.Status = StatusOriginal Then
			DuplicatesToCheck.Add(String.Duplicate1);
		EndIf;
		
		If String.Status = StatusOriginal Then
			Original = String.Duplicate1;
		EndIf;
	EndDo;
	
	Return CommonClientServer.CollapseArray(DuplicatesToCheck);
	
EndFunction

Function Sources(Duplicates)
	
	StatusOriginal = SearchAndReplaceDuplicatesMasterDataClientServer.StatusOriginal();
	StatusIsNotDouble = SearchAndReplaceDuplicatesMasterDataClientServer.StatusIsNotDouble();
	
	Sources = New Array;
	
	For Each String In Duplicates Do
		If String.Status = StatusIsNotDouble Or String.Status = StatusOriginal Then
			Sources.Add(String.Source); 
		EndIf;
	EndDo;
	
	Return CommonClientServer.CollapseArray(Sources);
	
EndFunction

Function CheckReFoundOnesByRule(Sources, DuplicatesToCheck, Original)
	
	StructureOfWarnings = New Map;
	
	For Each Source In Sources Do
		If TypeOf(Source) = Type("CatalogRef.MasterDataDuplicateSearchRules") Then
			
			Query = Catalogs.MasterDataDuplicateSearchRules.GenerateRequestBasedOnRule(
				Source, True, DuplicatesToCheck);
			DoublesAccordingToRule = Query.Execute().Select();
			
			ReFoundByRule = New Array;
			ThereAreRecords = False;
			
			While DoublesAccordingToRule.Next() Do
				ThereAreRecords = True;
				If DoublesAccordingToRule.Ref <> Original Then
					ReFoundByRule.Add(DoublesAccordingToRule.Ref);
				EndIf;
				If DoublesAccordingToRule.Ref1 <> Original Then
					ReFoundByRule.Add(DoublesAccordingToRule.Ref1);
				EndIf;
			EndDo;
			
			If ThereAreRecords Then
				ReFoundByRule = CommonClientServer.CollapseArray(
					ReFoundByRule);
				StructureOfWarnings.Insert(Source, ReFoundByRule);
			EndIf;
			
		EndIf;
	EndDo;
	
	Return StructureOfWarnings;
	
EndFunction

Procedure GenerateWarningAboutRepeatedSearch(StructureOfWarnings, CheckResult)
	
	TemplateForElements = NStr("vi = 'Đối với phần tử ""%1"" đã thiết lập trạng thái ""Không phải là bản trùng lặp"".';
								|ru = 'Для элементов ""%1"" установлен статус ""Не является дублем"".';
								|en = 'The ""Not duplicate"" status is set for the ""%1"" items.'; fa = 'The ""Not duplicate"" status is set for the ""%1"" items.';
								|it = 'The ""Not duplicate"" status is set for the ""%1"" items.';
								|pl = 'The ""Not duplicate"" status is set for the ""%1"" items.';
								|tr = '""%1"" öğeleri için ""Yinelenen değil"" durumu ayarlandı.'");
	TemplateForElement = NStr("vi = 'Đối với phần tử ""%1"" đã thiết lập trạng thái ""Không phải là bản trùng lặp"".';
								|ru = 'Для элемента ""%1"" установлен статус ""Не является дублем"".';
								|en = 'The ""Not duplicate"" status is set for the ""%1"" item.'; fa = 'The ""Not duplicate"" status is set for the ""%1"" item.';
								|it = 'The ""Not duplicate"" status is set for the ""%1"" item.';
								|pl = 'The ""Not duplicate"" status is set for the ""%1"" item.';
								|tr = '""%1"" öğesi için ""Yinelenen değil"" durumu ayarlandı.'");
	
	TemplateForNextSearchForItemByRule = NStr(
		"vi = 'Khi tìm kiếm tiếp theo theo quy tắc ""%1"", sẽ thêm lại phần tử như bản trùng lặp cần xác nhận.';
		|ru = 'При следующем поиске по правилу ""%1"" элемент повторно будет добавлен как дубль к подтверждению.';
		|en = 'The next time you search by the ""%1"" rule, the item will be added again as a duplicate to confirm.'; fa = 'The next time you search by the ""%1"" rule, the item will be added again as a duplicate to confirm.';
		|it = 'The next time you search by the ""%1"" rule, the item will be added again as a duplicate to confirm.';
		|pl = 'The next time you search by the ""%1"" rule, the item will be added again as a duplicate to confirm.';
		|tr = '""%1"" kuralıyla yapılacak bir sonraki aramada öğe, onaylanmak üzere tekrar yinelenen olarak eklenecektir.'");
	TemplateForNextSearchForItemsByRule = NStr(
		"vi = 'Khi tìm kiếm tiếp theo theo quy tắc ""%1"", sẽ thêm lại phần tử như bản trùng lặp cần xác nhận.';
		|ru = 'При следующем поиске по правилу ""%1"" элементы повторно будут добавлены как дубли к подтверждению.';
		|en = 'The next time you search by the ""%1"" rule, the items will be added again as duplicates to confirm.'; fa = 'The next time you search by the ""%1"" rule, the items will be added again as duplicates to confirm.';
		|it = 'The next time you search by the ""%1"" rule, the items will be added again as duplicates to confirm.';
		|pl = 'The next time you search by the ""%1"" rule, the items will be added again as duplicates to confirm.';
		|tr = '""%1"" kuralıyla yapılacak bir sonraki aramada öğeler, onaylanmak üzere tekrar yinelenen olarak eklenecektir.'");
	
	Recommendation = NStr("vi = 'Để tránh ghi nhận trùng lặp, bạn nên làm rõ giá trị của các mục tin phần tử hoặc điều kiện trong quy tắc tìm kiếm trùng lặp.
		|Tiếp tục?';
		|ru = 'Чтобы исключить повторную регистрацию дубля, рекомендуется уточнить значения реквизитов элемента или условие в правиле поиска дублей.
		|Продолжить?';
		|en = 'To prevent duplicate reregistration, specify the item attribute values or a condition in the duplicate search rule.
		|Continue?'; fa = 'To prevent duplicate reregistration, specify the item attribute values or a condition in the duplicate search rule.
		|Continue?';
		|it = 'To prevent duplicate reregistration, specify the item attribute values or a condition in the duplicate search rule.
		|Continue?';
		|pl = 'To prevent duplicate reregistration, specify the item attribute values or a condition in the duplicate search rule.
		|Continue?';
		|tr = 'Yinelenen öğenin yeniden kaydedilmesini önlemek için, öğenin öznitelik değerlerini veya yinelenenleri arama kuralındaki koşulu netleştirmeniz önerilir.
		|Devam edilsin mi?'");
	
	PartsOfWarning = New Array;
	For Each Warning In StructureOfWarnings Do
		ItemCount = Warning.Value.Count();
		
		If ItemCount = 1 Then
			PartsOfWarning.Add(StrTemplate(TemplateForElement, Warning.Value[0]));
			PartsOfWarning.Add(StrTemplate(TemplateForNextSearchForItemByRule, 
				Warning.Key));
		ElsIf ItemCount > 1 Then
			PartsOfWarning.Add(StrTemplate(TemplateForElements, 
				StrConcat(Warning.Value, ", ")));
			PartsOfWarning.Add(StrTemplate(TemplateForNextSearchForItemsByRule, 
				Warning.Key));
		EndIf;
	EndDo;
	
	PartsOfWarning.Add(Recommendation);
	CheckResult.TextOfWarningAboutRepeatedSearch = StrConcat(PartsOfWarning, Chars.LF);
	CheckResult.ConfirmationIsPossible = False;
	
EndProcedure

Procedure CheckChangedConfirmedStatuses(Duplicates, Original, CheckResult)
	
	DoublesSelection = DuplicatesConfirmed(Duplicates);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	MasterDataDuplicates.Original AS Original
	|FROM
	|	InformationRegister.MasterDataDuplicates AS MasterDataDuplicates
	|WHERE
	|	MasterDataDuplicates.Original IN (&DoublesSelection)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MasterDataDuplicates.Duplicate1 AS Duplicate1
	|FROM
	|	InformationRegister.MasterDataDuplicates AS MasterDataDuplicates
	|WHERE
	|	MasterDataDuplicates.Duplicate1 = &OriginalSelection";
	Query.SetParameter("DoublesSelection", DoublesSelection);
	Query.SetParameter("OriginalSelection", Original);
	QueryResult = Query.ExecuteBatch();
	
	DuplicatesTable = Duplicates.Unload();
	
	SamplingOriginals = QueryResult[0].Select();
	While SamplingOriginals.Next() Do
		NewString = CheckResult.StatusSelectionErrors.Add();
		NewString.ErrorText = NStr("vi = 'Đã xác nhận phần tử như bản gốc, không thể thay đổi trạng thái';
									|ru = 'Элемент подтвержден как оригинал, смена статуса невозможна';
									|en = 'The item is confirmed as an original. Cannot change the status'; fa = 'The item is confirmed as an original. Cannot change the status';
									|it = 'The item is confirmed as an original. Cannot change the status';
									|pl = 'The item is confirmed as an original. Cannot change the status';
									|tr = 'Öğe orijinal olarak onaylandı, durum değişikliği mümkün değil'");
		SearchString_ = DuplicatesTable.Find(SamplingOriginals.Original, "Duplicate1"); 
		LineNumber = DuplicatesTable.IndexOf(SearchString_);
		If LineNumber <> Undefined Then
			NewString.Field = "Duplicates[" + LineNumber + "].Status";
		Else
			NewString.Field = "Duplicates[0].Status";
		EndIf;
	EndDo;
	
	DuplicatesSelection = QueryResult[1].Select();
	While DuplicatesSelection.Next() Do
		NewString = CheckResult.StatusSelectionErrors.Add();
		NewString.ErrorText = NStr("vi = 'Đã xác nhận phần tử như bản trùng lặp, không thể thay đổi trạng thái';
									|ru = 'Элемент подтвержден как дубль, смена статуса невозможна';
									|en = 'The item is confirmed as a duplicate. Cannot change the status.'; fa = 'The item is confirmed as a duplicate. Cannot change the status.';
									|it = 'The item is confirmed as a duplicate. Cannot change the status.';
									|pl = 'The item is confirmed as a duplicate. Cannot change the status.';
									|tr = 'Öğe yinelenen olarak onaylandı, durum değişikliği mümkün değil'");
		SearchString_ = DuplicatesTable.Find(DuplicatesSelection.Duplicate1, "Duplicate1"); 
		LineNumber = DuplicatesTable.IndexOf(SearchString_);
		If LineNumber <> Undefined Then
			NewString.Field = "Duplicates[" + LineNumber + "].Status";
		Else
			NewString.Field = "Duplicates[0].Status";
		EndIf;
	EndDo;
	
	If CheckResult.StatusSelectionErrors.Count() > 0 Then
		CheckResult.ConfirmationIsPossible = False;
	EndIf;
	
EndProcedure

Function DuplicatesConfirmed(Duplicates)
	
	StatusDoubleReplace = SearchAndReplaceDuplicatesMasterDataClientServer.StatusDoubleReplace();
	DoNotDeleteDoubleStatus = SearchAndReplaceDuplicatesMasterDataClientServer.DoNotDeleteDoubleStatus();
	
	DoublesSelection = New Array;
	
	For Each String In Duplicates Do
		StatusOfLine = String.Status;
		
		If StatusOfLine = StatusDoubleReplace Or StatusOfLine = DoNotDeleteDoubleStatus Then
			DoublesSelection.Add(String.Duplicate1);
		EndIf;
	EndDo;
	
	Return DoublesSelection;
	
EndFunction

#EndRegion

#Region Workplace

// Returns data for filling out the Master Data duplicate comparison form for the specified groups and Catalog type.
//
// Parameters:
//   GroupsIDs - String
//                       - Array of String - ids of duplicate groups to select.
//   CatalogType - String - ID of the directory type (metadata).
//
// Returns:
//   ValueTable - duplicate data:
//      *Duplicate1 - CatalogRef,ChartOfCharacteristicTypesRef
//      *DuplicatesGroup - String
//      *Source - CatalogRef.MasterDataDuplicateSearchRules,CatalogRef.Users
//      *OccurrenceQuantity - Number
//      *OccurrenceSearchDate - Date
//      *UsageInstancesCount - String
//      *Status - String
//      *Description - String
//      *Code - String
//
Function DataFromFillingOutDuplicateComparisonForm(GroupsIDs, CatalogType) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	MasterDataDuplicatesToConfirm.Duplicate1 AS Duplicate1
	|INTO AllRelatedTakes
	|FROM
	|	InformationRegister.MasterDataDuplicatesToConfirm AS MasterDataDuplicatesToConfirm
	|WHERE
	|	MasterDataDuplicatesToConfirm.DuplicatesGroup IN (&Groups_Selection)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MasterDataDuplicatesToConfirm.Duplicate1 AS Duplicate1,
	|	MasterDataDuplicatesToConfirm.DuplicatesGroup AS DuplicatesGroup,
	|	MasterDataDuplicatesToConfirm.Source AS Source,
	|	MasterDataDuplicatesToConfirm.OccurrenceQuantity AS OccurrenceQuantity,
	|	MasterDataDuplicatesToConfirm.OccurrenceSearchDate AS OccurrenceSearchDate,
	|	CAST("""" AS STRING(200)) AS UsageInstancesCount,
	|	CAST("""" AS STRING(200)) AS Status,
	|	CAST("""" AS STRING(200)) AS Description,
	|	CAST("""" AS STRING(200)) AS Code
	|FROM
	|	InformationRegister.MasterDataDuplicatesToConfirm AS MasterDataDuplicatesToConfirm
	|WHERE
	|	MasterDataDuplicatesToConfirm.Duplicate1 IN
	|		(SELECT
	|			T.Duplicate1
	|		FROM
	|			AllRelatedTakes AS T)";
	Query.SetParameter("Groups_Selection", GroupsIDs);
	
	SetPrivilegedMode(True);
	ResultTable1 = Query.Execute().Unload();
	SetPrivilegedMode(False);
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	MasterDataDuplicates.Duplicate1 AS Duplicate1,
	|	MasterDataDuplicates.Original AS Original,
	|	MasterDataDuplicates.DuplicateDeletionState AS DuplicateDeletionState,
	|	MasterDataDuplicates.OccurrenceQuantity AS OccurrenceQuantity,
	|	MasterDataDuplicates.OccurrenceSearchDate AS OccurrenceSearchDate
	|FROM
	|	InformationRegister.MasterDataDuplicates AS MasterDataDuplicates
	|WHERE
	|	MasterDataDuplicates.Original IN
	|		(SELECT DISTINCT
	|			T.Original
	|		FROM
	|			InformationRegister.MasterDataDuplicates AS T
	|		WHERE
	|			MasterDataDuplicates.Original IN (&Duplicates))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MasterDataDuplicates.Duplicate1 AS Duplicate1,
	|	MasterDataDuplicates.Original AS Original,
	|	MasterDataDuplicates.DuplicateDeletionState AS DuplicateDeletionState,
	|	MasterDataDuplicates.OccurrenceQuantity AS OccurrenceQuantity,
	|	MasterDataDuplicates.OccurrenceSearchDate AS OccurrenceSearchDate
	|FROM
	|	InformationRegister.MasterDataDuplicates AS MasterDataDuplicates
	|WHERE
	|	MasterDataDuplicates.Duplicate1 IN (&Duplicates)";
	
	Query.SetParameter("Duplicates", ResultTable1.UnloadColumn("Duplicate1"));
	SetPrivilegedMode(True);
	QueryResult = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	ProcessOriginals(ResultTable1, QueryResult[0].Select());
	ProcessDuplicates(ResultTable1, QueryResult[1].Select());
	
	ObjectMetadata = Common.MetadataObjectByID(CatalogType);
	CheckingStandardDetails = CodeName();
	FillPropertyValues(CheckingStandardDetails, ObjectMetadata.StandardAttributes);
	
	AttributesArray = New Array;
	For Each Validation In CheckingStandardDetails Do
		If Validation.Value <> Undefined Then
			AttributesArray.Add(Validation.Key); 
		EndIf;
	EndDo;
	
	Duplicates = ResultTable1.UnloadColumn("Duplicate1");
	AttributesOfDoubles = Common.ObjectsAttributesValues(Duplicates, StrConcat(AttributesArray, ","));
	
	For Each TableRow In ResultTable1 Do
		ObjectAttributes = CodeName();
		FillPropertyValues(ObjectAttributes, AttributesOfDoubles[TableRow.Duplicate1]);
		TableRow.Code = ObjectAttributes.Code;
		TableRow.Description = ObjectAttributes.Description;
		TableRow.UsageInstancesCount = PresentationOfPlacesOfUse(
			TableRow.OccurrenceQuantity, TableRow.OccurrenceSearchDate);
		
		If Not ValueIsFilled(TableRow.Status) Then
			TableRow.Status = SearchAndReplaceDuplicatesMasterDataClientServer.StatusConfirmationRequired();
		EndIf;
	EndDo;
	
	Return ResultTable1;
	
EndFunction

Procedure ProcessOriginals(ResultTable1, Selection)
	
	While Selection.Next() Do
		LinesWithOriginals = ResultTable1.FindRows(New Structure("Duplicate1", Selection.Original));
		For Each LineWithOriginal In LinesWithOriginals Do
			LineWithOriginal.Status = SearchAndReplaceDuplicatesMasterDataClientServer.StatusOriginal();
		EndDo;
		
		AddLineIfMissing(ResultTable1, Selection.Duplicate1, 
			Selection.OccurrenceSearchDate, Selection.OccurrenceQuantity);
		AddLineIfMissing(ResultTable1, Selection.Original);
	EndDo;
	
EndProcedure

Procedure ProcessDuplicates(ResultTable1, Selection)
	
	While Selection.Next() Do
		LinesWithDuplicates = ResultTable1.FindRows(New Structure("Duplicate1", Selection.Duplicate1));
		For Each StringWithDouble In LinesWithDuplicates Do
			StringWithDouble.Status = StatusSelection(Selection.DuplicateDeletionState);
			StringWithDouble.OccurrenceQuantity = Selection.OccurrenceQuantity;
			StringWithDouble.OccurrenceSearchDate = Selection.OccurrenceSearchDate;
		EndDo;
		
		AddLineIfMissing(ResultTable1, Selection.Duplicate1, 
			Selection.OccurrenceSearchDate, Selection.OccurrenceQuantity);
		AddLineIfMissing(ResultTable1, Selection.Original);
	EndDo;
	
EndProcedure

Procedure AddLineIfMissing(ResultTable1, Duplicate1, 
	DateOfUse = Undefined, UsageCount = Undefined)
	
	Filter = New Structure("Duplicate1,Source", Duplicate1, Undefined);
	RowsSearch = ResultTable1.FindRows(Filter);
	If RowsSearch.Count() = 0 Then
		NewRow = ResultTable1.Add();
		NewRow.Duplicate1 = Duplicate1;
		If ValueIsFilled(DateOfUse) Then
			NewRow.OccurrenceSearchDate = DateOfUse;
		EndIf;
		If ValueIsFilled(UsageCount) Then
			NewRow.OccurrenceQuantity = UsageCount;
		EndIf;
	EndIf;
	
EndProcedure


Function CodeName()
	Return New Structure("Code, Description");
EndFunction

// Generates a string Presentation of the number of records and the date to display the places of use.
//
// Parameters:
//   Count - Number - the number of records found.
//   Date - Date - the date the number of records refers to.
//
// Returns:
//   String - text in the format "%1 by %2", if the parameters are filled in, otherwise an empty line.
//
Function PresentationOfPlacesOfUse(Count, Date) Export
	
	Result = "";
	
	If ValueIsFilled(Count) And ValueIsFilled(Date) Then
		Result = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 sang %2';
				|ru = '%1 на %2';
				|en = '%1 with %2'; fa = '%1 with %2';
				|it = '%1 with %2';
				|pl = '%1 with %2';
				|tr = '%1 yerine %2'"), Count, Format(Date, "DLF=D"));
	EndIf;
	
	Return Result;
	
EndFunction

Function StatusSelection(DuplicateDeletionState)
	
	If DuplicateDeletionState = Enums.MasterDataDuplicateDeletionStates.LinkReplacementAndDeletionIsScheduled
		Or DuplicateDeletionState = Enums.MasterDataDuplicateDeletionStates.LinkReplacementAndDeletionAreSuspendedDueToErrors Then
		Return SearchAndReplaceDuplicatesMasterDataClientServer.StatusDoubleReplace();
		
	ElsIf DuplicateDeletionState = Enums.MasterDataDuplicateDeletionStates.DeletionIsNotScheduled Then
		Return SearchAndReplaceDuplicatesMasterDataClientServer.DoNotDeleteDoubleStatus();
		
	Else
		Return SearchAndReplaceDuplicatesMasterDataClientServer.StatusConfirmationRequired();
		
	EndIf;
	
EndFunction

#EndRegion

#EndRegion

#EndIf