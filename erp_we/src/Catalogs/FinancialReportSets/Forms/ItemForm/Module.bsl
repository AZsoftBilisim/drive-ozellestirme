
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnReadCreateAtServer();
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
EndProcedure

&AtClient
Procedure  AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	LineOfAccountPlans = LineOfAccountPlans();
	SetParametersForSelectingTypesOfFinancialStatements();
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "Catalog.FinancialReportTypes.Form.SelectChartsOfAccounts" Then
		
		TypesOfFinancialStatementsToDelete = CheckTypesOfFinancialStatements(ValueSelected);
		If TypesOfFinancialStatementsToDelete.Count() > 0 Then
			
			AdditionalParameters = New Structure();
			AdditionalParameters.Insert("SelectedAccountPlans", ValueSelected);
			AdditionalParameters.Insert("TypesOfFinancialStatementsToDelete", TypesOfFinancialStatementsToDelete);
			
			Notification = New CallbackDescription("ResponseProcessingDeletingReportTypes", ThisObject, AdditionalParameters);
			If TypesOfFinancialStatementsToDelete.Count() = 1 Then
				QueryText = StrTemplate(NStr("vi = 'Dạng báo cáo ""%1"" sẽ bị xóa khỏi bộ báo cáo. Tiếp tục?';
											|ru = 'Вид отчета ""%1"" будет удален из комплекта. Продолжить?';
											|en = 'The ""%1"" report kind will be removed from the kit. Continue?'; fa = 'The ""%1"" report kind will be removed from the kit. Continue?';
											|it = 'Il tipo di report ""%1"" sarà cancellato dal set. Continuare?';
											|pl = 'Rodzaj raportu ""%1"" będzie usunięty z zestawu. Kontynuować?';
											|tr = '""%1"" rapor türü setten silinecektir. Devam edilsin mi?'"), TypesOfFinancialStatementsToDelete);
			Else
				QueryText = StrTemplate(
									NStr("vi = 'Dạng báo cáo:
									|- %1
									|sẽ bị xóa khỏi bộ báo cáo. Tiếp tục?';
									|ru = 'Виды отчетов:
									|- %1
									|будут удалены из комплекта. Продолжить?';
									|en = 'Report kinds:
									|- %1
									|will be deleted from the kit. Continue?'; fa = 'Report kinds:
									|- %1
									|will be deleted from the kit. Continue?';
									|it = 'Tipi di report:
									|- %1
									| saranno cancellati dal set. Continuare?';
									|pl = 'Rodzaje raportów:
									|- %1
									|będą usunięte z zestawu. Kontynuować?';
									|tr = 'Bu rapor türleri setten silinecektir:
									|-
									|%1 . Devam edilsin mi?'"),
									StrConcat(TypesOfFinancialStatementsToDelete, "," + Chars.LF + "- "));
			EndIf;
			
			Buttons = New ValueList;
			Buttons.Add(DialogReturnCode.OK, NStr("vi = 'Tiếp tục';
													|ru = 'Продолжить';
													|en = 'Continue'; fa = 'ادامه';
													|it = 'Continuare';
													|pl = 'Kontynuuj';
													|tr = 'Devam et'"));
			Buttons.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
														|ru = 'Отмена';
														|en = 'Cancel'; fa = 'انصراف';
														|it = 'Annulla';
														|pl = 'Anuluj';
														|tr = 'İptal'"));
			ShowQueryBox(Notification, QueryText, Buttons);
			
		EndIf;
		
		FillOutAccountPlans(ValueSelected);
		
	EndIf;
	
EndProcedure

&AtServer
Function CheckTypesOfFinancialStatements(SelectedAccountPlans)
	
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	TableOfAccountPlans.Ref AS Ref
	|FROM
	|	Catalog.FinancialReportTypes.ChartsOfAccounts AS TableOfAccountPlans
	|WHERE
	|	TableOfAccountPlans.Ref IN (&KitReports)
	|	AND NOT TableOfAccountPlans.ChartOfAccounts IN (&SelectedAccountPlans)
	|";
	Query.SetParameter("SelectedAccountPlans", SelectedAccountPlans);
	Query.SetParameter("KitReports", Object.ReportsKinds.Unload().UnloadColumn("FinancialReportType"));
	
	Return Query.Execute().Unload().UnloadColumn("Ref");
	
EndFunction

&AtClient
Procedure ResponseProcessingDeletingReportTypes(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.OK Then
		LinesToDelete = New Array;
		For Each ReportKind In AdditionalParameters.TypesOfFinancialStatementsToDelete Do
			CommonClientServer.SupplementArray(
				LinesToDelete,
				Object.ReportsKinds.FindRows(New Structure("FinancialReportType", ReportKind)));
		EndDo;
		For Each RowToDelete In LinesToDelete Do
			Object.ReportsKinds.Delete(RowToDelete);
		EndDo;
		
		FillOutAccountPlans(AdditionalParameters.SelectedAccountPlans);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ReportsKindsFinancialReportTypeOnChange(Item)
	Items.ReportsKinds.CurrentData.SettingsText_3 = NStr("vi = 'Tùy chỉnh lọc';
														|ru = 'Настроить отборы';
														|en = 'Set filters'; fa = 'تعیین فیلترها';
														|it = 'Impostare le selezioni';
														|pl = 'Ustaw selekcje';
														|tr = 'Filtreleri ayarla'");
EndProcedure

&AtClient
Procedure LongDescStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	CommonClient.ShowCommentEditingForm(
		Item.EditText, 
		ThisObject, 
		"Object.LongDesc");
	
EndProcedure

&AtClient
Procedure ChartsOfAccountsURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	FormParameters = AccountPlanSelectionFormParameters();
	OpenForm("Catalog.FinancialReportTypes.Form.SelectChartsOfAccounts", FormParameters, ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure OnReadCreateAtServer() 
	
	LineOfAccountPlans = LineOfAccountPlans();
	SetParametersForSelectingTypesOfFinancialStatements();
	
EndProcedure

&AtServer
Function LineOfAccountPlans()
	
	SetAccountPlans = New Array;
	For Each TableRow In Object.ChartsOfAccounts Do
		If TypeOf(TableRow.ChartOfAccounts) = Type("CatalogRef.MetadataObjectIDs") Then
			MetadataObjectChartOfAccounts = Common.MetadataObjectByID(TableRow.ChartOfAccounts);
			ObjectManager = Common.ObjectManagerByFullName(MetadataObjectChartOfAccounts.FullName()); // MetadataObjectChartOfAccounts - 
			SetAccountPlans.Add(ObjectManager.PresentationInFinancialStatements());
		Else
			SetAccountPlans.Add(TableRow.ChartOfAccounts);
		EndIf;
	EndDo;
	
	If SetAccountPlans.Count() <> 0 Then
		PresentationOfChartsOfAccounts = StrConcat(SetAccountPlans, ", ");
		ColorOfHyperlink = StyleColors.HyperlinkColor;
	Else
		PresentationOfChartsOfAccounts = NStr("vi = '<Chưa chọn hệ thống tài khoản>';
												|ru = '<План счетов не выбран>';
												|en = '<Chart of accounts is not selected>'; fa = '<Chart of accounts is not selected>';
												|it = '<Piano dei conti non selezionato>';
												|pl = '<Planu kont nie wybrano>';
												|tr = '<Hesap planı seçili değil>'");
		ColorOfHyperlink = StyleColors.OverdueDataColor;
	EndIf;
	
	Return New FormattedString(PresentationOfChartsOfAccounts, , ColorOfHyperlink, , "OpenSelectionOfAccountPlans")
	
EndFunction

&AtServer
Procedure FillOutAccountPlans(SelectedAccountPlans)
	
	Object.ChartsOfAccounts.Clear();
	For Each ChartOfAccounts In SelectedAccountPlans Do
		NewRow = Object.ChartsOfAccounts.Add();
		NewRow.ChartOfAccounts = ChartOfAccounts;
	EndDo;
	LineOfAccountPlans = LineOfAccountPlans();
	SetParametersForSelectingTypesOfFinancialStatements();
	Modified = True;
	
EndProcedure

&AtServer
Function AccountPlanSelectionFormParameters()
	
	FormParameters = New Structure();
	FormParameters.Insert("SelectedAccountPlans", Object.ChartsOfAccounts.Unload().UnloadColumn("ChartOfAccounts"));
	Return FormParameters;
	
EndFunction

&AtServer
Procedure SetParametersForSelectingTypesOfFinancialStatements()
	
	SetAccountPlans = Object.ChartsOfAccounts.Unload().UnloadColumn("ChartOfAccounts");
	
	ParametersForSelectingReportType = New Array;
	ParametersForSelectingReportType.Add(New ChoiceParameter("ChartsOfAccounts", New FixedArray(SetAccountPlans)));
	
	Items.ReportsKindsFinancialReportType.ChoiceParameters = New FixedArray(ParametersForSelectingReportType);
	
EndProcedure


#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
