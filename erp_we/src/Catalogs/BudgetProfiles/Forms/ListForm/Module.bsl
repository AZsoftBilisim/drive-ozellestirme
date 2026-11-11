#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	FilterByOwnerParameter = Undefined;
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	If Parameters.Property("Filter") Then
		If Parameters.Filter.Property("Owner", FilterByOwnerParameter) Then
			BudgetingModel = FilterByOwnerParameter;
			Items.BudgetingModel.Visible = False;
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(BudgetingModel) Then
		BudgetingModel = DefaultBudgetingModel();
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "Owner", BudgetingModel,,, ValueIsFilled(BudgetingModel));
		
	If Items.Find("FormToPreviewTheReport") <> Undefined Then
		Items.FormToPreviewTheReport.Visible = AccessRight("View", Metadata.Reports.BudgetReport);
	EndIf;
	If Items.Find("ListCreateBudgetEntryDocument") <> Undefined Then
		Items.ListCreateBudgetEntryDocument.Visible = AccessRight("InteractiveInsert", Metadata.Documents.BudgetEntryForm);
	EndIf;
	If Items.Find("ListInstancesByBudgetProfile") <> Undefined Then
		Items.ListInstancesByBudgetProfile.Visible = AccessRight("View", Metadata.Documents.BudgetEntryForm);
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ViewReportKind(Command)
	
	ClearMessages();
	
	CurrentRow = Items.List.CurrentRow;
	If CurrentRow = Undefined Then
		WarningText = NStr("vi = 'Không thể thực hiện lệnh đối với đối tượng được chọn';
							|ru = 'Команда не может быть выполнена для указанного объекта';
							|en = 'Cannot execute the command for the specified object'; fa = 'Cannot execute the command for the specified object';
							|it = 'Il comando non può essere eseguito per l''oggetto indicato';
							|pl = 'Polecenie nie może zostać wykonane dla wskazanego obiektu';
							|tr = 'Komut belirtilen nesne için uygulanamaz'");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	
	RowData = GeneralPurposeTMServerCall.ObjectAttributesValues(CurrentRow, "Owner, Ref, IsFolder");
	If RowData.IsFolder = True Then
		WarningText = NStr("vi = 'Không thể xem báo cáo theo nhóm phần tử';
							|ru = 'Просмотр отчета по группе элемента невозможен';
							|en = 'Cannot view the report by item group'; fa = 'Cannot view the report by item group';
							|it = 'Non è possibile visualizzare un report relativo al gruppo di elemento';
							|pl = 'Przeglądanie raportu dla grupy elementu nie jest możliwe';
							|tr = 'Raporun öğe grubuna göre önizlemesi yapılamaz'");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	
	ReportParameters = New Structure;
	ReportParameters.Insert("BudgetingModel", RowData.Owner);
	ReportParameters.Insert("BudgetProfile", RowData.Ref);
	ReportParameters.Insert("GenerateBudgetReportWhenOpening", True);
	
	OpenForm("Report.BudgetReport.Form.ReportForm",
		ReportParameters,
		ThisObject,
		RowData.Ref);
	
EndProcedure

&AtClient
Procedure BudgetingModelOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "Owner", BudgetingModel,,, ValueIsFilled(BudgetingModel));
	RecordSelectedBudgetingModel(BudgetingModel);
	
EndProcedure

&AtClient
Procedure CreateBudgetEntryDocument(Command)
	
	ClearMessages();
	
	CurrentRow = Items.List.CurrentRow;
	If Not ValueIsFilled(CurrentRow) Then
		WarningText = NStr("vi = 'Không thể thực hiện lệnh đối với đối tượng được chọn';
							|ru = 'Команда не может быть выполнена для указанного объекта';
							|en = 'Cannot execute the command for the specified object'; fa = 'Cannot execute the command for the specified object';
							|it = 'Il comando non può essere eseguito per l''oggetto indicato';
							|pl = 'Polecenie nie może zostać wykonane dla wskazanego obiektu';
							|tr = 'Komut belirtilen nesne için uygulanamaz'");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	
	If Not Items.List.CurrentData.UseToEnterPlan Then
		WarningText = NStr("vi = 'Dạng ngân sách không được dùng để nhập dữ liệu kế hoạch';
							|ru = 'Вид бюджета не используется для ввода плановых данных';
							|en = 'Budget profile is not used to enter planned data'; fa = 'Budget profile is not used to enter planned data';
							|it = 'Il tipo di budget non viene utilizzato per inserire i dati di pianificazione';
							|pl = 'Rodzaj budżetu nie jest używany do wprowadzania danych planowych';
							|tr = 'Bütçe profili planlanan veri girişleri için kullanılamaz'");
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	
	If Not CheckBudgetViewOnServer(CurrentRow) Then
		Return;
	EndIf;
	
	FillingData = New Structure("BudgetProfile", CurrentRow);
	FormParameters = New Structure("FillingValues", FillingData);
	OpenForm("Document.BudgetEntryForm.Form.DocumentForm", FormParameters);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Function DefaultBudgetingModel()
	
	BudgetingModel = FormDataSettingsStorage.Load("Catalog.BudgetProfiles.Form.ListForm", "BudgetingModel");
	If BudgetingModel = Undefined Then
		BudgetingModel = Catalogs.BudgetingModels.EmptyRef();
	EndIf;
	Return BudgetingModel;
	
EndFunction

&AtServerNoContext
Procedure RecordSelectedBudgetingModel(Model)
	FormDataSettingsStorage.Save("Catalog.BudgetProfiles.Form.ListForm", "BudgetingModel", Model);
EndProcedure

&AtServer
Function CheckBudgetViewOnServer(CurrentRow)
	
	Return Catalogs.BudgetProfiles.BudgetViewIsFilledInCorrectly(CurrentRow)
				And BudgetingModelOfBudgetTypeIsValid(CurrentRow);
	
EndFunction

&AtServer
Function BudgetingModelOfBudgetTypeIsValid(BudgetProfile)
	
	Valid = False;
	
	If ValueIsFilled(BudgetProfile) Then
		BudgetingModel = Common.ObjectAttributeValue(BudgetProfile, "Owner");
		Valid = Catalogs.BudgetingModels.BudgetingModelWorks(BudgetingModel);
		
		If Not Valid Then
			ErrorText = NStr("vi = 'Mô hình lập ngân sách của dạng ngân sách không hoạt động';
							|ru = 'Модель бюджетирования вида бюджета не действует';
							|en = 'Budgeting model of the budget profile is invalid'; fa = 'Budgeting model of the budget profile is invalid';
							|it = 'Il modello di determinazione del budget non è valido per il tipo di budget';
							|pl = 'Model budżetowania rodzaju budżetu nie obowiązuje';
							|tr = 'Bütçe profilinin bütçeleme modeli çalışmıyor'");
			CommonClientServer.MessageToUser(ErrorText);
		EndIf;
	EndIf;
	
	Return Valid;
	
EndFunction

#EndRegion

