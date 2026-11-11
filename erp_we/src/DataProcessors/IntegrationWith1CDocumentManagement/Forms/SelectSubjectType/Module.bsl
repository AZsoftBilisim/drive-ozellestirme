#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Tree = FormAttributeToValue("TreeOfOptions");
	
	// Independent types of items.
	AddRow(Tree, "FileFromDisk", NStr("vi = 'Tệp từ đĩa';
										|ru = 'Файл с диска';
										|en = 'File from hard drive'; fa = 'File from hard drive';
										|it = 'File dal disco';
										|pl = 'Plik z dysku';
										|tr = 'Diskteki dosya'"));
	
	If (Parameters.Property("Process_Type") And Parameters.Process_Type = "DMBusinessProcessIssuesSolution")
			Or (Parameters.Property("Type") And Parameters.Type = "DMBusinessProcessIssuesSolution") Then
		AddingOtherItemsIsAvailable = False;
	Else
		AddingOtherItemsIsAvailable = True;
	EndIf;
	
	If AddingOtherItemsIsAvailable Then
		
		// Items in IS.
		Query = New Query(
			"SELECT
			|	Rules.ObjectTypeIS AS ObjectType,
			|	CAST(Rules.ObjectPresentationIS AS STRING(100)) AS Variant,
			|	Rules.Ref AS Rule,
			|	KeyAttributes.AttributeNameObjectIS AS SelectionKey,
			|	KeyAttributes.AttributeValueIS AS FilterValue
			|FROM
			|	Catalog.RulesForIntegrationWith1CDocumentManagement AS Rules
			|		LEFT JOIN Catalog.RulesForIntegrationWith1CDocumentManagement.AttributeFillingRulesIS AS KeyAttributes
			|		ON Rules.Ref = KeyAttributes.Ref
			|			AND (KeyAttributes.KeyAttribute_)
			|			AND (NOT KeyAttributes.IsAdditionalAttributeIS)
			|WHERE
			|	NOT Rules.DeletionMark
			|
			|ORDER BY
			|	Variant
			|TOTALS BY
			|	Rule");
		RuleSelection_ = Query.Execute().Select(QueryResultIteration.ByGroups);
		If RuleSelection_.Count() <> 0 Then
			DescriptionIS = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Trong %1';
					|ru = 'В %1';
					|en = 'In %1'; fa = 'In %1';
					|it = 'In %1';
					|pl = 'W %1';
					|tr = '%1de'"),
				IntegrationWith1CDocumentManagementCore.AbbreviatedNameOfConfiguration());
			TitleIS = AddTitle(Tree, DescriptionIS);
			While RuleSelection_.Next() Do
				Filter = New ValueList;
				SampleKeyDetails = RuleSelection_.Select();
				While SampleKeyDetails.Next() Do
					If ValueIsFilled(SampleKeyDetails.SelectionKey) Then
						Filter.Add(SampleKeyDetails.FilterValue, SampleKeyDetails.SelectionKey);
					EndIf;
				EndDo;
				AddRow(TitleIS, RuleSelection_.ObjectType, RuleSelection_.Variant, Filter);
			EndDo;
		EndIf;
		
		// Items in UP to.
		TitleBefore = AddTitle(Tree, NStr("vi = 'Trong 1C:Document Management';
											|ru = 'В 1С:Документообороте';
											|en = 'In 1C:Document Management'; fa = 'در 1C:Document Management';
											|it = 'In 1C:Document Management';
											|pl = 'W 1С:Document Management';
											|tr = '1C:Document Management''de'"));
		AddRow(TitleBefore, "DMFile");
		AddRow(TitleBefore, "DMInternalDocument");
		AddRow(TitleBefore, "DMIncomingDocument");
		AddRow(TitleBefore, "DMOutgoingDocument");
		If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.3.2.3.CORP") Then
			AddRow(TitleBefore, "DMProject");
		EndIf;
		AddRow(TitleBefore, "DMCorrespondent");
		
	EndIf;
	
	ValueToFormData(Tree, TreeOfOptions);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TreeOfOptionsSelection(Item, RowSelected, Field, StandardProcessing)
	
	SelectOption();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectCommand(Command)
	
	SelectOption();
	
EndProcedure

&AtClient
Procedure CancelCommand(Command)
	
	Close(Undefined);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SelectOption()
	
	CurrentData = Items.TreeOfOptions.CurrentData;
	If CurrentData = Undefined Or CurrentData.ThisIsTheTitle Then
		Return;
	EndIf;
	
	Result = New Structure;
	Result.Insert("Variant", CurrentData.Variant);
	Result.Insert("Filter", CurrentData.Filter);
	Close(Result);
	
EndProcedure

&AtServer
Function AddRow(Tree, Variant, Presentation = "", Filter = Undefined)
	
	String = Tree.Rows.Add();
	String.Variant = Variant;
	If Not ValueIsFilled(Presentation) Then
		Presentation = IntegrationWith1CDocumentManagementClientServer.ObjectTypePresentationXDTO(Variant);
	EndIf;
	String.Presentation = Presentation;
	String.Filter = Filter;
	
	Return String;
	
EndFunction

&AtServer
Function AddTitle(Tree, Presentation)
	
	String = Tree.Rows.Add();
	String.Presentation = String(Presentation);
	String.ThisIsTheTitle = True;
	
	Return String;
	
EndFunction

#EndRegion