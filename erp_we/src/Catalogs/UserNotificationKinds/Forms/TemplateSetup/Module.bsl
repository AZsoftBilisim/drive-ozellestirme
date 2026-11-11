#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	DefaultLanguageCode = Common.DefaultLanguageCode();
	If Not AccessRight("Update", Metadata.Catalogs.UserNotificationKinds) Then
		ReadOnly = True;
	EndIf;
	ParseMultilingualString(Parameters.NotificationTextTemplate);
	Add_Attributes();
	FillInSubstitutionParameters(Parameters.SubstitutionParameters);
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	AvailableParameters = SubstitutionParameters.Unload().UnloadColumn("Parameter");
	RegularExpression = "(?<=\[)[^\[\]\s]+(?=\])"; //@Non-NLS-1
	Errors = Undefined;
	
	For Each CurrentRow In TableAText Do
		If Not ValueIsFilled(CurrentRow.Text) Then
			If CurrentRow.LanguageCode = DefaultLanguageCode Then
				CommonClientServer.AddUserError(Errors,
					"",
					StrTemplate(NStr("vi = 'Chưa điền nội dung thông báo dựa trên ngôn ngữ chính %1';
									|ru = 'Не заполнен текст сообщения на основном языке %1';
									|en = 'The message text in the %1 main language is not filled in'; fa = 'The message text in the %1 main language is not filled in';
									|it = 'The message text in the %1 main language is not filled in';
									|pl = 'The message text in the %1 main language is not filled in';
									|tr = 'Birincil %1 dilindeki mesaj metni doldurulmadı'"),
						CurrentRow.Language));
			EndIf;
		Else
			SearchResults = StrFindAllByRegularExpression(
				CurrentRow.Text,
				RegularExpression);
			For Each SearchResult In SearchResults Do
				If AvailableParameters.Find(SearchResult.Value) = Undefined Then
					CommonClientServer.AddUserError(Errors,
						"",
						StrTemplate(NStr("vi = 'Đã chỉ định mẫu không tồn tại [%1] đối với ngôn ngữ %2';
										|ru = 'Указан несуществующий шаблон [%1] для языка %2';
										|en = 'A non-existent [%1] template for the %2 language is specified'; fa = 'A non-existent [%1] template for the %2 language is specified';
										|it = 'A non-existent [%1] template for the %2 language is specified';
										|pl = 'A non-existent [%1] template for the %2 language is specified';
										|tr = '%2 dili için mevcut olmayan [%1] şablonu belirtildi'"),
							SearchResult.Value,
							CurrentRow.Language));
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
	CommonClientServer.ReportErrorsToUser(Errors, Cancel);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSubstitutionParameters

&AtClient
Procedure SubstitutionParametersSelection(Item, RowSelected, Field, StandardProcessing)
	CurrentData = Items.SubstitutionParameters.CurrentData;
	If CurrentData <> Undefined And Not ReadOnly Then
		AddReplacementParameter(CurrentData.Parameter);
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure FinishEditingTemplate(Command)
	ClearMessages();
	If CheckFilling() Then
		Close(AssembleMultilingualString());
	EndIf;
EndProcedure

&AtClient
Procedure MoveTo_(Command)
	CurrentData = Items.SubstitutionParameters.CurrentData;
	If CurrentData <> Undefined Then
		AddReplacementParameter(CurrentData.Parameter);
	EndIf;
EndProcedure

#EndRegion

#Region Private

&AtServer
//@skip-check bsl-nstr-string-literal-format
Procedure ParseMultilingualString(NotificationTextTemplate)
	TableAText.Clear();
	
	TextTemplateMainLanguage = NStr(NotificationTextTemplate, DefaultLanguageCode);
	AvailableLanguages = AvailableLanguages();
	For Each Language In AvailableLanguages Do
		NewRow = TableAText.Add();
		NewRow.LanguageCode = Language.LanguageCode;
		NewRow.Language = Language.Synonym;
		TextTemplate1 = NStr(NotificationTextTemplate, Language.LanguageCode);
		NewRow.Text = ?(ValueIsFilled(TextTemplate1),
			TextTemplate1,
			TextTemplateMainLanguage);
	EndDo;
	
EndProcedure

&AtServerNoContext
Function AvailableLanguages()
	AvailableLanguages = New Array;
	For Each Language In Metadata.Languages Do
		LanguageDetails = New Structure("LanguageCode, Synonym");
		LanguageDetails.LanguageCode = Language.LanguageCode;
		LanguageDetails.Synonym = Language.Synonym;
		AvailableLanguages.Add(LanguageDetails);
	EndDo;
	Return AvailableLanguages
EndFunction

&AtServer
Procedure Add_Attributes()
	
	MoreThanOneLanguage = TableAText.Count() > 1;
	If MoreThanOneLanguage Then
		CurrentPage = Items.GroupOfManyLanguages;
	Else
		CurrentPage = Items.OneLanguageGroup;
	EndIf;
	
	Items.GroupPages.CurrentPage = CurrentPage;
	
	LineNumber = 0;
	For Each String_Text In TableAText Do
		AttributeName = NameOfAttributeToLocalize(String_Text.LanguageCode);
		If Items.Find(AttributeName) = Undefined Then
			NewItem = Items.Add(AttributeName,
				Type("FormField"),
				CurrentPage);
			NewItem.Type = FormFieldType.TextDocumentField;
			NewItem.DataPath = "TableAText" + "[" + Format(LineNumber,"NFD=0; NG=")
				+ "]." + "Text";
			NewItem.TitleLocation = FormItemTitleLocation.Top;
			NewItem.Height = 2;
			NewItem.Width = 50;
			If Not MoreThanOneLanguage Then
				NewItem.Title = NStr("vi = 'Mẫu thông báo';
									|ru = 'Шаблон оповещения';
									|en = 'Notification template'; fa = 'Notification template';
									|it = 'Notification template';
									|pl = 'Notification template';
									|tr = 'Bildirim şablonu'");
			Else
				NewItem.Title = String_Text.Language;
			EndIf;
		EndIf;
		LineNumber = LineNumber + 1;
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Function NameOfAttributeToLocalize(LanguageCode)
	
	Return "NotificationText1" + "_" + LanguageCode;
	
EndFunction

&AtServer
Procedure FillInSubstitutionParameters(InitialParameters)
	If Not ValueIsFilled(InitialParameters) Then
		Items.SubstitutionParameters.Visible = False;
		Items.MoveTo_.Visible = False;
		Return
	EndIf;
	
	For Each SubstitutionParameter In InitialParameters Do
		NewRow = SubstitutionParameters.Add();
		NewRow.Parameter = SubstitutionParameter.Field;
		NewRow.Presentation = SubstitutionParameter.Title;
	EndDo;
	
EndProcedure

&AtClient
Function AssembleMultilingualString()
	NotificationTextTemplate = "";
	TextInMainLanguage = "";
	FoundRows = TableAText.FindRows(New Structure("LanguageCode", DefaultLanguageCode));
	If FoundRows.Count() > 0 Then
		TextInMainLanguage = FoundRows[0].Text;
	EndIf;
	
	For Each CurRow In TableAText Do
		Text = ?(ValueIsFilled(CurRow.Text), CurRow.Text, TextInMainLanguage);
		TextString = CurRow.LanguageCode + " " + "=" + " " + "'";
		TextString = TextString + StrReplace(Text, "'", """") + "';";
		NotificationTextTemplate = NotificationTextTemplate + TextString;
	EndDo;
	Return NotificationTextTemplate
EndFunction

&AtClient
Procedure AddReplacementParameter(ReplacementParameter)
	For Each CurRow In TableAText Do
		AttributeName = NameOfAttributeToLocalize(CurRow.LanguageCode);
		Items[AttributeName].SelectedText = "[" + ReplacementParameter + "]";
	EndDo;
EndProcedure

#EndRegion