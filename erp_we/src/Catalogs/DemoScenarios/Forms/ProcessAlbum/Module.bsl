
#Region FormEventHandlers 

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ProcessPassedParameters(Cancel); 
	
	If Cancel Then
		Return;
	EndIf;
	
	InitializeFormData();
	
	GenerateHTMLDocument();
	
EndProcedure

#EndRegion 

#Region FormHeaderItemsEventHandlers 

&AtClient
Procedure HTMLTextDocumentComplete(Item)
	
	If Not DoNotCallPrintCommand 
		And Not PrintDialogFormOnOpenOpened Then
		Items.HTMLText.Document.execCommand("Print");
		PrintDialogFormOnOpenOpened = True;
	EndIf;
	
EndProcedure 

&AtClient
Procedure HTMLTextOnClick(Item, EventData, StandardProcessing)
	
	DemoScenariosClient.WhenYouClickInHTMLDocumentField(ThisObject, Item, EventData, StandardProcessing)
	
EndProcedure

#EndRegion 

#Region Private

#Region InitializeForm

&AtServer
Procedure ProcessPassedParameters(Cancel)

	If TypeOf(Parameters.ReportScenarios) <> Type("Array") Then
		
		Cancel = True;
		
	ElsIf Parameters.ReportScenarios.Count() = 0 Then
		
		Cancel = True;
		
	Else
		
		ReportScenarios.LoadValues(Parameters.ReportScenarios);
		
	EndIf;
	
	DoNotCallPrintCommand = Parameters.DoNotCallPrintCommand;
	
	If Cancel Then
		
		Common.MessageToUser(DemoScenariosClientServer.MessageTextIncorrectProcessAlbumParameters());
		
	EndIf;

EndProcedure

&AtServer
Procedure InitializeFormData()

	ScenariosLanguage = CurrentLanguage().LanguageCode;

EndProcedure 

#EndRegion 

#Region GeneratingHTMLDocument

&AtServer
Procedure GenerateHTMLDocument()

	DataToGenerate_ = DataForGeneratingHTMLDocument(); 
	
	If DataToGenerate_.NumberOfScenarios = 0 Then
		
		Raise DemoScenariosClientServer.MessageTextIncorrectProcessAlbumParameters();
		
	EndIf;
	
	HTMLDocument = New HTMLDocument;
	
	ItemBody = HTMLDocument.CreateElement("body");
	HTMLDocument.Body = ItemBody;
	
	GroupsToOutput = DataToGenerate_.Data.Count();
	GroupsAreDerived = 0;
	
	For Each ScenarioDataGroups In DataToGenerate_.Data Do
	
		For Each TreeRow In ScenarioDataGroups.Rows Do
			
			OutputHTMLDocumentScriptString(TreeRow, HTMLDocument);
		
		EndDo; 
		
		GroupsAreDerived = GroupsAreDerived + 1;
		
		If GroupsAreDerived < GroupsToOutput Then
			
			AddPrintBreakForPageToHTMLDocument(HTMLDocument);
			
		EndIf;
	
	EndDo;
	
	HTMLText = HTMLTextFromHTMLDocumentObject( HTMLDocument);

EndProcedure

&AtServer
Procedure AddEmptyLineToHTMLDocument(HTMLDocument)
	
	GapElement = HTMLDocument.CreateElement("br");
	HTMLDocument.Body.AppendChild(GapElement);
	
EndProcedure 

&AtServer
Procedure AddPrintBreakForPageToHTMLDocument(HTMLDocument)
	
	AddEmptyLineToHTMLDocument(HTMLDocument);
	AddEmptyLineToHTMLDocument(HTMLDocument);
	
	ItemTable = HTMLDocument.CreateElement("table");
	SetHTMLElementAttribute(ItemTable,"width", "100%");
	SetHTMLElementAttribute(ItemTable,"padding", "0");
	SetHTMLElementAttribute(ItemTable,"border", "none");
	SetHTMLElementAttribute(ItemTable,"border-collapse", "collapse");
	
	HTMLDocument.Body.AppendChild(ItemTable);
	
	TableRowItem = HTMLDocument.CreateElement("tr");
	SetHTMLElementAttribute(TableRowItem,"background-color", "#B0B0B0");
	SetHTMLElementAttribute(TableRowItem,"padding", "0");
	SetHTMLElementAttribute(TableRowItem,"height",  "1");
	
	ItemTable.AppendChild(TableRowItem);
	
	GapElement = HTMLDocument.CreateElement("br");
	SetHTMLElementAttribute(TableRowItem,"page-break-after", "always"); 
	HTMLDocument.Body.AppendChild(GapElement);
	
EndProcedure 

// Displays a line with the script in the report
// 
// Parameters:
//  TreeRow - ValueTreeRow - Contains:
//    * FullCode    - String - full script code
//    * Description - String - Name of the Script
//    * HTMLText    - String - Scenario Description
//  HTMLDocument - HTMLDocument - the document in which the title is displayed
&AtServer
Procedure OutputHTMLDocumentScriptString(TreeRow, HTMLDocument)
	
	ParentString = TreeRow.Parent; 
	
	If ParentString <> Undefined
		And ParentString.IsFolder <> TreeRow.IsFolder Then
		
		CurrentRowIndex = ParentString.Rows.IndexOf(TreeRow);
		If CurrentRowIndex > 0 Then
			If ParentString.Rows[ParentString.Rows.IndexOf(TreeRow) - 1].IsFolder Then
				AddEmptyLineToHTMLDocument(HTMLDocument);
			EndIf;
		EndIf;
		
		If Not ParentString.TableHeaderIsDisplayed Then
			
			ParentString.HTMLTableElement = TableElementAfterTableHeaderIsDisplayed(HTMLDocument); 
			
			ParentString.TableHeaderIsDisplayed = True; 
			
		EndIf;
		
		OutputScriptLineToTable(HTMLDocument, ParentString.HTMLTableElement, TreeRow); 
		
	Else
		
		If ParentString <> Undefined Then
			ParentString.TableHeaderIsDisplayed = False;
		EndIf;
		
		PrintScriptTitle(TreeRow, HTMLDocument);
		
		For Each SubordinateRow In TreeRow.Rows Do 
			
			OutputHTMLDocumentScriptString(SubordinateRow, HTMLDocument);
			
		EndDo;
		
	EndIf;
	
EndProcedure

// Output the script line to the table.
// 
// Parameters:
//  HTMLDocument - HTMLDocument - the document in which the string is output
//  HTMLTableElement - HTMLElement - contains a table in which the line is output
//  TreeRow - ValueTreeRow - Contains:
//    * FullCode    - String - full script code
//    * Description - String - Name of the Script
//    * HTMLText    - String - Scenario Description
&AtServer
Procedure OutputScriptLineToTable(HTMLDocument, HTMLTableElement, TreeRow)
	
	TableRowItem = HTMLDocument.CreateElement("tr");
	AddCellToTable(HTMLDocument, TableRowItem, TreeRow.FullCode, False);
	AddCellToTable(HTMLDocument, TableRowItem, TreeRow.Description, False);
	AddCellToTable(HTMLDocument, TableRowItem, PerformersByLine(TreeRow.Assignees), False);
	AddCellToTable(HTMLDocument, TableRowItem, HTMLDocumentFromHTMLTextForTableCell(TreeRow.HTMLText), False);
	AddCellToTable(HTMLDocument, TableRowItem, ConfigurationObjectsByString(TreeRow.DocumentsCatalogs), False);
	
	HTMLTableElement.AppendChild(TableRowItem);
	
EndProcedure

&AtServer
Function HTMLDocumentFromHTMLTextForTableCell(HTMLText)
	
	BodyContents = HTMLTagContent(HTMLText, "body");
	HTMLDocument   =  HTMLDocumentObjectFromHTMLText(BodyContents);
	
	Return HTMLDocument;

EndFunction

&AtServer
Function HTMLTagContent(Text, NameTag, IncludeStartEndTag = False, SerialNumber = 1)
	
	Result = Undefined;
	
	Begin    = "<"  + NameTag;
	Ending = "</" + NameTag + ">";
	
	FoundPositionStart = StrFind(Lower(Text), Lower(Begin), SearchDirection.FromBegin, 1, SerialNumber);
	FoundPositionEnd = StrFind(Lower(Text), Lower(Ending), SearchDirection.FromBegin, 1, SerialNumber);
	If FoundPositionStart = 0
		Or FoundPositionEnd = 0 Then
		Return "";
	EndIf;
	
	Content = Mid(Text,
	                  FoundPositionStart,
	                  FoundPositionEnd - FoundPositionStart + StrLen(Ending));
	
	If IncludeStartEndTag Then
		
		Result = TrimAll(Content);
		
	Else
		
		StartTag = Left(Content, StrFind(Content, ">"));
		Content = StrReplace(Content, StartTag, "");
		
		EndTag1 = Right(Content, StrLen(Content) - StrFind(Content, "<", SearchDirection.FromEnd) + 1);
		Content = StrReplace(Content, EndTag1, "");
		
		Result = TrimAll(Content);
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Function PerformersByLine(PerformersArray) 
	
	Return StrConcat(PerformersArray, ",");
	
EndFunction

&AtServer
Function ConfigurationObjectsByString(ArrayConfigurationObjects) 
	
	Return StrConcat(ArrayConfigurationObjects, ",");
	
EndFunction

&AtServer
Function TableElementAfterTableHeaderIsDisplayed(HTMLDocument)
	
	HeaderCellBackgroundColor = "E6E6FA";
	HeightOfHeaderCell   = "50";
	
	ItemTable = HTMLDocument.CreateElement("table");
	SetHTMLElementAttribute(ItemTable,"border", "1");
	SetHTMLElementAttribute(ItemTable,"border-collapse", "collapse");
	SetHTMLElementAttribute(ItemTable,"rules", "all");
	HTMLDocument.Body.AppendChild(ItemTable);
	
	AddTableColumn(HTMLDocument, ItemTable, "60", "left");
	AddTableColumn(HTMLDocument, ItemTable, "200", "left");
	AddTableColumn(HTMLDocument, ItemTable, "150", "left");
	AddTableColumn(HTMLDocument, ItemTable, "900", "left");
	AddTableColumn(HTMLDocument, ItemTable, "150", "left");
	
	TableHeaderElement = HTMLDocument.CreateElement("thead");
	TableRowItem = HTMLDocument.CreateElement("tr");
	
	AddCellToTable(HTMLDocument, TableRowItem, NStr("vi = 'Mã';
													|ru = 'Код';
													|en = 'Code'; fa = 'کد';
													|it = 'Код';
													|pl = 'Code';
													|tr = 'Kod'"),                   True, HeaderCellBackgroundColor, HeightOfHeaderCell);
	AddCellToTable(HTMLDocument, TableRowItem, NStr("vi = 'Bước quy trình';
													|ru = 'Шаг процесса';
													|en = 'Process step'; fa = 'گام فرایند';
													|it = 'Fase del processo';
													|pl = 'Krok procesu';
													|tr = 'Süreç adımı'"),          True, HeaderCellBackgroundColor, HeightOfHeaderCell);
	AddCellToTable(HTMLDocument, TableRowItem, NStr("vi = 'Người thực hiện';
													|ru = 'Исполнитель';
													|en = 'Assignee'; fa = 'Assignee';
													|it = 'Исполнитель';
													|pl = 'Assignee';
													|tr = 'Atanan'"),           True, HeaderCellBackgroundColor, HeightOfHeaderCell);
	AddCellToTable(HTMLDocument, TableRowItem, NStr("vi = 'Thao tác trong chương trình';
													|ru = 'Действия в программе';
													|en = 'Actions in the application'; fa = 'Actions in the application';
													|it = 'Действия в программе';
													|pl = 'Actions in the application';
													|tr = 'Programdaki eylemler'"),  True, HeaderCellBackgroundColor, HeightOfHeaderCell);
	AddCellToTable(HTMLDocument, TableRowItem, NStr("vi = 'Thông tin tra cứu, chứng từ, biểu mẫu';
													|ru = 'НСИ, документы, формы';
													|en = 'Master data, documents, forms'; fa = 'Master data, documents, forms';
													|it = 'НСИ, документы, формы';
													|pl = 'Master data, documents, forms';
													|tr = 'Master veri, belgeler, formlar'"), True, HeaderCellBackgroundColor, HeightOfHeaderCell);
	
	TableHeaderElement.AppendChild(TableRowItem);
	ItemTable.AppendChild(TableHeaderElement);
	
	Return ItemTable;
	
EndFunction 

&AtServer
Procedure AddTableColumn(HTMLDocument, ItemTable, Var_Width, Align);
	
	ItemColumn = HTMLDocument.CreateElement("col");
	
	SetHTMLElementAttribute(ItemColumn, "width", Var_Width);
	SetHTMLElementAttribute(ItemColumn, "aligh", Align);
	SetHTMLElementAttribute(ItemColumn, "valign", "top");
	
	ItemTable.AppendChild(ItemColumn);
	
EndProcedure

&AtServer
Procedure AddCellToTable(HTMLDocument, RowItem, CellValue, HighlightWithBold = False, BackColor = Undefined, Var_Height = 0)
	
	CellItem = HTMLDocument.CreateElement("td");
	SetHTMLElementAttribute(CellItem, "valign", "top");
	SetHTMLElementAttribute(CellItem,"border", "1");
	SetHTMLElementAttribute(CellItem,"border-collapse", "collapse");
	If BackColor <> Undefined Then
		SetHTMLElementAttribute(CellItem,"bgcolor", BackColor);
	EndIf;
	If Var_Height <> 0 Then
		SetHTMLElementAttribute(CellItem,"height", Var_Height);
	EndIf;
	FontItem =  FontItem(RowItem.OwnerDocument, "2", "Tahoma"); 
	
	If TypeOf(CellValue) = Type("HTMLDocument") Then
		
		For Each ChildNode In CellValue.ChildNodes Do
			
			If ChildNode.NodeType = DOMNodeType.Element Then
				
				CloneOfChildNode = ChildNode.CloneNode( True);
				CellItem.AppendChild(CloneOfChildNode);
				
			EndIf;
			
		EndDo;
	
	Else
		
		If HighlightWithBold Then
			BoldItem = HTMLDocument.CreateElement("b");
			BoldItem.TextContent = CellValue;
			FontItem.AppendChild(BoldItem);
		Else 
			FontItem.TextContent = CellValue;
		EndIf;
		
		CellItem.AppendChild(FontItem);
		
	EndIf;
	
	RowItem.AppendChild(CellItem);
	
EndProcedure

// Displays the script title in the report
// 
// Parameters:
//  TreeRow - ValueTreeRow - Contains:
//    * FullCode    - String - full script code
//    * Description - String - Name of the Script
//    * HTMLText    - String - Scenario Description
//  HTMLDocument - HTMLDocument - the document in which the title is displayed
&AtServer
Procedure PrintScriptTitle(TreeRow, HTMLDocument)
	
	ItemBlock = HTMLDocument.CreateElement("p");
	HTMLDocument.Body.AppendChild(ItemBlock);
	TreeRowLevel = TreeRowLevel(TreeRow);
	FontItem = FontItem(HTMLDocument, FontSizeByTreeLineLevel(TreeRowLevel), "Cambria", "#4b0082");
	AddTextNode(FontItem, StrTemplate("%1 %2", TreeRow.FullCode, TreeRow.Description), True);

	ItemBlock.AppendChild(FontItem);
	
EndProcedure

&AtServer
Function FontSizeByTreeLineLevel(TreeRowLevel)

	If TreeRowLevel = 0 Then
		Return "4";
	ElsIf TreeRowLevel = 1 Then
		Return "3";
	Else
		Return "2";
	EndIf;
	
EndFunction

&AtServer
Function TreeRowLevel(TreeRow)
	
	Level = 0;
	
	DetermineNumberOfLevelsOfTree(TreeRow, Level);
	
	Return Level;
	
EndFunction 

&AtServer
Procedure DetermineNumberOfLevelsOfTree(TreeRow, Level)
	
	ParentString =TreeRow.Parent; 
	If ParentString <> Undefined Then
		Level = Level + 1; 
		DetermineNumberOfLevelsOfTree(ParentString, Level)
	EndIf;

EndProcedure

&AtServer
Procedure AddTextNode(ParentElement, Text, HighlightWithBold = False, AddLineBreak = False)
	
	OwnerDocument = ParentElement.OwnerDocument;
	
	TextNode = OwnerDocument.CreateTextNode(Text);
	
	If HighlightWithBold Then
		BoldItem = OwnerDocument.CreateElement("b");
		BoldItem.AppendChild(TextNode);
		ParentElement.AppendChild(BoldItem);
	Else
		
		ParentElement.AppendChild(TextNode);
		
	EndIf;
	
	If AddLineBreak Then
		ParentElement.AppendChild(OwnerDocument.CreateElement("br"));
	EndIf;
	
EndProcedure

&AtServer
Function FontItem(HTMLDocument, Size, FontName, FontColor = Undefined)
	
	FontItem = HTMLDocument.CreateElement("Font");
	SetHTMLElementAttribute(FontItem,"size",   Size);
	SetHTMLElementAttribute(FontItem,"face",   FontName);
	If FontColor <> Undefined Then
		SetHTMLElementAttribute(FontItem,"color", FontColor);
	EndIf;
	
	Return FontItem;
	
EndFunction

&AtServer
Procedure SetHTMLElementAttribute(HTMLElement, Name, TextContent)
	
	HTMLAttribute = HTMLElement.OwnerDocument.CreateAttribute(Name);
	HTMLAttribute.TextContent = TextContent;
	HTMLElement.Attributes.SetNamedItem(HTMLAttribute);
	
EndProcedure

&AtServer
Function DataForGeneratingHTMLDocument()
	
	DataToGenerate_ = New Structure;
	DataToGenerate_.Insert("Data",              New Array);
	DataToGenerate_.Insert("NumberOfScenarios", 0); 
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	DemoScenarios.Ref AS Ref
	|FROM
	|	Catalog.DemoScenarios AS DemoScenarios
	|WHERE
	|	DemoScenarios.Ref IN(&ReportScenarios)
	|	AND DemoScenarios.IsFolder";
	
	Query.SetParameter("ReportScenarios",ReportScenarios);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		
		Return DataToGenerate_;
		
	EndIf;
	
	SampleGroupScenarios = QueryResult.Select(); 
	DataToGenerate_.NumberOfScenarios = SampleGroupScenarios.Count();
	
	If DataToGenerate_.NumberOfScenarios = 0 Then
		Return DataToGenerate_;
	EndIf;
	
	While SampleGroupScenarios.Next() Do
	
		Query = New Query;
		Query.Text = "
		|SELECT
		|	DemoScenarios.Ref                                             AS Ref,
		|	MIN(ISNULL(DemoScenariosScenarioDescriptions.LineNumber, -1)) AS DescriptionLineNumber
		|INTO DescriptionScenarios
		|FROM
		|	Catalog.DemoScenarios AS DemoScenarios
		|		LEFT JOIN Catalog.DemoScenarios.ScenarioDescriptions AS DemoScenariosScenarioDescriptions
		|		ON (DemoScenariosScenarioDescriptions.Ref = DemoScenarios.Ref)
		|			AND (DemoScenariosScenarioDescriptions.LanguageCode = &LanguageCode)
		|WHERE
		|	DemoScenarios.Parent IN HIERARCHY(&DemoScenario)
		|	AND NOT DemoScenarios.DeletionMark
		|
		|GROUP BY DemoScenarios.Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DemoScenarios.Ref       AS Ref,
		|	DemoScenarios.Parent     AS Parent,
		|	DemoScenarios.Description AS Description,
		|	DemoScenarios.FullCode    AS FullCode,
		|	DemoScenarios.IsFolder    AS IsFolder,
		|	DemoScenarios.GroupType    AS GroupType,
		|	DemoScenarios.AccessGroupProfiles.(
		|		Profile AS Profile
		|	) AS AccessGroupProfiles,
		|	DemoScenarios.ConfigurationObjects.(
		|		ConfigurationObject AS ConfigurationObject
		|	) AS ConfigurationObjects,
		|	ISNULL(DemoScenariosScenarioDescriptions.AttachedFile, VALUE(Catalog.DemoScenariosAttachedFiles.EmptyRef)) AS AttachedFile
		|FROM
		|	DescriptionScenarios AS DescriptionScenarios
		|	INNER JOIN Catalog.DemoScenarios AS DemoScenarios 
		|		ON DemoScenarios.Ref = DescriptionScenarios.Ref
		|		LEFT JOIN Catalog.DemoScenarios.ScenarioDescriptions AS DemoScenariosScenarioDescriptions
		|		ON (DemoScenariosScenarioDescriptions.Ref = DemoScenarios.Ref)
		|			AND (DescriptionScenarios.DescriptionLineNumber = DemoScenariosScenarioDescriptions.LineNumber)
		|ORDER BY
		|	FullCode
		|TOTALS BY
		|	DemoScenarios.Ref HIERARCHY";
		
		NationalLanguageSupportServer.ChangeRequestFieldUnderCurrentLanguage(Query.Text, "Description");
		
		Query.SetParameter("DemoScenario", SampleGroupScenarios.Ref);
		Query.SetParameter("LanguageCode",                 ScenariosLanguage);
		
		QueryResult = Query.Execute(); // @skip-warning
		
		DataByGroup = QueryResult.Unload(QueryResultIteration.ByGroupsWithHierarchy);
		TransformDataTree(DataByGroup);
		
		DataToGenerate_.Data.Add(DataByGroup); 
	
	EndDo;
	
	Return DataToGenerate_;
	
EndFunction 

&AtServer
Procedure TransformDataTree(DataTree)
	
	DataTree.Columns.Add("DocumentsCatalogs", New TypeDescription("Array"));
	DataTree.Columns.Add("Assignees",          New TypeDescription("Array"));
	DataTree.Columns.Add("HTMLText",            Common.StringTypeDetails(0));
	DataTree.Columns.Add("TableHeaderIsDisplayed", New TypeDescription("Boolean"));
	DataTree.Columns.Add("HTMLTableElement",   New TypeDescription("HTMLTableElement"));
	
	For Each TreeRow In DataTree.Rows Do
		
		LinesToDelete = New Array;
		ConvertTreeString(TreeRow, LinesToDelete);
		
	EndDo;
	
	NameOfFieldToChange = DemoScenarios.NameOfMultilingualAttribute("Description");
	DataTree.Columns[NameOfFieldToChange].Name = "Description";
	
	DataTree.Columns.Delete("AccessGroupProfiles"); 
	DataTree.Columns.Delete("ConfigurationObjects");
	DataTree.Columns.Delete("AttachedFile"); 
	
	For Each TreeRow In LinesToDelete Do
		
		ParentString = TreeRow.Parent;
		If ParentString <> Undefined Then
			
			ParentString.Rows.Delete(TreeRow);
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure ConvertTreeString(TreeRow, LinesToDelete)
	
	ParentString = TreeRow.Parent;
	If ParentString <> Undefined 
		And ParentString.Ref = TreeRow.Ref Then 
		
		For Each TableRow In TreeRow.ConfigurationObjects Do
			
			ParentString.DocumentsCatalogs.Add(TableRow.ConfigurationObject);
			
		EndDo;
		
		For Each TableRow In TreeRow.AccessGroupProfiles Do
			
			ParentString.Assignees.Add(TableRow.Profile);
			
		EndDo;
		
		If ValueIsFilled(TreeRow.AttachedFile) Then 
			
			FileData = FilesOperations.FileData(TreeRow.AttachedFile);
	
			If IsTempStorageURL(FileData.RefToBinaryFileData) Then
				
				FileBinaryData = GetFromTempStorage(FileData.RefToBinaryFileData);
				HTMLText = GetStringFromBinaryData(FileBinaryData, "UTF-8");
				
			Else
				
				HTMLText = "";
				
			EndIf;
			
		Else
			
			HTMLText = "";
			
		EndIf;
		
		DemoScenariosClientServer.AddBodyTagsIfNecessary(HTMLText);
		
		RemoveExtraNewlines(HTMLText);
		
		ParentString.HTMLText = HTMLText;
		
		LinesToDelete.Add(TreeRow);
		
		Return;
		
	EndIf;
	
	For Each SubordinateRow In TreeRow.Rows Do
		
		ConvertTreeString(SubordinateRow, LinesToDelete);
		
	EndDo;

EndProcedure

&AtServer
Procedure RemoveExtraNewlines(TextToProcess)

	TextToProcess = StrReplace(TextToProcess, "<o:p>&nbsp;</o:p>", "");
	TextToProcess = StrReplace(TextToProcess, "<p><br></p>", "");

EndProcedure

&AtServer
Function HTMLTextFromHTMLDocumentObject(HTMLDocument)
	
	Try
		DOMWriter = New DOMWriter;
		HTMLWriter = New HTMLWriter;
		HTMLWriter.SetString();
		DOMWriter.Write(HTMLDocument,HTMLWriter);
		Return HTMLWriter.Close();
	Except
		Return "";
	EndTry;
	
EndFunction

&AtServer
Function HTMLDocumentObjectFromHTMLText(HTMLText, Encoding = Undefined)
	
	Builder = New DOMBuilder;
	HTMLReader = New HTMLReader;
	
	NewHTMLText = HTMLText;
	PositionOpenXML = StrFind(NewHTMLText,"<?xml");
	
	If PositionOpenXML > 0 Then
		
		PositionCloseXML = StrFind(NewHTMLText,"?>");
		If PositionCloseXML > 0 Then
			
			NewHTMLText = Left(NewHTMLText,PositionOpenXML - 1) + Right(NewHTMLText,StrLen(NewHTMLText) - PositionCloseXML -1);
			
		EndIf;
		
	EndIf;
	
	If Encoding = Undefined Then
		
		HTMLReader.SetString(HTMLText);
		
	Else
		
		Try
		
			HTMLReader.SetString(HTMLText, Encoding);
		
		Except
			
			HTMLReader.SetString(HTMLText);
			
		EndTry;
		
	EndIf;
	
	Return Builder.Read(HTMLReader);
	
EndFunction

#EndRegion

#EndRegion 
