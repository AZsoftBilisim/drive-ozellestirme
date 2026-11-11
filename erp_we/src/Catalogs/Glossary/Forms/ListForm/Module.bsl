
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ThereIsTheRightToEdit = AccessRight("Update", Metadata.Catalogs.Glossary);
	
	Items.LoadFromTheTable.Visible             = ThereIsTheRightToEdit;
	Items.DownloadContextMenuList.Visible = ThereIsTheRightToEdit;
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject, ,"List");
	// End StandardSubsystems.Core
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtServerNoContext
Procedure ListOnGetDataAtServer(TagName, Settings, Rows)
	
	DescriptionLanguage = CurrentLanguage().LanguageCode; 
	If Not ValueIsFilled(DescriptionLanguage) Then
		Return;
	EndIf;
	
	MatchingStringsToKeys               = New Map;
	GlossaryElementsForGettingDescription = New Array;
	
	For Each ListLine In Rows Do
		
		MatchingStringsToKeys.Insert(ListLine.Key, ListLine.Value);
		
		GlossaryElementsForGettingDescription.Add(ListLine.Key);
		
	EndDo;
	
	If MatchingStringsToKeys.Count() = 0 Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	GlossaryGlossaryDetails.Ref AS Ref,
	|	GlossaryGlossaryDetails.LongDesc AS LongDesc
	|FROM
	|	Catalog.Glossary.GlossaryDetails AS GlossaryGlossaryDetails
	|WHERE
	|	GlossaryGlossaryDetails.Ref IN(&Glossaries)
	|	AND GlossaryGlossaryDetails.LanguageCode = &LanguageCode";
	
	Query.SetParameter("Glossaries", GlossaryElementsForGettingDescription);
	Query.SetParameter("LanguageCode",  CurrentLanguage().LanguageCode);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		
		AttributeData = Selection.LongDesc.Get();
		
		If TypeOf(AttributeData) = Type("FormattedDocument") Then
			DescriptionOfListLine = AttributeData.GetText();
			ArrayOfNonDescriptionStrings = StringFunctionsClientServer.SplitStringIntoSubstringsArray(DescriptionOfListLine, Chars.LF);
			ArrayOfNonEmptyStrings = New Array;
			For Each DetailsString In ArrayOfNonDescriptionStrings Do
				If IsBlankString(DetailsString) Then
					Continue;
				EndIf;
				ArrayOfNonEmptyStrings.Add(DetailsString);
			EndDo;
			DescriptionOfListLine = StrConcat(ArrayOfNonEmptyStrings);
			ListLine =  MatchingStringsToKeys.Get(Selection.Ref); //DynamicListRow
			If ListLine <> Undefined Then
				ListLine.Data.GlossaryDescription = DescriptionOfListLine; // 
			EndIf;
		EndIf;
	
	EndDo;
	
EndProcedure

#EndRegion 

#Region FormCommandsEventHandlers

&AtClient
Procedure Load(Command)
	
	OpenForm("Catalog.Glossary.Form.GlossaryImportForm",, ThisObject);
	
EndProcedure

&AtClient
Procedure TranslateSelectedItems(Command)
	
	ArrayOfSelected = Items.List.SelectedRows;
	
	If ArrayOfSelected.Count()>0 Then
		Couples  = New Structure;
		Couples.Insert("SelectedItems", ArrayOfSelected);
		OpenForm("Catalog.DemoScenarios.Form.TranslateSeveralScenarios",Couples);
	Else
		ShowMessageBox(, NStr("vi = 'Cần chọn ít nhất một phần tử hoặc nhóm';
								|ru = 'Необходимо выбрать хотя бы один элемент или группу';
								|en = 'Select at least one item or group'; fa = 'Select at least one item or group';
								|it = 'Необходимо выбрать хотя бы один элемент или группу';
								|pl = 'Select at least one item or group';
								|tr = 'En az bir öğe veya grup seçmeniz gerekmektedir'"), 20);
	EndIf;
	
EndProcedure

#EndRegion


