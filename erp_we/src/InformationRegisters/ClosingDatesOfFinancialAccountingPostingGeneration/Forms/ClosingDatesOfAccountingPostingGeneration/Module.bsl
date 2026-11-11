
#Region FormEventHandlers

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Tab.Organization,
	|	MAX(Tab.PeriodEndClosingDate) AS PeriodEndClosingDate,
	|	Tab.Description AS Description
	|FROM
	|	(SELECT
	|		VALUE(Catalog.Companies.EmptyRef) AS Organization,
	|		DATETIME(1, 1, 1) AS PeriodEndClosingDate,
	|		"""" AS Description
	|	
	|	UNION
	|	
	|	SELECT
	|		ClosingDatesOfPostingGeneration.Organization,
	|		ClosingDatesOfPostingGeneration.PeriodEndClosingDate,
	|		""""
	|	FROM
	|		InformationRegister.ClosingDatesOfFinancialAccountingPostingGeneration AS ClosingDatesOfPostingGeneration
	|	WHERE
	|		ClosingDatesOfPostingGeneration.Organization = VALUE(Catalog.Companies.EmptyRef)) AS Tab
	|
	|GROUP BY
	|	Tab.Description,
	|	Tab.Organization
	|
	|UNION ALL
	|
	|SELECT
	|	Companies.Ref,
	|	ClosingDatesOfPostingGeneration.PeriodEndClosingDate,
	|	Companies.Description
	|FROM
	|	Catalog.Companies AS Companies
	|		LEFT JOIN InformationRegister.ClosingDatesOfFinancialAccountingPostingGeneration AS ClosingDatesOfPostingGeneration
	|		ON Companies.Ref = ClosingDatesOfPostingGeneration.Organization
	|WHERE
	|	Companies.Ref <> VALUE(Catalog.Companies.ManagementCompany)
	|
	|ORDER BY
	|	Description";
	
	ClosingDates.Clear();
	CommonClientServer.SupplementTable(Query.Execute().Unload(),ClosingDates);
	ReadOnly = Not AccessRight("Update", Metadata.InformationRegisters.ClosingDatesOfFinancialAccountingPostingGeneration);

	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	CurrentObject.Clear();
	For Each Page1 In ClosingDates Do
		If ValueIsFilled(Page1.PeriodEndClosingDate) Then
			NewRow = CurrentObject.Add();
			FillPropertyValues(NewRow, Page1);
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("ChangedDateWhenTransactionsWereBanned");
	
EndProcedure

#EndRegion

#Region CommandHandlers

&AtClient
Procedure InstallToAll(Command)
	
	DateInputHandler = New CallbackDescription("SetBanDateForEveryone",ThisObject);
	ShowInputDate(DateInputHandler,ClosingDates[0].PeriodEndClosingDate,NStr("vi = 'Nhập ngày';
																			|ru = 'Введите дату';
																			|en = 'Enter the date'; fa = 'Enter the date';
																			|it = 'Inserisci la data';
																			|pl = 'Wprowadź datę';
																			|tr = 'Tarihi girin'"),DateFractions.Date);
	
EndProcedure

&AtClient
Procedure ClearToAll(Command)
	
	Cleaner = New CallbackDescription("ClearBanDateForAll",ThisObject);
	QueryText = NStr("vi = 'Xóa tất cả ngày?';
					|ru = 'Убрать все даты?';
					|en = 'Remove all dates?'; fa = 'Remove all dates?';
					|it = 'Eliminare tutte le date?';
					|pl = 'Usunąć wszystkie daty?';
					|tr = 'Tüm tarihler kaldırılsın mı?'");
	If Items.ClosingDates.SelectedRows.Count() > 1 Then
		QueryText = NStr("vi = 'Xóa ngày đã chọn?';
						|ru = 'Убрать выбранные даты?';
						|en = 'Remove the selected dates?'; fa = 'Remove the selected dates?';
						|it = 'Eliminare le date selezionate?';
						|pl = 'Usunąć wybrane daty?';
						|tr = 'Seçilen tarihler kaldırılsın mı?'");
	EndIf;
	ShowQueryBox(Cleaner,QueryText,QuestionDialogMode.YesNo,,DialogReturnCode.Yes);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SetBanDateForEveryone(PeriodEndClosingDate, Var_Parameters) Export
	
	If ValueIsFilled(PeriodEndClosingDate) Then
		FillInDate(PeriodEndClosingDate);
	EndIf;
	
EndProcedure

&AtClient
Procedure ClearBanDateForAll(Result, Var_Parameters) Export
	
	If Result = DialogReturnCode.Yes Then
		FillInDate();
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInDate(NewDate = Undefined)
	
	If Items.ClosingDates.SelectedRows.Count() > 1 Then
		For Each LineID In Items.ClosingDates.SelectedRows Do
			RowData = ClosingDates.FindByID(LineID);
			RowData.PeriodEndClosingDate = NewDate;
		EndDo;
	Else
		For Each Page1 In ClosingDates Do
			Page1.PeriodEndClosingDate = NewDate;
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion