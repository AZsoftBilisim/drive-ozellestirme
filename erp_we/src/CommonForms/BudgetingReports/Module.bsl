
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	BudgetingModel = DefaultBudgetingModel();
	ListSelectionsClientServer.ChangeListSelectionElement(
		BudgetProfileList, "Owner", BudgetingModel, ValueIsFilled(BudgetingModel));
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	ListSelectionsClientServer.ChangeListSelectionElement(
		BudgetProfileList, "Owner", BudgetingModel, ValueIsFilled(BudgetingModel));
	
EndProcedure

&AtClient
Procedure BudgetingModelOnChange(Item)
	
	ListSelectionsClientServer.ChangeListSelectionElement(
		BudgetProfileList, "Owner", BudgetingModel, ValueIsFilled(BudgetingModel));
	RecordSelectedBudgetingModel(BudgetingModel);
	
EndProcedure

#EndRegion

#Region FormListEventHandlers

&AtClient
Procedure BudgetProfileListSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Not Item.CurrentData.IsFolder Then
		StandardProcessing = False;
		GenerateReport(Item.CurrentData);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Generate(Command)
	
	ClearMessages();
	CurrentRow = Items.BudgetProfileList.CurrentData;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	If CurrentRow.IsFolder Then
		CommonClientServer.MessageToUser(NStr("vi = 'Báo cáo theo nhóm là không có sẵn.';
												|ru = 'Формирование отчета по группе не доступно.';
												|en = 'Report generation by group is not available.'; fa = 'Report generation by group is not available.';
												|it = 'Creazione del report per gruppo non disponibile.';
												|pl = 'Tworzenie raportu dla grupy nie jest dostępne.';
												|tr = 'Gruba göre rapor oluşturulamıyor.'"));
		Return;
	EndIf;
	
	GenerateReport(CurrentRow);
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Function DefaultBudgetingModel()
	
	BudgetingModel = FormDataSettingsStorage.Load("CommonForm.BudgetingReports", "BudgetingModel");
	If BudgetingModel = Undefined Then
		BudgetingModel = Catalogs.BudgetingModels.EmptyRef();
	EndIf;
	Return BudgetingModel;
	
EndFunction

&AtServerNoContext
Procedure RecordSelectedBudgetingModel(Model)
	FormDataSettingsStorage.Save("CommonForm.BudgetingReports", "BudgetingModel", Model);
EndProcedure

&AtClient
Procedure GenerateReport(CurrentRow)
	
	ReportParameters = New Structure;
	ReportParameters.Insert("BudgetProfile",           CurrentRow.BudgetProfile);
	ReportParameters.Insert("BudgetingModel", CurrentRow.Owner);
	ReportParameters.Insert("GenerateBudgetReportWhenOpening", True);
	
	OpenForm("Report.BudgetReport.Form.ReportForm", ReportParameters, ThisForm, True);
	
EndProcedure

#EndRegion

