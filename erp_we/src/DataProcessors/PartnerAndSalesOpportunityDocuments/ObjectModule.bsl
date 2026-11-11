#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// Fills in the query table
//
// Parameters:
//  TableOfRequests            - ValueTable - contains documents and their corresponding requests
//  FilterCriteriaName          - String - either a Partner document or a Build document
//  AdditionalDocuments               - Array - the request may include documents that are not included in the criteria, but have a link
//                               to a document that is included in the criteria by the header Attributes.
//  AdditionalHeaderFields               - Array - names of additional header fields that will be received in the request
//  ConsiderPMVInDocuments  - Boolean - indicates that 
//                               the table parts of the document will be taken into account when forming the request
//  CurrentOnly  - Boolean - indicates that canceled documents will not be taken into account when forming the request.
//
Procedure FillInQueryTable(TableOfRequests, FilterCriteriaName, AdditionalDocuments, AdditionalHeaderFields, ConsiderPMVInDocuments = False,CurrentOnly = False) Export

	DocumentTree = New ValueTree;
	DocumentTree.Columns.Add("Document");
	DocumentTree.Columns.Add("StructureOfData");
	DocumentTree.Columns.Add("TabularSection");
	DocumentTree.Columns.Add("ConditionText");

	For Each CompositionItem In Metadata.FilterCriteria[FilterCriteriaName].Content Do

		StructureOfData = StructureOfData(CompositionItem.FullName());

		If Not AccessRight("Read", StructureOfData.Metadata) Then
			Continue;
		EndIf;
		
		If Not Common.MetadataObjectAvailableByFunctionalOptions(StructureOfData.Metadata) Then
			Continue;
		EndIf;

		DocumentRoot = DocumentTree.Rows.Find(StructureOfData.Metadata, "Document", False);
		If DocumentRoot = Undefined Then

			DocumentRoot = DocumentTree.Rows.Add();
			DocumentRoot.Document = StructureOfData.Metadata;

		EndIf;

		StringHeaderTS = DocumentRoot.Rows.Find(StructureOfData.NameOfTablePart, "TabularSection", False);
		If StringHeaderTS = Undefined Then

			StringHeaderTS = DocumentRoot.Rows.Add();
			StringHeaderTS.TabularSection = StructureOfData.NameOfTablePart;

		EndIf;

		DataString1 = StringHeaderTS.Rows.Add();
		DataString1.StructureOfData = StructureOfData;

	EndDo;

	HeaderConditionTemplate = " %PathToPropsTable%.%HeaderParameterField% = &Parameter ";
	QueryTemplate = 
	"SELECT
	|	HeaderTable.Ref              AS Document
	|	INTO TTSelectionTable
	|FROM
	|	&HeaderTableName AS HeaderTable
	|WHERE
	|	HeaderTable.Date >= BEGINOFPERIOD(&BeginOfPeriod, DAY)
	|	AND (HeaderTable.Date <= ENDOFPERIOD(&PeriodEnding, DAY) OR &PeriodEnding = DATETIME(1,1,1))
	|	AND (&ConditionText)
	|";
	ConditionTemplateForTS = " TableOfRows.%TSParameterField% = &Parameter ";
	TSConditionTemplate    = 
	" 1 IN
	|	(SELECT TOP 1
	|			1
	|	FROM
	|		Document.%NameOfTSTable% AS TableOfRows
	|	WHERE
	|		TableOfRows.Ref = %ConditionForVTCHLink%
	|		AND ( %ConditionForTSLines% )
	|	)";

	For Each RootString In DocumentTree.Rows Do

		TextOfConditionsForDocument = "";
		// Cycle through the details and tabular parts of one document
		For Each StringPropsTS In RootString.Rows Do

			ConditionText = "";
			// The condition on the field in PM.
			If Not IsBlankString(StringPropsTS.TabularSection) Then

				TimeText = "";
				// Cycle by tabular parts
				For Each TSRow In StringPropsTS.Rows Do

					TimeText = TimeText + ?(IsBlankString(TimeText),"", " OR ")
						+ StrReplace(ConditionTemplateForTS, "%TSParameterField%", TSRow.StructureOfData.AttributeName);

				EndDo;

				ConditionText = StrReplace(TSConditionTemplate, "%NameOfTSTable%", RootString.Document["Name"] + "." + StringPropsTS.TabularSection);
				ConditionText = StrReplace(ConditionText, "%ConditionForTSLines%", TimeText);

			Else // Cap condition

				// Cycle by details
				For Each TSRow In StringPropsTS.Rows Do

					ConditionText = ConditionText + ?(IsBlankString(ConditionText),"", " OR ")
						+ StrReplace(HeaderConditionTemplate, "%HeaderParameterField%", TSRow.StructureOfData.AttributeName);

				EndDo;

			EndIf;
			
			If CurrentOnly Then
				
				If RootString.Document.Name = "SalesOrder" Then
					TimeConditionText = StrReplace(TSConditionTemplate, "%NameOfTSTable%", "SalesOrder.Goods");
					TimeConditionText = StrReplace(TimeConditionText, "%ConditionForTSLines%", ("NOT TableOfRows.Canceled"));
					ConditionText = ConditionText + ?(IsBlankString(ConditionText),"", " And ") + TimeConditionText;
				Else
					
					CRMLocalization.AddRequestConditionBasedOnDocumentRelevance(RootString.Document.Name, ConditionText);
					
				EndIf;
			EndIf;
			
			If Not IsBlankString(ConditionText) Then
				
				AddTextToLine(TextOfConditionsForDocument, ConditionText, " OR ");
				
			EndIf;
		EndDo;

		If Not IsBlankString(TextOfConditionsForDocument) Then

			QueryText = StrReplace(QueryTemplate, "&HeaderTableName", "Document." + RootString.Document.Name);
			QueryText = StrReplace(QueryText, "&ConditionText", TextOfConditionsForDocument);
			QueryText = StrReplace(QueryText, "%PathToPropsTable%", "HeaderTable");
			QueryText = StrReplace(QueryText, "%ConditionForVTCHLink%", " HeaderTable.Ref");

			AddAdditionalHeaderFields(QueryText,RootString.Document, AdditionalHeaderFields);
			AddQueryToTable(TableOfRequests, RootString.Document, QueryText);

			RootString.ConditionText = TextOfConditionsForDocument;

		EndIf;
	EndDo;

	// Documents that are not included in the criteria are added to the request, but have a link
	// to a document that is included in the criteria by the header details.

	TSStringConditionTemplate = 
	"1 IN
	|	(SELECT
	|		1
	|	FROM
	|		Document.%DocumentName% AS TabularSection%TabSectionName%
	|	WHERE
	|		TabularSection%TabSectionName%.Ref = HeaderTable.Ref
	|		AND (&ConditionText)
	|)";
	ArrayOfConditions      = New Array;
	FieldsMap  = New Map;

	For Each Document In AdditionalDocuments Do
		If Not AccessRight("Read", Document) Then
			Continue;
		EndIf;

		ArrayOfConditions.Clear();
		FieldsMap.Clear();

		For Each Attribute In Document.Attributes Do
			For Each TreeRow In DocumentTree.Rows Do

				// Checking that the base document contains the necessary link only in the header.
				If Not PropsContainType(Attribute, "DocumentRef." + TreeRow.Document["Name"])
				 Or Not PropsOnlyInHeader(TreeRow) Then
					Continue;
				EndIf;

				StructuresArray = FieldsMap.Get(Attribute);
				If StructuresArray = Undefined Then

					StructuresArray = New Array;
					FieldsMap.Insert(Attribute, StructuresArray);

				EndIf;

				StructuresArray.Add(New Structure("Document, ConditionText",
												TreeRow.Document,
												TreeRow.ConditionText));
			EndDo;
		EndDo;

		For Each KeyAndValue In FieldsMap Do
			For Each ElementStructure_ In KeyAndValue.Value Do

				If CompositeProps(KeyAndValue.Key) Then
					PathToPropsTable = "CAST(HeaderTable." + KeyAndValue.Key["Name"] +" AS Document." + ElementStructure_.Document["Name"] + ")";
				Else
					PathToPropsTable = "HeaderTable." + KeyAndValue.Key.Name;
				EndIf;

				TimeText = ElementStructure_.ConditionText;
				TimeText = StrReplace(TimeText, "%PathToPropsTable%", PathToPropsTable);
				TimeText = StrReplace(TimeText, "%ParameterField_%", KeyAndValue.Key.Name);
				TimeText = StrReplace(TimeText, "%ConditionForVTCHLink%", "HeaderTable." + KeyAndValue.Key.Name);
				ArrayOfConditions.Add(TimeText);

			EndDo;
		EndDo;

		// By tabular parts
		If ConsiderPMVInDocuments Then
			For Each TabPart In Document.TabularSections Do

				FieldsMap.Clear();
				For Each Attribute In TabPart.Attributes Do
					For Each TreeRow In DocumentTree.Rows Do

						If Not PropsContainType(Attribute, "DocumentRef." + TreeRow.Document.Name)
						 Or Not PropsOnlyInHeader(TreeRow) Then
							Continue;
						EndIf;

						StructuresArray = FieldsMap.Get(Attribute);
						If StructuresArray = Undefined Then

							StructuresArray = New Array;
							FieldsMap.Insert(Attribute, StructuresArray);

						EndIf;
						StructuresArray.Add(New Structure("Document, ConditionText",
														TreeRow.Document,
														TreeRow.ConditionText));
					EndDo;
				EndDo;

				// Construction of a condition based on the tabular part.
				If FieldsMap.Count() > 0 Then
					TimeText = "";
					For Each KeyAndValue In FieldsMap Do
						For Each CurStructure In KeyAndValue.Value Do

							If CompositeProps(KeyAndValue.Key) Then
								TablePath = "CAST(TabularSection%TabSectionName%." + KeyAndValue.Key.Name +" AS Document." + CurStructure.Document["Name"] + ")";
							Else
								TablePath = "TabularSection%TabSectionName%." + KeyAndValue.Key.Name;
							EndIf;

							ConditionText = StrReplace(CurStructure.ConditionText, "%PathToPropsTable%", TablePath);
							ConditionText = StrReplace(ConditionText, "%ConditionForVTCHLink%", "TabularSection%TabSectionName%." + KeyAndValue.Key.Name);
							ConditionText = StrReplace(ConditionText, "%TabSectionName%",         TabPart.Name);

							AddTextToLine(TimeText, ConditionText, " OR ");

						EndDo;
					EndDo;

					TimeText = StrReplace(TSStringConditionTemplate, "&ConditionText", TimeText);
					TimeText = StrReplace(TimeText, "%DocumentName%", Document.Name + "." + TabPart.Name);
					TimeText = StrReplace(TimeText, "%TabSectionName%", TabPart.Name);

					ArrayOfConditions.Add(TimeText);

				EndIf;
			EndDo;
		EndIf;

		If ArrayOfConditions.Count() > 0 Then

			QueryText = StrReplace(QueryTemplate, "&HeaderTableName",  "Document." + Document.Name);
			QueryText = StrReplace(QueryText, "&ConditionText", StringFromArrayOfStrings(ArrayOfConditions, " OR "));

			AddAdditionalHeaderFields(QueryText, Document, AdditionalHeaderFields);
			AddQueryToTable(TableOfRequests, Document, QueryText);

		EndIf;

	EndDo;

		QueryTemplate = 
	"SELECT &PostfixToChoose,
	|	HeaderTable.Ref              AS Document,
	|	&StringOfAdditionalFields,
	|	HeaderTable.Number               AS Number,
	|	HeaderTable.Date                AS Date,
	|	VALUETYPE(HeaderTable.Ref) AS DocumentType,
	|	CASE
	|		WHEN HeaderTable.Posted THEN
	|			0
	|		WHEN HeaderTable.DeletionMark THEN
	|			1
	|		ELSE 2
	|	END                        AS PictureID
	|FROM
	|	&HeaderTableName AS HeaderTable
	|
	|	INNER JOIN TTSelectionTable AS FilterTable ON HeaderTable.Ref = FilterTable.Document
	|";
	For Each TabRow In TableOfRequests Do

		TimeText= StrReplace(QueryTemplate, "&HeaderTableName",  "Document." + TabRow.DocumentName);
		AddAdditionalHeaderFields(TimeText, Metadata.Documents[TabRow.DocumentName], AdditionalHeaderFields);

		TabRow.QueryTextSelection = TimeText;

	EndDo;

EndProcedure

Procedure AddTextToLine(String, Text, Separator = " Or ")

	String = String + ?(IsBlankString(String), "", Separator) + Text;

EndProcedure

Function StringFromArrayOfStrings(RowsArray, Separator = " Or ")

	Result = "";
	For Each Item In RowsArray Do

		AddTextToLine(Result, Item, Separator);

	EndDo;

	Return Result;

EndFunction

Function StructureOfData(DataPath)
	
	Structure = New Structure;
	
	MatchingNames = New Array();
	MatchingNames.Add("ObjectType");
	MatchingNames.Add("ObjectKind");
	MatchingNames.Add("DataPath");
	MatchingNames.Add("NameOfTablePart");
	MatchingNames.Add("AttributeName");
	
	For IndexOf = 1 To 3 Do
		
		Point = StrFind(DataPath, ".");
		CurrentValue = Left(DataPath, Point-1);
		Structure.Insert(MatchingNames[IndexOf-1], CurrentValue);
		DataPath = Mid(DataPath, Point+1);
		
	EndDo;
	
	DataPath = StrReplace(DataPath, "Attribute.", "");
	
	If Structure.DataPath = "TabularSection" Then
		
		For IndexOf = 4 To 5  Do 
			
			Point = StrFind(DataPath, ".");
			If Point = 0 Then
				CurrentValue = DataPath;
			Else
				CurrentValue = Left(DataPath, Point-1);
			EndIf;
			
			Structure.Insert(MatchingNames[IndexOf-1], CurrentValue);
			DataPath = Mid(DataPath,  Point+1);
			
		EndDo;
		
	Else
		
		Structure.Insert(MatchingNames[3], "");
		Structure.Insert(MatchingNames[4], DataPath);
		
	EndIf;
	
	If Structure.ObjectType = "Document" Then
		Structure.Insert("Metadata", Metadata.Documents[Structure.ObjectKind]);
	Else
		Structure.Insert("Metadata", Metadata.Catalogs[Structure.ObjectKind]);
	EndIf;
	
	Return Structure;
	
EndFunction

// Adds a query to the query table.
// 
// Parameters:
// 	TableOfRequests       - ValueTable - 
// 	MetadataOfDocument   - MetadataObjectDocument - 
// 	QueryText           - String - 
//
Procedure AddQueryToTable(TableOfRequests, MetadataOfDocument, QueryText)

	TabRow = TableOfRequests.Add();
	TabRow.DocumentName     = MetadataOfDocument.Name;
	TabRow.DocumentSynonym = MetadataOfDocument.Synonym;
	TabRow.Use     = True;
	TabRow.QueryText     = QueryText;

EndProcedure

Procedure AddAdditionalHeaderFields(QueryText, MetadataOfDocument, AdditionalHeaderFields)

	FieldPattern  = "%FieldName% AS %FieldAlias%,";
	FieldsString = "";

	For Each FieldName In AdditionalHeaderFields Do
	
		If MetadataOfDocument.Attributes.Find(FieldName) <> Undefined Then
	
			Text = StrReplace(FieldPattern, "%FieldName%", "REFPRESENTATION(HeaderTable." + FieldName +" ) "); // @query-part-2
	
		Else
	
			Text = StrReplace(FieldPattern, "%FieldName%", " NULL ");
	
		EndIf;
	
		FieldsString = FieldsString + ?(IsBlankString(FieldsString), "", Chars.LF)
		              + StrReplace(Text, "%FieldAlias%", FieldName);
	
	EndDo;
	
	QueryText = StrReplace(QueryText, "&StringOfAdditionalFields,", FieldsString);
	
EndProcedure

Function CompositeProps(AttributeMetadata)

	Return AttributeMetadata.Type.Types().Count() > 1;

EndFunction

Function PropsContainType(AttributeMetadata, TypeName)

	Return AttributeMetadata.Type.ContainsType(Type(TypeName));

EndFunction

Function PropsOnlyInHeader(TreeRow)

	Return TreeRow.Rows.FindRows(New Structure("TabularSection", ""), False).Count()>0;

EndFunction

#EndRegion

#EndIf